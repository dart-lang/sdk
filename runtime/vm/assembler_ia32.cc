// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/assembler.h"
#include "vm/heap.h"
#include "vm/memory_region.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");
DEFINE_FLAG(bool, code_comments, false,
            "Include comments into code and disassembly");


class DirectCallRelocation : public AssemblerFixup {
 public:
  void Process(const MemoryRegion& region, int position) {
    // Direct calls are relative to the following instruction on x86.
    int32_t pointer = region.Load<int32_t>(position);
    int32_t delta = region.start() + position + sizeof(int32_t);
    region.Store<int32_t>(position, pointer - delta);
  }
};


void Assembler::InitializeMemoryWithBreakpoints(uword data, int length) {
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


void Assembler::orl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0B);
  EmitOperand(dst, Operand(src));
}


void Assembler::orl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitComplex(1, Operand(dst), imm);
}


void Assembler::xorl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x33);
  EmitOperand(dst, Operand(src));
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
  EmitGenericShift(4, operand, shifter);
}


void Assembler::shrl(Register reg, const Immediate& imm) {
  EmitGenericShift(5, reg, imm);
}


void Assembler::shrl(Register operand, Register shifter) {
  EmitGenericShift(5, operand, shifter);
}


void Assembler::sarl(Register reg, const Immediate& imm) {
  EmitGenericShift(7, reg, imm);
}


void Assembler::sarl(Register operand, Register shifter) {
  EmitGenericShift(7, operand, shifter);
}


void Assembler::shld(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA5);
  EmitRegisterOperand(src, dst);
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
    int offset = label->Position() - buffer_.Size();
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
    int offset = label->Position() - buffer_.Size();
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


void Assembler::AddImmediate(Register reg, const Immediate& imm) {
  int value = imm.value();
  if (value > 0) {
    if (value == 1) {
      incl(reg);
    } else if (value != 0) {
      addl(reg, imm);
    }
  } else if (value < 0) {
    value = -value;
    if (value == 1) {
      decl(reg);
    } else if (value != 0) {
      subl(reg, Immediate(value));
    }
  }
}


void Assembler::LoadObject(Register dst, const Object& object) {
  if (object.IsSmi()) {
    movl(dst, Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsZoneHandle());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0xB8 + dst);
    buffer_.EmitObject(object);
  }
}


void Assembler::PushObject(const Object& object) {
  if (object.IsSmi()) {
    pushl(Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsZoneHandle());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0x68);
    buffer_.EmitObject(object);
  }
}


void Assembler::CompareObject(Register reg, const Object& object) {
  if (object.IsSmi()) {
    cmpl(reg, Immediate(reinterpret_cast<int32_t>(object.raw())));
  } else {
    ASSERT(object.IsZoneHandle());
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


void Assembler::StoreIntoObject(Register object,
                                const FieldAddress& dest,
                                Register value) {
  // TODO(iposva): Add write barrier.
  movl(dest, value);
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
  if (prolog_offset_ == -1) {
    prolog_offset_ = CodeSize();
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


void Assembler::CallRuntime(const RuntimeEntry& entry) {
  entry.Call(this);
}


void Assembler::Align(int alignment, int offset) {
  ASSERT(Utils::IsPowerOfTwo(alignment));
  int pos = offset + buffer_.GetPosition();
  int mod = pos & (alignment - 1);
  if (mod == 0) {
    return;
  }
  int bytes_needed = alignment - mod;
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
  int bound = buffer_.Size();
  ASSERT(!label->IsBound());  // Labels can only be bound once.
  while (label->IsLinked()) {
    int position = label->LinkPosition();
    int next = buffer_.Load<int32_t>(position);
    buffer_.Store<int32_t>(position, bound - (position + 4));
    label->position_ = next;
  }
  while (label->HasNear()) {
    int position = label->NearPosition();
    int offset = bound - (position + 1);
    ASSERT(Utils::IsInt(8, offset));
    buffer_.Store<int8_t>(position, offset);
  }
  label->BindTo(bound);
}


void Assembler::Stop(const char* message) {
  if (FLAG_print_stop_message) {
    pushl(EAX);  // Preserve EAX.
    movl(EAX, Immediate(reinterpret_cast<int32_t>(message)));
    call(&StubCode::PrintStopMessageLabel());  // Passing message in EAX.
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
  const int length = operand.length_;
  ASSERT(length > 0);
  // Emit the ModRM byte updated with the given RM value.
  ASSERT((operand.encoding_[0] & 0x38) == 0);
  EmitUint8(operand.encoding_[0] + (rm << 3));
  // Emit the rest of the encoded operand.
  for (int i = 1; i < length; i++) {
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


void Assembler::EmitLabel(Label* label, int instruction_size) {
  if (label->IsBound()) {
    int offset = label->Position() - buffer_.Size();
    ASSERT(offset <= 0);
    EmitInt32(offset - instruction_size);
  } else {
    EmitLabelLink(label);
  }
}


void Assembler::EmitLabelLink(Label* label) {
  ASSERT(!label->IsBound());
  int position = buffer_.Size();
  EmitInt32(label->position_);
  label->LinkTo(position);
}


void Assembler::EmitNearLabelLink(Label* label) {
  ASSERT(!label->IsBound());
  int position = buffer_.Size();
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
                                 Register operand,
                                 Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == ECX);
  EmitUint8(0xD3);
  EmitOperand(rm, Operand(operand));
}


void Assembler::LoadClassOfObject(Register result,
                                  Register object,
                                  Register scratch) {
  ASSERT(scratch != result);
  LoadClassIndexOfObject(scratch, object);

  movl(result, FieldAddress(CTX, Context::isolate_offset()));
  const intptr_t table_offset_in_isolate =
      Isolate::class_table_offset() + ClassTable::table_offset();
  movl(result, Address(result, table_offset_in_isolate));
  movl(result, Address(result, scratch, TIMES_4, 0));
}


void Assembler::LoadClassIndexOfObject(Register result, Register object) {
  ASSERT(RawObject::kClassTagBit == 16);
  ASSERT(RawObject::kClassTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassTagBit / kBitsPerByte;
  movzxw(result, FieldAddress(object, class_id_offset));
}


void Assembler::CompareClassOfObject(Register object,
                                     const Class& clazz,
                                     Register scratch) {
  LoadClassIndexOfObject(scratch, object);
  cmpl(scratch, Immediate(clazz.index()));
}


void Assembler::Comment(const char* comment) {
  if (FLAG_code_comments) {
    comments_.Add(new CodeComment(buffer_.GetPosition(),
                                  String::Handle(String::New(comment))));
  }
}


const Code::Comments& Assembler::GetCodeComments() const {
  Code::Comments& comments = Code::Comments::New(comments_.length());

  for (intptr_t i = 0; i < comments_.length(); i++) {
    comments.SetPCOffsetAt(i, comments_[i]->pc_offset());
    comments.SetCommentAt(i, comments_[i]->comment());
  }

  return comments;
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
