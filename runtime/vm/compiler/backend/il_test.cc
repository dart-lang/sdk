// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il.h"

#include <vector>

#include "platform/utils.h"
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
      if (auto store = it.Current()->AsStoreInstanceField()) {
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
                                          Representation intermediate) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H;

  // Add a variable into the scope which would provide static type for the
  // parameter.
  LocalVariable* v0_var =
      new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        String::Handle(Symbols::New(thread, "v0")),
                        AbstractType::ZoneHandle(Type::IntType()));
  v0_var->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  H.flow_graph()->parsed_function().scope()->AddVariable(v0_var);

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
                                              kUnboxedInt64, kUnboxedInt32));
  EXPECT(TestIntConverterCanonicalizationRule(thread, kMinInt32, kMaxInt32,
                                              kUnboxedInt64, kUnboxedInt32));
  EXPECT(!TestIntConverterCanonicalizationRule(
      thread, kMinInt32, static_cast<int64_t>(kMaxInt32) + 1, kUnboxedInt64,
      kUnboxedInt32));
  EXPECT(TestIntConverterCanonicalizationRule(thread, 0, kMaxInt16,
                                              kUnboxedInt64, kUnboxedUint32));
  EXPECT(TestIntConverterCanonicalizationRule(thread, 0, kMaxInt32,
                                              kUnboxedInt64, kUnboxedUint32));
  EXPECT(TestIntConverterCanonicalizationRule(thread, 0, kMaxUint32,
                                              kUnboxedInt64, kUnboxedUint32));
  EXPECT(!TestIntConverterCanonicalizationRule(
      thread, 0, static_cast<int64_t>(kMaxUint32) + 1, kUnboxedInt64,
      kUnboxedUint32));
  EXPECT(!TestIntConverterCanonicalizationRule(thread, -1, kMaxInt16,
                                               kUnboxedInt64, kUnboxedUint32));
}

ISOLATE_UNIT_TEST_CASE(IL_PhiCanonicalization) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H;

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

  FlowGraphBuilderHelper H;

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

}  // namespace dart
