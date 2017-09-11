// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // NOLINT
#if defined(TARGET_ARCH_DBC)

#include "vm/compiler/assembler/assembler.h"
#include "vm/cpu.h"
#include "vm/longjump.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, check_code_pointer);
DECLARE_FLAG(bool, inline_alloc);

void Assembler::InitializeMemoryWithBreakpoints(uword data, intptr_t length) {
  const uword end = data + length;
  while (data < end) {
    *reinterpret_cast<int32_t*>(data) = Bytecode::kTrap;
    data += sizeof(int32_t);
  }
}

#define DEFINE_EMIT(Name, Signature, Fmt0, Fmt1, Fmt2)                         \
  void Assembler::Name(PARAMS_##Signature) {                                   \
    Emit(Bytecode::FENCODE_##Signature(Bytecode::k##Name ENCODE_##Signature)); \
  }

#define PARAMS_0
#define PARAMS_A_D uintptr_t ra, uintptr_t rd
#define PARAMS_D uintptr_t rd
#define PARAMS_A_B_C uintptr_t ra, uintptr_t rb, uintptr_t rc
#define PARAMS_A uintptr_t ra
#define PARAMS_T intptr_t x
#define PARAMS_A_X uintptr_t ra, intptr_t x
#define PARAMS_X intptr_t x

#define ENCODE_0
#define ENCODE_A_D , ra, rd
#define ENCODE_D , 0, rd
#define ENCODE_A_B_C , ra, rb, rc
#define ENCODE_A , ra, 0
#define ENCODE_T , x
#define ENCODE_A_X , ra, x
#define ENCODE_X , 0, x

#define FENCODE_0 Encode
#define FENCODE_A_D Encode
#define FENCODE_D Encode
#define FENCODE_A_B_C Encode
#define FENCODE_A Encode
#define FENCODE_T EncodeSigned
#define FENCODE_A_X EncodeSigned
#define FENCODE_X EncodeSigned

BYTECODES_LIST(DEFINE_EMIT)

#undef DEFINE_EMIT

void Assembler::Emit(int32_t value) {
  AssemblerBuffer::EnsureCapacity ensured(&buffer_);
  buffer_.Emit<int32_t>(value);
}

const char* Assembler::RegisterName(Register reg) {
  return Thread::Current()->zone()->PrintToString("R%d", reg);
}

static int32_t EncodeJump(int32_t relative_pc) {
  return Bytecode::kJump | (relative_pc << 8);
}

static int32_t OffsetToPC(int32_t offset) {
  return offset >> 2;
}

void Assembler::Jump(Label* label) {
  if (label->IsBound()) {
    Emit(EncodeJump(OffsetToPC(label->Position() - buffer_.Size())));
  } else {
    const intptr_t position = buffer_.Size();
    Emit(label->position_);
    label->LinkTo(position);
  }
}

void Assembler::Bind(Label* label) {
  ASSERT(!label->IsBound());
  ASSERT(!label->IsBound());
  intptr_t bound_pc = buffer_.Size();
  while (label->IsLinked()) {
    const int32_t position = label->Position();
    const int32_t next_position = buffer_.Load<int32_t>(position);
    buffer_.Store<int32_t>(position,
                           EncodeJump(OffsetToPC(bound_pc - position)));
    label->position_ = next_position;
  }
  label->BindTo(bound_pc);
}

void Assembler::Stop(const char* message) {
  // TODO(vegorov) support passing a message to the bytecode.
  Emit(Bytecode::kTrap);
}

void Assembler::PushConstant(const Object& obj) {
  PushConstant(AddConstant(obj));
}

void Assembler::LoadConstant(uintptr_t ra, const Object& obj) {
  LoadConstant(ra, AddConstant(obj));
}

intptr_t Assembler::AddConstant(const Object& obj) {
  return object_pool_wrapper().FindObject(Object::ZoneHandle(obj.raw()));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
