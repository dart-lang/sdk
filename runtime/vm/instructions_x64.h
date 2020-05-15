// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef RUNTIME_VM_INSTRUCTIONS_X64_H_
#define RUNTIME_VM_INSTRUCTIONS_X64_H_

#ifndef RUNTIME_VM_INSTRUCTIONS_H_
#error "Do not include instructions_x64.h directly; use instructions.h instead."
#endif

#include "platform/unaligned.h"
#include "vm/allocation.h"

namespace dart {

intptr_t IndexFromPPLoadDisp8(uword start);
intptr_t IndexFromPPLoadDisp32(uword start);

// Template class for all instruction pattern classes.
// P has to specify a static pattern and a pattern length method.
template <class P>
class InstructionPattern : public ValueObject {
 public:
  explicit InstructionPattern(uword pc) : start_(pc) { ASSERT(pc != 0); }

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

class ReturnPattern : public InstructionPattern<ReturnPattern> {
 public:
  explicit ReturnPattern(uword pc) : InstructionPattern(pc) {}

  static const int* pattern() {
    static const int kReturnPattern[kLengthInBytes] = {0xC3};
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
    static const int kProloguePattern[kLengthInBytes] = {0x55, 0x48, 0x89,
                                                         0xe5};
    return kProloguePattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

 private:
  static const int kLengthInBytes = 4;
};

// mov rbp, rsp
class SetFramePointerPattern
    : public InstructionPattern<SetFramePointerPattern> {
 public:
  explicit SetFramePointerPattern(uword pc) : InstructionPattern(pc) {}

  static const int* pattern() {
    static const int kFramePointerPattern[kLengthInBytes] = {0x48, 0x89, 0xe5};
    return kFramePointerPattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

 private:
  static const int kLengthInBytes = 3;
};

// callq *[rip+offset]
class PcRelativeCallPattern : public InstructionPattern<PcRelativeCallPattern> {
 public:
  static const intptr_t kLowerCallingRange = -(DART_UINT64_C(1) << 31);
  static const intptr_t kUpperCallingRange = (DART_UINT64_C(1) << 31) - 1;

  explicit PcRelativeCallPattern(uword pc) : InstructionPattern(pc) {}

  int32_t distance() {
    return LoadUnaligned(reinterpret_cast<int32_t*>(start() + 1)) +
           kLengthInBytes;
  }

  void set_distance(int32_t distance) {
    // [distance] is relative to the start of the instruction, x64 considers the
    // offset relative to next PC.
    StoreUnaligned(reinterpret_cast<int32_t*>(start() + 1),
                   distance - kLengthInBytes);
  }

  static const int* pattern() {
    static const int kPattern[kLengthInBytes] = {0xe8, -1, -1, -1, -1};
    return kPattern;
  }

  static int pattern_length_in_bytes() { return kLengthInBytes; }

  static const int kLengthInBytes = 5;
};

// Instruction pattern for a tail call to a signed 32-bit PC-relative offset
//
// The AOT compiler can emit PC-relative calls. If the destination of such a
// call is not in range for the "bl.<cond> <offset>" instruction, the AOT
// compiler will emit a trampoline which is in range. That trampoline will
// then tail-call to the final destination (also via PC-relative offset, but it
// supports a full signed 32-bit offset).
//
// The pattern of the trampoline looks like:
//
//     jmp $rip + <offset>
//
// (Strictly speaking the pc-relative call distance on X64 is big enough, but
// for making AOT relocation code (i.e. relocation.cc) platform independent and
// allow testing of trampolines on X64 we have it nonetheless)
class PcRelativeTrampolineJumpPattern : public ValueObject {
 public:
  static const int kLengthInBytes = 5;

  explicit PcRelativeTrampolineJumpPattern(uword pattern_start)
      : pattern_start_(pattern_start) {}

  void Initialize() {
    uint8_t* pattern = reinterpret_cast<uint8_t*>(pattern_start_);
    pattern[0] = 0xe9;
  }

  int32_t distance() {
    return LoadUnaligned(reinterpret_cast<int32_t*>(pattern_start_ + 1)) +
           kLengthInBytes;
  }

  void set_distance(int32_t distance) {
    // [distance] is relative to the start of the instruction, x64 considers the
    // offset relative to next PC.
    StoreUnaligned(reinterpret_cast<int32_t*>(pattern_start_ + 1),
                   distance - kLengthInBytes);
  }

  bool IsValid() const {
    uint8_t* pattern = reinterpret_cast<uint8_t*>(pattern_start_);
    return pattern[0] == 0xe9;
  }

 private:
  uword pattern_start_;
};

class PcRelativeTailCallPattern : public PcRelativeTrampolineJumpPattern {
 public:
  static const intptr_t kLowerCallingRange = -(1ul << 31) + kLengthInBytes;
  static const intptr_t kUpperCallingRange = (1ul << 31) - 1;

  explicit PcRelativeTailCallPattern(uword pc)
      : PcRelativeTrampolineJumpPattern(pc) {}
};

}  // namespace dart

#endif  // RUNTIME_VM_INSTRUCTIONS_X64_H_
