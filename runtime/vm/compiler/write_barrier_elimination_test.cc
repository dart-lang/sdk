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
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  const char* nullable_tag = TestCase::NullableTag();
  const char* null_assert_tag = TestCase::NullAssertTag();

  // This is a regression test for a bug where we were using
  // JoinEntry::SuccessorCount() to determine the number of outgoing blocks
  // from the join block. JoinEntry::SuccessorCount() is in fact always 0;
  // JoinEntry::last_instruction()->SuccessorCount() should be used instead.
  // clang-format off
  auto kScript = Utils::CStringUniquePtr(
      OS::SCreate(nullptr, R"(
      class C {
        int%s value;
        C%s next;
        C%s prev;
      }

      @pragma("vm:never-inline")
      fn() {}

      foo(int x) {
        C%s prev = C();
        C%s next;
        while (x --> 0) {
          next = C();
          next%s.prev = prev;
          prev?.next = next;
          prev = next;
          fn();
        }
        return next;
      }

      main() { foo(10); }
      )",
      nullable_tag, nullable_tag, nullable_tag, nullable_tag,
      nullable_tag, null_assert_tag), std::free);
  // clang-format on

  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));

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
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  // Ensure that we process every block at least once during the analysis
  // phase so that the out-sets will be initialized. If we don't process
  // each block at least once, the store "c.next = n" will be marked
  // NoWriteBarrier.
  // clang-format off
  auto kScript = Utils::CStringUniquePtr(OS::SCreate(nullptr,
                                                     R"(
      class C {
        %s C next;
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
      )", TestCase::LateTag()), std::free);
  // clang-format on
  const auto& root_library = Library::Handle(LoadTestScript(kScript.get()));

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

static void TestWBEForArrays(int length) {
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  const char* nullable_tag = TestCase::NullableTag();

  // Test that array allocations are considered usable after a
  // may-trigger-GC instruction (in this case CheckStackOverflow) iff they
  // are small.
  // clang-format off
  auto kScript =
      Utils::CStringUniquePtr(OS::SCreate(nullptr, R"(
      class C {
        %s C next;
      }

      @pragma("vm:never-inline")
      fn() {}

      foo(int x) {
        C c = C();
        C n = C();
        List<C%s> array = List<C%s>.filled(%d, null);
        array[0] = c;
        while (x --> 0) {
          c.next = n;
          n = c;
          c = C();
        }
        array[0] = c;
        return array;
      }

      main() { foo(10); }
      )", TestCase::LateTag(), nullable_tag, nullable_tag, length), std::free);
  // clang-format on

  // Generate a length dependent test library uri.
  char lib_uri[256];
  snprintf(lib_uri, sizeof(lib_uri), "%s%d", RESOLVED_USER_TEST_URI, length);

  const auto& root_library = Library::Handle(
      LoadTestScript(kScript.get(), /*resolver=*/nullptr, lib_uri));

  Invoke(root_library, "main");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreInstanceFieldInstr* store_into_c = nullptr;
  StoreIndexedInstr* store_into_array_before_loop = nullptr;
  StoreIndexedInstr* store_into_array_after_loop = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch({
      kMoveGlob,
      {kMatchAndMoveStoreIndexed, &store_into_array_before_loop},
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
      {kMatchAndMoveStoreIndexed, &store_into_array_after_loop},
  }));

  EXPECT(store_into_c->ShouldEmitStoreBarrier() == false);
  EXPECT(store_into_array_before_loop->ShouldEmitStoreBarrier() == false);
  EXPECT(store_into_array_after_loop->ShouldEmitStoreBarrier() ==
         (length > Array::kMaxLengthForWriteBarrierElimination));
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_Arrays) {
  TestWBEForArrays(1);
  TestWBEForArrays(Array::kMaxLengthForWriteBarrierElimination);
  TestWBEForArrays(Array::kMaxLengthForWriteBarrierElimination + 1);
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_Regress43786) {
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  const char* kScript = R"(
      foo() {
        final root = List<dynamic>.filled(128, null);
        List<dynamic> last = root;
        for (int i = 0; i < 10 * 1024; ++i) {
          final nc = List<dynamic>.filled(128, null);
          last[0] = nc;
          last = nc;
        }
      }

      main() { foo(); }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));

  Invoke(root_library, "main");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreIndexedInstr* store_into_phi = nullptr;

  ILMatcher cursor(flow_graph, entry);
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveCreateArray,
          kMatchAndMoveGoto,
          kMatchAndMoveBranchTrue,
          kMatchAndMoveCreateArray,
          {kMatchAndMoveStoreIndexed, &store_into_phi},
      },
      kMoveGlob));

  EXPECT(store_into_phi->array()->definition()->IsPhi());
  EXPECT(store_into_phi->ShouldEmitStoreBarrier());
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_LoadLateField) {
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  const char* kScript = R"(
    class A {
      late var x = new B();
    }

    class B {
    }

    class C {
      C(this.a, this.b);
      A a;
      B b;
    }

    foo(A a) => C(a, a.x);

    main() { foo(A()); }
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
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveAllocateObject,
          kMatchAndMoveLoadField,
          {kMatchAndMoveStoreInstanceField, &store1},
          {kMatchAndMoveStoreInstanceField, &store2},
      },
      kMoveGlob));

  EXPECT(!store1->ShouldEmitStoreBarrier());
  EXPECT(!store2->ShouldEmitStoreBarrier());
}

ISOLATE_UNIT_TEST_CASE(IRTest_WriteBarrierElimination_LoadLateStaticField) {
  DEBUG_ONLY(
      SetFlagScope<bool> sfs(&FLAG_trace_write_barrier_elimination, true));
  const char* kScript = R"(
    class A {
    }

    class B {
    }

    class C {
      C(this.a, this.b);
      A a;
      B b;
    }

    late var x = new B();

    foo(A a) => C(a, x);

    main() { foo(A()); }
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
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveAllocateObject,
          kMatchAndMoveLoadStaticField,
          {kMatchAndMoveStoreInstanceField, &store1},
          {kMatchAndMoveStoreInstanceField, &store2},
      },
      kMoveGlob));

  EXPECT(!store1->ShouldEmitStoreBarrier());
  EXPECT(!store2->ShouldEmitStoreBarrier());
}

}  // namespace dart
