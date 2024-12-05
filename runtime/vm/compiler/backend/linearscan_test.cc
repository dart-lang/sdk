// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/linearscan.h"

#include <utility>

#include "vm/compiler/backend/block_builder.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/il_test_helper.h"
#include "vm/unit_test.h"
#include "vm/zone_text_buffer.h"

namespace dart {

class DummyDef : public Definition {
 public:
  explicit DummyDef(
      Zone* zone,
      std::initializer_list<std::pair<Definition*, Location>> inputs,
      Location output,
      LocationSummary::ContainsCall contains_call = LocationSummary::kNoCall)
      : inputs_(inputs.size()),
        summary_(new LocationSummary(zone,
                                     inputs.size(),
                                     /*temp_count=*/0,
                                     contains_call)) {
    intptr_t index = 0;
    for (auto [defn, loc] : inputs) {
      auto v = new Value(defn);
      summary_->set_in(index, loc);
      v->set_use_index(index);
      v->set_instruction(this);
      inputs_.Add(v);
      index++;
    }
    summary_->set_out(0, output);
  }

  LocationSummary* MakeLocationSummary(Zone* zone, bool opt) const {
    return summary_;
  }

  virtual void Accept(InstructionVisitor* visitor) { UNREACHABLE(); }

  virtual Tag tag() const { return Instruction::kRedefinition; }

  virtual const char* DebugName() const { return "DummyDef"; }

  virtual intptr_t InputCount() const { return inputs_.length(); }
  virtual Value* InputAt(intptr_t i) const { return inputs_[i]; }

  virtual bool MayThrow() const { return false; }
  virtual bool ComputeCanDeoptimize() const { return false; }
  virtual bool HasUnknownSideEffects() const { return false; }

 private:
  virtual void RawSetInputAt(intptr_t i, Value* value) { inputs_[i] = value; }

  GrowableArray<Value*> inputs_;
  LocationSummary* const summary_;

  DISALLOW_COPY_AND_ASSIGN(DummyDef);
};

ISOLATE_UNIT_TEST_CASE(LinearScan_TestSameAsFirstOrSecondFlip) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto zone = H.flow_graph()->zone();

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  DummyDef* lhs;
  DummyDef* rhs;
  DummyDef* binop;

  {
    BlockBuilder builder(H.flow_graph(), b1);

    lhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    rhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    binop = builder.AddDefinition(
        new DummyDef(zone,
                     {{lhs, Location::RequiresRegister()},
                      {rhs, Location::RequiresRegister()}},
                     Location::SameAsFirstOrSecondInput()));
    // Left hand side of the binary operation is still needed after it.
    builder.AddInstruction(
        new DummyDef(zone, {{lhs, Location::RequiresRegister()}}, Location()));
    builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(binop), S.GetNextDeoptId()));
  }
  H.FinishGraph();

  FlowGraphPrinter::PrintGraph("before regalloc", H.flow_graph());

  H.flow_graph()->InsertMoveArguments();
  // Ensure loop hierarchy has been computed.
  H.flow_graph()->GetLoopHierarchy();
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*H.flow_graph());
  allocator.AllocateRegisters();

  // There should be no parallel move between binop and rhs and inputs
  // to binop should be flipped.
  EXPECT_PROPERTY(binop->previous(),
                  &it == rhs || (it.IsParallelMove() &&
                                 it.AsParallelMove()->IsRedundant() &&
                                 it.previous() == rhs));
  EXPECT_PROPERTY(binop->InputAt(0)->definition(), &it == rhs);
  EXPECT_PROPERTY(binop->InputAt(1)->definition(), &it == lhs);
}

ISOLATE_UNIT_TEST_CASE(LinearScan_TestSameAsFirstOrSecondNoFlip) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto zone = H.flow_graph()->zone();

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  DummyDef* lhs;
  DummyDef* rhs;
  DummyDef* binop;

  {
    BlockBuilder builder(H.flow_graph(), b1);

    lhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    rhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    binop = builder.AddDefinition(
        new DummyDef(zone,
                     {{lhs, Location::RequiresRegister()},
                      {rhs, Location::RequiresRegister()}},
                     Location::SameAsFirstOrSecondInput()));
    // Right hand side of the binary operation is still needed after it.
    builder.AddInstruction(
        new DummyDef(zone, {{rhs, Location::RequiresRegister()}}, Location()));
    builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(binop), S.GetNextDeoptId()));
  }
  H.FinishGraph();

  H.flow_graph()->InsertMoveArguments();
  // Ensure loop hierarchy has been computed.
  H.flow_graph()->GetLoopHierarchy();
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*H.flow_graph());
  allocator.AllocateRegisters();

  // There should be no parallel move between binop and rhs and inputs
  // to binop should *not* be flipped.
  EXPECT_PROPERTY(binop->previous(),
                  &it == rhs || (it.IsParallelMove() &&
                                 it.AsParallelMove()->IsRedundant() &&
                                 it.previous() == rhs));
  EXPECT_PROPERTY(binop->InputAt(0)->definition(), &it == lhs);
  EXPECT_PROPERTY(binop->InputAt(1)->definition(), &it == rhs);
}

ISOLATE_UNIT_TEST_CASE(LinearScan_TestSameAsFirstOrSecondNoFlip2) {
  using compiler::BlockBuilder;
  CompilerState S(thread, /*is_aot=*/false, /*is_optimizing=*/true);
  FlowGraphBuilderHelper H;

  auto zone = H.flow_graph()->zone();

  auto b1 = H.flow_graph()->graph_entry()->normal_entry();

  DummyDef* lhs;
  DummyDef* rhs;
  DummyDef* binop;

  {
    BlockBuilder builder(H.flow_graph(), b1);

    lhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    rhs = builder.AddDefinition(
        new DummyDef(zone, {}, Location::RequiresRegister()));
    binop = builder.AddDefinition(
        new DummyDef(zone,
                     {{lhs, Location::RequiresRegister()},
                      {rhs, Location::RequiresRegister()}},
                     Location::SameAsFirstOrSecondInput()));
    // Both right and left hand sides of the binary operation are still needed
    // after it.
    builder.AddInstruction(
        new DummyDef(zone, {{rhs, Location::RequiresRegister()}}, Location()));
    builder.AddInstruction(
        new DummyDef(zone, {{lhs, Location::RequiresRegister()}}, Location()));
    builder.AddInstruction(new DartReturnInstr(
        InstructionSource(), new Value(binop), S.GetNextDeoptId()));
  }
  H.FinishGraph();

  H.flow_graph()->InsertMoveArguments();
  // Ensure loop hierarchy has been computed.
  H.flow_graph()->GetLoopHierarchy();
  // Perform register allocation on the SSA graph.
  FlowGraphAllocator allocator(*H.flow_graph());
  allocator.AllocateRegisters();

  // There should be a parallel move between binop and rhs and inputs
  // to binop should *not* be flipped.
  EXPECT_PROPERTY(binop->previous(), it.IsParallelMove());
  EXPECT_PROPERTY(binop->InputAt(0)->definition(), &it == lhs);
  EXPECT_PROPERTY(binop->InputAt(1)->definition(), &it == rhs);
}

}  // namespace dart
