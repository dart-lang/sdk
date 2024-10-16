// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

static int CountCheckBounds(FlowGraph* flow_graph) {
  int checks = 0;
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      if (it.Current()->IsCheckBoundBase()) {
        checks++;
      }
    }
  }
  return checks;
}

ISOLATE_UNIT_TEST_CASE(BoundsCheckElimination_Pragma) {
  const char* kScript = R"(
    import 'dart:typed_data';

    @pragma('vm:unsafe:no-bounds-checks')
    @pragma('vm:prefer-inline')
    int foo(Uint8List list) {
      int result = 0;
      for (int i = 0; i < 10; i++) {
        result = list[i];
      }
      return result;
    }

    int test(Uint8List list) {
      return foo(list);
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  auto flow_graph = pipeline.RunPasses({});
  EXPECT_EQ(0, CountCheckBounds(flow_graph));
}

ISOLATE_UNIT_TEST_CASE(BoundsCheckElimination_Pragma_learning) {
  // Test that BCE takes into account (i.e. 'learns from') checks that are
  // annotated to be removed.
  const char* kScript = R"(
    import 'dart:typed_data';

    @pragma('vm:unsafe:no-bounds-checks')
    @pragma('vm:prefer-inline')
    int load(Uint8List list, int index) => list[index];

    int test(Uint8List list) {
      int value1 = load(list, 10);
      int value2 = list[5];
      return value1 + value2;
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  auto flow_graph = pipeline.RunPasses({});

  // No checks because unsafe (trusted) check `list[10]` dominates `list[5]`.
  EXPECT_EQ(0, CountCheckBounds(flow_graph));
}

ISOLATE_UNIT_TEST_CASE(BoundsCheckElimination_Pragma_learning_control) {
  // Sister test to BoundsCheckElimination_Pragma_learning that shows without
  // the annotation, there is a check that corresponds to the check removed via
  // the annotation.
  const char* kScript = R"(
    import 'dart:typed_data';

    @pragma('vm:prefer-inline')
    int load(Uint8List list, int index) => list[index];

    int test(Uint8List list) {
      int value1 = load(list, 10);
      int value2 = list[5];
      return value1 + value2;
    }
  )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& function = Function::Handle(GetFunction(root_library, "test"));

  TestPipeline pipeline(function, CompilerPass::kAOT);
  auto flow_graph = pipeline.RunPasses({});

  // Single check because `list[10]` dominates `list[5]`.
  EXPECT_EQ(1, CountCheckBounds(flow_graph));
}

}  // namespace dart
