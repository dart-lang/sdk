// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_X64_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_X64_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_x64.h directly; use assembler.h instead.
#endif

#include <functional>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/compiler/assembler/assembler_base.h"
#include "vm/constants.h"
#include "vm/constants_x86.h"
#include "vm/hash_map.h"
#include "vm/pointer_tagging.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class RegisterSet;

namespace compiler {

class Immediate : public ValueObject {
 public:
  explicit Immediate(int64_t value) : value_(value) {}

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) {}

  int64_t value() const { return value_; }

  bool is_int8() const { return Utils::IsInt(8, value_); }
  bool is_uint8() const { return Utils::IsUint(8, value_); }
  bool is_int16() const { return Utils::IsInt(16, value_); }
  bool is_uint16() const { return Utils::IsUint(16, value_); }
  bool is_int32() const { return Utils::IsInt(32, value_); }
  bool is_uint32() const { return Utils::IsUint(32, value_); }

 private:
  const int64_t value_;

  // TODO(5411081): Add DISALLOW_COPY_AND_ASSIGN(Immediate) once the mac
  // build issue is resolved.
  // And remove the unnecessary copy constructor.
};

class Operand : public ValueObject {
 public:
  uint8_t rex() const { return rex_; }

  uint8_t mod() const { return (encoding_at(0) >> 6) & 3; }

  Register rm() const {
    int rm_rex = (rex_ & REX_B) << 3;
    return static_cast<Register>(rm_rex + (encoding_at(0) & 7));
  }

  ScaleFactor scale() const {
    return static_cast<ScaleFactor>((encoding_at(1) >> 6) & 3);
  }

  Register index() const {
    int index_rex = (rex_ & REX_X) << 2;
    return static_cast<Register>(index_rex + ((encoding_at(1) >> 3) & 7));
  }

  Register base() const {
    int base_rex = (rex_ & REX_B) << 3;
    return static_cast<Register>(base_rex + (encoding_at(1) & 7));
  }

  int8_t disp8() const {
    ASSERT(length_ >= 2);
    return static_cast<int8_t>(encoding_[length_ - 1]);
  }

  int32_t disp32() const {
    ASSERT(length_ >= 5);
    return bit_copy<int32_t>(encoding_[length_ - 4]);
  }

  Operand(const Operand& other)
      : ValueObject(), length_(other.length_), rex_(other.rex_) {
    memmove(&encoding_[0], &other.encoding_[0], other.length_);
  }

  Operand& operator=(const Operand& other) {
    length_ = other.length_;
    rex_ = other.rex_;
    memmove(&encoding_[0], &other.encoding_[0], other.length_);
    return *this;
  }

  bool Equals(const Operand& other) const {
    if (length_ != other.length_) return false;
    if (rex_ != other.rex_) return false;
    for (uint8_t i = 0; i < length_; i++) {
      if (encoding_[i] != other.encoding_[i]) return false;
    }
    return true;
  }

 protected:
  Operand() : length_(0), rex_(REX_NONE) {}  // Needed by subclass Address.

  void SetModRM(int mod, Register rm) {
    ASSERT((mod & ~3) == 0);
    if ((rm > 7) && !((rm == R12) && (mod != 3))) {
      rex_ |= REX_B;
    }
    encoding_[0] = (mod << 6) | (rm & 7);
    length_ = 1;
  }

  void SetSIB(ScaleFactor scale, Register index, Register base) {
    ASSERT(length_ == 1);
    ASSERT((scale & ~3) == 0);
    if (base > 7) {
      ASSERT((rex_ & REX_B) == 0);  // Must not have REX.B already set.
      rex_ |= REX_B;
    }
    if (index > 7) rex_ |= REX_X;
    encoding_[1] = (scale << 6) | ((index & 7) << 3) | (base & 7);
    length_ = 2;
  }

  void SetDisp8(int8_t disp) {
    ASSERT(length_ == 1 || length_ == 2);
    encoding_[length_++] = static_cast<uint8_t>(disp);
  }

  void SetDisp32(int32_t disp) {
    ASSERT(length_ == 1 || length_ == 2);
    memmove(&encoding_[length_], &disp, sizeof(disp));
    length_ += sizeof(disp);
  }

 private:
  uint8_t length_;
  uint8_t rex_;
  uint8_t encoding_[6];

  explicit Operand(Register reg) : rex_(REX_NONE) { SetModRM(3, reg); }

  // Get the operand encoding byte at the given index.
  uint8_t encoding_at(intptr_t index) const {
    ASSERT(index >= 0 && index < length_);
    return encoding_[index];
  }

  // Returns whether or not this operand is really the given register in
  // disguise. Used from the assembler to generate better encodings.
  bool IsRegister(Register reg) const {
    return ((reg > 7 ? 1 : 0) == (rex_ & REX_B))  // REX.B match.
           && ((encoding_at(0) & 0xF8) == 0xC0)  // Addressing mode is register.
           && ((encoding_at(0) & 0x07) == reg);  // Register codes match.
  }

  friend class Assembler;
};

class Address : public Operand {
 public:
  Address(Register base, int32_t disp) {
    if ((disp == 0) && ((base & 7) != RBP)) {
      SetModRM(0, base);
      if ((base & 7) == RSP) {
        SetSIB(TIMES_1, RSP, base);
      }
    } else if (Utils::IsInt(8, disp)) {
      SetModRM(1, base);
      if ((base & 7) == RSP) {
        SetSIB(TIMES_1, RSP, base);
      }
      SetDisp8(disp);
    } else {
      SetModRM(2, base);
      if ((base & 7) == RSP) {
        SetSIB(TIMES_1, RSP, base);
      }
      SetDisp32(disp);
    }
  }

  // This addressing mode does not exist.
  Address(Register base, Register r);

  Address(Register index, ScaleFactor scale, int32_t disp) {
    ASSERT(index != RSP);       // Illegal addressing mode.
    ASSERT(scale != TIMES_16);  // Unsupported scale factor.
    SetModRM(0, RSP);
    SetSIB(scale, index, RBP);
    SetDisp32(disp);
  }

  // This addressing mode does not exist.
  Address(Register index, ScaleFactor scale, Register r);

  Address(Register base, Register index, ScaleFactor scale, int32_t disp) {
    ASSERT(index != RSP);       // Illegal addressing mode.
    ASSERT(scale != TIMES_16);  // Unsupported scale factor.
    if ((disp == 0) && ((base & 7) != RBP)) {
      SetModRM(0, RSP);
      SetSIB(scale, index, base);
    } else if (Utils::IsInt(8, disp)) {
      SetModRM(1, RSP);
      SetSIB(scale, index, base);
      SetDisp8(disp);
    } else {
      SetModRM(2, RSP);
      SetSIB(scale, index, base);
      SetDisp32(disp);
    }
  }

  // This addressing mode does not exist.
  Address(Register base, Register index, ScaleFactor scale, Register r);

  Address(const Address& other) : Operand(other) {}

  Address& operator=(const Address& other) {
    Operand::operator=(other);
    return *this;
  }

  static Address AddressRIPRelative(int32_t disp) {
    return Address(RIPRelativeDisp(disp));
  }
  static Address AddressBaseImm32(Register base, int32_t disp) {
    return Address(base, disp, true);
  }

  // This addressing mode does not exist.
  static Address AddressBaseImm32(Register base, Register r);

 private:
  Address(Register base, int32_t disp, bool fixed) {
    ASSERT(fixed);
    SetModRM(2, base);
    if ((base & 7) == RSP) {
      SetSIB(TIMES_1, RSP, base);
    }
    SetDisp32(disp);
  }

  struct RIPRelativeDisp {
    explicit RIPRelativeDisp(int32_t disp) : disp_(disp) {}
    const int32_t disp_;
  };

  explicit Address(const RIPRelativeDisp& disp) {
    SetModRM(0, static_cast<Register>(0x5));
    SetDisp32(disp.disp_);
  }
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) {}

  // This addressing mode does not exist.
  FieldAddress(Register base, Register r);

  FieldAddress(Register base, Register index, ScaleFactor scale, int32_t disp)
      : Address(base, index, scale, disp - kHeapObjectTag) {}

  // This addressing mode does not exist.
  FieldAddress(Register base, Register index, ScaleFactor scale, Register r);

  FieldAddress(const FieldAddress& other) : Address(other) {}

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches = false);

  ~Assembler() {}

  /*
   * Emit Machine Instructions.
   */
  void call(Register reg) { EmitUnaryL(reg, 0xFF, 2); }
  void call(const Address& address) { EmitUnaryL(address, 0xFF, 2); }
  void call(Label* label);
  void call(const ExternalLabel* label);

  void pushq(Register reg);
  void pushq(const Address& address) { EmitUnaryL(address, 0xFF, 6); }
  void pushq(const Immediate& imm);
  void PushImmediate(const Immediate& imm) { pushq(imm); }
  void PushImmediate(int64_t value) { PushImmediate(Immediate(value)); }

  void popq(Register reg);
  void popq(const Address& address) { EmitUnaryL(address, 0x8F, 0); }

  void setcc(Condition condition, ByteRegister dst);

  void EnterSafepoint();
  void LeaveSafepoint();
  void TransitionGeneratedToNative(Register destination_address,
                                   Register new_exit_frame,
                                   Register new_exit_through_ffi,
                                   bool enter_safepoint);
  void TransitionNativeToGenerated(bool leave_safepoint);

// Register-register, register-address and address-register instructions.
#define RR(width, name, ...)                                                   \
  void name(Register dst, Register src) { Emit##width(dst, src, __VA_ARGS__); }
#define RA(width, name, ...)                                                   \
  void name(Register dst, const Address& src) {                                \
    Emit##width(dst, src, __VA_ARGS__);                                        \
  }
#define AR(width, name, ...)                                                   \
  void name(const Address& dst, Register src) {                                \
    Emit##width(src, dst, __VA_ARGS__);                                        \
  }
#define REGULAR_INSTRUCTION(name, ...)                                         \
  RA(W, name##w, __VA_ARGS__)                                                  \
  RA(L, name##l, __VA_ARGS__)                                                  \
  RA(Q, name##q, __VA_ARGS__)                                                  \
  RR(W, name##w, __VA_ARGS__)                                                  \
  RR(L, name##l, __VA_ARGS__)                                                  \
  RR(Q, name##q, __VA_ARGS__)
  REGULAR_INSTRUCTION(test, 0x85)
  REGULAR_INSTRUCTION(xchg, 0x87)
  REGULAR_INSTRUCTION(imul, 0xAF, 0x0F)
  REGULAR_INSTRUCTION(bsf, 0xBC, 0x0F)
  REGULAR_INSTRUCTION(bsr, 0xBD, 0x0F)
  REGULAR_INSTRUCTION(popcnt, 0xB8, 0x0F, 0xF3)
  REGULAR_INSTRUCTION(lzcnt, 0xBD, 0x0F, 0xF3)
#undef REGULAR_INSTRUCTION
  RA(Q, movsxd, 0x63)
  RR(Q, movsxd, 0x63)
  AR(L, movb, 0x88)
  AR(L, movl, 0x89)
  AR(Q, movq, 0x89)
  AR(W, movw, 0x89)
  RA(L, movb, 0x8A)
  RA(L, movl, 0x8B)
  RA(Q, movq, 0x8B)
  RR(L, movl, 0x8B)
  RA(Q, leaq, 0x8D)
  RA(L, leal, 0x8D)
  AR(L, cmpxchgl, 0xB1, 0x0F)
  AR(Q, cmpxchgq, 0xB1, 0x0F)
  RA(L, cmpxchgl, 0xB1, 0x0F)
  RA(Q, cmpxchgq, 0xB1, 0x0F)
  RR(L, cmpxchgl, 0xB1, 0x0F)
  RR(Q, cmpxchgq, 0xB1, 0x0F)
  RA(Q, movzxb, 0xB6, 0x0F)
  RR(Q, movzxb, 0xB6, 0x0F)
  RA(Q, movzxw, 0xB7, 0x0F)
  RR(Q, movzxw, 0xB7, 0x0F)
  RA(Q, movsxb, 0xBE, 0x0F)
  RR(Q, movsxb, 0xBE, 0x0F)
  RA(Q, movsxw, 0xBF, 0x0F)
  RR(Q, movsxw, 0xBF, 0x0F)
#define DECLARE_CMOV(name, code)                                               \
  RR(Q, cmov##name##q, 0x40 + code, 0x0F)                                      \
  RR(L, cmov##name##l, 0x40 + code, 0x0F)                                      \
  RA(Q, cmov##name##q, 0x40 + code, 0x0F)                                      \
  RA(L, cmov##name##l, 0x40 + code, 0x0F)
  X86_CONDITIONAL_SUFFIXES(DECLARE_CMOV)
#undef DECLARE_CMOV
#undef AA
#undef RA
#undef AR

#define SIMPLE(name, ...)                                                      \
  void name() { EmitSimple(__VA_ARGS__); }
  SIMPLE(cpuid, 0x0F, 0xA2)
  SIMPLE(fcos, 0xD9, 0xFF)
  SIMPLE(fincstp, 0xD9, 0xF7)
  SIMPLE(fsin, 0xD9, 0xFE)
  SIMPLE(lock, 0xF0)
  SIMPLE(rep_movsb, 0xF3, 0xA4)
  SIMPLE(rep_movsw, 0xF3, 0x66, 0xA5)
  SIMPLE(rep_movsl, 0xF3, 0xA5)
  SIMPLE(rep_movsq, 0xF3, 0x48, 0xA5)
#undef SIMPLE
// XmmRegister operations with another register or an address.
#define XX(width, name, ...)                                                   \
  void name(XmmRegister dst, XmmRegister src) {                                \
    Emit##width(dst, src, __VA_ARGS__);                                        \
  }
#define XA(width, name, ...)                                                   \
  void name(XmmRegister dst, const Address& src) {                             \
    Emit##width(dst, src, __VA_ARGS__);                                        \
  }
#define AX(width, name, ...)                                                   \
  void name(const Address& dst, XmmRegister src) {                             \
    Emit##width(src, dst, __VA_ARGS__);                                        \
  }
  // We could add movupd here, but movups does the same and is shorter.
  XA(L, movups, 0x10, 0x0F);
  XA(L, movsd, 0x10, 0x0F, 0xF2)
  XA(L, movss, 0x10, 0x0F, 0xF3)
  AX(L, movups, 0x11, 0x0F);
  AX(L, movsd, 0x11, 0x0F, 0xF2)
  AX(L, movss, 0x11, 0x0F, 0xF3)
  XX(L, movhlps, 0x12, 0x0F)
  XX(L, unpcklps, 0x14, 0x0F)
  XX(L, unpcklpd, 0x14, 0x0F, 0x66)
  XX(L, unpckhps, 0x15, 0x0F)
  XX(L, unpckhpd, 0x15, 0x0F, 0x66)
  XX(L, movlhps, 0x16, 0x0F)
  XX(L, movaps, 0x28, 0x0F)
  XX(L, comisd, 0x2F, 0x0F, 0x66)
#define DECLARE_XMM(name, code)                                                \
  XX(L, name##ps, 0x50 + code, 0x0F)                                           \
  XA(L, name##ps, 0x50 + code, 0x0F)                                           \
  AX(L, name##ps, 0x50 + code, 0x0F)                                           \
  XX(L, name##pd, 0x50 + code, 0x0F, 0x66)                                     \
  XA(L, name##pd, 0x50 + code, 0x0F, 0x66)                                     \
  AX(L, name##pd, 0x50 + code, 0x0F, 0x66)                                     \
  XX(L, name##sd, 0x50 + code, 0x0F, 0xF2)                                     \
  XA(L, name##sd, 0x50 + code, 0x0F, 0xF2)                                     \
  AX(L, name##sd, 0x50 + code, 0x0F, 0xF2)                                     \
  XX(L, name##ss, 0x50 + code, 0x0F, 0xF3)                                     \
  XA(L, name##ss, 0x50 + code, 0x0F, 0xF3)                                     \
  AX(L, name##ss, 0x50 + code, 0x0F, 0xF3)
  XMM_ALU_CODES(DECLARE_XMM)
#undef DECLARE_XMM
  XX(L, cvtps2pd, 0x5A, 0x0F)
  XX(L, cvtpd2ps, 0x5A, 0x0F, 0x66)
  XX(L, cvtsd2ss, 0x5A, 0x0F, 0xF2)
  XX(L, cvtss2sd, 0x5A, 0x0F, 0xF3)
  XX(L, pxor, 0xEF, 0x0F, 0x66)
  XX(L, subpl, 0xFA, 0x0F, 0x66)
  XX(L, addpl, 0xFE, 0x0F, 0x66)
#undef XX
#undef AX
#undef XA

#define DECLARE_CMPPS(name, code)                                              \
  void cmpps##name(XmmRegister dst, XmmRegister src) {                         \
    EmitL(dst, src, 0xC2, 0x0F);                                               \
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);                         \
    EmitUint8(code);                                                           \
  }
  XMM_CONDITIONAL_CODES(DECLARE_CMPPS)
#undef DECLARE_CMPPS

#define DECLARE_SIMPLE(name, opcode)                                           \
  void name() { EmitSimple(opcode); }
  X86_ZERO_OPERAND_1_BYTE_INSTRUCTIONS(DECLARE_SIMPLE)
#undef DECLARE_SIMPLE

  void movl(Register dst, const Immediate& imm);
  void movl(const Address& dst, const Immediate& imm);

  void movb(const Address& dst, const Immediate& imm);

  void movw(Register dst, const Address& src);
  void movw(const Address& dst, const Immediate& imm);

  void movq(Register dst, const Immediate& imm);
  void movq(const Address& dst, const Immediate& imm);

  // Destination and source are reversed for some reason.
  void movq(Register dst, XmmRegister src) {
    EmitQ(src, dst, 0x7E, 0x0F, 0x66);
  }
  void movl(Register dst, XmmRegister src) {
    EmitL(src, dst, 0x7E, 0x0F, 0x66);
  }
  void movss(XmmRegister dst, XmmRegister src) {
    EmitL(src, dst, 0x11, 0x0F, 0xF3);
  }
  void movsd(XmmRegister dst, XmmRegister src) {
    EmitL(src, dst, 0x11, 0x0F, 0xF2);
  }

  // Use the reversed operand order and the 0x89 bytecode instead of the
  // obvious 0x88 encoding for this some, because it is expected by gdb64 older
  // than 7.3.1-gg5 when disassembling a function's prologue (movq rbp, rsp)
  // for proper unwinding of Dart frames (use --generate_gdb_symbols and -O0).
  void movq(Register dst, Register src) { EmitQ(src, dst, 0x89); }

  void movq(XmmRegister dst, Register src) {
    EmitQ(dst, src, 0x6E, 0x0F, 0x66);
  }

  void movd(XmmRegister dst, Register src) {
    EmitL(dst, src, 0x6E, 0x0F, 0x66);
  }
  void cvtsi2sdq(XmmRegister dst, Register src) {
    EmitQ(dst, src, 0x2A, 0x0F, 0xF2);
  }
  void cvtsi2sdl(XmmRegister dst, Register src) {
    EmitL(dst, src, 0x2A, 0x0F, 0xF2);
  }
  void cvttsd2siq(Register dst, XmmRegister src) {
    EmitQ(dst, src, 0x2C, 0x0F, 0xF2);
  }
  void cvttsd2sil(Register dst, XmmRegister src) {
    EmitL(dst, src, 0x2C, 0x0F, 0xF2);
  }
  void movmskpd(Register dst, XmmRegister src) {
    EmitL(dst, src, 0x50, 0x0F, 0x66);
  }
  void movmskps(Register dst, XmmRegister src) { EmitL(dst, src, 0x50, 0x0F); }
  void pmovmskb(Register dst, XmmRegister src) {
    EmitL(dst, src, 0xD7, 0x0F, 0x66);
  }

  void btl(Register dst, Register src) { EmitL(src, dst, 0xA3, 0x0F); }
  void btq(Register dst, Register src) { EmitQ(src, dst, 0xA3, 0x0F); }

  void notps(XmmRegister dst, XmmRegister src);
  void negateps(XmmRegister dst, XmmRegister src);
  void absps(XmmRegister dst, XmmRegister src);
  void zerowps(XmmRegister dst, XmmRegister src);

  void set1ps(XmmRegister dst, Register tmp, const Immediate& imm);
  void shufps(XmmRegister dst, XmmRegister src, const Immediate& mask);

  void negatepd(XmmRegister dst, XmmRegister src);
  void abspd(XmmRegister dst, XmmRegister src);
  void shufpd(XmmRegister dst, XmmRegister src, const Immediate& mask);

  enum RoundingMode {
    kRoundToNearest = 0x0,
    kRoundDown = 0x1,
    kRoundUp = 0x2,
    kRoundToZero = 0x3
  };
  void roundsd(XmmRegister dst, XmmRegister src, RoundingMode mode);

  void CompareImmediate(Register reg, const Immediate& imm);
  void CompareImmediate(const Address& address, const Immediate& imm);
  void CompareImmediate(Register reg, int32_t immediate) {
    return CompareImmediate(reg, Immediate(immediate));
  }

  void testl(Register reg, const Immediate& imm) { testq(reg, imm); }
  void testb(const Address& address, const Immediate& imm);
  void testb(const Address& address, Register reg);

  void testq(Register reg, const Immediate& imm);
  void TestImmediate(Register dst, const Immediate& imm);

  void AndImmediate(Register dst, const Immediate& imm);
  void OrImmediate(Register dst, const Immediate& imm);
  void XorImmediate(Register dst, const Immediate& imm);

  void shldq(Register dst, Register src, Register shifter) {
    ASSERT(shifter == RCX);
    EmitQ(src, dst, 0xA5, 0x0F);
  }
  void shrdq(Register dst, Register src, Register shifter) {
    ASSERT(shifter == RCX);
    EmitQ(src, dst, 0xAD, 0x0F);
  }

#define DECLARE_ALU(op, c)                                                     \
  void op##w(Register dst, Register src) { EmitW(dst, src, c * 8 + 3); }       \
  void op##l(Register dst, Register src) { EmitL(dst, src, c * 8 + 3); }       \
  void op##q(Register dst, Register src) { EmitQ(dst, src, c * 8 + 3); }       \
  void op##w(Register dst, const Address& src) { EmitW(dst, src, c * 8 + 3); } \
  void op##l(Register dst, const Address& src) { EmitL(dst, src, c * 8 + 3); } \
  void op##q(Register dst, const Address& src) { EmitQ(dst, src, c * 8 + 3); } \
  void op##w(const Address& dst, Register src) { EmitW(src, dst, c * 8 + 1); } \
  void op##l(const Address& dst, Register src) { EmitL(src, dst, c * 8 + 1); } \
  void op##q(const Address& dst, Register src) { EmitQ(src, dst, c * 8 + 1); } \
  void op##l(Register dst, const Immediate& imm) { AluL(c, dst, imm); }        \
  void op##q(Register dst, const Immediate& imm) {                             \
    AluQ(c, c * 8 + 3, dst, imm);                                              \
  }                                                                            \
  void op##b(const Address& dst, const Immediate& imm) { AluB(c, dst, imm); }  \
  void op##w(const Address& dst, const Immediate& imm) { AluW(c, dst, imm); }  \
  void op##l(const Address& dst, const Immediate& imm) { AluL(c, dst, imm); }  \
  void op##q(const Address& dst, const Immediate& imm) {                       \
    AluQ(c, c * 8 + 3, dst, imm);                                              \
  }

  X86_ALU_CODES(DECLARE_ALU)

#undef DECLARE_ALU
#undef ALU_OPS

  void cqo();

#define REGULAR_UNARY(name, opcode, modrm)                                     \
  void name##q(Register reg) { EmitUnaryQ(reg, opcode, modrm); }               \
  void name##l(Register reg) { EmitUnaryL(reg, opcode, modrm); }               \
  void name##q(const Address& address) { EmitUnaryQ(address, opcode, modrm); } \
  void name##l(const Address& address) { EmitUnaryL(address, opcode, modrm); }
  REGULAR_UNARY(not, 0xF7, 2)
  REGULAR_UNARY(neg, 0xF7, 3)
  REGULAR_UNARY(mul, 0xF7, 4)
  REGULAR_UNARY(imul, 0xF7, 5)
  REGULAR_UNARY(div, 0xF7, 6)
  REGULAR_UNARY(idiv, 0xF7, 7)
  REGULAR_UNARY(inc, 0xFF, 0)
  REGULAR_UNARY(dec, 0xFF, 1)
#undef REGULAR_UNARY

  void imull(Register reg, const Immediate& imm);

  void imulq(Register dst, const Immediate& imm);
  void MulImmediate(Register reg,
                    const Immediate& imm,
                    OperandSize width = kEightBytes);

  void shll(Register reg, const Immediate& imm);
  void shll(Register operand, Register shifter);
  void shrl(Register reg, const Immediate& imm);
  void shrl(Register operand, Register shifter);
  void sarl(Register reg, const Immediate& imm);
  void sarl(Register operand, Register shifter);
  void shldl(Register dst, Register src, const Immediate& imm);

  void shlq(Register reg, const Immediate& imm);
  void shlq(Register operand, Register shifter);
  void shrq(Register reg, const Immediate& imm);
  void shrq(Register operand, Register shifter);
  void sarq(Register reg, const Immediate& imm);
  void sarq(Register operand, Register shifter);
  void shldq(Register dst, Register src, const Immediate& imm);

  void btq(Register base, int bit);

  void enter(const Immediate& imm);

  void fldl(const Address& src);
  void fstpl(const Address& dst);

  void ffree(intptr_t value);

  // 'size' indicates size in bytes and must be in the range 1..8.
  void nop(int size = 1);

  void j(Condition condition, Label* label, JumpDistance distance = kFarJump);
  void jmp(Register reg) { EmitUnaryL(reg, 0xFF, 4); }
  void jmp(const Address& address) { EmitUnaryL(address, 0xFF, 4); }
  void jmp(Label* label, JumpDistance distance = kFarJump);
  void jmp(const ExternalLabel* label);
  void jmp(const Code& code);

  // Issue memory to memory move through a TMP register.
  // TODO(koda): Assert that these are not used for heap objects.
  void MoveMemoryToMemory(const Address& dst, const Address& src) {
    movq(TMP, src);
    movq(dst, TMP);
  }

  void Exchange(Register reg, const Address& mem) {
    movq(TMP, mem);
    movq(mem, reg);
    movq(reg, TMP);
  }

  void Exchange(const Address& mem1, const Address& mem2) {
    movq(TMP, mem1);
    xorq(TMP, mem2);
    xorq(mem1, TMP);
    xorq(mem2, TMP);
  }

  // Methods for High-level operations and implemented on all architectures.
  void Ret() { ret(); }
  void CompareRegisters(Register a, Register b);
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump) {
    j(condition, label, distance);
  }
  void BranchIfZero(Register src,
                    Label* label,
                    JumpDistance distance = kFarJump) {
    cmpq(src, Immediate(0));
    j(ZERO, label, distance);
  }

  // Issues a move instruction if 'to' is not the same as 'from'.
  void MoveRegister(Register to, Register from);
  void PushRegister(Register r);
  void PopRegister(Register r);

  void PushRegisterPair(Register r0, Register r1) {
    PushRegister(r1);
    PushRegister(r0);
  }
  void PopRegisterPair(Register r0, Register r1) {
    PopRegister(r0);
    PopRegister(r1);
  }

  // Methods for adding/subtracting an immediate value that may be loaded from
  // the constant pool.
  // TODO(koda): Assert that these are not used for heap objects.
  void AddImmediate(Register reg,
                    const Immediate& imm,
                    OperandSize width = kEightBytes);
  void AddImmediate(Register reg,
                    int32_t value,
                    OperandSize width = kEightBytes) {
    AddImmediate(reg, Immediate(value), width);
  }
  void AddImmediate(const Address& address, const Immediate& imm);
  void SubImmediate(Register reg,
                    const Immediate& imm,
                    OperandSize width = kEightBytes);
  void SubImmediate(const Address& address, const Immediate& imm);

  void Drop(intptr_t stack_elements, Register tmp = TMP);

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

  // Unlike movq this can affect the flags or use the constant pool.
  void LoadImmediate(Register reg, const Immediate& imm);
  void LoadImmediate(Register reg, int32_t immediate) {
    LoadImmediate(reg, Immediate(immediate));
  }

  void LoadIsolate(Register dst);
  void LoadDispatchTable(Register dst);
  void LoadObject(Register dst, const Object& obj);
  void LoadUniqueObject(Register dst, const Object& obj);
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable);
  void JmpPatchable(const Code& code, Register pp);
  void Jmp(const Code& code, Register pp = PP);
  void J(Condition condition, const Code& code, Register pp);
  void CallPatchable(const Code& code,
                     CodeEntryKind entry_kind = CodeEntryKind::kNormal);
  void Call(const Code& stub_entry);
  void CallToRuntime();

  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void CallWithEquivalence(const Code& code,
                           const Object& equivalence,
                           CodeEntryKind entry_kind = CodeEntryKind::kNormal);

  void Call(Address target) { call(target); }

  // Unaware of write barrier (use StoreInto* methods for storing to objects).
  // TODO(koda): Add StackAddress/HeapAddress types to prevent misuse.
  void StoreObject(const Address& dst, const Object& obj);
  void PushObject(const Object& object);
  void CompareObject(Register reg, const Object& object);

  enum CanBeSmi {
    kValueIsNotSmi,
    kValueCanBeSmi,
  };

  // Store into a heap object and apply the generational and incremental write
  // barriers. All stores into heap objects must pass through this function or,
  // if the value can be proven either Smi or old-and-premarked, its NoBarrier
  // variants.
  // Preserves object and value registers.
  void StoreIntoObject(Register object,      // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,       // Value we are storing.
                       CanBeSmi can_be_smi = kValueCanBeSmi);
  void StoreIntoArray(Register object,  // Object we are storing into.
                      Register slot,    // Where we are storing into.
                      Register value,   // Value we are storing.
                      CanBeSmi can_be_smi = kValueCanBeSmi);

  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);

  // Stores a non-tagged value into a heap object.
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value);

  // Stores a Smi value into a heap object field that always contains a Smi.
  void StoreIntoSmiField(const Address& dest, Register value);
  void ZeroInitSmiField(const Address& dest);
  // Increments a Smi field. Leaves flags in same state as an 'addq'.
  void IncrementSmiField(const Address& dest, int64_t increment);

  void DoubleNegate(XmmRegister dst, XmmRegister src);
  void DoubleAbs(XmmRegister dst, XmmRegister src);

  void LockCmpxchgq(const Address& address, Register reg) {
    lock();
    cmpxchgq(address, reg);
  }

  void LockCmpxchgl(const Address& address, Register reg) {
    lock();
    cmpxchgl(address, reg);
  }

  void PushRegisters(const RegisterSet& registers);
  void PopRegisters(const RegisterSet& registers);

  void CheckCodePointer();

  void EnterFrame(intptr_t frame_space);
  void LeaveFrame();
  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // In debug mode, generates code to verify that:
  //   FP + kExitLinkSlotFromFp == SP
  //
  // Triggers breakpoint otherwise.
  // Clobbers RAX.
  void EmitEntryFrameVerification();

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's RSP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Call runtime function. Reserves shadow space on the stack before calling
  // if platform ABI requires that.
  void CallCFunction(Register reg, bool restore_rsp = false);
  void CallCFunction(Address address, bool restore_rsp = false);

  void ExtractClassIdFromTags(Register result, Register tags);
  void ExtractInstanceSizeFromTags(Register result, Register tags);

  // Loading and comparing classes of objects.
  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);

  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch = kNoRegister);

  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  // CheckClassIs fused with optimistic SmiUntag.
  // Value in the register object is untagged optimistically.
  void SmiUntagOrCheckClass(Register object, intptr_t class_id, Label* smi);

  // Misc. functionality.
  void SmiTag(Register reg) { addq(reg, reg); }

  void SmiUntag(Register reg) { sarq(reg, Immediate(kSmiTagSize)); }

  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump) {
    testq(reg, Immediate(kSmiTagMask));
    j(NOT_ZERO, label, distance);
  }

  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) {
    testq(reg, Immediate(kSmiTagMask));
    j(ZERO, label, distance);
  }

  void Align(int alignment, intptr_t offset);
  void Bind(Label* label);
  // Unconditional jump to a given label.
  void Jump(Label* label, JumpDistance distance = kFarJump) {
    jmp(label, distance);
  }
  // Unconditional jump to a given address in memory.
  void Jump(const Address& address) { jmp(address); }

  // Arch-specific LoadFromOffset to choose the right operation for [sz].
  void LoadFromOffset(Register dst,
                      const Address& address,
                      OperandSize sz = kEightBytes);
  void LoadFromOffset(Register dst,
                      Register base,
                      int32_t offset,
                      OperandSize sz = kEightBytes) {
    LoadFromOffset(dst, Address(base, offset), sz);
  }
  void LoadField(Register dst,
                 FieldAddress address,
                 OperandSize sz = kEightBytes) {
    LoadFromOffset(dst, address, sz);
  }
  void LoadFieldFromOffset(Register dst,
                           Register base,
                           int32_t offset,
                           OperandSize sz = kEightBytes) {
    LoadFromOffset(dst, FieldAddress(base, offset), sz);
  }
  void LoadIndexedPayload(Register dst,
                          Register base,
                          int32_t payload_offset,
                          Register index,
                          ScaleFactor scale,
                          OperandSize sz = kEightBytes) {
    LoadFromOffset(dst, FieldAddress(base, index, scale, payload_offset), sz);
  }
  void StoreFieldToOffset(Register src,
                          Register base,
                          int32_t offset,
                          OperandSize sz = kEightBytes) {
    if (sz != kEightBytes) {
      UNIMPLEMENTED();
    }
    StoreMemoryValue(src, base, offset - kHeapObjectTag);
  }
  void LoadFromStack(Register dst, intptr_t depth);
  void StoreToStack(Register src, intptr_t depth);
  void CompareToStack(Register src, intptr_t depth);
  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
    movq(dst, Address(base, offset));
  }
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
    movq(Address(base, offset), src);
  }
  void LoadAcquire(Register dst, Register address, int32_t offset = 0) {
    // On intel loads have load-acquire behavior (i.e. loads are not re-ordered
    // with other loads).
    movq(dst, Address(address, offset));
  }
  void StoreRelease(Register src, Register address, int32_t offset = 0) {
    // On intel stores have store-release behavior (i.e. stores are not
    // re-ordered with other stores).
    movq(Address(address, offset), src);
  }

  void CompareWithFieldValue(Register value, FieldAddress address) {
    cmpq(value, address);
  }

  void CompareTypeNullabilityWith(Register type, int8_t value) {
    cmpb(FieldAddress(type, compiler::target::Type::nullability_offset()),
         Immediate(value));
  }

  void RestoreCodePointer();
  void LoadPoolPointer(Register pp = PP);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  // The dart frame layout is as follows:
  //   ....
  //   locals space  <=== RSP
  //   saved PP
  //   code object (used to derive the RawInstruction Object of the dart code)
  //   saved RBP     <=== RBP
  //   ret PC
  //   .....
  // This code sets this up with the sequence:
  //   pushq rbp
  //   movq rbp, rsp
  //   call L
  //   L: <code to adjust saved pc if there is any intrinsification code>
  //   ...
  //   pushq r15
  //   .....
  void EnterDartFrame(intptr_t frame_size, Register new_pp = kNoRegister);
  void LeaveDartFrame(RestorePP restore_pp = kRestoreCallerPP);

  // Set up a Dart frame for a function compiled for on-stack replacement.
  // The frame layout is a normal Dart frame, but the frame is partially set
  // up on entry (it is the frame of the unoptimized code).
  void EnterOsrFrame(intptr_t extra_size);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  // The stub frame layout is as follows:
  //   ....       <=== RSP
  //   pc (used to derive the RawInstruction Object of the stub)
  //   saved RBP  <=== RBP
  //   ret PC
  //   .....
  // This code sets this up with the sequence:
  //   pushq rbp
  //   movq rbp, rsp
  //   pushq immediate(0)
  //   .....
  void EnterStubFrame();
  void LeaveStubFrame();

  // Set up a frame for calling a C function.
  // Automatically save the pinned registers in Dart which are not callee-
  // saved in the native calling convention.
  // Use together with CallCFunction.
  void EnterCFrame(intptr_t frame_space);
  void LeaveCFrame();

  void MonomorphicCheckedEntryJIT();
  void MonomorphicCheckedEntryAOT();
  void BranchOnMonomorphicCheckedEntryJIT(Label* label);

  // If allocation tracing for |cid| is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(intptr_t cid, Label* trace, JumpDistance distance);

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   JumpDistance distance,
                   Register instance_reg,
                   Register temp);

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        JumpDistance distance,
                        Register instance,
                        Register end_address,
                        Register temp);

  // This emits an PC-relative call of the form "callq *[rip+<offset>]".  The
  // offset is not yet known and needs therefore relocation to the right place
  // before the code can be used.
  //
  // The neccessary information for the "linker" (i.e. the relocation
  // information) is stored in [CodeLayout::static_calls_target_table_]: an
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

  // This emits an PC-relative tail call of the form "jmp *[rip+<offset>]".
  //
  // See also above for the pc-relative call.
  void GenerateUnRelocatedPcRelativeTailCall(intptr_t offset_into_target = 0);

  // Debugging and bringup support.
  void Breakpoint() override { int3(); }

  static Address ElementAddressForIntIndex(bool is_external,
                                           intptr_t cid,
                                           intptr_t index_scale,
                                           Register array,
                                           intptr_t index);
  static Address ElementAddressForRegIndex(bool is_external,
                                           intptr_t cid,
                                           intptr_t index_scale,
                                           bool index_unboxed,
                                           Register array,
                                           Register index);

  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi) {
    static_assert(kSmiTagShift == 1, "adjust scale factor");
    leaq(address, FieldAddress(instance, offset_in_words_as_smi, TIMES_4, 0));
  }

  static Address VMTagAddress();

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

 private:
  bool constant_pool_allowed_;

  intptr_t FindImmediate(int64_t imm);
  bool CanLoadFromObjectPool(const Object& object) const;
  void LoadObjectHelper(Register dst, const Object& obj, bool is_unique);
  void LoadWordFromPoolIndex(Register dst, intptr_t index);

  void AluL(uint8_t modrm_opcode, Register dst, const Immediate& imm);
  void AluB(uint8_t modrm_opcode, const Address& dst, const Immediate& imm);
  void AluW(uint8_t modrm_opcode, const Address& dst, const Immediate& imm);
  void AluL(uint8_t modrm_opcode, const Address& dst, const Immediate& imm);
  void AluQ(uint8_t modrm_opcode,
            uint8_t opcode,
            Register dst,
            const Immediate& imm);
  void AluQ(uint8_t modrm_opcode,
            uint8_t opcode,
            const Address& dst,
            const Immediate& imm);

  void EmitSimple(int opcode, int opcode2 = -1, int opcode3 = -1);
  void EmitUnaryQ(Register reg, int opcode, int modrm_code);
  void EmitUnaryL(Register reg, int opcode, int modrm_code);
  void EmitUnaryQ(const Address& address, int opcode, int modrm_code);
  void EmitUnaryL(const Address& address, int opcode, int modrm_code);
  // The prefixes are in reverse order due to the rules of default arguments in
  // C++.
  void EmitQ(int reg,
             const Address& address,
             int opcode,
             int prefix2 = -1,
             int prefix1 = -1);
  void EmitL(int reg,
             const Address& address,
             int opcode,
             int prefix2 = -1,
             int prefix1 = -1);
  void EmitW(Register reg,
             const Address& address,
             int opcode,
             int prefix2 = -1,
             int prefix1 = -1);
  void EmitQ(int dst, int src, int opcode, int prefix2 = -1, int prefix1 = -1);
  void EmitL(int dst, int src, int opcode, int prefix2 = -1, int prefix1 = -1);
  void EmitW(Register dst,
             Register src,
             int opcode,
             int prefix2 = -1,
             int prefix1 = -1);
  void CmpPS(XmmRegister dst, XmmRegister src, int condition);

  inline void EmitUint8(uint8_t value);
  inline void EmitInt32(int32_t value);
  inline void EmitUInt32(uint32_t value);
  inline void EmitInt64(int64_t value);

  inline void EmitRegisterREX(Register reg,
                              uint8_t rex,
                              bool force_emit = false);
  inline void EmitOperandREX(int rm, const Operand& operand, uint8_t rex);
  inline void EmitRegisterOperand(int rm, int reg);
  inline void EmitFixup(AssemblerFixup* fixup);
  inline void EmitOperandSizeOverride();
  inline void EmitRegRegRex(int reg, int base, uint8_t rex = REX_NONE);
  void EmitOperand(int rm, const Operand& operand);
  void EmitImmediate(const Immediate& imm);
  void EmitComplex(int rm, const Operand& operand, const Immediate& immediate);
  void EmitSignExtendedInt8(int rm,
                            const Operand& operand,
                            const Immediate& immediate);
  void EmitLabel(Label* label, intptr_t instruction_size);
  void EmitLabelLink(Label* label);
  void EmitNearLabelLink(Label* label);

  void EmitGenericShift(bool wide, int rm, Register reg, const Immediate& imm);
  void EmitGenericShift(bool wide, int rm, Register operand, Register shifter);

  enum BarrierFilterMode {
    // Filter falls through into the barrier update code. Target label
    // is a "after-store" label.
    kJumpToNoUpdate,

    // Filter falls through to the "after-store" code. Target label
    // is barrier update code label.
    kJumpToBarrier,
  };

  void StoreIntoObjectFilter(Register object,
                             Register value,
                             Label* label,
                             CanBeSmi can_be_smi,
                             BarrierFilterMode barrier_filter_mode);

  // Unaware of write barrier (use StoreInto* methods for storing to objects).
  void MoveImmediate(const Address& dst, const Immediate& imm);

  friend class dart::FlowGraphCompiler;
  std::function<void(Register reg)> generate_invoke_write_barrier_wrapper_;
  std::function<void()> generate_invoke_array_write_barrier_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

inline void Assembler::EmitUint8(uint8_t value) {
  buffer_.Emit<uint8_t>(value);
}

inline void Assembler::EmitInt32(int32_t value) {
  buffer_.Emit<int32_t>(value);
}

inline void Assembler::EmitUInt32(uint32_t value) {
  buffer_.Emit<uint32_t>(value);
}

inline void Assembler::EmitInt64(int64_t value) {
  buffer_.Emit<int64_t>(value);
}

inline void Assembler::EmitRegisterREX(Register reg, uint8_t rex, bool force) {
  ASSERT(reg != kNoRegister && reg <= R15);
  ASSERT(rex == REX_NONE || rex == REX_W);
  rex |= (reg > 7 ? REX_B : REX_NONE);
  if (rex != REX_NONE || force) EmitUint8(REX_PREFIX | rex);
}

inline void Assembler::EmitOperandREX(int rm,
                                      const Operand& operand,
                                      uint8_t rex) {
  rex |= (rm > 7 ? REX_R : REX_NONE) | operand.rex();
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}

inline void Assembler::EmitRegRegRex(int reg, int base, uint8_t rex) {
  ASSERT(reg != kNoRegister && reg <= R15);
  ASSERT(base != kNoRegister && base <= R15);
  ASSERT(rex == REX_NONE || rex == REX_W);
  if (reg > 7) rex |= REX_R;
  if (base > 7) rex |= REX_B;
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}

inline void Assembler::EmitFixup(AssemblerFixup* fixup) {
  buffer_.EmitFixup(fixup);
}

inline void Assembler::EmitOperandSizeOverride() {
  EmitUint8(0x66);
}

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_X64_H_
