// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/constant_propagator.h"

#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/compiler/backend/type_propagator.h"
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
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
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
    auto v2 = builder.AddDefinition(
        new EqualityCompareInstr(InstructionSource(), Token::kEQ, new Value(v1),
                                 new Value(v0), kSmiCid, S.GetNextDeoptId()));
    builder.AddBranch(new StrictCompareInstr(
                          InstructionSource(), Token::kEQ_STRICT, new Value(v2),
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

// This test does not work on 32-bit platforms because it requires
// kUnboxedInt64 constants.
#if defined(ARCH_IS_64_BIT)
namespace {
struct FoldingResult {
  static FoldingResult NoFold() { return {false, 0}; }

  static FoldingResult FoldsTo(int64_t result) { return {true, result}; }

  bool should_fold;
  int64_t result;
};

static void ConstantPropagatorUnboxedOpTest(
    Thread* thread,
    int64_t lhs,
    int64_t rhs,
    std::function<Definition*(Definition*, Definition*, intptr_t)> make_op,
    bool redundant_phi,
    FoldingResult expected) {
  using compiler::BlockBuilder;

  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  // Add a variable into the scope which would provide static type for the
  // parameter.
  LocalVariable* v0_var =
      new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        String::Handle(Symbols::New(thread, "v0")),
                        AbstractType::ZoneHandle(Type::IntType()));
  v0_var->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  H.flow_graph()->parsed_function().scope()->AddVariable(v0_var);

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- Parameter(0)
  //   if 1 == ${redundant_phi ? 1 : v0} then B2 else B3
  // B2:
  //   goto B4
  // B3:
  //   goto B4
  // B4:
  //   v1 <- Phi(lhs, ${redundant_phi ? -1 : lhs}) repr
  //   v2 <- Constant(rhs)
  //   v3 <- make_op(v1, v2)
  //   Return(v3)
  //
  // Note that we test both the case when v1 is fully redundant (has a single
  // live predecessor) and when it is not redundant but has a constant value.
  // These two cases are handled by different code paths - so we need to cover
  // them both to ensure that we properly insert any unbox operations
  // which are needed.

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();
  auto b2 = H.TargetEntry();
  auto b3 = H.TargetEntry();
  auto b4 = H.JoinEntry();
  ReturnInstr* ret;

  {
    BlockBuilder builder(H.flow_graph(), b1);
    auto v0 = builder.AddParameter(/*index=*/0, /*param_offset=*/0,
                                   /*with_frame=*/true, kTagged);
    builder.AddBranch(
        new StrictCompareInstr(
            InstructionSource(), Token::kEQ_STRICT, new Value(H.IntConstant(1)),
            new Value(redundant_phi ? H.IntConstant(1) : v0),
            /*needs_number_check=*/false, S.GetNextDeoptId()),
        b2, b3);
  }

  {
    BlockBuilder builder(H.flow_graph(), b2);
    builder.AddInstruction(new GotoInstr(b4, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(H.flow_graph(), b3);
    builder.AddInstruction(new GotoInstr(b4, S.GetNextDeoptId()));
  }

  PhiInstr* v1;
  Definition* op;
  {
    BlockBuilder builder(H.flow_graph(), b4);
    v1 = H.Phi(b4, {{b2, H.IntConstant(lhs)},
                    {b3, H.IntConstant(redundant_phi ? -1 : lhs)}});
    builder.AddPhi(v1);
    op = builder.AddDefinition(
        make_op(v1, H.IntConstant(rhs), S.GetNextDeoptId()));
    ret = builder.AddReturn(new Value(op));
  }

  H.FinishGraph();
  FlowGraphTypePropagator::Propagate(H.flow_graph());
  // Force phi unboxing independent of heuristics.
  v1->set_representation(op->representation());
  H.flow_graph()->SelectRepresentations();
  H.flow_graph()->Canonicalize();
  EXPECT_PROPERTY(ret->value()->definition(),
                  it.IsBoxInteger() && it.RequiredInputRepresentation(0) ==
                                           op->representation());

  ConstantPropagator::Optimize(H.flow_graph());

  // If |should_fold| then check that resulting graph is
  //
  //         Return(Box(Unbox(Constant(result))))
  //
  // otherwise check that the graph is
  //
  //         Return(Box(op))
  //
  {
    auto ret_val = ret->value()->definition();
    EXPECT_PROPERTY(
        ret_val, it.IsBoxInteger() &&
                     it.RequiredInputRepresentation(0) == op->representation());
    auto boxed_value = ret_val->AsBoxInteger()->value()->definition();
    if (expected.should_fold) {
      EXPECT_PROPERTY(
          boxed_value,
          it.IsUnboxInteger() && it.representation() == op->representation());
      auto unboxed_value = boxed_value->AsUnboxInteger()->value()->definition();
      EXPECT_PROPERTY(unboxed_value,
                      it.IsConstant() && it.AsConstant()->value().IsInteger());
      EXPECT_EQ(
          expected.result,
          Integer::Cast(unboxed_value->AsConstant()->value()).AsInt64Value());
    } else {
      EXPECT_PROPERTY(boxed_value, &it == op);
    }
  }
}

void ConstantPropagatorUnboxedOpTest(
    Thread* thread,
    int64_t lhs,
    int64_t rhs,
    std::function<Definition*(Definition*, Definition*, intptr_t)> make_op,
    FoldingResult expected) {
  ConstantPropagatorUnboxedOpTest(thread, lhs, rhs, make_op,
                                  /*redundant_phi=*/false, expected);
  ConstantPropagatorUnboxedOpTest(thread, lhs, rhs, make_op,
                                  /*redundant_phi=*/true, expected);
}

}  // namespace

// This test verifies that constant propagation respects representations when
// replacing unboxed operations.
ISOLATE_UNIT_TEST_CASE(ConstantPropagator_Regress35371) {
  auto make_int64_add = [](Definition* lhs, Definition* rhs,
                           intptr_t deopt_id) {
    return new BinaryInt64OpInstr(Token::kADD, new Value(lhs), new Value(rhs),
                                  deopt_id, Instruction::kNotSpeculative);
  };

  auto make_int32_add = [](Definition* lhs, Definition* rhs,
                           intptr_t deopt_id) {
    return new BinaryInt32OpInstr(Token::kADD, new Value(lhs), new Value(rhs),
                                  deopt_id);
  };

  auto make_int32_truncating_add = [](Definition* lhs, Definition* rhs,
                                      intptr_t deopt_id) {
    auto op = new BinaryInt32OpInstr(Token::kADD, new Value(lhs),
                                     new Value(rhs), deopt_id);
    op->mark_truncating();
    return op;
  };

  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/1, /*lhs=*/2, make_int64_add,
                                  FoldingResult::FoldsTo(3));
  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/kMaxInt64, /*lhs=*/1,
                                  make_int64_add,
                                  FoldingResult::FoldsTo(kMinInt64));

  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/1, /*lhs=*/2, make_int32_add,
                                  FoldingResult::FoldsTo(3));
  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/kMaxInt32 - 1, /*lhs=*/1,
                                  make_int32_add,
                                  FoldingResult::FoldsTo(kMaxInt32));

  // Overflow of int32 representation and operation is not marked as
  // truncating.
  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/kMaxInt32, /*lhs=*/1,
                                  make_int32_add, FoldingResult::NoFold());

  // Overflow of int32 representation and operation is marked as truncating.
  ConstantPropagatorUnboxedOpTest(thread, /*lhs=*/kMaxInt32, /*lhs=*/1,
                                  make_int32_truncating_add,
                                  FoldingResult::FoldsTo(kMinInt32));
}
#endif

}  // namespace dart
