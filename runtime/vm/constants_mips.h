// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CONSTANTS_MIPS_H_
#define VM_CONSTANTS_MIPS_H_

namespace dart {

enum Register {
  R0  =  0,
  R1  =  1,
  kFirstFreeCpuRegister = 2,
  R2  =  2,
  R3  =  3,
  R4  =  4,
  R5  =  5,
  R6  =  6,
  R7  =  7,
  R8  =  8,
  R9  =  9,
  R10 = 10,
  R11 = 11,
  R12 = 12,
  R13 = 13,
  R14 = 14,
  R15 = 15,
  R16 = 16,
  R17 = 17,
  R18 = 18,
  R19 = 19,
  R20 = 20,
  R21 = 21,
  kLastFreeCpuRegister = 21,
  R22 = 22,
  R23 = 23,
  R24 = 24,
  R25 = 25,
  R26 = 26,
  R27 = 27,
  R28 = 28,
  R29 = 29,
  R30 = 30,
  R31 = 31,
  kNumberOfCpuRegisters = 32,
  kNoRegister = -1,

  // Register aliases.
  ZR = R0,
  AT = R1,

  V0 = R2,
  V1 = R3,

  A0 = R4,
  A1 = R5,
  A2 = R6,
  A3 = R7,

  T0 = R8,
  T1 = R9,
  T2 = R10,
  T3 = R11,
  T4 = R12,
  T5 = R13,
  T6 = R14,
  T7 = R15,

  S0 = R16,
  S1 = R17,
  S2 = R18,
  S3 = R19,
  S4 = R20,
  S5 = R21,
  S6 = R22,
  S7 = R23,

  T8 = R24,
  T9 = R25,

  K0 = R26,
  K1 = R27,

  GP = R28,
  SP = R29,
  FP = R30,
  RA = R31,
};


// Values for floating point registers.
// Double-precision values use register pairs.
enum FRegister {
  F0  =  0,
  F1  =  1,
  F2  =  2,
  F3  =  3,
  F4  =  4,
  F5  =  5,
  F6  =  6,
  F7  =  7,
  F8  =  8,
  F9  =  9,
  F10 = 10,
  F11 = 11,
  F12 = 12,
  F13 = 13,
  F14 = 14,
  F15 = 15,
  F16 = 16,
  F17 = 17,
  F18 = 18,
  F19 = 19,
  F20 = 20,
  F21 = 21,
  F22 = 22,
  F23 = 23,
  F24 = 24,
  F25 = 25,
  F26 = 26,
  F27 = 27,
  F28 = 28,
  F29 = 29,
  F30 = 30,
  F31 = 31,
  kNumberOfFRegisters = 32,
  kNoFRegister = -1,
};


// Architecture independent aliases.
typedef FRegister FpuRegister;
const FpuRegister FpuTMP = F0;
const int kNumberOfFpuRegisters = kNumberOfFRegisters;
const FpuRegister kNoFpuRegister = kNoFRegister;


// Register aliases.
const Register TMP1 = AT;  // Used as scratch register by assembler.
const Register TMP2 = T9;  // Used as scratch register by assembler.
const Register TMP = TMP1;  // Arch independent flow graph compiler needs a
                            // Register called TMP.
const Register CTX = S6;  // Caches current context in generated code.
const Register PP = S7;  // Caches object pool pointer in generated code.
const Register SPREG = SP;  // Stack pointer register.
const Register FPREG = FP;  // Frame pointer register.

// The code that generates a comparison can be far away from the code that
// generates the branch that uses the result of that comparison. In this case,
// CMPRES is used for the result of the comparison.
const Register CMPRES = T8;

typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFFFFFF;


const RegList kAbiArgumentCpuRegs =
    (1 << A0) | (1 << A1) | (1 << A2) | (1 << A3);
const RegList kAbiPreservedCpuRegs =
    (1 << S0) | (1 << S1) | (1 << S2) | (1 << S3) |
    (1 << S4) | (1 << S5) | (1 << S6) | (1 << S7);
const int kAbiPreservedCpuRegCount = 8;

// FPU registers 20 - 31 are preserved across calls.
const FRegister kAbiFirstPreservedFpuReg = F20;
const FRegister kAbiLastPreservedFpuReg =
    static_cast<FRegister>(kNumberOfFRegisters - 1);

// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    (1 << R2) | (1 << R3) | (1 << R4) | (1 << R5) |
    (1 << R6) | (1 << R7) | (1 << R8) | (1 << R9) |
    (1 << R10) | (1 << R11) | (1 << R12) | (1 << R13) |
    (1 << R14) | (1 << R15) | (1 << R16) | (1 << R17) |
    (1 << R18) | (1 << R19) | (1 << R20) | (1 << R21);
const RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;
const int kDartVolatileCpuRegCount = 14;
const Register kDartFirstVolatileCpuReg = R2;
const Register kDartLastVolatileCpuReg = R15;

// FPU registers 0 - 19 are not preserved across calls.
const FRegister kDartFirstVolatileFpuReg = F0;
const FRegister kDartLastVolatileFpuReg = F19;
const int kDartVolatileFpuRegCount = 20;

// Dart stack frame layout.
static const int kLastParamSlotIndex = 3;
static const int kFirstLocalSlotIndex = -2;


// Values for the condition field.
// There is no condition field on MIPS, but Conditions are used and passed
// around by the intermediate language, so we need them here, too.
enum Condition {
  EQ,  // equal
  NE,  // not equal
  GT,  // greater than
  GE,  // greater equal
  LT,  // less than
  LE,  // less equal
  VS,  // overflow
};


// Constants used for the decoding or encoding of the individual fields of
// instructions. Based on the "Table 4.25 CPU Instruction Format Fields".
enum InstructionFields {
  kOpcodeShift = 26,
  kOpcodeBits = 6,
  kRsShift = 21,
  kRsBits = 5,
  kFmtShift = 21,
  kFmtBits = 5,
  kRtShift = 16,
  kRtBits = 5,
  kFtShift = 16,
  kFtBits = 5,
  kRdShift = 11,
  kRdBits = 5,
  kFsShift = 11,
  kFsBits = 5,
  kSaShift = 6,
  kSaBits = 5,
  kFdShift = 6,
  kFdBits = 5,
  kFunctionShift = 0,
  kFunctionBits = 6,
  kCop1FnShift = 0,
  kCop1FnBits = 6,
  kCop1SubShift = 21,
  kCop1SubBits = 5,
  kImmShift = 0,
  kImmBits = 16,
  kInstrShift = 0,
  kInstrBits = 26,
  kBreakCodeShift = 6,
  kBreakCodeBits = 20,

  kBranchOffsetMask = 0x0000ffff,
};


enum Opcode {
  SPECIAL = 0,
  REGIMM = 1,
  J = 2,
  JAL = 3,
  BEQ = 4,
  BNE = 5,
  BLEZ = 6,
  BGTZ = 7,
  ADDI = 8,
  ADDIU = 9,
  SLTI = 10,
  SLTIU = 11,
  ANDI = 12,
  ORI = 13,
  XORI = 14,
  LUI = 15,
  CPO0 = 16,
  COP1 = 17,
  COP2 = 18,
  COP1X = 19,
  BEQL = 20,
  BNEL = 21,
  BLEZL = 22,
  BGTZL = 23,
  SPECIAL2 = 28,
  JALX = 29,
  SPECIAL3 = 31,
  LB = 32,
  LH = 33,
  LWL = 34,
  LW = 35,
  LBU = 36,
  LHU = 37,
  LWR = 38,
  SB = 40,
  SH = 41,
  SWL = 42,
  SW = 43,
  SWR = 46,
  CACHE = 47,
  LL = 48,
  LWC1 = 49,
  LWC2 = 50,
  PREF = 51,
  LDC1 = 53,
  LDC2 = 54,
  SC = 56,
  SWC1 = 57,
  SWC2 = 58,
  SDC1 = 61,
  SDC2 = 62,
};


enum SpecialFunction {
  // SPECIAL opcodes.
  SLL = 0,
  MOVCI = 1,
  SRL = 2,
  SRA = 3,
  SLLV = 4,
  SRLV = 6,
  SRAV = 7,
  JR = 8,
  JALR = 9,
  MOVZ = 10,
  MOVN = 11,
  SYSCALL = 12,
  BREAK = 13,
  SYNC = 15,
  MFHI =16,
  MTHI = 17,
  MFLO = 18,
  MTLO = 19,
  MULT = 24,
  MULTU = 25,
  DIV = 26,
  DIVU = 27,
  ADD = 32,
  ADDU = 33,
  SUB = 34,
  SUBU = 35,
  AND = 36,
  OR = 37,
  XOR = 38,
  NOR = 39,
  SLT = 42,
  SLTU = 43,
  TGE = 48,
  TGEU = 49,
  TLT = 50,
  TLTU = 51,
  TEQ = 52,
  TNE = 54,

  // SPECIAL2 opcodes.
  CLZ = 32,
  CLO = 33,
};


enum RtRegImm {
  BLTZ = 0,
  BGEZ = 1,
  BLTZL = 2,
  BGEZL = 3,
  TGEI = 8,
  TGEIU = 9,
  TLTI = 10,
  TLTIU = 11,
  TEQI = 12,
  TNEI = 14,
  BLTZAL = 16,
  BGEZAL = 17,
  BLTZALL = 18,
  BGEZALL = 19,
  SYNCI = 31,
};


enum Cop1Function {
  COP1_ADD = 0,
  COP1_MOV = 6,
};

enum Cop1Sub {
  COP1_MF = 0,
  COP1_MT = 4,
};

enum Format {
  FMT_S = 16,
  FMT_D = 17,
  FMT_W = 20,
  FMT_L = 21,
  FMT_PS = 22,
};

class Instr {
 public:
  enum {
    kInstrSize = 4,
  };

  static const int32_t kBreakPointInstruction =
      (SPECIAL << kOpcodeShift) | (BREAK << kFunctionShift);
  static const int32_t kNopInstruction = 0;
  static const int32_t kStopMessageCode = 1;
  static const int32_t kRedirectCode = 2;

  // Get the raw instruction bits.
  inline int32_t InstructionBits() const {
    return *reinterpret_cast<const int32_t*>(this);
  }

  // Set the raw instruction bits to value.
  inline void SetInstructionBits(int32_t value) {
    *reinterpret_cast<int32_t*>(this) = value;
  }

  // Read one particular bit out of the instruction bits.
  inline int32_t Bit(int nr) const {
    return (InstructionBits() >> nr) & 1;
  }

  // Read a bit field out of the instruction bits.
  inline int32_t Bits(int shift, int count) const {
    return (InstructionBits() >> shift) & ((1 << count) - 1);
  }

  // Accessors to the different named fields used in the MIPS encoding.
  inline Opcode OpcodeField() const {
    return static_cast<Opcode>(Bits(kOpcodeShift, kOpcodeBits));
  }

  inline Register RsField() const {
    return static_cast<Register>(Bits(kRsShift, kRsBits));
  }

  inline Register RtField() const {
    return static_cast<Register>(Bits(kRtShift, kRtBits));
  }

  inline Register RdField() const {
    return static_cast<Register>(Bits(kRdShift, kRdBits));
  }

  inline FRegister FsField() const {
    return static_cast<FRegister>(Bits(kFsShift, kFsBits));
  }

  inline FRegister FtField() const {
    return static_cast<FRegister>(Bits(kFtShift, kFtBits));
  }

  inline FRegister FdField() const {
    return static_cast<FRegister>(Bits(kFdShift, kFdBits));
  }

  inline int SaField() const {
    return Bits(kSaShift, kSaBits);
  }

  inline int32_t UImmField() const {
    return Bits(kImmShift, kImmBits);
  }

  inline int32_t SImmField() const {
    // Sign-extend the imm field.
    return (Bits(kImmShift, kImmBits) << (32 - kImmBits)) >> (32 - kImmBits);
  }

  inline int32_t BreakCodeField() const {
    return Bits(kBreakCodeShift, kBreakCodeBits);
  }

  inline SpecialFunction FunctionField() const {
    return static_cast<SpecialFunction>(Bits(kFunctionShift, kFunctionBits));
  }

  inline RtRegImm RegImmFnField() const {
    return static_cast<RtRegImm>(Bits(kRtShift, kRtBits));
  }

  inline bool IsBreakPoint() {
    return (OpcodeField() == SPECIAL) && (FunctionField() == BREAK);
  }

  inline Cop1Function Cop1FunctionField() const {
    return static_cast<Cop1Function>(Bits(kCop1FnShift, kCop1FnBits));
  }

  inline Cop1Sub Cop1SubField() const {
    return static_cast<Cop1Sub>(Bits(kCop1SubShift, kCop1SubBits));
  }

  inline bool HasFormat() const {
    return (OpcodeField() == COP1) && (Bit(25) == 1);
  }

  inline Format FormatField() const {
    return static_cast<Format>(Bits(kFmtShift, kFmtBits));
  }

  // Instructions are read out of a code stream. The only way to get a
  // reference to an instruction is to convert a pc. There is no way
  // to allocate or create instances of class Instr.
  // Use the At(pc) function to create references to Instr.
  static Instr* At(uword pc) { return reinterpret_cast<Instr*>(pc); }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Instr);
};

}  // namespace dart

#endif  // VM_CONSTANTS_MIPS_H_
