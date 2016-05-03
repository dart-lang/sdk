// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/intermediate_language.h"

#include "vm/cpu.h"
#include "vm/compiler.h"
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

// List of instructions that are still unimplemented by DBC backend.
#define FOR_EACH_UNIMPLEMENTED_INSTRUCTION(M) \
  M(Stop)                                                                      \
  M(IndirectGoto)                                                              \
  M(LoadCodeUnits)                                                             \
  M(InstanceOf)                                                                \
  M(LoadUntagged)                                                              \
  M(AllocateUninitializedContext)                                              \
  M(BinaryInt32Op)                                                             \
  M(UnarySmiOp)                                                                \
  M(UnaryDoubleOp)                                                             \
  M(SmiToDouble)                                                               \
  M(Int32ToDouble)                                                             \
  M(MintToDouble)                                                              \
  M(DoubleToInteger)                                                           \
  M(DoubleToSmi)                                                               \
  M(DoubleToDouble)                                                            \
  M(DoubleToFloat)                                                             \
  M(FloatToDouble)                                                             \
  M(UnboxedConstant)                                                           \
  M(CheckEitherNonSmi)                                                         \
  M(BinaryDoubleOp)                                                            \
  M(MathUnary)                                                                 \
  M(MathMinMax)                                                                \
  M(Box)                                                                       \
  M(Unbox)                                                                     \
  M(BoxInt64)                                                                  \
  M(CaseInsensitiveCompareUC16)                                                \
  M(BinaryMintOp)                                                              \
  M(ShiftMintOp)                                                               \
  M(UnaryMintOp)                                                               \
  M(StringToCharCode)                                                          \
  M(StringFromCharCode)                                                        \
  M(InvokeMathCFunction)                                                       \
  M(MergedMath)                                                                \
  M(GuardFieldClass)                                                           \
  M(GuardFieldLength)                                                          \
  M(IfThenElse)                                                                \
  M(BinaryFloat32x4Op)                                                         \
  M(Simd32x4Shuffle)                                                           \
  M(Simd32x4ShuffleMix)                                                        \
  M(Simd32x4GetSignMask)                                                       \
  M(Float32x4Constructor)                                                      \
  M(Float32x4Zero)                                                             \
  M(Float32x4Splat)                                                            \
  M(Float32x4Comparison)                                                       \
  M(Float32x4MinMax)                                                           \
  M(Float32x4Scale)                                                            \
  M(Float32x4Sqrt)                                                             \
  M(Float32x4ZeroArg)                                                          \
  M(Float32x4Clamp)                                                            \
  M(Float32x4With)                                                             \
  M(Float32x4ToInt32x4)                                                        \
  M(Int32x4Constructor)                                                        \
  M(Int32x4BoolConstructor)                                                    \
  M(Int32x4GetFlag)                                                            \
  M(Int32x4Select)                                                             \
  M(Int32x4SetFlag)                                                            \
  M(Int32x4ToFloat32x4)                                                        \
  M(BinaryInt32x4Op)                                                           \
  M(TestCids)                                                                  \
  M(BinaryFloat64x2Op)                                                         \
  M(Float64x2Zero)                                                             \
  M(Float64x2Constructor)                                                      \
  M(Float64x2Splat)                                                            \
  M(Float32x4ToFloat64x2)                                                      \
  M(Float64x2ToFloat32x4)                                                      \
  M(Simd64x2Shuffle)                                                           \
  M(Float64x2ZeroArg)                                                          \
  M(Float64x2OneArg)                                                           \
  M(ExtractNthOutput)                                                          \
  M(BinaryUint32Op)                                                            \
  M(ShiftUint32Op)                                                             \
  M(UnaryUint32Op)                                                             \
  M(UnboxedIntConverter)                                                       \
  M(GrowRegExpStack)                                                           \
  M(BoxInteger32)                                                              \
  M(UnboxInteger32)                                                            \
  M(CheckedSmiOp)                                                              \
  M(CheckArrayBound)                                                           \
  M(CheckSmi)                                                                  \
  M(CheckClassId)                                                              \
  M(CheckClass)                                                                \
  M(BinarySmiOp)                                                               \
  M(TestSmi)                                                                   \
  M(RelationalOp)                                                              \
  M(EqualityCompare)                                                           \
  M(LoadIndexed)

// Location summaries actually are not used by the unoptimizing DBC compiler
// because we don't allocate any registers.
static LocationSummary* CreateLocationSummary(Zone* zone,
                                              intptr_t num_inputs,
                                              bool has_result) {
  const intptr_t kNumTemps = 0;
  LocationSummary* locs = new(zone) LocationSummary(
      zone, num_inputs, kNumTemps, LocationSummary::kNoCall);
  for (intptr_t i = 0; i < num_inputs; i++) {
    locs->set_in(i, Location::RequiresRegister());
  }
  if (has_result) {
    locs->set_out(0, Location::RequiresRegister());
  }
  return locs;
}


#define DEFINE_MAKE_LOCATION_SUMMARY(Name, In, Out)                            \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    return CreateLocationSummary(zone, In, Out);                               \
  }                                                                            \

#define EMIT_NATIVE_CODE(Name, In, Out)                                        \
  DEFINE_MAKE_LOCATION_SUMMARY(Name, In, Out);                                 \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler)                \

#define DEFINE_UNIMPLEMENTED_MAKE_LOCATION_SUMMARY(Name)                       \
  LocationSummary* Name##Instr::MakeLocationSummary(Zone* zone, bool opt)      \
      const {                                                                  \
    UNIMPLEMENTED();                                                           \
    return NULL;                                                               \
  }                                                                            \

#define DEFINE_UNIMPLEMENTED_EMIT_NATIVE_CODE(Name)                            \
  void Name##Instr::EmitNativeCode(FlowGraphCompiler* compiler) {              \
    UNIMPLEMENTED();                                                           \
  }

#define DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(Name)                            \
  void Name##Instr::EmitBranchCode(FlowGraphCompiler*, BranchInstr*) {         \
    UNIMPLEMENTED();                                                           \
  }                                                                            \
  Condition Name##Instr::EmitComparisonCode(FlowGraphCompiler*,                \
                                            BranchLabels) {                    \
    UNIMPLEMENTED();                                                           \
    return EQ;                                                                 \
  }

#define DEFINE_UNIMPLEMENTED(Name)                                             \
  DEFINE_UNIMPLEMENTED_MAKE_LOCATION_SUMMARY(Name)                             \
  DEFINE_UNIMPLEMENTED_EMIT_NATIVE_CODE(Name)                                  \

FOR_EACH_UNIMPLEMENTED_INSTRUCTION(DEFINE_UNIMPLEMENTED)

#undef DEFINE_UNIMPLEMENTED

DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(TestCids)
DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(TestSmi)
DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(RelationalOp)
DEFINE_UNIMPLEMENTED_EMIT_BRANCH_CODE(EqualityCompare)


DEFINE_MAKE_LOCATION_SUMMARY(AssertAssignable, 2, true);


EMIT_NATIVE_CODE(AssertBoolean, 1, true) {
  __ AssertBoolean(Isolate::Current()->type_checks() ? 1 : 0);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 deopt_id(),
                                 token_pos());
}


LocationSummary* PolymorphicInstanceCallInstr::MakeLocationSummary(Zone* zone,
                                                        bool optimizing) const {
  return MakeCallSummary(zone);
}


void PolymorphicInstanceCallInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


EMIT_NATIVE_CODE(CheckStackOverflow, 0, false) {
  __ CheckStack();
  compiler->AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall,
                                 Thread::kNoDeoptId,
                                 token_pos());
}


EMIT_NATIVE_CODE(PushArgument, 1, false) {
  if (compiler->is_optimizing()) {
    __ Push(locs()->in(0).reg());
  }
}


EMIT_NATIVE_CODE(LoadLocal, 0, false) {
  ASSERT(!compiler->is_optimizing());
  ASSERT(local().index() != 0);
  __ Push((local().index() > 0) ? (-local().index()) : (-local().index() - 1));
}


EMIT_NATIVE_CODE(StoreLocal, 0, false) {
  ASSERT(!compiler->is_optimizing());
  ASSERT(local().index() != 0);
  if (HasTemp()) {
    __ StoreLocal(
      (local().index() > 0) ? (-local().index()) : (-local().index() - 1));
  } else {
    __ PopLocal(
      (local().index() > 0) ? (-local().index()) : (-local().index() - 1));
  }
}


EMIT_NATIVE_CODE(LoadClassId, 1, true) {
  if (compiler->is_optimizing()) {
    __ LoadClassId(locs()->out(0).reg(), locs()->in(0).reg());
  } else {
    __ LoadClassIdTOS();
  }
}


EMIT_NATIVE_CODE(Constant, 0, true) {
  const intptr_t kidx = __ AddConstant(value());
  if (compiler->is_optimizing()) {
    __ LoadConstant(locs()->out(0).reg(), kidx);
  } else {
    __ PushConstant(kidx);
  }
}


EMIT_NATIVE_CODE(Return, 1, false) {
  __ ReturnTOS();
}


EMIT_NATIVE_CODE(StoreStaticField, 1, false) {
  const intptr_t kidx = __ AddConstant(field());
  __ StoreStaticTOS(kidx);
}


EMIT_NATIVE_CODE(LoadStaticField, 1, true) {
  const intptr_t kidx = __ AddConstant(StaticField());
  __ PushStatic(kidx);
}


EMIT_NATIVE_CODE(InitStaticField, 0, false) {
  ASSERT(!compiler->is_optimizing());
  __ InitStaticTOS();
}


EMIT_NATIVE_CODE(ClosureCall, 0, false) {
  intptr_t argument_count = ArgumentCount();
  const Array& arguments_descriptor =
      Array::ZoneHandle(ArgumentsDescriptor::New(argument_count,
                                                 argument_names()));
  const intptr_t argdesc_kidx =
      compiler->assembler()->AddConstant(arguments_descriptor);
  __ StaticCall(argument_count, argdesc_kidx);

  compiler->RecordSafepoint(locs());
  // Marks either the continuation point in unoptimized code or the
  // deoptimization point in optimized code, after call.
  const intptr_t deopt_id_after = Thread::ToDeoptAfter(deopt_id());
  if (compiler->is_optimizing()) {
    compiler->AddDeoptIndexAtCall(deopt_id_after, token_pos());
  }
  // Add deoptimization continuation point after the call and before the
  // arguments are removed.
  // In optimized code this descriptor is needed for exception handling.
  compiler->AddCurrentDescriptor(RawPcDescriptors::kDeopt,
                                 deopt_id_after,
                                 token_pos());
}


static void EmitBranchOnCondition(FlowGraphCompiler* compiler,
                                  Condition true_condition,
                                  BranchLabels labels) {
  if (labels.fall_through == labels.false_label) {
    // If the next block is the false successor, fall through to it.
    __ Jump(labels.true_label);
  } else {
    // If the next block is not the false successor, branch to it.
    __ Jump(labels.false_label);

    // Fall through or jump to the true successor.
    if (labels.fall_through != labels.true_label) {
      __ Jump(labels.true_label);
    }
  }
}


Condition StrictCompareInstr::EmitComparisonCode(FlowGraphCompiler* compiler,
                                                 BranchLabels labels) {
  ASSERT((kind() == Token::kNE_STRICT) ||
         (kind() == Token::kEQ_STRICT));
  const Bytecode::Opcode eq_op = needs_number_check() ?
      Bytecode::kIfEqStrictNumTOS : Bytecode::kIfEqStrictTOS;
  const Bytecode::Opcode ne_op = needs_number_check() ?
      Bytecode::kIfNeStrictNumTOS : Bytecode::kIfNeStrictTOS;

  if (kind() == Token::kEQ_STRICT) {
    __ Emit((labels.fall_through == labels.false_label) ? eq_op : ne_op);
  } else {
    __ Emit((labels.fall_through == labels.false_label) ? ne_op : eq_op);
  }

  if (needs_number_check() && token_pos().IsReal()) {
    compiler->AddCurrentDescriptor(RawPcDescriptors::kRuntimeCall,
                                   Thread::kNoDeoptId,
                                   token_pos());
  }
  return EQ;
}


void StrictCompareInstr::EmitBranchCode(FlowGraphCompiler* compiler,
                                        BranchInstr* branch) {
  ASSERT((kind() == Token::kEQ_STRICT) ||
         (kind() == Token::kNE_STRICT));

  BranchLabels labels = compiler->CreateBranchLabels(branch);
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
}


EMIT_NATIVE_CODE(StrictCompare, 2, true) {
  ASSERT((kind() == Token::kEQ_STRICT) ||
         (kind() == Token::kNE_STRICT));

  Label is_true, is_false;
  BranchLabels labels = { &is_true, &is_false, &is_false };
  Condition true_condition = EmitComparisonCode(compiler, labels);
  EmitBranchOnCondition(compiler, true_condition, labels);
  Label done;
  __ Bind(&is_false);
  __ PushConstant(Bool::False());
  __ Jump(&done);
  __ Bind(&is_true);
  __ PushConstant(Bool::True());
  __ Bind(&done);
}


LocationSummary* BranchInstr::MakeLocationSummary(Zone* zone,
                                                  bool opt) const {
  comparison()->InitializeLocationSummary(zone, opt);
  // Branches don't produce a result.
  comparison()->locs()->set_out(0, Location::NoLocation());
  return comparison()->locs();
}


void BranchInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  comparison()->EmitBranchCode(compiler, this);
}


EMIT_NATIVE_CODE(Goto, 0, false) {
  if (HasParallelMove()) {
    compiler->parallel_move_resolver()->EmitNativeCode(parallel_move());
  }
  // We can fall through if the successor is the next block in the list.
  // Otherwise, we need a jump.
  if (!compiler->CanFallThroughTo(successor())) {
    __ Jump(compiler->GetJumpLabel(successor()));
  }
}


EMIT_NATIVE_CODE(CreateArray, 2, true) {
  __ CreateArrayTOS();
}


EMIT_NATIVE_CODE(StoreIndexed, 3, false) {
  ASSERT(class_id() == kArrayCid);
  __ StoreIndexedTOS();
}


EMIT_NATIVE_CODE(StringInterpolate, 0, false) {
  const intptr_t kArgumentCount = 1;
  const Array& arguments_descriptor = Array::Handle(
      ArgumentsDescriptor::New(kArgumentCount, Object::null_array()));
  __ PushConstant(CallFunction());
  const intptr_t argdesc_kidx = __ AddConstant(arguments_descriptor);
  __ StaticCall(kArgumentCount, argdesc_kidx);
}


EMIT_NATIVE_CODE(NativeCall, 0, false) {
  SetupNative();

  const intptr_t argc_tag = NativeArguments::ComputeArgcTag(function());

  ASSERT(!link_lazily());
  const ExternalLabel label(reinterpret_cast<uword>(native_c_function()));
  const intptr_t target_kidx =
      __ object_pool_wrapper().FindImmediate(label.address());
  const intptr_t argc_tag_kidx =
      __ object_pool_wrapper().FindImmediate(static_cast<uword>(argc_tag));
  __ PushConstant(target_kidx);
  __ PushConstant(argc_tag_kidx);
  if (is_bootstrap_native()) {
    __ NativeBootstrapCall();
  } else {
    __ NativeCall();
  }
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 Thread::kNoDeoptId,
                                 token_pos());
}


EMIT_NATIVE_CODE(AllocateObject, 0, true) {
  if (ArgumentCount() == 1) {
    __ PushConstant(cls());
    __ AllocateT();
    compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                   Thread::kNoDeoptId,
                                   token_pos());
  } else {
    const intptr_t kidx = __ AddConstant(cls());
    __ Allocate(kidx);
    compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                   Thread::kNoDeoptId,
                                   token_pos());
  }
}


EMIT_NATIVE_CODE(StoreInstanceField, 2, false) {
  ASSERT(!HasTemp());
  ASSERT(offset_in_bytes() % kWordSize == 0);
  if (compiler->is_optimizing()) {
    const Register value = locs()->in(1).reg();
    const Register instance = locs()->in(0).reg();
    __ StoreField(instance, offset_in_bytes() / kWordSize, value);
  } else {
    __ StoreFieldTOS(offset_in_bytes() / kWordSize);
  }
}


EMIT_NATIVE_CODE(LoadField, 1, true) {
  ASSERT(offset_in_bytes() % kWordSize == 0);
  __ LoadFieldTOS(offset_in_bytes() / kWordSize);
}


EMIT_NATIVE_CODE(BooleanNegate, 1, true) {
  __ BooleanNegateTOS();
}


EMIT_NATIVE_CODE(AllocateContext, 0, false) {
  __ AllocateContext(num_context_variables());
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 Thread::kNoDeoptId,
                                 token_pos());
}


EMIT_NATIVE_CODE(CloneContext, 0, false) {
  __ CloneContext();
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 Thread::kNoDeoptId,
                                 token_pos());
}


EMIT_NATIVE_CODE(CatchBlockEntry, 0, false) {
  __ Bind(compiler->GetJumpLabel(this));
  compiler->AddExceptionHandler(catch_try_index(),
                                try_index(),
                                compiler->assembler()->CodeSize(),
                                catch_handler_types_,
                                needs_stacktrace());
  __ MoveSpecial(-exception_var().index()-1,
                 Simulator::kExceptionSpecialIndex);
  __ MoveSpecial(-stacktrace_var().index()-1,
                 Simulator::kStacktraceSpecialIndex);
  __ SetFrame(compiler->StackSize());
}


EMIT_NATIVE_CODE(Throw, 0, false) {
  __ Throw(0);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 deopt_id(),
                                 token_pos());
  __ Trap();
}


EMIT_NATIVE_CODE(ReThrow, 0, false) {
  compiler->SetNeedsStacktrace(catch_try_index());
  __ Throw(1);
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 deopt_id(),
                                 token_pos());
  __ Trap();
}

EMIT_NATIVE_CODE(InstantiateType, 1, true) {
  __ InstantiateType(__ AddConstant(type()));
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 deopt_id(),
                                 token_pos());
}

EMIT_NATIVE_CODE(InstantiateTypeArguments, 1, true) {
  __ InstantiateTypeArgumentsTOS(
      type_arguments().IsRawInstantiatedRaw(type_arguments().Length()),
      __ AddConstant(type_arguments()));
  compiler->AddCurrentDescriptor(RawPcDescriptors::kOther,
                                 deopt_id(),
                                 token_pos());
}


void DebugStepCheckInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  __ DebugStep();
  compiler->AddCurrentDescriptor(stub_kind_, Thread::kNoDeoptId, token_pos());
}


void GraphEntryInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  if (!compiler->CanFallThroughTo(normal_entry())) {
    __ Jump(compiler->GetJumpLabel(normal_entry()));
  }
}


LocationSummary* Instruction::MakeCallSummary(Zone* zone) {
  LocationSummary* result = new(zone) LocationSummary(
      zone, 0, 0, LocationSummary::kCall);
  result->set_out(0, Location::RequiresRegister());
  return result;
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


static const intptr_t kMintShiftCountLimit = 63;


bool ShiftMintOpInstr::has_shift_count_check() const {
  return !RangeUtils::IsWithin(
      right()->definition()->range(), 0, kMintShiftCountLimit);
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

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
