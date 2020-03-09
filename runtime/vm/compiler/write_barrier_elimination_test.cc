// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/unit_test.h"

namespace dart {

DEBUG_ONLY(DECLARE_FLAG(bool, trace_write_barrier_elimination);)

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_JoinSuccessors) {
  DEBUG_ONLY(FLAG_trace_write_barrier_elimination = true);

  // This is a regression test for a bug where we were using
  // JoinEntry::SuccessorCount() to determine the number of outgoing blocks
  // from the join block. JoinEntry::SuccessorCount() is in fact always 0;
  // JoinEntry::last_instruction()->SuccessorCount() should be used instead.
  const char* kScript =
      R"(
      class C {
        int value;
        C next;
        C prev;
      }

      @pragma("vm:never-inline")
      fn() {}

      foo(int x) {
        C prev = C();
        C next;
        while (x --> 0) {
          next = C();
          next.prev = prev;
          prev?.next = next;
          prev = next;
          fn();
        }
        return next;
      }

      main() { foo(10); }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  Invoke(root_library, "main");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreInstanceFieldInstr* store1 = nullptr;
  StoreInstanceFieldInstr* store2 = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveGoto,
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      {kMatchAndMoveStoreInstanceField, &store1},
      kMoveGlob,
      {kMatchAndMoveStoreInstanceField, &store2},
  }));

  EXPECT(store1->ShouldEmitStoreBarrier() == false);
  EXPECT(store2->ShouldEmitStoreBarrier() == true);
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_AtLeastOnce) {
  DEBUG_ONLY(FLAG_trace_write_barrier_elimination = true);

  // Ensure that we process every block at least once during the analysis
  // phase so that the out-sets will be initialized. If we don't process
  // each block at least once, the store "c.next = n" will be marked
  // NoWriteBarrier.
  const char* kScript =
      R"(
      class C {
        C next;
      }

      @pragma("vm:never-inline")
      fn() {}

      foo(int x) {
        C c = C();
        C n = C();
        if (x > 5) {
          fn();
        }
        c.next = n;
        return c;
      }

      main() { foo(0); foo(10); }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  Invoke(root_library, "main");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreInstanceFieldInstr* store = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveBranchFalse,
      kMoveGlob,
      kMatchAndMoveGoto,
      kMoveGlob,
      {kMatchAndMoveStoreInstanceField, &store},
  }));

  EXPECT(store->ShouldEmitStoreBarrier() == true);
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_Arrays) {
  DEBUG_ONLY(FLAG_trace_write_barrier_elimination = true);

  // Test that array allocations are not considered usable after a
  // may-trigger-GC instruction (in this case CheckStackOverflow), unlike
  // normal allocations, which are only interruped by a Dart call.
  const char* kScript =
      R"(
      class C {
        C next;
      }

      @pragma("vm:never-inline")
      fn() {}

      foo(int x) {
        C c = C();
        C n = C();
        List<C> array = List<C>(1);
        while (x --> 0) {
          c.next = n;
          n = c;
          c = C();
        }
        array[0] = c;
        return c;
      }

      main() { foo(10); }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  Invoke(root_library, "main");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreInstanceFieldInstr* store_into_c = nullptr;
  StoreIndexedInstr* store_into_array = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      kMatchAndMoveGoto,
      kMoveGlob,
      kMatchAndMoveBranchTrue,
      kMoveGlob,
      {kMatchAndMoveStoreInstanceField, &store_into_c},
      kMoveGlob,
      kMatchAndMoveGoto,
      kMoveGlob,
      kMatchAndMoveBranchFalse,
      kMoveGlob,
      {kMatchAndMoveStoreIndexed, &store_into_array},
  }));

  EXPECT(store_into_c->ShouldEmitStoreBarrier() == false);
  EXPECT(store_into_array->ShouldEmitStoreBarrier() == true);
}

}  // namespace dart
