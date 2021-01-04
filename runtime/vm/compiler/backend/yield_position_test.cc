// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

using Pair = std::pair<intptr_t, TokenPosition>;
using YieldPoints = ZoneGrowableArray<Pair>;

int LowestFirst(const Pair* a, const Pair* b) {
  return a->first - b->first;
}

static YieldPoints* GetYieldPointsFromGraph(FlowGraph* flow_graph) {
  auto array = new (flow_graph->zone()) YieldPoints();
  const auto& blocks = flow_graph->reverse_postorder();
  for (auto block : blocks) {
    ForwardInstructionIterator it(block);
    while (!it.Done()) {
      if (auto return_instr = it.Current()->AsReturn()) {
        if (return_instr->yield_index() !=
            PcDescriptorsLayout::kInvalidYieldIndex) {
          ASSERT(return_instr->yield_index() > 0);
          array->Add(
              Pair(return_instr->yield_index(), return_instr->token_pos()));
        }
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
  PcDescriptors::Iterator it(pc_descriptor, PcDescriptorsLayout::kOther);
  while (it.MoveNext()) {
    if (it.YieldIndex() != PcDescriptorsLayout::kInvalidYieldIndex) {
      array->Add(Pair(it.YieldIndex(), it.TokenPos()));
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

  const auto& outer_function =
      Function::Handle(GetFunction(root_library, "foo"));

  // Grab the inner, lazily created, closure from the object store.
  const auto& closures = GrowableObjectArray::Handle(
      Isolate::Current()->object_store()->closure_functions());
  ASSERT(!closures.IsNull());
  auto& closure = Object::Handle();
  for (intptr_t i = 0; i < closures.Length(); ++i) {
    closure = closures.At(i);
    if (Function::Cast(closure).parent_function() == outer_function.raw()) {
      break;
    }
    closure = Object::null();
  }
  RELEASE_ASSERT(closure.IsFunction());
  const auto& function = Function::Cast(closure);

  // Ensure we have 3 different return instructions with yield indices attached
  // to them.
  TestPipeline pipeline(function, mode);
  FlowGraph* flow_graph = pipeline.RunPasses({
      CompilerPass::kComputeSSA,
  });

  auto validate_indices = [](const YieldPoints& yield_points) {
    EXPECT_EQ(3, yield_points.length());

    EXPECT_EQ(1, yield_points[0].first);
    EXPECT_EQ(88, yield_points[0].second.Pos());
    EXPECT_EQ(2, yield_points[1].first);
    EXPECT_EQ(129, yield_points[1].second.Pos());
    EXPECT_EQ(3, yield_points[2].first);
    EXPECT_EQ(170, yield_points[2].second.Pos());
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
