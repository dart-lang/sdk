// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/intermediate_language.h"

#include "vm/dart_entry.h"
#include "vm/flow_graph.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/locations.h"
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
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, use_osr);

// Generic summary for call instructions that have all arguments pushed
// on the stack and return the result in a fixed register V0.
LocationSummary* Instruction::MakeCallSummary() {
  Isolate* isolate = Isolate::Current();
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RegisterLocation(V0));
  return result;
}


LocationSummary* PushArgumentInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps= 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::AnyOrConstant(value()));
  return locs;
}


void PushArgumentInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // In SSA mode, we need an explicit push. Nothing to do in non-SSA mode
  // where PushArgument is handled by BindInstr::EmitNativeCode.
  __ TraceSimMsg("PushArgumentInstr");
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


LocationSummary* ReturnInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RegisterLocation(V0));
  return locs;
}


// Attempt optimized compilation at return instruction instead of at the entry.
// The entry needs to be patchable, no inlined objects are allowed in the area
// that will be overwritten by the patch instructions: a branch macro sequence.
void ReturnInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("ReturnInstr");
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
  __ TraceSimMsg("Stack Check");
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ subu(CMPRES1, SP, FP);

  __ BranchEqual(CMPRES1, fp_sp_dist, &stack_ok);
  __ break_(0);

  __ Bind(&stack_ok);
#endif
  __ LeaveDartFrameAndReturn();
}


static Condition NegateCondition(Condition condition) {
  switch (condition) {
    case EQ: return NE;
    case NE: return EQ;
    case LT: return GE;
    case LE: return GT;
    case GT: return LE;
    case GE: return LT;
    default:
      OS::Print("Error: Condition not recognized: %d\n", condition);
      UNIMPLEMENTED();
      return EQ;
  }
}


// Detect pattern when one value is zero and another is a power of 2.
static bool IsPowerOfTwoKind(intptr_t v1, intptr_t v2) {
  return (Utils::IsPowerOfTwo(v1) && (v2 == 0)) ||
         (Utils::IsPowerOfTwo(v2) && (v1 == 0));
}


LocationSummary* IfThenElseInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  comparison()->InitializeLocationSummary(isolate, opt);
  return comparison()->locs();
}


void IfThenElseInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const Register result = locs()->out(0).reg();

  Location left = locs()->in(0);
  Location right = locs()->in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  // Clear out register.
  __ mov(result, ZR);

  // Emit comparison code. This must not overwrite the result register.
  BranchLabels labels = { NULL, NULL, NULL };
  Condition true_condition = comparison()->EmitComparisonCode(compiler, labels);

  const bool is_power_of_two_kind = IsPowerOfTwoKind(if_true_, if_false_);

  intptr_t true_value = if_true_;
  intptr_t false_value = if_false_;

  if (is_power_of_two_kind) {
    if (true_value == 0) {
      // We need to have zero in result on true_condition.
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

  switch (true_condition) {
    case EQ:
      __ xor_(result, CMPRES1, CMPRES2);
      __ xori(result, result, Immediate(1));
      break;
    case NE:
      __ xor_(result, CMPRES1, CMPRES2);
      break;
    case GT:
      __ mov(result, CMPRES2);
      break;
    case GE:
      __ xori(result, CMPRES1, Immediate(1));
      break;
    case LT:
      __ mov(result, CMPRES1);
      break;
    case LE:
      __ xori(result, CMPRES2, Immediate(1));
      break;
    default:
      UNREACHABLE();
      break;
  }

  if (is_power_of_two_kind) {
    const intptr_t shift =
        Utils::ShiftForPowerOfTwo(Utils::Maximum(true_value, false_value));
    __ sll(result, result, shift + kSmiTagSize);
  } else {
    __ AddImmediate(result, result, -1);
    const int32_t val =
        Smi::RawValue(true_value) - Smi::RawValue(false_value);
    __ AndImmediate(result, result, val);
    if (false_value != 0) {
      __ AddImmediate(result, result, Smi::RawValue(false_value));
    }
  }
}


LocationSummary* ClosureCallInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(T0));  // Function.
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void ClosureCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // Load arguments descriptor in S4.
  int argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  __ LoadObject(S4, arguments_descriptor);

  // Load closure function code in T2.
  // S4: arguments descriptor array.
  // S5: Smi 0 (no IC data; the lazy-compile stub expects a GC-safe value).
  ASSERT(locs()->in(0).reg() == T0);
  __ LoadImmediate(S5, 0);
  __ lw(T2, FieldAddress(T0, Function::instructions_offset()));
  __ AddImmediate(T2, Instructions::HeaderSize() - kHeapObjectTag);
  __ jalr(T2);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kClosureCall,
                                 deopt_id(),
                                 token_pos());
  compiler->RecordSafepoint(locs());
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Isolate::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after, token_pos());
  } else {
    // Add deoptimization continuation point after the call and before the
    // arguments are removed.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   deopt_id_after,
                                   token_pos());
  }
  __ Drop(argument_count);
}


LocationSummary* LoadLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("LoadLocalInstr");
  Register result = locs()->out(0).reg();
  __ lw(result, Address(FP, local().index() * kWordSize));
}


LocationSummary* StoreLocalInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  return LocationSummary::Make(isolate,
                               1,
                               Location::SameAsFirstInput(),
                               LocationSummary::kNoCall);
}


void StoreLocalInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StoreLocalInstr");
  Register value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  ASSERT(result == value);  // Assert that register assignment is correct.
  __ sw(value, Address(FP, local().index() * kWordSize));
}


LocationSummary* ConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void ConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    __ TraceSimMsg("ConstantInstr");
    Register result = locs()->out(0).reg();
    __ LoadObject(result, value());
  }
}


LocationSummary* UnboxedConstantInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_out(0, Location::RequiresFpuRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void UnboxedConstantInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(representation_ == kUnboxedDouble);
  // The register allocator drops constant definitions that have no uses.
  if (!locs()->out(0).IsInvalid()) {
    ASSERT(value().IsDouble());
    const Register const_value = locs()->temp(0).reg();
    const DRegister result = locs()->out(0).fpu_reg();
    __ LoadObject(const_value, value());
    __ LoadDFromOffset(result, const_value,
        Double::value_offset() - kHeapObjectTag);
  }
}


LocationSummary* AssertAssignableInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));  // Value.
  summary->set_in(1, Location::RegisterLocation(A2));  // Instantiator.
  summary->set_in(2, Location::RegisterLocation(A1));  // Type arguments.
  summary->set_out(0, Location::RegisterLocation(A0));
  return summary;
}


LocationSummary* AssertBooleanInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(A0));
  locs->set_out(0, Location::RegisterLocation(A0));
  return locs;
}


static void EmitAssertBoolean(Register reg,
                              intptr_t token_pos,
                              intptr_t deopt_id,
                              LocationSummary* locs,
                              FlowGraphCompiler* compiler) {
  // Check that the type of the value is allowed in conditional context.
  // Call the runtime if the object is not bool::true or bool::false.
  ASSERT(locs->always_calls());
  Label done;
  __ BranchEqual(reg, Bool::True(), &done);
  __ BranchEqual(reg, Bool::False(), &done);

  __ Push(reg);  // Push the source object.
  compiler->GenerateRuntimeCall(token_pos,
                                deopt_id,
                                kNonBoolTypeErrorRuntimeEntry,
                                1,
                                locs);
  // We should never return here.
  __ break_(0);
  __ Bind(&done);
}


void AssertBooleanInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register obj = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ TraceSimMsg("AssertBooleanInstr");
  EmitAssertBoolean(obj, token_pos(), deopt_id(), locs(), compiler);
  ASSERT(obj == result);
}


LocationSummary* EqualityCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 1;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kSmiCid) {
    const intptr_t kNumTemps = 0;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  __ TraceSimMsg("LoadValueCid");
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


static Condition TokenKindToSmiCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQ;
    case Token::kNE: return NE;
    case Token::kLT: return LT;
    case Token::kGT: return GT;
    case Token::kLTE: return LE;
    case Token::kGTE: return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}


// Branches on condition c assuming comparison results in CMPRES1 and CMPRES2.
static void EmitBranchAfterCompare(
    FlowGraphCompiler* compiler, Condition condition, Label* is_true) {
  switch (condition) {
    case EQ: __ beq(CMPRES1, CMPRES2, is_true); break;
    case NE: __ bne(CMPRES1, CMPRES2, is_true); break;
    case GT: __ bne(CMPRES2, ZR, is_true); break;
    case GE: __ beq(CMPRES1, ZR, is_true); break;
    case LT: __ bne(CMPRES1, ZR, is_true); break;
    case LE: __ beq(CMPRES2, ZR, is_true); break;
    default:
      UNREACHABLE();
      break;
  }
}


static Condition FlipCondition(Condition condition) {
  switch (condition) {
    case EQ: return EQ;
    case NE: return NE;
    case LT: return GT;
    case LE: return GE;
    case GT: return LT;
    case GE: return LE;
    default:
      UNREACHABLE();
      return EQ;
  }
}


// The comparison result is in CMPRES1/CMPRES2.
static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  __ TraceSimMsg("ControlInstruction::EmitBranchOnCondition");
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    EmitBranchAfterCompare(compiler, true_condition, labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    Condition false_condition = NegateCondition(true_condition);
    EmitBranchAfterCompare(compiler, false_condition, labels.false_label);
    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ b(labels.true_label);
    }
  }
}


static Condition EmitSmiComparisonOp(FlowGraphCompiler* compiler,
                                     const LocationSummary& locs,
                                     Token::Kind kind,
                                     BranchLabels labels) {
  __ TraceSimMsg("EmitSmiComparisonOp");
  __ Comment("EmitSmiComparisonOp");
  Location left = locs.in(0);
  Location right = locs.in(1);
  ASSERT(!left.IsConstant() || !right.IsConstant());

  Condition true_condition = TokenKindToSmiCondition(kind);

  if (left.IsConstant()) {
    __ CompareObject(CMPRES1, CMPRES2, right.reg(), left.constant());
    true_condition = FlipCondition(true_condition);
  } else if (right.IsConstant()) {
    __ CompareObject(CMPRES1, CMPRES2, left.reg(), right.constant());
  } else {
    __ slt(CMPRES1, left.reg(), right.reg());
    __ slt(CMPRES2, right.reg(), left.reg());
  }
  return true_condition;
}


static Condition TokenKindToDoubleCondition(Token::Kind kind) {
  switch (kind) {
    case Token::kEQ: return EQ;
    case Token::kNE: return NE;
    case Token::kLT: return LT;
    case Token::kGT: return GT;
    case Token::kLTE: return LE;
    case Token::kGTE: return GE;
    default:
      UNREACHABLE();
      return VS;
  }
}


static Condition EmitDoubleComparisonOp(FlowGraphCompiler* compiler,
                                        const LocationSummary& locs,
                                        Token::Kind kind,
                                        BranchLabels labels) {
  DRegister left = locs.in(0).fpu_reg();
  DRegister right = locs.in(1).fpu_reg();

  __ Comment("DoubleComparisonOp(left=%d, right=%d)", left, right);

  Condition true_condition = TokenKindToDoubleCondition(kind);
  __ cund(left, right);
  Label* nan_label = (true_condition == NE)
      ? labels.true_label : labels.false_label;
  __ bc1t(nan_label);

  switch (true_condition) {
    case EQ: __ ceqd(left, right); break;
    case NE: __ ceqd(left, right); break;
    case LT: __ coltd(left, right); break;
    case LE: __ coled(left, right); break;
    case GT: __ coltd(right, left); break;
    case GE: __ coled(right, left); break;
    default: {
      // We should only be passing the above conditions to this function.
      UNREACHABLE();
      break;
    }
  }

  // Ordering is expected to be described by CMPRES1, CMPRES2.
  __ LoadImmediate(TMP, 1);
  if (true_condition == NE) {
    __ movf(CMPRES1, ZR);
    __ movt(CMPRES1, TMP);
  } else {
    __ movf(CMPRES1, TMP);
    __ movt(CMPRES1, ZR);
  }
  __ mov(CMPRES2, ZR);
  return EQ;
}


Condition EqualityCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                   BranchLabels labels) {
  if (operation_cid() == kSmiCid) {
    return EmitSmiComparisonOp(compiler, *locs(), kind(), labels);
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void EqualityCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));
  __ Comment("EqualityCompareInstr");

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
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
  __ TraceSimMsg("EqualityCompareInstr");
  __ Comment("EqualityCompareInstr:BranchCode");
  ASSERT((kind() == Token::kNE) || (kind() == Token::kEQ));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* TestSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                   bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    const int32_t imm =
        reinterpret_cast<int32_t>(right.constant().raw());
    __ AndImmediate(CMPRES1, left, imm);
  } else {
    __ and_(CMPRES1, left, right.reg());
  }
  __ mov(CMPRES2, ZR);
  Condition true_condition = (kind() == Token::kNE) ? NE : EQ;
  return true_condition;
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


LocationSummary* TestCidsInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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

  Label* deopt = CanDeoptimize() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptTestCids) : NULL;

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
    __ BranchEqual(cid_reg, test_cid,
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
  // Dummy result as the last instruction is a jump, any conditional
  // branch using the result will therefore be skipped.
  return EQ;
}


void TestCidsInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                   BranchInstr* branch) {
  BranchLabels labels = compiler->CreateBranchLabels(branch);
  EmitComparisonCode(compiler, labels);
}


void TestCidsInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register result_reg = locs()->out(0).reg();
  Label is_true, is_false, done;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  EmitComparisonCode(compiler, labels);
  __ Bind(&is_false);
  __ LoadObject(result_reg, Bool::False());
  __ b(&done);
  __ Bind(&is_true);
  __ LoadObject(result_reg, Bool::True());
  __ Bind(&done);
}


LocationSummary* RelationalOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (operation_cid() == kMintCid) {
    const intptr_t kNumTemps = 2;
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    locs->set_in(0, Location::RequiresFpuRegister());
    locs->set_in(1, Location::RequiresFpuRegister());
    locs->set_temp(0, Location::RequiresRegister());
    locs->set_temp(1, Location::RequiresRegister());
    locs->set_out(0, Location::RequiresRegister());
    return locs;
  }
  if (operation_cid() == kDoubleCid) {
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresFpuRegister());
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_out(0, Location::RequiresRegister());
    return summary;
  }
  ASSERT(operation_cid() == kSmiCid);
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  } else {
    ASSERT(operation_cid() == kDoubleCid);
    return EmitDoubleComparisonOp(compiler, *locs(), kind(), labels);
  }
}


void RelationalOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("RelationalOpInstr");

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
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
  __ TraceSimMsg("RelationalOpInstr");

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* NativeCallInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(A1));
  locs->set_temp(1, Location::RegisterLocation(A2));
  locs->set_temp(2, Location::RegisterLocation(T5));
  locs->set_out(0, Location::RegisterLocation(V0));
  return locs;
}


void NativeCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("NativeCallInstr");
  ASSERT(locs()->temp(0).reg() == A1);
  ASSERT(locs()->temp(1).reg() == A2);
  ASSERT(locs()->temp(2).reg() == T5);
  Register result = locs()->out(0).reg();

  // Push the result place holder initialized to NULL.
  __ PushObject(Object::null_object());
  // Pass a pointer to the first argument in A2.
  if (!function().HasOptionalParameters()) {
    __ AddImmediate(A2, FP, (kParamEndSlotFromFp +
                             function().NumParameters()) * kWordSize);
  } else {
    __ AddImmediate(A2, FP, kFirstLocalSlotFromFp * kWordSize);
  }
  // Compute the effective address. When running under the simulator,
  // this is a redirection address that forces the simulator to call
  // into the runtime system.
  uword entry = reinterpret_cast<uword>(native_c_function());
  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());
  const bool is_leaf_call =
    (argc_tag & NativeArguments::AutoSetupScopeMask()) == 0;
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel* stub_entry;
  if (is_bootstrap_native() || is_leaf_call) {
    stub_entry = &stub_code->CallBootstrapCFunctionLabel();
#if defined(USING_SIMULATOR)
    entry = Simulator::RedirectExternalReference(
        entry, Simulator::kBootstrapNativeCall, function().NumParameters());
#endif
  } else {
    // In the case of non bootstrap native methods the CallNativeCFunction
    // stub generates the redirection address when running under the simulator
    // and hence we do not change 'entry' here.
    stub_entry = &stub_code->CallNativeCFunctionLabel();
#if defined(USING_SIMULATOR)
    if (!function().IsNativeAutoSetupScope()) {
      entry = Simulator::RedirectExternalReference(
          entry, Simulator::kBootstrapNativeCall, function().NumParameters());
    }
#endif
  }
  __ LoadImmediate(T5, entry);
  __ LoadImmediate(A1, argc_tag);
  compiler->GenerateCall(token_pos(),
                         stub_entry,
                         RawPcDescriptors::kOther,
                         locs());
  __ Pop(result);
}


LocationSummary* StringFromCharCodeInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 1;
  // TODO(fschneider): Allow immediate operands for the char code.
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringFromCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register char_code = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ TraceSimMsg("StringFromCharCodeInstr");

  __ LoadImmediate(result,
                   reinterpret_cast<uword>(Symbols::PredefinedAddress()));
  __ AddImmediate(result, Symbols::kNullCharCodeSymbolOffset * kWordSize);
  __ sll(TMP, char_code, 1);  // Char code is a smi.
  __ addu(TMP, TMP, result);
  __ lw(result, Address(TMP));
}


LocationSummary* StringToCharCodeInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void StringToCharCodeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StringToCharCodeInstr");

  ASSERT(cid_ == kOneByteStringCid);
  Register str = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  Label done, is_one;
  __ lw(result, FieldAddress(str, String::length_offset()));
  __ BranchEqual(result, Smi::RawValue(1), &is_one);
  __ LoadImmediate(result, Smi::RawValue(-1));
  __ b(&done);
  __ Bind(&is_one);
  __ lbu(result, FieldAddress(str, OneByteString::data_offset()));
  __ SmiTag(result);
  __ Bind(&done);
}


LocationSummary* StringInterpolateInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void StringInterpolateInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register array = locs()->in(0).reg();
  __ Push(array);
  const int kNumberOfArguments = 1;
  const Array& kNoArgumentNames = Object::null_array();
  compiler->GenerateStaticCall(deopt_id(),
                               token_pos(),
                               CallFunction(),
                               kNumberOfArguments,
                               kNoArgumentNames,
                               locs(),
                               ICData::Handle());
  ASSERT(locs()->out(0).reg() == V0);
}


LocationSummary* LoadUntaggedInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadUntaggedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ LoadFromOffset(result, object, offset() - kHeapObjectTag);
}


LocationSummary* LoadClassIdInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  return LocationSummary::Make(isolate,
                               kNumInputs,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void LoadClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register object = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ LoadTaggedClassIdMayBeSmi(result, object);
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
      return CompileType::FromCid(kSmiCid);

    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return Typed32BitIsSmi() ? CompileType::FromCid(kSmiCid)
                                 : CompileType::FromCid(kMintCid);

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
      return kTagged;
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      return Typed32BitIsSmi() ? kTagged : kUnboxedMint;
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
  const int64_t offset = index * scale +
      (is_external ? 0 : (Instance::DataOffsetFor(cid) - kHeapObjectTag));
  if (!Utils::IsInt(32, offset)) {
    return false;
  }
  return Address::CanHoldOffset(static_cast<int32_t>(offset));
}


LocationSummary* LoadIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(0, Location::RequiresRegister());
  if (CanBeImmediateIndex(index(), class_id(), IsExternal())) {
    locs->set_in(1, Location::Constant(index()->definition()->AsConstant()));
  } else {
    locs->set_in(1, Location::RequiresRegister());
  }
  if ((representation() == kUnboxedDouble)    ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)) {
    locs->set_out(0, Location::RequiresFpuRegister());
  } else {
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}


void LoadIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("LoadIndexedInstr");
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = index.IsRegister()
      ? __ ElementAddressForRegIndex(true,  // Load.
                                     IsExternal(), class_id(), index_scale(),
                                     array, index.reg())
      : __ ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());
  // Warning: element_address may use register TMP as base.

  if ((representation() == kUnboxedDouble) ||
      (representation() == kUnboxedMint) ||
      (representation() == kUnboxedFloat32x4) ||
      (representation() == kUnboxedInt32x4)) {
    DRegister result = locs()->out(0).fpu_reg();
    switch (class_id()) {
      case kTypedDataInt32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataUint32ArrayCid:
        UNIMPLEMENTED();
        break;
      case kTypedDataFloat32ArrayCid:
        // Load single precision float.
        __ lwc1(EvenFRegisterOf(result), element_address);
        break;
      case kTypedDataFloat64ArrayCid:
        __ LoadDFromOffset(result,
                           element_address.base(), element_address.offset());
        break;
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
        UNIMPLEMENTED();
        break;
    }
    return;
  }

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
      ASSERT(index_scale() == 1);
      __ lbu(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt16ArrayCid:
      __ lh(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataUint16ArrayCid:
    case kTwoByteStringCid:
      __ lhu(result, element_address);
      __ SmiTag(result);
      break;
    case kTypedDataInt32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptInt32Load);
        __ lw(result, element_address);
        // Verify that the signed value in 'result' can fit inside a Smi.
        __ BranchSignedLess(result, 0xC0000000, deopt);
        __ SmiTag(result);
      }
      break;
    case kTypedDataUint32ArrayCid: {
        Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                              ICData::kDeoptUint32Load);
        __ lw(result, element_address);
        // Verify that the unsigned value in 'result' can fit inside a Smi.
        __ LoadImmediate(TMP, 0xC0000000);
        __ and_(CMPRES1, result, TMP);
        __ bne(CMPRES1, ZR, deopt);
        __ SmiTag(result);
      }
      break;
    default:
      ASSERT((class_id() == kArrayCid) || (class_id() == kImmutableArrayCid));
      __ lw(result, element_address);
      break;
  }
}


Representation StoreIndexedInstr::RequiredInputRepresentation(
    intptr_t idx) const {
  // Array can be a Dart object or a pointer to external data.
  if (idx == 0)  return kNoRepresentation;  // Flexible input representation.
  if (idx == 1) return kTagged;  // Index is a smi.
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
    case kTypedDataUint32ArrayCid:
      return value()->IsSmiValue() ? kTagged : kUnboxedMint;
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


LocationSummary* StoreIndexedInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  return locs;
}


void StoreIndexedInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StoreIndexedInstr");
  // The array register points to the backing store for external arrays.
  const Register array = locs()->in(0).reg();
  const Location index = locs()->in(1);

  Address element_address = index.IsRegister()
      ? __ ElementAddressForRegIndex(false,  // Store.
                                     IsExternal(), class_id(), index_scale(),
                                     array, index.reg())
      : __ ElementAddressForIntIndex(
            IsExternal(), class_id(), index_scale(),
            array, Smi::Cast(index.constant()).Value());

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
    case kOneByteStringCid: {
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
        __ BranchUnsignedLess(TMP, 0xFF + 1, &store_value);
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
      __ sh(TMP, element_address);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid: {
      if (value()->IsSmiValue()) {
        ASSERT(RequiredInputRepresentation(2) == kTagged);
        Register value = locs()->in(2).reg();
        __ SmiUntag(TMP, value);
        __ sw(TMP, element_address);
      } else {
        UNIMPLEMENTED();
      }
      break;
    }
    case kTypedDataFloat32ArrayCid: {
      FRegister value = EvenFRegisterOf(locs()->in(2).fpu_reg());
      __ swc1(value, element_address);
      break;
    }
    case kTypedDataFloat64ArrayCid:
      __ StoreDToOffset(locs()->in(2).fpu_reg(),
                        element_address.base(), element_address.offset());
      break;
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
      UNIMPLEMENTED();
      break;
    default:
      UNREACHABLE();
  }
}


LocationSummary* GuardFieldClassInstr::MakeLocationSummary(Isolate* isolate,
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

  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, num_temps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());

  for (intptr_t i = 0; i < num_temps; i++) {
    summary->set_temp(i, Location::RequiresRegister());
  }

  return summary;
}


void GuardFieldClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("GuardFieldClassInstr");

  const intptr_t value_cid = value()->Type()->ToCid();
  const intptr_t field_cid = field().guarded_cid();
  const intptr_t nullability = field().is_nullable() ? kNullCid : kIllegalCid;

  if (field_cid == kDynamicCid) {
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  const bool emit_full_guard =
      !compiler->is_optimizing() || (field_cid == kIllegalCid);

  const bool needs_value_cid_temp_reg =
      (value_cid == kDynamicCid) && (emit_full_guard || (field_cid != kSmiCid));

  const bool needs_field_temp_reg = emit_full_guard;

  const Register value_reg = locs()->in(0).reg();

  const Register value_cid_reg = needs_value_cid_temp_reg ?
      locs()->temp(0).reg() : kNoRegister;

  const Register field_reg = needs_field_temp_reg ?
      locs()->temp(locs()->temp_count() - 1).reg() : kNoRegister;

  Label ok, fail_label;

  Label* deopt = compiler->is_optimizing() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField) : NULL;

  Label* fail = (deopt != NULL) ? deopt : &fail_label;

  if (emit_full_guard) {
    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    FieldAddress field_cid_operand(field_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(
        field_reg, Field::is_nullable_offset());

    if (value_cid == kDynamicCid) {
      LoadValueCid(compiler, value_cid_reg, value_reg);

      __ lw(CMPRES1, field_cid_operand);
      __ beq(value_cid_reg, CMPRES1, &ok);
      __ lw(TMP, field_nullability_operand);
      __ subu(CMPRES1, value_cid_reg, TMP);
    } else if (value_cid == kNullCid) {
      __ lw(TMP, field_nullability_operand);
      __ LoadImmediate(CMPRES1, value_cid);
      __ subu(CMPRES1, TMP, CMPRES1);
    } else {
      __ lw(TMP, field_cid_operand);
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
      __ lw(CMPRES1, field_cid_operand);
      __ BranchNotEqual(CMPRES1, kIllegalCid, fail);

      if (value_cid == kDynamicCid) {
        __ sw(value_cid_reg, field_cid_operand);
        __ sw(value_cid_reg, field_nullability_operand);
      } else {
        __ LoadImmediate(TMP, value_cid);
        __ sw(TMP, field_cid_operand);
        __ sw(TMP, field_nullability_operand);
      }

      if (deopt == NULL) {
        ASSERT(!compiler->is_optimizing());
        __ b(&ok);
      }
    }

    if (deopt == NULL) {
      ASSERT(!compiler->is_optimizing());
      __ Bind(fail);

      __ lw(CMPRES1, FieldAddress(field_reg, Field::guarded_cid_offset()));
      __ BranchEqual(CMPRES1, kDynamicCid, &ok);

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
          __ LoadImmediate(TMP, reinterpret_cast<int32_t>(Object::null()));
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


LocationSummary* GuardFieldLengthInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  const intptr_t kNumInputs = 1;

  if (!opt || (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    // We need temporaries for field object.
    summary->set_temp(0, Location::RequiresRegister());
    return summary;
  } else {
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, 0, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    return summary;
  }
  UNREACHABLE();
}


void GuardFieldLengthInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (field().guarded_list_length() == Field::kNoFixedLength) {
    ASSERT(!compiler->is_optimizing());
    return;  // Nothing to emit.
  }

  Label* deopt = compiler->is_optimizing() ?
      compiler->AddDeoptStub(deopt_id(), ICData::kDeoptGuardField) : NULL;

  const Register value_reg = locs()->in(0).reg();

  if (!compiler->is_optimizing() ||
      (field().guarded_list_length() == Field::kUnknownFixedLength)) {
    const Register field_reg = locs()->temp(0).reg();

    Label ok;

    __ LoadObject(field_reg, Field::ZoneHandle(field().raw()));

    __ lb(CMPRES1, FieldAddress(field_reg,
        Field::guarded_list_length_in_object_offset_offset()));
    __ blez(CMPRES1, &ok);

    __ lw(CMPRES2, FieldAddress(field_reg,
        Field::guarded_list_length_offset()));

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
      : instruction_(instruction),
        cls_(cls),
        result_(result) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    Isolate* isolate = compiler->isolate();
    StubCode* stub_code = isolate->stub_code();

    if (Assembler::EmittingComments()) {
      __ Comment("%s slow path allocation of %s",
                 instruction_->DebugName(),
                 String::Handle(cls_.PrettyName()).ToCString());
    }
    __ Bind(entry_label());
    const Code& stub =
        Code::Handle(isolate, stub_code->GetAllocationStubForClass(cls_));
    const ExternalLabel label(stub.EntryPoint());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(Location::RegisterLocation(result_));

    compiler->SaveLiveRegisters(locs);
    compiler->GenerateCall(Scanner::kNoSourcePos,  // No token position.
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
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
      __ TryAllocate(cls,
                     compiler->intrinsic_slow_path_label(),
                     result,
                     temp);
    } else {
      BoxAllocationSlowPath* slow_path =
          new BoxAllocationSlowPath(instruction, cls, result);
      compiler->AddSlowPathCode(slow_path);

      __ TryAllocate(cls,
                     slow_path->entry_label(),
                     result,
                     temp);
      __ Bind(slow_path->exit_label());
    }
  }

 private:
  Instruction* instruction_;
  const Class& cls_;
  const Register result_;
};


LocationSummary* StoreInstanceFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      (IsUnboxedStore() && opt) ? 2 :
          ((IsPotentialUnboxedStore()) ? 3 : 0);
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps,
          ((IsUnboxedStore() && opt && is_initialization_) ||
           IsPotentialUnboxedStore())
          ? LocationSummary::kCallOnSlowPath
          : LocationSummary::kNoCall);

  summary->set_in(0, Location::RequiresRegister());
  if (IsUnboxedStore() && opt) {
    summary->set_in(1, Location::RequiresFpuRegister());
    summary->set_temp(0, Location::RequiresRegister());
    summary->set_temp(1, Location::RequiresRegister());
  } else if (IsPotentialUnboxedStore()) {
    summary->set_in(1, ShouldEmitStoreBarrier()
        ? Location::WritableRegister()
        :  Location::RequiresRegister());
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
  __ BranchNotEqual(box_reg, reinterpret_cast<int32_t>(Object::null()),
                    &done);
  BoxAllocationSlowPath::Allocate(compiler, instruction, cls, box_reg, temp);
  __ mov(temp, box_reg);
  __ StoreIntoObjectOffset(instance_reg, offset, temp);
  __ Bind(&done);
}


void StoreInstanceFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label skip_store;

  Register instance_reg = locs()->in(0).reg();

  if (IsUnboxedStore() && compiler->is_optimizing()) {
    DRegister value = locs()->in(1).fpu_reg();
    Register temp = locs()->temp(0).reg();
    Register temp2 = locs()->temp(1).reg();
    const intptr_t cid = field().UnboxedFieldCid();

    if (is_initialization_) {
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

    __ LoadObject(temp, Field::ZoneHandle(field().raw()));

    __ lw(temp2, FieldAddress(temp, Field::is_nullable_offset()));
    __ BranchEqual(temp2, kNullCid, &store_pointer);

    __ lbu(temp2, FieldAddress(temp, Field::kind_bits_offset()));
    __ andi(CMPRES1, temp2, Immediate(1 << Field::kUnboxingCandidateBit));
    __ beq(CMPRES1, ZR, &store_pointer);

    __ lw(temp2, FieldAddress(temp, Field::guarded_cid_offset()));
    __ BranchEqual(temp2, kDoubleCid, &store_double);

    // Fall through.
    __ b(&store_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
      locs()->live_registers()->Add(locs()->in(1));
    }

    {
      __ Bind(&store_double);
      EnsureMutableBox(compiler,
                       this,
                       temp,
                       compiler->double_class(),
                       instance_reg,
                       offset_in_bytes_,
                       temp2);
      __ LoadDFromOffset(fpu_temp,
                         value_reg,
                         Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(fpu_temp, temp,
                        Double::value_offset() - kHeapObjectTag);
      __ b(&skip_store);
    }

    __ Bind(&store_pointer);
  }

  if (ShouldEmitStoreBarrier()) {
    Register value_reg = locs()->in(1).reg();
    __ StoreIntoObjectOffset(instance_reg,
                             offset_in_bytes_,
                             value_reg,
                             CanValueBeSmi());
  } else {
    if (locs()->in(1).IsConstant()) {
      __ StoreIntoObjectNoBarrierOffset(
          instance_reg,
          offset_in_bytes_,
          locs()->in(1).constant());
    } else {
      Register value_reg = locs()->in(1).reg();
      __ StoreIntoObjectNoBarrierOffset(instance_reg,
                                        offset_in_bytes_,
                                        value_reg);
    }
  }
  __ Bind(&skip_store);
}


LocationSummary* LoadStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  __ TraceSimMsg("LoadStaticFieldInstr");
  Register field = locs()->in(0).reg();
  Register result = locs()->out(0).reg();
  __ lw(result, FieldAddress(field, Field::value_offset()));
}


LocationSummary* StoreStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, 1, 1, LocationSummary::kNoCall);
  locs->set_in(0, value()->NeedsStoreBuffer() ? Location::WritableRegister()
                                              : Location::RequiresRegister());
  locs->set_temp(0, Location::RequiresRegister());
  return locs;
}


void StoreStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StoreStaticFieldInstr");
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  __ LoadObject(temp, field());
  if (this->value()->NeedsStoreBuffer()) {
    __ StoreIntoObject(temp,
        FieldAddress(temp, Field::value_offset()), value, CanValueBeSmi());
  } else {
    __ StoreIntoObjectNoBarrier(
        temp, FieldAddress(temp, Field::value_offset()), value);
  }
}


LocationSummary* InstanceOfInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 3;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  summary->set_in(0, Location::RegisterLocation(A0));
  summary->set_in(1, Location::RegisterLocation(A2));
  summary->set_in(2, Location::RegisterLocation(A1));
  summary->set_out(0, Location::RegisterLocation(V0));
  return summary;
}


void InstanceOfInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->in(0).reg() == A0);  // Value.
  ASSERT(locs()->in(1).reg() == A2);  // Instantiator.
  ASSERT(locs()->in(2).reg() == A1);  // Instantiator type arguments.

  __ Comment("InstanceOfInstr");
  compiler->GenerateInstanceOf(token_pos(),
                               deopt_id(),
                               type(),
                               negate_result(),
                               locs());
  ASSERT(locs()->out(0).reg() == V0);
}


LocationSummary* CreateArrayInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  const Register kLengthReg = A1;
  const Register kElemTypeReg = A0;
  const intptr_t instance_size = Array::InstanceSize(num_elements);

  __ TryAllocateArray(kArrayCid, instance_size, slow_path,
                      V0,  // instance
                      T1,  // end address
                      T2,
                      T3);
  // V0: new object start as a tagged pointer.
  // T1: new object end address.

  // Store the type argument field.
  __ StoreIntoObjectNoBarrier(V0,
                              FieldAddress(V0, Array::type_arguments_offset()),
                              kElemTypeReg);

  // Set the length field.
  __ StoreIntoObjectNoBarrier(V0,
                              FieldAddress(V0, Array::length_offset()),
                              kLengthReg);

  // Initialize all array elements to raw_null.
  // V0: new object start as a tagged pointer.
  // T1: new object end address.
  // T2: iterator which initially points to the start of the variable
  // data area to be initialized.
  // T7: null.
  if (num_elements > 0) {
    __ LoadImmediate(T7, reinterpret_cast<int32_t>(Object::null()));
    __ AddImmediate(T2, V0, sizeof(RawArray) - kHeapObjectTag);

    Label init_loop;
    __ Bind(&init_loop);
    __ sw(T7, Address(T2, 0));
    __ addiu(T2, T2, Immediate(kWordSize));
    __ BranchUnsignedLess(T2, T1, &init_loop);
  }
  __ b(done);
}


void CreateArrayInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("CreateArrayInstr");
  const Register kLengthReg = A1;
  const Register kElemTypeReg = A0;
  const Register kResultReg = V0;
  ASSERT(locs()->in(0).reg() == kElemTypeReg);
  ASSERT(locs()->in(1).reg() == kLengthReg);

  Label slow_path, done;
  if (num_elements()->BindsToConstant() &&
      num_elements()->BoundConstant().IsSmi()) {
    const intptr_t length = Smi::Cast(num_elements()->BoundConstant()).Value();
    if ((length >= 0) && (length <= Array::kMaxElements)) {
      Label slow_path, done;
      InlineArrayAllocation(compiler, length, &slow_path, &done);
      __ Bind(&slow_path);
      __ PushObject(Object::null_object());  // Make room for the result.
      __ Push(kLengthReg);  // length.
      __ Push(kElemTypeReg);
      compiler->GenerateRuntimeCall(token_pos(),
                                    deopt_id(),
                                    kAllocateArrayRuntimeEntry,
                                    2,
                                    locs());
      __ Drop(2);
      __ Pop(kResultReg);
      __ Bind(&done);
      return;
    }
  }

  __ Bind(&slow_path);
  StubCode* stub_code = compiler->isolate()->stub_code();
  compiler->GenerateCall(token_pos(),
                         &stub_code->AllocateArrayLabel(),
                         RawPcDescriptors::kOther,
                         locs());
  __ Bind(&done);
  ASSERT(locs()->out(0).reg() == kResultReg);
}


LocationSummary* LoadFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps =
      (IsUnboxedLoad() && opt) ? 1 :
          ((IsPotentialUnboxedLoad()) ? 2 : 0);
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps,
          (opt && !IsPotentialUnboxedLoad())
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
  Register instance_reg = locs()->in(0).reg();
  if (IsUnboxedLoad() && compiler->is_optimizing()) {
    DRegister result = locs()->out(0).fpu_reg();
    Register temp = locs()->temp(0).reg();
    __ lw(temp, FieldAddress(instance_reg, offset_in_bytes()));
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

    __ LoadObject(result_reg, Field::ZoneHandle(field()->raw()));

    FieldAddress field_cid_operand(result_reg, Field::guarded_cid_offset());
    FieldAddress field_nullability_operand(result_reg,
                                           Field::is_nullable_offset());

    __ lw(temp, field_nullability_operand);
    __ BranchEqual(temp, kNullCid, &load_pointer);

    __ lw(temp, field_cid_operand);
    __ BranchEqual(temp, kDoubleCid, &load_double);

    // Fall through.
    __ b(&load_pointer);

    if (!compiler->is_optimizing()) {
      locs()->live_registers()->Add(locs()->in(0));
    }

    {
      __ Bind(&load_double);
      BoxAllocationSlowPath::Allocate(
          compiler, this, compiler->double_class(), result_reg, temp);
      __ lw(temp, FieldAddress(instance_reg, offset_in_bytes()));
      __ LoadDFromOffset(value, temp, Double::value_offset() - kHeapObjectTag);
      __ StoreDToOffset(value,
                        result_reg,
                        Double::value_offset() - kHeapObjectTag);
      __ b(&done);
    }

    __ Bind(&load_pointer);
  }
  __ LoadFromOffset(
      result_reg, instance_reg, offset_in_bytes() - kHeapObjectTag);
  __ Bind(&done);
}


LocationSummary* InstantiateTypeInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("InstantiateTypeInstr");
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  // A runtime call to instantiate the type is required.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 2 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP, type());
  __ sw(TMP, Address(SP, 1 * kWordSize));
  // Push instantiator type arguments.
  __ sw(instantiator_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeRuntimeEntry,
                                2,
                                locs());
  // Pop instantiated type.
  __ lw(result_reg, Address(SP, 2 * kWordSize));
  // Drop instantiator and uninstantiated type.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  ASSERT(instantiator_reg == result_reg);
}


LocationSummary* InstantiateTypeArgumentsInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void InstantiateTypeArgumentsInstr::EmitNativeCode(
    FlowGraphCompiler* compiler) {
  __ TraceSimMsg("InstantiateTypeArgumentsInstr");
  Register instantiator_reg = locs()->in(0).reg();
  Register result_reg = locs()->out(0).reg();
  ASSERT(instantiator_reg == T0);
  ASSERT(instantiator_reg == result_reg);

  // 'instantiator_reg' is the instantiator TypeArguments object (or null).
  ASSERT(!type_arguments().IsUninstantiatedIdentity() &&
         !type_arguments().CanShareInstantiatorTypeArguments(
             instantiator_class()));
  // If the instantiator is null and if the type argument vector
  // instantiated from null becomes a vector of dynamic, then use null as
  // the type arguments.
  Label type_arguments_instantiated;
  const intptr_t len = type_arguments().Length();
  if (type_arguments().IsRawInstantiatedRaw(len)) {
    __ BranchEqual(instantiator_reg, reinterpret_cast<int32_t>(Object::null()),
                   &type_arguments_instantiated);
  }

  __ LoadObject(T2, type_arguments());
  __ lw(T2, FieldAddress(T2, TypeArguments::instantiations_offset()));
  __ AddImmediate(T2, Array::data_offset() - kHeapObjectTag);
  // The instantiations cache is initialized with Object::zero_array() and is
  // therefore guaranteed to contain kNoInstantiator. No length check needed.
  Label loop, found, slow_case;
  __ Bind(&loop);
  __ lw(T1, Address(T2, 0 * kWordSize));  // Cached instantiator.
  __ beq(T1, T0, &found);
  __ BranchNotEqual(T1, Smi::RawValue(StubCode::kNoInstantiator), &loop);
  __ delay_slot()->addiu(T2, T2, Immediate(2 * kWordSize));
  __ b(&slow_case);
  __ Bind(&found);
  __ lw(T0, Address(T2, 1 * kWordSize));  // Cached instantiated args.
  __ b(&type_arguments_instantiated);

  __ Bind(&slow_case);
  // Instantiate non-null type arguments.
  // A runtime call to instantiate the type arguments is required.
  __ addiu(SP, SP, Immediate(-3 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 2 * kWordSize));  // Make room for the result.
  __ LoadObject(TMP, type_arguments());
  __ sw(TMP, Address(SP, 1 * kWordSize));
  // Push instantiator type arguments.
  __ sw(instantiator_reg, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInstantiateTypeArgumentsRuntimeEntry,
                                2,
                                locs());
  // Pop instantiated type arguments.
  __ lw(result_reg, Address(SP, 2 * kWordSize));
  // Drop instantiator and uninstantiated type arguments.
  __ addiu(SP, SP, Immediate(3 * kWordSize));
  __ Bind(&type_arguments_instantiated);
}


LocationSummary* AllocateUninitializedContextInstr::MakeLocationSummary(
    Isolate* isolate,
    bool opt) const {
  ASSERT(opt);
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 3;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCallOnSlowPath);
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
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    __ Comment("AllocateContextSlowPath");
    __ Bind(entry_label());

    LocationSummary* locs = instruction_->locs();
    locs->live_registers()->Remove(locs->out(0));

    compiler->SaveLiveRegisters(locs);

    __ LoadImmediate(T1, instruction_->num_context_variables());
    StubCode* stub_code = compiler->isolate()->stub_code();
    const ExternalLabel label(stub_code->AllocateContextEntryPoint());
    compiler->GenerateCall(instruction_->token_pos(),
                           &label,
                           RawPcDescriptors::kOther,
                           locs);
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
                      temp0,
                      temp1,
                      temp2);

  // Setup up number of context variables field.
  __ LoadImmediate(temp0, num_context_variables());
  __ sw(temp0, FieldAddress(result, Context::num_variables_offset()));

  // Setup isolate field.
  __ lw(temp0, FieldAddress(CTX, Context::isolate_offset()));
  __ sw(temp0, FieldAddress(result, Context::isolate_offset()));

  __ Bind(slow_path->exit_label());
}


LocationSummary* AllocateContextInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_temp(0, Location::RegisterLocation(T1));
  locs->set_out(0, Location::RegisterLocation(V0));
  return locs;
}


void AllocateContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(locs()->temp(0).reg() == T1);
  ASSERT(locs()->out(0).reg() == V0);

  __ TraceSimMsg("AllocateContextInstr");
  __ LoadImmediate(T1, num_context_variables());
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel label(stub_code->AllocateContextEntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
}


LocationSummary* InitStaticFieldInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_temp(0, Location::RegisterLocation(T1));
  return locs;
}


void InitStaticFieldInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register field = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();

  Label call_runtime, no_call;
  __ TraceSimMsg("InitStaticFieldInstr");

  __ lw(temp, FieldAddress(field, Field::value_offset()));
  __ BranchEqual(temp, Object::sentinel(), &call_runtime);
  __ BranchNotEqual(temp, Object::transition_sentinel(), &no_call);

  __ Bind(&call_runtime);
  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());
  __ sw(TMP, Address(SP, 1 * kWordSize));   // Make room for (unused) result.
  __ sw(field, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kInitStaticFieldRuntimeEntry,
                                1,
                                locs());

  __ addiu(SP, SP, Immediate(2 * kWordSize));  // Purge argument and result.

  __ Bind(&no_call);
}


LocationSummary* CloneContextInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
  locs->set_in(0, Location::RegisterLocation(T0));
  locs->set_out(0, Location::RegisterLocation(T0));
  return locs;
}


void CloneContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register context_value = locs()->in(0).reg();
  Register result = locs()->out(0).reg();

  __ TraceSimMsg("CloneContextInstr");

  __ addiu(SP, SP, Immediate(-2 * kWordSize));
  __ LoadObject(TMP, Object::null_object());  // Make room for the result.
  __ sw(TMP, Address(SP, 1 * kWordSize));
  __ sw(context_value, Address(SP, 0 * kWordSize));

  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kCloneContextRuntimeEntry,
                                1,
                                locs());
  __ lw(result, Address(SP, 1 * kWordSize));  // Get result (cloned context).
  __ addiu(SP, SP, Immediate(2 * kWordSize));
}


LocationSummary* CatchBlockEntryInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNREACHABLE();
  return NULL;
}


void CatchBlockEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(),
                                try_index(),
                                compiler->assembler()->CodeSize(),
                                catch_handler_types_,
                                needs_stacktrace());
  // Restore pool pointer.
  __ GetNextPC(CMPRES1, TMP);
  const intptr_t object_pool_pc_dist =
     Instructions::HeaderSize() - Instructions::object_pool_offset() +
     compiler->assembler()->CodeSize() - 1 * Instr::kInstrSize;
  __ LoadFromOffset(PP, CMPRES1, -object_pool_pc_dist);

  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }

  // Restore SP from FP as we are coming from a throw and the code for
  // popping arguments has not been run.
  const intptr_t fp_sp_dist =
      (kFirstLocalSlotFromFp + 1 - compiler->StackSize()) * kWordSize;
  ASSERT(fp_sp_dist <= 0);
  __ AddImmediate(SP, FP, fp_sp_dist);

  // Restore stack and initialize the two exception variables:
  // exception and stack trace variables.
  __ sw(kExceptionObjectReg,
        Address(FP, exception_var().index() * kWordSize));
  __ sw(kStackTraceObjectReg,
        Address(FP, stacktrace_var().index() * kWordSize));
}


LocationSummary* CheckStackOverflowInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  const intptr_t kNumInputs = 0;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_temp(0, Location::RequiresRegister());
  return summary;
}


class CheckStackOverflowSlowPath : public SlowPathCode {
 public:
  explicit CheckStackOverflowSlowPath(CheckStackOverflowInstr* instruction)
      : instruction_(instruction) { }

  virtual void EmitNativeCode(FlowGraphCompiler* compiler) {
    if (FLAG_use_osr) {
      uword flags_address = Isolate::Current()->stack_overflow_flags_address();
      Register value = instruction_->locs()->temp(0).reg();
      __ TraceSimMsg("CheckStackOverflowSlowPathOsr");
      __ Comment("CheckStackOverflowSlowPathOsr");
      __ Bind(osr_entry_label());
      __ LoadImmediate(TMP, flags_address);
      __ LoadImmediate(value, Isolate::kOsrRequest);
      __ sw(value, Address(TMP));
    }
    __ TraceSimMsg("CheckStackOverflowSlowPath");
    __ Comment("CheckStackOverflowSlowPath");
    __ Bind(entry_label());
    compiler->SaveLiveRegisters(instruction_->locs());
    // pending_deoptimization_env_ is needed to generate a runtime call that
    // may throw an exception.
    ASSERT(compiler->pending_deoptimization_env_ == NULL);
    Environment* env = compiler->SlowPathEnvironmentFor(instruction_);
    compiler->pending_deoptimization_env_ = env;
    compiler->GenerateRuntimeCall(instruction_->token_pos(),
                                  instruction_->deopt_id(),
                                  kStackOverflowRuntimeEntry,
                                  0,
                                  instruction_->locs());

    if (FLAG_use_osr && !compiler->is_optimizing() && instruction_->in_loop()) {
      // In unoptimized code, record loop stack checks as possible OSR entries.
      compiler->AddCurrentDescriptor(RawPcDescriptors::kOsrEntry,
                                     instruction_->deopt_id(),
                                     0);  // No token position.
    }
    compiler->pending_deoptimization_env_ = NULL;
    compiler->RestoreLiveRegisters(instruction_->locs());
    __ b(exit_label());
  }

  Label* osr_entry_label() {
    ASSERT(FLAG_use_osr);
    return &osr_entry_label_;
  }

 private:
  CheckStackOverflowInstr* instruction_;
  Label osr_entry_label_;
};


void CheckStackOverflowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("CheckStackOverflowInstr");
  CheckStackOverflowSlowPath* slow_path = new CheckStackOverflowSlowPath(this);
  compiler->AddSlowPathCode(slow_path);

  __ LoadImmediate(TMP, Isolate::Current()->stack_limit_address());
  __ lw(CMPRES1, Address(TMP));
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
    __ BranchSignedGreaterEqual(temp, threshold, slow_path->osr_entry_label());
  }
  if (compiler->ForceSlowPathForStackOverflow()) {
    __ b(slow_path->entry_label());
  }
  __ Bind(slow_path->exit_label());
}


static void EmitSmiShiftLeft(FlowGraphCompiler* compiler,
                             BinarySmiOpInstr* shift_left) {
  const bool is_truncating = shift_left->IsTruncating();
  const LocationSummary& locs = *shift_left->locs();
  Register left = locs.in(0).reg();
  Register result = locs.out(0).reg();
  Label* deopt = shift_left->CanDeoptimize() ?
      compiler->AddDeoptStub(shift_left->deopt_id(), ICData::kDeoptBinarySmiOp)
      : NULL;

  __ TraceSimMsg("EmitSmiShiftLeft");

  if (locs.in(1).IsConstant()) {
    const Object& constant = locs.in(1).constant();
    ASSERT(constant.IsSmi());
    // Immediate shift operation takes 5 bits for the count.
    const intptr_t kCountLimit = 0x1F;
    const intptr_t value = Smi::Cast(constant).Value();
    if (value == 0) {
      if (result != left) {
        __ mov(result, left);
      }
    } else if ((value < 0) || (value >= kCountLimit)) {
      // This condition may not be known earlier in some cases because
      // of constant propagation, inlining, etc.
      if ((value >= kCountLimit) && is_truncating) {
        __ mov(result, ZR);
      } else {
        // Result is Mint or exception.
        __ b(deopt);
      }
    } else {
      if (!is_truncating) {
        // Check for overflow (preserve left).
        __ sll(TMP, left, value);
        __ sra(CMPRES1, TMP, value);
        __ bne(CMPRES1, left, deopt);  // Overflow.
      }
      // Shift for result now we know there is no overflow.
      __ sll(result, left, value);
    }
    return;
  }

  // Right (locs.in(1)) is not constant.
  Register right = locs.in(1).reg();
  Range* right_range = shift_left->right()->definition()->range();
  if (shift_left->left()->BindsToConstant() && !is_truncating) {
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
        __ BranchUnsignedGreaterEqual(
            right, reinterpret_cast<int32_t>(Smi::New(max_right)), deopt);
      }
      __ SmiUntag(TMP, right);
      __ sllv(result, left, TMP);
    }
    return;
  }

  const bool right_needs_check =
      !RangeUtils::IsWithin(right_range, 0, (Smi::kBits - 1));
  if (is_truncating) {
    if (right_needs_check) {
      const bool right_may_be_negative =
          (right_range == NULL) || !right_range->IsPositive();
      if (right_may_be_negative) {
        ASSERT(shift_left->CanDeoptimize());
        __ bltz(right, deopt);
      }
      Label done, is_not_zero;

      __ sltiu(CMPRES1,
          right, Immediate(reinterpret_cast<int32_t>(Smi::New(Smi::kBits))));
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
      ASSERT(shift_left->CanDeoptimize());
      __ BranchUnsignedGreaterEqual(
          right, reinterpret_cast<int32_t>(Smi::New(Smi::kBits)), deopt);
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


LocationSummary* BinarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps =
      ((op_kind() == Token::kADD) ||
       (op_kind() == Token::kMOD) ||
       (op_kind() == Token::kTRUNCDIV) ||
       (((op_kind() == Token::kSHL) && !IsTruncating()) ||
         (op_kind() == Token::kSHR))) ? 1 : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  if (((op_kind() == Token::kSHL) && !IsTruncating()) ||
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
  __ TraceSimMsg("BinarySmiOpInstr");
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
        __ TraceSimMsg("kSUB imm");
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
        if (deopt == NULL) {
          if (value == 2) {
            __ sll(result, left, 1);
          } else {
            __ LoadImmediate(TMP, value);
            __ mult(left, TMP);
            __ mflo(result);
          }
        } else {
          if (value == 2) {
            __ sra(CMPRES2, left, 31);  // CMPRES2 = sign of left.
            __ sll(result, left, 1);
          } else {
            __ LoadImmediate(TMP, value);
            __ mult(left, TMP);
            __ mflo(result);
            __ mfhi(CMPRES2);
          }
          __ sra(CMPRES1, result, 31);
          __ bne(CMPRES1, CMPRES2, deopt);
        }
        break;
      }
      case Token::kTRUNCDIV: {
        const intptr_t value = Smi::Cast(constant).Value();
        if (value == 1) {
          if (result != left) {
            __ mov(result, left);
          }
          break;
        } else if (value == -1) {
          // Check the corner case of dividing the 'MIN_SMI' with -1, in which
          // case we cannot negate the result.
          __ BranchEqual(left, 0x80000000, deopt);
          __ subu(result, ZR, left);
          break;
        }
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
        if (Utils::IsUint(kImmBits, imm)) {
          __ andi(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP, imm);
          __ and_(result, left, TMP);
        }
        break;
      }
      case Token::kBIT_OR: {
        // No overflow check.
        if (Utils::IsUint(kImmBits, imm)) {
          __ ori(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP, imm);
          __ or_(result, left, TMP);
        }
        break;
      }
      case Token::kBIT_XOR: {
        // No overflow check.
        if (Utils::IsUint(kImmBits, imm)) {
          __ xori(result, left, Immediate(imm));
        } else {
          __ LoadImmediate(TMP, imm);
          __ xor_(result, left, TMP);
        }
        break;
      }
      case Token::kSHR: {
        // sarl operation masks the count to 5 bits.
        const intptr_t kCountLimit = 0x1F;
        intptr_t value = Smi::Cast(constant).Value();

        __ TraceSimMsg("kSHR");

        if (value == 0) {
          // TODO(vegorov): should be handled outside.
          if (result != left) {
            __ mov(result, left);
          }
          break;
        } else if (value < 0) {
          // TODO(vegorov): should be handled outside.
          __ b(deopt);
          break;
        }

        value = value + kSmiTagSize;
        if (value >= kCountLimit) {
          value = kCountLimit;
        }

        __ sra(result, left, value);
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
  Range* right_range = this->right()->definition()->range();
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
      __ TraceSimMsg("kSUB");
      if (deopt == NULL) {
        __ subu(result, left, right);
      } else {
        __ SubuDetectOverflow(result, left, right, CMPRES1);
        __ bltz(CMPRES1, deopt);
      }
      break;
    }
    case Token::kMUL: {
      __ TraceSimMsg("kMUL");
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
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      __ BranchEqual(result, 0x40000000, deopt);
      __ SmiTag(result);
      break;
    }
    case Token::kMOD: {
      if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
      if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
        Label subtract;
        __ bltz(right, &subtract);
        __ addu(result, result, TMP);
        __ b(&done);
        __ Bind(&subtract);
        __ subu(result, result, TMP);
      } else if (right_range->IsPositive()) {
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
      if ((right_range == NULL) ||
          !right_range->OnlyLessThanOrEqualTo(kCountLimit)) {
        Label ok;
        __ BranchSignedLessEqual(temp, kCountLimit, &ok);
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


LocationSummary* CheckEitherNonSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  intptr_t left_cid = left()->Type()->ToCid();
  intptr_t right_cid = right()->Type()->ToCid();
  ASSERT((left_cid != kDoubleCid) && (right_cid != kDoubleCid));
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_in(1, Location::RequiresRegister());
  return summary;
}


void CheckEitherNonSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptBinaryDoubleOp);
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


LocationSummary* BoxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs,
                          kNumTemps,
                          LocationSummary::kCallOnSlowPath);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresRegister());
  return summary;
}


void BoxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register out_reg = locs()->out(0).reg();
  DRegister value = locs()->in(0).fpu_reg();

  BoxAllocationSlowPath::Allocate(
      compiler, this, compiler->double_class(), out_reg, locs()->temp(0).reg());
  __ StoreDToOffset(value, out_reg, Double::value_offset() - kHeapObjectTag);
}


LocationSummary* UnboxDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  return summary;
}


void UnboxDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  CompileType* value_type = value()->Type();
  const intptr_t value_cid = value_type->ToCid();
  const Register value = locs()->in(0).reg();
  const DRegister result = locs()->out(0).fpu_reg();

  if (value_cid == kDoubleCid) {
    __ LoadDFromOffset(result, value, Double::value_offset() - kHeapObjectTag);
  } else if (value_cid == kSmiCid) {
    __ SmiUntag(TMP, value);
    __ mtc1(TMP, STMP1);
    __ cvtdw(result, STMP1);
  } else {
    Label* deopt = compiler->AddDeoptStub(deopt_id_,
                                          ICData::kDeoptBinaryDoubleOp);
    if (value_type->is_nullable() &&
        (value_type->ToNullableCid() == kDoubleCid)) {
      __ BranchEqual(value, reinterpret_cast<int32_t>(Object::null()), deopt);
      // It must be double now.
      __ LoadDFromOffset(result, value,
          Double::value_offset() - kHeapObjectTag);
    } else {
      Label is_smi, done;

      __ andi(CMPRES1, value, Immediate(kSmiTagMask));
      __ beq(CMPRES1, ZR, &is_smi);
      __ LoadClassId(CMPRES1, value);
      __ BranchNotEqual(CMPRES1, kDoubleCid, deopt);
      __ LoadDFromOffset(result, value,
          Double::value_offset() - kHeapObjectTag);
      __ b(&done);
      __ Bind(&is_smi);
      __ SmiUntag(TMP, value);
      __ mtc1(TMP, STMP1);
      __ cvtdw(result, STMP1);
      __ Bind(&done);
    }
  }
}


LocationSummary* BoxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxFloat64x2Instr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnboxInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryDoubleOpInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    case Token::kADD: __ addd(result, left, right); break;
    case Token::kSUB: __ subd(result, left, right); break;
    case Token::kMUL: __ muld(result, left, right); break;
    case Token::kDIV: __ divd(result, left, right); break;
    default: UNREACHABLE();
  }
}


LocationSummary* BinaryFloat32x4OpInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryFloat64x2OpInstr::MakeLocationSummary(Isolate* isolate,
                                                             bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryFloat64x2OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}



LocationSummary* Simd32x4ShuffleMixInstr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4ShuffleMixInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ComparisonInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ComparisonInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4MinMaxInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4MinMaxInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4SqrtInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4SqrtInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ScaleInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ScaleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ZeroArgInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ClampInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ClampInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4WithInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4WithInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToInt32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToInt32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd64x2ShuffleInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd64x2ShuffleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
    UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2SplatInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2SplatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ToFloat32x4Instr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float32x4ToFloat64x2Instr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float32x4ToFloat64x2Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2ZeroArgInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2ZeroArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Float64x2OneArgInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Float64x2OneArgInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4ConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4ConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4BoolConstructorInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4BoolConstructorInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4GetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4GetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Simd32x4GetSignMaskInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Simd32x4GetSignMaskInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SelectInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SelectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4SetFlagInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4SetFlagInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* Int32x4ToFloat32x4Instr::MakeLocationSummary(Isolate* isolate,
                                                              bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void Int32x4ToFloat32x4Instr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryInt32x4OpInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryInt32x4OpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* MathUnaryInstr::MakeLocationSummary(Isolate* isolate,
                                                     bool opt) const {
  if ((kind() == MathUnaryInstr::kSin) || (kind() == MathUnaryInstr::kCos)) {
    const intptr_t kNumInputs = 1;
    const intptr_t kNumTemps = 0;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    summary->set_in(0, Location::FpuRegisterLocation(D6));
    summary->set_out(0, Location::FpuRegisterLocation(D0));
    return summary;
  }
  ASSERT((kind() == MathUnaryInstr::kSqrt) ||
         (kind() == MathUnaryInstr::kDoubleSquare));
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
    __ CallRuntime(TargetFunction(), InputCount());
  }
}


LocationSummary* MathMinMaxInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  if (result_cid() == kDoubleCid) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* UnarySmiOpInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* UnaryDoubleOpInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresFpuRegister());
  summary->set_out(0, Location::RequiresFpuRegister());
  summary->set_temp(0, Location::RequiresFpuRegister());
  return summary;
}


void UnaryDoubleOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  // TODO(zra): Implement vneg.
  const Double& minus_one = Double::ZoneHandle(Double::NewCanonical(-1));
  __ LoadObject(TMP, minus_one);
  FpuRegister result = locs()->out(0).fpu_reg();
  FpuRegister value = locs()->in(0).fpu_reg();
  FpuRegister temp_fp = locs()->temp(0).fpu_reg();
  __ LoadDFromOffset(temp_fp, TMP, Double::value_offset() - kHeapObjectTag);
  __ muld(result, value, temp_fp);
}


DEFINE_UNIMPLEMENTED_INSTRUCTION(Int32ToDoubleInstr)


LocationSummary* SmiToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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


LocationSummary* DoubleToIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
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
  __ cvtwd(STMP1, DTMP);
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
  ASSERT((ic_data.NumberOfChecks() == 1));
  const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(0));

  const intptr_t kNumberOfArguments = 1;
  compiler->GenerateStaticCall(deopt_id(),
                               instance_call()->token_pos(),
                               target,
                               kNumberOfArguments,
                               Object::null_array(),  // No argument names.,
                               locs(),
                               ICData::Handle());
  __ Bind(&done);
}


LocationSummary* DoubleToSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::RequiresRegister());
  return result;
}


void DoubleToSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptDoubleToSmi);
  Register result = locs()->out(0).reg();
  DRegister value = locs()->in(0).fpu_reg();
  __ cvtwd(STMP1, value);
  __ mfc1(result, STMP1);

  // Check for overflow and that it fits into Smi.
  __ LoadImmediate(TMP, 0xC0000000);
  __ subu(CMPRES1, result, TMP);
  __ bltz(CMPRES1, deopt);
  __ SmiTag(result);
}


LocationSummary* DoubleToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void DoubleToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* DoubleToFloatInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void DoubleToFloatInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  DRegister value = locs()->in(0).fpu_reg();
  FRegister result = EvenFRegisterOf(locs()->out(0).fpu_reg());
  __ cvtsd(result, value);
}


LocationSummary* FloatToDoubleInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  result->set_in(0, Location::RequiresFpuRegister());
  result->set_out(0, Location::SameAsFirstInput());
  return result;
}


void FloatToDoubleInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  FRegister value = EvenFRegisterOf(locs()->in(0).fpu_reg());
  DRegister result = locs()->out(0).fpu_reg();
  __ cvtds(result, value);
}


LocationSummary* InvokeMathCFunctionInstr::MakeLocationSummary(Isolate* isolate,
                                                               bool opt) const {
  // Calling convention on MIPS uses D6 and D7 to pass the first two
  // double arguments.
  ASSERT((InputCount() == 1) || (InputCount() == 2));
  const intptr_t kNumTemps = 0;
  LocationSummary* result = new(isolate) LocationSummary(
      isolate, InputCount(), kNumTemps, LocationSummary::kCall);
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
  __ LoadImmediate(result, INFINITY);
  // base == -Infinity -> call pow;
  __ ceqd(base, result);
  Label do_pow;
  __ b(&do_pow);

  // exponent == 0.5 ?
  __ LoadImmediate(result, 0.5);
  __ ceqd(base, result);
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


LocationSummary* ExtractNthOutputInstr::MakeLocationSummary(Isolate* isolate,
                                                            bool opt) const {
  // Only use this instruction in optimized code.
  ASSERT(opt);
  const intptr_t kNumInputs = 1;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, 0, LocationSummary::kNoCall);
  if (representation() == kUnboxedDouble) {
    if (index() == 0) {
      summary->set_in(0, Location::Pair(Location::RequiresFpuRegister(),
                                        Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(0, Location::Pair(Location::Any(),
                                        Location::RequiresFpuRegister()));
    }
    summary->set_out(0, Location::RequiresFpuRegister());
  } else {
    ASSERT(representation() == kTagged);
    if (index() == 0) {
      summary->set_in(0, Location::Pair(Location::RequiresRegister(),
                                        Location::Any()));
    } else {
      ASSERT(index() == 1);
      summary->set_in(0, Location::Pair(Location::Any(),
                                        Location::RequiresRegister()));
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


LocationSummary* MergedMathInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  if (kind() == MergedMathInstr::kTruncDivMod) {
    const intptr_t kNumInputs = 2;
    const intptr_t kNumTemps = 1;
    LocationSummary* summary = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
    summary->set_in(0, Location::RequiresRegister());
    summary->set_in(1, Location::RequiresRegister());
    summary->set_temp(0, Location::RequiresRegister());
    // Output is a pair of registers.
    summary->set_out(0, Location::Pair(Location::RequiresRegister(),
                                       Location::RequiresRegister()));
    return summary;
  }
  UNIMPLEMENTED();
  return NULL;
}


void MergedMathInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = NULL;
  if (CanDeoptimize()) {
    deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptBinarySmiOp);
  }
  if (kind() == MergedMathInstr::kTruncDivMod) {
    Register left = locs()->in(0).reg();
    Register right = locs()->in(1).reg();
    Register temp = locs()->temp(0).reg();
    ASSERT(locs()->out(0).IsPairLocation());
    PairLocation* pair = locs()->out(0).AsPairLocation();
    Register result_div = pair->At(0).reg();
    Register result_mod = pair->At(1).reg();
    Range* right_range = InputAt(1)->definition()->range();
    if ((right_range == NULL) || right_range->Overlaps(0, 0)) {
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
    __ BranchEqual(result_div, 0x40000000, deopt);
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
    if ((right_range == NULL) || right_range->Overlaps(-1, 1)) {
      Label subtract;
      __ bltz(right, &subtract);
      __ addu(result_mod, result_mod, TMP);
      __ b(&done);
      __ Bind(&subtract);
      __ subu(result_mod, result_mod, TMP);
    } else if (right_range->IsPositive()) {
      // Right is positive.
      __ addu(result_mod, result_mod, TMP);
    } else {
      // Right is negative.
      __ subu(result_mod, result_mod, TMP);
    }
    __ Bind(&done);

    __ SmiTag(result_div);
    __ SmiTag(result_mod);
    return;
  }
  UNIMPLEMENTED();
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(
    Isolate* isolate, bool opt) const {
  return MakeCallSummary();
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(
      deopt_id(), ICData::kDeoptPolymorphicInstanceCallTestFail);
  __ TraceSimMsg("PolymorphicInstanceCallInstr");
  if (ic_data().NumberOfChecks() == 0) {
    __ b(deopt);
    return;
  }
  ASSERT(ic_data().NumArgsTested() == 1);
  if (!with_checks()) {
    ASSERT(ic_data().HasOneTarget());
    const Function& target = Function::ZoneHandle(ic_data().GetTargetAt(0));
    compiler->GenerateStaticCall(deopt_id(),
                                 instance_call()->token_pos(),
                                 target,
                                 instance_call()->ArgumentCount(),
                                 instance_call()->argument_names(),
                                 locs(),
                                 ICData::Handle());
    return;
  }

  // Load receiver into T0.
  __ lw(T0, Address(SP, (instance_call()->ArgumentCount() - 1) * kWordSize));

  LoadValueCid(compiler, T2, T0,
               (ic_data().GetReceiverClassIdAt(0) == kSmiCid) ? NULL : deopt);

  compiler->EmitTestAndCall(ic_data(),
                            T2,  // Class id register.
                            instance_call()->ArgumentCount(),
                            instance_call()->argument_names(),
                            deopt,
                            deopt_id(),
                            instance_call()->token_pos(),
                            locs());
}


LocationSummary* BranchInstr::MakeLocationSummary(Isolate* isolate,
                                                  bool opt) const {
  comparison()->InitializeLocationSummary(isolate, opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("BranchInstr");
  comparison()->EmitBranchCode(compiler, this);
}


LocationSummary* CheckClassInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  const intptr_t kNumInputs = 1;
  const bool need_mask_temp = IsDenseSwitch() && !IsDenseMask(ComputeCidMask());
  const intptr_t kNumTemps = !IsNullCheck() ? (need_mask_temp ? 2 : 1) : 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  if (!IsNullCheck()) {
    summary->set_temp(0, Location::RequiresRegister());
    if (need_mask_temp) {
      summary->set_temp(1, Location::RequiresRegister());
    }
  }
  return summary;
}


void CheckClassInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  const ICData::DeoptReasonId deopt_reason = licm_hoisted_ ?
      ICData::kDeoptHoistedCheckClass : ICData::kDeoptCheckClass;
  if (IsNullCheck()) {
    Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
    __ BranchEqual(locs()->in(0).reg(),
        reinterpret_cast<int32_t>(Object::null()), deopt);
    return;
  }

  ASSERT((unary_checks().GetReceiverClassIdAt(0) != kSmiCid) ||
         (unary_checks().NumberOfChecks() > 1));
  Register value = locs()->in(0).reg();
  Register temp = locs()->temp(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), deopt_reason);
  Label is_ok;
  intptr_t cix = 0;
  if (unary_checks().GetReceiverClassIdAt(cix) == kSmiCid) {
    __ andi(CMPRES1, value, Immediate(kSmiTagMask));
    __ beq(CMPRES1, ZR, &is_ok);
    cix++;  // Skip first check.
  } else {
    __ andi(CMPRES1, value, Immediate(kSmiTagMask));
    __ beq(CMPRES1, ZR, deopt);
  }
  __ LoadClassId(temp, value);

  if (IsDenseSwitch()) {
    ASSERT(cids_[0] < cids_[cids_.length() - 1]);
    __ LoadImmediate(TMP, cids_[0]);
    __ subu(temp, temp, TMP);
    __ LoadImmediate(TMP, cids_[cids_.length() - 1] - cids_[0]);
    __ BranchUnsignedGreater(temp, TMP, deopt);

    intptr_t mask = ComputeCidMask();
    if (!IsDenseMask(mask)) {
      // Only need mask if there are missing numbers in the range.
      ASSERT(cids_.length() > 2);
      Register mask_reg = locs()->temp(1).reg();
      __ LoadImmediate(mask_reg, 1);
      __ sllv(mask_reg, mask_reg, temp);
      __ AndImmediate(mask_reg, mask_reg, mask);
      __ beq(mask_reg, ZR, deopt);
    }
  } else {
    const intptr_t num_checks = unary_checks().NumberOfChecks();
    for (intptr_t i = cix; i < num_checks; i++) {
      ASSERT(unary_checks().GetReceiverClassIdAt(i) != kSmiCid);
      __ LoadImmediate(TMP, unary_checks().GetReceiverClassIdAt(i));
      __ subu(CMPRES1, temp, TMP);
      if (i == (num_checks - 1)) {
        __ bne(CMPRES1, ZR, deopt);
      } else {
        __ beq(CMPRES1, ZR, &is_ok);
      }
    }
  }
  __ Bind(&is_ok);
}


LocationSummary* CheckSmiInstr::MakeLocationSummary(Isolate* isolate,
                                                    bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckSmiInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("CheckSmiInstr");
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckSmi);
  __ andi(CMPRES1, value, Immediate(kSmiTagMask));
  __ bne(CMPRES1, ZR, deopt);
}


LocationSummary* CheckClassIdInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  const intptr_t kNumInputs = 1;
  const intptr_t kNumTemps = 0;
  LocationSummary* summary = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  summary->set_in(0, Location::RequiresRegister());
  return summary;
}


void CheckClassIdInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Register value = locs()->in(0).reg();
  Label* deopt = compiler->AddDeoptStub(deopt_id(), ICData::kDeoptCheckClass);
  __ BranchNotEqual(value, Smi::RawValue(cid_), deopt);
}


LocationSummary* CheckArrayBoundInstr::MakeLocationSummary(Isolate* isolate,
                                                           bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
  locs->set_in(kLengthPos, Location::RegisterOrSmiConstant(length()));
  locs->set_in(kIndexPos, Location::RegisterOrSmiConstant(index()));
  return locs;
}


void CheckArrayBoundInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  Label* deopt = compiler->AddDeoptStub(deopt_id(),
                                        ICData::kDeoptCheckArrayBound);

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

  if (index_loc.IsConstant()) {
    Register length = length_loc.reg();
    const Smi& index = Smi::Cast(index_loc.constant());
    __ BranchUnsignedLessEqual(
        length, reinterpret_cast<int32_t>(index.raw()), deopt);
  } else if (length_loc.IsConstant()) {
    const Smi& length = Smi::Cast(length_loc.constant());
    Register index = index_loc.reg();
    __ BranchUnsignedGreaterEqual(
        index, reinterpret_cast<int32_t>(length.raw()), deopt);
  } else {
    Register length = length_loc.reg();
    Register index = index_loc.reg();
    __ BranchUnsignedGreaterEqual(index, length, deopt);
  }
}


LocationSummary* UnboxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnboxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BoxIntegerInstr::MakeLocationSummary(Isolate* isolate,
                                                      bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BoxIntegerInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* BinaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                        bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void BinaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


bool ShiftMintOpInstr::has_shift_count_check() const {
  UNREACHABLE();
  return false;
}


LocationSummary* ShiftMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void ShiftMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


LocationSummary* UnaryMintOpInstr::MakeLocationSummary(Isolate* isolate,
                                                       bool opt) const {
  UNIMPLEMENTED();
  return NULL;
}


void UnaryMintOpInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
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


DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(ShiftUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnaryUint32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxInt32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxInt32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BinaryInt32OpInstr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(BoxUint32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxUint32Instr)
DEFINE_UNIMPLEMENTED_INSTRUCTION(UnboxedIntConverterInstr)


LocationSummary* ThrowInstr::MakeLocationSummary(Isolate* isolate,
                                                 bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kCall);
}



void ThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kThrowRuntimeEntry,
                                1,
                                locs());
  __ break_(0);
}


LocationSummary* ReThrowInstr::MakeLocationSummary(Isolate* isolate,
                                                   bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kCall);
}


void ReThrowInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  compiler->SetNeedsStacktrace(catch_try_index());
  compiler->GenerateRuntimeCall(token_pos(),
                                deopt_id(),
                                kReThrowRuntimeEntry,
                                2,
                                locs());
  __ break_(0);
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ b(compiler->GetJumpLabel(normal_entry()));
  }
}


void TargetEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ Bind(compiler->GetJumpLabel(this));
  if (!compiler->is_optimizing()) {
    if (compiler->NeedsEdgeCounter(this)) {
      compiler->EmitEdgeCounter();
    }
    // On MIPS the deoptimization descriptor points after the edge counter
    // code so that we can reuse the same pattern matching code as at call
    // sites, which matches backwards from the end of the pattern.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   deopt_id_,
                                   Scanner::kNoSourcePos);
  }
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
}


LocationSummary* GotoInstr::MakeLocationSummary(Isolate* isolate,
                                                bool opt) const {
  return new(isolate) LocationSummary(isolate, 0, 0, LocationSummary::kNoCall);
}


void GotoInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("GotoInstr");
  if (!compiler->is_optimizing()) {
    if (FLAG_emit_edge_counters) {
      compiler->EmitEdgeCounter();
    }
    // Add a deoptimization descriptor for deoptimizing instructions that
    // may be inserted before this instruction.  On MIPS this descriptor
    // points after the edge counter code so that we can reuse the same
    // pattern matching code as at call sites, which matches backwards from
    // the end of the pattern.
    compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                   GetDeoptId(),
                                   Scanner::kNoSourcePos);
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


LocationSummary* CurrentContextInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  return LocationSummary::Make(isolate,
                               0,
                               Location::RequiresRegister(),
                               LocationSummary::kNoCall);
}


void CurrentContextInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ mov(locs()->out(0).reg(), CTX);
}


LocationSummary* StrictCompareInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  const intptr_t kNumInputs = 2;
  const intptr_t kNumTemps = 0;
  if (needs_number_check()) {
    LocationSummary* locs = new(isolate) LocationSummary(
        isolate, kNumInputs, kNumTemps, LocationSummary::kCall);
    locs->set_in(0, Location::RegisterLocation(A0));
    locs->set_in(1, Location::RegisterLocation(A1));
    locs->set_out(0, Location::RegisterLocation(A0));
    return locs;
  }
  LocationSummary* locs = new(isolate) LocationSummary(
      isolate, kNumInputs, kNumTemps, LocationSummary::kNoCall);
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
  if (left.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(right.reg(),
                                          left.constant(),
                                          needs_number_check(),
                                          token_pos());
  } else if (right.IsConstant()) {
    compiler->EmitEqualityRegConstCompare(left.reg(),
                                          right.constant(),
                                          needs_number_check(),
                                          token_pos());
  } else {
    compiler->EmitEqualityRegRegCompare(left.reg(),
                                       right.reg(),
                                       needs_number_check(),
                                       token_pos());
  }
  Condition true_condition = (kind() == Token::kEQ_STRICT) ? EQ : NE;
  return true_condition;
}


void StrictCompareInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("StrictCompareInstr");
  __ Comment("StrictCompareInstr");
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
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
  __ TraceSimMsg("StrictCompareInstr::EmitBranchCode");
  ASSERT(kind() == Token::kEQ_STRICT || kind() == Token::kNE_STRICT);

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


LocationSummary* BooleanNegateInstr::MakeLocationSummary(Isolate* isolate,
                                                         bool opt) const {
  return LocationSummary::Make(isolate,
                               1,
                               Location::RequiresRegister(),
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


LocationSummary* AllocateObjectInstr::MakeLocationSummary(Isolate* isolate,
                                                          bool opt) const {
  return MakeCallSummary();
}


void AllocateObjectInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ TraceSimMsg("AllocateObjectInstr");
  __ Comment("AllocateObjectInstr");
  Isolate* isolate = compiler->isolate();
  StubCode* stub_code = isolate->stub_code();
  const Code& stub = Code::Handle(isolate,
                                  stub_code->GetAllocationStubForClass(cls()));
  const ExternalLabel label(stub.EntryPoint());
  compiler->GenerateCall(token_pos(),
                         &label,
                         RawPcDescriptors::kOther,
                         locs());
  __ Drop(ArgumentCount());  // Discard arguments.
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  ASSERT(!compiler->is_optimizing());
  StubCode* stub_code = compiler->isolate()->stub_code();
  const ExternalLabel label(stub_code->DebugStepCheckEntryPoint());
  compiler->GenerateCall(token_pos(), &label, stub_kind_, locs());
#if defined(DEBUG)
  __ LoadImmediate(S4, kInvalidObjectPointer);
  __ LoadImmediate(S5, kInvalidObjectPointer);
#endif
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
