// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_MIPS_H_
#define VM_INSTRUCTIONS_MIPS_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_mips.h directly; use instructions.h instead.
#endif

#include "vm/allocation.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class RawClass;
class Immediate;
class RawObject;

// Abstract class for all instruction pattern classes.
class InstructionPattern : public ValueObject {
 public:
  explicit InstructionPattern(uword pc) : end_(pc) {
    ASSERT(pc != 0);
  }
  virtual ~InstructionPattern() { }

  // Check if the instruction ending at 'end_' matches the expected pattern.
  virtual bool IsValid() const {
    return TestBytesWith(pattern(), pattern_length_in_bytes());
  }

  // 'pattern' returns the expected byte pattern in form of an integer array
  // with length of 'pattern_length_in_bytes'. A '-1' element means 'any byte'.
  virtual const int* pattern() const = 0;
  virtual int pattern_length_in_bytes() const = 0;

 protected:
  uword end() const { return end_; }

 private:
  // Returns true if the 'num_bytes' bytes at 'num_bytes' before 'end_'
  // correspond to array of integers 'data'. 'data' elements are either a byte
  // or -1, which represents any byte.
  bool TestBytesWith(const int* data, int num_bytes) const;

  const uword end_;

  DISALLOW_COPY_AND_ASSIGN(InstructionPattern);
};


class CallPattern : public InstructionPattern {
 public:
  CallPattern(uword pc, const Code& code)
      : InstructionPattern(pc), code_(code) { }

  static const int kLengthInBytes = 1*kWordSize;

  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }
  uword TargetAddress() const;
  void SetTargetAddress(uword new_target) const;

 private:
  virtual const int* pattern() const;

  const Code& code_;

  DISALLOW_COPY_AND_ASSIGN(CallPattern);
};


class JumpPattern : public InstructionPattern {
 public:
  explicit JumpPattern(uword pc) : InstructionPattern(pc) { }

  static const int kLengthInBytes = 3*kWordSize;

  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }
  uword TargetAddress() const;
  void SetTargetAddress(uword new_target) const;

 private:
  virtual const int* pattern() const;

  DISALLOW_COPY_AND_ASSIGN(JumpPattern);
};

}  // namespace dart

#endif  // VM_INSTRUCTIONS_MIPS_H_

