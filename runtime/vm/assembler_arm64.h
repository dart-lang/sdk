// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_ARM64_H_
#define VM_ASSEMBLER_ARM64_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_arm64.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_arm64.h"
#include "vm/object.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;

// TODO(zra): Label, Address, and FieldAddress are copied from ARM,
// they must be adapted to ARM64.
class Label : public ValueObject {
 public:
  Label() : position_(0) { }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  intptr_t Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  intptr_t position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class Address : public ValueObject {
 public:
  Address(const Address& other)
      : ValueObject(), encoding_(other.encoding_) {
  }

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    return *this;
  }

  Address(Register rn, int32_t offset = 0) {
    ASSERT(Utils::IsAbsoluteUint(12, offset));
    encoding_ = -1;
  }

 private:
  uint32_t encoding() const { return encoding_; }

  uint32_t encoding_;

  friend class Assembler;
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) { }

  FieldAddress(const FieldAddress& other) : Address(other) { }

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


class Operand : public ValueObject {
 public:
  // Data-processing operand - Uninitialized.
  Operand() : encoding_(-1), type_(Unknown) { }

  // Data-processing operands - Copy constructor.
  Operand(const Operand& other)
      : ValueObject(), encoding_(other.encoding_), type_(other.type_) { }

  explicit Operand(Register rm) {
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ = (static_cast<int32_t>(crm) << kRmShift);
    type_ = Shifted;
  }

  Operand(Register rm, Shift shift, int32_t imm) {
    ASSERT(Utils::IsUint(6, imm));
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        (imm << kImm6Shift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(shift) << kShiftTypeShift);
    type_ = Shifted;
  }

  Operand(Register rm, Extend extend, int32_t imm) {
    ASSERT(Utils::IsUint(3, imm));
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        B21 |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(extend) << kExtendTypeShift) |
        ((imm & 0x7) << kImm3Shift);
    type_ = Extended;
  }

  explicit Operand(int32_t imm) {
    if (Utils::IsUint(12, imm)) {
      encoding_ = imm << kImm12Shift;
    } else {
      // imm only has bits in [12, 24) set.
      ASSERT(((imm & 0xfff) == 0) && (Utils::IsUint(12, imm >> 12)));
      encoding_ = B22 | ((imm >> 12) << kImm12Shift);
    }
    type_ = Immediate;
  }

  // TODO(zra): Add bitfield immediate operand
  // Operand(int32_t n, int32_t imms, int32_t immr);

  enum OperandType {
    Shifted,
    Extended,
    Immediate,
    BitfieldImm,
    Unknown,
  };

 private:
  uint32_t encoding() const {
    return encoding_;
  }
  OperandType type() const {
    return type_;
  }

  uint32_t encoding_;
  OperandType type_;

  friend class Assembler;
};


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false)
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        use_far_branches_(use_far_branches),
        comments_() { }
  ~Assembler() { }

  void PopRegister(Register r) {
    UNIMPLEMENTED();
  }

  void Drop(intptr_t stack_elements) {
    UNIMPLEMENTED();
  }

  void Bind(Label* label) {
    UNIMPLEMENTED();
  }

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.  On ARM64 there are no pointers in code.
  intptr_t CountPointerOffsets() const { return 0; }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    ASSERT(buffer_.pointer_offsets().length() == 0);  // No pointers in code.
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) {
    ASSERT(buffer_.Size() == 0);
    use_far_branches_ = b;
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  // TODO(zra): Make sure this is right.
  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kEntryPointToPcMarkerOffset = 0;

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

  // Addition and subtraction.
  void add(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, false, rd, rn, o);
  }
  void addw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, false, false, rd, rn, o);
  }
  void sub(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, true, rd, rn, o);
  }

  // Move wide immediate.
  void movk(Register rd, int32_t imm, int32_t hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVK, crd, imm, hw_idx, kDoubleWord);
  }
  void movn(Register rd, int32_t imm, int32_t hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVN, crd, imm, hw_idx, kDoubleWord);
  }
  void movz(Register rd, int32_t imm, int32_t hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVZ, crd, imm, hw_idx, kDoubleWord);
  }


  // Function return.
  void ret(Register rn = R30) {
    EmitUnconditionalBranchRegOp(RET, rn);
  }

 private:
  AssemblerBuffer buffer_;  // Contains position independent code.
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  int32_t prologue_offset_;

  bool use_far_branches_;

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

  void AddSubHelper(OperandSize os, bool set_flags, bool subtract,
                    Register rd, Register rn, Operand o) {
    ASSERT((rd != R31) && (rn != R31));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    if (o.type() == Operand::Immediate) {
      ASSERT((rd != ZR) && (rn != ZR));
      EmitAddSubImmOp(subtract ? SUBI : ADDI, crd, crn, o, os, set_flags);
    } else if (o.type() == Operand::Shifted) {
      ASSERT((rd != SP) && (rn != SP));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    } else {
      ASSERT(o.type() == Operand::Extended);
      ASSERT((rd != SP) && (rn != ZR));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    }
  }

  void EmitAddSubImmOp(AddSubImmOp op, Register rd, Register rn,
                       Operand o, OperandSize os, bool set_flags) {
    ASSERT((os == kDoubleWord) || (os == kWord));
    const int32_t size = (os == kDoubleWord) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding =
        op | size | s |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(rn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  void EmitAddSubShiftExtOp(AddSubShiftExtOp op,
                            Register rd, Register rn, Operand o,
                            OperandSize sz, bool set_flags) {
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding =
        op | size | s |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(rn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  void EmitUnconditionalBranchRegOp(UnconditionalBranchRegOp op, Register rn) {
    const int32_t encoding =
        op | (static_cast<int32_t>(rn) << kRnShift);
    Emit(encoding);
  }

  void EmitMoveWideOp(MoveWideOp op, Register rd, int32_t imm, int32_t hw_idx,
                      OperandSize sz) {
    ASSERT(Utils::IsUint(16, imm));
    ASSERT((hw_idx >= 0) && (hw_idx <= 3));
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(rd) << kRdShift) |
        (hw_idx << kHWShift) |
        (imm << kImm16Shift);
    Emit(encoding);
  }

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM64_H_
