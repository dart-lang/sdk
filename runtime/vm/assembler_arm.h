// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_ARM_H_
#define VM_ASSEMBLER_ARM_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_arm.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "vm/constants_arm.h"

namespace dart {

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


class Assembler {
 public:
  Assembler() { }
  ~Assembler() { }

  // Macros for High-level operations.
  void AddConstant(Register reg, int value, Condition cond = AL) {
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
  void FinalizeInstructions(const MemoryRegion& region) {
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

 private:
  ZoneGrowableArray<int>* pointer_offsets_;
  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM_H_
