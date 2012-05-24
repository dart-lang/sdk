// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/heap.h"
#include "vm/memory_region.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");
DEFINE_FLAG(bool, code_comments, false,
            "Include comments into code and disassembly");


void Assembler::InitializeMemoryWithBreakpoints(uword data, int length) {
  memset(reinterpret_cast<void*>(data), Instr::kBreakPointInstruction, length);
}


void Assembler::call(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg);
  EmitOperandREX(2, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(2, operand);
}


void Assembler::call(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(2, address, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(2, address);
}


void Assembler::call(Label* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  static const int kSize = 5;
  EmitUint8(0xE8);
  EmitLabel(label, kSize);
}


void Assembler::call(const ExternalLabel* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  intptr_t call_start = buffer_.GetPosition();

  // Encode movq(TMP, Immediate(label->address())), but always as imm64.
  EmitRegisterREX(TMP, REX_W);
  EmitUint8(0xB8 | (TMP & 7));
  EmitInt64(label->address());

  // Encode call(TMP).
  Operand operand(TMP);
  EmitOperandREX(2, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(2, operand);

  ASSERT((buffer_.GetPosition() - call_start) == kCallExternalLabelSize);
}


void Assembler::pushq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0x50 | (reg & 7));
}


void Assembler::pushq(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(6, address, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(6, address);
}


void Assembler::pushq(const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0x68);
    EmitImmediate(imm);
  } else {
    movq(TMP, imm);
    pushq(TMP);
  }
}


void Assembler::popq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0x58 | (reg & 7));
}


void Assembler::popq(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(0, address, REX_NONE);
  EmitUint8(0x8F);
  EmitOperand(0, address);
}


void Assembler::movl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x8B);
  EmitOperand(dst & 7, operand);
}


void Assembler::movl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(dst);
  EmitOperandREX(0, operand, REX_NONE);
  EmitUint8(0xC7);
  EmitOperand(0, operand);
  ASSERT(imm.is_int32());
  EmitImmediate(imm);
}


void Assembler::movl(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_NONE);
  EmitUint8(0x8B);
  EmitOperand(dst & 7, src);
}


void Assembler::movl(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, dst, REX_NONE);
  EmitUint8(0x89);
  EmitOperand(src & 7, dst);
}


void Assembler::movzxb(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xB6);
  EmitOperand(dst & 7, operand);
}


void Assembler::movzxb(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xB6);
  EmitOperand(dst & 7, src);
}


void Assembler::movsxb(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xBE);
  EmitOperand(dst & 7, operand);
}


void Assembler::movsxb(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xBE);
  EmitOperand(dst & 7, src);
}


void Assembler::movb(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_NONE);
  EmitUint8(0x8A);
  EmitOperand(dst & 7, src);
}


void Assembler::movb(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(0, dst, REX_NONE);
  EmitUint8(0xC6);
  EmitOperand(0, dst);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
}


void Assembler::movb(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, dst, REX_NONE);
  EmitUint8(0x88);
  EmitOperand(src & 7, dst);
}


void Assembler::movzxw(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xB7);
  EmitOperand(dst & 7, operand);
}


void Assembler::movzxw(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xB7);
  EmitOperand(dst & 7, src);
}


void Assembler::movsxw(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xBF);
  EmitOperand(dst & 7, operand);
}


void Assembler::movsxw(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xBF);
  EmitOperand(dst & 7, src);
}


void Assembler::movw(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_NONE);
  EmitOperandSizeOverride();
  EmitUint8(0x8B);
  EmitOperand(dst & 7, src);
}


void Assembler::movw(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, dst, REX_NONE);
  EmitOperandSizeOverride();
  EmitUint8(0x89);
  EmitOperand(src & 7, dst);
}


void Assembler::movq(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (imm.is_int32()) {
    Operand operand(dst);
    EmitOperandREX(0, operand, REX_W);
    EmitUint8(0xC7);
    EmitOperand(0, operand);
  } else {
    EmitRegisterREX(dst, REX_W);
    EmitUint8(0xB8 | (dst & 7));
  }
  EmitImmediate(imm);
}


// Use 0x89 encoding (instead of 0x8B encoding), which is expected by gdb64
// older than 7.3.1-gg5 when disassembling a function's prolog (movq rbp, rsp)
// for proper unwinding of Dart frames (use --generate_gdb_symbols and -O0).
void Assembler::movq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(dst);
  EmitOperandREX(src, operand, REX_W);
  EmitUint8(0x89);
  EmitOperand(src & 7, operand);
}


void Assembler::movq(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x8B);
  EmitOperand(dst & 7, src);
}


void Assembler::movq(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, dst, REX_W);
  EmitUint8(0x89);
  EmitOperand(src & 7, dst);
}


void Assembler::movq(const Address& dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    Operand operand(dst);
    EmitOperandREX(0, operand, REX_W);
    EmitUint8(0xC7);
    EmitOperand(0, operand);
    EmitImmediate(imm);
  } else {
    movq(TMP, imm);
    movq(dst, TMP);
  }
}


void Assembler::movsxl(Register dst, const Address& src) {
  UNIMPLEMENTED();
}


void Assembler::leaq(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x8D);
  EmitOperand(dst & 7, src);
}


void Assembler::movss(XmmRegister dst, const Address& src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitOperandREX(0, src, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst & 7, src);
}


void Assembler::movss(const Address& dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitOperandREX(0, dst, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src & 7, dst);
}


void Assembler::movss(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src & 7, dst);
}


void Assembler::movd(XmmRegister dst, Register src) {
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x6E);
  EmitOperand(dst & 7, Operand(src));
}


void Assembler::movd(Register dst, XmmRegister src) {
  ASSERT(src <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x7E);
  EmitOperand(src & 7, Operand(dst));
}


void Assembler::addss(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subss(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulss(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divss(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::movsd(XmmRegister dst, const Address& src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitOperandREX(0, src, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst & 7, src);
}


void Assembler::movsd(const Address& dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitOperandREX(0, dst, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src & 7, dst);
}


void Assembler::movsd(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src & 7, dst);
}


void Assembler::addsd(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subsd(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::mulsd(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::divsd(XmmRegister dst, XmmRegister src) {
  // TODO(srdjan): implement and test XMM8 - XMM15.
  ASSERT(src <= XMM7);
  ASSERT(dst <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::comisd(XmmRegister a, XmmRegister b) {
  ASSERT(a <= XMM7);
  ASSERT(b <= XMM7);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0x2F);
  EmitXmmRegisterOperand(a, b);
}


void Assembler::xchgl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x87);
  EmitOperand(dst & 7, operand);
}


void Assembler::xchgq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x87);
  EmitOperand(dst & 7, operand);
}


void Assembler::cmpl(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitComplex(7, Operand(reg), imm);
}


void Assembler::cmpl(Register reg0, Register reg1) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg1);
  EmitOperandREX(reg0, operand, REX_NONE);
  EmitUint8(0x3B);
  EmitOperand(reg0 & 7, operand);
}


void Assembler::cmpl(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_NONE);
  EmitUint8(0x3B);
  EmitOperand(reg & 7, address);
}


void Assembler::cmpl(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(7, operand, REX_NONE);
  EmitComplex(7, operand, imm);
}


void Assembler::cmpq(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x39);
  EmitOperand(reg & 7, address);
}


void Assembler::cmpq(const Address& address, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    Operand operand(address);
    EmitOperandREX(7, operand, REX_W);
    EmitComplex(7, operand, imm);
  } else {
    movq(TMP, imm);
    cmpq(address, TMP);
  }
}


void Assembler::cmpq(Register reg, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(reg, REX_W);
    EmitComplex(7, Operand(reg), imm);
  } else {
    movq(TMP, imm);
    cmpq(reg, TMP);
  }
}


void Assembler::cmpq(Register reg0, Register reg1) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg1);
  EmitOperandREX(reg0, operand, REX_W);
  EmitUint8(0x3B);
  EmitOperand(reg0 & 7, operand);
}


void Assembler::cmpq(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x3B);
  EmitOperand(reg & 7, address);
}


void Assembler::testl(Register reg1, Register reg2) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg2);
  EmitOperandREX(reg1, operand, REX_NONE);
  EmitUint8(0x85);
  EmitOperand(reg1 & 7, operand);
}


void Assembler::testl(Register reg, const Immediate& imm) {
  // TODO(kasperl): Deal with registers r8-r15 using the short
  // encoding form of the immediate?

  // We are using RBP for the exception marker. See testl(Label*).
  ASSERT(reg != RBP);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  // For registers that have a byte variant (RAX, RBX, RCX, and RDX)
  // we only test the byte register to keep the encoding short.
  if (imm.is_uint8() && reg < 4) {
    // Use zero-extended 8-bit immediate.
    if (reg == RAX) {
      EmitUint8(0xA8);
    } else {
      EmitUint8(0xF6);
      EmitUint8(0xC0 + reg);
    }
    EmitUint8(imm.value() & 0xFF);
  } else {
    ASSERT(imm.is_int32());
    if (reg == RAX) {
      EmitUint8(0xA9);
    } else {
      EmitRegisterREX(reg, REX_NONE);
      EmitUint8(0xF7);
      EmitUint8(0xC0 | (reg & 7));
    }
    EmitImmediate(imm);
  }
}


void Assembler::testq(Register reg1, Register reg2) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg2);
  EmitOperandREX(reg1, operand, REX_W);
  EmitUint8(0x85);
  EmitOperand(reg1 & 7, operand);
}


void Assembler::testq(Register reg, const Immediate& imm) {
  // TODO(kasperl): Deal with registers r8-r15 using the short
  // encoding form of the immediate?

  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  // For registers that have a byte variant (RAX, RBX, RCX, and RDX)
  // we only test the byte register to keep the encoding short.
  if (imm.is_uint8() && reg < 4) {
    // Use zero-extended 8-bit immediate.
    if (reg == RAX) {
      EmitUint8(0xA8);
    } else {
      EmitUint8(0xF6);
      EmitUint8(0xC0 + reg);
    }
    EmitUint8(imm.value() & 0xFF);
  } else {
    ASSERT(imm.is_int32());
    if (reg == RAX) {
      EmitUint8(0xA9 | REX_W);
    } else {
      EmitRegisterREX(reg, REX_W);
      EmitUint8(0xF7);
      EmitUint8(0xC0 | (reg & 7));
    }
    EmitImmediate(imm);
  }
}


void Assembler::andl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x23);
  EmitOperand(dst & 7, operand);
}


void Assembler::andl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(4, Operand(dst), imm);
}


void Assembler::orl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x0B);
  EmitOperand(dst & 7, operand);
}


void Assembler::orl(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(1, Operand(dst), imm);
}


void Assembler::xorl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x33);
  EmitOperand(dst & 7, operand);
}


void Assembler::andq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x23);
  EmitOperand(dst & 7, operand);
}


void Assembler::andq(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_W);
  EmitComplex(4, Operand(dst), imm);
}


void Assembler::orq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0B);
  EmitOperand(dst & 7, operand);
}


void Assembler::orq(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_W);
  EmitComplex(1, Operand(dst), imm);
}


void Assembler::xorq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x33);
  EmitOperand(dst & 7, operand);
}


void Assembler::addl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x03);
  EmitOperand(dst & 7, operand);
}


void Assembler::addq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x03);
  EmitOperand(dst & 7, operand);
}


void Assembler::addl(const Address& address, const Immediate& imm) {
  UNIMPLEMENTED();
}


void Assembler::addq(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitComplex(0, Operand(reg), imm);
}


void Assembler::addq(const Address& address, const Immediate& imm) {
  UNIMPLEMENTED();
}


void Assembler::subl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x2B);
  EmitOperand(dst & 7, operand);
}


void Assembler::cdq() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x99);
}


void Assembler::cqo() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(RAX, REX_W);
  EmitUint8(0x99);
}


void Assembler::idivl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0xF7);
  EmitUint8(0xF8 | (reg & 7));
}


void Assembler::idivq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitUint8(0xF7);
  EmitUint8(0xF8 | (reg & 7));
}


void Assembler::imull(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(dst & 7, Operand(src));
}


void Assembler::imull(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0x69);
  EmitOperand(reg & 7, Operand(reg));
  EmitImmediate(imm);
}


void Assembler::imulq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(dst & 7, operand);
}


void Assembler::subq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x2B);
  EmitOperand(dst & 7, operand);
}


void Assembler::subq(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitComplex(5, Operand(reg), imm);
}


void Assembler::subq(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x2B);
  EmitOperand(reg & 7, address);
}


void Assembler::shll(Register reg, const Immediate& imm) {
  EmitGenericShift(false, 4, reg, imm);
}


void Assembler::shll(Register operand, Register shifter) {
  EmitGenericShift(false, 4, operand, shifter);
}


void Assembler::shrl(Register reg, const Immediate& imm) {
  EmitGenericShift(false, 5, reg, imm);
}


void Assembler::shrl(Register operand, Register shifter) {
  EmitGenericShift(false, 5, operand, shifter);
}


void Assembler::sarl(Register reg, const Immediate& imm) {
  EmitGenericShift(false, 7, reg, imm);
}


void Assembler::sarl(Register operand, Register shifter) {
  EmitGenericShift(false, 7, operand, shifter);
}


void Assembler::shlq(Register reg, const Immediate& imm) {
  EmitGenericShift(true, 4, reg, imm);
}


void Assembler::shlq(Register operand, Register shifter) {
  EmitGenericShift(true, 4, operand, shifter);
}


void Assembler::shrq(Register reg, const Immediate& imm) {
  EmitGenericShift(true, 5, reg, imm);
}


void Assembler::shrq(Register operand, Register shifter) {
  EmitGenericShift(true, 5, operand, shifter);
}


void Assembler::sarq(Register reg, const Immediate& imm) {
  EmitGenericShift(true, 7, reg, imm);
}


void Assembler::sarq(Register operand, Register shifter) {
  EmitGenericShift(true, 7, operand, shifter);
}


void Assembler::incl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(0, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(0, operand);
}


void Assembler::decl(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(1, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(1, operand);
}


void Assembler::incq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg);
  EmitOperandREX(0, operand, REX_W);
  EmitUint8(0xFF);
  EmitOperand(0, operand);
}


void Assembler::incq(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(0, operand, REX_W);
  EmitUint8(0xFF);
  EmitOperand(0, operand);
}


void Assembler::decq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg);
  EmitOperandREX(1, operand, REX_W);
  EmitUint8(0xFF);
  EmitOperand(1, operand);
}


void Assembler::decq(const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(1, operand, REX_W);
  EmitUint8(0xFF);
  EmitOperand(1, operand);
}


void Assembler::negl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0xF7);
  EmitOperand(3, Operand(reg));
}


void Assembler::negq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitUint8(0xF7);
  EmitOperand(3, Operand(reg));
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
  Label no_jump;
  j(static_cast<Condition>(condition ^ 1), &no_jump);  // Negate condition.
  jmp(label);
  Bind(&no_jump);
}


void Assembler::jmp(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg);
  EmitOperandREX(4, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(4, operand);
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
  intptr_t call_start = buffer_.GetPosition();

  // Encode movq(TMP, Immediate(label->address())), but always as imm64.
  EmitRegisterREX(TMP, REX_W);
  EmitUint8(0xB8 | (TMP & 7));
  EmitInt64(label->address());

  // Encode jmp(TMP).
  Operand operand(TMP);
  EmitOperandREX(4, operand, REX_NONE);
  EmitUint8(0xFF);
  EmitOperand(4, operand);

  ASSERT((buffer_.GetPosition() - call_start) == kCallExternalLabelSize);
}


void Assembler::lock() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF0);
}


void Assembler::cmpxchgl(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0xB1);
  EmitOperand(reg & 7, address);
}


void Assembler::cmpxchgq(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xB1);
  EmitOperand(reg & 7, address);
}


void Assembler::AddImmediate(Register reg, const Immediate& imm) {
  int64_t value = imm.value();
  if (value > 0) {
    if (value == 1) {
      incq(reg);
    } else if (value != 0) {
      addq(reg, imm);
    }
  } else if (value < 0) {
    value = -value;
    if (value == 1) {
      decq(reg);
    } else if (value != 0) {
      subq(reg, Immediate(value));
    }
  }
}


void Assembler::Drop(intptr_t stack_elements) {
  ASSERT(stack_elements >= 0);
  if (stack_elements > 0) {
    // TODO(fschneider): When optimizing for code size, we could
    // consider using pop for stack_elements < 4 instead.
    addq(RSP, Immediate(stack_elements * kWordSize));
  }
}


void Assembler::LoadObject(Register dst, const Object& object) {
  if (object.IsSmi()) {
    movq(dst, Immediate(reinterpret_cast<int64_t>(object.raw())));
  } else {
    ASSERT(object.IsZoneHandle());
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitUint8(0xB8 | (dst & 7));
    buffer_.EmitObject(object);
  }
}


void Assembler::PushObject(const Object& object) {
  if (object.IsSmi()) {
    pushq(Immediate(reinterpret_cast<int64_t>(object.raw())));
  } else {
    LoadObject(TMP, object);
    pushq(TMP);
  }
}


void Assembler::CompareObject(Register reg, const Object& object) {
  if (object.IsSmi()) {
    cmpq(reg, Immediate(reinterpret_cast<int64_t>(object.raw())));
  } else {
    ASSERT(reg != TMP);
    LoadObject(TMP, object);
    cmpq(reg, TMP);
  }
}


void Assembler::StoreIntoObject(Register object,
                                const FieldAddress& dest,
                                Register value) {
  // TODO(iposva): Add write barrier.
  movq(dest, value);
}


void Assembler::Stop(const char* message) {
  int64_t message_address = reinterpret_cast<int64_t>(message);
  if (FLAG_print_stop_message) {
    pushq(TMP);  // Preserve TMP register.
    pushq(RDI);  // Preserve RDI register.
    movq(RDI, Immediate(message_address));
    call(&StubCode::PrintStopMessageLabel());
    popq(RDI);  // Restore RDI register.
    popq(TMP);  // Restore TMP register.
  } else {
    // Emit the lower half and the higher half of the message address as
    // immediate operands in the test rax instructions.
    testl(RAX, Immediate(Utils::Low32Bits(message_address)));
    testl(RAX, Immediate(Utils::High32Bits(message_address)));
  }
  // Emit the int3 instruction.
  int3();  // Execution can be resumed with the 'cont' command in gdb.
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


void Assembler::EnterFrame(intptr_t frame_size) {
  if (prolog_offset_ == -1) {
    prolog_offset_ = CodeSize();
  }
  pushq(RBP);
  movq(RBP, RSP);
  if (frame_size != 0) {
    Immediate frame_space(frame_size);
    subq(RSP, frame_space);
  }
}


void Assembler::LeaveFrame() {
  movq(RSP, RBP);
  popq(RBP);
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


void Assembler::EmitXmmRegisterOperand(int rm, XmmRegister xmm_reg) {
  Operand operand;
  operand.SetModRM(3, static_cast<Register>(xmm_reg));
  EmitOperand(rm, operand);
}


void Assembler::EmitImmediate(const Immediate& imm) {
  if (imm.is_int32()) {
    EmitInt32(static_cast<int32_t>(imm.value()));
  } else {
    EmitInt64(imm.value());
  }
}


void Assembler::EmitComplex(int rm,
                            const Operand& operand,
                            const Immediate& immediate) {
  ASSERT(rm >= 0 && rm < 8);
  ASSERT(immediate.is_int32());
  if (immediate.is_int8()) {
    // Use sign-extended 8-bit immediate.
    EmitUint8(0x83);
    EmitOperand(rm, operand);
    EmitUint8(immediate.value() & 0xFF);
  } else if (operand.IsRegister(RAX)) {
    // Use short form if the destination is rax.
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


void Assembler::EmitGenericShift(bool wide,
                                 int rm,
                                 Register reg,
                                 const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  if (wide) {
    EmitRegisterREX(reg, REX_W);
  } else {
    EmitRegisterREX(reg, REX_NONE);
  }
  if (imm.value() == 1) {
    EmitUint8(0xD1);
    EmitOperand(rm, Operand(reg));
  } else {
    EmitUint8(0xC1);
    EmitOperand(rm, Operand(reg));
    EmitUint8(imm.value() & 0xFF);
  }
}


void Assembler::EmitGenericShift(bool wide,
                                 int rm,
                                 Register operand,
                                 Register shifter) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(shifter == RCX);
  if (wide) {
    EmitRegisterREX(operand, REX_W);
  } else {
    EmitRegisterREX(operand, REX_NONE);
  }
  EmitUint8(0xD3);
  EmitOperand(rm, Operand(operand));
}


void Assembler::Comment(const char* format, ...) {
  if (FLAG_code_comments) {
    char buffer[1024];

    va_list args;
    va_start(args, format);
    OS::VSNPrint(buffer, sizeof(buffer), format, args);
    va_end(args);

    comments_.Add(new CodeComment(buffer_.GetPosition(),
                                  String::Handle(String::New(buffer))));
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

#endif  // defined TARGET_ARCH_X64
