// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_IA32_H_
#define VM_INSTRUCTIONS_IA32_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_ia32.h directly; use instructions.h instead.
#endif

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class RawClass;
class Immediate;
class RawObject;

// Abstract class for all instruction pattern classes.
class Instruction : public ValueObject {
 public:
  explicit Instruction(uword pc) : start_(pc) {
    ASSERT(pc != 0);
  }
  virtual ~Instruction() {}

  // Call to check if the instruction pattern at 'pc' match the instruction.
  virtual bool IsValid() const {
    return TestBytesWith(pattern(), pattern_length_in_bytes());
  }

  // 'pattern' returns the expected byte pattern in form of an integer array
  // with length of 'pattern_length_in_bytes'. A '-1' element means 'any byte'.
  virtual const int* pattern() const = 0;
  virtual int pattern_length_in_bytes() const = 0;

 protected:
  uword start() const { return start_; }

 private:
  // Returns true if the 'num_bytes' bytes at 'start_' correspond to
  // array of integers 'data'. 'data' elements are either a byte or -1, which
  // represents any byte.
  bool TestBytesWith(const int* data, int num_bytes) const;

  const uword start_;

  DISALLOW_COPY_AND_ASSIGN(Instruction);
};


class CallOrJump : public Instruction {
 public:
  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }
  uword TargetAddress() const;
  void SetTargetAddress(uword new_target) const;

 protected:
  explicit CallOrJump(uword pc) : Instruction(pc) {}
  static const int kLengthInBytes = 5;

 private:
  DISALLOW_COPY_AND_ASSIGN(CallOrJump);
};


class Call : public CallOrJump {
 public:
  explicit Call(uword pc) : CallOrJump(pc) {}
  static int InstructionLength() {
    return kLengthInBytes;
  }

 private:
  virtual const int* pattern() const;

  DISALLOW_COPY_AND_ASSIGN(Call);
};


class Jump : public CallOrJump {
 public:
  explicit Jump(uword pc) : CallOrJump(pc) {}

 private:
  virtual const int* pattern() const;

  DISALLOW_COPY_AND_ASSIGN(Jump);
};


}  // namespace dart

#endif  // VM_INSTRUCTIONS_IA32_H_
