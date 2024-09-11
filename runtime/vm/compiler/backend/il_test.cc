// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il.h"

#include <optional>
#include <vector>

#include "platform/text_buffer.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/unit_test.h"

namespace dart {

ISOLATE_UNIT_TEST_CASE(InstructionTests) {
  TargetEntryInstr* target_instr =
      new TargetEntryInstr(1, kInvalidTryIndex, DeoptId::kNone);
  EXPECT(target_instr->IsBlockEntry());
  EXPECT(!target_instr->IsDefinition());
}

ISOLATE_UNIT_TEST_CASE(OptimizationTests) {
  JoinEntryInstr* join =
      new JoinEntryInstr(1, kInvalidTryIndex, DeoptId::kNone);

  Definition* def1 = new PhiInstr(join, 0);
  Definition* def2 = new PhiInstr(join, 0);
  Value* use1a = new Value(def1);
  Value* use1b = new Value(def1);
  EXPECT(use1a->Equals(*use1b));
  Value* use2 = new Value(def2);
  EXPECT(!use2->Equals(*use1a));

  ConstantInstr* c1 = new ConstantInstr(Bool::True());
  ConstantInstr* c2 = new ConstantInstr(Bool::True());
  EXPECT(c1->Equals(*c2));
  ConstantInstr* c3 = new ConstantInstr(Object::ZoneHandle());
  ConstantInstr* c4 = new ConstantInstr(Object::ZoneHandle());
  EXPECT(c3->Equals(*c4));
  EXPECT(!c3->Equals(*c1));
}

ISOLATE_UNIT_TEST_CASE(IRTest_EliminateWriteBarrier) {
  // clang-format off
  const char* kScript = R"(
      class Container<T> {
        operator []=(var index, var value) {
          return data[index] = value;
        }

        List<T?> data = List<T?>.filled(10, null);
      }

      Container<int> x = Container<int>();

      foo() {
        for (int i = 0; i < 10; ++i) {
          x[i] = i;
        }
      }
    )";
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  Invoke(root_library, "foo");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreIndexedInstr* store_indexed = nullptr;

  ILMatcher cursor(flow_graph, entry, true);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      {kMatchStoreIndexed, &store_indexed},
  }));

  EXPECT(!store_indexed->value()->NeedsWriteBarrier());
}

static void ExpectStores(FlowGraph* flow_graph,
                         const std::vector<const char*>& expected_stores) {
  size_t next_expected_store = 0;
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      if (auto store = it.Current()->AsStoreField()) {
        EXPECT_LT(next_expected_store, expected_stores.size());
        EXPECT_STREQ(expected_stores[next_expected_store],
                     store->slot().Name());
        next_expected_store++;
      }
    }
  }
}

static void RunInitializingStoresTest(
    const Library& root_library,
    const char* function_name,
    CompilerPass::PipelineMode mode,
    const std::vector<const char*>& expected_stores) {
  const auto& function =
      Function::Handle(GetFunction(root_library, function_name));
  TestPipeline pipeline(function, mode);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,
      CompilerPass::kInlining,
      CompilerPass::kTypePropagation,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kCanonicalize,
      CompilerPass::kConstantPropagation,
  });
  ASSERT(flow_graph != nullptr);
  ExpectStores(flow_graph, expected_stores);
}

ISOLATE_UNIT_TEST_CASE(IRTest_InitializingStores) {
  // clang-format off
  const char* kScript = R"(
    class Bar {
      var f;
      var g;

      Bar({this.f, this.g});
    }
    Bar f1() => Bar(f: 10);
    Bar f2() => Bar(g: 10);
    f3() {
      return () { };
    }
    f4<T>({T? value}) {
      return () { return value; };
    }
    main() {
      f1();
      f2();
      f3();
      f4();
    }
  )";
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");

  RunInitializingStoresTest(root_library, "f1", CompilerPass::kJIT,
                            /*expected_stores=*/{"f"});
  RunInitializingStoresTest(root_library, "f2", CompilerPass::kJIT,
                            /*expected_stores=*/{"g"});
  RunInitializingStoresTest(root_library, "f3", CompilerPass::kJIT,
                            /*expected_stores=*/
                            {"Closure.function", "Closure.entry_point"});

  // Note that in JIT mode we lower context allocation in a way that hinders
  // removal of initializing moves so there would be some redundant stores of
  // null left in the graph. In AOT mode we don't apply this optimization
  // which enables us to remove more stores.
  std::vector<const char*> expected_stores_jit;
  std::vector<const char*> expected_stores_aot;

  expected_stores_jit.insert(
      expected_stores_jit.end(),
      {"value", "Context.parent", "Context.parent", "value",
       "Closure.function_type_arguments", "Closure.context"});
  expected_stores_aot.insert(
      expected_stores_aot.end(),
      {"value", "Closure.function_type_arguments", "Closure.context"});

  RunInitializingStoresTest(root_library, "f4", CompilerPass::kJIT,
                            expected_stores_jit);
  RunInitializingStoresTest(root_library, "f4", CompilerPass::kAOT,
                            expected_stores_aot);
}

// Returns |true| if compiler canonicalizes away a chain of IntConverters going
// from |initial| representation to |intermediate| representation and then
// back to |initial| given that initial value has range [min_value, max_value].
bool TestIntConverterCanonicalizationRule(Thread* thread,
                                          int64_t min_value,
                                          int64_t max_value,
                                          Representation initial,
                                          Representation intermediate,
                                          Representation final) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/1);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::IntType()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();

  Definition* v0;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, initial);
    v0->set_range(Range(RangeBoundary::FromConstant(min_value),
                        RangeBoundary::FromConstant(max_value)));
    auto conv1 = builder.AddDefinition(new IntConverterInstr(
        initial, intermediate, new Value(v0), S.GetNextDeoptId()));
    auto conv2 = builder.AddDefinition(new IntConverterInstr(
        intermediate, initial, new Value(conv1), S.GetNextDeoptId()));
    ret = builder.AddReturn(new Value(conv2));
  }

  H.FinishGraph();

  H.flow_graph()->Canonicalize();
  H.flow_graph()->Canonicalize();

  return ret->value()->definition() == v0;
}

ISOLATE_UNIT_TEST_CASE(IL_IntConverterCanonicalization) {
  EXPECT(TestIntConverterCanonicalizationRule(thread, kMinInt16, kMaxInt16,
                                              kUnboxedInt64, kUnboxedInt32,
                                              kUnboxedInt64));
  EXPECT(TestIntConverterCanonicalizationRule(thread, kMinInt32, kMaxInt32,
                                              kUnboxedInt64, kUnboxedInt32,
                                              kUnboxedInt64));
  EXPECT(!TestIntConverterCanonicalizationRule(
      thread, kMinInt32, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedInt64,
      kUnboxedInt32, kUnboxedInt64));
  EXPECT(TestIntConverterCanonicalizationRule(
      thread, 0, kMaxInt16, kUnboxedInt64, kUnboxedUint32, kUnboxedInt64));
  EXPECT(TestIntConverterCanonicalizationRule(
      thread, 0, kMaxInt32, kUnboxedInt64, kUnboxedUint32, kUnboxedInt64));
  EXPECT(TestIntConverterCanonicalizationRule(
      thread, 0, kMaxUint32, kUnboxedInt64, kUnboxedUint32, kUnboxedInt64));
  EXPECT(!TestIntConverterCanonicalizationRule(
      thread, 0, static_cast<int64_t>(kMaxUint32) + 1, kUnboxedInt64,
      kUnboxedUint32, kUnboxedInt64));
  EXPECT(!TestIntConverterCanonicalizationRule(
      thread, -1, kMaxInt16, kUnboxedInt64, kUnboxedUint32, kUnboxedInt64));

  // Regression test for https://dartbug.com/53613.
  EXPECT(!TestIntConverterCanonicalizationRule(thread, kMinInt32, kMaxInt32,
                                               kUnboxedInt32, kUnboxedUint32,
                                               kUnboxedInt64));
  EXPECT(!TestIntConverterCanonicalizationRule(thread, kMinInt32, kMaxInt32,
                                               kUnboxedInt32, kUnboxedUint32,
                                               kUnboxedInt32));
  EXPECT(TestIntConverterCanonicalizationRule(
      thread, 0, kMaxInt32, kUnboxedInt32, kUnboxedUint32, kUnboxedInt64));
  EXPECT(TestIntConverterCanonicalizationRule(
      thread, 0, kMaxInt32, kUnboxedInt32, kUnboxedUint32, kUnboxedInt32));
}

ISOLATE_UNIT_TEST_CASE(IL_PhiCanonicalization) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/1);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::DynamicType()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto b2 = H.JoinEntry();
  auto b3 = H.TargetEntry();
  auto b4 = H.TargetEntry();

  Definition* v0;
  DartReturnInstr* ret;
  PhiInstr* phi;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, kTagged);
    builder.AddInstruction(new GotoInstr(b2, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), b2);
    phi = new PhiInstr(b2, 2);
    phi->SetInputAt(0, new Value(v0));
    phi->SetInputAt(1, new Value(phi));
    builder.AddPhi(phi);
    builder.AddBranch(new StrictCompareInstr(
                          InstructionSource(), Token::kEQ_STRICT,
                          new Value(H.IntConstant(1)), new Value(phi),
                          /*needs_number_check=*/false, S.GetNextDeoptId()),
                      b3, b4);
  }

  {
    BlockBuilder builder(H.flow_graph(), b3);
    builder.AddInstruction(new GotoInstr(b2, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), b4);
    ret = builder.AddReturn(new Value(phi));
  }

  H.FinishGraph();

  H.flow_graph()->Canonicalize();

  EXPECT(ret->value()->definition() == v0);
}

// Regression test for issue 46018.
ISOLATE_UNIT_TEST_CASE(IL_UnboxIntegerCanonicalization) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/2);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::DynamicType()));
  H.AddVariable("v1", AbstractType::ZoneHandle(Type::DynamicType()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  Definition* unbox;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    Definition* index = H.IntConstant(0);
    Definition* int_type =
        H.flow_graph()->GetConstant(Type::Handle(Type::IntType()));

    Definition* float64_array = builder.AddParameter(0, kTagged);
    Definition* int64_array = builder.AddParameter(1, kTagged);

    Definition* load_indexed = builder.AddDefinition(new LoadIndexedInstr(
        new Value(float64_array), new Value(index),
        /* index_unboxed */ false,
        /* index_scale */ 8, kTypedDataFloat64ArrayCid, kAlignedAccess,
        S.GetNextDeoptId(), InstructionSource()));
    Definition* box = builder.AddDefinition(
        BoxInstr::Create(kUnboxedDouble, new Value(load_indexed)));
    Definition* cast = builder.AddDefinition(new AssertAssignableInstr(
        InstructionSource(), new Value(box), new Value(int_type),
        /* instantiator_type_arguments */
        new Value(H.flow_graph()->constant_null()),
        /* function_type_arguments */
        new Value(H.flow_graph()->constant_null()),
        /* dst_name */ String::Handle(String::New("not-null")),
        S.GetNextDeoptId()));
    unbox = builder.AddDefinition(new UnboxInt64Instr(
        new Value(cast), S.GetNextDeoptId(), BoxInstr::kGuardInputs));

    builder.AddInstruction(new StoreIndexedInstr(
        new Value(int64_array), new Value(index), new Value(unbox),
        kNoStoreBarrier,
        /* index_unboxed */ false,
        /* index_scale */ 8, kTypedDataInt64ArrayCid, kAlignedAccess,
        S.GetNextDeoptId(), InstructionSource()));
    builder.AddReturn(new Value(index));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  EXPECT(!unbox->ComputeCanDeoptimize());

  H.flow_graph()->Canonicalize();
  EXPECT(!unbox->ComputeCanDeoptimize());

  H.flow_graph()->RemoveRedefinitions();
  EXPECT(!unbox->ComputeCanDeoptimize());  // Previously this reverted to true.
}

static void WriteCidTo(intptr_t cid, BaseTextBuffer* buffer) {
  ClassTable* const class_table = IsolateGroup::Current()->class_table();
  buffer->Printf("%" Pd "", cid);
  if (class_table->HasValidClassAt(cid)) {
    const auto& cls = Class::Handle(class_table->At(cid));
    buffer->Printf(" (%s", cls.ScrubbedNameCString());
    if (cls.is_abstract()) {
      buffer->AddString(", abstract");
    }
    buffer->AddString(")");
  }
}

static void TestNullAwareEqualityCompareCanonicalization(
    Thread* thread,
    bool allow_representation_change) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/2);
  H.AddVariable("v0", AbstractType::ZoneHandle(Type::IntType()));
  H.AddVariable("v1", AbstractType::ZoneHandle(Type::IntType()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();

  EqualityCompareInstr* compare = nullptr;
  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    Definition* v0 = builder.AddParameter(0, kUnboxedInt64);
    Definition* v1 = builder.AddParameter(1, kUnboxedInt64);
    Definition* box0 = builder.AddDefinition(new BoxInt64Instr(new Value(v0)));
    Definition* box1 = builder.AddDefinition(new BoxInt64Instr(new Value(v1)));

    compare = builder.AddDefinition(new EqualityCompareInstr(
        InstructionSource(), Token::kEQ, new Value(box0), new Value(box1),
        kMintCid, S.GetNextDeoptId(), /*null_aware=*/true));
    builder.AddReturn(new Value(compare));
  }

  H.FinishGraph();

  if (!allow_representation_change) {
    H.flow_graph()->disallow_unmatched_representations();
  }

  H.flow_graph()->Canonicalize();

  EXPECT(compare->is_null_aware() == !allow_representation_change);
}

ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_EqualityCompare) {
  TestNullAwareEqualityCompareCanonicalization(thread, true);
  TestNullAwareEqualityCompareCanonicalization(thread, false);
}

static void WriteCidRangeVectorTo(const CidRangeVector& ranges,
                                  BaseTextBuffer* buffer) {
  if (ranges.is_empty()) {
    buffer->AddString("empty CidRangeVector");
    return;
  }
  buffer->AddString("non-empty CidRangeVector:\n");
  for (const auto& range : ranges) {
    for (intptr_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      buffer->AddString("  * ");
      WriteCidTo(cid, buffer);
      buffer->AddString("\n");
    }
  }
}

static bool ExpectRangesContainCid(const Expect& expect,
                                   const CidRangeVector& ranges,
                                   intptr_t expected) {
  for (const auto& range : ranges) {
    for (intptr_t cid = range.cid_start; cid <= range.cid_end; cid++) {
      if (expected == cid) return true;
    }
  }
  TextBuffer buffer(128);
  buffer.AddString("Expected CidRangeVector to include cid ");
  WriteCidTo(expected, &buffer);
  expect.Fail("%s", buffer.buffer());
  return false;
}

static void RangesContainExpectedCids(const Expect& expect,
                                      const CidRangeVector& ranges,
                                      const GrowableArray<intptr_t>& expected) {
  ASSERT(!ranges.is_empty());
  ASSERT(!expected.is_empty());
  {
    TextBuffer buffer(128);
    buffer.AddString("Checking that ");
    WriteCidRangeVectorTo(ranges, &buffer);
    buffer.AddString("includes cids:\n");
    for (const intptr_t cid : expected) {
      buffer.AddString("  * ");
      WriteCidTo(cid, &buffer);
      buffer.AddString("\n");
    }
    THR_Print("%s", buffer.buffer());
  }
  bool all_found = true;
  for (const intptr_t cid : expected) {
    if (!ExpectRangesContainCid(expect, ranges, cid)) {
      all_found = false;
    }
  }
  if (all_found) {
    THR_Print("All expected cids included.\n\n");
  }
}

#define RANGES_CONTAIN_EXPECTED_CIDS(ranges, cids)                             \
  RangesContainExpectedCids(dart::Expect(__FILE__, __LINE__), ranges, cids)

ISOLATE_UNIT_TEST_CASE(HierarchyInfo_Object_Subtype) {
  HierarchyInfo hi(thread);
  const auto& type =
      Type::Handle(IsolateGroup::Current()->object_store()->object_type());
  const bool is_nullable = Instance::NullIsAssignableTo(type);
  EXPECT(hi.CanUseSubtypeRangeCheckFor(type));
  const auto& cls = Class::Handle(type.type_class());

  ClassTable* const class_table = thread->isolate_group()->class_table();
  const intptr_t num_cids = class_table->NumCids();
  auto& to_check = Class::Handle(thread->zone());
  auto& rare_type = AbstractType::Handle(thread->zone());

  GrowableArray<intptr_t> expected_concrete_cids;
  GrowableArray<intptr_t> expected_abstract_cids;
  for (intptr_t cid = kInstanceCid; cid < num_cids; cid++) {
    if (!class_table->HasValidClassAt(cid)) continue;
    if (cid == kNullCid) continue;
    if (cid == kNeverCid) continue;
    if (cid == kDynamicCid && !is_nullable) continue;
    if (cid == kVoidCid && !is_nullable) continue;
    to_check = class_table->At(cid);
    // Only add concrete classes.
    if (to_check.is_abstract()) {
      expected_abstract_cids.Add(cid);
    } else {
      expected_concrete_cids.Add(cid);
    }
    if (cid != kTypeArgumentsCid) {  // Cannot call RareType() on this.
      rare_type = to_check.RareType();
      EXPECT(rare_type.IsSubtypeOf(type, Heap::kNew));
    }
  }

  const CidRangeVector& concrete_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/false, /*exclude_null=*/!is_nullable);
  RANGES_CONTAIN_EXPECTED_CIDS(concrete_range, expected_concrete_cids);

  GrowableArray<intptr_t> expected_cids;
  expected_cids.AddArray(expected_concrete_cids);
  expected_cids.AddArray(expected_abstract_cids);
  const CidRangeVector& abstract_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/true, /*exclude_null=*/!is_nullable);
  RANGES_CONTAIN_EXPECTED_CIDS(abstract_range, expected_cids);
}

ISOLATE_UNIT_TEST_CASE(HierarchyInfo_Function_Subtype) {
  HierarchyInfo hi(thread);
  const auto& type =
      Type::Handle(IsolateGroup::Current()->object_store()->function_type());
  EXPECT(hi.CanUseSubtypeRangeCheckFor(type));
  const auto& cls = Class::Handle(type.type_class());

  GrowableArray<intptr_t> expected_concrete_cids;
  expected_concrete_cids.Add(kClosureCid);

  GrowableArray<intptr_t> expected_abstract_cids;
  expected_abstract_cids.Add(type.type_class_id());

  const CidRangeVector& concrete_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/false, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(concrete_range, expected_concrete_cids);

  GrowableArray<intptr_t> expected_cids;
  expected_cids.AddArray(expected_concrete_cids);
  expected_cids.AddArray(expected_abstract_cids);
  const CidRangeVector& abstract_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/true, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(abstract_range, expected_cids);
}

ISOLATE_UNIT_TEST_CASE(HierarchyInfo_Num_Subtype) {
  HierarchyInfo hi(thread);
  const auto& num_type = Type::Handle(Type::Number());
  const auto& int_type = Type::Handle(Type::IntType());
  const auto& double_type = Type::Handle(Type::Double());
  EXPECT(hi.CanUseSubtypeRangeCheckFor(num_type));
  const auto& cls = Class::Handle(num_type.type_class());

  GrowableArray<intptr_t> expected_concrete_cids;
  expected_concrete_cids.Add(kSmiCid);
  expected_concrete_cids.Add(kMintCid);
  expected_concrete_cids.Add(kDoubleCid);

  GrowableArray<intptr_t> expected_abstract_cids;
  expected_abstract_cids.Add(num_type.type_class_id());
  expected_abstract_cids.Add(int_type.type_class_id());
  expected_abstract_cids.Add(double_type.type_class_id());

  const CidRangeVector& concrete_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/false, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(concrete_range, expected_concrete_cids);

  GrowableArray<intptr_t> expected_cids;
  expected_cids.AddArray(expected_concrete_cids);
  expected_cids.AddArray(expected_abstract_cids);
  const CidRangeVector& abstract_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/true, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(abstract_range, expected_cids);
}

ISOLATE_UNIT_TEST_CASE(HierarchyInfo_Int_Subtype) {
  HierarchyInfo hi(thread);
  const auto& type = Type::Handle(Type::IntType());
  EXPECT(hi.CanUseSubtypeRangeCheckFor(type));
  const auto& cls = Class::Handle(type.type_class());

  GrowableArray<intptr_t> expected_concrete_cids;
  expected_concrete_cids.Add(kSmiCid);
  expected_concrete_cids.Add(kMintCid);

  GrowableArray<intptr_t> expected_abstract_cids;
  expected_abstract_cids.Add(type.type_class_id());

  const CidRangeVector& concrete_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/false, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(concrete_range, expected_concrete_cids);

  GrowableArray<intptr_t> expected_cids;
  expected_cids.AddArray(expected_concrete_cids);
  expected_cids.AddArray(expected_abstract_cids);
  const CidRangeVector& abstract_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/true, /*exclude_null=*/true);
  RANGES_CONTAIN_EXPECTED_CIDS(abstract_range, expected_cids);
}

ISOLATE_UNIT_TEST_CASE(HierarchyInfo_String_Subtype) {
  HierarchyInfo hi(thread);
  const auto& type = Type::Handle(Type::StringType());
  EXPECT(hi.CanUseSubtypeRangeCheckFor(type));
  const auto& cls = Class::Handle(type.type_class());

  GrowableArray<intptr_t> expected_concrete_cids;
  expected_concrete_cids.Add(kOneByteStringCid);
  expected_concrete_cids.Add(kTwoByteStringCid);

  GrowableArray<intptr_t> expected_abstract_cids;
  expected_abstract_cids.Add(type.type_class_id());

  const CidRangeVector& concrete_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/false, /*exclude_null=*/true);
  THR_Print("Checking concrete subtype ranges for String\n");
  RANGES_CONTAIN_EXPECTED_CIDS(concrete_range, expected_concrete_cids);

  GrowableArray<intptr_t> expected_cids;
  expected_cids.AddArray(expected_concrete_cids);
  expected_cids.AddArray(expected_abstract_cids);
  const CidRangeVector& abstract_range = hi.SubtypeRangesForClass(
      cls, /*include_abstract=*/true, /*exclude_null=*/true);
  THR_Print("Checking concrete and abstract subtype ranges for String\n");
  RANGES_CONTAIN_EXPECTED_CIDS(abstract_range, expected_cids);
}

// This test verifies that double == Smi is recognized and
// implemented using EqualityCompare.
// Regression test for https://github.com/dart-lang/sdk/issues/47031.
ISOLATE_UNIT_TEST_CASE(IRTest_DoubleEqualsSmi) {
  const char* kScript = R"(
    bool foo(double x) => (x + 0.5) == 0;
    main() {
      foo(-0.5);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  ILMatcher cursor(flow_graph, entry, /*trace=*/true,
                   ParallelMovesHandling::kSkip);

  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveBinaryDoubleOp,
      kMatchAndMoveEqualityCompare,
      kMatchDartReturn,
  }));
}

ISOLATE_UNIT_TEST_CASE(IRTest_LoadThread) {
  // clang-format off
  auto kScript = R"(
    import 'dart:ffi';

    int myFunction() {
      return 100;
    }

    void anotherFunction() {}
  )";
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Zone* const zone = Thread::Current()->zone();
  auto& invoke_result = Instance::Handle(zone);
  invoke_result ^= Invoke(root_library, "myFunction");
  EXPECT_EQ(Smi::New(100), invoke_result.ptr());

  const auto& my_function =
      Function::Handle(GetFunction(root_library, "myFunction"));

  TestPipeline pipeline(my_function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  DartReturnInstr* return_instr = nullptr;
  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        {kMatchDartReturn, &return_instr},
    }));
  }

  auto* const load_thread_instr = new (zone) LoadThreadInstr();
  flow_graph->InsertBefore(return_instr, load_thread_instr, nullptr,
                           FlowGraph::kValue);
  auto load_thread_value = Value(load_thread_instr);

  auto* const convert_instr = new (zone) IntConverterInstr(
      kUntagged, kUnboxedAddress, &load_thread_value, DeoptId::kNone);
  flow_graph->InsertBefore(return_instr, convert_instr, nullptr,
                           FlowGraph::kValue);
  auto convert_value = Value(convert_instr);

  auto* const box_instr = BoxInstr::Create(kUnboxedAddress, &convert_value);
  flow_graph->InsertBefore(return_instr, box_instr, nullptr, FlowGraph::kValue);

  return_instr->InputAt(0)->definition()->ReplaceUsesWith(box_instr);

  {
    // Check we constructed the right graph.
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
    EXPECT(cursor.TryMatch({
        kMoveGlob,
        kMatchAndMoveLoadThread,
        kMatchAndMoveIntConverter,
        kMatchAndMoveBox,
        kMatchDartReturn,
    }));
  }

  pipeline.RunForcedOptimizedAfterSSAPasses();

  {
#if !defined(PRODUCT) && !defined(USING_THREAD_SANITIZER)
    SetFlagScope<bool> sfs(&FLAG_disassemble_optimized, true);
#endif
    pipeline.CompileGraphAndAttachFunction();
  }

  // Ensure we can successfully invoke the function.
  invoke_result ^= Invoke(root_library, "myFunction");
  intptr_t result_int = Integer::Cast(invoke_result).Value();
  EXPECT_EQ(reinterpret_cast<intptr_t>(thread), result_int);
}

#if !defined(TARGET_ARCH_IA32)
ISOLATE_UNIT_TEST_CASE(IRTest_CachableIdempotentCall) {
  // clang-format off
  CStringUniquePtr kScript(OS::SCreate(nullptr, R"(
    int globalCounter = 0;

    int increment() => ++globalCounter;

    int cachedIncrement() {
      // We will replace this call with a cacheable call,
      // which will lead to the counter no longer being incremented.
      // Make sure to return the value, so we can see that the boxing and
      // unboxing works as expected.
      return increment();
    }

    int multipleIncrement() {
      int returnValue = 0;
      for(int i = 0; i < 10; i++) {
        // Save the last returned value.
        returnValue = cachedIncrement();
      }
      return returnValue;
    }
  )"));
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
  const auto& first_result =
      Object::Handle(Invoke(root_library, "multipleIncrement"));
  EXPECT(first_result.IsSmi());
  if (first_result.IsSmi()) {
    const intptr_t int_value = Smi::Cast(first_result).Value();
    EXPECT_EQ(10, int_value);
  }

  const auto& cached_increment_function =
      Function::Handle(GetFunction(root_library, "cachedIncrement"));

  const auto& increment_function =
      Function::ZoneHandle(GetFunction(root_library, "increment"));

  TestPipeline pipeline(cached_increment_function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  StaticCallInstr* static_call = nullptr;
  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        {kMatchAndMoveStaticCall, &static_call},
        kMoveGlob,
        kMatchDartReturn,
    }));
  }

  InputsArray args;
  CachableIdempotentCallInstr* call = new CachableIdempotentCallInstr(
      InstructionSource(), kUnboxedAddress, increment_function,
      static_call->type_args_len(), Array::empty_array(), std::move(args),
      DeoptId::kNone);
  static_call->ReplaceWith(call, nullptr);

  pipeline.RunForcedOptimizedAfterSSAPasses();

  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        kMatchAndMoveCachableIdempotentCall,
        kMoveGlob,
        // The cacheable call returns unboxed, so select representations
        // adds boxing.
        kMatchBox,
        kMoveGlob,
        kMatchDartReturn,
    }));
  }

  {
#if !defined(PRODUCT)
    SetFlagScope<bool> sfs(&FLAG_disassemble_optimized, true);
#endif
    pipeline.CompileGraphAndAttachFunction();
  }

  const auto& second_result =
      Object::Handle(Invoke(root_library, "multipleIncrement"));
  EXPECT(second_result.IsSmi());
  if (second_result.IsSmi()) {
    const intptr_t int_value = Smi::Cast(second_result).Value();
    EXPECT_EQ(11, int_value);
  }
}
#endif

// Helper to set up an inlined FfiCall by replacing a StaticCall.
FlowGraph* SetupFfiFlowgraph(TestPipeline* pipeline,
                             const compiler::ffi::CallMarshaller& marshaller,
                             uword native_entry,
                             bool is_leaf) {
  FlowGraph* flow_graph = pipeline->RunPasses({CompilerPass::kComputeSSA});

  {
    // Locate the placeholder call.
    StaticCallInstr* static_call = nullptr;
    {
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry(),
                       /*trace=*/false);
      cursor.TryMatch({kMoveGlob, {kMatchStaticCall, &static_call}});
    }
    RELEASE_ASSERT(static_call != nullptr);

    // Store the native entry as an unboxed constant and convert it to an
    // untagged pointer for the FfiCall.
    Zone* const Z = flow_graph->zone();
    auto* const load_entry_point = new (Z) IntConverterInstr(
        kUnboxedIntPtr, kUntagged,
        new (Z) Value(flow_graph->GetConstant(
            Integer::Handle(Z, Integer::NewCanonical(native_entry)),
            kUnboxedIntPtr)),
        DeoptId::kNone);
    flow_graph->InsertBefore(static_call, load_entry_point, /*env=*/nullptr,
                             FlowGraph::kValue);

    // Make an FfiCall based on ffi_trampoline that calls our native function.
    const intptr_t num_arguments =
        FfiCallInstr::InputCountForMarshaller(marshaller);
    RELEASE_ASSERT(num_arguments == 1);
    InputsArray arguments(num_arguments);
    arguments.Add(new (Z) Value(load_entry_point));
    auto* const ffi_call = new (Z)
        FfiCallInstr(DeoptId::kNone, marshaller, is_leaf, std::move(arguments));
    RELEASE_ASSERT(
        ffi_call->InputAt(ffi_call->TargetAddressIndex())->definition() ==
        load_entry_point);
    flow_graph->InsertBefore(static_call, ffi_call, /*env=*/nullptr,
                             FlowGraph::kEffect);

    // Remove the placeholder call.
    static_call->RemoveFromGraph(/*return_previous=*/false);
  }

  // Run remaining relevant compiler passes.
  pipeline->RunAdditionalPasses({
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      // Skipping passes that don't seem to do anything for this test.
      CompilerPass::kSelectRepresentations,
      // Skipping passes that don't seem to do anything for this test.
      CompilerPass::kTypePropagation,
      CompilerPass::kRangeAnalysis,
      // Skipping passes that don't seem to do anything for this test.
      CompilerPass::kFinalizeGraph,
      CompilerPass::kCanonicalize,
      CompilerPass::kAllocateRegisters,
      CompilerPass::kReorderBlocks,
  });

  return flow_graph;
}

// Test that FFI calls spill all live values to the stack, and that FFI leaf
// calls are free to use available ABI callee-save registers to avoid spilling.
// Additionally test that register allocation is done correctly by clobbering
// all volatile registers in the native function being called.
ISOLATE_UNIT_TEST_CASE(IRTest_FfiCallInstrLeafDoesntSpill) {
  const char* kScript = R"(
    import 'dart:ffi';

    // This is purely a placeholder and is never called.
    void placeholder() {}

    // Will call the "doFfiCall" and exercise its code.
    bool invokeDoFfiCall() {
      final double result = doFfiCall(1, 2, 3, 1.0, 2.0, 3.0);
      if (result != (2 + 3 + 4 + 2.0 + 3.0 + 4.0)) {
        throw 'Failed. Result was $result.';
      }
      return true;
    }

    // Will perform a "C" call while having live values in registers
    // across the FfiCall.
    double doFfiCall(int a, int b, int c, double x, double y, double z) {
      // Ensure there is at least one live value in a register.
      a += 1;
      b += 1;
      c += 1;
      x += 1.0;
      y += 1.0;
      z += 1.0;
      // We'll replace this StaticCall with an FfiCall.
      placeholder();
      // Use the live value.
      return (a + b + c + x + y + z);
    }

    // FFI trampoline function.
    typedef NT = Void Function();
    typedef DT = void Function();
    Pointer<NativeFunction<NT>> ptr = Pointer.fromAddress(0);
    DT getFfiTrampolineClosure() => ptr.asFunction(isLeaf:true);
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  // Build a "C" function that we can actually invoke.
  auto& c_function = Instructions::Handle(
      BuildInstructions([](compiler::Assembler* assembler) {
        // Clobber all volatile registers to make sure caller doesn't rely on
        // any non-callee-save register.
        for (intptr_t reg = 0; reg < kNumberOfFpuRegisters; reg++) {
          if ((kAbiVolatileFpuRegs & (1 << reg)) != 0) {
#if defined(TARGET_ARCH_ARM)
            // On ARM we need an extra scratch register for LoadDImmediate.
            assembler->LoadDImmediate(static_cast<DRegister>(reg), 0.0, R3);
#else
            assembler->LoadDImmediate(static_cast<FpuRegister>(reg), 0.0);
#endif
          }
        }
        for (intptr_t reg = 0; reg < kNumberOfCpuRegisters; reg++) {
          if ((kDartVolatileCpuRegs & (1 << reg)) != 0) {
            assembler->LoadImmediate(static_cast<Register>(reg), 0xDEADBEEF);
          }
        }
        assembler->Ret();
      }));
  uword native_entry = c_function.EntryPoint();

  // Get initial compilation done.
  Invoke(root_library, "invokeDoFfiCall");

  const Function& do_ffi_call =
      Function::Handle(GetFunction(root_library, "doFfiCall"));
  RELEASE_ASSERT(!do_ffi_call.IsNull());

  const auto& value = Closure::Handle(
      Closure::RawCast(Invoke(root_library, "getFfiTrampolineClosure")));
  RELEASE_ASSERT(value.IsClosure());
  const auto& ffi_trampoline =
      Function::ZoneHandle(Closure::Cast(value).function());
  RELEASE_ASSERT(!ffi_trampoline.IsNull());

  // Construct the FFICallInstr from the trampoline matching our native
  // function.
  const char* error = nullptr;
  auto* const zone = thread->zone();
  const auto& c_signature =
      FunctionType::ZoneHandle(zone, ffi_trampoline.FfiCSignature());
  const auto marshaller_ptr = compiler::ffi::CallMarshaller::FromFunction(
      zone, ffi_trampoline, /*function_params_start_at=*/1, c_signature,
      &error);
  RELEASE_ASSERT(error == nullptr);
  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;

  const auto& compile_and_run =
      [&](bool is_leaf, std::function<void(ParallelMoveInstr*)> verify) {
        // Build the SSA graph for "doFfiCall"
        TestPipeline pipeline(do_ffi_call, CompilerPass::kJIT);
        FlowGraph* flow_graph =
            SetupFfiFlowgraph(&pipeline, marshaller, native_entry, is_leaf);

        {
          ParallelMoveInstr* parallel_move = nullptr;
          ILMatcher cursor(flow_graph,
                           flow_graph->graph_entry()->normal_entry(),
                           /*trace=*/false);
          while (cursor.TryMatch(
              {kMoveGlob, {kMatchAndMoveParallelMove, &parallel_move}})) {
            verify(parallel_move);
          }
        }

        // Finish the compilation and attach code so we can run it.
        pipeline.CompileGraphAndAttachFunction();

        // Ensure we can successfully invoke the FFI call.
        auto& result = Object::Handle(Invoke(root_library, "invokeDoFfiCall"));
        RELEASE_ASSERT(result.IsBool());
        EXPECT(Bool::Cast(result).value());
      };

  intptr_t num_cpu_reg_to_stack_nonleaf = 0;
  intptr_t num_cpu_reg_to_stack_leaf = 0;
  intptr_t num_fpu_reg_to_stack_nonleaf = 0;
  intptr_t num_fpu_reg_to_stack_leaf = 0;

  // Test non-leaf spills live values.
  compile_and_run(/*is_leaf=*/false, [&](ParallelMoveInstr* parallel_move) {
    // TargetAddress is passed in register, live values are all spilled.
    for (int i = 0; i < parallel_move->NumMoves(); i++) {
      auto move = parallel_move->moves()[i];
      if (move->src_slot()->IsRegister() && move->dest_slot()->IsStackSlot()) {
        num_cpu_reg_to_stack_nonleaf++;
      } else if (move->src_slot()->IsFpuRegister() &&
                 move->dest_slot()->IsDoubleStackSlot()) {
        num_fpu_reg_to_stack_nonleaf++;
      }
    }
  });

  // Test leaf calls do not cause spills of live values.
  compile_and_run(/*is_leaf=*/true, [&](ParallelMoveInstr* parallel_move) {
    // TargetAddress is passed in registers, live values are not spilled and
    // remains in callee-save registers.
    for (int i = 0; i < parallel_move->NumMoves(); i++) {
      auto move = parallel_move->moves()[i];
      if (move->src_slot()->IsRegister() && move->dest_slot()->IsStackSlot()) {
        num_cpu_reg_to_stack_leaf++;
      } else if (move->src_slot()->IsFpuRegister() &&
                 move->dest_slot()->IsDoubleStackSlot()) {
        num_fpu_reg_to_stack_leaf++;
      }
    }
  });

  // We should have less moves to the stack (i.e. spilling) in leaf calls.
  EXPECT_LT(num_cpu_reg_to_stack_leaf, num_cpu_reg_to_stack_nonleaf);
  // We don't have volatile FPU registers on all platforms.
  const bool has_callee_save_fpu_regs =
      Utils::CountOneBitsWord(kAbiVolatileFpuRegs) <
      Utils::CountOneBitsWord(kAllFpuRegistersList);
  EXPECT(!has_callee_save_fpu_regs ||
         num_fpu_reg_to_stack_leaf < num_fpu_reg_to_stack_nonleaf);
}

static void TestConstantFoldToSmi(const Library& root_library,
                                  const char* function_name,
                                  CompilerPass::PipelineMode mode,
                                  intptr_t expected_value) {
  const auto& function =
      Function::Handle(GetFunction(root_library, function_name));

  TestPipeline pipeline(function, mode);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  DartReturnInstr* ret = nullptr;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchDartReturn, &ret},
  }));

  ConstantInstr* constant = ret->value()->definition()->AsConstant();
  EXPECT(constant != nullptr);
  if (constant != nullptr) {
    const Object& value = constant->value();
    EXPECT(value.IsSmi());
    if (value.IsSmi()) {
      const intptr_t int_value = Smi::Cast(value).Value();
      EXPECT_EQ(expected_value, int_value);
    }
  }
}

ISOLATE_UNIT_TEST_CASE(ConstantFold_bitLength) {
  // clang-format off
  auto kScript = R"(
      b0() => 0. bitLength;  // 0...00000
      b1() => 1. bitLength;  // 0...00001
      b100() => 100. bitLength;
      b200() => 200. bitLength;
      bffff() => 0xffff. bitLength;
      m1() => (-1).bitLength;  // 1...11111
      m2() => (-2).bitLength;  // 1...11110

      main() {
        b0();
        b1();
        b100();
        b200();
        bffff();
        m1();
        m2();
      }
    )";
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "main");

  auto test = [&](const char* function, intptr_t expected) {
    TestConstantFoldToSmi(root_library, function, CompilerPass::kJIT, expected);
    TestConstantFoldToSmi(root_library, function, CompilerPass::kAOT, expected);
  };

  test("b0", 0);
  test("b1", 1);
  test("b100", 7);
  test("b200", 8);
  test("bffff", 16);
  test("m1", 0);
  test("m2", 1);
}

static void TestRepresentationChangeDuringCanonicalization(
    Thread* thread,
    bool allow_representation_change) {
  using compiler::BlockBuilder;

  const auto& lib = Library::Handle(Library::CoreLibrary());
  const Class& list_class =
      Class::Handle(lib.LookupClassAllowPrivate(Symbols::_List()));
  EXPECT(!list_class.IsNull());
  const Error& err = Error::Handle(list_class.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());
  const Function& list_filled = Function::ZoneHandle(
      list_class.LookupFactoryAllowPrivate(Symbols::_ListFilledFactory()));
  EXPECT(!list_filled.IsNull());

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H(/*num_parameters=*/1);
  H.AddVariable("param", AbstractType::ZoneHandle(Type::IntType()));

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();

  Definition* param = nullptr;
  LoadFieldInstr* load = nullptr;
  UnboxInstr* unbox = nullptr;
  Definition* add = nullptr;
  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    param = builder.AddParameter(0, kUnboxedInt64);

    InputsArray args;
    args.Add(new Value(H.flow_graph()->constant_null()));
    args.Add(new Value(param));
    args.Add(new Value(H.IntConstant(0)));
    StaticCallInstr* array = builder.AddDefinition(new StaticCallInstr(
        InstructionSource(), list_filled, 1, Array::empty_array(),
        std::move(args), DeoptId::kNone, 0, ICData::kNoRebind));
    array->UpdateType(CompileType::FromCid(kArrayCid));
    array->SetResultType(thread->zone(), CompileType::FromCid(kArrayCid));
    array->set_is_known_list_constructor(true);

    load = builder.AddDefinition(new LoadFieldInstr(
        new Value(array), Slot::Array_length(), InstructionSource()));

    unbox = builder.AddDefinition(new UnboxInt64Instr(
        new Value(load), DeoptId::kNone, Instruction::kNotSpeculative));

    add = builder.AddDefinition(new BinaryInt64OpInstr(
        Token::kADD, new Value(unbox), new Value(H.IntConstant(1)),
        S.GetNextDeoptId(), Instruction::kNotSpeculative));

    Definition* box = builder.AddDefinition(new BoxInt64Instr(new Value(add)));

    builder.AddReturn(new Value(box));
  }

  H.FinishGraph();

  if (!allow_representation_change) {
    H.flow_graph()->disallow_unmatched_representations();
  }

  H.flow_graph()->Canonicalize();

  if (allow_representation_change) {
    EXPECT(add->InputAt(0)->definition() == param);
  } else {
    EXPECT(add->InputAt(0)->definition() == unbox);
    EXPECT(unbox->value()->definition() == load);
  }
}

ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_RepresentationChange) {
  TestRepresentationChangeDuringCanonicalization(thread, true);
  TestRepresentationChangeDuringCanonicalization(thread, false);
}

enum TypeDataField {
  TypedDataBase_length,
  TypedDataView_offset_in_bytes,
  TypedDataView_typed_data,
};

static void TestCanonicalizationOfTypedDataViewFieldLoads(
    Thread* thread,
    TypeDataField field_kind) {
  const auto& typed_data_lib = Library::Handle(Library::TypedDataLibrary());
  const auto& view_cls = Class::Handle(
      typed_data_lib.LookupClassAllowPrivate(Symbols::_Float32ArrayView()));
  const Error& err = Error::Handle(view_cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());
  const auto& factory =
      Function::ZoneHandle(view_cls.LookupFactoryAllowPrivate(String::Handle(
          String::Concat(Symbols::_Float32ArrayView(), Symbols::DotUnder()))));
  EXPECT(!factory.IsNull());

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  const Slot* field = nullptr;
  switch (field_kind) {
    case TypedDataBase_length:
      field = &Slot::TypedDataBase_length();
      break;
    case TypedDataView_offset_in_bytes:
      field = &Slot::TypedDataView_offset_in_bytes();
      break;
    case TypedDataView_typed_data:
      field = &Slot::TypedDataView_typed_data();
      break;
  }

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  const auto constant_4 = H.IntConstant(4);
  const auto constant_1 = H.IntConstant(1);

  Definition* array;
  Definition* load;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    // array <- AllocateTypedData(1)
    array = builder.AddDefinition(new AllocateTypedDataInstr(
        InstructionSource(), kTypedDataFloat64ArrayCid, new Value(constant_1),
        DeoptId::kNone));
    // view <- StaticCall(_Float32ArrayView._, null, array, 4, 1)
    const auto view = builder.AddDefinition(new StaticCallInstr(
        InstructionSource(), factory, 1, Array::empty_array(),
        {new Value(H.flow_graph()->constant_null()), new Value(array),
         new Value(constant_4), new Value(constant_1)},
        DeoptId::kNone, 1, ICData::RebindRule::kStatic));
    // array_alias <- LoadField(view.length)
    load = builder.AddDefinition(
        new LoadFieldInstr(new Value(view), *field, InstructionSource()));
    // Return(load)
    ret = builder.AddReturn(new Value(load));
  }
  H.FinishGraph();
  H.flow_graph()->Canonicalize();

  switch (field_kind) {
    case TypedDataBase_length:
      EXPECT_PROPERTY(ret->value()->definition(), &it == constant_1);
      break;
    case TypedDataView_offset_in_bytes:
      EXPECT_PROPERTY(ret->value()->definition(), &it == constant_4);
      break;
    case TypedDataView_typed_data:
      EXPECT_PROPERTY(ret->value()->definition(), &it == array);
      break;
  }
}

ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_TypedDataViewFactory) {
  TestCanonicalizationOfTypedDataViewFieldLoads(thread, TypedDataBase_length);
  TestCanonicalizationOfTypedDataViewFieldLoads(thread,
                                                TypedDataView_offset_in_bytes);
  TestCanonicalizationOfTypedDataViewFieldLoads(thread,
                                                TypedDataView_typed_data);
}

// Check that canonicalize can devirtualize InstanceCall based on type
// information in AOT mode.
ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_InstanceCallWithNoICDataInAOT) {
  const auto& typed_data_lib = Library::Handle(Library::TypedDataLibrary());
  const auto& view_cls = Class::Handle(typed_data_lib.LookupClassAllowPrivate(
      String::Handle(Symbols::New(thread, "_TypedListBase"))));
  const Error& err = Error::Handle(view_cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());
  const auto& getter = Function::Handle(
      view_cls.LookupFunctionAllowPrivate(Symbols::GetLength()));
  EXPECT(!getter.IsNull());

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  InstanceCallInstr* length_call;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    // array <- AllocateTypedData(1)
    const auto array = builder.AddDefinition(new AllocateTypedDataInstr(
        InstructionSource(), kTypedDataFloat64ArrayCid,
        new Value(H.IntConstant(1)), DeoptId::kNone));
    // length_call <- InstanceCall('get:length', array, ICData[])
    length_call = builder.AddDefinition(new InstanceCallInstr(
        InstructionSource(), Symbols::GetLength(), Token::kGET,
        /*args=*/{new Value(array)}, 0, Array::empty_array(), 1,
        /*deopt_id=*/42));
    length_call->EnsureICData(H.flow_graph());
    // Return(load)
    ret = builder.AddReturn(new Value(length_call));
  }
  H.FinishGraph();
  H.flow_graph()->Canonicalize();

  EXPECT_PROPERTY(length_call, it.previous() == nullptr);
  EXPECT_PROPERTY(ret->value()->definition(), it.IsStaticCall());
  EXPECT_PROPERTY(ret->value()->definition()->AsStaticCall(),
                  it.function().ptr() == getter.ptr());
}

static void TestTestRangeCanonicalize(const AbstractType& type,
                                      uword lower,
                                      uword upper,
                                      bool result) {
  using compiler::BlockBuilder;
  CompilerState S(Thread::Current(), /*is_aot=*/true, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H(/*num_parameters=*/1);
  H.AddVariable("v0", type);

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();

  DartReturnInstr* ret;
  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    Definition* param = builder.AddParameter(0, kTagged);
    Definition* load_cid =
        builder.AddDefinition(new LoadClassIdInstr(new Value(param)));
    Definition* test_range = builder.AddDefinition(new TestRangeInstr(
        InstructionSource(), new Value(load_cid), lower, upper, kTagged));
    ret = builder.AddReturn(new Value(test_range));
  }
  H.FinishGraph();
  H.flow_graph()->Canonicalize();

  EXPECT_PROPERTY(ret, it.value()->BindsToConstant());
  EXPECT_PROPERTY(ret,
                  it.value()->BoundConstant().ptr() == Bool::Get(result).ptr());
}

ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_TestRange) {
  HierarchyInfo hierarchy_info(thread);
  TestTestRangeCanonicalize(AbstractType::ZoneHandle(Type::IntType()),
                            kOneByteStringCid, kTwoByteStringCid, false);
  TestTestRangeCanonicalize(AbstractType::ZoneHandle(Type::IntType()), kSmiCid,
                            kMintCid, true);
  TestTestRangeCanonicalize(AbstractType::ZoneHandle(Type::NullType()), kSmiCid,
                            kMintCid, false);
  TestTestRangeCanonicalize(AbstractType::ZoneHandle(Type::Double()), kSmiCid,
                            kMintCid, false);
  TestTestRangeCanonicalize(AbstractType::ZoneHandle(Type::ObjectType()), 1,
                            kClassIdTagMax, true);
}

void TestStaticFieldForwarding(Thread* thread,
                               const Class& test_cls,
                               const Field& field,
                               intptr_t num_stores,
                               bool expected_to_forward) {
  EXPECT(num_stores <= 2);

  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  const auto constant_42 = H.IntConstant(42);
  const auto constant_24 = H.IntConstant(24);
  Definition* load;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    // obj <- AllocateObject(TestClass)
    const auto obj = builder.AddDefinition(
        new AllocateObjectInstr(InstructionSource(), test_cls, DeoptId::kNone));

    if (num_stores >= 1) {
      // StoreField(o.field = 42)
      builder.AddInstruction(new StoreFieldInstr(
          field, new Value(obj), new Value(constant_42),
          StoreBarrierType::kNoStoreBarrier, InstructionSource(),
          &H.flow_graph()->parsed_function(),
          StoreFieldInstr::Kind::kInitializing));
    }

    if (num_stores >= 2) {
      // StoreField(o.field = 24)
      builder.AddInstruction(new StoreFieldInstr(
          field, new Value(obj), new Value(constant_24),
          StoreBarrierType::kNoStoreBarrier, InstructionSource(),
          &H.flow_graph()->parsed_function()));
    }

    // load <- LoadField(view.field)
    load = builder.AddDefinition(new LoadFieldInstr(
        new Value(obj), Slot::Get(field, &H.flow_graph()->parsed_function()),
        InstructionSource()));

    // Return(load)
    ret = builder.AddReturn(new Value(load));
  }
  H.FinishGraph();
  H.flow_graph()->Canonicalize();

  if (expected_to_forward) {
    EXPECT_PROPERTY(ret->value()->definition(), &it == constant_42);
  } else {
    EXPECT_PROPERTY(ret->value()->definition(), &it == load);
  }
}

ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_FinalFieldForwarding) {
  const char* script_chars = R"(
    import 'dart:typed_data';

    class TestClass {
      final dynamic finalField;
      late final dynamic lateFinalField;
      dynamic normalField;

      TestClass(this.finalField, this.lateFinalField, this.normalField);
    }
  )";
  const auto& lib = Library::Handle(LoadTestScript(script_chars));

  const auto& test_cls = Class::ZoneHandle(
      lib.LookupClass(String::Handle(Symbols::New(thread, "TestClass"))));
  const auto& err = Error::Handle(test_cls.EnsureIsFinalized(thread));
  EXPECT(err.IsNull());

  const auto lookup_field = [&](const char* name) -> const Field& {
    const auto& original_field = Field::Handle(
        test_cls.LookupField(String::Handle(Symbols::New(thread, name))));
    EXPECT(!original_field.IsNull());
    return Field::Handle(original_field.CloneFromOriginal());
  };

  const auto& final_field = lookup_field("finalField");
  const auto& late_final_field = lookup_field("lateFinalField");
  const auto& normal_field = lookup_field("normalField");

  TestStaticFieldForwarding(thread, test_cls, final_field, /*num_stores=*/0,
                            /*expected_to_forward=*/false);
  TestStaticFieldForwarding(thread, test_cls, final_field, /*num_stores=*/1,
                            /*expected_to_forward=*/true);
  TestStaticFieldForwarding(thread, test_cls, final_field, /*num_stores=*/2,
                            /*expected_to_forward=*/false);

  TestStaticFieldForwarding(thread, test_cls, late_final_field,
                            /*num_stores=*/0, /*expected_to_forward=*/false);
  TestStaticFieldForwarding(thread, test_cls, late_final_field,
                            /*num_stores=*/1, /*expected_to_forward=*/false);
  TestStaticFieldForwarding(thread, test_cls, late_final_field,
                            /*num_stores=*/2, /*expected_to_forward=*/false);

  TestStaticFieldForwarding(thread, test_cls, normal_field, /*num_stores=*/0,
                            /*expected_to_forward=*/false);
  TestStaticFieldForwarding(thread, test_cls, normal_field, /*num_stores=*/1,
                            /*expected_to_forward=*/false);
  TestStaticFieldForwarding(thread, test_cls, normal_field, /*num_stores=*/2,
                            /*expected_to_forward=*/false);
}

void TestBoxIntegerUnboxedConstantCanonicalization(Thread* thread,
                                                   int64_t value,
                                                   Representation constant_rep,
                                                   Representation from_rep,
                                                   bool should_canonicalize) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  auto* const unboxed_constant = H.IntConstant(value, constant_rep);
  auto* const boxed_constant = H.IntConstant(value);

  BoxInstr* box;
  DartReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    box = builder.AddDefinition(
        BoxInstr::Create(from_rep, new Value(unboxed_constant)));

    ret = builder.AddReturn(new Value(box));
  }
  H.FinishGraph();
  H.flow_graph()->Canonicalize();

  if (should_canonicalize) {
    EXPECT_PROPERTY(ret->value()->definition(), &it == boxed_constant);
    EXPECT_PROPERTY(box, !it.HasUses());
  } else {
    EXPECT_PROPERTY(ret->value()->definition(), &it == box);
  }
}

// Check that canonicalize can replace BoxInteger<from>(UnboxedConstant<to>(v))
// with v if v is representable in from, and does not if it is not.
ISOLATE_UNIT_TEST_CASE(IL_Canonicalize_BoxIntegerUnboxedConstant) {
  // kUnboxedInt8
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 0, kUnboxedInt8,
                                                kUnboxedInt8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 1, kUnboxedInt8,
                                                kUnboxedInt8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, -1, kUnboxedInt8,
                                                kUnboxedInt8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt8, kUnboxedInt8,
                                                kUnboxedInt8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt8, kUnboxedInt8,
                                                kUnboxedInt8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint8,
                                                kUnboxedUint8, kUnboxedInt8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt32,
                                                kUnboxedInt32, kUnboxedInt8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt32,
                                                kUnboxedInt32, kUnboxedInt8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedUint32, kUnboxedInt8,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMinInt32) - 1, kUnboxedInt32, kUnboxedInt8,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint32,
                                                kUnboxedUint32, kUnboxedInt8,
                                                /*should_canonicalize=*/false);

  // kUnboxedUint8
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 0, kUnboxedInt8,
                                                kUnboxedUint8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 1, kUnboxedInt8,
                                                kUnboxedUint8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, -1, kUnboxedInt8,
                                                kUnboxedUint8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt8, kUnboxedInt8,
                                                kUnboxedUint8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt8, kUnboxedInt8,
                                                kUnboxedUint8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint8,
                                                kUnboxedUint8, kUnboxedUint8,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt32,
                                                kUnboxedInt32, kUnboxedUint8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt32,
                                                kUnboxedInt32, kUnboxedUint8,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedUint32,
      kUnboxedUint8,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMinInt32) - 1, kUnboxedInt32, kUnboxedUint8,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint32,
                                                kUnboxedUint32, kUnboxedUint8,
                                                /*should_canonicalize=*/false);

  // kUnboxedInt32
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 0, kUnboxedInt8,
                                                kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 1, kUnboxedInt8,
                                                kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, -1, kUnboxedInt8,
                                                kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt8, kUnboxedInt8,
                                                kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt8, kUnboxedInt8,
                                                kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint8,
                                                kUnboxedUint8, kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt32,
                                                kUnboxedInt32, kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt32,
                                                kUnboxedInt32, kUnboxedInt32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedUint32,
      kUnboxedInt32,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMinInt32) - 1, kUnboxedInt32, kUnboxedInt32,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint32,
                                                kUnboxedUint32, kUnboxedInt32,
                                                /*should_canonicalize=*/false);

  // kUnboxedUint32
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 0, kUnboxedInt8,
                                                kUnboxedUint32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 1, kUnboxedInt8,
                                                kUnboxedUint32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, -1, kUnboxedInt8,
                                                kUnboxedUint32,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt8, kUnboxedInt8,
                                                kUnboxedUint32,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt8, kUnboxedInt8,
                                                kUnboxedUint32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint8,
                                                kUnboxedUint8, kUnboxedUint32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt32,
                                                kUnboxedInt32, kUnboxedUint32,
                                                /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt32,
                                                kUnboxedInt32, kUnboxedUint32,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedInt32,
      kUnboxedUint32,
      /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMinInt32) - 1, kUnboxedInt32,
      kUnboxedUint32,
      /*should_canonicalize=*/false);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint32,
                                                kUnboxedUint32, kUnboxedUint32,
                                                /*should_canonicalize=*/true);

  // kUnboxedInt64
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 0, kUnboxedInt8,
                                                kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, 1, kUnboxedInt8,
                                                kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, -1, kUnboxedInt8,
                                                kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt8, kUnboxedInt8,
                                                kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt8, kUnboxedInt8,
                                                kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint8,
                                                kUnboxedUint8, kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMinInt32,
                                                kUnboxedInt32, kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxInt32,
                                                kUnboxedInt32, kUnboxedInt64,
                                                /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedInt32, kUnboxedInt64,
      /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(
      thread, static_cast<int64_t>(kMinInt32) - 1, kUnboxedInt32, kUnboxedInt64,
      /*should_canonicalize=*/true);
  TestBoxIntegerUnboxedConstantCanonicalization(thread, kMaxUint32,
                                                kUnboxedUint32, kUnboxedInt64,
                                                /*should_canonicalize=*/true);
}

template <typename... Args>
static ObjectPtr InvokeFunction(const Function& function, Args&... args) {
  const Array& args_array = Array::Handle(Array::New(sizeof...(Args)));
  intptr_t i = 0;
  (args_array.SetAt(i++, args), ...);
  return DartEntry::InvokeFunction(function, args_array);
}

static const Function& BuildTestFunction(
    intptr_t num_parameters,
    std::function<void(FlowGraphBuilderHelper&)> build_graph) {
  using compiler::BlockBuilder;

  TestPipeline pipeline(CompilerPass::kAOT, [&]() {
    FlowGraphBuilderHelper H(num_parameters);
    build_graph(H);
    H.FinishGraph();
    return H.flow_graph();
  });
  auto flow_graph = pipeline.RunPasses({
      CompilerPass::kFinalizeGraph,
      CompilerPass::kReorderBlocks,
      CompilerPass::kAllocateRegisters,
  });
  pipeline.CompileGraphAndAttachFunction();
  return flow_graph->function();
}

enum class TestIntVariant {
  kTestBranch,
  kTestValue,
};

static const Function& BuildTestIntFunction(
    Zone* zone,
    TestIntVariant test_variant,
    bool eq_zero,
    Representation rep,
    std::optional<int64_t> immediate_mask) {
  using compiler::BlockBuilder;
  return BuildTestFunction(
      /*num_parameters=*/1 + (!immediate_mask.has_value() ? 1 : 0),
      [&](auto& H) {
        H.AddVariable("lhs", AbstractType::ZoneHandle(Type::IntType()),
                      new CompileType(CompileType::Int()));
        if (!immediate_mask.has_value()) {
          H.AddVariable("rhs", AbstractType::ZoneHandle(Type::IntType()),
                        new CompileType(CompileType::Int()));
        }

        auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
        auto true_successor = H.TargetEntry();
        auto false_successor = H.TargetEntry();

        {
          BlockBuilder builder(H.flow_graph(), normal_entry);
          Definition* lhs = builder.AddParameter(0);
          Definition* rhs = immediate_mask.has_value()
                                ? H.IntConstant(immediate_mask.value(), rep)
                                : builder.AddParameter(1);
          if (rep != lhs->representation()) {
            lhs =
                builder.AddUnboxInstr(kUnboxedInt64, lhs, /*is_checked=*/false);
          }
          if (rep != rhs->representation()) {
            rhs =
                builder.AddUnboxInstr(kUnboxedInt64, rhs, /*is_checked=*/false);
          }

          auto comparison = new TestIntInstr(
              InstructionSource(), eq_zero ? Token::kEQ : Token::kNE, rep,
              new Value(lhs), new Value(rhs));

          if (test_variant == TestIntVariant::kTestValue) {
            auto v2 = builder.AddDefinition(comparison);
            builder.AddReturn(new Value(v2));
          } else {
            builder.AddBranch(comparison, true_successor, false_successor);
          }
        }

        if (test_variant == TestIntVariant::kTestBranch) {
          {
            BlockBuilder builder(H.flow_graph(), true_successor);
            builder.AddReturn(
                new Value(H.flow_graph()->GetConstant(Bool::True())));
          }

          {
            BlockBuilder builder(H.flow_graph(), false_successor);
            builder.AddReturn(
                new Value(H.flow_graph()->GetConstant(Bool::False())));
          }
        }
      });
}

static void TestIntTestWithImmediate(Zone* zone,
                                     TestIntVariant test_variant,
                                     bool eq_zero,
                                     Representation rep,
                                     const std::vector<int64_t>& inputs,
                                     int64_t mask) {
  const auto& func =
      BuildTestIntFunction(zone, test_variant, eq_zero, rep, mask);
  auto invoke = [&](int64_t v) -> bool {
    const auto& input = Integer::Handle(Integer::New(v));
    EXPECT(rep == kUnboxedInt64 || input.IsSmi());
    const auto& result = Bool::CheckedHandle(zone, InvokeFunction(func, input));
    return result.value();
  };

  for (auto& input : inputs) {
    const auto expected = ((input & mask) == 0) == eq_zero;
    const auto got = invoke(input);
    if (expected != got) {
      FAIL("testing [%s] [%s] %" Px64 " & %" Px64
           " %s 0: expected %s but got %s\n",
           test_variant == TestIntVariant::kTestBranch ? "branch" : "value",
           RepresentationUtils::ToCString(rep), input, mask,
           eq_zero ? "==" : "!=", expected ? "true" : "false",
           got ? "true" : "false");
    }
  }
}

static void TestIntTest(Zone* zone,
                        TestIntVariant test_variant,
                        bool eq_zero,
                        Representation rep,
                        const std::vector<int64_t>& inputs,
                        const std::vector<int64_t>& masks) {
  if (!TestIntInstr::IsSupported(rep)) {
    return;
  }

  const auto& func = BuildTestIntFunction(zone, test_variant, eq_zero, rep, {});
  auto invoke = [&](int64_t lhs, int64_t mask) -> bool {
    const auto& arg0 = Integer::Handle(Integer::New(lhs));
    const auto& arg1 = Integer::Handle(Integer::New(mask));
    EXPECT(rep == kUnboxedInt64 || arg0.IsSmi());
    EXPECT(rep == kUnboxedInt64 || arg1.IsSmi());
    const auto& result =
        Bool::CheckedHandle(zone, InvokeFunction(func, arg0, arg1));
    return result.value();
  };

  for (auto& mask : masks) {
    TestIntTestWithImmediate(zone, test_variant, eq_zero, rep, inputs, mask);

    // We allow non-Smi masks as immediates but not as non-constant operands.
    if (rep == kTagged && !Smi::IsValid(mask)) {
      continue;
    }

    for (auto& input : inputs) {
      const auto expected = ((input & mask) == 0) == eq_zero;
      const auto got = invoke(input, mask);
      if (expected != got) {
        FAIL("testing [%s] [%s] %" Px64 " & %" Px64
             " %s 0: expected %s but got %s\n",
             test_variant == TestIntVariant::kTestBranch ? "branch" : "value",
             RepresentationUtils::ToCString(rep), input, mask,
             eq_zero ? "==" : "!=", expected ? "true" : "false",
             got ? "true" : "false");
      }
    }
  }
}

ISOLATE_UNIT_TEST_CASE(IL_TestIntInstr) {
  const int64_t msb = static_cast<int64_t>(0x8000000000000000L);
  const int64_t kSmiSignBit = kSmiMax + 1;

  const std::initializer_list<int64_t> kMasks = {
      1, 2, kSmiSignBit, kSmiSignBit | 1, msb, msb | 1};

  const std::vector<std::pair<Representation, std::vector<int64_t>>> kValues = {
      {kTagged,
       {-2, -1, 0, 1, 2, 3, kSmiMax & ~1, kSmiMin & ~1, kSmiMax | 1,
        kSmiMin | 1}},
      {kUnboxedInt64,
       {-2, -1, 0, 1, 2, 3, kSmiMax & ~1, kSmiMin & ~1, kSmiMax | 1,
        kSmiMin | 1, msb, msb | 1, msb | 2}},
  };

  for (auto test_variant :
       {TestIntVariant::kTestBranch, TestIntVariant::kTestValue}) {
    for (auto eq_zero : {true, false}) {
      for (auto& [rep, values] : kValues) {
        TestIntTest(thread->zone(), test_variant, eq_zero, rep, values, kMasks);
      }
    }
  }
}

// This is a smoke test which verifies that RecordCoverage instruction is not
// accidentally removed by some overly eager optimization.
ISOLATE_UNIT_TEST_CASE(IL_RecordCoverageSurvivesOptimizations) {
  using compiler::BlockBuilder;
  SetFlagScope<bool> sfs(&FLAG_reorder_basic_blocks, false);

  TestPipeline pipeline(CompilerPass::kJIT, [&]() {
    FlowGraphBuilderHelper H(/*num_parameters=*/0);

    {
      BlockBuilder builder(H.flow_graph(),
                           H.flow_graph()->graph_entry()->normal_entry());
      const auto& coverage_array = Array::Handle(Array::New(1));
      coverage_array.SetAt(0, Smi::Handle(Smi::New(0)));
      builder.AddInstruction(
          new RecordCoverageInstr(coverage_array, 0, InstructionSource()));
      builder.AddReturn(new Value(H.flow_graph()->constant_null()));
    }

    H.FinishGraph();
    return H.flow_graph();
  });

  auto flow_graph = pipeline.RunPasses({});

  // RecordCoverage instruction should remain in the graph.
  EXPECT(flow_graph->graph_entry()->normal_entry()->next()->IsRecordCoverage());
}

// This test verifies that the ASSERT in Assembler::ElementAddressForIntIndex
// appropriately accounts for the heap object tag to check the displacement.
// Regression test for https://github.com/dart-lang/sdk/issues/56588.
ISOLATE_UNIT_TEST_CASE(IRTest_Regress_56588) {
  TestPipeline pipeline(CompilerPass::kAOT, [&]() {
    FlowGraphBuilderHelper H(1);

    const classid_t cid = kTypedDataUint8ClampedArrayCid;
    // Must not be a view or an external cid, so that the untagged address
    // isn't extracted first.
    EXPECT(IsTypedDataClassId(cid));
    const intptr_t index_scale = 1;
    // Set the constant index such that the displacement is not a signed 32-bit
    // integer unless the displacement also takes into account that the
    // base address is tagged.
    const int64_t constant_index =
        static_cast<int64_t>(kMaxInt32) + kHeapObjectTag -
        compiler::target::Instance::DataOffsetFor(cid);

    // Double-check that we chose such an index correctly.
    const int64_t disp = constant_index * index_scale +
                         compiler::target::Instance::DataOffsetFor(cid);
    EXPECT(!Utils::IsInt(32, disp));
    EXPECT(Utils::IsInt(32, disp - kHeapObjectTag));

    const auto& cls =
        Class::Handle(IsolateGroup::Current()->class_table()->At(cid));
    ASSERT(!cls.IsNull());
    auto& type =
        AbstractType::ZoneHandle(Type::New(cls, Object::null_type_arguments()));
    type = ClassFinalizer::FinalizeType(type);

    H.AddVariable("arg", type);

    auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();

    {
      compiler::BlockBuilder builder(H.flow_graph(), normal_entry);
      Definition* const array = builder.AddParameter(0);
      auto* const index = H.IntConstant(constant_index, kUnboxedInt64);
      auto* const deref = builder.AddDefinition(new LoadIndexedInstr(
          new Value(array), new Value(index),
          index->representation() != kTagged, index_scale, cid, kAlignedAccess,
          CompilerState::Current().GetNextDeoptId(), InstructionSource()));
      builder.AddReturn(new Value(deref));
    }
    H.FinishGraph();
    return H.flow_graph();
  });
  pipeline.RunPasses({});
  pipeline.CompileGraphAndAttachFunction();
}

}  // namespace dart
