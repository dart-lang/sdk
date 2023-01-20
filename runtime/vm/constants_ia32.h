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
#include "platform/utils.h"

#include "vm/constants_base.h"

namespace dart {

#define R(reg) (1 << (reg))

enum Register {
  EAX = 0,
  ECX = 1,
  EDX = 2,
  EBX = 3,
  ESP = 4,  // SP
  EBP = 5,  // FP
  ESI = 6,  // THR
  EDI = 7,
  kNumberOfCpuRegisters = 8,
  kNoRegister = -1,  // Signals an illegal register.
};

// Low and high bytes registers of the first four general purpose registers.
// The other four general purpose registers do not have byte registers.
enum ByteRegister {
  AL = 0,
  CL = 1,
  DL = 2,
  BL = 3,
  AH = 4,
  CH = 5,
  DH = 6,
  BH = 7,
  kNumberOfByteRegisters = 8,
  kNoByteRegister = -1  // Signals an illegal register.
};

inline ByteRegister ByteRegisterOf(Register reg) {
  // This only works for EAX, ECX, EDX, EBX.
  // Remaining Register values map to high byte of the above registers.
  RELEASE_ASSERT(reg == Register::EAX || reg == Register::ECX ||
                 reg == Register::EDX || reg == Register::EBX);
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
const int kFpuRegisterSize = 16;
typedef simd128_value_t fpu_register_t;
const int kNumberOfFpuRegisters = kNumberOfXmmRegisters;
const FpuRegister kNoFpuRegister = kNoXmmRegister;

extern const char* const cpu_reg_names[kNumberOfCpuRegisters];
extern const char* const cpu_reg_abi_names[kNumberOfCpuRegisters];
extern const char* const cpu_reg_byte_names[kNumberOfByteRegisters];
extern const char* const fpu_reg_names[kNumberOfXmmRegisters];

// Register aliases.
const Register TMP = kNoRegister;   // No scratch register used by assembler.
const Register TMP2 = kNoRegister;  // No second assembler scratch register.
const Register CODE_REG = EDI;
// Set when calling Dart functions in JIT mode, used by LazyCompileStub.
const Register FUNCTION_REG = EAX;
const Register PP = kNoRegister;     // No object pool pointer.
const Register SPREG = ESP;          // Stack pointer register.
const Register FPREG = EBP;          // Frame pointer register.
const Register IC_DATA_REG = ECX;    // ICData/MegamorphicCache register.
const Register ARGS_DESC_REG = EDX;  // Arguments descriptor register.
const Register THR = ESI;            // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = EBX;
const Register CALLEE_SAVED_TEMP2 = EDI;

// ABI for catch-clause entry point.
const Register kExceptionObjectReg = EAX;
const Register kStackTraceObjectReg = EDX;

// ABI for write barrier stub.
const Register kWriteBarrierObjectReg = EDX;
const Register kWriteBarrierValueReg = EBX;
const Register kWriteBarrierSlotReg = EDI;

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
  static const Register kScratchReg = EDI;  // On ia32 we don't use CODE_REG.
};

// Registers in addition to those listed in InstantiationABI used inside the
// implementation of the InstantiateTypeArguments stubs.
struct InstantiateTAVInternalRegs {
  // On IA32, we don't do hash cache checks in the stub. We only define
  // kSavedRegisters to avoid needing to #ifdef uses of it.
  static const intptr_t kSavedRegisters = 0;
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

// For calling the ia32-specific AssertAssignableStub
struct AssertAssignableStubABI {
  static const Register kDstNameReg = EBX;
  static const Register kSubtypeTestReg = ECX;

  static const intptr_t kInstanceSlotFromFp = 2 + 3;
  static const intptr_t kDstTypeSlotFromFp = 2 + 2;
  static const intptr_t kInstantiatorTAVSlotFromFp = 2 + 1;
  static const intptr_t kFunctionTAVSlotFromFp = 2 + 0;
};

// ABI for InitStaticFieldStub.
struct InitStaticFieldABI {
  static const Register kFieldReg = EDX;
  static const Register kResultReg = EAX;
};

// Registers used inside the implementation of InitLateStaticFieldStub.
struct InitLateStaticFieldInternalRegs {
  static const Register kAddressReg = ECX;
  static const Register kScratchReg = EDI;
};

// ABI for InitInstanceFieldStub.
struct InitInstanceFieldABI {
  static const Register kInstanceReg = EBX;
  static const Register kFieldReg = EDX;
  static const Register kResultReg = EAX;
};

// Registers used inside the implementation of InitLateInstanceFieldStub.
struct InitLateInstanceFieldInternalRegs {
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

// ABI for AllocateObjectStub.
struct AllocateObjectABI {
  static const Register kResultReg = EAX;
  static const Register kTypeArgumentsReg = EDX;
  static const Register kTagsReg = kNoRegister;  // Not used.
};

// ABI for Allocate{Mint,Double,Float32x4,Float64x2}Stub.
struct AllocateBoxABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kTempReg = EBX;
};

// ABI for AllocateClosureStub.
struct AllocateClosureABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kFunctionReg = EBX;
  static const Register kContextReg = ECX;
  static const Register kScratchReg = EDX;
};

// ABI for AllocateArrayStub.
struct AllocateArrayABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kLengthReg = EDX;
  static const Register kTypeArgumentsReg = ECX;
};

// ABI for AllocateRecordStub.
struct AllocateRecordABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kShapeReg = EDX;
  static const Register kTemp1Reg = EBX;
  static const Register kTemp2Reg = EDI;
};

// ABI for AllocateSmallRecordStub (AllocateRecord2, AllocateRecord2Named,
// AllocateRecord3, AllocateRecord3Named).
struct AllocateSmallRecordABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kShapeReg = EBX;
  static const Register kValue0Reg = ECX;
  static const Register kValue1Reg = EDX;
  static const Register kValue2Reg = kNoRegister;
  static const Register kTempReg = EDI;
};

// ABI for AllocateTypedDataArrayStub.
struct AllocateTypedDataArrayABI {
  static const Register kResultReg = AllocateObjectABI::kResultReg;
  static const Register kLengthReg = kResultReg;
};

// ABI for BoxDoubleStub.
struct BoxDoubleStubABI {
  static const FpuRegister kValueReg = XMM0;
  static const Register kTempReg = EBX;
  static const Register kResultReg = EAX;
};

// ABI for DoubleToIntegerStub.
struct DoubleToIntegerStubABI {
  static const FpuRegister kInputReg = XMM0;
  static const Register kRecognizedKindReg = EAX;
  static const Register kResultReg = EAX;
};

// ABI for SuspendStub (AwaitStub, AwaitWithTypeCheckStub, YieldAsyncStarStub,
// SuspendSyncStarAtStartStub, SuspendSyncStarAtYieldStub).
struct SuspendStubABI {
  static const Register kArgumentReg = EAX;
  static const Register kTypeArgsReg = EDX;  // Can be the same as kTempReg
  static const Register kTempReg = EDX;
  static const Register kFrameSizeReg = ECX;
  static const Register kSuspendStateReg = EBX;
  static const Register kFunctionDataReg = EDI;
  // Can reuse THR.
  static const Register kSrcFrameReg = ESI;
  // Can reuse kFunctionDataReg.
  static const Register kDstFrameReg = EDI;

  // Number of bytes to skip after
  // suspend stub return address in order to resume.
  // IA32: mov esp, ebp; pop ebp; ret
  static const intptr_t kResumePcDistance = 4;
};

// ABI for InitSuspendableFunctionStub (InitAsyncStub, InitAsyncStarStub,
// InitSyncStarStub).
struct InitSuspendableFunctionStubABI {
  static const Register kTypeArgsReg = EAX;
};

// ABI for ResumeStub
struct ResumeStubABI {
  static const Register kSuspendStateReg = EBX;
  static const Register kTempReg = EDX;
  // Registers for the frame copying (the 1st part).
  static const Register kFrameSizeReg = ECX;
  // Can reuse THR.
  static const Register kSrcFrameReg = ESI;
  // Can reuse CODE_REG.
  static const Register kDstFrameReg = EDI;
  // Registers for control transfer.
  // (the 2nd part, can reuse registers from the 1st part)
  static const Register kResumePcReg = ECX;
  // Can also reuse kSuspendStateReg but should not conflict with CODE_REG.
  static const Register kExceptionReg = EAX;
  static const Register kStackTraceReg = EBX;
};

// ABI for ReturnStub (ReturnAsyncStub, ReturnAsyncNotFutureStub,
// ReturnAsyncStarStub).
struct ReturnStubABI {
  static const Register kSuspendStateReg = EBX;
};

// ABI for AsyncExceptionHandlerStub.
struct AsyncExceptionHandlerStubABI {
  static const Register kSuspendStateReg = EBX;
};

// ABI for CloneSuspendStateStub.
struct CloneSuspendStateStubABI {
  static const Register kSourceReg = EAX;
  static const Register kDestinationReg = EBX;
  static const Register kTempReg = EDX;
  static const Register kFrameSizeReg = ECX;
  // Can reuse THR.
  static const Register kSrcFrameReg = ESI;
  static const Register kDstFrameReg = EDI;
};

// ABI for DispatchTableNullErrorStub and consequently for all dispatch
// table calls (though normal functions will not expect or use this
// register). This ABI is added to distinguish memory corruption errors from
// null errors.
// Note: dispatch table calls are never actually generated on IA32, this
// declaration is only added for completeness.
struct DispatchTableNullErrorABI {
  static const Register kClassIdReg = EAX;
};

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFF;
const RegList kAllFpuRegistersList = (1 << kNumberOfFpuRegisters) - 1;

const intptr_t kReservedCpuRegisters = (1 << SPREG) | (1 << FPREG) | (1 << THR);
constexpr intptr_t kNumberOfReservedCpuRegisters =
    Utils::CountOneBits32(kReservedCpuRegisters);
// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
constexpr int kNumberOfDartAvailableCpuRegs =
    kNumberOfCpuRegisters - kNumberOfReservedCpuRegisters;
// No reason to prefer certain registers on IA32.
constexpr int kRegisterAllocationBias = 0;
constexpr int kStoreBufferWrapperSize = 11;

const RegList kAbiPreservedCpuRegs = (1 << EDI) | (1 << ESI) | (1 << EBX);

// Registers available to Dart that are not preserved by runtime calls.
const RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;

const RegList kAbiVolatileFpuRegs = kAllFpuRegistersList;

#undef R

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
#if !defined(DART_COMPRESSED_POINTERS)
  TIMES_COMPRESSED_WORD_SIZE = TIMES_WORD_SIZE,
#else
#error Cannot compress IA32
#endif
  // Used for Smi-boxed indices.
  TIMES_COMPRESSED_HALF_WORD_SIZE = TIMES_COMPRESSED_WORD_SIZE - 1,
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

  static constexpr intptr_t kCalleeSaveCpuRegisters = kAbiPreservedCpuRegs;

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
  static constexpr AlignmentStrategy kArgumentRegisterAlignmentVarArgs =
      kArgumentRegisterAlignment;

  // How stack arguments are aligned.
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSize;

  // How fields in compounds are aligned.
#if defined(DART_TARGET_OS_WINDOWS)
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
