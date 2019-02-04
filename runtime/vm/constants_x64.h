// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_X64_H_
#define RUNTIME_VM_CONSTANTS_X64_H_

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
const FpuRegister FpuTMP = XMM0;
const int kNumberOfFpuRegisters = kNumberOfXmmRegisters;
const FpuRegister kNoFpuRegister = kNoXmmRegister;

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
  TIMES_16 = 4,
  TIMES_HALF_WORD_SIZE = kWordSizeLog2 - 1
};

#define R(reg) (1 << (reg))

#if defined(_WIN64)
class CallingConventions {
 public:
  static const Register kArg1Reg = RCX;
  static const Register kArg2Reg = RDX;
  static const Register kArg3Reg = R8;
  static const Register kArg4Reg = R9;
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

  // Windows x64 ABI specifies that small objects are passed in registers.
  // Otherwise they are passed by reference.
  static const size_t kRegisterTransferLimit = 16;
};
#else
class CallingConventions {
 public:
  static const Register kArg1Reg = RDI;
  static const Register kArg2Reg = RSI;
  static const Register kArg3Reg = RDX;
  static const Register kArg4Reg = RCX;
  static const Register kArg5Reg = R8;
  static const Register kArg6Reg = R9;
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
};
#endif

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

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_X64_H_
