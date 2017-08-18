// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_IA32_H_
#define RUNTIME_VM_CONSTANTS_IA32_H_

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
const FpuRegister FpuTMP = XMM0;
const int kNumberOfFpuRegisters = kNumberOfXmmRegisters;
const FpuRegister kNoFpuRegister = kNoXmmRegister;

// Register aliases.
const Register TMP = kNoRegister;   // No scratch register used by assembler.
const Register TMP2 = kNoRegister;  // No second assembler scratch register.
const Register CTX = EDI;  // Location of current context at method entry.
const Register CODE_REG = EDI;
const Register PP = kNoRegister;     // No object pool pointer.
const Register SPREG = ESP;          // Stack pointer register.
const Register FPREG = EBP;          // Frame pointer register.
const Register ICREG = ECX;          // IC data register.
const Register ARGS_DESC_REG = EDX;  // Arguments descriptor register.
const Register THR = ESI;            // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = EBX;
const Register CALLEE_SAVED_TEMP2 = EDI;

// Exception object is passed in this register to the catch handlers when an
// exception is thrown.
const Register kExceptionObjectReg = EAX;

// Stack trace object is passed in this register to the catch handlers when
// an exception is thrown.
const Register kStackTraceObjectReg = EDX;

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

enum Condition {
  OVERFLOW = 0,
  NO_OVERFLOW = 1,
  BELOW = 2,
  ABOVE_EQUAL = 3,
  EQUAL = 4,
  NOT_EQUAL = 5,
  BELOW_EQUAL = 6,
  ABOVE = 7,
  SIGN = 8,
  NOT_SIGN = 9,
  PARITY_EVEN = 10,
  PARITY_ODD = 11,
  LESS = 12,
  GREATER_EQUAL = 13,
  LESS_EQUAL = 14,
  GREATER = 15,

  ZERO = EQUAL,
  NOT_ZERO = NOT_EQUAL,
  NEGATIVE = SIGN,
  POSITIVE = NOT_SIGN,
  CARRY = BELOW,
  NOT_CARRY = ABOVE_EQUAL,

  INVALID_CONDITION = 16
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

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_IA32_H_
