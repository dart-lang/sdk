// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unit tests specific to BCE (bounds check eliminaton),
// which runs as part of range analysis optimizations.

#include "vm/compiler/backend/range_analysis.h"

#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

// Helper method to count number of bounds checks.
static intptr_t CountBoundChecks(FlowGraph* flow_graph) {
  intptr_t count = 0;
  for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
       !block_it.Done(); block_it.Advance()) {
    for (ForwardInstructionIterator it(block_it.Current()); !it.Done();
         it.Advance()) {
      if (it.Current()->IsCheckBoundBase()) {
        count++;
      }
    }
  }
  return count;
}

// Helper method to build CFG, run BCE, and count number of
// before/after bounds checks.
static std::pair<intptr_t, intptr_t> ApplyBCE(const char* script_chars,
                                              CompilerPass::PipelineMode mode) {
  // Load the script and exercise the code once
  // while exercising the given compiler passes.
  const auto& root_library = Library::Handle(LoadTestScript(script_chars));
  Invoke(root_library, "main");
  std::initializer_list<CompilerPass::Id> passes = {
      CompilerPass::kComputeSSA,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,
      CompilerPass::kInlining,
      CompilerPass::kTypePropagation,
      CompilerPass::kApplyICData,
      CompilerPass::kSelectRepresentations,
      CompilerPass::kCanonicalize,
      CompilerPass::kConstantPropagation,
      CompilerPass::kCSE,
      CompilerPass::kLICM,
  };
  const auto& function = Function::Handle(GetFunction(root_library, "foo"));
  TestPipeline pipeline(function, mode);
  FlowGraph* flow_graph = pipeline.RunPasses(passes);
  // Count the number of before/after bounds checks.
  const intptr_t num_bc_before = CountBoundChecks(flow_graph);
  RangeAnalysis range_analysis(flow_graph);
  range_analysis.Analyze();
  const intptr_t num_bc_after = CountBoundChecks(flow_graph);
  return {num_bc_before, num_bc_after};
}

static void TestScriptJIT(const char* script_chars,
                          intptr_t expected_before,
                          intptr_t expected_after) {
  auto jit_result = ApplyBCE(script_chars, CompilerPass::kJIT);
  EXPECT_STREQ(expected_before, jit_result.first);
  EXPECT_STREQ(expected_after, jit_result.second);
}

//
// BCE (bounds-check-elimination) tests.
//

ISOLATE_UNIT_TEST_CASE(BCECannotRemove) {
  const char* kScriptChars =
      R"(
      import 'dart:typed_data';
      foo(Float64List l) {
        return l[0];
      }
      main() {
        var l = new Float64List(1);
        foo(l);
      }
    )";
  TestScriptJIT(kScriptChars, 1, 1);
}

ISOLATE_UNIT_TEST_CASE(BCERemoveOne) {
  const char* kScriptChars =
      R"(
      import 'dart:typed_data';
      foo(Float64List l) {
        return l[1] + l[0];
      }
      main() {
        var l = new Float64List(2);
        foo(l);
      }
    )";
  TestScriptJIT(kScriptChars, 2, 1);
}

ISOLATE_UNIT_TEST_CASE(BCESimpleLoop) {
  const char* kScriptChars =
      R"(
      import 'dart:typed_data';
      foo(Float64List l) {
        for (int i = 0; i < l.length; i++) {
          l[i] = 0;
        }
      }
      main() {
        var l = new Float64List(100);
        foo(l);
      }
    )";
  TestScriptJIT(kScriptChars, 1, 0);
}

ISOLATE_UNIT_TEST_CASE(BCEModulo) {
  const char* kScriptChars =
      R"(
      foo(int i) {
        var l = new List<int>(3);
        return l[i % 3] ?? l[i % (-3)];
      }
      main() {
        foo(0);
      }
    )";
  TestScriptJIT(kScriptChars, 2, 0);
}

// TODO(ajcbik): add more tests

}  // namespace dart
