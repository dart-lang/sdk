// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_IA32_H_
#define VM_ASSEMBLER_IA32_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_ia32.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_ia32.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;


#if defined(TESTING) || defined(DEBUG)

#if defined(TARGET_OS_WINDOWS)
// The compiler may dynamically align the stack on Windows, so do not check.
#define CHECK_STACK_ALIGNMENT { }
#else
#define CHECK_STACK_ALIGNMENT {                                                \
  uword current_sp;                                                            \
  asm volatile("mov %%esp, %[current_sp]" : [current_sp] "=r" (current_sp));   \
  ASSERT((OS::ActivationFrameAlignment() == 0) ||                              \
         (Utils::IsAligned(current_sp, OS::ActivationFrameAlignment())));      \
}
#endif

#else

#define CHECK_STACK_ALIGNMENT { }

#endif


class Immediate : public ValueObject {
 public:
  explicit Immediate(int32_t value) : value_(value) { }

  int32_t value() const { return value_; }

  bool is_int8() const { return Utils::IsInt(8, value_); }
  bool is_uint8() const { return Utils::IsUint(8, value_); }
  bool is_uint16() const { return Utils::IsUint(16, value_); }

 private:
  const int32_t value_;

  // TODO(5411081): Add DISALLOW_COPY_AND_ASSIGN(Immediate) once the mac
  // build issue is resolved.
};


class Operand : public ValueObject {
 public:
  uint8_t mod() const {
    return (encoding_at(0) >> 6) & 3;
  }

  Register rm() const {
    return static_cast<Register>(encoding_at(0) & 7);
  }

  ScaleFactor scale() const {
    return static_cast<ScaleFactor>((encoding_at(1) >> 6) & 3);
  }

  Register index() const {
    return static_cast<Register>((encoding_at(1) >> 3) & 7);
  }

  Register base() const {
    return static_cast<Register>(encoding_at(1) & 7);
  }

  int8_t disp8() const {
    ASSERT(length_ >= 2);
    return static_cast<int8_t>(encoding_[length_ - 1]);
  }

  int32_t disp32() const {
    ASSERT(length_ >= 5);
    return bit_copy<int32_t>(encoding_[length_ - 4]);
  }

  bool IsRegister(Register reg) const {
    return ((encoding_[0] & 0xF8) == 0xC0)  // Addressing mode is register only.
        && ((encoding_[0] & 0x07) == reg);  // Register codes match.
  }

 protected:
  // Operand can be sub classed (e.g: Address).
  Operand() : length_(0) { }

  void SetModRM(int mod, Register rm) {
    ASSERT((mod & ~3) == 0);
    encoding_[0] = (mod << 6) | rm;
    length_ = 1;
  }

  void SetSIB(ScaleFactor scale, Register index, Register base) {
    ASSERT(length_ == 1);
    ASSERT((scale & ~3) == 0);
    encoding_[1] = (scale << 6) | (index << 3) | base;
    length_ = 2;
  }

  void SetDisp8(int8_t disp) {
    ASSERT(length_ == 1 || length_ == 2);
    encoding_[length_++] = static_cast<uint8_t>(disp);
  }

  void SetDisp32(int32_t disp) {
    ASSERT(length_ == 1 || length_ == 2);
    int disp_size = sizeof(disp);
    memmove(&encoding_[length_], &disp, disp_size);
    length_ += disp_size;
  }

 private:
  uint8_t length_;
  uint8_t encoding_[6];
  uint8_t padding_;

  explicit Operand(Register reg) { SetModRM(3, reg); }

  // Get the operand encoding byte at the given index.
  uint8_t encoding_at(int index) const {
    ASSERT(index >= 0 && index < length_);
    return encoding_[index];
  }

  friend class Assembler;

  // TODO(5411081): Add DISALLOW_COPY_AND_ASSIGN(Operand) once the mac
  // build issue is resolved.
};


class Address : public Operand {
 public:
  Address(Register base, int32_t disp) {
    if (disp == 0 && base != EBP) {
      SetModRM(0, base);
      if (base == ESP) SetSIB(TIMES_1, ESP, base);
    } else if (Utils::IsInt(8, disp)) {
      SetModRM(1, base);
      if (base == ESP) SetSIB(TIMES_1, ESP, base);
      SetDisp8(disp);
    } else {
      SetModRM(2, base);
      if (base == ESP) SetSIB(TIMES_1, ESP, base);
      SetDisp32(disp);
    }
  }

  Address(Register index, ScaleFactor scale, int32_t disp) {
    ASSERT(index != ESP);  // Illegal addressing mode.
    SetModRM(0, ESP);
    SetSIB(scale, index, EBP);
    SetDisp32(disp);
  }

  Address(Register base, Register index, ScaleFactor scale, int32_t disp) {
    ASSERT(index != ESP);  // Illegal addressing mode.
    if (disp == 0 && base != EBP) {
      SetModRM(0, ESP);
      SetSIB(scale, index, base);
    } else if (Utils::IsInt(8, disp)) {
      SetModRM(1, ESP);
      SetSIB(scale, index, base);
      SetDisp8(disp);
    } else {
      SetModRM(2, ESP);
      SetSIB(scale, index, base);
      SetDisp32(disp);
    }
  }

  static Address Absolute(const uword addr) {
    Address result;
    result.SetModRM(0, EBP);
    result.SetDisp32(addr);
    return result;
  }

 private:
  Address() {}

  // TODO(5411081): Add DISALLOW_COPY_AND_ASSIGN(Address) once the mac
  // build issue is resolved.
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) {}
  FieldAddress(Register base, Register index, ScaleFactor scale, int32_t disp)
      : Address(base, index, scale, disp - kHeapObjectTag) {}
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
  int Position() const {
    ASSERT(IsBound());
    return -position_ - kWordSize;
  }

  int LinkPosition() const {
    ASSERT(IsLinked());
    return position_ - kWordSize;
  }

  int NearPosition() {
    ASSERT(HasNear());
    return unresolved_near_positions_[--unresolved_];
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return (position_ == 0) && (unresolved_ == 0); }
  bool IsLinked() const { return position_ > 0; }
  bool HasNear() const { return unresolved_ != 0; }

 private:
  void BindTo(int position) {
    ASSERT(!IsBound());
    ASSERT(!HasNear());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(int position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  void NearLinkTo(int position) {
    ASSERT(!IsBound());
    ASSERT(unresolved_ < kMaxUnresolvedBranches);
    unresolved_near_positions_[unresolved_++] = position;
  }

  static const int kMaxUnresolvedBranches = 20;

  int position_;
  int unresolved_;
  int unresolved_near_positions_[kMaxUnresolvedBranches];

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class Assembler : public ValueObject {
 public:
  Assembler() : buffer_(), prolog_offset_(-1), comments_() { }
  ~Assembler() { }

  static const bool kNearJump = true;
  static const bool kFarJump = false;

  /*
   * Emit Machine Instructions.
   */
  void call(Register reg);
  void call(const Address& address);
  void call(Label* label);
  void call(const ExternalLabel* label);

  static const intptr_t kCallExternalLabelSize = 5;

  void pushl(Register reg);
  void pushl(const Address& address);
  void pushl(const Immediate& imm);

  void popl(Register reg);
  void popl(const Address& address);

  void movl(Register dst, const Immediate& src);
  void movl(Register dst, Register src);

  void movl(Register dst, const Address& src);
  void movl(const Address& dst, Register src);
  void movl(const Address& dst, const Immediate& imm);

  void movzxb(Register dst, ByteRegister src);
  void movzxb(Register dst, const Address& src);
  void movsxb(Register dst, ByteRegister src);
  void movsxb(Register dst, const Address& src);
  void movb(Register dst, const Address& src);
  void movb(const Address& dst, ByteRegister src);
  void movb(const Address& dst, const Immediate& imm);

  void movzxw(Register dst, Register src);
  void movzxw(Register dst, const Address& src);
  void movsxw(Register dst, Register src);
  void movsxw(Register dst, const Address& src);
  void movw(Register dst, const Address& src);
  void movw(const Address& dst, Register src);

  void leal(Register dst, const Address& src);

  void cmovs(Register dst, Register src);
  void cmovns(Register dst, Register src);

  void movss(XmmRegister dst, const Address& src);
  void movss(const Address& dst, XmmRegister src);
  void movss(XmmRegister dst, XmmRegister src);

  void movd(XmmRegister dst, Register src);
  void movd(Register dst, XmmRegister src);

  void addss(XmmRegister dst, XmmRegister src);
  void addss(XmmRegister dst, const Address& src);
  void subss(XmmRegister dst, XmmRegister src);
  void subss(XmmRegister dst, const Address& src);
  void mulss(XmmRegister dst, XmmRegister src);
  void mulss(XmmRegister dst, const Address& src);
  void divss(XmmRegister dst, XmmRegister src);
  void divss(XmmRegister dst, const Address& src);

  void movsd(XmmRegister dst, const Address& src);
  void movsd(const Address& dst, XmmRegister src);
  void movsd(XmmRegister dst, XmmRegister src);

  void addsd(XmmRegister dst, XmmRegister src);
  void addsd(XmmRegister dst, const Address& src);
  void subsd(XmmRegister dst, XmmRegister src);
  void subsd(XmmRegister dst, const Address& src);
  void mulsd(XmmRegister dst, XmmRegister src);
  void mulsd(XmmRegister dst, const Address& src);
  void divsd(XmmRegister dst, XmmRegister src);
  void divsd(XmmRegister dst, const Address& src);

  void cvtsi2ss(XmmRegister dst, Register src);
  void cvtsi2sd(XmmRegister dst, Register src);

  void cvtss2si(Register dst, XmmRegister src);
  void cvtss2sd(XmmRegister dst, XmmRegister src);

  void cvtsd2si(Register dst, XmmRegister src);
  void cvtsd2ss(XmmRegister dst, XmmRegister src);

  void cvttss2si(Register dst, XmmRegister src);
  void cvttsd2si(Register dst, XmmRegister src);

  void cvtdq2pd(XmmRegister dst, XmmRegister src);

  void comiss(XmmRegister a, XmmRegister b);
  void comisd(XmmRegister a, XmmRegister b);

  void movmskpd(Register dst, XmmRegister src);

  void sqrtsd(XmmRegister dst, XmmRegister src);
  void sqrtss(XmmRegister dst, XmmRegister src);

  void xorpd(XmmRegister dst, const Address& src);
  void xorpd(XmmRegister dst, XmmRegister src);
  void xorps(XmmRegister dst, const Address& src);
  void xorps(XmmRegister dst, XmmRegister src);

  void andpd(XmmRegister dst, const Address& src);

  void flds(const Address& src);
  void fstps(const Address& dst);

  void fldl(const Address& src);
  void fstpl(const Address& dst);

  void fnstcw(const Address& dst);
  void fldcw(const Address& src);

  void fistpl(const Address& dst);
  void fistps(const Address& dst);
  void fildl(const Address& src);
  void filds(const Address& src);

  void fincstp();
  void ffree(intptr_t value);

  void fsin();
  void fcos();
  void fptan();

  void xchgl(Register dst, Register src);

  void cmpl(Register reg, const Immediate& imm);
  void cmpl(Register reg0, Register reg1);
  void cmpl(Register reg, const Address& address);

  void cmpl(const Address& address, Register reg);
  void cmpl(const Address& address, const Immediate& imm);

  void testl(Register reg1, Register reg2);
  void testl(Register reg, const Immediate& imm);

  void andl(Register dst, const Immediate& imm);
  void andl(Register dst, Register src);

  void orl(Register dst, const Immediate& imm);
  void orl(Register dst, Register src);

  void xorl(Register dst, Register src);

  void addl(Register dst, Register src);
  void addl(Register reg, const Immediate& imm);
  void addl(Register reg, const Address& address);

  void addl(const Address& address, Register reg);
  void addl(const Address& address, const Immediate& imm);

  void adcl(Register dst, Register src);
  void adcl(Register reg, const Immediate& imm);
  void adcl(Register dst, const Address& address);

  void subl(Register dst, Register src);
  void subl(Register reg, const Immediate& imm);
  void subl(Register reg, const Address& address);

  void cdq();

  void idivl(Register reg);

  void imull(Register dst, Register src);
  void imull(Register reg, const Immediate& imm);
  void imull(Register reg, const Address& address);

  void imull(Register reg);
  void imull(const Address& address);

  void mull(Register reg);
  void mull(const Address& address);

  void sbbl(Register dst, Register src);
  void sbbl(Register reg, const Immediate& imm);
  void sbbl(Register reg, const Address& address);

  void incl(Register reg);
  void incl(const Address& address);

  void decl(Register reg);
  void decl(const Address& address);

  void shll(Register reg, const Immediate& imm);
  void shll(Register operand, Register shifter);
  void shrl(Register reg, const Immediate& imm);
  void shrl(Register operand, Register shifter);
  void sarl(Register reg, const Immediate& imm);
  void sarl(Register operand, Register shifter);
  void shld(Register dst, Register src);

  void negl(Register reg);
  void notl(Register reg);

  void enter(const Immediate& imm);
  void leave();

  void ret();
  void ret(const Immediate& imm);

  // 'size' indicates size in bytes and must be in the range 1..8.
  void nop(int size = 1);
  void int3();
  void hlt();

  void j(Condition condition, Label* label, bool near = kFarJump);
  void j(Condition condition, const ExternalLabel* label);

  void jmp(Register reg);
  void jmp(Label* label, bool near = kFarJump);
  void jmp(const ExternalLabel* label);

  void lock();
  void cmpxchgl(const Address& address, Register reg);

  /*
   * Macros for High-level operations and implemented on all architectures.
   */

  void CompareRegisters(Register a, Register b);

  // Issues a move instruction if 'to' is not the same as 'from'.
  void MoveRegister(Register to, Register from);

  void AddImmediate(Register reg, const Immediate& imm);

  void Drop(intptr_t stack_elements);

  void LoadObject(Register dst, const Object& object);
  void PushObject(const Object& object);
  void CompareObject(Register reg, const Object& object);
  void LoadDoubleConstant(XmmRegister dst, double value);

  void StoreIntoObject(Register object,  // Object we are storing into.
                       const FieldAddress& dest,  // Where we are storing into.
                       Register value);  // Value we are storing.

  void DoubleNegate(XmmRegister d);
  void FloatNegate(XmmRegister f);

  void DoubleAbs(XmmRegister reg);

  void LockCmpxchgl(const Address& address, Register reg) {
    lock();
    cmpxchgl(address, reg);
  }

  void EnterFrame(intptr_t frame_space);
  void LeaveFrame();

  void CallRuntime(const RuntimeEntry& entry);

  /*
   * Loading and comparing classes of objects.
   */
  void LoadClassId(Register result, Register object);

  void LoadClassById(Register result, Register class_id);

  void LoadClass(Register result, Register object, Register scratch);

  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch);

  /*
   * Misc. functionality
   */
  void SmiTag(Register reg) {
    addl(reg, reg);
  }

  void SmiUntag(Register reg) {
    sarl(reg, Immediate(kSmiTagSize));
  }

  int PreferredLoopAlignment() { return 16; }
  void Align(int alignment, int offset);
  void Bind(Label* label);

  int CodeSize() const { return buffer_.Size(); }
  int prolog_offset() const { return prolog_offset_; }
  const ZoneGrowableArray<int>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, int length);

  void Comment(const char* format, ...);
  const Code::Comments& GetCodeComments() const;

 private:
  AssemblerBuffer buffer_;
  int prolog_offset_;

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) { }

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;

  inline void EmitUint8(uint8_t value);
  inline void EmitInt32(int32_t value);
  inline void EmitRegisterOperand(int rm, int reg);
  inline void EmitXmmRegisterOperand(int rm, XmmRegister reg);
  inline void EmitFixup(AssemblerFixup* fixup);
  inline void EmitOperandSizeOverride();

  void EmitOperand(int rm, const Operand& operand);
  void EmitImmediate(const Immediate& imm);
  void EmitComplex(int rm, const Operand& operand, const Immediate& immediate);
  void EmitLabel(Label* label, int instruction_size);
  void EmitLabelLink(Label* label);
  void EmitNearLabelLink(Label* label);

  void EmitGenericShift(int rm, Register reg, const Immediate& imm);
  void EmitGenericShift(int rm, Register operand, Register shifter);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};


inline void Assembler::EmitUint8(uint8_t value) {
  buffer_.Emit<uint8_t>(value);
}


inline void Assembler::EmitInt32(int32_t value) {
  buffer_.Emit<int32_t>(value);
}


inline void Assembler::EmitRegisterOperand(int rm, int reg) {
  ASSERT(rm >= 0 && rm < 8);
  buffer_.Emit<uint8_t>(0xC0 + (rm << 3) + reg);
}


inline void Assembler::EmitXmmRegisterOperand(int rm, XmmRegister reg) {
  EmitRegisterOperand(rm, static_cast<Register>(reg));
}


inline void Assembler::EmitFixup(AssemblerFixup* fixup) {
  buffer_.EmitFixup(fixup);
}


inline void Assembler::EmitOperandSizeOverride() {
  EmitUint8(0x66);
}

}  // namespace dart

#endif  // VM_ASSEMBLER_IA32_H_
