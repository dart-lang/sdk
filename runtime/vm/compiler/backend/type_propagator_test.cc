// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/inliner.h"
#include "vm/compiler/backend/loops.h"
#include "vm/compiler/backend/redundancy_elimination.h"
#include "vm/compiler/backend/type_propagator.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/frontend/kernel_to_il.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/compiler/jit/jit_call_specializer.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#if !defined(PRODUCT)
#define TOCSTRING(v) ((v)->ToCString())
#else
#define TOCSTRING(v) "<?>"
#endif

#define EXPECT_PROPERTY(entity, property)                                      \
  do {                                                                         \
    auto& it = *entity;                                                        \
    if (!(property)) {                                                         \
      dart::Expect(__FILE__, __LINE__)                                         \
          .Fail("expected " #property " for " #entity " which is %s.\n",       \
                TOCSTRING(entity));                                            \
    }                                                                          \
  } while (0)

using compiler::BlockBuilder;

FlowGraph* MakeDummyGraph(Thread* thread) {
  const Function& func = Function::ZoneHandle(Function::New(
      String::Handle(Symbols::New(thread, "dummy")),
      RawFunction::kRegularFunction,
      /*is_static=*/true,
      /*is_const=*/false,
      /*is_abstract=*/false,
      /*is_external=*/false,
      /*is_native=*/true,
      Class::Handle(thread->isolate()->object_store()->object_class()),
      TokenPosition::kNoSource));

  Zone* zone = thread->zone();
  ParsedFunction* parsed_function = new (zone) ParsedFunction(thread, func);

  parsed_function->SetNodeSequence(new SequenceNode(
      TokenPosition::kNoSource, new LocalScope(nullptr, 0, 0)));

  auto graph_entry =
      new GraphEntryInstr(*parsed_function, Compiler::kNoOSRDeoptId);

  intptr_t block_id = 1;  // 0 is GraphEntry.
  graph_entry->set_normal_entry(
      new FunctionEntryInstr(graph_entry, block_id, kInvalidTryIndex,
                             CompilerState::Current().GetNextDeoptId()));
  return new FlowGraph(*parsed_function, graph_entry, block_id,
                       PrologueInfo{-1, -1});
}

namespace {
class FlowGraphBuilderHelper {
 public:
  explicit FlowGraphBuilderHelper(FlowGraph* flow_graph)
      : state_(CompilerState::Current()),
        flow_graph_(*flow_graph),
        constant_dead_(flow_graph->GetConstant(Symbols::OptimizedOut())) {}

  TargetEntryInstr* TargetEntry(intptr_t try_index = kInvalidTryIndex) const {
    return new TargetEntryInstr(flow_graph_.allocate_block_id(), try_index,
                                state_.GetNextDeoptId());
  }

  JoinEntryInstr* JoinEntry(intptr_t try_index = kInvalidTryIndex) const {
    return new JoinEntryInstr(flow_graph_.allocate_block_id(), try_index,
                              state_.GetNextDeoptId());
  }

  ConstantInstr* IntConstant(int64_t value) const {
    return flow_graph_.GetConstant(
        Integer::Handle(Integer::New(value, Heap::kOld)));
  }

  ConstantInstr* DoubleConstant(double value) {
    return flow_graph_.GetConstant(
        Double::Handle(Double::New(value, Heap::kOld)));
  }

  PhiInstr* Phi(JoinEntryInstr* join,
                std::initializer_list<std::pair<BlockEntryInstr*, Definition*>>
                    incomming) {
    auto phi = new PhiInstr(join, incomming.size());
    for (size_t i = 0; i < incomming.size(); i++) {
      auto input = new Value(constant_dead_);
      phi->SetInputAt(i, input);
      input->definition()->AddInputUse(input);
    }
    for (auto pair : incomming) {
      pending_phis_.Add({phi, pair.first, pair.second});
    }
    return phi;
  }

  void FinishGraph() {
    flow_graph_.DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph_.ComputeDominators(&dominance_frontier);

    for (auto& pending : pending_phis_) {
      auto join = pending.phi->block();
      EXPECT(pending.phi->InputCount() == join->PredecessorCount());
      auto pred_index = join->IndexOfPredecessor(pending.pred);
      EXPECT(pred_index != -1);
      pending.phi->InputAt(pred_index)->BindTo(pending.defn);
    }
  }

 private:
  CompilerState& state_;
  FlowGraph& flow_graph_;
  ConstantInstr* constant_dead_;

  struct PendingPhiInput {
    PhiInstr* phi;
    BlockEntryInstr* pred;
    Definition* defn;
  };
  GrowableArray<PendingPhiInput> pending_phis_;
};
}  // namespace

ISOLATE_UNIT_TEST_CASE(TypePropagator_RedefinitionAfterStrictCompareWithNull) {
  CompilerState S(thread);

  FlowGraph* flow_graph = MakeDummyGraph(thread);
  FlowGraphBuilderHelper H(flow_graph);

  // Add a variable into the scope which would provide static type for the
  // parameter.
  LocalVariable* v0_var =
      new LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                        String::Handle(Symbols::New(thread, "v0")),
                        AbstractType::ZoneHandle(Type::IntType()));
  v0_var->set_type_check_mode(LocalVariable::kTypeCheckedByCaller);
  flow_graph->parsed_function().node_sequence()->scope()->AddVariable(v0_var);

  auto normal_entry = flow_graph->graph_entry()->normal_entry();

  // We are going to build the following graph:
  //
  // B0[graph_entry]:
  // B1[function_entry]:
  //   v0 <- Parameter(0)
  //   if v0 == null then B2 else B3
  // B2:
  //   Return(v0)
  // B3:
  //   Return(v0)

  Definition* v0;
  auto b2 = H.TargetEntry();
  auto b3 = H.TargetEntry();

  {
    BlockBuilder builder(flow_graph, normal_entry);
    v0 = builder.AddParameter(0, /*with_frame=*/true);
    builder.AddBranch(
        new StrictCompareInstr(
            TokenPosition::kNoSource, Token::kEQ_STRICT, new Value(v0),
            new Value(flow_graph->GetConstant(Object::Handle())),
            /*needs_number_check=*/false, S.GetNextDeoptId()),
        b2, b3);
  }

  {
    BlockBuilder builder(flow_graph, b2);
    builder.AddReturn(new Value(v0));
  }

  {
    BlockBuilder builder(flow_graph, b3);
    builder.AddReturn(new Value(v0));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(flow_graph);

  // We expect that v0 is inferred to be nullable int because that is what
  // static type of an associated variable tells us.
  EXPECT(v0->Type()->IsNullableInt());

  // In B2 v0 should not have any additional type information so reaching
  // type should be still nullable int.
  auto b2_value = b2->last_instruction()->AsReturn()->value();
  EXPECT(b2_value->Type()->IsNullableInt());

  // In B3 v0 is constrained by comparison with null - it should be non-nullable
  // integer. There should be a Redefinition inserted to prevent LICM past
  // the branch.
  auto b3_value = b3->last_instruction()->AsReturn()->value();
  EXPECT(b3_value->Type()->IsInt());
  EXPECT(b3_value->definition()->IsRedefinition());
  EXPECT(b3_value->definition()->GetBlock() == b3);
}

ISOLATE_UNIT_TEST_CASE(
    TypePropagator_RedefinitionAfterStrictCompareWithLoadClassId) {
  CompilerState S(thread);

  FlowGraph* flow_graph = MakeDummyGraph(thread);
  FlowGraphBuilderHelper H(flow_graph);

  // We are going to build the following graph:
  //
  // B0[graph_entry]:
  // B1[function_entry]:
  //   v0 <- Parameter(0)
  //   v1 <- LoadClassId(v0)
  //   if v1 == kDoubleCid then B2 else B3
  // B2:
  //   Return(v0)
  // B3:
  //   Return(v0)

  Definition* v0;
  auto b1 = flow_graph->graph_entry()->normal_entry();
  auto b2 = H.TargetEntry();
  auto b3 = H.TargetEntry();

  {
    BlockBuilder builder(flow_graph, b1);
    v0 = builder.AddParameter(0, /*with_frame=*/true);
    auto load_cid = builder.AddDefinition(new LoadClassIdInstr(new Value(v0)));
    builder.AddBranch(
        new StrictCompareInstr(
            TokenPosition::kNoSource, Token::kEQ_STRICT, new Value(load_cid),
            new Value(H.IntConstant(kDoubleCid)),
            /*needs_number_check=*/false, S.GetNextDeoptId()),
        b2, b3);
  }

  {
    BlockBuilder builder(flow_graph, b2);
    builder.AddReturn(new Value(v0));
  }

  {
    BlockBuilder builder(flow_graph, b3);
    builder.AddReturn(new Value(v0));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(flow_graph);

  // There should be no information available about the incoming type of
  // the parameter either on entry or in B3.
  EXPECT_PROPERTY(v0->Type()->ToAbstractType(), it.IsDynamicType());
  auto b3_value = b3->last_instruction()->AsReturn()->value();
  EXPECT(b3_value->Type() == v0->Type());

  // In B3 v0 is constrained by comparison of its cid with kDoubleCid - it
  // should be non-nullable double. There should be a Redefinition inserted to
  // prevent LICM past the branch.
  auto b2_value = b2->last_instruction()->AsReturn()->value();
  EXPECT_PROPERTY(b2_value->Type(), it.IsDouble());
  EXPECT_PROPERTY(b2_value->definition(), it.IsRedefinition());
  EXPECT_PROPERTY(b2_value->definition()->GetBlock(), &it == b2);
}

ISOLATE_UNIT_TEST_CASE(TypePropagator_Refinement) {
  CompilerState S(thread);

  const Class& object_class =
      Class::Handle(thread->isolate()->object_store()->object_class());

  const Function& target_func = Function::ZoneHandle(Function::New(
      String::Handle(Symbols::New(thread, "dummy2")),
      RawFunction::kRegularFunction,
      /*is_static=*/true,
      /*is_const=*/false,
      /*is_abstract=*/false,
      /*is_external=*/false,
      /*is_native=*/true, object_class, TokenPosition::kNoSource));
  target_func.set_result_type(AbstractType::Handle(Type::IntType()));

  const Field& field = Field::ZoneHandle(
      Field::New(String::Handle(Symbols::New(thread, "dummy")),
                 /*is_static=*/true,
                 /*is_final=*/false,
                 /*is_const=*/false,
                 /*is_reflectable=*/true, object_class, Object::dynamic_type(),
                 TokenPosition::kNoSource, TokenPosition::kNoSource));

  FlowGraph* flow_graph = MakeDummyGraph(thread);
  FlowGraphBuilderHelper H(flow_graph);

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- Parameter(0)
  //   v1 <- Constant(0)
  //   if v0 == 1 then B3 else B2
  // B2:
  //   v2 <- StaticCall(target_func)
  //   goto B4
  // B3:
  //   goto B4
  // B4:
  //  v3 <- phi(v1, v2)
  //  return v5

  Definition* v0;
  Definition* v2;
  PhiInstr* v3;
  auto b1 = flow_graph->graph_entry()->normal_entry();
  auto b2 = H.TargetEntry();
  auto b3 = H.TargetEntry();
  auto b4 = H.JoinEntry();

  {
    BlockBuilder builder(flow_graph, b1);
    v0 = builder.AddParameter(0, /*with_frame=*/true);
    builder.AddBranch(new StrictCompareInstr(
                          TokenPosition::kNoSource, Token::kEQ_STRICT,
                          new Value(v0), new Value(H.IntConstant(1)),
                          /*needs_number_check=*/false, S.GetNextDeoptId()),
                      b2, b3);
  }

  {
    BlockBuilder builder(flow_graph, b2);
    v2 = builder.AddDefinition(
        new StaticCallInstr(TokenPosition::kNoSource, target_func,
                            /*type_args_len=*/0,
                            /*argument_names=*/Array::empty_array(),
                            new PushArgumentsArray(0), S.GetNextDeoptId(),
                            /*call_count=*/0, ICData::RebindRule::kStatic));
    builder.AddInstruction(new GotoInstr(b4, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b3);
    builder.AddInstruction(new GotoInstr(b4, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b4);
    v3 = H.Phi(b4, {{b2, v2}, {b3, H.IntConstant(0)}});
    builder.AddPhi(v3);
    builder.AddReturn(new Value(v3));
  }

  H.FinishGraph();
  FlowGraphTypePropagator::Propagate(flow_graph);

  EXPECT_PROPERTY(v2->Type(), it.IsNullableInt());
  EXPECT_PROPERTY(v3->Type(), it.IsNullableInt());

  auto v4 = new LoadStaticFieldInstr(new Value(flow_graph->GetConstant(field)),
                                     TokenPosition::kNoSource);
  flow_graph->InsertBefore(v2, v4, nullptr, FlowGraph::kValue);
  v2->ReplaceUsesWith(v4);
  v2->RemoveFromGraph();

  FlowGraphTypePropagator::Propagate(flow_graph);

  EXPECT_PROPERTY(v3->Type(), it.IsNullableInt());
}

// This test verifies that mutable compile types are not incorrectly cached
// as reaching types after inference.
ISOLATE_UNIT_TEST_CASE(TypePropagator_Regress36156) {
  CompilerState S(thread);

  FlowGraph* flow_graph = MakeDummyGraph(thread);
  FlowGraphBuilderHelper H(flow_graph);

  // We are going to build the following graph:
  //
  // B0[graph_entry]
  // B1[function_entry]:
  //   v0 <- Parameter(0)
  //   v1 <- Constant(42)
  //   v2 <- Constant(24)
  //   v4 <- Constant(1.0)
  //   if v0 == 1 then B6 else B2
  // B2:
  //   if v0 == 2 then B3 else B4
  // B3:
  //   goto B5
  // B4:
  //   goto B5
  // B5:
  //   v3 <- phi(v1, v2)
  //   goto B7
  // B6:
  //   goto B7
  // B7:
  //  v5 <- phi(v4, v3)
  //  return v5

  Definition* v0;
  PhiInstr* v3;
  PhiInstr* v5;
  auto b1 = flow_graph->graph_entry()->normal_entry();
  auto b2 = H.TargetEntry();
  auto b3 = H.TargetEntry();
  auto b4 = H.TargetEntry();
  auto b5 = H.JoinEntry();
  auto b6 = H.TargetEntry();
  auto b7 = H.JoinEntry();

  {
    BlockBuilder builder(flow_graph, b1);
    v0 = builder.AddParameter(0, /*with_frame=*/true);
    builder.AddBranch(new StrictCompareInstr(
                          TokenPosition::kNoSource, Token::kEQ_STRICT,
                          new Value(v0), new Value(H.IntConstant(1)),
                          /*needs_number_check=*/false, S.GetNextDeoptId()),
                      b6, b2);
  }

  {
    BlockBuilder builder(flow_graph, b2);
    builder.AddBranch(new StrictCompareInstr(
                          TokenPosition::kNoSource, Token::kEQ_STRICT,
                          new Value(v0), new Value(H.IntConstant(2)),
                          /*needs_number_check=*/false, S.GetNextDeoptId()),
                      b3, b4);
  }

  {
    BlockBuilder builder(flow_graph, b3);
    builder.AddInstruction(new GotoInstr(b5, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b4);
    builder.AddInstruction(new GotoInstr(b5, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b5);
    v3 = H.Phi(b5, {{b3, H.IntConstant(42)}, {b4, H.IntConstant(24)}});
    builder.AddPhi(v3);
    builder.AddInstruction(new GotoInstr(b7, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b6);
    builder.AddInstruction(new GotoInstr(b7, S.GetNextDeoptId()));
  }

  {
    BlockBuilder builder(flow_graph, b7);
    v5 = H.Phi(b7, {{b5, v3}, {b6, H.DoubleConstant(1.0)}});
    builder.AddPhi(v5);
    builder.AddInstruction(new ReturnInstr(TokenPosition::kNoSource,
                                           new Value(v5), S.GetNextDeoptId()));
  }

  H.FinishGraph();

  FlowGraphTypePropagator::Propagate(flow_graph);

  // We expect that v3 has an integer type, and v5 is either T{Object} or
  // T{num}.
  EXPECT_PROPERTY(v3->Type(), it.IsInt());
  EXPECT_PROPERTY(v5->Type()->ToAbstractType(),
                  it.IsObjectType() || it.IsNumberType());

  // Now unbox v3 phi by inserting unboxing for both inputs and boxing
  // for the result.
  {
    v3->set_representation(kUnboxedInt64);
    for (intptr_t i = 0; i < v3->InputCount(); i++) {
      auto input = v3->InputAt(i);
      auto unbox =
          new UnboxInt64Instr(input->CopyWithType(), S.GetNextDeoptId(),
                              Instruction::kNotSpeculative);
      flow_graph->InsertBefore(
          v3->block()->PredecessorAt(i)->last_instruction(), unbox, nullptr,
          FlowGraph::kValue);
      input->BindTo(unbox);
    }

    auto box = new BoxInt64Instr(new Value(v3));
    v3->ReplaceUsesWith(box);
    flow_graph->InsertBefore(b4->last_instruction(), box, nullptr,
                             FlowGraph::kValue);
  }

  // Run type propagation again.
  FlowGraphTypePropagator::Propagate(flow_graph);

  // If CompileType of v3 would be cached as a reaching type at its use in
  // v5 then we will be incorrect type propagation results.
  // We expect that v3 has an integer type, and v5 is either T{Object} or
  // T{num}.
  EXPECT_PROPERTY(v3->Type(), it.IsInt());
  EXPECT_PROPERTY(v5->Type()->ToAbstractType(),
                  it.IsObjectType() || it.IsNumberType());
}

}  // namespace dart
