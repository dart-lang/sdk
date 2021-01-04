// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_X64_H_
#define RUNTIME_VM_CONSTANTS_X64_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_x64.h directly; use constants.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/constants_base.h"

namespace dart {

enum Register {
  RAX = 0,
  RCX = 1,
  RDX = 2,
  RBX = 3,
  RSP = 4,
  RBP = 5,
  RSI = 6,
  RDI = 7,
  R8 = 8,
  R9 = 9,
  R10 = 10,
  R11 = 11,
  R12 = 12,
  R13 = 13,
  R14 = 14,
  R15 = 15,
  kNumberOfCpuRegisters = 16,
  kNoRegister = -1,  // Signals an illegal register.
};

enum ByteRegister {
  AL = 0,
  CL = 1,
  DL = 2,
  BL = 3,
  AH = 4,
  CH = 5,
  DH = 6,
  BH = 7,
  SPL = 4 | 0x10,
  BPL = 5 | 0x10,
  SIL = 6 | 0x10,
  DIL = 7 | 0x10,
  R8B = 8,
  R9B = 9,
  R10B = 10,
  R11B = 11,
  R12B = 12,
  R13B = 13,
  R14B = 14,
  R15B = 15,
  kNoByteRegister = -1  // Signals an illegal register.
};

inline ByteRegister ByteRegisterOf(Register reg) {
  if (RSP <= reg && reg <= RDI) {
    return static_cast<ByteRegister>(reg | 0x10);
  } else {
    return static_cast<ByteRegister>(reg);
  }
}

enum XmmRegister {
  XMM0 = 0,
  XMM1 = 1,
  XMM2 = 2,
  XMM3 = 3,
  XMM4 = 4,
  XMM5 = 5,
  XMM6 = 6,
  XMM7 = 7,
  XMM8 = 8,
  XMM9 = 9,
  XMM10 = 10,
  XMM11 = 11,
  XMM12 = 12,
  XMM13 = 13,
  XMM14 = 14,
  XMM15 = 15,
  kNumberOfXmmRegisters = 16,
  kNoXmmRegister = -1  // Signals an illegal register.
};

// Architecture independent aliases.
typedef XmmRegister FpuRegister;
const FpuRegister FpuTMP = XMM15;
const int kNumberOfFpuRegisters = kNumberOfXmmRegisters;
const FpuRegister kNoFpuRegister = kNoXmmRegister;

extern const char* cpu_reg_names[kNumberOfCpuRegisters];
extern const char* fpu_reg_names[kNumberOfXmmRegisters];

enum RexBits {
  REX_NONE = 0,
  REX_B = 1 << 0,
  REX_X = 1 << 1,
  REX_R = 1 << 2,
  REX_W = 1 << 3,
  REX_PREFIX = 1 << 6
};

// Register aliases.
const Register TMP = R11;  // Used as scratch register by the assembler.
const Register TMP2 = kNoRegister;  // No second assembler scratch register.
// Caches object pool pointer in generated code.
const Register PP = R15;
const Register SPREG = RSP;          // Stack pointer register.
const Register FPREG = RBP;          // Frame pointer register.
const Register ARGS_DESC_REG = R10;  // Arguments descriptor register.
const Register CODE_REG = R12;
const Register THR = R14;  // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = RBX;

// ABI for catch-clause entry point.
const Register kExceptionObjectReg = RAX;
const Register kStackTraceObjectReg = RDX;

// ABI for write barrier stub.
const Register kWriteBarrierObjectReg = RDX;
const Register kWriteBarrierValueReg = RAX;
const Register kWriteBarrierSlotReg = R13;

// ABI for allocation stubs.
const Register kAllocationStubTypeArgumentsReg = RDX;

// Common ABI for shared slow path stubs.
struct SharedSlowPathStubABI {
  static const Register kResultReg = RAX;
};

// ABI for instantiation stubs.
struct InstantiationABI {
  static const Register kUninstantiatedTypeArgumentsReg = RBX;
  static const Register kInstantiatorTypeArgumentsReg = RDX;
  static const Register kFunctionTypeArgumentsReg = RCX;
  static const Register kResultTypeArgumentsReg = RAX;
  static const Register kResultTypeReg = RAX;
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of type testing stubs that are _not_ preserved.
struct TTSInternalRegs {
  static const Register kInstanceTypeArgumentsReg = RSI;
  static const Register kScratchReg = R8;

  static const intptr_t kInternalRegisters =
      (1 << kInstanceTypeArgumentsReg) | (1 << kScratchReg);
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of subtype test cache stubs that are _not_ preserved.
struct STCInternalRegs {
  static const Register kCacheEntryReg = RDI;
  static const Register kInstanceCidOrFunctionReg = R10;
  static const Register kInstanceInstantiatorTypeArgumentsReg = R13;

  static const intptr_t kInternalRegisters =
      (1 << kCacheEntryReg) | (1 << kInstanceCidOrFunctionReg) |
      (1 << kInstanceInstantiatorTypeArgumentsReg);
};

// Calling convention when calling TypeTestingStub and SubtypeTestCacheStub.
struct TypeTestABI {
  static const Register kInstanceReg = RAX;
  static const Register kDstTypeReg = RBX;
  static const Register kInstantiatorTypeArgumentsReg = RDX;
  static const Register kFunctionTypeArgumentsReg = RCX;
  static const Register kSubtypeTestCacheReg = R9;
  static const Register kScratchReg = RSI;

  // For calls to InstanceOfStub.
  static const Register kInstanceOfResultReg = kInstanceReg;
  // For calls to SubtypeNTestCacheStub. Must not overlap with any other
  // registers above, for it is also used internally as kNullReg in those stubs.
  static const Register kSubtypeTestCacheResultReg = R8;

  // No registers need saving across SubtypeTestCacheStub calls.
  static const intptr_t kSubtypeTestCacheStubCallerSavedRegisters = 0;

  static const intptr_t kPreservedAbiRegisters =
      (1 << kInstanceReg) | (1 << kDstTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg);

  static const intptr_t kNonPreservedAbiRegisters =
      TTSInternalRegs::kInternalRegisters |
      STCInternalRegs::kInternalRegisters | (1 << kSubtypeTestCacheReg) |
      (1 << kScratchReg) | (1 << kSubtypeTestCacheResultReg) | (1 << CODE_REG);

  static const intptr_t kAbiRegisters =
      kPreservedAbiRegisters | kNonPreservedAbiRegisters;
};

// Calling convention when calling AssertSubtypeStub.
struct AssertSubtypeABI {
  static const Register kSubTypeReg = RAX;
  static const Register kSuperTypeReg = RBX;
  static const Register kInstantiatorTypeArgumentsReg = RDX;
  static const Register kFunctionTypeArgumentsReg = RCX;
  static const Register kDstNameReg = R9;

  static const intptr_t kAbiRegisters =
      (1 << kSubTypeReg) | (1 << kSuperTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg) |
      (1 << kDstNameReg);

  // No result register, as AssertSubtype is only run for side effect
  // (throws if the subtype check fails).
};

// ABI for InitStaticFieldStub.
struct InitStaticFieldABI {
  static const Register kFieldReg = RAX;
  static const Register kResultReg = RAX;
};

// ABI for InitInstanceFieldStub.
struct InitInstanceFieldABI {
  static const Register kInstanceReg = RBX;
  static const Register kFieldReg = RDX;
  static const Register kResultReg = RAX;
};

// Registers used inside the implementation of InitLateInstanceFieldStub.
struct InitLateInstanceFieldInternalRegs {
  static const Register kFunctionReg = RAX;
  static const Register kAddressReg = RCX;
  static const Register kScratchReg = RSI;
};

// ABI for LateInitializationError stubs.
struct LateInitializationErrorABI {
  static const Register kFieldReg = RSI;
};

// ABI for ThrowStub.
struct ThrowABI {
  static const Register kExceptionReg = RAX;
};

// ABI for ReThrowStub.
struct ReThrowABI {
  static const Register kExceptionReg = RAX;
  static const Register kStackTraceReg = RBX;
};

// ABI for AssertBooleanStub.
struct AssertBooleanABI {
  static const Register kObjectReg = RAX;
};

// ABI for RangeErrorStub.
struct RangeErrorABI {
  static const Register kLengthReg = RAX;
  static const Register kIndexReg = RBX;
};

// ABI for AllocateMint*Stub.
struct AllocateMintABI {
  static const Register kResultReg = RAX;
  static const Register kTempReg = RBX;
};

// ABI for Allocate<TypedData>ArrayStub.
struct AllocateTypedDataArrayABI {
  static const Register kLengthReg = RAX;
  static const Register kResultReg = RAX;
};

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFF;
const RegList kAllFpuRegistersList = 0xFFFF;

const RegList kReservedCpuRegisters =
    (1 << SPREG) | (1 << FPREG) | (1 << TMP) | (1 << PP) | (1 << THR);
constexpr intptr_t kNumberOfReservedCpuRegisters = 5;
// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
constexpr int kNumberOfDartAvailableCpuRegs =
    kNumberOfCpuRegisters - kNumberOfReservedCpuRegisters;
constexpr int kStoreBufferWrapperSize = 13;

enum ScaleFactor {
  TIMES_1 = 0,
  TIMES_2 = 1,
  TIMES_4 = 2,
  TIMES_8 = 3,
  // Note that Intel addressing does not support this addressing.
  // > Scale factor — A value of 2, 4, or 8 that is multiplied by the index
  // > value.
  // https://software.intel.com/en-us/download/intel-64-and-ia-32-architectures-sdm-combined-volumes-1-2a-2b-2c-2d-3a-3b-3c-3d-and-4
  // 3.7.5 Specifying an Offset
  TIMES_16 = 4,
// We can't include vm/compiler/runtime_api.h, so just be explicit instead
// of using (dart::)kWordSizeLog2.
#if defined(TARGET_ARCH_IS_64_BIT)
  // Used for Smi-boxed indices.
  TIMES_HALF_WORD_SIZE = kInt64SizeLog2 - 1,
  // Used for unboxed indices.
  TIMES_WORD_SIZE = kInt64SizeLog2,
#else
#error "Unexpected word size"
#endif
};

#define R(reg) (1 << (reg))

class CallingConventions {
 public:
#if defined(TARGET_OS_WINDOWS)
  static const Register kArg1Reg = RCX;
  static const Register kArg2Reg = RDX;
  static const Register kArg3Reg = R8;
  static const Register kArg4Reg = R9;
  static const Register ArgumentRegisters[];
  static const intptr_t kArgumentRegisters =
      R(kArg1Reg) | R(kArg2Reg) | R(kArg3Reg) | R(kArg4Reg);
  static const intptr_t kNumArgRegs = 4;
  static const Register kPointerToReturnStructRegisterCall = kArg1Reg;

  static const XmmRegister FpuArgumentRegisters[];
  static const intptr_t kFpuArgumentRegisters =
      R(XMM0) | R(XMM1) | R(XMM2) | R(XMM3);
  static const intptr_t kNumFpuArgRegs = 4;

  // can ArgumentRegisters[i] and XmmArgumentRegisters[i] both be used at the
  // same time? (Windows no, rest yes)
  static const bool kArgumentIntRegXorFpuReg = true;

  // > The x64 Application Binary Interface (ABI) uses a four-register
  // > fast-call calling convention by default. Space is allocated on the call
  // > stack as a shadow store for callees to save those registers.
  // https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention?view=msvc-160
  //
  // The caller allocates this space. The caller should also reclaim this space
  // after the call to restore the stack to its original state if needed.
  //
  // This is also known as home space.
  // https://devblogs.microsoft.com/oldnewthing/20160623-00/?p=93735
  static const intptr_t kShadowSpaceBytes = 4 * kWordSize;

  static const intptr_t kVolatileCpuRegisters =
      R(RAX) | R(RCX) | R(RDX) | R(R8) | R(R9) | R(R10) | R(R11);

  static const intptr_t kVolatileXmmRegisters =
      R(XMM0) | R(XMM1) | R(XMM2) | R(XMM3) | R(XMM4) | R(XMM5);

  static const intptr_t kCalleeSaveCpuRegisters =
      R(RBX) | R(RSI) | R(RDI) | R(R12) | R(R13) | R(R14) | R(R15);

  static const intptr_t kCalleeSaveXmmRegisters =
      R(XMM6) | R(XMM7) | R(XMM8) | R(XMM9) | R(XMM10) | R(XMM11) | R(XMM12) |
      R(XMM13) | R(XMM14) | R(XMM15);

  static const XmmRegister xmmFirstNonParameterReg = XMM4;

  // Windows x64 ABI specifies that small objects are passed in registers.
  // Otherwise they are passed by reference.
  static const size_t kRegisterTransferLimit = 16;

  static constexpr Register kReturnReg = RAX;
  static constexpr Register kSecondReturnReg = kNoRegister;
  static constexpr FpuRegister kReturnFpuReg = XMM0;
  static constexpr Register kPointerToReturnStructRegisterReturn = kReturnReg;

  // Whether larger than wordsize arguments are aligned to even registers.
  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;

  // How stack arguments are aligned.
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSize;

  // How fields in composites are aligned.
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;

  // Whether 1 or 2 byte-sized arguments or return values are passed extended
  // to 4 bytes.
  static constexpr ExtensionStrategy kReturnRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentStackExtension = kNotExtended;

#else
  static const Register kArg1Reg = RDI;
  static const Register kArg2Reg = RSI;
  static const Register kArg3Reg = RDX;
  static const Register kArg4Reg = RCX;
  static const Register kArg5Reg = R8;
  static const Register kArg6Reg = R9;
  static const Register ArgumentRegisters[];
  static const intptr_t kArgumentRegisters = R(kArg1Reg) | R(kArg2Reg) |
                                             R(kArg3Reg) | R(kArg4Reg) |
                                             R(kArg5Reg) | R(kArg6Reg);
  static const intptr_t kNumArgRegs = 6;
  static const Register kPointerToReturnStructRegisterCall = kArg1Reg;

  static const XmmRegister FpuArgumentRegisters[];
  static const intptr_t kFpuArgumentRegisters = R(XMM0) | R(XMM1) | R(XMM2) |
                                                R(XMM3) | R(XMM4) | R(XMM5) |
                                                R(XMM6) | R(XMM7);
  static const intptr_t kNumFpuArgRegs = 8;

  // can ArgumentRegisters[i] and XmmArgumentRegisters[i] both be used at the
  // same time? (Windows no, rest yes)
  static const bool kArgumentIntRegXorFpuReg = false;

  static const intptr_t kShadowSpaceBytes = 0;

  static const intptr_t kVolatileCpuRegisters = R(RAX) | R(RCX) | R(RDX) |
                                                R(RSI) | R(RDI) | R(R8) |
                                                R(R9) | R(R10) | R(R11);

  static const intptr_t kVolatileXmmRegisters =
      R(XMM0) | R(XMM1) | R(XMM2) | R(XMM3) | R(XMM4) | R(XMM5) | R(XMM6) |
      R(XMM7) | R(XMM8) | R(XMM9) | R(XMM10) | R(XMM11) | R(XMM12) | R(XMM13) |
      R(XMM14) | R(XMM15);

  static const intptr_t kCalleeSaveCpuRegisters =
      R(RBX) | R(R12) | R(R13) | R(R14) | R(R15);

  static const intptr_t kCalleeSaveXmmRegisters = 0;

  static const XmmRegister xmmFirstNonParameterReg = XMM8;

  static constexpr Register kReturnReg = RAX;
  static constexpr Register kSecondReturnReg = RDX;
  static constexpr FpuRegister kReturnFpuReg = XMM0;
  static constexpr FpuRegister kSecondReturnFpuReg = XMM1;
  static constexpr Register kPointerToReturnStructRegisterReturn = kReturnReg;

  // Whether larger than wordsize arguments are aligned to even registers.
  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;

  // How stack arguments are aligned.
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSize;

  // How fields in composites are aligned.
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;

  // Whether 1 or 2 byte-sized arguments or return values are passed extended
  // to 4 bytes.
  // Note that `kReturnRegisterExtension != kArgumentRegisterExtension`, which
  // effectively means that the caller is responsable for truncating and
  // extending both arguments and return value.
  static constexpr ExtensionStrategy kReturnRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kExtendedTo4;
  static constexpr ExtensionStrategy kArgumentStackExtension = kExtendedTo4;

#endif

  COMPILE_ASSERT((kArgumentRegisters & kReservedCpuRegisters) == 0);

  static constexpr Register kFfiAnyNonAbiRegister = R12;
  static constexpr Register kFirstNonArgumentRegister = RAX;
  static constexpr Register kSecondNonArgumentRegister = RBX;
  static constexpr Register kStackPointerRegister = SPREG;

  COMPILE_ASSERT(((R(kFfiAnyNonAbiRegister)) & kCalleeSaveCpuRegisters) != 0);

  COMPILE_ASSERT(
      ((R(kFirstNonArgumentRegister) | R(kSecondNonArgumentRegister)) &
       (kArgumentRegisters | R(kPointerToReturnStructRegisterCall))) == 0);
};

constexpr intptr_t kAbiPreservedCpuRegs =
    CallingConventions::kCalleeSaveCpuRegisters;

#undef R

class Instr {
 public:
  static const uint8_t kHltInstruction = 0xF4;
  // We prefer not to use the int3 instruction since it conflicts with gdb.
  static const uint8_t kBreakPointInstruction = kHltInstruction;
  static const int kBreakPointInstructionSize = 1;
  static const uint8_t kGdbBreakpointInstruction = 0xcc;

  bool IsBreakPoint() {
    ASSERT(kBreakPointInstructionSize == 1);
    return (*reinterpret_cast<const uint8_t*>(this)) == kBreakPointInstruction;
  }

  // Instructions are read out of a code stream. The only way to get a
  // reference to an instruction is to convert a pointer. There is no way
  // to allocate or create instances of class Instr.
  // Use the At(pc) function to create references to Instr.
  static Instr* At(uword pc) { return reinterpret_cast<Instr*>(pc); }

 private:
  DISALLOW_ALLOCATION();
  // We need to prevent the creation of instances of class Instr.
  DISALLOW_IMPLICIT_CONSTRUCTORS(Instr);
};

// The largest multibyte nop we will emit.  This could go up to 15 if it
// becomes important to us.
const int MAX_NOP_SIZE = 8;

const uint64_t kBreakInstructionFiller = 0xCCCCCCCCCCCCCCCCL;

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_X64_H_
