// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(DART_PRECOMPILER)

ISOLATE_UNIT_TEST_CASE(IRTest_MultilpeEntryPoints_Regress43534) {
  const char* kScript =
      R"(
      import 'dart:typed_data';

      @pragma('vm:never-inline')
      void callWith<T>(void Function(T arg) fun, T arg) {
        fun(arg);
      }

      @pragma('vm:never-inline')
      void use(dynamic arg) {}

      void test() {
        callWith<Uint8List>((Uint8List list) {
          use(list);
        }, Uint8List(10));
      }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  Invoke(root_library, "test");
  const auto& test_function =
      Function::Handle(GetFunction(root_library, "test"));
  const auto& closures = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->closure_functions());
  auto& function = Function::Handle();
  for (intptr_t i = closures.Length() - 1; 0 <= i; ++i) {
    function ^= closures.At(i);
    if (function.parent_function() == test_function.raw()) {
      break;
    }
    function = Function::null();
  }
  RELEASE_ASSERT(!function.IsNull());
  TestPipeline pipeline(function, CompilerPass::kAOT);
  FlowGraph* flow_graph = pipeline.RunPasses({CompilerPass::kComputeSSA});

  auto entry = flow_graph->graph_entry()->normal_entry();
  EXPECT(entry != nullptr);

  auto unchecked_entry = flow_graph->graph_entry()->unchecked_entry();
  EXPECT(unchecked_entry != nullptr);

  AssertAssignableInstr* assert_assignable = nullptr;
  StaticCallInstr* static_call = nullptr;

  // Normal entry
  ILMatcher cursor(flow_graph, entry, /*trace=*/true);
  RELEASE_ASSERT(cursor.TryMatch(
      {
          kMatchAndMoveGoto,
          kMatchAndMoveBranchFalse,
          {kMatchAndMoveAssertAssignable, &assert_assignable},
          kMatchAndMoveGoto,
          {kMatchAndMoveStaticCall, &static_call},
          kMatchReturn,
      },
      kMoveGlob));

  RedefinitionInstr* redefinition = nullptr;
  StaticCallInstr* static_call2 = nullptr;

  // Unchecked entry
  ILMatcher cursor2(flow_graph, entry, /*trace=*/true);
  RELEASE_ASSERT(cursor2.TryMatch(
      {
          kMatchAndMoveGoto,
          kMatchAndMoveBranchTrue,
          {kMatchAndMoveRedefinition, &redefinition},
          kMatchAndMoveGoto,
          {kMatchAndMoveStaticCall, &static_call2},
          kMatchReturn,
      },
      kMoveGlob));

  // Ensure the value the static call uses is a Phi node with 2 inputs:
  //   a) Normal entry: AssertAssignable
  //   b) Unchecked entry: Redefinition
  RELEASE_ASSERT(static_call->ArgumentAt(0)->IsPhi());
  auto phi = static_call->ArgumentAt(0)->AsPhi();
  auto input_a = phi->InputAt(0)->definition();
  auto input_b = phi->InputAt(1)->definition();
  RELEASE_ASSERT(input_a->IsRedefinition());
  RELEASE_ASSERT(input_b->IsAssertAssignable());
  RELEASE_ASSERT(input_a == redefinition);
  RELEASE_ASSERT(input_b == assert_assignable);
  RELEASE_ASSERT(static_call == static_call2);
}

#endif  // defined(DART_PRECOMPILER)

}  // namespace dart
