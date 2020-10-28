// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il.h"

#include <vector>

#include "platform/utils.h"
#include "vm/compiler/backend/il_test_helper.h"
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
  EXPECT(use1a->Equals(use1b));
  Value* use2 = new Value(def2);
  EXPECT(!use2->Equals(use1a));

  ConstantInstr* c1 = new ConstantInstr(Bool::True());
  ConstantInstr* c2 = new ConstantInstr(Bool::True());
  EXPECT(c1->Equals(c2));
  ConstantInstr* c3 = new ConstantInstr(Object::ZoneHandle());
  ConstantInstr* c4 = new ConstantInstr(Object::ZoneHandle());
  EXPECT(c3->Equals(c4));
  EXPECT(!c3->Equals(c1));
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
                            {"Closure.function"});

  // Note that in JIT mode we lower context allocation in a way that hinders
  // removal of initializing moves so there would be some redundant stores of
  // null left in the graph. In AOT mode we don't apply this optimization
  // which enables us to remove more stores.
  std::vector<const char*> expected_stores_jit;
  std::vector<const char*> expected_stores_aot;

  expected_stores_jit.insert(expected_stores_jit.end(),
                             {"value", "Context.parent", "Context.parent",
                              "value", "Closure.function_type_arguments",
                              "Closure.function", "Closure.context"});
  expected_stores_aot.insert(expected_stores_aot.end(),
                             {"value", "Closure.function_type_arguments",
                              "Closure.function", "Closure.context"});

  RunInitializingStoresTest(root_library, "f4", CompilerPass::kJIT,
                            expected_stores_jit);
  RunInitializingStoresTest(root_library, "f4", CompilerPass::kAOT,
                            expected_stores_aot);
}

}  // namespace dart
