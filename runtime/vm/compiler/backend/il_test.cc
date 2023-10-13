// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il.h"

#include <vector>

#include "platform/text_buffer.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/compiler/backend/block_builder.h"
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
  SpecialParameterInstr* context = new SpecialParameterInstr(
      SpecialParameterInstr::kContext, DeoptId::kNone, target_instr);
  EXPECT(context->IsDefinition());
  EXPECT(!context->IsBlockEntry());
  EXPECT(context->GetBlock() == target_instr);
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
  const char* nullable_tag = TestCase::NullableTag();
  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
      class Container<T> {
        operator []=(var index, var value) {
          return data[index] = value;
        }

        List<T%s> data = List<T%s>.filled(10, null);
      }

      Container<int> x = Container<int>();

      foo() {
        for (int i = 0; i < 10; ++i) {
          x[i] = i;
        }
      }
    )", nullable_tag, nullable_tag), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
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
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
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
    f4<T>({T%s value}) {
      return () { return value; };
    }
    main() {
      f1();
      f2();
      f3();
      f4();
    }
  )",
  TestCase::NullableTag()), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
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
  ReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, 0, /*with_frame=*/true, initial);
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
  ReturnInstr* ret;
  PhiInstr* phi;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, 0, /*with_frame=*/true, kTagged);
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

    Definition* float64_array =
        builder.AddParameter(0, 0, /*with_frame=*/true, kTagged);
    Definition* int64_array =
        builder.AddParameter(1, 1, /*with_frame=*/true, kTagged);

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
    Definition* v0 =
        builder.AddParameter(0, 0, /*with_frame=*/true, kUnboxedInt64);
    Definition* v1 =
        builder.AddParameter(1, 1, /*with_frame=*/true, kUnboxedInt64);
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
  expected_concrete_cids.Add(kExternalOneByteStringCid);
  expected_concrete_cids.Add(kExternalTwoByteStringCid);

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
      kMatchReturn,
  }));
}

#ifdef DART_TARGET_OS_WINDOWS
const char* pointer_prefix = "0x";
#else
const char* pointer_prefix = "";
#endif

ISOLATE_UNIT_TEST_CASE(IRTest_RawStoreField) {
  InstancePtr ptr = Smi::New(100);
  OS::Print("&ptr %p\n", &ptr);

  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
    import 'dart:ffi';

    void myFunction() {
      final pointer = Pointer<IntPtr>.fromAddress(%s%p);
      anotherFunction();
    }

    void anotherFunction() {}
  )", pointer_prefix, &ptr), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
  Invoke(root_library, "myFunction");
  EXPECT_EQ(Smi::New(100), ptr);

  const auto& my_function =
      Function::Handle(GetFunction(root_library, "myFunction"));

  TestPipeline pipeline(my_function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  Zone* const zone = Thread::Current()->zone();

  StaticCallInstr* pointer = nullptr;
  StaticCallInstr* another_function_call = nullptr;
  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        {kMatchAndMoveStaticCall, &pointer},
        {kMatchAndMoveStaticCall, &another_function_call},
    }));
  }
  auto pointer_value = Value(pointer);
  auto* const load_untagged_instr = new (zone) LoadUntaggedInstr(
      &pointer_value, compiler::target::PointerBase::data_offset());
  flow_graph->InsertBefore(another_function_call, load_untagged_instr, nullptr,
                           FlowGraph::kValue);
  auto load_untagged_value = Value(load_untagged_instr);
  auto pointer_value2 = Value(pointer);
  auto* const raw_store_field_instr =
      new (zone) RawStoreFieldInstr(&load_untagged_value, &pointer_value2, 0);
  flow_graph->InsertBefore(another_function_call, raw_store_field_instr,
                           nullptr, FlowGraph::kEffect);
  another_function_call->RemoveFromGraph();

  {
    // Check we constructed the right graph.
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
    EXPECT(cursor.TryMatch({
        kMoveGlob,
        kMatchAndMoveStaticCall,
        kMatchAndMoveLoadUntagged,
        kMatchAndMoveRawStoreField,
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
  Invoke(root_library, "myFunction");

  // Might be garbage if we ran a GC, but should never be a Smi.
  EXPECT(!ptr.IsSmi());
}

// We do not have a RawLoadFieldInstr, instead we just use LoadIndexed for
// loading from outside the heap.
//
// This test constructs to instructions from FlowGraphBuilder::RawLoadField
// and exercises them to do a load from outside the heap.
ISOLATE_UNIT_TEST_CASE(IRTest_RawLoadField) {
  InstancePtr ptr = Smi::New(100);
  intptr_t ptr2 = 100;
  OS::Print("&ptr %p &ptr2 %p\n", &ptr, &ptr2);

  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
    import 'dart:ffi';

    void myFunction() {
      final pointer = Pointer<IntPtr>.fromAddress(%s%p);
      anotherFunction();
      final pointer2 = Pointer<IntPtr>.fromAddress(%s%p);
      pointer2.value = 3;
    }

    void anotherFunction() {}
  )", pointer_prefix, &ptr, pointer_prefix, &ptr2), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));
  Invoke(root_library, "myFunction");
  EXPECT_EQ(Smi::New(100), ptr);
  EXPECT_EQ(3, ptr2);

  const auto& my_function =
      Function::Handle(GetFunction(root_library, "myFunction"));

  TestPipeline pipeline(my_function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  Zone* const zone = Thread::Current()->zone();

  StaticCallInstr* pointer = nullptr;
  StaticCallInstr* another_function_call = nullptr;
  StaticCallInstr* pointer2 = nullptr;
  StaticCallInstr* pointer2_store = nullptr;
  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        {kMatchAndMoveStaticCall, &pointer},
        {kMatchAndMoveStaticCall, &another_function_call},
        {kMatchAndMoveStaticCall, &pointer2},
        {kMatchAndMoveStaticCall, &pointer2_store},
    }));
  }
  auto pointer_value = Value(pointer);
  auto* const load_untagged_instr = new (zone) LoadUntaggedInstr(
      &pointer_value, compiler::target::PointerBase::data_offset());
  flow_graph->InsertBefore(another_function_call, load_untagged_instr, nullptr,
                           FlowGraph::kValue);
  auto load_untagged_value = Value(load_untagged_instr);
  auto* const constant_instr = new (zone) UnboxedConstantInstr(
      Integer::ZoneHandle(zone, Integer::New(0, Heap::kOld)), kUnboxedIntPtr);
  flow_graph->InsertBefore(another_function_call, constant_instr, nullptr,
                           FlowGraph::kValue);
  auto constant_value = Value(constant_instr);
  auto* const load_indexed_instr = new (zone)
      LoadIndexedInstr(&load_untagged_value, &constant_value,
                       /*index_unboxed=*/true, /*index_scale=*/1, kArrayCid,
                       kAlignedAccess, DeoptId::kNone, InstructionSource());
  flow_graph->InsertBefore(another_function_call, load_indexed_instr, nullptr,
                           FlowGraph::kValue);

  another_function_call->RemoveFromGraph();
  pointer2_store->InputAt(2)->definition()->ReplaceUsesWith(load_indexed_instr);

  {
    // Check we constructed the right graph.
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());
    EXPECT(cursor.TryMatch({
        kMoveGlob,
        kMatchAndMoveStaticCall,
        kMatchAndMoveLoadUntagged,
        kMatchAndMoveUnboxedConstant,
        kMatchAndMoveLoadIndexed,
        kMatchAndMoveStaticCall,
        kMatchAndMoveStaticCall,
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
  Invoke(root_library, "myFunction");
  EXPECT_EQ(Smi::New(100), ptr);
  EXPECT_EQ(100, ptr2);
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

  ReturnInstr* return_instr = nullptr;
  {
    ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry());

    EXPECT(cursor.TryMatch({
        kMoveGlob,
        {kMatchReturn, &return_instr},
    }));
  }

  auto* const load_thread_instr = new (zone) LoadThreadInstr();
  flow_graph->InsertBefore(return_instr, load_thread_instr, nullptr,
                           FlowGraph::kValue);
  auto load_thread_value = Value(load_thread_instr);

  auto* const convert_instr = new (zone) IntConverterInstr(
      kUntagged, kUnboxedFfiIntPtr, &load_thread_value, DeoptId::kNone);
  flow_graph->InsertBefore(return_instr, convert_instr, nullptr,
                           FlowGraph::kValue);
  auto convert_value = Value(convert_instr);

  auto* const box_instr = BoxInstr::Create(kUnboxedFfiIntPtr, &convert_value);
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
        kMatchReturn,
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
  intptr_t result_int = Integer::Cast(invoke_result).AsInt64Value();
  EXPECT_EQ(reinterpret_cast<intptr_t>(thread), result_int);
}

// Helper to set up an inlined FfiCall by replacing a StaticCall.
FlowGraph* SetupFfiFlowgraph(TestPipeline* pipeline,
                             Zone* zone,
                             const compiler::ffi::CallMarshaller& marshaller,
                             uword native_entry,
                             bool is_leaf) {
  FlowGraph* flow_graph = pipeline->RunPasses({CompilerPass::kComputeSSA});

  // Make an FfiCall based on ffi_trampoline that calls our native function.
  auto ffi_call = new FfiCallInstr(DeoptId::kNone, marshaller, is_leaf);
  RELEASE_ASSERT(ffi_call->InputCount() == 1);
  // TargetAddress is the function pointer called.
  const Representation address_repr =
      compiler::target::kWordSize == 4 ? kUnboxedUint32 : kUnboxedInt64;
  ffi_call->SetInputAt(
      ffi_call->TargetAddressIndex(),
      new Value(flow_graph->GetConstant(
          Integer::Handle(Integer::NewCanonical(native_entry)), address_repr)));

  // Replace the placeholder StaticCall with an FfiCall to our native function.
  {
    StaticCallInstr* static_call = nullptr;
    {
      ILMatcher cursor(flow_graph, flow_graph->graph_entry()->normal_entry(),
                       /*trace=*/false);
      cursor.TryMatch({kMoveGlob, {kMatchStaticCall, &static_call}});
    }
    RELEASE_ASSERT(static_call != nullptr);

    flow_graph->InsertBefore(static_call, ffi_call, /*env=*/nullptr,
                             FlowGraph::kEffect);
    static_call->RemoveFromGraph(/*return_previous=*/false);
  }

  // Run remaining relevant compiler passes.
  pipeline->RunAdditionalPasses({
      CompilerPass::kApplyICData,
      CompilerPass::kTryOptimizePatterns,
      CompilerPass::kSetOuterInliningId,
      CompilerPass::kTypePropagation,
      // Skipping passes that don't seem to do anything for this test.
      CompilerPass::kWidenSmiToInt32,
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
  SetFlagScope<bool> sfs(&FLAG_sound_null_safety, true);

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
  const auto marshaller_ptr = compiler::ffi::CallMarshaller::FromFunction(
      thread->zone(), ffi_trampoline, &error);
  RELEASE_ASSERT(error == nullptr);
  RELEASE_ASSERT(marshaller_ptr != nullptr);
  const auto& marshaller = *marshaller_ptr;

  const auto& compile_and_run =
      [&](bool is_leaf, std::function<void(ParallelMoveInstr*)> verify) {
        // Build the SSA graph for "doFfiCall"
        TestPipeline pipeline(do_ffi_call, CompilerPass::kJIT);
        FlowGraph* flow_graph = SetupFfiFlowgraph(
            &pipeline, thread->zone(), marshaller, native_entry, is_leaf);

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

  ReturnInstr* ret = nullptr;

  ILMatcher cursor(flow_graph, entry, true, ParallelMovesHandling::kSkip);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchReturn, &ret},
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
    param = builder.AddParameter(0, 0, /*with_frame=*/true, kUnboxedInt64);

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
  ReturnInstr* ret;

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
  ReturnInstr* ret;

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

  ReturnInstr* ret;
  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    Definition* param =
        builder.AddParameter(0, 0, /*with_frame=*/true, kTagged);
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
  ReturnInstr* ret;

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

}  // namespace dart
