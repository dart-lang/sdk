// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_IA32)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/instructions.h"

namespace dart {

DECLARE_FLAG(bool, inline_alloc);
DECLARE_FLAG(bool, use_slow_path);

namespace compiler {

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
    jit_cookie_ = CreateJitCookie();
  }
  return jit_cookie_;
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
  if (imm.is_int8()) {
    EmitUint8(0x6A);
    EmitUint8(imm.value() & 0xFF);
  } else {
    EmitUint8(0x68);
    EmitImmediate(imm);
  }
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
  // This would leave 24 bits above the 1 byte value undefined.
  // If we ever want to purposefully have those undefined, remove this.
  // TODO(dartbug.com/40210): Allow this.
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
  // This would leave 16 bits above the 2 byte value undefined.
  // If we ever want to purposefully have those undefined, remove this.
  // TODO(dartbug.com/40210): Allow this.
  FATAL("Use movzxw or movsxw instead.");
}

void Assembler::movw(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitUint8(0x89);
  EmitOperand(src, dst);
}

void Assembler::movw(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitUint8(0xC7);
  EmitOperand(0, dst);
  EmitUint8(imm.value() & 0xFF);
  EmitUint8((imm.value() >> 8) & 0xFF);
}

void Assembler::leal(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x8D);
  EmitOperand(dst, src);
}

// Move if not overflow.
void Assembler::cmovno(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x41);
  EmitRegisterOperand(dst, src);
}

void Assembler::cmove(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x44);
  EmitRegisterOperand(dst, src);
}

void Assembler::cmovne(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x45);
  EmitRegisterOperand(dst, src);
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

void Assembler::rep_movsw() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x66);
  EmitUint8(0xA5);
}

void Assembler::rep_movsl() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0xA5);
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
  } float_not_constant = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF};
  xorps(dst, Address::Absolute(reinterpret_cast<uword>(&float_not_constant)));
}

void Assembler::negateps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_negate_constant = {0x80000000, 0x80000000, 0x80000000, 0x80000000};
  xorps(dst,
        Address::Absolute(reinterpret_cast<uword>(&float_negate_constant)));
}

void Assembler::absps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_absolute_constant = {0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF};
  andps(dst,
        Address::Absolute(reinterpret_cast<uword>(&float_absolute_constant)));
}

void Assembler::zerowps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_zerow_constant = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000};
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
  } double_negate_constant = {0x8000000000000000LLU, 0x8000000000000000LLU};
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
  } double_absolute_constant = {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL};
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

void Assembler::pmovmskb(Register dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xD7);
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

void Assembler::cmpw(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitUint8(0x81);
  EmitOperand(7, address);
  EmitUint8(imm.value() & 0xFF);
  EmitUint8((imm.value() >> 8) & 0xFF);
}

void Assembler::cmpb(const Address& address, const Immediate& imm) {
  ASSERT(imm.is_int8());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x80);
  EmitOperand(7, address);
  EmitUint8(imm.value() & 0xFF);
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

void Assembler::testb(const Address& address, const Immediate& imm) {
  ASSERT(imm.is_int8());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF6);
  EmitOperand(0, address);
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::Alu(int bytes, uint8_t opcode, Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (bytes == 2) {
    EmitOperandSizeOverride();
  }
  ASSERT((opcode & 7) == 3);
  EmitUint8(opcode);
  EmitOperand(dst, Operand(src));
}

void Assembler::Alu(uint8_t modrm_opcode, Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(modrm_opcode, Operand(dst), imm);
}

void Assembler::Alu(int bytes,
                    uint8_t opcode,
                    Register dst,
                    const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (bytes == 2) {
    EmitOperandSizeOverride();
  }
  ASSERT((opcode & 7) == 3);
  EmitUint8(opcode);
  EmitOperand(dst, src);
}

void Assembler::Alu(int bytes,
                    uint8_t opcode,
                    const Address& dst,
                    Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (bytes == 2) {
    EmitOperandSizeOverride();
  }
  ASSERT((opcode & 7) == 1);
  EmitUint8(opcode);
  EmitOperand(src, dst);
}

void Assembler::Alu(uint8_t modrm_opcode,
                    const Address& dst,
                    const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(modrm_opcode, dst, imm);
}

void Assembler::cdq() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x99);
}

void Assembler::idivl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(7, Operand(reg));
}

void Assembler::divl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(6, Operand(reg));
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

void Assembler::shldl(Register dst, Register src, Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
  EmitUint8(0x0F);
  EmitUint8(0xA5);
  EmitRegisterOperand(src, dst);
}

void Assembler::shldl(Register dst, Register src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  EmitUint8(0x0F);
  EmitUint8(0xA4);
  EmitRegisterOperand(src, dst);
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::shldl(const Address& operand, Register src, Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
  EmitUint8(0x0F);
  EmitUint8(0xA5);
  EmitOperand(src, Operand(operand));
}

void Assembler::shrdl(Register dst, Register src, Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
  EmitUint8(0x0F);
  EmitUint8(0xAD);
  EmitRegisterOperand(src, dst);
}

void Assembler::shrdl(Register dst, Register src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  EmitUint8(0x0F);
  EmitUint8(0xAC);
  EmitRegisterOperand(src, dst);
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::shrdl(const Address& dst, Register src, Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
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

void Assembler::bsfl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBC);
  EmitRegisterOperand(dst, src);
}

void Assembler::bsrl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBD);
  EmitRegisterOperand(dst, src);
}

void Assembler::popcntl(Register dst, Register src) {
  ASSERT(TargetCPUFeatures::popcnt_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0xB8);
  EmitRegisterOperand(dst, src);
}

void Assembler::lzcntl(Register dst, Register src) {
  ASSERT(TargetCPUFeatures::abm_supported());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0xBD);
  EmitRegisterOperand(dst, src);
}

void Assembler::bt(Register base, Register offset) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA3);
  EmitRegisterOperand(offset, base);
}

void Assembler::bt(Register base, int bit) {
  ASSERT(bit >= 0 && bit < 32);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xBA);
  EmitRegisterOperand(4, base);
  EmitUint8(bit);
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

void Assembler::j(Condition condition, Label* label, JumpDistance distance) {
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
  } else if (distance == kNearJump) {
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

void Assembler::jmp(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFF);
  EmitOperand(4, address);
}

void Assembler::jmp(Label* label, JumpDistance distance) {
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
  } else if (distance == kNearJump) {
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

void Assembler::LoadFromOffset(Register reg,
                               Register base,
                               int32_t offset,
                               OperandSize type) {
  switch (type) {
    case kByte:
      return movsxb(reg, Address(base, offset));
    case kUnsignedByte:
      return movzxb(reg, Address(base, offset));
    case kTwoBytes:
      return movsxw(reg, Address(base, offset));
    case kUnsignedTwoBytes:
      return movzxw(reg, Address(base, offset));
    case kFourBytes:
      return movl(reg, Address(base, offset));
    default:
      UNREACHABLE();
      break;
  }
}

void Assembler::LoadFromStack(Register dst, intptr_t depth) {
  ASSERT(depth >= 0);
  movl(dst, Address(ESP, depth * target::kWordSize));
}

void Assembler::StoreToStack(Register src, intptr_t depth) {
  ASSERT(depth >= 0);
  movl(Address(ESP, depth * target::kWordSize), src);
}

void Assembler::CompareToStack(Register src, intptr_t depth) {
  cmpl(src, Address(ESP, depth * target::kWordSize));
}

void Assembler::MoveRegister(Register to, Register from) {
  if (to != from) {
    movl(to, from);
  }
}

void Assembler::PushRegister(Register r) {
  pushl(r);
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
    addl(ESP, Immediate(stack_elements * target::kWordSize));
  }
}

void Assembler::LoadIsolate(Register dst) {
  movl(dst, Address(THR, target::Thread::isolate_offset()));
}

void Assembler::LoadObject(Register dst,
                           const Object& object,
                           bool movable_referent) {
  ASSERT(IsOriginalObject(object));

  // movable_referent: some references to VM heap objects may be patched with
  // references to isolate-local objects (e.g., optimized static calls).
  // We need to track such references since the latter may move during
  // compaction.
  if (target::CanEmbedAsRawPointerInGeneratedCode(object) &&
      !movable_referent) {
    movl(dst, Immediate(target::ToRawPointer(object)));
  } else {
    ASSERT(IsNotTemporaryScopedHandle(object));
    ASSERT(IsInOldSpace(object));
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xB8 + dst);
    buffer_.EmitObject(object);
  }
}

void Assembler::LoadObjectSafely(Register dst, const Object& object) {
  ASSERT(IsOriginalObject(object));
  if (target::IsSmi(object) && !IsSafeSmi(object)) {
    const int32_t cookie = jit_cookie();
    movl(dst, Immediate(target::ToRawSmi(object) ^ cookie));
    xorl(dst, Immediate(cookie));
  } else {
    LoadObject(dst, object);
  }
}

void Assembler::PushObject(const Object& object) {
  ASSERT(IsOriginalObject(object));
  if (target::CanEmbedAsRawPointerInGeneratedCode(object)) {
    pushl(Immediate(target::ToRawPointer(object)));
  } else {
    ASSERT(IsNotTemporaryScopedHandle(object));
    ASSERT(IsInOldSpace(object));
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0x68);
    buffer_.EmitObject(object);
  }
}

void Assembler::CompareObject(Register reg, const Object& object) {
  ASSERT(IsOriginalObject(object));
  if (target::CanEmbedAsRawPointerInGeneratedCode(object)) {
    cmpl(reg, Immediate(target::ToRawPointer(object)));
  } else {
    ASSERT(IsNotTemporaryScopedHandle(object));
    ASSERT(IsInOldSpace(object));
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
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* label,
                                      CanBeSmi can_be_smi,
                                      BarrierFilterMode how_to_jump) {
  if (can_be_smi == kValueIsNotSmi) {
#if defined(DEBUG)
    Label okay;
    BranchIfNotSmi(value, &okay);
    Stop("Unexpected Smi!");
    Bind(&okay);
#endif
    COMPILE_ASSERT((target::ObjectAlignment::kNewObjectAlignmentOffset ==
                    target::kWordSize) &&
                   (target::ObjectAlignment::kOldObjectAlignmentOffset == 0));
    // Write-barrier triggers if the value is in the new space (has bit set) and
    // the object is in the old space (has bit cleared).
    // To check that we could compute value & ~object and skip the write barrier
    // if the bit is not set. However we can't destroy the object.
    // However to preserve the object we compute negated expression
    // ~value | object instead and skip the write barrier if the bit is set.
    notl(value);
    orl(value, object);
    testl(value, Immediate(target::ObjectAlignment::kNewObjectAlignmentOffset));
  } else {
    ASSERT(target::ObjectAlignment::kNewObjectAlignmentOffset == 4);
    ASSERT(kHeapObjectTag == 1);
    // Detect value being ...101 and object being ...001.
    andl(value, Immediate(7));
    leal(value, Address(value, object, TIMES_2, 9));
    testl(value, Immediate(0xf));
  }
  Condition condition = how_to_jump == kJumpToNoUpdate ? NOT_ZERO : ZERO;
  auto const distance = how_to_jump == kJumpToNoUpdate ? kNearJump : kFarJump;
  j(condition, label, distance);
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);

  movl(dest, value);
  Label done;
  StoreIntoObjectFilter(object, value, &done, can_be_smi, kJumpToNoUpdate);
  // A store buffer update is required.
  if (value != EDX) {
    pushl(EDX);  // Preserve EDX.
  }
  if (object != EDX) {
    movl(EDX, object);
  }
  call(Address(THR, target::Thread::write_barrier_entry_point_offset()));
  if (value != EDX) {
    popl(EDX);  // Restore EDX.
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  movl(dest, value);
#if defined(DEBUG)
  Label done;
  pushl(value);
  StoreIntoObjectFilter(object, value, &done, kValueCanBeSmi, kJumpToNoUpdate);

  testb(FieldAddress(object, target::Object::tags_offset()),
        Immediate(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  j(ZERO, &done, Assembler::kNearJump);

  Stop("Store buffer update is required");
  Bind(&done);
  popl(value);
#endif  // defined(DEBUG)
  // No store buffer update.
}

// Destroys the value register.
void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_be_smi) {
  ASSERT(object != value);
  movl(Address(slot, 0), value);

  Label done;
  StoreIntoObjectFilter(object, value, &done, can_be_smi, kJumpToNoUpdate);
  // A store buffer update is required.
  if (value != kWriteBarrierObjectReg) {
    pushl(kWriteBarrierObjectReg);  // Preserve kWriteBarrierObjectReg.
  }
  if (value != kWriteBarrierSlotReg && slot != kWriteBarrierSlotReg) {
    pushl(kWriteBarrierSlotReg);  // Preserve kWriteBarrierSlotReg.
  }
  if (object != kWriteBarrierObjectReg && slot != kWriteBarrierSlotReg) {
    if (slot == kWriteBarrierObjectReg && object == kWriteBarrierSlotReg) {
      xchgl(slot, object);
    } else if (slot == kWriteBarrierObjectReg) {
      movl(kWriteBarrierSlotReg, slot);
      movl(kWriteBarrierObjectReg, object);
    } else {
      movl(kWriteBarrierObjectReg, object);
      movl(kWriteBarrierSlotReg, slot);
    }
  } else if (object != kWriteBarrierObjectReg) {
    movl(kWriteBarrierObjectReg, object);
  } else if (slot != kWriteBarrierSlotReg) {
    movl(kWriteBarrierSlotReg, slot);
  }
  call(Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
  if (value != kWriteBarrierSlotReg && slot != kWriteBarrierSlotReg) {
    popl(kWriteBarrierSlotReg);  // Restore kWriteBarrierSlotReg.
  }
  if (value != kWriteBarrierObjectReg) {
    popl(kWriteBarrierObjectReg);  // Restore kWriteBarrierObjectReg.
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  ASSERT(IsOriginalObject(value));
  if (target::CanEmbedAsRawPointerInGeneratedCode(value)) {
    Immediate imm_value(target::ToRawPointer(value));
    movl(dest, imm_value);
  } else {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xC7);
    EmitOperand(0, dest);
    buffer_.EmitObject(value);
  }
  // No store buffer update.
}

void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  movl(dest, value);
}

void Assembler::StoreIntoSmiField(const Address& dest, Register value) {
#if defined(DEBUG)
  Label done;
  testl(value, Immediate(kHeapObjectTag));
  j(ZERO, &done);
  Stop("New value must be Smi.");
  Bind(&done);
#endif  // defined(DEBUG)
  movl(dest, value);
}

void Assembler::ZeroInitSmiField(const Address& dest) {
  Immediate zero(target::ToRawSmi(0));
  movl(dest, zero);
}

void Assembler::IncrementSmiField(const Address& dest, int32_t increment) {
  // Note: FlowGraphCompiler::EdgeCounterIncrementSizeInBytes depends on
  // the length of this instruction sequence.
  Immediate inc_imm(target::ToRawSmi(increment));
  addl(dest, inc_imm);
}

void Assembler::LoadDoubleConstant(XmmRegister dst, double value) {
  // TODO(5410843): Need to have a code constants table.
  int64_t constant = bit_cast<int64_t, double>(value);
  pushl(Immediate(Utils::High32Bits(constant)));
  pushl(Immediate(Utils::Low32Bits(constant)));
  movsd(dst, Address(ESP, 0));
  addl(ESP, Immediate(2 * target::kWordSize));
}

void Assembler::FloatNegate(XmmRegister f) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_negate_constant = {0x80000000, 0x00000000, 0x80000000, 0x00000000};
  xorps(f, Address::Absolute(reinterpret_cast<uword>(&float_negate_constant)));
}

void Assembler::DoubleNegate(XmmRegister d) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_negate_constant = {0x8000000000000000LLU, 0x8000000000000000LLU};
  xorpd(d, Address::Absolute(reinterpret_cast<uword>(&double_negate_constant)));
}

void Assembler::DoubleAbs(XmmRegister reg) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_abs_constant = {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL};
  andpd(reg, Address::Absolute(reinterpret_cast<uword>(&double_abs_constant)));
}

void Assembler::EnterFrame(intptr_t frame_size) {
  if (prologue_offset_ == -1) {
    Comment("PrologueOffset = %" Pd "", CodeSize());
    prologue_offset_ = CodeSize();
  }
#ifdef DEBUG
  intptr_t check_offset = CodeSize();
#endif
  pushl(EBP);
  movl(EBP, ESP);
#ifdef DEBUG
  ProloguePattern pp(CodeAddress(check_offset));
  ASSERT(pp.IsValid());
#endif
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

void Assembler::EmitEntryFrameVerification() {
#if defined(DEBUG)
  Label ok;
  leal(EAX, Address(EBP, target::frame_layout.exit_link_slot_from_entry_fp *
                             target::kWordSize));
  cmpl(EAX, ESP);
  j(EQUAL, &ok);
  Stop("target::frame_layout.exit_link_slot_from_entry_fp mismatch");
  Bind(&ok);
#endif
}

// EBX receiver, ECX ICData entries array
// Preserve EDX (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryJIT() {
  has_monomorphic_entry_ = true;
  intptr_t start = CodeSize();
  Label have_cid, miss;
  Bind(&miss);
  jmp(Address(THR, target::Thread::switchable_call_miss_entry_offset()));

  Comment("MonomorphicCheckedEntry");
  ASSERT(CodeSize() - start ==
         target::Instructions::kMonomorphicEntryOffsetJIT);

  const intptr_t cid_offset = target::Array::element_offset(0);
  const intptr_t count_offset = target::Array::element_offset(1);

  movl(EAX, Immediate(kSmiCid << 1));
  testl(EBX, Immediate(kSmiTagMask));
  j(ZERO, &have_cid, kNearJump);
  LoadClassId(EAX, EBX);
  SmiTag(EAX);
  Bind(&have_cid);
  // EAX: cid as Smi

  cmpl(EAX, FieldAddress(ECX, cid_offset));
  j(NOT_EQUAL, &miss, Assembler::kNearJump);
  addl(FieldAddress(ECX, count_offset), Immediate(target::ToRawSmi(1)));
  xorl(EDX, EDX);  // GC-safe for OptimizeInvokedFunction.
  nop(1);

  // Fall through to unchecked entry.
  ASSERT(CodeSize() - start ==
         target::Instructions::kPolymorphicEntryOffsetJIT);
}

// EBX receiver, ECX guarded cid as Smi.
// Preserve EDX (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryAOT() {
  UNIMPLEMENTED();
}

void Assembler::BranchOnMonomorphicCheckedEntryJIT(Label* label) {
  has_monomorphic_entry_ = true;
  while (CodeSize() < target::Instructions::kMonomorphicEntryOffsetJIT) {
    int3();
  }
  jmp(label);
  while (CodeSize() < target::Instructions::kPolymorphicEntryOffsetJIT) {
    int3();
  }
}

void Assembler::EnterSafepoint(Register scratch) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.

  // Compare and swap the value at Thread::safepoint_state from unacquired to
  // acquired. On success, jump to 'success'; otherwise, fallthrough.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  pushl(EAX);
  movl(EAX, Immediate(target::Thread::safepoint_state_unacquired()));
  movl(scratch, Immediate(target::Thread::safepoint_state_acquired()));
  LockCmpxchgl(Address(THR, target::Thread::safepoint_state_offset()), scratch);
  movl(scratch, EAX);
  popl(EAX);
  cmpl(scratch, Immediate(target::Thread::safepoint_state_unacquired()));

  if (!FLAG_use_slow_path) {
    j(EQUAL, &done);
  }

  Bind(&slow_path);
  movl(scratch, Address(THR, target::Thread::enter_safepoint_stub_offset()));
  movl(scratch, FieldAddress(scratch, target::Code::entry_point_offset()));
  call(scratch);

  Bind(&done);
}

void Assembler::TransitionGeneratedToNative(Register destination_address,
                                            Register new_exit_frame,
                                            Register new_exit_through_ffi,
                                            bool enter_safepoint) {
  // Save exit frame information to enable stack walking.
  movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
       new_exit_frame);

  movl(compiler::Address(THR,
                         compiler::target::Thread::exit_through_ffi_offset()),
       new_exit_through_ffi);
  Register scratch = new_exit_through_ffi;

  // Mark that the thread is executing native code.
  movl(VMTagAddress(), destination_address);
  movl(Address(THR, target::Thread::execution_state_offset()),
       Immediate(target::Thread::native_execution_state()));

  if (enter_safepoint) {
    EnterSafepoint(scratch);
  }
}

void Assembler::ExitSafepoint(Register scratch) {
  ASSERT(scratch != EAX);
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterSafepoint.

  // Compare and swap the value at Thread::safepoint_state from acquired to
  // unacquired. On success, jump to 'success'; otherwise, fallthrough.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  pushl(EAX);
  movl(EAX, Immediate(target::Thread::safepoint_state_acquired()));
  movl(scratch, Immediate(target::Thread::safepoint_state_unacquired()));
  LockCmpxchgl(Address(THR, target::Thread::safepoint_state_offset()), scratch);
  movl(scratch, EAX);
  popl(EAX);
  cmpl(scratch, Immediate(target::Thread::safepoint_state_acquired()));

  if (!FLAG_use_slow_path) {
    j(EQUAL, &done);
  }

  Bind(&slow_path);
  movl(scratch, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  movl(scratch, FieldAddress(scratch, target::Code::entry_point_offset()));
  call(scratch);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(Register scratch,
                                            bool exit_safepoint) {
  if (exit_safepoint) {
    ExitSafepoint(scratch);
  } else {
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    movl(scratch, Address(THR, target::Thread::safepoint_state_offset()));
    andl(scratch, Immediate(1 << target::Thread::safepoint_state_inside_bit()));
    Label ok;
    j(ZERO, &ok);
    Breakpoint();
    Bind(&ok);
#endif
  }

  // Mark that the thread is executing Dart code.
  movl(Assembler::VMTagAddress(), Immediate(target::Thread::vm_tag_dart_id()));
  movl(Address(THR, target::Thread::execution_state_offset()),
       Immediate(target::Thread::generated_execution_state()));

  // Reset exit frame information in Isolate's mutator thread structure.
  movl(Address(THR, target::Thread::top_exit_frame_info_offset()),
       Immediate(0));
  movl(compiler::Address(THR,
                         compiler::target::Thread::exit_through_ffi_offset()),
       compiler::Immediate(0));
}

static const intptr_t kNumberOfVolatileCpuRegisters = 3;
static const Register volatile_cpu_registers[kNumberOfVolatileCpuRegisters] = {
    EAX, ECX, EDX};

// XMM0 is used only as a scratch register in the optimized code. No need to
// save it.
static const intptr_t kNumberOfVolatileXmmRegisters = kNumberOfXmmRegisters - 1;

void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  Comment("EnterCallRuntimeFrame");
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
      kNumberOfVolatileCpuRegisters * target::kWordSize +
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

void Assembler::Call(const Code& target,
                     bool movable_target,
                     CodeEntryKind entry_kind) {
  LoadObject(CODE_REG, ToObject(target), movable_target);
  call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::CallToRuntime() {
  call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

void Assembler::Jmp(const Code& target) {
  const ExternalLabel label(target::Code::EntryPointOf(target));
  jmp(&label);
}

void Assembler::J(Condition condition, const Code& target) {
  const ExternalLabel label(target::Code::EntryPointOf(target));
  j(condition, &label);
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
  ASSERT(((offset + buffer_.GetPosition()) & (alignment - 1)) == 0);
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

void Assembler::MoveMemoryToMemory(Address dst, Address src, Register tmp) {
  movl(tmp, src);
  movl(dst, tmp);
}

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Register temp_reg,
                                     Label* trace,
                                     JumpDistance distance) {
  ASSERT(cid > 0);
  Address state_address(kNoRegister, 0);

  const intptr_t shared_table_offset =
      target::Isolate::shared_class_table_offset();
  const intptr_t table_offset =
      target::SharedClassTable::class_heap_stats_table_offset();
  const intptr_t class_offset = target::ClassTable::ClassOffsetFor(cid);

  ASSERT(temp_reg != kNoRegister);
  LoadIsolate(temp_reg);
  movl(temp_reg, Address(temp_reg, shared_table_offset));
  movl(temp_reg, Address(temp_reg, table_offset));
  cmpb(Address(temp_reg, class_offset), Immediate(0));
  // We are tracing for this class, jump to the trace label which will use
  // the allocation stub.
  j(NOT_ZERO, trace, distance);
}
#endif  // !PRODUCT

void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            JumpDistance distance,
                            Register instance_reg,
                            Register temp_reg) {
  ASSERT(failure != NULL);
  ASSERT(temp_reg != kNoRegister);
  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    const classid_t cid = target::Class::GetId(cls);
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, temp_reg, failure, distance));
    movl(instance_reg, Address(THR, target::Thread::top_offset()));
    addl(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    cmpl(instance_reg, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure, distance);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    movl(Address(THR, target::Thread::top_offset()), instance_reg);
    ASSERT(instance_size >= kHeapObjectTag);
    subl(instance_reg, Immediate(instance_size - kHeapObjectTag));
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    movl(FieldAddress(instance_reg, target::Object::tags_offset()),
         Immediate(tags));
  } else {
    jmp(failure);
  }
}

void Assembler::TryAllocateArray(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 JumpDistance distance,
                                 Register instance,
                                 Register end_address,
                                 Register temp_reg) {
  ASSERT(failure != NULL);
  ASSERT(temp_reg != kNoRegister);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, temp_reg, failure, distance));
    movl(instance, Address(THR, target::Thread::top_offset()));
    movl(end_address, instance);

    addl(end_address, Immediate(instance_size));
    j(CARRY, failure);

    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    cmpl(end_address, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    movl(Address(THR, target::Thread::top_offset()), end_address);
    addl(instance, Immediate(kHeapObjectTag));

    // Initialize the tags.
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    movl(FieldAddress(instance, target::Object::tags_offset()),
         Immediate(tags));
  } else {
    jmp(failure);
  }
}

void Assembler::PushCodeObject() {
  ASSERT(IsNotTemporaryScopedHandle(code_));
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x68);
  buffer_.EmitObject(code_);
}

void Assembler::EnterDartFrame(intptr_t frame_size) {
  EnterFrame(0);

  PushCodeObject();

  if (frame_size != 0) {
    subl(ESP, Immediate(frame_size));
  }
}

// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up. There may be extra space for spill slots to
// allocate.
void Assembler::EnterOsrFrame(intptr_t extra_size) {
  Comment("EnterOsrFrame");
  if (prologue_offset_ == -1) {
    Comment("PrologueOffset = %" Pd "", CodeSize());
    prologue_offset_ = CodeSize();
  }

  if (extra_size != 0) {
    subl(ESP, Immediate(extra_size));
  }
}

void Assembler::EnterStubFrame() {
  EnterDartFrame(0);
}

void Assembler::LeaveStubFrame() {
  LeaveFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  EnterFrame(0);
  ReserveAlignedFrameSpace(frame_space);
}

void Assembler::LeaveCFrame() {
  LeaveFrame();
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

void Assembler::EmitGenericShift(int rm, Register reg, const Immediate& imm) {
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
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      target::Object::tags_offset() +
      target::ObjectLayout::kClassIdTagPos / kBitsPerByte;
  movzxw(result, FieldAddress(object, class_id_offset));
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::Isolate::cached_class_table_table_offset();
  LoadIsolate(result);
  movl(result, Address(result, table_offset));
  movl(result, Address(result, class_id, TIMES_4, 0));
}

void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(scratch, object);
  cmpl(scratch, Immediate(class_id));
}

void Assembler::SmiUntagOrCheckClass(Register object,
                                     intptr_t class_id,
                                     Register scratch,
                                     Label* is_smi) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  const intptr_t class_id_offset =
      target::Object::tags_offset() +
      target::ObjectLayout::kClassIdTagPos / kBitsPerByte;

  // Untag optimistically. Tag bit is shifted into the CARRY.
  SmiUntag(object);
  j(NOT_CARRY, is_smi, kNearJump);
  // Load cid: can't use LoadClassId, object is untagged. Use TIMES_2 scale
  // factor in the addressing mode to compensate for this.
  movzxw(scratch, Address(object, TIMES_2, class_id_offset));
  cmpl(scratch, Immediate(class_id));
}

void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  if (result == object) {
    Label smi, join;

    testl(object, Immediate(kSmiTagMask));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);
    jmp(&join, Assembler::kNearJump);

    Bind(&smi);
    movl(result, Immediate(kSmiCid));

    Bind(&join);
  } else {
    ASSERT(result != object);
    static const intptr_t kSmiCidSource =
        kSmiCid << target::ObjectLayout::kClassIdTagPos;

    // Make a dummy "Object" whose cid is kSmiCid.
    movl(result, Immediate(reinterpret_cast<int32_t>(&kSmiCidSource) + 1));

    // Check if object (in tmp) is a Smi.
    testl(object, Immediate(kSmiTagMask));

    // If the object is not a Smi, use the original object to load the cid.
    // Otherwise, the dummy object is used, and the result is kSmiCid.
    cmovne(result, object);
    LoadClassId(result, result);
  }
}

void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  if (result == object) {
    Label smi, join;

    testl(object, Immediate(kSmiTagMask));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);
    SmiTag(result);
    jmp(&join, Assembler::kNearJump);

    Bind(&smi);
    movl(result, Immediate(target::ToRawSmi(kSmiCid)));

    Bind(&join);
  } else {
    LoadClassIdMayBeSmi(result, object);
    SmiTag(result);
  }
}

Address Assembler::ElementAddressForIntIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index,
                                             intptr_t extra_disp) {
  if (is_external) {
    return Address(array, index * index_scale + extra_disp);
  } else {
    const int64_t disp = static_cast<int64_t>(index) * index_scale +
                         target::Instance::DataOffsetFor(cid) + extra_disp;
    ASSERT(Utils::IsInt(32, disp));
    return FieldAddress(array, static_cast<int32_t>(disp));
  }
}

static ScaleFactor ToScaleFactor(intptr_t index_scale, bool index_unboxed) {
  if (index_unboxed) {
    switch (index_scale) {
      case 1:
        return TIMES_1;
      case 2:
        return TIMES_2;
      case 4:
        return TIMES_4;
      case 8:
        return TIMES_8;
      case 16:
        return TIMES_16;
      default:
        UNREACHABLE();
        return TIMES_1;
    }
  } else {
    // Note that index is expected smi-tagged, (i.e, times 2) for all arrays
    // with index scale factor > 1. E.g., for Uint8Array and OneByteString the
    // index is expected to be untagged before accessing.
    ASSERT(kSmiTagShift == 1);
    switch (index_scale) {
      case 1:
        return TIMES_1;
      case 2:
        return TIMES_1;
      case 4:
        return TIMES_2;
      case 8:
        return TIMES_4;
      case 16:
        return TIMES_8;
      default:
        UNREACHABLE();
        return TIMES_1;
    }
  }
}

Address Assembler::ElementAddressForRegIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             bool index_unboxed,
                                             Register array,
                                             Register index,
                                             intptr_t extra_disp) {
  if (is_external) {
    return Address(array, index, ToScaleFactor(index_scale, index_unboxed),
                   extra_disp);
  } else {
    return FieldAddress(array, index, ToScaleFactor(index_scale, index_unboxed),
                        target::Instance::DataOffsetFor(cid) + extra_disp);
  }
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)
