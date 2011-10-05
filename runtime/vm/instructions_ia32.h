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


// Pattern to load receiver from stack into EAX, with caller's return
// address on TOS and EDX containing the number of arguments. Pattern:
// 'mov eax, 0xb(edx)'.
// 'mov eax, (esp+eax*0x2)'.
class ICLoadReceiver : public Instruction {
 public:
  explicit ICLoadReceiver(uword pc) : Instruction(pc) {}

  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }

 private:
  virtual const int* pattern() const;

  static const int kLengthInBytes = 6;

  DISALLOW_COPY_AND_ASSIGN(ICLoadReceiver);
};


// Pattern for a conditional jump (if zero) to a far address. Pattern:
// 'jz <target-address>'
class JumpIfZero : public Instruction {
 public:
  explicit JumpIfZero(uword pc) : Instruction(pc) {}
  uword TargetAddress() const;
  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }

  void SetTargetAddress(uword pc);

 private:
  friend class TestEaxIsSmi;
  friend class ICCheckReceiverClass;

  virtual const int* pattern() const;

  static const int kLengthInBytes = 6;

  DISALLOW_COPY_AND_ASSIGN(JumpIfZero);
};


// Pattern for comparison of an immediate with EAX. Pattern:
// 'cmp eax, <immediate>'.
class CmpEaxWithImmediate : public Instruction {
 public:
  explicit CmpEaxWithImmediate(uword pc) : Instruction(pc) {}
  Immediate* immediate() const {
    ASSERT(IsValid());
    return reinterpret_cast<Immediate*>(start() + 1);
  }
  virtual int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }

 private:
  virtual const int* pattern() const;

  static const int kLengthInBytes = 5;

  DISALLOW_COPY_AND_ASSIGN(CmpEaxWithImmediate);
};


// Pattern to test if EAX contains a Smi. Pattern:
// 'test al, 0x1'
// 'jz <is-smi-target>'.
class TestEaxIsSmi : public Instruction {
 public:
  explicit TestEaxIsSmi(uword pc)
      : Instruction(pc),
        jz_(pc + kTestLengthInBytes) {}
  uword TargetAddress() const {
    ASSERT(IsValid());
    return jz_.TargetAddress();
  }

  void SetTargetAddress(uword new_target) {
    ASSERT(IsValid());
    jz_.SetTargetAddress(new_target);
    ASSERT(IsValid());
  }

  virtual int pattern_length_in_bytes() const {
    return kTestLengthInBytes + jz_.pattern_length_in_bytes();
  }
  virtual bool IsValid() const {
    return Instruction::IsValid() && jz_.IsValid();
  }

 private:
  virtual const int* pattern() const;

  static const int kTestLengthInBytes = 2;
  JumpIfZero jz_;

  DISALLOW_COPY_AND_ASSIGN(TestEaxIsSmi);
};


// Pattern for checking class of the receiver (class in EBX). Pattern:
// cmp ebx, <test-class>
// jz <is-class-target>'
class ICCheckReceiverClass : public Instruction {
 public:
  explicit ICCheckReceiverClass(uword pc)
      : Instruction(pc),
        jz_(pc + kTestLengthInBytes) {}
  virtual int pattern_length_in_bytes() const {
    return kTestLengthInBytes + jz_.pattern_length_in_bytes();
  }
  virtual bool IsValid() const {
    return Instruction::IsValid() && jz_.IsValid();
  }
  uword TargetAddress() const {
    ASSERT(IsValid());
    return jz_.TargetAddress();
  }
  RawClass* TestClass() const;

  void SetTargetAddress(uword new_target) {
    ASSERT(IsValid());
    jz_.SetTargetAddress(new_target);
    ASSERT(IsValid());
  }

 private:
  virtual const int* pattern() const;

  static const int kTestLengthInBytes = 6;
  JumpIfZero jz_;

  DISALLOW_COPY_AND_ASSIGN(ICCheckReceiverClass);
};


class LoadObjectClass : public Instruction {
 public:
  explicit LoadObjectClass(uword pc) : Instruction(pc) {}
  virtual int pattern_length_in_bytes() const {
    return kLoadObjectClassLengthInBytes;
  }
 private:
  virtual const int* pattern() const;
  static const int kLoadObjectClassLengthInBytes = 3;

  DISALLOW_COPY_AND_ASSIGN(LoadObjectClass);
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
