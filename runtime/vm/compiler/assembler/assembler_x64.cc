// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_X64)

#define SHOULD_NOT_INCLUDE_RUNTIME

#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/locations.h"
#include "vm/instructions.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);
DECLARE_FLAG(bool, precompiled_mode);
DECLARE_FLAG(bool, use_slow_path);

namespace compiler {

Assembler::Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches)
    : AssemblerBase(object_pool_builder), constant_pool_allowed_(false) {
  // Far branching mode is only needed and implemented for ARM.
  ASSERT(!use_far_branches);

  generate_invoke_write_barrier_wrapper_ = [&](Register reg) {
    call(Address(THR,
                 target::Thread::write_barrier_wrappers_thread_offset(reg)));
  };
  generate_invoke_array_write_barrier_ = [&]() {
    call(
        Address(THR, target::Thread::array_write_barrier_entry_point_offset()));
  };
}

void Assembler::call(Label* label) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  static const int kSize = 5;
  EmitUint8(0xE8);
  EmitLabel(label, kSize);
}

void Assembler::LoadNativeEntry(
    Register dst,
    const ExternalLabel* label,
    ObjectPoolBuilderEntry::Patchability patchable) {
  const intptr_t index =
      object_pool_builder().FindNativeFunction(label, patchable);
  LoadWordFromPoolIndex(dst, index);
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

void Assembler::CallPatchable(const Code& target, CodeEntryKind entry_kind) {
  ASSERT(constant_pool_allowed());
  const intptr_t idx = object_pool_builder().AddObject(
      ToObject(target), ObjectPoolBuilderEntry::kPatchable);
  LoadWordFromPoolIndex(CODE_REG, idx);
  call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::CallWithEquivalence(const Code& target,
                                    const Object& equivalence,
                                    CodeEntryKind entry_kind) {
  ASSERT(constant_pool_allowed());
  const intptr_t idx =
      object_pool_builder().FindObject(ToObject(target), equivalence);
  LoadWordFromPoolIndex(CODE_REG, idx);
  call(FieldAddress(CODE_REG, target::Code::entry_point_offset(entry_kind)));
}

void Assembler::Call(const Code& target) {
  ASSERT(constant_pool_allowed());
  const intptr_t idx = object_pool_builder().FindObject(
      ToObject(target), ObjectPoolBuilderEntry::kNotPatchable);
  LoadWordFromPoolIndex(CODE_REG, idx);
  call(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

void Assembler::CallToRuntime() {
  call(Address(THR, target::Thread::call_to_runtime_entry_point_offset()));
}

void Assembler::pushq(Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(0x50 | (reg & 7));
}

void Assembler::pushq(const Immediate& imm) {
  if (imm.is_int8()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitUint8(0x6A);
    EmitUint8(imm.value() & 0xFF);
  } else if (imm.is_int32()) {
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

void Assembler::setcc(Condition condition, ByteRegister dst) {
  ASSERT(dst != kNoByteRegister);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (dst >= 8) {
    EmitUint8(REX_PREFIX | (((dst & 0x08) != 0) ? REX_B : REX_NONE));
  }
  EmitUint8(0x0F);
  EmitUint8(0x90 + condition);
  EmitUint8(0xC0 + (dst & 0x07));
}

void Assembler::EnterSafepoint() {
  // We generate the same number of instructions whether or not the slow-path is
  // forced, to simplify GenerateJitCallbackTrampolines.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  // Compare and swap the value at Thread::safepoint_state from unacquired to
  // acquired. If the CAS fails, go to a slow-path stub.
  pushq(RAX);
  movq(RAX, Immediate(target::Thread::safepoint_state_unacquired()));
  movq(TMP, Immediate(target::Thread::safepoint_state_acquired()));
  LockCmpxchgq(Address(THR, target::Thread::safepoint_state_offset()), TMP);
  movq(TMP, RAX);
  popq(RAX);
  cmpq(TMP, Immediate(target::Thread::safepoint_state_unacquired()));

  if (!FLAG_use_slow_path) {
    j(EQUAL, &done);
  }

  Bind(&slow_path);
  movq(TMP, Address(THR, target::Thread::enter_safepoint_stub_offset()));
  movq(TMP, FieldAddress(TMP, target::Code::entry_point_offset()));

  // Use call instead of CallCFunction to avoid having to clean up shadow space
  // afterwards. This is possible because the safepoint stub does not use the
  // shadow space as scratch and has no arguments.
  call(TMP);

  Bind(&done);
}

void Assembler::TransitionGeneratedToNative(Register destination_address,
                                            Register new_exit_frame,
                                            Register new_exit_through_ffi,
                                            bool enter_safepoint) {
  // Save exit frame information to enable stack walking.
  movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
       new_exit_frame);

  movq(compiler::Address(THR,
                         compiler::target::Thread::exit_through_ffi_offset()),
       new_exit_through_ffi);

  movq(Assembler::VMTagAddress(), destination_address);
  movq(Address(THR, target::Thread::execution_state_offset()),
       Immediate(target::Thread::native_execution_state()));

  if (enter_safepoint) {
    EnterSafepoint();
  }
}

void Assembler::LeaveSafepoint() {
  // We generate the same number of instructions whether or not the slow-path is
  // forced, for consistency with EnterSafepoint.
  Label done, slow_path;
  if (FLAG_use_slow_path) {
    jmp(&slow_path);
  }

  // Compare and swap the value at Thread::safepoint_state from acquired to
  // unacquired. On success, jump to 'success'; otherwise, fallthrough.

  pushq(RAX);
  movq(RAX, Immediate(target::Thread::safepoint_state_acquired()));
  movq(TMP, Immediate(target::Thread::safepoint_state_unacquired()));
  LockCmpxchgq(Address(THR, target::Thread::safepoint_state_offset()), TMP);
  movq(TMP, RAX);
  popq(RAX);
  cmpq(TMP, Immediate(target::Thread::safepoint_state_acquired()));

  if (!FLAG_use_slow_path) {
    j(EQUAL, &done);
  }

  Bind(&slow_path);
  movq(TMP, Address(THR, target::Thread::exit_safepoint_stub_offset()));
  movq(TMP, FieldAddress(TMP, target::Code::entry_point_offset()));

  // Use call instead of CallCFunction to avoid having to clean up shadow space
  // afterwards. This is possible because the safepoint stub does not use the
  // shadow space as scratch and has no arguments.
  call(TMP);

  Bind(&done);
}

void Assembler::TransitionNativeToGenerated(bool leave_safepoint) {
  if (leave_safepoint) {
    LeaveSafepoint();
  } else {
#if defined(DEBUG)
    // Ensure we've already left the safepoint.
    movq(TMP, Address(THR, target::Thread::safepoint_state_offset()));
    andq(TMP, Immediate((1 << target::Thread::safepoint_state_inside_bit())));
    Label ok;
    j(ZERO, &ok);
    Breakpoint();
    Bind(&ok);
#endif
  }

  movq(Assembler::VMTagAddress(), Immediate(target::Thread::vm_tag_dart_id()));
  movq(Address(THR, target::Thread::execution_state_offset()),
       Immediate(target::Thread::generated_execution_state()));

  // Reset exit frame information in Isolate's mutator thread structure.
  movq(Address(THR, target::Thread::top_exit_frame_info_offset()),
       Immediate(0));
  movq(compiler::Address(THR,
                         compiler::target::Thread::exit_through_ffi_offset()),
       compiler::Immediate(0));
}

void Assembler::EmitQ(int reg,
                      const Address& address,
                      int opcode,
                      int prefix2,
                      int prefix1) {
  ASSERT(reg <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitOperandREX(reg, address, REX_W);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitOperand(reg & 7, address);
}

void Assembler::EmitL(int reg,
                      const Address& address,
                      int opcode,
                      int prefix2,
                      int prefix1) {
  ASSERT(reg <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitOperandREX(reg, address, REX_NONE);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitOperand(reg & 7, address);
}

void Assembler::EmitW(Register reg,
                      const Address& address,
                      int opcode,
                      int prefix2,
                      int prefix1) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitOperandSizeOverride();
  EmitOperandREX(reg, address, REX_NONE);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitOperand(reg & 7, address);
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

void Assembler::movl(const Address& dst, const Immediate& imm) {
  movl(TMP, imm);
  movl(dst, TMP);
}

void Assembler::movb(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(0, dst, REX_NONE);
  EmitUint8(0xC6);
  EmitOperand(0, dst);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::movw(Register dst, const Address& src) {
  // This would leave 16 bits above the 2 byte value undefined.
  // If we ever want to purposefully have those undefined, remove this.
  // TODO(40210): Allow this.
  FATAL("Use movzxw or movsxw instead.");
}

void Assembler::movw(const Address& dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitOperandREX(0, dst, REX_NONE);
  EmitUint8(0xC7);
  EmitOperand(0, dst);
  EmitUint8(imm.value() & 0xFF);
  EmitUint8((imm.value() >> 8) & 0xFF);
}

void Assembler::movq(Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (imm.is_uint32()) {
    // Pick single byte B8 encoding if possible. If dst < 8 then we also omit
    // the Rex byte.
    EmitRegisterREX(dst, REX_NONE);
    EmitUint8(0xB8 | (dst & 7));
    EmitUInt32(imm.value());
  } else if (imm.is_int32()) {
    // Sign extended C7 Cx encoding if we have a negative input.
    Operand operand(dst);
    EmitOperandREX(0, operand, REX_W);
    EmitUint8(0xC7);
    EmitOperand(0, operand);
    EmitImmediate(imm);
  } else {
    // Full 64 bit immediate encoding.
    EmitRegisterREX(dst, REX_W);
    EmitUint8(0xB8 | (dst & 7));
    EmitImmediate(imm);
  }
}

void Assembler::movq(const Address& dst, const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitOperandREX(0, dst, REX_W);
    EmitUint8(0xC7);
    EmitOperand(0, dst);
    EmitImmediate(imm);
  } else {
    movq(TMP, imm);
    movq(dst, TMP);
  }
}

void Assembler::EmitSimple(int opcode, int opcode2, int opcode3) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(opcode);
  if (opcode2 != -1) {
    EmitUint8(opcode2);
    if (opcode3 != -1) {
      EmitUint8(opcode3);
    }
  }
}

void Assembler::EmitQ(int dst, int src, int opcode, int prefix2, int prefix1) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitRegRegRex(dst, src, REX_W);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitRegisterOperand(dst & 7, src);
}

void Assembler::EmitL(int dst, int src, int opcode, int prefix2, int prefix1) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitRegRegRex(dst, src);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitRegisterOperand(dst & 7, src);
}

void Assembler::EmitW(Register dst,
                      Register src,
                      int opcode,
                      int prefix2,
                      int prefix1) {
  ASSERT(src <= R15);
  ASSERT(dst <= R15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (prefix1 >= 0) {
    EmitUint8(prefix1);
  }
  EmitOperandSizeOverride();
  EmitRegRegRex(dst, src);
  if (prefix2 >= 0) {
    EmitUint8(prefix2);
  }
  EmitUint8(opcode);
  EmitRegisterOperand(dst & 7, src);
}

#define UNARY_XMM_WITH_CONSTANT(name, constant, op)                            \
  void Assembler::name(XmmRegister dst, XmmRegister src) {                     \
    movq(TMP, Address(THR, target::Thread::constant##_address_offset()));      \
    if (dst == src) {                                                          \
      op(dst, Address(TMP, 0));                                                \
    } else {                                                                   \
      movups(dst, Address(TMP, 0));                                            \
      op(dst, src);                                                            \
    }                                                                          \
  }

// TODO(erikcorry): For the case where dst != src, we could construct these
// with pcmpeqw xmm0,xmm0 followed by left and right shifts.  This would avoid
// memory traffic.
// { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
UNARY_XMM_WITH_CONSTANT(notps, float_not, xorps)
// { 0x80000000, 0x80000000, 0x80000000, 0x80000000 }
UNARY_XMM_WITH_CONSTANT(negateps, float_negate, xorps)
// { 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF }
UNARY_XMM_WITH_CONSTANT(absps, float_absolute, andps)
// { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000 }
UNARY_XMM_WITH_CONSTANT(zerowps, float_zerow, andps)
// { 0x8000000000000000LL, 0x8000000000000000LL }
UNARY_XMM_WITH_CONSTANT(negatepd, double_negate, xorpd)
// { 0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL }
UNARY_XMM_WITH_CONSTANT(abspd, double_abs, andpd)
// {0x8000000000000000LL, 0x8000000000000000LL}
UNARY_XMM_WITH_CONSTANT(DoubleNegate, double_negate, xorpd)
// {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL}
UNARY_XMM_WITH_CONSTANT(DoubleAbs, double_abs, andpd)

#undef UNARY_XMM_WITH_CONSTANT

void Assembler::CmpPS(XmmRegister dst, XmmRegister src, int condition) {
  EmitL(dst, src, 0xC2, 0x0F);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(condition);
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
  EmitL(dst, src, 0xC6, 0x0F);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}

void Assembler::shufpd(XmmRegister dst, XmmRegister src, const Immediate& imm) {
  EmitL(dst, src, 0xC6, 0x0F, 0x66);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_uint8());
  EmitUint8(imm.value());
}

void Assembler::roundsd(XmmRegister dst, XmmRegister src, RoundingMode mode) {
  ASSERT(src <= XMM15);
  ASSERT(dst <= XMM15);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitUint8(0x66);
  EmitRegRegRex(dst, src);
  EmitUint8(0x0F);
  EmitUint8(0x3A);
  EmitUint8(0x0B);
  EmitRegisterOperand(dst & 7, src);
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

void Assembler::ffree(intptr_t value) {
  ASSERT(value < 7);
  EmitSimple(0xDD, 0xC0 + value);
}

void Assembler::CompareImmediate(Register reg, const Immediate& imm) {
  if (imm.is_int32()) {
    cmpq(reg, imm);
  } else {
    ASSERT(reg != TMP);
    LoadImmediate(TMP, imm);
    cmpq(reg, TMP);
  }
}

void Assembler::CompareImmediate(const Address& address, const Immediate& imm) {
  if (imm.is_int32()) {
    cmpq(address, imm);
  } else {
    LoadImmediate(TMP, imm);
    cmpq(address, TMP);
  }
}

void Assembler::testb(const Address& address, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(0, address, REX_NONE);
  EmitUint8(0xF6);
  EmitOperand(0, address);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::testb(const Address& address, Register reg) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(reg, address, REX_NONE);
  EmitUint8(0x84);
  EmitOperand(reg & 7, address);
}

void Assembler::testq(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  if (imm.is_uint8()) {
    // Use zero-extended 8-bit immediate.
    if (reg >= 4) {
      // We need the Rex byte to give access to the SIL and DIL registers (the
      // low bytes of RSI and RDI).
      EmitRegisterREX(reg, REX_NONE, /* force = */ true);
    }
    if (reg == RAX) {
      EmitUint8(0xA8);
    } else {
      EmitUint8(0xF6);
      EmitUint8(0xC0 + (reg & 7));
    }
    EmitUint8(imm.value() & 0xFF);
  } else if (imm.is_uint32()) {
    if (reg == RAX) {
      EmitUint8(0xA9);
    } else {
      EmitRegisterREX(reg, REX_NONE);
      EmitUint8(0xF7);
      EmitUint8(0xC0 | (reg & 7));
    }
    EmitUInt32(imm.value());
  } else {
    // Sign extended version of 32 bit test.
    ASSERT(imm.is_int32());
    EmitRegisterREX(reg, REX_W);
    if (reg == RAX) {
      EmitUint8(0xA9);
    } else {
      EmitUint8(0xF7);
      EmitUint8(0xC0 | (reg & 7));
    }
    EmitImmediate(imm);
  }
}

void Assembler::TestImmediate(Register dst, const Immediate& imm) {
  if (imm.is_int32() || imm.is_uint32()) {
    testq(dst, imm);
  } else {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm);
    testq(dst, TMP);
  }
}

void Assembler::AluL(uint8_t modrm_opcode, Register dst, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(dst, REX_NONE);
  EmitComplex(modrm_opcode, Operand(dst), imm);
}

void Assembler::AluB(uint8_t modrm_opcode,
                     const Address& dst,
                     const Immediate& imm) {
  ASSERT(imm.is_uint8() || imm.is_int8());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(modrm_opcode, dst, REX_NONE);
  EmitUint8(0x80);
  EmitOperand(modrm_opcode, dst);
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::AluW(uint8_t modrm_opcode,
                     const Address& dst,
                     const Immediate& imm) {
  ASSERT(imm.is_int16() || imm.is_uint16());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandSizeOverride();
  EmitOperandREX(modrm_opcode, dst, REX_NONE);
  if (imm.is_int8()) {
    EmitSignExtendedInt8(modrm_opcode, dst, imm);
  } else {
    EmitUint8(0x81);
    EmitOperand(modrm_opcode, dst);
    EmitUint8(imm.value() & 0xFF);
    EmitUint8((imm.value() >> 8) & 0xFF);
  }
}

void Assembler::AluL(uint8_t modrm_opcode,
                     const Address& dst,
                     const Immediate& imm) {
  ASSERT(imm.is_int32());
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitOperandREX(modrm_opcode, dst, REX_NONE);
  EmitComplex(modrm_opcode, dst, imm);
}

void Assembler::AluQ(uint8_t modrm_opcode,
                     uint8_t opcode,
                     Register dst,
                     const Immediate& imm) {
  Operand operand(dst);
  if (modrm_opcode == 4 && imm.is_uint32()) {
    // We can use andl for andq.
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_NONE);
    // Would like to use EmitComplex here, but it doesn't like uint32
    // immediates.
    if (imm.is_int8()) {
      EmitSignExtendedInt8(modrm_opcode, operand, imm);
    } else {
      if (dst == RAX) {
        EmitUint8(0x25);
      } else {
        EmitUint8(0x81);
        EmitOperand(modrm_opcode, operand);
      }
      EmitUInt32(imm.value());
    }
  } else if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(dst, REX_W);
    EmitComplex(modrm_opcode, operand, imm);
  } else {
    ASSERT(dst != TMP);
    movq(TMP, imm);
    EmitQ(dst, TMP, opcode);
  }
}

void Assembler::AluQ(uint8_t modrm_opcode,
                     uint8_t opcode,
                     const Address& dst,
                     const Immediate& imm) {
  if (imm.is_int32()) {
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitOperandREX(modrm_opcode, dst, REX_W);
    EmitComplex(modrm_opcode, dst, imm);
  } else {
    movq(TMP, imm);
    EmitQ(TMP, dst, opcode);
  }
}

void Assembler::AndImmediate(Register dst, const Immediate& imm) {
  if (imm.is_int32() || imm.is_uint32()) {
    andq(dst, imm);
  } else {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm);
    andq(dst, TMP);
  }
}

void Assembler::OrImmediate(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    orq(dst, imm);
  } else {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm);
    orq(dst, TMP);
  }
}

void Assembler::XorImmediate(Register dst, const Immediate& imm) {
  if (imm.is_int32()) {
    xorq(dst, imm);
  } else {
    ASSERT(dst != TMP);
    LoadImmediate(TMP, imm);
    xorq(dst, TMP);
  }
}

void Assembler::cqo() {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(RAX, REX_W);
  EmitUint8(0x99);
}

void Assembler::EmitUnaryQ(Register reg, int opcode, int modrm_code) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_W);
  EmitUint8(opcode);
  EmitOperand(modrm_code, Operand(reg));
}

void Assembler::EmitUnaryL(Register reg, int opcode, int modrm_code) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  EmitRegisterREX(reg, REX_NONE);
  EmitUint8(opcode);
  EmitOperand(modrm_code, Operand(reg));
}

void Assembler::EmitUnaryQ(const Address& address, int opcode, int modrm_code) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(modrm_code, operand, REX_W);
  EmitUint8(opcode);
  EmitOperand(modrm_code, operand);
}

void Assembler::EmitUnaryL(const Address& address, int opcode, int modrm_code) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(address);
  EmitOperandREX(modrm_code, operand, REX_NONE);
  EmitUint8(opcode);
  EmitOperand(modrm_code, operand);
}

void Assembler::imull(Register reg, const Immediate& imm) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(reg);
  EmitOperandREX(reg, operand, REX_NONE);
  EmitUint8(0x69);
  EmitOperand(reg & 7, Operand(reg));
  EmitImmediate(imm);
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
    ASSERT(reg != TMP);
    movq(TMP, imm);
    imulq(reg, TMP);
  }
}

void Assembler::MulImmediate(Register reg,
                             const Immediate& imm,
                             OperandSize width) {
  ASSERT(width == kFourBytes || width == kEightBytes);
  if (imm.is_int32()) {
    if (width == kFourBytes) {
      imull(reg, imm);
    } else {
      imulq(reg, imm);
    }
  } else {
    ASSERT(reg != TMP);
    ASSERT(width == kEightBytes);
    movq(TMP, imm);
    imulq(reg, TMP);
  }
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
  EmitL(src, dst, 0xA4, 0x0F);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
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

void Assembler::shldq(Register dst, Register src, const Immediate& imm) {
  EmitQ(src, dst, 0xA4, 0x0F);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  ASSERT(imm.is_int8());
  EmitUint8(imm.value() & 0xFF);
}

void Assembler::btq(Register base, int bit) {
  ASSERT(bit >= 0 && bit < 64);
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  Operand operand(base);
  EmitOperandREX(4, operand, bit >= 32 ? REX_W : REX_NONE);
  EmitUint8(0x0F);
  EmitUint8(0xBA);
  EmitOperand(4, operand);
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

void Assembler::J(Condition condition, const Code& target, Register pp) {
  Label no_jump;
  // Negate condition.
  j(static_cast<Condition>(condition ^ 1), &no_jump, kNearJump);
  Jmp(target, pp);
  Bind(&no_jump);
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
  {  // Encode movq(TMP, Immediate(label->address())), but always as imm64.
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    EmitRegisterREX(TMP, REX_W);
    EmitUint8(0xB8 | (TMP & 7));
    EmitInt64(label->address());
  }
  jmp(TMP);
}

void Assembler::JmpPatchable(const Code& target, Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  const intptr_t idx = object_pool_builder().AddObject(
      ToObject(target), ObjectPoolBuilderEntry::kPatchable);
  const int32_t offset = target::ObjectPool::element_offset(idx);
  movq(CODE_REG, Address(pp, offset - kHeapObjectTag));
  movq(TMP, FieldAddress(CODE_REG, target::Code::entry_point_offset()));
  jmp(TMP);
}

void Assembler::Jmp(const Code& target, Register pp) {
  ASSERT((pp != PP) || constant_pool_allowed());
  const intptr_t idx = object_pool_builder().FindObject(
      ToObject(target), ObjectPoolBuilderEntry::kNotPatchable);
  const int32_t offset = target::ObjectPool::element_offset(idx);
  movq(CODE_REG, FieldAddress(pp, offset));
  jmp(FieldAddress(CODE_REG, target::Code::entry_point_offset()));
}

void Assembler::CompareRegisters(Register a, Register b) {
  cmpq(a, b);
}

void Assembler::LoadFromStack(Register dst, intptr_t depth) {
  ASSERT(depth >= 0);
  movq(dst, Address(SPREG, depth * target::kWordSize));
}

void Assembler::StoreToStack(Register src, intptr_t depth) {
  ASSERT(depth >= 0);
  movq(Address(SPREG, depth * target::kWordSize), src);
}

void Assembler::CompareToStack(Register src, intptr_t depth) {
  cmpq(Address(SPREG, depth * target::kWordSize), src);
}

void Assembler::MoveRegister(Register to, Register from) {
  if (to != from) {
    movq(to, from);
  }
}

void Assembler::PushRegister(Register r) {
  pushq(r);
}

void Assembler::PopRegister(Register r) {
  popq(r);
}

void Assembler::AddImmediate(Register reg,
                             const Immediate& imm,
                             OperandSize width) {
  ASSERT(width == kFourBytes || width == kEightBytes);
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      if (width == kFourBytes) {
        incl(reg);
      } else {
        incq(reg);
      }
    } else {
      if (imm.is_int32() || (width == kFourBytes && imm.is_uint32())) {
        if (width == kFourBytes) {
          addl(reg, imm);
        } else {
          addq(reg, imm);
        }
      } else {
        ASSERT(reg != TMP);
        ASSERT(width == kEightBytes);
        LoadImmediate(TMP, imm);
        addq(reg, TMP);
      }
    }
  } else {
    SubImmediate(reg, Immediate(-value), width);
  }
}

void Assembler::AddImmediate(const Address& address, const Immediate& imm) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      incq(address);
    } else {
      if (imm.is_int32()) {
        addq(address, imm);
      } else {
        LoadImmediate(TMP, imm);
        addq(address, TMP);
      }
    }
  } else {
    SubImmediate(address, Immediate(-value));
  }
}

void Assembler::SubImmediate(Register reg,
                             const Immediate& imm,
                             OperandSize width) {
  ASSERT(width == kFourBytes || width == kEightBytes);
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64) ||
      (value == kMinInt32 && width == kFourBytes)) {
    if (value == 1) {
      if (width == kFourBytes) {
        decl(reg);
      } else {
        decq(reg);
      }
    } else {
      if (imm.is_int32()) {
        if (width == kFourBytes) {
          subl(reg, imm);
        } else {
          subq(reg, imm);
        }
      } else {
        ASSERT(reg != TMP);
        ASSERT(width == kEightBytes);
        LoadImmediate(TMP, imm);
        subq(reg, TMP);
      }
    }
  } else {
    AddImmediate(reg, Immediate(-value), width);
  }
}

void Assembler::SubImmediate(const Address& address, const Immediate& imm) {
  const int64_t value = imm.value();
  if (value == 0) {
    return;
  }
  if ((value > 0) || (value == kMinInt64)) {
    if (value == 1) {
      decq(address);
    } else {
      if (imm.is_int32()) {
        subq(address, imm);
      } else {
        LoadImmediate(TMP, imm);
        subq(address, TMP);
      }
    }
  } else {
    AddImmediate(address, Immediate(-value));
  }
}

void Assembler::Drop(intptr_t stack_elements, Register tmp) {
  ASSERT(stack_elements >= 0);
  if (stack_elements <= 4) {
    for (intptr_t i = 0; i < stack_elements; i++) {
      popq(tmp);
    }
    return;
  }
  addq(RSP, Immediate(stack_elements * target::kWordSize));
}

bool Assembler::CanLoadFromObjectPool(const Object& object) const {
  ASSERT(IsOriginalObject(object));
  if (!constant_pool_allowed()) {
    return false;
  }

  if (target::IsSmi(object)) {
    // If the raw smi does not fit into a 32-bit signed int, then we'll keep
    // the raw value in the object pool.
    return !Utils::IsInt(32, target::ToRawSmi(object));
  }
  ASSERT(IsNotTemporaryScopedHandle(object));
  ASSERT(IsInOldSpace(object));
  return true;
}

void Assembler::LoadWordFromPoolIndex(Register dst, intptr_t idx) {
  ASSERT(constant_pool_allowed());
  ASSERT(dst != PP);
  // PP is tagged on X64.
  const int32_t offset =
      target::ObjectPool::element_offset(idx) - kHeapObjectTag;
  // This sequence must be decodable by code_patcher_x64.cc.
  movq(dst, Address(PP, offset));
}

void Assembler::LoadIsolate(Register dst) {
  movq(dst, Address(THR, target::Thread::isolate_offset()));
}

void Assembler::LoadDispatchTable(Register dst) {
  movq(dst, Address(THR, target::Thread::dispatch_table_array_offset()));
}

void Assembler::LoadObjectHelper(Register dst,
                                 const Object& object,
                                 bool is_unique) {
  ASSERT(IsOriginalObject(object));

  // `is_unique == true` effectively means object has to be patchable.
  if (!is_unique) {
    intptr_t offset;
    if (target::CanLoadFromThread(object, &offset)) {
      movq(dst, Address(THR, offset));
      return;
    }
  }
  if (CanLoadFromObjectPool(object)) {
    const intptr_t index = is_unique ? object_pool_builder().AddObject(object)
                                     : object_pool_builder().FindObject(object);
    LoadWordFromPoolIndex(dst, index);
    return;
  }
  ASSERT(target::IsSmi(object));
  LoadImmediate(dst, Immediate(target::ToRawSmi(object)));
}

void Assembler::LoadObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, false);
}

void Assembler::LoadUniqueObject(Register dst, const Object& object) {
  LoadObjectHelper(dst, object, true);
}

void Assembler::StoreObject(const Address& dst, const Object& object) {
  ASSERT(IsOriginalObject(object));

  intptr_t offset_from_thread;
  if (target::CanLoadFromThread(object, &offset_from_thread)) {
    movq(TMP, Address(THR, offset_from_thread));
    movq(dst, TMP);
  } else if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object);
    movq(dst, TMP);
  } else {
    ASSERT(target::IsSmi(object));
    MoveImmediate(dst, Immediate(target::ToRawSmi(object)));
  }
}

void Assembler::PushObject(const Object& object) {
  ASSERT(IsOriginalObject(object));

  intptr_t offset_from_thread;
  if (target::CanLoadFromThread(object, &offset_from_thread)) {
    pushq(Address(THR, offset_from_thread));
  } else if (CanLoadFromObjectPool(object)) {
    LoadObject(TMP, object);
    pushq(TMP);
  } else {
    ASSERT(target::IsSmi(object));
    PushImmediate(Immediate(target::ToRawSmi(object)));
  }
}

void Assembler::CompareObject(Register reg, const Object& object) {
  ASSERT(IsOriginalObject(object));

  intptr_t offset_from_thread;
  if (target::CanLoadFromThread(object, &offset_from_thread)) {
    cmpq(reg, Address(THR, offset_from_thread));
  } else if (CanLoadFromObjectPool(object)) {
    const intptr_t idx = object_pool_builder().FindObject(
        object, ObjectPoolBuilderEntry::kNotPatchable);
    const int32_t offset = target::ObjectPool::element_offset(idx);
    cmpq(reg, Address(PP, offset - kHeapObjectTag));
  } else {
    ASSERT(target::IsSmi(object));
    CompareImmediate(reg, Immediate(target::ToRawSmi(object)));
  }
}

intptr_t Assembler::FindImmediate(int64_t imm) {
  return object_pool_builder().FindImmediate(imm);
}

void Assembler::LoadImmediate(Register reg, const Immediate& imm) {
  if (imm.value() == 0) {
    xorl(reg, reg);
  } else if (imm.is_int32() || !constant_pool_allowed()) {
    movq(reg, imm);
  } else {
    const intptr_t idx = FindImmediate(imm.value());
    LoadWordFromPoolIndex(reg, idx);
  }
}

void Assembler::MoveImmediate(const Address& dst, const Immediate& imm) {
  if (imm.is_int32()) {
    movq(dst, imm);
  } else {
    LoadImmediate(TMP, imm);
    movq(dst, TMP);
  }
}

// Destroys the value register.
void Assembler::StoreIntoObjectFilter(Register object,
                                      Register value,
                                      Label* label,
                                      CanBeSmi can_be_smi,
                                      BarrierFilterMode how_to_jump) {
  COMPILE_ASSERT((target::ObjectAlignment::kNewObjectAlignmentOffset ==
                  target::kWordSize) &&
                 (target::ObjectAlignment::kOldObjectAlignmentOffset == 0));

  if (can_be_smi == kValueIsNotSmi) {
#if defined(DEBUG)
    Label okay;
    BranchIfNotSmi(value, &okay);
    Stop("Unexpected Smi!");
    Bind(&okay);
#endif
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
    ASSERT(kHeapObjectTag == 1);
    // Detect value being ...1001 and object being ...0001.
    andl(value, Immediate(0xf));
    leal(value, Address(value, object, TIMES_2, 0x15));
    testl(value, Immediate(0x1f));
  }
  Condition condition = how_to_jump == kJumpToNoUpdate ? NOT_ZERO : ZERO;
  JumpDistance distance = how_to_jump == kJumpToNoUpdate ? kNearJump : kFarJump;
  j(condition, label, distance);
}

void Assembler::StoreIntoObject(Register object,
                                const Address& dest,
                                Register value,
                                CanBeSmi can_be_smi) {
  // x.slot = x. Barrier should have be removed at the IL level.
  ASSERT(object != value);
  ASSERT(object != TMP);
  ASSERT(value != TMP);

  movq(dest, value);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    testq(value, Immediate(kSmiTagMask));
    j(ZERO, &done, kNearJump);
  }
  movb(TMP, FieldAddress(object, target::Object::tags_offset()));
  shrl(TMP, Immediate(target::ObjectLayout::kBarrierOverlapShift));
  andl(TMP, Address(THR, target::Thread::write_barrier_mask_offset()));
  testb(FieldAddress(value, target::Object::tags_offset()), TMP);
  j(ZERO, &done, kNearJump);

  Register object_for_call = object;
  if (value != kWriteBarrierValueReg) {
    // Unlikely. Only non-graph intrinsics.
    // TODO(rmacnak): Shuffle registers in intrinsics.
    pushq(kWriteBarrierValueReg);
    if (object == kWriteBarrierValueReg) {
      COMPILE_ASSERT(RBX != kWriteBarrierValueReg);
      COMPILE_ASSERT(RCX != kWriteBarrierValueReg);
      object_for_call = (value == RBX) ? RCX : RBX;
      pushq(object_for_call);
      movq(object_for_call, object);
    }
    movq(kWriteBarrierValueReg, value);
  }
  generate_invoke_write_barrier_wrapper_(object_for_call);
  if (value != kWriteBarrierValueReg) {
    if (object == kWriteBarrierValueReg) {
      popq(object_for_call);
    }
    popq(kWriteBarrierValueReg);
  }
  Bind(&done);
}

void Assembler::StoreIntoArray(Register object,
                               Register slot,
                               Register value,
                               CanBeSmi can_be_smi) {
  ASSERT(object != TMP);
  ASSERT(value != TMP);
  ASSERT(slot != TMP);

  movq(Address(slot, 0), value);

  // In parallel, test whether
  //  - object is old and not remembered and value is new, or
  //  - object is old and value is old and not marked and concurrent marking is
  //    in progress
  // If so, call the WriteBarrier stub, which will either add object to the
  // store buffer (case 1) or add value to the marking stack (case 2).
  // Compare ObjectLayout::StorePointer.
  Label done;
  if (can_be_smi == kValueCanBeSmi) {
    testq(value, Immediate(kSmiTagMask));
    j(ZERO, &done, kNearJump);
  }
  movb(TMP, FieldAddress(object, target::Object::tags_offset()));
  shrl(TMP, Immediate(target::ObjectLayout::kBarrierOverlapShift));
  andl(TMP, Address(THR, target::Thread::write_barrier_mask_offset()));
  testb(FieldAddress(value, target::Object::tags_offset()), TMP);
  j(ZERO, &done, kNearJump);

  if ((object != kWriteBarrierObjectReg) || (value != kWriteBarrierValueReg) ||
      (slot != kWriteBarrierSlotReg)) {
    // Spill and shuffle unimplemented. Currently StoreIntoArray is only used
    // from StoreIndexInstr, which gets these exact registers from the register
    // allocator.
    UNIMPLEMENTED();
  }

  generate_invoke_array_write_barrier_();

  Bind(&done);
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         Register value) {
  movq(dest, value);
#if defined(DEBUG)
  Label done;
  pushq(value);
  StoreIntoObjectFilter(object, value, &done, kValueCanBeSmi, kJumpToNoUpdate);

  testb(FieldAddress(object, target::Object::tags_offset()),
        Immediate(1 << target::ObjectLayout::kOldAndNotRememberedBit));
  j(ZERO, &done, Assembler::kNearJump);

  Stop("Store buffer update is required");
  Bind(&done);
  popq(value);
#endif  // defined(DEBUG)
  // No store buffer update.
}

void Assembler::StoreIntoObjectNoBarrier(Register object,
                                         const Address& dest,
                                         const Object& value) {
  StoreObject(dest, value);
}

void Assembler::StoreInternalPointer(Register object,
                                     const Address& dest,
                                     Register value) {
  movq(dest, value);
}

void Assembler::StoreIntoSmiField(const Address& dest, Register value) {
#if defined(DEBUG)
  Label done;
  testq(value, Immediate(kHeapObjectTag));
  j(ZERO, &done);
  Stop("New value must be Smi.");
  Bind(&done);
#endif  // defined(DEBUG)
  movq(dest, value);
}

void Assembler::ZeroInitSmiField(const Address& dest) {
  Immediate zero(target::ToRawSmi(0));
  movq(dest, zero);
}

void Assembler::IncrementSmiField(const Address& dest, int64_t increment) {
  // Note: FlowGraphCompiler::EdgeCounterIncrementSizeInBytes depends on
  // the length of this instruction sequence.
  Immediate inc_imm(target::ToRawSmi(increment));
  addq(dest, inc_imm);
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

void Assembler::LoadFromOffset(Register reg,
                               const Address& address,
                               OperandSize sz) {
  switch (sz) {
    case kByte:
      return movsxb(reg, address);
    case kUnsignedByte:
      return movzxb(reg, address);
    case kTwoBytes:
      return movsxw(reg, address);
    case kUnsignedTwoBytes:
      return movzxw(reg, address);
    case kFourBytes:
      return movl(reg, address);
    case kEightBytes:
      return movq(reg, address);
    default:
      UNREACHABLE();
      break;
  }
}

void Assembler::EnterFrame(intptr_t frame_size) {
  if (prologue_offset_ == -1) {
    prologue_offset_ = CodeSize();
    Comment("PrologueOffset = %" Pd "", CodeSize());
  }
#ifdef DEBUG
  intptr_t check_offset = CodeSize();
#endif
  pushq(RBP);
  movq(RBP, RSP);
#ifdef DEBUG
  ProloguePattern pp(CodeAddress(check_offset));
  ASSERT(pp.IsValid());
#endif
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

void Assembler::EmitEntryFrameVerification() {
#if defined(DEBUG)
  Label ok;
  leaq(RAX, Address(RBP, target::frame_layout.exit_link_slot_from_entry_fp *
                             target::kWordSize));
  cmpq(RAX, RSP);
  j(EQUAL, &ok);
  Stop("target::frame_layout.exit_link_slot_from_entry_fp mismatch");
  Bind(&ok);
#endif
}

void Assembler::PushRegisters(const RegisterSet& register_set) {
  const intptr_t xmm_regs_count = register_set.FpuRegisterCount();
  if (xmm_regs_count > 0) {
    AddImmediate(RSP, Immediate(-xmm_regs_count * kFpuRegisterSize));
    // Store XMM registers with the lowest register number at the lowest
    // address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfXmmRegisters; ++i) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(i);
      if (register_set.ContainsFpuRegister(xmm_reg)) {
        movups(Address(RSP, offset), xmm_reg);
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
  }

  // The order in which the registers are pushed must match the order
  // in which the registers are encoded in the safe point's stack map.
  for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
    Register reg = static_cast<Register>(i);
    if (register_set.ContainsRegister(reg)) {
      pushq(reg);
    }
  }
}

void Assembler::PopRegisters(const RegisterSet& register_set) {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
    Register reg = static_cast<Register>(i);
    if (register_set.ContainsRegister(reg)) {
      popq(reg);
    }
  }

  const intptr_t xmm_regs_count = register_set.FpuRegisterCount();
  if (xmm_regs_count > 0) {
    // XMM registers have the lowest register number at the lowest address.
    intptr_t offset = 0;
    for (intptr_t i = 0; i < kNumberOfXmmRegisters; ++i) {
      XmmRegister xmm_reg = static_cast<XmmRegister>(i);
      if (register_set.ContainsFpuRegister(xmm_reg)) {
        movups(xmm_reg, Address(RSP, offset));
        offset += kFpuRegisterSize;
      }
    }
    ASSERT(offset == (xmm_regs_count * kFpuRegisterSize));
    AddImmediate(RSP, Immediate(offset));
  }
}

static const RegisterSet kVolatileRegisterSet(
    CallingConventions::kVolatileCpuRegisters,
    CallingConventions::kVolatileXmmRegisters);

void Assembler::EnterCallRuntimeFrame(intptr_t frame_space) {
  Comment("EnterCallRuntimeFrame");
  EnterFrame(0);
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    pushq(CODE_REG);
    pushq(PP);
  }

  // TODO(vegorov): avoid saving FpuTMP, it is used only as scratch.
  PushRegisters(kVolatileRegisterSet);

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
      kPushedCpuRegistersCount * target::kWordSize +
      kPushedXmmRegistersCount * kFpuRegisterSize +
      (target::frame_layout.dart_fixed_frame_size - 2) *
          target::kWordSize;  // From EnterStubFrame (excluding PC / FP)

  leaq(RSP, Address(RBP, -kPushedRegistersSize));

  // TODO(vegorov): avoid saving FpuTMP, it is used only as scratch.
  PopRegisters(kVolatileRegisterSet);

  LeaveStubFrame();
}

void Assembler::CallCFunction(Register reg, bool restore_rsp) {
  // Reserve shadow space for outgoing arguments.
  if (CallingConventions::kShadowSpaceBytes != 0) {
    subq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
  call(reg);
  // Restore stack.
  if (restore_rsp && CallingConventions::kShadowSpaceBytes != 0) {
    addq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
}
void Assembler::CallCFunction(Address address, bool restore_rsp) {
  // Reserve shadow space for outgoing arguments.
  if (CallingConventions::kShadowSpaceBytes != 0) {
    subq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
  call(address);
  // Restore stack.
  if (restore_rsp && CallingConventions::kShadowSpaceBytes != 0) {
    addq(RSP, Immediate(CallingConventions::kShadowSpaceBytes));
  }
}

void Assembler::CallRuntime(const RuntimeEntry& entry,
                            intptr_t argument_count) {
  entry.Call(this, argument_count);
}

void Assembler::RestoreCodePointer() {
  movq(CODE_REG,
       Address(RBP, target::frame_layout.code_from_fp * target::kWordSize));
}

void Assembler::LoadPoolPointer(Register pp) {
  // Load new pool pointer.
  CheckCodePointer();
  movq(pp, FieldAddress(CODE_REG, target::Code::object_pool_offset()));
  set_constant_pool_allowed(pp == PP);
}

void Assembler::EnterDartFrame(intptr_t frame_size, Register new_pp) {
  ASSERT(!constant_pool_allowed());
  EnterFrame(0);
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    pushq(CODE_REG);
    pushq(PP);
    if (new_pp == kNoRegister) {
      LoadPoolPointer(PP);
    } else {
      movq(PP, new_pp);
    }
  }
  set_constant_pool_allowed(true);
  if (frame_size != 0) {
    subq(RSP, Immediate(frame_size));
  }
}

void Assembler::LeaveDartFrame(RestorePP restore_pp) {
  // Restore caller's PP register that was pushed in EnterDartFrame.
  if (!(FLAG_precompiled_mode && FLAG_use_bare_instructions)) {
    if (restore_pp == kRestoreCallerPP) {
      movq(PP, Address(RBP, (target::frame_layout.saved_caller_pp_from_fp *
                             target::kWordSize)));
    }
  }
  set_constant_pool_allowed(false);
  LeaveFrame();
}

void Assembler::CheckCodePointer() {
#ifdef DEBUG
  if (!FLAG_check_code_pointer) {
    return;
  }
  Comment("CheckCodePointer");
  Label cid_ok, instructions_ok;
  pushq(RAX);
  LoadClassId(RAX, CODE_REG);
  cmpq(RAX, Immediate(kCodeCid));
  j(EQUAL, &cid_ok);
  int3();
  Bind(&cid_ok);
  {
    const intptr_t kRIPRelativeLeaqSize = 7;
    const intptr_t header_to_entry_offset =
        (target::Instructions::HeaderSize() - kHeapObjectTag);
    const intptr_t header_to_rip_offset =
        CodeSize() + kRIPRelativeLeaqSize + header_to_entry_offset;
    leaq(RAX, Address::AddressRIPRelative(-header_to_rip_offset));
    ASSERT(CodeSize() == (header_to_rip_offset - header_to_entry_offset));
  }
  cmpq(RAX, FieldAddress(CODE_REG, target::Code::saved_instructions_offset()));
  j(EQUAL, &instructions_ok);
  int3();
  Bind(&instructions_ok);
  popq(RAX);
#endif
}

// On entry to a function compiled for OSR, the caller's frame pointer, the
// stack locals, and any copied parameters are already in place.  The frame
// pointer is already set up.  The PC marker is not correct for the
// optimized function and there may be extra space for spill slots to
// allocate.
void Assembler::EnterOsrFrame(intptr_t extra_size) {
  ASSERT(!constant_pool_allowed());
  if (prologue_offset_ == -1) {
    Comment("PrologueOffset = %" Pd "", CodeSize());
    prologue_offset_ = CodeSize();
  }
  RestoreCodePointer();
  LoadPoolPointer();

  if (extra_size != 0) {
    subq(RSP, Immediate(extra_size));
  }
}

void Assembler::EnterStubFrame() {
  EnterDartFrame(0, kNoRegister);
}

void Assembler::LeaveStubFrame() {
  LeaveDartFrame();
}

void Assembler::EnterCFrame(intptr_t frame_space) {
  EnterFrame(0);
  ReserveAlignedFrameSpace(frame_space);
}

void Assembler::LeaveCFrame() {
  LeaveFrame();
}

// RDX receiver, RBX ICData entries array
// Preserve R10 (ARGS_DESC_REG), not required today, but maybe later.
void Assembler::MonomorphicCheckedEntryJIT() {
  has_monomorphic_entry_ = true;
  intptr_t start = CodeSize();
  Label have_cid, miss;
  Bind(&miss);
  jmp(Address(THR, target::Thread::switchable_call_miss_entry_offset()));

  // Ensure the monomorphic entry is 2-byte aligned (so GC can see them if we
  // store them in ICData / MegamorphicCache arrays)
  nop(1);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetJIT);
  ASSERT((CodeSize() & kSmiTagMask) == kSmiTag);

  const intptr_t cid_offset = target::Array::element_offset(0);
  const intptr_t count_offset = target::Array::element_offset(1);

  LoadTaggedClassIdMayBeSmi(RAX, RDX);

  cmpq(RAX, FieldAddress(RBX, cid_offset));
  j(NOT_EQUAL, &miss, Assembler::kNearJump);
  addl(FieldAddress(RBX, count_offset), Immediate(target::ToRawSmi(1)));
  xorq(R10, R10);  // GC-safe for OptimizeInvokedFunction.
  nop(1);

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetJIT);
  ASSERT(((CodeSize() - start) & kSmiTagMask) == kSmiTag);
}

// RBX - input: class id smi
// RDX - input: receiver object
void Assembler::MonomorphicCheckedEntryAOT() {
  has_monomorphic_entry_ = true;
  intptr_t start = CodeSize();
  Label have_cid, miss;
  Bind(&miss);
  jmp(Address(THR, target::Thread::switchable_call_miss_entry_offset()));

  // Ensure the monomorphic entry is 2-byte aligned (so GC can see them if we
  // store them in ICData / MegamorphicCache arrays)
  nop(1);

  Comment("MonomorphicCheckedEntry");
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kMonomorphicEntryOffsetAOT);
  ASSERT((CodeSize() & kSmiTagMask) == kSmiTag);

  SmiUntag(RBX);
  LoadClassId(RAX, RDX);
  cmpq(RAX, RBX);
  j(NOT_EQUAL, &miss, Assembler::kNearJump);

  // Ensure the unchecked entry is 2-byte aligned (so GC can see them if we
  // store them in ICData / MegamorphicCache arrays).
  nop(1);

  // Fall through to unchecked entry.
  ASSERT_EQUAL(CodeSize() - start,
               target::Instructions::kPolymorphicEntryOffsetAOT);
  ASSERT(((CodeSize() - start) & kSmiTagMask) == kSmiTag);
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

#ifndef PRODUCT
void Assembler::MaybeTraceAllocation(intptr_t cid,
                                     Label* trace,
                                     JumpDistance distance) {
  ASSERT(cid > 0);
  const intptr_t shared_table_offset =
      target::Isolate::shared_class_table_offset();
  const intptr_t table_offset =
      target::SharedClassTable::class_heap_stats_table_offset();
  const intptr_t class_offset = target::ClassTable::ClassOffsetFor(cid);

  Register temp_reg = TMP;
  LoadIsolate(temp_reg);
  movq(temp_reg, Address(temp_reg, shared_table_offset));
  movq(temp_reg, Address(temp_reg, table_offset));
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
                            Register temp) {
  ASSERT(failure != NULL);
  const intptr_t instance_size = target::Class::GetInstanceSize(cls);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    const classid_t cid = target::Class::GetId(cls);
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, distance));
    movq(instance_reg, Address(THR, target::Thread::top_offset()));
    addq(instance_reg, Immediate(instance_size));
    // instance_reg: potential next object start.
    cmpq(instance_reg, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure, distance);
    // Successfully allocated the object, now update top to point to
    // next object start and store the class in the class field of object.
    movq(Address(THR, target::Thread::top_offset()), instance_reg);
    ASSERT(instance_size >= kHeapObjectTag);
    AddImmediate(instance_reg, Immediate(kHeapObjectTag - instance_size));
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    MoveImmediate(FieldAddress(instance_reg, target::Object::tags_offset()),
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
                                 Register temp) {
  ASSERT(failure != NULL);
  if (FLAG_inline_alloc &&
      target::Heap::IsAllocatableInNewSpace(instance_size)) {
    // If this allocation is traced, program will jump to failure path
    // (i.e. the allocation stub) which will allocate the object and trace the
    // allocation call site.
    NOT_IN_PRODUCT(MaybeTraceAllocation(cid, failure, distance));
    movq(instance, Address(THR, target::Thread::top_offset()));
    movq(end_address, instance);

    addq(end_address, Immediate(instance_size));
    j(CARRY, failure);

    // Check if the allocation fits into the remaining space.
    // instance: potential new object start.
    // end_address: potential next object start.
    cmpq(end_address, Address(THR, target::Thread::end_offset()));
    j(ABOVE_EQUAL, failure);

    // Successfully allocated the object(s), now update top to point to
    // next object start and initialize the object.
    movq(Address(THR, target::Thread::top_offset()), end_address);
    addq(instance, Immediate(kHeapObjectTag));

    // Initialize the tags.
    // instance: new object start as a tagged pointer.
    const uword tags = target::MakeTagWordForNewSpaceObject(cid, instance_size);
    movq(FieldAddress(instance, target::Object::tags_offset()),
         Immediate(tags));
  } else {
    jmp(failure);
  }
}

void Assembler::GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<uint8_t>(0xe8);
  buffer_.Emit<int32_t>(0);

  PcRelativeCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                PcRelativeCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
}

void Assembler::GenerateUnRelocatedPcRelativeTailCall(
    intptr_t offset_into_target) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<uint8_t>(0xe9);
  buffer_.Emit<int32_t>(0);

  PcRelativeCallPattern pattern(buffer_.contents() + buffer_.Size() -
                                PcRelativeCallPattern::kLengthInBytes);
  pattern.set_distance(offset_into_target);
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
  if (bytes_needed != 0) {
    nop(bytes_needed);
  }
  ASSERT(((offset + buffer_.GetPosition()) & (alignment - 1)) == 0);
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

void Assembler::EmitRegisterOperand(int rm, int reg) {
  Operand operand;
  operand.SetModRM(3, static_cast<Register>(reg));
  EmitOperand(rm, operand);
}

void Assembler::EmitImmediate(const Immediate& imm) {
  if (imm.is_int32()) {
    EmitInt32(static_cast<int32_t>(imm.value()));
  } else {
    EmitInt64(imm.value());
  }
}

void Assembler::EmitSignExtendedInt8(int rm,
                                     const Operand& operand,
                                     const Immediate& immediate) {
  EmitUint8(0x83);
  EmitOperand(rm, operand);
  EmitUint8(immediate.value() & 0xFF);
}

void Assembler::EmitComplex(int rm,
                            const Operand& operand,
                            const Immediate& immediate) {
  ASSERT(rm >= 0 && rm < 8);
  ASSERT(immediate.is_int32());
  if (immediate.is_int8()) {
    EmitSignExtendedInt8(rm, operand, immediate);
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
  EmitRegisterREX(operand, wide ? REX_W : REX_NONE);
  EmitUint8(0xD3);
  EmitOperand(rm, Operand(operand));
}

void Assembler::ExtractClassIdFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kClassIdTagPos == 16);
  ASSERT(target::ObjectLayout::kClassIdTagSize == 16);
  movl(result, tags);
  shrl(result, Immediate(target::ObjectLayout::kClassIdTagPos));
}

void Assembler::ExtractInstanceSizeFromTags(Register result, Register tags) {
  ASSERT(target::ObjectLayout::kSizeTagPos == 8);
  ASSERT(target::ObjectLayout::kSizeTagSize == 8);
  movzxw(result, tags);
  shrl(result, Immediate(target::ObjectLayout::kSizeTagPos -
                         target::ObjectAlignment::kObjectAlignmentLog2));
  AndImmediate(result,
               Immediate(Utils::NBitMask(target::ObjectLayout::kSizeTagSize)
                         << target::ObjectAlignment::kObjectAlignmentLog2));
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
  movq(result, Address(result, table_offset));
  movq(result, Address(result, class_id, TIMES_8, 0));
}

void Assembler::CompareClassId(Register object,
                               intptr_t class_id,
                               Register scratch) {
  LoadClassId(TMP, object);
  cmpl(TMP, Immediate(class_id));
}

void Assembler::SmiUntagOrCheckClass(Register object,
                                     intptr_t class_id,
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
  movzxw(TMP, Address(object, TIMES_2, class_id_offset));
  cmpl(TMP, Immediate(class_id));
}

void Assembler::LoadClassIdMayBeSmi(Register result, Register object) {
  Label smi;

  if (result == object) {
    Label join;

    testq(object, Immediate(kSmiTagMask));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);
    jmp(&join, Assembler::kNearJump);

    Bind(&smi);
    movq(result, Immediate(kSmiCid));

    Bind(&join);
  } else {
    testq(object, Immediate(kSmiTagMask));
    movq(result, Immediate(kSmiCid));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);

    Bind(&smi);
  }
}

void Assembler::LoadTaggedClassIdMayBeSmi(Register result, Register object) {
  Label smi;

  if (result == object) {
    Label join;

    testq(object, Immediate(kSmiTagMask));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);
    SmiTag(result);
    jmp(&join, Assembler::kNearJump);

    Bind(&smi);
    movq(result, Immediate(target::ToRawSmi(kSmiCid)));

    Bind(&join);
  } else {
    testq(object, Immediate(kSmiTagMask));
    movq(result, Immediate(target::ToRawSmi(kSmiCid)));
    j(EQUAL, &smi, Assembler::kNearJump);
    LoadClassId(result, object);
    SmiTag(result);

    Bind(&smi);
  }
}

Address Assembler::VMTagAddress() {
  return Address(THR, target::Thread::vm_tag_offset());
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
                         target::Instance::DataOffsetFor(cid);
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
                                             Register index) {
  if (is_external) {
    return Address(array, index, ToScaleFactor(index_scale, index_unboxed), 0);
  } else {
    return FieldAddress(array, index, ToScaleFactor(index_scale, index_unboxed),
                        target::Instance::DataOffsetFor(cid));
  }
}

}  // namespace compiler
}  // namespace dart

#endif  // defined(TARGET_ARCH_X64)
