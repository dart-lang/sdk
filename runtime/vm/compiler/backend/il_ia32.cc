// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/backend/il.h"

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/compiler/backend/locations_helpers.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

#define __ compiler->assembler()->
#define Z (compiler->zone())

namespace dart {

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register EAX.
LocationSummary* Instruction::MakeCallSummary(Zone* zone) {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(EAX));
  return result;
}

DEFINE_BACKEND(LoadIndexedUnsafe, (Register out, Register index)) {
  ASSERT(instr->RequiredInputRepresentation(0) == kTagged);  // It is a Smi.
  __ movl(out, Address(instr->base_reg(), index, TIMES_2, instr->offset()));

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(StoreIndexedUnsafe,
               (NoLocation, Register index, Register value)) {
  ASSERT(instr->RequiredInputRepresentation(
             StoreIndexedUnsafeInstr::kIndexPos) == kTagged);  // It is a Smi.
  __ movl(Address(instr->base_reg(), index, TIMES_2, instr->offset()), value);

  ASSERT(kSmiTag == 0);
  ASSERT(kSmiTagSize == 1);
}

DEFINE_BACKEND(TailCall,
               (NoLocation,
                Fixed<Register, ARGS_DESC_REG>,
                Temp<Register> temp)) {
  __ LoadObject(CODE_REG, instr->code());
  __ LeaveFrame();  // The arguments are still on the stack.
  __ movl(temp, FieldAddress(CODE_REG, Code::entry_point_offset()));
  __ jmp(temp);
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
  if (compiler->is_optimizing()) {
    Location value = locs()->in(0);
    if (value.IsRegister()) {
      __ pushl(value.reg());
    } else if (value.IsConstant()) {
      __ PushObject(value.constant());
    } else {
      ASSERT(value.IsStackSlot());
      __ pushl(value.ToStackSlotAddress());
    }
  }
}

LocationSummary* ReturnInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  return locs;
}

// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instruction: a jump).
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->in(0).reg();
  ASSERT(result == EAX);

  if (compiler->intrinsic_mode()) {
    // Intrinsics don't have a frame.
    __ ret();
    return;
  }

#if defined(DEBUG)
  __ Comment("Stack Check");
  Label done;
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ movl(EDI, ESP);
  __ subl(EDI, EBP);
  __ cmpl(EDI, Immediate(fp_sp_dist));
  __ j(EQUAL, &done, Assembler::kNearJump);
  __ int3();
  __ Bind(&done);
#endif
  __ LeaveFrame();
  __ ret();
}

LocationSummary* LoadLocalInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t stack_index = (local().index() < 0)
                                   ? kFirstLocalSlotFromFp - local().index()
                                   : kParamEndSlotFromFp - local().index();
  return LocationSummary::Make(zone, kNumInputs,
                               Location::StackSlot(stack_index),
                               LocationSummary::kNoCall);
}

void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  // Nothing to do.
}

LocationSummary* StoreLocalInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ movl(Address(EBP, local().index() * kWordSize), value);
}

LocationSummary* ConstantInstr::MakeLocationSummary(Zone* zone,
                                                    bool opt) const {
  const intptr_t kNumInputs = 0;
  return LocationSummary::Make(zone, kNumInputs,
                               Assembler::IsSafe(value())
                                   ? Location::Constant(this)
                                   : Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  Location out = locs()->out(0);
  ASSERT(out.IsRegister() || out.IsConstant() || out.IsInvalid());
  if (out.IsRegister()) {
    Register result = out.reg();
    __ LoadObjectSafely(result, value());
  }
}

void ConstantInstr::EmitMoveToLocation(FlowGraphCompiler* compiler,
                                       const Location& destination,
                                       Register tmp) {
  if (destination.IsRegister()) {
    if (value_.IsSmi() && Smi::Cast(value_).Value() == 0) {
      __ xorl(destination.reg(), destination.reg());
    } else if (value_.IsSmi() && (representation() == kUnboxedInt32)) {
      __ movl(destination.reg(), Immediate(Smi::Cast(value_).Value()));
    } else {
      ASSERT(representation() == kTagged);
      __ LoadObjectSafely(destination.reg(), value_);
    }
  } else if (destination.IsFpuRegister()) {
    const double value_as_double = Double::Cast(value_).value();
    uword addr = FlowGraphBuilder::FindDoubleConstant(value_as_double);
    if (addr == 0) {
      __ pushl(EAX);
      __ LoadObject(EAX, value_);
      __ movsd(destination.fpu_reg(),
               FieldAddress(EAX, Double::value_offset()));
      __ popl(EAX);
    } else if (Utils::DoublesBitEqual(value_as_double, 0.0)) {
      __ xorps(destination.fpu_reg(), destination.fpu_reg());
    } else {
      __ movsd(destination.fpu_reg(), Address::Absolute(addr));
    }
  } else if (destination.IsDoubleStackSlot()) {
    const double value_as_double = Double::Cast(value_).value();
    uword addr = FlowGraphBuilder::FindDoubleConstant(value_as_double);
    if (addr == 0) {
      __ pushl(EAX);
      __ LoadObject(EAX, value_);
      __ movsd(XMM0, FieldAddress(EAX, Double::value_offset()));
      __ popl(EAX);
    } else if (Utils::DoublesBitEqual(value_as_double, 0.0)) {
      __ xorps(XMM0, XMM0);
    } else {
      __ movsd(XMM0, Address::Absolute(addr));
    }
    __ movsd(destination.ToStackSlotAddress(), XMM0);
  } else {
    ASSERT(destination.IsStackSlot());
    if (value_.IsSmi() && representation() == kUnboxedInt32) {
      __ movl(destination.ToStackSlotAddress(),
              Immediate(Smi::Cast(value_).Value()));
    } else {
      if (Assembler::IsSafeSmi(value_) || value_.IsNull()) {
        __ movl(destination.ToStackSlotAddress(),
                Immediate(reinterpret_cast<int32_t>(value_.raw())));
      } else {
        __ pushl(EAX);
        __ LoadObjectSafely(EAX, value_);
        __ movl(destination.ToStackSlotAddress(), EAX);
        __ popl(EAX);
      }
    }
  }
}

LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps =
      (constant_address() == 0) && (representation() != kUnboxedInt32) ? 1 : 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(representation() == kUnboxedInt32);
    locs->set_out(0, Location::RequiresRegister());
  }
  if (kNumTemps == 1) {
    locs->set_temp(0, Location::RequiresRegister());
  }
  return locs;
}

void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    EmitMoveToLocation(compiler, locs()->out(0));
  }
}

LocationSummary* AssertAssignableInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));  // Value.
  summary->set_in(1, Location::RegisterLocation(EDX));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(ECX));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

LocationSummary* AssertSubtypeInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EDX));  // Instant. type args.
  summary->set_in(1, Location::RegisterLocation(ECX));  // Function type args.
  return summary;
}

LocationSummary* AssertBooleanInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
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
  Isolate* isolate = Isolate::Current();

  if (isolate->type_checks()) {
    __ CompareObject(reg, Bool::True());
    __ j(EQUAL, &done, Assembler::kNearJump);
    __ CompareObject(reg, Bool::False());
    __ j(EQUAL, &done, Assembler::kNearJump);
  } else {
    ASSERT(isolate->asserts() || isolate->strong());
    __ CompareObject(reg, Object::null_instance());
    __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  }

  __ pushl(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos, deopt_id,
                                kNonBoolTypeErrorRuntimeEntry, 1, locs);
  // We should never return here.
  __ int3();
  __ Bind(&done);
}

void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}

static Condition TokenKindToSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return LESS;
    case Token::kGT:
      return GREATER;
    case Token::kLTE:
      return LESS_EQUAL;
    case Token::kGTE:
      return GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
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
    // Only right can be a stack slot.
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
  Label done;
  if (value_is_smi == NULL) {
    __ movl(value_cid_reg, Immediate(kSmiCid));
  }
  __ testl(value_reg, Immediate(kSmiTagMask));
  if (value_is_smi == NULL) {
    __ j(ZERO, &done, Assembler::kNearJump);
  } else {
    __ j(ZERO, value_is_smi);
  }
  __ LoadClassId(value_cid_reg, value_reg);
  __ Bind(&done);
}

static Condition FlipCondition(Condition condition) {
  switch (condition) {
    case EQUAL:
      return EQUAL;
    case NOT_EQUAL:
      return NOT_EQUAL;
    case LESS:
      return GREATER;
    case LESS_EQUAL:
      return GREATER_EQUAL;
    case GREATER:
      return LESS;
    case GREATER_EQUAL:
      return LESS_EQUAL;
    case BELOW:
      return ABOVE;
    case BELOW_EQUAL:
      return ABOVE_EQUAL;
    case ABOVE:
      return BELOW;
    case ABOVE_EQUAL:
      return BELOW_EQUAL;
    default:
      UNIMPLEMENTED();
      return EQUAL;
  }
}

static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQUAL:
      return NOT_EQUAL;
    case NOT_EQUAL:
      return EQUAL;
    case LESS:
      return GREATER_EQUAL;
    case LESS_EQUAL:
      return GREATER;
    case GREATER:
      return LESS_EQUAL;
    case GREATER_EQUAL:
      return LESS;
    case BELOW:
      return ABOVE_EQUAL;
    case BELOW_EQUAL:
      return ABOVE;
    case ABOVE:
      return BELOW_EQUAL;
    case ABOVE_EQUAL:
      return BELOW;
    case PARITY_ODD:
      return PARITY_EVEN;
    case PARITY_EVEN:
      return PARITY_ODD;
    default:
      UNIMPLEMENTED();
      return EQUAL;
  }
}

static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ j(true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = NegateCondition(true_condition);
    __ j(false_condition, labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ jmp(labels.true_label);
    }
  }
}

static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     const LocationSummary& locs,
                                     Token::Kind kind,
                                     BranchLabels labels) {
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(left.reg(), right.constant());
  } else if (right.IsStackSlot()) {
    __ cmpl(left.reg(), right.ToStackSlotAddress());
  } else {
    __ cmpl(left.reg(), right.reg());
  }
  return true_condition;
}

static Condition TokenKindToMintCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return LESS;
    case Token::kGT:
      return GREATER;
    case Token::kLTE:
      return LESS_EQUAL;
    case Token::kGTE:
      return GREATER_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}

static Condition EmitUnboxedMintEqualityOp(FlowGraphCompiler* compiler,
                                           const LocationSummary& locs,
                                           Token::Kind kind,
                                           BranchLabels labels) {
  ASSERT(Token::IsEqualityOperator(kind));
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();
  Label done;
  // Compare lower.
  __ cmpl(left1, right1);
  __ j(NOT_EQUAL, &done);
  // Lower is equal, compare upper.
  __ cmpl(left2, right2);
  __ Bind(&done);
  Condition true_condition = TokenKindToMintCondition(kind);
  return true_condition;
}

static Condition EmitUnboxedMintComparisonOp(FlowGraphCompiler* compiler,
                                             const LocationSummary& locs,
                                             Token::Kind kind,
                                             BranchLabels labels) {
  PairLocation* left_pair = locs.in(0).AsPairLocation();
  Register left1 = left_pair->At(0).reg();
  Register left2 = left_pair->At(1).reg();
  PairLocation* right_pair = locs.in(1).AsPairLocation();
  Register right1 = right_pair->At(0).reg();
  Register right2 = right_pair->At(1).reg();

  Condition hi_cond = OVERFLOW, lo_cond = OVERFLOW;
  switch (kind) {
    case Token::kLT:
      hi_cond = LESS;
      lo_cond = BELOW;
      break;
    case Token::kGT:
      hi_cond = GREATER;
      lo_cond = ABOVE;
      break;
    case Token::kLTE:
      hi_cond = LESS;
      lo_cond = BELOW_EQUAL;
      break;
    case Token::kGTE:
      hi_cond = GREATER;
      lo_cond = ABOVE_EQUAL;
      break;
    default:
      break;
  }
  ASSERT(hi_cond != OVERFLOW && lo_cond != OVERFLOW);
  // Compare upper halves first.
  __ cmpl(left2, right2);
  __ j(hi_cond, labels.true_label);
  __ j(FlipCondition(hi_cond), labels.false_label);

  // If upper is equal, compare lower half.
  __ cmpl(left1, right1);
  return lo_cond;
}

static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ:
      return EQUAL;
    case Token::kNE:
      return NOT_EQUAL;
    case Token::kLT:
      return BELOW;
    case Token::kGT:
      return ABOVE;
    case Token::kLTE:
      return BELOW_EQUAL;
    case Token::kGTE:
      return ABOVE_EQUAL;
    default:
      UNREACHABLE();
      return OVERFLOW;
  }
}

static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  XmmRegister left = locs.in(0).fpu_reg();
  XmmRegister right = locs.in(1).fpu_reg();

  __ comisd(left, right);

  Condition true_condition = TokenKindToDoubleCondition(kind);
  Label* nan_result =
      (true_condition == NOT_EQUAL) ? labels.true_label : labels.false_label;
  __ j(PARITY_EVEN, nan_result);
  return true_condition;
}

Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintEqualityOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}

void ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label is_true, is_false;
  BranchLabels labels = {&is_true, &is_false, &is_false};
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != INVALID_CONDITION) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }

  Register result = locs()->out(0).reg();
  Label done;
  __ Bind(&is_false);
  __ LoadObject(result, Bool::False());
  __ jmp(&done, Assembler::kNearJump);
  __ Bind(&is_true);
  __ LoadObject(result, Bool::True());
  __ Bind(&done);
}

void ComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                     BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  if (true_condition != INVALID_CONDITION) {
    EmitBranchOnCondition(compiler, true_condition, labels);
  }
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
    __ testl(left, Immediate(imm));
  } else {
    __ testl(left, right.reg());
  }
  Condition true_condition = (kind() == Token::kNE) ? NOT_ZERO : ZERO;
  return true_condition;
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

  Label* deopt = CanDeoptimize() ? compiler->AddDeoptStub(
                                       deopt_id(), ICData::kDeoptTestCids,
                                       licm_hoisted_ ? ICData::kHoisted : 0)
                                 : NULL;

  const intptr_t true_result = (kind() == Token::kIS) ? 1 : 0;
  const ZoneGrowableArray<intptr_t>& data = cid_results();
  ASSERT(data[0] == kSmiCid);
  bool result = data[1] == true_result;
  __ testl(val_reg, Immediate(kSmiTagMask));
  __ j(ZERO, result ? labels.true_label : labels.false_label);
  __ LoadClassId(cid_reg, val_reg);
  for (intptr_t i = 2; i < data.length(); i += 2) {
    const intptr_t test_cid = data[i];
    ASSERT(test_cid != kSmiCid);
    result = data[i + 1] == true_result;
    __ cmpl(cid_reg, Immediate(test_cid));
    __ j(EQUAL, result ? labels.true_label : labels.false_label);
  }
  // No match found, deoptimize or default action.
  if (deopt == NULL) {
    // If the cid is not in the list, jump to the opposite label from the cids
    // that are in the list.  These must be all the same (see asserts in the
    // constructor).
    Label* target = result ? labels.false_label : labels.true_label;
    if (target != labels.fall_through) {
      __ jmp(target);
    }
  } else {
    __ jmp(deopt);
  }
  // Dummy result as this method already did the jump, there's no need
  // for the caller to branch on a condition.
  return INVALID_CONDITION;
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
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else if (operation_cid() == kMintCid) {
    return EmitUnboxedMintComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}

LocationSummary* NativeCallInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  return MakeCallSummary(zone);
}

void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  SetupNative();
  Register result = locs()->out(0).reg();
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());

  // All arguments are already @ESP due to preceding PushArgument()s.
  ASSERT(ArgumentCount() == function().NumParameters() +
                                (function().IsGeneric() &&
                                 Isolate::Current()->reify_generic_functions())
             ? 1
             : 0);

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());

  // Pass a pointer to the first argument in EAX.
  __ leal(EAX, Address(ESP, ArgumentCount() * kWordSize));

  __ movl(EDX, Immediate(argc_tag));

  const StubEntry* stub_entry;

  // There is no lazy-linking support on ia32.
  ASSERT(!link_lazily());
  if (is_bootstrap_native()) {
    stub_entry = StubCode::CallBootstrapNative_entry();
  } else if (is_auto_scope()) {
    stub_entry = StubCode::CallAutoScopeNative_entry();
  } else {
    stub_entry = StubCode::CallNoScopeNative_entry();
  }
  const ExternalLabel label(reinterpret_cast<uword>(native_c_function()));
  __ movl(ECX, Immediate(label.address()));
  compiler->GenerateCall(token_pos(), *stub_entry, RawPcDescriptors::kOther,
                         locs());

  __ popl(result);

  __ Drop(ArgumentCount());  // Drop the arguments.
}

static bool CanBeImmediateIndex(Value* value, intptr_t cid) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if ((constant == NULL) || !Assembler::IsSafeSmi(constant->value())) {
    return false;
  }
  const int64_t index = Smi::Cast(constant->value()).AsInt64Value();
  const intptr_t scale = Instance::ElementSizeFor(cid);
  const intptr_t offset = Instance::DataOffsetFor(cid);
  const int64_t displacement = index * scale + offset;
  return Utils::IsInt(32, displacement);
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
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ movl(result,
          Immediate(reinterpret_cast<uword>(Symbols::PredefinedAddress())));
  __ movl(result, Address(result, char_code,
                          TIMES_HALF_WORD_SIZE,  // Char code is a smi.
                          Symbols::kNullCharCodeSymbolOffset * kWordSize));
}

LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(cid_ == kOneByteStringCid);
  Register str = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Label is_one, done;
  __ movl(result, FieldAddress(str, String::length_offset()));
  __ cmpl(result, Immediate(Smi::RawValue(1)));
  __ j(EQUAL, &is_one, Assembler::kNearJump);
  __ movl(result, Immediate(Smi::RawValue(-1)));
  __ jmp(&done);
  __ Bind(&is_one);
  __ movzxb(result, FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
}

LocationSummary* StringInterpolateInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ pushl(array);
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), token_pos(), CallFunction(),
                               args_info, locs(), ICData::Handle(),
                               ICData::kStatic);
  ASSERT(locs()->out(0).reg() == EAX);
}

LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  if (object()->definition()->representation() == kUntagged) {
    __ movl(result, Address(obj, offset()));
  } else {
    ASSERT(object()->definition()->representation() == kTagged);
    __ movl(result, FieldAddress(obj, offset()));
  }
}

LocationSummary* LoadClassIdInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register object = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  const AbstractType& value_type = *this->object()->Type()->ToAbstractType();
  if (CompileType::Smi().IsAssignableTo(value_type) ||
      value_type.IsTypeParameter()) {
    // We don't use Assembler::LoadTaggedClassIdMayBeSmi() here---which uses
    // a conditional move instead, and requires an additional register---because
    // it is slower, probably due to branch prediction usually working just fine
    // in this case.
    ASSERT(result != object);
    Label done;
    __ movl(result, Immediate(kSmiCid << 1));
    __ testl(object, Immediate(kSmiTagMask));
    __ j(EQUAL, &done, Assembler::kNearJump);
    __ LoadClassId(result, object);
    __ SmiTag(result);
    __ Bind(&done);
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
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}

LocationSummary* LoadIndexedInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                         : Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else if (representation() == kUnboxedUint32) {
    ASSERT(class_id() == kTypedDataUint32ArrayCid);
    locs->set_out(0, Location::RequiresRegister());
  } else if (representation() == kUnboxedInt32) {
    ASSERT(class_id() == kTypedDataInt32ArrayCid);
    locs->set_out(0, Location::RequiresRegister());
  } else {
    ASSERT(representation() == kTagged);
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}

void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address =
      index.IsRegister()
          ? Assembler::ElementAddressForRegIndex(
                IsExternal(), class_id(), index_scale(), array, index.reg())
          : Assembler::ElementAddressForIntIndex(
                IsExternal(), class_id(), index_scale(), array,
                Smi::Cast(index.constant()).Value());

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4) ||
      (representation() == kUnboxedFloat64x2)) {
    XmmRegister result = locs()->out(0).fpu_reg();
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }
    switch (class_id()) {
      case kTypedDataFloat32ArrayCid:
        __ movss(result, element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        __ movsd(result, element_address);
        break;
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataFloat64x2ArrayCid:
        __ movups(result, element_address);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if ((representation() == kUnboxedUint32) ||
      (representation() == kUnboxedInt32)) {
    Register result = locs()->out(0).reg();
    if ((index_scale() == 1) && index.IsRegister()) {
      __ SmiUntag(index.reg());
    }
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        ASSERT(representation() == kUnboxedInt32);
        __ movl(result, element_address);
        break;
      case kTypedDataUint32ArrayCid:
        ASSERT(representation() == kUnboxedUint32);
        __ movl(result, element_address);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  ASSERT(representation() == kTagged);

  Register result = locs()->out(0).reg();
  if ((index_scale() == 1) && index.IsRegister()) {
    __ SmiUntag(index.reg());
  }
  switch (class_id()) {
    case kTypedDataInt8ArrayCid:
      ASSERT(index_scale() == 1);
      __ movsxb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      ASSERT(index_scale() == 1);
      __ movzxb(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ movsxw(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      __ movzxw(result, element_address);
      __ SmiTag(result);
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ movl(result, element_address);
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
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      UNIMPLEMENTED();
      return kTagged;
  }
}

LocationSummary* StoreIndexedInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id())) {
    // CanBeImmediateIndex must return false for unsafe smis.
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    // The index is either untagged (element size == 1) or a smi (for all
    // element sizes > 1).
    locs->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                         : Location::RequiresRegister());
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
      // TODO(fschneider): Add location constraint for byte registers (EAX,
      // EBX, ECX, EDX) instead of using a fixed register.
      locs->set_in(2, Location::FixedRegisterOrSmiConstant(value(), EAX));
      break;
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
      // Writable register because the value must be untagged before storing.
      locs->set_in(2, Location::WritableRegister());
      break;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      locs->set_in(2, Location::RequiresRegister());
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
      // TODO(srdjan): Support Float64 constants.
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
      locs->set_in(2, Location::RequiresFpuRegister());
      break;
    default:
      UNREACHABLE();
      return NULL;
  }
  return locs;
}

void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address =
      index.IsRegister()
          ? Assembler::ElementAddressForRegIndex(
                IsExternal(), class_id(), index_scale(), array, index.reg())
          : Assembler::ElementAddressForIntIndex(
                IsExternal(), class_id(), index_scale(), array,
                Smi::Cast(index.constant()).Value());

  if ((index_scale() == 1) && index.IsRegister()) {
    __ SmiUntag(index.reg());
  }
  switch (class_id()) {
    case kArrayCid:
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
    case kOneByteStringCid:
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        __ movb(element_address,
                Immediate(static_cast<int8_t>(constant.Value())));
      } else {
        ASSERT(locs()->in(2).reg() == EAX);
        __ SmiUntag(EAX);
        __ movb(element_address, AL);
      }
      break;
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid: {
      if (locs()->in(2).IsConstant()) {
        const Smi& constant = Smi::Cast(locs()->in(2).constant());
        intptr_t value = constant.Value();
        // Clamp to 0x0 or 0xFF respectively.
        if (value > 0xFF) {
          value = 0xFF;
        } else if (value < 0) {
          value = 0;
        }
        __ movb(element_address, Immediate(static_cast<int8_t>(value)));
      } else {
        ASSERT(locs()->in(2).reg() == EAX);
        Label store_value, store_0xff;
        __ SmiUntag(EAX);
        __ cmpl(EAX, Immediate(0xFF));
        __ j(BELOW_EQUAL, &store_value, Assembler::kNearJump);
        // Clamp to 0x0 or 0xFF respectively.
        __ j(GREATER, &store_0xff);
        __ xorl(EAX, EAX);
        __ jmp(&store_value, Assembler::kNearJump);
        __ Bind(&store_0xff);
        __ movl(EAX, Immediate(0xFF));
        __ Bind(&store_value);
        __ movb(element_address, AL);
      }
      break;
    }
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      Register value = locs()->in(2).reg();
      __ SmiUntag(value);
      __ movw(element_address, value);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      __ movl(element_address, locs()->in(2).reg());
      break;
    case kTypedDataFloat32ArrayCid:
      __ movss(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataFloat64ArrayCid:
      __ movsd(element_address, locs()->in(2).fpu_reg());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
      __ movups(element_address, locs()->in(2).fpu_reg());
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
      __ cmpw(value_cid_reg, field_cid_operand);
      __ j(EQUAL, &ok);
      __ cmpw(value_cid_reg, field_nullability_operand);
    } else if (value_cid == kNullCid) {
      // Value in graph known to be null.
      // Compare with null.
      __ cmpw(field_nullability_operand, Immediate(value_cid));
    } else {
      // Value in graph known to be non-null.
      // Compare class id with guard field class id.
      __ cmpw(field_cid_operand, Immediate(value_cid));
    }
    __ j(EQUAL, &ok);

    // Check if the tracked state of the guarded field can be initialized
    // inline. If the field needs length check we fall through to runtime
    // which is responsible for computing offset of the length field
    // based on the class id.
    // Length guard will be emitted separately when needed via GuardFieldLength
    // instruction after GuardFieldClass.
    if (!field().needs_length_check()) {
      // Uninitialized field can be handled inline. Check if the
      // field is still unitialized.
      __ cmpw(field_cid_operand, Immediate(kIllegalCid));
      // Jump to failure path when guard field has been initialized and
      // the field and value class ids do not not match.
      __ j(NOT_EQUAL, fail);

      if (value_cid == kDynamicCid) {
        // Do not know value's class id.
        __ movw(field_cid_operand, value_cid_reg);
        __ movw(field_nullability_operand, value_cid_reg);
      } else {
        ASSERT(field_reg != kNoRegister);
        __ movw(field_cid_operand, Immediate(value_cid));
        __ movw(field_nullability_operand, Immediate(value_cid));
      }

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ jmp(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ cmpw(FieldAddress(field_reg, Field::guarded_cid_offset()),
              Immediate(kDynamicCid));
      __ j(EQUAL, &ok);

      __ pushl(field_reg);
      __ pushl(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    }
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(deopt != NULL);
    ASSERT(fail == deopt);

    // Field guard class has been initialized and is known.
    if (value_cid == kDynamicCid) {
      // Value's class id is not known.
      __ testl(value_reg, Immediate(kSmiTagMask));

      if (field_cid != kSmiCid) {
        __ j(ZERO, fail);
        __ LoadClassId(value_cid_reg, value_reg);
        __ cmpl(value_cid_reg, Immediate(field_cid));
      }

      if (field().is_nullable() && (field_cid != kNullCid)) {
        __ j(EQUAL, &ok);
        if (field_cid != kSmiCid) {
          __ cmpl(value_cid_reg, Immediate(kNullCid));
        } else {
          const Immediate& raw_null =
              Immediate(reinterpret_cast<intptr_t>(Object::null()));
          __ cmpl(value_reg, raw_null);
        }
      }
      __ j(NOT_EQUAL, fail);
    } else {
      // Both value's and field's class id is known.
      ASSERT((value_cid != field_cid) && (value_cid != nullability));
      __ jmp(fail);
    }
  }
  __ Bind(&ok);
}

LocationSummary* GuardFieldLengthInstr::MakeLocationSummary(Zone* zone,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  if (!opt || (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const intptr_t kNumTemps = 3;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    // We need temporaries for field object, length offset and expected length.
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
    summary->set_temp(2, Location::RequiresRegister());
    return summary;
  } else {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, 0, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
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
    const Register offset_reg = locs()->temp(1).reg();
    const Register length_reg = locs()->temp(2).reg();

    Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().Original()));

    __ movsxb(
        offset_reg,
        FieldAddress(field_reg,
                     Field::guarded_list_length_in_object_offset_offset()));
    __ movl(length_reg,
            FieldAddress(field_reg, Field::guarded_list_length_offset()));

    __ cmpl(offset_reg, Immediate(0));
    __ j(NEGATIVE, &ok);

    // Load the length from the value. GuardFieldClass already verified that
    // value's class matches guarded class id of the field.
    // offset_reg contains offset already corrected by -kHeapObjectTag that is
    // why we use Address instead of FieldAddress.
    __ cmpl(length_reg, Address(value_reg, offset_reg, TIMES_1, 0));

    if (deopt == NULL) {
      __ j(EQUAL, &ok);

      __ pushl(field_reg);
      __ pushl(value_reg);
      __ CallRuntime(kUpdateFieldCidRuntimeEntry, 2);
      __ Drop(2);  // Drop the field and the value.
    } else {
      __ j(NOT_EQUAL, deopt);
    }

    __ Bind(&ok);
  } else {
    ASSERT(compiler->is_optimizing());
    ASSERT(field().guarded_list_length() >= 0);
    ASSERT(field().guarded_list_length_in_object_offset() !=
           Field::kUnknownLengthOffset);

    __ cmpl(
        FieldAddress(value_reg, field().guarded_list_length_in_object_offset()),
        Immediate(Smi::RawValue(field().guarded_list_length())));
    __ j(NOT_EQUAL, deopt);
  }
}

class BoxAllocationSlowPath : public TemplateSlowPathCode<Instruction> {
 public:
  BoxAllocationSlowPath(Instruction* instruction,
                        const Class& cls,
                        Register result)
      : TemplateSlowPathCode(instruction), cls_(cls), result_(result) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s", instruction()->DebugName(),
                 String::Handle(cls_.ScrubbedName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::GetAllocationStubForClass(cls_));
    const StubEntry stub_entry(stub);

    LocationSummary* locs = instruction()->locs();

    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(TokenPosition::kNoSource, stub_entry,
                           RawPcDescriptors::kOther, locs);
    compiler->AddStubCallTarget(stub);
    __ MoveRegister(result_, EAX);
    compiler->RestoreLiveRegisters(locs);
    __ jmp(exit_label());
  }

  static void Allocate(FlowGraphCompiler* compiler,
                       Instruction* instruction,
                       const Class& cls,
                       Register result,
                       Register temp) {
    if (compiler->intrinsic_mode()) {
      __ TryAllocate(cls, compiler->intrinsic_slow_path_label(),
                     Assembler::kFarJump, result, temp);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls, slow_path->entry_label(), Assembler::kFarJump, result,
                     temp);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
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
                             : Location::FpuRegisterLocation(XMM1));
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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ movl(box_reg, FieldAddress(instance_reg, offset));
  __ cmpl(box_reg, raw_null);
  __ j(NOT_EQUAL, &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ movl(temp, box_reg);
  __ StoreIntoObject(instance_reg, FieldAddress(instance_reg, offset), temp);

  __ Bind(&done);
}

void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);
  Label skip_store;

  Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    XmmRegister value = locs()->in(1).fpu_reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    const intptr_t cid = field().UnboxedFieldCid();

    if (is_initialization()) {
      const Class* cls = NULL;
      switch (cid) {
        case kDoubleCid:
          cls = &compiler->double_class();
          break;
        case kFloat32x4Cid:
          cls = &compiler->float32x4_class();
          break;
        case kFloat64x2Cid:
          cls = &compiler->float64x2_class();
          break;
        default:
          UNREACHABLE();
      }

      BoxAllocationSlowPath::Allocate(compiler, this, *cls, temp, temp2);
      __ movl(temp2, temp);
      __ StoreIntoObject(instance_reg,
                         FieldAddress(instance_reg, offset_in_bytes_), temp2);
    } else {
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes_));
    }
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleStoreInstanceFieldInstr");
        __ movsd(FieldAddress(temp, Double::value_offset()), value);
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4StoreInstanceFieldInstr");
        __ movups(FieldAddress(temp, Float32x4::value_offset()), value);
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2StoreInstanceFieldInstr");
        __ movups(FieldAddress(temp, Float64x2::value_offset()), value);
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  if (IsPotentialUnboxedStore()) {
    __ Comment("PotentialUnboxedStore");
    Register value_reg = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    FpuRegister fpu_temp = locs()->temp(2).fpu_reg();

    if (ShouldEmitStoreBarrier()) {
      // Value input is a writable register and should be manually preserved
      // across allocation slow-path.  Add it to live_registers set which
      // determines which registers to preserve.
      locs()->live_registers()->Add(locs()->in(1), kTagged);
    }

    Label store_pointer;
    Label store_double;
    Label store_float32x4;
    Label store_float64x2;

    __ LoadObject(temp, Field::ZoneHandle(Z, field().Original()));

    __ cmpw(FieldAddress(temp, Field::is_nullable_offset()),
            Immediate(kNullCid));
    __ j(EQUAL, &store_pointer);

    __ movzxb(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ testl(temp2, Immediate(1 << Field::kUnboxingCandidateBit));
    __ j(ZERO, &store_pointer);

    __ cmpw(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kDoubleCid));
    __ j(EQUAL, &store_double);

    __ cmpw(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kFloat32x4Cid));
    __ j(EQUAL, &store_float32x4);

    __ cmpw(FieldAddress(temp, Field::guarded_cid_offset()),
            Immediate(kFloat64x2Cid));
    __ j(EQUAL, &store_float64x2);

    // Fall through.
    __ jmp(&store_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
      locs()->live_registers()->Add(locs()->in(1));
    }

    {
      __ Bind(&store_double);
      EnsureMutableBox(compiler, this, temp, compiler->double_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ movsd(fpu_temp, FieldAddress(value_reg, Double::value_offset()));
      __ movsd(FieldAddress(temp, Double::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    {
      __ Bind(&store_float32x4);
      EnsureMutableBox(compiler, this, temp, compiler->float32x4_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ movups(fpu_temp, FieldAddress(value_reg, Float32x4::value_offset()));
      __ movups(FieldAddress(temp, Float32x4::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    {
      __ Bind(&store_float64x2);
      EnsureMutableBox(compiler, this, temp, compiler->float64x2_class(),
                       instance_reg, offset_in_bytes_, temp2);
      __ movups(fpu_temp, FieldAddress(value_reg, Float64x2::value_offset()));
      __ movups(FieldAddress(temp, Float64x2::value_offset()), fpu_temp);
      __ jmp(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObject(instance_reg,
                       FieldAddress(instance_reg, offset_in_bytes_), value_reg,
                       CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrier(instance_reg,
                                  FieldAddress(instance_reg, offset_in_bytes_),
                                  locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrier(instance_reg,
                                  FieldAddress(instance_reg, offset_in_bytes_),
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
  // By specifying same register as input, our simple register allocator can
  // generate better code.
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

// When the parser is building an implicit static getter for optimization,
// it can generate a function body where deoptimization ids do not line up
// with the unoptimized code.
//
// This is safe only so long as LoadStaticFieldInstr cannot deoptimize.
void LoadStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ movl(result, FieldAddress(field, Field::static_value_offset()));
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
  summary->set_in(0, Location::RegisterLocation(EAX));  // Instance.
  summary->set_in(1, Location::RegisterLocation(EDX));  // Instant. type args.
  summary->set_in(2, Location::RegisterLocation(ECX));  // Function type args.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == EAX);  // Value.
  ASSERT(locs()->in(1).reg() == EDX);  // Instantiator type arguments.
  ASSERT(locs()->in(2).reg() == ECX);  // Function type arguments.

  compiler->GenerateInstanceOf(token_pos(), deopt_id(), type(), locs());
  ASSERT(locs()->out(0).reg() == EAX);
}

// TODO(srdjan): In case of constant inputs make CreateArray kNoCall and
// use slow path stub.
LocationSummary* CreateArrayInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(ECX));
  locs->set_in(1, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

// Inlines array allocation for known constant values.
static void InlineArrayAllocation(FlowGraphCompiler* compiler,
                                  intptr_t num_elements,
                                  Label* slow_path,
                                  Label* done) {
  const int kInlineArraySize = 12;  // Same as kInlineInstanceSize.
  const Register kLengthReg = EDX;
  const Register kElemTypeReg = ECX;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  // Instance in EAX.
  // Object end address in EBX.
  __ TryAllocateArray(kArrayCid, instance_size, slow_path, Assembler::kFarJump,
                      EAX,   // instance
                      EBX,   // end address
                      EDI);  // temp

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(
      EAX, FieldAddress(EAX, Array::type_arguments_offset()), kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(EAX, FieldAddress(EAX, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // EAX: new object start as a tagged pointer.
  // EBX: new object end address.
  // EDI: iterator which initially points to the start of the variable
  // data area to be initialized.
  if (num_elements > 0) {
    const intptr_t array_size = instance_size - sizeof(RawArray);
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ leal(EDI, FieldAddress(EAX, sizeof(RawArray)));
    if (array_size < (kInlineArraySize * kWordSize)) {
      intptr_t current_offset = 0;
      __ movl(EBX, raw_null);
      while (current_offset < array_size) {
        __ StoreIntoObjectNoBarrier(EAX, Address(EDI, current_offset), EBX);
        current_offset += kWordSize;
      }
    } else {
      Label init_loop;
      __ Bind(&init_loop);
      __ StoreIntoObjectNoBarrier(EAX, Address(EDI, 0), Object::null_object());
      __ addl(EDI, Immediate(kWordSize));
      __ cmpl(EDI, EBX);
      __ j(BELOW, &init_loop, Assembler::kNearJump);
    }
  }
  __ jmp(done, Assembler::kNearJump);
}

void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Allocate the array.  EDX = length, ECX = element type.
  const Register kLengthReg = EDX;
  const Register kElemTypeReg = ECX;
  const Register kResultReg = EAX;
  ASSERT(locs()->in(0).reg() == kElemTypeReg);
  ASSERT(locs()->in(1).reg() == kLengthReg);

  Label slow_path, done;
  if (compiler->is_optimizing() && num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object());  // Make room for the result.
      __ pushl(kLengthReg);
      __ pushl(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                    kAllocateArrayRuntimeEntry, 2, locs());
      __ Drop(2);
      __ popl(kResultReg);
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
      zone, kNumInputs, kNumTemps,
      (opt && !IsPotentialUnboxedLoad()) ? LocationSummary::kNoCall
                                         : LocationSummary::kCallOnSlowPath);

  locs->set_in(0, Location::RequiresRegister());

  if (IsUnboxedLoad() && opt) {
    locs->set_temp(0, Location::RequiresRegister());
  } else if (IsPotentialUnboxedLoad()) {
    locs->set_temp(0, opt ? Location::RequiresFpuRegister()
                          : Location::FpuRegisterLocation(XMM1));
    locs->set_temp(1, Location::RequiresRegister());
  }
  locs->set_out(0, Location::RequiresRegister());
  return locs;
}

void LoadFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(sizeof(classid_t) == kInt16Size);

  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    XmmRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
    const intptr_t cid = field()->UnboxedFieldCid();
    switch (cid) {
      case kDoubleCid:
        __ Comment("UnboxedDoubleLoadFieldInstr");
        __ movsd(result, FieldAddress(temp, Double::value_offset()));
        break;
      case kFloat32x4Cid:
        __ Comment("UnboxedFloat32x4LoadFieldInstr");
        __ movups(result, FieldAddress(temp, Float32x4::value_offset()));
        break;
      case kFloat64x2Cid:
        __ Comment("UnboxedFloat64x2LoadFieldInstr");
        __ movups(result, FieldAddress(temp, Float64x2::value_offset()));
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  Label done;
  Register result = locs()->out(0).reg();
  if (IsPotentialUnboxedLoad()) {
    Register temp = locs()->temp(1).reg();
    XmmRegister value = locs()->temp(0).fpu_reg();

    Label load_pointer;
    Label load_double;
    Label load_float32x4;
    Label load_float64x2;

    __ LoadObject(result, Field::ZoneHandle(field()->Original()));

    FieldAddress field_cid_operand(result, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result, Field::is_nullable_offset());

    __ cmpw(field_nullability_operand, Immediate(kNullCid));
    __ j(EQUAL, &load_pointer);

    __ cmpw(field_cid_operand, Immediate(kDoubleCid));
    __ j(EQUAL, &load_double);

    __ cmpw(field_cid_operand, Immediate(kFloat32x4Cid));
    __ j(EQUAL, &load_float32x4);

    __ cmpw(field_cid_operand, Immediate(kFloat64x2Cid));
    __ j(EQUAL, &load_float64x2);

    // Fall through.
    __ jmp(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->double_class(),
                                      result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movsd(value, FieldAddress(temp, Double::value_offset()));
      __ movsd(FieldAddress(result, Double::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float32x4);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float32x4_class(), result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float32x4::value_offset()));
      __ movups(FieldAddress(result, Float32x4::value_offset()), value);
      __ jmp(&done);
    }

    {
      __ Bind(&load_float64x2);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->float64x2_class(), result, temp);
      __ movl(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ movups(value, FieldAddress(temp, Float64x2::value_offset()));
      __ movups(FieldAddress(result, Float64x2::value_offset()), value);
      __ jmp(&done);
    }

    __ Bind(&load_pointer);
  }
  __ movl(result, FieldAddress(instance_reg, offset_in_bytes()));
  __ Bind(&done);
}

LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(EDX));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register instantiator_type_args_reg = locs()->in(0).reg();
  Register function_type_args_reg = locs()->in(1).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_type_args_reg' is a TypeArguments object (or null).
  // 'function_type_args_reg' is a TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type());
  __ pushl(instantiator_type_args_reg);  // Push instantiator type arguments.
  __ pushl(function_type_args_reg);      // Push function type arguments.
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeRuntimeEntry, 3, locs());
  __ Drop(3);           // Drop 2 type argument vectors and uninstantiated type.
  __ popl(result_reg);  // Pop instantiated type.
  ASSERT(instantiator_type_args_reg == result_reg);
}

LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));  // Instant. type args.
  locs->set_in(1, Location::RegisterLocation(ECX));  // Function type args.
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  Register instantiator_type_args_reg = locs()->in(0).reg();
  Register function_type_args_reg = locs()->in(1).reg();
  Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_type_args_reg == EAX);
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
    const Immediate& raw_null =
        Immediate(reinterpret_cast<intptr_t>(Object::null()));
    __ cmpl(instantiator_type_args_reg, raw_null);
    __ j(NOT_EQUAL, &non_null_type_args, Assembler::kNearJump);
    __ cmpl(function_type_args_reg, raw_null);
    __ j(EQUAL, &type_arguments_instantiated, Assembler::kNearJump);
    __ Bind(&non_null_type_args);
  }
  // Lookup cache before calling runtime.
  // TODO(regis): Consider moving this into a shared stub to reduce
  // generated code size.
  __ LoadObject(EDI, type_arguments());
  __ movl(EDI, FieldAddress(EDI, TypeArguments::instantiations_offset()));
  __ leal(EDI, FieldAddress(EDI, Array::data_offset()));
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, next, found, slow_case;
  __ Bind(&loop);
  __ movl(EDX, Address(EDI, 0 * kWordSize));  // Cached instantiator type args.
  __ cmpl(EDX, instantiator_type_args_reg);
  __ j(NOT_EQUAL, &next, Assembler::kNearJump);
  __ movl(EBX, Address(EDI, 1 * kWordSize));  // Cached function type args.
  __ cmpl(EBX, function_type_args_reg);
  __ j(EQUAL, &found, Assembler::kNearJump);
  __ Bind(&next);
  __ addl(EDI, Immediate(StubCode::kInstantiationSizeInWords * kWordSize));
  __ cmpl(EDX, Immediate(Smi::RawValue(StubCode::kNoInstantiator)));
  __ j(NOT_EQUAL, &loop, Assembler::kNearJump);
  __ jmp(&slow_case, Assembler::kNearJump);
  __ Bind(&found);
  __ movl(result_reg, Address(EDI, 2 * kWordSize));  // Cached instantiated ta.
  __ jmp(&type_arguments_instantiated, Assembler::kNearJump);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ PushObject(Object::null_object());  // Make room for the result.
  __ PushObject(type_arguments());
  __ pushl(instantiator_type_args_reg);  // Push instantiator type arguments.
  __ pushl(function_type_args_reg);      // Push function type arguments.
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry, 3,
                                locs());
  __ Drop(3);           // Drop 2 type argument vectors and uninstantiated args.
  __ popl(result_reg);  // Pop instantiated type arguments.
  __ Bind(&type_arguments_instantiated);
}

LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 2;
  LocationSummary* locs = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  locs->set_temp(0, Location::RegisterLocation(ECX));
  locs->set_temp(1, Location::RegisterLocation(EDI));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

class AllocateContextSlowPath
    : public TemplateSlowPathCode<AllocateUninitializedContextInstr> {
 public:
  explicit AllocateContextSlowPath(
      AllocateUninitializedContextInstr* instruction)
      : TemplateSlowPathCode(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction()->locs();
    ASSERT(!locs->live_registers()->Contains(locs->out(0)));

    compiler->SaveLiveRegisters(locs);

    __ movl(EDX, Immediate(instruction()->num_context_variables()));
    const Code& stub = Code::ZoneHandle(
        compiler->zone(), StubCode::AllocateContext_entry()->code());
    compiler->AddStubCallTarget(stub);
    compiler->GenerateCall(instruction()->token_pos(),
                           *StubCode::AllocateContext_entry(),
                           RawPcDescriptors::kOther, locs);
    ASSERT(instruction()->locs()->out(0).reg() == EAX);
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ jmp(exit_label());
  }
};

void AllocateUninitializedContextInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  ASSERT(compiler->is_optimizing());
  Register temp = locs()->temp(0).reg();
  Register temp2 = locs()->temp(1).reg();
  Register result = locs()->out(0).reg();
  // Try allocate the object.
  AllocateContextSlowPath* slow_path = new AllocateContextSlowPath(this);
  compiler->AddSlowPathCode(slow_path);
  intptr_t instance_size = Context::InstanceSize(num_context_variables());

  __ TryAllocateArray(kContextCid, instance_size, slow_path->entry_label(),
                      Assembler::kFarJump,
                      result,  // instance
                      temp,    // end address
                      temp2);  // temp

  // Setup up number of context variables field.
  __ movl(FieldAddress(result, Context::num_variables_offset()),
          Immediate(num_context_variables()));

  __ Bind(slow_path->exit_label());
}

LocationSummary* AllocateContextInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(EDX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == EDX);
  ASSERT(locs()->out(0).reg() == EAX);

  __ movl(EDX, Immediate(num_context_variables()));
  compiler->GenerateCall(token_pos(), *StubCode::AllocateContext_entry(),
                         RawPcDescriptors::kOther, locs());
}

LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_temp(0, Location::RegisterLocation(ECX));
  return locs;
}

void InitStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  Label call_runtime, no_call;

  __ movl(temp, FieldAddress(field, Field::static_value_offset()));
  __ CompareObject(temp, Object::sentinel());
  __ j(EQUAL, &call_runtime);

  __ CompareObject(temp, Object::transition_sentinel());
  __ j(NOT_EQUAL, &no_call);

  __ Bind(&call_runtime);
  __ PushObject(Object::null_object());  // Make room for (unused) result.
  __ pushl(field);
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kInitStaticFieldRuntimeEntry, 1, locs());
  __ Drop(2);  // Remove argument and unused result.
  __ Bind(&no_call);
}

LocationSummary* CloneContextInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(EAX));
  locs->set_out(0, Location::RegisterLocation(EAX));
  return locs;
}

void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ PushObject(Object::null_object());  // Make room for the result.
  __ pushl(context_value);
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(),
                                kCloneContextRuntimeEntry, 1, locs());
  __ popl(result);  // Remove argument.
  __ popl(result);  // Get result (cloned context).
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

  // Restore ESP from EBP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ leal(ESP, Address(EBP, fp_sp_dist));

  // Auxiliary variables introduced by the try catch can be captured if we are
  // inside a function with yield/resume points. In this case we first need
  // to restore the context to match the context at entry into the closure.
  if (should_restore_closure_context()) {
    const ParsedFunction& parsed_function = compiler->parsed_function();
    ASSERT(parsed_function.function().IsClosureFunction());
    LocalScope* scope = parsed_function.node_sequence()->scope();

    LocalVariable* closure_parameter = scope->VariableAt(0);
    ASSERT(!closure_parameter->is_captured());
    __ movl(EDI, Address(EBP, closure_parameter->index() * kWordSize));
    __ movl(EDI, FieldAddress(EDI, Closure::context_offset()));

#ifdef DEBUG
    Label ok;
    __ LoadClassId(EBX, EDI);
    __ cmpl(EBX, Immediate(kContextCid));
    __ j(EQUAL, &ok, Assembler::kNearJump);
    __ Stop("Incorrect context at entry");
    __ Bind(&ok);
#endif

    const intptr_t context_index =
        parsed_function.current_context_var()->index();
    __ movl(Address(EBP, context_index * kWordSize), EDI);
  }

  // Initialize exception and stack trace variables.
  if (exception_var().is_captured()) {
    ASSERT(stacktrace_var().is_captured());
    __ StoreIntoObject(
        EDI,
        FieldAddress(EDI, Context::variable_offset(exception_var().index())),
        kExceptionObjectReg);
    __ StoreIntoObject(
        EDI,
        FieldAddress(EDI, Context::variable_offset(stacktrace_var().index())),
        kStackTraceObjectReg);
  } else {
    // Restore stack and initialize the two exception variables:
    // exception and stack trace variables.
    __ movl(Address(EBP, exception_var().index() * kWordSize),
            kExceptionObjectReg);
    __ movl(Address(EBP, stacktrace_var().index() * kWordSize),
            kStackTraceObjectReg);
  }
}

LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Zone* zone,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = opt ? 0 : 1;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
  if (!opt) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  return summary;
}

class CheckStackOverflowSlowPath
    : public TemplateSlowPathCode<CheckStackOverflowInstr> {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : TemplateSlowPathCode(instruction) {}

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (compiler->isolate()->use_osr() && osr_entry_label()->IsLinked()) {
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ movl(Address(THR, Thread::stack_overflow_flags_offset()),
              Immediate(Thread::kOsrRequest));
    }
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction()->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction());
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(
        instruction()->token_pos(), instruction()->deopt_id(),
        kStackOverflowRuntimeEntry, 0, instruction()->locs());

    if (compiler->isolate()->use_osr() && !compiler->is_optimizing() &&
        instruction()->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOsrEntry,
                                     instruction()->deopt_id(),
                                     TokenPosition::kNoSource);
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction()->locs());
    __ jmp(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(Isolate::Current()->use_osr());
    return &osr_entry_label_;
  }

 private:
  Label osr_entry_label_;
};

void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ cmpl(ESP, Address(THR, Thread::stack_limit_offset()));
  __ j(BELOW_EQUAL, slow_path->entry_label());
  if (compiler->CanOSRFunction() && in_loop()) {
    // In unoptimized code check the usage counter to trigger OSR at loop
    // stack checks.  Use progressively higher thresholds for more deeply
    // nested loops to attempt to hit outer loops with OSR when possible.
    __ LoadObject(EDI, compiler->parsed_function().function());
    intptr_t threshold =
        FLAG_optimization_counter_threshold * (loop_depth() + 1);
    __ cmpl(FieldAddress(EDI, Function::usage_counter_offset()),
            Immediate(threshold));
    __ j(GREATER_EQUAL, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    // TODO(turnidge): Implement stack overflow count in assembly to
    // make --stacktrace-every and --deoptimize-every faster.
    __ jmp(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}

static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  ASSERT(left == result);
  Label* deopt = shift_left->CanDeoptimize()
                     ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                              ICData::kDeoptBinarySmiOp)
                     : NULL;
  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // shll operation masks the count to 5 bits.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    ASSERT((0 < value) && (value < kCountLimit));
    if (shift_left->can_overflow()) {
      if (value == 1) {
        // Use overflow flag.
        __ shll(left, Immediate(1));
        __ j(OVERFLOW, deopt);
        return;
      }
      // Check for overflow.
      Register temp = locs.temp(0).reg();
      __ movl(temp, left);
      __ shll(left, Immediate(value));
      __ sarl(left, Immediate(value));
      __ cmpl(left, temp);
      __ j(NOT_EQUAL, deopt);  // Overflow.
    }
    // Shift for result now we know there is no overflow.
    __ shll(left, Immediate(value));
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right_range();
  if (shift_left->left()->BindsToConstant() && shift_left->can_overflow()) {
    // TODO(srdjan): Implement code below for can_overflow().
    // If left is constant, we know the maximal allowed size for right.
    const Object& obj = shift_left->left()->BoundConstant();
    if (obj.IsSmi()) {
      const intptr_t left_int = Smi::Cast(obj).Value();
      if (left_int == 0) {
        __ cmpl(right, Immediate(0));
        __ j(NEGATIVE, deopt);
        return;
      }
      const intptr_t max_right = kSmiBits - Utils::HighestBit(left_int);
      const bool right_needs_check =
          !RangeUtils::IsWithin(right_range, 0, max_right - 1);
      if (right_needs_check) {
        __ cmpl(right,
                Immediate(reinterpret_cast<int32_t>(Smi::New(max_right))));
        __ j(ABOVE_EQUAL, deopt);
      }
      __ SmiUntag(right);
      __ shll(left, right);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  ASSERT(right == ECX);  // Count must be in ECX
  if (!shift_left->can_overflow()) {
    if (right_needs_check) {
      if (!RangeUtils::IsPositive(right_range)) {
        ASSERT(shift_left->CanDeoptimize());
        __ cmpl(right, Immediate(0));
        __ j(NEGATIVE, deopt);
      }
      Label done, is_not_zero;
      __ cmpl(right,
              Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ j(BELOW, &is_not_zero, Assembler::kNearJump);
      __ xorl(left, left);
      __ jmp(&done, Assembler::kNearJump);
      __ Bind(&is_not_zero);
      __ SmiUntag(right);
      __ shll(left, right);
      __ Bind(&done);
    } else {
      __ SmiUntag(right);
      __ shll(left, right);
    }
  } else {
    if (right_needs_check) {
      ASSERT(shift_left->CanDeoptimize());
      __ cmpl(right,
              Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
      __ j(ABOVE_EQUAL, deopt);
    }
    // Left is not a constant.
    Register temp = locs.temp(0).reg();
    // Check if count too large for handling it inlined.
    __ movl(temp, left);
    __ SmiUntag(right);
    // Overflow test (preserve temp and right);
    __ shll(left, right);
    __ sarl(left, right);
    __ cmpl(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
    // Shift for result now we know there is no overflow.
    __ shll(left, right);
  }
}

LocationSummary* CheckedSmiOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
  return NULL;
}

void CheckedSmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
}

LocationSummary* CheckedSmiComparisonInstr::MakeLocationSummary(
    Zone* zone,
    bool opt) const {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
  return NULL;
}

Condition CheckedSmiComparisonInstr::EmitComparisonCode(
    FlowGraphCompiler* compiler,
    BranchLabels labels) {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
  return ZERO;
}

void CheckedSmiComparisonInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                               BranchInstr* instr) {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
}

void CheckedSmiComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Only for precompiled code, not on ia32 currently.
  UNIMPLEMENTED();
}

static bool IsSmiValue(const Object& constant, intptr_t value) {
  return constant.IsSmi() && (Smi::Cast(constant).Value() == value);
}

LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    if (RightIsPowerOfTwoConstant()) {
      summary->set_in(0, Location::RequiresRegister());
      ConstantInstr* right_constant = right()->definition()->AsConstant();
      // The programmer only controls one bit, so the constant is safe.
      summary->set_in(1, Location::Constant(right_constant));
      summary->set_temp(0, Location::RequiresRegister());
      summary->set_out(0, Location::SameAsFirstInput());
    } else {
      // Both inputs must be writable because they will be untagged.
      summary->set_in(0, Location::RegisterLocation(EAX));
      summary->set_in(1, Location::WritableRegister());
      summary->set_out(0, Location::SameAsFirstInput());
      // Will be used for sign extension and division.
      summary->set_temp(0, Location::RegisterLocation(EDX));
    }
    return summary;
  } else if (op_kind() == Token::kMOD) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Both inputs must be writable because they will be untagged.
    summary->set_in(0, Location::RegisterLocation(EDX));
    summary->set_in(1, Location::WritableRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    // Will be used for sign extension and division.
    summary->set_temp(0, Location::RegisterLocation(EAX));
    return summary;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    ConstantInstr* right_constant = right()->definition()->AsConstant();
    // Shift-by-1 overflow checking can use flags, otherwise we need a temp.
    const bool shiftBy1 =
        (right_constant != NULL) && IsSmiValue(right_constant->value(), 1);
    const intptr_t kNumTemps = (can_overflow() && !shiftBy1) ? 1 : 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    if (kNumTemps == 1) {
      summary->set_temp(0, Location::RequiresRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    ConstantInstr* constant = right()->definition()->AsConstant();
    if (constant != NULL) {
      summary->set_in(1, Location::RegisterOrSmiConstant(right()));
    } else {
      summary->set_in(1, Location::PrefersRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }
}

template <typename OperandType>
static void EmitIntegerArithmetic(FlowGraphCompiler* compiler,
                                  Token::Kind op_kind,
                                  Register left,
                                  const OperandType& right,
                                  Label* deopt) {
  switch (op_kind) {
    case Token::kADD:
      __ addl(left, right);
      break;
    case Token::kSUB:
      __ subl(left, right);
      break;
    case Token::kBIT_AND:
      __ andl(left, right);
      break;
    case Token::kBIT_OR:
      __ orl(left, right);
      break;
    case Token::kBIT_XOR:
      __ xorl(left, right);
      break;
    case Token::kMUL:
      __ imull(left, right);
      break;
    default:
      UNREACHABLE();
  }
  if (deopt != NULL) __ j(OVERFLOW, deopt);
}

void BinarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitSmiShiftLeft(compiler, this);
    return;
  }

  Register left = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(left == result);
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t value = Smi::Cast(constant).Value();
    switch (op_kind()) {
      case Token::kADD:
      case Token::kSUB:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
      case Token::kMUL: {
        const intptr_t imm =
            (op_kind() == Token::kMUL) ? value : Smi::RawValue(value);
        EmitIntegerArithmetic(compiler, op_kind(), left, Immediate(imm), deopt);
        break;
      }

      case Token::kTRUNCDIV: {
        ASSERT(value != kIntptrMin);
        ASSERT(Utils::IsPowerOfTwo(Utils::Abs(value)));
        const intptr_t shift_count =
            Utils::ShiftForPowerOfTwo(Utils::Abs(value)) + kSmiTagSize;
        ASSERT(kSmiTagSize == 1);
        Register temp = locs()->temp(0).reg();
        __ movl(temp, left);
        __ sarl(temp, Immediate(31));
        ASSERT(shift_count > 1);  // 1, -1 case handled above.
        __ shrl(temp, Immediate(32 - shift_count));
        __ addl(left, temp);
        ASSERT(shift_count > 0);
        __ sarl(left, Immediate(shift_count));
        if (value < 0) {
          __ negl(left);
        }
        __ SmiTag(left);
        break;
      }

      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ sarl(left,
                Immediate(Utils::Minimum(value + kSmiTagSize, kCountLimit)));
        __ SmiTag(left);
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // if locs()->in(1).IsConstant()

  if (locs()->in(1).IsStackSlot()) {
    const Address& right = locs()->in(1).ToStackSlotAddress();
    if (op_kind() == Token::kMUL) {
      __ SmiUntag(left);
    }
    EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
    return;
  }

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kMUL:
      if (op_kind() == Token::kMUL) {
        __ SmiUntag(left);
      }
      EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
      break;

    case Token::kTRUNCDIV: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testl(right, right);
        __ j(ZERO, deopt);
      }
      ASSERT(left == EAX);
      ASSERT((right != EDX) && (right != EAX));
      ASSERT(locs()->temp(0).reg() == EDX);
      ASSERT(result == EAX);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ cdq();         // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      // Check the corner case of dividing the 'MIN_SMI' with -1, in which
      // case we cannot tag the result.
      __ cmpl(result, Immediate(0x40000000));
      __ j(EQUAL, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if (RangeUtils::CanBeZero(right_range())) {
        // Handle divide by zero in runtime.
        __ testl(right, right);
        __ j(ZERO, deopt);
      }
      ASSERT(left == EDX);
      ASSERT((right != EDX) && (right != EAX));
      ASSERT(locs()->temp(0).reg() == EAX);
      ASSERT(result == EDX);
      __ SmiUntag(left);
      __ SmiUntag(right);
      __ movl(EAX, EDX);
      __ cdq();         // Sign extend EAX -> EDX:EAX.
      __ idivl(right);  //  EAX: quotient, EDX: remainder.
      //  res = left % right;
      //  if (res < 0) {
      //    if (right < 0) {
      //      res = res - right;
      //    } else {
      //      res = res + right;
      //    }
      //  }
      Label done;
      __ cmpl(result, Immediate(0));
      __ j(GREATER_EQUAL, &done, Assembler::kNearJump);
      // Result is negative, adjust it.
      if (RangeUtils::Overlaps(right_range(), -1, 1)) {
        // Right can be positive and negative.
        Label subtract;
        __ cmpl(right, Immediate(0));
        __ j(LESS, &subtract, Assembler::kNearJump);
        __ addl(result, right);
        __ jmp(&done, Assembler::kNearJump);
        __ Bind(&subtract);
        __ subl(result, right);
      } else if (right_range()->IsPositive()) {
        // Right is positive.
        __ addl(result, right);
      } else {
        // Right is negative.
        __ subl(result, right);
      }
      __ Bind(&done);
      __ SmiTag(result);
      break;
    }
    case Token::kSHR: {
      if (CanDeoptimize()) {
        __ cmpl(right, Immediate(0));
        __ j(LESS, deopt);
      }
      __ SmiUntag(right);
      // sarl operation masks the count to 5 bits.
      const intptr_t kCountLimit = 0x1F;
      if (!RangeUtils::OnlyLessThanOrEqualTo(right_range(), kCountLimit)) {
        __ cmpl(right, Immediate(kCountLimit));
        Label count_ok;
        __ j(LESS, &count_ok, Assembler::kNearJump);
        __ movl(right, Immediate(kCountLimit));
        __ Bind(&count_ok);
      }
      ASSERT(right == ECX);  // Count must be in ECX
      __ SmiUntag(left);
      __ sarl(left, right);
      __ SmiTag(left);
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

LocationSummary* BinaryInt32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  if (op_kind() == Token::kTRUNCDIV) {
    UNREACHABLE();
    return NULL;
  } else if (op_kind() == Token::kMOD) {
    UNREACHABLE();
    return NULL;
  } else if (op_kind() == Token::kSHR) {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else if (op_kind() == Token::kSHL) {
    const intptr_t kNumTemps = can_overflow() ? 1 : 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
    if (can_overflow()) {
      summary->set_temp(0, Location::RequiresRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    ConstantInstr* constant = right()->definition()->AsConstant();
    if (constant != NULL) {
      summary->set_in(1, Location::RegisterOrSmiConstant(right()));
    } else {
      summary->set_in(1, Location::PrefersRegister());
    }
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  }
}

static void EmitInt32ShiftLeft(FlowGraphCompiler* compiler,
                               BinaryInt32OpInstr* shift_left) {
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  ASSERT(left == result);
  Label* deopt = shift_left->CanDeoptimize()
                     ? compiler->AddDeoptStub(shift_left->deopt_id(),
                                              ICData::kDeoptBinarySmiOp)
                     : NULL;
  ASSERT(locs.in(1).IsConstant());

  const Object& constant = locs.in(1).constant();
  ASSERT(constant.IsSmi());
  // shll operation masks the count to 5 bits.
  const intptr_t kCountLimit = 0x1F;
  const intptr_t value = Smi::Cast(constant).Value();
  ASSERT((0 < value) && (value < kCountLimit));
  if (shift_left->can_overflow()) {
    // Check for overflow.
    Register temp = locs.temp(0).reg();
    __ movl(temp, left);
    __ shll(left, Immediate(value));
    __ sarl(left, Immediate(value));
    __ cmpl(left, temp);
    __ j(NOT_EQUAL, deopt);  // Overflow.
  }
  // Shift for result now we know there is no overflow.
  __ shll(left, Immediate(value));
}

void BinaryInt32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (op_kind() == Token::kSHL) {
    EmitInt32ShiftLeft(compiler, this);
    return;
  }

  Register left = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(left == result);
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }

  if (locs()->in(1).IsConstant()) {
    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t value = Smi::Cast(constant).Value();
    switch (op_kind()) {
      case Token::kADD:
      case Token::kSUB:
      case Token::kMUL:
      case Token::kBIT_AND:
      case Token::kBIT_OR:
      case Token::kBIT_XOR:
        EmitIntegerArithmetic(compiler, op_kind(), left, Immediate(value),
                              deopt);
        break;

      case Token::kTRUNCDIV: {
        UNREACHABLE();
        break;
      }

      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        __ sarl(left, Immediate(Utils::Minimum(value, kCountLimit)));
        break;
      }

      default:
        UNREACHABLE();
        break;
    }
    return;
  }  // if locs()->in(1).IsConstant()

  if (locs()->in(1).IsStackSlot()) {
    const Address& right = locs()->in(1).ToStackSlotAddress();
    EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
    return;
  }  // if locs()->in(1).IsStackSlot.

  // if locs()->in(1).IsRegister.
  Register right = locs()->in(1).reg();
  switch (op_kind()) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      EmitIntegerArithmetic(compiler, op_kind(), left, right, deopt);
      break;

    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* BinaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (op_kind() == Token::kMUL) {
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_temp(0, Location::RegisterLocation(EDX));
  } else {
    summary->set_in(0, Location::RequiresRegister());
  }
  summary->set_in(1, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void BinaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register out = locs()->out(0).reg();
  ASSERT(out == left);
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kADD:
    case Token::kSUB:
      EmitIntegerArithmetic(compiler, op_kind(), left, right, NULL);
      return;

    case Token::kMUL:
      __ mull(right);  // Result in EDX:EAX.
      ASSERT(out == EAX);
      ASSERT(locs()->temp(0).reg() == EDX);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Zone* zone,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const bool need_temp = (left()->definition() != right()->definition()) &&
                         (left_cid != kSmiCid) && (right_cid != kSmiCid);
  const intptr_t kNumTemps = need_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  if (need_temp) summary->set_temp(0, Location::RequiresRegister());
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
    __ testl(left, Immediate(kSmiTagMask));
  } else if (left_cid == kSmiCid) {
    __ testl(right, Immediate(kSmiTagMask));
  } else if (right_cid == kSmiCid) {
    __ testl(left, Immediate(kSmiTagMask));
  } else {
    Register temp = locs()->temp(0).reg();
    __ movl(temp, left);
    __ orl(temp, right);
    __ testl(temp, Immediate(kSmiTagMask));
  }
  __ j(ZERO, deopt);
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
  Register out_reg = locs()->out(0).reg();
  XmmRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(compiler, this,
                                  compiler->BoxClassFor(from_representation()),
                                  out_reg, locs()->temp(0).reg());

  switch (from_representation()) {
    case kUnboxedDouble:
      __ movsd(FieldAddress(out_reg, ValueOffset()), value);
      break;
    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4:
      __ movups(FieldAddress(out_reg, ValueOffset()), value);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

LocationSummary* UnboxInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  const bool needs_temp =
      CanDeoptimize() ||
      (CanConvertSmi() && (value()->Type()->ToCid() == kSmiCid));

  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = needs_temp ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (needs_temp) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                       Location::RegisterLocation(EDX)));
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}

void UnboxInstr::EmitLoadFromBox(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();

  switch (representation()) {
    case kUnboxedInt64: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      ASSERT(result->At(0).reg() != box);
      __ movl(result->At(0).reg(), FieldAddress(box, ValueOffset()));
      __ movl(result->At(1).reg(),
              FieldAddress(box, ValueOffset() + kWordSize));
      break;
    }

    case kUnboxedDouble: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movsd(result, FieldAddress(box, ValueOffset()));
      break;
    }

    case kUnboxedFloat32x4:
    case kUnboxedFloat64x2:
    case kUnboxedInt32x4: {
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movups(result, FieldAddress(box, ValueOffset()));
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
    case kUnboxedInt64: {
      PairLocation* result = locs()->out(0).AsPairLocation();
      ASSERT(result->At(0).reg() == EAX);
      ASSERT(result->At(1).reg() == EDX);
      __ movl(EAX, box);
      __ SmiUntag(EAX);
      __ cdq();
      break;
    }

    case kUnboxedDouble: {
      const Register temp = locs()->temp(0).reg();
      const FpuRegister result = locs()->out(0).fpu_reg();
      __ movl(temp, box);
      __ SmiUntag(temp);
      __ cvtsi2sd(result, temp);
      break;
    }

    default:
      UNREACHABLE();
      break;
  }
}

void UnboxInstr::EmitLoadInt64FromBoxOrSmi(FlowGraphCompiler* compiler) {
  const Register box = locs()->in(0).reg();
  PairLocation* result = locs()->out(0).AsPairLocation();
  ASSERT(result->At(0).reg() != box);
  ASSERT(result->At(1).reg() != box);
  Label done;
  EmitSmiConversion(compiler);  // Leaves CF after SmiUntag.
  __ j(NOT_CARRY, &done, Assembler::kNearJump);
  EmitLoadFromBox(compiler);
  __ Bind(&done);
}

LocationSummary* BoxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = ValueFitsSmi() ? 0 : 1;
  if (ValueFitsSmi()) {
    LocationSummary* summary = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    // Same regs, can overwrite input.
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
    return summary;
  } else {
    LocationSummary* summary = new (zone) LocationSummary(
        zone, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
    // Guaranteed different regs.  In the signed case we are going to use the
    // input for sign extension of any Mint.
    const bool needs_writable_input = (from_representation() == kUnboxedInt32);
    summary->set_in(0, needs_writable_input ? Location::WritableRegister()
                                            : Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
}

void BoxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register value = locs()->in(0).reg();
  const Register out = locs()->out(0).reg();

  if (ValueFitsSmi()) {
    ASSERT(value == out);
    ASSERT(kSmiTag == 0);
    __ shll(out, Immediate(kSmiTagSize));
    return;
  }

  __ movl(out, value);
  __ shll(out, Immediate(kSmiTagSize));
  Label done;
  if (from_representation() == kUnboxedInt32) {
    __ j(NO_OVERFLOW, &done);
  } else {
    ASSERT(value != out);  // Value was not overwritten.
    __ testl(value, Immediate(0xC0000000));
    __ j(ZERO, &done);
  }

  // Allocate a Mint.
  if (from_representation() == kUnboxedInt32) {
    // Value input is a writable register and should be manually preserved
    // across allocation slow-path.  Add it to live_registers set which
    // determines which registers to preserve.
    locs()->live_registers()->Add(locs()->in(0), kUnboxedInt32);
  }
  ASSERT(value != out);  // We need the value after the allocation.
  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(), out,
                                  locs()->temp(0).reg());
  __ movl(FieldAddress(out, Mint::value_offset()), value);
  if (from_representation() == kUnboxedInt32) {
    // In the signed may-overflow case we asked for the input (value) to be
    // writable so we can use it as a temp to put the sign extension bits in.
    __ sarl(value, Immediate(31));  // Sign extend the Mint.
    __ movl(FieldAddress(out, Mint::value_offset() + kWordSize), value);
  } else {
    __ movl(FieldAddress(out, Mint::value_offset() + kWordSize),
            Immediate(0));  // Zero extend the Mint.
  }
  __ Bind(&done);
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
    __ movl(out_reg, value_lo);
    __ SmiTag(out_reg);
    return;
  }

  PairLocation* value_pair = locs()->in(0).AsPairLocation();
  Register value_lo = value_pair->At(0).reg();
  Register value_hi = value_pair->At(1).reg();
  Register out_reg = locs()->out(0).reg();

  // Copy value_hi into out_reg as a temporary.
  // We modify value_lo but restore it before using it.
  __ movl(out_reg, value_hi);

  // Unboxed operations produce smis or mint-sized values.
  // Check if value fits into a smi.
  Label not_smi, done;

  // 1. Compute (x + -kMinSmi) which has to be in the range
  //    0 .. -kMinSmi+kMaxSmi for x to fit into a smi.
  __ addl(value_lo, Immediate(0x40000000));
  __ adcl(out_reg, Immediate(0));
  // 2. Unsigned compare to -kMinSmi+kMaxSmi.
  __ cmpl(value_lo, Immediate(0x80000000));
  __ sbbl(out_reg, Immediate(0));
  __ j(ABOVE_EQUAL, &not_smi);
  // 3. Restore lower half if result is a smi.
  __ subl(value_lo, Immediate(0x40000000));
  __ movl(out_reg, value_lo);
  __ SmiTag(out_reg);
  __ jmp(&done);
  __ Bind(&not_smi);
  // 3. Restore lower half of input before using it.
  __ subl(value_lo, Immediate(0x40000000));

  BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                  out_reg, locs()->temp(0).reg());
  __ movl(FieldAddress(out_reg, Mint::value_offset()), value_lo);
  __ movl(FieldAddress(out_reg, Mint::value_offset() + kWordSize), value_hi);
  __ Bind(&done);
}

LocationSummary* UnboxInteger32Instr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t kNumInputs = 1;
  intptr_t kNumTemps = 0;

  if (CanDeoptimize()) {
    if ((value_cid != kSmiCid) && (value_cid != kMintCid) && !is_truncating()) {
      kNumTemps = 2;
    } else {
      kNumTemps = 1;
    }
  }

  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  for (int i = 0; i < kNumTemps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }
  summary->set_out(0, ((value_cid == kSmiCid) || (value_cid != kMintCid))
                          ? Location::SameAsFirstInput()
                          : Location::RequiresRegister());
  return summary;
}

static void LoadInt32FromMint(FlowGraphCompiler* compiler,
                              Register result,
                              const Address& lo,
                              const Address& hi,
                              Register temp,
                              Label* deopt) {
  __ movl(result, lo);
  if (deopt != NULL) {
    ASSERT(temp != result);
    __ movl(temp, result);
    __ sarl(temp, Immediate(31));
    __ cmpl(temp, hi);
    __ j(NOT_EQUAL, deopt);
  }
}

void UnboxInteger32Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t value_cid = value()->Type()->ToCid();
  Register value = locs()->in(0).reg();
  const Register result = locs()->out(0).reg();
  const Register temp = CanDeoptimize() ? locs()->temp(0).reg() : kNoRegister;
  Label* deopt = CanDeoptimize() ? compiler->AddDeoptStub(
                                       GetDeoptId(), ICData::kDeoptUnboxInteger)
                                 : NULL;
  Label* out_of_range = !is_truncating() ? deopt : NULL;

  const intptr_t lo_offset = Mint::value_offset();
  const intptr_t hi_offset = Mint::value_offset() + kWordSize;

  if (value_cid == kSmiCid) {
    ASSERT(value == result);
    __ SmiUntag(value);
  } else if (value_cid == kMintCid) {
    ASSERT((value != result) || (out_of_range == NULL));
    LoadInt32FromMint(compiler, result, FieldAddress(value, lo_offset),
                      FieldAddress(value, hi_offset), temp, out_of_range);
  } else if (!CanDeoptimize()) {
    ASSERT(value == result);
    Label done;
    __ SmiUntag(value);
    __ j(NOT_CARRY, &done);
    __ movl(value, Address(value, TIMES_2, lo_offset));
    __ Bind(&done);
  } else {
    ASSERT(value == result);
    Label done;
    __ SmiUntagOrCheckClass(value, kMintCid, temp, &done);
    __ j(NOT_EQUAL, deopt);
    if (out_of_range != NULL) {
      Register value_temp = locs()->temp(1).reg();
      __ movl(value_temp, value);
      value = value_temp;
    }
    LoadInt32FromMint(compiler, result, Address(value, TIMES_2, lo_offset),
                      Address(value, TIMES_2, hi_offset), temp, out_of_range);
    __ Bind(&done);
  }
}

LocationSummary* LoadCodeUnitsInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const bool might_box = (representation() == kTagged) && !can_pack_into_smi();
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = might_box ? 2 : 0;
  LocationSummary* summary = new (zone) LocationSummary(
      zone, kNumInputs, kNumTemps,
      might_box ? LocationSummary::kCallOnSlowPath : LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  // The smi index is either untagged (element size == 1), or it is left smi
  // tagged (for all element sizes > 1).
  summary->set_in(1, (index_scale() == 1) ? Location::WritableRegister()
                                          : Location::RequiresRegister());
  if (might_box) {
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  }

  if (representation() == kUnboxedInt64) {
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else {
    ASSERT(representation() == kTagged);
    summary->set_out(0, Location::RequiresRegister());
  }

  return summary;
}

void LoadCodeUnitsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The string register points to the backing store for external strings.
  const Register str = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = Assembler::ElementAddressForRegIndex(
      IsExternal(), class_id(), index_scale(), str, index.reg());

  if ((index_scale() == 1)) {
    __ SmiUntag(index.reg());
  }

  if (representation() == kUnboxedInt64) {
    ASSERT(compiler->is_optimizing());
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* result_pair = locs()->out(0).AsPairLocation();
    Register result1 = result_pair->At(0).reg();
    Register result2 = result_pair->At(1).reg();

    switch (class_id()) {
      case kOneByteStringCid:
      case kExternalOneByteStringCid:
        ASSERT(element_count() == 4);
        __ movl(result1, element_address);
        __ xorl(result2, result2);
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        ASSERT(element_count() == 2);
        __ movl(result1, element_address);
        __ xorl(result2, result2);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    ASSERT(representation() == kTagged);
    Register result = locs()->out(0).reg();
    switch (class_id()) {
      case kOneByteStringCid:
      case kExternalOneByteStringCid:
        switch (element_count()) {
          case 1:
            __ movzxb(result, element_address);
            break;
          case 2:
            __ movzxw(result, element_address);
            break;
          case 4:
            __ movl(result, element_address);
            break;
          default:
            UNREACHABLE();
        }
        break;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        switch (element_count()) {
          case 1:
            __ movzxw(result, element_address);
            break;
          case 2:
            __ movl(result, element_address);
            break;
          default:
            UNREACHABLE();
        }
        break;
      default:
        UNREACHABLE();
        break;
    }
    if (can_pack_into_smi()) {
      __ SmiTag(result);
    } else {
      // If the value cannot fit in a smi then allocate a mint box for it.
      Register temp = locs()->temp(0).reg();
      Register temp2 = locs()->temp(1).reg();
      // Temp register needs to be manually preserved on allocation slow-path.
      // Add it to live_registers set which determines which registers to
      // preserve.
      locs()->live_registers()->Add(locs()->temp(0), kUnboxedInt32);

      ASSERT(temp != result);
      __ MoveRegister(temp, result);
      __ SmiTag(result);

      Label done;
      __ testl(temp, Immediate(0xC0000000));
      __ j(ZERO, &done);
      BoxAllocationSlowPath::Allocate(compiler, this, compiler->mint_class(),
                                      result, temp2);
      __ movl(FieldAddress(result, Mint::value_offset()), temp);
      __ movl(FieldAddress(result, Mint::value_offset() + kWordSize),
              Immediate(0));
      __ Bind(&done);
    }
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void BinaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister left = locs()->in(0).fpu_reg();
  XmmRegister right = locs()->in(1).fpu_reg();

  ASSERT(locs()->out(0).fpu_reg() == left);

  switch (op_kind()) {
    case Token::kADD:
      __ addsd(left, right);
      break;
    case Token::kSUB:
      __ subsd(left, right);
      break;
    case Token::kMUL:
      __ mulsd(left, right);
      break;
    case Token::kDIV:
      __ divsd(left, right);
      break;
    default:
      UNREACHABLE();
  }
}

LocationSummary* DoubleTestOpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (op_kind() == MethodRecognizer::kDouble_getIsInfinite) ? 1 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (op_kind() == MethodRecognizer::kDouble_getIsInfinite) {
    summary->set_temp(0, Location::RequiresRegister());
  }
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}

Condition DoubleTestOpInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                BranchLabels labels) {
  ASSERT(compiler->is_optimizing());
  const XmmRegister value = locs()->in(0).fpu_reg();
  const bool is_negated = kind() != Token::kEQ;
  if (op_kind() == MethodRecognizer::kDouble_getIsNaN) {
    Label is_nan;
    __ comisd(value, value);
    return is_negated ? PARITY_ODD : PARITY_EVEN;
  } else {
    ASSERT(op_kind() == MethodRecognizer::kDouble_getIsInfinite);
    const Register temp = locs()->temp(0).reg();
    Label check_upper;
    __ AddImmediate(ESP, Immediate(-kDoubleSize));
    __ movsd(Address(ESP, 0), value);
    __ movl(temp, Address(ESP, 0));
    // If the low word isn't zero, then it isn't infinity.
    __ cmpl(temp, Immediate(0));
    __ j(EQUAL, &check_upper, Assembler::kNearJump);
    __ AddImmediate(ESP, Immediate(kDoubleSize));
    __ jmp(is_negated ? labels.true_label : labels.false_label);
    __ Bind(&check_upper);
    // Check the high word.
    __ movl(temp, Address(ESP, kWordSize));
    __ AddImmediate(ESP, Immediate(kDoubleSize));
    // Mask off sign bit.
    __ andl(temp, Immediate(0x7FFFFFFF));
    // Compare with +infinity.
    __ cmpl(temp, Immediate(0x7FF00000));
    return is_negated ? NOT_EQUAL : EQUAL;
  }
}

// SIMD

#define DEFINE_EMIT(Name, Args)                                                \
  static void Emit##Name(FlowGraphCompiler* compiler, SimdOpInstr* instr,      \
                         PP_APPLY(PP_UNPACK, Args))

#define SIMD_OP_FLOAT_ARITH(V, Name, op)                                       \
  V(Float32x4##Name, op##ps)                                                   \
  V(Float64x2##Name, op##pd)

#define SIMD_OP_SIMPLE_BINARY(V)                                               \
  SIMD_OP_FLOAT_ARITH(V, Add, add)                                             \
  SIMD_OP_FLOAT_ARITH(V, Sub, sub)                                             \
  SIMD_OP_FLOAT_ARITH(V, Mul, mul)                                             \
  SIMD_OP_FLOAT_ARITH(V, Div, div)                                             \
  SIMD_OP_FLOAT_ARITH(V, Min, min)                                             \
  SIMD_OP_FLOAT_ARITH(V, Max, max)                                             \
  V(Int32x4Add, addpl)                                                         \
  V(Int32x4Sub, subpl)                                                         \
  V(Int32x4BitAnd, andps)                                                      \
  V(Int32x4BitOr, orps)                                                        \
  V(Int32x4BitXor, xorps)                                                      \
  V(Float32x4Equal, cmppseq)                                                   \
  V(Float32x4NotEqual, cmppsneq)                                               \
  V(Float32x4GreaterThan, cmppsnle)                                            \
  V(Float32x4GreaterThanOrEqual, cmppsnlt)                                     \
  V(Float32x4LessThan, cmppslt)                                                \
  V(Float32x4LessThanOrEqual, cmppsle)

DEFINE_EMIT(SimdBinaryOp,
            (SameAsFirstInput, XmmRegister left, XmmRegister right)) {
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(left, right);                                                        \
    break;
    SIMD_OP_SIMPLE_BINARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4Scale:
      __ cvtsd2ss(left, left);
      __ shufps(left, left, Immediate(0x00));
      __ mulps(left, right);
      break;
    case SimdOpInstr::kFloat32x4ShuffleMix:
    case SimdOpInstr::kInt32x4ShuffleMix:
      __ shufps(left, right, Immediate(instr->mask()));
      break;
    case SimdOpInstr::kFloat64x2Constructor:
      // shufpd mask 0x0 results in:
      // Lower 64-bits of left = Lower 64-bits of left.
      // Upper 64-bits of left = Lower 64-bits of right.
      __ shufpd(left, right, Immediate(0x0));
      break;
    case SimdOpInstr::kFloat64x2Scale:
      __ shufpd(right, right, Immediate(0x00));
      __ mulpd(left, right);
      break;
    case SimdOpInstr::kFloat64x2WithX:
    case SimdOpInstr::kFloat64x2WithY: {
      // TODO(dartbug.com/30949) avoid transfer through memory
      COMPILE_ASSERT(SimdOpInstr::kFloat64x2WithY ==
                     (SimdOpInstr::kFloat64x2WithX + 1));
      const intptr_t lane_index = instr->kind() - SimdOpInstr::kFloat64x2WithX;
      ASSERT(0 <= lane_index && lane_index < 2);
      __ SubImmediate(ESP, Immediate(kSimd128Size));
      __ movups(Address(ESP, 0), left);
      __ movsd(Address(ESP, lane_index * kDoubleSize), right);
      __ movups(left, Address(ESP, 0));
      __ AddImmediate(ESP, Immediate(kSimd128Size));
      break;
    }
    case SimdOpInstr::kFloat32x4WithX:
    case SimdOpInstr::kFloat32x4WithY:
    case SimdOpInstr::kFloat32x4WithZ:
    case SimdOpInstr::kFloat32x4WithW: {
      // TODO(dartbug.com/30949) avoid transfer through memory. SSE4.1 has
      // insertps. SSE2 these instructions can be implemented via a combination
      // of shufps/movss/movlhps.
      COMPILE_ASSERT(
          SimdOpInstr::kFloat32x4WithY == (SimdOpInstr::kFloat32x4WithX + 1) &&
          SimdOpInstr::kFloat32x4WithZ == (SimdOpInstr::kFloat32x4WithX + 2) &&
          SimdOpInstr::kFloat32x4WithW == (SimdOpInstr::kFloat32x4WithX + 3));
      const intptr_t lane_index = instr->kind() - SimdOpInstr::kFloat32x4WithX;
      ASSERT(0 <= lane_index && lane_index < 4);
      __ cvtsd2ss(left, left);
      __ SubImmediate(ESP, Immediate(kSimd128Size));
      __ movups(Address(ESP, 0), right);
      __ movss(Address(ESP, lane_index * kFloatSize), left);
      __ movups(left, Address(ESP, 0));
      __ AddImmediate(ESP, Immediate(kSimd128Size));
      break;
    }
    default:
      UNREACHABLE();
  }
}

#define SIMD_OP_SIMPLE_UNARY(V)                                                \
  SIMD_OP_FLOAT_ARITH(V, Sqrt, sqrt)                                           \
  SIMD_OP_FLOAT_ARITH(V, Negate, negate)                                       \
  SIMD_OP_FLOAT_ARITH(V, Abs, abs)                                             \
  V(Float32x4Reciprocal, reciprocalps)                                         \
  V(Float32x4ReciprocalSqrt, rsqrtps)

DEFINE_EMIT(SimdUnaryOp, (SameAsFirstInput, XmmRegister value)) {
  // TODO(dartbug.com/30949) select better register constraints to avoid
  // redundant move of input into a different register because all instructions
  // below support two operand forms.
  switch (instr->kind()) {
#define EMIT(Name, op)                                                         \
  case SimdOpInstr::k##Name:                                                   \
    __ op(value);                                                              \
    break;
    SIMD_OP_SIMPLE_UNARY(EMIT)
#undef EMIT
    case SimdOpInstr::kFloat32x4ShuffleX:
      // Shuffle not necessary.
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleY:
      __ shufps(value, value, Immediate(0x55));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleZ:
      __ shufps(value, value, Immediate(0xAA));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ShuffleW:
      __ shufps(value, value, Immediate(0xFF));
      __ cvtss2sd(value, value);
      break;
    case SimdOpInstr::kFloat32x4Shuffle:
    case SimdOpInstr::kInt32x4Shuffle:
      __ shufps(value, value, Immediate(instr->mask()));
      break;
    case SimdOpInstr::kFloat32x4Splat:
      // Convert to Float32.
      __ cvtsd2ss(value, value);
      // Splat across all lanes.
      __ shufps(value, value, Immediate(0x00));
      break;
    case SimdOpInstr::kFloat64x2ToFloat32x4:
      __ cvtpd2ps(value, value);
      break;
    case SimdOpInstr::kFloat32x4ToFloat64x2:
      __ cvtps2pd(value, value);
      break;
    case SimdOpInstr::kFloat32x4ToInt32x4:
    case SimdOpInstr::kInt32x4ToFloat32x4:
      // TODO(dartbug.com/30949) these operations are essentially nop and should
      // not generate any code. They should be removed from the graph before
      // code generation.
      break;
    case SimdOpInstr::kFloat64x2GetX:
      // NOP.
      break;
    case SimdOpInstr::kFloat64x2GetY:
      __ shufpd(value, value, Immediate(0x33));
      break;
    case SimdOpInstr::kFloat64x2Splat:
      __ shufpd(value, value, Immediate(0x0));
      break;
    default:
      UNREACHABLE();
  }
}

DEFINE_EMIT(SimdGetSignMask, (Register out, XmmRegister value)) {
  switch (instr->kind()) {
    case SimdOpInstr::kFloat32x4GetSignMask:
    case SimdOpInstr::kInt32x4GetSignMask:
      __ movmskps(out, value);
      break;
    case SimdOpInstr::kFloat64x2GetSignMask:
      __ movmskpd(out, value);
      break;
    default:
      UNREACHABLE();
      break;
  }
}

DEFINE_EMIT(
    Float32x4Constructor,
    (SameAsFirstInput, XmmRegister v0, XmmRegister, XmmRegister, XmmRegister)) {
  // TODO(dartbug.com/30949) avoid transfer through memory. SSE4.1 has
  // insertps, with SSE2 this instruction can be implemented through unpcklps.
  const XmmRegister out = v0;
  __ SubImmediate(ESP, Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ cvtsd2ss(out, instr->locs()->in(i).fpu_reg());
    __ movss(Address(ESP, i * kFloatSize), out);
  }
  __ movups(out, Address(ESP, 0));
  __ AddImmediate(ESP, Immediate(kSimd128Size));
}

DEFINE_EMIT(Float32x4Zero, (XmmRegister out)) {
  __ xorps(out, out);
}

DEFINE_EMIT(Float64x2Zero, (XmmRegister value)) {
  __ xorpd(value, value);
}

DEFINE_EMIT(Float32x4Clamp,
            (SameAsFirstInput,
             XmmRegister left,
             XmmRegister lower,
             XmmRegister upper)) {
  __ minps(left, upper);
  __ maxps(left, lower);
}

DEFINE_EMIT(Int32x4Constructor,
            (XmmRegister result, Register, Register, Register, Register)) {
  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    __ movl(Address(ESP, i * kInt32Size), instr->locs()->in(i).reg());
  }
  __ movups(result, Address(ESP, 0));
  __ AddImmediate(ESP, Immediate(kSimd128Size));
}

DEFINE_EMIT(Int32x4BoolConstructor,
            (XmmRegister result, Register, Register, Register, Register)) {
  // TODO(dartbug.com/30949) avoid transfer through memory and branches.
  __ SubImmediate(ESP, Immediate(kSimd128Size));
  for (intptr_t i = 0; i < 4; i++) {
    Label store_false, done;
    __ CompareObject(instr->locs()->in(i).reg(), Bool::True());
    __ j(NOT_EQUAL, &store_false);
    __ movl(Address(ESP, kInt32Size * i), Immediate(0xFFFFFFFF));
    __ jmp(&done);
    __ Bind(&store_false);
    __ movl(Address(ESP, kInt32Size * i), Immediate(0x0));
    __ Bind(&done);
  }
  __ movups(result, Address(ESP, 0));
  __ AddImmediate(ESP, Immediate(kSimd128Size));
}

// TODO(dartbug.com/30953) need register with a byte component for setcc.
DEFINE_EMIT(Int32x4GetFlag, (Fixed<Register, EDX> result, XmmRegister value)) {
  COMPILE_ASSERT(
      SimdOpInstr::kInt32x4GetFlagY == (SimdOpInstr::kInt32x4GetFlagX + 1) &&
      SimdOpInstr::kInt32x4GetFlagZ == (SimdOpInstr::kInt32x4GetFlagX + 2) &&
      SimdOpInstr::kInt32x4GetFlagW == (SimdOpInstr::kInt32x4GetFlagX + 3));
  const intptr_t lane_index = instr->kind() - SimdOpInstr::kInt32x4GetFlagX;
  ASSERT(0 <= lane_index && lane_index < 4);

  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, Immediate(kSimd128Size));
  __ movups(Address(ESP, 0), value);
  __ movl(EDX, Address(ESP, lane_index * kInt32Size));
  __ AddImmediate(ESP, Immediate(kSimd128Size));

  // EDX = EDX != 0 ? 0 : 1
  __ testl(EDX, EDX);
  __ setcc(ZERO, DL);
  __ movzxb(EDX, DL);

  ASSERT_BOOL_FALSE_FOLLOWS_BOOL_TRUE();
  __ movl(EDX, Address(THR, EDX, TIMES_4, Thread::bool_true_offset()));
}

// TODO(dartbug.com/30953) need register with a byte component for setcc.
DEFINE_EMIT(Int32x4WithFlag,
            (SameAsFirstInput,
             XmmRegister mask,
             Register flag,
             Temp<Fixed<Register, EDX> > temp)) {
  COMPILE_ASSERT(
      SimdOpInstr::kInt32x4WithFlagY == (SimdOpInstr::kInt32x4WithFlagX + 1) &&
      SimdOpInstr::kInt32x4WithFlagZ == (SimdOpInstr::kInt32x4WithFlagX + 2) &&
      SimdOpInstr::kInt32x4WithFlagW == (SimdOpInstr::kInt32x4WithFlagX + 3));
  const intptr_t lane_index = instr->kind() - SimdOpInstr::kInt32x4WithFlagX;
  ASSERT(0 <= lane_index && lane_index < 4);

  // TODO(dartbug.com/30949) avoid transfer through memory.
  __ SubImmediate(ESP, Immediate(kSimd128Size));
  __ movups(Address(ESP, 0), mask);

  // EDX = flag == true ? -1 : 0
  __ xorl(EDX, EDX);
  __ CompareObject(flag, Bool::True());
  __ setcc(EQUAL, DL);
  __ negl(EDX);

  __ movl(Address(ESP, lane_index * kInt32Size), EDX);

  // Copy mask back to register.
  __ movups(mask, Address(ESP, 0));
  __ AddImmediate(ESP, Immediate(kSimd128Size));
}

DEFINE_EMIT(Int32x4Select,
            (SameAsFirstInput,
             XmmRegister mask,
             XmmRegister trueValue,
             XmmRegister falseValue,
             Temp<XmmRegister> temp)) {
  // Copy mask.
  __ movaps(temp, mask);
  // Invert it.
  __ notps(temp);
  // mask = mask & trueValue.
  __ andps(mask, trueValue);
  // temp = temp & falseValue.
  __ andps(temp, falseValue);
  // out = mask | temp.
  __ orps(mask, temp);
}

// Map SimdOpInstr::Kind-s to corresponding emit functions. Uses the following
// format:
//
//     CASE(OpA) CASE(OpB) ____(Emitter) - Emitter is used to emit OpA and OpB.
//     SIMPLE(OpA) - Emitter with name OpA is used to emit OpA.
//
#define SIMD_OP_VARIANTS(CASE, ____, SIMPLE)                                   \
  SIMD_OP_SIMPLE_BINARY(CASE)                                                  \
  CASE(Float32x4Scale)                                                         \
  CASE(Float32x4ShuffleMix)                                                    \
  CASE(Int32x4ShuffleMix)                                                      \
  CASE(Float64x2Constructor)                                                   \
  CASE(Float64x2Scale)                                                         \
  CASE(Float64x2WithX)                                                         \
  CASE(Float64x2WithY)                                                         \
  CASE(Float32x4WithX)                                                         \
  CASE(Float32x4WithY)                                                         \
  CASE(Float32x4WithZ)                                                         \
  CASE(Float32x4WithW)                                                         \
  ____(SimdBinaryOp)                                                           \
  SIMD_OP_SIMPLE_UNARY(CASE)                                                   \
  CASE(Float32x4ShuffleX)                                                      \
  CASE(Float32x4ShuffleY)                                                      \
  CASE(Float32x4ShuffleZ)                                                      \
  CASE(Float32x4ShuffleW)                                                      \
  CASE(Float32x4Shuffle)                                                       \
  CASE(Int32x4Shuffle)                                                         \
  CASE(Float32x4Splat)                                                         \
  CASE(Float32x4ToFloat64x2)                                                   \
  CASE(Float64x2ToFloat32x4)                                                   \
  CASE(Int32x4ToFloat32x4)                                                     \
  CASE(Float32x4ToInt32x4)                                                     \
  CASE(Float64x2GetX)                                                          \
  CASE(Float64x2GetY)                                                          \
  CASE(Float64x2Splat)                                                         \
  ____(SimdUnaryOp)                                                            \
  CASE(Float32x4GetSignMask)                                                   \
  CASE(Int32x4GetSignMask)                                                     \
  CASE(Float64x2GetSignMask)                                                   \
  ____(SimdGetSignMask)                                                        \
  SIMPLE(Float32x4Constructor)                                                 \
  SIMPLE(Int32x4Constructor)                                                   \
  SIMPLE(Int32x4BoolConstructor)                                               \
  SIMPLE(Float32x4Zero)                                                        \
  SIMPLE(Float64x2Zero)                                                        \
  SIMPLE(Float32x4Clamp)                                                       \
  CASE(Int32x4GetFlagX)                                                        \
  CASE(Int32x4GetFlagY)                                                        \
  CASE(Int32x4GetFlagZ)                                                        \
  CASE(Int32x4GetFlagW)                                                        \
  ____(Int32x4GetFlag)                                                         \
  CASE(Int32x4WithFlagX)                                                       \
  CASE(Int32x4WithFlagY)                                                       \
  CASE(Int32x4WithFlagZ)                                                       \
  CASE(Int32x4WithFlagW)                                                       \
  ____(Int32x4WithFlag)                                                        \
  SIMPLE(Int32x4Select)

LocationSummary* SimdOpInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  switch (kind()) {
#define CASE(Name, ...) case k##Name:
#define EMIT(Name)                                                             \
  return MakeLocationSummaryFromEmitter(zone, this, &Emit##Name);
#define SIMPLE(Name) CASE(Name) EMIT(Name)
    SIMD_OP_VARIANTS(CASE, EMIT, SIMPLE)
#undef CASE
#undef EMIT
#undef SIMPLE
    case kIllegalSimdOp:
      UNREACHABLE();
      break;
  }
  UNREACHABLE();
  return NULL;
}

void SimdOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  switch (kind()) {
#define CASE(Name, ...) case k##Name:
#define EMIT(Name)                                                             \
  InvokeEmitter(compiler, this, &Emit##Name);                                  \
  break;
#define SIMPLE(Name) CASE(Name) EMIT(Name)
    SIMD_OP_VARIANTS(CASE, EMIT, SIMPLE)
#undef CASE
#undef EMIT
#undef SIMPLE
    case kIllegalSimdOp:
      UNREACHABLE();
      break;
  }
}

#undef DEFINE_EMIT

LocationSummary* MathUnaryInstr::MakeLocationSummary(Zone* zone,
                                                     bool opt) const {
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  if (kind() == MathUnaryInstr::kDoubleSquare) {
    summary->set_out(0, Location::SameAsFirstInput());
  } else {
    summary->set_out(0, Location::RequiresFpuRegister());
  }
  return summary;
}

void MathUnaryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (kind() == MathUnaryInstr::kSqrt) {
    __ sqrtsd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
  } else if (kind() == MathUnaryInstr::kDoubleSquare) {
    XmmRegister value_reg = locs()->in(0).fpu_reg();
    __ mulsd(value_reg, value_reg);
    ASSERT(value_reg == locs()->out(0).fpu_reg());
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
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::RegisterLocation(ECX));
  summary->set_in(2, Location::RegisterLocation(EDX));
  summary->set_in(3, Location::RegisterLocation(EBX));
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void CaseInsensitiveCompareUC16Instr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  // Save ESP. EDI is chosen because it is callee saved so we do not need to
  // back it up before calling into the runtime.
  static const Register kSavedSPReg = EDI;
  __ movl(kSavedSPReg, ESP);
  __ ReserveAlignedFrameSpace(kWordSize * TargetFunction().argument_count());

  __ movl(Address(ESP, +0 * kWordSize), locs()->in(0).reg());
  __ movl(Address(ESP, +1 * kWordSize), locs()->in(1).reg());
  __ movl(Address(ESP, +2 * kWordSize), locs()->in(2).reg());
  __ movl(Address(ESP, +3 * kWordSize), locs()->in(3).reg());

  // Call the function.
  __ CallRuntime(TargetFunction(), TargetFunction().argument_count());

  // Restore ESP.
  __ movl(ESP, kSavedSPReg);
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
    XmmRegister left = locs()->in(0).fpu_reg();
    XmmRegister right = locs()->in(1).fpu_reg();
    XmmRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ comisd(left, right);
    __ j(PARITY_EVEN, &returns_nan, Assembler::kNearJump);
    __ j(EQUAL, &are_equal, Assembler::kNearJump);
    const Condition double_condition =
        is_min ? TokenKindToDoubleCondition(Token::kLT)
               : TokenKindToDoubleCondition(Token::kGT);
    ASSERT(left == result);
    __ j(double_condition, &done, Assembler::kNearJump);
    __ movsd(result, right);
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&returns_nan);
    static double kNaN = NAN;
    __ movsd(result, Address::Absolute(reinterpret_cast<uword>(&kNaN)));
    __ jmp(&done, Assembler::kNearJump);

    __ Bind(&are_equal);
    Label left_is_negative;
    // Check for negative zero: -0.0 is equal 0.0 but min or max must return
    // -0.0 or 0.0 respectively.
    // Check for negative left value (get the sign bit):
    // - min -> left is negative ? left : right.
    // - max -> left is negative ? right : left
    // Check the sign bit.
    __ movmskpd(temp, left);
    __ testl(temp, Immediate(1));
    ASSERT(left == result);
    if (is_min) {
      __ j(NOT_ZERO, &done, Assembler::kNearJump);  // Negative -> return left.
    } else {
      __ j(ZERO, &done, Assembler::kNearJump);  // Positive -> return left.
    }
    __ movsd(result, right);
    __ Bind(&done);
    return;
  }

  ASSERT(result_cid() == kSmiCid);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  Register result = locs()->out(0).reg();
  __ cmpl(left, right);
  ASSERT(result == left);
  if (is_min) {
    __ cmovgel(result, right);
  } else {
    __ cmovlessl(result, right);
  }
}

LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(zone, kNumInputs, Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}

void UnarySmiOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  ASSERT(value == locs()->out(0).reg());
  switch (op_kind()) {
    case Token::kNEGATE: {
      Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnaryOp);
      __ negl(value);
      __ j(OVERFLOW, deopt);
      break;
    }
    case Token::kBIT_NOT:
      __ notl(value);
      __ andl(value, Immediate(~kSmiTagMask));  // Remove inverted smi-tag.
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
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  ASSERT(locs()->out(0).fpu_reg() == value);
  __ DoubleNegate(value);
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
  __ cvtsi2sd(result, value);
}

LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::WritableRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void SmiToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  FpuRegister result = locs()->out(0).fpu_reg();
  __ SmiUntag(value);
  __ cvtsi2sd(result, value);
}

LocationSummary* Int64ToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::Pair(Location::RequiresRegister(),
                                   Location::RequiresRegister()));
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void Int64ToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* pair = locs()->in(0).AsPairLocation();
  Register in_lo = pair->At(0).reg();
  Register in_hi = pair->At(1).reg();

  FpuRegister result = locs()->out(0).fpu_reg();

  // Push hi.
  __ pushl(in_hi);
  // Push lo.
  __ pushl(in_lo);
  // Perform conversion from Mint to double.
  __ fildl(Address(ESP, 0));
  // Pop FPU stack onto regular stack.
  __ fstpl(Address(ESP, 0));
  // Copy into result.
  __ movsd(result, Address(ESP, 0));
  // Pop args.
  __ addl(ESP, Immediate(2 * kWordSize));
}

LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  result->set_in(0, Location::RegisterLocation(ECX));
  result->set_out(0, Location::RegisterLocation(EAX));
  return result;
}

void DoubleToIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result = locs()->out(0).reg();
  Register value_obj = locs()->in(0).reg();
  XmmRegister value_double = XMM0;
  ASSERT(result == EAX);
  ASSERT(result != value_obj);
  __ movsd(value_double, FieldAddress(value_obj, Double::value_offset()));
  __ cvttsd2si(result, value_double);
  // Overflow is signalled with minint.
  Label do_call, done;
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, Immediate(0xC0000000));
  __ j(NEGATIVE, &do_call, Assembler::kNearJump);
  __ SmiTag(result);
  __ jmp(&done);
  __ Bind(&do_call);
  __ pushl(value_obj);
  ASSERT(instance_call()->HasICData());
  const ICData& ic_data = *instance_call()->ic_data();
  ASSERT(ic_data.NumberOfChecksIs(1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));
  const int kTypeArgsLen = 0;
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  ArgumentsInfo args_info(kTypeArgsLen, kNumberOfArguments, kNoArgumentNames);
  compiler->GenerateStaticCall(deopt_id(), instance_call()->token_pos(), target,
                               args_info, locs(), ICData::Handle(),
                               ICData::kStatic);
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
  XmmRegister value = locs()->in(0).fpu_reg();
  __ cvttsd2si(result, value);
  // Check for overflow and that it fits into Smi.
  __ cmpl(result, Immediate(0xC0000000));
  __ j(NEGATIVE, deopt);
  __ SmiTag(result);
}

LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresFpuRegister());
  return result;
}

void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  XmmRegister value = locs()->in(0).fpu_reg();
  XmmRegister result = locs()->out(0).fpu_reg();
  switch (recognized_kind()) {
    case MethodRecognizer::kDoubleTruncate:
      __ roundsd(result, value, Assembler::kRoundToZero);
      break;
    case MethodRecognizer::kDoubleFloor:
      __ roundsd(result, value, Assembler::kRoundDown);
      break;
    case MethodRecognizer::kDoubleCeil:
      __ roundsd(result, value, Assembler::kRoundUp);
      break;
    default:
      UNREACHABLE();
  }
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
  __ cvtsd2ss(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
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
  __ cvtss2sd(locs()->out(0).fpu_reg(), locs()->in(0).fpu_reg());
}

LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps =
      (recognized_kind() == MethodRecognizer::kMathDoublePow) ? 3 : 1;
  LocationSummary* result = new (zone)
      LocationSummary(zone, InputCount(), kNumTemps, LocationSummary::kCall);
  // EDI is chosen because it is callee saved so we do not need to back it
  // up before calling into the runtime.
  result->set_temp(0, Location::RegisterLocation(EDI));
  result->set_in(0, Location::FpuRegisterLocation(XMM1));
  if (InputCount() == 2) {
    result->set_in(1, Location::FpuRegisterLocation(XMM2));
  }
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    // Temp index 1.
    result->set_temp(1, Location::RegisterLocation(EAX));
    // Temp index 2.
    result->set_temp(2, Location::FpuRegisterLocation(XMM4));
  }
  result->set_out(0, Location::FpuRegisterLocation(XMM3));
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

  XmmRegister base = locs->in(0).fpu_reg();
  XmmRegister exp = locs->in(1).fpu_reg();
  XmmRegister result = locs->out(0).fpu_reg();
  Register temp = locs->temp(InvokeMathCFunctionInstr::kObjectTempIndex).reg();
  XmmRegister zero_temp =
      locs->temp(InvokeMathCFunctionInstr::kDoubleTempIndex).fpu_reg();

  __ xorps(zero_temp, zero_temp);  // 0.0.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(1.0)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));

  Label check_base, skip_call;
  // exponent == 0.0 -> return 1.0;
  __ comisd(exp, zero_temp);
  __ j(PARITY_EVEN, &check_base);
  __ j(EQUAL, &skip_call);  // 'result' is 1.0.

  // exponent == 1.0 ?
  __ comisd(exp, result);
  Label return_base;
  __ j(EQUAL, &return_base, Assembler::kNearJump);

  // exponent == 2.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(2.0)));
  __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  Label return_base_times_2;
  __ j(EQUAL, &return_base_times_2, Assembler::kNearJump);

  // exponent == 3.0 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(3.0)));
  __ movsd(XMM0, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, XMM0);
  __ j(NOT_EQUAL, &check_base);

  // Base times 3.
  __ movsd(result, base);
  __ mulsd(result, base);
  __ mulsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&return_base);
  __ movsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&return_base_times_2);
  __ movsd(result, base);
  __ mulsd(result, base);
  __ jmp(&skip_call);

  __ Bind(&check_base);
  // Note: 'exp' could be NaN.

  // base == 1.0 -> return 1.0;
  __ comisd(base, result);
  Label return_nan;
  __ j(PARITY_EVEN, &return_nan, Assembler::kNearJump);
  __ j(EQUAL, &skip_call, Assembler::kNearJump);
  // Note: 'base' could be NaN.
  __ comisd(exp, base);
  // Neither 'exp' nor 'base' is NaN.
  Label try_sqrt;
  __ j(PARITY_ODD, &try_sqrt, Assembler::kNearJump);
  // Return NaN.
  __ Bind(&return_nan);
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(NAN)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  __ jmp(&skip_call);

  Label do_pow, return_zero;
  __ Bind(&try_sqrt);
  // Before calling pow, check if we could use sqrt instead of pow.
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(kNegInfinity)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  // base == -Infinity -> call pow;
  __ comisd(base, result);
  __ j(EQUAL, &do_pow, Assembler::kNearJump);

  // exponent == 0.5 ?
  __ LoadObject(temp, Double::ZoneHandle(Double::NewCanonical(0.5)));
  __ movsd(result, FieldAddress(temp, Double::value_offset()));
  __ comisd(exp, result);
  __ j(NOT_EQUAL, &do_pow, Assembler::kNearJump);

  // base == 0 -> return 0;
  __ comisd(base, zero_temp);
  __ j(EQUAL, &return_zero, Assembler::kNearJump);

  __ sqrtsd(result, base);
  __ jmp(&skip_call, Assembler::kNearJump);

  __ Bind(&return_zero);
  __ movsd(result, zero_temp);
  __ jmp(&skip_call);

  __ Bind(&do_pow);
  // Save ESP.
  __ movl(locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg(), ESP);
  __ ReserveAlignedFrameSpace(kDoubleSize * kInputCount);
  for (intptr_t i = 0; i < kInputCount; i++) {
    __ movsd(Address(ESP, kDoubleSize * i), locs->in(i).fpu_reg());
  }
  __ CallRuntime(instr->TargetFunction(), kInputCount);
  __ fstpl(Address(ESP, 0));
  __ movsd(locs->out(0).fpu_reg(), Address(ESP, 0));
  // Restore ESP.
  __ movl(ESP, locs->temp(InvokeMathCFunctionInstr::kSavedSpTempIndex).reg());
  __ Bind(&skip_call);
}

void InvokeMathCFunctionInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (recognized_kind() == MethodRecognizer::kMathDoublePow) {
    InvokeDoublePow(compiler, this);
    return;
  }
  // Save ESP.
  __ movl(locs()->temp(kSavedSpTempIndex).reg(), ESP);
  __ ReserveAlignedFrameSpace(kDoubleSize * InputCount());
  for (intptr_t i = 0; i < InputCount(); i++) {
    __ movsd(Address(ESP, kDoubleSize * i), locs()->in(i).fpu_reg());
  }

  __ CallRuntime(TargetFunction(), InputCount());
  __ fstpl(Address(ESP, 0));
  __ movsd(locs()->out(0).fpu_reg(), Address(ESP, 0));
  // Restore ESP.
  __ movl(ESP, locs()->temp(kSavedSpTempIndex).reg());
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
    XmmRegister out = locs()->out(0).fpu_reg();
    XmmRegister in = in_loc.fpu_reg();
    __ movaps(out, in);
  } else {
    ASSERT(representation() == kTagged);
    Register out = locs()->out(0).reg();
    Register in = in_loc.reg();
    __ movl(out, in);
  }
}

LocationSummary* TruncDivModInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  // Both inputs must be writable because they will be untagged.
  summary->set_in(0, Location::RegisterLocation(EAX));
  summary->set_in(1, Location::WritableRegister());
  // Output is a pair of registers.
  summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                     Location::RegisterLocation(EDX)));
  return summary;
}

void TruncDivModInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(CanDeoptimize());
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  Register left = locs()->in(0).reg();
  Register right = locs()->in(1).reg();
  ASSERT(locs()->out(0).IsPairLocation());
  PairLocation* pair = locs()->out(0).AsPairLocation();
  Register result1 = pair->At(0).reg();
  Register result2 = pair->At(1).reg();
  if (RangeUtils::CanBeZero(divisor_range())) {
    // Handle divide by zero in runtime.
    __ testl(right, right);
    __ j(ZERO, deopt);
  }
  ASSERT(left == EAX);
  ASSERT((right != EDX) && (right != EAX));
  ASSERT(result1 == EAX);
  ASSERT(result2 == EDX);
  __ SmiUntag(left);
  __ SmiUntag(right);
  __ cdq();         // Sign extend EAX -> EDX:EAX.
  __ idivl(right);  //  EAX: quotient, EDX: remainder.
  // Check the corner case of dividing the 'MIN_SMI' with -1, in which
  // case we cannot tag the result.
  // TODO(srdjan): We could store instead untagged intermediate results in a
  // typed array, but then the load indexed instructions would need to be
  // able to deoptimize.
  __ cmpl(EAX, Immediate(0x40000000));
  __ j(EQUAL, deopt);
  // Modulo result (EDX) correction:
  //  res = left % right;
  //  if (res < 0) {
  //    if (right < 0) {
  //      res = res - right;
  //    } else {
  //      res = res + right;
  //    }
  //  }
  Label done;
  __ cmpl(EDX, Immediate(0));
  __ j(GREATER_EQUAL, &done, Assembler::kNearJump);
  // Result is negative, adjust it.
  if (RangeUtils::Overlaps(divisor_range(), -1, 1)) {
    Label subtract;
    __ cmpl(right, Immediate(0));
    __ j(LESS, &subtract, Assembler::kNearJump);
    __ addl(EDX, right);
    __ jmp(&done, Assembler::kNearJump);
    __ Bind(&subtract);
    __ subl(EDX, right);
  } else if (divisor_range()->IsPositive()) {
    // Right is positive.
    __ addl(EDX, right);
  } else {
    // Right is negative.
    __ subl(EDX, right);
  }
  __ Bind(&done);

  __ SmiTag(EAX);
  __ SmiTag(EDX);
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
  const Immediate& raw_null =
      Immediate(reinterpret_cast<intptr_t>(Object::null()));
  __ cmpl(locs()->in(0).reg(), raw_null);
  ASSERT(IsDeoptIfNull() || IsDeoptIfNotNull());
  Condition cond = IsDeoptIfNull() ? EQUAL : NOT_EQUAL;
  __ j(cond, deopt);
}

void CheckClassInstr::EmitBitTest(FlowGraphCompiler* compiler,
                                  intptr_t min,
                                  intptr_t max,
                                  intptr_t mask,
                                  Label* deopt) {
  Register biased_cid = locs()->temp(0).reg();
  __ subl(biased_cid, Immediate(min));
  __ cmpl(biased_cid, Immediate(max - min));
  __ j(ABOVE, deopt);

  Register mask_reg = locs()->temp(1).reg();
  __ movl(mask_reg, Immediate(mask));
  __ bt(mask_reg, biased_cid);
  __ j(NOT_CARRY, deopt);
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
  Condition no_match, match;
  if (cid_start == cid_end) {
    __ cmpl(biased_cid, Immediate(cid_start - bias));
    no_match = NOT_EQUAL;
    match = EQUAL;
  } else {
    // For class ID ranges use a subtract followed by an unsigned
    // comparison to check both ends of the ranges with one comparison.
    __ addl(biased_cid, Immediate(bias - cid_start));
    bias = cid_start;
    __ cmpl(biased_cid, Immediate(cid_end - cid_start));
    no_match = ABOVE;
    match = BELOW_EQUAL;
  }

  if (is_last) {
    __ j(no_match, deopt);
  } else {
    if (use_near_jump) {
      __ j(match, is_ok, Assembler::kNearJump);
    } else {
      __ j(match, is_ok);
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
    __ cmpl(value, Immediate(Smi::RawValue(cids_.cid_start)));
    __ j(NOT_ZERO, deopt);
  } else {
    __ AddImmediate(value, Immediate(-Smi::RawValue(cids_.cid_start)));
    __ cmpl(value, Immediate(Smi::RawValue(cids_.Extent())));
    __ j(ABOVE, deopt);
  }
}

// Length: register or constant.
// Index: register, constant or stack slot.
LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Zone* zone,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if (length()->definition()->IsConstant()) {
    locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  } else {
    locs->set_in(kLengthPos, Location::PrefersRegister());
  }
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
    __ jmp(deopt);
    return;
  }

  const intptr_t index_cid = index()->Type()->ToCid();
  if (length_loc.IsConstant()) {
    Register index = index_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    const Smi& length = Smi::Cast(length_loc.constant());
    if (length.Value() == Smi::kMaxValue) {
      __ testl(index, index);
      __ j(NEGATIVE, deopt);
    } else {
      __ cmpl(index, Immediate(reinterpret_cast<int32_t>(length.raw())));
      __ j(ABOVE_EQUAL, deopt);
    }
  } else if (index_loc.IsConstant()) {
    const Smi& index = Smi::Cast(index_loc.constant());
    if (length_loc.IsStackSlot()) {
      const Address& length = length_loc.ToStackSlotAddress();
      __ cmpl(length, Immediate(reinterpret_cast<int32_t>(index.raw())));
    } else {
      Register length = length_loc.reg();
      __ cmpl(length, Immediate(reinterpret_cast<int32_t>(index.raw())));
    }
    __ j(BELOW_EQUAL, deopt);
  } else if (length_loc.IsStackSlot()) {
    Register index = index_loc.reg();
    const Address& length = length_loc.ToStackSlotAddress();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmpl(index, length);
    __ j(ABOVE_EQUAL, deopt);
  } else {
    Register index = index_loc.reg();
    Register length = length_loc.reg();
    if (index_cid != kSmiCid) {
      __ BranchIfNotSmi(index, deopt);
    }
    __ cmpl(length, index);
    __ j(BELOW_EQUAL, deopt);
  }
}

LocationSummary* BinaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  switch (op_kind()) {
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL: {
      const intptr_t kNumTemps = (op_kind() == Token::kMUL) ? 1 : 0;
      LocationSummary* summary = new (zone) LocationSummary(
          zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
      summary->set_in(0, (op_kind() == Token::kMUL)
                             ? Location::Pair(Location::RegisterLocation(EAX),
                                              Location::RegisterLocation(EDX))
                             : Location::Pair(Location::RequiresRegister(),
                                              Location::RequiresRegister()));
      summary->set_in(1, Location::Pair(Location::RequiresRegister(),
                                        Location::RequiresRegister()));
      summary->set_out(0, Location::SameAsFirstInput());
      if (kNumTemps > 0) {
        summary->set_temp(0, Location::RequiresRegister());
      }
      return summary;
    }
    default:
      UNREACHABLE();
      return NULL;
  }
}

void BinaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* right_pair = locs()->in(1).AsPairLocation();
  Register right_lo = right_pair->At(0).reg();
  Register right_hi = right_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);
  }
  switch (op_kind()) {
    case Token::kBIT_AND:
      __ andl(left_lo, right_lo);
      __ andl(left_hi, right_hi);
      break;
    case Token::kBIT_OR:
      __ orl(left_lo, right_lo);
      __ orl(left_hi, right_hi);
      break;
    case Token::kBIT_XOR:
      __ xorl(left_lo, right_lo);
      __ xorl(left_hi, right_hi);
      break;
    case Token::kADD:
    case Token::kSUB: {
      if (op_kind() == Token::kADD) {
        __ addl(left_lo, right_lo);
        __ adcl(left_hi, right_hi);
      } else {
        __ subl(left_lo, right_lo);
        __ sbbl(left_hi, right_hi);
      }
      if (can_overflow()) {
        __ j(OVERFLOW, deopt);
      }
      break;
    }
    case Token::kMUL: {
      // The product of two signed 32-bit integers fits in a signed 64-bit
      // result without causing overflow.
      // We deopt on larger inputs.
      // TODO(regis): Range analysis may eliminate the deopt check.
      Register temp = locs()->temp(0).reg();
      __ movl(temp, left_lo);
      __ sarl(temp, Immediate(31));
      __ cmpl(temp, left_hi);
      __ j(NOT_EQUAL, deopt);
      __ movl(temp, right_lo);
      __ sarl(temp, Immediate(31));
      __ cmpl(temp, right_hi);
      __ j(NOT_EQUAL, deopt);
      ASSERT(left_lo == EAX);
      __ imull(right_lo);  // Result in EDX:EAX.
      ASSERT(out_lo == EAX);
      ASSERT(out_hi == EDX);
      break;
    }
    default:
      UNREACHABLE();
  }
}

LocationSummary* ShiftInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (op_kind() == Token::kSHL) && CanDeoptimize() ? 2 : 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
  if ((op_kind() == Token::kSHL) && CanDeoptimize()) {
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  }
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void ShiftInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);

  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);
  }
  if (locs()->in(1).IsConstant()) {
    // Code for a constant shift amount.
    ASSERT(locs()->in(1).constant().IsSmi());
    const int32_t shift = Smi::Cast(locs()->in(1).constant()).Value();
    ASSERT(shift >= 0);
    switch (op_kind()) {
      case Token::kSHR: {
        if (shift > 31) {
          __ movl(left_lo, left_hi);        // Shift by 32.
          __ sarl(left_hi, Immediate(31));  // Sign extend left hi.
          if (shift > 32) {
            __ sarl(left_lo, Immediate(shift > 63 ? 31 : shift - 32));
          }
        } else {
          __ shrdl(left_lo, left_hi, Immediate(shift));
          __ sarl(left_hi, Immediate(shift));
        }
        break;
      }
      case Token::kSHL: {
        ASSERT(shift < 64);
        if (can_overflow()) {
          Register temp1 = locs()->temp(0).reg();
          Register temp2 = locs()->temp(1).reg();
          __ movl(temp1, left_hi);  // Preserve high 32 bits.
          if (shift > 31) {
            __ movl(left_hi, left_lo);  // Shift by 32.
            if (shift > 32) {
              __ shll(left_hi, Immediate(shift - 32));
            }
            // Check for overflow by sign extending the high 32 bits
            // and comparing with the input.
            __ movl(temp2, left_hi);
            __ sarl(temp2, Immediate(31));
            __ cmpl(temp1, temp2);
            __ j(NOT_EQUAL, deopt);
            if (shift > 32) {
              // Also compare low word from input with high word from
              // output shifted back shift - 32.
              __ movl(temp2, left_hi);
              __ sarl(temp2, Immediate(shift - 32));
              __ cmpl(left_lo, temp2);
              __ j(NOT_EQUAL, deopt);
            }
            __ xorl(left_lo, left_lo);  // Zero left_lo.
          } else {
            __ shldl(left_hi, left_lo, Immediate(shift));
            __ shll(left_lo, Immediate(shift));
            // Check for overflow by shifting back the high 32 bits
            // and comparing with the input.
            __ movl(temp2, left_hi);
            __ sarl(temp2, Immediate(shift));
            __ cmpl(temp1, temp2);
            __ j(NOT_EQUAL, deopt);
          }
        } else {
          if (shift > 31) {
            __ movl(left_hi, left_lo);  // Shift by 32.
            __ xorl(left_lo, left_lo);  // Zero left_lo.
            if (shift > 32) {
              __ shll(left_hi, Immediate(shift - 32));
            }
          } else {
            __ shldl(left_hi, left_lo, Immediate(shift));
            __ shll(left_lo, Immediate(shift));
          }
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  } else {
    // Code for a variable shift amount.
    // Deoptimize if shift count is > 63.
    // sarl operation masks the count to 5 bits and
    // shrdl is undefined with count > operand size (32)
    __ SmiUntag(ECX);
    if (!IsShiftCountInRange()) {
      __ cmpl(ECX, Immediate(kMintShiftCountLimit));
      __ j(ABOVE, deopt);
    }
    Label done, large_shift;
    switch (op_kind()) {
      case Token::kSHR: {
        __ cmpl(ECX, Immediate(31));
        __ j(ABOVE, &large_shift);

        __ shrdl(left_lo, left_hi, ECX);  // Shift count in CL.
        __ sarl(left_hi, ECX);            // Shift count in CL.
        __ jmp(&done, Assembler::kNearJump);

        __ Bind(&large_shift);
        // No need to subtract 32 from CL, only 5 bits used by sarl.
        __ movl(left_lo, left_hi);        // Shift by 32.
        __ sarl(left_hi, Immediate(31));  // Sign extend left hi.
        __ sarl(left_lo, ECX);            // Shift count: CL % 32.
        break;
      }
      case Token::kSHL: {
        if (can_overflow()) {
          Register temp1 = locs()->temp(0).reg();
          Register temp2 = locs()->temp(1).reg();
          __ movl(temp1, left_hi);  // Preserve high 32 bits.
          __ cmpl(ECX, Immediate(31));
          __ j(ABOVE, &large_shift);

          __ shldl(left_hi, left_lo, ECX);  // Shift count in CL.
          __ shll(left_lo, ECX);            // Shift count in CL.
          // Check for overflow by shifting back the high 32 bits
          // and comparing with the input.
          __ movl(temp2, left_hi);
          __ sarl(temp2, ECX);
          __ cmpl(temp1, temp2);
          __ j(NOT_EQUAL, deopt);
          __ jmp(&done, Assembler::kNearJump);

          __ Bind(&large_shift);
          // No need to subtract 32 from CL, only 5 bits used by shll.
          __ movl(left_hi, left_lo);  // Shift by 32.
          __ shll(left_hi, ECX);      // Shift count: CL % 32.
          // Check for overflow by sign extending the high 32 bits
          // and comparing with the input.
          __ movl(temp2, left_hi);
          __ sarl(temp2, Immediate(31));
          __ cmpl(temp1, temp2);
          __ j(NOT_EQUAL, deopt);
          // Also compare low word from input with high word from
          // output shifted back shift - 32.
          __ movl(temp2, left_hi);
          __ sarl(temp2, ECX);  // Shift count: CL % 32.
          __ cmpl(left_lo, temp2);
          __ j(NOT_EQUAL, deopt);
          __ xorl(left_lo, left_lo);  // Zero left_lo.
        } else {
          __ cmpl(ECX, Immediate(31));
          __ j(ABOVE, &large_shift);

          __ shldl(left_hi, left_lo, ECX);  // Shift count in CL.
          __ shll(left_lo, ECX);            // Shift count in CL.
          __ jmp(&done, Assembler::kNearJump);

          __ Bind(&large_shift);
          // No need to subtract 32 from CL, only 5 bits used by shll.
          __ movl(left_hi, left_lo);  // Shift by 32.
          __ xorl(left_lo, left_lo);  // Zero left_lo.
          __ shll(left_hi, ECX);      // Shift count: CL % 32.
        }
        break;
      }
      default:
        UNREACHABLE();
    }
    __ Bind(&done);
  }
}

LocationSummary* UnaryInt64OpInstr::MakeLocationSummary(Zone* zone,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                    Location::RequiresRegister()));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryInt64OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(op_kind() == Token::kBIT_NOT);
  PairLocation* left_pair = locs()->in(0).AsPairLocation();
  Register left_lo = left_pair->At(0).reg();
  Register left_hi = left_pair->At(1).reg();
  PairLocation* out_pair = locs()->out(0).AsPairLocation();
  Register out_lo = out_pair->At(0).reg();
  Register out_hi = out_pair->At(1).reg();
  ASSERT(out_lo == left_lo);
  ASSERT(out_hi == left_hi);
  __ notl(left_lo);
  __ notl(left_hi);
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

LocationSummary* ShiftUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::FixedRegisterOrSmiConstant(right(), ECX));
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void ShiftUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const intptr_t kShifterLimit = 31;

  Register left = locs()->in(0).reg();
  Register out = locs()->out(0).reg();
  ASSERT(left == out);

  Label* deopt =
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinaryInt64Op);

  if (locs()->in(1).IsConstant()) {
    // Shifter is constant.

    const Object& constant = locs()->in(1).constant();
    ASSERT(constant.IsSmi());
    const intptr_t shift_value = Smi::Cast(constant).Value();

    // Do the shift: (shift_value > 0) && (shift_value <= kShifterLimit).
    switch (op_kind()) {
      case Token::kSHR:
        __ shrl(left, Immediate(shift_value));
        break;
      case Token::kSHL:
        __ shll(left, Immediate(shift_value));
        break;
      default:
        UNREACHABLE();
    }
    return;
  }

  // Non constant shift value.

  Register shifter = locs()->in(1).reg();
  ASSERT(shifter == ECX);

  Label done;
  Label zero;

  // TODO(johnmccutchan): Use range information to avoid these checks.
  __ SmiUntag(shifter);
  __ cmpl(shifter, Immediate(0));
  // If shift value is < 0, deoptimize.
  __ j(NEGATIVE, deopt);
  __ cmpl(shifter, Immediate(kShifterLimit));
  // If shift value is >= 32, return zero.
  __ j(ABOVE, &zero);

  // Do the shift.
  switch (op_kind()) {
    case Token::kSHR:
      __ shrl(left, shifter);
      __ jmp(&done);
      break;
    case Token::kSHL:
      __ shll(left, shifter);
      __ jmp(&done);
      break;
    default:
      UNREACHABLE();
  }

  __ Bind(&zero);
  // Shift was greater than 31 bits, just return zero.
  __ xorl(left, left);

  // Exit path.
  __ Bind(&done);
}

LocationSummary* UnaryUint32OpInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::SameAsFirstInput());
  return summary;
}

void UnaryUint32OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out = locs()->out(0).reg();
  ASSERT(locs()->in(0).reg() == out);

  ASSERT(op_kind() == Token::kBIT_NOT);

  __ notl(out);
}

LocationSummary* UnboxedIntConverterInstr::MakeLocationSummary(Zone* zone,
                                                               bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  if ((from() == kUnboxedInt32 || from() == kUnboxedUint32) &&
      (to() == kUnboxedInt32 || to() == kUnboxedUint32)) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::SameAsFirstInput());
  } else if (from() == kUnboxedInt64) {
    summary->set_in(
        0, Location::Pair(CanDeoptimize() ? Location::WritableRegister()
                                          : Location::RequiresRegister(),
                          Location::RequiresRegister()));
    summary->set_out(0, Location::RequiresRegister());
  } else if (from() == kUnboxedUint32) {
    summary->set_in(0, Location::RequiresRegister());
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
  } else if (from() == kUnboxedInt32) {
    summary->set_in(0, Location::RegisterLocation(EAX));
    summary->set_out(0, Location::Pair(Location::RegisterLocation(EAX),
                                       Location::RegisterLocation(EDX)));
  }
  return summary;
}

void UnboxedIntConverterInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (from() == kUnboxedInt32 && to() == kUnboxedUint32) {
    // Representations are bitwise equivalent.
    ASSERT(locs()->out(0).reg() == locs()->in(0).reg());
  } else if (from() == kUnboxedUint32 && to() == kUnboxedInt32) {
    // Representations are bitwise equivalent.
    ASSERT(locs()->out(0).reg() == locs()->in(0).reg());
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ testl(locs()->out(0).reg(), locs()->out(0).reg());
      __ j(NEGATIVE, deopt);
    }
  } else if (from() == kUnboxedInt64) {
    // TODO(vegorov) kUnboxedInt64 -> kInt32 conversion is currently usually
    // dominated by a CheckSmi(BoxInt64(val)) which is an artifact of ordering
    // of optimization passes and the way we check smi-ness of values.
    // Optimize it away.
    ASSERT(to() == kUnboxedInt32 || to() == kUnboxedUint32);
    PairLocation* in_pair = locs()->in(0).AsPairLocation();
    Register in_lo = in_pair->At(0).reg();
    Register in_hi = in_pair->At(1).reg();
    Register out = locs()->out(0).reg();
    // Copy low word.
    __ movl(out, in_lo);
    if (CanDeoptimize()) {
      Label* deopt =
          compiler->AddDeoptStub(deopt_id(), ICData::kDeoptUnboxInteger);
      __ sarl(in_lo, Immediate(31));
      __ cmpl(in_lo, in_hi);
      __ j(NOT_EQUAL, deopt);
    }
  } else if (from() == kUnboxedUint32) {
    ASSERT(to() == kUnboxedInt64);
    Register in = locs()->in(0).reg();
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    // Copy low word.
    __ movl(out_lo, in);
    // Zero upper word.
    __ xorl(out_hi, out_hi);
  } else if (from() == kUnboxedInt32) {
    ASSERT(to() == kUnboxedInt64);
    PairLocation* out_pair = locs()->out(0).AsPairLocation();
    Register out_lo = out_pair->At(0).reg();
    Register out_hi = out_pair->At(1).reg();
    ASSERT(locs()->in(0).reg() == EAX);
    ASSERT(out_lo == EAX && out_hi == EDX);
    __ cdq();
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
  __ int3();
}

LocationSummary* ReThrowInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kCall);
}

void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStackTrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(), deopt_id(), kReThrowRuntimeEntry,
                                2, locs());
  __ int3();
}

LocationSummary* StopInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}

void StopInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Stop(message());
}

void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ jmp(compiler->GetJumpLabel(normal_entry()));
  }
}

LocationSummary* GotoInstr::MakeLocationSummary(Zone* zone, bool opt) const {
  return new (zone) LocationSummary(zone, 0, 0, LocationSummary::kNoCall);
}

void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
    __ jmp(compiler->GetJumpLabel(successor()));
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

  // Load code object from frame.
  __ movl(target_reg, Address(EBP, kPcMarkerSlotFromFp * kWordSize));
  // Load instructions object (active_instructions and Code::entry_point() may
  // not point to this instruction object any more; see Code::DisableDartCode).
  __ movl(target_reg,
          FieldAddress(target_reg, Code::saved_instructions_offset()));
  __ addl(target_reg, Immediate(Instructions::HeaderSize() - kHeapObjectTag));

  // Add the offset.
  Register offset_reg = locs()->in(0).reg();
  if (offset()->definition()->representation() == kTagged) {
    __ SmiUntag(offset_reg);
  }
  __ addl(target_reg, offset_reg);

  // Jump to the absolute address.
  __ jmp(target_reg);
}

LocationSummary* StrictCompareInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new (zone)
        LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(EAX));
    locs->set_in(1, Location::RegisterLocation(ECX));
    locs->set_out(0, Location::RegisterLocation(EAX));
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
        right.reg(), left.constant(), needs_number_check(), token_pos(),
        deopt_id_);
  } else if (right.IsConstant()) {
    true_condition = compiler->EmitEqualityRegConstCompare(
        left.reg(), right.constant(), needs_number_check(), token_pos(),
        deopt_id_);
  } else {
    true_condition = compiler->EmitEqualityRegRegCompare(
        left.reg(), right.reg(), needs_number_check(), token_pos(), deopt_id_);
  }
  if (kind() != Token::kEQ_STRICT) {
    ASSERT(kind() == Token::kNE_STRICT);
    true_condition = NegateCondition(true_condition);
  }
  return true_condition;
}

// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}

LocationSummary* IfThenElseInstr::MakeLocationSummary(Zone* zone,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // TODO(dartbug.com/30953): support byte register constraints in the
  // register allocator.
  comparison()->locs()->set_out(0, Location::RegisterLocation(EDX));
  return comparison()->locs();
}

void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->out(0).reg() == EDX);

  // Clear upper part of the out register. We are going to use setcc on it
  // which is a byte move.
  __ xorl(EDX, EDX);

  // Emit comparison code. This must not overwrite the result register.
  // IfThenElseInstr::Supports() should prevent EmitComparisonCode from using
  // the labels or returning an invalid condition.
  BranchLabels labels = {NULL, NULL, NULL};
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);
  ASSERT(true_condition != INVALID_CONDITION);

  const bool is_power_of_two_kind = IsPowerOfTwoKind(if_true_, if_false_);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if (is_power_of_two_kind) {
    if (true_value == 0) {
      // We need to have zero in EDX on true_condition.
      true_condition = NegateCondition(true_condition);
    }
  } else {
    if (true_value == 0) {
      // Swap values so that false_value is zero.
      intptr_t temp = true_value;
      true_value = false_value;
      false_value = temp;
    } else {
      true_condition = NegateCondition(true_condition);
    }
  }

  __ setcc(true_condition, DL);

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ shll(EDX, Immediate(shift + kSmiTagSize));
  } else {
    __ decl(EDX);
    __ andl(EDX,
            Immediate(Smi::RawValue(true_value) - Smi::RawValue(false_value)));
    if (false_value != 0) {
      __ addl(EDX, Immediate(Smi::RawValue(false_value)));
    }
  }
}

LocationSummary* ClosureCallInstr::MakeLocationSummary(Zone* zone,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new (zone)
      LocationSummary(zone, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(EAX));  // Function.
  summary->set_out(0, Location::RegisterLocation(EAX));
  return summary;
}

void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor.
  const intptr_t argument_count = ArgumentCount();  // Includes type args.
  const Array& arguments_descriptor =
      Array::ZoneHandle(Z, GetArgumentsDescriptor());
  __ LoadObject(EDX, arguments_descriptor);

  // EBX: Code (compiled code or lazy compile stub).
  ASSERT(locs()->in(0).reg() == EAX);
  __ movl(EBX, FieldAddress(EAX, Function::entry_point_offset()));

  // EAX: Function.
  // EDX: Arguments descriptor array.
  // ECX: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  __ xorl(ECX, ECX);
  __ call(EBX);
  compiler->RecordSafepoint(locs());
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

LocationSummary* BooleanNegateInstr::MakeLocationSummary(Zone* zone,
                                                         bool opt) const {
  return LocationSummary::Make(zone, 1, Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}

void BooleanNegateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  Label done;
  __ LoadObject(result, Bool::True());
  __ CompareRegisters(result, value);
  __ j(NOT_EQUAL, &done, Assembler::kNearJump);
  __ LoadObject(result, Bool::False());
  __ Bind(&done);
}

LocationSummary* AllocateObjectInstr::MakeLocationSummary(Zone* zone,
                                                          bool opt) const {
  return MakeCallSummary(zone);
}

void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
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
  __ Call(*StubCode::DebugStepCheck_entry());
  compiler->AddCurrentDescriptor(stub_kind_, deopt_id_, token_pos());
  compiler->RecordSafepoint(locs());
}

}  // namespace dart

#undef __

#endif  // defined(TARGET_ARCH_IA32) && !defined(DART_PRECOMPILED_RUNTIME)
