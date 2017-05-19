// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ASSEMBLER_X64_H_
#define RUNTIME_VM_ASSEMBLER_X64_H_

#ifndef RUNTIME_VM_ASSEMBLER_H_
#error Do not include assembler_x64.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_x64.h"
#include "vm/hash_map.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;
class StubEntry;

class Immediate : public ValueObject {
 public:
  explicit Immediate(int64_t value) : value_(value) {}

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) {}

  int64_t value() const { return value_; }

  bool is_int8() const { return Utils::IsInt(8, value_); }
  bool is_uint8() const { return Utils::IsUint(8, value_); }
  bool is_uint16() const { return Utils::IsUint(16, value_); }
  bool is_int32() const { return Utils::IsInt(32, value_); }

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
    ASSERT(index != RSP);  // Illegal addressing mode.
    SetModRM(0, RSP);
    SetSIB(scale, index, RBP);
    SetDisp32(disp);
  }

  // This addressing mode does not exist.
  Address(Register index, ScaleFactor scale, Register r);

  Address(Register base, Register index, ScaleFactor scale, int32_t disp) {
    ASSERT(index != RSP);  // Illegal addressing mode.
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


class Label : public ValueObject {
 public:
  Label() : position_(0), unresolved_(0) {
#ifdef DEBUG
    for (int i = 0; i < kMaxUnresolvedBranches; i++) {
      unresolved_near_positions_[i] = -1;
    }
#endif  // DEBUG
  }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
    ASSERT(!HasNear());
  }

  // Returns the position for bound labels. Cannot be used for unused or linked
  // labels.
  intptr_t Position() const {
    ASSERT(IsBound());
    return -position_ - kWordSize;
  }

  intptr_t LinkPosition() const {
    ASSERT(IsLinked());
    return position_ - kWordSize;
  }

  intptr_t NearPosition() {
    ASSERT(HasNear());
    return unresolved_near_positions_[--unresolved_];
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return (position_ == 0) && (unresolved_ == 0); }
  bool IsLinked() const { return position_ > 0; }
  bool HasNear() const { return unresolved_ != 0; }

 private:
  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    ASSERT(!HasNear());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  void NearLinkTo(intptr_t position) {
    ASSERT(!IsBound());
    ASSERT(unresolved_ < kMaxUnresolvedBranches);
    unresolved_near_positions_[unresolved_++] = position;
  }

  static const int kMaxUnresolvedBranches = 20;

  intptr_t position_;
  intptr_t unresolved_;
  intptr_t unresolved_near_positions_[kMaxUnresolvedBranches];

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false);

  ~Assembler() {}

  static const bool kNearJump = true;
  static const bool kFarJump = false;

  /*
   * Emit Machine Instructions.
   */
  void call(Register reg);
  void call(const Address& address);
  void call(Label* label);
  void call(const ExternalLabel* label);

  static const intptr_t kCallExternalLabelSize = 15;

  void pushq(Register reg);
  void pushq(const Address& address);
  void pushq(const Immediate& imm);
  void PushImmediate(const Immediate& imm);

  void popq(Register reg);
  void popq(const Address& address);

  void setcc(Condition condition, ByteRegister dst);

  void movl(Register dst, Register src);
  void movl(Register dst, const Immediate& imm);
  void movl(Register dst, const Address& src);
  void movl(const Address& dst, Register src);
  void movl(const Address& dst, const Immediate& imm);

  void movzxb(Register dst, Register src);
  void movzxb(Register dst, const Address& src);
  void movsxb(Register dst, Register src);
  void movsxb(Register dst, const Address& src);
  void movb(Register dst, const Address& src);
  void movb(const Address& dst, Register src);
  void movb(const Address& dst, const Immediate& imm);

  void movzxw(Register dst, Register src);
  void movzxw(Register dst, const Address& src);
  void movsxw(Register dst, Register src);
  void movsxw(Register dst, const Address& src);
  void movw(Register dst, const Address& src);
  void movw(const Address& dst, Register src);
  void movw(const Address& dst, const Immediate& imm);

  void movq(Register dst, const Immediate& imm);
  void movq(Register dst, Register src);
  void movq(Register dst, const Address& src);
  void movq(const Address& dst, Register src);
  void movq(const Address& dst, const Immediate& imm);

  void movsxd(Register dst, Register src);
  void movsxd(Register dst, const Address& src);

  void rep_movsb();

  void leaq(Register dst, const Address& src);

  void cmovnoq(Register dst, Register src);
  void cmoveq(Register dst, Register src);
  void cmovgeq(Register dst, Register src);
  void cmovlessq(Register dst, Register src);

  void movss(XmmRegister dst, const Address& src);
  void movss(const Address& dst, XmmRegister src);
  void movss(XmmRegister dst, XmmRegister src);

  void movd(XmmRegister dst, Register src);
  void movd(Register dst, XmmRegister src);

  void addss(XmmRegister dst, XmmRegister src);
  void subss(XmmRegister dst, XmmRegister src);
  void mulss(XmmRegister dst, XmmRegister src);
  void divss(XmmRegister dst, XmmRegister src);

  void movsd(XmmRegister dst, const Address& src);
  void movsd(const Address& dst, XmmRegister src);
  void movsd(XmmRegister dst, XmmRegister src);

  void movaps(XmmRegister dst, XmmRegister src);

  void movups(const Address& dst, XmmRegister src);
  void movups(XmmRegister dst, const Address& src);

  void addsd(XmmRegister dst, XmmRegister src);
  void subsd(XmmRegister dst, XmmRegister src);
  void mulsd(XmmRegister dst, XmmRegister src);
  void divsd(XmmRegister dst, XmmRegister src);

  void addpl(XmmRegister dst, XmmRegister src);
  void subpl(XmmRegister dst, XmmRegister src);
  void addps(XmmRegister dst, XmmRegister src);
  void subps(XmmRegister dst, XmmRegister src);
  void divps(XmmRegister dst, XmmRegister src);
  void mulps(XmmRegister dst, XmmRegister src);
  void minps(XmmRegister dst, XmmRegister src);
  void maxps(XmmRegister dst, XmmRegister src);
  void andps(XmmRegister dst, XmmRegister src);
  void andps(XmmRegister dst, const Address& src);
  void orps(XmmRegister dst, XmmRegister src);
  void notps(XmmRegister dst);
  void negateps(XmmRegister dst);
  void absps(XmmRegister dst);
  void zerowps(XmmRegister dst);
  void cmppseq(XmmRegister dst, XmmRegister src);
  void cmppsneq(XmmRegister dst, XmmRegister src);
  void cmppslt(XmmRegister dst, XmmRegister src);
  void cmppsle(XmmRegister dst, XmmRegister src);
  void cmppsnlt(XmmRegister dst, XmmRegister src);
  void cmppsnle(XmmRegister dst, XmmRegister src);
  void sqrtps(XmmRegister dst);
  void rsqrtps(XmmRegister dst);
  void reciprocalps(XmmRegister dst);
  void movhlps(XmmRegister dst, XmmRegister src);
  void movlhps(XmmRegister dst, XmmRegister src);
  void unpcklps(XmmRegister dst, XmmRegister src);
  void unpckhps(XmmRegister dst, XmmRegister src);
  void unpcklpd(XmmRegister dst, XmmRegister src);
  void unpckhpd(XmmRegister dst, XmmRegister src);

  void set1ps(XmmRegister dst, Register tmp, const Immediate& imm);
  void shufps(XmmRegister dst, XmmRegister src, const Immediate& mask);

  void addpd(XmmRegister dst, XmmRegister src);
  void negatepd(XmmRegister dst);
  void subpd(XmmRegister dst, XmmRegister src);
  void mulpd(XmmRegister dst, XmmRegister src);
  void divpd(XmmRegister dst, XmmRegister src);
  void abspd(XmmRegister dst);
  void minpd(XmmRegister dst, XmmRegister src);
  void maxpd(XmmRegister dst, XmmRegister src);
  void sqrtpd(XmmRegister dst);
  void cvtps2pd(XmmRegister dst, XmmRegister src);
  void cvtpd2ps(XmmRegister dst, XmmRegister src);
  void shufpd(XmmRegister dst, XmmRegister src, const Immediate& mask);

  void comisd(XmmRegister a, XmmRegister b);
  void cvtsi2sdq(XmmRegister a, Register b);
  void cvtsi2sdl(XmmRegister a, Register b);
  void cvttsd2siq(Register dst, XmmRegister src);

  void cvtss2sd(XmmRegister dst, XmmRegister src);
  void cvtsd2ss(XmmRegister dst, XmmRegister src);

  void pxor(XmmRegister dst, XmmRegister src);

  enum RoundingMode {
    kRoundToNearest = 0x0,
    kRoundDown = 0x1,
    kRoundUp = 0x2,
    kRoundToZero = 0x3
  };
  void roundsd(XmmRegister dst, XmmRegister src, RoundingMode mode);

  void xchgl(Register dst, Register src);
  void xchgq(Register dst, Register src);

  void cmpb(const Address& address, const Immediate& imm);

  void cmpw(Register reg, const Address& address);
  void cmpw(const Address& address, const Immediate& imm);

  void cmpl(Register reg, const Immediate& imm);
  void cmpl(Register reg0, Register reg1);
  void cmpl(Register reg, const Address& address);
  void cmpl(const Address& address, const Immediate& imm);

  void cmpq(Register reg, const Immediate& imm);
  void cmpq(const Address& address, Register reg);
  void cmpq(const Address& address, const Immediate& imm);
  void cmpq(Register reg0, Register reg1);
  void cmpq(Register reg, const Address& address);

  void CompareImmediate(Register reg, const Immediate& imm);
  void CompareImmediate(const Address& address, const Immediate& imm);

  void testl(Register reg1, Register reg2);
  void testl(Register reg, const Immediate& imm);
  void testb(const Address& address, const Immediate& imm);

  void testq(Register reg1, Register reg2);
  void testq(Register reg, const Immediate& imm);
  void TestImmediate(Register dst, const Immediate& imm);

  void andl(Register dst, Register src);
  void andl(Register dst, const Immediate& imm);

  void orl(Register dst, Register src);
  void orl(Register dst, const Immediate& imm);
  void orl(const Address& dst, Register src);

  void xorl(Register dst, Register src);

  void andq(Register dst, Register src);
  void andq(Register dst, const Address& address);
  void andq(Register dst, const Immediate& imm);
  void AndImmediate(Register dst, const Immediate& imm);

  void orq(Register dst, Register src);
  void orq(Register dst, const Address& address);
  void orq(Register dst, const Immediate& imm);
  void OrImmediate(Register dst, const Immediate& imm);

  void xorq(Register dst, Register src);
  void xorq(Register dst, const Address& address);
  void xorq(const Address& dst, Register src);
  void xorq(Register dst, const Immediate& imm);
  void XorImmediate(Register dst, const Immediate& imm);

  void addl(Register dst, Register src);
  void addl(Register dst, const Immediate& imm);
  void addl(Register dst, const Address& address);
  void addl(const Address& address, Register src);
  void adcl(Register dst, Register src);
  void adcl(Register dst, const Immediate& imm);
  void adcl(Register dst, const Address& address);

  void addq(Register dst, Register src);
  void addq(Register dst, const Immediate& imm);
  void addq(Register dst, const Address& address);
  void addq(const Address& address, const Immediate& imm);
  void addq(const Address& address, Register src);
  void adcq(Register dst, Register src);
  void adcq(Register dst, const Immediate& imm);
  void adcq(Register dst, const Address& address);

  void cdq();
  void cqo();

  void idivl(Register reg);
  void divl(Register reg);

  void idivq(Register reg);
  void divq(Register reg);

  void imull(Register dst, Register src);
  void imull(Register reg, const Immediate& imm);
  void mull(Register reg);

  void imulq(Register dst, Register src);
  void imulq(Register dst, const Address& address);
  void imulq(Register dst, const Immediate& imm);
  void MulImmediate(Register reg, const Immediate& imm);
  void mulq(Register reg);

  void subl(Register dst, Register src);
  void subl(Register dst, const Immediate& imm);
  void subl(Register dst, const Address& address);
  void sbbl(Register dst, Register src);
  void sbbl(Register dst, const Immediate& imm);
  void sbbl(Register dst, const Address& address);

  void subq(Register dst, Register src);
  void subq(Register reg, const Immediate& imm);
  void subq(Register reg, const Address& address);
  void subq(const Address& address, Register reg);
  void subq(const Address& address, const Immediate& imm);
  void sbbq(Register dst, Register src);
  void sbbq(Register dst, const Immediate& imm);
  void sbbq(Register dst, const Address& address);

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
  void shldq(Register dst, Register src, Register shifter);
  void shrdq(Register dst, Register src, Register shifter);

  void incl(const Address& address);
  void decl(const Address& address);

  void incq(Register reg);
  void incq(const Address& address);
  void decq(Register reg);
  void decq(const Address& address);

  void negl(Register reg);
  void negq(Register reg);
  void notl(Register reg);
  void notq(Register reg);

  void bsrq(Register dst, Register src);

  void btq(Register base, Register offset);

  void enter(const Immediate& imm);
  void leave();
  void ret();

  void movmskpd(Register dst, XmmRegister src);
  void movmskps(Register dst, XmmRegister src);

  void sqrtsd(XmmRegister dst, XmmRegister src);

  void xorpd(XmmRegister dst, const Address& src);
  void xorpd(XmmRegister dst, XmmRegister src);

  void xorps(XmmRegister dst, const Address& src);
  void xorps(XmmRegister dst, XmmRegister src);

  void andpd(XmmRegister dst, const Address& src);

  void fldl(const Address& src);
  void fstpl(const Address& dst);

  void fincstp();
  void ffree(intptr_t value);

  void fsin();
  void fcos();

  // 'size' indicates size in bytes and must be in the range 1..8.
  void nop(int size = 1);
  void int3();
  void hlt();

  static uword GetBreakInstructionFiller() { return 0xCCCCCCCCCCCCCCCC; }

  void j(Condition condition, Label* label, bool near = kFarJump);

  void jmp(Register reg);
  void jmp(const Address& address);
  void jmp(Label* label, bool near = kFarJump);
  void jmp(const ExternalLabel* label);
  void jmp(const StubEntry& stub_entry);

  void lock();
  void cmpxchgl(const Address& address, Register reg);
  void lock_cmpxchgl(const Address& address, Register reg) {
    lock();
    cmpxchgl(address, reg);
  }

  void cmpxchgq(const Address& address, Register reg);
  void lock_cmpxchgq(const Address& address, Register reg) {
    lock();
    cmpxchgq(address, reg);
  }

  void cpuid();

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

  /*
   * Macros for High-level operations and implemented on all architectures.
   */

  void CompareRegisters(Register a, Register b);

  // Issues a move instruction if 'to' is not the same as 'from'.
  void MoveRegister(Register to, Register from);
  void PopRegister(Register r);

  // Macros for adding/subtracting an immediate value that may be loaded from
  // the constant pool.
  // TODO(koda): Assert that these are not used for heap objects.
  void AddImmediate(Register reg, const Immediate& imm);
  void AddImmediate(const Address& address, const Immediate& imm);
  void SubImmediate(Register reg, const Immediate& imm);
  void SubImmediate(const Address& address, const Immediate& imm);

  void Drop(intptr_t stack_elements, Register tmp = TMP);

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

  void LoadImmediate(Register reg, const Immediate& imm);
  void LoadIsolate(Register dst);
  void LoadObject(Register dst, const Object& obj);
  void LoadUniqueObject(Register dst, const Object& obj);
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       Patchability patchable);
  void LoadFunctionFromCalleePool(Register dst,
                                  const Function& function,
                                  Register new_pp);
  void JmpPatchable(const StubEntry& stub_entry, Register pp);
  void Jmp(const StubEntry& stub_entry, Register pp = PP);
  void J(Condition condition, const StubEntry& stub_entry, Register pp);
  void CallPatchable(const StubEntry& stub_entry);
  void Call(const StubEntry& stub_entry);
  void CallToRuntime();
  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void CallWithEquivalence(const StubEntry& stub_entry,
                           const Object& equivalence);
  // Unaware of write barrier (use StoreInto* methods for storing to objects).
  // TODO(koda): Add StackAddress/HeapAddress types to prevent misuse.
  void StoreObject(const Address& dst, const Object& obj);
  void PushObject(const Object& object);
  void CompareObject(Register reg, const Object& object);

  // Destroys value.
  void StoreIntoObject(Register object,      // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,       // Value we are storing.
                       bool can_value_be_smi = true);

  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);

  // Stores a Smi value into a heap object field that always contains a Smi.
  void StoreIntoSmiField(const Address& dest, Register value);
  void ZeroInitSmiField(const Address& dest);
  // Increments a Smi field. Leaves flags in same state as an 'addq'.
  void IncrementSmiField(const Address& dest, int64_t increment);

  void DoubleNegate(XmmRegister d);
  void FloatNegate(XmmRegister f);

  void DoubleAbs(XmmRegister reg);

  void LockCmpxchgq(const Address& address, Register reg) {
    lock();
    cmpxchgq(address, reg);
  }

  void PushRegisters(intptr_t cpu_register_set, intptr_t xmm_register_set);
  void PopRegisters(intptr_t cpu_register_set, intptr_t xmm_register_set);

  void CheckCodePointer();

  void EnterFrame(intptr_t frame_space);
  void LeaveFrame();
  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's RSP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Call runtime function. Reserves shadow space on the stack before calling
  // if platform ABI requires that. Does not restore RSP after the call itself.
  void CallCFunction(Register reg);

  /*
   * Loading and comparing classes of objects.
   */
  void LoadClassId(Register result, Register object);

  void LoadClassById(Register result, Register class_id);

  void LoadClass(Register result, Register object);

  void CompareClassId(Register object, intptr_t class_id);

  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  // CheckClassIs fused with optimistic SmiUntag.
  // Value in the register object is untagged optimistically.
  void SmiUntagOrCheckClass(Register object, intptr_t class_id, Label* smi);

  /*
   * Misc. functionality.
   */
  void SmiTag(Register reg) { addq(reg, reg); }

  void SmiUntag(Register reg) { sarq(reg, Immediate(kSmiTagSize)); }

  void BranchIfNotSmi(Register reg, Label* label) {
    testq(reg, Immediate(kSmiTagMask));
    j(NOT_ZERO, label);
  }

  void BranchIfSmi(Register reg, Label* label) {
    testq(reg, Immediate(kSmiTagMask));
    j(ZERO, label);
  }

  void Align(int alignment, intptr_t offset);
  void Bind(Label* label);
  void Jump(Label* label) { jmp(label); }

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  static bool EmittingComments();

  const Code::Comments& GetCodeComments() const;

  // Address of code at offset.
  uword CodeAddress(intptr_t offset) { return buffer_.Address(offset); }

  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }
  bool has_single_entry_point() const { return has_single_entry_point_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const { return buffer_.CountPointerOffsets(); }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }

  ObjectPoolWrapper& object_pool_wrapper() { return object_pool_wrapper_; }

  RawObjectPool* MakeObjectPool() {
    return object_pool_wrapper_.MakeObjectPool();
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
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
  //   pc (used to derive the RawInstruction Object of the dart code)
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
  void EnterDartFrame(intptr_t frame_size, Register new_pp);
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

  void MonomorphicCheckedEntry();

  void UpdateAllocationStats(intptr_t cid, Heap::Space space);

  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     Register size_reg,
                                     Heap::Space space);
  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     intptr_t instance_size,
                                     Heap::Space space);

  // If allocation tracing for |cid| is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(intptr_t cid, Label* trace, bool near_jump);

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   bool near_jump,
                   Register instance_reg,
                   Register temp);

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        bool near_jump,
                        Register instance,
                        Register end_address,
                        Register temp);

  // Debugging and bringup support.
  void Stop(const char* message, bool fixed_length_encoding = false);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  static Address ElementAddressForIntIndex(bool is_external,
                                           intptr_t cid,
                                           intptr_t index_scale,
                                           Register array,
                                           intptr_t index);
  static Address ElementAddressForRegIndex(bool is_external,
                                           intptr_t cid,
                                           intptr_t index_scale,
                                           Register array,
                                           Register index);

  static Address VMTagAddress() {
    return Address(THR, Thread::vm_tag_offset());
  }

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

 private:
  AssemblerBuffer buffer_;

  ObjectPoolWrapper object_pool_wrapper_;

  intptr_t prologue_offset_;
  bool has_single_entry_point_;

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) {}

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;
  bool constant_pool_allowed_;

  intptr_t FindImmediate(int64_t imm);
  bool CanLoadFromObjectPool(const Object& object) const;
  void LoadObjectHelper(Register dst, const Object& obj, bool is_unique);
  void LoadWordFromPoolOffset(Register dst, int32_t offset);

  inline void EmitUint8(uint8_t value);
  inline void EmitInt32(int32_t value);
  inline void EmitInt64(int64_t value);

  inline void EmitRegisterREX(Register reg, uint8_t rex);
  inline void EmitOperandREX(int rm, const Operand& operand, uint8_t rex);
  inline void EmitXmmRegisterOperand(int rm, XmmRegister reg);
  inline void EmitFixup(AssemblerFixup* fixup);
  inline void EmitOperandSizeOverride();
  inline void EmitREX_RB(XmmRegister reg,
                         XmmRegister base,
                         uint8_t rex = REX_NONE);
  inline void EmitREX_RB(XmmRegister reg,
                         const Operand& operand,
                         uint8_t rex = REX_NONE);
  inline void EmitREX_RB(XmmRegister reg,
                         Register base,
                         uint8_t rex = REX_NONE);
  inline void EmitREX_RB(Register reg,
                         XmmRegister base,
                         uint8_t rex = REX_NONE);
  void EmitOperand(int rm, const Operand& operand);
  void EmitImmediate(const Immediate& imm);
  void EmitComplex(int rm, const Operand& operand, const Immediate& immediate);
  void EmitLabel(Label* label, intptr_t instruction_size);
  void EmitLabelLink(Label* label);
  void EmitNearLabelLink(Label* label);

  void EmitGenericShift(bool wide, int rm, Register reg, const Immediate& imm);
  void EmitGenericShift(bool wide, int rm, Register operand, Register shifter);

  void StoreIntoObjectFilter(Register object, Register value, Label* no_update);

  // Shorter filtering sequence that assumes that value is not a smi.
  void StoreIntoObjectFilterNoSmi(Register object,
                                  Register value,
                                  Label* no_update);
  // Unaware of write barrier (use StoreInto* methods for storing to objects).
  void MoveImmediate(const Address& dst, const Immediate& imm);

  void ComputeCounterAddressesForCid(intptr_t cid,
                                     Heap::Space space,
                                     Address* count_address,
                                     Address* size_address);
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};


inline void Assembler::EmitUint8(uint8_t value) {
  buffer_.Emit<uint8_t>(value);
}


inline void Assembler::EmitInt32(int32_t value) {
  buffer_.Emit<int32_t>(value);
}


inline void Assembler::EmitInt64(int64_t value) {
  buffer_.Emit<int64_t>(value);
}


inline void Assembler::EmitRegisterREX(Register reg, uint8_t rex) {
  ASSERT(reg != kNoRegister);
  rex |= (reg > 7 ? REX_B : REX_NONE);
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}


inline void Assembler::EmitOperandREX(int rm,
                                      const Operand& operand,
                                      uint8_t rex) {
  rex |= (rm > 7 ? REX_R : REX_NONE) | operand.rex();
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}


inline void Assembler::EmitREX_RB(XmmRegister reg,
                                  XmmRegister base,
                                  uint8_t rex) {
  if (reg > 7) rex |= REX_R;
  if (base > 7) rex |= REX_B;
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}


inline void Assembler::EmitREX_RB(XmmRegister reg,
                                  const Operand& operand,
                                  uint8_t rex) {
  if (reg > 7) rex |= REX_R;
  rex |= operand.rex();
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}


inline void Assembler::EmitREX_RB(XmmRegister reg, Register base, uint8_t rex) {
  if (reg > 7) rex |= REX_R;
  if (base > 7) rex |= REX_B;
  if (rex != REX_NONE) EmitUint8(REX_PREFIX | rex);
}


inline void Assembler::EmitREX_RB(Register reg, XmmRegister base, uint8_t rex) {
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

}  // namespace dart

#endif  // RUNTIME_VM_ASSEMBLER_X64_H_
