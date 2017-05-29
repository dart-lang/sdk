// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/intermediate_language.h"

#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/instructions.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register V0.
LocationSummary* Instruction::MakeCallSummary(Zone* zone) {
  LocationSummary* result =
      new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(V0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::AnyOrConstant(value()));
  return locs;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where PushArgument is handled by BindInstr::EmitNativeCode.
  __ Comment("PushArgumentInstr");
  if (compiler->is_optimizing()) {
    Location value = locs()->in(0);
    if (value.IsRegister()) {
      __ Push(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      const intptr_t value_offset = value.ToStackSlotOffset();
      __ LoadFromOffset(TMP, FP, value_offset);
      __ Push(TMP);
    }
  }
}


LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(V0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("ReturnInstr");
  Register result = locs()->in(0).reg();
  ASSERT(result == V0);

  if (compiler->intrinsic_mode()) {
    // Intrinsics don't have a frame.
    __ Ret();
    return;
  }

#if defined(DEBUG)
  Label stack_ok;
  __ Comment("Stack Check");
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ subu(CMPRES1, SP, FP);

  __ BranchEqual(CMPRES1, Immediate(fp_sp_dist), &stack_ok);
  __ break_(0);

  __ Bind(&stack_ok);
#endif
  __ LeaveDartFrameAndReturn();
}


static Condition NegateCondition(Condition condition) {
  switch (condition.rel_op()) {
    case AL:
      condition.set_rel_op(NV);
      break;
    case NV:
      condition.set_rel_op(AL);
      break;
    case EQ:
      condition.set_rel_op(NE);
      break;
    case NE:
      condition.set_rel_op(EQ);
      break;
    case LT:
      condition.set_rel_op(GE);
      break;
    case LE:
      condition.set_rel_op(GT);
      break;
    case GT:
      condition.set_rel_op(LE);
      break;
    case GE:
      condition.set_rel_op(LT);
      break;
    case ULT:
      condition.set_rel_op(UGE);
      break;
    case ULE:
      condition.set_rel_op(UGT);
      break;
    case UGT:
      condition.set_rel_op(ULE);
      break;
    case UGE:
      condition.set_rel_op(ULT);
      break;
    default:
      UNREACHABLE();
  }
  return condition;
}


LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;
  bool swapped = false;
  if (true_value == 0) {
    // Swap values so that false_value is zero.
    intptr_t temp = true_value;
    true_value = false_value;
    false_value = temp;
    swapped = true;
  }

  // Initialize result with the true value.
  __ LoadImmediate(result, Smi::RawValue(true_value));

  // Emit comparison code. This must not overwrite the result register.
  BranchLabels labels = {NULL, NULL, NULL};  // Emit branch-free code.
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);
  if (swapped) {
    true_condition = NegateCondition(true_condition);
  }

  // Evaluate condition and provide result in CMPRES1.
  Register left = true_condition.left();
  Register right = true_condition.right();
  bool zero_is_false = true;  // Zero in CMPRES1 indicates a false condition.
  switch (true_condition.rel_op()) {
    case AL:
      return;  // Result holds true_value.
    case NV:
      __ LoadImmediate(result, false_value);
      return;
    case EQ:
      zero_is_false = false;
    // fall through.
    case NE: {
      if (left == IMM) {
        __ XorImmediate(CMPRES1, right, true_condition.imm());
      } else if (right == IMM) {
        __ XorImmediate(CMPRES1, left, true_condition.imm());
      } else {
        __ xor_(CMPRES1, left, right);
      }
      break;
    }
    case GE:
      zero_is_false = false;
    // fall through.
    case LT: {
      if (left == IMM) {
        __ slti(CMPRES1, right, Immediate(true_condition.imm() + 1));
        zero_is_false = !zero_is_false;
      } else if (right == IMM) {
        __ slti(CMPRES1, left, Immediate(true_condition.imm()));
      } else {
        __ slt(CMPRES1, left, right);
      }
      break;
    }
    case LE:
      zero_is_false = false;
    // fall through.
    case GT: {
      if (left == IMM) {
        __ slti(CMPRES1, right, Immediate(true_condition.imm()));
      } else if (right == IMM) {
        __ slti(CMPRES1, left, Immediate(true_condition.imm() + 1));
        zero_is_false = !zero_is_false;
      } else {
        __ slt(CMPRES1, right, left);
      }
      break;
    }
    case UGE:
      zero_is_false = false;
    // fall through.
    case ULT: {
      ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
      __ sltu(CMPRES1, left, right);
      break;
    }
    case ULE:
      zero_is_false = false;
    // fall through.
    case UGT: {
      ASSERT((left != IMM) && (right != IMM));  // No unsigned constants used.
      __ sltu(CMPRES1, right, left);
      break;
    }
    default:
      UNREACHABLE();
  }

  // CMPRES1 is the evaluated condition, zero or non-zero, as specified by the
  // flag zero_is_false.
  Register false_value_reg;
  if (false_value == 0) {
    false_value_reg = ZR;
  } else {
    __ LoadImmediate(CMPRES2, Smi::RawValue(false_value));
    false_value_reg = CMPRES2;
  }
  if (zero_is_false) {
    __ movz(result, false_value_reg, CMPRES1);
  } else {
    __ movn(result, false_value_reg, CMPRES1);
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(T0));  // Function.
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor in S4.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(S4, arguments_descriptor);

  // Load closure function code in T2.
  // S4: arguments descriptor array.
  // S5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  ASSERT(locs()->in(0).reg() == T0);
  __ LoadImmediate(S5, 0);
  __ lw(T2, FieldAddress(T0, Function::entry_point_offset()));
  __ lw(CODE_REG, FieldAddress(T0, Function::code_offset()));
  __ jalr(T2);
  compiler->RecordSafepoint(locs());
  compiler->EmitCatchEntryState();
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after);
  }
  // Add deoptimization continuation point after the call and before the
  // arguments are removed.
  // In optimized code this descriptor is needed for exception handling.
  compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id_after,
                                 token_pos());
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("LoadLocalInstr");
  Register result = locs()->out(0).reg();
  __ LoadFromOffset(result, FP, local().index() * kWordSize);
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return LocationSummary::Make(zone, 1, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StoreLocalInstr");
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ StoreToOffset(value, FP, local().index() * kWordSize);
}


LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  return LocationSummary::Make(zone, 0, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    __ Comment("ConstantInstr");
    Register result = locs()->out(0).reg();
    __ LoadObject(result, value());
  }
}


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = (representation_ == kUnboxedInt32) ? 0 : 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation_ == kUnboxedInt32) {
    locs->set_out(0, Location::RequiresRegister());
  } else {
    ASSERT(representation_ == kUnboxedDouble);
    locs->set_out(0, Location::RequiresFpuRegister());
  }
  if (kNumTemps > 0) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    switch (representation_) {
      case kUnboxedDouble: {
        ASSERT(value().IsDouble());
        const Register const_value = locs()->temp(0).reg();
        const DRegister result = locs()->out(0).fpu_reg();
        __ LoadObject(const_value, value());
        __ LoadDFromOffset(result, const_value,
                           Double::value_offset() - kHeapObjectTag);
        break;
      }

      case kUnboxedInt32:
        __ LoadImmediate(locs()->out(0).reg(), Smi::Cast(value()).Value());
        break;

      default:
        UNREACHABLE();
    }
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));  // Value.
  summary->set_in(1, Location::RegisterLocation(A1));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(A2));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(A0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_out(0, Location::RegisterLocation(A0));
  return locs;
}


static void EmitAssertBoolean(Register reg,
                              TokenPosition token_pos,
                              intptr_t deopt_id,
                              LocationSummary* locs,
                              FlowGraphCompiler* compiler) {
  // Check that the type of the value is allowed in conditional context.
  // Call the runtime if the object is not bool::true or bool::false.
  ASSERT(locs->always_calls());
  Label done;

  if (Isolate::Current()->type_checks()) {
    __ BranchEqual(reg, Bool::True(), &done);
    __ BranchEqual(reg, Bool::False(), &done);
  } else {
    ASSERT(Isolate::Current()->asserts());
    __ BranchNotEqual(reg, Object::null_instance(), &done);
  }

  __ Push(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos, deopt_id,
                                kNonBoolTypeErrorRuntimeEntry, 1, locs);
  // We should never return here.
  __ break_(0);
  __ Bind(&done);
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ Comment("AssertBooleanInstr");
  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RegisterOrConstant(left()));
    // Only one input can be a constant operand. The case of two constant
    // operands should be handled by constant propagation.
    locs->set_in(1, locs->in(0).IsConstant()
                        ? Location::RequiresRegister()
                        : Location::RegisterOrConstant(right()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  UNREACHABLE();
  return NULL;
}


static void LoadValueCid(FlowGraphCompiler* compiler,
                         Register value_cid_reg,
                         Register value_reg,
                         Label* value_is_smi = NULL) {
  __ Comment("LoadValueCid");
  Label done;
  if (value_is_smi == NULL) {
    __ LoadImmediate(value_cid_reg, kSmiCid);
  }
  __ andi(CMPRES1, value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ beq(CMPRES1, ZR, &done);
  } else {
    __ beq(CMPRES1, ZR, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}


static RelationOperator TokenKindToIntRelOp(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQ;
    case Token::kNE:
      return NE;
    case Token::kLT:
      return LT;
    case Token::kGT:
      return GT;
    case Token::kLTE:
      return LE;
    case Token::kGTE:
      return GE;
    default:
      UNREACHABLE();
      return NV;
  }
}


static RelationOperator TokenKindToUintRelOp(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQ;
    case Token::kNE:
      return NE;
    case Token::kLT:
      return ULT;
    case Token::kGT:
      return UGT;
    case Token::kLTE:
      return ULE;
    case Token::kGTE:
      return UGE;
    default:
      UNREACHABLE();
      return NV;
  }
}


// The comparison code to emit is specified by true_condition.
static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  __ Comment("ControlInstruction::EmitBranchOnCondition");
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ BranchOnCondition(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = NegateCondition(true_condition);
    __ BranchOnCondition(false_condition, labels.false_label);
    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
}


static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     const LocationSummary& locs,
                                     Token::Kind kind) {
  __ Comment("EmitSmiComparisonOp");
  const Location left = locs.in(0);
  const Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());
  ASSERT(left.IsRegister() || left.IsConstant());
  ASSERT(right.IsRegister() || right.IsConstant());

  int16_t imm = 0;
  const Register left_reg =
      left.IsRegister() ? left.reg() : __ LoadConditionOperand(
                                           CMPRES1, left.constant(), &imm);
  const Register right_reg =
      right.IsRegister() ? right.reg() : __ LoadConditionOperand(
                                             CMPRES2, right.constant(), &imm);
  return Condition(left_reg, right_reg, TokenKindToIntRelOp(kind), imm);
}


static Condition EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                           const LocationSummary& locs,
                                           Token::Kind kind,
                                           BranchLabels labels) {
  __ Comment("EmitUnboxedMintEqualityOp");
  ASSERT(Token::IsEqualityOperator(kind));
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();

  if (labels.false_label == NULL) {
    // Generate branch-free code.
    __ xor_(CMPRES1, left_lo, right_lo);
    __ xor_(AT, left_hi, right_hi);
    __ or_(CMPRES1, CMPRES1, AT);
    return Condition(CMPRES1, ZR, TokenKindToUintRelOp(kind));
  } else {
    if (kind == Token::kEQ) {
      __ bne(left_hi, right_hi, labels.false_label);
    } else {
      ASSERT(kind == Token::kNE);
      __ bne(left_hi, right_hi, labels.true_label);
    }
    return Condition(left_lo, right_lo, TokenKindToUintRelOp(kind));
  }
}


static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             const LocationSummary& locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  __ Comment("EmitUnboxedMintComparisonOp");
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();

  if (labels.false_label == NULL) {
    // Generate branch-free code (except for skipping the lower words compare).
    // Result in CMPRES1, CMPRES2, so that CMPRES1 op CMPRES2 === left op right.
    Label done;
    // Compare upper halves first.
    __ slt(CMPRES1, right_hi, left_hi);
    __ slt(CMPRES2, left_hi, right_hi);
    // If higher words aren't equal, skip comparing lower words.
    __ bne(CMPRES1, CMPRES2, &done);

    __ sltu(CMPRES1, right_lo, left_lo);
    __ sltu(CMPRES2, left_lo, right_lo);
    __ Bind(&done);
    return Condition(CMPRES1, CMPRES2, TokenKindToUintRelOp(kind));
  } else {
    switch (kind) {
      case Token::kLT:
      case Token::kLTE: {
        __ slt(AT, left_hi, right_hi);
        __ bne(AT, ZR, labels.true_label);
        __ delay_slot()->slt(AT, right_hi, left_hi);
        __ bne(AT, ZR, labels.false_label);
        break;
      }
      case Token::kGT:
      case Token::kGTE: {
        __ slt(AT, left_hi, right_hi);
        __ bne(AT, ZR, labels.false_label);
        __ delay_slot()->slt(AT, right_hi, left_hi);
        __ bne(AT, ZR, labels.true_label);
        break;
      }
      default:
        UNREACHABLE();
    }
    return Condition(left_lo, right_lo, TokenKindToUintRelOp(kind));
  }
}


static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  DRegister left = locs.in(0).fpu_reg();
  DRegister right = locs.in(1).fpu_reg();

  __ Comment("DoubleComparisonOp(left=%d, right=%d)", left, right);

  __ cund(left, right);
  Label* nan_label =
      (kind == Token::kNE) ? labels.true_label : labels.false_label;
  __ bc1t(nan_label);

  switch (kind) {
    case Token::kEQ:
      __ ceqd(left, right);
      break;
    case Token::kNE:
      __ ceqd(left, right);
      break;
    case Token::kLT:
      __ coltd(left, right);
      break;
    case Token::kLTE:
      __ coled(left, right);
      break;
    case Token::kGT:
      __ coltd(right, left);
      break;
    case Token::kGTE:
      __ coled(right, left);
      break;
    default: {
      // We should only be passing the above conditions to this function.
      UNREACHABLE();
      break;
    }
  }

  if (labels.false_label == NULL) {
    // Generate branch-free code and return result in condition.
    __ LoadImmediate(CMPRES1, 1);
    if (kind == Token::kNE) {
      __ movf(CMPRES1, ZR);
    } else {
      __ movt(CMPRES1, ZR);
    }
    return Condition(CMPRES1, ZR, EQ);
  } else {
    if (labels.fall_through == labels.false_label) {
      if (kind == Token::kNE) {
        __ bc1f(labels.true_label);
      } else {
        __ bc1t(labels.true_label);
      }
      // Since we already branched on true, return the never true condition.
      return Condition(CMPRES1, CMPRES2, NV);
    } else {
      if (kind == Token::kNE) {
        __ bc1t(labels.false_label);
      } else {
        __ bc1f(labels.false_label);
      }
      // Since we already branched on false, return the always true condition.
      return Condition(CMPRES1, CMPRES2, AL);
    }
  }
}


Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind());
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  __ Comment("EqualityCompareInstr");

  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void EqualityCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                          BranchInstr* branch) {
  __ Comment("EqualityCompareInstr::EmitBranchCode");
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestSmiInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  locs->set_in(1, Location::RegisterOrConstant(right()));
  return locs;
}


Condition TestSmiInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                           BranchLabels labels) {
  Register left = locs()->in(0).reg();
  Location right = locs()->in(1);
  if (right.IsConstant()) {
    ASSERT(right.constant().IsSmi());
    const int32_t imm = reinterpret_cast<int32_t>(right.constant().raw());
    __ AndImmediate(CMPRES1, left, imm);
  } else {
    __ and_(CMPRES1, left, right.reg());
  }
  return Condition(CMPRES1, ZR, (kind() == Token::kNE) ? NE : EQ);
}


void TestSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Never emitted outside of the BranchInstr.
  UNREACHABLE();
}


void TestSmiInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                  BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestCidsInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


Condition TestCidsInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                            BranchLabels labels) {
  ASSERT((kind() == Token::kIS) || (kind() == Token::kISNOT));
  Register val_reg = locs()->in(0).reg();
  Register cid_reg = locs()->temp(0).reg();

  Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids,
                                   licm_hoisted_ ? ICData::kHoisted : 0)
          : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ andi(CMPRES1, val_reg, Immediate(kSmiTagMask));
  __ beq(CMPRES1, ZR, result ? labels.true_label : labels.false_label);

  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ BranchEqual(cid_reg, Immediate(test_cid),
                   result ? labels.true_label : labels.false_label);
  }
  // No match found, deoptimize or false.
  if (deopt == NULL) {
    Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ b(target);
    }
  } else {
    __ b(deopt);
  }
  // Dummy result as the last instruction is a jump or fall through.
  return Condition(CMPRES1, ZR, AL);
}


void TestCidsInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                   BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  EmitComparisonCode(compiler, labels);
}


void TestCidsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result_reg = locs()->out(0).reg();
  Label is_true, is_false, done;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  EmitComparisonCode(compiler, labels);
  __ Bind(&is_false);
  __ LoadObject(result_reg, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True());
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_in(1, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RegisterOrConstant(left()));
  // Only one input can be a constant operand. The case of two constant
  // operands should be handled by constant propagation.
  summary->set_in(1, summary->in(0).IsConstant()
                         ? Location::RequiresRegister()
                         : Location::RegisterOrConstant(right()));
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


Condition RelationalOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind());
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("RelationalOpInstr");

  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void RelationalOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  __ Comment("RelationalOpInstr");

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* NativeCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return MakeCallSummary(zone);
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  __ Comment("NativeCallInstr");
  Register result = locs()->out(0).reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());
  // Pass a pointer to the first argument in A2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(
        A2, FP, (kParamEndSlotFromFp + function().NumParameters()) * kWordSize);
  } else {
    __ AddImmediate(A2, FP, kFirstLocalSlotFromFp * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry;
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const StubEntry* stub_entry;
  if (link_lazily()) {
    stub_entry = StubCode::CallBootstrapNative_entry();
    entry = NativeEntry::LinkNativeCallEntry();
  } else {
    entry = reinterpret_cast<uword>(native_c_function());
    if (is_bootstrap_native()) {
      stub_entry = StubCode::CallBootstrapNative_entry();
#if defined(USING_SIMULATOR)
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, NativeEntry::kNumArguments);
#endif
    } else if (is_auto_scope()) {
      // In the case of non bootstrap native methods the CallNativeCFunction
      // stub generates the redirection address when running under the simulator
      // and hence we do not change 'entry' here.
      stub_entry = StubCode::CallAutoScopeNative_entry();
    } else {
      // In the case of non bootstrap native methods the CallNativeCFunction
      // stub generates the redirection address when running under the simulator
      // and hence we do not change 'entry' here.
      stub_entry = StubCode::CallNoScopeNative_entry();
    }
  }
  __ LoadImmediate(A1, argc_tag);
  ExternalLabel label(entry);
  __ LoadNativeEntry(T5, &label, kNotPatchable);
  if (link_lazily()) {
    compiler->GeneratePatchableCall(token_pos(), *stub_entry,
                                    RawPcDescriptors::kOther, locs());
  } else {
    compiler->GenerateCall(token_pos(), *stub_entry, RawPcDescriptors::kOther,
                           locs());
  }
  __ Pop(result);
}


LocationSummary* OneByteStringFromCharCodeInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void OneByteStringFromCharCodeInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ lw(result, Address(THR, Thread::predefined_symbols_address_offset()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ sll(TMP, char_code, 1);  // Char code is a smi.
  __ addu(TMP, TMP, result);
  __ lw(result, Address(TMP));
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StringToCharCodeInstr");

  ASSERT(cid_ == kOneByteStringCid);
  Register str = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(str != result);
  Label done;
  __ lw(result, FieldAddress(str, String::length_offset()));
  __ BranchNotEqual(result, Immediate(Smi::RawValue(1)), &done);
  __ delay_slot()->addiu(result, ZR, Immediate(Smi::RawValue(-1)));
  __ lbu(result, FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ Push(array);
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), token_pos(), CallFunction(),
                               args_info, locs(), ICData::Handle());
  ASSERT(locs()->out(0).reg() == V0);
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ LoadFromOffset(result, obj, offset());
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ LoadFieldFromOffset(result, obj, offset());
  }
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  const AbstractType& value_type = *this->object()->Type()->ToAbstractType();
  if (CompileType::Smi().IsAssignableTo(value_type) ||
      value_type.IsTypeParameter()) {
    __ LoadTaggedClassIdMayBeSmi(result, object);
  } else {
    __ LoadClassId(result, object);
    __ SmiTag(result);
  }
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
      UNIMPLEMENTED();
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
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}


static bool CanBeImmediateIndex(Value* value, intptr_t cid, bool is_external) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == NULL) || !Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const int64_t offset =
      index * scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  if (!Utils::IsInt(32, offset)) {
    return false;
  }
  return Address::CanHoldOffset(static_cast<int32_t>(offset));
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = aligned() ? 0 : 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    locs->set_out(0, Location::RequiresRegister());
  }
  if (!aligned()) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("LoadIndexedInstr");
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register address = aligned() ? kNoRegister : locs()->temp(0).reg();

  Address element_address(kNoRegister);
  if (aligned()) {
    element_address =
        index.IsRegister()
            ? __ ElementAddressForRegIndex(true,  // Load.
                                           IsExternal(), class_id(),
                                           index_scale(), array, index.reg())
            : __ ElementAddressForIntIndex(IsExternal(), class_id(),
                                           index_scale(), array,
                                           Smi::Cast(index.constant()).Value());
    // Warning: element_address may use register TMP as base.
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(address,
                                       true,  // Load.
                                       IsExternal(), class_id(), index_scale(),
                                       array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(address, IsExternal(), class_id(),
                                       index_scale(), array,
                                       Smi::Cast(index.constant()).Value());
    }
  }

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)) {
    DRegister result = locs()->out(0).fpu_reg();
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        __ lwc1(EvenFRegisterOf(result), element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        __ LoadDFromOffset(result, element_address.base(),
                           element_address.offset());
        break;
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

  if ((representation() == kUnboxedUint32) ||
      (representation() == kUnboxedInt32)) {
    const Register result = locs()->out(0).reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        ASSERT(representation() == kUnboxedInt32);
        if (aligned()) {
          __ lw(result, element_address);
        } else {
          __ LoadWordUnaligned(result, address, TMP);
        }
        break;
      case kTypedDataUint32ArrayCid:
        ASSERT(representation() == kUnboxedUint32);
        if (aligned()) {
          __ lw(result, element_address);
        } else {
          __ LoadWordUnaligned(result, address, TMP);
        }
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  ASSERT(representation() == kTagged);

  const Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      __ lb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ lbu(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      if (aligned()) {
        __ lh(result, element_address);
      } else {
        __ LoadHalfWordUnaligned(result, address, TMP);
      }
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      if (aligned()) {
        __ lhu(result, element_address);
      } else {
        __ LoadHalfWordUnsignedUnaligned(result, address, TMP);
      }
      __ SmiTag(result);
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      ASSERT(aligned());
      __ lw(result, element_address);
      break;
  }
}


LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());

  // TODO(zerny): Handle mints properly once possible.
  ASSERT(representation() == kTagged);
  summary->set_out(0, Location::RequiresRegister());

  return summary;
}


void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = __ ElementAddressForRegIndex(
      true, IsExternal(), class_id(), index_scale(), str, index.reg());
  // Warning: element_address may use register TMP as base.

  ASSERT(representation() == kTagged);
  Register result = locs()->out(0).reg();
  switch (class_id()) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      switch (element_count()) {
        case 1:
          __ lbu(result, element_address);
          break;
        case 2:
          __ lhu(result, element_address);
          break;
        case 4:  // Loading multiple code units is disabled on MIPS.
        default:
          UNREACHABLE();
      }
      __ SmiTag(result);
      break;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      switch (element_count()) {
        case 1:
          __ lhu(result, element_address);
          break;
        case 2:  // Loading multiple code units is disabled on MIPS.
        default:
          UNREACHABLE();
      }
      __ SmiTag(result);
      break;
    default:
      UNREACHABLE();
      break;
  }
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0) return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) return kTagged;            // Index is a smi.
  ASSERT(idx == 2);
  switch (class_id_) {
    case kArrayCid:
    case kOneByteStringCid:
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
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}


LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = aligned() ? 0 : 2;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::WritableRegister());
  }
  switch (class_id()) {
    case kArrayCid:
      locs->set_in(2, ShouldEmitStoreBarrier()
                          ? Location::WritableRegister()
                          : Location::RegisterOrConstant(value()));
      break;
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:  // TODO(srdjan): Support Float64 constants.
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
      return NULL;
  }
  if (!aligned()) {
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_temp(1, Location::RequiresRegister());
  }
  return locs;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StoreIndexedInstr");
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);
  const Register address = aligned() ? kNoRegister : locs()->temp(0).reg();
  const Register scratch = aligned() ? kNoRegister : locs()->temp(1).reg();

  Address element_address(kNoRegister);
  if (aligned()) {
    element_address =
        index.IsRegister()
            ? __ ElementAddressForRegIndex(false,  // Store.
                                           IsExternal(), class_id(),
                                           index_scale(), array, index.reg())
            : __ ElementAddressForIntIndex(IsExternal(), class_id(),
                                           index_scale(), array,
                                           Smi::Cast(index.constant()).Value());
    ASSERT(element_address.base() != TMP);  // Allowed for load only.
  } else {
    if (index.IsRegister()) {
      __ LoadElementAddressForRegIndex(address,
                                       false,  // Store.
                                       IsExternal(), class_id(), index_scale(),
                                       array, index.reg());
    } else {
      __ LoadElementAddressForIntIndex(address, IsExternal(), class_id(),
                                       index_scale(), array,
                                       Smi::Cast(index.constant()).Value());
    }
  }

  switch (class_id()) {
    case kArrayCid:
      ASSERT(aligned());
      if (ShouldEmitStoreBarrier()) {
        Register value = locs()->in(2).reg();
        __ StoreIntoObject(array, element_address, value);
      } else if (locs()->in(2).IsConstant()) {
        const Object& constant = locs()->in(2).constant();
        __ StoreIntoObjectNoBarrier(array, element_address, constant);
      } else {
        Register value = locs()->in(2).reg();
        __ StoreIntoObjectNoBarrier(array, element_address, value);
      }
      break;
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kOneByteStringCid: {
      ASSERT(aligned());
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ LoadImmediate(TMP, static_cast<int8_t>(constant.Value()));
        __ sb(TMP, element_address);
      } else {
        Register value = locs()->in(2).reg();
        __ SmiUntag(TMP, value);
        __ sb(TMP, element_address);
      }
      break;
    }
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      ASSERT(aligned());
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        intptr_t value = constant.Value();
        // Clamp to 0x0 or 0xFF respectively.
        if (value > 0xFF) {
          value = 0xFF;
        } else if (value < 0) {
          value = 0;
        }
        __ LoadImmediate(TMP, static_cast<int8_t>(value));
        __ sb(TMP, element_address);
      } else {
        Register value = locs()->in(2).reg();
        Label store_value, bigger, smaller;
        __ SmiUntag(TMP, value);
        __ BranchUnsignedLess(TMP, Immediate(0xFF + 1), &store_value);
        __ LoadImmediate(TMP, 0xFF);
        __ slti(CMPRES1, value, Immediate(1));
        __ movn(TMP, ZR, CMPRES1);
        __ Bind(&store_value);
        __ sb(TMP, element_address);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      Register value = locs()->in(2).reg();
      __ SmiUntag(TMP, value);
      if (aligned()) {
        __ sh(TMP, element_address);
      } else {
        __ StoreHalfWordUnaligned(TMP, address, scratch);
      }
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (aligned()) {
        __ sw(locs()->in(2).reg(), element_address);
      } else {
        __ StoreWordUnaligned(locs()->in(2).reg(), address, scratch);
      }
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      ASSERT(aligned());
      FRegister value = EvenFRegisterOf(locs()->in(2).fpu_reg());
      __ swc1(value, element_address);
      break;
    }
    case kTypedDataFloat64ArrayCid:
      ASSERT(aligned());
      __ StoreDToOffset(locs()->in(2).fpu_reg(), element_address.base(),
                        element_address.offset());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      UNIMPLEMENTED();
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();

  const bool emit_full_guard = !opt || (field_cid == kIllegalCid);
  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));
  const bool needs_field_temp_reg = emit_full_guard;

  intptr_t num_temps = 0;
  if (needs_value_cid_temp_reg) {
    num_temps++;
  }
  if (needs_field_temp_reg) {
    num_temps++;
  }

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());

  for (intptr_t i = 0; i < num_temps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }

  return summary;
}


void GuardFieldClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);
  __ Comment("GuardFieldClassInstr");

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(
          deopt_id(),
          "GuardFieldClassInstr: field state changed while compiling");
    }
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  const bool emit_full_guard =
      !compiler->is_optimizing() || (field_cid == kIllegalCid);

  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));

  const bool needs_field_temp_reg = emit_full_guard;

  const Register value_reg = locs()->in(0).reg();

  const Register value_cid_reg =
      needs_value_cid_temp_reg ? locs()->temp(0).reg() : kNoRegister;

  const Register field_reg = needs_field_temp_reg
                                 ? locs()->temp(locs()->temp_count() - 1).reg()
                                 : kNoRegister;

  Label ok, fail_label;

  Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(field_reg,
                                           Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);

      __ lhu(CMPRES1, field_cid_operand);
      __ beq(value_cid_reg, CMPRES1, &ok);
      __ lhu(TMP, field_nullability_operand);
      __ subu(CMPRES1, value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ lhu(TMP, field_nullability_operand);
      __ LoadImmediate(CMPRES1, value_cid);
      __ subu(CMPRES1, TMP, CMPRES1);
    } else {
      __ lhu(TMP, field_cid_operand);
      __ LoadImmediate(CMPRES1, value_cid);
      __ subu(CMPRES1, TMP, CMPRES1);
    }
    __ beq(CMPRES1, ZR, &ok);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    // Length guard will be emitted separately when needed via GuardFieldLength
    // instruction after GuardFieldClass.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ lhu(CMPRES1, field_cid_operand);
      __ BranchNotEqual(CMPRES1, Immediate(kIllegalCid), fail);

      if (value_cid == kDynamicCid) {
        __ sh(value_cid_reg, field_cid_operand);
        __ sh(value_cid_reg, field_nullability_operand);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ sh(TMP, field_cid_operand);
        __ sh(TMP, field_nullability_operand);
      }

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ b(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ lhu(CMPRES1, FieldAddress(field_reg, Field::guarded_cid_offset()));
      __ BranchEqual(CMPRES1, Immediate(kDynamicCid), &ok);

      __ addiu(SP, SP, Immediate(-2 * kWordSize));
      __ sw(field_reg, Address(SP, 1 * kWordSize));
      __ sw(value_reg, Address(SP, 0 * kWordSize));
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ andi(CMPRES1, value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ beq(CMPRES1, ZR, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ LoadImmediate(TMP, field_cid);
        __ subu(CMPRES1, value_cid_reg, TMP);
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ beq(CMPRES1, ZR, &ok);
        if (field_cid != kSmiCid) {
          __ LoadImmediate(TMP, kNullCid);
          __ subu(CMPRES1, value_cid_reg, TMP);
        } else {
          __ LoadObject(TMP, Object::null_object());
          __ subu(CMPRES1, value_reg, TMP);
        }
      }

      __ bne(CMPRES1, ZR, fail);
    } else {
      // Both value's and field's class id is known.
      ASSERT((value_cid != field_cid) && (value_cid != nullability));
      __ b(fail);
    }
  }
  __ Bind(&ok);
}


LocationSummary* GuardFieldLengthInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;

  if (!opt || (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    // We need temporaries for field object.
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }
  LocationSummary* summary =
      new (zone) LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void GuardFieldLengthInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (field().guarded_list_length() == Field::kNoFixedLength) {
    if (Compiler::IsBackgroundCompilation()) {
      // Field state changed while compiling.
      Compiler::AbortBackgroundCompilation(
          deopt_id(),
          "GuardFieldLengthInstr: field state changed while compiling");
    }
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  Label* deopt =
      compiler->is_optimizing()
          ? compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField)
          : NULL;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();

    Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    __ lb(CMPRES1,
          FieldAddress(field_reg,
                       Field::guarded_list_length_in_object_offset_offset()));
    __ blez(CMPRES1, &ok);

    __ lw(CMPRES2,
          FieldAddress(field_reg, Field::guarded_list_length_offset()));

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // CMPRES1 contains offset already corrected by -kHeapObjectTag that is
    // why we can use Address instead of FieldAddress.
    __ addu(TMP, value_reg, CMPRES1);
    __ lw(TMP, Address(TMP));

    if (deopt == NULL) {
      __ beq(CMPRES2, TMP, &ok);

      __ addiu(SP, SP, Immediate(-2 * kWordSize));
      __ sw(field_reg, Address(SP, 1 * kWordSize));
      __ sw(value_reg, Address(SP, 0 * kWordSize));
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ bne(CMPRES2, TMP, deopt);
    }

    __ Bind(&ok);
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(field().guarded_list_length() >= 0);
    ASSERT(field().guarded_list_length_in_object_offset() !=
           Field::kUnknownLengthOffset);

    __ lw(CMPRES1,
          FieldAddress(value_reg,
                       field().guarded_list_length_in_object_offset()));
    __ LoadImmediate(TMP, Smi::RawValue(field().guarded_list_length()));
    __ bne(CMPRES1, TMP, deopt);
  }
}


class BoxAllocationSlowPath : public SlowPathCode {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : instruction_(instruction), cls_(cls), result_(result) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s", instruction_->DebugName(),
                 String::Handle(cls_.ScrubbedName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::GetAllocationStubForClass(cls_));
    const StubEntry stub_entry(stub);

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(TokenPosition::kNoSource,  // No token position.
                           stub_entry, RawPcDescriptors::kOther, locs);
    compiler->AddStubCallTarget(stub);
    if (result_ != V0) {
      __ mov(result_, V0);
    }
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp) {
    if (compiler->intrinsic_mode()) {
      __ TryAllocate(cls, compiler->intrinsic_slow_path_label(), result, temp);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls, slow_path->entry_label(), result, temp);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
  Instruction* instruction_;
  const Class& cls_;
  const Register result_;
};


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (IsUnboxedStore() && opt) ? 2 : ((IsPotentialUnboxedStore()) ? 3 : 0);
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      ((IsUnboxedStore() && opt && is_initialization()) ||
                       IsPotentialUnboxedStore())
                          ? LocationSummary::kCallOnSlowPath
                          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier() ? Location::WritableRegister()
                                                : Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, opt ? Location::RequiresFpuRegister()
                             : Location::FpuRegisterLocation(D1));
  } else {
    summary->set_in(1, ShouldEmitStoreBarrier()
                           ? Location::WritableRegister()
                           : Location::RegisterOrConstant(value()));
  }
  return summary;
}


static void EnsureMutableBox(FlowGraphCompiler* compiler,
                             StoreInstanceFieldInstr* instruction,
                             Register box_reg,
                             const Class& cls,
                             Register instance_reg,
                             intptr_t offset,
                             Register temp) {
  Label done;
  __ lw(box_reg, FieldAddress(instance_reg, offset));
  __ BranchNotEqual(box_reg, Object::null_object(), &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ mov(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp);
  __ Bind(&done);
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);
  Label skip_store;

  Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    DRegister value = locs()->in(1).fpu_reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    const intptr_t cid = field().UnboxedFieldCid();

    if (is_initialization()) {
      const Class* cls = NULL;
      switch (cid) {
        case kDoubleCid:
          cls = &compiler->double_class();
          break;
        default:
          UNREACHABLE();
      }

      BoxAllocationSlowPath::Allocate(compiler, this, *cls, temp, temp2);
      __ mov(temp2, temp);
      __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, temp2);
    } else {
      __ lw(temp, FieldAddress(instance_reg, offset_in_bytes_));
    }
    switch (cid) {
      case kDoubleCid:
        __ StoreDToOffset(value, temp, Double::value_offset() - kHeapObjectTag);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if (IsPotentialUnboxedStore()) {
    Register value_reg = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    DRegister fpu_temp = locs()->temp(2).fpu_reg();

    if (ShouldEmitStoreBarrier()) {
      // Value input is a writable register and should be manually preserved
      // across allocation slow-path.
      locs()->live_registers()->Add(locs()->in(1), kTagged);
    }

    Label store_pointer;
    Label store_double;

    __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));

    __ lhu(temp2, FieldAddress(temp, Field::is_nullable_offset()));
    __ BranchEqual(temp2, Immediate(kNullCid), &store_pointer);

    __ lbu(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ andi(CMPRES1, temp2, Immediate(1 << Field::kUnboxingCandidateBit));
    __ beq(CMPRES1, ZR, &store_pointer);

    __ lhu(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ BranchEqual(temp2, Immediate(kDoubleCid), &store_double);

    // Fall through.
    __ b(&store_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
      locs()->live_registers()->Add(locs()->in(1));
    }

    {
      __ Bind(&store_double);
      EnsureMutableBox(compiler, this, temp, compiler->double_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ LoadDFromOffset(fpu_temp, value_reg,
                         Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(fpu_temp, temp,
                        Double::value_offset() - kHeapObjectTag);
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(instance_reg, offset_in_bytes_, value_reg,
                             CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes_,
                                        locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrierOffset(instance_reg, offset_in_bytes_,
                                        value_reg);
    }
  }
  __ Bind(&skip_store);
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


// When the parser is building an implicit static getter for optimization,
// it can generate a function body where deoptimization ids do not line up
// with the unoptimized code.
//
// This is safe only so long as LoadStaticFieldInstr cannot deoptimize.
void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("LoadStaticFieldInstr");
  Register field = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ LoadFromOffset(result, field,
                    Field::static_value_offset() - kHeapObjectTag);
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  LocationSummary* locs =
      new (zone) LocationSummary(zone, 1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StoreStaticFieldInstr");
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(temp, FieldAddress(temp, Field::static_value_offset()),
                       value, CanValueBeSmi());
  } else {
    __ StoreIntoObjectNoBarrier(
        temp, FieldAddress(temp, Field::static_value_offset()), value);
  }
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));  // Instance.
  summary->set_in(1, Location::RegisterLocation(A1));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(A2));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == A0);  // Value.
  ASSERT(locs()->in(1).reg() == A1);  // Instantiator type arguments.
  ASSERT(locs()->in(2).reg() == A2);  // Function type arguments.

  __ Comment("InstanceOfInstr");
  compiler->GenerateInstanceOf(token_pos(), deopt_id(), type(), locs());
  ASSERT(locs()->out(0).reg() == V0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_in(1, Location::RegisterLocation(A1));
  locs->set_out(0, Location::RegisterLocation(V0));
  return locs;
}


// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  Label* slow_path,
                                  Label* done) {
  const int kInlineArraySize = 12;  // Same as kInlineInstanceSize.
  const Register kLengthReg = A1;
  const Register kElemTypeReg = A0;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      V0,  // instance
                      T1,  // end address
                      T2, T3);
  // V0: new object start as a tagged pointer.
  // T1: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      V0, FieldAddress(V0, Array::type_arguments_offset()), kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(V0, FieldAddress(V0, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // V0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: iterator which initially points to the start of the variable
  // data area to be initialized.
  // T7: null.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(RawArray);
    __ LoadObject(T7, Object::null_object());
    __ AddImmediate(T2, V0, sizeof(RawArray) - kHeapObjectTag);
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      while (current_offset < array_size) {
        __ sw(T7, Address(T2, current_offset));
        current_offset += kWordSize;
      }
    } else {
      Label init_loop;
      __ Bind(&init_loop);
      __ sw(T7, Address(T2, 0));
      __ addiu(T2, T2, Immediate(kWordSize));
      __ BranchUnsignedLess(T2, T1, &init_loop);
    }
  }
  __ b(done);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("CreateArrayInstr");
  const Register kLengthReg = A1;
  const Register kElemTypeReg = A0;
  const Register kResultReg = V0;
  ASSERT(locs()->in(0).reg() == kElemTypeReg);
  ASSERT(locs()->in(1).reg() == kLengthReg);

  Label slow_path, done;
  if (compiler->is_optimizing() && !FLAG_precompiled_mode &&
      num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object());  // Make room for the result.
      __ Push(kLengthReg);                   // length.
      __ Push(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                    kAllocateArrayRuntimeEntry, 2, locs());
      __ Drop(2);
      __ Pop(kResultReg);
      __ Bind(&done);
      return;
    }
  }

  __ Bind(&slow_path);
  const Code& stub = Code::ZoneHandle(compiler->zone(),
                                      StubCode::AllocateArray_entry()->code());
  compiler->AddStubCallTarget(stub);
  compiler->GenerateCallWithDeopt(token_pos(), deopt_id(),
                                  *StubCode::AllocateArray_entry(),
                                  RawPcDescriptors::kOther, locs());
  __ Bind(&done);
  ASSERT(locs()->out(0).reg() == kResultReg);
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 : ((IsPotentialUnboxedLoad()) ? 2 : 0);
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, (opt && !IsPotentialUnboxedLoad())
                                       ? LocationSummary::kNoCall
                                       : LocationSummary::kCallOnSlowPath);

  locs->set_in(0, Location::RequiresRegister());

  if (IsUnboxedLoad() && opt) {
    locs->set_temp(0, Location::RequiresRegister());
  } else if (IsPotentialUnboxedLoad()) {
    locs->set_temp(0, opt ? Location::RequiresFpuRegister()
                          : Location::FpuRegisterLocation(D1));
    locs->set_temp(1, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);

  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    DRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ LoadFieldFromOffset(temp, instance_reg, offset_in_bytes());
    intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        __ LoadDFromOffset(result, temp,
                           Double::value_offset() - kHeapObjectTag);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  Register result_reg = locs()->out(0).reg();
  if (IsPotentialUnboxedLoad()) {
    Register temp = locs()->temp(1).reg();
    DRegister value = locs()->temp(0).fpu_reg();

    Label load_pointer;
    Label load_double;

    __ LoadObject(result_reg, Field::ZoneHandle(field()->Original()));

    FieldAddress field_cid_operand(result_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result_reg,
                                           Field::is_nullable_offset());

    __ lhu(temp, field_nullability_operand);
    __ BranchEqual(temp, Immediate(kNullCid), &load_pointer);

    __ lhu(temp, field_cid_operand);
    __ BranchEqual(temp, Immediate(kDoubleCid), &load_double);

    // Fall through.
    __ b(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->double_class(),
                                      result_reg, temp);
      __ lw(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ LoadDFromOffset(value, temp, Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(value, result_reg,
                        Double::value_offset() - kHeapObjectTag);
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFieldFromOffset(result_reg, instance_reg, offset_in_bytes());
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(T1));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("InstantiateTypeInstr");
  Register instantiator_type_args_reg = locs()->in(0).reg();
  Register function_type_args_reg = locs()->in(1).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 3 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP, type());
  __ sw(TMP, Address(SP, 2 * kWordSize));
  __ sw(instantiator_type_args_reg, Address(SP, 1 * kWordSize));
  __ sw(function_type_args_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeRuntimeEntry, 3, locs());
  // Pop instantiated type.
  __ lw(result_reg, Address(SP, 3 * kWordSize));

  // Drop instantiator and uninstantiated type.
  __ addiu(SP, SP, Immediate(4 * kWordSize));
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(T1));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  __ Comment("InstantiateTypeArgumentsInstr");
  Register instantiator_type_args_reg = locs()->in(0).reg();
  Register function_type_args_reg = locs()->in(1).reg();
  Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_type_args_reg == T0);
  ASSERT(instantiator_type_args_reg == result_reg);

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If both the instantiator and function type arguments are null and if the
  // type argument vector instantiated from null becomes a vector of dynamic,
  // then use null as the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawWhenInstantiatedFromRaw(len)) {
    Label non_null_type_args;
    __ BranchNotEqual(instantiator_type_args_reg, Object::null_object(),
                      &non_null_type_args);
    __ BranchEqual(function_type_args_reg, Object::null_object(),
                   &type_arguments_instantiated);
    __ Bind(&non_null_type_args);
  }

  // Lookup cache before calling runtime.
  // TODO(regis): Consider moving this into a shared stub to reduce
  // generated code size.
  __ LoadObject(T2, type_arguments());
  __ lw(T2, FieldAddress(T2, TypeArguments::instantiations_offset()));
  __ AddImmediate(T2, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, next, found, slow_case;
  __ Bind(&loop);
  __ lw(T3, Address(T2, 0 * kWordSize));  // Cached instantiator type args.
  __ bne(T3, T0, &next);
  __ lw(T4, Address(T2, 1 * kWordSize));  // Cached function type args.
  __ beq(T4, T1, &found);
  __ Bind(&next);
  __ BranchNotEqual(T3, Immediate(Smi::RawValue(StubCode::kNoInstantiator)),
                    &loop);
  __ delay_slot()->addiu(
      T2, T2, Immediate(StubCode::kInstantiationSizeInWords * kWordSize));
  __ b(&slow_case);
  __ Bind(&found);
  __ lw(T0, Address(T2, 2 * kWordSize));  // Cached instantiated args.
  __ b(&type_arguments_instantiated);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ addiu(SP, SP, Immediate(-4 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 3 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP, type_arguments());
  __ sw(TMP, Address(SP, 2 * kWordSize));
  __ sw(instantiator_type_args_reg, Address(SP, 1 * kWordSize));
  __ sw(function_type_args_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry, 3,
                                locs());
  // Pop instantiated type arguments.
  __ lw(result_reg, Address(SP, 3 * kWordSize));
  // Drop 2 type argument vectors and uninstantiated type arguments.
  __ addiu(SP, SP, Immediate(4 * kWordSize));
  __ Bind(&type_arguments_instantiated);
}


LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_temp(1, Location::RegisterLocation(T2));
  locs->set_temp(2, Location::RegisterLocation(T3));
  locs->set_out(0, Location::RegisterLocation(V0));
  return locs;
}


class AllocateContextSlowPath : public SlowPathCode {
 public:
  explicit AllocateContextSlowPath(
      AllocateUninitializedContextInstr* instruction)
      : instruction_(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);

    __ LoadImmediate(T1, instruction_->num_context_variables());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::AllocateContext_entry()->code());
    compiler->AddStubCallTarget(stub);
    compiler->GenerateCall(instruction_->token_pos(),
                           *StubCode::AllocateContext_entry(),
                           RawPcDescriptors::kOther, locs);
    ASSERT(instruction_->locs()->out(0).reg() == V0);
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

 private:
  AllocateUninitializedContextInstr* instruction_;
};


void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register temp0 = locs()->temp(0).reg();
  Register temp1 = locs()->temp(1).reg();
  Register temp2 = locs()->temp(2).reg();
  Register result = locs()->out(0).reg();
  // Try allocate the object.
  AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  intptr_t instance_size = Context::InstanceSize(num_context_variables());

  __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                      result,  // instance
                      temp0, temp1, temp2);

  // Setup up number of context variables field.
  __ LoadImmediate(temp0, num_context_variables());
  __ sw(temp0, FieldAddress(result, Context::num_variables_offset()));

  __ Bind(slow_path->exit_label());
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_out(0, Location::RegisterLocation(V0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == T1);
  ASSERT(locs()->out(0).reg() == V0);

  __ Comment("AllocateContextInstr");
  __ LoadImmediate(T1, num_context_variables());
  compiler->GenerateCall(token_pos(), *StubCode::AllocateContext_entry(),
                         RawPcDescriptors::kOther, locs());
}


LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_temp(0, Location::RegisterLocation(T1));
  return locs;
}


void InitStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  Label call_runtime, no_call;
  __ Comment("InitStaticFieldInstr");

  __ lw(temp, FieldAddress(field, Field::static_value_offset()));
  __ BranchEqual(temp, Object::sentinel(), &call_runtime);
  __ BranchNotEqual(temp, Object::transition_sentinel(), &no_call);

  __ Bind(&call_runtime);
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 1 * kWordSize));  // Make room for (unused) result.
  __ sw(field, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInitStaticFieldRuntimeEntry, 1, locs());

  __ addiu(SP, SP, Immediate(2 * kWordSize));  // Purge argument and result.

  __ Bind(&no_call);
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ Comment("CloneContextInstr");

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());  // Make room for the result.
  __ sw(TMP, Address(SP, 1 * kWordSize));
  __ sw(context_value, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kCloneContextRuntimeEntry, 1, locs());
  __ lw(result, Address(SP, 1 * kWordSize));  // Get result (cloned context).
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNREACHABLE();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(), try_index(),
                                compiler->assembler()->CodeSize(),
                                handler_token_pos(), is_generated(),
                                catch_handler_types_, needs_stacktrace());
  // On lazy deoptimization we patch the optimized code here to enter the
  // deoptimization stub.
  const intptr_t deopt_id = Thread::ToDeoptAfter(GetDeoptId());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id);
  } else {
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt, deopt_id,
                                   TokenPosition::kNoSource);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

  // Auxiliary variables introduced by the try catch can be captured if we are
  // inside a function with yield/resume points. In this case we first need
  // to restore the context to match the context at entry into the closure.
  if (should_restore_closure_context()) {
    const ParsedFunction& parsed_function = compiler->parsed_function();
    ASSERT(parsed_function.function().IsClosureFunction());
    LocalScope* scope = parsed_function.node_sequence()->scope();

    LocalVariable* closure_parameter = scope->VariableAt(0);
    ASSERT(!closure_parameter->is_captured());
    __ LoadFromOffset(CTX, FP, closure_parameter->index() * kWordSize);
    __ LoadFieldFromOffset(CTX, CTX, Closure::context_offset());

    const intptr_t context_index =
        parsed_function.current_context_var()->index();
    __ StoreToOffset(CTX, FP, context_index * kWordSize);
  }

  // Initialize exception and stack trace variables.
  if (exception_var().is_captured()) {
    ASSERT(stacktrace_var().is_captured());
    __ StoreIntoObjectOffset(CTX,
                             Context::variable_offset(exception_var().index()),
                             kExceptionObjectReg);
    __ StoreIntoObjectOffset(CTX,
                             Context::variable_offset(stacktrace_var().index()),
                             kStackTraceObjectReg);
  } else {
    // Restore stack and initialize the two exception variables:
    // exception and stack trace variables.
    __ StoreToOffset(kExceptionObjectReg, FP,
                     exception_var().index() * kWordSize);
    __ StoreToOffset(kStackTraceObjectReg, FP,
                     stacktrace_var().index() * kWordSize);
  }
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
      Register value = instruction_->locs()->temp(0).reg();
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(value, Thread::kOsrRequest);
      __ sw(value, Address(THR, Thread::stack_overflow_flags_offset()));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(
        instruction_->token_pos(), instruction_->deopt_id(),
        kStackOverflowRuntimeEntry, 0, instruction_->locs());

    if (compiler->isolate()->use_osr() && !compiler->is_optimizing() &&
        instruction_->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     TokenPosition::kNoSource);
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(Isolate::Current()->use_osr());
    return &osr_entry_label_;
  }

 private:
  CheckStackOverflowInstr* instruction_;
  Label osr_entry_label_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("CheckStackOverflowInstr");
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ lw(CMPRES1, Address(THR, Thread::stack_limit_offset()));
  __ BranchUnsignedLessEqual(SP, CMPRES1, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    Register temp = locs()->temp(0).reg();
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(temp, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ lw(temp, FieldAddress(temp, Function::usage_counter_offset()));
    __ BranchSignedGreaterEqual(temp, Immediate(threshold),
                                slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ b(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}


static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  Label* deopt = shift_left->CanDeoptimize()
                     ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                              ICData::kDeoptBinarySmiOp)
                     : NULL;

  __ Comment("EmitSmiShiftLeft");

  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      // Check for overflow (preserve left).
      __ sll(TMP, left, value);
      __ sra(CMPRES1, TMP, value);
      __ bne(CMPRES1, left, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ sll(result, left, value);
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for is_truncating().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ bltz(right, deopt);
        __ mov(result, ZR);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        const Immediate& max_right_imm =
            Immediate(reinterpret_cast<int32_t>(Smi::New(max_right)));
        __ BranchUnsignedGreaterEqual(right, max_right_imm, deopt);
      }
      __ SmiUntag(TMP, right);
      __ sllv(result, left, TMP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ bltz(right, deopt);
      }
      Label done, is_not_zero;

      __ sltiu(CMPRES1, right,
               Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ movz(result, ZR, CMPRES1);  // result = right >= kBits ? 0 : result.
      __ sra(TMP, right, kSmiTagSize);
      __ sllv(TMP, left, TMP);
      // result = right < kBits ? left << right : result.
      __ movn(result, TMP, CMPRES1);
    } else {
      __ sra(TMP, right, kSmiTagSize);
      __ sllv(result, left, TMP);
    }
  } else {
    if (right_needs_check) {
      const Immediate& bits_imm =
          Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits)));
      ASSERT(shift_left->CanDeoptimize());
      __ BranchUnsignedGreaterEqual(right, bits_imm, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ SmiUntag(temp, right);
    // Overflow test (preserve left, right, and temp);
    __ sllv(CMPRES1, left, temp);
    __ srav(CMPRES1, CMPRES1, temp);
    __ bne(CMPRES1, left, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ sllv(result, left, temp);
  }
}


class CheckedSmiSlowPath : public SlowPathCode {
 public:
  CheckedSmiSlowPath(CheckedSmiOpInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    Register result = locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (instruction_->env() != NULL) {
      Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
      compiler->pending_deoptimization_env_ = env;
    }
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    const String& selector =
        String::Handle(instruction_->call()->ic_data()->target_name());
    const Array& argument_names =
        Array::Handle(instruction_->call()->ic_data()->arguments_descriptor());
    compiler->EmitMegamorphicInstanceCall(
        selector, argument_names, instruction_->call()->ArgumentCount(),
        instruction_->call()->deopt_id(), instruction_->call()->token_pos(),
        locs, try_index_,
        /* slow_path_argument_count = */ 2);
    __ mov(result, V0);
    compiler->RestoreLiveRegisters(locs);
    __ b(exit_label());
    compiler->pending_deoptimization_env_ = NULL;
  }

 private:
  CheckedSmiOpInstr* instruction_;
  intptr_t try_index_;
};


LocationSummary* CheckedSmiOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void CheckedSmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckedSmiSlowPath* slow_path =
      new CheckedSmiSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);
  // Test operands if necessary.
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  intptr_t left_cid = this->left()->Type()->ToCid();
  intptr_t right_cid = this->right()->Type()->ToCid();
  bool combined_smi_check = false;
  if (this->left()->definition() == this->right()->definition()) {
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ andi(CMPRES1, right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));
  } else {
    combined_smi_check = true;
    __ or_(result, left, right);
    __ andi(CMPRES1, result, Immediate(kSmiTagMask));
  }
  __ bne(CMPRES1, ZR, slow_path->entry_label());
  switch (op_kind()) {
    case Token::kADD:
      __ AdduDetectOverflow(result, left, right, CMPRES1);
      __ bltz(CMPRES1, slow_path->entry_label());
      break;
    case Token::kSUB:
      __ SubuDetectOverflow(result, left, right, CMPRES1);
      __ bltz(CMPRES1, slow_path->entry_label());
      break;
    case Token::kMUL:
      __ sra(TMP, left, kSmiTagSize);
      __ mult(TMP, right);
      __ mflo(result);
      __ mfhi(CMPRES2);
      __ sra(CMPRES1, result, 31);
      __ bne(CMPRES1, CMPRES2, slow_path->entry_label());
      break;
    case Token::kBIT_OR:
      // Operation part of combined smi check.
      if (!combined_smi_check) {
        __ or_(result, left, right);
      }
      break;
    case Token::kBIT_AND:
      __ and_(result, left, right);
      break;
    case Token::kBIT_XOR:
      __ xor_(result, left, right);
      break;
    case Token::kSHL:
      ASSERT(result != left);
      ASSERT(result != right);
      __ BranchUnsignedGreater(right, Immediate(Smi::RawValue(Smi::kBits)),
                               slow_path->entry_label());
      // Check for overflow by shifting left and shifting back arithmetically.
      // If the result is different from the original, there was overflow.
      __ delay_slot()->SmiUntag(TMP, right);
      __ sllv(result, left, TMP);
      __ srav(CMPRES1, result, TMP);
      __ bne(CMPRES1, left, slow_path->entry_label());
      break;
    case Token::kSHR:
      __ BranchUnsignedGreater(right, Immediate(Smi::RawValue(Smi::kBits)),
                               slow_path->entry_label());
      __ delay_slot()->SmiUntag(result, right);
      __ SmiUntag(TMP, left);
      __ srav(result, TMP, result);
      __ SmiTag(result);
      break;
    default:
      UNIMPLEMENTED();
  }
  __ Bind(slow_path->exit_label());
}


class CheckedSmiComparisonSlowPath : public SlowPathCode {
 public:
  CheckedSmiComparisonSlowPath(CheckedSmiComparisonInstr* instruction,
                               intptr_t try_index,
                               BranchLabels labels,
                               bool merged)
      : instruction_(instruction),
        try_index_(try_index),
        labels_(labels),
        merged_(merged) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path smi operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    Register result = merged_ ? locs->temp(0).reg() : locs->out(0).reg();
    locs->live_registers()->Remove(Location::RegisterLocation(result));

    compiler->SaveLiveRegisters(locs);
    if (instruction_->env() != NULL) {
      Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
      compiler->pending_deoptimization_env_ = env;
    }
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    String& selector =
        String::Handle(instruction_->call()->ic_data()->target_name());
    Array& argument_names =
        Array::Handle(instruction_->call()->ic_data()->arguments_descriptor());
    compiler->EmitMegamorphicInstanceCall(
        selector, argument_names, instruction_->call()->ArgumentCount(),
        instruction_->call()->deopt_id(), instruction_->call()->token_pos(),
        locs, try_index_,
        /* slow_path_argument_count = */ 2);
    __ mov(result, V0);
    compiler->RestoreLiveRegisters(locs);
    compiler->pending_deoptimization_env_ = NULL;
    if (merged_) {
      __ BranchEqual(result, Bool::True(), instruction_->is_negated()
                                               ? labels_.false_label
                                               : labels_.true_label);
      __ b(instruction_->is_negated() ? labels_.true_label
                                      : labels_.false_label);
    } else {
      __ b(exit_label());
    }
  }

 private:
  CheckedSmiComparisonInstr* instruction_;
  intptr_t try_index_;
  BranchLabels labels_;
  bool merged_;
};


LocationSummary* CheckedSmiComparisonInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


Condition CheckedSmiComparisonInstr::EmitComparisonCode(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  return EmitSmiComparisonOp(compiler, *locs(), kind());
}


#define EMIT_SMI_CHECK                                                         \
  Register left = locs()->in(0).reg();                                         \
  Register right = locs()->in(1).reg();                                        \
  Register temp = locs()->temp(0).reg();                                       \
  intptr_t left_cid = this->left()->Type()->ToCid();                           \
  intptr_t right_cid = this->right()->Type()->ToCid();                         \
  if (this->left()->definition() == this->right()->definition()) {             \
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));                            \
  } else if (left_cid == kSmiCid) {                                            \
    __ andi(CMPRES1, right, Immediate(kSmiTagMask));                           \
  } else if (right_cid == kSmiCid) {                                           \
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));                            \
  } else {                                                                     \
    __ or_(temp, left, right);                                                 \
    __ andi(CMPRES1, temp, Immediate(kSmiTagMask));                            \
  }                                                                            \
  __ bne(CMPRES1, ZR, slow_path->entry_label());


void CheckedSmiComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                               BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, compiler->CurrentTryIndex(), labels,
      /* merged = */ true);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
  __ Bind(slow_path->exit_label());
}


void CheckedSmiComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label true_label, false_label, done;
  BranchLabels labels = {&true_label, &false_label, &false_label};
  CheckedSmiComparisonSlowPath* slow_path = new CheckedSmiComparisonSlowPath(
      this, compiler->CurrentTryIndex(), labels,
      /* merged = */ false);
  compiler->AddSlowPathCode(slow_path);
  EMIT_SMI_CHECK;
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
  Register result = locs()->out(0).reg();
  __ Bind(&false_label);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&true_label);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
  __ Bind(slow_path->exit_label());
}


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      ((op_kind() == Token::kADD) || (op_kind() == Token::kMOD) ||
       (op_kind() == Token::kTRUNCDIV) ||
       (((op_kind() == Token::kSHL) && can_overflow()) ||
        (op_kind() == Token::kSHR)))
          ? 1
          : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kTRUNCDIV) {
    summary->set_in(0, Location::RequiresRegister());
    if (RightIsPowerOfTwoConstant()) {
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      summary->set_in(1, Location::Constant(right_constant));
    } else {
      summary->set_in(1, Location::RequiresRegister());
    }
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  if (op_kind() == Token::kMOD) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
  if (((op_kind() == Token::kSHL) && can_overflow()) ||
      (op_kind() == Token::kSHR)) {
    summary->set_temp(0, Location::RequiresRegister());
  } else if (op_kind() == Token::kADD) {
    // Need an extra temp for the overflow detection code.
    summary->set_temp(0, Location::RequiresRegister());
  }
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("BinarySmiOpInstr");
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  Register left = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const int32_t imm = reinterpret_cast<int32_t>(constant.raw());
    switch (op_kind()) {
      case Token::kADD: {
        if (deopt == NULL) {
          __ AddImmediate(result, left, imm);
        } else {
          Register temp = locs()->temp(0).reg();
          __ AddImmediateDetectOverflow(result, left, imm, CMPRES1, temp);
          __ bltz(CMPRES1, deopt);
        }
        break;
      }
      case Token::kSUB: {
        __ Comment("kSUB imm");
        if (deopt == NULL) {
          __ AddImmediate(result, left, -imm);
        } else {
          __ SubImmediateDetectOverflow(result, left, imm, CMPRES1);
          __ bltz(CMPRES1, deopt);
        }
        break;
      }
      case Token::kMUL: {
        // Keep left value tagged and untag right value.
        const intptr_t value = Smi::Cast(constant).Value();
        __ LoadImmediate(TMP, value);
        __ mult(left, TMP);
        __ mflo(result);
        if (deopt != NULL) {
          __ mfhi(CMPRES2);
          __ sra(CMPRES1, result, 31);
          __ bne(CMPRES1, CMPRES2, deopt);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        __ sra(TMP, left, 31);
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        Register temp = locs()->temp(0).reg();
        __ srl(TMP, TMP, 32 - shift_count);
        __ addu(temp, left, TMP);
        ASSERT(shift_count > 0);
        __ sra(result, temp, shift_count);
        if (value < 0) {
          __ subu(result, ZR, result);
        }
        __ SmiTag(result);
        break;
      }
      case Token::kBIT_AND: {
        // No overflow check.
        __ AndImmediate(result, left, imm);
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        __ OrImmediate(result, left, imm);
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        __ XorImmediate(result, left, imm);
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        const intptr_t value = Smi::Cast(constant).Value();
        __ Comment("kSHR");
        __ sra(result, left, Utils::Minimum(value + kSmiTagSize, kCountLimit));
        __ SmiTag(result);
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }

  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD: {
      if (deopt == NULL) {
        __ addu(result, left, right);
      } else {
        Register temp = locs()->temp(0).reg();
        __ AdduDetectOverflow(result, left, right, CMPRES1, temp);
        __ bltz(CMPRES1, deopt);
      }
      break;
    }
    case Token::kSUB: {
      __ Comment("kSUB");
      if (deopt == NULL) {
        __ subu(result, left, right);
      } else {
        __ SubuDetectOverflow(result, left, right, CMPRES1);
        __ bltz(CMPRES1, deopt);
      }
      break;
    }
    case Token::kMUL: {
      __ Comment("kMUL");
      __ sra(TMP, left, kSmiTagSize);
      __ mult(TMP, right);
      __ mflo(result);
      if (deopt != NULL) {
        __ mfhi(CMPRES2);
        __ sra(CMPRES1, result, 31);
        __ bne(CMPRES1, CMPRES2, deopt);
      }
      break;
    }
    case Token::kBIT_AND: {
      // No overflow check.
      __ and_(result, left, right);
      break;
    }
    case Token::kBIT_OR: {
      // No overflow check.
      __ or_(result, left, right);
      break;
    }
    case Token::kBIT_XOR: {
      // No overflow check.
      __ xor_(result, left, right);
      break;
    }
    case Token::kTRUNCDIV: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ beq(right, ZR, deopt);
      }
      Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);
      __ div(temp, TMP);
      __ mflo(result);
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ BranchEqual(result, Immediate(0x40000000), deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ beq(right, ZR, deopt);
      }
      Register temp = locs()->temp(0).reg();
      __ SmiUntag(temp, left);
      __ SmiUntag(TMP, right);
      __ div(temp, TMP);
      __ mfhi(result);
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      Label done;
      __ bgez(result, &done);
      if (RangeUtils::Overlaps(right_range(), -1, 1)) {
        Label subtract;
        __ bltz(right, &subtract);
        __ addu(result, result, TMP);
        __ b(&done);
        __ Bind(&subtract);
        __ subu(result, result, TMP);
      } else if (right_range()->IsPositive()) {
        // Right is positive.
        __ addu(result, result, TMP);
      } else {
        // Right is negative.
        __ subu(result, result, TMP);
      }
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      Register temp = locs()->temp(0).reg();
      if (CanDeoptimize()) {
        __ bltz(right, deopt);
      }
      __ SmiUntag(temp, right);
      // sra operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        Label ok;
        __ BranchSignedLessEqual(temp, Immediate(kCountLimit), &ok);
        __ LoadImmediate(temp, kCountLimit);
        __ Bind(&ok);
      }

      __ SmiUntag(CMPRES1, left);
      __ srav(result, CMPRES1, temp);
      __ SmiTag(result);
      break;
    }
    case Token::kDIV: {
      // Dispatches to 'Double./'.
      // TODO(srdjan): Implement as conversion to double and double division.
      UNREACHABLE();
      break;
    }
    case Token::kOR:
    case Token::kAND: {
      // Flow graph builder has dissected this operation to guarantee correct
      // behavior (short-circuit evaluation).
      UNREACHABLE();
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryDoubleOp,
                             licm_hoisted_ ? ICData::kHoisted : 0);
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  if (this->left()->definition() == this->right()->definition()) {
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ andi(CMPRES1, right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ andi(CMPRES1, left, Immediate(kSmiTagMask));
  } else {
    __ or_(TMP, left, right);
    __ andi(CMPRES1, TMP, Immediate(kSmiTagMask));
  }
  __ beq(CMPRES1, ZR, deopt);
}


LocationSummary* BoxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(from_representation() == kUnboxedDouble);

  Register out_reg = locs()->out(0).reg();
  DRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->double_class(),
                                  out_reg, locs()->temp(0).reg());
  __ StoreDToOffset(value, out_reg, Double::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (representation() == kUnboxedMint) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}


void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedMint: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      __ LoadFromOffset(result->At(0).reg(), box,
                        ValueOffset() - kHeapObjectTag);
      __ LoadFromOffset(result->At(1).reg(), box,
                        ValueOffset() - kHeapObjectTag + kWordSize);
      break;
    }

    case kUnboxedDouble: {
      const DRegister result = locs()->out(0).fpu_reg();
      __ LoadDFromOffset(result, box, Double::value_offset() - kHeapObjectTag);
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      UNIMPLEMENTED();
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}


void UnboxInstr::EmitSmiConversion(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedMint: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      __ SmiUntag(result->At(0).reg(), box);
      __ sra(result->At(1).reg(), result->At(0).reg(), 31);
      break;
    }

    case kUnboxedDouble: {
      const DRegister result = locs()->out(0).fpu_reg();
      __ SmiUntag(TMP, box);
      __ mtc1(TMP, STMP1);
      __ cvtdw(result, STMP1);
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}


void UnboxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t box_cid = BoxCid();

  if (value_cid == box_cid) {
    EmitLoadFromBox(compiler);
  } else if (CanConvertSmi() && (value_cid == kSmiCid)) {
    EmitSmiConversion(compiler);
  } else {
    const Register box = locs()->in(0).reg();
    Label* deopt =
        compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptCheckClass);
    Label is_smi;

    if ((value()->Type()->ToNullableCid() == box_cid) &&
        value()->Type()->is_nullable()) {
      __ BranchEqual(box, Object::null_object(), deopt);
    } else {
      __ andi(CMPRES1, box, Immediate(kSmiTagMask));
      __ beq(CMPRES1, ZR, CanConvertSmi() ? &is_smi : deopt);
      __ LoadClassId(CMPRES1, box);
      __ BranchNotEqual(CMPRES1, Immediate(box_cid), deopt);
    }

    EmitLoadFromBox(compiler);

    if (is_smi.IsLinked()) {
      Label done;
      __ b(&done);
      __ Bind(&is_smi);
      EmitSmiConversion(compiler);
      __ Bind(&done);
    }
  }
}


LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  ASSERT((from_representation() == kUnboxedInt32) ||
         (from_representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(value != out);

  __ SmiTag(out, value);
  if (!ValueFitsSmi()) {
    Register temp = locs()->temp(0).reg();
    Label done;
    if (from_representation() == kUnboxedInt32) {
      __ SmiUntag(CMPRES1, out);
      __ BranchEqual(CMPRES1, value, &done);
    } else {
      ASSERT(from_representation() == kUnboxedUint32);
      __ AndImmediate(CMPRES1, value, 0xC0000000);
      __ BranchEqual(CMPRES1, ZR, &done);
    }
    BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                    temp);
    Register hi;
    if (from_representation() == kUnboxedInt32) {
      hi = temp;
      __ sra(hi, value, kBitsPerWord - 1);
    } else {
      ASSERT(from_representation() == kUnboxedUint32);
      hi = ZR;
    }
    __ StoreToOffset(value, out, Mint::value_offset() - kHeapObjectTag);
    __ StoreToOffset(hi, out,
                     Mint::value_offset() - kHeapObjectTag + kWordSize);
    __ Bind(&done);
  }
}


LocationSummary* BoxInt64Instr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps,
                      ValueFitsSmi() ? LocationSummary::kNoCall
                                     : LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  if (!ValueFitsSmi()) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxInt64Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (ValueFitsSmi()) {
    PairLocation* value_pair = locs()->in(0).AsPairLocation();
    Register value_lo = value_pair->At(0).reg();
    Register out_reg = locs()->out(0).reg();
    __ SmiTag(out_reg, value_lo);
    return;
  }

  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register tmp = locs()->temp(0).reg();
  Register out_reg = locs()->out(0).reg();

  Label not_smi, done;
  __ SmiTag(out_reg, value_lo);
  __ SmiUntag(tmp, out_reg);
  __ bne(tmp, value_lo, &not_smi);
  __ delay_slot()->sra(tmp, out_reg, 31);
  __ beq(tmp, value_hi, &done);

  __ Bind(&not_smi);
  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                  out_reg, tmp);
  __ StoreToOffset(value_lo, out_reg, Mint::value_offset() - kHeapObjectTag);
  __ StoreToOffset(value_hi, out_reg,
                   Mint::value_offset() - kHeapObjectTag + kWordSize);
  __ Bind(&done);
}


LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  ASSERT((representation() == kUnboxedInt32) ||
         (representation() == kUnboxedUint32));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register mint,
                              Register result,
                              Label* deopt) {
  __ LoadFieldFromOffset(result, mint, Mint::value_offset());
  if (deopt != NULL) {
    __ LoadFieldFromOffset(CMPRES1, mint, Mint::value_offset() + kWordSize);
    __ sra(CMPRES2, result, kBitsPerWord - 1);
    __ BranchNotEqual(CMPRES1, CMPRES2, deopt);
  }
}


void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();
  Label* deopt =
      CanDeoptimize()
          ? compiler->AddDeoptStub(GetDeoptId(), ICData::kDeoptUnboxInteger)
          : NULL;
  Label* out_of_range = !is_truncating() ? deopt : NULL;
  ASSERT(value != out);

  if (value_cid == kSmiCid) {
    __ SmiUntag(out, value);
  } else if (value_cid == kMintCid) {
    LoadInt32FromMint(compiler, value, out, out_of_range);
  } else if (!CanDeoptimize()) {
    Label done;
    __ SmiUntag(out, value);
    __ andi(CMPRES1, value, Immediate(kSmiTagMask));
    __ beq(CMPRES1, ZR, &done);
    LoadInt32FromMint(compiler, value, out, NULL);
    __ Bind(&done);
  } else {
    Label done;
    __ SmiUntag(out, value);
    __ andi(CMPRES1, value, Immediate(kSmiTagMask));
    __ beq(CMPRES1, ZR, &done);
    __ LoadClassId(CMPRES1, value);
    __ BranchNotEqual(CMPRES1, Immediate(kMintCid), deopt);
    LoadInt32FromMint(compiler, value, out, out_of_range);
    __ Bind(&done);
  }
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_in(1, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister left = locs()->in(0).fpu_reg();
  DRegister right = locs()->in(1).fpu_reg();
  DRegister result = locs()->out(0).fpu_reg();
  switch (op_kind()) {
    case Token::kADD:
      __ addd(result, left, right);
      break;
    case Token::kSUB:
      __ subd(result, left, right);
      break;
    case Token::kMUL:
      __ muld(result, left, right);
      break;
    case Token::kDIV:
      __ divd(result, left, right);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


Condition DoubleTestOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  const DRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    __ cund(value, value);
    if (labels.fall_through == labels.true_label) {
      if (is_negated) {
        __ bc1t(labels.false_label);
      } else {
        __ bc1f(labels.false_label);
      }
    } else if (labels.fall_through == labels.false_label) {
      if (is_negated) {
        __ bc1f(labels.true_label);
      } else {
        __ bc1t(labels.true_label);
      }
    } else {
      if (is_negated) {
        __ bc1t(labels.false_label);
      } else {
        __ bc1f(labels.false_label);
      }
      __ b(labels.true_label);
    }
    return Condition();  // Unused.
  } else {
    ASSERT(op_kind() == MethodRecognizer::kDouble_getIsInfinite);
    __ mfc1(CMPRES1, EvenFRegisterOf(value));
    // If the low word isn't zero, then it isn't infinity.
    __ bne(CMPRES1, ZR, is_negated ? labels.true_label : labels.false_label);
    __ mfc1(CMPRES1, OddFRegisterOf(value));
    // Mask off the sign bit.
    __ AndImmediate(CMPRES1, CMPRES1, 0x7FFFFFFF);
    // Compare with +infinity.
    __ LoadImmediate(CMPRES2, 0x7FF00000);
    return Condition(CMPRES1, CMPRES2, is_negated ? NE : EQ);
  }
}

void DoubleTestOpInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                       BranchInstr* branch) {
  ASSERT(compiler->is_optimizing());
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  // Branches for isNaN are emitted in EmitComparisonCode already.
  if (op_kind() == MethodRecognizer::kDouble_getIsInfinite) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
}


void DoubleTestOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  // Branches for isNaN are emitted in EmitComparisonCode already.
  if (op_kind() == MethodRecognizer::kDouble_getIsInfinite) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
  const Register result = locs()->out(0).reg();
  Label done;
  __ Comment("return bool");
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2OneArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4ConstructorInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (kind() == MathUnaryInstr::kSqrt) {
    __ sqrtd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    DRegister val = locs()->in(0).fpu_reg();
    DRegister result = locs()->out(0).fpu_reg();
    __ muld(result, val, val);
  } else {
    UNREACHABLE();
  }
}


LocationSummary* CaseInsensitiveCompareUC16Instr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_in(1, Location::RegisterLocation(A1));
  summary->set_in(2, Location::RegisterLocation(A2));
  summary->set_in(3, Location::RegisterLocation(A3));
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void CaseInsensitiveCompareUC16Instr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  // Call the function.
  __ CallRuntime(TargetFunction(), TargetFunction().argument_count());
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    // Reuse the left register so that code can be made shorter.
    summary->set_out(0, Location::SameAsFirstInput());
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(result_cid() == kSmiCid);
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  // Reuse the left register so that code can be made shorter.
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}


void MathMinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((op_kind() == MethodRecognizer::kMathMin) ||
         (op_kind() == MethodRecognizer::kMathMax));
  const intptr_t is_min = (op_kind() == MethodRecognizer::kMathMin);
  if (result_cid() == kDoubleCid) {
    Label done, returns_nan, are_equal;
    DRegister left = locs()->in(0).fpu_reg();
    DRegister right = locs()->in(1).fpu_reg();
    DRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ cund(left, right);
    __ bc1t(&returns_nan);
    __ ceqd(left, right);
    __ bc1t(&are_equal);
    if (is_min) {
      __ coltd(left, right);
    } else {
      __ coltd(right, left);
    }
    // TODO(zra): Add conditional moves.
    ASSERT(left == result);
    __ bc1t(&done);
    __ movd(result, right);
    __ b(&done);

    __ Bind(&returns_nan);
    __ LoadImmediate(result, NAN);
    __ b(&done);

    __ Bind(&are_equal);
    Label left_is_negative;
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ mfc1(temp, OddFRegisterOf(left));  // Moves bits 32...63 of left to temp.
    if (is_min) {
      ASSERT(left == result);
      __ bltz(temp, &done);  // Left is negative.
    } else {
      __ bgez(temp, &done);  // Left is positive.
    }
    __ movd(result, right);
    __ Bind(&done);
    return;
  }

  Label done;
  ASSERT(result_cid() == kSmiCid);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == left);
  if (is_min) {
    __ BranchSignedLessEqual(left, right, &done);
  } else {
    __ BranchSignedGreaterEqual(left, right, &done);
  }
  __ mov(result, right);
  __ Bind(&done);
}


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // We make use of 3-operand instructions by not requiring result register
  // to be identical to first input register as on Intel.
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ SubuDetectOverflow(result, ZR, value, CMPRES1);
      __ bltz(CMPRES1, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ nor(result, value, ZR);
      __ addiu(result, result, Immediate(-1));  // Remove inverted smi-tag.
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  FpuRegister result = locs()->out(0).fpu_reg();
  FpuRegister value = locs()->in(0).fpu_reg();
  __ negd(result, value);
}


LocationSummary* Int32ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}


void Int32ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out(0).fpu_reg();
  __ mtc1(value, STMP1);
  __ cvtdw(result, STMP1);
}


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}


void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out(0).fpu_reg();
  __ SmiUntag(TMP, value);
  __ mtc1(TMP, STMP1);
  __ cvtdw(result, STMP1);
}


LocationSummary* MintToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void MintToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(T1));
  result->set_out(0, Location::RegisterLocation(V0));
  return result;
}


void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value_obj = locs()->in(0).reg();
  ASSERT(result == V0);
  ASSERT(result != value_obj);
  __ LoadDFromOffset(DTMP, value_obj, Double::value_offset() - kHeapObjectTag);
  __ truncwd(STMP1, DTMP);
  __ mfc1(result, STMP1);

  // Overflow is signaled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES1, result, TMP);
  __ bltz(CMPRES1, &do_call);
  __ SmiTag(result);
  __ b(&done);
  __ Bind(&do_call);
  __ Push(value_obj);
  ASSERT(instance_call()->HasICData());
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), instance_call()->token_pos(), target,
                               args_info, locs(), ICData::Handle());
  __ Bind(&done);
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  Register result = locs()->out(0).reg();
  DRegister value = locs()->in(0).fpu_reg();
  __ truncwd(STMP1, value);
  __ mfc1(result, STMP1);

  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES1, result, TMP);
  __ bltz(CMPRES1, deopt);
  __ SmiTag(result);
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister value = locs()->in(0).fpu_reg();
  FRegister result = EvenFRegisterOf(locs()->out(0).fpu_reg());
  __ cvtsd(result, value);
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  FRegister value = EvenFRegisterOf(locs()->in(0).fpu_reg());
  DRegister result = locs()->out(0).fpu_reg();
  __ cvtds(result, value);
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  // Calling convention on MIPS uses D6 and D7 to pass the first two
  // double arguments.
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::FpuRegisterLocation(D6));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(D7));
  }
  result->set_out(0, Location::FpuRegisterLocation(D0));
  return result;
}


// Pseudo code:
// if (exponent == 0.0) return 1.0;
// // Speed up simple cases.
// if (exponent == 1.0) return base;
// if (exponent == 2.0) return base * base;
// if (exponent == 3.0) return base * base * base;
// if (base == 1.0) return 1.0;
// if (base.isNaN || exponent.isNaN) {
//    return double.NAN;
// }
// if (base != -Infinity && exponent == 0.5) {
//   if (base == 0.0) return 0.0;
//   return sqrt(value);
// }
// TODO(srdjan): Move into a stub?
static void InvokeDoublePow(FlowGraphCompiler* compiler,
                            InvokeMathCFunctionInstr* instr) {
  ASSERT(instr->recognized_kind() == MethodRecognizer::kMathDoublePow);
  const intptr_t kInputCount = 2;
  ASSERT(instr->InputCount() == kInputCount);
  LocationSummary* locs = instr->locs();

  DRegister base = locs->in(0).fpu_reg();
  DRegister exp = locs->in(1).fpu_reg();
  DRegister result = locs->out(0).fpu_reg();

  Label check_base, skip_call;
  __ LoadImmediate(DTMP, 0.0);
  __ LoadImmediate(result, 1.0);
  // exponent == 0.0 -> return 1.0;
  __ cund(exp, exp);
  __ bc1t(&check_base);  // NaN -> check base.
  __ ceqd(exp, DTMP);
  __ bc1t(&skip_call);  // exp is 0.0, result is 1.0.

  // exponent == 1.0 ?
  __ ceqd(exp, result);
  Label return_base;
  __ bc1t(&return_base);
  // exponent == 2.0 ?
  __ LoadImmediate(DTMP, 2.0);
  __ ceqd(exp, DTMP);
  Label return_base_times_2;
  __ bc1t(&return_base_times_2);
  // exponent == 3.0 ?
  __ LoadImmediate(DTMP, 3.0);
  __ ceqd(exp, DTMP);
  __ bc1f(&check_base);

  // base_times_3.
  __ muld(result, base, base);
  __ muld(result, result, base);
  __ b(&skip_call);

  __ Bind(&return_base);
  __ movd(result, base);
  __ b(&skip_call);

  __ Bind(&return_base_times_2);
  __ muld(result, base, base);
  __ b(&skip_call);

  __ Bind(&check_base);
  // Note: 'exp' could be NaN.
  // base == 1.0 -> return 1.0;
  __ cund(base, base);
  Label return_nan;
  __ bc1t(&return_nan);
  __ ceqd(base, result);
  __ bc1t(&skip_call);  // base and result are 1.0.

  __ cund(exp, exp);
  Label try_sqrt;
  __ bc1f(&try_sqrt);  // Neither 'exp' nor 'base' are NaN.

  __ Bind(&return_nan);
  __ LoadImmediate(result, NAN);
  __ b(&skip_call);

  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadImmediate(result, kNegInfinity);
  // base == -Infinity -> call pow;
  __ ceqd(base, result);
  Label do_pow;
  __ bc1t(&do_pow);

  // exponent == 0.5 ?
  __ LoadImmediate(result, 0.5);
  __ ceqd(exp, result);
  __ bc1f(&do_pow);

  // base == 0 -> return 0;
  __ LoadImmediate(DTMP, 0.0);
  __ ceqd(base, DTMP);
  Label return_zero;
  __ bc1t(&return_zero);

  __ sqrtd(result, base);
  __ b(&skip_call);

  __ Bind(&return_zero);
  __ movd(result, DTMP);
  __ b(&skip_call);

  __ Bind(&do_pow);

  // double values are passed and returned in vfp registers.
  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ Bind(&skip_call);
}


void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // For pow-function return NaN if exponent is NaN.
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  // double values are passed and returned in vfp registers.
  __ CallRuntime(TargetFunction(), InputCount());
}


LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  // Only use this instruction in optimized code.
  ASSERT(opt);
  const intptr_t kNumInputs = 1;
  LocationSummary* summary =
      new (zone) LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    if (index() == 0) {
      summary->set_in(
          0, Location::Pair(Location::RequiresFpuRegister(), Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(
          0, Location::Pair(Location::Any(), Location::RequiresFpuRegister()));
    }
    summary->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(representation() == kTagged);
    if (index() == 0) {
      summary->set_in(
          0, Location::Pair(Location::RequiresRegister(), Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(
          0, Location::Pair(Location::Any(), Location::RequiresRegister()));
    }
    summary->set_out(0, Location::RequiresRegister());
  }
  return summary;
}


void ExtractNthOutputInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).IsPairLocation());
  PairLocation* pair = locs()->in(0).AsPairLocation();
  Location in_loc = pair->At(index());
  if (representation() == kUnboxedDouble) {
    DRegister out = locs()->out(0).fpu_reg();
    DRegister in = in_loc.fpu_reg();
    __ movd(out, in);
  } else {
    ASSERT(representation() == kTagged);
    Register out = locs()->out(0).reg();
    Register in = in_loc.reg();
    __ mov(out, in);
  }
}


LocationSummary* TruncDivModInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());
  // Output is a pair of registers.
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void TruncDivModInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(CanDeoptimize());
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register temp = locs()->temp(0).reg();
  ASSERT(locs()->out(0).IsPairLocation());
  PairLocation* pair = locs()->out(0).AsPairLocation();
  Register result_div = pair->At(0).reg();
  Register result_mod = pair->At(1).reg();
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ beq(right, ZR, deopt);
  }
  __ SmiUntag(temp, left);
  __ SmiUntag(TMP, right);
  __ div(temp, TMP);
  __ mflo(result_div);
  __ mfhi(result_mod);
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  __ BranchEqual(result_div, Immediate(0x40000000), deopt);
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  Label done;
  __ bgez(result_mod, &done);
  if (RangeUtils::Overlaps(divisor_range(), -1, 1)) {
    Label subtract;
    __ bltz(right, &subtract);
    __ addu(result_mod, result_mod, TMP);
    __ b(&done);
    __ Bind(&subtract);
    __ subu(result_mod, result_mod, TMP);
  } else if (divisor_range()->IsPositive()) {
    // Right is positive.
    __ addu(result_mod, result_mod, TMP);
  } else {
    // Right is negative.
    __ subu(result_mod, result_mod, TMP);
  }
  __ Bind(&done);

  __ SmiTag(result_div);
  __ SmiTag(result_mod);
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  return MakeCallSummary(zone);
}


LocationSummary* BranchInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("BranchInstr");
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const bool need_mask_temp = IsBitTest();
  const intptr_t kNumTemps = !IsNullCheck() ? (need_mask_temp ? 2 : 1) : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->set_temp(0, Location::RequiresRegister());
    if (need_mask_temp) {
      summary->set_temp(1, Location::RequiresRegister());
    }
  }
  return summary;
}


void CheckClassInstr::EmitNullCheck(FlowGraphCompiler* compiler, Label* deopt) {
  if (IsDeoptIfNull()) {
    __ BranchEqual(locs()->in(0).reg(), Object::null_object(), deopt);
  } else {
    ASSERT(IsDeoptIfNotNull());
    __ BranchNotEqual(locs()->in(0).reg(), Object::null_object(), deopt);
  }
}


void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ LoadImmediate(TMP, min);
  __ subu(biased_cid, biased_cid, TMP);
  __ LoadImmediate(TMP, max - min);
  __ BranchUnsignedGreater(biased_cid, TMP, deopt);

  Register bit_reg = locs()->temp(1).reg();
  __ LoadImmediate(bit_reg, 1);
  __ sllv(bit_reg, bit_reg, biased_cid);
  __ AndImmediate(bit_reg, bit_reg, mask);
  __ beq(bit_reg, ZR, deopt);
}


int CheckClassInstr::EmitCheckCid(FlowGraphCompiler* compiler,
                                  int bias,
                                  intptr_t cid_start,
                                  intptr_t cid_end,
                                  bool is_last,
                                  Label* is_ok,
                                  Label* deopt,
                                  bool use_near_jump) {
  Register biased_cid = locs()->temp(0).reg();
  if (cid_start == cid_end) {
    __ LoadImmediate(TMP, cid_start - bias);
    if (is_last) {
      __ bne(biased_cid, TMP, deopt);
    } else {
      __ beq(biased_cid, TMP, is_ok);
    }
  } else {
    // For class ID ranges use a subtract followed by an unsigned
    // comparison to check both ends of the ranges with one comparison.
    __ AddImmediate(biased_cid, biased_cid, bias - cid_start);
    bias = cid_start;
    // TODO(erikcorry): We should use sltiu instead of the temporary TMP if
    // the range is small enough.
    __ LoadImmediate(TMP, cid_end - cid_start);
    // Reverse comparison so we get 1 if biased_cid > tmp ie cid is out of
    // range.
    __ sltu(TMP, TMP, biased_cid);
    if (is_last) {
      __ bne(TMP, ZR, deopt);
    } else {
      __ beq(TMP, ZR, is_ok);
    }
  }
  return bias;
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("CheckSmiInstr");
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi,
                                        licm_hoisted_ ? ICData::kHoisted : 0);
  __ BranchIfNotSmi(value, deopt);
}


LocationSummary* CheckClassIdInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, cids_.IsSingleCid() ? Location::RequiresRegister()
                                         : Location::WritableRegister());

  return summary;
}


void CheckClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  if (cids_.IsSingleCid()) {
    __ BranchNotEqual(value, Immediate(Smi::RawValue(cids_.cid_start)), deopt);
  } else {
    __ AddImmediate(value, value, -Smi::RawValue(cids_.cid_start));
    // TODO(erikcorry): We should use sltiu instead of the temporary TMP if
    // the range is small enough.
    __ LoadImmediate(TMP, cids_.Extent());
    // Reverse comparison so we get 1 if biased_cid > tmp ie cid is out of
    // range.
    __ sltu(TMP, TMP, value);
    __ bne(TMP, ZR, deopt);
  }
}


LocationSummary* GenericCheckBoundInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_in(kLengthPos, Location::RequiresRegister());
  locs->set_in(kIndexPos, Location::RequiresRegister());
  return locs;
}


class RangeErrorSlowPath : public SlowPathCode {
 public:
  RangeErrorSlowPath(GenericCheckBoundInstr* instruction, intptr_t try_index)
      : instruction_(instruction), try_index_(try_index) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("slow path check bound operation");
    }
    __ Bind(entry_label());
    LocationSummary* locs = instruction_->locs();
    compiler->SaveLiveRegisters(locs);
    __ Push(locs->in(0).reg());
    __ Push(locs->in(1).reg());
    __ CallRuntime(kRangeErrorRuntimeEntry, 2);
    compiler->AddDescriptor(
        RawPcDescriptors::kOther, compiler->assembler()->CodeSize(),
        instruction_->deopt_id(), instruction_->token_pos(), try_index_);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->EmitCatchEntryState(env, try_index_);
    __ break_(0);
  }

 private:
  GenericCheckBoundInstr* instruction_;
  intptr_t try_index_;
};


void GenericCheckBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  RangeErrorSlowPath* slow_path =
      new RangeErrorSlowPath(this, compiler->CurrentTryIndex());
  compiler->AddSlowPathCode(slow_path);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);
  Register length = length_loc.reg();
  Register index = index_loc.reg();
  const intptr_t index_cid = this->index()->Type()->ToCid();
  if (index_cid != kSmiCid) {
    __ BranchIfNotSmi(index, slow_path->entry_label());
  }
  __ BranchUnsignedGreaterEqual(index, length, slow_path->entry_label());
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  uint32_t flags = generalized_ ? ICData::kGeneralized : 0;
  flags |= licm_hoisted_ ? ICData::kHoisted : 0;
  Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckArrayBound, flags);

  Location length_loc = locs()->in(kLengthPos);
  Location index_loc = locs()->in(kIndexPos);

  if (length_loc.IsConstant() && index_loc.IsConstant()) {
    ASSERT((Smi::Cast(length_loc.constant()).Value() <=
            Smi::Cast(index_loc.constant()).Value()) ||
           (Smi::Cast(index_loc.constant()).Value() < 0));
    // Unconditionally deoptimize for constant bounds checks because they
    // only occur only when index is out-of-bounds.
    __ b(deopt);
    return;
  }

  const intptr_t index_cid = index()->Type()->ToCid();
  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ BranchUnsignedLessEqual(
        length, Immediate(reinterpret_cast<int32_t>(index.raw())), deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    if (length.Value() == Smi::kMaxValue) {
      __ BranchSignedLess(index, Immediate(0), deopt);
    } else {
      __ BranchUnsignedGreaterEqual(
          index, Immediate(reinterpret_cast<int32_t>(length.raw())), deopt);
    }
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ BranchUnsignedGreaterEqual(index, length, deopt);
  }
}

LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs()->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);
  }
  switch (op_kind()) {
    case Token::kBIT_AND: {
      __ and_(out_lo, left_lo, right_lo);
      __ and_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kBIT_OR: {
      __ or_(out_lo, left_lo, right_lo);
      __ or_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kBIT_XOR: {
      __ xor_(out_lo, left_lo, right_lo);
      __ xor_(out_hi, left_hi, right_hi);
      break;
    }
    case Token::kADD:
    case Token::kSUB: {
      if (op_kind() == Token::kADD) {
        __ addu(out_lo, left_lo, right_lo);
        __ sltu(TMP, out_lo, left_lo);  // TMP = carry of left_lo + right_lo.
        __ addu(out_hi, left_hi, right_hi);
        __ addu(out_hi, out_hi, TMP);
        if (can_overflow()) {
          __ xor_(CMPRES1, out_hi, left_hi);
          __ xor_(TMP, out_hi, right_hi);
          __ and_(CMPRES1, TMP, CMPRES1);
          __ bltz(CMPRES1, deopt);
        }
      } else {
        __ subu(out_lo, left_lo, right_lo);
        __ sltu(TMP, left_lo, out_lo);  // TMP = borrow of left_lo - right_lo.
        __ subu(out_hi, left_hi, right_hi);
        __ subu(out_hi, out_hi, TMP);
        if (can_overflow()) {
          __ xor_(CMPRES1, out_hi, left_hi);
          __ xor_(TMP, left_hi, right_hi);
          __ and_(CMPRES1, TMP, CMPRES1);
          __ bltz(CMPRES1, deopt);
        }
      }
      break;
    }
    case Token::kMUL: {
      // The product of two signed 32-bit integers fits in a signed 64-bit
      // result without causing overflow.
      // We deopt on larger inputs.
      // TODO(regis): Range analysis may eliminate the deopt check.
      __ sra(CMPRES1, left_lo, 31);
      __ bne(CMPRES1, left_hi, deopt);
      __ delay_slot()->sra(CMPRES2, right_lo, 31);
      __ bne(CMPRES2, right_hi, deopt);
      __ delay_slot()->mult(left_lo, right_lo);
      __ mflo(out_lo);
      __ mfhi(out_hi);
      break;
    }
    default:
      UNREACHABLE();
  }
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::WritableRegisterOrSmiConstant(right()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);
  }
  if (locs()->in(1).IsConstant()) {
    // Code for a constant shift amount.
    ASSERT(locs()->in(1).constant().IsSmi());
    const int32_t shift =
        reinterpret_cast<int32_t>(locs()->in(1).constant().raw()) >> 1;
    switch (op_kind()) {
      case Token::kSHR: {
        if (shift < 32) {
          __ sll(out_lo, left_hi, 32 - shift);
          __ srl(TMP, left_lo, shift);
          __ or_(out_lo, out_lo, TMP);
          __ sra(out_hi, left_hi, shift);
        } else {
          if (shift == 32) {
            __ mov(out_lo, left_hi);
          } else if (shift < 64) {
            __ sra(out_lo, left_hi, shift - 32);
          } else {
            __ sra(out_lo, left_hi, 31);
          }
          __ sra(out_hi, left_hi, 31);
        }
        break;
      }
      case Token::kSHL: {
        ASSERT(shift < 64);
        if (shift < 32) {
          __ srl(out_hi, left_lo, 32 - shift);
          __ sll(TMP, left_hi, shift);
          __ or_(out_hi, out_hi, TMP);
          __ sll(out_lo, left_lo, shift);
        } else {
          __ sll(out_hi, left_lo, shift - 32);
          __ mov(out_lo, ZR);
        }
        // Check for overflow.
        if (can_overflow()) {
          // Compare high word from input with shifted high word from output.
          // Overflow if they aren't equal.
          // If shift > 32, also compare low word from input with high word from
          // output shifted back shift - 32.
          if (shift > 32) {
            __ sra(TMP, out_hi, shift - 32);
            __ bne(left_lo, TMP, deopt);
            __ delay_slot()->sra(TMP, out_hi, 31);
          } else if (shift == 32) {
            __ sra(TMP, out_hi, 31);
          } else {
            __ sra(TMP, out_hi, shift);
          }
          __ bne(left_hi, TMP, deopt);
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  } else {
    // Code for a variable shift amount.
    Register shift = locs()->in(1).reg();

    // Code below assumes shift amount is not 0 (cannot shift by 32 - 0).
    Label non_zero_shift, done;
    __ bne(shift, ZR, &non_zero_shift);
    __ delay_slot()->mov(out_lo, left_lo);
    __ b(&done);
    __ delay_slot()->mov(out_hi, left_hi);
    __ Bind(&non_zero_shift);

    // Deopt if shift is larger than 63 or less than 0.
    if (has_shift_count_check()) {
      __ sltiu(CMPRES1, shift, Immediate(2 * (kMintShiftCountLimit + 1)));
      __ beq(CMPRES1, ZR, deopt);
      // Untag shift count.
      __ delay_slot()->SmiUntag(shift);
    } else {
      // Untag shift count.
      __ SmiUntag(shift);
    }

    switch (op_kind()) {
      case Token::kSHR: {
        Label large_shift;
        __ sltiu(CMPRES1, shift, Immediate(32));
        __ beq(CMPRES1, ZR, &large_shift);

        // 0 < shift < 32.
        __ delay_slot()->ori(TMP, ZR, Immediate(32));
        __ subu(TMP, TMP, shift);  // TMP = 32 - shift; 0 < TMP <= 31.
        __ sllv(out_lo, left_hi, TMP);
        __ srlv(TMP, left_lo, shift);
        __ or_(out_lo, out_lo, TMP);
        __ b(&done);
        __ delay_slot()->srav(out_hi, left_hi, shift);

        // shift >= 32.
        __ Bind(&large_shift);
        __ sra(out_hi, left_hi, 31);
        __ srav(out_lo, left_hi, shift);  // Only 5 low bits of shift used.

        break;
      }
      case Token::kSHL: {
        Label large_shift;
        __ sltiu(CMPRES1, shift, Immediate(32));
        __ beq(CMPRES1, ZR, &large_shift);

        // 0 < shift < 32.
        __ delay_slot()->ori(TMP, ZR, Immediate(32));
        __ subu(TMP, TMP, shift);  // TMP = 32 - shift; 0 < TMP <= 31.
        __ srlv(out_hi, left_lo, TMP);
        __ sllv(TMP, left_hi, shift);
        __ or_(out_hi, out_hi, TMP);
        // Check for overflow.
        if (can_overflow()) {
          // Compare high word from input with shifted high word from output.
          __ srav(TMP, out_hi, shift);
          __ beq(TMP, left_hi, &done);
          __ delay_slot()->sllv(out_lo, left_lo, shift);
          __ b(deopt);
        } else {
          __ b(&done);
          __ delay_slot()->sllv(out_lo, left_lo, shift);
        }

        // shift >= 32.
        __ Bind(&large_shift);
        __ sllv(out_hi, left_lo, shift);  // Only 5 low bits of shift used.
        // Check for overflow.
        if (can_overflow()) {
          // Compare low word from input with shifted high word from output and
          // high word from input to sign of output.
          // Overflow if they aren't equal.
          __ srav(TMP, out_hi, shift);
          __ bne(TMP, left_lo, deopt);
          __ delay_slot()->sra(TMP, out_hi, 31);
          __ bne(TMP, left_hi, deopt);
          __ delay_slot()->mov(out_lo, ZR);
        } else {
          __ mov(out_lo, ZR);
        }
        break;
      }
      default:
        UNREACHABLE();
    }
    __ Bind(&done);
  }
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                     Location::RequiresRegister()));
  return summary;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(op_kind() == Token::kBIT_NOT);
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();

  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();

  __ nor(out_lo, ZR, left_lo);
  __ nor(out_hi, ZR, left_hi);
}


CompileType BinaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType ShiftUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}


CompileType UnaryUint32OpInstr::ComputeType() const {
  return CompileType::Int();
}


LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BinaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register out = locs()->out(0).reg();
  ASSERT(out != left);
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ and_(out, left, right);
      break;
    case Token::kBIT_OR:
      __ or_(out, left, right);
      break;
    case Token::kBIT_XOR:
      __ xor_(out, left, right);
      break;
    case Token::kADD:
      __ addu(out, left, right);
      break;
    case Token::kSUB:
      __ subu(out, left, right);
      break;
    case Token::kMUL:
      __ multu(left, right);
      __ mflo(out);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RegisterOrSmiConstant(right()));
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t kShifterLimit = 31;

  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  Register temp = locs()->temp(0).reg();

  ASSERT(left != out);

  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryMintOp);

  if (locs()->in(1).IsConstant()) {
    // Shifter is constant.

    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t shift_value = Smi::Cast(constant).Value();

    // Do the shift: (shift_value > 0) && (shift_value <= kShifterLimit).
    switch (op_kind()) {
      case Token::kSHR:
        __ srl(out, left, shift_value);
        break;
      case Token::kSHL:
        __ sll(out, left, shift_value);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  // Non constant shift value.
  Register shifter = locs()->in(1).reg();

  __ SmiUntag(temp, shifter);
  // If shift value is < 0, deoptimize.
  __ bltz(temp, deopt);
  __ delay_slot()->mov(out, left);
  __ sltiu(CMPRES1, temp, Immediate(kShifterLimit + 1));
  __ movz(out, ZR, CMPRES1);  // out = shift > kShifterLimit ? 0 : left.
  // Do the shift % 32.
  switch (op_kind()) {
    case Token::kSHR:
      __ srlv(out, out, temp);
      break;
    case Token::kSHL:
      __ sllv(out, out, temp);
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* UnaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void UnaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(left != out);

  ASSERT(op_kind() == Token::kBIT_NOT);

  __ nor(out, ZR, left);
}


DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)


LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (from() == kUnboxedMint) {
    ASSERT((to() == kUnboxedUint32) || (to() == kUnboxedInt32));
    summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                      Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else if (to() == kUnboxedMint) {
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT((to() == kUnboxedUint32) || (to() == kUnboxedInt32));
    ASSERT((from() == kUnboxedUint32) || (from() == kUnboxedInt32));
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  }
  return summary;
}


void UnboxedIntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    const Register out = locs()->out(0).reg();
    // Representations are bitwise equivalent.
    ASSERT(out == locs()->in(0).reg());
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ BranchSignedLess(out, Immediate(0), deopt);
    }
  } else if (from() == kUnboxedMint) {
    ASSERT(to() == kUnboxedUint32 || to() == kUnboxedInt32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ mov(out, in_lo);
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      ASSERT(to() == kUnboxedInt32);
      __ sra(TMP, in_lo, 31);
      __ bne(in_hi, TMP, deopt);
    }
  } else if (from() == kUnboxedUint32 || from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedMint);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ mov(out_lo, in);
    if (from() == kUnboxedUint32) {
      __ xor_(out_hi, out_hi, out_hi);
    } else {
      ASSERT(from() == kUnboxedInt32);
      __ sra(out_hi, in, 31);
    }
  } else {
    UNREACHABLE();
  }
}


LocationSummary* ThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(), kThrowRuntimeEntry, 1,
                                locs());
  __ break_(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStackTrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(), kReThrowRuntimeEntry,
                                2, locs());
  __ break_(0);
}


LocationSummary* StopInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void StopInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Stop(message());
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("GotoInstr");
  if (!compiler->is_optimizing()) {
    if (FLAG_reorder_basic_blocks) {
      compiler->EmitEdgeCounter(block()->preorder_number());
    }
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
    __ b(compiler->GetJumpLabel(successor()));
  }
}


LocationSummary* IndirectGotoInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  summary->set_temp(0, Location::RequiresRegister());

  return summary;
}


void IndirectGotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register target_reg = locs()->temp_slot(0)->reg();

  __ GetNextPC(target_reg, TMP);
  const intptr_t entry_offset = __ CodeSize() - 1 * Instr::kInstrSize;
  __ AddImmediate(target_reg, target_reg, -entry_offset);

  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  if (offset()->definition()->representation() == kTagged) {
    __ SmiUntag(offset_reg);
  }
  __ addu(target_reg, target_reg, offset_reg);

  // Jump to the absolute address.
  __ jr(target_reg);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(A0));
    locs->set_in(1, Location::RegisterLocation(A1));
    locs->set_out(0, Location::RegisterLocation(A0));
    return locs;
  }
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterOrConstant(left()));
  // Only one of the inputs can be a constant. Choose register if the first one
  // is a constant.
  locs->set_in(1, locs->in(0).IsConstant()
                      ? Location::RequiresRegister()
                      : Location::RegisterOrConstant(right()));
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}


Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());
  Condition true_condition;
  if (left.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(
        right.reg(), left.constant(), needs_number_check(), token_pos());
  } else if (right.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(
        left.reg(), right.constant(), needs_number_check(), token_pos());
  } else {
    true_condition = compiler->EmitEqualityRegRegCompare(
        left.reg(), right.reg(), needs_number_check(), token_pos());
  }
  if (kind() != Token::kEQ_STRICT) {
    ASSERT(kind() == Token::kNE_STRICT);
    true_condition = NegateCondition(true_condition);
  }
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("StrictCompareInstr");
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  __ Comment("StrictCompareInstr::EmitBranchCode");
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ LoadObject(result, Bool::True());
  __ LoadObject(TMP, Bool::False());
  __ subu(CMPRES1, value, result);
  __ movz(result, TMP, CMPRES1);  // If value is True, move False into result.
}


LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  return MakeCallSummary(zone);
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Comment("AllocateObjectInstr");
  const Code& stub = Code::ZoneHandle(
      compiler->zone(), StubCode::GetAllocationStubForClass(cls()));
  const StubEntry stub_entry(stub);
  compiler->GenerateCall(token_pos(), stub_entry, RawPcDescriptors::kOther,
                         locs());
  compiler->AddStubCallTarget(stub);
  __ Drop(ArgumentCount());  // Discard arguments.
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  __ BranchLinkPatchable(*StubCode::DebugStepCheck_entry());
  compiler->AddCurrentDescriptor(stub_kind_, Thread::kNoDeoptId, token_pos());
  compiler->RecordSafepoint(locs());
}


LocationSummary* GrowRegExpStackInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void GrowRegExpStackInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register typed_data = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  __ Comment("GrowRegExpStackInstr");
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 1 * kWordSize));
  __ sw(typed_data, Address(SP, 0 * kWordSize));
  compiler->GenerateRuntimeCall(TokenPosition::kNoSource, deopt_id(),
                                kGrowRegExpStackRuntimeEntry, 1, locs());
  __ lw(result, Address(SP, 1 * kWordSize));
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
