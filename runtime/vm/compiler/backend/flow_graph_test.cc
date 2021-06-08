// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/flow_graph.h"

#include <vector>

#include "platform/utils.h"
#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IS_64_BIT)
ISOLATE_UNIT_TEST_CASE(FlowGraph_UnboxInt64Phi) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);

  FlowGraphBuilderHelper H;

  // Add a variable into the scope which would provide static type for the
  // parameter.
  LocalVariable* v0_var =
      new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        String::Handle(Symbols::New(thread, "v0")),
                        AbstractType::ZoneHandle(Type::IntType()),
                        new CompileType(CompileType::Int()));
  v0_var->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  H.flow_graph()->parsed_function().scope()->AddVariable(v0_var);

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto loop_header = H.JoinEntry();
  auto loop_body = H.TargetEntry();
  auto loop_exit = H.TargetEntry();

  Definition* v0;
  PhiInstr* loop_var;
  Definition* add1;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    v0 = builder.AddParameter(0, 0, /*with_frame=*/true, kTagged);
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_header);
    loop_var = H.Phi(loop_header, {{normal_entry, v0}, {loop_body, &add1}});
    builder.AddPhi(loop_var);
    builder.AddBranch(new RelationalOpInstr(
                          InstructionSource(), Token::kLT, new Value(loop_var),
                          new Value(H.IntConstant(50)), kMintCid,
                          S.GetNextDeoptId(), Instruction::kNotSpeculative),
                      loop_body, loop_exit);
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_body);
    add1 = builder.AddDefinition(new BinaryInt64OpInstr(
        Token::kADD, new Value(loop_var), new Value(H.IntConstant(1)),
        S.GetNextDeoptId(), Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_exit);
    builder.AddReturn(new Value(loop_var));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  H.flow_graph()->SelectRepresentations();

  EXPECT_PROPERTY(loop_var, it.representation() == kUnboxedInt64);
}
#endif  // defined(TARGET_ARCH_IS_64_BIT)

ISOLATE_UNIT_TEST_CASE(FlowGraph_LateVariablePhiUnboxing) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/true, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto normal_entry = H.flow_graph()->graph_entry()->normal_entry();
  auto loop_header = H.JoinEntry();
  auto loop_body = H.TargetEntry();
  auto loop_exit = H.TargetEntry();

  ConstantInstr* sentinel = H.flow_graph()->GetConstant(Object::sentinel());

  PhiInstr* loop_var;
  PhiInstr* late_var;
  Definition* add1;

  {
    BlockBuilder builder(H.flow_graph(), normal_entry);
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_header);
    loop_var = H.Phi(loop_header,
                     {{normal_entry, H.IntConstant(0)}, {loop_body, &add1}});
    builder.AddPhi(loop_var);
    loop_var->UpdateType(CompileType::Int());
    loop_var->UpdateType(CompileType::FromAbstractType(
        Type::ZoneHandle(Type::IntType()), CompileType::kCannotBeNull,
        CompileType::kCanBeSentinel));
    late_var =
        H.Phi(loop_header, {{normal_entry, sentinel}, {loop_body, &add1}});
    builder.AddPhi(late_var);
    builder.AddBranch(new RelationalOpInstr(
                          InstructionSource(), Token::kLT, new Value(loop_var),
                          new Value(H.IntConstant(10)), kMintCid,
                          S.GetNextDeoptId(), Instruction::kNotSpeculative),
                      loop_body, loop_exit);
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_body);
    add1 = builder.AddDefinition(new BinaryInt64OpInstr(
        Token::kADD, new Value(loop_var), new Value(H.IntConstant(1)),
        S.GetNextDeoptId(), Instruction::kNotSpeculative));
    builder.AddInstruction(new GotoInstr(loop_header, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), loop_exit);
    builder.AddReturn(new Value(late_var));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(H.flow_graph());
  H.flow_graph()->SelectRepresentations();

#if defined(TARGET_ARCH_IS_64_BIT)
  EXPECT_PROPERTY(loop_var, it.representation() == kUnboxedInt64);
#endif
  EXPECT_PROPERTY(late_var, it.representation() == kTagged);
}

}  // namespace dart
