// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_MIPS_H_
#define RUNTIME_VM_CONSTANTS_MIPS_H_

#include "platform/assert.h"

namespace dart {

enum Register {
  R0 = 0,
  R1 = 1,  // AT aka TMP
  R2 = 2,
  R3 = 3,
  R4 = 4,
  R5 = 5,
  R6 = 6,
  R7 = 7,
  R8 = 8,
  R9 = 9,
  R10 = 10,
  R11 = 11,
  R12 = 12,
  R13 = 13,
  R14 = 14,
  R15 = 15,
  R16 = 16,
  R17 = 17,
  R18 = 18,
  R19 = 19,  // THR
  R20 = 20,
  R21 = 21,
  R22 = 22,  // CTX
  R23 = 23,  // PP
  R24 = 24,
  R25 = 25,
  R26 = 26,
  R27 = 27,
  R28 = 28,
  R29 = 29,  // SP
  R30 = 30,  // FP
  R31 = 31,  // RA
  kNumberOfCpuRegisters = 32,
  IMM = 32,  // Positive value is easier to encode than kNoRegister in bitfield.
  kNoRegister = -1,  // Signals an illegal register.


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
  F0 = 0,
  F1 = 1,
  F2 = 2,
  F3 = 3,
  F4 = 4,
  F5 = 5,
  F6 = 6,
  F7 = 7,
  F8 = 8,
  F9 = 9,
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

// The double precision floating point registers are concatenated pairs of the
// single precision registers, e.g. D0 is F1:F0, D1 is F3:F2, etc.. We only
// tell the architecture generic code about the double precision registers, then
// convert to the single precision registers when needed in the mips-specific
// code.
enum DRegister {
  D0 = 0,    // Function return value 1.
  D1 = 1,    // Function return value 2.
  D2 = 2,    // Not preserved.
  D3 = 3,    // Not preserved.
  D4 = 4,    // Not preserved.
  D5 = 5,    // Not preserved.
  D6 = 6,    // Argument 1.
  D7 = 7,    // Argument 2.
  D8 = 8,    // Not preserved.
  D9 = 9,    // Not preserved.
  D10 = 10,  // Preserved.
  D11 = 11,  // Preserved.
  D12 = 12,  // Preserved.
  D13 = 13,  // Preserved.
  D14 = 14,  // Preserved.
  D15 = 15,  // Preserved.
  kNumberOfDRegisters = 16,
  kNoDRegister = -1,
};

static inline FRegister EvenFRegisterOf(DRegister d) {
  return static_cast<FRegister>(d * 2);
}

static inline FRegister OddFRegisterOf(DRegister d) {
  return static_cast<FRegister>((d * 2) + 1);
}

const DRegister DTMP = D9;
const FRegister STMP1 = F18;
const FRegister STMP2 = F19;

// Architecture independent aliases.
typedef DRegister FpuRegister;
const FpuRegister FpuTMP = DTMP;
const int kNumberOfFpuRegisters = kNumberOfDRegisters;
const FpuRegister kNoFpuRegister = kNoDRegister;


// Register aliases.
const Register TMP = AT;            // Used as scratch register by assembler.
const Register TMP2 = kNoRegister;  // No second assembler scratch register.
const Register CTX = S6;  // Location of current context at method entry.
const Register CODE_REG = S6;
const Register PP = S7;     // Caches object pool pointer in generated code.
const Register SPREG = SP;  // Stack pointer register.
const Register FPREG = FP;  // Frame pointer register.
const Register LRREG = RA;  // Link register.
const Register ICREG = S5;  // IC data register.
const Register ARGS_DESC_REG = S4;
const Register THR = S3;  // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = S5;

// The code that generates a comparison can be far away from the code that
// generates the branch that uses the result of that comparison. In this case,
// CMPRES1 and CMPRES2 are used for the results of the comparison. We need two
// since TMP is clobbered by a far branch.
const Register CMPRES1 = T8;
const Register CMPRES2 = T9;

// Exception object is passed in this register to the catch handlers when an
// exception is thrown.
const Register kExceptionObjectReg = V0;

// Stack trace object is passed in this register to the catch handlers when
// an exception is thrown.
const Register kStackTraceObjectReg = V1;


typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFFFFFF;

const RegList kAbiArgumentCpuRegs =
    (1 << A0) | (1 << A1) | (1 << A2) | (1 << A3);
const RegList kAbiPreservedCpuRegs = (1 << S0) | (1 << S1) | (1 << S2) |
                                     (1 << S3) | (1 << S4) | (1 << S5) |
                                     (1 << S6) | (1 << S7);
const int kAbiPreservedCpuRegCount = 8;

// FPU registers 20 - 31 are preserved across calls.
const FRegister kAbiFirstPreservedFpuReg = F20;
const FRegister kAbiLastPreservedFpuReg =
    static_cast<FRegister>(kNumberOfFRegisters - 1);
const int kAbiPreservedFpuRegCount = 12;

const RegList kReservedCpuRegisters =
    (1 << SPREG) | (1 << FPREG) | (1 << TMP) | (1 << PP) | (1 << THR) |
    (1 << CTX) | (1 << ZR) | (1 << CMPRES1) | (1 << CMPRES2) | (1 << K0) |
    (1 << K1) | (1 << GP) | (1 << RA);
// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
// Registers available to Dart that are not preserved by runtime calls.
const RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;
const int kDartVolatileCpuRegCount = 14;
const Register kDartFirstVolatileCpuReg = R2;
const Register kDartLastVolatileCpuReg = R15;

// FPU registers 0 - 19 are not preserved across calls.
const FRegister kDartFirstVolatileFpuReg = F0;
const FRegister kDartLastVolatileFpuReg = F19;
const int kDartVolatileFpuRegCount = 20;


// There is no status register on MIPS. Instead of representing a condition
// code, type Condition (see assembler_mips.h) represents a pair of operands and
// a relation operator between them.
enum RelationOperator {
  AL,   // always
  NV,   // never
  EQ,   // equal
  NE,   // not equal
  GT,   // greater than
  GE,   // greater equal
  LT,   // less than
  LE,   // less equal
  UGT,  // unsigned greater than
  UGE,  // unsigned greater equal
  ULT,  // unsigned less than
  ULE,  // unsigned less equal
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
  kFpuCCShift = 8,
  kFpuCCBits = 3,

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
  MFHI = 16,
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
  MADD = 0,
  MADDU = 1,
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
  COP1_ADD = 0x00,
  COP1_SUB = 0x01,
  COP1_MUL = 0x02,
  COP1_DIV = 0x03,
  COP1_SQRT = 0x04,
  COP1_MOV = 0x06,
  COP1_NEG = 0x07,
  COP1_TRUNC_W = 0x0d,
  COP1_CVT_S = 0x20,
  COP1_CVT_D = 0x21,
  COP1_C_F = 0x30,
  COP1_C_UN = 0x31,
  COP1_C_EQ = 0x32,
  COP1_C_UEQ = 0x33,
  COP1_C_OLT = 0x34,
  COP1_C_ULT = 0x35,
  COP1_C_OLE = 0x36,
  COP1_C_ULE = 0x37,
};


enum Cop1Sub {
  COP1_MF = 0,
  COP1_MT = 4,
  COP1_BC = 8,
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

  static const int32_t kNopInstruction = 0;

  // Reserved break instruction codes.
  static const int32_t kBreakPointCode = 0xdeb0;      // For breakpoint.
  static const int32_t kStopMessageCode = 0xdeb1;     // For Stop(message).
  static const int32_t kSimulatorBreakCode = 0xdeb2;  // For breakpoint in sim.
  static const int32_t kSimulatorRedirectCode = 0xca11;  // For redirection.

  static const int32_t kBreakPointZeroInstruction =
      (SPECIAL << kOpcodeShift) | (BREAK << kFunctionShift);

  // Breakpoint instruction filling assembler code buffers in debug mode.
  static const int32_t kBreakPointInstruction =
      kBreakPointZeroInstruction | (kBreakPointCode << kBreakCodeShift);

  // Breakpoint instruction used by the simulator.
  // Should be distinct from kBreakPointInstruction and from a typical user
  // breakpoint inserted in generated code for debugging, e.g. break_(0).
  static const int32_t kSimulatorBreakpointInstruction =
      kBreakPointZeroInstruction | (kSimulatorBreakCode << kBreakCodeShift);

  // Runtime call redirection instruction used by the simulator.
  static const int32_t kSimulatorRedirectInstruction =
      kBreakPointZeroInstruction | (kSimulatorRedirectCode << kBreakCodeShift);

  // Get the raw instruction bits.
  inline int32_t InstructionBits() const {
    return *reinterpret_cast<const int32_t*>(this);
  }

  // Set the raw instruction bits to value.
  inline void SetInstructionBits(int32_t value) {
    *reinterpret_cast<int32_t*>(this) = value;
  }

  inline void SetImmInstrBits(Opcode op,
                              Register rs,
                              Register rt,
                              uint16_t imm) {
    SetInstructionBits(op << kOpcodeShift | rs << kRsShift | rt << kRtShift |
                       imm << kImmShift);
  }

  inline void SetSpecialInstrBits(SpecialFunction f,
                                  Register rs,
                                  Register rt,
                                  Register rd) {
    SetInstructionBits(SPECIAL << kOpcodeShift | f << kFunctionShift |
                       rs << kRsShift | rt << kRtShift | rd << kRdShift);
  }

  // Read one particular bit out of the instruction bits.
  inline int32_t Bit(int nr) const { return (InstructionBits() >> nr) & 1; }

  // Read a bit field out of the instruction bits.
  inline int32_t Bits(int shift, int count) const {
    return (InstructionBits() >> shift) & ((1 << count) - 1);
  }

  // Accessors to the different named fields used in the MIPS encoding.
  inline Opcode OpcodeField() const {
    return static_cast<Opcode>(Bits(kOpcodeShift, kOpcodeBits));
  }

  inline void SetOpcodeField(Opcode b) {
    int32_t instr = InstructionBits();
    int32_t mask = ((1 << kOpcodeBits) - 1) << kOpcodeShift;
    SetInstructionBits((b << kOpcodeShift) | (instr & ~mask));
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

  inline int SaField() const { return Bits(kSaShift, kSaBits); }

  inline int32_t UImmField() const { return Bits(kImmShift, kImmBits); }

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

  inline void SetRegImmFnField(RtRegImm b) {
    int32_t instr = InstructionBits();
    int32_t mask = ((1 << kRtBits) - 1) << kRtShift;
    SetInstructionBits((b << kRtShift) | (instr & ~mask));
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

  inline int32_t FpuCCField() const { return Bits(kFpuCCShift, kFpuCCBits); }

  // Instructions are read out of a code stream. The only way to get a
  // reference to an instruction is to convert a pc. There is no way
  // to allocate or create instances of class Instr.
  // Use the At(pc) function to create references to Instr.
  static Instr* At(uword pc) { return reinterpret_cast<Instr*>(pc); }

#if defined(DEBUG)
  inline void AssertIsImmInstr(Opcode op,
                               Register rs,
                               Register rt,
                               int32_t imm) {
    ASSERT((OpcodeField() == op) && (RsField() == rs) && (RtField() == rt) &&
           (SImmField() == imm));
  }

  inline void AssertIsSpecialInstr(SpecialFunction f,
                                   Register rs,
                                   Register rt,
                                   Register rd) {
    ASSERT((OpcodeField() == SPECIAL) && (FunctionField() == f) &&
           (RsField() == rs) && (RtField() == rt) && (RdField() == rd));
  }
#endif  // defined(DEBUG)

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Instr);
};

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_MIPS_H_
