// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/instructions.h"
#include "vm/instructions_dbc.h"

#include "vm/assembler.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

static bool HasLoadFromPool(Instr instr) {
  switch (Bytecode::DecodeOpcode(instr)) {
    case Bytecode::kLoadConstant:
    case Bytecode::kPushConstant:
    case Bytecode::kStaticCall:
    case Bytecode::kIndirectStaticCall:
    case Bytecode::kInstanceCall1:
    case Bytecode::kInstanceCall2:
    case Bytecode::kInstanceCall1Opt:
    case Bytecode::kInstanceCall2Opt:
    case Bytecode::kStoreStaticTOS:
    case Bytecode::kPushStatic:
    case Bytecode::kAllocate:
    case Bytecode::kInstantiateType:
    case Bytecode::kInstantiateTypeArgumentsTOS:
    case Bytecode::kAssertAssignable:
      return true;
    default:
      return false;
  }
}

static bool GetLoadedObjectAt(uword pc,
                              const ObjectPool& object_pool,
                              Object* obj) {
  Instr instr = Bytecode::At(pc);
  if (HasLoadFromPool(instr)) {
    uint16_t index = Bytecode::DecodeD(instr);
    if (object_pool.InfoAt(index) == ObjectPool::kTaggedObject) {
      *obj = object_pool.ObjectAt(index);
      return true;
    }
  }
  return false;
}

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      ic_data_load_end_(0),
      target_code_pool_index_(-1),
      ic_data_(ICData::Handle()) {
  ASSERT(code.ContainsInstructionAt(end_));
  const uword call_pc = end_ - sizeof(Instr);
  Instr call_instr = Bytecode::At(call_pc);
  ASSERT(Bytecode::IsCallOpcode(call_instr));
  ic_data_load_end_ = call_pc;
  target_code_pool_index_ = Bytecode::DecodeD(call_instr);
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      target_code_pool_index_(-1) {
  UNIMPLEMENTED();
}

RawCode* NativeCallPattern::target() const {
  return reinterpret_cast<RawCode*>(
      object_pool_.ObjectAt(target_code_pool_index_));
}

void NativeCallPattern::set_target(const Code& new_target) const {
  object_pool_.SetObjectAt(target_code_pool_index_, new_target);
  // No need to flush the instruction cache, since the code is not modified.
}

NativeFunction NativeCallPattern::native_function() const {
  return reinterpret_cast<NativeFunction>(
      object_pool_.RawValueAt(native_function_pool_index_));
}

void NativeCallPattern::set_native_function(NativeFunction func) const {
  object_pool_.SetRawValueAt(native_function_pool_index_,
                             reinterpret_cast<uword>(func));
}

// Decodes a load sequence ending at 'end' (the last instruction of the load
// sequence is the instruction before the one at end).  Returns a pointer to
// the first instruction in the sequence.  Returns the register being loaded
// and the loaded object in the output parameters 'reg' and 'obj'
// respectively.
uword InstructionPattern::DecodeLoadObject(uword end,
                                           const ObjectPool& object_pool,
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

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));
  const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
  return GetLoadedObjectAt(pc, pool, obj);
}

RawICData* CallPattern::IcData() {
  if (ic_data_.IsNull()) {
    bool found = GetLoadedObjectAt(ic_data_load_end_, object_pool_, &ic_data_);
    ASSERT(found);
  }
  return ic_data_.raw();
}

RawCode* CallPattern::TargetCode() const {
  return reinterpret_cast<RawCode*>(
      object_pool_.ObjectAt(target_code_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target_code) const {
  object_pool_.SetObjectAt(target_code_pool_index_, target_code);
}

void CallPattern::InsertDeoptCallAt(uword pc) {
  const uint8_t argc = Bytecode::IsCallOpcode(Bytecode::At(pc))
                           ? Bytecode::DecodeArgc(Bytecode::At(pc))
                           : 0;
  *reinterpret_cast<Instr*>(pc) = Bytecode::Encode(Bytecode::kDeopt, argc, 0);
}

SwitchableCallPattern::SwitchableCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      data_pool_index_(-1),
      target_pool_index_(-1) {
  UNIMPLEMENTED();
}

RawObject* SwitchableCallPattern::data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

RawCode* SwitchableCallPattern::target() const {
  return reinterpret_cast<RawCode*>(object_pool_.ObjectAt(target_pool_index_));
}

void SwitchableCallPattern::SetData(const Object& data) const {
  ASSERT(!Object::Handle(object_pool_.ObjectAt(data_pool_index_)).IsCode());
  object_pool_.SetObjectAt(data_pool_index_, data);
}

void SwitchableCallPattern::SetTarget(const Code& target) const {
  ASSERT(Object::Handle(object_pool_.ObjectAt(target_pool_index_)).IsCode());
  object_pool_.SetObjectAt(target_pool_index_, target);
}

ReturnPattern::ReturnPattern(uword pc) : pc_(pc) {
  USE(pc_);
}

bool ReturnPattern::IsValid() const {
  UNIMPLEMENTED();
  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
