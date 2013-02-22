// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_ARM_H_
#define VM_INSTRUCTIONS_ARM_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_arm.h directly; use instructions.h instead.
#endif

#include "vm/object.h"

namespace dart {

// Abstract class for all instruction pattern classes.
class InstructionPattern : public ValueObject {
 public:
  explicit InstructionPattern(uword pc) : end_(reinterpret_cast<uword*>(pc)) {
    ASSERT(pc != 0);
  }
  virtual ~InstructionPattern() { }

 protected:
  uword Back(int n) const;

 private:
  const uword* end_;

  DISALLOW_COPY_AND_ASSIGN(InstructionPattern);
};


class CallPattern : public InstructionPattern {
 public:
  CallPattern(uword pc, const Code& code);

  uword TargetAddress() const;
  void SetTargetAddress(uword target_address) const;

 private:
  int DecodePoolIndex();
  const int pool_index_;
  const Array& object_pool_;

  DISALLOW_COPY_AND_ASSIGN(CallPattern);
};


class JumpPattern : public InstructionPattern {
 public:
  explicit JumpPattern(uword pc) : InstructionPattern(pc) { }

  static const int kLengthInBytes = 3*kWordSize;

  int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }
  bool IsValid() const;
  uword TargetAddress() const;
  void SetTargetAddress(uword target_address) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(JumpPattern);
};

}  // namespace dart

#endif  // VM_INSTRUCTIONS_ARM_H_

