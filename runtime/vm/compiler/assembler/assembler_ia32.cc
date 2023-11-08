// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_IA32)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/tags.h"

namespace dart {

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
  const int kSize = 5;
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

void Assembler::movb(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x88);
  EmitOperand(src, dst);
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

void Assembler::rep_movsd() {
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
  // Mask precision exception.
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

void Assembler::testl(const Address& address, const Immediate& immediate) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF7);
  EmitOperand(0, address);
  EmitImmediate(immediate);
}

void Assembler::testl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x85);
  EmitOperand(reg, address);
}

void Assembler::testb(const Address& address, const Immediate& imm) {
  ASSERT(imm.is_int8());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF6);
  EmitOperand(0, address);
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::testb(const Address& address, ByteRegister reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x84);
  EmitOperand(reg, address);
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
    const int kShortSize = 2;
    const int kLongSize = 6;
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
    const int kShortSize = 2;
    const int kLongSize = 5;
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

void Assembler::cld() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFC);
}

void Assembler::std() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xFD);
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
                               const Address& address,
                               OperandSize type) {
  switch (type) {
    case kByte:
      return movsxb(reg, address);
    case kUnsignedByte:
      return movzxb(reg, address);
    case kTwoBytes:
      return movsxw(reg, address);
    case kUnsignedTwoBytes:
      return movzxw(reg, address);
    case kUnsignedFourBytes:
    case kFourBytes:
      return movl(reg, address);
    default:
      UNREACHABLE();
      break;
  }
}

void Assembler::StoreToOffset(Register reg,
                              const Address& address,
                              OperandSize sz) {
  switch (sz) {
    case kByte:
    case kUnsignedByte:
      return movb(address, reg);
    case kTwoBytes:
    case kUnsignedTwoBytes:
      return movw(address, reg);
    case kFourBytes:
    case kUnsignedFourBytes:
      return movl(address, reg);
    default:
      UNREACHABLE();
      break;
  }
}

void Assembler::StoreToOffset(const Object& object, const Address& dst) {
  if (target::CanEmbedAsRawPointerInGeneratedCode(object)) {
    movl(dst, Immediate(target::ToRawPointer(object)));
  } else {
    DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
    ASSERT(IsInOldSpace(object));
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xC7);
    EmitOperand(0, dst);
    buffer_.EmitObject(object);
  }
}

void Assembler::ArithmeticShiftRightImmediate(Register reg, intptr_t shift) {
  sarl(reg, Immediate(shift));
}

void Assembler::CompareWords(Register reg1,
                             Register reg2,
                             intptr_t offset,
                             Register count,
                             Register temp,
                             Label* equals) {
  Label loop;
  Bind(&loop);
  decl(count);
  j(LESS, equals, Assembler::kNearJump);
  COMPILE_ASSERT(target::kWordSize == 4);
  movl(temp, FieldAddress(reg1, count, TIMES_4, offset));
  cmpl(temp, FieldAddress(reg2, count, TIMES_4, offset));
  BranchIf(EQUAL, &loop, Assembler::kNearJump);
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

void Assembler::ExtendValue(Register to, Register from, OperandSize sz) {
  switch (sz) {
    case kUnsignedFourBytes:
    case kFourBytes:
      if (to == from) return;  // No operation needed.
      return movl(to, from);
    case kUnsignedTwoBytes:
      return movzxw(to, from);
    case kTwoBytes:
      return movsxw(to, from);
    case kUnsignedByte:
      switch (from) {
        case EAX:
        case EBX:
        case ECX:
        case EDX:
          return movzxb(to, ByteRegisterOf(from));
          break;
        default:
          if (to != from) {
            movl(to, from);
          }
          return andl(to, Immediate(0xFF));
      }
    case kByte:
      switch (from) {
        case EAX:
        case EBX:
        case ECX:
        case EDX:
          return movsxb(to, ByteRegisterOf(from));
          break;
        default:
          if (to != from) {
            movl(to, from);
          }
          shll(to, Immediate(24));
          return sarl(to, Immediate(24));
      }
    default:
      UNIMPLEMENTED();
      break;
  }
}

void Assembler::PushRegister(Register r) {
  pushl(r);
}

void Assembler::PopRegister(Register r) {
  popl(r);
}

void Assembler::PushRegistersInOrder(std::initializer_list<Register> regs) {
  for (Register reg : regs) {
    PushRegister(reg);
  }
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

void Assembler::AddImmediate(Register dest, Register src, int32_t value) {
  if (dest == src) {
    AddImmediate(dest, value);
    return;
  }
  if (value == 0) {
    MoveRegister(dest, src);
    return;
  }
  leal(dest, Address(src, value));
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

void Assembler::AndRegisters(Register dst, Register src1, Register src2) {
  ASSERT(src1 != src2);  // Likely a mistake.
  if (src2 == kNoRegister) {
    src2 = dst;
  }
  if (dst == src2) {
    andl(dst, src1);
  } else if (dst == src1) {
    andl(dst, src2);
  } else {
    movl(dst, src1);
    andl(dst, src2);
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

void Assembler::LoadIsolateGroup(Register dst) {
  movl(dst, Address(THR, target::Thread::isolate_group_offset()));
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
    DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
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
    DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
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
    DEBUG_ASSERT(IsNotTemporaryScopedHandle(object));
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

void Assembler::LoadCompressedSmi(Register dest, const Address& slot) {
  movl(dest, slot);
#if defined(DEBUG)
  Label done;
  BranchIfSmi(dest, &done, kNearJump);
  Stop("Expected Smi");
  Bind(&done);
#endif
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi,
                                MemoryOrder memory_order,
                                Register scratch) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);

  if (memory_order == kRelease) {
    StoreRelease(value, dest.base(), dest.disp32());
  } else {
    movl(dest, value);
  }

  bool spill_scratch = false;
  if (scratch == kNoRegister) {
    spill_scratch = true;
    if (object != EAX && value != EAX) {
      scratch = EAX;
    } else if (object != EBX && value != EBX) {
      scratch = EBX;
    } else {
      scratch = ECX;
    }
  }
  ASSERT(scratch != object);
  ASSERT(scratch != value);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done, kNearJump);
  }
  if (spill_scratch) {
    pushl(scratch);
  }
  movl(scratch, FieldAddress(object, target::Object::tags_offset()));
  shrl(scratch, Immediate(target::UntaggedObject::kBarrierOverlapShift));
  andl(scratch, Address(THR, target::Thread::write_barrier_mask_offset()));
  testl(FieldAddress(value, target::Object::tags_offset()), scratch);
  if (spill_scratch) {
    popl(scratch);
  }
  j(ZERO, &done, kNearJump);

  Register object_for_call = object;
  if (value != kWriteBarrierValueReg) {
    // Unlikely. Only non-graph intrinsics.
    // TODO(rmacnak): Shuffle registers in intrinsics.
    pushl(kWriteBarrierValueReg);
    if (object == kWriteBarrierValueReg) {
      COMPILE_ASSERT(EAX != kWriteBarrierValueReg);
      COMPILE_ASSERT(ECX != kWriteBarrierValueReg);
      object_for_call = (value == EAX) ? ECX : EAX;
      pushl(object_for_call);
      movl(object_for_call, object);
    }
    movl(kWriteBarrierValueReg, value);
  }
  call(Address(THR, target::Thread::write_barrier_wrappers_thread_offset(
                        object_for_call)));
  if (value != kWriteBarrierValueReg) {
    if (object == kWriteBarrierValueReg) {
      popl(object_for_call);
    }
    popl(kWriteBarrierValueReg);
  }
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value,
                                         MemoryOrder memory_order) {
  if (memory_order == kRelease) {
    StoreRelease(value, dest.base(), dest.disp32());
  } else {
    movl(dest, value);
  }
#if defined(DEBUG)
  // We can't assert the incremental barrier is not needed here, only the
  // generational barrier. We sometimes omit the write barrier when 'value' is
  // a constant, but we don't eagerly mark 'value' and instead assume it is also
  // reachable via a constant pool, so it doesn't matter if it is not traced via
  // 'object'.
  Label done;
  BranchIfSmi(value, &done, kNearJump);
  testb(FieldAddress(value, target::Object::tags_offset()),
        Immediate(1 << target::UntaggedObject::kNewBit));
  j(ZERO, &done, Assembler::kNearJump);
  testb(FieldAddress(object, target::Object::tags_offset()),
        Immediate(1 << target::UntaggedObject::kOldAndNotRememberedBit));
  j(ZERO, &done, Assembler::kNearJump);
  Stop("Write barrier is required");
  Bind(&done);
#endif  // defined(DEBUG)
}

void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_be_smi,
                               Register scratch) {
  ASSERT(object != value);
  movl(Address(slot, 0), value);

  ASSERT(scratch != kNoRegister);
  ASSERT(scratch != object);
  ASSERT(scratch != value);
  ASSERT(scratch != slot);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare UntaggedObject::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    BranchIfSmi(value, &done, kNearJump);
  }
  movl(scratch, FieldAddress(object, target::Object::tags_offset()));
  shrl(scratch, Immediate(target::UntaggedObject::kBarrierOverlapShift));
  andl(scratch, Address(THR, target::Thread::write_barrier_mask_offset()));
  testl(FieldAddress(value, target::Object::tags_offset()), scratch);
  j(ZERO, &done, kNearJump);

  if ((object != kWriteBarrierObjectReg) || (value != kWriteBarrierValueReg) ||
      (slot != kWriteBarrierSlotReg)) {
    // Spill and shuffle unimplemented. Currently StoreIntoArray is only used
    // from StoreIndexInstr, which gets these exact registers from the register
    // allocator.
    UNIMPLEMENTED();
  }
  call(Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value,
                                         MemoryOrder memory_order) {
  ASSERT(IsOriginalObject(value));
  // Ignoring memory_order.
  // On intel stores have store-release behavior (i.e. stores are not
  // re-ordered with other stores).
  // We don't run TSAN on 32 bit systems.
  // Don't call StoreRelease here because we would have to load the immediate
  // into a temp register which causes spilling.
#if defined(TARGET_USES_THREAD_SANITIZER)
  if (memory_order == kRelease) {
    UNIMPLEMENTED();
  }
#endif
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

void Assembler::LoadSImmediate(XmmRegister dst, float value) {
  int32_t constant = bit_cast<int32_t, float>(value);
  pushl(Immediate(constant));
  movss(dst, Address(ESP, 0));
  addl(ESP, Immediate(target::kWordSize));
}

void Assembler::LoadDImmediate(XmmRegister dst, double value) {
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

void Assembler::CombineHashes(Register dst, Register other) {
  // hash += other_hash
  addl(dst, other);
  // hash += hash << 10
  movl(other, dst);
  shll(other, Immediate(10));
  addl(dst, other);
  // hash ^= hash >> 6
  movl(other, dst);
  shrl(other, Immediate(6));
  xorl(dst, other);
}

void Assembler::FinalizeHashForSize(intptr_t bit_size,
                                    Register dst,
                                    Register scratch) {
  ASSERT(bit_size > 0);  // Can't avoid returning 0 if there are no hash bits!
  // While any 32-bit hash value fits in X bits, where X > 32, the caller may
  // reasonably expect that the returned values fill the entire bit space.
  ASSERT(bit_size <= kBitsPerInt32);
  ASSERT(scratch != kNoRegister);
  // hash += hash << 3;
  movl(scratch, dst);
  shll(scratch, Immediate(3));
  addl(dst, scratch);
  // hash ^= hash >> 11;  // Logical shift, unsigned hash.
  movl(scratch, dst);
  shrl(scratch, Immediate(11));
  xorl(dst, scratch);
  // hash += hash << 15;
  movl(scratch, dst);
  shll(scratch, Immediate(15));
  addl(dst, scratch);
  // Size to fit.
  if (bit_size < kBitsPerInt32) {
    andl(dst, Immediate(Utils::NBitMask(bit_size)));
  }
  // return (hash == 0) ? 1 : hash;
  Label done;
  j(NOT_ZERO, &done, kNearJump);
  incl(dst);
  Bind(&done);
}

void Assembler::EnterFullSafepoint(Register scratch) {
  // We generate the same number of instructions whether or not the slow-path is
  // forced. This simplifies GenerateJitCallbackTrampolines.

  // Compare and swap the value at Thread::safepoint_state from unacquired
  // to acquired. On success, jump to 'success'; otherwise, fallthrough.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  pushl(EAX);
  movl(EAX, Immediate(target::Thread::full_safepoint_state_unacquired()));
  movl(scratch, Immediate(target::Thread::full_safepoint_state_acquired()));
  LockCmpxchgl(Address(THR, target::Thread::safepoint_state_offset()), scratch);
  movl(scratch, EAX);
  popl(EAX);
  cmpl(scratch, Immediate(target::Thread::full_safepoint_state_unacquired()));

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
    EnterFullSafepoint(scratch);
  }
}

void Assembler::ExitFullSafepoint(Register scratch,
                                  bool ignore_unwind_in_progress) {
  ASSERT(scratch != EAX);
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterFullSafepoint.

  // Compare and swap the value at Thread::safepoint_state from acquired
  // to unacquired. On success, jump to 'success'; otherwise, fallthrough.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  pushl(EAX);
  movl(EAX, Immediate(target::Thread::full_safepoint_state_acquired()));
  movl(scratch, Immediate(target::Thread::full_safepoint_state_unacquired()));
  LockCmpxchgl(Address(THR, target::Thread::safepoint_state_offset()), scratch);
  movl(scratch, EAX);
  popl(EAX);
  cmpl(scratch, Immediate(target::Thread::full_safepoint_state_acquired()));

  if (!FLAG_use_slow_path) {
    j(EQUAL, &done);
  }

  Bind(&slow_path);
  if (ignore_unwind_in_progress) {
    movl(scratch,
         Address(THR,
                 target::Thread::
                     exit_safepoint_ignore_unwind_in_progress_stub_offset()));
  } else {
    movl(scratch, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  }
  movl(scratch, FieldAddress(scratch, target::Code::entry_point_offset()));
  call(scratch);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(Register scratch,
                                            bool exit_safepoint,
                                            bool ignore_unwind_in_progress) {
  if (exit_safepoint) {
    ExitFullSafepoint(scratch, ignore_unwind_in_progress);
  } else {
    // flag only makes sense if we are leaving safepoint
    ASSERT(!ignore_unwind_in_progress);
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    movl(scratch, Address(THR, target::Thread::safepoint_state_offset()));
    andl(scratch, Immediate(target::Thread::full_safepoint_state_acquired()));
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

static constexpr intptr_t kNumberOfVolatileCpuRegisters = 3;
static const Register volatile_cpu_registers[kNumberOfVolatileCpuRegisters] = {
    EAX, ECX, EDX};

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(!entry.is_leaf());
  // Argument count is not checked here, but in the runtime entry for a more
  // informative error message.
  movl(ECX, compiler::Address(THR, entry.OffsetFromThread()));
  movl(EDX, compiler::Immediate(argument_count));
  call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

#define __ assembler_->

LeafRuntimeScope::LeafRuntimeScope(Assembler* assembler,
                                   intptr_t frame_size,
                                   bool preserve_registers)
    : assembler_(assembler), preserve_registers_(preserve_registers) {
  __ Comment("EnterCallRuntimeFrame");
  __ EnterFrame(0);

  if (preserve_registers_) {
    // Preserve volatile CPU registers.
    for (intptr_t i = 0; i < kNumberOfVolatileCpuRegisters; i++) {
      __ pushl(volatile_cpu_registers[i]);
    }

    // Preserve all XMM registers.
    __ subl(ESP, Immediate(kNumberOfXmmRegisters * kFpuRegisterSize));
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      __ movups(Address(ESP, offset), xmm_reg);
      offset += kFpuRegisterSize;
    }
  } else {
    // These registers must always be preserved.
    COMPILE_ASSERT(IsCalleeSavedRegister(THR));
  }

  __ ReserveAlignedFrameSpace(frame_size);
}

void LeafRuntimeScope::Call(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  ASSERT(argument_count == entry.argument_count());
  __ movl(EAX, compiler::Address(THR, entry.OffsetFromThread()));
  __ movl(compiler::Assembler::VMTagAddress(), EAX);
  __ call(EAX);
  __ movl(compiler::Assembler::VMTagAddress(),
          compiler::Immediate(VMTag::kDartTagId));
}

LeafRuntimeScope::~LeafRuntimeScope() {
  if (preserve_registers_) {
    // ESP might have been modified to reserve space for arguments
    // and ensure proper alignment of the stack frame.
    // We need to restore it before restoring registers.
    const intptr_t kPushedRegistersSize =
        kNumberOfVolatileCpuRegisters * target::kWordSize +
        kNumberOfXmmRegisters * kFpuRegisterSize;
    __ leal(ESP, Address(EBP, -kPushedRegistersSize));

    // Restore all XMM registers.
    // XMM registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      __ movups(xmm_reg, Address(ESP, offset));
      offset += kFpuRegisterSize;
    }
    __ addl(ESP, Immediate(offset));

    // Restore volatile CPU registers.
    for (intptr_t i = kNumberOfVolatileCpuRegisters - 1; i >= 0; i--) {
      __ popl(volatile_cpu_registers[i]);
    }
  }

  __ leave();
}

void Assembler::Call(const Code& target,
                     bool movable_target,
                     CodeEntryKind entry_kind) {
  LoadObject(CODE_REG, ToObject(target), movable_target);
  call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::CallVmStub(const Code& target) {
  const Object& target_as_object = CastHandle<Object, Code>(target);
  ASSERT(target::CanEmbedAsRawPointerInGeneratedCode(target_as_object));
  call(Address::Absolute(
      target::ToRawPointer(target_as_object) +
      target::Code::entry_point_offset(CodeEntryKind::kNormal) -
      kHeapObjectTag));
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
  if (bytes_needed != 0) {
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
                                     Label* trace,
                                     Register temp_reg,
                                     JumpDistance distance) {
  ASSERT(cid > 0);
  Address state_address(kNoRegister, 0);

  ASSERT(temp_reg != kNoRegister);
  LoadIsolateGroup(temp_reg);
  movl(temp_reg, Address(temp_reg, target::IsolateGroup::class_table_offset()));
  movl(temp_reg,
       Address(temp_reg,
               target::ClassTable::allocation_tracing_state_table_offset()));
  cmpb(Address(temp_reg,
               target::ClassTable::AllocationTracingStateSlotOffsetFor(cid)),
       Immediate(0));
  // We are tracing for this class, jump to the trace label which will use
  // the allocation stub.
  j(NOT_ZERO, trace, distance);
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
  ASSERT(Utils::IsAligned(instance_size,
                          target::ObjectAlignment::kObjectAlignment));
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp_reg, distance));
    movl(instance_reg, Address(THR, target::Thread::top_offset()));
    addl(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    cmpl(instance_reg, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure, distance);
    CheckAllocationCanary(instance_reg);
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
  ASSERT(failure != nullptr);
  ASSERT(temp_reg != kNoRegister);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, temp_reg, distance));
    movl(instance, Address(THR, target::Thread::top_offset()));
    movl(end_address, instance);

    addl(end_address, Immediate(instance_size));
    j(CARRY, failure);

    // Check if the allocation fits into the remaining space.
    // EAX: potential new object start.
    // EBX: potential next object start.
    cmpl(end_address, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure);
    CheckAllocationCanary(instance);

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

void Assembler::CopyMemoryWords(Register src,
                                Register dst,
                                Register size,
                                Register temp) {
  // This loop is equivalent to
  //   shrl(size, Immediate(target::kWordSizeLog2));
  //   rep_movsd();
  // but shows better performance on certain micro-benchmarks.
  Label loop, done;
  cmpl(size, Immediate(0));
  j(EQUAL, &done, kNearJump);
  Bind(&loop);
  movl(temp, Address(src, 0));
  addl(src, Immediate(target::kWordSize));
  movl(Address(dst, 0), temp);
  addl(dst, Immediate(target::kWordSize));
  subl(size, Immediate(target::kWordSize));
  j(NOT_ZERO, &loop, kNearJump);
  Bind(&done);
}

void Assembler::PushCodeObject() {
  DEBUG_ASSERT(IsNotTemporaryScopedHandle(code_));
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

void Assembler::LeaveDartFrame() {
  LeaveFrame();
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
  LeaveDartFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  // Already saved.
  COMPILE_ASSERT(IsCalleeSavedRegister(THR));

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
  ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
  ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
  movl(result, FieldAddress(object, target::Object::tags_offset()));
  shrl(result, Immediate(target::UntaggedObject::kClassIdTagPos));
}

void Assembler::LoadClassById(Register result, Register class_id) {
  ASSERT(result != class_id);

  const intptr_t table_offset =
      target::IsolateGroup::cached_class_table_table_offset();
  LoadIsolateGroup(result);
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
  ASSERT(target::UntaggedObject::kClassIdTagPos == 12);
  ASSERT(target::UntaggedObject::kClassIdTagSize == 20);
  // Untag optimistically. Tag bit is shifted into the CARRY.
  SmiUntag(object);
  j(NOT_CARRY, is_smi, kNearJump);
  // Load cid: can't use LoadClassId, object is untagged. Use TIMES_2 scale
  // factor in the addressing mode to compensate for this.
  movl(scratch, Address(object, TIMES_2,
                        target::Object::tags_offset() + kHeapObjectTag));
  shrl(scratch, Immediate(target::UntaggedObject::kClassIdTagPos));
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
        kSmiCid << target::UntaggedObject::kClassIdTagPos;

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
  Breakpoint();
  Bind(&matches);
#endif
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

void Assembler::RangeCheck(Register value,
                           Register temp,
                           intptr_t low,
                           intptr_t high,
                           RangeCheckCondition condition,
                           Label* target) {
  auto cc = condition == kIfInRange ? BELOW_EQUAL : ABOVE;
  Register to_check = value;
  if (temp != kNoRegister) {
    movl(temp, value);
    to_check = temp;
  }
  subl(to_check, Immediate(low));
  cmpl(to_check, Immediate(high - low));
  j(cc, target);
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_IA32)
