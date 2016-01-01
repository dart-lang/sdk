// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_MIPS_H_
#define VM_INSTRUCTIONS_MIPS_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_mips.h directly; use instructions.h instead.
#endif

#include "vm/constants_mips.h"
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
};


class CallPattern : public ValueObject {
 public:
  CallPattern(uword pc, const Code& code);

  RawICData* IcData();

  RawCode* TargetCode() const;
  void SetTargetCode(const Code& target) const;

  static const int kDeoptCallLengthInInstructions = 4;
  static const int kDeoptCallLengthInBytes =
      kDeoptCallLengthInInstructions * Instr::kInstrSize;

  static void InsertDeoptCallAt(uword pc, uword target_address);

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


// Instance call that can switch from an IC call to a megamorphic call
//   load ICData             load MegamorphicCache
//   call ICLookup stub  ->  call MegamorphicLookup stub
//   call target             call target
class SwitchableCallPattern : public ValueObject {
 public:
  SwitchableCallPattern(uword pc, const Code& code);

  RawObject* cache() const;
  void SetCache(const MegamorphicCache& cache) const;
  void SetLookupStub(const Code& stub) const;

 private:
  const ObjectPool& object_pool_;
  intptr_t cache_pool_index_;
  intptr_t stub_pool_index_;

  DISALLOW_COPY_AND_ASSIGN(SwitchableCallPattern);
};


class ReturnPattern : public ValueObject {
 public:
  explicit ReturnPattern(uword pc);

  // jr(RA) = 1
  static const int kLengthInBytes = 1 * Instr::kInstrSize;

  int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }

  bool IsValid() const;

 private:
  const uword pc_;
};

}  // namespace dart

#endif  // VM_INSTRUCTIONS_MIPS_H_
