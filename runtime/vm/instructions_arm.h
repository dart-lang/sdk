// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef VM_INSTRUCTIONS_ARM_H_
#define VM_INSTRUCTIONS_ARM_H_

#ifndef VM_INSTRUCTIONS_H_
#error Do not include instructions_arm.h directly; use instructions.h instead.
#endif

#include "vm/constants_arm.h"
#include "vm/object.h"

namespace dart {

class CallPattern : public ValueObject {
 public:
  CallPattern(uword pc, const Code& code);

  RawICData* IcData();
  RawArray* ArgumentsDescriptor();

  uword TargetAddress() const;
  void SetTargetAddress(uword target_address) const;

 private:
  uword Back(int n) const;
  int DecodeLoadObject(int end, Register* reg, Object* obj);
  int DecodeLoadWordImmediate(int end, Register* reg, int* value);
  int DecodeLoadWordFromPool(int end, Register* reg, int* index);
  const uword* end_;
  int target_address_pool_index_;
  int args_desc_load_end_;
  Array& args_desc_;
  int ic_data_load_end_;
  ICData& ic_data_;
  const Array& object_pool_;

  DISALLOW_COPY_AND_ASSIGN(CallPattern);
};


class JumpPattern : public ValueObject {
 public:
  explicit JumpPattern(uword pc);

  static const int kLengthInBytes = 3 * Instr::kInstrSize;

  int pattern_length_in_bytes() const {
    return kLengthInBytes;
  }

  bool IsValid() const;
  uword TargetAddress() const;
  void SetTargetAddress(uword target_address) const;

 private:
  const uword pc_;

  DISALLOW_COPY_AND_ASSIGN(JumpPattern);
};

}  // namespace dart

#endif  // VM_INSTRUCTIONS_ARM_H_

