// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/instructions.h"
#include "vm/instructions_dbc.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/constants_dbc.h"
#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

static bool HasLoadFromPool(Instr instr) {
  switch (SimulatorBytecode::DecodeOpcode(instr)) {
    case SimulatorBytecode::kLoadConstant:
    case SimulatorBytecode::kPushConstant:
    case SimulatorBytecode::kStaticCall:
    case SimulatorBytecode::kIndirectStaticCall:
    case SimulatorBytecode::kInstanceCall1:
    case SimulatorBytecode::kInstanceCall2:
    case SimulatorBytecode::kInstanceCall1Opt:
    case SimulatorBytecode::kInstanceCall2Opt:
    case SimulatorBytecode::kStoreStaticTOS:
    case SimulatorBytecode::kPushStatic:
    case SimulatorBytecode::kAllocate:
    case SimulatorBytecode::kInstantiateType:
    case SimulatorBytecode::kInstantiateTypeArgumentsTOS:
    case SimulatorBytecode::kAssertAssignable:
      return true;
    default:
      return false;
  }
}

static bool GetLoadedObjectAt(uword pc,
                              const ObjectPool& object_pool,
                              Object* obj) {
  Instr instr = SimulatorBytecode::At(pc);
  if (HasLoadFromPool(instr)) {
    uint16_t index = SimulatorBytecode::DecodeD(instr);
    if (object_pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
      *obj = object_pool.ObjectAt(index);
      return true;
    }
  }
  return false;
}

CallPattern::CallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      data_pool_index_(-1),
      target_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(end_));
  const uword call_pc = end_ - sizeof(Instr);
  Instr call_instr = SimulatorBytecode::At(call_pc);
  ASSERT(SimulatorBytecode::IsCallOpcode(call_instr));
  data_pool_index_ = SimulatorBytecode::DecodeD(call_instr);
  target_pool_index_ = SimulatorBytecode::DecodeD(call_instr);
}

NativeCallPattern::NativeCallPattern(uword pc, const Code& code)
    : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
      end_(pc),
      native_function_pool_index_(-1),
      trampoline_pool_index_(-1) {
  ASSERT(code.ContainsInstructionAt(end_));
  const uword call_pc = end_ - sizeof(Instr);
  Instr call_instr = SimulatorBytecode::At(call_pc);
  ASSERT(SimulatorBytecode::DecodeOpcode(call_instr) ==
         SimulatorBytecode::kNativeCall);
  native_function_pool_index_ = SimulatorBytecode::DecodeB(call_instr);
  trampoline_pool_index_ = SimulatorBytecode::DecodeA(call_instr);
}

NativeFunctionWrapper NativeCallPattern::target() const {
  return reinterpret_cast<NativeFunctionWrapper>(
      object_pool_.ObjectAt(trampoline_pool_index_));
}

void NativeCallPattern::set_target(NativeFunctionWrapper new_target) const {
  object_pool_.SetRawValueAt(trampoline_pool_index_,
                             reinterpret_cast<uword>(new_target));
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

RawObject* CallPattern::Data() const {
  return object_pool_.ObjectAt(data_pool_index_);
}

void CallPattern::SetData(const Object& data) const {
  object_pool_.SetObjectAt(data_pool_index_, data);
}

RawCode* CallPattern::TargetCode() const {
  return reinterpret_cast<RawCode*>(object_pool_.ObjectAt(target_pool_index_));
}

void CallPattern::SetTargetCode(const Code& target) const {
  object_pool_.SetObjectAt(target_pool_index_, target);
}

void CallPattern::InsertDeoptCallAt(uword pc) {
  const uint8_t argc =
      SimulatorBytecode::IsCallOpcode(SimulatorBytecode::At(pc))
          ? SimulatorBytecode::DecodeArgc(SimulatorBytecode::At(pc))
          : 0;
  *reinterpret_cast<Instr*>(pc) =
      SimulatorBytecode::Encode(SimulatorBytecode::kDeopt, argc, 0);
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
