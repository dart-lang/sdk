// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef RUNTIME_VM_INSTRUCTIONS_RISCV_H_
#define RUNTIME_VM_INSTRUCTIONS_RISCV_H_

#ifndef RUNTIME_VM_INSTRUCTIONS_H_
#error Do not include instructions_riscv.h directly; use instructions.h instead.
#endif

#include "platform/unaligned.h"
#include "vm/allocation.h"
#include "vm/constants.h"
#include "vm/native_function.h"
#include "vm/tagged_pointer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

class Code;
class ICData;
class Object;
class ObjectPool;

class InstructionPattern : public AllStatic {
 public:
  // Decodes a load sequence ending at 'end' (the last instruction of the
  // load sequence is the instruction before the one at end).  Returns the
  // address of the first instruction in the sequence.  Returns the register
  // being loaded and the loaded immediate value in the output parameters
  // 'reg' and 'value' respectively.
  static uword DecodeLoadWordImmediate(uword end,
                                       Register* reg,
                                       intptr_t* value);

  // Decodes a load sequence ending at 'end' (the last instruction of the
  // load sequence is the instruction before the one at end).  Returns the
  // address of the first instruction in the sequence.  Returns the register
  // being loaded and the index in the pool being read from in the output
  // parameters 'reg' and 'index' respectively.
  // IMPORTANT: When generating code loading values from pool on ARM64 use
  // LoadWordFromPool macro instruction instead of emitting direct load.
  // The macro instruction takes care of pool offsets that can't be
  // encoded as immediates.
  static uword DecodeLoadWordFromPool(uword end,
                                      Register* reg,
                                      intptr_t* index);

  // Encodes a load sequence ending at 'end'. Encodes a fixed length two
  // instruction load from the pool pointer in PP using the destination
  // register reg as a temporary for the base address.
  static void EncodeLoadWordFromPoolFixed(uword end, int32_t offset);
};

class CallPattern : public ValueObject {
 public:
  CallPattern(uword pc, const Code& code);

  CodePtr TargetCode() const;
  void SetTargetCode(const Code& target) const;

 private:
  const ObjectPool& object_pool_;

  intptr_t target_code_pool_index_;

  DISALLOW_COPY_AND_ASSIGN(CallPattern);
};

class ICCallPattern : public ValueObject {
 public:
  ICCallPattern(uword pc, const Code& caller_code);

  ObjectPtr Data() const;
  void SetData(const Object& data) const;

  CodePtr TargetCode() const;
  void SetTargetCode(const Code& target) const;

 private:
  const ObjectPool& object_pool_;

  intptr_t target_pool_index_;
  intptr_t data_pool_index_;

  DISALLOW_COPY_AND_ASSIGN(ICCallPattern);
};

class NativeCallPattern : public ValueObject {
 public:
  NativeCallPattern(uword pc, const Code& code);

  CodePtr target() const;
  void set_target(const Code& target) const;

  NativeFunction native_function() const;
  void set_native_function(NativeFunction target) const;

 private:
  const ObjectPool& object_pool_;

  uword end_;
  intptr_t native_function_pool_index_;
  intptr_t target_code_pool_index_;

  DISALLOW_COPY_AND_ASSIGN(NativeCallPattern);
};

// Instance call that can switch between a direct monomorphic call, an IC call,
// and a megamorphic call.
//   load guarded cid            load ICData             load MegamorphicCache
//   load monomorphic target <-> load ICLookup stub  ->  load MMLookup stub
//   call target.entry           call stub.entry         call stub.entry
class SwitchableCallPatternBase : public ValueObject {
 public:
  explicit SwitchableCallPatternBase(const ObjectPool& object_pool);

  ObjectPtr data() const;
  void SetData(const Object& data) const;

 protected:
  const ObjectPool& object_pool_;
  intptr_t data_pool_index_;
  intptr_t target_pool_index_;

 private:
  DISALLOW_COPY_AND_ASSIGN(SwitchableCallPatternBase);
};

// See [SwitchableCallBase] for a switchable calls in general.
//
// The target slot is always a [Code] object: Either the code of the
// monomorphic function or a stub code.
class SwitchableCallPattern : public SwitchableCallPatternBase {
 public:
  SwitchableCallPattern(uword pc, const Code& code);

  uword target_entry() const;
  void SetTarget(const Code& target) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(SwitchableCallPattern);
};

// See [SwitchableCallBase] for a switchable calls in general.
//
// The target slot is always a direct entrypoint address: Either the entry point
// of the monomorphic function or a stub entry point.
class BareSwitchableCallPattern : public SwitchableCallPatternBase {
 public:
  explicit BareSwitchableCallPattern(uword pc);

  uword target_entry() const;
  void SetTarget(const Code& target) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(BareSwitchableCallPattern);
};

class ReturnPattern : public ValueObject {
 public:
  explicit ReturnPattern(uword pc);

  // ret = 1 compressed instruction
  static constexpr intptr_t kLengthInBytes = 2;

  int pattern_length_in_bytes() const { return kLengthInBytes; }

  bool IsValid() const;

 private:
  const uword pc_;
};

class PcRelativePatternBase : public ValueObject {
 public:
  static constexpr intptr_t kLengthInBytes = 8;
  static constexpr intptr_t kLowerCallingRange =
      static_cast<int32_t>(0x80000000);
  static constexpr intptr_t kUpperCallingRange =
      static_cast<int32_t>(0x7FFFFFFE);

  explicit PcRelativePatternBase(uword pc) : pc_(pc) {}

  int32_t distance() {
    Instr auipc(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
    Instr jalr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4)));
    return auipc.utype_imm() + jalr.itype_imm();
  }

  void set_distance(int32_t distance) {
    Instr auipc(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_)));
    Instr jalr(LoadUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4)));
    intx_t imm = distance;
    intx_t lo = ImmLo(imm);
    intx_t hi = ImmHi(imm);
    StoreUnaligned(reinterpret_cast<uint32_t*>(pc_), EncodeUTypeImm(hi) |
                                                         EncodeRd(auipc.rd()) |
                                                         EncodeOpcode(AUIPC));
    StoreUnaligned(reinterpret_cast<uint32_t*>(pc_ + 4),
                   EncodeITypeImm(lo) | EncodeRs1(jalr.rs1()) |
                       EncodeFunct3(F3_0) | EncodeRd(jalr.rd()) |
                       EncodeOpcode(JALR));
  }

  bool IsValid() const;

 protected:
  uword pc_;
};

// auipc ra, hi20
// jalr ra, lo12(ra)
class PcRelativeCallPattern : public PcRelativePatternBase {
 public:
  explicit PcRelativeCallPattern(uword pc) : PcRelativePatternBase(pc) {}

  bool IsValid() const;
};

// auipc tmp, hi20
// jalr zero, lo12(tmp)
class PcRelativeTailCallPattern : public PcRelativePatternBase {
 public:
  explicit PcRelativeTailCallPattern(uword pc) : PcRelativePatternBase(pc) {}

  bool IsValid() const;
};

// This exists only for the CodeRelocator_OutOfRange tests. Real programs never
// use trampolines because regular calls have 32-bit of range and trampolines
// provide no additional range.
class PcRelativeTrampolineJumpPattern : public PcRelativeTailCallPattern {
 public:
  explicit PcRelativeTrampolineJumpPattern(uword pc)
      : PcRelativeTailCallPattern(pc) {}

  void Initialize();
};

}  // namespace dart

#endif  // RUNTIME_VM_INSTRUCTIONS_RISCV_H_
