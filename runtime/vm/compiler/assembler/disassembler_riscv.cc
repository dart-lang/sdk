// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_RISCV.
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#include "vm/compiler/assembler/disassembler.h"

#include "platform/assert.h"
#include "vm/instructions.h"

namespace dart {

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

// We deviate from objdump in two places:
//  - branches display displacements instead of targets so our output is
//    position independent for tests.
//  - auipc/lui display the decoded value instead of the encoded value
class RISCVDisassembler {
 public:
  explicit RISCVDisassembler(char* buffer,
                             size_t buffer_size,
                             ExtensionSet extensions)
      : extensions_(extensions),
        buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0) {}

  bool Supports(Extension extension) const {
    return extensions_.Includes(extension);
  }
  bool Supports(ExtensionSet extensions) const {
    return extensions_.IncludesAll(extensions);
  }

  intptr_t Disassemble(uword pc) {
    uint16_t parcel = *reinterpret_cast<uint16_t*>(pc);
    if (Supports(RV_C) && IsCInstruction(parcel)) {
      CInstr instr(parcel);
      DisassembleInstruction(instr);
      return instr.length();
    } else {
      uint32_t parcel = LoadUnaligned(reinterpret_cast<uint32_t*>(pc));
      Instr instr(parcel);
      DisassembleInstruction(instr);
      return instr.length();
    }
  }

 private:
  void DisassembleInstruction(Instr instr);
  void DisassembleInstruction(CInstr instr);
  void DisassembleLUI(Instr instr);
  void DisassembleAUIPC(Instr instr);
  void DisassembleJAL(Instr instr);
  void DisassembleJALR(Instr instr);
  void DisassembleBRANCH(Instr instr);
  void DisassembleLOAD(Instr instr);
  void DisassembleSTORE(Instr instr);
  void DisassembleOPIMM(Instr instr);
  void DisassembleOPIMM32(Instr instr);
  void DisassembleOP(Instr instr);
  void DisassembleOP_0(Instr instr);
  void DisassembleOP_SUB(Instr instr);
  void DisassembleOP_MULDIV(Instr instr);
  void DisassembleOP_SHADD(Instr instr);
  void DisassembleOP_MINMAXCLMUL(Instr instr);
  void DisassembleOP_ROTATE(Instr instr);
  void DisassembleOP_BCLRBEXT(Instr instr);
  void DisassembleOP32(Instr instr);
  void DisassembleOP32_0(Instr instr);
  void DisassembleOP32_SUB(Instr instr);
  void DisassembleOP32_MULDIV(Instr instr);
  void DisassembleOP32_SHADD(Instr instr);
  void DisassembleOP32_ADDUW(Instr instr);
  void DisassembleOP32_ROTATE(Instr instr);
  void DisassembleMISCMEM(Instr instr);
  void DisassembleSYSTEM(Instr instr);
  void DisassembleAMO(Instr instr);
  void DisassembleAMO32(Instr instr);
  void DisassembleAMO64(Instr instr);
  void DisassembleLOADFP(Instr instr);
  void DisassembleSTOREFP(Instr instr);
  void DisassembleFMADD(Instr instr);
  void DisassembleFMSUB(Instr instr);
  void DisassembleFNMADD(Instr instr);
  void DisassembleFNMSUB(Instr instr);
  void DisassembleOPFP(Instr instr);

  void UnknownInstruction(Instr instr);
  void UnknownInstruction(CInstr instr);

  void Print(const char* format, Instr instr, ExtensionSet extension);
  void Print(const char* format, CInstr instr, ExtensionSet extension);
  const char* PrintOption(const char* format, Instr instr);
  const char* PrintOption(const char* format, CInstr instr);

  void Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3) {
    va_list args;
    va_start(args, format);
    intptr_t len = Utils::VSNPrint(buffer_ + buffer_pos_,
                                   buffer_size_ - buffer_pos_, format, args);
    va_end(args);
    buffer_pos_ += len;
    buffer_[buffer_pos_] = '\0';
  }

  const ExtensionSet extensions_;
  char* buffer_;        // Decode instructions into this buffer.
  size_t buffer_size_;  // The size of the character buffer.
  size_t buffer_pos_;   // Current character position in buffer.
};

void RISCVDisassembler::DisassembleInstruction(Instr instr) {
  switch (instr.opcode()) {
    case LUI:
      DisassembleLUI(instr);
      break;
    case AUIPC:
      DisassembleAUIPC(instr);
      break;
    case JAL:
      DisassembleJAL(instr);
      break;
    case JALR:
      DisassembleJALR(instr);
      break;
    case BRANCH:
      DisassembleBRANCH(instr);
      break;
    case LOAD:
      DisassembleLOAD(instr);
      break;
    case STORE:
      DisassembleSTORE(instr);
      break;
    case OPIMM:
      DisassembleOPIMM(instr);
      break;
    case OPIMM32:
      DisassembleOPIMM32(instr);
      break;
    case OP:
      DisassembleOP(instr);
      break;
    case OP32:
      DisassembleOP32(instr);
      break;
    case MISCMEM:
      DisassembleMISCMEM(instr);
      break;
    case SYSTEM:
      DisassembleSYSTEM(instr);
      break;
    case AMO:
      DisassembleAMO(instr);
      break;
    case LOADFP:
      DisassembleLOADFP(instr);
      break;
    case STOREFP:
      DisassembleSTOREFP(instr);
      break;
    case FMADD:
      DisassembleFMADD(instr);
      break;
    case FMSUB:
      DisassembleFMSUB(instr);
      break;
    case FNMADD:
      DisassembleFNMADD(instr);
      break;
    case FNMSUB:
      DisassembleFNMSUB(instr);
      break;
    case OPFP:
      DisassembleOPFP(instr);
      break;
    default:
      if ((instr.encoding() == 0) ||
          (instr.encoding() == static_cast<uint32_t>(-1))) {
        Print("trap", instr, RV_I);
        break;
      }
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleInstruction(CInstr instr) {
  switch (instr.opcode()) {
    case C_LWSP:
      Print("lw 'rd, 'spload4imm(sp)", instr, RV_C);
      break;
#if XLEN == 32
    case C_FLWSP:
      Print("flw 'frd, 'spload4imm(sp)", instr, RV_C | RV_F);
      break;
#else
    case C_LDSP:
      Print("ld 'rd, 'spload8imm(sp)", instr, RV_C);
      break;
#endif
    case C_FLDSP:
      Print("fld 'frd, 'spload8imm(sp)", instr, RV_C | RV_D);
      break;
    case C_SWSP:
      Print("sw 'rs2, 'spstore4imm(sp)", instr, RV_C);
      break;
#if XLEN == 32
    case C_FSWSP:
      Print("fsw 'frs2, 'spstore4imm(sp)", instr, RV_C | RV_F);
      break;
#else
    case C_SDSP:
      Print("sd 'rs2, 'spstore8imm(sp)", instr, RV_C);
      break;
#endif
    case C_FSDSP:
      Print("fsd 'frs2, 'spstore8imm(sp)", instr, RV_C | RV_D);
      break;
    case C_LW:
      Print("lw 'rdp, 'mem4imm('rs1p)", instr, RV_C);
      break;
#if XLEN == 32
    case C_FLW:
      Print("flw 'frdp, 'mem4imm('rs1p)", instr, RV_C | RV_F);
      break;
#else
    case C_LD:
      Print("ld 'rdp, 'mem8imm('rs1p)", instr, RV_C);
      break;
#endif
    case C_FLD:
      Print("fld 'frdp, 'mem8imm('rs1p)", instr, RV_C | RV_D);
      break;
    case C_SW:
      Print("sw 'rs2p, 'mem4imm('rs1p)", instr, RV_C);
      break;
#if XLEN == 32
    case C_FSW:
      Print("fsw 'frs2p, 'mem4imm('rs1p)", instr, RV_C | RV_F);
      break;
#else
    case C_SD:
      Print("sd 'rs2p, 'mem8imm('rs1p)", instr, RV_C);
      break;
#endif
    case C_FSD:
      Print("fsd 'frs2p, 'mem8imm('rs1p)", instr, RV_C | RV_F);
      break;
    case C_J:
      Print("j 'jimm", instr, RV_C);
      break;
#if XLEN == 32
    case C_JAL:
      Print("jal 'jimm", instr, RV_C);
      break;
#endif
    case C_JR:
      if ((instr.encoding() & (C_JALR ^ C_JR)) != 0) {
        if ((instr.rs1() == ZR) && (instr.rs2() == ZR)) {
          Print("ebreak", instr, RV_C);
        } else if (instr.rs2() == ZR) {
          Print("jalr 'rs1", instr, RV_C);
        } else {
          Print("add 'rd, 'rs1, 'rs2", instr, RV_C);
        }
      } else {
        if (instr.rd() != ZR && instr.rs2() != ZR) {
          Print("mv 'rd, 'rs2", instr, RV_C);
        } else if (instr.rs2() != ZR) {
          UnknownInstruction(instr);
        } else if (instr.rs1() == RA) {
          Print("ret", instr, RV_C);
        } else {
          Print("jr 'rs1", instr, RV_C);
        }
      }
      break;
    case C_BEQZ:
      Print("beqz 'rs1p, 'bimm", instr, RV_C);
      break;
    case C_BNEZ:
      Print("bnez 'rs1p, 'bimm", instr, RV_C);
      break;
    case C_LI:
      Print("li 'rd, 'iimm", instr, RV_C);
      break;
    case C_LUI:
      if (instr.rd() == SP) {
        Print("addi 'rd, 'rs1, 'i16imm", instr, RV_C);
      } else {
        Print("lui 'rd, 'uimm", instr, RV_C);
      }
      break;
    case C_ADDI:
      if ((instr.rd() == ZR) && (instr.rs1() == ZR) && (instr.i_imm() == 0)) {
        Print("nop", instr, RV_C);
      } else {
        Print("addi 'rd, 'rs1, 'iimm", instr, RV_C);
      }
      break;
#if XLEN >= 64
    case C_ADDIW:
      if (instr.i_imm() == 0) {
        Print("sext.w 'rd, 'rs1", instr, RV_C);
      } else {
        Print("addiw 'rd, 'rs1, 'iimm", instr, RV_C);
      }
      break;
#endif
    case C_ADDI4SPN:
      if (instr.i4spn_imm() == 0) {
        UnknownInstruction(instr);
      } else {
        Print("addi 'rdp, sp, 'i4spnimm", instr, RV_C);
      }
      break;
    case C_SLLI:
      if (instr.i_imm() == 0) {
        UnknownInstruction(instr);
      } else {
        Print("slli 'rd, 'rs1, 'iimm", instr, RV_C);
      }
      break;
    case C_MISCALU:
      switch (instr.encoding() & C_MISCALU_MASK) {
        case C_SRLI:
          if (instr.i_imm() == 0) {
            UnknownInstruction(instr);
          } else {
            Print("srli 'rs1p, 'rs1p, 'iimm", instr, RV_C);
          }
          break;
        case C_SRAI:
          if (instr.i_imm() == 0) {
            UnknownInstruction(instr);
          } else {
            Print("srai 'rs1p, 'rs1p, 'iimm", instr, RV_C);
          }
          break;
        case C_ANDI:
          Print("andi 'rs1p, 'rs1p, 'iimm", instr, RV_C);
          break;
        case C_RR:
          switch (instr.encoding() & C_RR_MASK) {
            case C_AND:
              Print("and 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
            case C_OR:
              Print("or 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
            case C_XOR:
              Print("xor 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
            case C_SUB:
              Print("sub 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
#if XLEN >= 64
            case C_ADDW:
              Print("addw 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
            case C_SUBW:
              Print("subw 'rs1p, 'rs1p, 'rs2p", instr, RV_C);
              break;
#endif
            default:
              UnknownInstruction(instr);
          }
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    default:
      if ((instr.encoding() == 0) ||
          (instr.encoding() == static_cast<uint16_t>(-1))) {
        Print("trap", instr, RV_C);
        break;
      }
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleLUI(Instr instr) {
  Print("lui 'rd, 'uimm", instr, RV_I);
}

void RISCVDisassembler::DisassembleAUIPC(Instr instr) {
  Print("auipc 'rd, 'uimm", instr, RV_I);
}

void RISCVDisassembler::DisassembleJAL(Instr instr) {
  if (instr.rd() == ZR) {
    Print("j 'jimm", instr, RV_I);
  } else if (instr.rd() == RA) {
    Print("jal 'jimm", instr, RV_I);
  } else {
    Print("jal 'rd, 'jimm", instr, RV_I);
  }
}

void RISCVDisassembler::DisassembleJALR(Instr instr) {
  if (instr.rd() == ZR) {
    if ((instr.rs1() == RA) && (instr.itype_imm() == 0)) {
      Print("ret", instr, RV_I);
    } else if (instr.itype_imm() == 0) {
      Print("jr 'rs1", instr, RV_I);
    } else {
      Print("jr 'iimm('rs1)", instr, RV_I);
    }
  } else if (instr.rd() == RA) {
    if (instr.itype_imm() == 0) {
      Print("jalr 'rs1", instr, RV_I);
    } else {
      Print("jalr 'iimm('rs1)", instr, RV_I);
    }
  } else {
    if (instr.itype_imm() == 0) {
      Print("jalr 'rd, 'rs1", instr, RV_I);
    } else {
      Print("jalr 'rd, 'iimm('rs1)", instr, RV_I);
    }
  }
}

void RISCVDisassembler::DisassembleBRANCH(Instr instr) {
  switch (instr.funct3()) {
    case BEQ:
      if (instr.rs2() == ZR) {
        Print("beqz 'rs1, 'bimm", instr, RV_I);
      } else {
        Print("beq 'rs1, 'rs2, 'bimm", instr, RV_I);
      }
      break;
    case BNE:
      if (instr.rs2() == ZR) {
        Print("bnez 'rs1, 'bimm", instr, RV_I);
      } else {
        Print("bne 'rs1, 'rs2, 'bimm", instr, RV_I);
      }
      break;
    case BLT:
      if (instr.rs2() == ZR) {
        Print("bltz 'rs1, 'bimm", instr, RV_I);
      } else if (instr.rs1() == ZR) {
        Print("bgtz 'rs2, 'bimm", instr, RV_I);
      } else {
        Print("blt 'rs1, 'rs2, 'bimm", instr, RV_I);
      }
      break;
    case BGE:
      if (instr.rs2() == ZR) {
        Print("bgez 'rs1, 'bimm", instr, RV_I);
      } else if (instr.rs1() == ZR) {
        Print("blez 'rs2, 'bimm", instr, RV_I);
      } else {
        Print("ble 'rs2, 'rs1, 'bimm", instr, RV_I);
      }
      break;
    case BLTU:
      Print("bltu 'rs1, 'rs2, 'bimm", instr, RV_I);
      break;
    case BGEU:
      Print("bleu 'rs2, 'rs1, 'bimm", instr, RV_I);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleLOAD(Instr instr) {
  switch (instr.funct3()) {
    case LB:
      Print("lb 'rd, 'iimm('rs1)", instr, RV_I);
      break;
    case LH:
      Print("lh 'rd, 'iimm('rs1)", instr, RV_I);
      break;
    case LW:
      Print("lw 'rd, 'iimm('rs1)", instr, RV_I);
      break;
    case LBU:
      Print("lbu 'rd, 'iimm('rs1)", instr, RV_I);
      break;
    case LHU:
      Print("lhu 'rd, 'iimm('rs1)", instr, RV_I);
      break;
#if XLEN >= 64
    case LWU:
      Print("lwu 'rd, 'iimm('rs1)", instr, RV_I);
      break;
    case LD:
      Print("ld 'rd, 'iimm('rs1)", instr, RV_I);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleLOADFP(Instr instr) {
  switch (instr.funct3()) {
    case S:
      Print("flw 'frd, 'iimm('rs1)", instr, RV_F);
      break;
    case D:
      Print("fld 'frd, 'iimm('rs1)", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleSTORE(Instr instr) {
  switch (instr.funct3()) {
    case SB:
      Print("sb 'rs2, 'simm('rs1)", instr, RV_I);
      break;
    case SH:
      Print("sh 'rs2, 'simm('rs1)", instr, RV_I);
      break;
    case SW:
      Print("sw 'rs2, 'simm('rs1)", instr, RV_I);
      break;
#if XLEN >= 64
    case SD:
      Print("sd 'rs2, 'simm('rs1)", instr, RV_I);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleSTOREFP(Instr instr) {
  switch (instr.funct3()) {
    case S:
      Print("fsw 'frs2, 'simm('rs1)", instr, RV_F);
      break;
    case D:
      Print("fsd 'frs2, 'simm('rs1)", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOPIMM(Instr instr) {
  switch (instr.funct3()) {
    case ADDI:
      if ((instr.rd() == ZR) && (instr.rs1() == ZR) &&
          (instr.itype_imm() == 0)) {
        Print("nop", instr, RV_I);  // The canonical nop.
      } else if (instr.itype_imm() == 0) {
        Print("mv 'rd, 'rs1", instr, RV_I);
      } else if (instr.rs1() == ZR) {
        Print("li 'rd, 'iimm", instr, RV_I);
      } else {
        Print("addi 'rd, 'rs1, 'iimm", instr, RV_I);
      }
      break;
    case SLTI:
      Print("slti 'rd, 'rs1, 'iimm", instr, RV_I);
      break;
    case SLTIU:
      if (instr.itype_imm() == 1) {
        Print("seqz 'rd, 'rs1", instr, RV_I);
      } else {
        Print("sltiu 'rd, 'rs1, 'iimm", instr, RV_I);
      }
      break;
    case XORI:
      if (instr.itype_imm() == -1) {
        Print("not 'rd, 'rs1", instr, RV_I);
      } else {
        Print("xori 'rd, 'rs1, 'iimm", instr, RV_I);
      }
      break;
    case ORI:
      Print("ori 'rd, 'rs1, 'iimm", instr, RV_I);
      break;
    case ANDI:
      Print("andi 'rd, 'rs1, 'iimm", instr, RV_I);
      break;
    case SLLI:
      if (instr.funct7() == COUNT) {
        if (instr.shamt() == 0b00000) {
          Print("clz 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00001) {
          Print("ctz 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00010) {
          Print("cpop 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00100) {
          Print("sext.b 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00101) {
          Print("sext.h 'rd, 'rs1", instr, RV_Zbb);
        } else {
          UnknownInstruction(instr);
        }
      } else if ((instr.funct7() & 0b1111110) == BCLRBEXT) {
        Print("bclri 'rd, 'rs1, 'shamt", instr, RV_Zbs);
      } else if ((instr.funct7() & 0b1111110) == BINV) {
        Print("binvi 'rd, 'rs1, 'shamt", instr, RV_Zbs);
      } else if ((instr.funct7() & 0b1111110) == BSET) {
        Print("bseti 'rd, 'rs1, 'shamt", instr, RV_Zbs);
      } else {
        Print("slli 'rd, 'rs1, 'shamt", instr, RV_I);
      }
      break;
    case SRI:
      if ((instr.funct7() & 0b1111110) == SRA) {
        Print("srai 'rd, 'rs1, 'shamt", instr, RV_I);
      } else if ((instr.funct7() & 0b1111110) == ROTATE) {
        Print("rori 'rd, 'rs1, 'shamt", instr, RV_Zbb);
      } else if (instr.funct7() == 0b0010100) {
        Print("orc.b 'rd, 'rs1", instr, RV_Zbb);
#if XLEN == 32
      } else if (instr.funct7() == 0b0110100) {
        Print("rev8 'rd, 'rs1", instr, RV_Zbb);
#else
      } else if (instr.funct7() == 0b0110101) {
        Print("rev8 'rd, 'rs1", instr, RV_Zbb);
#endif
      } else if ((instr.funct7() & 0b1111110) == BCLRBEXT) {
        Print("bexti 'rd, 'rs1, 'shamt", instr, RV_Zbs);
      } else {
        Print("srli 'rd, 'rs1, 'shamt", instr, RV_I);
      }
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOPIMM32(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case ADDI:
      if (instr.itype_imm() == 0) {
        Print("sext.w 'rd, 'rs1", instr, RV_I);
      } else {
        Print("addiw 'rd, 'rs1, 'iimm", instr, RV_I);
      }
      break;
    case SLLI:
      if (instr.funct7() == SLLIUW) {
        Print("slli.uw 'rd, 'rs1, 'shamt", instr, RV_Zba);
      } else if (instr.funct7() == COUNT) {
        if (instr.shamt() == 0b00000) {
          Print("clzw 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00001) {
          Print("ctzw 'rd, 'rs1", instr, RV_Zbb);
        } else if (instr.shamt() == 0b00010) {
          Print("cpopw 'rd, 'rs1", instr, RV_Zbb);
        } else {
          UnknownInstruction(instr);
        }
      } else {
        Print("slliw 'rd, 'rs1, 'shamt", instr, RV_I);
      }
      break;
    case SRI:
      if (instr.funct7() == SRA) {
        Print("sraiw 'rd, 'rs1, 'shamt", instr, RV_I);
      } else if (instr.funct7() == ROTATE) {
        Print("roriw 'rd, 'rs1, 'shamt", instr, RV_Zbb);
      } else {
        Print("srliw 'rd, 'rs1, 'shamt", instr, RV_I);
      }
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP(Instr instr) {
  switch (instr.funct7()) {
    case 0:
      DisassembleOP_0(instr);
      break;
    case SUB:
      DisassembleOP_SUB(instr);
      break;
    case MULDIV:
      DisassembleOP_MULDIV(instr);
      break;
    case SHADD:
      DisassembleOP_SHADD(instr);
      break;
    case MINMAXCLMUL:
      DisassembleOP_MINMAXCLMUL(instr);
      break;
    case ROTATE:
      DisassembleOP_ROTATE(instr);
      break;
    case BCLRBEXT:
      DisassembleOP_BCLRBEXT(instr);
      break;
    case BINV:
      Print("binv 'rd, 'rs1, 'rs2", instr, RV_Zbs);
      break;
    case BSET:
      Print("bset 'rd, 'rs1, 'rs2", instr, RV_Zbs);
      break;
#if XLEN == 32
    case 0b0000100:
      Print("zext.h 'rd, 'rs1", instr, RV_Zbb);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_0(Instr instr) {
  switch (instr.funct3()) {
    case ADD:
      Print("add 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case SLL:
      Print("sll 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case SLT:
      if (instr.rs2() == ZR) {
        Print("sltz 'rd, 'rs1", instr, RV_I);
      } else if (instr.rs1() == ZR) {
        Print("sgtz 'rd, 'rs2", instr, RV_I);
      } else {
        Print("slt 'rd, 'rs1, 'rs2", instr, RV_I);
      }
      break;
    case SLTU:
      if (instr.rs1() == ZR) {
        Print("snez 'rd, 'rs2", instr, RV_I);
      } else {
        Print("sltu 'rd, 'rs1, 'rs2", instr, RV_I);
      }
      break;
    case XOR:
      Print("xor 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case SR:
      Print("srl 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case OR:
      Print("or 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case AND:
      Print("and 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_SUB(Instr instr) {
  switch (instr.funct3()) {
    case ADD:
      if (instr.rs1() == ZR) {
        Print("neg 'rd, 'rs2", instr, RV_I);
      } else {
        Print("sub 'rd, 'rs1, 'rs2", instr, RV_I);
      }
      break;
    case SR:
      Print("sra 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case AND:
      Print("andn 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case OR:
      Print("orn 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case XOR:
      Print("xnor 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_MULDIV(Instr instr) {
  switch (instr.funct3()) {
    case MUL:
      Print("mul 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case MULH:
      Print("mulh 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case MULHSU:
      Print("mulhsu 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case MULHU:
      Print("mulhu 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case DIV:
      Print("div 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case DIVU:
      Print("divu 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case REM:
      Print("rem 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case REMU:
      Print("remu 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_SHADD(Instr instr) {
  switch (instr.funct3()) {
    case SH1ADD:
      Print("sh1add 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    case SH2ADD:
      Print("sh2add 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    case SH3ADD:
      Print("sh3add 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_MINMAXCLMUL(Instr instr) {
  switch (instr.funct3()) {
    case MAX:
      Print("max 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case MAXU:
      Print("maxu 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case MIN:
      Print("min 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case MINU:
      Print("minu 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case CLMUL:
      Print("clmul 'rd, 'rs1, 'rs2", instr, RV_Zbc);
      break;
    case CLMULH:
      Print("clmulh 'rd, 'rs1, 'rs2", instr, RV_Zbc);
      break;
    case CLMULR:
      Print("clmulr 'rd, 'rs1, 'rs2", instr, RV_Zbc);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_ROTATE(Instr instr) {
  switch (instr.funct3()) {
    case ROR:
      Print("ror 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case ROL:
      Print("rol 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP_BCLRBEXT(Instr instr) {
  switch (instr.funct3()) {
    case BCLR:
      Print("bclr 'rd, 'rs1, 'rs2", instr, RV_Zbs);
      break;
    case BEXT:
      Print("bext 'rd, 'rs1, 'rs2", instr, RV_Zbs);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32(Instr instr) {
  switch (instr.funct7()) {
    case 0:
      DisassembleOP32_0(instr);
      break;
    case SUB:
      DisassembleOP32_SUB(instr);
      break;
    case MULDIV:
      DisassembleOP32_MULDIV(instr);
      break;
    case SHADD:
      DisassembleOP32_SHADD(instr);
      break;
    case ADDUW:
      DisassembleOP32_ADDUW(instr);
      break;
    case ROTATE:
      DisassembleOP32_ROTATE(instr);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_0(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case ADD:
      Print("addw 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case SLL:
      Print("sllw 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    case SR: {
      Print("srlw 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
    }
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_SUB(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case ADD:
      if (instr.rs1() == ZR) {
        Print("negw 'rd, 'rs2", instr, RV_I);
      } else {
        Print("subw 'rd, 'rs1, 'rs2", instr, RV_I);
      }
      break;
    case SR:
      Print("sraw 'rd, 'rs1, 'rs2", instr, RV_I);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_MULDIV(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case MULW:
      Print("mulw 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case DIVW:
      Print("divw 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case DIVUW:
      Print("divuw 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case REMW:
      Print("remw 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
    case REMUW:
      Print("remuw 'rd, 'rs1, 'rs2", instr, RV_M);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_SHADD(Instr instr) {
  switch (instr.funct3()) {
    case SH1ADD:
      Print("sh1add.uw 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    case SH2ADD:
      Print("sh2add.uw 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    case SH3ADD:
      Print("sh3add.uw 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_ADDUW(Instr instr) {
  switch (instr.funct3()) {
#if XLEN >= 64
    case F3_0:
      Print("add.uw 'rd, 'rs1, 'rs2", instr, RV_Zba);
      break;
    case ZEXT:
      Print("zext.h 'rd, 'rs1", instr, RV_Zbb);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOP32_ROTATE(Instr instr) {
  switch (instr.funct3()) {
    case ROR:
      Print("rorw 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    case ROL:
      Print("rolw 'rd, 'rs1, 'rs2", instr, RV_Zbb);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleMISCMEM(Instr instr) {
  switch (instr.funct3()) {
    case FENCE:
      Print("fence'predsucc", instr, RV_I);
      break;
    case FENCEI:
      Print("fence.i", instr, RV_I);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleSYSTEM(Instr instr) {
  switch (instr.funct3()) {
    case 0:
      switch (instr.funct12()) {
        case ECALL:
          if (instr.rs1() == ZR) {
            Print("ecall", instr, RV_I);
          } else {
            Print("SimulatorPrintObject 'rs1", instr, RV_I);
          }
          break;
        case EBREAK:
          Print("ebreak", instr, RV_I);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    case CSRRW:
      if (instr.rd() == ZR) {
        Print("csrw 'csr, 'rs1", instr, RV_I);
      } else {
        Print("csrrw 'rd, 'csr, 'rs1", instr, RV_I);
      }
      break;
    case CSRRS:
      if (instr.rs1() == ZR) {
        Print("csrr 'rd, 'csr", instr, RV_I);
      } else if (instr.rd() == ZR) {
        Print("csrs 'csr, 'rs1", instr, RV_I);
      } else {
        Print("csrrs 'rd, 'csr, 'rs1", instr, RV_I);
      }
      break;
    case CSRRC:
      if (instr.rd() == ZR) {
        Print("csrc 'csr, 'rs1", instr, RV_I);
      } else {
        Print("csrrc 'rd, 'csr, 'rs1", instr, RV_I);
      }
      break;
    case CSRRWI:
      if (instr.rd() == ZR) {
        Print("csrwi 'csr, 'zimm", instr, RV_I);
      } else {
        Print("csrrwi 'rd, 'csr, 'zimm", instr, RV_I);
      }
      break;
    case CSRRSI:
      if (instr.rd() == ZR) {
        Print("csrsi 'csr, 'zimm", instr, RV_I);
      } else {
        Print("csrrsi 'rd, 'csr, 'zimm", instr, RV_I);
      }
      break;
    case CSRRCI:
      if (instr.rd() == ZR) {
        Print("csrci 'csr, 'zimm", instr, RV_I);
      } else {
        Print("csrrci 'rd, 'csr, 'zimm", instr, RV_I);
      }
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleAMO(Instr instr) {
  switch (instr.funct3()) {
    case WIDTH32:
      DisassembleAMO32(instr);
      break;
    case WIDTH64:
      DisassembleAMO64(instr);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleAMO32(Instr instr) {
  switch (instr.funct5()) {
    case LR:
      Print("lr.w'order 'rd, ('rs1)", instr, RV_A);
      break;
    case SC:
      Print("sc.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOSWAP:
      Print("amoswap.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOADD:
      Print("amoadd.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOXOR:
      Print("amoxor.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOAND:
      Print("amoand.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOOR:
      Print("amoor.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMIN:
      Print("amomin.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMAX:
      Print("amomax.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMINU:
      Print("amominu.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMAXU:
      Print("amomaxu.w'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleAMO64(Instr instr) {
  switch (instr.funct5()) {
#if XLEN >= 64
    case LR:
      Print("lr.d'order 'rd, ('rs1)", instr, RV_A);
      break;
    case SC:
      Print("sc.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOSWAP:
      Print("amoswap.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOADD:
      Print("amoadd.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOXOR:
      Print("amoxor.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOAND:
      Print("amoand.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOOR:
      Print("amoor.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMIN:
      Print("amomin.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMAX:
      Print("amomax.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMINU:
      Print("amominu.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
    case AMOMAXU:
      Print("amomaxu.d'order 'rd, 'rs2, ('rs1)", instr, RV_A);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleFMADD(Instr instr) {
  switch (instr.funct2()) {
    case F2_S:
      Print("fmadd.s 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_F);
      break;
    case F2_D:
      Print("fmadd.d 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleFMSUB(Instr instr) {
  switch (instr.funct2()) {
    case F2_S:
      Print("fmsub.s 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_F);
      break;
    case F2_D:
      Print("fmsub.d 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleFNMADD(Instr instr) {
  switch (instr.funct2()) {
    case F2_S:
      Print("fnmadd.s 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_F);
      break;
    case F2_D:
      Print("fnmadd.d 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleFNMSUB(Instr instr) {
  switch (instr.funct2()) {
    case F2_S:
      Print("fnmsub.s 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_F);
      break;
    case F2_D:
      Print("fnmsub.d 'frd, 'frs1, 'frs2, 'frs3'round", instr, RV_D);
      break;
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::DisassembleOPFP(Instr instr) {
  switch (instr.funct7()) {
    case FADDS:
      Print("fadd.s 'frd, 'frs1, 'frs2'round", instr, RV_F);
      break;
    case FSUBS:
      Print("fsub.s 'frd, 'frs1, 'frs2'round", instr, RV_F);
      break;
    case FMULS:
      Print("fmul.s 'frd, 'frs1, 'frs2'round", instr, RV_F);
      break;
    case FDIVS:
      Print("fdiv.s 'frd, 'frs1, 'frs2'round", instr, RV_F);
      break;
    case FSQRTS:
      Print("fsqrt.s 'frd, 'frs1'round", instr, RV_F);
      break;
    case FSGNJS: {
      switch (instr.funct3()) {
        case J:
          if (instr.frs1() == instr.frs2()) {
            Print("fmv.s 'frd, 'frs1", instr, RV_F);
          } else {
            Print("fsgnj.s 'frd, 'frs1, 'frs2", instr, RV_F);
          }
          break;
        case JN:
          if (instr.frs1() == instr.frs2()) {
            Print("fneg.s 'frd, 'frs1", instr, RV_F);
          } else {
            Print("fsgnjn.s 'frd, 'frs1, 'frs2", instr, RV_F);
          }
          break;
        case JX:
          if (instr.frs1() == instr.frs2()) {
            Print("fabs.s 'frd, 'frs1", instr, RV_F);
          } else {
            Print("fsgnjx.s 'frd, 'frs1, 'frs2", instr, RV_F);
          }
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FMINMAXS: {
      switch (instr.funct3()) {
        case FMIN:
          Print("fmin.s 'frd, 'frs1, 'frs2", instr, RV_F);
          break;
        case FMAX:
          Print("fmax.s 'frd, 'frs1, 'frs2", instr, RV_F);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCMPS: {
      switch (instr.funct3()) {
        case FEQ:
          Print("feq.s 'rd, 'frs1, 'frs2", instr, RV_F);
          break;
        case FLT:
          Print("flt.s 'rd, 'frs1, 'frs2", instr, RV_F);
          break;
        case FLE:
          Print("fle.s 'rd, 'frs1, 'frs2", instr, RV_F);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCLASSS:  // = FMVXW
      switch (instr.funct3()) {
        case 1:
          Print("fclass.s 'rd, 'frs1", instr, RV_F);
          break;
        case 0:
          Print("fmv.x.w 'rd, 'frs1", instr, RV_F);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    case FCVTintS:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          Print("fcvt.w.s 'rd, 'frs1'round", instr, RV_F);
          break;
        case WU:
          Print("fcvt.wu.s 'rd, 'frs1'round", instr, RV_F);
          break;
#if XLEN >= 64
        case L:
          Print("fcvt.l.s 'rd, 'frs1'round", instr, RV_F);
          break;
        case LU:
          Print("fcvt.lu.s 'rd, 'frs1'round", instr, RV_F);
          break;
#endif
        default:
          UnknownInstruction(instr);
      }
      break;
    case FCVTSint:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          Print("fcvt.s.w 'frd, 'rs1'round", instr, RV_F);
          break;
        case WU:
          Print("fcvt.s.wu 'frd, 'rs1'round", instr, RV_F);
          break;
#if XLEN >= 64
        case L:
          Print("fcvt.s.l 'frd, 'rs1'round", instr, RV_F);
          break;
        case LU:
          Print("fcvt.s.lu 'frd, 'rs1'round", instr, RV_F);
          break;
#endif
        default:
          UnknownInstruction(instr);
      }
      break;
    case FMVWX:
      Print("fmv.w.x 'frd, 'rs1", instr, RV_F);
      break;
    case FADDD:
      Print("fadd.d 'frd, 'frs1, 'frs2'round", instr, RV_D);
      break;
    case FSUBD:
      Print("fsub.d 'frd, 'frs1, 'frs2'round", instr, RV_D);
      break;
    case FMULD:
      Print("fmul.d 'frd, 'frs1, 'frs2'round", instr, RV_D);
      break;
    case FDIVD:
      Print("fdiv.d 'frd, 'frs1, 'frs2'round", instr, RV_D);
      break;
    case FSQRTD:
      Print("fsqrt.d 'frd, 'frs1'round", instr, RV_D);
      break;
    case FSGNJD: {
      switch (instr.funct3()) {
        case J:
          if (instr.frs1() == instr.frs2()) {
            Print("fmv.d 'frd, 'frs1", instr, RV_D);
          } else {
            Print("fsgnj.d 'frd, 'frs1, 'frs2", instr, RV_D);
          }
          break;
        case JN:
          if (instr.frs1() == instr.frs2()) {
            Print("fneg.d 'frd, 'frs1", instr, RV_D);
          } else {
            Print("fsgnjn.d 'frd, 'frs1, 'frs2", instr, RV_D);
          }
          break;
        case JX:
          if (instr.frs1() == instr.frs2()) {
            Print("fabs.d 'frd, 'frs1", instr, RV_D);
          } else {
            Print("fsgnjx.d 'frd, 'frs1, 'frs2", instr, RV_D);
          }
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FMINMAXD: {
      switch (instr.funct3()) {
        case FMIN:
          Print("fmin.d 'frd, 'frs1, 'frs2", instr, RV_D);
          break;
        case FMAX:
          Print("fmax.d 'frd, 'frs1, 'frs2", instr, RV_D);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCVTS: {
      switch (instr.rs2()) {
        case 1:
          Print("fcvt.s.d 'frd, 'frs1'round", instr, RV_D);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCVTD: {
      switch (instr.rs2()) {
        case 0:
          Print("fcvt.d.s 'frd, 'frs1'round", instr, RV_D);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCMPD: {
      switch (instr.funct3()) {
        case FEQ:
          Print("feq.d 'rd, 'frs1, 'frs2", instr, RV_D);
          break;
        case FLT:
          Print("flt.d 'rd, 'frs1, 'frs2", instr, RV_D);
          break;
        case FLE:
          Print("fle.d 'rd, 'frs1, 'frs2", instr, RV_D);
          break;
        default:
          UnknownInstruction(instr);
      }
      break;
    }
    case FCLASSD:  // = FMVXD
      switch (instr.funct3()) {
        case 1:
          Print("fclass.d 'rd, 'frs1", instr, RV_D);
          break;
#if XLEN >= 64
        case 0:
          Print("fmv.x.d 'rd, 'frs1", instr, RV_D);
          break;
#endif
        default:
          UnknownInstruction(instr);
      }
      break;
    case FCVTintD:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          Print("fcvt.w.d 'rd, 'frs1'round", instr, RV_D);
          break;
        case WU:
          Print("fcvt.wu.d 'rd, 'frs1'round", instr, RV_D);
          break;
#if XLEN >= 64
        case L:
          Print("fcvt.l.d 'rd, 'frs1'round", instr, RV_D);
          break;
        case LU:
          Print("fcvt.lu.d 'rd, 'frs1'round", instr, RV_D);
          break;
#endif
        default:
          UnknownInstruction(instr);
      }
      break;
    case FCVTDint:
      switch (static_cast<FcvtRs2>(instr.rs2())) {
        case W:
          Print("fcvt.d.w 'frd, 'rs1'round", instr, RV_D);
          break;
        case WU:
          Print("fcvt.d.wu 'frd, 'rs1'round", instr, RV_D);
          break;
#if XLEN >= 64
        case L:
          Print("fcvt.d.l 'frd, 'rs1'round", instr, RV_D);
          break;
        case LU:
          Print("fcvt.d.lu 'frd, 'rs1'round", instr, RV_D);
          break;
#endif
        default:
          UnknownInstruction(instr);
      }
      break;
#if XLEN >= 64
    case FMVDX:
      Print("fmv.d.x 'frd, 'rs1", instr, RV_D);
      break;
#endif
    default:
      UnknownInstruction(instr);
  }
}

void RISCVDisassembler::UnknownInstruction(Instr instr) {
  if (instr.encoding() == 0) {
    Print("trap", instr, RV_I);
  } else {
    Print("unknown", instr, ExtensionSet::Empty());
  }
}

void RISCVDisassembler::UnknownInstruction(CInstr instr) {
  if (instr.encoding() == 0) {
    Print("trap", instr, RV_I);
  } else {
    Print("unknown", instr, ExtensionSet::Empty());
  }
}

void RISCVDisassembler::Print(const char* format,
                              Instr instr,
                              ExtensionSet ex) {
  // Printf("  %08x ", instr.encoding());

  while (format[0] != '\0') {
    if (format[0] == '\'') {
      format = PrintOption(format + 1, instr);
    } else {
      Printf("%c", format[0]);
      format++;
    }
  }

  // Printf("\n");
}

void RISCVDisassembler::Print(const char* format,
                              CInstr instr,
                              ExtensionSet ex) {
  // Printf("      %04x ", instr.encoding());

  while (format[0] != '\0') {
    if (format[0] == '\'') {
      format = PrintOption(format + 1, instr);
    } else {
      Printf("%c", format[0]);
      format++;
    }
  }

  // Printf("\n");
}

#define STRING_STARTS_WITH(string, compare_string)                             \
  (strncmp(string, compare_string, strlen(compare_string)) == 0)

const char* RISCVDisassembler::PrintOption(const char* format, Instr instr) {
  if (STRING_STARTS_WITH(format, "rd")) {
    Printf("%s", cpu_reg_names[instr.rd()]);
    return format + 2;
  } else if (STRING_STARTS_WITH(format, "rs1")) {
    Printf("%s", cpu_reg_names[instr.rs1()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "rs2")) {
    Printf("%s", cpu_reg_names[instr.rs2()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "shamt")) {
    Printf("0x%x", instr.shamt());
    return format + 5;
  } else if (STRING_STARTS_WITH(format, "jimm")) {
    Printf("%+" Pd, static_cast<intptr_t>(instr.jtype_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "uimm")) {
    // objdump instead displays (imm >> 12) as hex.
    Printf("%" Pd, static_cast<intptr_t>(instr.utype_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "iimm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.itype_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "simm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.stype_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "bimm")) {
    Printf("%+" Pd, static_cast<intptr_t>(instr.btype_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "zimm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.zimm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "csr")) {
    Printf("0x%" Px, static_cast<intptr_t>(instr.csr()));
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "order")) {
    switch (instr.memory_order()) {
      case std::memory_order_relaxed:
        break;
      case std::memory_order_acquire:
        Printf(".aq");
        break;
      case std::memory_order_release:
        Printf(".rl");
        break;
      case std::memory_order_acq_rel:
        Printf(".aqrl");
        break;
      default:
        UNREACHABLE();
    }
    return format + 5;
  } else if (STRING_STARTS_WITH(format, "round")) {
    switch (instr.rounding()) {
      case RNE:
        // Printf(", rne");
        break;
      case RTZ:
        Printf(", rtz");
        break;
      case RDN:
        Printf(", rdn");
        break;
      case RUP:
        Printf(", rup");
        break;
      case RMM:
        Printf(", rmm");
        break;
      case DYN:
        Printf(", dyn");
        break;
      default:
        Printf("<invalid rounding mode>");
    }
    return format + 5;
  } else if (STRING_STARTS_WITH(format, "predsucc")) {
    HartEffects pred = static_cast<HartEffects>((instr.itype_imm() >> 4) & 0xF);
    HartEffects succ = static_cast<HartEffects>((instr.itype_imm() >> 0) & 0xF);
    if ((pred != HartEffects::kAll) || (succ != HartEffects::kAll)) {
      Printf(" ");
      if ((pred & HartEffects::kInput) != 0) Printf("i");
      if ((pred & HartEffects::kOutput) != 0) Printf("o");
      if ((pred & HartEffects::kRead) != 0) Printf("r");
      if ((pred & HartEffects::kWrite) != 0) Printf("w");
      Printf(",");
      if ((succ & HartEffects::kInput) != 0) Printf("i");
      if ((succ & HartEffects::kOutput) != 0) Printf("o");
      if ((succ & HartEffects::kRead) != 0) Printf("r");
      if ((succ & HartEffects::kWrite) != 0) Printf("w");
    }
    return format + 8;
  } else if (STRING_STARTS_WITH(format, "frd")) {
    Printf("%s", fpu_reg_names[instr.frd()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "frs1")) {
    Printf("%s", fpu_reg_names[instr.frs1()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "frs2")) {
    Printf("%s", fpu_reg_names[instr.frs2()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "frs3")) {
    Printf("%s", fpu_reg_names[instr.frs3()]);
    return format + 4;
  }

  FATAL("Bad format %s\n", format);
  return nullptr;
}

const char* RISCVDisassembler::PrintOption(const char* format, CInstr instr) {
  if (STRING_STARTS_WITH(format, "rdp")) {
    Printf("%s", cpu_reg_names[instr.rdp()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "rs1p")) {
    Printf("%s", cpu_reg_names[instr.rs1p()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "rs2p")) {
    Printf("%s", cpu_reg_names[instr.rs2p()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "rd")) {
    Printf("%s", cpu_reg_names[instr.rd()]);
    return format + 2;
  } else if (STRING_STARTS_WITH(format, "rs1")) {
    Printf("%s", cpu_reg_names[instr.rs1()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "rs2")) {
    Printf("%s", cpu_reg_names[instr.rs2()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "frdp")) {
    Printf("%s", fpu_reg_names[instr.frdp()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "frs1p")) {
    Printf("%s", fpu_reg_names[instr.frs1p()]);
    return format + 5;
  } else if (STRING_STARTS_WITH(format, "frs2p")) {
    Printf("%s", fpu_reg_names[instr.frs2p()]);
    return format + 5;
  } else if (STRING_STARTS_WITH(format, "frd")) {
    Printf("%s", fpu_reg_names[instr.frd()]);
    return format + 3;
  } else if (STRING_STARTS_WITH(format, "frs1")) {
    Printf("%s", fpu_reg_names[instr.frs1()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "frs2")) {
    Printf("%s", fpu_reg_names[instr.frs2()]);
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "spload4imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.spload4_imm()));
    return format + 10;
  } else if (STRING_STARTS_WITH(format, "spload8imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.spload8_imm()));
    return format + 10;
  } else if (STRING_STARTS_WITH(format, "spstore4imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.spstore4_imm()));
    return format + 11;
  } else if (STRING_STARTS_WITH(format, "spstore8imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.spstore8_imm()));
    return format + 11;
  } else if (STRING_STARTS_WITH(format, "mem4imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.mem4_imm()));
    return format + 7;
  } else if (STRING_STARTS_WITH(format, "mem8imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.mem8_imm()));
    return format + 7;
  } else if (STRING_STARTS_WITH(format, "jimm")) {
    Printf("%+" Pd, static_cast<intptr_t>(instr.j_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "bimm")) {
    Printf("%+" Pd, static_cast<intptr_t>(instr.b_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "iimm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.i_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "uimm")) {
    // objdump instead displays (imm >> 12) as hex.
    Printf("%" Pd, static_cast<intptr_t>(instr.u_imm()));
    return format + 4;
  } else if (STRING_STARTS_WITH(format, "i16imm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.i16_imm()));
    return format + 6;
  } else if (STRING_STARTS_WITH(format, "i4spnimm")) {
    Printf("%" Pd, static_cast<intptr_t>(instr.i4spn_imm()));
    return format + 8;
  }

  FATAL("Bad format %s\n", format);
  return nullptr;
}

void Disassembler::DecodeInstruction(char* hex_buffer,
                                     intptr_t hex_size,
                                     char* human_buffer,
                                     intptr_t human_size,
                                     int* out_instr_size,
                                     const Code& code,
                                     Object** object,
                                     uword pc) {
  RISCVDisassembler decoder(human_buffer, human_size,
                            FLAG_use_compressed_instructions ? RV_GC : RV_G);
  int instr_size = decoder.Disassemble(pc);
  if (instr_size == 2) {
    Utils::SNPrint(hex_buffer, hex_size, "    %04x",
                   *reinterpret_cast<uint16_t*>(pc));
  } else if (instr_size == 4) {
    Utils::SNPrint(hex_buffer, hex_size, "%08x",
                   LoadUnaligned(reinterpret_cast<uint32_t*>(pc)));
  }
  if (out_instr_size != nullptr) {
    *out_instr_size = instr_size;
  }

  *object = nullptr;
  if (!code.IsNull()) {
    *object = &Object::Handle();
    if (!DecodeLoadObjectFromPoolOrThread(pc, code, *object)) {
      *object = nullptr;
    }
  }
}

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
