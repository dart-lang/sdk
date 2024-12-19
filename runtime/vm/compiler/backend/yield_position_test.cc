// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/closure_functions_cache.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

using YieldPoints = ZoneGrowableArray<TokenPosition>;

int LowestFirst(const TokenPosition* a, const TokenPosition* b) {
  return a->Pos() - b->Pos();
}

static YieldPoints* GetYieldPointsFromGraph(FlowGraph* flow_graph) {
  auto array = new (flow_graph->zone()) YieldPoints();
  const auto& blocks = flow_graph->reverse_postorder();
  for (auto block : blocks) {
    ForwardInstructionIterator it(block);
    while (!it.Done()) {
      if (auto suspend_instr = it.Current()->AsSuspend()) {
        array->Add(suspend_instr->token_pos());
      }
      it.Advance();
    }
  }
  array->Sort(LowestFirst);
  return array;
}

static YieldPoints* GetYieldPointsFromCode(const Code& code) {
  auto array = new YieldPoints();
  const auto& pc_descriptor = PcDescriptors::Handle(code.pc_descriptors());
  PcDescriptors::Iterator it(pc_descriptor, UntaggedPcDescriptors::kOther);
  while (it.MoveNext()) {
    if (it.YieldIndex() != UntaggedPcDescriptors::kInvalidYieldIndex) {
      array->Add(it.TokenPos());
    }
  }
  array->Sort(LowestFirst);
  return array;
}

void RunTestInMode(CompilerPass::PipelineMode mode) {
  const char* kScript =
      R"(
      import 'dart:async';

      Future foo() async {
        print('pos-0');
        await 0;
        print('pos-1');
        await 1;
        print('pos-2');
        await 2;
      }
      )";

  SetupCoreLibrariesForUnitTest();

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  // Ensure the outer function was compiled once, ensuring we have a closure
  // function for the inner closure.
  Invoke(root_library, "foo");

  const auto& function = Function::Handle(GetFunction(root_library, "foo"));

  // Ensure we have 3 different return instructions with yield indices attached
  // to them.
  TestPipeline pipeline(function, mode);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto validate_indices = [](const YieldPoints& yield_points) {
    EXPECT_EQ(3, yield_points.length());

    EXPECT_EQ(88, yield_points[0].Pos());
    EXPECT_EQ(129, yield_points[1].Pos());
    EXPECT_EQ(170, yield_points[2].Pos());
  };

  validate_indices(*GetYieldPointsFromGraph(flow_graph));

  // Ensure we have 3 different yield indices attached to the code via pc
  // descriptors.
  const auto& error = Error::Handle(
      Compiler::EnsureUnoptimizedCode(Thread::Current(), function));
  RELEASE_ASSERT(error.IsNull());
  const auto& code = Code::Handle(function.CurrentCode());
  validate_indices(*GetYieldPointsFromCode(code));
}

ISOLATE_UNIT_TEST_CASE(IRTest_YieldIndexAvailableJIT) {
  RunTestInMode(CompilerPass::kJIT);
}

ISOLATE_UNIT_TEST_CASE(IRTest_YieldIndexAvailableAOT) {
  RunTestInMode(CompilerPass::kAOT);
}

}  // namespace dart
