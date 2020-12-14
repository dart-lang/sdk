// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_IA32_H_
#define RUNTIME_VM_CONSTANTS_IA32_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_ia32.h directly; use constants.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"

#include "vm/constants_base.h"

namespace dart {

enum Register {
  EAX = 0,
  ECX = 1,
  EDX = 2,
  EBX = 3,
  ESP = 4,
  EBP = 5,
  ESI = 6,
  EDI = 7,
  kNumberOfCpuRegisters = 8,
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
  kNoByteRegister = -1  // Signals an illegal register.
};

inline ByteRegister ByteRegisterOf(Register reg) {
  return static_cast<ByteRegister>(reg);
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
  kNumberOfXmmRegisters = 8,
  kNoXmmRegister = -1  // Signals an illegal register.
};

// Architecture independent aliases.
typedef XmmRegister FpuRegister;
const FpuRegister FpuTMP = XMM7;
const int kNumberOfFpuRegisters = kNumberOfXmmRegisters;
const FpuRegister kNoFpuRegister = kNoXmmRegister;

extern const char* cpu_reg_names[kNumberOfCpuRegisters];
extern const char* fpu_reg_names[kNumberOfXmmRegisters];

// Register aliases.
const Register TMP = kNoRegister;   // No scratch register used by assembler.
const Register TMP2 = kNoRegister;  // No second assembler scratch register.
const Register CODE_REG = EDI;
const Register PP = kNoRegister;     // No object pool pointer.
const Register SPREG = ESP;          // Stack pointer register.
const Register FPREG = EBP;          // Frame pointer register.
const Register ARGS_DESC_REG = EDX;  // Arguments descriptor register.
const Register THR = ESI;            // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = EBX;
const Register CALLEE_SAVED_TEMP2 = EDI;

// ABI for catch-clause entry point.
const Register kExceptionObjectReg = EAX;
const Register kStackTraceObjectReg = EDX;

// ABI for write barrier stub.
const Register kWriteBarrierObjectReg = EDX;
const Register kWriteBarrierValueReg = kNoRegister;
const Register kWriteBarrierSlotReg = EDI;

// ABI for allocation stubs.
const Register kAllocationStubTypeArgumentsReg = EDX;

// Common ABI for shared slow path stubs.
struct SharedSlowPathStubABI {
  static const Register kResultReg = EAX;
};

// ABI for instantiation stubs.
struct InstantiationABI {
  static const Register kUninstantiatedTypeArgumentsReg = EBX;
  static const Register kInstantiatorTypeArgumentsReg = EDX;
  static const Register kFunctionTypeArgumentsReg = ECX;
  static const Register kResultTypeArgumentsReg = EAX;
  static const Register kResultTypeReg = EAX;
};

// Calling convention when calling SubtypeTestCacheStub.
// Although ia32 uses a stack-based calling convention, we keep the same
// 'TypeTestABI' name for symmetry with other architectures with a proper ABI.
// Note that ia32 has no support for type testing stubs.
struct TypeTestABI {
  static const Register kInstanceReg = EAX;
  static const Register kDstTypeReg = EBX;
  static const Register kInstantiatorTypeArgumentsReg = EDX;
  static const Register kFunctionTypeArgumentsReg = ECX;
  static const Register kSubtypeTestCacheReg =
      EDI;  // On ia32 we don't use CODE_REG.

  // For call to InstanceOfStub.
  static const Register kInstanceOfResultReg = kInstanceReg;
  // For call to SubtypeNTestCacheStub.
  static const Register kSubtypeTestCacheResultReg =
      TypeTestABI::kSubtypeTestCacheReg;
};

// Calling convention when calling kSubtypeCheckRuntimeEntry, to match other
// architectures. We don't generate a call to the AssertSubtypeStub because we
// need CODE_REG to store a fifth argument.
struct AssertSubtypeABI {
  static const Register kSubTypeReg = EAX;
  static const Register kSuperTypeReg = EBX;
  static const Register kInstantiatorTypeArgumentsReg = EDX;
  static const Register kFunctionTypeArgumentsReg = ECX;
  static const Register kDstNameReg = EDI;  /// On ia32 we don't use CODE_REG.

  // No result register, as AssertSubtype is only run for side effect
  // (throws if the subtype check fails).
};

// ABI for InitStaticFieldStub.
struct InitStaticFieldABI {
  static const Register kFieldReg = EAX;
  static const Register kResultReg = EAX;
};

// ABI for InitInstanceFieldStub.
struct InitInstanceFieldABI {
  static const Register kInstanceReg = EBX;
  static const Register kFieldReg = EDX;
  static const Register kResultReg = EAX;
};

// Registers used inside the implementation of InitLateInstanceFieldStub.
struct InitLateInstanceFieldInternalRegs {
  static const Register kFunctionReg = EAX;
  static const Register kAddressReg = ECX;
  static const Register kScratchReg = EDI;
};

// ABI for LateInitializationError stubs.
struct LateInitializationErrorABI {
  static const Register kFieldReg = EDI;
};

// ABI for ThrowStub.
struct ThrowABI {
  static const Register kExceptionReg = EAX;
};

// ABI for ReThrowStub.
struct ReThrowABI {
  static const Register kExceptionReg = EAX;
  static const Register kStackTraceReg = EBX;
};

// ABI for AssertBooleanStub.
struct AssertBooleanABI {
  static const Register kObjectReg = EAX;
};

// ABI for RangeErrorStub.
struct RangeErrorABI {
  static const Register kLengthReg = EAX;
  static const Register kIndexReg = EBX;
};

// ABI for Allocate<TypedData>ArrayStub.
struct AllocateTypedDataArrayABI {
  static const Register kLengthReg = EAX;
  static const Register kResultReg = EAX;
};

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFF;

const intptr_t kReservedCpuRegisters = (1 << SPREG) | (1 << FPREG) | (1 << THR);
// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;

enum ScaleFactor {
  TIMES_1 = 0,
  TIMES_2 = 1,
  TIMES_4 = 2,
  TIMES_8 = 3,
  TIMES_16 = 4,
// We can't include vm/compiler/runtime_api.h, so just be explicit instead
// of using (dart::)kWordSizeLog2.
#if defined(TARGET_ARCH_IS_32_BIT)
  // Used for Smi-boxed indices.
  TIMES_HALF_WORD_SIZE = kInt32SizeLog2 - 1,
  // Used for unboxed indices.
  TIMES_WORD_SIZE = kInt32SizeLog2,
#else
#error "Unexpected word size"
#endif
};

class Instr {
 public:
  static const uint8_t kHltInstruction = 0xF4;
  // We prefer not to use the int3 instruction since it conflicts with gdb.
  static const uint8_t kBreakPointInstruction = kHltInstruction;
  static const int kBreakPointInstructionSize = 1;

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

class CallingConventions {
 public:
  static const Register ArgumentRegisters[];
  static const intptr_t kArgumentRegisters = 0;
  static const intptr_t kFpuArgumentRegisters = 0;
  static const intptr_t kNumArgRegs = 0;
  static const Register kPointerToReturnStructRegisterCall = kNoRegister;

  static const XmmRegister FpuArgumentRegisters[];
  static const intptr_t kXmmArgumentRegisters = 0;
  static const intptr_t kNumFpuArgRegs = 0;

  static constexpr intptr_t kCalleeSaveCpuRegisters =
      (1 << EDI) | (1 << ESI) | (1 << EBX);

  static const bool kArgumentIntRegXorFpuReg = false;

  static constexpr Register kReturnReg = EAX;
  static constexpr Register kSecondReturnReg = EDX;
  static constexpr Register kPointerToReturnStructRegisterReturn = kReturnReg;

  // Whether the callee uses `ret 4` instead of `ret` to return with struct
  // return values.
  // See: https://c9x.me/x86/html/file_module_x86_id_280.html
#if defined(_WIN32)
  static const bool kUsesRet4 = false;
#else
  static const bool kUsesRet4 = true;
#endif

  // Floating point values are returned on the "FPU stack" (in "ST" registers).
  // However, we use XMM0 in our compiler pipeline as the location.
  // The move from and to ST is done in FfiCallInstr::EmitNativeCode and
  // NativeReturnInstr::EmitNativeCode.
  static constexpr XmmRegister kReturnFpuReg = XMM0;

  static constexpr Register kFfiAnyNonAbiRegister = EBX;
  static constexpr Register kFirstNonArgumentRegister = EAX;
  static constexpr Register kSecondNonArgumentRegister = ECX;
  static constexpr Register kStackPointerRegister = SPREG;

  // Whether larger than wordsize arguments are aligned to even registers.
  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;

  // How stack arguments are aligned.
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSize;

  // How fields in composites are aligned.
#if defined(TARGET_OS_WINDOWS)
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;
#else
  static constexpr AlignmentStrategy kFieldAlignment =
      kAlignedToValueSizeBut8AlignedTo4;
#endif

  // Whether 1 or 2 byte-sized arguments or return values are passed extended
  // to 4 bytes.
  static constexpr ExtensionStrategy kReturnRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentStackExtension = kExtendedTo4;
};

const uword kBreakInstructionFiller = 0xCCCCCCCC;

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_IA32_H_
