// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/simulator.h"
#include "vm/tags.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, precompiled_mode);

DEFINE_FLAG(int, far_branch_level, 0, "Always use far branches");

namespace compiler {

MicroAssembler::MicroAssembler(ObjectPoolBuilder* object_pool_builder,
                               intptr_t far_branch_level,
                               ExtensionSet extensions)
    : AssemblerBase(object_pool_builder),
      extensions_(extensions),
      far_branch_level_(far_branch_level) {
  ASSERT(far_branch_level >= 0);
  ASSERT(far_branch_level <= 2);
}

MicroAssembler::~MicroAssembler() {}

void MicroAssembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t target_position = Position();
  intptr_t branch_position;

#define BIND(head, update)                                                     \
  branch_position = label->head;                                               \
  while (branch_position >= 0) {                                               \
    ASSERT(Utils::IsAligned(branch_position, Supports(RV_C) ? 2 : 4));         \
    intptr_t new_offset = target_position - branch_position;                   \
    ASSERT(Utils::IsAligned(new_offset, Supports(RV_C) ? 2 : 4));              \
    intptr_t old_offset = update(branch_position, new_offset);                 \
    if (old_offset == 0) break;                                                \
    branch_position -= old_offset;                                             \
  }                                                                            \
  label->head = -1

  BIND(unresolved_cb_, UpdateCBOffset);
  BIND(unresolved_cj_, UpdateCJOffset);
  BIND(unresolved_b_, UpdateBOffset);
  BIND(unresolved_j_, UpdateJOffset);
  BIND(unresolved_far_, UpdateFarOffset);

  label->BindTo(target_position);
}

intptr_t MicroAssembler::UpdateCBOffset(intptr_t branch_position,
                                        intptr_t new_offset) {
  CInstr instr(Read16(branch_position));
  ASSERT((instr.opcode() == C_BEQZ) || (instr.opcode() == C_BNEZ));
  intptr_t old_offset = instr.b_imm();
  if (!IsCBImm(new_offset)) {
    FATAL("Incorrect Assembler::kNearJump");
  }
  Write16(branch_position,
          instr.opcode() | EncodeCRs1p(instr.rs1p()) | EncodeCBImm(new_offset));
  return old_offset;
}

intptr_t MicroAssembler::UpdateCJOffset(intptr_t branch_position,
                                        intptr_t new_offset) {
  CInstr instr(Read16(branch_position));
  ASSERT((instr.opcode() == C_J) || (instr.opcode() == C_JAL));
  intptr_t old_offset = instr.j_imm();
  if (!IsCJImm(new_offset)) {
    FATAL("Incorrect Assembler::kNearJump");
  }
  Write16(branch_position, instr.opcode() | EncodeCJImm(new_offset));
  return old_offset;
}

intptr_t MicroAssembler::UpdateBOffset(intptr_t branch_position,
                                       intptr_t new_offset) {
  Instr instr(Read32(branch_position));
  ASSERT(instr.opcode() == BRANCH);
  intptr_t old_offset = instr.btype_imm();
  if (!IsBTypeImm(new_offset)) {
    BailoutWithBranchOffsetError();
  }
  Write32(branch_position, EncodeRs2(instr.rs2()) | EncodeRs1(instr.rs1()) |
                               EncodeFunct3(instr.funct3()) |
                               EncodeOpcode(instr.opcode()) |
                               EncodeBTypeImm(new_offset));
  return old_offset;
}

intptr_t MicroAssembler::UpdateJOffset(intptr_t branch_position,
                                       intptr_t new_offset) {
  Instr instr(Read32(branch_position));
  ASSERT(instr.opcode() == JAL);
  intptr_t old_offset = instr.jtype_imm();
  if (!IsJTypeImm(new_offset)) {
    BailoutWithBranchOffsetError();
  }
  Write32(branch_position, EncodeRd(instr.rd()) | EncodeOpcode(instr.opcode()) |
                               EncodeJTypeImm(new_offset));
  return old_offset;
}

intptr_t MicroAssembler::UpdateFarOffset(intptr_t branch_position,
                                         intptr_t new_offset) {
  Instr auipc_instr(Read32(branch_position));
  ASSERT(auipc_instr.opcode() == AUIPC);
  ASSERT(auipc_instr.rd() == FAR_TMP);
  Instr jr_instr(Read32(branch_position + 4));
  ASSERT(jr_instr.opcode() == JALR);
  ASSERT(jr_instr.rd() == ZR);
  ASSERT(jr_instr.funct3() == F3_0);
  ASSERT(jr_instr.rs1() == FAR_TMP);
  intptr_t old_offset = auipc_instr.utype_imm() + jr_instr.itype_imm();
  intx_t lo = ImmLo(new_offset);
  intx_t hi = ImmHi(new_offset);
  if (!IsUTypeImm(hi)) {
    FATAL("Jump/branch distance exceeds 2GB!");
  }
  Write32(branch_position,
          EncodeUTypeImm(hi) | EncodeRd(FAR_TMP) | EncodeOpcode(AUIPC));
  Write32(branch_position + 4, EncodeITypeImm(lo) | EncodeRs1(FAR_TMP) |
                                   EncodeFunct3(F3_0) | EncodeRd(ZR) |
                                   EncodeOpcode(JALR));
  return old_offset;
}

void MicroAssembler::lui(Register rd, intptr_t imm) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C) && (rd != ZR) && (rd != SP) && IsCUImm(imm)) {
    c_lui(rd, imm);
    return;
  }
  EmitUType(imm, rd, LUI);
}

void MicroAssembler::lui_fixed(Register rd, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitUType(imm, rd, LUI);
}

void MicroAssembler::auipc(Register rd, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitUType(imm, rd, AUIPC);
}

void MicroAssembler::jal(Register rd, Label* label, JumpDistance distance) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C) &&
      ((distance == kNearJump) ||
       (label->IsBound() && IsCJImm(label->Position() - Position())))) {
    if (rd == ZR) {
      c_j(label);
      return;
    }
#if XLEN == 32
    if (rd == RA) {
      c_jal(label);
      return;
    }
#endif  // XLEN == 32
  }
  EmitJump(rd, label, JAL, distance);
}

void MicroAssembler::jalr(Register rd, Register rs1, intptr_t offset) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if (rs1 != ZR && offset == 0) {
      if (rd == ZR) {
        c_jr(rs1);
        return;
      } else if (rd == RA) {
        c_jalr(rs1);
        return;
      }
    }
  }
  EmitIType(offset, rs1, F3_0, rd, JALR);
}

void MicroAssembler::jalr_fixed(Register rd, Register rs1, intptr_t offset) {
  ASSERT(Supports(RV_I));
  EmitIType(offset, rs1, F3_0, rd, JALR);
}

void MicroAssembler::beq(Register rs1,
                         Register rs2,
                         Label* label,
                         JumpDistance distance) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C) &&
      ((distance == kNearJump) ||
       (label->IsBound() && IsCBImm(label->Position() - Position())))) {
    if ((rs1 == ZR) && IsCRs1p(rs2)) {
      c_beqz(rs2, label);
      return;
    } else if ((rs2 == ZR) && IsCRs1p(rs1)) {
      c_beqz(rs1, label);
      return;
    }
  }
  EmitBranch(rs1, rs2, label, BEQ, distance);
}

void MicroAssembler::bne(Register rs1,
                         Register rs2,
                         Label* label,
                         JumpDistance distance) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C) &&
      ((distance == kNearJump) ||
       (label->IsBound() && IsCBImm(label->Position() - Position())))) {
    if ((rs1 == ZR) && IsCRs1p(rs2)) {
      c_bnez(rs2, label);
      return;
    } else if ((rs2 == ZR) && IsCRs1p(rs1)) {
      c_bnez(rs1, label);
      return;
    }
  }
  EmitBranch(rs1, rs2, label, BNE, distance);
}

void MicroAssembler::blt(Register rs1,
                         Register rs2,
                         Label* label,
                         JumpDistance distance) {
  ASSERT(Supports(RV_I));
  EmitBranch(rs1, rs2, label, BLT, distance);
}

void MicroAssembler::bge(Register rs1,
                         Register rs2,
                         Label* label,
                         JumpDistance distance) {
  ASSERT(Supports(RV_I));
  EmitBranch(rs1, rs2, label, BGE, distance);
}

void MicroAssembler::bltu(Register rs1,
                          Register rs2,
                          Label* label,
                          JumpDistance distance) {
  ASSERT(Supports(RV_I));
  EmitBranch(rs1, rs2, label, BLTU, distance);
}

void MicroAssembler::bgeu(Register rs1,
                          Register rs2,
                          Label* label,
                          JumpDistance distance) {
  EmitBranch(rs1, rs2, label, BGEU, distance);
}

void MicroAssembler::lb(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  EmitIType(addr.offset(), addr.base(), LB, rd, LOAD);
}

void MicroAssembler::lh(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  EmitIType(addr.offset(), addr.base(), LH, rd, LOAD);
}

void MicroAssembler::lw(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd != ZR) && (addr.base() == SP) && IsCSPLoad4Imm(addr.offset())) {
      c_lwsp(rd, addr);
      return;
    }
    if (IsCRdp(rd) && IsCRs1p(addr.base()) && IsCMem4Imm(addr.offset())) {
      c_lw(rd, addr);
      return;
    }
  }
  EmitIType(addr.offset(), addr.base(), LW, rd, LOAD);
}

void MicroAssembler::lbu(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  EmitIType(addr.offset(), addr.base(), LBU, rd, LOAD);
}

void MicroAssembler::lhu(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  EmitIType(addr.offset(), addr.base(), LHU, rd, LOAD);
}

void MicroAssembler::sb(Register rs2, Address addr) {
  ASSERT(Supports(RV_I));
  EmitSType(addr.offset(), rs2, addr.base(), SB, STORE);
}

void MicroAssembler::sh(Register rs2, Address addr) {
  ASSERT(Supports(RV_I));
  EmitSType(addr.offset(), rs2, addr.base(), SH, STORE);
}

void MicroAssembler::sw(Register rs2, Address addr) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPStore4Imm(addr.offset())) {
      c_swsp(rs2, addr);
      return;
    }
    if (IsCRs2p(rs2) && IsCRs1p(addr.base()) && IsCMem4Imm(addr.offset())) {
      c_sw(rs2, addr);
      return;
    }
  }
  EmitSType(addr.offset(), rs2, addr.base(), SW, STORE);
}

void MicroAssembler::addi(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd != ZR) && (rs1 == ZR) && IsCIImm(imm)) {
      c_li(rd, imm);
      return;
    }
    if ((rd == rs1) && IsCIImm(imm) && (imm != 0)) {
      c_addi(rd, rs1, imm);
      return;
    }
    if ((rd == SP) && (rs1 == SP) && IsCI16Imm(imm) && (imm != 0)) {
      c_addi16sp(rd, rs1, imm);
      return;
    }
    if (IsCRdp(rd) && (rs1 == SP) && IsCI4SPNImm(imm) && (imm != 0)) {
      c_addi4spn(rd, rs1, imm);
      return;
    }
    if (imm == 0) {
      if ((rd == ZR) && (rs1 == ZR)) {
        c_nop();
        return;
      }
      if ((rd != ZR) && (rs1 != ZR)) {
        c_mv(rd, rs1);
        return;
      }
    }
  }
  EmitIType(imm, rs1, ADDI, rd, OPIMM);
}

void MicroAssembler::slti(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(imm, rs1, SLTI, rd, OPIMM);
}

void MicroAssembler::sltiu(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(imm, rs1, SLTIU, rd, OPIMM);
}

void MicroAssembler::xori(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(imm, rs1, XORI, rd, OPIMM);
}

void MicroAssembler::ori(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(imm, rs1, ORI, rd, OPIMM);
}

void MicroAssembler::andi(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCIImm(imm)) {
      c_andi(rd, rs1, imm);
      return;
    }
  }
  EmitIType(imm, rs1, ANDI, rd, OPIMM);
}

void MicroAssembler::slli(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < XLEN));
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && (shamt != 0) && IsCIImm(shamt)) {
      c_slli(rd, rs1, shamt);
      return;
    }
  }
  EmitRType(F7_0, shamt, rs1, SLLI, rd, OPIMM);
}

void MicroAssembler::srli(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < XLEN));
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && (shamt != 0) && IsCIImm(shamt)) {
      c_srli(rd, rs1, shamt);
      return;
    }
  }
  EmitRType(F7_0, shamt, rs1, SRI, rd, OPIMM);
}

void MicroAssembler::srai(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < XLEN));
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && (shamt != 0) && IsCIImm(shamt)) {
      c_srai(rd, rs1, shamt);
      return;
    }
  }
  EmitRType(SRA, shamt, rs1, SRI, rd, OPIMM);
}

void MicroAssembler::add(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if (rd == rs1) {
      c_add(rd, rs1, rs2);
      return;
    }
    if (rd == rs2) {
      c_add(rd, rs2, rs1);
      return;
    }
  }
  EmitRType(F7_0, rs2, rs1, ADD, rd, OP);
}

void MicroAssembler::sub(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_sub(rd, rs1, rs2);
      return;
    }
  }
  EmitRType(SUB, rs2, rs1, ADD, rd, OP);
}

void MicroAssembler::sll(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SLL, rd, OP);
}

void MicroAssembler::slt(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SLT, rd, OP);
}

void MicroAssembler::sltu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SLTU, rd, OP);
}

void MicroAssembler::xor_(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_xor(rd, rs1, rs2);
      return;
    }
    if ((rd == rs2) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_xor(rd, rs2, rs1);
      return;
    }
  }
  EmitRType(F7_0, rs2, rs1, XOR, rd, OP);
}

void MicroAssembler::srl(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SR, rd, OP);
}

void MicroAssembler::sra(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(SRA, rs2, rs1, SR, rd, OP);
}

void MicroAssembler::or_(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_or(rd, rs1, rs2);
      return;
    }
    if ((rd == rs2) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_or(rd, rs2, rs1);
      return;
    }
  }
  EmitRType(F7_0, rs2, rs1, OR, rd, OP);
}

void MicroAssembler::and_(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_and(rd, rs1, rs2);
      return;
    }
    if ((rd == rs2) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_and(rd, rs2, rs1);
      return;
    }
  }
  EmitRType(F7_0, rs2, rs1, AND, rd, OP);
}

void MicroAssembler::fence(HartEffects predecessor, HartEffects successor) {
  ASSERT((predecessor & kAll) == predecessor);
  ASSERT((successor & kAll) == successor);
  ASSERT(Supports(RV_I));
  EmitIType((predecessor << 4) | successor, ZR, FENCE, ZR, MISCMEM);
}

void MicroAssembler::fencei() {
  ASSERT(Supports(RV_I));
  EmitIType(0, ZR, FENCEI, ZR, MISCMEM);
}

void MicroAssembler::ecall() {
  ASSERT(Supports(RV_I));
  EmitIType(ECALL, ZR, F3_0, ZR, SYSTEM);
}
void MicroAssembler::ebreak() {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    c_ebreak();
    return;
  }
  EmitIType(EBREAK, ZR, F3_0, ZR, SYSTEM);
}
void MicroAssembler::SimulatorPrintObject(Register rs1) {
  ASSERT(Supports(RV_I));
  EmitIType(ECALL, rs1, F3_0, ZR, SYSTEM);
}

void MicroAssembler::csrrw(Register rd, uint32_t csr, Register rs1) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, rs1, CSRRW, rd, SYSTEM);
}

void MicroAssembler::csrrs(Register rd, uint32_t csr, Register rs1) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, rs1, CSRRS, rd, SYSTEM);
}

void MicroAssembler::csrrc(Register rd, uint32_t csr, Register rs1) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, rs1, CSRRC, rd, SYSTEM);
}

void MicroAssembler::csrrwi(Register rd, uint32_t csr, uint32_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, Register(imm), CSRRWI, rd, SYSTEM);
}

void MicroAssembler::csrrsi(Register rd, uint32_t csr, uint32_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, Register(imm), CSRRSI, rd, SYSTEM);
}

void MicroAssembler::csrrci(Register rd, uint32_t csr, uint32_t imm) {
  ASSERT(Supports(RV_I));
  EmitIType(csr, Register(imm), CSRRCI, rd, SYSTEM);
}

void MicroAssembler::trap() {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    Emit16(0);  // Permanently reserved illegal instruction.
  } else {
    Emit32(0);  // Permanently reserved illegal instruction.
  }
}

#if XLEN >= 64
void MicroAssembler::lwu(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  EmitIType(addr.offset(), addr.base(), LWU, rd, LOAD);
}

void MicroAssembler::ld(Register rd, Address addr) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd != ZR) && (addr.base() == SP) && IsCSPLoad8Imm(addr.offset())) {
      c_ldsp(rd, addr);
      return;
    }
    if (IsCRdp(rd) && IsCRs1p(addr.base()) && IsCMem8Imm(addr.offset())) {
      c_ld(rd, addr);
      return;
    }
  }
  EmitIType(addr.offset(), addr.base(), LD, rd, LOAD);
}

void MicroAssembler::sd(Register rs2, Address addr) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPStore8Imm(addr.offset())) {
      c_sdsp(rs2, addr);
      return;
    }
    if (IsCRs2p(rs2) && IsCRs1p(addr.base()) && IsCMem8Imm(addr.offset())) {
      c_sd(rs2, addr);
      return;
    }
  }
  EmitSType(addr.offset(), rs2, addr.base(), SD, STORE);
}

void MicroAssembler::addiw(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd != ZR) && (rs1 == ZR) && IsCIImm(imm)) {
      c_li(rd, imm);
      return;
    }
    if ((rd == rs1) && (rd != ZR) && IsCIImm(imm)) {
      c_addiw(rd, rs1, imm);
      return;
    }
  }
  EmitIType(imm, rs1, ADDI, rd, OPIMM32);
}

void MicroAssembler::slliw(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < 32));
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, shamt, rs1, SLLI, rd, OPIMM32);
}

void MicroAssembler::srliw(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < 32));
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, shamt, rs1, SRI, rd, OPIMM32);
}

void MicroAssembler::sraiw(Register rd, Register rs1, intptr_t shamt) {
  ASSERT((shamt > 0) && (shamt < XLEN));
  ASSERT(Supports(RV_I));
  EmitRType(SRA, shamt, rs1, SRI, rd, OPIMM32);
}

void MicroAssembler::addw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_addw(rd, rs1, rs2);
      return;
    }
    if ((rd == rs2) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_addw(rd, rs2, rs1);
      return;
    }
  }
  EmitRType(F7_0, rs2, rs1, ADD, rd, OP32);
}

void MicroAssembler::subw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  if (Supports(RV_C)) {
    if ((rd == rs1) && IsCRs1p(rs1) && IsCRs2p(rs2)) {
      c_subw(rd, rs1, rs2);
      return;
    }
  }
  EmitRType(SUB, rs2, rs1, ADD, rd, OP32);
}

void MicroAssembler::sllw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SLL, rd, OP32);
}

void MicroAssembler::srlw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(F7_0, rs2, rs1, SR, rd, OP32);
}
void MicroAssembler::sraw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_I));
  EmitRType(SRA, rs2, rs1, SR, rd, OP32);
}
#endif  // XLEN >= 64

void MicroAssembler::mul(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, MUL, rd, OP);
}

void MicroAssembler::mulh(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, MULH, rd, OP);
}

void MicroAssembler::mulhsu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, MULHSU, rd, OP);
}

void MicroAssembler::mulhu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, MULHU, rd, OP);
}

void MicroAssembler::div(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, DIV, rd, OP);
}

void MicroAssembler::divu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, DIVU, rd, OP);
}

void MicroAssembler::rem(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, REM, rd, OP);
}

void MicroAssembler::remu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, REMU, rd, OP);
}

#if XLEN >= 64
void MicroAssembler::mulw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, MULW, rd, OP32);
}

void MicroAssembler::divw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, DIVW, rd, OP32);
}

void MicroAssembler::divuw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, DIVUW, rd, OP32);
}

void MicroAssembler::remw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, REMW, rd, OP32);
}

void MicroAssembler::remuw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_M));
  EmitRType(MULDIV, rs2, rs1, REMUW, rd, OP32);
}
#endif  // XLEN >= 64

void MicroAssembler::lrw(Register rd, Address addr, std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(LR, order, ZR, addr.base(), WIDTH32, rd, AMO);
}
void MicroAssembler::scw(Register rd,
                         Register rs2,
                         Address addr,
                         std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(SC, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amoswapw(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOSWAP, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amoaddw(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOADD, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amoxorw(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOXOR, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amoandw(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOAND, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amoorw(Register rd,
                            Register rs2,
                            Address addr,
                            std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOOR, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amominw(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMIN, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amomaxw(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMAX, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amominuw(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMINU, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

void MicroAssembler::amomaxuw(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMAXU, order, rs2, addr.base(), WIDTH32, rd, AMO);
}

#if XLEN >= 64
void MicroAssembler::lrd(Register rd, Address addr, std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(LR, order, ZR, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::scd(Register rd,
                         Register rs2,
                         Address addr,
                         std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(SC, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amoswapd(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOSWAP, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amoaddd(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOADD, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amoxord(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOXOR, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amoandd(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOAND, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amoord(Register rd,
                            Register rs2,
                            Address addr,
                            std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOOR, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amomind(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMIN, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amomaxd(Register rd,
                             Register rs2,
                             Address addr,
                             std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMAX, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amominud(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMINU, order, rs2, addr.base(), WIDTH64, rd, AMO);
}

void MicroAssembler::amomaxud(Register rd,
                              Register rs2,
                              Address addr,
                              std::memory_order order) {
  ASSERT(addr.offset() == 0);
  ASSERT(Supports(RV_A));
  EmitRType(AMOMAXU, order, rs2, addr.base(), WIDTH64, rd, AMO);
}
#endif  // XLEN >= 64

void MicroAssembler::flw(FRegister rd, Address addr) {
  ASSERT(Supports(RV_F));
#if XLEN == 32
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPLoad4Imm(addr.offset())) {
      c_flwsp(rd, addr);
      return;
    }
    if (IsCFRdp(rd) && IsCRs1p(addr.base()) && IsCMem4Imm(addr.offset())) {
      c_flw(rd, addr);
      return;
    }
  }
#endif  // XLEN == 32
  EmitIType(addr.offset(), addr.base(), S, rd, LOADFP);
}

void MicroAssembler::fsw(FRegister rs2, Address addr) {
  ASSERT(Supports(RV_F));
#if XLEN == 32
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPStore4Imm(addr.offset())) {
      c_fswsp(rs2, addr);
      return;
    }
    if (IsCFRs2p(rs2) && IsCRs1p(addr.base()) && IsCMem4Imm(addr.offset())) {
      c_fsw(rs2, addr);
      return;
    }
  }
#endif  // XLEN == 32
  EmitSType(addr.offset(), rs2, addr.base(), S, STOREFP);
}

void MicroAssembler::fmadds(FRegister rd,
                            FRegister rs1,
                            FRegister rs2,
                            FRegister rs3,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitR4Type(rs3, F2_S, rs2, rs1, rounding, rd, FMADD);
}

void MicroAssembler::fmsubs(FRegister rd,
                            FRegister rs1,
                            FRegister rs2,
                            FRegister rs3,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitR4Type(rs3, F2_S, rs2, rs1, rounding, rd, FMSUB);
}

void MicroAssembler::fnmsubs(FRegister rd,
                             FRegister rs1,
                             FRegister rs2,
                             FRegister rs3,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitR4Type(rs3, F2_S, rs2, rs1, rounding, rd, FNMSUB);
}

void MicroAssembler::fnmadds(FRegister rd,
                             FRegister rs1,
                             FRegister rs2,
                             FRegister rs3,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitR4Type(rs3, F2_S, rs2, rs1, rounding, rd, FNMADD);
}

void MicroAssembler::fadds(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FADDS, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsubs(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FSUBS, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fmuls(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FMULS, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fdivs(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FDIVS, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsqrts(FRegister rd,
                            FRegister rs1,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FSQRTS, FRegister(0), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsgnjs(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FSGNJS, rs2, rs1, J, rd, OPFP);
}

void MicroAssembler::fsgnjns(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FSGNJS, rs2, rs1, JN, rd, OPFP);
}

void MicroAssembler::fsgnjxs(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FSGNJS, rs2, rs1, JX, rd, OPFP);
}

void MicroAssembler::fmins(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FMINMAXS, rs2, rs1, FMIN, rd, OPFP);
}

void MicroAssembler::fmaxs(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FMINMAXS, rs2, rs1, FMAX, rd, OPFP);
}

void MicroAssembler::feqs(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FCMPS, rs2, rs1, FEQ, rd, OPFP);
}

void MicroAssembler::flts(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FCMPS, rs2, rs1, FLT, rd, OPFP);
}

void MicroAssembler::fles(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_F));
  EmitRType(FCMPS, rs2, rs1, FLE, rd, OPFP);
}

void MicroAssembler::fclasss(Register rd, FRegister rs1) {
  ASSERT(Supports(RV_F));
  EmitRType(FCLASSS, FRegister(0), rs1, F3_1, rd, OPFP);
}

void MicroAssembler::fcvtws(Register rd, FRegister rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTintS, FRegister(W), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtwus(Register rd,
                             FRegister rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTintS, FRegister(WU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtsw(FRegister rd, Register rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTSint, FRegister(W), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtswu(FRegister rd,
                             Register rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTSint, FRegister(WU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fmvxw(Register rd, FRegister rs1) {
  ASSERT(Supports(RV_F));
  EmitRType(FMVXW, FRegister(0), rs1, F3_0, rd, OPFP);
}

void MicroAssembler::fmvwx(FRegister rd, Register rs1) {
  ASSERT(Supports(RV_F));
  EmitRType(FMVWX, FRegister(0), rs1, F3_0, rd, OPFP);
}

#if XLEN >= 64
void MicroAssembler::fcvtls(Register rd, FRegister rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTintS, FRegister(L), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtlus(Register rd,
                             FRegister rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTintS, FRegister(LU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtsl(FRegister rd, Register rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTSint, FRegister(L), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtslu(FRegister rd,
                             Register rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_F));
  EmitRType(FCVTSint, FRegister(LU), rs1, rounding, rd, OPFP);
}
#endif  // XLEN >= 64

void MicroAssembler::fld(FRegister rd, Address addr) {
  ASSERT(Supports(RV_D));
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPLoad8Imm(addr.offset())) {
      c_fldsp(rd, addr);
      return;
    }
    if (IsCFRdp(rd) && IsCRs1p(addr.base()) && IsCMem8Imm(addr.offset())) {
      c_fld(rd, addr);
      return;
    }
  }
  EmitIType(addr.offset(), addr.base(), D, rd, LOADFP);
}

void MicroAssembler::fsd(FRegister rs2, Address addr) {
  ASSERT(Supports(RV_D));
  if (Supports(RV_C)) {
    if ((addr.base() == SP) && IsCSPStore8Imm(addr.offset())) {
      c_fsdsp(rs2, addr);
      return;
    }
    if (IsCFRs2p(rs2) && IsCRs1p(addr.base()) && IsCMem8Imm(addr.offset())) {
      c_fsd(rs2, addr);
      return;
    }
  }
  EmitSType(addr.offset(), rs2, addr.base(), D, STOREFP);
}

void MicroAssembler::fmaddd(FRegister rd,
                            FRegister rs1,
                            FRegister rs2,
                            FRegister rs3,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitR4Type(rs3, F2_D, rs2, rs1, rounding, rd, FMADD);
}

void MicroAssembler::fmsubd(FRegister rd,
                            FRegister rs1,
                            FRegister rs2,
                            FRegister rs3,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitR4Type(rs3, F2_D, rs2, rs1, rounding, rd, FMSUB);
}

void MicroAssembler::fnmsubd(FRegister rd,
                             FRegister rs1,
                             FRegister rs2,
                             FRegister rs3,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitR4Type(rs3, F2_D, rs2, rs1, rounding, rd, FNMSUB);
}

void MicroAssembler::fnmaddd(FRegister rd,
                             FRegister rs1,
                             FRegister rs2,
                             FRegister rs3,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitR4Type(rs3, F2_D, rs2, rs1, rounding, rd, FNMADD);
}

void MicroAssembler::faddd(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FADDD, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsubd(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FSUBD, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fmuld(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FMULD, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fdivd(FRegister rd,
                           FRegister rs1,
                           FRegister rs2,
                           RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FDIVD, rs2, rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsqrtd(FRegister rd,
                            FRegister rs1,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FSQRTD, FRegister(0), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fsgnjd(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FSGNJD, rs2, rs1, J, rd, OPFP);
}

void MicroAssembler::fsgnjnd(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FSGNJD, rs2, rs1, JN, rd, OPFP);
}

void MicroAssembler::fsgnjxd(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FSGNJD, rs2, rs1, JX, rd, OPFP);
}

void MicroAssembler::fmind(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FMINMAXD, rs2, rs1, FMIN, rd, OPFP);
}

void MicroAssembler::fmaxd(FRegister rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FMINMAXD, rs2, rs1, FMAX, rd, OPFP);
}

void MicroAssembler::fcvtsd(FRegister rd,
                            FRegister rs1,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTS, FRegister(1), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtds(FRegister rd,
                            FRegister rs1,
                            RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTD, FRegister(0), rs1, rounding, rd, OPFP);
}

void MicroAssembler::feqd(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FCMPD, rs2, rs1, FEQ, rd, OPFP);
}

void MicroAssembler::fltd(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FCMPD, rs2, rs1, FLT, rd, OPFP);
}

void MicroAssembler::fled(Register rd, FRegister rs1, FRegister rs2) {
  ASSERT(Supports(RV_D));
  EmitRType(FCMPD, rs2, rs1, FLE, rd, OPFP);
}

void MicroAssembler::fclassd(Register rd, FRegister rs1) {
  ASSERT(Supports(RV_D));
  EmitRType(FCLASSD, FRegister(0), rs1, F3_1, rd, OPFP);
}

void MicroAssembler::fcvtwd(Register rd, FRegister rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTintD, FRegister(W), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtwud(Register rd,
                             FRegister rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTintD, FRegister(WU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtdw(FRegister rd, Register rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTDint, FRegister(W), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtdwu(FRegister rd,
                             Register rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTDint, FRegister(WU), rs1, rounding, rd, OPFP);
}

#if XLEN >= 64
void MicroAssembler::fcvtld(Register rd, FRegister rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTintD, FRegister(L), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtlud(Register rd,
                             FRegister rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTintD, FRegister(LU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fmvxd(Register rd, FRegister rs1) {
  ASSERT(Supports(RV_D));
  EmitRType(FMVXD, FRegister(0), rs1, F3_0, rd, OPFP);
}

void MicroAssembler::fcvtdl(FRegister rd, Register rs1, RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTDint, FRegister(L), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fcvtdlu(FRegister rd,
                             Register rs1,
                             RoundingMode rounding) {
  ASSERT(Supports(RV_D));
  EmitRType(FCVTDint, FRegister(LU), rs1, rounding, rd, OPFP);
}

void MicroAssembler::fmvdx(FRegister rd, Register rs1) {
  ASSERT(Supports(RV_D));
  EmitRType(FMVDX, FRegister(0), rs1, F3_0, rd, OPFP);
}
#endif  // XLEN >= 64

#if XLEN >= 64
void MicroAssembler::adduw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(ADDUW, rs2, rs1, F3_0, rd, OP32);
}
#endif

void MicroAssembler::sh1add(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH1ADD, rd, OP);
}

#if XLEN >= 64
void MicroAssembler::sh1adduw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH1ADD, rd, OP32);
}
#endif

void MicroAssembler::sh2add(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH2ADD, rd, OP);
}

#if XLEN >= 64
void MicroAssembler::sh2adduw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH2ADD, rd, OP32);
}
#endif

void MicroAssembler::sh3add(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH3ADD, rd, OP);
}

#if XLEN >= 64
void MicroAssembler::sh3adduw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zba));
  EmitRType(SHADD, rs2, rs1, SH3ADD, rd, OP32);
}

void MicroAssembler::slliuw(Register rd, Register rs1, intx_t shamt) {
  ASSERT((shamt > 0) && (shamt < 32));
  ASSERT(Supports(RV_Zba));
  EmitRType(SLLIUW, shamt, rs1, SLLI, rd, OPIMM32);
}
#endif

void MicroAssembler::andn(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(SUB, rs2, rs1, AND, rd, OP);
}

void MicroAssembler::orn(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(SUB, rs2, rs1, OR, rd, OP);
}

void MicroAssembler::xnor(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(SUB, rs2, rs1, XOR, rd, OP);
}

void MicroAssembler::clz(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00000, rs1, F3_COUNT, rd, OPIMM);
}

void MicroAssembler::clzw(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00000, rs1, F3_COUNT, rd, OPIMM32);
}

void MicroAssembler::ctz(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00001, rs1, F3_COUNT, rd, OPIMM);
}

void MicroAssembler::ctzw(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00001, rs1, F3_COUNT, rd, OPIMM32);
}

void MicroAssembler::cpop(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00010, rs1, F3_COUNT, rd, OPIMM);
}

void MicroAssembler::cpopw(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(COUNT, 0b00010, rs1, F3_COUNT, rd, OPIMM32);
}

void MicroAssembler::max(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(MINMAXCLMUL, rs2, rs1, MAX, rd, OP);
}

void MicroAssembler::maxu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(MINMAXCLMUL, rs2, rs1, MAXU, rd, OP);
}

void MicroAssembler::min(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(MINMAXCLMUL, rs2, rs1, MIN, rd, OP);
}

void MicroAssembler::minu(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(MINMAXCLMUL, rs2, rs1, MINU, rd, OP);
}

void MicroAssembler::sextb(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType((Funct7)0b0110000, 0b00100, rs1, SEXT, rd, OPIMM);
}

void MicroAssembler::sexth(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType((Funct7)0b0110000, 0b00101, rs1, SEXT, rd, OPIMM);
}

void MicroAssembler::zexth(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
#if XLEN == 32
  EmitRType((Funct7)0b0000100, 0b00000, rs1, ZEXT, rd, OP);
#elif XLEN == 64
  EmitRType((Funct7)0b0000100, 0b00000, rs1, ZEXT, rd, OP32);
#else
  UNIMPLEMENTED();
#endif
}

void MicroAssembler::rol(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, rs2, rs1, ROL, rd, OP);
}

void MicroAssembler::rolw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, rs2, rs1, ROL, rd, OP32);
}

void MicroAssembler::ror(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, rs2, rs1, ROR, rd, OP);
}

void MicroAssembler::rori(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, shamt, rs1, ROR, rd, OPIMM);
}

void MicroAssembler::roriw(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, shamt, rs1, ROR, rd, OPIMM32);
}

void MicroAssembler::rorw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbb));
  EmitRType(ROTATE, rs2, rs1, ROR, rd, OP32);
}

void MicroAssembler::orcb(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
  EmitRType((Funct7)0b0010100, 0b00111, rs1, (Funct3)0b101, rd, OPIMM);
}

void MicroAssembler::rev8(Register rd, Register rs1) {
  ASSERT(Supports(RV_Zbb));
#if XLEN == 32
  EmitRType((Funct7)0b0110100, 0b11000, rs1, (Funct3)0b101, rd, OPIMM);
#elif XLEN == 64
  EmitRType((Funct7)0b0110101, 0b11000, rs1, (Funct3)0b101, rd, OPIMM);
#else
  UNIMPLEMENTED();
#endif
}

void MicroAssembler::clmul(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbc));
  EmitRType(MINMAXCLMUL, rs2, rs1, CLMUL, rd, OP);
}

void MicroAssembler::clmulh(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbc));
  EmitRType(MINMAXCLMUL, rs2, rs1, CLMULH, rd, OP);
}

void MicroAssembler::clmulr(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbc));
  EmitRType(MINMAXCLMUL, rs2, rs1, CLMULR, rd, OP);
}

void MicroAssembler::bclr(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BCLRBEXT, rs2, rs1, BCLR, rd, OP);
}

void MicroAssembler::bclri(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BCLRBEXT, shamt, rs1, BCLR, rd, OPIMM);
}

void MicroAssembler::bext(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BCLRBEXT, rs2, rs1, BEXT, rd, OP);
}

void MicroAssembler::bexti(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BCLRBEXT, shamt, rs1, BEXT, rd, OPIMM);
}

void MicroAssembler::binv(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BINV, rs2, rs1, F3_BINV, rd, OP);
}

void MicroAssembler::binvi(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BINV, shamt, rs1, F3_BINV, rd, OPIMM);
}

void MicroAssembler::bset(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BSET, rs2, rs1, F3_BSET, rd, OP);
}

void MicroAssembler::bseti(Register rd, Register rs1, intx_t shamt) {
  ASSERT(Supports(RV_Zbs));
  EmitRType(BSET, shamt, rs1, F3_BSET, rd, OPIMM);
}

void MicroAssembler::c_lwsp(Register rd, Address addr) {
  ASSERT(rd != ZR);
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  Emit16(C_LWSP | EncodeCRd(rd) | EncodeCSPLoad4Imm(addr.offset()));
}

#if XLEN == 32
void MicroAssembler::c_flwsp(FRegister rd, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_F));
  Emit16(C_FLWSP | EncodeCFRd(rd) | EncodeCSPLoad4Imm(addr.offset()));
}
#else
void MicroAssembler::c_ldsp(Register rd, Address addr) {
  ASSERT(rd != ZR);
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  Emit16(C_LDSP | EncodeCRd(rd) | EncodeCSPLoad8Imm(addr.offset()));
}
#endif

void MicroAssembler::c_fldsp(FRegister rd, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_D));
  Emit16(C_FLDSP | EncodeCFRd(rd) | EncodeCSPLoad8Imm(addr.offset()));
}

void MicroAssembler::c_swsp(Register rs2, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  Emit16(C_SWSP | EncodeCRs2(rs2) | EncodeCSPStore4Imm(addr.offset()));
}

#if XLEN == 32
void MicroAssembler::c_fswsp(FRegister rs2, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_F));
  Emit16(C_FSWSP | EncodeCFRs2(rs2) | EncodeCSPStore4Imm(addr.offset()));
}
#else
void MicroAssembler::c_sdsp(Register rs2, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  Emit16(C_SDSP | EncodeCRs2(rs2) | EncodeCSPStore8Imm(addr.offset()));
}
#endif
void MicroAssembler::c_fsdsp(FRegister rs2, Address addr) {
  ASSERT(addr.base() == SP);
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_D));
  Emit16(C_FSDSP | EncodeCFRs2(rs2) | EncodeCSPStore8Imm(addr.offset()));
}

void MicroAssembler::c_lw(Register rd, Address addr) {
  ASSERT(Supports(RV_C));
  Emit16(C_LW | EncodeCRdp(rd) | EncodeCRs1p(addr.base()) |
         EncodeCMem4Imm(addr.offset()));
}

void MicroAssembler::c_ld(Register rd, Address addr) {
  ASSERT(Supports(RV_C));
  Emit16(C_LD | EncodeCRdp(rd) | EncodeCRs1p(addr.base()) |
         EncodeCMem8Imm(addr.offset()));
}

void MicroAssembler::c_flw(FRegister rd, Address addr) {
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_F));
  Emit16(C_FLW | EncodeCFRdp(rd) | EncodeCRs1p(addr.base()) |
         EncodeCMem4Imm(addr.offset()));
}

void MicroAssembler::c_fld(FRegister rd, Address addr) {
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_D));
  Emit16(C_FLD | EncodeCFRdp(rd) | EncodeCRs1p(addr.base()) |
         EncodeCMem8Imm(addr.offset()));
}

void MicroAssembler::c_sw(Register rs2, Address addr) {
  ASSERT(Supports(RV_C));
  Emit16(C_SW | EncodeCRs1p(addr.base()) | EncodeCRs2p(rs2) |
         EncodeCMem4Imm(addr.offset()));
}

void MicroAssembler::c_sd(Register rs2, Address addr) {
  ASSERT(Supports(RV_C));
  Emit16(C_SD | EncodeCRs1p(addr.base()) | EncodeCRs2p(rs2) |
         EncodeCMem8Imm(addr.offset()));
}

void MicroAssembler::c_fsw(FRegister rs2, Address addr) {
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_F));
  Emit16(C_FSW | EncodeCRs1p(addr.base()) | EncodeCFRs2p(rs2) |
         EncodeCMem4Imm(addr.offset()));
}

void MicroAssembler::c_fsd(FRegister rs2, Address addr) {
  ASSERT(Supports(RV_C));
  ASSERT(Supports(RV_D));
  Emit16(C_FSD | EncodeCRs1p(addr.base()) | EncodeCFRs2p(rs2) |
         EncodeCMem8Imm(addr.offset()));
}

void MicroAssembler::c_j(Label* label) {
  ASSERT(Supports(RV_C));
  EmitCJump(label, C_J);
}

#if XLEN == 32
void MicroAssembler::c_jal(Label* label) {
  ASSERT(Supports(RV_C));
  EmitCJump(label, C_JAL);
}
#endif  // XLEN == 32

void MicroAssembler::c_jr(Register rs1) {
  ASSERT(Supports(RV_C));
  ASSERT(rs1 != ZR);
  Emit16(C_JR | EncodeCRs1(rs1) | EncodeCRs2(ZR));
}

void MicroAssembler::c_jalr(Register rs1) {
  ASSERT(Supports(RV_C));
  Emit16(C_JALR | EncodeCRs1(rs1) | EncodeCRs2(ZR));
}

void MicroAssembler::c_beqz(Register rs1p, Label* label) {
  ASSERT(Supports(RV_C));
  EmitCBranch(rs1p, label, C_BEQZ);
}

void MicroAssembler::c_bnez(Register rs1p, Label* label) {
  ASSERT(Supports(RV_C));
  EmitCBranch(rs1p, label, C_BNEZ);
}

void MicroAssembler::c_li(Register rd, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd != ZR);
  Emit16(C_LI | EncodeCRd(rd) | EncodeCIImm(imm));
}

void MicroAssembler::c_lui(Register rd, uintptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd != ZR);
  ASSERT(rd != SP);
  Emit16(C_LUI | EncodeCRd(rd) | EncodeCUImm(imm));
}

void MicroAssembler::c_addi(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(imm != 0);
  ASSERT(rd == rs1);
  Emit16(C_ADDI | EncodeCRd(rd) | EncodeCIImm(imm));
}

#if XLEN >= 64
void MicroAssembler::c_addiw(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  Emit16(C_ADDIW | EncodeCRd(rd) | EncodeCIImm(imm));
}
#endif
void MicroAssembler::c_addi16sp(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  Emit16(C_ADDI16SP | EncodeCRd(rd) | EncodeCI16Imm(imm));
}

void MicroAssembler::c_addi4spn(Register rdp, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rs1 == SP);
  ASSERT(imm != 0);
  Emit16(C_ADDI4SPN | EncodeCRdp(rdp) | EncodeCI4SPNImm(imm));
}

void MicroAssembler::c_slli(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  ASSERT(imm != 0);
  Emit16(C_SLLI | EncodeCRd(rd) | EncodeCIImm(imm));
}

void MicroAssembler::c_srli(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  ASSERT(imm != 0);
  Emit16(C_SRLI | EncodeCRs1p(rd) | EncodeCIImm(imm));
}

void MicroAssembler::c_srai(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  ASSERT(imm != 0);
  Emit16(C_SRAI | EncodeCRs1p(rd) | EncodeCIImm(imm));
}

void MicroAssembler::c_andi(Register rd, Register rs1, intptr_t imm) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  Emit16(C_ANDI | EncodeCRs1p(rd) | EncodeCIImm(imm));
}

void MicroAssembler::c_mv(Register rd, Register rs2) {
  ASSERT(Supports(RV_C));
  ASSERT(rd != ZR);
  ASSERT(rs2 != ZR);
  Emit16(C_MV | EncodeCRd(rd) | EncodeCRs2(rs2));
}

void MicroAssembler::c_add(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  ASSERT(rd != ZR);
  ASSERT(rd == rs1);
  ASSERT(rs2 != ZR);
  Emit16(C_ADD | EncodeCRd(rd) | EncodeCRs2(rs2));
}

void MicroAssembler::c_and(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  ASSERT(rd == rs1);
  Emit16(C_AND | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}

void MicroAssembler::c_or(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  Emit16(C_OR | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}

void MicroAssembler::c_xor(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  Emit16(C_XOR | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}

void MicroAssembler::c_sub(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  Emit16(C_SUB | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}

#if XLEN >= 64
void MicroAssembler::c_addw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  Emit16(C_ADDW | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}

void MicroAssembler::c_subw(Register rd, Register rs1, Register rs2) {
  ASSERT(Supports(RV_C));
  Emit16(C_SUBW | EncodeCRs1p(rs1) | EncodeCRs2p(rs2));
}
#endif  // XLEN >= 64

void MicroAssembler::c_nop() {
  ASSERT(Supports(RV_C));
  Emit16(C_NOP);
}

void MicroAssembler::c_ebreak() {
  ASSERT(Supports(RV_C));
  Emit16(C_EBREAK);
}

static Funct3 InvertFunct3(Funct3 func) {
  switch (func) {
    case BEQ:
      return BNE;
    case BNE:
      return BEQ;
    case BGE:
      return BLT;
    case BGEU:
      return BLTU;
    case BLT:
      return BGE;
    case BLTU:
      return BGEU;
    default:
      UNREACHABLE();
  }
}

void MicroAssembler::EmitBranch(Register rs1,
                                Register rs2,
                                Label* label,
                                Funct3 func,
                                JumpDistance distance) {
  intptr_t offset;
  if (label->IsBound()) {
    // Backward branch: use near or far branch based on actual distance.
    offset = label->Position() - Position();
    if (IsBTypeImm(offset)) {
      EmitBType(offset, rs2, rs1, func, BRANCH);
      return;
    }

    if (IsJTypeImm(offset + 4)) {
      intptr_t start = Position();
      const intptr_t kFarBranchLength = 8;
      EmitBType(kFarBranchLength, rs2, rs1, InvertFunct3(func), BRANCH);
      offset = label->Position() - Position();
      EmitJType(offset, ZR, JAL);
      intptr_t end = Position();
      ASSERT_EQUAL(end - start, kFarBranchLength);
      return;
    }

    intptr_t start = Position();
    const intptr_t kFarBranchLength = 12;
    EmitBType(kFarBranchLength, rs2, rs1, InvertFunct3(func), BRANCH);
    offset = label->Position() - Position();
    intx_t lo = ImmLo(offset);
    intx_t hi = ImmHi(offset);
    if (!IsUTypeImm(hi)) {
      FATAL("Branch distance exceeds 2GB!");
    }
    EmitUType(hi, FAR_TMP, AUIPC);
    EmitIType(lo, FAR_TMP, F3_0, ZR, JALR);
    intptr_t end = Position();
    ASSERT_EQUAL(end - start, kFarBranchLength);
    return;
  } else {
    // Forward branch: speculatively use near branches and re-assemble with far
    // branches if any need greater length.
    if (distance == kNearJump) {
      offset = label->link_b(Position());
      if (!IsBTypeImm(offset)) {
        FATAL("Incorrect Assembler::kNearJump");
      }
      EmitBType(offset, rs2, rs1, func, BRANCH);
    } else if (far_branch_level() == 0) {
      offset = label->link_b(Position());
      if (!IsBTypeImm(offset)) {
        // TODO(riscv): This isn't so much because the branch is out of range
        // as some previous jump to the same target would be out of B-type
        // range... A possible alternative is to have separate lists on Labels
        // for pending B-type and J-type instructions.
        BailoutWithBranchOffsetError();
      }
      EmitBType(offset, rs2, rs1, func, BRANCH);
    } else if (far_branch_level() == 1) {
      intptr_t start = Position();
      const intptr_t kFarBranchLength = 8;
      EmitBType(kFarBranchLength, rs2, rs1, InvertFunct3(func), BRANCH);
      offset = label->link_j(Position());
      EmitJType(offset, ZR, JAL);
      intptr_t end = Position();
      ASSERT_EQUAL(end - start, kFarBranchLength);
    } else {
      intptr_t start = Position();
      const intptr_t kFarBranchLength = 12;
      EmitBType(kFarBranchLength, rs2, rs1, InvertFunct3(func), BRANCH);
      offset = label->link_far(Position());
      intx_t lo = ImmLo(offset);
      intx_t hi = ImmHi(offset);
      if (!IsUTypeImm(hi)) {
        FATAL("Branch distance exceeds 2GB!");
      }
      EmitUType(hi, FAR_TMP, AUIPC);
      EmitIType(lo, FAR_TMP, F3_0, ZR, JALR);
      intptr_t end = Position();
      ASSERT_EQUAL(end - start, kFarBranchLength);
    }
  }
}

void MicroAssembler::EmitJump(Register rd,
                              Label* label,
                              Opcode op,
                              JumpDistance distance) {
  intptr_t offset;
  if (label->IsBound()) {
    // Backward jump: use near or far jump based on actual distance.
    offset = label->Position() - Position();

    if (IsJTypeImm(offset)) {
      EmitJType(offset, rd, JAL);
      return;
    }
    intx_t lo = ImmLo(offset);
    intx_t hi = ImmHi(offset);
    if (!IsUTypeImm(hi)) {
      FATAL("Jump distance exceeds 2GB!");
    }
    EmitUType(hi, FAR_TMP, AUIPC);
    EmitIType(lo, FAR_TMP, F3_0, ZR, JALR);
    return;
  } else {
    // Forward jump: speculatively use near jumps and re-assemble with far
    // jumps if any need greater length.
    if (distance == kNearJump) {
      offset = label->link_j(Position());
      if (!IsJTypeImm(offset)) {
        FATAL("Incorrect Assembler::kNearJump");
      }
      EmitJType(offset, rd, JAL);
    } else if (far_branch_level() < 2) {
      offset = label->link_j(Position());
      if (!IsJTypeImm(offset)) {
        BailoutWithBranchOffsetError();
      }
      EmitJType(offset, rd, JAL);
    } else {
      offset = label->link_far(Position());
      intx_t lo = ImmLo(offset);
      intx_t hi = ImmHi(offset);
      if (!IsUTypeImm(hi)) {
        FATAL("Jump distance exceeds 2GB!");
      }
      EmitUType(hi, FAR_TMP, AUIPC);
      EmitIType(lo, FAR_TMP, F3_0, ZR, JALR);
    }
  }
}

void MicroAssembler::EmitCBranch(Register rs1p, Label* label, COpcode op) {
  intptr_t offset;
  if (label->IsBound()) {
    offset = label->Position() - Position();
  } else {
    offset = label->link_cb(Position());
  }
  if (!IsCBImm(offset)) {
    FATAL("Incorrect Assembler::kNearJump");
  }
  Emit16(op | EncodeCRs1p(rs1p) | EncodeCBImm(offset));
}

void MicroAssembler::EmitCJump(Label* label, COpcode op) {
  intptr_t offset;
  if (label->IsBound()) {
    offset = label->Position() - Position();
  } else {
    offset = label->link_cj(Position());
  }
  if (!IsCJImm(offset)) {
    FATAL("Incorrect Assembler::kNearJump");
  }
  Emit16(op | EncodeCJImm(offset));
}

void MicroAssembler::EmitRType(Funct5 funct5,
                               std::memory_order order,
                               Register rs2,
                               Register rs1,
                               Funct3 funct3,
                               Register rd,
                               Opcode opcode) {
  intptr_t funct7 = funct5 << 2;
  switch (order) {
    case std::memory_order_acq_rel:
      funct7 |= 0b11;
      break;
    case std::memory_order_acquire:
      funct7 |= 0b10;
      break;
    case std::memory_order_release:
      funct7 |= 0b01;
      break;
    case std::memory_order_relaxed:
      funct7 |= 0b00;
      break;
    default:
      FATAL("Invalid memory order");
  }
  EmitRType((Funct7)funct7, rs2, rs1, funct3, rd, opcode);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               Register rs2,
                               Register rs1,
                               Funct3 funct3,
                               Register rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               FRegister rs1,
                               Funct3 funct3,
                               FRegister rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeFRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               FRegister rs1,
                               RoundingMode round,
                               FRegister rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeFRs1(rs1);
  e |= EncodeRoundingMode(round);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               Register rs1,
                               RoundingMode round,
                               FRegister rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeRoundingMode(round);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               Register rs1,
                               Funct3 funct3,
                               FRegister rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               FRegister rs1,
                               Funct3 funct3,
                               Register rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeFRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               FRegister rs2,
                               FRegister rs1,
                               RoundingMode round,
                               Register rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeFRs2(rs2);
  e |= EncodeFRs1(rs1);
  e |= EncodeRoundingMode(round);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitRType(Funct7 funct7,
                               intptr_t shamt,
                               Register rs1,
                               Funct3 funct3,
                               Register rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFunct7(funct7);
  e |= EncodeShamt(shamt);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitR4Type(FRegister rs3,
                                Funct2 funct2,
                                FRegister rs2,
                                FRegister rs1,
                                RoundingMode round,
                                FRegister rd,
                                Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeFRs3(rs3);
  e |= EncodeFunct2(funct2);
  e |= EncodeFRs2(rs2);
  e |= EncodeFRs1(rs1);
  e |= EncodeRoundingMode(round);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitIType(intptr_t imm,
                               Register rs1,
                               Funct3 funct3,
                               Register rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeITypeImm(imm);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitIType(intptr_t imm,
                               Register rs1,
                               Funct3 funct3,
                               FRegister rd,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeITypeImm(imm);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeFRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitSType(intptr_t imm,
                               Register rs2,
                               Register rs1,
                               Funct3 funct3,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeSTypeImm(imm);
  e |= EncodeRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitSType(intptr_t imm,
                               FRegister rs2,
                               Register rs1,
                               Funct3 funct3,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeSTypeImm(imm);
  e |= EncodeFRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitBType(intptr_t imm,
                               Register rs2,
                               Register rs1,
                               Funct3 funct3,
                               Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeBTypeImm(imm);
  e |= EncodeRs2(rs2);
  e |= EncodeRs1(rs1);
  e |= EncodeFunct3(funct3);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitUType(intptr_t imm, Register rd, Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeUTypeImm(imm);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

void MicroAssembler::EmitJType(intptr_t imm, Register rd, Opcode opcode) {
  uint32_t e = 0;
  e |= EncodeJTypeImm(imm);
  e |= EncodeRd(rd);
  e |= EncodeOpcode(opcode);
  Emit32(e);
}

Assembler::Assembler(ObjectPoolBuilder* object_pool_builder,
                     intptr_t far_branch_level)
    : MicroAssembler(object_pool_builder,
                     far_branch_level,
                     FLAG_use_compressed_instructions ? RV_GC : RV_G),
      constant_pool_allowed_(false) {
  generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
    // Note this does not destroy RA.
    lx(TMP,
       Address(THR, target::Thread::write_barrier_wrappers_thread_offset(reg)));
    jalr(TMP, TMP);
  };
  generate_invoke_array_write_barrier_ = [&]() {
    Call(
        Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
  };
}

void Assembler::PushRegister(Register r) {
  ASSERT(r != SP);
  subi(SP, SP, target::kWordSize);
  sx(r, Address(SP, 0));
}
void Assembler::PopRegister(Register r) {
  ASSERT(r != SP);
  lx(r, Address(SP, 0));
  addi(SP, SP, target::kWordSize);
}

void Assembler::PushRegisterPair(Register r0, Register r1) {
  ASSERT(r0 != SP);
  ASSERT(r1 != SP);
  subi(SP, SP, 2 * target::kWordSize);
  sx(r1, Address(SP, target::kWordSize));
  sx(r0, Address(SP, 0));
}

void Assembler::PopRegisterPair(Register r0, Register r1) {
  ASSERT(r0 != SP);
  ASSERT(r1 != SP);
  lx(r1, Address(SP, target::kWordSize));
  lx(r0, Address(SP, 0));
  addi(SP, SP, 2 * target::kWordSize);
}

void Assembler::PushRegisters(const RegisterSet& regs) {
  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safepoint's stack map.

  intptr_t size = (regs.CpuRegisterCount() * target::kWordSize) +
                  (regs.FpuRegisterCount() * kFpuRegisterSize);
  if (size == 0) {
    return;  // Skip no-op SP update.
  }

  subi(SP, SP, size);
  intptr_t offset = size;
  for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; i--) {
    FRegister reg = static_cast<FRegister>(i);
    if (regs.ContainsFpuRegister(reg)) {
      offset -= kFpuRegisterSize;
      fsd(reg, Address(SP, offset));
    }
  }
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; i--) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      offset -= target::kWordSize;
      sx(reg, Address(SP, offset));
    }
  }
  ASSERT(offset == 0);
}

void Assembler::PopRegisters(const RegisterSet& regs) {
  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safepoint's stack map.

  intptr_t size = (regs.CpuRegisterCount() * target::kWordSize) +
                  (regs.FpuRegisterCount() * kFpuRegisterSize);
  if (size == 0) {
    return;  // Skip no-op SP update.
  }
  intptr_t offset = 0;
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      lx(reg, Address(SP, offset));
      offset += target::kWordSize;
    }
  }
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    FRegister reg = static_cast<FRegister>(i);
    if (regs.ContainsFpuRegister(reg)) {
      fld(reg, Address(SP, offset));
      offset += kFpuRegisterSize;
    }
  }
  ASSERT(offset == size);
  addi(SP, SP, size);
}

void Assembler::PushRegistersInOrder(std::initializer_list<Register> regs) {
  intptr_t offset = regs.size() * target::kWordSize;
  subi(SP, SP, offset);
  for (Register reg : regs) {
    ASSERT(reg != SP);
    offset -= target::kWordSize;
    sx(reg, Address(SP, offset));
  }
}

void Assembler::PushNativeCalleeSavedRegisters() {
  RegisterSet regs(kAbiPreservedCpuRegs, kAbiPreservedFpuRegs);
  intptr_t size = (regs.CpuRegisterCount() * target::kWordSize) +
                  (regs.FpuRegisterCount() * sizeof(double));
  subi(SP, SP, size);
  intptr_t offset = 0;
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    FRegister reg = static_cast<FRegister>(i);
    if (regs.ContainsFpuRegister(reg)) {
      fsd(reg, Address(SP, offset));
      offset += sizeof(double);
    }
  }
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      sx(reg, Address(SP, offset));
      offset += target::kWordSize;
    }
  }
  ASSERT(offset == size);
}

void Assembler::PopNativeCalleeSavedRegisters() {
  RegisterSet regs(kAbiPreservedCpuRegs, kAbiPreservedFpuRegs);
  intptr_t size = (regs.CpuRegisterCount() * target::kWordSize) +
                  (regs.FpuRegisterCount() * sizeof(double));
  intptr_t offset = 0;
  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    FRegister reg = static_cast<FRegister>(i);
    if (regs.ContainsFpuRegister(reg)) {
      fld(reg, Address(SP, offset));
      offset += sizeof(double);
    }
  }
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    Register reg = static_cast<Register>(i);
    if (regs.ContainsRegister(reg)) {
      lx(reg, Address(SP, offset));
      offset += target::kWordSize;
    }
  }
  ASSERT(offset == size);
  addi(SP, SP, size);
}

void Assembler::ExtendValue(Register rd, Register rn, OperandSize sz) {
  switch (sz) {
#if XLEN == 64
    case kEightBytes:
      if (rd == rn) return;  // No operation needed.
      return mv(rd, rn);
    case kUnsignedFourBytes:
      return UNIMPLEMENTED();
    case kFourBytes:
      return sextw(rd, rn);
#elif XLEN == 32
    case kUnsignedFourBytes:
    case kFourBytes:
      if (rd == rn) return;  // No operation needed.
      return mv(rd, rn);
#endif
    case kUnsignedTwoBytes:
    case kTwoBytes:
    case kUnsignedByte:
    case kByte:
    default:
      UNIMPLEMENTED();
      break;
  }
  UNIMPLEMENTED();
}
void Assembler::ExtendAndSmiTagValue(Register rd, Register rn, OperandSize sz) {
  if (sz == kWordBytes) {
    SmiTag(rd, rn);
    return;
  }

  switch (sz) {
#if XLEN == 64
    case kUnsignedFourBytes:
      slli(rd, rn, XLEN - kBitsPerInt32);
      srli(rd, rd, XLEN - kBitsPerInt32 - kSmiTagShift);
      return;
    case kFourBytes:
      slli(rd, rn, XLEN - kBitsPerInt32);
      srai(rd, rd, XLEN - kBitsPerInt32 - kSmiTagShift);
      return;
#endif
    case kUnsignedTwoBytes:
      slli(rd, rn, XLEN - kBitsPerInt16);
      srli(rd, rd, XLEN - kBitsPerInt16 - kSmiTagShift);
      return;
    case kTwoBytes:
      slli(rd, rn, XLEN - kBitsPerInt16);
      srai(rd, rd, XLEN - kBitsPerInt16 - kSmiTagShift);
      return;
    case kUnsignedByte:
      slli(rd, rn, XLEN - kBitsPerInt8);
      srli(rd, rd, XLEN - kBitsPerInt8 - kSmiTagShift);
      return;
    case kByte:
      slli(rd, rn, XLEN - kBitsPerInt8);
      srai(rd, rd, XLEN - kBitsPerInt8 - kSmiTagShift);
      return;
    default:
      UNIMPLEMENTED();
      break;
  }
}

// Unconditional jump to a given address in memory. Clobbers TMP.
void Assembler::Jump(const Address& address) {
  lx(TMP2, address);
  jr(TMP2);
}

void Assembler::LoadField(Register dst, const FieldAddress& address) {
  lx(dst, address);
}

#if defined(TARGET_USES_THREAD_SANITIZER)
void Assembler::TsanLoadAcquire(Register addr) {
  LeafRuntimeScope rt(this, /*frame_size=*/0, /*preserve_registers=*/true);
  MoveRegister(A0, addr);
  rt.Call(kTsanLoadAcquireRuntimeEntry, /*argument_count=*/1);
}
void Assembler::TsanStoreRelease(Register addr) {
  LeafRuntimeScope rt(this, /*frame_size=*/0, /*preserve_registers=*/true);
  MoveRegister(A0, addr);
  rt.Call(kTsanStoreReleaseRuntimeEntry, /*argument_count=*/1);
}
#endif

void Assembler::LoadAcquire(Register dst,
                            Register address,
                            int32_t offset,
                            OperandSize size) {
  ASSERT(dst != address);
  LoadFromOffset(dst, address, offset, size);
  fence(HartEffects::kRead, HartEffects::kMemory);

#if defined(TARGET_USES_THREAD_SANITIZER)
  if (offset == 0) {
    TsanLoadAcquire(address);
  } else {
    AddImmediate(TMP2, address, offset);
    TsanLoadAcquire(TMP2);
  }
#endif
}

void Assembler::LoadAcquireCompressed(Register dst,
                                      Register address,
                                      int32_t offset) {
  LoadAcquire(dst, address, offset);
}

void Assembler::StoreRelease(Register src, Register address, int32_t offset) {
  fence(HartEffects::kMemory, HartEffects::kWrite);
  StoreToOffset(src, address, offset);
}

void Assembler::StoreReleaseCompressed(Register src,
                                       Register address,
                                       int32_t offset) {
  UNIMPLEMENTED();
}

void Assembler::CompareWithCompressedFieldFromOffset(Register value,
                                                     Register base,
                                                     int32_t offset) {
  UNIMPLEMENTED();
}

void Assembler::CompareWithMemoryValue(Register value,
                                       Address address,
                                       OperandSize size) {
#if XLEN >= 64
  ASSERT(size == kEightBytes || size == kFourBytes);
  if (size == kFourBytes) {
    lw(TMP2, address);
  } else {
    ld(TMP2, address);
  }
#else
  ASSERT_EQUAL(size, kFourBytes);
  lx(TMP2, address);
#endif
  CompareRegisters(value, TMP2);
}

void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  if (frame_space != 0) {
    addi(SP, SP, -frame_space);
  }
  const intptr_t kAbiStackAlignment = 16;  // For both 32 and 64 bit.
  andi(SP, SP, ~(kAbiStackAlignment - 1));
}

// In debug mode, this generates code to check that:
//   FP + kExitLinkSlotFromEntryFp == SP
// or triggers breakpoint otherwise.
void Assembler::EmitEntryFrameVerification() {
#if defined(DEBUG)
  Label done;
  ASSERT(!constant_pool_allowed());
  LoadImmediate(TMP, target::frame_layout.exit_link_slot_from_entry_fp *
                         target::kWordSize);
  add(TMP, TMP, FPREG);
  beq(TMP, SPREG, &done, kNearJump);

  Breakpoint();

  Bind(&done);
#endif
}

void Assembler::CompareRegisters(Register rn, Register rm) {
  ASSERT(deferred_compare_ == kNone);
  deferred_compare_ = kCompareReg;
  deferred_left_ = rn;
  deferred_reg_ = rm;
}
void Assembler::CompareObjectRegisters(Register rn, Register rm) {
  CompareRegisters(rn, rm);
}
void Assembler::TestRegisters(Register rn, Register rm) {
  ASSERT(deferred_compare_ == kNone);
  deferred_compare_ = kTestReg;
  deferred_left_ = rn;
  deferred_reg_ = rm;
}

void Assembler::BranchIf(Condition condition,
                         Label* label,
                         JumpDistance distance) {
  ASSERT(deferred_compare_ != kNone);

  if (deferred_compare_ == kCompareImm || deferred_compare_ == kCompareReg) {
    Register left = deferred_left_;
    Register right;
    if (deferred_compare_ == kCompareImm) {
      if (deferred_imm_ == 0) {
        right = ZR;
      } else {
        LoadImmediate(TMP2, deferred_imm_);
        right = TMP2;
      }
    } else {
      right = deferred_reg_;
    }
    switch (condition) {
      case EQUAL:
        beq(left, right, label, distance);
        break;
      case NOT_EQUAL:
        bne(left, right, label, distance);
        break;
      case LESS:
        blt(left, right, label, distance);
        break;
      case LESS_EQUAL:
        ble(left, right, label, distance);
        break;
      case GREATER_EQUAL:
        bge(left, right, label, distance);
        break;
      case GREATER:
        bgt(left, right, label, distance);
        break;
      case UNSIGNED_LESS:
        bltu(left, right, label, distance);
        break;
      case UNSIGNED_LESS_EQUAL:
        bleu(left, right, label, distance);
        break;
      case UNSIGNED_GREATER_EQUAL:
        bgeu(left, right, label, distance);
        break;
      case UNSIGNED_GREATER:
        bgtu(left, right, label, distance);
        break;
      case OVERFLOW:
      case NO_OVERFLOW:
        FATAL("Use Add/Subtract/MultiplyBranchOverflow instead.");
      default:
        UNREACHABLE();
    }
  } else if (deferred_compare_ == kTestImm || deferred_compare_ == kTestReg) {
    if (deferred_compare_ == kTestImm) {
      AndImmediate(TMP2, deferred_left_, deferred_imm_);
    } else {
      and_(TMP2, deferred_left_, deferred_reg_);
    }
    switch (condition) {
      case ZERO:
        beqz(TMP2, label, distance);
        break;
      case NOT_ZERO:
        bnez(TMP2, label, distance);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    UNREACHABLE();
  }
  deferred_compare_ = kNone;  // Consumed.
}

void Assembler::SetIf(Condition condition, Register rd) {
  ASSERT(deferred_compare_ != kNone);

  if (deferred_compare_ == kCompareImm) {
    if (deferred_imm_ == 0) {
      deferred_compare_ = kCompareReg;
      deferred_reg_ = ZR;
      SetIf(condition, rd);
      return;
    }
    if (!IsITypeImm(deferred_imm_) || !IsITypeImm(deferred_imm_ + 1)) {
      LoadImmediate(TMP2, deferred_imm_);
      deferred_compare_ = kCompareReg;
      deferred_reg_ = TMP2;
      SetIf(condition, rd);
      return;
    }
    Register left = deferred_left_;
    intx_t right = deferred_imm_;
    switch (condition) {
      case EQUAL:
        subi(rd, left, right);
        seqz(rd, rd);
        break;
      case NOT_EQUAL:
        subi(rd, left, right);
        snez(rd, rd);
        break;
      case LESS:
        slti(rd, left, right);
        break;
      case LESS_EQUAL:
        slti(rd, left, right + 1);
        break;
      case GREATER_EQUAL:
        slti(rd, left, right);
        xori(rd, rd, 1);
        break;
      case GREATER:
        slti(rd, left, right + 1);
        xori(rd, rd, 1);
        break;
      case UNSIGNED_LESS:
        sltiu(rd, left, right);
        break;
      case UNSIGNED_LESS_EQUAL:
        sltiu(rd, left, right + 1);
        break;
      case UNSIGNED_GREATER_EQUAL:
        sltiu(rd, left, right);
        xori(rd, rd, 1);
        break;
      case UNSIGNED_GREATER:
        sltiu(rd, left, right + 1);
        xori(rd, rd, 1);
        break;
      default:
        UNREACHABLE();
    }
  } else if (deferred_compare_ == kCompareReg) {
    Register left = deferred_left_;
    Register right = deferred_reg_;
    switch (condition) {
      case EQUAL:
        if (right == ZR) {
          seqz(rd, left);
        } else {
          xor_(rd, left, right);
          seqz(rd, rd);
        }
        break;
      case NOT_EQUAL:
        if (right == ZR) {
          snez(rd, left);
        } else {
          xor_(rd, left, right);
          snez(rd, rd);
        }
        break;
      case LESS:
        slt(rd, left, right);
        break;
      case LESS_EQUAL:
        slt(rd, right, left);
        xori(rd, rd, 1);
        break;
      case GREATER_EQUAL:
        slt(rd, left, right);
        xori(rd, rd, 1);
        break;
      case GREATER:
        slt(rd, right, left);
        break;
      case UNSIGNED_LESS:
        sltu(rd, left, right);
        break;
      case UNSIGNED_LESS_EQUAL:
        sltu(rd, right, left);
        xori(rd, rd, 1);
        break;
      case UNSIGNED_GREATER_EQUAL:
        sltu(rd, left, right);
        xori(rd, rd, 1);
        break;
      case UNSIGNED_GREATER:
        sltu(rd, right, left);
        break;
      default:
        UNREACHABLE();
    }
  } else if (deferred_compare_ == kTestImm) {
    uintx_t uimm = deferred_imm_;
    if (deferred_imm_ == 1) {
      switch (condition) {
        case ZERO:
          andi(rd, deferred_left_, 1);
          xori(rd, rd, 1);
          break;
        case NOT_ZERO:
          andi(rd, deferred_left_, 1);
          break;
        default:
          UNREACHABLE();
      }
    } else if (Supports(RV_Zbs) && Utils::IsPowerOfTwo(uimm)) {
      switch (condition) {
        case ZERO:
          bexti(rd, deferred_left_, Utils::ShiftForPowerOfTwo(uimm));
          xori(rd, rd, 1);
          break;
        case NOT_ZERO:
          bexti(rd, deferred_left_, Utils::ShiftForPowerOfTwo(uimm));
          break;
        default:
          UNREACHABLE();
      }
    } else {
      AndImmediate(rd, deferred_left_, deferred_imm_);
      switch (condition) {
        case ZERO:
          seqz(rd, rd);
          break;
        case NOT_ZERO:
          snez(rd, rd);
          break;
        default:
          UNREACHABLE();
      }
    }
  } else if (deferred_compare_ == kTestReg) {
    and_(rd, deferred_left_, deferred_reg_);
    switch (condition) {
      case ZERO:
        seqz(rd, rd);
        break;
      case NOT_ZERO:
        snez(rd, rd);
        break;
      default:
        UNREACHABLE();
    }
  } else {
    UNREACHABLE();
  }

  deferred_compare_ = kNone;  // Consumed.
}

void Assembler::BranchIfZero(Register rn, Label* label, JumpDistance distance) {
  beqz(rn, label, distance);
}

void Assembler::BranchIfBit(Register rn,
                            intptr_t bit_number,
                            Condition condition,
                            Label* label,
                            JumpDistance distance) {
  ASSERT(rn != TMP2);
  andi(TMP2, rn, 1 << bit_number);
  if (condition == ZERO) {
    beqz(TMP2, label, distance);
  } else if (condition == NOT_ZERO) {
    bnez(TMP2, label, distance);
  } else {
    UNREACHABLE();
  }
}

void Assembler::BranchIfNotSmi(Register reg,
                               Label* label,
                               JumpDistance distance) {
  ASSERT(reg != TMP2);
  andi(TMP2, reg, kSmiTagMask);
  bnez(TMP2, label, distance);
}
void Assembler::BranchIfSmi(Register reg, Label* label, JumpDistance distance) {
  ASSERT(reg != TMP2);
  andi(TMP2, reg, kSmiTagMask);
  beqz(TMP2, label, distance);
}

void Assembler::ArithmeticShiftRightImmediate(Register reg, intptr_t shift) {
  srai(reg, reg, shift);
}

void Assembler::CompareWords(Register reg1,
                             Register reg2,
                             intptr_t offset,
                             Register count,
                             Register temp,
                             Label* equals) {
  Label loop;
  Bind(&loop);
  BranchIfZero(count, equals, Assembler::kNearJump);
  AddImmediate(count, -1);
  lx(temp, FieldAddress(reg1, offset));
  lx(TMP, FieldAddress(reg2, offset));
  addi(reg1, reg1, target::kWordSize);
  addi(reg2, reg2, target::kWordSize);
  beq(temp, TMP, &loop, Assembler::kNearJump);
}

void Assembler::Jump(const Code& target,
                     Register pp,
                     ObjectPoolBuilderEntry::Patchability patchable) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), patchable);
  LoadWordFromPoolIndex(CODE_REG, index, pp);
  Jump(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

void Assembler::JumpAndLink(
    const Code& target,
    ObjectPoolBuilderEntry::Patchability patchable,
    CodeEntryKind entry_kind,
    ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior) {
  const intptr_t index = object_pool_builder().FindObject(
      ToObject(target), patchable, snapshot_behavior);
  LoadWordFromPoolIndex(CODE_REG, index);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::JumpAndLinkWithEquivalence(const Code& target,
                                           const Object& equivalence,
                                           CodeEntryKind entry_kind) {
  const intptr_t index =
      object_pool_builder().FindObject(ToObject(target), equivalence);
  LoadWordFromPoolIndex(CODE_REG, index);
  Call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::Call(Address target) {
  lx(RA, target);
  jalr(RA);
}

void Assembler::Call(Register target) {
  jalr(target);
}

void Assembler::AddShifted(Register dest,
                           Register base,
                           Register index,
                           intx_t shift) {
  if (shift == 0) {
    add(dest, index, base);
  } else if (Supports(RV_Zba) && (shift == 1)) {
    sh1add(dest, index, base);
  } else if (Supports(RV_Zba) && (shift == 2)) {
    sh2add(dest, index, base);
  } else if (Supports(RV_Zba) && (shift == 3)) {
    sh3add(dest, index, base);
  } else if (shift < 0) {
    if (base != dest) {
      srai(dest, index, -shift);
      add(dest, dest, base);
    } else {
      srai(TMP2, index, -shift);
      add(dest, TMP2, base);
    }
  } else {
    if (base != dest) {
      slli(dest, index, shift);
      add(dest, dest, base);
    } else {
      slli(TMP2, index, shift);
      add(dest, TMP2, base);
    }
  }
}

void Assembler::AddImmediate(Register rd,
                             Register rs1,
                             intx_t imm,
                             OperandSize sz) {
  if ((imm == 0) && (rd == rs1)) {
    return;
  }
  if (IsITypeImm(imm)) {
    addi(rd, rs1, imm);
  } else {
    ASSERT(rs1 != TMP2);
    LoadImmediate(TMP2, imm);
    add(rd, rs1, TMP2);
  }
}

void Assembler::MulImmediate(Register rd,
                             Register rs1,
                             intx_t imm,
                             OperandSize sz) {
  if (Utils::IsPowerOfTwo(imm)) {
    const intx_t shift = Utils::ShiftForPowerOfTwo(imm);
#if XLEN >= 64
    ASSERT(sz == kFourBytes || sz == kEightBytes);
    if (sz == kFourBytes) {
      slliw(rd, rs1, shift);
    } else {
      slli(rd, rs1, shift);
    }
#else
    ASSERT(sz == kFourBytes);
    slli(rd, rs1, shift);
#endif
  } else {
    LoadImmediate(TMP, imm);
#if XLEN >= 64
    ASSERT(sz == kFourBytes || sz == kEightBytes);
    if (sz == kFourBytes) {
      mulw(rd, rs1, TMP);
    } else {
      mul(rd, rs1, TMP);
    }
#else
    ASSERT(sz == kFourBytes);
    mul(rd, rs1, TMP);
#endif
  }
}

void Assembler::AndImmediate(Register rd,
                             Register rs1,
                             intx_t imm,
                             OperandSize sz) {
  uintx_t uimm = imm;
  if (imm == -1) {
    MoveRegister(rd, rs1);
  } else if (IsITypeImm(imm)) {
    andi(rd, rs1, imm);
  } else if (Supports(RV_Zbs) && Utils::IsPowerOfTwo(~uimm)) {
    bclri(rd, rs1, Utils::ShiftForPowerOfTwo(~uimm));
  } else if (Utils::IsPowerOfTwo(uimm + 1)) {
    intptr_t shift = Utils::ShiftForPowerOfTwo(uimm + 1);
    if (Supports(RV_Zbb) && (shift == 16)) {
      zexth(rd, rs1);
    } else {
      slli(rd, rs1, XLEN - shift);
      srli(rd, rd, XLEN - shift);
    }
  } else {
    ASSERT(rs1 != TMP2);
    LoadImmediate(TMP2, imm);
    and_(rd, rs1, TMP2);
  }
}
void Assembler::OrImmediate(Register rd,
                            Register rs1,
                            intx_t imm,
                            OperandSize sz) {
  uintx_t uimm = imm;
  if (imm == 0) {
    MoveRegister(rd, rs1);
  } else if (IsITypeImm(imm)) {
    ori(rd, rs1, imm);
  } else if (Supports(RV_Zbs) && Utils::IsPowerOfTwo(uimm)) {
    bseti(rd, rs1, Utils::ShiftForPowerOfTwo(uimm));
  } else {
    ASSERT(rs1 != TMP2);
    LoadImmediate(TMP2, imm);
    or_(rd, rs1, TMP2);
  }
}
void Assembler::XorImmediate(Register rd,
                             Register rs1,
                             intx_t imm,
                             OperandSize sz) {
  uintx_t uimm = imm;
  if (imm == 0) {
    MoveRegister(rd, rs1);
  } else if (IsITypeImm(imm)) {
    xori(rd, rs1, imm);
  } else if (Supports(RV_Zbs) && Utils::IsPowerOfTwo(uimm)) {
    binvi(rd, rs1, Utils::ShiftForPowerOfTwo(uimm));
  } else {
    ASSERT(rs1 != TMP2);
    LoadImmediate(TMP2, imm);
    xor_(rd, rs1, TMP2);
  }
}

void Assembler::TestImmediate(Register rn, intx_t imm, OperandSize sz) {
  ASSERT(deferred_compare_ == kNone);
  deferred_compare_ = kTestImm;
  deferred_left_ = rn;
  deferred_imm_ = imm;
}
void Assembler::CompareImmediate(Register rn, intx_t imm, OperandSize sz) {
  ASSERT(deferred_compare_ == kNone);
  deferred_compare_ = kCompareImm;
  deferred_left_ = rn;
  deferred_imm_ = imm;
}

Address Assembler::PrepareLargeOffset(Register base, int32_t offset) {
  ASSERT(base != TMP2);
  if (IsITypeImm(offset)) {
    return Address(base, offset);
  }
  intx_t lo = ImmLo(offset);
  intx_t hi = ImmHi(offset);
  ASSERT(hi != 0);
  lui(TMP2, hi);
  add(TMP2, TMP2, base);
  return Address(TMP2, lo);
}

void Assembler::LoadFromOffset(Register dest,
                               const Address& address,
                               OperandSize sz) {
  Address addr = PrepareLargeOffset(address.base(), address.offset());
  switch (sz) {
#if XLEN == 64
    case kEightBytes:
      return ld(dest, addr);
    case kUnsignedFourBytes:
      return lwu(dest, addr);
#elif XLEN == 32
    case kUnsignedFourBytes:
      return lw(dest, addr);
#endif
    case kFourBytes:
      return lw(dest, addr);
    case kUnsignedTwoBytes:
      return lhu(dest, addr);
    case kTwoBytes:
      return lh(dest, addr);
    case kUnsignedByte:
      return lbu(dest, addr);
    case kByte:
      return lb(dest, addr);
    default:
      UNREACHABLE();
  }
}
// For loading indexed payloads out of tagged objects like Arrays. If the
// payload objects are word-sized, use TIMES_HALF_WORD_SIZE if the contents of
// [index] is a Smi, otherwise TIMES_WORD_SIZE if unboxed.
void Assembler::LoadIndexedPayload(Register dest,
                                   Register base,
                                   int32_t payload_offset,
                                   Register index,
                                   ScaleFactor scale,
                                   OperandSize sz) {
  AddShifted(TMP, base, index, scale);
  LoadFromOffset(dest, TMP, payload_offset - kHeapObjectTag, sz);
}
void Assembler::LoadIndexedCompressed(Register dest,
                                      Register base,
                                      int32_t offset,
                                      Register index) {
  LoadIndexedPayload(dest, base, offset, index, TIMES_WORD_SIZE, kObjectBytes);
}

void Assembler::LoadSFromOffset(FRegister dest, Register base, int32_t offset) {
  flw(dest, PrepareLargeOffset(base, offset));
}

void Assembler::LoadDFromOffset(FRegister dest, Register base, int32_t offset) {
  fld(dest, PrepareLargeOffset(base, offset));
}

void Assembler::LoadFromStack(Register dst, intptr_t depth) {
  LoadFromOffset(dst, SPREG, target::kWordSize * depth);
}
void Assembler::StoreToStack(Register src, intptr_t depth) {
  StoreToOffset(src, SPREG, target::kWordSize * depth);
}
void Assembler::CompareToStack(Register src, intptr_t depth) {
  CompareWithMemoryValue(src, Address(SPREG, target::kWordSize * depth));
}

void Assembler::StoreToOffset(Register src,
                              const Address& address,
                              OperandSize sz) {
  Address addr = PrepareLargeOffset(address.base(), address.offset());
  switch (sz) {
#if XLEN == 64
    case kEightBytes:
      return sd(src, addr);
#endif
    case kUnsignedFourBytes:
    case kFourBytes:
      return sw(src, addr);
    case kUnsignedTwoBytes:
    case kTwoBytes:
      return sh(src, addr);
    case kUnsignedByte:
    case kByte:
      return sb(src, addr);
    default:
      UNREACHABLE();
  }
}

void Assembler::StoreSToOffset(FRegister src, Register base, int32_t offset) {
  fsw(src, PrepareLargeOffset(base, offset));
}

void Assembler::StoreDToOffset(FRegister src, Register base, int32_t offset) {
  fsd(src, PrepareLargeOffset(base, offset));
}

// Store into a heap object and apply the generational and incremental write
// barriers. All stores into heap objects must pass through this function or,
// if the value can be proven either Smi or old-and-premarked, its NoBarrier
// variants.
// Preserves object and value registers.
void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_value_be_smi,
                                MemoryOrder memory_order) {
  // stlr does not feature an address operand.
  ASSERT(memory_order == kRelaxedNonAtomic);
  StoreToOffset(value, dest);
  StoreBarrier(object, value, can_value_be_smi);
}
void Assembler::StoreCompressedIntoObject(Register object,
                                          const Address& dest,
                                          Register value,
                                          CanBeSmi can_value_be_smi,
                                          MemoryOrder memory_order) {
  StoreIntoObject(object, dest, value, can_value_be_smi, memory_order);
}
void Assembler::StoreBarrier(Register object,
                             Register value,
                             CanBeSmi can_value_be_smi) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);
  ASSERT(object != RA);
  ASSERT(value != RA);
  ASSERT(object != TMP);
  ASSERT(object != TMP2);
  ASSERT(value != TMP);
  ASSERT(value != TMP2);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // See RestorePinnedRegisters for why this can be `ble`.
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_value_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done, kNearJump);
  }
  lbu(TMP, FieldAddress(object, target::Object::tags_offset()));
  lbu(TMP2, FieldAddress(value, target::Object::tags_offset()));
  srli(TMP, TMP, target::UntaggedObject::kBarrierOverlapShift);
  and_(TMP, TMP, TMP2);
  ble(TMP, WRITE_BARRIER_STATE, &done, kNearJump);

  Register objectForCall = object;
  if (value != kWriteBarrierValueReg) {
    // Unlikely. Only non-graph intrinsics.
    // TODO(rmacnak): Shuffle registers in intrinsics.
    if (object != kWriteBarrierValueReg) {
      PushRegister(kWriteBarrierValueReg);
    } else {
      COMPILE_ASSERT(S3 != kWriteBarrierValueReg);
      COMPILE_ASSERT(S4 != kWriteBarrierValueReg);
      objectForCall = (value == S3) ? S4 : S3;
      PushRegisterPair(kWriteBarrierValueReg, objectForCall);
      mv(objectForCall, object);
    }
    mv(kWriteBarrierValueReg, value);
  }

  // Note this uses TMP as the link register, so RA remains preserved.
  generate_invoke_write_barrier_wrapper_(objectForCall);

  if (value != kWriteBarrierValueReg) {
    if (object != kWriteBarrierValueReg) {
      PopRegister(kWriteBarrierValueReg);
    } else {
      PopRegisterPair(kWriteBarrierValueReg, objectForCall);
    }
  }
  Bind(&done);
}
void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_value_be_smi) {
  sx(value, Address(slot, 0));
  StoreIntoArrayBarrier(object, slot, value, can_value_be_smi);
}
void Assembler::StoreCompressedIntoArray(Register object,
                                         Register slot,
                                         Register value,
                                         CanBeSmi can_value_be_smi) {
  StoreIntoArray(object, slot, value, can_value_be_smi);
}
void Assembler::StoreIntoArrayBarrier(Register object,
                                      Register slot,
                                      Register value,
                                      CanBeSmi can_value_be_smi) {
  // TODO(riscv): Use RA2 to avoid spilling RA inline?
  const bool spill_lr = true;
  ASSERT(object != TMP);
  ASSERT(object != TMP2);
  ASSERT(value != TMP);
  ASSERT(value != TMP2);
  ASSERT(slot != TMP);
  ASSERT(slot != TMP2);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // See RestorePinnedRegisters for why this can be `ble`.
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_value_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done, kNearJump);
  }
  lbu(TMP, FieldAddress(object, target::Object::tags_offset()));
  lbu(TMP2, FieldAddress(value, target::Object::tags_offset()));
  srli(TMP, TMP, target::UntaggedObject::kBarrierOverlapShift);
  and_(TMP, TMP, TMP2);
  ble(TMP, WRITE_BARRIER_STATE, &done, kNearJump);
  if (spill_lr) {
    PushRegister(RA);
  }
  if ((object != kWriteBarrierObjectReg) || (value != kWriteBarrierValueReg) ||
      (slot != kWriteBarrierSlotReg)) {
    // Spill and shuffle unimplemented. Currently StoreIntoArray is only used
    // from StoreIndexInstr, which gets these exact registers from the register
    // allocator.
    UNIMPLEMENTED();
  }
  generate_invoke_array_write_barrier_();
  if (spill_lr) {
    PopRegister(RA);
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectOffset(Register object,
                                      int32_t offset,
                                      Register value,
                                      CanBeSmi can_value_be_smi,
                                      MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreRelease(value, object, offset - kHeapObjectTag);
  } else {
    StoreToOffset(value, object, offset - kHeapObjectTag);
  }
  StoreBarrier(object, value, can_value_be_smi);
}
void Assembler::StoreCompressedIntoObjectOffset(Register object,
                                                int32_t offset,
                                                Register value,
                                                CanBeSmi can_value_be_smi,
                                                MemoryOrder memory_order) {
  StoreIntoObjectOffset(object, offset, value, can_value_be_smi, memory_order);
}
void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value,
                                         MemoryOrder memory_order) {
  ASSERT(memory_order == kRelaxedNonAtomic);
  StoreToOffset(value, dest);
#if defined(DEBUG)
  // We can't assert the incremental barrier is not needed here, only the
  // generational barrier. We sometimes omit the write barrier when 'value' is
  // a constant, but we don't eagerly mark 'value' and instead assume it is also
  // reachable via a constant pool, so it doesn't matter if it is not traced via
  // 'object'.
  Label done;
  BranchIfSmi(value, &done, kNearJump);
  lbu(TMP2, FieldAddress(value, target::Object::tags_offset()));
  andi(TMP2, TMP2, 1 << target::UntaggedObject::kNewBit);
  beqz(TMP2, &done, kNearJump);
  lbu(TMP2, FieldAddress(object, target::Object::tags_offset()));
  andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotRememberedBit);
  beqz(TMP2, &done, kNearJump);
  Stop("Write barrier is required");
  Bind(&done);
#endif
}
void Assembler::StoreCompressedIntoObjectNoBarrier(Register object,
                                                   const Address& dest,
                                                   Register value,
                                                   MemoryOrder memory_order) {
  StoreIntoObjectNoBarrier(object, dest, value, memory_order);
}
void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               Register value,
                                               MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreRelease(value, object, offset - kHeapObjectTag);
  } else {
    StoreToOffset(value, object, offset - kHeapObjectTag);
  }
#if defined(DEBUG)
  // We can't assert the incremental barrier is not needed here, only the
  // generational barrier. We sometimes omit the write barrier when 'value' is
  // a constant, but we don't eagerly mark 'value' and instead assume it is also
  // reachable via a constant pool, so it doesn't matter if it is not traced via
  // 'object'.
  Label done;
  BranchIfSmi(value, &done, kNearJump);
  lbu(TMP2, FieldAddress(value, target::Object::tags_offset()));
  andi(TMP2, TMP2, 1 << target::UntaggedObject::kNewBit);
  beqz(TMP2, &done, kNearJump);
  lbu(TMP2, FieldAddress(object, target::Object::tags_offset()));
  andi(TMP2, TMP2, 1 << target::UntaggedObject::kOldAndNotRememberedBit);
  beqz(TMP2, &done, kNearJump);
  Stop("Write barrier is required");
  Bind(&done);
#endif
}
void Assembler::StoreCompressedIntoObjectOffsetNoBarrier(
    Register object,
    int32_t offset,
    Register value,
    MemoryOrder memory_order) {
  StoreIntoObjectOffsetNoBarrier(object, offset, value, memory_order);
}
void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value,
                                         MemoryOrder memory_order) {
  ASSERT(IsOriginalObject(value));
  DEBUG_ASSERT(IsNotTemporaryScopedHandle(value));
  // No store buffer update.
  Register value_reg;
  if (IsSameObject(compiler::NullObject(), value)) {
    value_reg = NULL_REG;
  } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
    value_reg = ZR;
  } else {
    LoadObject(TMP2, value);
    value_reg = TMP2;
  }
  if (memory_order == kRelease) {
    fence(HartEffects::kMemory, HartEffects::kWrite);
  }
  sx(value_reg, dest);
}
void Assembler::StoreCompressedIntoObjectNoBarrier(Register object,
                                                   const Address& dest,
                                                   const Object& value,
                                                   MemoryOrder memory_order) {
  UNIMPLEMENTED();
}
void Assembler::StoreIntoObjectOffsetNoBarrier(Register object,
                                               int32_t offset,
                                               const Object& value,
                                               MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    Register value_reg = TMP2;
    if (IsSameObject(compiler::NullObject(), value)) {
      value_reg = NULL_REG;
    } else if (target::IsSmi(value) && (target::ToRawSmi(value) == 0)) {
      value_reg = ZR;
    } else {
      LoadObject(value_reg, value);
    }
    StoreIntoObjectOffsetNoBarrier(object, offset, value_reg, memory_order);
  } else if (IsITypeImm(offset - kHeapObjectTag)) {
    StoreIntoObjectNoBarrier(object, FieldAddress(object, offset), value);
  } else {
    AddImmediate(TMP, object, offset - kHeapObjectTag);
    StoreIntoObjectNoBarrier(object, Address(TMP), value);
  }
}
void Assembler::StoreCompressedIntoObjectOffsetNoBarrier(
    Register object,
    int32_t offset,
    const Object& value,
    MemoryOrder memory_order) {
  UNIMPLEMENTED();
}

// Stores a non-tagged value into a heap object.
void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  sx(value, dest);
}

// Object pool, loading from pool, etc.
void Assembler::LoadPoolPointer(Register pp) {
  CheckCodePointer();
  lx(pp, FieldAddress(CODE_REG, target::Code::object_pool_offset()));

  // When in the PP register, the pool pointer is untagged. When we
  // push it on the stack with TagAndPushPP it is tagged again. PopAndUntagPP
  // then untags when restoring from the stack. This will make loading from the
  // object pool only one instruction for the first 4096 entries. Otherwise,
  // because the offset wouldn't be aligned, it would be only one instruction
  // for the first 64 entries.
  subi(pp, pp, kHeapObjectTag);
  set_constant_pool_allowed(pp == PP);
}

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(IsOriginalObject(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
  ASSERT(IsInOldSpace(object));
  return true;
}
void Assembler::LoadNativeEntry(
    Register dst,
    const ExternalLabel* label,
    ObjectPoolBuilderEntry::Patchability patchable) {
  const intptr_t index =
      object_pool_builder().FindNativeFunction(label, patchable);
  LoadWordFromPoolIndex(dst, index);
}
void Assembler::LoadIsolate(Register dst) {
  lx(dst, Address(THR, target::Thread::isolate_offset()));
}
void Assembler::LoadIsolateGroup(Register dst) {
  lx(dst, Address(THR, target::Thread::isolate_group_offset()));
}

void Assembler::LoadImmediate(Register reg, intx_t imm) {
#if XLEN > 32
  if (!Utils::IsInt(32, imm)) {
    int shift = Utils::CountTrailingZeros64(imm);
    if (IsITypeImm(imm >> shift)) {
      li(reg, imm >> shift);
      slli(reg, reg, shift);
      return;
    }
    if ((shift >= 12) && IsUTypeImm(imm >> (shift - 12))) {
      lui(reg, imm >> (shift - 12));
      slli(reg, reg, shift - 12);
      return;
    }

    if (constant_pool_allowed()) {
      intptr_t index = object_pool_builder().FindImmediate(imm);
      LoadWordFromPoolIndex(reg, index);
      return;
    }

    intx_t lo = ImmLo(imm);
    intx_t hi = imm - lo;
    shift = Utils::CountTrailingZeros64(hi);
    ASSERT(shift != 0);
    LoadImmediate(reg, hi >> shift);
    slli(reg, reg, shift);
    if (lo != 0) {
      addi(reg, reg, lo);
    }
    return;
  }
#endif

  intx_t lo = ImmLo(imm);
  intx_t hi = ImmHi(imm);
  if (hi == 0) {
    addi(reg, ZR, lo);
  } else {
    lui(reg, hi);
    if (lo != 0) {
#if XLEN == 32
      addi(reg, reg, lo);
#else
      addiw(reg, reg, lo);
#endif
    }
  }
}

void Assembler::LoadSImmediate(FRegister reg, float imms) {
  int32_t imm = bit_cast<int32_t, float>(imms);
  if (imm == 0) {
    fmvwx(reg, ZR);  // bit_cast uint32_t -> float
  } else {
    ASSERT(constant_pool_allowed());
    intptr_t index = object_pool_builder().FindImmediate(imm);
    intptr_t offset = target::ObjectPool::element_offset(index);
    LoadSFromOffset(reg, PP, offset);
  }
}

void Assembler::LoadDImmediate(FRegister reg, double immd) {
  int64_t imm = bit_cast<int64_t, double>(immd);
  if (imm == 0) {
#if XLEN >= 64
    fmvdx(reg, ZR);  // bit_cast uint64_t -> double
#else
    fcvtdwu(reg, ZR);  // static_cast uint32_t -> double
#endif
  } else {
    ASSERT(constant_pool_allowed());
    intptr_t index = object_pool_builder().FindImmediate64(imm);
    intptr_t offset = target::ObjectPool::element_offset(index);
    LoadDFromOffset(reg, PP, offset);
  }
}

void Assembler::LoadQImmediate(FRegister reg, simd128_value_t immq) {
  UNREACHABLE();  // F registers cannot represent SIMD128.
}

// Load word from pool from the given offset using encoding that
// InstructionPattern::DecodeLoadWordFromPool can decode.
//
// Note: the function never clobbers TMP, TMP2 scratch registers.
void Assembler::LoadWordFromPoolIndex(Register dst,
                                      intptr_t index,
                                      Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  ASSERT(dst != pp);
  const uint32_t offset = target::ObjectPool::element_offset(index);
  // PP is untagged.
  intx_t lo = ImmLo(offset);
  intx_t hi = ImmHi(offset);
  if (hi == 0) {
    lx(dst, Address(pp, lo));
  } else {
    lui(dst, hi);
    add(dst, dst, pp);
    lx(dst, Address(dst, lo));
  }
}

void Assembler::CompareObject(Register reg, const Object& object) {
  ASSERT(IsOriginalObject(object));
  if (IsSameObject(compiler::NullObject(), object)) {
    CompareObjectRegisters(reg, NULL_REG);
  } else if (target::IsSmi(object)) {
    CompareImmediate(reg, target::ToRawSmi(object), kObjectBytes);
  } else {
    LoadObject(TMP, object);
    CompareObjectRegisters(reg, TMP);
  }
}

void Assembler::ExtractClassIdFromTags(Register result, Register tags) {
  ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
  ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
#if XLEN == 64
  srliw(result, tags, target::UntaggedObject::kClassIdTagPos);
#else
  srli(result, tags, target::UntaggedObject::kClassIdTagPos);
#endif
}

void Assembler::ExtractInstanceSizeFromTags(Register result, Register tags) {
  ASSERT(target::UntaggedObject::kSizeTagPos == 8);
  ASSERT(target::UntaggedObject::kSizeTagSize == 4);
  srli(result, tags, target::UntaggedObject::kSizeTagPos);
  andi(result, result, (1 << target::UntaggedObject::kSizeTagSize) - 1);
  slli(result, result, target::ObjectAlignment::kObjectAlignmentLog2);
}

void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
  ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
#if XLEN == 64
  lwu(result, FieldAddress(object, target::Object::tags_offset()));
#else
  lw(result, FieldAddress(object, target::Object::tags_offset()));
#endif
  srli(result, result, target::UntaggedObject::kClassIdTagPos);
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::IsolateGroup::cached_class_table_table_offset();

  LoadIsolateGroup(result);
  LoadFromOffset(result, result, table_offset);
  AddShifted(result, result, class_id, target::kWordSizeLog2);
  lx(result, Address(result, 0));
}
void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  ASSERT(scratch != kNoRegister);
  LoadClassId(scratch, object);
  CompareImmediate(scratch, class_id);
}
// Note: input and output registers must be different.
void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  ASSERT(result != object);
  ASSERT(result != TMP2);
  ASSERT(object != TMP2);
  li(result, kSmiCid);
  Label done;
  BranchIfSmi(object, &done, kNearJump);
  LoadClassId(result, object);
  Bind(&done);
}
void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  LoadClassIdMayBeSmi(result, object);
  SmiTag(result);
}
void Assembler::EnsureHasClassIdInDEBUG(intptr_t cid,
                                        Register src,
                                        Register scratch,
                                        bool can_be_null) {
#if defined(DEBUG)
  Comment("Check that object in register has cid %" Pd "", cid);
  Label matches;
  LoadClassIdMayBeSmi(scratch, src);
  CompareImmediate(scratch, cid);
  BranchIf(EQUAL, &matches, Assembler::kNearJump);
  if (can_be_null) {
    CompareImmediate(scratch, kNullCid);
    BranchIf(EQUAL, &matches, Assembler::kNearJump);
  }
  trap();
  Bind(&matches);
#endif
}

void Assembler::EnterFrame(intptr_t frame_size) {
  // N.B. The ordering here is important. We must never write beyond SP or
  // it can be clobbered by a signal handler.
  subi(SP, SP, frame_size + 2 * target::kWordSize);
  sx(RA, Address(SP, frame_size + 1 * target::kWordSize));
  sx(FP, Address(SP, frame_size + 0 * target::kWordSize));
  addi(FP, SP, frame_size + 2 * target::kWordSize);
}
void Assembler::LeaveFrame() {
  // N.B. The ordering here is important. We must never read beyond SP or
  // it may have already been clobbered by a signal handler.
  subi(SP, FP, 2 * target::kWordSize);
  lx(FP, Address(SP, 0 * target::kWordSize));
  lx(RA, Address(SP, 1 * target::kWordSize));
  addi(SP, SP, 2 * target::kWordSize);
}

void Assembler::TransitionGeneratedToNative(Register destination,
                                            Register new_exit_frame,
                                            Register new_exit_through_ffi,
                                            bool enter_safepoint) {
  // Save exit frame information to enable stack walking.
  sx(new_exit_frame,
     Address(THR, target::Thread::top_exit_frame_info_offset()));

  sx(new_exit_through_ffi,
     Address(THR, target::Thread::exit_through_ffi_offset()));
  Register tmp = new_exit_through_ffi;

  // Mark that the thread is executing native code.
  sx(destination, Address(THR, target::Thread::vm_tag_offset()));
  li(tmp, target::Thread::native_execution_state());
  sx(tmp, Address(THR, target::Thread::execution_state_offset()));

  if (enter_safepoint) {
    EnterFullSafepoint(tmp);
  }
}

void Assembler::TransitionNativeToGenerated(Register state,
                                            bool exit_safepoint,
                                            bool ignore_unwind_in_progress) {
  if (exit_safepoint) {
    ExitFullSafepoint(state, ignore_unwind_in_progress);
  } else {
    // flag only makes sense if we are leaving safepoint
    ASSERT(!ignore_unwind_in_progress);
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    ASSERT(target::Thread::full_safepoint_state_acquired() != 0);
    li(state, target::Thread::full_safepoint_state_acquired());
    lx(RA, Address(THR, target::Thread::safepoint_state_offset()));
    and_(RA, RA, state);
    Label ok;
    beqz(RA, &ok, Assembler::kNearJump);
    Breakpoint();
    Bind(&ok);
#endif
  }

  // Mark that the thread is executing Dart code.
  li(state, target::Thread::vm_tag_dart_id());
  sx(state, Address(THR, target::Thread::vm_tag_offset()));
  li(state, target::Thread::generated_execution_state());
  sx(state, Address(THR, target::Thread::execution_state_offset()));

  // Reset exit frame information in Isolate's mutator thread structure.
  sx(ZR, Address(THR, target::Thread::top_exit_frame_info_offset()));
  sx(ZR, Address(THR, target::Thread::exit_through_ffi_offset()));
}

void Assembler::EnterFullSafepoint(Register state) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.
  // For TSAN, we always go to the runtime so TSAN is aware of the release
  // semantics of entering the safepoint.

  Register addr = RA;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path || kTargetUsesThreadSanitizer) {
    j(&slow_path, Assembler::kNearJump);
  }

  addi(addr, THR, target::Thread::safepoint_state_offset());
  Bind(&retry);
  lr(state, Address(addr, 0));
  subi(state, state, target::Thread::full_safepoint_state_unacquired());
  bnez(state, &slow_path, Assembler::kNearJump);

  li(state, target::Thread::full_safepoint_state_acquired());
  sc(state, state, Address(addr, 0));
  beqz(state, &done, Assembler::kNearJump);  // 0 means sc was successful.

  if (!FLAG_use_slow_path && !kTargetUsesThreadSanitizer) {
    j(&retry, Assembler::kNearJump);
  }

  Bind(&slow_path);
  lx(addr, Address(THR, target::Thread::enter_safepoint_stub_offset()));
  lx(addr, FieldAddress(addr, target::Code::entry_point_offset()));
  jalr(addr);

  Bind(&done);
}

void Assembler::ExitFullSafepoint(Register state,
                                  bool ignore_unwind_in_progress) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterFullSafepoint.
  // For TSAN, we always go to the runtime so TSAN is aware of the acquire
  // semantics of leaving the safepoint.
  Register addr = RA;
  ASSERT(addr != state);

  Label slow_path, done, retry;
  if (FLAG_use_slow_path || kTargetUsesThreadSanitizer) {
    j(&slow_path, Assembler::kNearJump);
  }

  addi(addr, THR, target::Thread::safepoint_state_offset());
  Bind(&retry);
  lr(state, Address(addr, 0));
  subi(state, state, target::Thread::full_safepoint_state_acquired());
  bnez(state, &slow_path, Assembler::kNearJump);

  li(state, target::Thread::full_safepoint_state_unacquired());
  sc(state, state, Address(addr, 0));
  beqz(state, &done, Assembler::kNearJump);  // 0 means sc was successful.

  if (!FLAG_use_slow_path && !kTargetUsesThreadSanitizer) {
    j(&retry, Assembler::kNearJump);
  }

  Bind(&slow_path);
  if (ignore_unwind_in_progress) {
    lx(addr,
       Address(THR,
               target::Thread::
                   exit_safepoint_ignore_unwind_in_progress_stub_offset()));
  } else {
    lx(addr, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  }
  lx(addr, FieldAddress(addr, target::Code::entry_point_offset()));
  jalr(addr);

  Bind(&done);
}

void Assembler::CheckFpSpDist(intptr_t fp_sp_dist) {
  ASSERT(fp_sp_dist <= 0);
#if defined(DEBUG)
  Label ok;
  Comment("CheckFpSpDist");
  sub(TMP, SP, FP);
  CompareImmediate(TMP, fp_sp_dist);
  BranchIf(EQ, &ok, compiler::Assembler::kNearJump);
  ebreak();
  Bind(&ok);
#endif
}

void Assembler::CheckCodePointer() {
#ifdef DEBUG
  if (!FLAG_check_code_pointer) {
    return;
  }
  Comment("CheckCodePointer");
  Label cid_ok, instructions_ok;
  CompareClassId(CODE_REG, kCodeCid, TMP);
  BranchIf(EQ, &cid_ok, kNearJump);
  ebreak();
  Bind(&cid_ok);

  const intptr_t entry_offset =
      CodeSize() + target::Instructions::HeaderSize() - kHeapObjectTag;
  intx_t imm = -entry_offset;
  intx_t lo = ImmLo(imm);
  intx_t hi = ImmHi(imm);
  auipc(TMP, hi);
  addi(TMP, TMP, lo);
  lx(TMP2, FieldAddress(CODE_REG, target::Code::instructions_offset()));
  beq(TMP, TMP2, &instructions_ok, kNearJump);
  ebreak();
  Bind(&instructions_ok);
#endif
}

void Assembler::RestoreCodePointer() {
  lx(CODE_REG,
     Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
  CheckCodePointer();
}

void Assembler::RestorePoolPointer() {
  if (FLAG_precompiled_mode) {
    lx(PP, Address(THR, target::Thread::global_object_pool_offset()));
  } else {
    lx(PP, Address(FP, target::frame_layout.code_from_fp * target::kWordSize));
    lx(PP, FieldAddress(PP, target::Code::object_pool_offset()));
  }
  subi(PP, PP, kHeapObjectTag);  // Pool in PP is untagged!
}

void Assembler::RestorePinnedRegisters() {
  lx(WRITE_BARRIER_STATE,
     Address(THR, target::Thread::write_barrier_mask_offset()));
  lx(NULL_REG, Address(THR, target::Thread::object_null_offset()));

  // Our write barrier usually uses mask-and-test,
  //   01b6f6b3  and tmp, tmp, mask
  //       c689  beqz tmp, +10
  // but on RISC-V compare-and-branch is shorter,
  //   00ddd663  ble tmp, wbs, +12
  //
  // TMP bit 4+ = 0
  // TMP bit 3  = object is old-and-not-remembered AND value is new (genr bit)
  // TMP bit 2  = object is old AND value is old-and-not-marked     (incr bit)
  // TMP bit 1  = garbage
  // TMP bit 0  = garbage
  //
  // Thread::wbm | WRITE_BARRIER_STATE | TMP/combined headers | result
  // generational only
  // 0b1000        0b0111                0b11xx                 impossible
  //                                     0b10xx                 call stub
  //                                     0b01xx                 skip
  //                                     0b00xx                 skip
  // generational and incremental
  // 0b1100        0b0011                0b11xx                 impossible
  //                                     0b10xx                 call stub
  //                                     0b01xx                 call stub
  //                                     0b00xx                 skip
  xori(WRITE_BARRIER_STATE, WRITE_BARRIER_STATE,
       (target::UntaggedObject::kGenerationalBarrierMask << 1) - 1);

  // Generational bit must be higher than incremental bit, with no other bits
  // between.
  ASSERT(target::UntaggedObject::kGenerationalBarrierMask ==
         (target::UntaggedObject::kIncrementalBarrierMask << 1));
  // Other header bits must be lower.
  ASSERT(target::UntaggedObject::kIncrementalBarrierMask >
         target::UntaggedObject::kCanonicalBit);
  ASSERT(target::UntaggedObject::kIncrementalBarrierMask >
         target::UntaggedObject::kCardRememberedBit);
}

void Assembler::SetupGlobalPoolAndDispatchTable() {
  ASSERT(FLAG_precompiled_mode);
  lx(PP, Address(THR, target::Thread::global_object_pool_offset()));
  subi(PP, PP, kHeapObjectTag);  // Pool in PP is untagged!
  lx(DISPATCH_TABLE_REG,
     Address(THR, target::Thread::dispatch_table_array_offset()));
}

void Assembler::EnterDartFrame(intptr_t frame_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());

  if (!IsITypeImm(frame_size + 4 * target::kWordSize)) {
    EnterDartFrame(0, new_pp);
    AddImmediate(SP, SP, -frame_size);
    return;
  }

  // N.B. The ordering here is important. We must never write beyond SP or
  // it can be clobbered by a signal handler.
  if (FLAG_precompiled_mode) {
    subi(SP, SP, frame_size + 2 * target::kWordSize);
    sx(RA, Address(SP, frame_size + 1 * target::kWordSize));
    sx(FP, Address(SP, frame_size + 0 * target::kWordSize));
    addi(FP, SP, frame_size + 2 * target::kWordSize);
  } else {
    subi(SP, SP, frame_size + 4 * target::kWordSize);
    sx(RA, Address(SP, frame_size + 3 * target::kWordSize));
    sx(FP, Address(SP, frame_size + 2 * target::kWordSize));
    sx(CODE_REG, Address(SP, frame_size + 1 * target::kWordSize));
    addi(PP, PP, kHeapObjectTag);
    sx(PP, Address(SP, frame_size + 0 * target::kWordSize));
    addi(FP, SP, frame_size + 4 * target::kWordSize);
    if (new_pp == kNoRegister) {
      LoadPoolPointer();
    } else {
      mv(PP, new_pp);
    }
  }
  set_constant_pool_allowed(true);
}

// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate. We must also set up the pool pointer for the function.
void Assembler::EnterOsrFrame(intptr_t extra_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());
  Comment("EnterOsrFrame");
  RestoreCodePointer();
  LoadPoolPointer();

  if (extra_size > 0) {
    AddImmediate(SP, -extra_size);
  }
}

void Assembler::LeaveDartFrame() {
  // N.B. The ordering here is important. We must never read beyond SP or
  // it may have already been clobbered by a signal handler.
  if (!FLAG_precompiled_mode) {
    lx(PP, Address(FP, target::frame_layout.saved_caller_pp_from_fp *
                           target::kWordSize));
    subi(PP, PP, kHeapObjectTag);
  }
  set_constant_pool_allowed(false);
  subi(SP, FP, 2 * target::kWordSize);
  lx(FP, Address(SP, 0 * target::kWordSize));
  lx(RA, Address(SP, 1 * target::kWordSize));
  addi(SP, SP, 2 * target::kWordSize);
}

void Assembler::LeaveDartFrame(intptr_t fp_sp_dist) {
  intptr_t pp_offset =
      target::frame_layout.saved_caller_pp_from_fp * target::kWordSize -
      fp_sp_dist;
  intptr_t fp_offset =
      target::frame_layout.saved_caller_fp_from_fp * target::kWordSize -
      fp_sp_dist;
  intptr_t ra_offset =
      target::frame_layout.saved_caller_pc_from_fp * target::kWordSize -
      fp_sp_dist;
  if (!IsITypeImm(pp_offset) || !IsITypeImm(fp_offset) ||
      !IsITypeImm(ra_offset)) {
    // Shorter to update SP twice than generate large immediates.
    LeaveDartFrame();
    return;
  }

  if (!FLAG_precompiled_mode) {
    lx(PP, Address(SP, pp_offset));
    subi(PP, PP, kHeapObjectTag);
  }
  set_constant_pool_allowed(false);
  lx(FP, Address(SP, fp_offset));
  lx(RA, Address(SP, ra_offset));
  addi(SP, SP, -fp_sp_dist);
}

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(!entry.is_leaf());
  // Argument count is not checked here, but in the runtime entry for a more
  // informative error message.
  lx(T5, compiler::Address(THR, entry.OffsetFromThread()));
  li(T4, argument_count);
  Call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

static const RegisterSet kRuntimeCallSavedRegisters(kDartVolatileCpuRegs,
                                                    kAbiVolatileFpuRegs);

#define __ assembler_->

LeafRuntimeScope::LeafRuntimeScope(Assembler* assembler,
                                   intptr_t frame_size,
                                   bool preserve_registers)
    : assembler_(assembler), preserve_registers_(preserve_registers) {
  // N.B. The ordering here is important. We must never write beyond SP or
  // it can be clobbered by a signal handler.
  __ subi(SP, SP, 4 * target::kWordSize);
  __ sx(RA, Address(SP, 3 * target::kWordSize));
  __ sx(FP, Address(SP, 2 * target::kWordSize));
  __ sx(CODE_REG, Address(SP, 1 * target::kWordSize));
  __ sx(PP, Address(SP, 0 * target::kWordSize));
  __ addi(FP, SP, 4 * target::kWordSize);

  if (preserve_registers) {
    __ PushRegisters(kRuntimeCallSavedRegisters);
  } else {
    // Or no reason to save above.
    COMPILE_ASSERT(!IsAbiPreservedRegister(CODE_REG));
    COMPILE_ASSERT(!IsAbiPreservedRegister(PP));
    // Or would need to save above.
    COMPILE_ASSERT(IsCalleeSavedRegister(THR));
    COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
    COMPILE_ASSERT(IsCalleeSavedRegister(WRITE_BARRIER_STATE));
    COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));
  }

  __ ReserveAlignedFrameSpace(frame_size);
}

void LeafRuntimeScope::Call(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(argument_count == entry.argument_count());
  __ lx(TMP2, compiler::Address(THR, entry.OffsetFromThread()));
  __ sx(TMP2, compiler::Address(THR, target::Thread::vm_tag_offset()));
  __ jalr(TMP2);
  __ LoadImmediate(TMP2, VMTag::kDartTagId);
  __ sx(TMP2, compiler::Address(THR, target::Thread::vm_tag_offset()));
}

LeafRuntimeScope::~LeafRuntimeScope() {
  if (preserve_registers_) {
    const intptr_t kSavedRegistersSize =
        kRuntimeCallSavedRegisters.CpuRegisterCount() * target::kWordSize +
        kRuntimeCallSavedRegisters.FpuRegisterCount() * kFpuRegisterSize +
        4 * target::kWordSize;

    __ subi(SP, FP, kSavedRegistersSize);

    __ PopRegisters(kRuntimeCallSavedRegisters);
  }

  __ subi(SP, FP, 4 * target::kWordSize);
  __ lx(PP, Address(SP, 0 * target::kWordSize));
  __ lx(CODE_REG, Address(SP, 1 * target::kWordSize));
  __ lx(FP, Address(SP, 2 * target::kWordSize));
  __ lx(RA, Address(SP, 3 * target::kWordSize));
  __ addi(SP, SP, 4 * target::kWordSize);
}

#undef __

void Assembler::EnterCFrame(intptr_t frame_space) {
  // Already saved.
  COMPILE_ASSERT(IsCalleeSavedRegister(THR));
  COMPILE_ASSERT(IsCalleeSavedRegister(NULL_REG));
  COMPILE_ASSERT(IsCalleeSavedRegister(WRITE_BARRIER_STATE));
  COMPILE_ASSERT(IsCalleeSavedRegister(DISPATCH_TABLE_REG));
  // Need to save.
  COMPILE_ASSERT(!IsCalleeSavedRegister(PP));

  // N.B. The ordering here is important. We must never read beyond SP or
  // it may have already been clobbered by a signal handler.
  subi(SP, SP, frame_space + 3 * target::kWordSize);
  sx(RA, Address(SP, frame_space + 2 * target::kWordSize));
  sx(FP, Address(SP, frame_space + 1 * target::kWordSize));
  sx(PP, Address(SP, frame_space + 0 * target::kWordSize));
  addi(FP, SP, frame_space + 3 * target::kWordSize);
  const intptr_t kAbiStackAlignment = 16;  // For both 32 and 64 bit.
  andi(SP, SP, ~(kAbiStackAlignment - 1));
}

void Assembler::LeaveCFrame() {
  // N.B. The ordering here is important. We must never read beyond SP or
  // it may have already been clobbered by a signal handler.
  subi(SP, FP, 3 * target::kWordSize);
  lx(PP, Address(SP, 0 * target::kWordSize));
  lx(FP, Address(SP, 1 * target::kWordSize));
  lx(RA, Address(SP, 2 * target::kWordSize));
  addi(SP, SP, 3 * target::kWordSize);
}

// A0: Receiver
// S5: ICData entry array
// PP: Caller's PP (preserved)
void Assembler::MonomorphicCheckedEntryJIT() {
  has_monomorphic_entry_ = true;
  const intptr_t saved_far_branch_level = far_branch_level();
  set_far_branch_level(0);
  const intptr_t start = CodeSize();

  Label immediate, miss;
  Bind(&miss);
  lx(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  jr(TMP);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetJIT);

  Register entries_reg = IC_DATA_REG;  // Contains ICData::entries().
  const intptr_t cid_offset = target::Array::element_offset(0);
  const intptr_t count_offset = target::Array::element_offset(1);
  ASSERT(A1 != PP);
  ASSERT(A1 != entries_reg);
  ASSERT(A1 != CODE_REG);

  lx(TMP, FieldAddress(entries_reg, cid_offset));
  LoadTaggedClassIdMayBeSmi(A1, A0);
  bne(TMP, A1, &miss, kNearJump);

  lx(TMP, FieldAddress(entries_reg, count_offset));
  addi(TMP, TMP, target::ToRawSmi(1));
  sx(TMP, FieldAddress(entries_reg, count_offset));

  li(ARGS_DESC_REG, 0);  // GC-safe for OptimizeInvokedFunction

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetJIT);

  set_far_branch_level(saved_far_branch_level);
}

// A0 receiver, S5 guarded cid as Smi.
// Preserve S4 (ARGS_DESC_REG), not required today, but maybe later.
// PP: Caller's PP (preserved)
void Assembler::MonomorphicCheckedEntryAOT() {
  has_monomorphic_entry_ = true;
  intptr_t saved_far_branch_level = far_branch_level();
  set_far_branch_level(0);

  const intptr_t start = CodeSize();

  Label immediate, miss;
  Bind(&miss);
  lx(TMP, Address(THR, target::Thread::switchable_call_miss_entry_offset()));
  jr(TMP);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetAOT);
  LoadClassId(TMP, A0);
  SmiTag(TMP);
  bne(S5, TMP, &miss, kNearJump);

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetAOT);

  set_far_branch_level(saved_far_branch_level);
}

void Assembler::BranchOnMonomorphicCheckedEntryJIT(Label* label) {
  has_monomorphic_entry_ = true;
  while (CodeSize() < target::Instructions::kMonomorphicEntryOffsetJIT) {
    ebreak();
  }
  j(label);
  while (CodeSize() < target::Instructions::kPolymorphicEntryOffsetJIT) {
    ebreak();
  }
}

void Assembler::CombineHashes(Register hash, Register other) {
#if XLEN >= 64
  // hash += other_hash
  addw(hash, hash, other);
  // hash += hash << 10
  slliw(other, hash, 10);
  addw(hash, hash, other);
  // hash ^= hash >> 6
  srliw(other, hash, 6);
  xor_(hash, hash, other);
#else
  // hash += other_hash
  add(hash, hash, other);
  // hash += hash << 10
  slli(other, hash, 10);
  add(hash, hash, other);
  // hash ^= hash >> 6
  srli(other, hash, 6);
  xor_(hash, hash, other);
#endif
}

void Assembler::FinalizeHashForSize(intptr_t bit_size,
                                    Register hash,
                                    Register scratch) {
  ASSERT(bit_size > 0);  // Can't avoid returning 0 if there are no hash bits!
  // While any 32-bit hash value fits in X bits, where X > 32, the caller may
  // reasonably expect that the returned values fill the entire bit space.
  ASSERT(bit_size <= kBitsPerInt32);
  ASSERT(scratch != kNoRegister);
#if XLEN >= 64
  // hash += hash << 3;
  slliw(scratch, hash, 3);
  addw(hash, hash, scratch);
  // hash ^= hash >> 11;  // Logical shift, unsigned hash.
  srliw(scratch, hash, 11);
  xor_(hash, hash, scratch);
  // hash += hash << 15;
  slliw(scratch, hash, 15);
  addw(hash, hash, scratch);
#else
  // hash += hash << 3;
  slli(scratch, hash, 3);
  add(hash, hash, scratch);
  // hash ^= hash >> 11;  // Logical shift, unsigned hash.
  srli(scratch, hash, 11);
  xor_(hash, hash, scratch);
  // hash += hash << 15;
  slli(scratch, hash, 15);
  add(hash, hash, scratch);
#endif
  // Size to fit.
  if (bit_size < kBitsPerInt32) {
    AndImmediate(hash, hash, Utils::NBitMask(bit_size));
  }
  // return (hash == 0) ? 1 : hash;
  seqz(scratch, hash);
  add(hash, hash, scratch);
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Label* trace,
                                     Register temp_reg,
                                     JumpDistance distance) {
  ASSERT(cid > 0);
  LoadIsolateGroup(temp_reg);
  lx(temp_reg, Address(temp_reg, target::IsolateGroup::class_table_offset()));
  lx(temp_reg,
     Address(temp_reg,
             target::ClassTable::allocation_tracing_state_table_offset()));
  LoadFromOffset(temp_reg, temp_reg,
                 target::ClassTable::AllocationTracingStateSlotOffsetFor(cid),
                 kUnsignedByte);
  bnez(temp_reg, trace);
}
#endif  // !PRODUCT

void Assembler::TryAllocateObject(intptr_t cid,
                                  intptr_t instance_size,
                                  Label* failure,
                                  JumpDistance distance,
                                  Register instance_reg,
                                  Register temp_reg) {
  ASSERT(failure != nullptr);
  ASSERT(instance_size != 0);
  ASSERT(instance_reg != temp_reg);
  ASSERT(temp_reg != kNoRegister);
  ASSERT(Utils::IsAligned(instance_size,
                          target::ObjectAlignment::kObjectAlignment));
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp_reg));

    lx(instance_reg, Address(THR, target::Thread::top_offset()));
    lx(temp_reg, Address(THR, target::Thread::end_offset()));
    // instance_reg: current top (next object start).
    // temp_reg: heap end

    // TODO(koda): Protect against unsigned overflow here.
    AddImmediate(instance_reg, instance_size);
    // instance_reg: potential top (next object start).
    // fail if heap end unsigned less than or equal to new heap top.
    bleu(temp_reg, instance_reg, failure, distance);
    CheckAllocationCanary(instance_reg, temp_reg);

    // Successfully allocated the object, now update temp to point to
    // next object start and store the class in the class field of object.
    sx(instance_reg, Address(THR, target::Thread::top_offset()));
    // Move instance_reg back to the start of the object and tag it.
    AddImmediate(instance_reg, -instance_size + kHeapObjectTag);

    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(temp_reg, tags);
    StoreToOffset(temp_reg,
                  FieldAddress(instance_reg, target::Object::tags_offset()));
  } else {
    j(failure, distance);
  }
}

void Assembler::TryAllocateArray(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 Register instance,
                                 Register end_address,
                                 Register temp1,
                                 Register temp2) {
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp1));
    // Potential new object start.
    lx(instance, Address(THR, target::Thread::top_offset()));
    AddImmediate(end_address, instance, instance_size);
    bltu(end_address, instance, failure);  // Fail on unsigned overflow.

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    lx(temp2, Address(THR, target::Thread::end_offset()));
    bgeu(end_address, temp2, failure);
    CheckAllocationCanary(instance, temp2);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    sx(end_address, Address(THR, target::Thread::top_offset()));
    addi(instance, instance, kHeapObjectTag);
    NOT_IN_PRODUCT(LoadImmediate(temp2, instance_size));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    LoadImmediate(temp2, tags);
    sx(temp2, FieldAddress(instance, target::Object::tags_offset()));
  } else {
    j(failure);
  }
}

void Assembler::CopyMemoryWords(Register src,
                                Register dst,
                                Register size,
                                Register temp) {
  Label loop, done;
  beqz(size, &done, kNearJump);
  Bind(&loop);
  lx(temp, Address(src));
  addi(src, src, target::kWordSize);
  sx(temp, Address(dst));
  addi(dst, dst, target::kWordSize);
  subi(size, size, target::kWordSize);
  bnez(size, &loop, kNearJump);
  Bind(&done);
}

void Assembler::GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target) {
  // JAL only has a +/- 1MB range. AUIPC+JALR has a +/- 2GB range.
  intx_t lo = ImmLo(offset_into_target);
  intx_t hi = ImmHi(offset_into_target);
  auipc(RA, hi);
  jalr_fixed(RA, RA, lo);
}

void Assembler::GenerateUnRelocatedPcRelativeTailCall(
    intptr_t offset_into_target) {
  // J only has a +/- 1MB range. AUIPC+JR has a +/- 2GB range.
  intx_t lo = ImmLo(offset_into_target);
  intx_t hi = ImmHi(offset_into_target);
  auipc(TMP, hi);
  jalr_fixed(ZR, TMP, lo);
}

static OperandSize OperandSizeFor(intptr_t cid) {
  switch (cid) {
    case kArrayCid:
    case kImmutableArrayCid:
    case kRecordCid:
    case kTypeArgumentsCid:
      return kObjectBytes;
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      return kByte;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      return kTwoBytes;
    case kTypedDataInt8ArrayCid:
      return kByte;
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnsignedByte;
    case kTypedDataInt16ArrayCid:
      return kTwoBytes;
    case kTypedDataUint16ArrayCid:
      return kUnsignedTwoBytes;
    case kTypedDataInt32ArrayCid:
      return kFourBytes;
    case kTypedDataUint32ArrayCid:
      return kUnsignedFourBytes;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kDWord;
    case kTypedDataFloat32ArrayCid:
      return kSWord;
    case kTypedDataFloat64ArrayCid:
      return kDWord;
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataInt32x4ArrayCid:
    case kTypedDataFloat64x2ArrayCid:
      return kQWord;
    case kTypedDataInt8ArrayViewCid:
      UNREACHABLE();
      return kByte;
    default:
      UNREACHABLE();
      return kByte;
  }
}

Address Assembler::ElementAddressForIntIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index) const {
  const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
  ASSERT(Utils::IsInt(32, offset));
  return Address(array, static_cast<int32_t>(offset));
}
void Assembler::ComputeElementAddressForIntIndex(Register address,
                                                 bool is_external,
                                                 intptr_t cid,
                                                 intptr_t index_scale,
                                                 Register array,
                                                 intptr_t index) {
  const int64_t offset = index * index_scale + HeapDataOffset(is_external, cid);
  AddImmediate(address, array, offset);
}

Address Assembler::ElementAddressForRegIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             bool index_unboxed,
                                             Register array,
                                             Register index,
                                             Register temp) {
  return ElementAddressForRegIndexWithSize(is_external, cid,
                                           OperandSizeFor(cid), index_scale,
                                           index_unboxed, array, index, temp);
}

Address Assembler::ElementAddressForRegIndexWithSize(bool is_external,
                                                     intptr_t cid,
                                                     OperandSize size,
                                                     intptr_t index_scale,
                                                     bool index_unboxed,
                                                     Register array,
                                                     Register index,
                                                     Register temp) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  const int32_t offset = HeapDataOffset(is_external, cid);
  ASSERT(array != temp);
  ASSERT(index != temp);
  AddShifted(temp, array, index, shift);
  return Address(temp, offset);
}

void Assembler::ComputeElementAddressForRegIndex(Register address,
                                                 bool is_external,
                                                 intptr_t cid,
                                                 intptr_t index_scale,
                                                 bool index_unboxed,
                                                 Register array,
                                                 Register index) {
  // If unboxed, index is expected smi-tagged, (i.e, LSL 1) for all arrays.
  const intptr_t boxing_shift = index_unboxed ? 0 : -kSmiTagShift;
  const intptr_t shift = Utils::ShiftForPowerOfTwo(index_scale) + boxing_shift;
  const int32_t offset = HeapDataOffset(is_external, cid);
  ASSERT(array != address);
  ASSERT(index != address);
  AddShifted(address, array, index, shift);
  if (offset != 0) {
    AddImmediate(address, address, offset);
  }
}

void Assembler::LoadStaticFieldAddress(Register address,
                                       Register field,
                                       Register scratch) {
  LoadCompressedSmiFieldFromOffset(
      scratch, field, target::Field::host_offset_or_field_id_offset());
  const intptr_t field_table_offset =
      compiler::target::Thread::field_table_values_offset();
  LoadMemoryValue(address, THR, static_cast<int32_t>(field_table_offset));
  slli(scratch, scratch, target::kWordSizeLog2 - kSmiTagShift);
  add(address, address, scratch);
}

void Assembler::LoadCompressedFieldAddressForRegOffset(
    Register address,
    Register instance,
    Register offset_in_words_as_smi) {
  AddShifted(address, instance, offset_in_words_as_smi,
             target::kCompressedWordSizeLog2 - kSmiTagShift);
  addi(address, address, -kHeapObjectTag);
}

void Assembler::LoadFieldAddressForRegOffset(Register address,
                                             Register instance,
                                             Register offset_in_words_as_smi) {
  AddShifted(address, instance, offset_in_words_as_smi,
             target::kWordSizeLog2 - kSmiTagShift);
  addi(address, address, -kHeapObjectTag);
}

// Note: the function never clobbers TMP, TMP2 scratch registers.
void Assembler::LoadObjectHelper(
    Register dst,
    const Object& object,
    bool is_unique,
    ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior) {
  ASSERT(IsOriginalObject(object));
  // `is_unique == true` effectively means object has to be patchable.
  // (even if the object is null)
  if (!is_unique) {
    if (IsSameObject(compiler::NullObject(), object)) {
      mv(dst, NULL_REG);
      return;
    }
    if (IsSameObject(CastHandle<Object>(compiler::TrueObject()), object)) {
      addi(dst, NULL_REG, kTrueOffsetFromNull);
      return;
    }
    if (IsSameObject(CastHandle<Object>(compiler::FalseObject()), object)) {
      addi(dst, NULL_REG, kFalseOffsetFromNull);
      return;
    }
    word offset = 0;
    if (target::CanLoadFromThread(object, &offset)) {
      lx(dst, Address(THR, offset));
      return;
    }
    if (target::IsSmi(object)) {
      LoadImmediate(dst, target::ToRawSmi(object));
      return;
    }
  }
  RELEASE_ASSERT(CanLoadFromObjectPool(object));
  const intptr_t index =
      is_unique
          ? object_pool_builder().AddObject(
                object, ObjectPoolBuilderEntry::kPatchable, snapshot_behavior)
          : object_pool_builder().FindObject(
                object, ObjectPoolBuilderEntry::kNotPatchable,
                snapshot_behavior);
  LoadWordFromPoolIndex(dst, index);
}

void Assembler::AddImmediateBranchOverflow(Register rd,
                                           Register rs1,
                                           intx_t imm,
                                           Label* overflow) {
  ASSERT(rd != TMP2);
  if (rd == rs1) {
    mv(TMP2, rs1);
    AddImmediate(rd, rs1, imm);
    if (imm > 0) {
      blt(rd, TMP2, overflow);
    } else if (imm < 0) {
      bgt(rd, TMP2, overflow);
    }
  } else {
    AddImmediate(rd, rs1, imm);
    if (imm > 0) {
      blt(rd, rs1, overflow);
    } else if (imm < 0) {
      bgt(rd, rs1, overflow);
    }
  }
}
void Assembler::SubtractImmediateBranchOverflow(Register rd,
                                                Register rs1,
                                                intx_t imm,
                                                Label* overflow) {
  // TODO(riscv): Incorrect for MIN_INTX_T!
  AddImmediateBranchOverflow(rd, rs1, -imm, overflow);
}
void Assembler::MultiplyImmediateBranchOverflow(Register rd,
                                                Register rs1,
                                                intx_t imm,
                                                Label* overflow) {
  ASSERT(rd != TMP);
  ASSERT(rd != TMP2);
  ASSERT(rs1 != TMP);
  ASSERT(rs1 != TMP2);

  LoadImmediate(TMP2, imm);
  // Macro-op fusion: when both products are needed, the recommended sequence
  // is mulh first.
  mulh(TMP, rs1, TMP2);
  mul(rd, rs1, TMP2);
  srai(TMP2, rd, XLEN - 1);
  bne(TMP, TMP2, overflow);
}
void Assembler::AddBranchOverflow(Register rd,
                                  Register rs1,
                                  Register rs2,
                                  Label* overflow) {
  ASSERT(rd != TMP);
  ASSERT(rd != TMP2);
  ASSERT(rs1 != TMP);
  ASSERT(rs1 != TMP2);
  ASSERT(rs2 != TMP);
  ASSERT(rs2 != TMP2);

  if ((rd == rs1) && (rd == rs2)) {
    ASSERT(rs1 == rs2);
    mv(TMP, rs1);
    add(rd, rs1, rs2);   // rs1, rs2 destroyed
    xor_(TMP, TMP, rd);  // TMP negative if sign changed
    bltz(TMP, overflow);
  } else if (rs1 == rs2) {
    ASSERT(rd != rs1);
    ASSERT(rd != rs2);
    add(rd, rs1, rs2);
    xor_(TMP, rd, rs1);  // TMP negative if sign changed
    bltz(TMP, overflow);
  } else if (rd == rs1) {
    ASSERT(rs1 != rs2);
    slti(TMP, rs1, 0);
    add(rd, rs1, rs2);  // rs1 destroyed
    slt(TMP2, rd, rs2);
    bne(TMP, TMP2, overflow);
  } else if (rd == rs2) {
    ASSERT(rs1 != rs2);
    slti(TMP, rs2, 0);
    add(rd, rs1, rs2);  // rs2 destroyed
    slt(TMP2, rd, rs1);
    bne(TMP, TMP2, overflow);
  } else {
    add(rd, rs1, rs2);
    slti(TMP, rs2, 0);
    slt(TMP2, rd, rs1);
    bne(TMP, TMP2, overflow);
  }
}

void Assembler::SubtractBranchOverflow(Register rd,
                                       Register rs1,
                                       Register rs2,
                                       Label* overflow) {
  ASSERT(rd != TMP);
  ASSERT(rd != TMP2);
  ASSERT(rs1 != TMP);
  ASSERT(rs1 != TMP2);
  ASSERT(rs2 != TMP);
  ASSERT(rs2 != TMP2);

  if ((rd == rs1) && (rd == rs2)) {
    ASSERT(rs1 == rs2);
    mv(TMP, rs1);
    sub(rd, rs1, rs2);   // rs1, rs2 destroyed
    xor_(TMP, TMP, rd);  // TMP negative if sign changed
    bltz(TMP, overflow);
  } else if (rs1 == rs2) {
    ASSERT(rd != rs1);
    ASSERT(rd != rs2);
    sub(rd, rs1, rs2);
    xor_(TMP, rd, rs1);  // TMP negative if sign changed
    bltz(TMP, overflow);
  } else if (rd == rs1) {
    ASSERT(rs1 != rs2);
    slti(TMP, rs1, 0);
    sub(rd, rs1, rs2);  // rs1 destroyed
    slt(TMP2, rd, rs2);
    bne(TMP, TMP2, overflow);
  } else if (rd == rs2) {
    ASSERT(rs1 != rs2);
    slti(TMP, rs2, 0);
    sub(rd, rs1, rs2);  // rs2 destroyed
    slt(TMP2, rd, rs1);
    bne(TMP, TMP2, overflow);
  } else {
    sub(rd, rs1, rs2);
    slti(TMP, rs2, 0);
    slt(TMP2, rs1, rd);
    bne(TMP, TMP2, overflow);
  }
}

void Assembler::MultiplyBranchOverflow(Register rd,
                                       Register rs1,
                                       Register rs2,
                                       Label* overflow) {
  ASSERT(rd != TMP);
  ASSERT(rd != TMP2);
  ASSERT(rs1 != TMP);
  ASSERT(rs1 != TMP2);
  ASSERT(rs2 != TMP);
  ASSERT(rs2 != TMP2);

  // Macro-op fusion: when both products are needed, the recommended sequence
  // is mulh first.
  mulh(TMP, rs1, rs2);
  mul(rd, rs1, rs2);
  srai(TMP2, rd, XLEN - 1);
  bne(TMP, TMP2, overflow);
}

void Assembler::CountLeadingZeroes(Register rd, Register rs) {
  if (Supports(RV_Zbb)) {
    clz(rd, rs);
    return;
  }

  //  n = XLEN
  //  y = x >>32; if (y != 0) { n = n - 32; x = y; }
  //  y = x >>16; if (y != 0) { n = n - 16; x = y; }
  //  y = x >> 8; if (y != 0) { n = n - 8; x = y; }
  //  y = x >> 4; if (y != 0) { n = n - 4; x = y; }
  //  y = x >> 2; if (y != 0) { n = n - 2; x = y; }
  //  y = x >> 1; if (y != 0) { return n - 2; }
  //  return n - x;
  Label l0, l1, l2, l3, l4, l5;
  li(TMP2, XLEN);
#if XLEN == 64
  srli(TMP, rs, 32);
  beqz(TMP, &l0, Assembler::kNearJump);
  subi(TMP2, TMP2, 32);
  mv(rs, TMP);
  Bind(&l0);
#endif
  srli(TMP, rs, 16);
  beqz(TMP, &l1, Assembler::kNearJump);
  subi(TMP2, TMP2, 16);
  mv(rs, TMP);
  Bind(&l1);
  srli(TMP, rs, 8);
  beqz(TMP, &l2, Assembler::kNearJump);
  subi(TMP2, TMP2, 8);
  mv(rs, TMP);
  Bind(&l2);
  srli(TMP, rs, 4);
  beqz(TMP, &l3, Assembler::kNearJump);
  subi(TMP2, TMP2, 4);
  mv(rs, TMP);
  Bind(&l3);
  srli(TMP, rs, 2);
  beqz(TMP, &l4, Assembler::kNearJump);
  subi(TMP2, TMP2, 2);
  mv(rs, TMP);
  Bind(&l4);
  srli(TMP, rs, 1);
  sub(rd, TMP2, rs);
  beqz(TMP, &l5, Assembler::kNearJump);
  subi(rd, TMP2, 2);
  Bind(&l5);
}

void Assembler::RangeCheck(Register value,
                           Register temp,
                           intptr_t low,
                           intptr_t high,
                           RangeCheckCondition condition,
                           Label* target) {
  auto cc = condition == kIfInRange ? LS : HI;
  Register to_check = temp != kNoRegister ? temp : value;
  AddImmediate(to_check, value, -low);
  CompareImmediate(to_check, high - low);
  BranchIf(cc, target);
}

}  // namespace compiler

}  // namespace dart

#endif  // defined(TARGET_ARCH_RISCV)
