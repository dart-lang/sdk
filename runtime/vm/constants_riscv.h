// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_RISCV_H_
#define RUNTIME_VM_CONSTANTS_RISCV_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_riscv.h directly; use constants.h instead.
#endif

#include <sstream>

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

#include "vm/constants_base.h"
#include "vm/flags.h"

namespace dart {

DECLARE_FLAG(bool, use_compressed_instructions);

#if defined(TARGET_ARCH_RISCV32)
typedef uint32_t uintx_t;
typedef int32_t intx_t;
constexpr intx_t kMaxIntX = kMaxInt32;
constexpr uintx_t kMaxUIntX = kMaxUint32;
constexpr intx_t kMinIntX = kMinInt32;
#define XLEN 32
#elif defined(TARGET_ARCH_RISCV64)
typedef uint64_t uintx_t;
typedef int64_t intx_t;
constexpr intx_t kMaxIntX = kMaxInt64;
constexpr uintx_t kMaxUIntX = kMaxUint64;
constexpr intx_t kMinIntX = kMinInt64;
#define XLEN 64
#else
#error What XLEN?
#endif

enum Register {
  // The correct name for this register is ZERO, but this conflicts with other
  // globals.
  ZR = 0,
  RA = 1,
  SP = 2,
  GP = 3,  // Shadow call stack on Fuchsia and Android
  TP = 4,
  T0 = 5,
  T1 = 6,
  T2 = 7,
  FP = 8,
  S1 = 9,  // THR
  A0 = 10,
  A1 = 11,
  A2 = 12,  // CODE_REG
  A3 = 13,  // TMP
  A4 = 14,  // TMP2
  A5 = 15,  // PP, untagged
  A6 = 16,
  A7 = 17,
  S2 = 18,
  S3 = 19,
  S4 = 20,  // ARGS_DESC_REG
  S5 = 21,  // IC_DATA_REG
  S6 = 22,
  S7 = 23,   // CALLEE_SAVED_TEMP2
  S8 = 24,   // CALLEE_SAVED_TEMP / FAR_TMP
  S9 = 25,   // DISPATCH_TABLE_REG
  S10 = 26,  // nullptr
  S11 = 27,  // WRITE_BARRIER_STATE
  T3 = 28,
  T4 = 29,
  T5 = 30,
  T6 = 31,
  kNumberOfCpuRegisters = 32,
  kNoRegister = -1,

  RA2 = T0,
  S0 = FP,

  // Note that some compressed instructions can only take registers x8-x15 for
  // some of their operands, so to reduce code size we assign the most popular
  // uses to these registers.

  // If the base register of a load/store is not SP, both the base register and
  // source/destination register must be in x8-x15 and the offset must be
  // aligned to make use a compressed instruction. So either,
  //   - PP, CODE_REG and IC_DATA_REG should all be assigned to x8-x15 and we
  //     should hold PP untagged like on ARM64. This makes the loads in the call
  //     sequence shorter, but adds extra PP tagging/untagging on entry and
  //     return.
  //   - PP should be assigned to a C-preserved register to avoid spilling it on
  //     leaf runtime calls.
};

enum FRegister {
  FT0 = 0,
  FT1 = 1,
  FT2 = 2,
  FT3 = 3,
  FT4 = 4,
  FT5 = 5,
  FT6 = 6,
  FT7 = 7,
  FS0 = 8,
  FS1 = 9,
  FA0 = 10,
  FA1 = 11,
  FA2 = 12,
  FA3 = 13,
  FA4 = 14,
  FA5 = 15,
  FA6 = 16,
  FA7 = 17,
  FS2 = 18,
  FS3 = 19,
  FS4 = 20,
  FS5 = 21,
  FS6 = 22,
  FS7 = 23,
  FS8 = 24,
  FS9 = 25,
  FS10 = 26,
  FS11 = 27,
  FT8 = 28,
  FT9 = 29,
  FT10 = 30,
  FT11 = 31,
  kNumberOfFpuRegisters = 32,
  kNoFpuRegister = -1,
};

// Register alias for floating point scratch register.
const FRegister FTMP = FT11;

// Architecture independent aliases.
typedef FRegister FpuRegister;
const FpuRegister FpuTMP = FTMP;
const int kFpuRegisterSize = 8;
typedef double fpu_register_t;

extern const char* const cpu_reg_names[kNumberOfCpuRegisters];
extern const char* const cpu_reg_abi_names[kNumberOfCpuRegisters];
extern const char* const fpu_reg_names[kNumberOfFpuRegisters];

// Register aliases.
constexpr Register TMP = A3;  // Used as scratch register by assembler.
constexpr Register TMP2 = A4;
constexpr Register FAR_TMP = S8;
constexpr Register PP = A5;  // Caches object pool pointer in generated code.
constexpr Register DISPATCH_TABLE_REG = S9;  // Dispatch table register.
constexpr Register CODE_REG = A2;
// Set when calling Dart functions in JIT mode, used by LazyCompileStub.
constexpr Register FUNCTION_REG = T0;
constexpr Register FPREG = FP;          // Frame pointer register.
constexpr Register SPREG = SP;          // Stack pointer register.
constexpr Register IC_DATA_REG = S5;    // ICData/MegamorphicCache register.
constexpr Register ARGS_DESC_REG = S4;  // Arguments descriptor register.
constexpr Register THR = S1;  // Caches current thread in generated code.
constexpr Register CALLEE_SAVED_TEMP = S8;
constexpr Register CALLEE_SAVED_TEMP2 = S7;
constexpr Register WRITE_BARRIER_STATE = S11;
constexpr Register NULL_REG = S10;  // Caches NullObject() value.
#define DART_ASSEMBLER_HAS_NULL_REG 1

// ABI for catch-clause entry point.
constexpr Register kExceptionObjectReg = A0;
constexpr Register kStackTraceObjectReg = A1;

// ABI for write barrier stub.
constexpr Register kWriteBarrierObjectReg = A0;
constexpr Register kWriteBarrierValueReg = A1;
constexpr Register kWriteBarrierSlotReg = A6;

// Common ABI for shared slow path stubs.
struct SharedSlowPathStubABI {
  static constexpr Register kResultReg = A0;
};

// ABI for instantiation stubs.
struct InstantiationABI {
  static constexpr Register kUninstantiatedTypeArgumentsReg = T1;
  static constexpr Register kInstantiatorTypeArgumentsReg = T2;
  static constexpr Register kFunctionTypeArgumentsReg = T3;
  static constexpr Register kResultTypeArgumentsReg = A0;
  static constexpr Register kResultTypeReg = A0;
  static constexpr Register kScratchReg = T4;
};

// Registers in addition to those listed in InstantiationABI used inside the
// implementation of the InstantiateTypeArguments stubs.
struct InstantiateTAVInternalRegs {
  // The set of registers that must be pushed/popped when probing a hash-based
  // cache due to overlap with the registers in InstantiationABI.
  static constexpr intptr_t kSavedRegisters = 0;

  // Additional registers used to probe hash-based caches.
  static constexpr Register kEntryStartReg = S2;
  static constexpr Register kProbeMaskReg = S3;
  static constexpr Register kProbeDistanceReg = S4;
  static constexpr Register kCurrentEntryIndexReg = S5;
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of type testing stubs that are _not_ preserved.
struct TTSInternalRegs {
  static constexpr Register kInstanceTypeArgumentsReg = S2;
  static constexpr Register kScratchReg = S3;
  static constexpr Register kSubTypeArgumentReg = S4;
  static constexpr Register kSuperTypeArgumentReg = S5;

  // Must be pushed/popped whenever generic type arguments are being checked as
  // they overlap with registers in TypeTestABI.
  static constexpr intptr_t kSavedTypeArgumentRegisters = 0;

  static constexpr intptr_t kInternalRegisters =
      ((1 << kInstanceTypeArgumentsReg) | (1 << kScratchReg) |
       (1 << kSubTypeArgumentReg) | (1 << kSuperTypeArgumentReg)) &
      ~kSavedTypeArgumentRegisters;
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of subtype test cache stubs that are _not_ preserved.
struct STCInternalRegs {
  static constexpr Register kInstanceCidOrSignatureReg = S2;
  static constexpr Register kInstanceInstantiatorTypeArgumentsReg = S3;
  static constexpr Register kInstanceParentFunctionTypeArgumentsReg = S4;
  static constexpr Register kInstanceDelayedFunctionTypeArgumentsReg = S5;
  static constexpr Register kCacheEntriesEndReg = S6;
  static constexpr Register kCacheContentsSizeReg = A6;
  static constexpr Register kProbeDistanceReg = A7;

  static constexpr intptr_t kInternalRegisters =
      (1 << kInstanceCidOrSignatureReg) |
      (1 << kInstanceInstantiatorTypeArgumentsReg) |
      (1 << kInstanceParentFunctionTypeArgumentsReg) |
      (1 << kInstanceDelayedFunctionTypeArgumentsReg) |
      (1 << kCacheEntriesEndReg) | (1 << kCacheContentsSizeReg) |
      (1 << kProbeDistanceReg);
};

// Calling convention when calling TypeTestingStub and SubtypeTestCacheStub.
struct TypeTestABI {
  static constexpr Register kInstanceReg = A0;
  static constexpr Register kDstTypeReg = T1;
  static constexpr Register kInstantiatorTypeArgumentsReg = T2;
  static constexpr Register kFunctionTypeArgumentsReg = T3;
  static constexpr Register kSubtypeTestCacheReg = T4;
  static constexpr Register kScratchReg = T5;

  // For calls to SubtypeNTestCacheStub. Must be distinct from the registers
  // listed above.
  static constexpr Register kSubtypeTestCacheResultReg = T0;
  // For calls to InstanceOfStub.
  static constexpr Register kInstanceOfResultReg = kInstanceReg;

  static constexpr intptr_t kPreservedAbiRegisters =
      (1 << kInstanceReg) | (1 << kDstTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg);

  static constexpr intptr_t kNonPreservedAbiRegisters =
      TTSInternalRegs::kInternalRegisters |
      STCInternalRegs::kInternalRegisters | (1 << kSubtypeTestCacheReg) |
      (1 << kScratchReg) | (1 << kSubtypeTestCacheResultReg) | (1 << CODE_REG);

  static constexpr intptr_t kAbiRegisters =
      kPreservedAbiRegisters | kNonPreservedAbiRegisters;
};

// Calling convention when calling AssertSubtypeStub.
struct AssertSubtypeABI {
  static constexpr Register kSubTypeReg = T1;
  static constexpr Register kSuperTypeReg = T2;
  static constexpr Register kInstantiatorTypeArgumentsReg = T3;
  static constexpr Register kFunctionTypeArgumentsReg = T4;
  static constexpr Register kDstNameReg = T5;

  static constexpr intptr_t kAbiRegisters =
      (1 << kSubTypeReg) | (1 << kSuperTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg) |
      (1 << kDstNameReg);

  // No result register, as AssertSubtype is only run for side effect
  // (throws if the subtype check fails).
};

// ABI for InitStaticFieldStub.
struct InitStaticFieldABI {
  static constexpr Register kFieldReg = T2;
  static constexpr Register kResultReg = A0;
};

// Registers used inside the implementation of InitLateStaticFieldStub.
struct InitLateStaticFieldInternalRegs {
  static constexpr Register kAddressReg = T3;
  static constexpr Register kScratchReg = T4;
};

// ABI for InitInstanceFieldStub.
struct InitInstanceFieldABI {
  static constexpr Register kInstanceReg = T1;
  static constexpr Register kFieldReg = T2;
  static constexpr Register kResultReg = A0;
};

// Registers used inside the implementation of InitLateInstanceFieldStub.
struct InitLateInstanceFieldInternalRegs {
  static constexpr Register kAddressReg = T3;
  static constexpr Register kScratchReg = T4;
};

// ABI for LateInitializationError stubs.
struct LateInitializationErrorABI {
  static constexpr Register kFieldReg = T2;
};

// ABI for ThrowStub.
struct ThrowABI {
  static constexpr Register kExceptionReg = A0;
};

// ABI for ReThrowStub.
struct ReThrowABI {
  static constexpr Register kExceptionReg = A0;
  static constexpr Register kStackTraceReg = A1;
};

// ABI for AssertBooleanStub.
struct AssertBooleanABI {
  static constexpr Register kObjectReg = A0;
};

// ABI for RangeErrorStub.
struct RangeErrorABI {
  static constexpr Register kLengthReg = T1;
  static constexpr Register kIndexReg = T2;
};

// ABI for AllocateObjectStub.
struct AllocateObjectABI {
  static constexpr Register kResultReg = A0;
  static constexpr Register kTypeArgumentsReg = A1;
  static constexpr Register kTagsReg = T2;
};

// ABI for AllocateClosureStub.
struct AllocateClosureABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kFunctionReg = T2;
  static constexpr Register kContextReg = T3;
  static constexpr Register kScratchReg = T4;
};

// ABI for AllocateMintShared*Stub.
struct AllocateMintABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = T2;
};

// ABI for Allocate{Mint,Double,Float32x4,Float64x2}Stub.
struct AllocateBoxABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = T2;
};

// ABI for AllocateArrayStub.
struct AllocateArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = T2;
  static constexpr Register kTypeArgumentsReg = T1;
};

// ABI for AllocateRecordStub.
struct AllocateRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = T1;
  static constexpr Register kTemp1Reg = T2;
  static constexpr Register kTemp2Reg = T3;
};

// ABI for AllocateSmallRecordStub (AllocateRecord2, AllocateRecord2Named,
// AllocateRecord3, AllocateRecord3Named).
struct AllocateSmallRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = T2;
  static constexpr Register kValue0Reg = T3;
  static constexpr Register kValue1Reg = T4;
  static constexpr Register kValue2Reg = A1;
  static constexpr Register kTempReg = T1;
};

// ABI for AllocateTypedDataArrayStub.
struct AllocateTypedDataArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = T2;
};

// ABI for BoxDoubleStub.
struct BoxDoubleStubABI {
  static constexpr FpuRegister kValueReg = FA0;
  static constexpr Register kTempReg = T1;
  static constexpr Register kResultReg = A0;
};

// ABI for DoubleToIntegerStub.
struct DoubleToIntegerStubABI {
  static constexpr FpuRegister kInputReg = FA0;
  static constexpr Register kRecognizedKindReg = T1;
  static constexpr Register kResultReg = A0;
};

// ABI for SuspendStub (AwaitStub, AwaitWithTypeCheckStub, YieldAsyncStarStub,
// SuspendSyncStarAtStartStub, SuspendSyncStarAtYieldStub).
struct SuspendStubABI {
  static constexpr Register kArgumentReg = A0;
  static constexpr Register kTypeArgsReg = T0;  // Can be the same as kTempReg
  static constexpr Register kTempReg = T0;
  static constexpr Register kFrameSizeReg = T1;
  static constexpr Register kSuspendStateReg = T2;
  static constexpr Register kFunctionDataReg = T3;
  static constexpr Register kSrcFrameReg = T4;
  static constexpr Register kDstFrameReg = T5;
};

// ABI for InitSuspendableFunctionStub (InitAsyncStub, InitAsyncStarStub,
// InitSyncStarStub).
struct InitSuspendableFunctionStubABI {
  static constexpr Register kTypeArgsReg = A0;
};

// ABI for ResumeStub
struct ResumeStubABI {
  static constexpr Register kSuspendStateReg = T1;
  static constexpr Register kTempReg = T0;
  // Registers for the frame copying (the 1st part).
  static constexpr Register kFrameSizeReg = T2;
  static constexpr Register kSrcFrameReg = T3;
  static constexpr Register kDstFrameReg = T4;
  // Registers for control transfer.
  // (the 2nd part, can reuse registers from the 1st part)
  static constexpr Register kResumePcReg = T2;
  // Can also reuse kSuspendStateReg but should not conflict with CODE_REG/PP.
  static constexpr Register kExceptionReg = T3;
  static constexpr Register kStackTraceReg = T4;
};

// ABI for ReturnStub (ReturnAsyncStub, ReturnAsyncNotFutureStub,
// ReturnAsyncStarStub).
struct ReturnStubABI {
  static constexpr Register kSuspendStateReg = T1;
};

// ABI for AsyncExceptionHandlerStub.
struct AsyncExceptionHandlerStubABI {
  static constexpr Register kSuspendStateReg = T1;
};

// ABI for CloneSuspendStateStub.
struct CloneSuspendStateStubABI {
  static constexpr Register kSourceReg = A0;
  static constexpr Register kDestinationReg = A1;
  static constexpr Register kTempReg = T0;
  static constexpr Register kFrameSizeReg = T1;
  static constexpr Register kSrcFrameReg = T2;
  static constexpr Register kDstFrameReg = T3;
};

// ABI for FfiAsyncCallbackSendStub.
struct FfiAsyncCallbackSendStubABI {
  static constexpr Register kArgsReg = A0;
};

// ABI for DispatchTableNullErrorStub and consequently for all dispatch
// table calls (though normal functions will not expect or use this
// register). This ABI is added to distinguish memory corruption errors from
// null errors.
struct DispatchTableNullErrorABI {
  static constexpr Register kClassIdReg = A2;
};

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFFFFFF;
const RegList kAllFpuRegistersList = 0xFFFFFFFF;

#define R(reg) (static_cast<RegList>(1) << (reg))

// C++ ABI call registers.

constexpr RegList kAbiArgumentCpuRegs =
    R(A0) | R(A1) | R(A2) | R(A3) | R(A4) | R(A5) | R(A6) | R(A7);
constexpr RegList kAbiVolatileCpuRegs = kAbiArgumentCpuRegs | R(T0) | R(T1) |
                                        R(T2) | R(T3) | R(T4) | R(T5) | R(T6) |
                                        R(RA);
constexpr RegList kAbiPreservedCpuRegs = R(S1) | R(S2) | R(S3) | R(S4) | R(S5) |
                                         R(S6) | R(S7) | R(S8) | R(S9) |
                                         R(S10) | R(S11);
constexpr int kAbiPreservedCpuRegCount = 11;

constexpr RegList kReservedCpuRegisters =
    R(ZR) | R(TP) | R(GP) | R(SP) | R(FP) | R(TMP) | R(TMP2) | R(PP) | R(THR) |
    R(RA) | R(WRITE_BARRIER_STATE) | R(NULL_REG) | R(DISPATCH_TABLE_REG) |
    R(FAR_TMP);
constexpr intptr_t kNumberOfReservedCpuRegisters =
    Utils::CountOneBits32(kReservedCpuRegisters);
// CPU registers available to Dart allocator.
constexpr RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
constexpr int kNumberOfDartAvailableCpuRegs =
    kNumberOfCpuRegisters - kNumberOfReservedCpuRegisters;
// Registers X8-15 (S0-1,A0-5) have more compressed instructions available.
constexpr int kRegisterAllocationBias = 8;
// Registers available to Dart that are not preserved by runtime calls.
constexpr RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;

constexpr RegList kAbiArgumentFpuRegs =
    R(FA0) | R(FA1) | R(FA2) | R(FA3) | R(FA4) | R(FA5) | R(FA6) | R(FA7);
constexpr RegList kAbiVolatileFpuRegs =
    kAbiArgumentFpuRegs | R(FT0) | R(FT1) | R(FT2) | R(FT3) | R(FT4) | R(FT5) |
    R(FT6) | R(FT7) | R(FT8) | R(FT9) | R(FT10) | R(FT11);
constexpr RegList kAbiPreservedFpuRegs = R(FS0) | R(FS1) | R(FS2) | R(FS3) |
                                         R(FS4) | R(FS5) | R(FS6) | R(FS7) |
                                         R(FS8) | R(FS9) | R(FS10) | R(FS11);
constexpr int kAbiPreservedFpuRegCount = 12;
constexpr intptr_t kReservedFpuRegisters = 0;
constexpr intptr_t kNumberOfReservedFpuRegisters = 0;

constexpr int kStoreBufferWrapperSize = 26;

class CallingConventions {
 public:
  static constexpr intptr_t kArgumentRegisters = kAbiArgumentCpuRegs;
  static const Register ArgumentRegisters[];
  static constexpr intptr_t kNumArgRegs = 8;
  static constexpr Register kPointerToReturnStructRegisterCall = A0;
  static constexpr Register kPointerToReturnStructRegisterReturn = A0;

  static const FpuRegister FpuArgumentRegisters[];
  static constexpr intptr_t kFpuArgumentRegisters =
      R(FA0) | R(FA1) | R(FA2) | R(FA3) | R(FA4) | R(FA5) | R(FA6) | R(FA7);
  static constexpr intptr_t kNumFpuArgRegs = 8;

  static constexpr bool kArgumentIntRegXorFpuReg = false;

  static constexpr intptr_t kCalleeSaveCpuRegisters = kAbiPreservedCpuRegs;

  // Whether larger than wordsize arguments are aligned to even registers.
  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;
  static constexpr AlignmentStrategy kArgumentRegisterAlignmentVarArgs =
      kAlignedToWordSizeAndValueSize;

  // How stack arguments are aligned.
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSizeAndValueSize;

  // How fields in compounds are aligned.
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;

  // Whether 1 or 2 byte-sized arguments or return values are passed extended
  // to 4 bytes.
  // TODO(ffi): Need to add kExtendedToWord.
  static constexpr ExtensionStrategy kReturnRegisterExtension = kExtendedTo4;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kExtendedTo4;
  static constexpr ExtensionStrategy kArgumentStackExtension = kNotExtended;

  static constexpr Register kReturnReg = A0;
  static constexpr Register kSecondReturnReg = A1;
  static constexpr FpuRegister kReturnFpuReg = FA0;

  // S0=FP, S1=THR
  static constexpr Register kFfiAnyNonAbiRegister = S2;
  static constexpr Register kFirstNonArgumentRegister = T0;
  static constexpr Register kSecondNonArgumentRegister = T1;
  static constexpr Register kStackPointerRegister = SPREG;

  COMPILE_ASSERT(
      ((R(kFirstNonArgumentRegister) | R(kSecondNonArgumentRegister)) &
       (kArgumentRegisters | R(kPointerToReturnStructRegisterCall))) == 0);
};

// TODO(riscv): Architecture-independent parts of the compiler should use
// compare-and-branch instead of condition codes.
enum Condition {
  kNoCondition = -1,
  EQ = 0,   // equal
  NE = 1,   // not equal
  CS = 2,   // carry set/unsigned higher or same
  CC = 3,   // carry clear/unsigned lower
  MI = 4,   // minus/negative
  PL = 5,   // plus/positive or zero
  VS = 6,   // overflow
  VC = 7,   // no overflow
  HI = 8,   // unsigned higher
  LS = 9,   // unsigned lower or same
  GE = 10,  // signed greater than or equal
  LT = 11,  // signed less than
  GT = 12,  // signed greater than
  LE = 13,  // signed less than or equal
  AL = 14,  // always (unconditional)
  NV = 15,  // special condition (refer to section C1.2.3)
  kNumberOfConditions = 16,

  // Platform-independent variants declared for all platforms
  EQUAL = EQ,
  ZERO = EQUAL,
  NOT_EQUAL = NE,
  NOT_ZERO = NOT_EQUAL,
  LESS = LT,
  LESS_EQUAL = LE,
  GREATER_EQUAL = GE,
  GREATER = GT,
  UNSIGNED_LESS = CC,
  UNSIGNED_LESS_EQUAL = LS,
  UNSIGNED_GREATER = HI,
  UNSIGNED_GREATER_EQUAL = CS,
  OVERFLOW = VS,
  NO_OVERFLOW = VC,

  kInvalidCondition = 16
};

static inline Condition InvertCondition(Condition c) {
  COMPILE_ASSERT((EQ ^ NE) == 1);
  COMPILE_ASSERT((CS ^ CC) == 1);
  COMPILE_ASSERT((MI ^ PL) == 1);
  COMPILE_ASSERT((VS ^ VC) == 1);
  COMPILE_ASSERT((HI ^ LS) == 1);
  COMPILE_ASSERT((GE ^ LT) == 1);
  COMPILE_ASSERT((GT ^ LE) == 1);
  COMPILE_ASSERT((AL ^ NV) == 1);
  ASSERT(c != AL);
  ASSERT(c != kInvalidCondition);
  return static_cast<Condition>(c ^ 1);
}

enum ScaleFactor {
  TIMES_1 = 0,
  TIMES_2 = 1,
  TIMES_4 = 2,
  TIMES_8 = 3,
  TIMES_16 = 4,
// We can't include vm/compiler/runtime_api.h, so just be explicit instead
// of using (dart::)kWordSizeLog2.
#if defined(TARGET_ARCH_IS_64_BIT)
  // Used for Smi-boxed indices.
  TIMES_HALF_WORD_SIZE = kInt64SizeLog2 - 1,
  // Used for unboxed indices.
  TIMES_WORD_SIZE = kInt64SizeLog2,
#elif defined(TARGET_ARCH_IS_32_BIT)
  // Used for Smi-boxed indices.
  TIMES_HALF_WORD_SIZE = kInt32SizeLog2 - 1,
  // Used for unboxed indices.
  TIMES_WORD_SIZE = kInt32SizeLog2,
#else
#error "Unexpected word size"
#endif
#if !defined(DART_COMPRESSED_POINTERS)
  TIMES_COMPRESSED_WORD_SIZE = TIMES_WORD_SIZE,
#else
  TIMES_COMPRESSED_WORD_SIZE = TIMES_HALF_WORD_SIZE,
#endif
  // Used for Smi-boxed indices.
  TIMES_COMPRESSED_HALF_WORD_SIZE = TIMES_COMPRESSED_WORD_SIZE - 1,
};

const uword kBreakInstructionFiller = 0;  // trap or c.trap

inline int32_t SignExtend(int N, int32_t value) {
  return static_cast<int32_t>(static_cast<uint32_t>(value) << (32 - N)) >>
         (32 - N);
}

inline intx_t sign_extend(int32_t x) {
  return static_cast<intx_t>(x);
}
inline intx_t sign_extend(int64_t x) {
  return static_cast<intx_t>(x);
}
inline intx_t sign_extend(uint32_t x) {
  return static_cast<intx_t>(static_cast<int32_t>(x));
}
inline intx_t sign_extend(uint64_t x) {
  return static_cast<intx_t>(static_cast<int64_t>(x));
}

enum Opcode {
  LUI = 0b0110111,
  AUIPC = 0b0010111,
  JAL = 0b1101111,
  JALR = 0b1100111,
  BRANCH = 0b1100011,
  LOAD = 0b0000011,
  STORE = 0b0100011,
  OPIMM = 0b0010011,
  OP = 0b0110011,
  MISCMEM = 0b0001111,
  SYSTEM = 0b1110011,
  OP32 = 0b0111011,
  OPIMM32 = 0b0011011,
  AMO = 0b0101111,
  LOADFP = 0b0000111,
  STOREFP = 0b0100111,
  FMADD = 0b1000011,
  FMSUB = 0b1000111,
  FNMSUB = 0b1001011,
  FNMADD = 0b1001111,
  OPFP = 0b1010011,
};

enum Funct12 {
  ECALL = 0,
  EBREAK = 1,
};

enum Funct3 {
  F3_0 = 0,
  F3_1 = 1,

  BEQ = 0b000,
  BNE = 0b001,
  BLT = 0b100,
  BGE = 0b101,
  BLTU = 0b110,
  BGEU = 0b111,

  LB = 0b000,
  LH = 0b001,
  LW = 0b010,
  LBU = 0b100,
  LHU = 0b101,
  LWU = 0b110,
  LD = 0b011,

  SB = 0b000,
  SH = 0b001,
  SW = 0b010,
  SD = 0b011,

  ADDI = 0b000,
  SLLI = 0b001,
  SLTI = 0b010,
  SLTIU = 0b011,
  XORI = 0b100,
  SRI = 0b101,
  ORI = 0b110,
  ANDI = 0b111,

  ADD = 0b000,
  SLL = 0b001,
  SLT = 0b010,
  SLTU = 0b011,
  XOR = 0b100,
  SR = 0b101,
  OR = 0b110,
  AND = 0b111,

  FENCE = 0b000,
  FENCEI = 0b001,

  CSRRW = 0b001,
  CSRRS = 0b010,
  CSRRC = 0b011,
  CSRRWI = 0b101,
  CSRRSI = 0b110,
  CSRRCI = 0b111,

  MUL = 0b000,
  MULH = 0b001,
  MULHSU = 0b010,
  MULHU = 0b011,
  DIV = 0b100,
  DIVU = 0b101,
  REM = 0b110,
  REMU = 0b111,

  MULW = 0b000,
  DIVW = 0b100,
  DIVUW = 0b101,
  REMW = 0b110,
  REMUW = 0b111,

  WIDTH32 = 0b010,
  WIDTH64 = 0b011,

  S = 0b010,
  D = 0b011,
  J = 0b000,
  JN = 0b001,
  JX = 0b010,
  FMIN = 0b000,
  FMAX = 0b001,
  FEQ = 0b010,
  FLT = 0b001,
  FLE = 0b000,

  SH1ADD = 0b010,
  SH2ADD = 0b100,
  SH3ADD = 0b110,

  F3_COUNT = 0b001,

  MAX = 0b110,
  MAXU = 0b111,
  MIN = 0b100,
  MINU = 0b101,
  CLMUL = 0b001,
  CLMULH = 0b011,
  CLMULR = 0b010,

  SEXT = 0b001,
  ZEXT = 0b100,

  ROL = 0b001,
  ROR = 0b101,

  BCLR = 0b001,
  BEXT = 0b101,
  F3_BINV = 0b001,
  F3_BSET = 0b001,
};

enum Funct7 {
  F7_0 = 0,
  SRA = 0b0100000,
  SUB = 0b0100000,
  MULDIV = 0b0000001,

  FADDS = 0b0000000,
  FSUBS = 0b0000100,
  FMULS = 0b0001000,
  FDIVS = 0b0001100,
  FSQRTS = 0b0101100,
  FSGNJS = 0b0010000,
  FMINMAXS = 0b0010100,
  FCMPS = 0b1010000,
  FCLASSS = 0b1110000,
  FCVTintS = 0b1100000,
  FCVTSint = 0b1101000,
  FMVXW = 0b1110000,
  FMVWX = 0b1111000,

  FADDD = 0b0000001,
  FSUBD = 0b0000101,
  FMULD = 0b0001001,
  FDIVD = 0b0001101,
  FSQRTD = 0b0101101,
  FSGNJD = 0b0010001,
  FMINMAXD = 0b0010101,
  FCVTS = 0b0100000,
  FCVTD = 0b0100001,
  FCMPD = 0b1010001,
  FCLASSD = 0b1110001,
  FCVTintD = 0b1100001,
  FCVTDint = 0b1101001,
  FMVXD = 0b1110001,
  FMVDX = 0b1111001,

  ADDUW = 0b0000100,
  SHADD = 0b0010000,
  SLLIUW = 0b0000100,
  COUNT = 0b0110000,
  MINMAXCLMUL = 0b0000101,
  ROTATE = 0b0110000,
  BCLRBEXT = 0b0100100,
  BINV = 0b0110100,
  BSET = 0b0010100,
};

enum Funct5 {
  LR = 0b00010,
  SC = 0b00011,
  AMOSWAP = 0b00001,
  AMOADD = 0b00000,
  AMOXOR = 0b00100,
  AMOAND = 0b01100,
  AMOOR = 0b01000,
  AMOMIN = 0b10000,
  AMOMAX = 0b10100,
  AMOMINU = 0b11000,
  AMOMAXU = 0b11100,
};

enum Funct2 {
  F2_S = 0b00,
  F2_D = 0b01,
};

enum RoundingMode {
  RNE = 0b000,  // Round to Nearest, ties to Even
  RTZ = 0b001,  // Round toward Zero
  RDN = 0b010,  // Round Down (toward negative infinity)
  RUP = 0b011,  // Round Up (toward positive infinity)
  RMM = 0b100,  // Round to nearest, ties to Max Magnitude
  DYN = 0b111,  // Dynamic rounding mode
};

enum FcvtRs2 {
  W = 0b00000,
  WU = 0b00001,
  L = 0b00010,
  LU = 0b00011,
};

enum FClass {
  kFClassNegInfinity = 1 << 0,
  kFClassNegNormal = 1 << 1,
  kFClassNegSubnormal = 1 << 2,
  kFClassNegZero = 1 << 3,
  kFClassPosZero = 1 << 4,
  kFClassPosSubnormal = 1 << 5,
  kFClassPosNormal = 1 << 6,
  kFClassPosInfinity = 1 << 7,
  kFClassSignallingNan = 1 << 8,
  kFClassQuietNan = 1 << 9,
};

enum HartEffects {
  kWrite = 1 << 0,
  kRead = 1 << 1,
  kOutput = 1 << 2,
  kInput = 1 << 3,
  kMemory = kWrite | kRead,
  kIO = kOutput | kInput,
  kAll = kMemory | kIO,
};

const intptr_t kReleaseShift = 25;
const intptr_t kAcquireShift = 26;

#define DEFINE_REG_ENCODING(type, name, shift)                                 \
  inline uint32_t Is##name(type r) { return static_cast<uint32_t>(r) < 32; }   \
  inline uint32_t Encode##name(type r) {                                       \
    ASSERT(Is##name(r));                                                       \
    return static_cast<uint32_t>(r) << shift;                                  \
  }                                                                            \
  inline type Decode##name(uint32_t encoding) {                                \
    return type((encoding >> shift) & 31);                                     \
  }

DEFINE_REG_ENCODING(Register, Rd, 7)
DEFINE_REG_ENCODING(Register, Rs1, 15)
DEFINE_REG_ENCODING(Register, Rs2, 20)
DEFINE_REG_ENCODING(FRegister, FRd, 7)
DEFINE_REG_ENCODING(FRegister, FRs1, 15)
DEFINE_REG_ENCODING(FRegister, FRs2, 20)
DEFINE_REG_ENCODING(FRegister, FRs3, 27)
#undef DEFINE_REG_ENCODING

#define DEFINE_FUNCT_ENCODING(type, name, shift, mask)                         \
  inline uint32_t Is##name(type f) { return (f & mask) == f; }                 \
  inline uint32_t Encode##name(type f) {                                       \
    ASSERT(Is##name(f));                                                       \
    return f << shift;                                                         \
  }                                                                            \
  inline type Decode##name(uint32_t encoding) {                                \
    return static_cast<type>((encoding >> shift) & mask);                      \
  }

DEFINE_FUNCT_ENCODING(Opcode, Opcode, 0, 0x7F)
DEFINE_FUNCT_ENCODING(Funct2, Funct2, 25, 0x3)
DEFINE_FUNCT_ENCODING(Funct3, Funct3, 12, 0x7)
DEFINE_FUNCT_ENCODING(Funct5, Funct5, 27, 0x1F)
DEFINE_FUNCT_ENCODING(Funct7, Funct7, 25, 0x7F)
DEFINE_FUNCT_ENCODING(Funct12, Funct12, 20, 0xFFF)
#if XLEN == 32
DEFINE_FUNCT_ENCODING(uint32_t, Shamt, 20, 0x1F)
#elif XLEN == 64
DEFINE_FUNCT_ENCODING(uint32_t, Shamt, 20, 0x3F)
#endif
DEFINE_FUNCT_ENCODING(RoundingMode, RoundingMode, 12, 0x7)
#undef DEFINE_FUNCT_ENCODING

inline intx_t ImmLo(intx_t imm) {
  return static_cast<intx_t>(static_cast<uintx_t>(imm) << (XLEN - 12)) >>
         (XLEN - 12);
}
inline intx_t ImmHi(intx_t imm) {
  return static_cast<intx_t>(static_cast<uintx_t>(imm) -
                             static_cast<uintx_t>(ImmLo(imm)))
             << (XLEN - 32) >>
         (XLEN - 32);
}

inline bool IsBTypeImm(intptr_t imm) {
  return Utils::IsInt(12, imm) && Utils::IsAligned(imm, 2);
}
inline uint32_t EncodeBTypeImm(intptr_t imm) {
  ASSERT(IsBTypeImm(imm));
  uint32_t encoded = 0;
  encoded |= ((imm >> 12) & 0x1) << 31;
  encoded |= ((imm >> 5) & 0x3f) << 25;
  encoded |= ((imm >> 1) & 0xf) << 8;
  encoded |= ((imm >> 11) & 0x1) << 7;
  return encoded;
}
inline intptr_t DecodeBTypeImm(uint32_t encoded) {
  uint32_t imm = 0;
  imm |= (((encoded >> 31) & 0x1) << 12);
  imm |= (((encoded >> 25) & 0x3f) << 5);
  imm |= (((encoded >> 8) & 0xf) << 1);
  imm |= (((encoded >> 7) & 0x1) << 11);
  return SignExtend(12, imm);
}

inline bool IsJTypeImm(intptr_t imm) {
  return Utils::IsInt(20, imm) && Utils::IsAligned(imm, 2);
}
inline uint32_t EncodeJTypeImm(intptr_t imm) {
  ASSERT(IsJTypeImm(imm));
  uint32_t encoded = 0;
  encoded |= ((imm >> 20) & 0x1) << 31;
  encoded |= ((imm >> 1) & 0x3ff) << 21;
  encoded |= ((imm >> 11) & 0x1) << 20;
  encoded |= ((imm >> 12) & 0xff) << 12;
  return encoded;
}
inline intptr_t DecodeJTypeImm(uint32_t encoded) {
  uint32_t imm = 0;
  imm |= (((encoded >> 31) & 0x1) << 20);
  imm |= (((encoded >> 21) & 0x3ff) << 1);
  imm |= (((encoded >> 20) & 0x1) << 11);
  imm |= (((encoded >> 12) & 0xff) << 12);
  return SignExtend(20, imm);
}

inline bool IsITypeImm(intptr_t imm) {
  return Utils::IsInt(12, imm);
}
inline uint32_t EncodeITypeImm(intptr_t imm) {
  ASSERT(IsITypeImm(imm));
  return static_cast<uint32_t>(imm) << 20;
}
inline intptr_t DecodeITypeImm(uint32_t encoded) {
  return SignExtend(12, encoded >> 20);
}

inline bool IsUTypeImm(intptr_t imm) {
  return Utils::IsInt(32, imm) && Utils::IsAligned(imm, 1 << 12);
}
inline uint32_t EncodeUTypeImm(intptr_t imm) {
  ASSERT(IsUTypeImm(imm));
  return imm;
}
inline intptr_t DecodeUTypeImm(uint32_t encoded) {
  return SignExtend(32, encoded & ~((1 << 12) - 1));
}

inline bool IsSTypeImm(intptr_t imm) {
  return Utils::IsInt(12, imm);
}
inline uint32_t EncodeSTypeImm(intptr_t imm) {
  ASSERT(IsSTypeImm(imm));
  uint32_t encoded = 0;
  encoded |= ((imm >> 5) & 0x7f) << 25;
  encoded |= ((imm >> 0) & 0x1f) << 7;
  return encoded;
}
inline intptr_t DecodeSTypeImm(uint32_t encoded) {
  uint32_t imm = 0;
  imm |= (((encoded >> 25) & 0x7f) << 5);
  imm |= (((encoded >> 7) & 0x1f) << 0);
  return SignExtend(12, imm);
}

inline bool IsCInstruction(uint16_t parcel) {
  return (parcel & 3) != 3;
}

class Instr {
 public:
  explicit Instr(uint32_t encoding) : encoding_(encoding) {}
  uint32_t encoding() const { return encoding_; }

  size_t length() const { return 4; }

  Opcode opcode() const { return DecodeOpcode(encoding_); }

  Register rd() const { return DecodeRd(encoding_); }
  Register rs1() const { return DecodeRs1(encoding_); }
  Register rs2() const { return DecodeRs2(encoding_); }

  FRegister frd() const { return DecodeFRd(encoding_); }
  FRegister frs1() const { return DecodeFRs1(encoding_); }
  FRegister frs2() const { return DecodeFRs2(encoding_); }
  FRegister frs3() const { return DecodeFRs3(encoding_); }

  Funct2 funct2() const { return DecodeFunct2(encoding_); }
  Funct3 funct3() const { return DecodeFunct3(encoding_); }
  Funct5 funct5() const { return DecodeFunct5(encoding_); }
  Funct7 funct7() const { return DecodeFunct7(encoding_); }
  Funct12 funct12() const { return DecodeFunct12(encoding_); }

  uint32_t shamt() const { return DecodeShamt(encoding_); }
  RoundingMode rounding() const { return DecodeRoundingMode(encoding_); }

  std::memory_order memory_order() const {
    bool acquire = ((encoding_ >> kAcquireShift) & 1) != 0;
    bool release = ((encoding_ >> kReleaseShift) & 1) != 0;
    if (acquire && release) return std::memory_order_acq_rel;
    if (acquire) return std::memory_order_acquire;
    if (release) return std::memory_order_release;
    return std::memory_order_relaxed;
  }

  intx_t itype_imm() const { return DecodeITypeImm(encoding_); }
  intx_t stype_imm() const { return DecodeSTypeImm(encoding_); }
  intx_t btype_imm() const { return DecodeBTypeImm(encoding_); }
  intx_t utype_imm() const { return DecodeUTypeImm(encoding_); }
  intx_t jtype_imm() const { return DecodeJTypeImm(encoding_); }

  uint32_t csr() const { return encoding_ >> 20; }
  uint32_t zimm() const { return rs1(); }

  static constexpr uint32_t kBreakPointInstruction = 0;
  static constexpr uint32_t kInstrSize = 4;
  static constexpr uint32_t kSimulatorRedirectInstruction =
      ECALL << 20 | SYSTEM;

 private:
  const uint32_t encoding_;
};

#define DEFINE_REG_ENCODING(type, name, shift)                                 \
  inline uint32_t Is##name(type r) { return static_cast<uint32_t>(r) < 32; }   \
  inline uint32_t Encode##name(type r) {                                       \
    ASSERT(Is##name(r));                                                       \
    return static_cast<uint32_t>(r) << shift;                                  \
  }                                                                            \
  inline type Decode##name(uint32_t encoding) {                                \
    return type((encoding >> shift) & 31);                                     \
  }

#define DEFINE_REG_PRIME_ENCODING(type, name, shift)                           \
  inline uint32_t Is##name(type r) { return (r >= 8) && (r < 16); }            \
  inline uint32_t Encode##name(type r) {                                       \
    ASSERT(Is##name(r));                                                       \
    return (static_cast<uint32_t>(r) & 7) << shift;                            \
  }                                                                            \
  inline type Decode##name(uint32_t encoding) {                                \
    return type(((encoding >> shift) & 7) + 8);                                \
  }

DEFINE_REG_ENCODING(Register, CRd, 7)
DEFINE_REG_ENCODING(Register, CRs1, 7)
DEFINE_REG_ENCODING(Register, CRs2, 2)
DEFINE_REG_ENCODING(FRegister, CFRd, 7)
DEFINE_REG_ENCODING(FRegister, CFRs1, 7)
DEFINE_REG_ENCODING(FRegister, CFRs2, 2)
DEFINE_REG_PRIME_ENCODING(Register, CRdp, 2)
DEFINE_REG_PRIME_ENCODING(Register, CRs1p, 7)
DEFINE_REG_PRIME_ENCODING(Register, CRs2p, 2)
DEFINE_REG_PRIME_ENCODING(FRegister, CFRdp, 2)
DEFINE_REG_PRIME_ENCODING(FRegister, CFRs1p, 7)
DEFINE_REG_PRIME_ENCODING(FRegister, CFRs2p, 2)
#undef DEFINE_REG_ENCODING
#undef DEFINE_REG_PRIME_ENCODING

inline bool IsCSPLoad4Imm(intptr_t imm) {
  return Utils::IsUint(8, imm) && Utils::IsAligned(imm, 4);
}
inline uint32_t EncodeCSPLoad4Imm(intptr_t imm) {
  ASSERT(IsCSPLoad4Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 5) & 0x1) << 12;
  encoding |= ((imm >> 2) & 0x7) << 4;
  encoding |= ((imm >> 6) & 0x3) << 2;
  return encoding;
}
inline intx_t DecodeCSPLoad4Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 5;
  imm |= ((encoding >> 4) & 0x7) << 2;
  imm |= ((encoding >> 2) & 0x3) << 6;
  return imm;
}

inline bool IsCSPLoad8Imm(intptr_t imm) {
  return Utils::IsUint(9, imm) && Utils::IsAligned(imm, 8);
}
inline uint32_t EncodeCSPLoad8Imm(intptr_t imm) {
  ASSERT(IsCSPLoad8Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 5) & 0x1) << 12;
  encoding |= ((imm >> 3) & 0x3) << 5;
  encoding |= ((imm >> 6) & 0x7) << 2;
  return encoding;
}
inline intx_t DecodeCSPLoad8Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 5;
  imm |= ((encoding >> 5) & 0x3) << 3;
  imm |= ((encoding >> 2) & 0x7) << 6;
  return imm;
}

inline bool IsCSPStore4Imm(intptr_t imm) {
  return Utils::IsUint(8, imm) && Utils::IsAligned(imm, 4);
}
inline uint32_t EncodeCSPStore4Imm(intptr_t imm) {
  ASSERT(IsCSPStore4Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 2) & 0xF) << 9;
  encoding |= ((imm >> 6) & 0x3) << 7;
  return encoding;
}
inline intx_t DecodeCSPStore4Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 9) & 0xF) << 2;
  imm |= ((encoding >> 7) & 0x3) << 6;
  return imm;
}

inline bool IsCSPStore8Imm(intptr_t imm) {
  return Utils::IsUint(9, imm) && Utils::IsAligned(imm, 8);
}
inline uint32_t EncodeCSPStore8Imm(intptr_t imm) {
  ASSERT(IsCSPStore8Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 3) & 0x7) << 10;
  encoding |= ((imm >> 6) & 0x7) << 7;
  return encoding;
}
inline intx_t DecodeCSPStore8Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 10) & 0x7) << 3;
  imm |= ((encoding >> 7) & 0x7) << 6;
  return imm;
}

inline bool IsCMem4Imm(intptr_t imm) {
  return Utils::IsUint(7, imm) && Utils::IsAligned(imm, 4);
}
inline uint32_t EncodeCMem4Imm(intptr_t imm) {
  ASSERT(IsCMem4Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 3) & 0x7) << 10;
  encoding |= ((imm >> 2) & 0x1) << 6;
  encoding |= ((imm >> 6) & 0x1) << 5;
  return encoding;
}
inline intx_t DecodeCMem4Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 10) & 0x7) << 3;
  imm |= ((encoding >> 6) & 0x1) << 2;
  imm |= ((encoding >> 5) & 0x1) << 6;
  return imm;
}

inline bool IsCMem8Imm(intptr_t imm) {
  return Utils::IsUint(8, imm) && Utils::IsAligned(imm, 8);
}
inline uint32_t EncodeCMem8Imm(intptr_t imm) {
  ASSERT(IsCMem8Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 3) & 0x7) << 10;
  encoding |= ((imm >> 6) & 0x3) << 5;
  return encoding;
}
inline intx_t DecodeCMem8Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 10) & 0x7) << 3;
  imm |= ((encoding >> 5) & 0x3) << 6;
  return imm;
}

inline bool IsCJImm(intptr_t imm) {
  return Utils::IsInt(11, imm) && Utils::IsAligned(imm, 2);
}
inline uint32_t EncodeCJImm(intptr_t imm) {
  ASSERT(IsCJImm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 11) & 0x1) << 12;
  encoding |= ((imm >> 4) & 0x1) << 11;
  encoding |= ((imm >> 8) & 0x3) << 9;
  encoding |= ((imm >> 10) & 0x1) << 8;
  encoding |= ((imm >> 6) & 0x1) << 7;
  encoding |= ((imm >> 7) & 0x1) << 6;
  encoding |= ((imm >> 1) & 0x7) << 3;
  encoding |= ((imm >> 5) & 0x1) << 2;
  return encoding;
}
inline intx_t DecodeCJImm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 11;
  imm |= ((encoding >> 11) & 0x1) << 4;
  imm |= ((encoding >> 9) & 0x3) << 8;
  imm |= ((encoding >> 8) & 0x1) << 10;
  imm |= ((encoding >> 7) & 0x1) << 6;
  imm |= ((encoding >> 6) & 0x1) << 7;
  imm |= ((encoding >> 3) & 0x7) << 1;
  imm |= ((encoding >> 2) & 0x1) << 5;
  return SignExtend(11, imm);
}

inline bool IsCBImm(intptr_t imm) {
  return Utils::IsInt(8, imm) && Utils::IsAligned(imm, 2);
}
inline uint32_t EncodeCBImm(intptr_t imm) {
  ASSERT(IsCBImm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 8) & 0x1) << 12;
  encoding |= ((imm >> 3) & 0x3) << 10;
  encoding |= ((imm >> 6) & 0x3) << 5;
  encoding |= ((imm >> 1) & 0x3) << 3;
  encoding |= ((imm >> 5) & 0x1) << 2;
  return encoding;
}
inline intx_t DecodeCBImm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 8;
  imm |= ((encoding >> 10) & 0x3) << 3;
  imm |= ((encoding >> 5) & 0x3) << 6;
  imm |= ((encoding >> 3) & 0x3) << 1;
  imm |= ((encoding >> 2) & 0x1) << 5;
  return SignExtend(8, imm);
}

inline bool IsCIImm(intptr_t imm) {
  return Utils::IsInt(6, imm) && Utils::IsAligned(imm, 1);
}
inline uint32_t EncodeCIImm(intptr_t imm) {
  ASSERT(IsCIImm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 5) & 0x1) << 12;
  encoding |= ((imm >> 0) & 0x1F) << 2;
  return encoding;
}
inline intx_t DecodeCIImm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 5;
  imm |= ((encoding >> 2) & 0x1F) << 0;
  return SignExtend(6, imm);
}

inline bool IsCUImm(intptr_t imm) {
  return Utils::IsInt(17, imm) && Utils::IsAligned(imm, 1 << 12);
}
inline uint32_t EncodeCUImm(intptr_t imm) {
  ASSERT(IsCUImm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 17) & 0x1) << 12;
  encoding |= ((imm >> 12) & 0x1F) << 2;
  return encoding;
}
inline intx_t DecodeCUImm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 17;
  imm |= ((encoding >> 2) & 0x1F) << 12;
  return SignExtend(17, imm);
}

inline bool IsCI16Imm(intptr_t imm) {
  return Utils::IsInt(10, imm) && Utils::IsAligned(imm, 16);
}
inline uint32_t EncodeCI16Imm(intptr_t imm) {
  ASSERT(IsCI16Imm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 9) & 0x1) << 12;
  encoding |= ((imm >> 4) & 0x1) << 6;
  encoding |= ((imm >> 6) & 0x1) << 5;
  encoding |= ((imm >> 7) & 0x3) << 3;
  encoding |= ((imm >> 5) & 0x1) << 2;
  return encoding;
}
inline intx_t DecodeCI16Imm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 12) & 0x1) << 9;
  imm |= ((encoding >> 6) & 0x1) << 4;
  imm |= ((encoding >> 5) & 0x1) << 6;
  imm |= ((encoding >> 3) & 0x3) << 7;
  imm |= ((encoding >> 2) & 0x1) << 5;
  return SignExtend(10, imm);
}

inline bool IsCI4SPNImm(intptr_t imm) {
  return Utils::IsUint(9, imm) && Utils::IsAligned(imm, 4);
}
inline uint32_t EncodeCI4SPNImm(intptr_t imm) {
  ASSERT(IsCI4SPNImm(imm));
  uint32_t encoding = 0;
  encoding |= ((imm >> 4) & 0x3) << 11;
  encoding |= ((imm >> 6) & 0xF) << 7;
  encoding |= ((imm >> 2) & 0x1) << 6;
  encoding |= ((imm >> 3) & 0x1) << 5;
  return encoding;
}
inline intx_t DecodeCI4SPNImm(uint32_t encoding) {
  uint32_t imm = 0;
  imm |= ((encoding >> 11) & 0x3) << 4;
  imm |= ((encoding >> 7) & 0xF) << 6;
  imm |= ((encoding >> 6) & 0x1) << 2;
  imm |= ((encoding >> 5) & 0x1) << 3;
  return imm;
}

enum COpcode {
  C_OP_MASK = 0b1110000000000011,

  C_ADDI4SPN = 0b0000000000000000,
  C_FLD = 0b0010000000000000,
  C_LW = 0b0100000000000000,
  C_FLW = 0b0110000000000000,
  C_LD = 0b0110000000000000,
  C_FSD = 0b1010000000000000,
  C_SW = 0b1100000000000000,
  C_FSW = 0b1110000000000000,
  C_SD = 0b1110000000000000,

  C_ADDI = 0b0000000000000001,
  C_JAL = 0b0010000000000001,
  C_ADDIW = 0b0010000000000001,
  C_LI = 0b0100000000000001,
  C_ADDI16SP = 0b0110000000000001,
  C_LUI = 0b0110000000000001,

  C_MISCALU = 0b1000000000000001,
  C_MISCALU_MASK = 0b1110110000000011,
  C_SRLI = 0b1000000000000001,
  C_SRAI = 0b1000010000000001,
  C_ANDI = 0b1000100000000001,
  C_RR = 0b1000110000000001,
  C_RR_MASK = 0b1111110001100011,
  C_SUB = 0b1000110000000001,
  C_XOR = 0b1000110000100001,
  C_OR = 0b1000110001000001,
  C_AND = 0b1000110001100001,
  C_SUBW = 0b1001110000000001,
  C_ADDW = 0b1001110000100001,

  C_J = 0b1010000000000001,
  C_BEQZ = 0b1100000000000001,
  C_BNEZ = 0b1110000000000001,

  C_SLLI = 0b0000000000000010,
  C_FLDSP = 0b0010000000000010,
  C_LWSP = 0b0100000000000010,
  C_FLWSP = 0b0110000000000010,
  C_LDSP = 0b0110000000000010,
  C_JR = 0b1000000000000010,
  C_MV = 0b1000000000000010,
  C_JALR = 0b1001000000000010,
  C_ADD = 0b1001000000000010,
  C_FSDSP = 0b1010000000000010,
  C_SWSP = 0b1100000000000010,
  C_FSWSP = 0b1110000000000010,
  C_SDSP = 0b1110000000000010,

  C_NOP = 0b0000000000000001,
  C_EBREAK = 0b1001000000000010,
};

class CInstr {
 public:
  explicit CInstr(uint16_t encoding) : encoding_(encoding) {}
  uint16_t encoding() const { return encoding_; }

  static constexpr uint32_t kInstrSize = 2;
  size_t length() const { return kInstrSize; }

  COpcode opcode() const { return COpcode(encoding_ & C_OP_MASK); }

  Register rd() const { return DecodeCRd(encoding_); }
  Register rs1() const { return DecodeCRd(encoding_); }
  Register rs2() const { return DecodeCRs2(encoding_); }
  Register rdp() const { return DecodeCRdp(encoding_); }
  Register rs1p() const { return DecodeCRs1p(encoding_); }
  Register rs2p() const { return DecodeCRs2p(encoding_); }
  FRegister frd() const { return DecodeCFRd(encoding_); }
  FRegister frs1() const { return DecodeCFRd(encoding_); }
  FRegister frs2() const { return DecodeCFRs2(encoding_); }
  FRegister frdp() const { return DecodeCFRdp(encoding_); }
  FRegister frs1p() const { return DecodeCFRs1p(encoding_); }
  FRegister frs2p() const { return DecodeCFRs2p(encoding_); }

  intx_t spload4_imm() { return DecodeCSPLoad4Imm(encoding_); }
  intx_t spload8_imm() { return DecodeCSPLoad8Imm(encoding_); }
  intx_t spstore4_imm() { return DecodeCSPStore4Imm(encoding_); }
  intx_t spstore8_imm() { return DecodeCSPStore8Imm(encoding_); }
  intx_t mem4_imm() { return DecodeCMem4Imm(encoding_); }
  intx_t mem8_imm() { return DecodeCMem8Imm(encoding_); }
  intx_t j_imm() { return DecodeCJImm(encoding_); }
  intx_t b_imm() { return DecodeCBImm(encoding_); }
  intx_t i_imm() { return DecodeCIImm(encoding_); }
  intx_t u_imm() { return DecodeCUImm(encoding_); }
  intx_t i16_imm() { return DecodeCI16Imm(encoding_); }
  intx_t i4spn_imm() { return DecodeCI4SPNImm(encoding_); }

 private:
  const uint16_t encoding_;
};

#define DEFINE_TYPED_ENUM_SET(name, storage_t)                                 \
  class name##Set;                                                             \
  class name {                                                                 \
   public:                                                                     \
    constexpr explicit name(storage_t encoding) : encoding_(encoding) {}       \
    constexpr storage_t encoding() const { return encoding_; }                 \
    constexpr bool operator==(const name& other) const {                       \
      return encoding_ == other.encoding_;                                     \
    }                                                                          \
    constexpr bool operator!=(const name& other) const {                       \
      return encoding_ != other.encoding_;                                     \
    }                                                                          \
    inline constexpr name##Set operator|(const name& other) const;             \
    inline constexpr name##Set operator|(const name##Set& other) const;        \
                                                                               \
   private:                                                                    \
    const storage_t encoding_;                                                 \
  };                                                                           \
  inline std::ostream& operator<<(std::ostream& stream, const name& element) { \
    return stream << #name << "(" << element.encoding() << ")";                \
  }                                                                            \
  class name##Set {                                                            \
   public:                                                                     \
    constexpr /* implicit */ name##Set(name element)                           \
        : encoding_(1u << element.encoding()) {}                               \
    constexpr explicit name##Set(storage_t encoding) : encoding_(encoding) {}  \
    constexpr static name##Set Empty() { return name##Set(0); }                \
    constexpr bool Includes(const name r) const {                              \
      return (encoding_ & (1 << r.encoding())) != 0;                           \
    }                                                                          \
    constexpr bool IncludesAll(const name##Set other) const {                  \
      return (encoding_ & other.encoding_) == other.encoding_;                 \
    }                                                                          \
    constexpr bool IsEmpty() const { return encoding_ == 0; }                  \
    constexpr bool operator==(const name##Set& other) const {                  \
      return encoding_ == other.encoding_;                                     \
    }                                                                          \
    constexpr bool operator!=(const name##Set& other) const {                  \
      return encoding_ != other.encoding_;                                     \
    }                                                                          \
    constexpr name##Set operator|(const name& other) const {                   \
      return name##Set(encoding_ | (1 << other.encoding()));                   \
    }                                                                          \
    constexpr name##Set operator|(const name##Set& other) const {              \
      return name##Set(encoding_ | other.encoding_);                           \
    }                                                                          \
    constexpr name##Set operator&(const name##Set& other) const {              \
      return name##Set(encoding_ & other.encoding_);                           \
    }                                                                          \
                                                                               \
   private:                                                                    \
    storage_t encoding_;                                                       \
  };                                                                           \
  constexpr name##Set name::operator|(const name& other) const {               \
    return name##Set((1u << encoding_) | (1u << other.encoding_));             \
  }                                                                            \
  constexpr name##Set name::operator|(const name##Set& other) const {          \
    return other | *this;                                                      \
  }

DEFINE_TYPED_ENUM_SET(Extension, uint32_t)
static constexpr Extension RV_I(0);  // Integer base
static constexpr Extension RV_M(1);  // Multiply/divide
static constexpr Extension RV_A(2);  // Atomic
static constexpr Extension RV_F(3);  // Single-precision floating point
static constexpr Extension RV_D(4);  // Double-precision floating point
static constexpr Extension RV_C(5);  // Compressed instructions
static constexpr ExtensionSet RV_G = RV_I | RV_M | RV_A | RV_F | RV_D;
static constexpr ExtensionSet RV_GC = RV_G | RV_C;
static constexpr Extension RV_Zba(6);  // Address generation
static constexpr Extension RV_Zbb(7);  // Basic bit-manipulation
static constexpr Extension RV_Zbc(8);  // Carry-less multiplication
static constexpr Extension RV_Zbs(9);  // Single-bit instructions
static constexpr ExtensionSet RV_B = RV_Zba | RV_Zbb | RV_Zbc | RV_Zbs;
static constexpr ExtensionSet RV_GCB = RV_GC | RV_B;

#undef R

inline Register ConcreteRegister(Register r) {
  return r;
}
#define LINK_REGISTER RA

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_RISCV_H_
