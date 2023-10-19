// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_RISCV_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_RISCV_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_riscv.h directly; use assembler.h instead.
#endif

#include <functional>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler_base.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/constants.h"
#include "vm/hash_map.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class RuntimeEntry;
class RegisterSet;

namespace compiler {

class Address {
 public:
  Address(Register base, intptr_t offset) : base_(base), offset_(offset) {}
  explicit Address(Register base) : base_(base), offset_(0) {}

  // Prevent implicit conversion of Register to intptr_t.
  Address(Register base, Register index) = delete;

  Register base() const { return base_; }
  intptr_t offset() const { return offset_; }

 private:
  Register base_;
  intptr_t offset_;
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, intptr_t offset)
      : Address(base, offset - kHeapObjectTag) {}

  // Prevent implicit conversion of Register to intptr_t.
  FieldAddress(Register base, Register index) = delete;
};

// All functions produce exactly one instruction.
class MicroAssembler : public AssemblerBase {
 public:
  MicroAssembler(ObjectPoolBuilder* object_pool_builder,
                 intptr_t far_branch_level,
                 ExtensionSet extensions);
  ~MicroAssembler();

#if defined(TESTING)
  void SetExtensions(ExtensionSet extensions) { extensions_ = extensions; }
#endif
  bool Supports(Extension extension) const {
    return extensions_.Includes(extension);
  }
  bool Supports(ExtensionSet extensions) const {
    return extensions_.IncludesAll(extensions);
  }

  intptr_t far_branch_level() const { return far_branch_level_; }
  void set_far_branch_level(intptr_t level) { far_branch_level_ = level; }
  void Bind(Label* label);

  // ==== RV32I ====
  void lui(Register rd, intptr_t imm);
  void lui_fixed(Register rd, intptr_t imm);
  void auipc(Register rd, intptr_t imm);

  void jal(Register rd, Label* label, JumpDistance d = kFarJump);
  void jal(Label* label, JumpDistance d = kFarJump) { jal(RA, label, d); }
  void j(Label* label, JumpDistance d = kFarJump) { jal(ZR, label, d); }

  void jalr(Register rd, Register rs1, intptr_t offset = 0);
  void jalr_fixed(Register rd, Register rs1, intptr_t offset);
  void jalr(Register rs1, intptr_t offset = 0) { jalr(RA, rs1, offset); }
  void jr(Register rs1, intptr_t offset = 0) { jalr(ZR, rs1, offset); }
  void ret() { jalr(ZR, RA, 0); }

  void beq(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void bne(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void blt(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void bge(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void bgt(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump) {
    blt(rs2, rs1, l, d);
  }
  void ble(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump) {
    bge(rs2, rs1, l, d);
  }
  void bltu(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void bgeu(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump);
  void bgtu(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump) {
    bltu(rs2, rs1, l, d);
  }
  void bleu(Register rs1, Register rs2, Label* l, JumpDistance d = kFarJump) {
    bgeu(rs2, rs1, l, d);
  }

  void lb(Register rd, Address addr);
  void lh(Register rd, Address addr);
  void lw(Register rd, Address addr);
  void lbu(Register rd, Address addr);
  void lhu(Register rd, Address addr);

  void sb(Register rs2, Address addr);
  void sh(Register rs2, Address addr);
  void sw(Register rs2, Address addr);

  void addi(Register rd, Register rs1, intptr_t imm);
  void subi(Register rd, Register rs1, intptr_t imm) { addi(rd, rs1, -imm); }
  void slti(Register rd, Register rs1, intptr_t imm);
  void sltiu(Register rd, Register rs1, intptr_t imm);
  void xori(Register rd, Register rs1, intptr_t imm);
  void ori(Register rd, Register rs1, intptr_t imm);
  void andi(Register rd, Register rs1, intptr_t imm);
  void slli(Register rd, Register rs1, intptr_t shamt);
  void srli(Register rd, Register rs1, intptr_t shamt);
  void srai(Register rd, Register rs1, intptr_t shamt);

  void add(Register rd, Register rs1, Register rs2);
  void sub(Register rd, Register rs1, Register rs2);
  void sll(Register rd, Register rs1, Register rs2);
  void slt(Register rd, Register rs1, Register rs2);
  void sltu(Register rd, Register rs1, Register rs2);
  void xor_(Register rd, Register rs1, Register rs2);
  void srl(Register rd, Register rs1, Register rs2);
  void sra(Register rd, Register rs1, Register rs2);
  void or_(Register rd, Register rs1, Register rs2);
  void and_(Register rd, Register rs1, Register rs2);

  void fence(HartEffects predecessor, HartEffects successor);
  void fence() { fence(kAll, kAll); }
  void fencei();
  void ecall();
  void ebreak();  // Causes SIGTRAP(5).

  void csrrw(Register rd, uint32_t csr, Register rs1);
  void csrrs(Register rd, uint32_t csr, Register rs1);
  void csrrc(Register rd, uint32_t csr, Register rs1);
  void csrr(Register rd, uint32_t csr) { csrrs(rd, csr, ZR); }
  void csrw(uint32_t csr, Register rs) { csrrw(ZR, csr, rs); }
  void csrs(uint32_t csr, Register rs) { csrrs(ZR, csr, rs); }
  void csrc(uint32_t csr, Register rs) { csrrc(ZR, csr, rs); }
  void csrrwi(Register rd, uint32_t csr, uint32_t imm);
  void csrrsi(Register rd, uint32_t csr, uint32_t imm);
  void csrrci(Register rd, uint32_t csr, uint32_t imm);
  void csrwi(uint32_t csr, uint32_t imm) { csrrwi(ZR, csr, imm); }
  void csrsi(uint32_t csr, uint32_t imm) { csrrsi(ZR, csr, imm); }
  void csrci(uint32_t csr, uint32_t imm) { csrrci(ZR, csr, imm); }

  void trap();  // Permanently reserved illegal instruction; causes SIGILL(4).

  void nop() { addi(ZR, ZR, 0); }
  void li(Register rd, intptr_t imm) { addi(rd, ZR, imm); }
  void mv(Register rd, Register rs) { addi(rd, rs, 0); }
  void not_(Register rd, Register rs) { xori(rd, rs, -1); }
  void neg(Register rd, Register rs) { sub(rd, ZR, rs); }

  void snez(Register rd, Register rs) { sltu(rd, ZR, rs); }
  void seqz(Register rd, Register rs) { sltiu(rd, rs, 1); }
  void sltz(Register rd, Register rs) { slt(rd, rs, ZR); }
  void sgtz(Register rd, Register rs) { slt(rd, ZR, rs); }

  void beqz(Register rs, Label* label, JumpDistance distance = kFarJump) {
    beq(rs, ZR, label, distance);
  }
  void bnez(Register rs, Label* label, JumpDistance distance = kFarJump) {
    bne(rs, ZR, label, distance);
  }
  void blez(Register rs, Label* label, JumpDistance distance = kFarJump) {
    bge(ZR, rs, label, distance);
  }
  void bgez(Register rs, Label* label, JumpDistance distance = kFarJump) {
    bge(rs, ZR, label, distance);
  }
  void bltz(Register rs, Label* label, JumpDistance distance = kFarJump) {
    blt(rs, ZR, label, distance);
  }
  void bgtz(Register rs, Label* label, JumpDistance distance = kFarJump) {
    blt(ZR, rs, label, distance);
  }

  // ==== RV64I ====
#if XLEN >= 64
  void lwu(Register rd, Address addr);
  void ld(Register rd, Address addr);

  void sd(Register rs2, Address addr);

  void addiw(Register rd, Register rs1, intptr_t imm);
  void subiw(Register rd, Register rs1, intptr_t imm) { addiw(rd, rs1, -imm); }
  void slliw(Register rd, Register rs1, intptr_t shamt);
  void srliw(Register rd, Register rs1, intptr_t shamt);
  void sraiw(Register rd, Register rs1, intptr_t shamt);

  void addw(Register rd, Register rs1, Register rs2);
  void subw(Register rd, Register rs1, Register rs2);
  void sllw(Register rd, Register rs1, Register rs2);
  void srlw(Register rd, Register rs1, Register rs2);
  void sraw(Register rd, Register rs1, Register rs2);

  void negw(Register rd, Register rs) { subw(rd, ZR, rs); }
  void sextw(Register rd, Register rs) { addiw(rd, rs, 0); }
#endif  // XLEN >= 64

#if XLEN == 32
  void lx(Register rd, Address addr) { lw(rd, addr); }
  void sx(Register rs2, Address addr) { sw(rs2, addr); }
#elif XLEN == 64
  void lx(Register rd, Address addr) { ld(rd, addr); }
  void sx(Register rs2, Address addr) { sd(rs2, addr); }
#elif XLEN == 128
  void lx(Register rd, Address addr) { lq(rd, addr); }
  void sx(Register rs2, Address addr) { sq(rs2, addr); }
#endif

  // ==== RV32M ====
  void mul(Register rd, Register rs1, Register rs2);
  void mulh(Register rd, Register rs1, Register rs2);
  void mulhsu(Register rd, Register rs1, Register rs2);
  void mulhu(Register rd, Register rs1, Register rs2);
  void div(Register rd, Register rs1, Register rs2);
  void divu(Register rd, Register rs1, Register rs2);
  void rem(Register rd, Register rs1, Register rs2);
  void remu(Register rd, Register rs1, Register rs2);

  // ==== RV64M ====
#if XLEN >= 64
  void mulw(Register rd, Register rs1, Register rs2);
  void divw(Register rd, Register rs1, Register rs2);
  void divuw(Register rd, Register rs1, Register rs2);
  void remw(Register rd, Register rs1, Register rs2);
  void remuw(Register rd, Register rs1, Register rs2);
#endif  // XLEN >= 64

  // ==== RV32A ====
  void lrw(Register rd,
           Address addr,
           std::memory_order order = std::memory_order_relaxed);
  void scw(Register rd,
           Register rs2,
           Address addr,
           std::memory_order order = std::memory_order_relaxed);
  void amoswapw(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);
  void amoaddw(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoxorw(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoandw(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoorw(Register rd,
              Register rs2,
              Address addr,
              std::memory_order order = std::memory_order_relaxed);
  void amominw(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amomaxw(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amominuw(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);
  void amomaxuw(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);

  // ==== RV64A ====
#if XLEN >= 64
  void lrd(Register rd,
           Address addr,
           std::memory_order order = std::memory_order_relaxed);
  void scd(Register rd,
           Register rs2,
           Address addr,
           std::memory_order order = std::memory_order_relaxed);
  void amoswapd(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);
  void amoaddd(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoxord(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoandd(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amoord(Register rd,
              Register rs2,
              Address addr,
              std::memory_order order = std::memory_order_relaxed);
  void amomind(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amomaxd(Register rd,
               Register rs2,
               Address addr,
               std::memory_order order = std::memory_order_relaxed);
  void amominud(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);
  void amomaxud(Register rd,
                Register rs2,
                Address addr,
                std::memory_order order = std::memory_order_relaxed);
#endif  // XLEN >= 64

#if XLEN == 32
  void lr(Register rd,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    lrw(rd, addr, order);
  }
  void sc(Register rd,
          Register rs2,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    scw(rd, rs2, addr, order);
  }
#elif XLEN == 64
  void lr(Register rd,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    lrd(rd, addr, order);
  }
  void sc(Register rd,
          Register rs2,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    scd(rd, rs2, addr, order);
  }
#elif XLEN == 128
  void lr(Register rd,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    lrq(rd, addr, order);
  }
  void sc(Register rd,
          Register rs2,
          Address addr,
          std::memory_order order = std::memory_order_relaxed) {
    scq(rd, rs2, addr, order);
  }
#endif

  // ==== RV32F ====
  void flw(FRegister rd, Address addr);
  void fsw(FRegister rs2, Address addr);
  // rd := (rs1 * rs2) + rs3
  void fmadds(FRegister rd,
              FRegister rs1,
              FRegister rs2,
              FRegister rs3,
              RoundingMode rounding = RNE);
  // rd := (rs1 * rs2) - rs3
  void fmsubs(FRegister rd,
              FRegister rs1,
              FRegister rs2,
              FRegister rs3,
              RoundingMode rounding = RNE);
  // rd := -(rs1 * rs2) + rs3
  void fnmsubs(FRegister rd,
               FRegister rs1,
               FRegister rs2,
               FRegister rs3,
               RoundingMode rounding = RNE);
  // rd := -(rs1 * rs2) - rs3
  void fnmadds(FRegister rd,
               FRegister rs1,
               FRegister rs2,
               FRegister rs3,
               RoundingMode rounding = RNE);
  void fadds(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fsubs(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fmuls(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fdivs(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fsqrts(FRegister rd, FRegister rs1, RoundingMode rounding = RNE);
  void fsgnjs(FRegister rd, FRegister rs1, FRegister rs2);
  void fsgnjns(FRegister rd, FRegister rs1, FRegister rs2);
  void fsgnjxs(FRegister rd, FRegister rs1, FRegister rs2);
  void fmins(FRegister rd, FRegister rs1, FRegister rs2);
  void fmaxs(FRegister rd, FRegister rs1, FRegister rs2);
  void feqs(Register rd, FRegister rs1, FRegister rs2);
  void flts(Register rd, FRegister rs1, FRegister rs2);
  void fles(Register rd, FRegister rs1, FRegister rs2);
  void fgts(Register rd, FRegister rs1, FRegister rs2) { flts(rd, rs2, rs1); }
  void fges(Register rd, FRegister rs1, FRegister rs2) { fles(rd, rs2, rs1); }
  void fclasss(Register rd, FRegister rs1);
  // int32_t <- float
  void fcvtws(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // uint32_t <- float
  void fcvtwus(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // float <- int32_t
  void fcvtsw(FRegister rd, Register rs1, RoundingMode rounding = RNE);
  // float <- uint32_t
  void fcvtswu(FRegister rd, Register rs1, RoundingMode rounding = RNE);

  void fmvs(FRegister rd, FRegister rs) { fsgnjs(rd, rs, rs); }
  void fabss(FRegister rd, FRegister rs) { fsgnjxs(rd, rs, rs); }
  void fnegs(FRegister rd, FRegister rs) { fsgnjns(rd, rs, rs); }

  // xlen <--bit_cast-- float
  void fmvxw(Register rd, FRegister rs1);
  // float <--bit_cast-- xlen
  void fmvwx(FRegister rd, Register rs1);

  // ==== RV64F ====
#if XLEN >= 64
  // int64_t <- double
  void fcvtls(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // uint64_t <- double
  void fcvtlus(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // double <- int64_t
  void fcvtsl(FRegister rd, Register rs1, RoundingMode rounding = RNE);
  // double <- uint64_t
  void fcvtslu(FRegister rd, Register rs1, RoundingMode rounding = RNE);
#endif  // XLEN >= 64

  // ==== RV32D ====
  void fld(FRegister rd, Address addr);
  void fsd(FRegister rs2, Address addr);
  // rd := (rs1 * rs2) + rs3
  void fmaddd(FRegister rd,
              FRegister rs1,
              FRegister rs2,
              FRegister rs3,
              RoundingMode rounding = RNE);
  // rd := (rs1 * rs2) - rs3
  void fmsubd(FRegister rd,
              FRegister rs1,
              FRegister rs2,
              FRegister rs3,
              RoundingMode rounding = RNE);
  // rd := -(rs1 * rs2) - rs3
  void fnmsubd(FRegister rd,
               FRegister rs1,
               FRegister rs2,
               FRegister rs3,
               RoundingMode rounding = RNE);
  // rd := -(rs1 * rs2) + rs3
  void fnmaddd(FRegister rd,
               FRegister rs1,
               FRegister rs2,
               FRegister rs3,
               RoundingMode rounding = RNE);
  void faddd(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fsubd(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fmuld(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fdivd(FRegister rd,
             FRegister rs1,
             FRegister rs2,
             RoundingMode rounding = RNE);
  void fsqrtd(FRegister rd, FRegister rs1, RoundingMode rounding = RNE);
  void fsgnjd(FRegister rd, FRegister rs1, FRegister rs2);
  void fsgnjnd(FRegister rd, FRegister rs1, FRegister rs2);
  void fsgnjxd(FRegister rd, FRegister rs1, FRegister rs2);
  void fmind(FRegister rd, FRegister rs1, FRegister rs2);
  void fmaxd(FRegister rd, FRegister rs1, FRegister rs2);
  void fcvtsd(FRegister rd, FRegister rs1, RoundingMode rounding = RNE);
  void fcvtds(FRegister rd, FRegister rs1, RoundingMode rounding = RNE);
  void feqd(Register rd, FRegister rs1, FRegister rs2);
  void fltd(Register rd, FRegister rs1, FRegister rs2);
  void fled(Register rd, FRegister rs1, FRegister rs2);
  void fgtd(Register rd, FRegister rs1, FRegister rs2) { fltd(rd, rs2, rs1); }
  void fged(Register rd, FRegister rs1, FRegister rs2) { fled(rd, rs2, rs1); }
  void fclassd(Register rd, FRegister rs1);
  // int32_t <- double
  void fcvtwd(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // uint32_t <- double
  void fcvtwud(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // double <- int32_t
  void fcvtdw(FRegister rd, Register rs1, RoundingMode rounding = RNE);
  // double <- uint32_t
  void fcvtdwu(FRegister rd, Register rs1, RoundingMode rounding = RNE);

  void fmvd(FRegister rd, FRegister rs) { fsgnjd(rd, rs, rs); }
  void fabsd(FRegister rd, FRegister rs) { fsgnjxd(rd, rs, rs); }
  void fnegd(FRegister rd, FRegister rs) { fsgnjnd(rd, rs, rs); }

  // ==== RV64D ====
#if XLEN >= 64
  // int64_t <- double
  void fcvtld(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // uint64_t <- double
  void fcvtlud(Register rd, FRegister rs1, RoundingMode rounding = RNE);
  // xlen <--bit_cast-- double
  void fmvxd(Register rd, FRegister rs1);
  // double <- int64_t
  void fcvtdl(FRegister rd, Register rs1, RoundingMode rounding = RNE);
  // double <- uint64_t
  void fcvtdlu(FRegister rd, Register rs1, RoundingMode rounding = RNE);
  // double <--bit_cast-- xlen
  void fmvdx(FRegister rd, Register rs1);
#endif  // XLEN >= 64

  // ==== Zba: Address generation ====
  void adduw(Register rd, Register rs1, Register rs2);
  void sh1add(Register rd, Register rs1, Register rs2);
  void sh1adduw(Register rd, Register rs1, Register rs2);
  void sh2add(Register rd, Register rs1, Register rs2);
  void sh2adduw(Register rd, Register rs1, Register rs2);
  void sh3add(Register rd, Register rs1, Register rs2);
  void sh3adduw(Register rd, Register rs1, Register rs2);
  void slliuw(Register rd, Register rs1, intx_t imm);

  // ==== Zbb: Basic bit-manipulation ====
  void andn(Register rd, Register rs1, Register rs2);
  void orn(Register rd, Register rs1, Register rs2);
  void xnor(Register rd, Register rs1, Register rs2);
  void clz(Register rd, Register rs);
  void clzw(Register rd, Register rs);
  void ctz(Register rd, Register rs);
  void ctzw(Register rd, Register rs);
  void cpop(Register rd, Register rs);
  void cpopw(Register rd, Register rs);
  void max(Register rd, Register rs1, Register rs2);  // NOLINT
  void maxu(Register rd, Register rs1, Register rs2);
  void min(Register rd, Register rs1, Register rs2);  // NOLINT
  void minu(Register rd, Register rs1, Register rs2);
  void sextb(Register rd, Register rs);
  void sexth(Register rd, Register rs);
  void zexth(Register rd, Register rs);
  void rol(Register rd, Register rs1, Register rs2);
  void rolw(Register rd, Register rs1, Register rs2);
  void ror(Register rd, Register rs1, Register rs2);
  void rori(Register rd, Register rs1, intx_t imm);
  void roriw(Register rd, Register rs1, intx_t imm);
  void rorw(Register rd, Register rs1, Register rs2);
  void orcb(Register rd, Register rs);
  void rev8(Register rd, Register rs);

  // ==== Zbc: Carry-less multiplication ====
  void clmul(Register rd, Register rs1, Register rs2);
  void clmulh(Register rd, Register rs1, Register rs2);
  void clmulr(Register rd, Register rs1, Register rs2);

  // ==== Zbs: Single-bit instructions ====
  void bclr(Register rd, Register rs1, Register rs2);
  void bclri(Register rd, Register rs1, intx_t shamt);
  void bext(Register rd, Register rs1, Register rs2);
  void bexti(Register rd, Register rs1, intx_t shamt);
  void binv(Register rd, Register rs1, Register rs2);
  void binvi(Register rd, Register rs1, intx_t shamt);
  void bset(Register rd, Register rs1, Register rs2);
  void bseti(Register rd, Register rs1, intx_t shamt);

  // ==== Dart Simulator Debugging ====
  void SimulatorPrintObject(Register rs1);

 private:
  // ==== RV32/64C ====
  void c_lwsp(Register rd, Address addr);
#if XLEN == 32
  void c_flwsp(FRegister rd, Address addr);
#else
  void c_ldsp(Register rd, Address addr);
#endif
  void c_fldsp(FRegister rd, Address addr);

  void c_swsp(Register rs2, Address addr);
#if XLEN == 32
  void c_fswsp(FRegister rs2, Address addr);
#else
  void c_sdsp(Register rs2, Address addr);
#endif
  void c_fsdsp(FRegister rs2, Address addr);

  void c_lw(Register rd, Address addr);
  void c_ld(Register rd, Address addr);
  void c_flw(FRegister rd, Address addr);
  void c_fld(FRegister rd, Address addr);

  void c_sw(Register rs2, Address addr);
  void c_sd(Register rs2, Address addr);
  void c_fsw(FRegister rs2, Address addr);
  void c_fsd(FRegister rs2, Address addr);

  void c_j(Label* label);
#if XLEN == 32
  void c_jal(Label* label);
#endif
  void c_jr(Register rs1);
  void c_jalr(Register rs1);

  void c_beqz(Register rs1p, Label* label);
  void c_bnez(Register rs1p, Label* label);

  void c_li(Register rd, intptr_t imm);
  void c_lui(Register rd, uintptr_t imm);

  void c_addi(Register rd, Register rs1, intptr_t imm);
#if XLEN >= 64
  void c_addiw(Register rd, Register rs1, intptr_t imm);
#endif
  void c_addi16sp(Register rd, Register rs1, intptr_t imm);
  void c_addi4spn(Register rdp, Register rs1, intptr_t imm);

  void c_slli(Register rd, Register rs1, intptr_t imm);
  void c_srli(Register rd, Register rs1, intptr_t imm);
  void c_srai(Register rd, Register rs1, intptr_t imm);
  void c_andi(Register rd, Register rs1, intptr_t imm);

  void c_mv(Register rd, Register rs2);

  void c_add(Register rd, Register rs1, Register rs2);
  void c_and(Register rd, Register rs1, Register rs2);
  void c_or(Register rd, Register rs1, Register rs2);
  void c_xor(Register rd, Register rs1, Register rs2);
  void c_sub(Register rd, Register rs1, Register rs2);
#if XLEN >= 64
  void c_addw(Register rd, Register rs1, Register rs2);
  void c_subw(Register rd, Register rs1, Register rs2);
#endif

  void c_nop();
  void c_ebreak();

 protected:
  intptr_t UpdateCBOffset(intptr_t branch_position, intptr_t new_offset);
  intptr_t UpdateCJOffset(intptr_t branch_position, intptr_t new_offset);
  intptr_t UpdateBOffset(intptr_t branch_position, intptr_t new_offset);
  intptr_t UpdateJOffset(intptr_t branch_position, intptr_t new_offset);
  intptr_t UpdateFarOffset(intptr_t branch_position, intptr_t new_offset);

  intptr_t Position() { return buffer_.Size(); }
  void EmitBranch(Register rs1,
                  Register rs2,
                  Label* label,
                  Funct3 func,
                  JumpDistance distance);
  void EmitJump(Register rd, Label* label, Opcode op, JumpDistance distance);
  void EmitCBranch(Register rs1p, Label* label, COpcode op);
  void EmitCJump(Label* label, COpcode op);

  void EmitRType(Funct5 funct5,
                 std::memory_order order,
                 Register rs2,
                 Register rs1,
                 Funct3 funct3,
                 Register rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 Register rs2,
                 Register rs1,
                 Funct3 funct3,
                 Register rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 FRegister rs1,
                 Funct3 funct3,
                 FRegister rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 FRegister rs1,
                 RoundingMode round,
                 FRegister rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 Register rs1,
                 RoundingMode round,
                 FRegister rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 Register rs1,
                 Funct3 funct3,
                 FRegister rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 FRegister rs1,
                 Funct3 funct3,
                 Register rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 FRegister rs2,
                 FRegister rs1,
                 RoundingMode round,
                 Register rd,
                 Opcode opcode);
  void EmitRType(Funct7 funct7,
                 intptr_t shamt,
                 Register rs1,
                 Funct3 funct3,
                 Register rd,
                 Opcode opcode);

  void EmitR4Type(FRegister rs3,
                  Funct2 funct2,
                  FRegister rs2,
                  FRegister rs1,
                  RoundingMode round,
                  FRegister rd,
                  Opcode opcode);

  void EmitIType(intptr_t imm,
                 Register rs1,
                 Funct3 funct3,
                 Register rd,
                 Opcode opcode);
  void EmitIType(intptr_t imm,
                 Register rs1,
                 Funct3 funct3,
                 FRegister rd,
                 Opcode opcode);

  void EmitSType(intptr_t imm,
                 Register rs2,
                 Register rs1,
                 Funct3 funct3,
                 Opcode opcode);
  void EmitSType(intptr_t imm,
                 FRegister rs2,
                 Register rs1,
                 Funct3 funct3,
                 Opcode opcode);

  void EmitBType(intptr_t imm,
                 Register rs2,
                 Register rs1,
                 Funct3 funct3,
                 Opcode opcode);

  void EmitUType(intptr_t imm, Register rd, Opcode opcode);

  void EmitJType(intptr_t imm, Register rd, Opcode opcode);

  uint16_t Read16(intptr_t position) {
    return buffer_.Load<uint16_t>(position);
  }
  void Write16(intptr_t position, uint16_t instruction) {
    return buffer_.Store<uint16_t>(position, instruction);
  }
  void Emit16(uint16_t instruction) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<uint16_t>(instruction);
  }
  uint32_t Read32(intptr_t position) {
    return buffer_.Load<uint32_t>(position);
  }
  void Write32(intptr_t position, uint32_t instruction) {
    return buffer_.Store<uint32_t>(position, instruction);
  }

 public:
  void Emit32(uint32_t instruction) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<uint32_t>(instruction);
  }
  void Emit64(uint64_t instruction) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<uint64_t>(instruction);
  }

 protected:
  ExtensionSet extensions_;
  intptr_t far_branch_level_;
};

class Assembler : public MicroAssembler {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     intptr_t far_branch_level = 0);
  ~Assembler() {}

  void PushRegister(Register r);
  void PopRegister(Register r);

  void PushRegisterPair(Register r0, Register r1);
  void PopRegisterPair(Register r0, Register r1);

  void PushRegisters(const RegisterSet& registers);
  void PopRegisters(const RegisterSet& registers);

  void PushRegistersInOrder(std::initializer_list<Register> regs);

  void PushValueAtOffset(Register base, int32_t offset) { UNIMPLEMENTED(); }

  // Push all registers which are callee-saved according to the ARM64 ABI.
  void PushNativeCalleeSavedRegisters();

  // Pop all registers which are callee-saved according to the ARM64 ABI.
  void PopNativeCalleeSavedRegisters();

  void ExtendValue(Register rd, Register rn, OperandSize sz) override;
  void ExtendAndSmiTagValue(Register rd,
                            Register rn,
                            OperandSize sz = kWordBytes) override;

  void Drop(intptr_t stack_elements) {
    ASSERT(stack_elements >= 0);
    if (stack_elements > 0) {
      AddImmediate(SP, SP, stack_elements * target::kWordSize);
    }
  }

  void Bind(Label* label) { MicroAssembler::Bind(label); }
  // Unconditional jump to a given label.
  void Jump(Label* label, JumpDistance distance = kFarJump) {
    j(label, distance);
  }
  // Unconditional jump to a given address in register.
  void Jump(Register target) { jr(target); }
  // Unconditional jump to a given address in memory. Clobbers TMP.
  void Jump(const Address& address);

  void LoadField(Register dst, const FieldAddress& address) override;
  void LoadCompressedField(Register dst, const FieldAddress& address) override {
    LoadCompressed(dst, address);
  }
  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
    LoadFromOffset(dst, base, offset, kWordBytes);
  }
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
    StoreToOffset(src, base, offset, kWordBytes);
  }

#if defined(TARGET_USES_THREAD_SANITIZER)
  void TsanLoadAcquire(Register addr);
  void TsanStoreRelease(Register addr);
#endif

  void LoadAcquire(Register dst,
                   Register address,
                   int32_t offset = 0,
                   OperandSize size = kWordBytes) override;

  void LoadAcquireCompressed(Register dst,
                             Register address,
                             int32_t offset = 0) override;

  void StoreRelease(Register src,
                    Register address,
                    int32_t offset = 0) override;

  void StoreReleaseCompressed(Register src,
                              Register address,
                              int32_t offset = 0);

  void CompareWithCompressedFieldFromOffset(Register value,
                                            Register base,
                                            int32_t offset);

  void CompareWithMemoryValue(Register value,
                              Address address,
                              OperandSize size = kWordBytes) override;

  // Debugging and bringup support.
  void Breakpoint() override { trap(); }

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // In debug mode, this generates code to check that:
  //   FP + kExitLinkSlotFromEntryFp == SP
  // or triggers breakpoint otherwise.
  void EmitEntryFrameVerification();

  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static constexpr intptr_t kEntryPointToPcMarkerOffset = 0;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

  void CompareRegisters(Register rn, Register rm);
  void CompareObjectRegisters(Register rn, Register rm);
  void TestRegisters(Register rn, Register rm);

  // Branches to the given label if the condition holds.
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump);
  void BranchIfZero(Register rn,
                    Label* label,
                    JumpDistance distance = kFarJump);
  void BranchIfBit(Register rn,
                   intptr_t bit_number,
                   Condition condition,
                   Label* label,
                   JumpDistance distance = kFarJump);
  void SetIf(Condition condition, Register rd);

  void SmiUntag(Register reg) { SmiUntag(reg, reg); }
  void SmiUntag(Register dst, Register src) { srai(dst, src, kSmiTagSize); }
  void SmiTag(Register reg) override { SmiTag(reg, reg); }
  void SmiTag(Register dst, Register src) { slli(dst, src, kSmiTagSize); }

  // Truncates upper bits.
  void LoadInt32FromBoxOrSmi(Register result, Register value) override {
    if (result == value) {
      ASSERT(TMP != value);
      MoveRegister(TMP, value);
      value = TMP;
    }
    ASSERT(value != result);
    compiler::Label done;
    SmiUntag(result, value);
    BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    LoadFieldFromOffset(result, value, target::Mint::value_offset(),
                        compiler::kFourBytes);
    Bind(&done);
  }

#if XLEN != 32
  void LoadInt64FromBoxOrSmi(Register result, Register value) override {
    if (result == value) {
      ASSERT(TMP != value);
      MoveRegister(TMP, value);
      value = TMP;
    }
    ASSERT(value != result);
    compiler::Label done;
    SmiUntag(result, value);
    BranchIfSmi(value, &done, compiler::Assembler::kNearJump);
    LoadFieldFromOffset(result, value, target::Mint::value_offset());
    Bind(&done);
  }
#endif

  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump);
  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) override;

  void ArithmeticShiftRightImmediate(Register reg, intptr_t shift) override;
  void CompareWords(Register reg1,
                    Register reg2,
                    intptr_t offset,
                    Register count,
                    Register temp,
                    Label* equals) override;

  void Jump(const Code& code,
            Register pp,
            ObjectPoolBuilderEntry::Patchability patchable =
                ObjectPoolBuilderEntry::kNotPatchable);

  void JumpAndLink(const Code& code,
                   ObjectPoolBuilderEntry::Patchability patchable =
                       ObjectPoolBuilderEntry::kNotPatchable,
                   CodeEntryKind entry_kind = CodeEntryKind::kNormal,
                   ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
                       ObjectPoolBuilderEntry::kSnapshotable);

  void JumpAndLinkPatchable(
      const Code& code,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
    JumpAndLink(code, ObjectPoolBuilderEntry::kPatchable, entry_kind,
                snapshot_behavior);
  }

  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void JumpAndLinkWithEquivalence(
      const Code& code,
      const Object& equivalence,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal);

  void Call(Address target);
  void Call(Register target);
  void Call(const Code& code) { JumpAndLink(code); }

  void CallCFunction(Address target) { Call(target); }
  void CallCFunction(Register target) {
    Call(target);
  }

  void AddImmediate(Register dest, intx_t imm) {
    AddImmediate(dest, dest, imm);
  }
  void MulImmediate(Register dest,
                    intx_t imm,
                    OperandSize width = kWordBytes) override {
    MulImmediate(dest, dest, imm, width);
  }
  void AddRegisters(Register dest, Register src) { add(dest, dest, src); }
  // [dest] = [src] << [scale] + [value].
  void AddScaled(Register dest,
                 Register src,
                 ScaleFactor scale,
                 int32_t value) {
    if (scale == 0) {
      AddImmediate(dest, src, value);
    } else {
      slli(dest, src, scale);
      AddImmediate(dest, dest, value);
    }
  }
  void AddShifted(Register dest, Register base, Register index, intx_t shift);
  void SubRegisters(Register dest, Register src) {
    sub(dest, dest, src);
  }

  // Macros accepting a pp Register argument may attempt to load values from
  // the object pool when possible. Unless you are sure that the untagged object
  // pool pointer is in another register, or that it is not available at all,
  // PP should be passed for pp. `dest` can be TMP2, `rn` cannot. `dest` can be
  // TMP.
  void AddImmediate(Register dest,
                    Register rn,
                    intx_t imm,
                    OperandSize sz = kWordBytes);
  void MulImmediate(Register dest,
                    Register rn,
                    intx_t imm,
                    OperandSize width = kWordBytes);
  void AndImmediate(Register rd,
                    Register rn,
                    intx_t imm,
                    OperandSize sz = kWordBytes);
  void AndImmediate(Register rd, intx_t imm) override {
    AndImmediate(rd, rd, imm);
  }
  void AndRegisters(Register dst,
                    Register src1,
                    Register src2 = kNoRegister) override {
    ASSERT(src1 != src2);  // Likely a mistake.
    if (src2 == kNoRegister) {
      src2 = dst;
    }
    and_(dst, src2, src1);
  }
  void OrImmediate(Register rd,
                   Register rn,
                   intx_t imm,
                   OperandSize sz = kWordBytes);
  void OrImmediate(Register rd, intx_t imm) {
    OrImmediate(rd, rd, imm);
  }
  void XorImmediate(Register rd,
                    Register rn,
                    intx_t imm,
                    OperandSize sz = kWordBytes);
  void LslImmediate(Register rd, int32_t shift) {
    slli(rd, rd, shift);
  }
  void LslRegister(Register dst, Register shift) override {
    sll(dst, dst, shift);
  }
  void LsrImmediate(Register rd, int32_t shift) override {
    srli(rd, rd, shift);
  }
  void TestImmediate(Register rn, intx_t imm, OperandSize sz = kWordBytes);
  void CompareImmediate(Register rn,
                        intx_t imm,
                        OperandSize sz = kWordBytes) override;

  Address PrepareLargeOffset(Register base, int32_t offset);
  void LoadFromOffset(Register dest,
                      const Address& address,
                      OperandSize sz = kWordBytes) override;
  void LoadFromOffset(Register dest,
                      Register base,
                      int32_t offset,
                      OperandSize sz = kWordBytes) {
    LoadFromOffset(dest, Address(base, offset), sz);
  }
  void LoadFieldFromOffset(Register dest,
                           Register base,
                           int32_t offset,
                           OperandSize sz = kWordBytes) override {
    LoadFromOffset(dest, base, offset - kHeapObjectTag, sz);
  }
  void LoadCompressedFieldFromOffset(Register dest,
                                     Register base,
                                     int32_t offset) override {
    LoadCompressedFromOffset(dest, base, offset - kHeapObjectTag);
  }
  void LoadCompressedSmiFieldFromOffset(Register dest,
                                        Register base,
                                        int32_t offset) {
    LoadCompressedSmiFromOffset(dest, base, offset - kHeapObjectTag);
  }
  // For loading indexed payloads out of tagged objects like Arrays. If the
  // payload objects are word-sized, use TIMES_HALF_WORD_SIZE if the contents of
  // [index] is a Smi, otherwise TIMES_WORD_SIZE if unboxed.
  void LoadIndexedPayload(Register dest,
                          Register base,
                          int32_t payload_offset,
                          Register index,
                          ScaleFactor scale,
                          OperandSize sz = kWordBytes);
  void LoadIndexedCompressed(Register dest,
                             Register base,
                             int32_t offset,
                             Register index);
  void LoadSFromOffset(FRegister dest, Register base, int32_t offset);
  void LoadDFromOffset(FRegister dest, Register base, int32_t offset);
  void LoadSFieldFromOffset(FRegister dest, Register base, int32_t offset) {
    LoadSFromOffset(dest, base, offset - kHeapObjectTag);
  }
  void LoadDFieldFromOffset(FRegister dest, Register base, int32_t offset) {
    LoadDFromOffset(dest, base, offset - kHeapObjectTag);
  }

  void LoadFromStack(Register dst, intptr_t depth);
  void StoreToStack(Register src, intptr_t depth);
  void CompareToStack(Register src, intptr_t depth);

  void StoreToOffset(Register src,
                     const Address& address,
                     OperandSize sz = kWordBytes) override;
  void StoreToOffset(Register src,
                     Register base,
                     int32_t offset,
                     OperandSize sz = kWordBytes) {
    StoreToOffset(src, Address(base, offset), sz);
  }
  void StoreFieldToOffset(Register src,
                          Register base,
                          int32_t offset,
                          OperandSize sz = kWordBytes) {
    StoreToOffset(src, FieldAddress(base, offset), sz);
  }
  void StoreZero(const Address& address, Register temp = kNoRegister) {
    StoreToOffset(ZR, address);
  }
  void StoreSToOffset(FRegister src, Register base, int32_t offset);
  void StoreSFieldToOffset(FRegister src, Register base, int32_t offset) {
    StoreSToOffset(src, base, offset - kHeapObjectTag);
  }
  void StoreDToOffset(FRegister src, Register base, int32_t offset);
  void StoreDFieldToOffset(FRegister src, Register base, int32_t offset) {
    StoreDToOffset(src, base, offset - kHeapObjectTag);
  }

  void LoadUnboxedDouble(FpuRegister dst, Register base, int32_t offset) {
    LoadDFromOffset(dst, base, offset);
  }
  void StoreUnboxedDouble(FpuRegister src, Register base, int32_t offset) {
    StoreDToOffset(src, base, offset);
  }
  void MoveUnboxedDouble(FpuRegister dst, FpuRegister src) {
    fmvd(dst, src);
  }

  void LoadUnboxedSimd128(FpuRegister dst, Register base, int32_t offset) {
    // No single register SIMD on RISC-V.
    UNREACHABLE();
  }
  void StoreUnboxedSimd128(FpuRegister src, Register base, int32_t offset) {
    // No single register SIMD on RISC-V.
    UNREACHABLE();
  }
  void MoveUnboxedSimd128(FpuRegister dst, FpuRegister src) {
    // No single register SIMD on RISC-V.
    UNREACHABLE();
  }

  void LoadCompressed(Register dest, const Address& slot) {
    LoadFromOffset(dest, slot);
  }
  void LoadCompressedFromOffset(Register dest, Register base, int32_t offset) {
    LoadFromOffset(dest, base, offset);
  }
  void LoadCompressedSmi(Register dest, const Address& slot) override {
    LoadFromOffset(dest, slot);
#if defined(DEBUG)
    Label done;
    BranchIfSmi(dest, &done, kNearJump);
    Stop("Expected Smi");
    Bind(&done);
#endif
  }
  void LoadCompressedSmiFromOffset(Register dest,
                                   Register base,
                                   int32_t offset) {
    LoadFromOffset(dest, base, offset);
  }

  // Store into a heap object and apply the generational and incremental write
  // barriers. All stores into heap objects must pass through this function or,
  // if the value can be proven either Smi or old-and-premarked, its NoBarrier
  // variants.
  // Preserves object and value registers.
  void StoreIntoObject(Register object,
                       const Address& dest,
                       Register value,
                       CanBeSmi can_value_be_smi = kValueCanBeSmi,
                       MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreCompressedIntoObject(
      Register object,
      const Address& dest,
      Register value,
      CanBeSmi can_value_be_smi = kValueCanBeSmi,
      MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreBarrier(Register object, Register value, CanBeSmi can_value_be_smi);
  void StoreIntoArray(Register object,
                      Register slot,
                      Register value,
                      CanBeSmi can_value_be_smi = kValueCanBeSmi);
  void StoreCompressedIntoArray(Register object,
                                Register slot,
                                Register value,
                                CanBeSmi can_value_be_smi = kValueCanBeSmi);
  void StoreIntoArrayBarrier(Register object,
                             Register slot,
                             Register value,
                             CanBeSmi can_value_be_smi);

  void StoreIntoObjectOffset(Register object,
                             int32_t offset,
                             Register value,
                             CanBeSmi can_value_be_smi = kValueCanBeSmi,
                             MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreCompressedIntoObjectOffset(
      Register object,
      int32_t offset,
      Register value,
      CanBeSmi can_value_be_smi = kValueCanBeSmi,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreIntoObjectNoBarrier(
      Register object,
      const Address& dest,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreCompressedIntoObjectNoBarrier(
      Register object,
      const Address& dest,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic) override;
  void StoreIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreCompressedIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      Register value,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value,
                                MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreCompressedIntoObjectNoBarrier(
      Register object,
      const Address& dest,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic);
  void StoreCompressedIntoObjectOffsetNoBarrier(
      Register object,
      int32_t offset,
      const Object& value,
      MemoryOrder memory_order = kRelaxedNonAtomic);

  // Stores a non-tagged value into a heap object.
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value);

  // Object pool, loading from pool, etc.
  void LoadPoolPointer(Register pp = PP);

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

  bool CanLoadFromObjectPool(const Object& object) const;
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable);
  void LoadIsolate(Register dst);
  void LoadIsolateGroup(Register dst);

  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadObject(Register dst, const Object& obj) {
    LoadObjectHelper(dst, obj, false);
  }
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadUniqueObject(
      Register dst,
      const Object& obj,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable) {
    LoadObjectHelper(dst, obj, true, snapshot_behavior);
  }
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadImmediate(Register reg, intx_t imm);

  void LoadSImmediate(FRegister reg, float imms);
  void LoadDImmediate(FRegister reg, double immd);
  void LoadQImmediate(FRegister reg, simd128_value_t immq);

  // Load word from pool from the given offset using encoding that
  // InstructionPattern::DecodeLoadWordFromPool can decode.
  //
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadWordFromPoolIndex(Register dst, intptr_t index, Register pp = PP);

  void PushObject(const Object& object) {
    if (IsSameObject(compiler::NullObject(), object)) {
      PushRegister(NULL_REG);
    } else if (target::IsSmi(object) && (target::ToRawSmi(object) == 0)) {
      PushRegister(ZR);
    } else {
      LoadObject(TMP, object);
      PushRegister(TMP);
    }
  }
  void PushImmediate(int64_t immediate) {
    if (immediate == 0) {
      PushRegister(ZR);
    } else {
      LoadImmediate(TMP, immediate);
      PushRegister(TMP);
    }
  }
  void CompareObject(Register reg, const Object& object);

  void ExtractClassIdFromTags(Register result, Register tags);
  void ExtractInstanceSizeFromTags(Register result, Register tags);

  void RangeCheck(Register value,
                  Register temp,
                  intptr_t low,
                  intptr_t high,
                  RangeCheckCondition condition,
                  Label* target) override;

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch = kNoRegister);
  // Note: input and output registers must be different.
  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);
  void EnsureHasClassIdInDEBUG(intptr_t cid,
                               Register src,
                               Register scratch,
                               bool can_be_null = false) override;

  void EnterFrame(intptr_t frame_size);
  void LeaveFrame();
  void Ret() { ret(); }

  // Sets the return address to [value] as if there was a call.
  // On RISC-V sets RA.
  void SetReturnAddress(Register value) {
    mv(RA, value);
  }

  // Emit code to transition between generated mode and native mode.
  //
  // These require and ensure that CSP and SP are equal and aligned and require
  // a scratch register (in addition to TMP/TMP2).

  void TransitionGeneratedToNative(Register destination_address,
                                   Register new_exit_frame,
                                   Register new_exit_through_ffi,
                                   bool enter_safepoint);
  void TransitionNativeToGenerated(Register scratch,
                                   bool exit_safepoint,
                                   bool ignore_unwind_in_progress = false);
  void EnterFullSafepoint(Register scratch);
  void ExitFullSafepoint(Register scratch, bool ignore_unwind_in_progress);

  void CheckFpSpDist(intptr_t fp_sp_dist);

  void CheckCodePointer();
  void RestoreCodePointer();
  void RestorePoolPointer();

  // Restores the values of the registers that are blocked to cache some values
  // e.g. WRITE_BARRIER_STATE and NULL_REG.
  void RestorePinnedRegisters();

  void SetupGlobalPoolAndDispatchTable();

  void EnterDartFrame(intptr_t frame_size, Register new_pp = kNoRegister);
  void EnterOsrFrame(intptr_t extra_size, Register new_pp = kNoRegister);
  void LeaveDartFrame();
  void LeaveDartFrame(intptr_t fp_sp_dist);

  // For non-leaf runtime calls. For leaf runtime calls, use LeafRuntimeScope,
  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame() { EnterDartFrame(0); }
  void LeaveStubFrame() { LeaveDartFrame(); }

  // Set up a frame for calling a C function.
  // Automatically save the pinned registers in Dart which are not callee-
  // saved in the native calling convention.
  // Use together with CallCFunction.
  void EnterCFrame(intptr_t frame_space);
  void LeaveCFrame();

  void MonomorphicCheckedEntryJIT();
  void MonomorphicCheckedEntryAOT();
  void BranchOnMonomorphicCheckedEntryJIT(Label* label);

  void CombineHashes(Register dst, Register other) override;
  void FinalizeHashForSize(intptr_t bit_size,
                           Register dst,
                           Register scratch = TMP) override;

  // If allocation tracing for |cid| is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(intptr_t cid,
                            Label* trace,
                            Register temp_reg,
                            JumpDistance distance = JumpDistance::kFarJump);

  void TryAllocateObject(intptr_t cid,
                         intptr_t instance_size,
                         Label* failure,
                         JumpDistance distance,
                         Register instance_reg,
                         Register temp_reg) override;

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2);

  void CheckAllocationCanary(Register top, Register tmp = TMP) {
#if defined(DEBUG)
    Label okay;
    lx(tmp, Address(top, 0));
    subi(tmp, tmp, kAllocationCanary);
    beqz(tmp, &okay, Assembler::kNearJump);
    Stop("Allocation canary");
    Bind(&okay);
#endif
  }
  void WriteAllocationCanary(Register top) {
#if defined(DEBUG)
    ASSERT(top != TMP);
    li(TMP, kAllocationCanary);
    sx(TMP, Address(top, 0));
#endif
  }

  // Copy [size] bytes from [src] address to [dst] address.
  // [size] should be a multiple of word size.
  // Clobbers [src], [dst], [size] and [temp] registers.
  void CopyMemoryWords(Register src,
                       Register dst,
                       Register size,
                       Register temp);

  // This emits an PC-relative call of the form "bl <offset>".  The offset
  // is not yet known and needs therefore relocation to the right place before
  // the code can be used.
  //
  // The necessary information for the "linker" (i.e. the relocation
  // information) is stored in [UntaggedCode::static_calls_target_table_]: an
  // entry of the form
  //
  //   (Code::kPcRelativeCall & pc_offset, <target-code>, <target-function>)
  //
  // will be used during relocation to fix the offset.
  //
  // The provided [offset_into_target] will be added to calculate the final
  // destination.  It can be used e.g. for calling into the middle of a
  // function.
  void GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target = 0);

  // This emits an PC-relative tail call of the form "b <offset>".
  //
  // See also above for the pc-relative call.
  void GenerateUnRelocatedPcRelativeTailCall(intptr_t offset_into_target = 0);

  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const;
  void ComputeElementAddressForIntIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        Register array,
                                        intptr_t index);
  Address ElementAddressForRegIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    bool index_unboxed,
                                    Register array,
                                    Register index,
                                    Register temp);

  // Special version of ElementAddressForRegIndex for the case when cid and
  // operand size for the target load don't match (e.g. when loading a few
  // elements of the array with one load).
  Address ElementAddressForRegIndexWithSize(bool is_external,
                                            intptr_t cid,
                                            OperandSize size,
                                            intptr_t index_scale,
                                            bool index_unboxed,
                                            Register array,
                                            Register index,
                                            Register temp);

  void ComputeElementAddressForRegIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        bool index_unboxed,
                                        Register array,
                                        Register index);

  void LoadStaticFieldAddress(Register address,
                              Register field,
                              Register scratch);

  void LoadCompressedFieldAddressForRegOffset(Register address,
                                              Register instance,
                                              Register offset_in_words_as_smi);

  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi);

  void LoadFieldAddressForOffset(Register address,
                                 Register instance,
                                 int32_t offset) override {
    AddImmediate(address, instance, offset - kHeapObjectTag);
  }

  // Returns object data offset for address calculation; for heap objects also
  // accounts for the tag.
  static int32_t HeapDataOffset(bool is_external, intptr_t cid) {
    return is_external
               ? 0
               : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag);
  }

  void AddImmediateBranchOverflow(Register rd,
                                  Register rs1,
                                  intx_t imm,
                                  Label* overflow);
  void SubtractImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow);
  void MultiplyImmediateBranchOverflow(Register rd,
                                       Register rs1,
                                       intx_t imm,
                                       Label* overflow);
  void AddBranchOverflow(Register rd,
                         Register rs1,
                         Register rs2,
                         Label* overflow);
  void SubtractBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow);
  void MultiplyBranchOverflow(Register rd,
                              Register rs1,
                              Register rs2,
                              Label* overflow);

  // Clobbers [rs].
  void CountLeadingZeroes(Register rd, Register rs);

 private:
  bool constant_pool_allowed_;

  enum DeferredCompareType {
    kNone,
    kCompareReg,
    kCompareImm,
    kTestReg,
    kTestImm,
  };
  DeferredCompareType deferred_compare_ = kNone;
  Register deferred_left_ = kNoRegister;
  Register deferred_reg_ = kNoRegister;
  intptr_t deferred_imm_ = 0;

  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadObjectHelper(
      Register dst,
      const Object& obj,
      bool is_unique,
      ObjectPoolBuilderEntry::SnapshotBehavior snapshot_behavior =
          ObjectPoolBuilderEntry::kSnapshotable);

  friend class dart::FlowGraphCompiler;
  std::function<void(Register reg)> generate_invoke_write_barrier_wrapper_;
  std::function<void()> generate_invoke_array_write_barrier_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_RISCV_H_
