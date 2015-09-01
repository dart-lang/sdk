// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_X64_H_
#define VM_INSTRUCTIONS_X64_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_ia32.h directly; use instructions.h instead.
#endif

#include "vm/allocation.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class RawClass;
class Immediate;
class RawObject;


intptr_t IndexFromPPLoad(uword start);


// Template class for all instruction pattern classes.
// P has to specify a static pattern and a pattern length method.
template<class P> class InstructionPattern : public ValueObject {
 public:
  explicit InstructionPattern(uword pc) : start_(pc) {
    ASSERT(pc != 0);
  }

  // Call to check if the instruction pattern at 'pc' match the instruction.
  // 'P::pattern()' returns the expected byte pattern in form of an integer
  // array with length of 'P::pattern_length_in_bytes()'. A '-1' element means
  // 'any byte'.
  bool IsValid() const {
    return TestBytesWith(P::pattern(), P::pattern_length_in_bytes());
  }

 protected:
  uword start() const { return start_; }

 private:
  // Returns true if the 'num_bytes' bytes at 'start_' correspond to
  // array of integers 'data'. 'data' elements are either a byte or -1, which
  // represents any byte.
  bool TestBytesWith(const int* data, int num_bytes) const {
    ASSERT(data != NULL);
    const uint8_t* byte_array = reinterpret_cast<const uint8_t*>(start_);
    for (int i = 0; i < num_bytes; i++) {
      // Skip comparison for data[i] < 0.
      if ((data[i] >= 0) && (byte_array[i] != (0xFF & data[i]))) {
        return false;
      }
    }
    return true;
  }

  const uword start_;

  DISALLOW_COPY_AND_ASSIGN(InstructionPattern);
};


class JumpPattern : public InstructionPattern<JumpPattern> {
 public:
  JumpPattern(uword pc, const Code& code)
      : InstructionPattern(pc),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {}

  uword TargetAddress() const;
  void SetTargetAddress(uword new_target) const;

  static const int kLengthInBytes = 7;
  static int pattern_length_in_bytes() { return kLengthInBytes; }
  static const int* pattern() {
    //  07: 41 ff a7 imm32  jmpq [reg + off]
    static const int kJumpPattern[kLengthInBytes] =
        {0x41, 0xFF, -1, -1, -1, -1, -1};
    return kJumpPattern;
  }
 private:
  const ObjectPool& object_pool_;

  DISALLOW_COPY_AND_ASSIGN(JumpPattern);
};


// 5 byte call instruction.
class ShortCallPattern : public InstructionPattern<ShortCallPattern> {
 public:
  explicit ShortCallPattern(uword pc) : InstructionPattern(pc) {}

  void SetTargetAddress(uword new_target) const;

  static int pattern_length_in_bytes() { return kLengthInBytes; }
  static const int* pattern() {
    static const int kCallPattern[kLengthInBytes] = {0xE8, -1, -1, -1, -1};
    return kCallPattern;
  }

 private:
  static const int kLengthInBytes = 5;
  DISALLOW_COPY_AND_ASSIGN(ShortCallPattern);
};


class ReturnPattern : public InstructionPattern<ReturnPattern> {
 public:
  explicit ReturnPattern(uword pc) : InstructionPattern(pc) {}

  static const int* pattern() {
    static const int kReturnPattern[kLengthInBytes] = { 0xC3 };
    return kReturnPattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

 private:
  static const int kLengthInBytes = 1;
};


// push rbp
// mov rbp, rsp
class ProloguePattern : public InstructionPattern<ProloguePattern> {
 public:
  explicit ProloguePattern(uword pc) : InstructionPattern(pc) {}

  static const int* pattern() {
    static const int kProloguePattern[kLengthInBytes] =
        { 0x55, 0x48, 0x89, 0xe5 };
    return kProloguePattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

 private:
  static const int kLengthInBytes = 4;
};


// mov rbp, rsp
class SetFramePointerPattern :
    public InstructionPattern<SetFramePointerPattern> {
 public:
  explicit SetFramePointerPattern(uword pc) : InstructionPattern(pc) {}

  static const int* pattern() {
    static const int kFramePointerPattern[kLengthInBytes] =
        { 0x48, 0x89, 0xe5 };
    return kFramePointerPattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

 private:
  static const int kLengthInBytes = 3;
};

}  // namespace dart

#endif  // VM_INSTRUCTIONS_X64_H_
