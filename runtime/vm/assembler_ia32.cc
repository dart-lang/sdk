// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/cpu.h"
#include "vm/heap.h"
#include "vm/memory_region.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");
DECLARE_FLAG(bool, inline_alloc);


class DirectCallRelocation : public AssemblerFixup {
 public:
  void Process(const MemoryRegion& region, intptr_t position) {
    // Direct calls are relative to the following instruction on x86.
    int32_t pointer = region.Load<int32_t>(position);
    int32_t delta = region.start() + position + sizeof(int32_t);
    region.Store<int32_t>(position, pointer - delta);
  }

  virtual bool IsPointerOffset() const { return false; }
};


int32_t Assembler::jit_cookie() {
  if (jit_cookie_ == 0) {
    jit_cookie_ = static_cast<int32_t>(
        Isolate::Current()->random()->NextUInt32());
  }
  return jit_cookie_;
}


void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
  memset(reinterpret_cast<void*>(data), Instr::kBreakPointInstruction, length);
}


void Assembler::call(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitRegisterOperand(2, reg);
}


void Assembler::call(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitOperand(2, address);
}


void Assembler::call(Label* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xE8);
  static const int kSize = 5;
  EmitLabel(label, kSize);
}


void Assembler::call(const ExternalLabel* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  intptr_t call_start = buffer_.GetPosition();
  EmitUint8(0xE8);
  EmitFixup(new DirectCallRelocation());
  EmitInt32(label->address());
  ASSERT((buffer_.GetPosition() - call_start) == kCallExternalLabelSize);
}


void Assembler::pushl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x50 + reg);
}


void Assembler::pushl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitOperand(6, address);
}


void Assembler::pushl(const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x68);
  EmitImmediate(imm);
}


void Assembler::popl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x58 + reg);
}


void Assembler::popl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x8F);
  EmitOperand(0, address);
}


void Assembler::pushal() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x60);
}


void Assembler::popal() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x61);
}


void Assembler::setcc(Condition condition, ByteRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x90 + condition);
  EmitUint8(0xC0 + dst);
}


void Assembler::movl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xB8 + dst);
  EmitImmediate(imm);
}


void Assembler::movl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x89);
  EmitRegisterOperand(src, dst);
}


void Assembler::movl(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x8B);
  EmitOperand(dst, src);
}


void Assembler::movl(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x89);
  EmitOperand(src, dst);
}


void Assembler::movl(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC7);
  EmitOperand(0, dst);
  EmitImmediate(imm);
}


void Assembler::movzxb(Register dst, ByteRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xB6);
  EmitRegisterOperand(dst, src);
}


void Assembler::movzxb(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xB6);
  EmitOperand(dst, src);
}


void Assembler::movsxb(Register dst, ByteRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBE);
  EmitRegisterOperand(dst, src);
}


void Assembler::movsxb(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBE);
  EmitOperand(dst, src);
}


void Assembler::movb(Register dst, const Address& src) {
  FATAL("Use movzxb or movsxb instead.");
}


void Assembler::movb(const Address& dst, ByteRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x88);
  EmitOperand(src, dst);
}


void Assembler::movb(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC6);
  EmitOperand(EAX, dst);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
}


void Assembler::movzxw(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xB7);
  EmitRegisterOperand(dst, src);
}


void Assembler::movzxw(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xB7);
  EmitOperand(dst, src);
}


void Assembler::movsxw(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBF);
  EmitRegisterOperand(dst, src);
}


void Assembler::movsxw(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBF);
  EmitOperand(dst, src);
}


void Assembler::movw(Register dst, const Address& src) {
  FATAL("Use movzxw or movsxw instead.");
}


void Assembler::movw(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitUint8(0x89);
  EmitOperand(src, dst);
}


void Assembler::leal(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x8D);
  EmitOperand(dst, src);
}


void Assembler::cmovs(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x48);
  EmitRegisterOperand(dst, src);
}


void Assembler::cmovns(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x49);
  EmitRegisterOperand(dst, src);
}


void Assembler::cmovgel(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x4D);
  EmitRegisterOperand(dst, src);
}


void Assembler::cmovlessl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x4C);
  EmitRegisterOperand(dst, src);
}


void Assembler::rep_movsb() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0xA4);
}


void Assembler::movss(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst, src);
}


void Assembler::movss(const Address& dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src, dst);
}


void Assembler::movss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src, dst);
}


void Assembler::movd(XmmRegister dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x6E);
  EmitOperand(dst, Operand(src));
}


void Assembler::movd(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x7E);
  EmitOperand(src, Operand(dst));
}


void Assembler::movq(const Address& dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xD6);
  EmitOperand(src, Operand(dst));
}


void Assembler::movq(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x7E);
  EmitOperand(dst, Operand(src));
}


void Assembler::addss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::addss(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitOperand(dst, src);
}


void Assembler::subss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subss(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitOperand(dst, src);
}


void Assembler::mulss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulss(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitOperand(dst, src);
}


void Assembler::divss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divss(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitOperand(dst, src);
}


void Assembler::flds(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitOperand(0, src);
}


void Assembler::fstps(const Address& dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitOperand(3, dst);
}


void Assembler::movsd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst, src);
}


void Assembler::movsd(const Address& dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src, dst);
}


void Assembler::movsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src, dst);
}


void Assembler::movaps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x28);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::movups(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst, src);
}


void Assembler::movups(const Address& dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src, dst);
}


void Assembler::addsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::addsd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitOperand(dst, src);
}


void Assembler::addpl(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xFE);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subpl(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xFA);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::addps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::minps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x5D);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::maxps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x5F);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::andps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::andps(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitOperand(dst, src);
}


void Assembler::orps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x56);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::notps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_not_constant =
      { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
  xorps(dst,
    Address::Absolute(reinterpret_cast<uword>(&float_not_constant)));
}


void Assembler::negateps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_negate_constant =
      { 0x80000000, 0x80000000, 0x80000000, 0x80000000 };
  xorps(dst,
        Address::Absolute(reinterpret_cast<uword>(&float_negate_constant)));
}


void Assembler::absps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_absolute_constant =
      { 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF };
  andps(dst,
        Address::Absolute(reinterpret_cast<uword>(&float_absolute_constant)));
}


void Assembler::zerowps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_zerow_constant =
      { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000 };
  andps(dst, Address::Absolute(reinterpret_cast<uword>(&float_zerow_constant)));
}


void Assembler::cmppseq(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x0);
}


void Assembler::cmppsneq(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x4);
}


void Assembler::cmppslt(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x1);
}


void Assembler::cmppsle(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x2);
}


void Assembler::cmppsnlt(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x5);
}


void Assembler::cmppsnle(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst, src);
  EmitUint8(0x6);
}


void Assembler::sqrtps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst, dst);
}


void Assembler::rsqrtps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x52);
  EmitXmmRegisterOperand(dst, dst);
}


void Assembler::reciprocalps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x53);
  EmitXmmRegisterOperand(dst, dst);
}


void Assembler::movhlps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x12);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::movlhps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x16);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::unpcklps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x14);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::unpckhps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x15);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::unpcklpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x14);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::unpckhpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x15);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::set1ps(XmmRegister dst, Register tmp1, const Immediate& imm) {
  // Load 32-bit immediate value into tmp1.
  movl(tmp1, imm);
  // Move value from tmp1 into dst.
  movd(dst, tmp1);
  // Broadcast low lane into other three lanes.
  shufps(dst, dst, Immediate(0x0));
}


void Assembler::shufps(XmmRegister dst, XmmRegister src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xC6);
  EmitXmmRegisterOperand(dst, src);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}


void Assembler::addpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::negatepd(XmmRegister dst) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_negate_constant =
      { 0x8000000000000000LL, 0x8000000000000000LL };
  xorpd(dst,
        Address::Absolute(reinterpret_cast<uword>(&double_negate_constant)));
}


void Assembler::subpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::abspd(XmmRegister dst) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_absolute_constant =
      { 0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL };
  andpd(dst,
        Address::Absolute(reinterpret_cast<uword>(&double_absolute_constant)));
}


void Assembler::minpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x5D);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::maxpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x5F);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::sqrtpd(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst, dst);
}


void Assembler::cvtps2pd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvtpd2ps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::shufpd(XmmRegister dst, XmmRegister src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xC6);
  EmitXmmRegisterOperand(dst, src);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}


void Assembler::subsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subsd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitOperand(dst, src);
}


void Assembler::mulsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulsd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitOperand(dst, src);
}


void Assembler::divsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divsd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitOperand(dst, src);
}


void Assembler::cvtsi2ss(XmmRegister dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x2A);
  EmitOperand(dst, Operand(src));
}


void Assembler::cvtsi2sd(XmmRegister dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x2A);
  EmitOperand(dst, Operand(src));
}


void Assembler::cvtss2si(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x2D);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvtss2sd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvtsd2si(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x2D);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvttss2si(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x2C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvttsd2si(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x2C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvtsd2ss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::cvtdq2pd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0xE6);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::comiss(XmmRegister a, XmmRegister b) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x2F);
  EmitXmmRegisterOperand(a, b);
}


void Assembler::comisd(XmmRegister a, XmmRegister b) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x2F);
  EmitXmmRegisterOperand(a, b);
}


void Assembler::movmskpd(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x50);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::movmskps(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x50);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::sqrtsd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::sqrtss(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::xorpd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitOperand(dst, src);
}


void Assembler::xorpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::orpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x56);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::xorps(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitOperand(dst, src);
}


void Assembler::xorps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::andpd(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitOperand(dst, src);
}


void Assembler::andpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::pextrd(Register dst, XmmRegister src, const Immediate& imm) {
  ASSERT(TargetCPUFeatures::sse4_1_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x3A);
  EmitUint8(0x16);
  EmitOperand(src, Operand(dst));
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}


void Assembler::pmovsxdq(XmmRegister dst, XmmRegister src) {
  ASSERT(TargetCPUFeatures::sse4_1_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x38);
  EmitUint8(0x25);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::pcmpeqq(XmmRegister dst, XmmRegister src) {
  ASSERT(TargetCPUFeatures::sse4_1_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x38);
  EmitUint8(0x29);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::pxor(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xEF);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::roundsd(XmmRegister dst, XmmRegister src, RoundingMode mode) {
  ASSERT(TargetCPUFeatures::sse4_1_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x3A);
  EmitUint8(0x0B);
  EmitXmmRegisterOperand(dst, src);
  // Mask precision exeption.
  EmitUint8(static_cast<uint8_t>(mode) | 0x8);
}


void Assembler::fldl(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDD);
  EmitOperand(0, src);
}


void Assembler::fstpl(const Address& dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDD);
  EmitOperand(3, dst);
}


void Assembler::fnstcw(const Address& dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitOperand(7, dst);
}


void Assembler::fldcw(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitOperand(5, src);
}


void Assembler::fistpl(const Address& dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDF);
  EmitOperand(7, dst);
}


void Assembler::fistps(const Address& dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDB);
  EmitOperand(3, dst);
}


void Assembler::fildl(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDF);
  EmitOperand(5, src);
}


void Assembler::filds(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDB);
  EmitOperand(0, src);
}


void Assembler::fincstp() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitUint8(0xF7);
}


void Assembler::ffree(intptr_t value) {
  ASSERT(value < 7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDD);
  EmitUint8(0xC0 + value);
}


void Assembler::fsin() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitUint8(0xFE);
}


void Assembler::fcos() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitUint8(0xFF);
}


void Assembler::fsincos() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitUint8(0xFB);
}


void Assembler::fptan() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xD9);
  EmitUint8(0xF2);
}


void Assembler::xchgl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x87);
  EmitRegisterOperand(dst, src);
}


void Assembler::cmpl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(7, Operand(reg), imm);
}


void Assembler::cmpl(Register reg0, Register reg1) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x3B);
  EmitOperand(reg0, Operand(reg1));
}


void Assembler::cmpl(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x3B);
  EmitOperand(reg, address);
}


void Assembler::addl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x03);
  EmitRegisterOperand(dst, src);
}


void Assembler::addl(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x03);
  EmitOperand(reg, address);
}


void Assembler::cmpl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x39);
  EmitOperand(reg, address);
}


void Assembler::cmpl(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(7, address, imm);
}


void Assembler::testl(Register reg1, Register reg2) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x85);
  EmitRegisterOperand(reg1, reg2);
}


void Assembler::testl(Register reg, const Immediate& immediate) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  // For registers that have a byte variant (EAX, EBX, ECX, and EDX)
  // we only test the byte register to keep the encoding short.
  if (immediate.is_uint8() && reg < 4) {
    // Use zero-extended 8-bit immediate.
    if (reg == EAX) {
      EmitUint8(0xA8);
    } else {
      EmitUint8(0xF6);
      EmitUint8(0xC0 + reg);
    }
    EmitUint8(immediate.value() & 0xFF);
  } else if (reg == EAX) {
    // Use short form if the destination is EAX.
    EmitUint8(0xA9);
    EmitImmediate(immediate);
  } else {
    EmitUint8(0xF7);
    EmitOperand(0, Operand(reg));
    EmitImmediate(immediate);
  }
}


void Assembler::andl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x23);
  EmitOperand(dst, Operand(src));
}


void Assembler::andl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(4, Operand(dst), imm);
}


void Assembler::andl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x23);
  EmitOperand(dst, address);
}


void Assembler::orl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0B);
  EmitOperand(dst, Operand(src));
}


void Assembler::orl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(1, Operand(dst), imm);
}


void Assembler::orl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0B);
  EmitOperand(dst, address);
}


void Assembler::xorl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x33);
  EmitOperand(dst, Operand(src));
}


void Assembler::xorl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(6, Operand(dst), imm);
}


void Assembler::xorl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x33);
  EmitOperand(dst, address);
}


void Assembler::addl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(0, Operand(reg), imm);
}


void Assembler::addl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x01);
  EmitOperand(reg, address);
}


void Assembler::addl(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(0, address, imm);
}


void Assembler::adcl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(2, Operand(reg), imm);
}


void Assembler::adcl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x13);
  EmitOperand(dst, Operand(src));
}


void Assembler::adcl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x13);
  EmitOperand(dst, address);
}


void Assembler::adcl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x11);
  EmitOperand(reg, address);
}


void Assembler::subl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x2B);
  EmitOperand(dst, Operand(src));
}


void Assembler::subl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(5, Operand(reg), imm);
}


void Assembler::subl(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x2B);
  EmitOperand(reg, address);
}


void Assembler::subl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x29);
  EmitOperand(reg, address);
}


void Assembler::cdq() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x99);
}


void Assembler::idivl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitUint8(0xF8 | reg);
}


void Assembler::imull(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(dst, Operand(src));
}


void Assembler::imull(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x69);
  EmitOperand(reg, Operand(reg));
  EmitImmediate(imm);
}


void Assembler::imull(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(reg, address);
}


void Assembler::imull(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(5, Operand(reg));
}


void Assembler::imull(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(5, address);
}


void Assembler::mull(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(4, Operand(reg));
}


void Assembler::mull(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(4, address);
}


void Assembler::sbbl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x1B);
  EmitOperand(dst, Operand(src));
}


void Assembler::sbbl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(3, Operand(reg), imm);
}


void Assembler::sbbl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x1B);
  EmitOperand(dst, address);
}


void Assembler::sbbl(const Address& address, Register dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x19);
  EmitOperand(dst, address);
}


void Assembler::incl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x40 + reg);
}


void Assembler::incl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitOperand(0, address);
}


void Assembler::decl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x48 + reg);
}


void Assembler::decl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitOperand(1, address);
}


void Assembler::shll(Register reg, const Immediate& imm) {
  EmitGenericShift(4, reg, imm);
}


void Assembler::shll(Register operand, Register shifter) {
  EmitGenericShift(4, Operand(operand), shifter);
}


void Assembler::shll(const Address& operand, Register shifter) {
  EmitGenericShift(4, Operand(operand), shifter);
}


void Assembler::shrl(Register reg, const Immediate& imm) {
  EmitGenericShift(5, reg, imm);
}


void Assembler::shrl(Register operand, Register shifter) {
  EmitGenericShift(5, Operand(operand), shifter);
}


void Assembler::sarl(Register reg, const Immediate& imm) {
  EmitGenericShift(7, reg, imm);
}


void Assembler::sarl(Register operand, Register shifter) {
  EmitGenericShift(7, Operand(operand), shifter);
}


void Assembler::sarl(const Address& address, Register shifter) {
  EmitGenericShift(7, Operand(address), shifter);
}


void Assembler::shld(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA5);
  EmitRegisterOperand(src, dst);
}


void Assembler::shld(const Address& operand, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA5);
  EmitOperand(src, Operand(operand));
}

void Assembler::shrd(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xAD);
  EmitRegisterOperand(src, dst);
}


void Assembler::shrd(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xAD);
  EmitOperand(src, Operand(dst));
}


void Assembler::negl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(3, Operand(reg));
}


void Assembler::notl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitUint8(0xD0 | reg);
}


void Assembler::bsrl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBD);
  EmitRegisterOperand(dst, src);
}


void Assembler::enter(const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC8);
  ASSERT(imm.is_uint16());
  EmitUint8(imm.value() & 0xFF);
  EmitUint8((imm.value() >> 8) & 0xFF);
  EmitUint8(0x00);
}


void Assembler::leave() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC9);
}


void Assembler::ret() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC3);
}


void Assembler::ret(const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xC2);
  ASSERT(imm.is_uint16());
  EmitUint8(imm.value() & 0xFF);
  EmitUint8((imm.value() >> 8) & 0xFF);
}


void Assembler::nop(int size) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  // There are nops up to size 15, but for now just provide up to size 8.
  ASSERT(0 < size && size <= MAX_NOP_SIZE);
  switch (size) {
    case 1:
      EmitUint8(0x90);
      break;
    case 2:
      EmitUint8(0x66);
      EmitUint8(0x90);
      break;
    case 3:
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x00);
      break;
    case 4:
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x40);
      EmitUint8(0x00);
      break;
    case 5:
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x44);
      EmitUint8(0x00);
      EmitUint8(0x00);
      break;
    case 6:
      EmitUint8(0x66);
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x44);
      EmitUint8(0x00);
      EmitUint8(0x00);
      break;
    case 7:
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x80);
      EmitUint8(0x00);
      EmitUint8(0x00);
      EmitUint8(0x00);
      EmitUint8(0x00);
      break;
    case 8:
      EmitUint8(0x0F);
      EmitUint8(0x1F);
      EmitUint8(0x84);
      EmitUint8(0x00);
      EmitUint8(0x00);
      EmitUint8(0x00);
      EmitUint8(0x00);
      EmitUint8(0x00);
      break;
    default:
      UNIMPLEMENTED();
  }
}


void Assembler::int3() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xCC);
}


void Assembler::hlt() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF4);
}


void Assembler::j(Condition condition, Label* label, bool near) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (label->IsBound()) {
    static const int kShortSize = 2;
    static const int kLongSize = 6;
    intptr_t offset = label->Position() - buffer_.Size();
    ASSERT(offset <= 0);
    if (Utils::IsInt(8, offset - kShortSize)) {
      EmitUint8(0x70 + condition);
      EmitUint8((offset - kShortSize) & 0xFF);
    } else {
      EmitUint8(0x0F);
      EmitUint8(0x80 + condition);
      EmitInt32(offset - kLongSize);
    }
  } else if (near) {
    EmitUint8(0x70 + condition);
    EmitNearLabelLink(label);
  } else {
    EmitUint8(0x0F);
    EmitUint8(0x80 + condition);
    EmitLabelLink(label);
  }
}


void Assembler::j(Condition condition, const ExternalLabel* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x80 + condition);
  EmitFixup(new DirectCallRelocation());
  EmitInt32(label->address());
}


void Assembler::jmp(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitRegisterOperand(4, reg);
}


void Assembler::jmp(Label* label, bool near) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (label->IsBound()) {
    static const int kShortSize = 2;
    static const int kLongSize = 5;
    intptr_t offset = label->Position() - buffer_.Size();
    ASSERT(offset <= 0);
    if (Utils::IsInt(8, offset - kShortSize)) {
      EmitUint8(0xEB);
      EmitUint8((offset - kShortSize) & 0xFF);
    } else {
      EmitUint8(0xE9);
      EmitInt32(offset - kLongSize);
    }
  } else if (near) {
    EmitUint8(0xEB);
    EmitNearLabelLink(label);
  } else {
    EmitUint8(0xE9);
    EmitLabelLink(label);
  }
}


void Assembler::jmp(const ExternalLabel* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xE9);
  EmitFixup(new DirectCallRelocation());
  EmitInt32(label->address());
}


void Assembler::lock() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF0);
}


void Assembler::cmpxchgl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xB1);
  EmitOperand(reg, address);
}


void Assembler::cpuid() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA2);
}


void Assembler::CompareRegisters(Register a, Register b) {
  cmpl(a, b);
}


void Assembler::MoveRegister(Register to, Register from) {
  if (to != from) {
    movl(to, from);
  }
}


void Assembler::PopRegister(Register r) {
  popl(r);
}


void Assembler::AddImmediate(Register reg, const Immediate& imm) {
  const intptr_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt32)) {
    if (value == 1) {
      incl(reg);
    } else {
      addl(reg, imm);
    }
  } else {
    SubImmediate(reg, Immediate(-value));
  }
}


void Assembler::SubImmediate(Register reg, const Immediate& imm) {
  const intptr_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt32)) {
    if (value == 1) {
      decl(reg);
    } else {
      subl(reg, imm);
    }
  } else {
    AddImmediate(reg, Immediate(-value));
  }
}


void Assembler::Drop(intptr_t stack_elements) {
  ASSERT(stack_elements >= 0);
  if (stack_elements > 0) {
    addl(ESP, Immediate(stack_elements * kWordSize));
  }
}


void Assembler::LoadObject(Register dst, const Object& object) {
  if (object.IsSmi() || object.InVMHeap()) {
    movl(dst, Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsNotTemporaryScopedHandle());
    ASSERT(object.IsOld());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xB8 + dst);
    buffer_.EmitObject(object);
  }
}


void Assembler::LoadObjectSafely(Register dst, const Object& object) {
  if (Assembler::IsSafe(object)) {
    LoadObject(dst, object);
  } else {
    int32_t cookie = jit_cookie();
    movl(dst, Immediate(reinterpret_cast<int32_t>(object.raw()) ^ cookie));
    xorl(dst, Immediate(cookie));
  }
}


void Assembler::PushObject(const Object& object) {
  if (object.IsSmi() || object.InVMHeap()) {
    pushl(Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsNotTemporaryScopedHandle());
    ASSERT(object.IsOld());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0x68);
    buffer_.EmitObject(object);
  }
}


void Assembler::CompareObject(Register reg, const Object& object) {
  if (object.IsSmi() || object.InVMHeap()) {
    cmpl(reg, Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsNotTemporaryScopedHandle());
    ASSERT(object.IsOld());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    if (reg == EAX) {
      EmitUint8(0x05 + (7 << 3));
      buffer_.EmitObject(object);
    } else {
      EmitUint8(0x81);
      EmitOperand(7, Operand(reg));
      buffer_.EmitObject(object);
    }
  }
}


// Destroys the value register.
void Assembler::StoreIntoObjectFilterNoSmi(Register object,
                                           Register value,
                                           Label* no_update) {
  COMPILE_ASSERT((kNewObjectAlignmentOffset == kWordSize) &&
                 (kOldObjectAlignmentOffset == 0));

  // Write-barrier triggers if the value is in the new space (has bit set) and
  // the object is in the old space (has bit cleared).
  // To check that we could compute value & ~object and skip the write barrier
  // if the bit is not set. However we can't destroy the object.
  // However to preserve the object we compute negated expression
  // ~value | object instead and skip the write barrier if the bit is set.
  notl(value);
  orl(value, object);
  testl(value, Immediate(kNewObjectAlignmentOffset));
  j(NOT_ZERO, no_update, Assembler::kNearJump);
}


// Destroys the value register.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* no_update) {
  // For the value we are only interested in the new/old bit and the tag bit.
  andl(value, Immediate(kNewObjectAlignmentOffset | kHeapObjectTag));
  // Shift the tag bit into the carry.
  shrl(value, Immediate(1));
  // Add the tag bits together, if the value is not a Smi the addition will
  // overflow into the next bit, leaving us with a zero low bit.
  adcl(value, object);
  // Mask out higher, uninteresting bits which were polluted by dest.
  andl(value, Immediate(kObjectAlignment - 1));
  // Compare with the expected bit pattern.
  cmpl(value, Immediate(
      (kNewObjectAlignmentOffset >> 1) + kHeapObjectTag +
      kOldObjectAlignmentOffset + kHeapObjectTag));
  j(NOT_ZERO, no_update, Assembler::kNearJump);
}


// Destroys the value register.
void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                bool can_value_be_smi) {
  ASSERT(object != value);
  movl(dest, value);
  Label done;
  if (can_value_be_smi) {
    StoreIntoObjectFilter(object, value, &done);
  } else {
    StoreIntoObjectFilterNoSmi(object, value, &done);
  }
  // A store buffer update is required.
  if (value != EAX) pushl(EAX);  // Preserve EAX.
  if (object != EAX) {
    movl(EAX, object);
  }
  StubCode* stub_code = Isolate::Current()->stub_code();
  call(&stub_code->UpdateStoreBufferLabel());
  if (value != EAX) popl(EAX);  // Restore EAX.
  Bind(&done);
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  movl(dest, value);
#if defined(DEBUG)
  Label done;
  pushl(value);
  StoreIntoObjectFilter(object, value, &done);
  Stop("Store buffer update is required");
  Bind(&done);
  popl(value);
#endif  // defined(DEBUG)
  // No store buffer update.
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  if (value.IsSmi() || value.InVMHeap()) {
    movl(dest, Immediate(reinterpret_cast<int32_t>(value.raw())));
  } else {
    ASSERT(value.IsOld());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xC7);
    EmitOperand(0, dest);
    buffer_.EmitObject(value);
  }
  // No store buffer update.
}


void Assembler::LoadDoubleConstant(XmmRegister dst, double value) {
  // TODO(5410843): Need to have a code constants table.
  int64_t constant = bit_cast<int64_t, double>(value);
  pushl(Immediate(Utils::High32Bits(constant)));
  pushl(Immediate(Utils::Low32Bits(constant)));
  movsd(dst, Address(ESP, 0));
  addl(ESP, Immediate(2 * kWordSize));
}


void Assembler::FloatNegate(XmmRegister f) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_negate_constant =
      { 0x80000000, 0x00000000, 0x80000000, 0x00000000 };
  xorps(f, Address::Absolute(reinterpret_cast<uword>(&float_negate_constant)));
}


void Assembler::DoubleNegate(XmmRegister d) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_negate_constant =
      {0x8000000000000000LL, 0x8000000000000000LL};
  xorpd(d, Address::Absolute(reinterpret_cast<uword>(&double_negate_constant)));
}


void Assembler::DoubleAbs(XmmRegister reg) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_abs_constant =
      {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL};
  andpd(reg, Address::Absolute(reinterpret_cast<uword>(&double_abs_constant)));
}


void Assembler::EnterFrame(intptr_t frame_size) {
  if (prologue_offset_ == -1) {
    prologue_offset_ = CodeSize();
  }
  pushl(EBP);
  movl(EBP, ESP);
  if (frame_size != 0) {
    Immediate frame_space(frame_size);
    subl(ESP, frame_space);
  }
}


void Assembler::LeaveFrame() {
  movl(ESP, EBP);
  popl(EBP);
}


void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  AddImmediate(ESP, Immediate(-frame_space));
  if (OS::ActivationFrameAlignment() > 1) {
    andl(ESP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }
}


static const intptr_t kNumberOfVolatileCpuRegisters = 3;
static const Register volatile_cpu_registers[kNumberOfVolatileCpuRegisters] = {
    EAX, ECX, EDX
};


// XMM0 is used only as a scratch register in the optimized code. No need to
// save it.
static const intptr_t kNumberOfVolatileXmmRegisters =
    kNumberOfXmmRegisters - 1;


void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  EnterFrame(0);

  // Preserve volatile CPU registers.
  for (intptr_t i = 0; i < kNumberOfVolatileCpuRegisters; i++) {
    pushl(volatile_cpu_registers[i]);
  }

  // Preserve all XMM registers except XMM0
  subl(ESP, Immediate((kNumberOfXmmRegisters - 1) * kFpuRegisterSize));
  // Store XMM registers with the lowest register number at the lowest
  // address.
  intptr_t offset = 0;
  for (intptr_t reg_idx = 1; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    movups(Address(ESP, offset), xmm_reg);
    offset += kFpuRegisterSize;
  }

  ReserveAlignedFrameSpace(frame_space);
}


void Assembler::LeaveCallRuntimeFrame() {
  // ESP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t kPushedRegistersSize =
      kNumberOfVolatileCpuRegisters * kWordSize +
      kNumberOfVolatileXmmRegisters * kFpuRegisterSize;
  leal(ESP, Address(EBP, -kPushedRegistersSize));

  // Restore all XMM registers except XMM0
  // XMM registers have the lowest register number at the lowest address.
  intptr_t offset = 0;
  for (intptr_t reg_idx = 1; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
    XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
    movups(xmm_reg, Address(ESP, offset));
    offset += kFpuRegisterSize;
  }
  addl(ESP, Immediate(offset));

  // Restore volatile CPU registers.
  for (intptr_t i = kNumberOfVolatileCpuRegisters - 1; i >= 0; i--) {
    popl(volatile_cpu_registers[i]);
  }

  leave();
}


void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}


void Assembler::Align(intptr_t alignment, intptr_t offset) {
  ASSERT(Utils::IsPowerOfTwo(alignment));
  intptr_t pos = offset + buffer_.GetPosition();
  intptr_t mod = pos & (alignment - 1);
  if (mod == 0) {
    return;
  }
  intptr_t bytes_needed = alignment - mod;
  while (bytes_needed > MAX_NOP_SIZE) {
    nop(MAX_NOP_SIZE);
    bytes_needed -= MAX_NOP_SIZE;
  }
  if (bytes_needed) {
    nop(bytes_needed);
  }
  ASSERT(((offset + buffer_.GetPosition()) & (alignment-1)) == 0);
}


void Assembler::Bind(Label* label) {
  intptr_t bound = buffer_.Size();
  ASSERT(!label->IsBound());  // Labels can only be bound once.
  while (label->IsLinked()) {
    intptr_t position = label->LinkPosition();
    intptr_t next = buffer_.Load<int32_t>(position);
    buffer_.Store<int32_t>(position, bound - (position + 4));
    label->position_ = next;
  }
  while (label->HasNear()) {
    intptr_t position = label->NearPosition();
    intptr_t offset = bound - (position + 1);
    ASSERT(Utils::IsInt(8, offset));
    buffer_.Store<int8_t>(position, offset);
  }
  label->BindTo(bound);
}


static void ComputeCounterAddressesForCid(intptr_t cid,
                                          Heap::Space space,
                                          Address* count_address,
                                          Address* size_address) {
  ASSERT(cid < kNumPredefinedCids);
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
  const uword class_heap_stats_table_address =
      class_table->PredefinedClassHeapStatsTableAddress();
  const uword class_offset = cid * sizeof(ClassHeapStats);  // NOLINT
  const uword count_field_offset = (space == Heap::kNew) ?
    ClassHeapStats::allocated_since_gc_new_space_offset() :
    ClassHeapStats::allocated_since_gc_old_space_offset();
  const uword size_field_offset = (space == Heap::kNew) ?
    ClassHeapStats::allocated_size_since_gc_new_space_offset() :
    ClassHeapStats::allocated_size_since_gc_old_space_offset();
  *count_address = Address::Absolute(
      class_heap_stats_table_address + class_offset + count_field_offset);
  *size_address = Address::Absolute(
      class_heap_stats_table_address + class_offset + size_field_offset);
}

void Assembler::UpdateAllocationStats(intptr_t cid,
                                      Register temp_reg,
                                      Heap::Space space) {
  ASSERT(cid > 0);
  if (cid < kNumPredefinedCids) {
    Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
    ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
    incl(count_address);
  } else {
    ASSERT(temp_reg != kNoRegister);
    const uword class_offset = cid * sizeof(ClassHeapStats);  // NOLINT
    const uword count_field_offset = (space == Heap::kNew) ?
      ClassHeapStats::allocated_since_gc_new_space_offset() :
      ClassHeapStats::allocated_since_gc_old_space_offset();
    // temp_reg gets address of class table pointer.
    ClassTable* class_table = Isolate::Current()->class_table();
    movl(temp_reg, Address::Absolute(class_table->ClassStatsTableAddress()));
    // Increment allocation count.
    incl(Address(temp_reg, class_offset + count_field_offset));
  }
}


void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              Register size_reg,
                                              Register temp_reg,
                                              Heap::Space space) {
  ASSERT(cid > 0);
  ASSERT(cid < kNumPredefinedCids);
  Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
  ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
  incl(count_address);
  addl(size_address, size_reg);
}


void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              intptr_t size_in_bytes,
                                              Register temp_reg,
                                              Heap::Space space) {
  ASSERT(cid > 0);
  ASSERT(cid < kNumPredefinedCids);
  Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
  ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
  incl(count_address);
  addl(size_address, Immediate(size_in_bytes));
}


void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            bool near_jump,
                            Register instance_reg,
                            Register temp_reg) {
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc) {
    Heap* heap = Isolate::Current()->heap();
    const intptr_t instance_size = cls.instance_size();
    movl(instance_reg, Address::Absolute(heap->TopAddress()));
    addl(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    cmpl(instance_reg, Address::Absolute(heap->EndAddress()));
    j(ABOVE_EQUAL, failure, near_jump);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    movl(Address::Absolute(heap->TopAddress()), instance_reg);
    UpdateAllocationStats(cls.id(), temp_reg);
    ASSERT(instance_size >= kHeapObjectTag);
    subl(instance_reg, Immediate(instance_size - kHeapObjectTag));
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    movl(FieldAddress(instance_reg, Object::tags_offset()), Immediate(tags));
  } else {
    jmp(failure);
  }
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  EnterFrame(0);
  Label dart_entry;
  call(&dart_entry);
  Bind(&dart_entry);
  // The runtime system assumes that the code marker address is
  // kEntryPointToPcMarkerOffset bytes from the entry.  If there is any code
  // generated before entering the frame, the address needs to be adjusted.
  const intptr_t offset = kEntryPointToPcMarkerOffset - CodeSize();
  if (offset != 0) {
    addl(Address(ESP, 0), Immediate(offset));
  }
  if (frame_size != 0) {
    subl(ESP, Immediate(frame_size));
  }
}


// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate.
void Assembler::EnterOsrFrame(intptr_t extra_size) {
  Comment("EnterOsrFrame");
  Label dart_entry;
  call(&dart_entry);
  Bind(&dart_entry);
  // The runtime system assumes that the code marker address is
  // kEntryPointToPcMarkerOffset bytes from the entry.  Since there is no
  // code to set up the frame pointer, the address needs to be adjusted.
  const intptr_t offset = kEntryPointToPcMarkerOffset - CodeSize();
  if (offset != 0) {
    addl(Address(ESP, 0), Immediate(offset));
  }
  popl(Address(EBP, kPcMarkerSlotFromFp * kWordSize));
  if (extra_size != 0) {
    subl(ESP, Immediate(extra_size));
  }
}


void Assembler::EnterStubFrame() {
  EnterFrame(0);
  pushl(Immediate(0));  // Push 0 in the saved PC area for stub frames.
}


void Assembler::Stop(const char* message) {
  if (FLAG_print_stop_message) {
    StubCode* stub_code = Isolate::Current()->stub_code();
    pushl(EAX);  // Preserve EAX.
    movl(EAX, Immediate(reinterpret_cast<int32_t>(message)));
    call(&stub_code->PrintStopMessageLabel());  // Passing message in EAX.
    popl(EAX);  // Restore EAX.
  } else {
    // Emit the message address as immediate operand in the test instruction.
    testl(EAX, Immediate(reinterpret_cast<int32_t>(message)));
  }
  // Emit the int3 instruction.
  int3();  // Execution can be resumed with the 'cont' command in gdb.
}


void Assembler::EmitOperand(int rm, const Operand& operand) {
  ASSERT(rm >= 0 && rm < 8);
  const intptr_t length = operand.length_;
  ASSERT(length > 0);
  // Emit the ModRM byte updated with the given RM value.
  ASSERT((operand.encoding_[0] & 0x38) == 0);
  EmitUint8(operand.encoding_[0] + (rm << 3));
  // Emit the rest of the encoded operand.
  for (intptr_t i = 1; i < length; i++) {
    EmitUint8(operand.encoding_[i]);
  }
}


void Assembler::EmitImmediate(const Immediate& imm) {
  EmitInt32(imm.value());
}


void Assembler::EmitComplex(int rm,
                            const Operand& operand,
                            const Immediate& immediate) {
  ASSERT(rm >= 0 && rm < 8);
  if (immediate.is_int8()) {
    // Use sign-extended 8-bit immediate.
    EmitUint8(0x83);
    EmitOperand(rm, operand);
    EmitUint8(immediate.value() & 0xFF);
  } else if (operand.IsRegister(EAX)) {
    // Use short form if the destination is eax.
    EmitUint8(0x05 + (rm << 3));
    EmitImmediate(immediate);
  } else {
    EmitUint8(0x81);
    EmitOperand(rm, operand);
    EmitImmediate(immediate);
  }
}


void Assembler::EmitLabel(Label* label, intptr_t instruction_size) {
  if (label->IsBound()) {
    intptr_t offset = label->Position() - buffer_.Size();
    ASSERT(offset <= 0);
    EmitInt32(offset - instruction_size);
  } else {
    EmitLabelLink(label);
  }
}


void Assembler::EmitLabelLink(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t position = buffer_.Size();
  EmitInt32(label->position_);
  label->LinkTo(position);
}


void Assembler::EmitNearLabelLink(Label* label) {
  ASSERT(!label->IsBound());
  intptr_t position = buffer_.Size();
  EmitUint8(0);
  label->NearLinkTo(position);
}


void Assembler::EmitGenericShift(int rm,
                                 Register reg,
                                 const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  if (imm.value() == 1) {
    EmitUint8(0xD1);
    EmitOperand(rm, Operand(reg));
  } else {
    EmitUint8(0xC1);
    EmitOperand(rm, Operand(reg));
    EmitUint8(imm.value() & 0xFF);
  }
}


void Assembler::EmitGenericShift(int rm,
                                 const Operand& operand,
                                 Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
  EmitUint8(0xD3);
  EmitOperand(rm, Operand(operand));
}


void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagPos == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassIdTagPos / kBitsPerByte;
  movzxw(result, FieldAddress(object, class_id_offset));
}


void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);
  movl(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  movl(result, Address(result, table_offset_in_isolate));
  movl(result, Address(result, class_id, TIMES_4, 0));
}


void Assembler::LoadClass(Register result,
                          Register object,
                          Register scratch) {
  ASSERT(scratch != result);
  LoadClassId(scratch, object);

  movl(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  movl(result, Address(result, table_offset_in_isolate));
  movl(result, Address(result, scratch, TIMES_4, 0));
}


void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(scratch, object);
  cmpl(scratch, Immediate(class_id));
}


void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  testl(object, Immediate(kSmiTagMask));
  Label not_smi, done;
  j(NOT_ZERO, &not_smi, Assembler::kNearJump);
  movl(result, Immediate(Smi::RawValue(kSmiCid)));
  jmp(&done, Assembler::kNearJump);
  Bind(&not_smi);
  LoadClassId(result, object);
  SmiTag(result);
  Bind(&done);
}


static const char* cpu_reg_names[kNumberOfCpuRegisters] = {
  "eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi"
};


const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}


static const char* xmm_reg_names[kNumberOfXmmRegisters] = {
  "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7"
};


const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfXmmRegisters));
  return xmm_reg_names[reg];
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
