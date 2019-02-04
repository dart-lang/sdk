// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/compiler/backend/il.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->

namespace dart {

DECLARE_FLAG(bool, emit_edge_counters);
DECLARE_FLAG(int, optimization_counter_threshold);

// List of instructions that are still unimplemented by DBC backend.
#define FOR_EACH_UNIMPLEMENTED_INSTRUCTION(M)                                  \
  M(BinaryInt32Op)                                                             \
  M(BinaryUint32Op)                                                            \
  M(BoxInt64)                                                                  \
  M(CheckCondition)                                                            \
  M(DoubleToInteger)                                                           \
  M(ExtractNthOutput)                                                          \
  M(GuardFieldClass)                                                           \
  M(GuardFieldLength)                                                          \
  M(GuardFieldType)                                                            \
  M(IfThenElse)                                                                \
  M(Int32ToDouble)                                                             \
  M(LoadCodeUnits)                                                             \
  M(ShiftUint32Op)                                                             \
  M(SpeculativeShiftUint32Op)                                                  \
  M(TruncDivMod)                                                               \
  M(UnaryUint32Op)                                                             \
  M(UnboxedIntConverter)

// List of instructions that are not used by DBC.
// Things we aren't planning to implement for DBC:
// - Unboxed SIMD,
// - Unboxed Mint,
// - Optimized RegExps,
// - Precompilation.
#define FOR_EACH_UNREACHABLE_INSTRUCTION(M)                                    \
  M(CaseInsensitiveCompareUC16)                                                \
  M(GenericCheckBound)                                                         \
  M(CheckNull)                                                                 \
  M(IndirectGoto)                                                              \
  M(Int64ToDouble)                                                             \
  M(BinaryInt64Op)                                                             \
  M(ShiftInt64Op)                                                              \
  M(SpeculativeShiftInt64Op)                                                   \
  M(UnaryInt64Op)                                                              \
  M(CheckedSmiOp)                                                              \
  M(CheckedSmiComparison)                                                      \
  M(SimdOp)

// Location summaries actually are not used by the unoptimizing DBC compiler
// because we don't allocate any registers.
static LocationSummary* CreateLocationSummary(
    Zone* zone,
    intptr_t num_inputs,
    Location output = Location::NoLocation(),
    LocationSummary::ContainsCall contains_call = LocationSummary::kNoCall,
    intptr_t num_temps = 0) {
  LocationSummary* locs =
      new (zone) LocationSummary(zone, num_inputs, num_temps, contains_call);
  for (intptr_t i = 0; i < num_inputs; i++) {
    locs->set_in(i, (contains_call == LocationSummary::kNoCall)
                        ? Location::RequiresRegister()
                        : Location::RegisterLocation(i));
  }
  for (intptr_t i = 0; i < num_temps; i++) {
    locs->set_temp(i, Location::RequiresRegister());
  }
  if (!output.IsInvalid()) {
    // For instructions that call we default to returning result in R0.
    locs->set_out(0, output);
  }
  return locs;
}

#define DEFINE_MAKE_LOCATION_SUMMARY(Name, ...)                                \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    return CreateLocationSummary(zone, __VA_ARGS__);                           \
  }

#define EMIT_NATIVE_CODE(Name, ...)                                            \
  DEFINE_MAKE_LOCATION_SUMMARY(Name, __VA_ARGS__);                             \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler)

#define DEFINE_UNIMPLEMENTED_MAKE_LOCATION_SUMMARY(Name)                       \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    if (!opt) UNIMPLEMENTED();                                                 \
    return NULL;                                                               \
  }

#define DEFINE_UNREACHABLE_MAKE_LOCATION_SUMMARY(Name)                         \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    UNREACHABLE();                                                             \
    return NULL;                                                               \
  }

#define DEFINE_UNIMPLEMENTED_EMIT_NATIVE_CODE(Name)                            \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler) {              \
    UNIMPLEMENTED();                                                           \
  }

#define DEFINE_UNREACHABLE_EMIT_NATIVE_CODE(Name)                              \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler) {              \
    UNREACHABLE();                                                             \
  }

#define DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(Name)                            \
  void Name##Instr::EmitBranchCode(FlowGraphCompiler*, BranchInstr*) {         \
    UNIMPLEMENTED();                                                           \
  }                                                                            \
  Condition Name##Instr::EmitComparisonCode(FlowGraphCompiler*,                \
                                            BranchLabels) {                    \
    UNIMPLEMENTED();                                                           \
    return NEXT_IS_TRUE;                                                       \
  }

#define DEFINE_UNIMPLEMENTED(Name)                                             \
  DEFINE_UNIMPLEMENTED_MAKE_LOCATION_SUMMARY(Name)                             \
  DEFINE_UNIMPLEMENTED_EMIT_NATIVE_CODE(Name)

FOR_EACH_UNIMPLEMENTED_INSTRUCTION(DEFINE_UNIMPLEMENTED)

#undef DEFINE_UNIMPLEMENTED

#define DEFINE_UNREACHABLE(Name)                                               \
  DEFINE_UNREACHABLE_MAKE_LOCATION_SUMMARY(Name)                               \
  DEFINE_UNREACHABLE_EMIT_NATIVE_CODE(Name)

FOR_EACH_UNREACHABLE_INSTRUCTION(DEFINE_UNREACHABLE)

#undef DEFINE_UNREACHABLE

// Only used in AOT compilation.
DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(CheckedSmiComparison)

EMIT_NATIVE_CODE(InstanceOf,
                 3,
                 Location::SameAsFirstInput(),
                 LocationSummary::kCall) {
  SubtypeTestCache& test_cache = SubtypeTestCache::Handle();
  if (!type().IsVoidType() && type().IsInstantiated()) {
    test_cache = SubtypeTestCache::New();
  }

  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());  // Value.
    __ Push(locs()->in(1).reg());  // Instantiator type arguments.
    __ Push(locs()->in(2).reg());  // Function type arguments.
  }

  __ PushConstant(type());
  __ PushConstant(test_cache);
  __ InstanceOf();
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

DEFINE_MAKE_LOCATION_SUMMARY(AssertAssignable,
                             3,
                             Location::SameAsFirstInput(),
                             LocationSummary::kCall);

DEFINE_MAKE_LOCATION_SUMMARY(AssertSubtype,
                             2,
                             Location::NoLocation(),
                             LocationSummary::kCall);

EMIT_NATIVE_CODE(AssertBoolean,
                 1,
                 Location::SameAsFirstInput(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }
  __ AssertBoolean(0);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
  if (compiler->is_optimizing()) {
    __ Drop1();
  }
}

EMIT_NATIVE_CODE(PolymorphicInstanceCall,
                 0,
                 Location::RegisterLocation(0),
                 LocationSummary::kCall) {
  const Array& arguments_descriptor =
      Array::Handle(instance_call()->GetArgumentsDescriptor());
  const intptr_t argdesc_kidx = __ AddConstant(arguments_descriptor);

  // Push the target onto the stack.
  const intptr_t length = targets_.length();
  if (!Utils::IsUint(8, length)) {
    Unsupported(compiler);
    UNREACHABLE();
  }
  bool using_ranges = false;
  for (intptr_t i = 0; i < length; i++) {
    if (!targets_[i].IsSingleCid()) {
      using_ranges = true;
      break;
    }
  }

  if (using_ranges) {
    __ PushPolymorphicInstanceCallByRange(
        instance_call()->ArgumentCountWithoutTypeArgs(), length);
  } else {
    __ PushPolymorphicInstanceCall(
        instance_call()->ArgumentCountWithoutTypeArgs(), length);
  }
  for (intptr_t i = 0; i < length; i++) {
    const Function& target = *targets_.TargetAt(i)->target;

    __ Nop(compiler->ToEmbeddableCid(targets_[i].cid_start, this));
    if (using_ranges) {
      __ Nop(compiler->ToEmbeddableCid(1 + targets_[i].Extent(), this));
    }
    __ Nop(__ AddConstant(target));
  }
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptPolymorphicInstanceCallTestFail,
                      0);

  // Call the function.
  __ StaticCall(instance_call()->ArgumentCount(), argdesc_kidx);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 instance_call()->token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
  __ PopLocal(locs()->out(0).reg());
}

EMIT_NATIVE_CODE(LoadIndexedUnsafe, 1, Location::RegisterLocation(0)) {
  ASSERT(base_reg() == FPREG);

  ASSERT(offset_ % kWordSize == 0);
  const intptr_t slot_offset = offset_ / kWordSize;
  ASSERT(Utils::IsInt(8, slot_offset));

  if (compiler->is_optimizing()) {
    const Register index = locs()->in(0).reg();
    const Register result = locs()->out(0).reg();
    __ LoadFpRelativeSlotOpt(result, index, slot_offset);
  } else {
    __ LoadFpRelativeSlot(slot_offset);
  }
}

EMIT_NATIVE_CODE(StoreIndexedUnsafe, 2, Location::RegisterLocation(0)) {
  ASSERT(base_reg() == FPREG);

  ASSERT(offset_ % kWordSize == 0);
  const intptr_t slot_offset = offset_ / kWordSize;
  ASSERT(Utils::IsInt(8, slot_offset));

  if (compiler->is_optimizing()) {
    const Register index = locs()->in(kIndexPos).reg();
    const Register value = locs()->in(kValuePos).reg();
    __ StoreFpRelativeSlotOpt(value, index, slot_offset);
  } else {
    __ StoreFpRelativeSlot(slot_offset);
  }
}

EMIT_NATIVE_CODE(TailCall,
                 1,
                 Location::NoLocation(),
                 LocationSummary::kNoCall,
                 1) {
  if (compiler->is_optimizing()) {
    const Register arg_desc = locs()->in(0).reg();
    const Register temp = locs()->temp(0).reg();
    __ LoadConstant(temp, code());
    __ TailCallOpt(arg_desc, temp);
  } else {
    __ PushConstant(code());
    __ TailCall();
  }
}

EMIT_NATIVE_CODE(Stop, 0) {
  __ Stop(message());
}

EMIT_NATIVE_CODE(CheckStackOverflow,
                 0,
                 Location::NoLocation(),
                 LocationSummary::kCall) {
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ CheckStackAlwaysExit();
  } else {
    __ CheckStack();
  }
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kNoResult);
}

EMIT_NATIVE_CODE(PushArgument, 1) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }
}

EMIT_NATIVE_CODE(LoadLocal, 0) {
  ASSERT(!compiler->is_optimizing());
  const intptr_t slot_index =
      compiler::target::frame_layout.FrameSlotForVariable(&local());
  __ Push(LocalVarIndex(0, slot_index));
}

EMIT_NATIVE_CODE(StoreLocal, 0) {
  ASSERT(!compiler->is_optimizing());
  const intptr_t slot_index =
      compiler::target::frame_layout.FrameSlotForVariable(&local());
  if (HasTemp()) {
    __ StoreLocal(LocalVarIndex(0, slot_index));
  } else {
    __ PopLocal(LocalVarIndex(0, slot_index));
  }
}

EMIT_NATIVE_CODE(LoadClassId, 1, Location::RequiresRegister()) {
  if (compiler->is_optimizing()) {
    __ LoadClassId(locs()->out(0).reg(), locs()->in(0).reg());
  } else {
    __ LoadClassIdTOS();
  }
}

EMIT_NATIVE_CODE(Constant, 0, Location::RequiresRegister()) {
  if (compiler->is_optimizing()) {
    if (locs()->out(0).IsRegister()) {
      __ LoadConstant(locs()->out(0).reg(), value());
    }
  } else {
    __ PushConstant(value());
  }
}

EMIT_NATIVE_CODE(UnboxedConstant, 0, Location::RequiresRegister()) {
  // The register allocator drops constant definitions that have no uses.
  if (locs()->out(0).IsInvalid()) {
    return;
  }
  if (representation_ != kUnboxedDouble) {
    Unsupported(compiler);
    UNREACHABLE();
  }
  const Register result = locs()->out(0).reg();
  if (Utils::DoublesBitEqual(Double::Cast(value()).value(), 0.0)) {
    __ BitXor(result, result, result);
  } else {
    __ LoadConstant(result, value());
    __ UnboxDouble(result, result);
  }
}

EMIT_NATIVE_CODE(Return, 1) {
  if (compiler->is_optimizing()) {
    __ Return(locs()->in(0).reg());
  } else {
    __ ReturnTOS();
  }
}

LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(

    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  for (intptr_t i = 0; i < kNumInputs; i++) {
    locs->set_in(i, Location::RequiresRegister());
  }
  for (intptr_t i = 0; i < kNumTemps; i++) {
    locs->set_temp(i, Location::RequiresRegister());
  }
  return locs;
}

void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (compiler->is_optimizing()) {
    __ LoadConstant(locs()->temp(0).reg(),
                    Field::ZoneHandle(field().Original()));
    __ StoreField(locs()->temp(0).reg(),
                  Field::static_value_offset() / kWordSize,
                  locs()->in(0).reg());
  } else {
    const intptr_t kidx = __ AddConstant(field());
    __ StoreStaticTOS(kidx);
  }
}

EMIT_NATIVE_CODE(LoadStaticField, 1, Location::RequiresRegister()) {
  if (compiler->is_optimizing()) {
    __ LoadField(locs()->out(0).reg(), locs()->in(0).reg(),
                 Field::static_value_offset() / kWordSize);
  } else {
    const intptr_t kidx = __ AddConstant(StaticField());
    __ PushStatic(kidx);
  }
}

EMIT_NATIVE_CODE(InitStaticField,
                 1,
                 Location::NoLocation(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
    __ InitStaticTOS();
  } else {
    __ InitStaticTOS();
  }
  compiler->RecordAfterCall(this, FlowGraphCompiler::kNoResult);
}

EMIT_NATIVE_CODE(ClosureCall,
                 1,
                 Location::RegisterLocation(0),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }

  const Array& arguments_descriptor =
      Array::ZoneHandle(GetArgumentsDescriptor());
  const intptr_t argdesc_kidx =
      compiler->assembler()->AddConstant(arguments_descriptor);
  __ StaticCall(ArgumentCount(), argdesc_kidx);
  compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (true_condition == NEXT_IS_TRUE) {
    // NEXT_IS_TRUE indicates that the preceeding test expects the true case
    // to be in the subsequent instruction, which it skips if the test fails.
    __ Jump(labels.true_label);
    if (labels.fall_through != labels.false_label) {
      // The preceeding Jump instruction will be skipped if the test fails.
      // If we aren't falling through to the false case, then we have to do
      // a Jump to it here.
      __ Jump(labels.false_label);
    }
  } else {
    ASSERT(true_condition == NEXT_IS_FALSE);
    // NEXT_IS_FALSE indicates that the preceeding test has been flipped and
    // expects the false case to be in the subsequent instruction, which it
    // skips if the test succeeds.
    __ Jump(labels.false_label);
    if (labels.fall_through != labels.true_label) {
      // The preceeding Jump instruction will be skipped if the test succeeds.
      // If we aren't falling through to the true case, then we have to do
      // a Jump to it here.
      __ Jump(labels.true_label);
    }
  }
}

Condition StrictCompareInstr::GetNextInstructionCondition(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  return (labels.fall_through == labels.false_label) ? NEXT_IS_TRUE
                                                     : NEXT_IS_FALSE;
}

Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  ASSERT((kind() == Token::kNE_STRICT) || (kind() == Token::kEQ_STRICT));

  Token::Kind comparison;
  Condition condition;
  if (labels.fall_through == labels.false_label) {
    condition = NEXT_IS_TRUE;
    comparison = kind();
  } else {
    // Flip comparison to save a jump.
    condition = NEXT_IS_FALSE;
    comparison =
        (kind() == Token::kEQ_STRICT) ? Token::kNE_STRICT : Token::kEQ_STRICT;
  }

  if (!compiler->is_optimizing()) {
    const SimulatorBytecode::Opcode eq_op =
        needs_number_check() ? SimulatorBytecode::kIfEqStrictNumTOS
                             : SimulatorBytecode::kIfEqStrictTOS;
    const SimulatorBytecode::Opcode ne_op =
        needs_number_check() ? SimulatorBytecode::kIfNeStrictNumTOS
                             : SimulatorBytecode::kIfNeStrictTOS;
    __ Emit(comparison == Token::kEQ_STRICT ? eq_op : ne_op);
  } else {
    const SimulatorBytecode::Opcode eq_op =
        needs_number_check() ? SimulatorBytecode::kIfEqStrictNum
                             : SimulatorBytecode::kIfEqStrict;
    const SimulatorBytecode::Opcode ne_op =
        needs_number_check() ? SimulatorBytecode::kIfNeStrictNum
                             : SimulatorBytecode::kIfNeStrict;
    __ Emit(SimulatorBytecode::Encode(
        (comparison == Token::kEQ_STRICT) ? eq_op : ne_op, locs()->in(0).reg(),
        locs()->in(1).reg()));
  }

  if (needs_number_check() && token_pos().IsReal()) {
    compiler->RecordSafepoint(locs());
    compiler->AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall, deopt_id_,
                                   token_pos());
  }

  return condition;
}

DEFINE_MAKE_LOCATION_SUMMARY(StrictCompare,
                             2,
                             Location::RequiresRegister(),
                             needs_number_check() ? LocationSummary::kCall
                                                  : LocationSummary::kNoCall)

void ComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                     BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != INVALID_CONDITION) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
}

void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition =
      this->GetNextInstructionCondition(compiler, labels);
  if (true_condition == INVALID_CONDITION || !compiler->is_optimizing() ||
      is_true.IsLinked() || is_false.IsLinked()) {
    Condition actual_condition = EmitComparisonCode(compiler, labels);
    ASSERT(actual_condition == true_condition);
    if (true_condition != INVALID_CONDITION) {
      EmitBranchOnCondition(compiler, true_condition, labels);
    }
    Label done;
    __ Bind(&is_false);
    __ PushConstant(Bool::False());
    __ Jump(&done);
    __ Bind(&is_true);
    __ PushConstant(Bool::True());
    __ Bind(&done);
  } else {
    const Register result = this->locs()->out(0).reg();
    bool next_is_true = true_condition == NEXT_IS_TRUE;
    __ LoadConstant(result, Bool::Get(!next_is_true));
    Condition actual_condition = EmitComparisonCode(compiler, labels);
    ASSERT(actual_condition == true_condition);
    // Although we have a condition to branch on, the comparison code may also
    // have contained a direct branch to one of the labels, so they may need to
    // be bound.
    if (next_is_true && is_true.IsLinked()) {
      __ Bind(&is_true);
    } else if (!next_is_true && is_false.IsLinked()) {
      __ Bind(&is_false);
    }
    // This instruction is conditionally skipped by EmitComparisonCode.
    __ LoadConstant(result, Bool::Get(next_is_true));
    // If the other label is linked we need to bind it and emit code that loads
    // the correct boolean.
    if ((next_is_true && is_false.IsLinked()) ||
        (!next_is_true && is_true.IsLinked())) {
      Label done;
      __ Jump(&done);
      __ Bind(next_is_true ? &is_false : &is_true);
      __ LoadConstant(result, Bool::Get(!next_is_true));
      __ Bind(&done);
    }
  }
}

LocationSummary* BranchInstr::MakeLocationSummary(

    Zone* zone,
    bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  if (!comparison()->HasLocs()) {
    return NULL;
  }
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}

void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
}

EMIT_NATIVE_CODE(Goto, 0) {
  if (!compiler->is_optimizing()) {
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, GetDeoptId(),
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
  // We can fall through if the successor is the next block in the list.
  // Otherwise, we need a jump.
  if (!compiler->CanFallThroughTo(successor())) {
    __ Jump(compiler->GetJumpLabel(successor()));
  }
}

Condition TestSmiInstr::GetNextInstructionCondition(FlowGraphCompiler* compiler,
                                                    BranchLabels labels) {
  ASSERT((kind() == Token::kEQ) || (kind() == Token::kNE));
  return (kind() == Token::kEQ) ? NEXT_IS_TRUE : NEXT_IS_FALSE;
}

Condition TestSmiInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  ASSERT((kind() == Token::kEQ) || (kind() == Token::kNE));
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  __ TestSmi(left, right);
  return (kind() == Token::kEQ) ? NEXT_IS_TRUE : NEXT_IS_FALSE;
}

DEFINE_MAKE_LOCATION_SUMMARY(TestSmi,
                             2,
                             Location::RequiresRegister(),
                             LocationSummary::kNoCall)

Condition TestCidsInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                            BranchLabels labels) {
  ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
  const Register value = locs()->in(0).reg();
  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;

  const ZoneGrowableArray<intptr_t>& data = cid_results();
  const intptr_t num_cases = data.length() / 2;
  ASSERT(num_cases <= 255);
  __ TestCids(value, num_cases);

  bool result = false;
  for (intptr_t i = 0; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    result = data[i + 1] == true_result;
    __ Nop(result ? 1 : 0, compiler->ToEmbeddableCid(test_cid, this));
  }

  // No match found, deoptimize or default action.
  if (CanDeoptimize()) {
    compiler->EmitDeopt(deopt_id(), ICData::kDeoptTestCids,
                        licm_hoisted_ ? ICData::kHoisted : 0);
  } else {
    // If the cid is not in the list, jump to the opposite label from the cids
    // that are in the list.  These must be all the same (see asserts in the
    // constructor).
    Label* target = result ? labels.false_label : labels.true_label;
    __ Jump(target);
  }

  return NEXT_IS_TRUE;
}

Condition TestCidsInstr::GetNextInstructionCondition(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  return NEXT_IS_TRUE;
}

DEFINE_MAKE_LOCATION_SUMMARY(TestCids,
                             1,
                             Location::RequiresRegister(),
                             LocationSummary::kNoCall)

EMIT_NATIVE_CODE(CreateArray,
                 2,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    const Register length = locs()->in(kLengthPos).reg();
    const Register type_arguments = locs()->in(kElementTypePos).reg();
    const Register out = locs()->out(0).reg();
    __ CreateArrayOpt(out, length, type_arguments);
    __ Push(type_arguments);
    __ Push(length);
    __ CreateArrayTOS();
    compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
    __ PopLocal(out);
  } else {
    __ CreateArrayTOS();
    compiler->RecordAfterCall(this, FlowGraphCompiler::kHasResult);
  }
}

EMIT_NATIVE_CODE(StoreIndexed,
                 3,
                 Location::NoLocation(),
                 LocationSummary::kNoCall,
                 1) {
  if (!compiler->is_optimizing()) {
    ASSERT(class_id() == kArrayCid);
    __ StoreIndexedTOS();
    return;
  }
  const Register array = locs()->in(kArrayPos).reg();
  const Register index = locs()->in(kIndexPos).reg();
  const Register value = locs()->in(kValuePos).reg();
  const Register temp = locs()->temp(0).reg();
  switch (class_id()) {
    case kArrayCid:
      __ StoreIndexed(array, index, value);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataInt8ArrayCid:
    case kExternalOneByteStringCid:
    case kExternalTypedDataUint8ArrayCid:
      ASSERT(index_scale() == 1);
      if (IsExternal()) {
        __ StoreIndexedExternalUint8(array, index, value);
      } else {
        __ StoreIndexedUint8(array, index, value);
      }
      break;
    case kOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ StoreIndexedOneByteString(array, index, value);
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (IsExternal()) {
        Unsupported(compiler);
        UNREACHABLE();
      }
      if (index_scale() == 1) {
        __ StoreIndexedUint32(array, index, value);
      } else {
        __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
        __ StoreIndexedUint32(array, temp, value);
      }
      break;
    }
    case kTypedDataFloat32ArrayCid:
      if (IsExternal()) {
        Unsupported(compiler);
        UNREACHABLE();
      }
      if (index_scale() == 1) {
        __ StoreIndexedFloat32(array, index, value);
      } else if (index_scale() == 4) {
        __ StoreIndexed4Float32(array, index, value);
      } else {
        __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
        __ StoreIndexedFloat32(array, temp, value);
      }
      break;
    case kTypedDataFloat64ArrayCid:
      if (IsExternal()) {
        Unsupported(compiler);
        UNREACHABLE();
      }
      if (index_scale() == 1) {
        __ StoreIndexedFloat64(array, index, value);
      } else if (index_scale() == 8) {
        __ StoreIndexed8Float64(array, index, value);
      } else {
        __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
        __ StoreIndexedFloat64(array, temp, value);
      }
      break;
    default:
      Unsupported(compiler);
      UNREACHABLE();
      break;
  }
}

EMIT_NATIVE_CODE(LoadIndexed,
                 2,
                 Location::RequiresRegister(),
                 LocationSummary::kNoCall,
                 1) {
  if (compiler->is_optimizing()) {
    ASSERT(compiler->is_optimizing());
    const Register array = locs()->in(0).reg();
    const Register index = locs()->in(1).reg();
    const Register temp = locs()->temp(0).reg();
    const Register result = locs()->out(0).reg();
    switch (class_id()) {
      case kArrayCid:
      case kImmutableArrayCid:
        __ LoadIndexed(result, array, index);
        break;
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalOneByteStringCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        ASSERT(index_scale() == 1);
        if (IsExternal()) {
          __ LoadIndexedExternalUint8(result, array, index);
        } else {
          __ LoadIndexedUint8(result, array, index);
        }
        break;
      case kTypedDataInt8ArrayCid:
        ASSERT(index_scale() == 1);
        if (IsExternal()) {
          __ LoadIndexedExternalInt8(result, array, index);
        } else {
          __ LoadIndexedInt8(result, array, index);
        }
        break;
      case kOneByteStringCid:
        ASSERT(index_scale() == 1);
        __ LoadIndexedOneByteString(result, array, index);
        break;
      case kTwoByteStringCid:
        if (index_scale() != 2) {
          // TODO(zra): Fix-up index.
          Unsupported(compiler);
          UNREACHABLE();
        }
        if (IsExternal()) {
          Unsupported(compiler);
          UNREACHABLE();
        }
        __ LoadIndexedTwoByteString(result, array, index);
        break;
      case kTypedDataInt32ArrayCid:
        ASSERT(representation() == kUnboxedInt32);
        if (IsExternal()) {
          Unsupported(compiler);
          UNREACHABLE();
        }
        if (index_scale() == 1) {
          __ LoadIndexedInt32(result, array, index);
        } else {
          __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
          __ LoadIndexedInt32(result, array, temp);
        }
        break;
      case kTypedDataUint32ArrayCid:
        ASSERT(representation() == kUnboxedUint32);
        if (IsExternal()) {
          Unsupported(compiler);
          UNREACHABLE();
        }
        if (index_scale() == 1) {
          __ LoadIndexedUint32(result, array, index);
        } else {
          __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
          __ LoadIndexedUint32(result, array, temp);
        }
        break;
      case kTypedDataFloat32ArrayCid:
        if (IsExternal()) {
          Unsupported(compiler);
          UNREACHABLE();
        }
        if (index_scale() == 1) {
          __ LoadIndexedFloat32(result, array, index);
        } else if (index_scale() == 4) {
          __ LoadIndexed4Float32(result, array, index);
        } else {
          __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
          __ LoadIndexedFloat32(result, array, temp);
        }
        break;
      case kTypedDataFloat64ArrayCid:
        if (IsExternal()) {
          Unsupported(compiler);
          UNREACHABLE();
        }
        if (index_scale() == 1) {
          __ LoadIndexedFloat64(result, array, index);
        } else if (index_scale() == 8) {
          __ LoadIndexed8Float64(result, array, index);
        } else {
          __ ShlImm(temp, index, Utils::ShiftForPowerOfTwo(index_scale()));
          __ LoadIndexedFloat64(result, array, temp);
        }
        break;
      default:
        Unsupported(compiler);
        UNREACHABLE();
        break;
    }
  } else {
    switch (class_id()) {
      case kArrayCid:
      case kImmutableArrayCid:
        __ LoadIndexedTOS();
        break;
      default:
        Unsupported(compiler);
        UNREACHABLE();
        break;
    }
  }
}

EMIT_NATIVE_CODE(StringInterpolate,
                 1,
                 Location::RegisterLocation(0),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }
  const intptr_t kTypeArgsLen = 0;
  const intptr_t kArgumentCount = 1;
  const Array& arguments_descriptor = Array::Handle(ArgumentsDescriptor::New(
      kTypeArgsLen, kArgumentCount, Object::null_array()));
  __ PushConstant(CallFunction());
  const intptr_t argdesc_kidx = __ AddConstant(arguments_descriptor);
  __ StaticCall(kArgumentCount, argdesc_kidx);
  // Note: can't use RecordAfterCall here because
  // StringInterpolateInstr::ArgumentCount() is 0. However
  // internally it does a call with 1 argument which needs to
  // be reflected in the lazy deoptimization environment.
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCallHelper(token_pos(), deopt_id(), kArgumentCount,
                                  FlowGraphCompiler::kHasResult, locs());
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

EMIT_NATIVE_CODE(NativeCall,
                 0,
                 Location::NoLocation(),
                 LocationSummary::kCall) {
  SetupNative();

  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());

  NativeFunctionWrapper trampoline;
  NativeFunction function;
  if (link_lazily()) {
    trampoline = &NativeEntry::BootstrapNativeCallWrapper;
    function = reinterpret_cast<NativeFunction>(&NativeEntry::LinkNativeCall);
  } else {
    if (is_bootstrap_native()) {
      trampoline = &NativeEntry::BootstrapNativeCallWrapper;
    } else if (is_auto_scope()) {
      trampoline = &NativeEntry::AutoScopeNativeCallWrapper;
    } else {
      trampoline = &NativeEntry::NoScopeNativeCallWrapper;
    }
    function = native_c_function();
  }

  const ExternalLabel trampoline_label(reinterpret_cast<uword>(trampoline));
  const intptr_t trampoline_kidx =
      __ object_pool_builder().FindNativeFunctionWrapper(
          &trampoline_label, ObjectPool::Patchability::kPatchable);
  const ExternalLabel label(reinterpret_cast<uword>(function));
  const intptr_t target_kidx = __ object_pool_builder().FindNativeFunction(
      &label, ObjectPool::Patchability::kPatchable);
  const intptr_t argc_tag_kidx =
      __ object_pool_builder().FindImmediate(static_cast<uword>(argc_tag));
  __ NativeCall(trampoline_kidx, target_kidx, argc_tag_kidx);
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                 token_pos());
}

EMIT_NATIVE_CODE(OneByteStringFromCharCode,
                 1,
                 Location::RequiresRegister(),
                 LocationSummary::kNoCall) {
  ASSERT(compiler->is_optimizing());
  const Register char_code = locs()->in(0).reg();  // Char code is a smi.
  const Register result = locs()->out(0).reg();
  __ OneByteStringFromCharCode(result, char_code);
}

EMIT_NATIVE_CODE(StringToCharCode,
                 1,
                 Location::RequiresRegister(),
                 LocationSummary::kNoCall) {
  ASSERT(cid_ == kOneByteStringCid);
  const Register str = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();  // Result char code is a smi.
  __ StringToCharCode(result, str);
}

EMIT_NATIVE_CODE(AllocateObject,
                 0,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  if (ArgumentCount() == 1) {
    // Allocate with type arguments.
    if (compiler->is_optimizing()) {
      // If we're optimizing, try a streamlined fastpath.
      const intptr_t instance_size = cls().instance_size();
      Isolate* isolate = Isolate::Current();
      if (Heap::IsAllocatableInNewSpace(instance_size) &&
          !cls().TraceAllocation(isolate)) {
        uint32_t tags = 0;
        tags = RawObject::SizeTag::update(instance_size, tags);
        ASSERT(cls().id() != kIllegalCid);
        tags = RawObject::ClassIdTag::update(cls().id(), tags);
        if (Smi::IsValid(tags)) {
          const intptr_t tags_kidx =
              __ AddConstant(Smi::Handle(Smi::New(tags)));
          __ AllocateTOpt(locs()->out(0).reg(), tags_kidx);
          __ Nop(cls().type_arguments_field_offset());
        }
      }
      __ PushConstant(cls());
      __ AllocateT();
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                     token_pos());
      compiler->RecordSafepoint(locs());
      __ PopLocal(locs()->out(0).reg());
    } else {
      __ PushConstant(cls());
      __ AllocateT();
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                     token_pos());
      compiler->RecordSafepoint(locs());
    }
  } else if (compiler->is_optimizing()) {
    // If we're optimizing, try a streamlined fastpath.
    const intptr_t instance_size = cls().instance_size();
    Isolate* isolate = Isolate::Current();
    if (Heap::IsAllocatableInNewSpace(instance_size) &&
        !cls().TraceAllocation(isolate)) {
      uword tags = 0;
      tags = RawObject::SizeTag::update(instance_size, tags);
      ASSERT(cls().id() != kIllegalCid);
      tags = RawObject::ClassIdTag::update(cls().id(), tags);
      // tags also has the initial zero hash code on 64 bit.
      if (Smi::IsValid(tags)) {
        const intptr_t tags_kidx = __ AddConstant(Smi::Handle(Smi::New(tags)));
        __ AllocateOpt(locs()->out(0).reg(), tags_kidx);
      }
    }
    const intptr_t kidx = __ AddConstant(cls());
    __ Allocate(kidx);
    compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                   token_pos());
    compiler->RecordSafepoint(locs());
    __ PopLocal(locs()->out(0).reg());
  } else {
    const intptr_t kidx = __ AddConstant(cls());
    __ Allocate(kidx);
    compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                   token_pos());
    compiler->RecordSafepoint(locs());
  }
}

EMIT_NATIVE_CODE(StoreInstanceField, 2) {
  ASSERT(OffsetInBytes() % kWordSize == 0);
  if (compiler->is_optimizing()) {
    const Register value = locs()->in(1).reg();
    const Register instance = locs()->in(0).reg();
    if (Utils::IsInt(8, OffsetInBytes() / kWordSize)) {
      __ StoreField(instance, OffsetInBytes() / kWordSize, value);
    } else {
      __ StoreFieldExt(instance, value);
      __ Nop(OffsetInBytes() / kWordSize);
    }
  } else {
    __ StoreFieldTOS(OffsetInBytes() / kWordSize);
  }
}

EMIT_NATIVE_CODE(LoadField, 1, Location::RequiresRegister()) {
  ASSERT(OffsetInBytes() % kWordSize == 0);
  if (compiler->is_optimizing()) {
    const Register result = locs()->out(0).reg();
    const Register instance = locs()->in(0).reg();
    if (Utils::IsInt(8, OffsetInBytes() / kWordSize)) {
      __ LoadField(result, instance, OffsetInBytes() / kWordSize);
    } else {
      __ LoadFieldExt(result, instance);
      __ Nop(OffsetInBytes() / kWordSize);
    }
  } else {
    __ LoadFieldTOS(OffsetInBytes() / kWordSize);
  }
}

EMIT_NATIVE_CODE(LoadUntagged, 1, Location::RequiresRegister()) {
  const Register obj = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ LoadUntagged(result, obj, offset() / kWordSize);
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ LoadField(result, obj, offset() / kWordSize);
  }
}

EMIT_NATIVE_CODE(BooleanNegate, 1, Location::RequiresRegister()) {
  if (compiler->is_optimizing()) {
    __ BooleanNegate(locs()->out(0).reg(), locs()->in(0).reg());
  } else {
    __ BooleanNegateTOS();
  }
}

EMIT_NATIVE_CODE(AllocateContext,
                 0,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  ASSERT(!compiler->is_optimizing());
  __ AllocateContext(num_context_variables());
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                 token_pos());
}

EMIT_NATIVE_CODE(AllocateUninitializedContext,
                 0,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  ASSERT(compiler->is_optimizing());
  __ AllocateUninitializedContext(locs()->out(0).reg(),
                                  num_context_variables());
  __ AllocateContext(num_context_variables());
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                 token_pos());
  __ PopLocal(locs()->out(0).reg());
}

EMIT_NATIVE_CODE(CloneContext,
                 1,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }
  __ CloneContext();
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                 token_pos());
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

EMIT_NATIVE_CODE(CatchBlockEntry, 0) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(), try_index(),
                                compiler->assembler()->CodeSize(),
                                handler_token_pos(), is_generated(),
                                catch_handler_types_, needs_stacktrace());
  // On lazy deoptimization we patch the optimized code here to enter the
  // deoptimization stub.
  const intptr_t deopt_id = DeoptId::ToDeoptAfter(GetDeoptId());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id);
  } else {
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id,
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
  __ SetFrame(compiler->StackSize());

  if (!compiler->is_optimizing()) {
    if (raw_exception_var_ != nullptr) {
      __ MoveSpecial(
          LocalVarIndex(0, compiler::target::frame_layout.FrameSlotForVariable(
                               raw_exception_var_)),
          Simulator::kExceptionSpecialIndex);
    }
    if (raw_stacktrace_var_ != nullptr) {
      __ MoveSpecial(
          LocalVarIndex(0, compiler::target::frame_layout.FrameSlotForVariable(
                               raw_stacktrace_var_)),
          Simulator::kStackTraceSpecialIndex);
    }
  }
}

EMIT_NATIVE_CODE(Throw, 0, Location::NoLocation(), LocationSummary::kCall) {
  __ Throw(0);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kNoResult);
  __ Trap();
}

EMIT_NATIVE_CODE(ReThrow, 0, Location::NoLocation(), LocationSummary::kCall) {
  compiler->SetNeedsStackTrace(catch_try_index());
  __ Throw(1);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  compiler->RecordAfterCall(this, FlowGraphCompiler::kNoResult);
  __ Trap();
}

EMIT_NATIVE_CODE(InstantiateType,
                 2,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());  // Instantiator type arguments.
    __ Push(locs()->in(1).reg());  // Function type arguments.
  }
  __ InstantiateType(__ AddConstant(type()));
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

EMIT_NATIVE_CODE(InstantiateTypeArguments,
                 2,
                 Location::RequiresRegister(),
                 LocationSummary::kCall) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());  // Instantiator type arguments.
    __ Push(locs()->in(1).reg());  // Function type arguments.
  }
  __ InstantiateTypeArgumentsTOS(
      type_arguments().IsRawWhenInstantiatedFromRaw(type_arguments().Length()),
      __ AddConstant(type_arguments()));
  compiler->RecordSafepoint(locs());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id(),
                                 token_pos());
  if (compiler->is_optimizing()) {
    __ PopLocal(locs()->out(0).reg());
  }
}

void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ DebugStep();
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, token_pos());
}

void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  BlockEntryInstr* entry = normal_entry();
  if (entry == nullptr) entry = osr_entry();

  if (!compiler->CanFallThroughTo(entry)) {
    __ Jump(compiler->GetJumpLabel(entry));
  }
}

LocationSummary* Instruction::MakeCallSummary(Zone* zone) {
  LocationSummary* result =
      new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
  // TODO(vegorov) support allocating out registers for calls.
  // Currently we require them to be fixed.
  result->set_out(0, Location::RegisterLocation(0));
  return result;
}

CompileType BinaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType ShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType SpeculativeShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType UnaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}

CompileType LoadIndexedInstr::ComputeType() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
      return CompileType::Dynamic();

    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return CompileType::FromCid(kDoubleCid);
    case kTypedDataFloat32x4ArrayCid:
      return CompileType::FromCid(kFloat32x4Cid);
    case kTypedDataInt32x4ArrayCid:
      return CompileType::FromCid(kInt32x4Cid);
    case kTypedDataFloat64x2ArrayCid:
      return CompileType::FromCid(kFloat64x2Cid);

    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return CompileType::Int();

    default:
      UNREACHABLE();
      return CompileType::Dynamic();
  }
}

Representation LoadIndexedInstr::representation() const {
  switch (class_id_) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
      return kTagged;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNREACHABLE();
      return kTagged;
  }
}

Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) {
    return kNoRepresentation;  // Flexible input representation.
  }
  if (idx == 1) {
    return kTagged;  // Index is a smi.
  }
  ASSERT(idx == 2);
  switch (class_id_) {
    case kArrayCid:
    case kOneByteStringCid:
    case kTwoByteStringCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      return kTagged;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNREACHABLE();
      return kTagged;
  }
}

void Environment::DropArguments(intptr_t argc) {
#if defined(DEBUG)
  // Check that we are in the backend - register allocation has been run.
  ASSERT(locations_ != NULL);

  // Check that we are only dropping a valid number of instructions from the
  // environment.
  ASSERT(argc <= values_.length());
#endif
  values_.TruncateTo(values_.length() - argc);
}

EMIT_NATIVE_CODE(CheckSmi, 1) {
  __ CheckSmi(locs()->in(0).reg());
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptCheckSmi,
                      licm_hoisted_ ? ICData::kHoisted : 0);
}

EMIT_NATIVE_CODE(CheckEitherNonSmi, 2) {
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  __ CheckEitherNonSmi(left, right);
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                      licm_hoisted_ ? ICData::kHoisted : 0);
}

EMIT_NATIVE_CODE(CheckClassId, 1) {
  if (cids_.IsSingleCid()) {
    __ CheckClassId(locs()->in(0).reg(),
                    compiler->ToEmbeddableCid(cids_.cid_start, this));
  } else {
    __ CheckClassIdRange(locs()->in(0).reg(),
                         compiler->ToEmbeddableCid(cids_.cid_start, this));
    __ Nop(compiler->ToEmbeddableCid(cids_.Extent(), this));
  }
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptCheckClass);
}

EMIT_NATIVE_CODE(CheckClass, 1) {
  const Register value = locs()->in(0).reg();
  if (IsNullCheck()) {
    ASSERT(IsDeoptIfNull() || IsDeoptIfNotNull());
    if (IsDeoptIfNull()) {
      __ IfEqNull(value);
    } else {
      __ IfNeNull(value);
    }
  } else {
    ASSERT(!cids_.IsMonomorphic() || !cids_.HasClassId(kSmiCid));
    const intptr_t may_be_smi = cids_.HasClassId(kSmiCid) ? 1 : 0;
    bool is_bit_test = false;
    intptr_t cid_mask = 0;
    if (IsBitTest()) {
      cid_mask = ComputeCidMask();
      is_bit_test = Smi::IsValid(cid_mask);
    }
    if (is_bit_test) {
      intptr_t min = cids_.ComputeLowestCid();
      __ CheckBitTest(value, may_be_smi);
      __ Nop(compiler->ToEmbeddableCid(min, this));
      __ Nop(__ AddConstant(Smi::Handle(Smi::New(cid_mask))));
    } else {
      bool using_ranges = false;
      int smi_adjustment = 0;
      int length = cids_.length();
      for (intptr_t i = 0; i < length; i++) {
        if (!cids_[i].IsSingleCid()) {
          using_ranges = true;
        } else if (cids_[i].cid_start == kSmiCid) {
          ASSERT(cids_[i].cid_end == kSmiCid);  // We are in the else clause.
          ASSERT(smi_adjustment == 0);
          smi_adjustment = 1;
        }
      }

      if (!Utils::IsUint(8, length)) {
        Unsupported(compiler);
        UNREACHABLE();
      }
      if (using_ranges) {
        __ CheckCidsByRange(value, may_be_smi, (length - smi_adjustment) * 2);
      } else {
        __ CheckCids(value, may_be_smi, length - smi_adjustment);
      }
      for (intptr_t i = 0; i < length; i++) {
        intptr_t cid_start = cids_[i].cid_start;
        intptr_t cid_end = cids_[i].cid_end;
        if (cid_start == kSmiCid && cid_end == kSmiCid) {
          ASSERT(smi_adjustment == 1);
          continue;
        }
        __ Nop(compiler->ToEmbeddableCid(cid_start, this));
        if (using_ranges) {
          __ Nop(compiler->ToEmbeddableCid(1 + cids_[i].Extent(), this));
        }
      }
    }
  }
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptCheckClass,
                      licm_hoisted_ ? ICData::kHoisted : 0);
}

EMIT_NATIVE_CODE(BinarySmiOp, 2, Location::RequiresRegister()) {
  if (compiler->is_optimizing()) {
    const Register left = locs()->in(0).reg();
    const Register right = locs()->in(1).reg();
    const Register out = locs()->out(0).reg();
    const bool can_deopt = CanDeoptimize();
    bool needs_nop = false;
    switch (op_kind()) {
      case Token::kADD:
        __ Add(out, left, right);
        needs_nop = true;
        break;
      case Token::kSUB:
        __ Sub(out, left, right);
        needs_nop = true;
        break;
      case Token::kMUL:
        __ Mul(out, left, right);
        needs_nop = true;
        break;
      case Token::kTRUNCDIV:
        ASSERT(can_deopt);
        __ Div(out, left, right);
        break;
      case Token::kBIT_AND:
        ASSERT(!can_deopt);
        __ BitAnd(out, left, right);
        break;
      case Token::kBIT_OR:
        ASSERT(!can_deopt);
        __ BitOr(out, left, right);
        break;
      case Token::kBIT_XOR:
        ASSERT(!can_deopt);
        __ BitXor(out, left, right);
        break;
      case Token::kMOD:
        __ Mod(out, left, right);
        needs_nop = true;
        break;
      case Token::kSHR:
        __ Shr(out, left, right);
        needs_nop = true;
        break;
      case Token::kSHL:
        __ Shl(out, left, right);
        needs_nop = true;
        break;
      default:
        UNREACHABLE();
    }
    if (can_deopt) {
      compiler->EmitDeopt(deopt_id(), ICData::kDeoptBinarySmiOp);
    } else if (needs_nop) {
      __ Nop(0);
    }
  } else {
    switch (op_kind()) {
      case Token::kADD:
        __ SmiAddTOS();
        break;
      case Token::kSUB:
        __ SmiSubTOS();
        break;
      case Token::kMUL:
        __ SmiMulTOS();
        break;
      case Token::kBIT_AND:
        __ SmiBitAndTOS();
        break;
      default:
        UNIMPLEMENTED();
    }
  }
}

EMIT_NATIVE_CODE(UnarySmiOp, 1, Location::RequiresRegister()) {
  switch (op_kind()) {
    case Token::kNEGATE: {
      __ Neg(locs()->out(0).reg(), locs()->in(0).reg());
      compiler->EmitDeopt(deopt_id(), ICData::kDeoptUnaryOp);
      break;
    }
    case Token::kBIT_NOT:
      __ BitNot(locs()->out(0).reg(), locs()->in(0).reg());
      break;
    default:
      UNREACHABLE();
      break;
  }
}

EMIT_NATIVE_CODE(Box, 1, Location::RequiresRegister(), LocationSummary::kCall) {
  ASSERT(from_representation() == kUnboxedDouble);
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  const intptr_t instance_size = compiler->double_class().instance_size();
  Isolate* isolate = Isolate::Current();
  ASSERT(Heap::IsAllocatableInNewSpace(instance_size));
  if (!compiler->double_class().TraceAllocation(isolate)) {
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    tags = RawObject::ClassIdTag::update(compiler->double_class().id(), tags);
    // tags also has the initial zero hash code on 64 bit.
    if (Smi::IsValid(tags)) {
      const intptr_t tags_kidx = __ AddConstant(Smi::Handle(Smi::New(tags)));
      __ AllocateOpt(out, tags_kidx);
    }
  }
  const intptr_t kidx = __ AddConstant(compiler->double_class());
  __ Allocate(kidx);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther, DeoptId::kNone,
                                 token_pos());
  compiler->RecordSafepoint(locs());
  __ PopLocal(out);
  __ WriteIntoDouble(out, value);
}

EMIT_NATIVE_CODE(Unbox, 1, Location::RequiresRegister()) {
  ASSERT(representation() == kUnboxedDouble);
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t box_cid = BoxCid();
  const Register box = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (value_cid == box_cid) {
    __ UnboxDouble(result, box);
  } else if (CanConvertSmi() && (value_cid == kSmiCid)) {
    __ SmiToDouble(result, box);
  } else if ((value()->Type()->ToNullableCid() == box_cid) &&
             value()->Type()->is_nullable()) {
    __ IfEqNull(box);
    compiler->EmitDeopt(GetDeoptId(), ICData::kDeoptCheckClass);
    __ UnboxDouble(result, box);
  } else {
    __ CheckedUnboxDouble(result, box);
    compiler->EmitDeopt(GetDeoptId(), ICData::kDeoptCheckClass);
  }
}

EMIT_NATIVE_CODE(UnboxInteger32, 1, Location::RequiresRegister()) {
#if defined(ARCH_IS_64_BIT)
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  const bool may_truncate = is_truncating() || !CanDeoptimize();
  __ UnboxInt32(out, value, may_truncate);
  if (CanDeoptimize()) {
    compiler->EmitDeopt(GetDeoptId(), ICData::kDeoptUnboxInteger);
  } else {
    __ Nop(0);
  }
#else
  Unsupported(compiler);
  UNREACHABLE();
#endif  // defined(ARCH_IS_64_BIT)
}

EMIT_NATIVE_CODE(BoxInteger32, 1, Location::RequiresRegister()) {
#if defined(ARCH_IS_64_BIT)
  const Register out = locs()->out(0).reg();
  const Register value = locs()->in(0).reg();
  if (from_representation() == kUnboxedInt32) {
    __ BoxInt32(out, value);
  } else {
    ASSERT(from_representation() == kUnboxedUint32);
    __ BoxUint32(out, value);
  }
#else
  Unsupported(compiler);
  UNREACHABLE();
#endif  // defined(ARCH_IS_64_BIT)
}

EMIT_NATIVE_CODE(DoubleToSmi, 1, Location::RequiresRegister()) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ DoubleToSmi(result, value);
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptDoubleToSmi);
}

EMIT_NATIVE_CODE(SmiToDouble, 1, Location::RequiresRegister()) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ SmiToDouble(result, value);
}

EMIT_NATIVE_CODE(BinaryDoubleOp, 2, Location::RequiresRegister()) {
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kADD:
      __ DAdd(result, left, right);
      break;
    case Token::kSUB:
      __ DSub(result, left, right);
      break;
    case Token::kMUL:
      __ DMul(result, left, right);
      break;
    case Token::kDIV:
      __ DDiv(result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}

Condition DoubleTestOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const Register value = locs()->in(0).reg();
  switch (op_kind()) {
    case MethodRecognizer::kDouble_getIsNaN:
      __ DoubleIsNaN(value);
      break;
    case MethodRecognizer::kDouble_getIsInfinite:
      __ DoubleIsInfinite(value);
      break;
    default:
      UNREACHABLE();
  }
  const bool is_negated = kind() != Token::kEQ;
  return is_negated ? NEXT_IS_FALSE : NEXT_IS_TRUE;
}

Condition DoubleTestOpInstr::GetNextInstructionCondition(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  const bool is_negated = kind() != Token::kEQ;
  return is_negated ? NEXT_IS_FALSE : NEXT_IS_TRUE;
}

DEFINE_MAKE_LOCATION_SUMMARY(DoubleTestOp, 1, Location::RequiresRegister())

EMIT_NATIVE_CODE(UnaryDoubleOp, 1, Location::RequiresRegister()) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ DNeg(result, value);
}

EMIT_NATIVE_CODE(MathUnary, 1, Location::RequiresRegister()) {
  const Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (kind() == MathUnaryInstr::kSqrt) {
    __ DSqrt(result, value);
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    __ DMul(result, value, value);
  } else {
    Unsupported(compiler);
    UNREACHABLE();
  }
}

EMIT_NATIVE_CODE(DoubleToDouble, 1, Location::RequiresRegister()) {
  const Register in = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleTruncate:
      __ DTruncate(result, in);
      break;
    case MethodRecognizer::kDoubleFloor:
      __ DFloor(result, in);
      break;
    case MethodRecognizer::kDoubleCeil:
      __ DCeil(result, in);
      break;
    default:
      UNREACHABLE();
  }
}

EMIT_NATIVE_CODE(DoubleToFloat, 1, Location::RequiresRegister()) {
  const Register in = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ DoubleToFloat(result, in);
}

EMIT_NATIVE_CODE(FloatToDouble, 1, Location::RequiresRegister()) {
  const Register in = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ FloatToDouble(result, in);
}

EMIT_NATIVE_CODE(InvokeMathCFunction,
                 InputCount(),
                 Location::RequiresRegister()) {
  const Register left = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    const Register right = locs()->in(1).reg();
    __ DPow(result, left, right);
  } else if (recognized_kind() == MethodRecognizer::kDoubleMod) {
    const Register right = locs()->in(1).reg();
    __ DMod(result, left, right);
  } else if (recognized_kind() == MethodRecognizer::kMathSin) {
    __ DSin(result, left);
  } else if (recognized_kind() == MethodRecognizer::kMathCos) {
    __ DCos(result, left);
  } else {
    Unsupported(compiler);
    UNREACHABLE();
  }
}

EMIT_NATIVE_CODE(MathMinMax, 2, Location::RequiresRegister()) {
  ASSERT((op_kind() == MethodRecognizer::kMathMin) ||
         (op_kind() == MethodRecognizer::kMathMax));
  const Register left = locs()->in(0).reg();
  const Register right = locs()->in(1).reg();
  const Register result = locs()->out(0).reg();
  if (result_cid() == kDoubleCid) {
    if (op_kind() == MethodRecognizer::kMathMin) {
      __ DMin(result, left, right);
    } else {
      __ DMax(result, left, right);
    }
  } else {
    ASSERT(result_cid() == kSmiCid);
    if (op_kind() == MethodRecognizer::kMathMin) {
      __ Min(result, left, right);
    } else {
      __ Max(result, left, right);
    }
  }
}

static SimulatorBytecode::Opcode OpcodeForSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return SimulatorBytecode::kIfEqStrict;
    case Token::kNE:
      return SimulatorBytecode::kIfNeStrict;
    case Token::kLT:
      return SimulatorBytecode::kIfLt;
    case Token::kGT:
      return SimulatorBytecode::kIfGt;
    case Token::kLTE:
      return SimulatorBytecode::kIfLe;
    case Token::kGTE:
      return SimulatorBytecode::kIfGe;
    default:
      UNREACHABLE();
      return SimulatorBytecode::kTrap;
  }
}

static SimulatorBytecode::Opcode OpcodeForDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return SimulatorBytecode::kIfDEq;
    case Token::kNE:
      return SimulatorBytecode::kIfDNe;
    case Token::kLT:
      return SimulatorBytecode::kIfDLt;
    case Token::kGT:
      return SimulatorBytecode::kIfDGt;
    case Token::kLTE:
      return SimulatorBytecode::kIfDLe;
    case Token::kGTE:
      return SimulatorBytecode::kIfDGe;
    default:
      UNREACHABLE();
      return SimulatorBytecode::kTrap;
  }
}

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     LocationSummary* locs,
                                     Token::Kind kind,
                                     BranchLabels labels) {
  Token::Kind comparison = kind;
  Condition condition = NEXT_IS_TRUE;
  if (labels.fall_through != labels.false_label) {
    // If we aren't falling through to the false label, we can save a Jump
    // instruction in the case that the true case is the fall through by
    // negating the sense of the test such that the instruction following the
    // test is the Jump to the false label.  In the case where both labels are
    // null we don't negate the sense of the test.
    condition = NEXT_IS_FALSE;
    comparison = Token::NegateComparison(kind);
  }
  if (compiler->is_optimizing()) {
    const Register left = locs->in(0).reg();
    const Register right = locs->in(1).reg();
    __ Emit(SimulatorBytecode::Encode(OpcodeForSmiCondition(comparison), left,
                                      right));
    return condition;
  } else {
    switch (kind) {
      case Token::kEQ:
        __ IfEqStrictTOS();
        break;
      case Token::kNE:
        __ IfNeStrictTOS();
        break;
      case Token::kLT:
        __ IfSmiLtTOS();
        break;
      case Token::kLTE:
        __ IfSmiLeTOS();
        break;
      case Token::kGT:
        __ IfSmiGtTOS();
        break;
      case Token::kGTE:
        __ IfSmiGeTOS();
        break;
      default:
        UNIMPLEMENTED();
    }
    return condition;
  }
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        LocationSummary* locs,
                                        Token::Kind kind) {
  const Register left = locs->in(0).reg();
  const Register right = locs->in(1).reg();
  Token::Kind comparison = kind;
  // For double comparisons we can't flip the condition like with smi
  // comparisons because of NaN which will compare false for all except !=
  // operations.
  // TODO(fschneider): Change the block order instead in DBC so that the
  // false block in always the fall-through block.
  Condition condition = NEXT_IS_TRUE;
  __ Emit(SimulatorBytecode::Encode(OpcodeForDoubleCondition(comparison), left,
                                    right));
  return condition;
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}

Condition EqualityCompareInstr::GetNextInstructionCondition(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return (labels.fall_through != labels.false_label) ? NEXT_IS_FALSE
                                                       : NEXT_IS_TRUE;
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return NEXT_IS_TRUE;
  }
}

DEFINE_MAKE_LOCATION_SUMMARY(EqualityCompare, 2, Location::RequiresRegister());

Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, locs(), kind());
  }
}

Condition RelationalOpInstr::GetNextInstructionCondition(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return (labels.fall_through != labels.false_label) ? NEXT_IS_FALSE
                                                       : NEXT_IS_TRUE;
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return NEXT_IS_TRUE;
  }
}

DEFINE_MAKE_LOCATION_SUMMARY(RelationalOp, 2, Location::RequiresRegister())

EMIT_NATIVE_CODE(CheckArrayBound, 2) {
  const Register length = locs()->in(kLengthPos).reg();
  const Register index = locs()->in(kIndexPos).reg();
  const intptr_t index_cid = this->index()->Type()->ToCid();
  if (index_cid != kSmiCid) {
    __ CheckSmi(index);
    compiler->EmitDeopt(deopt_id(), ICData::kDeoptCheckArrayBound,
                        (generalized_ ? ICData::kGeneralized : 0) |
                            (licm_hoisted_ ? ICData::kHoisted : 0));
  }
  __ IfULe(length, index);
  compiler->EmitDeopt(deopt_id(), ICData::kDeoptCheckArrayBound,
                      (generalized_ ? ICData::kGeneralized : 0) |
                          (licm_hoisted_ ? ICData::kHoisted : 0));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
