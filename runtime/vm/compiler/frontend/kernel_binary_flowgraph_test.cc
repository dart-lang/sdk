// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/frontend/kernel_binary_flowgraph.h"

#include "vm/compiler/backend/il_test_helper.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

ISOLATE_UNIT_TEST_CASE(StreamingFlowGraphBuilder_ConstFoldStringConcats) {
  // According to the Dart spec:
  // "Adjacent strings are implicitly concatenated to form a single string
  // literal."
  const char* kScript = R"(
    test() {
      var s = 'aaaa'
          'bbbb'
          'cccc';
      return s;
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  Invoke(root_library, "test");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  ReturnInstr* ret = nullptr;

  ILMatcher cursor(flow_graph, entry);
  // clang-format off
  RELEASE_ASSERT(cursor.TryMatch({
    kMatchAndMoveFunctionEntry,
    kMatchAndMoveCheckStackOverflow,
    kMoveDebugStepChecks,
    {kMatchReturn, &ret},
  }));
  // clang-format on

  EXPECT(ret->value()->BindsToConstant());
  EXPECT(ret->value()->BoundConstant().IsString());
  const String& ret_str = String::Cast(ret->value()->BoundConstant());
  EXPECT(ret_str.Equals("aaaabbbbcccc"));
}

ISOLATE_UNIT_TEST_CASE(StreamingFlowGraphBuilder_FlattenNestedStringInterp) {
  // We should collapse nested StringInterpolates:
  const char* kScript = R"(
    test(String s) {
      return '$s' '${'d' 'e'}';
    }
    main() => test('u');
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreIndexedInstr* store1 = nullptr;
  StoreIndexedInstr* store2 = nullptr;

  ILMatcher cursor(flow_graph, entry);
  // clang-format off
  RELEASE_ASSERT(cursor.TryMatch({
    kMatchAndMoveFunctionEntry,
    kMatchAndMoveCheckStackOverflow,
    kMoveDebugStepChecks,
    kMatchAndMoveCreateArray,
    {kMatchAndMoveStoreIndexed, &store1},
    {kMatchAndMoveStoreIndexed, &store2},
    kMatchAndMoveStringInterpolate,
    kMoveDebugStepChecks,
    kMatchReturn,
  }));
  // clang-format on

  // StoreIndexed(tmp_array, 0, s)
  EXPECT(store1->index()->BindsToConstant());
  EXPECT(store1->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store1->index()->BoundConstant()).AsInt64Value() == 0);

  EXPECT(!store1->value()->BindsToConstant());

  // StoreIndexed(tmp_array, 1, "de")
  EXPECT(store2->index()->BindsToConstant());
  EXPECT(store2->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store2->index()->BoundConstant()).AsInt64Value() == 1);

  EXPECT(store2->value()->BindsToConstant());
  EXPECT(store2->value()->BoundConstant().IsString());
  EXPECT(String::Cast(store2->value()->BoundConstant()).Equals("de"));
}

ISOLATE_UNIT_TEST_CASE(StreamingFlowGraphBuilder_DropEmptyStringInterp) {
  // We should drop empty strings from StringInterpolates:
  const char* kScript = R"(
    test(s) {
      return '' 'a' '$s' '' 'b' '';
    }
    main() => test('u');
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreIndexedInstr* store1 = nullptr;
  StoreIndexedInstr* store2 = nullptr;
  StoreIndexedInstr* store3 = nullptr;

  ILMatcher cursor(flow_graph, entry);
  // clang-format off
  RELEASE_ASSERT(cursor.TryMatch({
    kMatchAndMoveFunctionEntry,
    kMatchAndMoveCheckStackOverflow,
    kMoveDebugStepChecks,
    kMatchAndMoveCreateArray,
    {kMatchAndMoveStoreIndexed, &store1},
    {kMatchAndMoveStoreIndexed, &store2},
    {kMatchAndMoveStoreIndexed, &store3},
    kMatchAndMoveStringInterpolate,
    kMoveDebugStepChecks,
    kMatchReturn,
  }));
  // clang-format on

  // StoreIndexed(tmp_array, 0, "ab")
  EXPECT(store1->index()->BindsToConstant());
  EXPECT(store1->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store1->index()->BoundConstant()).AsInt64Value() == 0);

  EXPECT(store1->value()->BindsToConstant());
  EXPECT(store1->value()->BoundConstant().IsString());
  EXPECT(String::Cast(store1->value()->BoundConstant()).Equals("a"));

  // StoreIndexed(tmp_array, 1, s)
  EXPECT(store2->index()->BindsToConstant());
  EXPECT(store2->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store2->index()->BoundConstant()).AsInt64Value() == 1);

  EXPECT(!store2->value()->BindsToConstant());

  // StoreIndexed(tmp_array, 2, "b")
  EXPECT(store3->index()->BindsToConstant());
  EXPECT(store3->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store3->index()->BoundConstant()).AsInt64Value() == 2);

  EXPECT(store3->value()->BindsToConstant());
  EXPECT(store3->value()->BoundConstant().IsString());
  EXPECT(String::Cast(store3->value()->BoundConstant()).Equals("b"));
}

ISOLATE_UNIT_TEST_CASE(StreamingFlowGraphBuilder_ConcatStringLits) {
  // We should drop empty strings from StringInterpolates:
  const char* kScript = R"(
    test(s) {
      return '' 'a' '' 'b' '$s' '' 'c' '' 'd' '';
    }
    main() => test('u');
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  Invoke(root_library, "main");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  StoreIndexedInstr* store1 = nullptr;
  StoreIndexedInstr* store2 = nullptr;
  StoreIndexedInstr* store3 = nullptr;

  ILMatcher cursor(flow_graph, entry);
  // clang-format off
  RELEASE_ASSERT(cursor.TryMatch({
    kMatchAndMoveFunctionEntry,
    kMatchAndMoveCheckStackOverflow,
    kMoveDebugStepChecks,
    kMatchAndMoveCreateArray,
    {kMatchAndMoveStoreIndexed, &store1},
    {kMatchAndMoveStoreIndexed, &store2},
    {kMatchAndMoveStoreIndexed, &store3},
    kMatchAndMoveStringInterpolate,
    kMoveDebugStepChecks,
    kMatchReturn,
  }));
  // clang-format on

  // StoreIndexed(tmp_array, 0, "ab")
  EXPECT(store1->index()->BindsToConstant());
  EXPECT(store1->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store1->index()->BoundConstant()).AsInt64Value() == 0);

  EXPECT(store1->value()->BindsToConstant());
  EXPECT(store1->value()->BoundConstant().IsString());
  EXPECT(String::Cast(store1->value()->BoundConstant()).Equals("ab"));

  // StoreIndexed(tmp_array, 1, s)
  EXPECT(store2->index()->BindsToConstant());
  EXPECT(store2->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store2->index()->BoundConstant()).AsInt64Value() == 1);

  EXPECT(!store2->value()->BindsToConstant());

  // StoreIndexed(tmp_array, 2, "cd")
  EXPECT(store3->index()->BindsToConstant());
  EXPECT(store3->index()->BoundConstant().IsInteger());
  EXPECT(Integer::Cast(store3->index()->BoundConstant()).AsInt64Value() == 2);

  EXPECT(store3->value()->BindsToConstant());
  EXPECT(store3->value()->BoundConstant().IsString());
  EXPECT(String::Cast(store3->value()->BoundConstant()).Equals("cd"));
}

ISOLATE_UNIT_TEST_CASE(StreamingFlowGraphBuilder_InvariantFlagInListLiterals) {
  const char* kScript = R"(
    test() {
      return [...[], 42];
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  Invoke(root_library, "test");

  TestPipeline pipeline(function, CompilerPass::kJIT);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  InstanceCallInstr* call_add = nullptr;

  ILMatcher cursor(flow_graph, entry);
  // clang-format off
  RELEASE_ASSERT(cursor.TryMatch({
    kMatchAndMoveFunctionEntry,
    kMatchAndMoveCheckStackOverflow,
    kMoveDebugStepChecks,
    kMatchAndMoveStaticCall,
    kMatchAndMoveStaticCall,
    {kMatchAndMoveInstanceCall, &call_add},
    kMoveDebugStepChecks,
    kMatchReturn,
  }));
  // clang-format on

  EXPECT(call_add != nullptr);
  EXPECT(call_add->function_name().Equals("add"));
  EXPECT(call_add->entry_kind() == Code::EntryKind::kUnchecked);
}

}  // namespace dart
