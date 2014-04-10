// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/assembler.h"
#include "vm/constants_arm64.h"
#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(Array::Handle(code.ObjectPool())),
      end_(pc),
      args_desc_load_end_(0),
      ic_data_load_end_(0),
      target_address_pool_index_(-1),
      args_desc_(Array::Handle()),
      ic_data_(ICData::Handle()) {
  UNIMPLEMENTED();
}


int CallPattern::LengthInBytes() {
  UNIMPLEMENTED();
  return 0;
}


// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded object in the output parameters 'reg' and 'obj'
// respectively.
uword InstructionPattern::DecodeLoadObject(uword end,
                                           const Array& object_pool,
                                           Register* reg,
                                           Object* obj) {
  UNIMPLEMENTED();
  return 0;
}


// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded immediate value in the output parameters 'reg' and 'value'
// respectively.
uword InstructionPattern::DecodeLoadWordImmediate(uword end,
                                                  Register* reg,
                                                  intptr_t* value) {
  UNIMPLEMENTED();
  return 0;
}


// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the index in the pool being read from in the output parameters 'reg'
// and 'index' respectively.
uword InstructionPattern::DecodeLoadWordFromPool(uword end,
                                                 Register* reg,
                                                 intptr_t* index) {
  UNIMPLEMENTED();
  return 0;
}


RawICData* CallPattern::IcData() {
  UNIMPLEMENTED();
  return NULL;
}


RawArray* CallPattern::ClosureArgumentsDescriptor() {
  UNIMPLEMENTED();
  return NULL;
}


uword CallPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void CallPattern::SetTargetAddress(uword target_address) const {
  UNIMPLEMENTED();
}


void CallPattern::InsertAt(uword pc, uword target_address) {
  UNIMPLEMENTED();
}


JumpPattern::JumpPattern(uword pc, const Code& code) : pc_(pc) { }


int JumpPattern::pattern_length_in_bytes() {
  UNIMPLEMENTED();
  return 0;
}


bool JumpPattern::IsValid() const {
  UNIMPLEMENTED();
  return false;
}


uword JumpPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
