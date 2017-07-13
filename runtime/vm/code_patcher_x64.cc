// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/assembler.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/flow_graph_compiler.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

static bool MatchesPattern(uword addr, int16_t* pattern, intptr_t size) {
  uint8_t* bytes = reinterpret_cast<uint8_t*>(addr);
  for (intptr_t i = 0; i < size; i++) {
    int16_t val = pattern[i];
    if ((val >= 0) && (val != bytes[i])) {
      return false;
    }
  }
  return true;
}

intptr_t IndexFromPPLoad(uword start) {
  int32_t offset = *reinterpret_cast<int32_t*>(start);
  return ObjectPool::IndexFromOffset(offset);
}

intptr_t IndexFromPPLoadDisp8(uword start) {
  int8_t offset = *reinterpret_cast<int8_t*>(start);
  return ObjectPool::IndexFromOffset(offset);
}

class UnoptimizedCall : public ValueObject {
 public:
  UnoptimizedCall(uword return_address, const Code& code)
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        start_(return_address - kCallPatternSize) {
    ASSERT((kCallPatternSize - 7) == Assembler::kCallExternalLabelSize);
    ASSERT(IsValid());
  }

  static const int kCallPatternSize = 22;

  bool IsValid() const {
    static int16_t pattern[kCallPatternSize] = {
        0x49, 0x8b, 0x9f, -1,   -1,   -1, -1,  // movq RBX, [PP + offs]
        0x4d, 0x8b, 0xa7, -1,   -1,   -1, -1,  // movq CR, [PP + offs]
        0x4d, 0x8b, 0x5c, 0x24, 0x07,  // movq TMP, [CR + entry_point_offs]
        0x41, 0xff, 0xd3               // callq TMP
    };
    return MatchesPattern(start_, pattern, kCallPatternSize);
  }

  intptr_t argument_index() const { return IndexFromPPLoad(start_ + 3); }

  RawObject* ic_data() const { return object_pool_.ObjectAt(argument_index()); }

  RawCode* target() const {
    intptr_t index = IndexFromPPLoad(start_ + 10);
    Code& code = Code::Handle();
    code ^= object_pool_.ObjectAt(index);
    return code.raw();
  }

  void set_target(const Code& target) const {
    intptr_t index = IndexFromPPLoad(start_ + 10);
    object_pool_.SetObjectAt(index, target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  const ObjectPool& object_pool_;

 private:
  uword start_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedCall);
};

class NativeCall : public UnoptimizedCall {
 public:
  NativeCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {}

  NativeFunction native_function() const {
    return reinterpret_cast<NativeFunction>(
        object_pool_.RawValueAt(argument_index()));
  }

  void set_native_function(NativeFunction func) const {
    object_pool_.SetRawValueAt(argument_index(), reinterpret_cast<uword>(func));
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(NativeCall);
};

class InstanceCall : public UnoptimizedCall {
 public:
  InstanceCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {
#if defined(DEBUG)
    ICData& test_ic_data = ICData::Handle();
    test_ic_data ^= ic_data();
    ASSERT(test_ic_data.NumArgsTested() > 0);
#endif  // DEBUG
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCall);
};

class UnoptimizedStaticCall : public UnoptimizedCall {
 public:
  UnoptimizedStaticCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {
#if defined(DEBUG)
    ICData& test_ic_data = ICData::Handle();
    test_ic_data ^= ic_data();
    ASSERT(test_ic_data.NumArgsTested() >= 0);
#endif  // DEBUG
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedStaticCall);
};

// The expected pattern of a call where the target is loaded from
// the object pool.
class PoolPointerCall : public ValueObject {
 public:
  explicit PoolPointerCall(uword return_address, const Code& code)
      : start_(return_address - kCallPatternSize),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    ASSERT(IsValid());
  }

  static const int kCallPatternSize = 15;

  bool IsValid() const {
    static int16_t pattern[kCallPatternSize] = {
        0x4d, 0x8b, 0xa7, -1,   -1,   -1, -1,  // movq CR, [PP + offs]
        0x4d, 0x8b, 0x5c, 0x24, 0x07,  // movq TMP, [CR + entry_point_off]
        0x41, 0xff, 0xd3               // callq TMP
    };
    return MatchesPattern(start_, pattern, kCallPatternSize);
  }

  intptr_t pp_index() const { return IndexFromPPLoad(start_ + 3); }

  RawCode* Target() const {
    Code& code = Code::Handle();
    code ^= object_pool_.ObjectAt(pp_index());
    return code.raw();
  }

  void SetTarget(const Code& target) const {
    object_pool_.SetObjectAt(pp_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  uword start_;
  const ObjectPool& object_pool_;

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(PoolPointerCall);
};

// Instance call that can switch between a direct monomorphic call, an IC call,
// and a megamorphic call.
//   load guarded cid            load ICData             load MegamorphicCache
//   load monomorphic target <-> load ICLookup stub  ->  load MMLookup stub
//   call target.entry           call stub.entry         call stub.entry
class SwitchableCall : public ValueObject {
 public:
  SwitchableCall(uword return_address, const Code& code)
      : start_(return_address - kCallPatternSize),
        object_pool_(ObjectPool::Handle(code.GetObjectPool())) {
    ASSERT(IsValid());
  }

  static const int kCallPatternSize = 21;

  bool IsValid() const {
    static int16_t pattern[kCallPatternSize] = {
        0x4d, 0x8b, 0xa7, -1,   -1,   -1, -1,  // movq r12, [PP + code_offs]
        0x49, 0x8b, 0x4c, 0x24, 0x0f,  // movq rcx, [r12 + entrypoint_off]
        0x49, 0x8b, 0x9f, -1,   -1,   -1, -1,  // movq rbx, [PP + cache_offs]
        0xff, 0xd1,                            // call rcx
    };
    ASSERT(ARRAY_SIZE(pattern) == kCallPatternSize);
    return MatchesPattern(start_, pattern, kCallPatternSize);
  }

  intptr_t data_index() const { return IndexFromPPLoad(start_ + 15); }
  intptr_t target_index() const { return IndexFromPPLoad(start_ + 3); }

  RawObject* data() const { return object_pool_.ObjectAt(data_index()); }
  RawCode* target() const {
    return reinterpret_cast<RawCode*>(object_pool_.ObjectAt(target_index()));
  }

  void SetData(const Object& data) const {
    ASSERT(!Object::Handle(object_pool_.ObjectAt(data_index())).IsCode());
    object_pool_.SetObjectAt(data_index(), data);
    // No need to flush the instruction cache, since the code is not modified.
  }

  void SetTarget(const Code& target) const {
    ASSERT(Object::Handle(object_pool_.ObjectAt(target_index())).IsCode());
    object_pool_.SetObjectAt(target_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  uword start_;
  const ObjectPool& object_pool_;

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(SwitchableCall);
};

RawCode* CodePatcher::GetStaticCallTargetAt(uword return_address,
                                            const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  return call.Target();
}

void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    const Code& new_target) {
  PatchPoolPointerCallAt(return_address, code, new_target);
}

void CodePatcher::PatchPoolPointerCallAt(uword return_address,
                                         const Code& code,
                                         const Code& new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  PoolPointerCall call(return_address, code);
  call.SetTarget(new_target);
}

RawCode* CodePatcher::GetInstanceCallAt(uword return_address,
                                        const Code& code,
                                        ICData* ic_data) {
  ASSERT(code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, code);
  if (ic_data != NULL) {
    *ic_data ^= call.ic_data();
  }
  return call.target();
}

intptr_t CodePatcher::InstanceCallSizeInBytes() {
  return InstanceCall::kCallPatternSize;
}

void CodePatcher::InsertDeoptimizationCallAt(uword start) {
  UNREACHABLE();
}

RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                     const Code& code,
                                                     ICData* ic_data_result) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UnoptimizedStaticCall static_call(return_address, code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.ic_data();
  if (ic_data_result != NULL) {
    *ic_data_result = ic_data.raw();
  }
  return ic_data.GetTargetAt(0);
}

void CodePatcher::PatchSwitchableCallAt(uword return_address,
                                        const Code& caller_code,
                                        const Object& data,
                                        const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCall call(return_address, caller_code);
  call.SetData(data);
  call.SetTarget(target);
}

RawCode* CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCall call(return_address, caller_code);
  return call.target();
}

RawObject* CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                                const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  SwitchableCall call(return_address, caller_code);
  return call.data();
}

void CodePatcher::PatchNativeCallAt(uword return_address,
                                    const Code& code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCall call(return_address, code);
  call.set_target(trampoline);
  call.set_native_function(target);
}

RawCode* CodePatcher::GetNativeCallAt(uword return_address,
                                      const Code& code,
                                      NativeFunction* target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  NativeCall call(return_address, code);
  *target = call.native_function();
  return call.target();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
