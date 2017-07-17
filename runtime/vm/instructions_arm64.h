// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef RUNTIME_VM_INSTRUCTIONS_ARM64_H_
#define RUNTIME_VM_INSTRUCTIONS_ARM64_H_

#ifndef RUNTIME_VM_INSTRUCTIONS_H_
#error Do not include instructions_arm64.h directly; use instructions.h instead.
#endif

#include "vm/constants_arm64.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

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
  static uword DecodeLoadWordFromPool(uword end,
                                      Register* reg,
                                      intptr_t* index);

  // Encodes a load sequence ending at 'end'. Encodes a fixed length two
  // instruction load from the pool pointer in PP using the destination
  // register reg as a temporary for the base address.
  static void EncodeLoadWordFromPoolFixed(uword end, int32_t offset);

  static intptr_t OffsetFromPPIndex(intptr_t index);
};

class CallPattern : public ValueObject {
 public:
  CallPattern(uword pc, const Code& code);

  RawICData* IcData();

  RawCode* TargetCode() const;
  void SetTargetCode(const Code& target) const;

 private:
  const ObjectPool& object_pool_;

  uword end_;
  uword ic_data_load_end_;

  intptr_t target_code_pool_index_;
  ICData& ic_data_;

  DISALLOW_COPY_AND_ASSIGN(CallPattern);
};

class NativeCallPattern : public ValueObject {
 public:
  NativeCallPattern(uword pc, const Code& code);

  RawCode* target() const;
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
class SwitchableCallPattern : public ValueObject {
 public:
  SwitchableCallPattern(uword pc, const Code& code);

  RawObject* data() const;
  RawCode* target() const;
  void SetData(const Object& data) const;
  void SetTarget(const Code& target) const;

 private:
  const ObjectPool& object_pool_;
  intptr_t data_pool_index_;
  intptr_t target_pool_index_;

  DISALLOW_COPY_AND_ASSIGN(SwitchableCallPattern);
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

}  // namespace dart

#endif  // RUNTIME_VM_INSTRUCTIONS_ARM64_H_
