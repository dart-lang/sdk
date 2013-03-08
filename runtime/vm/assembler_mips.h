// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_MIPS_H_
#define VM_ASSEMBLER_MIPS_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_mips.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "vm/constants_mips.h"

// References to documentation in this file refer to:
// "MIPS® Architecture For Programmers Volume I-A:
//   Introduction to the MIPS32® Architecture" in short "VolI-A"
// and
// "MIPS® Architecture For Programmers Volume II-A:
//   The MIPS32® Instruction Set" in short "VolII-A"
namespace dart {

class Immediate : public ValueObject {
 public:
  explicit Immediate(int32_t value) : value_(value) { }

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) { }
  Immediate& operator=(const Immediate& other) {
    value_ = other.value_;
    return *this;
  }

 private:
  int32_t value_;

  int32_t value() const { return value_; }

  friend class Assembler;
};


class Address : public ValueObject {
 public:
  Address(Register base, int32_t offset) {
    UNIMPLEMENTED();
  }

  Address(const Address& other)
      : ValueObject(), base_(other.base_), offset_(other.offset_) { }
  Address& operator=(const Address& other) {
    base_ = other.base_;
    offset_ = other.offset_;
    return *this;
  }

 private:
  Register base_;
  int32_t offset_;
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


class Label : public ValueObject {
 public:
  Label() : position_(0) { }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  int Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  int position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(int position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(int position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class CPUFeatures : public AllStatic {
 public:
  static void InitOnce() { }
  static bool double_truncate_round_supported() {
    UNIMPLEMENTED();
    return false;
  }
};


class Assembler : public ValueObject {
 public:
  Assembler()
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        delay_slot_available_(false),
        in_delay_slot_(false),
        comments_() { }
  ~Assembler() { }

  void PopRegister(Register r) {
    UNIMPLEMENTED();
  }

  void Bind(Label* label) {
    UNIMPLEMENTED();
  }

  // Misc. functionality
  int CodeSize() const { return buffer_.Size(); }
  int prologue_offset() const { return -1; }
  const ZoneGrowableArray<int>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }
  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size) {
    UNIMPLEMENTED();
  }

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame() {
    UNIMPLEMENTED();
  }

  // Instruction pattern from entrypoint is used in dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kOffsetOfSavedPCfromEntrypoint = -1;  // UNIMPLEMENTED.

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   bool near_jump,
                   Register instance_reg) {
    UNIMPLEMENTED();
  }

  // Debugging and bringup support.
  void Stop(const char* message) { UNIMPLEMENTED(); }
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, int length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg) {
    UNIMPLEMENTED();
    return NULL;
  }

  static const char* FpuRegisterName(FpuRegister reg) {
    UNIMPLEMENTED();
    return NULL;
  }

  // A utility to be able to assemble an instruction into the delay slot.
  Assembler* delay_slot() {
    ASSERT(delay_slot_available_);
    ASSERT(buffer_.Load<int32_t>(buffer_.GetPosition() - sizeof(int32_t)) ==
        Instr::kNopInstruction);
    buffer_.Remit<int32_t>();
    delay_slot_available_ = false;
    in_delay_slot_ = true;
    return this;
  }

  // CPU instructions.
  void ori(Register rt, Register rs, const Immediate& imm) {
    ASSERT(Utils::IsUint(16, imm.value()));
    uint16_t imm_value = static_cast<uint16_t>(imm.value());
    EmitIType(ORI, rs, rt, imm_value);
  }

  void jr(Register rs) {
    ASSERT(!in_delay_slot_);  // Jump within a delay slot is not supported.
    EmitRType(SPECIAL, rs, R0, R0, 0, JR);
    Emit(Instr::kNopInstruction);  // Branch delay NOP.
    delay_slot_available_ = true;
  }

 private:
  AssemblerBuffer buffer_;
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  int prologue_offset_;

  bool delay_slot_available_;
  bool in_delay_slot_;

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

  void Emit(int32_t value) {
    // Emitting an instruction clears the delay slot state.
    in_delay_slot_ = false;
    delay_slot_available_ = false;
    AssemblerBuffer::EnsureCapacity ensured(&buffer_);
    buffer_.Emit<int32_t>(value);
  }

  // Encode CPU instructions according to the types specified in
  // Figures 4-1, 4-2 and 4-3 in VolI-A.
  void EmitIType(Opcode opcode,
                 Register rs,
                 Register rt,
                 uint16_t imm) {
    Emit(opcode << kOpcodeShift |
         rs << kRsShift |
         rt << kRtShift |
         imm);
  }

  void EmitJType(Opcode opcode, Label* label) {
    UNIMPLEMENTED();
  }

  void EmitRType(Opcode opcode,
                 Register rs,
                 Register rt,
                 Register rd,
                 int sa,
                 SpecialFunction func) {
    ASSERT(Utils::IsUint(5, sa));
    Emit(opcode << kOpcodeShift |
         rs << kRsShift |
         rt << kRtShift |
         rd << kRdShift |
         sa << kSaShift |
         func << kFunctionShift);
  }

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_MIPS_H_
