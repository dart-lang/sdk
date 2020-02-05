// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_IA32_H_
#define RUNTIME_VM_CONSTANTS_IA32_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_ia32.h directly; use constants.h instead.
#endif

#include "platform/assert.h"

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
  TIMES_HALF_WORD_SIZE = kWordSizeLog2 - 1
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

  static const XmmRegister FpuArgumentRegisters[];
  static const intptr_t kXmmArgumentRegisters = 0;
  static const intptr_t kNumFpuArgRegs = 0;

  static constexpr intptr_t kCalleeSaveCpuRegisters =
      (1 << EDI) | (1 << ESI) | (1 << EBX);

  static const bool kArgumentIntRegXorFpuReg = false;

  // Whether floating-point values should be passed as integers ("softfp" vs
  // "hardfp").
  static constexpr bool kAbiSoftFP = false;

  static constexpr Register kReturnReg = EAX;
  static constexpr Register kSecondReturnReg = EDX;

  // Floating point values are returned on the "FPU stack" (in "ST" registers).
  static constexpr XmmRegister kReturnFpuReg = kNoXmmRegister;

  static constexpr Register kFirstCalleeSavedCpuReg = EBX;
  static constexpr Register kFirstNonArgumentRegister = EAX;
  static constexpr Register kSecondNonArgumentRegister = ECX;
  static constexpr Register kStackPointerRegister = SPREG;

  // Whether 64-bit arguments must be aligned to an even register or 8-byte
  // stack address. On IA32, 64-bit integers and floating-point values do *not*
  // need to be 8-byte aligned.
  static constexpr bool kAlignArguments = false;
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_IA32_H_
