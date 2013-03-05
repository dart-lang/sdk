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

namespace dart {

class Operand : public ValueObject {
 public:
  Operand(const Operand& other) : ValueObject() {
    UNIMPLEMENTED();
  }

  Operand& operator=(const Operand& other) {
    UNIMPLEMENTED();
    return *this;
  }

 protected:
  Operand() { }  // Needed by subclass Address.
};


class Address : public Operand {
 public:
  Address(Register base, int32_t disp) {
    UNIMPLEMENTED();
  }

  Address(const Address& other) : Operand(other) { }

  Address& operator=(const Address& other) {
    Operand::operator=(other);
    return *this;
  }
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
        comments_() { }
  ~Assembler() { }

  void PopRegister(Register r) {
    UNIMPLEMENTED();
  }

  void Bind(Label* label) {
    UNIMPLEMENTED();
  }

  // Misc. functionality
  int CodeSize() const {
    UNIMPLEMENTED();
    return 0;
  }
  int prologue_offset() const {
    UNIMPLEMENTED();
    return 0;
  }
  const ZoneGrowableArray<int>& GetPointerOffsets() const {
    UNIMPLEMENTED();
    return *pointer_offsets_;
  }
  const GrowableObjectArray& object_pool() const {
    UNIMPLEMENTED();
    return object_pool_;
  }
  void FinalizeInstructions(const MemoryRegion& region) {
    UNIMPLEMENTED();
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

  static void InitializeMemoryWithBreakpoints(uword data, int length) {
    UNIMPLEMENTED();
  }

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

 private:
  AssemblerBuffer buffer_;
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  ZoneGrowableArray<int>* pointer_offsets_;
  int prologue_offset_;

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

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_MIPS_H_
