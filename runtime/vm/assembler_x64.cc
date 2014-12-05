// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/cpu.h"
#include "vm/heap.h"
#include "vm/locations.h"
#include "vm/memory_region.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

DEFINE_FLAG(bool, print_stop_message, true, "Print stop message.");
DECLARE_FLAG(bool, inline_alloc);


Assembler::Assembler(bool use_far_branches)
    : buffer_(),
      object_pool_(GrowableObjectArray::Handle()),
      patchable_pool_entries_(),
      prologue_offset_(-1),
      comments_(),
      allow_constant_pool_(true) {
  // Far branching mode is only needed and implemented for MIPS and ARM.
  ASSERT(!use_far_branches);
  Isolate* isolate = Isolate::Current();
  if (isolate != Dart::vm_isolate()) {
    object_pool_ = GrowableObjectArray::New(Heap::kOld);

    // These objects and labels need to be accessible through every pool-pointer
    // at the same index.
    object_pool_.Add(Object::null_object(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    // Not adding Object::null() to the index table. It is at index 0 in the
    // object pool, but the HashMap uses 0 to indicate not found.

    object_pool_.Add(Bool::True(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    object_pool_index_table_.Insert(ObjIndexPair(Bool::True().raw(), 1));

    object_pool_.Add(Bool::False(), Heap::kOld);
    patchable_pool_entries_.Add(kNotPatchable);
    object_pool_index_table_.Insert(ObjIndexPair(Bool::False().raw(), 2));

    const Smi& vacant = Smi::Handle(Smi::New(0xfa >> kSmiTagShift));

    StubCode* stub_code = isolate->stub_code();
    if (stub_code->UpdateStoreBuffer_entry() != NULL) {
      FindExternalLabel(&stub_code->UpdateStoreBufferLabel(), kNotPatchable);
    } else {
      object_pool_.Add(vacant, Heap::kOld);
      patchable_pool_entries_.Add(kNotPatchable);
    }

    if (stub_code->CallToRuntime_entry() != NULL) {
      FindExternalLabel(&stub_code->CallToRuntimeLabel(), kNotPatchable);
    } else {
      object_pool_.Add(vacant, Heap::kOld);
      patchable_pool_entries_.Add(kNotPatchable);
    }

    // Create fixed object pool entries for debugger stubs.
    if (stub_code->ICCallBreakpoint_entry() != NULL) {
      intptr_t index =
          FindExternalLabel(&stub_code->ICCallBreakpointLabel(),
                            kNotPatchable);
      ASSERT(index == kICCallBreakpointCPIndex);
    } else {
      object_pool_.Add(vacant, Heap::kOld);
      patchable_pool_entries_.Add(kNotPatchable);
    }
    if (stub_code->ClosureCallBreakpoint_entry() != NULL) {
      intptr_t index =
          FindExternalLabel(&stub_code->ClosureCallBreakpointLabel(),
                            kNotPatchable);
      ASSERT(index == kClosureCallBreakpointCPIndex);
    } else {
      object_pool_.Add(vacant, Heap::kOld);
      patchable_pool_entries_.Add(kNotPatchable);
    }
    if (stub_code->RuntimeCallBreakpoint_entry() != NULL) {
      intptr_t index =
          FindExternalLabel(&stub_code->RuntimeCallBreakpointLabel(),
                            kNotPatchable);
      ASSERT(index == kRuntimeCallBreakpointCPIndex);
    } else {
      object_pool_.Add(vacant, Heap::kOld);
      patchable_pool_entries_.Add(kNotPatchable);
    }
  }
}


void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
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


void Assembler::LoadExternalLabel(Register dst,
                                  const ExternalLabel* label,
                                  Patchability patchable,
                                  Register pp) {
  const int32_t offset =
      Array::element_offset(FindExternalLabel(label, patchable));
  LoadWordFromPoolOffset(dst, pp, offset - kHeapObjectTag);
}


void Assembler::call(const ExternalLabel* label) {
  {  // Encode movq(TMP, Immediate(label->address())), but always as imm64.
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(TMP, REX_W);
    EmitUint8(0xB8 | (TMP & 7));
    EmitInt64(label->address());
  }
  call(TMP);
}


void Assembler::CallPatchable(const ExternalLabel* label) {
  ASSERT(allow_constant_pool());
  intptr_t call_start = buffer_.GetPosition();
  LoadExternalLabel(TMP, label, kPatchable, PP);
  call(TMP);
  ASSERT((buffer_.GetPosition() - call_start) == kCallExternalLabelSize);
}


void Assembler::Call(const ExternalLabel* label, Register pp) {
  if (Isolate::Current() == Dart::vm_isolate()) {
    call(label);
  } else {
    LoadExternalLabel(TMP, label, kNotPatchable, pp);
    call(TMP);
  }
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


void Assembler::PushImmediate(const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    LoadImmediate(TMP, imm, pp);
    pushq(TMP);
  } else {
    pushq(imm);
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


void Assembler::setcc(Condition condition, ByteRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0x90 + condition);
  EmitUint8(0xC0 + dst);
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


void Assembler::movl(const Address& dst, const Immediate& imm) {
  movl(TMP, imm);
  movl(dst, TMP);
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
  FATAL("Use movzxw or movsxw instead.");
}


void Assembler::movw(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitOperandREX(src, dst, REX_NONE);
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
// older than 7.3.1-gg5 when disassembling a function's prologue (movq rbp, rsp)
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


void Assembler::movsxd(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x63);
  EmitOperand(dst & 7, operand);
}


void Assembler::movsxd(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x63);
  EmitOperand(dst & 7, src);
}


void Assembler::rep_movsb() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitUint8(0xA4);
}


void Assembler::leaq(Register dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, src, REX_W);
  EmitUint8(0x8D);
  EmitOperand(dst & 7, src);
}


void Assembler::cmovnoq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x41);
  EmitOperand(dst & 7, operand);
}


void Assembler::cmoveq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x44);
  EmitOperand(dst & 7, operand);
}


void Assembler::cmovgeq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x4D);
  EmitOperand(dst & 7, operand);
}


void Assembler::cmovlessq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x4C);
  EmitOperand(dst & 7, operand);
}



void Assembler::movss(XmmRegister dst, const Address& src) {
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst & 7, src);
}


void Assembler::movss(const Address& dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src & 7, dst);
}


void Assembler::movss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src & 7, dst);
}


void Assembler::movd(XmmRegister dst, Register src) {
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x6E);
  EmitOperand(dst & 7, Operand(src));
}


void Assembler::movd(Register dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x7E);
  EmitOperand(src & 7, Operand(dst));
}


void Assembler::addss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::subss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::mulss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::divss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::movsd(XmmRegister dst, const Address& src) {
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst & 7, src);
}


void Assembler::movsd(const Address& dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src & 7, dst);
}


void Assembler::movsd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitXmmRegisterOperand(src & 7, dst);
}


void Assembler::movaps(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x28);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::movups(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x10);
  EmitOperand(dst & 7, src);
}


void Assembler::movups(const Address& dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(src, dst);
  EmitUint8(0x0F);
  EmitUint8(0x11);
  EmitOperand(src & 7, dst);
}


void Assembler::addsd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::subsd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::mulsd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::divsd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::addpl(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xFE);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::subpl(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x66);
  EmitUint8(0x0F);
  EmitUint8(0xFA);
  EmitXmmRegisterOperand(dst, src);
}


void Assembler::addps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::subps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::divps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::mulps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::minps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5D);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::maxps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5F);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::andps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::andps(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitOperand(dst & 7, src);
}


void Assembler::orps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x56);
  EmitXmmRegisterOperand(dst & 7, src);
}

void Assembler::notps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_not_constant =
      { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&float_not_constant)), PP);
  xorps(dst, Address(TMP, 0));
}


void Assembler::negateps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_negate_constant =
      { 0x80000000, 0x80000000, 0x80000000, 0x80000000 };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&float_negate_constant)), PP);
  xorps(dst, Address(TMP, 0));
}


void Assembler::absps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_absolute_constant =
      { 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&float_absolute_constant)), PP);
  andps(dst, Address(TMP, 0));
}


void Assembler::zerowps(XmmRegister dst) {
  static const struct ALIGN16 {
    uint32_t a;
    uint32_t b;
    uint32_t c;
    uint32_t d;
  } float_zerow_constant =
      { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000 };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&float_zerow_constant)), PP);
  andps(dst, Address(TMP, 0));
}


void Assembler::cmppseq(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x0);
}


void Assembler::cmppsneq(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x4);
}


void Assembler::cmppslt(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x1);
}


void Assembler::cmppsle(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x2);
}


void Assembler::cmppsnlt(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x5);
}


void Assembler::cmppsnle(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC2);
  EmitXmmRegisterOperand(dst & 7, src);
  EmitUint8(0x6);
}


void Assembler::sqrtps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, dst);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst & 7, dst);
}


void Assembler::rsqrtps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, dst);
  EmitUint8(0x0F);
  EmitUint8(0x52);
  EmitXmmRegisterOperand(dst & 7, dst);
}


void Assembler::reciprocalps(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, dst);
  EmitUint8(0x0F);
  EmitUint8(0x53);
  EmitXmmRegisterOperand(dst & 7, dst);
}


void Assembler::movhlps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x12);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::movlhps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x16);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::unpcklps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x14);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::unpckhps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x15);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::unpcklpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x14);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::unpckhpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x15);
  EmitXmmRegisterOperand(dst & 7, src);
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
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC6);
  EmitXmmRegisterOperand(dst & 7, src);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}


void Assembler::addpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x58);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::negatepd(XmmRegister dst) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_negate_constant =
      { 0x8000000000000000LL, 0x8000000000000000LL };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&double_negate_constant)), PP);
  xorpd(dst, Address(TMP, 0));
}


void Assembler::subpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5C);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::mulpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x59);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::divpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5E);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::abspd(XmmRegister dst) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_absolute_const =
      { 0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL };
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&double_absolute_const)), PP);
  andpd(dst, Address(TMP, 0));
}


void Assembler::minpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5D);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::maxpd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5F);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::sqrtpd(XmmRegister dst) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, dst);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst & 7, dst);
}


void Assembler::cvtps2pd(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::cvtpd2ps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::shufpd(XmmRegister dst, XmmRegister src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xC6);
  EmitXmmRegisterOperand(dst & 7, src);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}


void Assembler::comisd(XmmRegister a, XmmRegister b) {
  ASSERT(a <= XMM15);
  ASSERT(b <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(a, b);
  EmitUint8(0x0F);
  EmitUint8(0x2F);
  EmitXmmRegisterOperand(a & 7, b);
}


void Assembler::movmskpd(Register dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x50);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::movmskps(Register dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x50);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::sqrtsd(XmmRegister dst, XmmRegister src) {
  ASSERT(dst <= XMM15);
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x51);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::xorpd(XmmRegister dst, const Address& src) {
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitOperandREX(dst, src, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitOperand(dst & 7, src);
}


void Assembler::xorpd(XmmRegister dst, XmmRegister src) {
  ASSERT(dst <= XMM15);
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::xorps(XmmRegister dst, const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitOperand(dst & 7, src);
}


void Assembler::xorps(XmmRegister dst, XmmRegister src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x57);
  EmitXmmRegisterOperand(dst & 7, src);
}

void Assembler::andpd(XmmRegister dst, const Address& src) {
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitOperandREX(dst, src, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x54);
  EmitOperand(dst & 7, src);
}


void Assembler::cvtsi2sdq(XmmRegister dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(dst <= XMM15);
  Operand operand(src);
  EmitUint8(0xF2);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x2A);
  EmitOperand(dst & 7, operand);
}


void Assembler::cvtsi2sdl(XmmRegister dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(dst <= XMM15);
  Operand operand(src);
  EmitUint8(0xF2);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0x2A);
  EmitOperand(dst & 7, operand);
}


void Assembler::cvttsd2siq(Register dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  Operand operand(dst);
  EmitREX_RB(dst, src, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0x2C);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::cvtss2sd(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF3);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::cvtsd2ss(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xF2);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x5A);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::pxor(XmmRegister dst, XmmRegister src) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0xEF);
  EmitXmmRegisterOperand(dst & 7, src);
}


void Assembler::roundsd(XmmRegister dst, XmmRegister src, RoundingMode mode) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitREX_RB(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x3A);
  EmitUint8(0x0B);
  EmitXmmRegisterOperand(dst & 7, src);
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


void Assembler::fildl(const Address& src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0xDF);
  EmitOperand(5, src);
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


void Assembler::cmpb(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(7, address, REX_NONE);
  EmitUint8(0x80);
  EmitOperand(7, address);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
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


void Assembler::CompareImmediate(Register reg, const Immediate& imm,
                                 Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    LoadImmediate(TMP, imm, pp);
    cmpq(reg, TMP);
  } else {
    cmpq(reg, imm);
  }
}


void Assembler::CompareImmediate(const Address& address, const Immediate& imm,
                                 Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    LoadImmediate(TMP, imm, pp);
    cmpq(address, TMP);
  } else {
    cmpq(address, imm);
  }
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


void Assembler::TestImmediate(Register dst, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm, pp);
    testq(dst, TMP);
  } else {
    testq(dst, imm);
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


void Assembler::andq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x23);
  EmitOperand(dst & 7, address);
}


void Assembler::andq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(4, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    andq(dst, TMP);
  }
}


void Assembler::AndImmediate(Register dst, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm, pp);
    andq(dst, TMP);
  } else {
    andq(dst, imm);
  }
}


void Assembler::orq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0B);
  EmitOperand(dst & 7, operand);
}


void Assembler::orq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x0B);
  EmitOperand(dst & 7, address);
}


void Assembler::orq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(1, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    orq(dst, TMP);
  }
}


void Assembler::OrImmediate(Register dst, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm, pp);
    orq(dst, TMP);
  } else {
    orq(dst, imm);
  }
}


void Assembler::xorq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x33);
  EmitOperand(dst & 7, operand);
}


void Assembler::xorq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x33);
  EmitOperand(dst & 7, address);
}


void Assembler::xorq(const Address& dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, dst, REX_W);
  EmitUint8(0x31);
  EmitOperand(src & 7, dst);
}


void Assembler::xorq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(6, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    xorq(dst, TMP);
  }
}


void Assembler::XorImmediate(Register dst, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm, pp);
    xorq(dst, TMP);
  } else {
    xorq(dst, imm);
  }
}


void Assembler::addl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x03);
  EmitOperand(dst & 7, operand);
}


void Assembler::addl(Register dst, const Immediate& imm) {
  ASSERT(imm.is_int32());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(0, Operand(dst), imm);
}


void Assembler::addl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_NONE);
  EmitUint8(0x03);
  EmitOperand(dst & 7, address);
}


void Assembler::addl(const Address& address, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, address, REX_NONE);
  EmitUint8(0x01);
  EmitOperand(src & 7, address);
}


void Assembler::adcl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x13);
  EmitOperand(dst & 7, operand);
}


void Assembler::adcl(Register dst, const Immediate& imm) {
  ASSERT(imm.is_int32());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(2, Operand(dst), imm);
}


void Assembler::adcl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_NONE);
  EmitUint8(0x13);
  EmitOperand(dst & 7, address);
}


void Assembler::addq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x03);
  EmitOperand(dst & 7, operand);
}


void Assembler::addq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x03);
  EmitOperand(dst & 7, address);
}


void Assembler::addq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(0, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    addq(dst, TMP);
  }
}


void Assembler::addq(const Address& address, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitOperandREX(0, address, REX_W);
    EmitComplex(0, Operand(address), imm);
  } else {
    movq(TMP, imm);
    addq(address, TMP);
  }
}


void Assembler::addq(const Address& address, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(src, address, REX_W);
  EmitUint8(0x01);
  EmitOperand(src & 7, address);
}


void Assembler::adcq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x13);
  EmitOperand(dst & 7, operand);
}


void Assembler::adcq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(2, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    adcq(dst, TMP);
  }
}


void Assembler::adcq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x13);
  EmitOperand(dst & 7, address);
}


void Assembler::subl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x2B);
  EmitOperand(dst & 7, operand);
}


void Assembler::subl(Register dst, const Immediate& imm) {
  ASSERT(imm.is_int32());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(3, Operand(dst), imm);
}


void Assembler::subl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_NONE);
  EmitUint8(0x2B);
  EmitOperand(dst & 7, address);
}


void Assembler::sbbl(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x1B);
  EmitOperand(dst & 7, operand);
}


void Assembler::sbbl(Register dst, const Immediate& imm) {
  ASSERT(imm.is_int32());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(3, Operand(dst), imm);
}


void Assembler::sbbl(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_NONE);
  EmitUint8(0x1B);
  EmitOperand(dst & 7, address);
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
  EmitOperand(7, Operand(reg));
}


void Assembler::divl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0xF7);
  EmitOperand(6, Operand(reg));
}


void Assembler::idivq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitUint8(0xF7);
  EmitOperand(7, Operand(reg));
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
  Operand operand(reg);
  EmitOperandREX(reg, operand, REX_NONE);
  EmitUint8(0x69);
  EmitOperand(reg & 7, Operand(reg));
  EmitImmediate(imm);
}


void Assembler::mull(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0xF7);
  EmitOperand(4, Operand(reg));
}


void Assembler::imulq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(dst & 7, operand);
}


void Assembler::imulq(Register reg, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    Operand operand(reg);
    EmitOperandREX(reg, operand, REX_W);
    EmitUint8(0x69);
    EmitOperand(reg & 7, Operand(reg));
    EmitImmediate(imm);
  } else {
    movq(TMP, imm);
    imulq(reg, TMP);
  }
}


void Assembler::MulImmediate(Register reg, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    ASSERT(reg != TMP);
    LoadImmediate(TMP, imm, pp);
    imulq(reg, TMP);
  } else {
    imulq(reg, imm);
  }
}


void Assembler::imulq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xAF);
  EmitOperand(dst & 7, address);
}


void Assembler::subq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x2B);
  EmitOperand(dst & 7, operand);
}


void Assembler::subq(Register reg, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(reg, REX_W);
    EmitComplex(5, Operand(reg), imm);
  } else {
    movq(TMP, imm);
    subq(reg, TMP);
  }
}


void Assembler::subq(Register reg, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x2B);
  EmitOperand(reg & 7, address);
}


void Assembler::subq(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_W);
  EmitUint8(0x29);
  EmitOperand(reg & 7, address);
}


void Assembler::subq(const Address& address, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitOperandREX(0, address, REX_W);
    EmitComplex(5, Operand(address), imm);
  } else {
    movq(TMP, imm);
    subq(address, TMP);
  }
}


void Assembler::sbbq(Register dst, Register src) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_W);
  EmitUint8(0x1B);
  EmitOperand(dst & 7, operand);
}


void Assembler::sbbq(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(3, Operand(dst), imm);
  } else {
    movq(TMP, imm);
    sbbq(dst, TMP);
  }
}


void Assembler::sbbq(Register dst, const Address& address) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(dst, address, REX_W);
  EmitUint8(0x1B);
  EmitOperand(dst & 7, address);
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


void Assembler::shldl(Register dst, Register src, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  Operand operand(src);
  EmitOperandREX(dst, operand, REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0xA4);
  EmitOperand(src & 7, Operand(dst));
  EmitUint8(imm.value() & 0xFF);
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


void Assembler::notl(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0xF7);
  EmitUint8(0xD0 | (reg & 7));
}


void Assembler::notq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitUint8(0xF7);
  EmitUint8(0xD0 | (reg & 7));
}

void Assembler::btq(Register base, Register offset) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(base);
  EmitOperandREX(offset, operand, REX_W);
  EmitUint8(0x0F);
  EmitUint8(0xA3);
  EmitOperand(offset & 7, operand);
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
  if (VerifiedMemory::enabled()) {
    near = Assembler::kFarJump;
  }
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
  Label no_jump;
  j(static_cast<Condition>(condition ^ 1), &no_jump);  // Negate condition.
  jmp(label);
  Bind(&no_jump);
}


void Assembler::J(Condition condition, const ExternalLabel* label,
                  Register pp) {
  Label no_jump;
  j(static_cast<Condition>(condition ^ 1), &no_jump);  // Negate condition.
  Jmp(label, pp);
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
  if (VerifiedMemory::enabled()) {
    near = Assembler::kFarJump;
  }
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
  {  // Encode movq(TMP, Immediate(label->address())), but always as imm64.
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(TMP, REX_W);
    EmitUint8(0xB8 | (TMP & 7));
    EmitInt64(label->address());
  }
  jmp(TMP);
}


void Assembler::JmpPatchable(const ExternalLabel* label, Register pp) {
  ASSERT(allow_constant_pool());
  intptr_t call_start = buffer_.GetPosition();
  LoadExternalLabel(TMP, label, kPatchable, pp);
  jmp(TMP);
  ASSERT((buffer_.GetPosition() - call_start) == kCallExternalLabelSize);
}


void Assembler::Jmp(const ExternalLabel* label, Register pp) {
  LoadExternalLabel(TMP, label, kNotPatchable, pp);
  jmp(TMP);
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


void Assembler::cpuid() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x0F);
  EmitUint8(0xA2);
}


void Assembler::CompareRegisters(Register a, Register b) {
  cmpq(a, b);
}


void Assembler::MoveRegister(Register to, Register from) {
  if (to != from) {
    movq(to, from);
  }
}


void Assembler::PopRegister(Register r) {
  popq(r);
}


void Assembler::AddImmediate(Register reg, const Immediate& imm, Register pp) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      incq(reg);
    } else {
      if (CanLoadImmediateFromPool(imm, pp)) {
        ASSERT(reg != TMP);
        LoadImmediate(TMP, imm, pp);
        addq(reg, TMP);
      } else {
        addq(reg, imm);
      }
    }
  } else {
    SubImmediate(reg, Immediate(-value), pp);
  }
}


void Assembler::AddImmediate(const Address& address, const Immediate& imm,
                             Register pp) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      incq(address);
    } else {
      if (CanLoadImmediateFromPool(imm, pp)) {
        LoadImmediate(TMP, imm, pp);
        addq(address, TMP);
      } else {
        addq(address, imm);
      }
    }
  } else {
    SubImmediate(address, Immediate(-value), pp);
  }
}


void Assembler::SubImmediate(Register reg, const Immediate& imm, Register pp) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      decq(reg);
    } else {
      if (CanLoadImmediateFromPool(imm, pp)) {
        ASSERT(reg != TMP);
        LoadImmediate(TMP, imm, pp);
        subq(reg, TMP);
      } else {
        subq(reg, imm);
      }
    }
  } else {
    AddImmediate(reg, Immediate(-value), pp);
  }
}


void Assembler::SubImmediate(const Address& address, const Immediate& imm,
                             Register pp) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      decq(address);
    } else {
      if (CanLoadImmediateFromPool(imm, pp)) {
        LoadImmediate(TMP, imm, pp);
        subq(address, TMP);
      } else {
        subq(address, imm);
      }
    }
  } else {
    AddImmediate(address, Immediate(-value), pp);
  }
}


void Assembler::Drop(intptr_t stack_elements) {
  ASSERT(stack_elements >= 0);
  if (stack_elements <= 4) {
    for (intptr_t i = 0; i < stack_elements; i++) {
      popq(TMP);
    }
    return;
  }
  addq(RSP, Immediate(stack_elements * kWordSize));
}


intptr_t Assembler::FindObject(const Object& obj, Patchability patchable) {
  // The object pool cannot be used in the vm isolate.
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());

  // If the object is not patchable, check if we've already got it in the
  // object pool.
  if (patchable == kNotPatchable) {
    // Special case for Object::null(), which is always at object_pool_ index 0
    // because Lookup() below returns 0 when the object is not mapped in the
    // table.
    if (obj.raw() == Object::null()) {
      return 0;
    }

    intptr_t idx = object_pool_index_table_.Lookup(obj.raw());
    if (idx != 0) {
      ASSERT(patchable_pool_entries_[idx] == kNotPatchable);
      return idx;
    }
  }

  object_pool_.Add(obj, Heap::kOld);
  patchable_pool_entries_.Add(patchable);
  if (patchable == kNotPatchable) {
    // The object isn't patchable. Record the index for fast lookup.
    object_pool_index_table_.Insert(
        ObjIndexPair(obj.raw(), object_pool_.Length() - 1));
  }
  return object_pool_.Length() - 1;
}


intptr_t Assembler::FindExternalLabel(const ExternalLabel* label,
                                      Patchability patchable) {
  // The object pool cannot be used in the vm isolate.
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());
  const uword address = label->address();
  ASSERT(Utils::IsAligned(address, 4));
  // The address is stored in the object array as a RawSmi.
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(address));
  if (patchable == kNotPatchable) {
    // If the call site is not patchable, we can try to re-use an existing
    // entry.
    return FindObject(smi, kNotPatchable);
  }
  // If the call is patchable, do not reuse an existing entry since each
  // reference may be patched independently.
  object_pool_.Add(smi, Heap::kOld);
  patchable_pool_entries_.Add(patchable);
  return object_pool_.Length() - 1;
}


// A set of VM objects that are present in every constant pool.
static bool IsAlwaysInConstantPool(const Object& object) {
  // TODO(zra): Evaluate putting all VM heap objects into the pool.
  return (object.raw() == Object::null())
      || (object.raw() == Bool::True().raw())
      || (object.raw() == Bool::False().raw());
}


bool Assembler::CanLoadFromObjectPool(const Object& object) {
  if (!allow_constant_pool()) {
    return IsAlwaysInConstantPool(object);
  }

  // TODO(zra, kmillikin): Also load other large immediates from the object
  // pool
  if (object.IsSmi()) {
    // If the raw smi does not fit into a 32-bit signed int, then we'll keep
    // the raw value in the object pool.
    return !Utils::IsInt(32, reinterpret_cast<int64_t>(object.raw()));
  }
  ASSERT(object.IsNotTemporaryScopedHandle());
  ASSERT(object.IsOld());
  return (Isolate::Current() != Dart::vm_isolate()) &&
         // Not in the VMHeap, OR is one of the VMHeap objects we put in every
         // object pool.
         (!object.InVMHeap() || IsAlwaysInConstantPool(object));
}


void Assembler::LoadWordFromPoolOffset(Register dst, Register pp,
                                       int32_t offset) {
  // This sequence must be of fixed size. AddressBaseImm32
  // forces the address operand to use a fixed-size imm32 encoding.
  movq(dst, Address::AddressBaseImm32(pp, offset));
}


void Assembler::LoadIsolate(Register dst) {
  movq(dst, Immediate(reinterpret_cast<uword>(Isolate::Current())));
}


void Assembler::LoadObject(Register dst, const Object& object, Register pp) {
  if (CanLoadFromObjectPool(object)) {
    const int32_t offset =
        Array::element_offset(FindObject(object, kNotPatchable));
    LoadWordFromPoolOffset(dst, pp, offset - kHeapObjectTag);
  } else {
    ASSERT((Isolate::Current() == Dart::vm_isolate()) ||
           object.IsSmi() ||
           object.InVMHeap());
    LoadImmediate(dst, Immediate(reinterpret_cast<int64_t>(object.raw())), pp);
  }
}


void Assembler::StoreObject(const Address& dst, const Object& object,
                            Register pp) {
  if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object, pp);
    movq(dst, TMP);
  } else {
    MoveImmediate(dst, Immediate(reinterpret_cast<int64_t>(object.raw())), pp);
  }
}


void Assembler::PushObject(const Object& object, Register pp) {
  if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object, pp);
    pushq(TMP);
  } else {
    PushImmediate(Immediate(reinterpret_cast<int64_t>(object.raw())), pp);
  }
}


void Assembler::CompareObject(Register reg, const Object& object, Register pp) {
  if (CanLoadFromObjectPool(object)) {
    const int32_t offset =
        Array::element_offset(FindObject(object, kNotPatchable));
    cmpq(reg, Address(pp, offset-kHeapObjectTag));
  } else {
    CompareImmediate(
        reg, Immediate(reinterpret_cast<int64_t>(object.raw())), pp);
  }
}


intptr_t Assembler::FindImmediate(int64_t imm) {
  ASSERT(Isolate::Current() != Dart::vm_isolate());
  ASSERT(!object_pool_.IsNull());
  const Smi& smi = Smi::Handle(reinterpret_cast<RawSmi*>(imm));
  return FindObject(smi, kNotPatchable);
}


bool Assembler::CanLoadImmediateFromPool(const Immediate& imm, Register pp) {
  if (!allow_constant_pool()) {
    return false;
  }
  return !imm.is_int32() &&
         (pp != kNoRegister) &&
         (Isolate::Current() != Dart::vm_isolate());
}


void Assembler::LoadImmediate(Register reg, const Immediate& imm, Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    // It's a 64-bit constant and we're not in the VM isolate, so load from
    // object pool.
    int64_t val = imm.value();
    // Save the bits that must be masked-off for the SmiTag
    int64_t val_smi_tag = val & kSmiTagMask;
    val &= ~kSmiTagMask;  // Mask off the tag bits.
    const int32_t offset = Array::element_offset(FindImmediate(val));
    LoadWordFromPoolOffset(reg, pp, offset - kHeapObjectTag);
    if (val_smi_tag != 0) {
      // Add back the tag bits.
      orq(reg, Immediate(val_smi_tag));
    }
  } else {
    movq(reg, imm);
  }
}


void Assembler::MoveImmediate(const Address& dst, const Immediate& imm,
                              Register pp) {
  if (CanLoadImmediateFromPool(imm, pp)) {
    LoadImmediate(TMP, imm, pp);
    movq(dst, TMP);
  } else {
    movq(dst, imm);
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


void Assembler::VerifyHeapWord(const Address& address) {
  if (VerifiedMemory::enabled()) {
    Register addr_reg = RDX;
    Register value = RBX;
    // Preserve registers.
    pushq(addr_reg);
    pushq(value);
    leaq(addr_reg, address);
    // ASSERT(*address == *(address + offset))
    movq(value, Address(addr_reg, 0));
    cmpq(value, Address(addr_reg, VerifiedMemory::offset()));
    Label ok;
    j(EQUAL, &ok);
    static const bool kFixedLengthEncoding = true;
    Stop("Write barrier verification failed", kFixedLengthEncoding);
    Bind(&ok);
    popq(value);
    popq(addr_reg);
  }
}


void Assembler::VerifiedWrite(const Address& dest, Register value) {
  VerifyHeapWord(dest);
  movq(dest, value);
  if (VerifiedMemory::enabled()) {
    Register temp = (value == RDX) ? RCX : RDX;
    pushq(temp);
    leaq(temp, dest);
    movq(Address(temp, VerifiedMemory::offset()), value);
    popq(temp);
  }
}


void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                bool can_value_be_smi) {
  ASSERT(object != value);
  VerifiedWrite(dest, value);
  Label done;
  if (can_value_be_smi) {
    StoreIntoObjectFilter(object, value, &done);
  } else {
    StoreIntoObjectFilterNoSmi(object, value, &done);
  }
  // A store buffer update is required.
  if (value != RDX) pushq(RDX);
  if (object != RDX) {
    movq(RDX, object);
  }
  StubCode* stub_code = Isolate::Current()->stub_code();
  Call(&stub_code->UpdateStoreBufferLabel(), PP);
  if (value != RDX) popq(RDX);
  Bind(&done);
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  VerifiedWrite(dest, value);
#if defined(DEBUG)
  Label done;
  pushq(value);
  StoreIntoObjectFilter(object, value, &done);
  Stop("Store buffer update is required");
  Bind(&done);
  popq(value);
#endif  // defined(DEBUG)
  // No store buffer update.
}


void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value,
                                         Register pp) {
  if (VerifiedMemory::enabled()) {
    VerifyHeapWord(dest);
    Register temp = (pp == RCX) ? RDX : RCX;
    pushq(temp);
    leaq(temp, dest);
    StoreObject(Address(temp, 0), value, pp);
    StoreObject(Address(temp, VerifiedMemory::offset()), value, pp);
    popq(temp);
  } else {
    StoreObject(dest, value, pp);
  }
  // TODO(koda): Use 'object', verify that generational barrier's not needed.
}


void Assembler::StoreIntoSmiField(const Address& dest, Register value) {
  VerifiedWrite(dest, value);
#if defined(DEBUG)
  Label done;
  testq(value, Immediate(kHeapObjectTag));
  j(ZERO, &done);
  Stop("Smi expected");
  Bind(&done);
#endif  // defined(DEBUG)
}


void Assembler::ZeroSmiField(const Address& dest) {
  // TODO(koda): Add VerifySmi once we distinguish initalization.
  VerifyHeapWord(dest);
  Immediate zero(Smi::RawValue(0));
  movq(dest, zero);
  if (VerifiedMemory::enabled()) {
    Register temp = RCX;
    pushq(temp);
    leaq(temp, dest);
    movq(Address(temp, VerifiedMemory::offset()), zero);
    popq(temp);
  }
}


void Assembler::IncrementSmiField(const Address& dest, int64_t increment) {
  // Note: FlowGraphCompiler::EdgeCounterIncrementSizeInBytes depends on
  // the length of this instruction sequence.
  // TODO(koda): Add VerifySmi once we distinguish initalization.
  VerifyHeapWord(dest);
  Immediate inc_imm(Smi::RawValue(increment));
  addq(dest, inc_imm);
  if (VerifiedMemory::enabled()) {
    Register temp = RCX;
    pushq(temp);
    leaq(temp, dest);
    addq(Address(temp, VerifiedMemory::offset()), inc_imm);
    popq(temp);
  }
}


void Assembler::DoubleNegate(XmmRegister d) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_negate_constant =
      {0x8000000000000000LL, 0x8000000000000000LL};
  LoadImmediate(
      TMP, Immediate(reinterpret_cast<intptr_t>(&double_negate_constant)), PP);
  xorpd(d, Address(TMP, 0));
}


void Assembler::DoubleAbs(XmmRegister reg) {
  static const struct ALIGN16 {
    uint64_t a;
    uint64_t b;
  } double_abs_constant =
      {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL};
  LoadImmediate(TMP,
      Immediate(reinterpret_cast<intptr_t>(&double_abs_constant)), PP);
  andpd(reg, Address(TMP, 0));
}


void Assembler::Stop(const char* message, bool fixed_length_encoding) {
  int64_t message_address = reinterpret_cast<int64_t>(message);
  if (FLAG_print_stop_message) {
    pushq(TMP);  // Preserve TMP register.
    pushq(RDI);  // Preserve RDI register.
    if (fixed_length_encoding) {
      AssemblerBuffer::EnsureCapacity ensured(&buffer_);
      EmitRegisterREX(RDI, REX_W);
      EmitUint8(0xB8 | (RDI & 7));
      EmitInt64(message_address);
    } else {
      LoadImmediate(RDI, Immediate(message_address), PP);
    }
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


void Assembler::EnterFrame(intptr_t frame_size) {
  if (prologue_offset_ == -1) {
    prologue_offset_ = CodeSize();
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


void Assembler::ReserveAlignedFrameSpace(intptr_t frame_space) {
  // Reserve space for arguments and align frame before entering
  // the C++ world.
  if (frame_space != 0) {
    subq(RSP, Immediate(frame_space));
  }
  if (OS::ActivationFrameAlignment() > 1) {
    andq(RSP, Immediate(~(OS::ActivationFrameAlignment() - 1)));
  }
}


void Assembler::PushRegisters(intptr_t cpu_register_set,
                              intptr_t xmm_register_set) {
  const intptr_t xmm_regs_count = RegisterSet::RegisterCount(xmm_register_set);
  if (xmm_regs_count > 0) {
    AddImmediate(RSP, Immediate(-xmm_regs_count * kFpuRegisterSize), PP);
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      if (RegisterSet::Contains(xmm_register_set, xmm_reg)) {
        movups(Address(RSP, offset), xmm_reg);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
  }

  // Store general purpose registers with the highest register number at the
  // lowest address. The order in which the registers are pushed must match the
  // order in which the registers are encoded in the safe point's stack map.
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfCpuRegisters; ++reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (RegisterSet::Contains(cpu_register_set, reg)) {
      pushq(reg);
    }
  }
}


void Assembler::PopRegisters(intptr_t cpu_register_set,
                             intptr_t xmm_register_set) {
  // General purpose registers have the highest register number at the
  // lowest address.
  for (intptr_t reg_idx = kNumberOfCpuRegisters - 1; reg_idx >= 0; --reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (RegisterSet::Contains(cpu_register_set, reg)) {
      popq(reg);
    }
  }

  const intptr_t xmm_regs_count = RegisterSet::RegisterCount(xmm_register_set);
  if (xmm_regs_count > 0) {
    // XMM registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfXmmRegisters; ++reg_idx) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(reg_idx);
      if (RegisterSet::Contains(xmm_register_set, xmm_reg)) {
        movups(xmm_reg, Address(RSP, offset));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
    AddImmediate(RSP, Immediate(offset), PP);
  }
}


void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  EnterFrame(0);

  // TODO(vegorov): avoid saving FpuTMP, it is used only as scratch.
  PushRegisters(CallingConventions::kVolatileCpuRegisters,
                CallingConventions::kVolatileXmmRegisters);

  ReserveAlignedFrameSpace(frame_space);
}


void Assembler::LeaveCallRuntimeFrame() {
  // RSP might have been modified to reserve space for arguments
  // and ensure proper alignment of the stack frame.
  // We need to restore it before restoring registers.
  const intptr_t kPushedCpuRegistersCount =
      RegisterSet::RegisterCount(CallingConventions::kVolatileCpuRegisters);
  const intptr_t kPushedXmmRegistersCount =
      RegisterSet::RegisterCount(CallingConventions::kVolatileXmmRegisters);
  const intptr_t kPushedRegistersSize =
      kPushedCpuRegistersCount * kWordSize +
      kPushedXmmRegistersCount * kFpuRegisterSize;
  leaq(RSP, Address(RBP, -kPushedRegistersSize));

  // TODO(vegorov): avoid saving FpuTMP, it is used only as scratch.
  PopRegisters(CallingConventions::kVolatileCpuRegisters,
               CallingConventions::kVolatileXmmRegisters);

  leave();
}


void Assembler::CallCFunction(const ExternalLabel* label) {
  // Reserve shadow space for outgoing arguments.
  if (CallingConventions::kShadowSpaceBytes != 0) {
    subq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
  call(label);
}


void Assembler::CallCFunction(Register reg) {
  // Reserve shadow space for outgoing arguments.
  if (CallingConventions::kShadowSpaceBytes != 0) {
    subq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
  call(reg);
}


void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}


void Assembler::LoadPoolPointer(Register pp) {
  Label next;
  call(&next);
  Bind(&next);

  // Load new pool pointer.
  const intptr_t object_pool_pc_dist =
      Instructions::HeaderSize() - Instructions::object_pool_offset() +
      CodeSize();
  popq(pp);
  movq(pp, Address(pp, -object_pool_pc_dist));
}


void Assembler::EnterDartFrame(intptr_t frame_size) {
  EnterFrame(0);

  Label dart_entry;
  call(&dart_entry);
  Bind(&dart_entry);
  // The runtime system assumes that the code marker address is
  // kEntryPointToPcMarkerOffset bytes from the entry.  If there is any code
  // generated before entering the frame, the address needs to be adjusted.
  const intptr_t object_pool_pc_dist =
      Instructions::HeaderSize() - Instructions::object_pool_offset() +
      CodeSize();
  const intptr_t offset = EntryPointToPcMarkerOffset() - CodeSize();
  if (offset != 0) {
    addq(Address(RSP, 0), Immediate(offset));
  }
  // Save caller's pool pointer
  pushq(PP);

  // Load callee's pool pointer.
  movq(PP, Address(RSP, 1 * kWordSize));
  movq(PP, Address(PP, -object_pool_pc_dist - offset));

  if (frame_size != 0) {
    subq(RSP, Immediate(frame_size));
  }
}


void Assembler::EnterDartFrameWithInfo(intptr_t frame_size,
                                       Register new_pp,
                                       Register pc_marker_override) {
  if (pc_marker_override == kNoRegister) {
    EnterDartFrame(frame_size);
  } else {
    EnterFrame(0);
    pushq(pc_marker_override);
    pushq(PP);
    movq(PP, new_pp);
    if (frame_size != 0) {
      subq(RSP, Immediate(frame_size));
    }
  }
}


void Assembler::LeaveDartFrame() {
  // Restore caller's PP register that was pushed in EnterDartFrame.
  movq(PP, Address(RBP, (kSavedCallerPpSlotFromFp * kWordSize)));
  LeaveFrame();
}


// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate.
void Assembler::EnterOsrFrame(intptr_t extra_size,
                              Register new_pp,
                              Register pc_marker_override) {
  if (pc_marker_override == kNoRegister) {
    Label dart_entry;
    call(&dart_entry);
    Bind(&dart_entry);
    // The runtime system assumes that the code marker address is
    // kEntryPointToPcMarkerOffset bytes from the entry.  Since there is no
    // code to set up the frame pointer, the address needs to be adjusted.
    const intptr_t object_pool_pc_dist =
        Instructions::HeaderSize() - Instructions::object_pool_offset() +
        CodeSize();
    const intptr_t offset = EntryPointToPcMarkerOffset() - CodeSize();
    if (offset != 0) {
      addq(Address(RSP, 0), Immediate(offset));
    }

    // Load callee's pool pointer.
    movq(PP, Address(RSP, 0));
    movq(PP, Address(PP, -object_pool_pc_dist - offset));

    popq(Address(RBP, kPcMarkerSlotFromFp * kWordSize));
  } else {
    movq(Address(RBP, kPcMarkerSlotFromFp * kWordSize), pc_marker_override);
    movq(PP, new_pp);
  }
  if (extra_size != 0) {
    subq(RSP, Immediate(extra_size));
  }
}


void Assembler::EnterStubFrame(bool load_pp) {
  EnterFrame(0);
  pushq(Immediate(0));  // Push 0 in the saved PC area for stub frames.
  pushq(PP);  // Save caller's pool pointer
  if (load_pp) {
    LoadPoolPointer(PP);
  }
}


void Assembler::LeaveStubFrame() {
  // Restore caller's PP register that was pushed in EnterStubFrame.
  movq(PP, Address(RBP, (kSavedCallerPpSlotFromFp * kWordSize)));
  LeaveFrame();
}


void Assembler::ComputeCounterAddressesForCid(intptr_t cid,
                                              Heap::Space space,
                                              Address* count_address,
                                              Address* size_address) {
  ASSERT(cid < kNumPredefinedCids);
  Register temp_reg = TMP;
  Isolate* isolate = Isolate::Current();
  ClassTable* class_table = isolate->class_table();
  const uword class_heap_stats_table_address =
      class_table->PredefinedClassHeapStatsTableAddress();
  const uword class_offset = cid * sizeof(ClassHeapStats);  // NOLINT
  const uword count_field_offset = (space == Heap::kNew)
      ? ClassHeapStats::allocated_since_gc_new_space_offset()
      : ClassHeapStats::allocated_since_gc_old_space_offset();
  const uword size_field_offset = (space == Heap::kNew)
      ? ClassHeapStats::allocated_size_since_gc_new_space_offset()
      : ClassHeapStats::allocated_size_since_gc_old_space_offset();
  movq(temp_reg, Immediate(class_heap_stats_table_address + class_offset));
  *count_address = Address(temp_reg, count_field_offset);
  *size_address = Address(temp_reg, size_field_offset);
}


void Assembler::UpdateAllocationStats(intptr_t cid,
                                      Heap::Space space) {
  ASSERT(cid > 0);
  if (cid < kNumPredefinedCids) {
    Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
    ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
    incq(count_address);
  } else {
    Register temp_reg = TMP;
    const uword class_offset = cid * sizeof(ClassHeapStats);  // NOLINT
    const uword count_field_offset = (space == Heap::kNew)
        ? ClassHeapStats::allocated_since_gc_new_space_offset()
        : ClassHeapStats::allocated_since_gc_old_space_offset();
    ClassTable* class_table = Isolate::Current()->class_table();
    movq(temp_reg, Immediate(class_table->ClassStatsTableAddress()));
    movq(temp_reg, Address(temp_reg, 0));
    incq(Address(temp_reg, class_offset + count_field_offset));
  }
}


void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              Register size_reg,
                                              Heap::Space space) {
  ASSERT(cid > 0);
  ASSERT(cid < kNumPredefinedCids);
  Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
  ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
  incq(count_address);
  addq(size_address, size_reg);
}


void Assembler::UpdateAllocationStatsWithSize(intptr_t cid,
                                              intptr_t size_in_bytes,
                                              Heap::Space space) {
  ASSERT(cid > 0);
  ASSERT(cid < kNumPredefinedCids);
  Address count_address(kNoRegister, 0), size_address(kNoRegister, 0);
  ComputeCounterAddressesForCid(cid, space, &count_address, &size_address);
  incq(count_address);
  addq(size_address, Immediate(size_in_bytes));
}


void Assembler::TryAllocate(const Class& cls,
                            Label* failure,
                            bool near_jump,
                            Register instance_reg,
                            Register pp) {
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc) {
    Heap* heap = Isolate::Current()->heap();
    const intptr_t instance_size = cls.instance_size();
    Heap::Space space = heap->SpaceForAllocation(cls.id());
    LoadImmediate(TMP, Immediate(heap->TopAddress(space)), pp);
    movq(instance_reg, Address(TMP, 0));
    AddImmediate(instance_reg, Immediate(instance_size), pp);
    // instance_reg: potential next object start.
    LoadImmediate(TMP, Immediate(heap->EndAddress(space)), pp);
    cmpq(instance_reg, Address(TMP, 0));
    j(ABOVE_EQUAL, failure, near_jump);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    LoadImmediate(TMP, Immediate(heap->TopAddress(space)), pp);
    movq(Address(TMP, 0), instance_reg);
    UpdateAllocationStats(cls.id(), space);
    ASSERT(instance_size >= kHeapObjectTag);
    AddImmediate(instance_reg, Immediate(kHeapObjectTag - instance_size), pp);
    uword tags = 0;
    tags = RawObject::SizeTag::update(instance_size, tags);
    ASSERT(cls.id() != kIllegalCid);
    tags = RawObject::ClassIdTag::update(cls.id(), tags);
    MoveImmediate(FieldAddress(instance_reg, Object::tags_offset()),
                  Immediate(tags), pp);
  } else {
    jmp(failure);
  }
}


void Assembler::TryAllocateArray(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 bool near_jump,
                                 Register instance,
                                 Register end_address) {
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc) {
    Isolate* isolate = Isolate::Current();
    Heap* heap = isolate->heap();
    Heap::Space space = heap->SpaceForAllocation(kArrayCid);
    movq(instance, Immediate(heap->TopAddress(space)));
    movq(instance, Address(instance, 0));
    movq(end_address, RAX);

    addq(end_address, Immediate(instance_size));
    j(CARRY, failure);

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    movq(TMP, Immediate(heap->EndAddress(space)));
    cmpq(end_address, Address(TMP, 0));
    j(ABOVE_EQUAL, failure);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    movq(TMP, Immediate(heap->TopAddress(space)));
    movq(Address(TMP, 0), end_address);
    addq(instance, Immediate(kHeapObjectTag));
    UpdateAllocationStatsWithSize(kArrayCid, instance_size, space);

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    uword tags = 0;
    tags = RawObject::ClassIdTag::update(cid, tags);
    tags = RawObject::SizeTag::update(instance_size, tags);
    movq(FieldAddress(instance, Array::tags_offset()), Immediate(tags));
  } else {
    jmp(failure);
  }
}

void Assembler::Align(int alignment, intptr_t offset) {
  ASSERT(Utils::IsPowerOfTwo(alignment));
  intptr_t pos = offset + buffer_.GetPosition();
  int mod = pos & (alignment - 1);
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


void Assembler::LoadClassId(Register result, Register object) {
  ASSERT(RawObject::kClassIdTagPos == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassIdTagPos / kBitsPerByte;
  movzxw(result, FieldAddress(object, class_id_offset));
}


void Assembler::LoadClassById(Register result, Register class_id, Register pp) {
  ASSERT(result != class_id);
  Isolate* isolate = Isolate::Current();
  LoadImmediate(result, Immediate(isolate->class_table()->TableAddress()), pp);
  movq(result, Address(result, 0));
  movq(result, Address(result, class_id, TIMES_8, 0));
}


void Assembler::LoadClass(Register result, Register object, Register pp) {
  LoadClassId(TMP, object);
  LoadClassById(result, TMP, pp);
}


void Assembler::CompareClassId(Register object, intptr_t class_id) {
  LoadClassId(TMP, object);
  cmpl(TMP, Immediate(class_id));
}


void Assembler::SmiUntagOrCheckClass(Register object,
                                     intptr_t class_id,
                                     Label* is_smi) {
  ASSERT(kSmiTagShift == 1);
  ASSERT(RawObject::kClassIdTagPos == 16);
  ASSERT(RawObject::kClassIdTagSize == 16);
  const intptr_t class_id_offset = Object::tags_offset() +
      RawObject::kClassIdTagPos / kBitsPerByte;

  // Untag optimistically. Tag bit is shifted into the CARRY.
  SmiUntag(object);
  j(NOT_CARRY, is_smi, kNearJump);
  // Load cid: can't use LoadClassId, object is untagged. Use TIMES_2 scale
  // factor in the addressing mode to compensate for this.
  movzxw(TMP, Address(object, TIMES_2, class_id_offset));
  cmpl(TMP, Immediate(class_id));
}


void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  ASSERT(result != object);

  // Load up a null object. We only need it so we can use LoadClassId on it in
  // the case that object is a Smi.
  LoadObject(result, Object::null_object(), PP);
  // Check if the object is a Smi.
  testq(object, Immediate(kSmiTagMask));
  // If the object *is* a Smi, use the null object instead.
  cmoveq(object, result);
  // Loads either the cid of the object if it isn't a Smi, or the cid of null
  // if it is a Smi, which will be ignored.
  LoadClassId(result, object);

  movq(object, Immediate(kSmiCid));
  // If object is a Smi, move the Smi cid into result. o/w leave alone.
  cmoveq(result, object);
  // Finally, tag the result.
  SmiTag(result);
}


Address Assembler::ElementAddressForIntIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             intptr_t index) {
  if (is_external) {
    return Address(array, index * index_scale);
  } else {
    const int64_t disp = static_cast<int64_t>(index) * index_scale +
        Instance::DataOffsetFor(cid);
    ASSERT(Utils::IsInt(32, disp));
    return FieldAddress(array, static_cast<int32_t>(disp));
  }
}


static ScaleFactor ToScaleFactor(intptr_t index_scale) {
  // Note that index is expected smi-tagged, (i.e, times 2) for all arrays with
  // index scale factor > 1. E.g., for Uint8Array and OneByteString the index is
  // expected to be untagged before accessing.
  ASSERT(kSmiTagShift == 1);
  switch (index_scale) {
    case 1: return TIMES_1;
    case 2: return TIMES_1;
    case 4: return TIMES_2;
    case 8: return TIMES_4;
    case 16: return TIMES_8;
    default:
      UNREACHABLE();
      return TIMES_1;
  }
}


Address Assembler::ElementAddressForRegIndex(bool is_external,
                                             intptr_t cid,
                                             intptr_t index_scale,
                                             Register array,
                                             Register index) {
  if (is_external) {
    return Address(array, index, ToScaleFactor(index_scale), 0);
  } else {
    return FieldAddress(array,
                        index,
                        ToScaleFactor(index_scale),
                        Instance::DataOffsetFor(cid));
  }
}


static const char* cpu_reg_names[kNumberOfCpuRegisters] = {
  "rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi",
  "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15"
};


const char* Assembler::RegisterName(Register reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfCpuRegisters));
  return cpu_reg_names[reg];
}


static const char* xmm_reg_names[kNumberOfXmmRegisters] = {
  "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7",
  "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15"
};


const char* Assembler::FpuRegisterName(FpuRegister reg) {
  ASSERT((0 <= reg) && (reg < kNumberOfXmmRegisters));
  return xmm_reg_names[reg];
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
