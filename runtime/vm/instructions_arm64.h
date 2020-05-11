// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef RUNTIME_VM_INSTRUCTIONS_ARM64_H_
#define RUNTIME_VM_INSTRUCTIONS_ARM64_H_

#ifndef RUNTIME_VM_INSTRUCTIONS_H_
#error Do not include instructions_arm64.h directly; use instructions.h instead.
#endif

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
  // being loaded and the loaded object in the output parameters 'reg' and
  // 'obj' respectively.
  static uword DecodeLoadObject(uword end,
                                const ObjectPool& object_pool,
                                Register* reg,
                                Object* obj);

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
  // IMPORANT: When generating code loading values from pool on ARM64 use
  // LoadWordFromPool macro instruction instead of emitting direct load.
  // The macro instruction takes care of pool offsets that can't be
  // encoded as immediates.
  static uword DecodeLoadWordFromPool(uword end,
                                      Register* reg,
                                      intptr_t* index);

  // Decodes a load sequence ending at 'end' (the last instruction of the
  // load sequence is the instruction before the one at end).  Returns the
  // address of the first instruction in the sequence.  Returns the registers
  // being loaded and the index in the pool being read from in the output
  // parameters 'reg1', 'reg2' and 'index' respectively.
  // IMPORANT: When generating code loading values from pool on ARM64 use
  // LoadDoubleWordFromPool macro instruction instead of emitting direct load.
  // The macro instruction takes care of pool offsets that can't be
  // encoded as immediates.
  static uword DecodeLoadDoubleWordFromPool(uword end,
                                            Register* reg1,
                                            Register* reg2,
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
  explicit SwitchableCallPatternBase(const Code& code);

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

  CodePtr target() const;
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
  BareSwitchableCallPattern(uword pc, const Code& code);

  CodePtr target() const;
  void SetTarget(const Code& target) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(BareSwitchableCallPattern);
};

class ReturnPattern : public ValueObject {
 public:
  explicit ReturnPattern(uword pc);

  // bx_lr = 1.
  static const int kLengthInBytes = 1 * Instr::kInstrSize;

  int pattern_length_in_bytes() const { return kLengthInBytes; }

  bool IsValid() const;

 private:
  const uword pc_;
};

class PcRelativePatternBase : public ValueObject {
 public:
  // 26 bit signed integer which will get multiplied by 4.
  static const intptr_t kLowerCallingRange = -(1 << 27);
  static const intptr_t kUpperCallingRange = (1 << 27) - 1;

  explicit PcRelativePatternBase(uword pc) : pc_(pc) {}

  static const int kLengthInBytes = 1 * Instr::kInstrSize;

  int32_t distance() {
#if !defined(DART_PRECOMPILED_RUNTIME)
    return compiler::Assembler::DecodeImm26BranchOffset(
        *reinterpret_cast<int32_t*>(pc_));
#else
    UNREACHABLE();
    return 0;
#endif
  }

  void set_distance(int32_t distance) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    int32_t* word = reinterpret_cast<int32_t*>(pc_);
    *word = compiler::Assembler::EncodeImm26BranchOffset(distance, *word);
#else
    UNREACHABLE();
#endif
  }

  bool IsValid() const;

 protected:
  uword pc_;
};

class PcRelativeCallPattern : public PcRelativePatternBase {
 public:
  explicit PcRelativeCallPattern(uword pc) : PcRelativePatternBase(pc) {}

  bool IsValid() const;
};

class PcRelativeTailCallPattern : public PcRelativePatternBase {
 public:
  explicit PcRelativeTailCallPattern(uword pc) : PcRelativePatternBase(pc) {}

  bool IsValid() const;
};

// Instruction pattern for a tail call to a signed 32-bit PC-relative offset
//
// The AOT compiler can emit PC-relative calls. If the destination of such a
// call is not in range for the "bl <offset>" instruction, the AOT compiler will
// emit a trampoline which is in range. That trampoline will then tail-call to
// the final destination (also via PC-relative offset, but it supports a full
// signed 32-bit offset).
//
// The pattern of the trampoline looks like:
//
//     adr TMP, #lower16  (same as TMP = PC + #lower16)
//     movz TMP2, #higher16 lsl 16
//     add TMP, TMP, TMP2, SXTW
//     br TMP
//
class PcRelativeTrampolineJumpPattern : public ValueObject {
 public:
  explicit PcRelativeTrampolineJumpPattern(uword pattern_start)
      : pattern_start_(pattern_start) {
    USE(pattern_start_);
  }

  static const int kLengthInBytes = 4 * Instr::kInstrSize;

  void Initialize();

  int32_t distance();
  void set_distance(int32_t distance);
  bool IsValid() const;

 private:
  // This offset must be applied to account for the fact that
  //   a) the actual "branch" is only in the 3rd instruction
  //   b) when reading the PC it reports current instruction + 8
  static const intptr_t kDistanceOffset = -5 * Instr::kInstrSize;

  // adr TMP, #lower16  (same as TMP = PC + #lower16)
  static const uint32_t kAdrEncoding = (1 << 28) | (TMP << kRdShift);

  // movz TMP2, #higher16 lsl 16
  static const uint32_t kMovzEncoding = MOVZ | (1 << kHWShift) | TMP2;

  // add TMP, TMP, TMP2, SXTW
  static const uint32_t kAddTmpTmp2 = 0x8b31c210;

  // br TMP
  static const uint32_t kJumpEncoding = BR | (TMP << kRnShift);

  uword pattern_start_;
};

}  // namespace dart

#endif  // RUNTIME_VM_INSTRUCTIONS_ARM64_H_
