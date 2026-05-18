// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_LOONG64_H_
#define RUNTIME_VM_CONSTANTS_LOONG64_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_loong64.h directly; use constants.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

#include "vm/constants_base.h"

namespace dart {

typedef uint64_t uintx_t;
typedef int64_t intx_t;
constexpr intx_t kMaxIntX = kMaxInt64;
constexpr uintx_t kMaxUIntX = kMaxUint64;
constexpr intx_t kMinIntX = kMinInt64;
#define XLEN 64

enum Register {
  ZR = 0,
  RA = 1,
  TP = 2,
  SP = 3,
  A0 = 4,
  A1 = 5,
  A2 = 6,  // CODE_REG
  A3 = 7,  // TMP
  A4 = 8,  // TMP2
  A5 = 9,  // PP, untagged
  A6 = 10,
  A7 = 11,
  T0 = 12,  // FUNCTION_REG
  T1 = 13,
  T2 = 14,  // FAR_TMP
  T3 = 15,
  T4 = 16,
  T5 = 17,
  T6 = 18,
  T7 = 19,
  T8 = 20,
  R21 = 21,  // Reserved in the LoongArch ELF psABI.
  FP = 22,
  S0 = 23,
  S1 = 24,  // THR
  S2 = 25,
  S3 = 26,  // DISPATCH_TABLE_REG
  S4 = 27,  // ARGS_DESC_REG
  S5 = 28,  // IC_DATA_REG
  S6 = 29,  // NULL_REG
  S7 = 30,  // CALLEE_SAVED_TEMP
  S8 = 31,  // WRITE_BARRIER_STATE
  kNumberOfCpuRegisters = 32,
  kNoRegister = -1,
};

enum FRegister {
  FA0 = 0,
  FA1 = 1,
  FA2 = 2,
  FA3 = 3,
  FA4 = 4,
  FA5 = 5,
  FA6 = 6,
  FA7 = 7,
  FT0 = 8,
  FT1 = 9,
  FT2 = 10,
  FT3 = 11,
  FT4 = 12,
  FT5 = 13,
  FT6 = 14,
  FT7 = 15,
  FT8 = 16,
  FT9 = 17,
  FT10 = 18,
  FT11 = 19,
  FT12 = 20,
  FT13 = 21,
  FT14 = 22,
  FT15 = 23,
  FS0 = 24,
  FS1 = 25,
  FS2 = 26,
  FS3 = 27,
  FS4 = 28,
  FS5 = 29,
  FS6 = 30,
  FS7 = 31,
  kNumberOfFpuRegisters = 32,
  kNoFpuRegister = -1,
};

enum VRegister {
  V0 = 0,
  V1 = 1,
  V2 = 2,
  V3 = 3,
  V4 = 4,
  V5 = 5,
  V6 = 6,
  V7 = 7,
  V8 = 8,
  V9 = 9,
  V10 = 10,
  V11 = 11,
  V12 = 12,
  V13 = 13,
  V14 = 14,
  V15 = 15,
  V16 = 16,
  V17 = 17,
  V18 = 18,
  V19 = 19,
  V20 = 20,
  V21 = 21,
  V22 = 22,
  V23 = 23,
  V24 = 24,
  V25 = 25,
  V26 = 26,
  V27 = 27,
  V28 = 28,
  V29 = 29,
  V30 = 30,
  V31 = 31,
  kNumberOfVectorRegisters = 32,
  kNoVectorRegister = -1,
};

const FRegister FTMP = FT15;

typedef FRegister FpuRegister;
const FpuRegister FpuTMP = FTMP;
const int kFpuRegisterSize = 8;
typedef double fpu_register_t;

extern const char* const cpu_reg_names[kNumberOfCpuRegisters];
extern const char* const cpu_reg_abi_names[kNumberOfCpuRegisters];
extern const char* const fpu_reg_names[kNumberOfFpuRegisters];
extern const char* const vector_reg_names[kNumberOfVectorRegisters];

constexpr Register TMP = A3;
constexpr Register TMP2 = A4;
constexpr Register FAR_TMP = T2;
constexpr Register PP = A5;
constexpr Register DISPATCH_TABLE_REG = S3;
constexpr Register CODE_REG = A2;
constexpr Register FUNCTION_REG = T0;
constexpr Register FPREG = FP;
constexpr Register SPREG = SP;
constexpr Register IC_DATA_REG = S5;
constexpr Register ARGS_DESC_REG = S4;
constexpr Register THR = S1;
constexpr Register CALLEE_SAVED_TEMP = S7;
constexpr Register WRITE_BARRIER_STATE = S8;
constexpr Register NULL_REG = S6;
#define DART_ASSEMBLER_HAS_NULL_REG 1

constexpr Register kExceptionObjectReg = A0;
constexpr Register kStackTraceObjectReg = A1;

constexpr Register kWriteBarrierObjectReg = A0;
constexpr Register kWriteBarrierValueReg = A1;
constexpr Register kWriteBarrierSlotReg = A6;

struct SharedSlowPathStubABI {
  static constexpr Register kResultReg = A0;
};

struct InstantiationABI {
  static constexpr Register kUninstantiatedTypeArgumentsReg = T1;
  static constexpr Register kInstantiatorTypeArgumentsReg = S0;
  static constexpr Register kFunctionTypeArgumentsReg = T3;
  static constexpr Register kResultTypeArgumentsReg = A0;
  static constexpr Register kResultTypeReg = A0;
  static constexpr Register kScratchReg = T4;
};

struct InstantiateTAVInternalRegs {
  static constexpr intptr_t kSavedRegisters = 0;
  static constexpr Register kEntryStartReg = S2;
  static constexpr Register kProbeMaskReg = S3;
  static constexpr Register kProbeDistanceReg = S4;
  static constexpr Register kCurrentEntryIndexReg = S5;
};

struct TTSInternalRegs {
  static constexpr Register kInstanceTypeArgumentsReg = S2;
  static constexpr Register kScratchReg = S3;
  static constexpr Register kSubTypeArgumentReg = S4;
  static constexpr Register kSuperTypeArgumentReg = S5;
  static constexpr intptr_t kSavedTypeArgumentRegisters = 0;
  static constexpr intptr_t kInternalRegisters =
      ((1 << kInstanceTypeArgumentsReg) | (1 << kScratchReg) |
       (1 << kSubTypeArgumentReg) | (1 << kSuperTypeArgumentReg)) &
      ~kSavedTypeArgumentRegisters;
};

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

struct TypeTestABI {
  static constexpr Register kInstanceReg = A0;
  static constexpr Register kDstTypeReg = T1;
  static constexpr Register kInstantiatorTypeArgumentsReg = S0;
  static constexpr Register kFunctionTypeArgumentsReg = T3;
  static constexpr Register kSubtypeTestCacheReg = T4;
  static constexpr Register kScratchReg = T5;
  static constexpr Register kSubtypeTestCacheResultReg = T0;
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

struct AssertSubtypeABI {
  static constexpr Register kSubTypeReg = T1;
  static constexpr Register kSuperTypeReg = S0;
  static constexpr Register kInstantiatorTypeArgumentsReg = T3;
  static constexpr Register kFunctionTypeArgumentsReg = T4;
  static constexpr Register kDstNameReg = T5;
  static constexpr intptr_t kAbiRegisters =
      (1 << kSubTypeReg) | (1 << kSuperTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg) |
      (1 << kDstNameReg);
};

struct InitStaticFieldABI {
  static constexpr Register kFieldReg = S0;
  static constexpr Register kResultReg = A0;
};

struct InitLateStaticFieldInternalRegs {
  static constexpr Register kAddressReg = T3;
  static constexpr Register kScratchReg = T4;
};

struct InitInstanceFieldABI {
  static constexpr Register kInstanceReg = T1;
  static constexpr Register kFieldReg = S0;
  static constexpr Register kResultReg = A0;
};

struct InitLateInstanceFieldInternalRegs {
  static constexpr Register kAddressReg = T3;
  static constexpr Register kScratchReg = T4;
};

struct LateInitializationErrorABI {
  static constexpr Register kFieldReg = S0;
};

struct FieldAccessErrorABI {
  static constexpr Register kFieldReg = S0;
};

struct ThrowABI {
  static constexpr Register kExceptionReg = A0;
};

struct ReThrowABI {
  static constexpr Register kExceptionReg = A0;
  static constexpr Register kStackTraceReg = A1;
};

struct RangeErrorABI {
  static constexpr Register kLengthReg = T1;
  static constexpr Register kIndexReg = S0;
};

struct AllocateObjectABI {
  static constexpr Register kResultReg = A0;
  static constexpr Register kTypeArgumentsReg = A1;
  static constexpr Register kTagsReg = S0;
};

struct AllocateClosureABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kFunctionReg = T1;
  static constexpr Register kLengthAndFlagsReg = S0;
  static constexpr Register kContextReg = T3;
  static constexpr Register kScratchReg = T4;
};

struct AllocateMintABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = S0;
};

struct AllocateBoxABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = S0;
};

struct AllocateArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = S0;
  static constexpr Register kTypeArgumentsReg = T1;
};

struct AllocateRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = T1;
  static constexpr Register kTemp1Reg = S0;
  static constexpr Register kTemp2Reg = T3;
};

struct AllocateSmallRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = S0;
  static constexpr Register kValue0Reg = T3;
  static constexpr Register kValue1Reg = T4;
  static constexpr Register kValue2Reg = A1;
  static constexpr Register kTempReg = T1;
};

struct AllocateTypedDataArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = S0;
};

struct BoxDoubleStubABI {
  static constexpr FpuRegister kValueReg = FA0;
  static constexpr Register kTempReg = T1;
  static constexpr Register kResultReg = A0;
};

struct DoubleToIntegerStubABI {
  static constexpr FpuRegister kInputReg = FA0;
  static constexpr Register kRecognizedKindReg = T1;
  static constexpr Register kResultReg = A0;
};

struct CheckedStoreIntoSharedStubABI {
  static constexpr Register kFieldReg = T1;
  static constexpr Register kValueReg = S0;
  static constexpr Register kResultReg = A0;
};

struct EnsureDeeplyImmutableStubABI {
  static constexpr Register kValueReg = A0;
  static constexpr Register kTempReg = T1;
};

struct SuspendStubABI {
  static constexpr Register kArgumentReg = A0;
  static constexpr Register kTypeArgsReg = T0;
  static constexpr Register kTempReg = T0;
  static constexpr Register kFrameSizeReg = T1;
  static constexpr Register kSuspendStateReg = S0;
  static constexpr Register kFunctionDataReg = T3;
  static constexpr Register kSrcFrameReg = T4;
  static constexpr Register kDstFrameReg = T5;
  static constexpr intptr_t kResumePcDistance = 0;
};

struct InitSuspendableFunctionStubABI {
  static constexpr Register kTypeArgsReg = A0;
};

struct ResumeStubABI {
  static constexpr Register kSuspendStateReg = T1;
  static constexpr Register kTempReg = T0;
  static constexpr Register kFrameSizeReg = S0;
  static constexpr Register kSrcFrameReg = T3;
  static constexpr Register kDstFrameReg = T4;
  static constexpr Register kResumePcReg = S0;
  static constexpr Register kExceptionReg = T3;
  static constexpr Register kStackTraceReg = T4;
};

struct ReturnStubABI {
  static constexpr Register kSuspendStateReg = T1;
};

struct AsyncExceptionHandlerStubABI {
  static constexpr Register kSuspendStateReg = T1;
};

struct CloneSuspendStateStubABI {
  static constexpr Register kSourceReg = A0;
  static constexpr Register kDestinationReg = A1;
  static constexpr Register kTempReg = T0;
  static constexpr Register kFrameSizeReg = T1;
  static constexpr Register kSrcFrameReg = S0;
  static constexpr Register kDstFrameReg = T3;
};

struct FfiAsyncCallbackSendStubABI {
  static constexpr Register kArgsReg = A0;
};

struct DispatchTableNullErrorABI {
  static constexpr Register kClassIdReg = A2;
};

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFFFFFF;
const RegList kAllFpuRegistersList = 0xFFFFFFFF;

#define R(reg) (static_cast<RegList>(1) << (reg))

constexpr RegList kAbiArgumentCpuRegs =
    R(A0) | R(A1) | R(A2) | R(A3) | R(A4) | R(A5) | R(A6) | R(A7);
constexpr RegList kAbiVolatileCpuRegs =
    kAbiArgumentCpuRegs | R(T0) | R(T1) | R(T2) | R(T3) | R(T4) | R(T5) |
    R(T6) | R(T7) | R(T8) | R(RA);
constexpr RegList kAbiPreservedCpuRegs =
    R(FP) | R(S0) | R(S1) | R(S2) | R(S3) | R(S4) | R(S5) | R(S6) | R(S7) |
    R(S8);
constexpr int kAbiPreservedCpuRegCount = 10;

constexpr RegList kReservedCpuRegisters =
    R(ZR) | R(TP) | R(SP) | R(FP) | R(TMP) | R(TMP2) | R(PP) | R(THR) |
    R(RA) | R(WRITE_BARRIER_STATE) | R(NULL_REG) | R(DISPATCH_TABLE_REG) |
    R(FAR_TMP) | R(R21);
constexpr intptr_t kNumberOfReservedCpuRegisters =
    Utils::CountOneBits32(kReservedCpuRegisters);
constexpr RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
constexpr int kNumberOfDartAvailableCpuRegs =
    kNumberOfCpuRegisters - kNumberOfReservedCpuRegisters;
constexpr int kRegisterAllocationBias = 0;
constexpr RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;

constexpr RegList kAbiArgumentFpuRegs =
    R(FA0) | R(FA1) | R(FA2) | R(FA3) | R(FA4) | R(FA5) | R(FA6) | R(FA7);
constexpr RegList kAbiVolatileFpuRegs =
    kAbiArgumentFpuRegs | R(FT0) | R(FT1) | R(FT2) | R(FT3) | R(FT4) |
    R(FT5) | R(FT6) | R(FT7) | R(FT8) | R(FT9) | R(FT10) | R(FT11) |
    R(FT12) | R(FT13) | R(FT14) | R(FT15);
constexpr RegList kAbiPreservedFpuRegs =
    R(FS0) | R(FS1) | R(FS2) | R(FS3) | R(FS4) | R(FS5) | R(FS6) | R(FS7);
constexpr int kAbiPreservedFpuRegCount = 8;
constexpr intptr_t kReservedFpuRegisters = 0;
constexpr intptr_t kNumberOfReservedFpuRegisters = 0;
constexpr RegList kDartVolatileFpuRegs = kAbiVolatileFpuRegs & ~R(FpuTMP);

constexpr int kStoreBufferWrapperSize = 32;

class CallingConventions {
 public:
  static constexpr intptr_t kArgumentRegisters = kAbiArgumentCpuRegs;
  static const Register ArgumentRegisters[];
  static constexpr intptr_t kNumArgRegs = 8;
  static constexpr Register kPointerToReturnStructRegisterCall = A0;
  static constexpr Register kPointerToReturnStructRegisterReturn = A0;

  static const FpuRegister FpuArgumentRegisters[];
  static constexpr intptr_t kFpuArgumentRegisters = kAbiArgumentFpuRegs;
  static constexpr intptr_t kNumFpuArgRegs = 8;

  static constexpr bool kArgumentIntRegXorFpuReg = false;
  static constexpr intptr_t kCalleeSaveCpuRegisters = kAbiPreservedCpuRegs;

  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;
  static constexpr AlignmentStrategy kArgumentRegisterAlignmentVarArgs =
      kAlignedToWordSizeAndValueSize;
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSizeAndValueSize;
  static constexpr AlignmentStrategy kArgumentStackAlignmentVarArgs =
      kArgumentStackAlignment;
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;

  static constexpr ExtensionStrategy kReturnRegisterExtension = kExtendedTo8;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kExtendedTo8;
  static constexpr ExtensionStrategy kArgumentStackExtension = kExtendedTo8;

  static constexpr Register kReturnReg = A0;
  static constexpr Register kSecondReturnReg = A1;
  static constexpr FpuRegister kReturnFpuReg = FA0;
  static constexpr FpuRegister kSecondReturnFpuReg = FA1;

  static constexpr Register kFfiAnyNonAbiRegister = S2;
  static constexpr Register kFirstNonArgumentRegister = T0;
  static constexpr Register kSecondNonArgumentRegister = T1;
  static constexpr Register kStackPointerRegister = SPREG;

  COMPILE_ASSERT(
      ((R(kFirstNonArgumentRegister) | R(kSecondNonArgumentRegister)) &
       (kArgumentRegisters | R(kPointerToReturnStructRegisterCall))) == 0);
};

struct DartCallingConvention {
  static constexpr Register kCpuRegistersForArgs[] = {A1, A6, A0, A7};
  static constexpr FpuRegister kFpuRegistersForArgs[] = {FA0, FA1, FA2, FA3};
};

enum Condition {
  kNoCondition = -1,
  EQ = 0,
  NE = 1,
  CS = 2,
  CC = 3,
  MI = 4,
  PL = 5,
  VS = 6,
  VC = 7,
  HI = 8,
  LS = 9,
  GE = 10,
  LT = 11,
  GT = 12,
  LE = 13,
  AL = 14,
  NV = 15,
  kNumberOfConditions = 16,

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
  TIMES_HALF_WORD_SIZE = kInt64SizeLog2 - 1,
  TIMES_WORD_SIZE = kInt64SizeLog2,
#if !defined(DART_COMPRESSED_POINTERS)
  TIMES_COMPRESSED_WORD_SIZE = TIMES_WORD_SIZE,
#else
  TIMES_COMPRESSED_WORD_SIZE = TIMES_HALF_WORD_SIZE,
#endif
  TIMES_COMPRESSED_HALF_WORD_SIZE = TIMES_COMPRESSED_WORD_SIZE - 1,
};

const uword kBreakInstructionFiller = 0;

const intptr_t kPreferredLoopAlignment = 1;

inline int32_t SignExtend(int N, int32_t value) {
  return static_cast<int32_t>(static_cast<uint32_t>(value) << (32 - N)) >>
         (32 - N);
}

inline intx_t sign_extend(int8_t x) {
  return static_cast<intx_t>(x);
}
inline intx_t sign_extend(int16_t x) {
  return static_cast<intx_t>(x);
}
inline intx_t sign_extend(int32_t x) {
  return static_cast<intx_t>(x);
}
inline intx_t sign_extend(int64_t x) {
  return static_cast<intx_t>(x);
}

inline Register ConcreteRegister(Register r) {
  return r;
}
#define LINK_REGISTER RA

}  // namespace dart

#undef R

#endif  // RUNTIME_VM_CONSTANTS_LOONG64_H_
