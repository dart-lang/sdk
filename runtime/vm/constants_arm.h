// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CONSTANTS_ARM_H_
#define VM_CONSTANTS_ARM_H_

namespace dart {

// We support both VFPv3-D16 and VFPv3-D32 profiles, but currently only one at
// a time.
#define VFPv3_D16
#if defined(VFPv3_D16) == defined(VFPv3_D32)
#error "Exactly one of VFPv3_D16 or VFPv3_D32 can be defined at a time."
#endif


enum Register {
  R0  =  0,
  R1  =  1,
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
  FP  = 11,
  IP  = 12,
  SP  = 13,
  LR  = 14,
  PC  = 15,
  kNumberOfCpuRegisters = 16,
  kNoRegister = -1,
};


// Values for single-precision floating point registers.
enum SRegister {
  S0  =  0,
  S1  =  1,
  S2  =  2,
  S3  =  3,
  S4  =  4,
  S5  =  5,
  S6  =  6,
  S7  =  7,
  S8  =  8,
  S9  =  9,
  S10 = 10,
  S11 = 11,
  S12 = 12,
  S13 = 13,
  S14 = 14,
  S15 = 15,
  S16 = 16,
  S17 = 17,
  S18 = 18,
  S19 = 19,
  S20 = 20,
  S21 = 21,
  S22 = 22,
  S23 = 23,
  S24 = 24,
  S25 = 25,
  S26 = 26,
  S27 = 27,
  S28 = 28,
  S29 = 29,
  S30 = 30,
  S31 = 31,
  kNumberOfSRegisters = 32,
  kNoSRegister = -1,
};


// Values for double-precision floating point registers.
enum DRegister {
  D0  =  0,
  D1  =  1,
  D2  =  2,
  D3  =  3,
  D4  =  4,
  D5  =  5,
  D6  =  6,
  D7  =  7,
  D8  =  8,
  D9  =  9,
  D10 = 10,
  D11 = 11,
  D12 = 12,
  D13 = 13,
  D14 = 14,
  D15 = 15,
#ifdef VFPv3_D16
  kNumberOfDRegisters = 16,
#else
  D16 = 16,
  D17 = 17,
  D18 = 18,
  D19 = 19,
  D20 = 20,
  D21 = 21,
  D22 = 22,
  D23 = 23,
  D24 = 24,
  D25 = 25,
  D26 = 26,
  D27 = 27,
  D28 = 28,
  D29 = 29,
  D30 = 30,
  D31 = 31,
  kNumberOfDRegisters = 32,
#endif
  kNumberOfOverlappingDRegisters = 16,
  kNoDRegister = -1,
};


// Architecture independent aliases.
typedef DRegister FpuRegister;
const FpuRegister FpuTMP = D0;
const int kNumberOfFpuRegisters = kNumberOfDRegisters;


// Register aliases.
const Register TMP = kNoRegister;  // No scratch register used by assembler.
const Register CTX = R9;           // Caches current context in generated code.
const Register SPREG = SP;
const Register FPREG = FP;


// Exception object is passed in this register to the catch handlers when an
// exception is thrown.
const Register kExceptionObjectReg = R0;  // Unimplemented.


// Values for the condition field as defined in section A3.2.
enum Condition {
  kNoCondition = -1,
  EQ =  0,  // equal
  NE =  1,  // not equal
  CS =  2,  // carry set/unsigned higher or same
  CC =  3,  // carry clear/unsigned lower
  MI =  4,  // minus/negative
  PL =  5,  // plus/positive or zero
  VS =  6,  // overflow
  VC =  7,  // no overflow
  HI =  8,  // unsigned higher
  LS =  9,  // unsigned lower or same
  GE = 10,  // signed greater than or equal
  LT = 11,  // signed less than
  GT = 12,  // signed greater than
  LE = 13,  // signed less than or equal
  AL = 14,  // always (unconditional)
  kSpecialCondition = 15,  // special condition (refer to section A3.2.1)
  kMaxCondition = 16,
};


// Opcodes for Data-processing instructions (instructions with a type 0 and 1)
// as defined in section A3.4
enum Opcode {
  kNoOperand = -1,
  AND =  0,  // Logical AND
  EOR =  1,  // Logical Exclusive OR
  SUB =  2,  // Subtract
  RSB =  3,  // Reverse Subtract
  ADD =  4,  // Add
  ADC =  5,  // Add with Carry
  SBC =  6,  // Subtract with Carry
  RSC =  7,  // Reverse Subtract with Carry
  TST =  8,  // Test
  TEQ =  9,  // Test Equivalence
  CMP = 10,  // Compare
  CMN = 11,  // Compare Negated
  ORR = 12,  // Logical (inclusive) OR
  MOV = 13,  // Move
  BIC = 14,  // Bit Clear
  MVN = 15,  // Move Not
  kMaxOperand = 16
};


// Shifter types for Data-processing operands as defined in section A5.1.2.
enum Shift {
  kNoShift = -1,
  LSL = 0,  // Logical shift left
  LSR = 1,  // Logical shift right
  ASR = 2,  // Arithmetic shift right
  ROR = 3,  // Rotate right
  kMaxShift = 4
};


// Special Supervisor Call 24-bit codes used in the presence of the ARM
// simulator for redirection, breakpoints, stop messages, and spill markers.
// See /usr/include/asm/unistd.h
const uint32_t kRedirectionSvcCode = 0x90001f;  //  unused syscall, was sys_stty
const uint32_t kBreakpointSvcCode = 0x900020;  // unused syscall, was sys_gtty
const uint32_t kStopMessageSvcCode = 0x9f0001;  // __ARM_NR_breakpoint
const uint32_t kSpillMarkerSvcBase = 0x9f0100;  // unused ARM private syscall
const uint32_t kWordSpillMarkerSvcCode = kSpillMarkerSvcBase + 1;
const uint32_t kDWordSpillMarkerSvcCode = kSpillMarkerSvcBase + 2;


// Constants used for the decoding or encoding of the individual fields of
// instructions. Based on the "Figure 3-1 ARM instruction set summary".
enum InstructionFields {
  kConditionShift = 28,
  kConditionBits = 4,
  kTypeShift = 25,
  kTypeBits = 3,
  kLinkShift = 24,
  kLinkBits = 1,
  kUShift = 23,
  kUBits = 1,
  kOpcodeShift = 21,
  kOpcodeBits = 4,
  kSShift = 20,
  kSBits = 1,
  kRnShift = 16,
  kRnBits = 4,
  kRdShift = 12,
  kRdBits = 4,
  kRsShift = 8,
  kRsBits = 4,
  kRmShift = 0,
  kRmBits = 4,

  // Immediate instruction fields encoding.
  kRotateShift = 8,
  kRotateBits = 4,
  kImmed8Shift = 0,
  kImmed8Bits = 8,

  // Shift instruction register fields encodings.
  kShiftImmShift = 7,
  kShiftRegisterShift = 8,
  kShiftImmBits = 5,
  kShiftShift = 5,
  kShiftBits = 2,

  // Load/store instruction offset field encoding.
  kOffset12Shift = 0,
  kOffset12Bits = 12,
  kOffset12Mask = 0x00000fff,

  // Mul instruction register fields encodings.
  kMulRdShift = 16,
  kMulRdBits = 4,
  kMulRnShift = 12,
  kMulRnBits = 4,

  kBranchOffsetMask = 0x00ffffff
};


// The class Instr enables access to individual fields defined in the ARM
// architecture instruction set encoding as described in figure A3-1.
//
// Example: Test whether the instruction at ptr sets the condition code bits.
//
// bool InstructionSetsConditionCodes(byte* ptr) {
//   Instr* instr = Instr::At(ptr);
//   int type = instr->TypeField();
//   return ((type == 0) || (type == 1)) && instr->HasS();
// }
//
class Instr {
 public:
  enum {
    kInstrSize = 4,
    kInstrSizeLog2 = 2,
    kPCReadOffset = 8
  };

  static const int kBreakPointInstructionSize = kInstrSize;
  bool IsBreakPoint() {
    return IsBkpt();
  }

  // Get the raw instruction bits.
  inline int32_t InstructionBits() const {
    return *reinterpret_cast<const int32_t*>(this);
  }

  // Set the raw instruction bits to value.
  inline void SetInstructionBits(int32_t value) {
    *reinterpret_cast<int32_t*>(this) = value;
  }

  // Read one particular bit out of the instruction bits.
  inline int Bit(int nr) const {
    return (InstructionBits() >> nr) & 1;
  }

  // Read a bit field out of the instruction bits.
  inline int Bits(int shift, int count) const {
    return (InstructionBits() >> shift) & ((1 << count) - 1);
  }


  // Accessors for the different named fields used in the ARM encoding.
  // The naming of these accessor corresponds to figure A3-1.
  // Generally applicable fields
  inline Condition ConditionField() const {
    return static_cast<Condition>(Bits(kConditionShift, kConditionBits));
  }
  inline int TypeField() const { return Bits(kTypeShift, kTypeBits); }

  inline Register RnField() const { return static_cast<Register>(
                                        Bits(kRnShift, kRnBits)); }
  inline Register RdField() const { return static_cast<Register>(
                                        Bits(kRdShift, kRdBits)); }

  // Fields used in Data processing instructions
  inline Opcode OpcodeField() const {
    return static_cast<Opcode>(Bits(kOpcodeShift, kOpcodeBits));
  }
  inline int SField() const { return Bits(kSShift, kSBits); }
  // with register
  inline Register RmField() const {
    return static_cast<Register>(Bits(kRmShift, kRmBits));
  }
  inline Shift ShiftField() const { return static_cast<Shift>(
                                        Bits(kShiftShift, kShiftBits)); }
  inline int RegShiftField() const { return Bit(4); }
  inline Register RsField() const {
    return static_cast<Register>(Bits(kRsShift, kRsBits));
  }
  inline int ShiftAmountField() const { return Bits(kShiftImmShift,
                                                    kShiftImmBits); }
  // with immediate
  inline int RotateField() const { return Bits(kRotateShift, kRotateBits); }
  inline int Immed8Field() const { return Bits(kImmed8Shift, kImmed8Bits); }

  // Fields used in Load/Store instructions
  inline int PUField() const { return Bits(23, 2); }
  inline int  BField() const { return Bit(22); }
  inline int  WField() const { return Bit(21); }
  inline int  LField() const { return Bit(20); }
  // with register uses same fields as Data processing instructions above
  // with immediate
  inline int Offset12Field() const { return Bits(kOffset12Shift,
                                                 kOffset12Bits); }
  // multiple
  inline int RlistField() const { return Bits(0, 16); }
  // extra loads and stores
  inline int SignField() const { return Bit(6); }
  inline int HField() const { return Bit(5); }
  inline int ImmedHField() const { return Bits(8, 4); }
  inline int ImmedLField() const { return Bits(0, 4); }

  // Fields used in Branch instructions
  inline int LinkField() const { return Bits(kLinkShift, kLinkBits); }
  inline int SImmed24Field() const { return ((InstructionBits() << 8) >> 8); }

  // Fields used in Supervisor Call instructions
  inline uint32_t SvcField() const { return Bits(0, 24); }

  // Field used in Breakpoint instruction
  inline uint16_t BkptField() const {
    return ((Bits(8, 12) << 4) | Bits(0, 4));
  }

  // Field used in 16-bit immediate move instructions
  inline uint16_t MovwField() const {
    return ((Bits(16, 4) << 12) | Bits(0, 12));
  }

  // Field used in VFP float immediate move instruction
  inline float ImmFloatField() const {
    uint32_t imm32 = (Bit(19) << 31) | (((1 << 5) - Bit(18)) << 25) |
                     (Bits(16, 2) << 23) | (Bits(0, 4) << 19);
    return bit_cast<float, uint32_t>(imm32);
  }

  // Field used in VFP double immediate move instruction
  inline double ImmDoubleField() const {
    uint64_t imm64 = (Bit(19)*(1LL << 63)) | (((1LL << 8) - Bit(18)) << 54) |
                     (Bits(16, 2)*(1LL << 52)) | (Bits(0, 4)*(1LL << 48));
    return bit_cast<double, uint64_t>(imm64);
  }

  // Test for data processing instructions of type 0 or 1.
  // See "ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition",
  // section A5.1 "ARM instruction set encoding".
  inline bool IsDataProcessing() const {
    ASSERT(ConditionField() != kSpecialCondition);
    ASSERT(Bits(26, 2) == 0);  // Type 0 or 1.
    return ((Bits(20, 5) & 0x19) != 0x10) &&
      ((Bit(25) == 1) ||  // Data processing immediate.
       (Bit(4) == 0) ||  // Data processing register.
       (Bit(7) == 0));  // Data processing register-shifted register.
  }

  // Tests for special encodings of type 0 instructions (extra loads and stores,
  // as well as multiplications, synchronization primitives, and miscellaneous).
  // Can only be called for a type 0 or 1 instruction.
  inline bool IsMiscellaneous() const {
    ASSERT(Bits(26, 2) == 0);  // Type 0 or 1.
    return ((Bit(25) == 0) && ((Bits(20, 5) & 0x19) == 0x10) && (Bit(7) == 0));
  }
  inline bool IsMultiplyOrSyncPrimitive() const {
    ASSERT(Bits(26, 2) == 0);  // Type 0 or 1.
    return ((Bit(25) == 0) && (Bits(4, 4) == 9));
  }

  // Test for Supervisor Call instruction.
  inline bool IsSvc() const {
    return ((InstructionBits() & 0xff000000) == 0xef000000);
  }

  // Test for Breakpoint instruction.
  inline bool IsBkpt() const {
    return ((InstructionBits() & 0xfff000f0) == 0xe1200070);
  }

  // VFP register fields.
  inline SRegister SnField() const {
    return static_cast<SRegister>((Bits(kRnShift, kRnBits) << 1) + Bit(7));
  }
  inline SRegister SdField() const {
    return static_cast<SRegister>((Bits(kRdShift, kRdBits) << 1) + Bit(22));
  }
  inline SRegister SmField() const {
    return static_cast<SRegister>((Bits(kRmShift, kRmBits) << 1) + Bit(5));
  }
  inline DRegister DnField() const {
    return static_cast<DRegister>(Bits(kRnShift, kRnBits) + (Bit(7) << 4));
  }
  inline DRegister DdField() const {
    return static_cast<DRegister>(Bits(kRdShift, kRdBits) + (Bit(22) << 4));
  }
  inline DRegister DmField() const {
    return static_cast<DRegister>(Bits(kRmShift, kRmBits) + (Bit(5) << 4));
  }

  // Test for VFP data processing or single transfer instructions of type 7.
  inline bool IsVFPDataProcessingOrSingleTransfer() const {
    ASSERT(ConditionField() != kSpecialCondition);
    ASSERT(TypeField() == 7);
    return ((Bit(24) == 0) && (Bits(9, 3) == 5));
    // Bit(4) == 0: Data Processing
    // Bit(4) == 1: 8, 16, or 32-bit Transfer between ARM Core and VFP
  }

  // Test for VFP 64-bit transfer instructions of type 6.
  inline bool IsVFPDoubleTransfer() const {
    ASSERT(ConditionField() != kSpecialCondition);
    ASSERT(TypeField() == 6);
    return ((Bits(21, 4) == 2) && (Bits(9, 3) == 5) &&
            ((Bits(4, 4) & 0xd) == 1));
  }

  // Test for VFP load and store instructions of type 6.
  inline bool IsVFPLoadStore() const {
    ASSERT(ConditionField() != kSpecialCondition);
    ASSERT(TypeField() == 6);
    return ((Bits(20, 5) & 0x12) == 0x10) && (Bits(9, 3) == 5);
  }

  // Special accessors that test for existence of a value.
  inline bool HasS()    const { return SField() == 1; }
  inline bool HasB()    const { return BField() == 1; }
  inline bool HasW()    const { return WField() == 1; }
  inline bool HasL()    const { return LField() == 1; }
  inline bool HasSign() const { return SignField() == 1; }
  inline bool HasH()    const { return HField() == 1; }
  inline bool HasLink() const { return LinkField() == 1; }

  // Instructions are read out of a code stream. The only way to get a
  // reference to an instruction is to convert a pointer. There is no way
  // to allocate or create instances of class Instr.
  // Use the At(pc) function to create references to Instr.
  static Instr* At(uword pc) { return reinterpret_cast<Instr*>(pc); }
  Instr* Next() { return this + kInstrSize; }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Instr);
};

}  // namespace dart

#endif  // VM_CONSTANTS_ARM_H_
