// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/constant_propagator.h"

#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/unit_test.h"

namespace dart {

// Test issue https://github.com/flutter/flutter/issues/53903.
//
// If graph contains a cyclic phi which participates in an EqualityCompare
// or StrictCompare with its input like phi(x, ...) == x then constant
// propagation might fail to converge by constantly revisiting this phi and
// its uses (which includes comparison and the phi itself).
ISOLATE_UNIT_TEST_CASE(ConstantPropagation_PhiUnwrappingAndConvergence) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false);
  FlowGraphBuilderHelper H;

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- Constant(0)
  //   goto B2
  // B2:
  //   v1 <- phi(v0, v1)
  //   v2 <- EqualityCompare(v1 == v0)
  //   if v2 == true then B4 else B3
  // B3:
  //   goto B2
  // B4:
  //   Return(v1)

  PhiInstr* v1;
  ConstantInstr* v0 = H.IntConstant(0);
  auto b1 = H.flow_graph()->graph_entry()->normal_entry();
  auto b2 = H.JoinEntry();
  auto b3 = H.TargetEntry();
  auto b4 = H.TargetEntry();

  {
    BlockBuilder builder(H.flow_graph(), b1);
    builder.AddInstruction(new GotoInstr(b2, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), b2);
    v1 = H.Phi(b2, {{b1, v0}, {b3, FlowGraphBuilderHelper::kPhiSelfReference}});
    builder.AddPhi(v1);
    auto v2 = builder.AddDefinition(new EqualityCompareInstr(
        TokenPosition::kNoSource, Token::kEQ, new Value(v1), new Value(v0),
        kSmiCid, S.GetNextDeoptId()));
    builder.AddBranch(
        new StrictCompareInstr(
            TokenPosition::kNoSource, Token::kEQ_STRICT, new Value(v2),
            new Value(H.flow_graph()->GetConstant(Bool::True())),
            /*needs_number_check=*/false, S.GetNextDeoptId()),
        b4, b3);
  }

  {
    BlockBuilder builder(H.flow_graph(), b3);
    builder.AddInstruction(new GotoInstr(b2, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), b4);
    builder.AddReturn(new Value(v1));
  }

  H.FinishGraph();

  // Graph transformations will attempt to copy deopt information from
  // branches and block entries which we did not assign.
  // To disable copying we mark graph to disable LICM.
  H.flow_graph()->disallow_licm();

  ConstantPropagator::Optimize(H.flow_graph());

  auto& blocks = H.flow_graph()->reverse_postorder();
  EXPECT_EQ(2, blocks.length());
  EXPECT_PROPERTY(blocks[0], it.IsGraphEntry());
  EXPECT_PROPERTY(blocks[1], it.IsFunctionEntry());
  EXPECT_PROPERTY(blocks[1]->next(), it.IsReturn());
  EXPECT_PROPERTY(blocks[1]->next()->AsReturn(),
                  it.value()->definition() == v0);
}

}  // namespace dart
