// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A light-weight assembler for the Irregexp byte code.

#include "vm/regexp_bytecodes.h"

#ifndef RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_INL_H_
#define RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_INL_H_

namespace dart {

void BytecodeRegExpMacroAssembler::Emit(uint32_t byte,
                                        uint32_t twenty_four_bits) {
  uint32_t word = ((twenty_four_bits << BYTECODE_SHIFT) | byte);
  ASSERT(pc_ <= buffer_->length());
  if (pc_ + 3 >= buffer_->length()) {
    Expand();
  }
  *reinterpret_cast<uint32_t*>(buffer_->data() + pc_) = word;
  pc_ += 4;
}

void BytecodeRegExpMacroAssembler::Emit16(uint32_t word) {
  ASSERT(pc_ <= buffer_->length());
  if (pc_ + 1 >= buffer_->length()) {
    Expand();
  }
  *reinterpret_cast<uint16_t*>(buffer_->data() + pc_) = word;
  pc_ += 2;
}

void BytecodeRegExpMacroAssembler::Emit8(uint32_t word) {
  ASSERT(pc_ <= buffer_->length());
  if (pc_ == buffer_->length()) {
    Expand();
  }
  *reinterpret_cast<unsigned char*>(buffer_->data() + pc_) = word;
  pc_ += 1;
}

void BytecodeRegExpMacroAssembler::Emit32(uint32_t word) {
  ASSERT(pc_ <= buffer_->length());
  if (pc_ + 3 >= buffer_->length()) {
    Expand();
  }
  *reinterpret_cast<uint32_t*>(buffer_->data() + pc_) = word;
  pc_ += 4;
}

}  // namespace dart

#endif  // RUNTIME_VM_REGEXP_ASSEMBLER_BYTECODE_INL_H_
