// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/code_patcher.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

class UnoptimizedCall : public ValueObject {
 public:
  UnoptimizedCall(uword return_address, const Code& code)
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        code_index_(-1),
        argument_index_(-1) {
    uword pc = return_address;

    // callq [CODE_REG + entry_point_offset]
    static int16_t call_pattern[] = {
        0x41, 0xff, 0x54, 0x24, -1,
    };
    if (MatchesPattern(pc, call_pattern, ARRAY_SIZE(call_pattern))) {
      pc -= ARRAY_SIZE(call_pattern);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }

    // movq CODE_REG, [PP + offset]
    static int16_t load_code_disp8[] = {
        0x4d, 0x8b, 0x67, -1,  //
    };
    static int16_t load_code_disp32[] = {
        0x4d, 0x8b, 0xa7, -1, -1, -1, -1,
    };
    if (MatchesPattern(pc, load_code_disp8, ARRAY_SIZE(load_code_disp8))) {
      pc -= ARRAY_SIZE(load_code_disp8);
      code_index_ = IndexFromPPLoadDisp8(pc + 3);
    } else if (MatchesPattern(pc, load_code_disp32,
                              ARRAY_SIZE(load_code_disp32))) {
      pc -= ARRAY_SIZE(load_code_disp32);
      code_index_ = IndexFromPPLoadDisp32(pc + 3);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }
    ASSERT(Object::Handle(object_pool_.ObjectAt(code_index_)).IsCode());

    // movq RBX, [PP + offset]
    static int16_t load_argument_disp8[] = {
        0x49, 0x8b, 0x5f, -1,  //
    };
    static int16_t load_argument_disp32[] = {
        0x49, 0x8b, 0x9f, -1, -1, -1, -1,
    };
    if (MatchesPattern(pc, load_argument_disp8,
                       ARRAY_SIZE(load_argument_disp8))) {
      pc -= ARRAY_SIZE(load_argument_disp8);
      argument_index_ = IndexFromPPLoadDisp8(pc + 3);
    } else if (MatchesPattern(pc, load_argument_disp32,
                              ARRAY_SIZE(load_argument_disp32))) {
      pc -= ARRAY_SIZE(load_argument_disp32);
      argument_index_ = IndexFromPPLoadDisp32(pc + 3);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }
  }

  intptr_t argument_index() const { return argument_index_; }

  RawObject* ic_data() const { return object_pool_.ObjectAt(argument_index()); }

  RawCode* target() const {
    Code& code = Code::Handle();
    code ^= object_pool_.ObjectAt(code_index_);
    return code.raw();
  }

  void set_target(const Code& target) const {
    object_pool_.SetObjectAt(code_index_, target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  const ObjectPool& object_pool_;
  intptr_t code_index_;
  intptr_t argument_index_;

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
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        code_index_(-1) {
    uword pc = return_address;

    // callq [CODE_REG + entry_point_offset]
    static int16_t call_pattern[] = {
        0x41, 0xff, 0x54, 0x24, -1,
    };
    if (MatchesPattern(pc, call_pattern, ARRAY_SIZE(call_pattern))) {
      pc -= ARRAY_SIZE(call_pattern);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }

    // movq CODE_REG, [PP + offset]
    static int16_t load_code_disp8[] = {
        0x4d, 0x8b, 0x67, -1,  //
    };
    static int16_t load_code_disp32[] = {
        0x4d, 0x8b, 0xa7, -1, -1, -1, -1,
    };
    if (MatchesPattern(pc, load_code_disp8, ARRAY_SIZE(load_code_disp8))) {
      pc -= ARRAY_SIZE(load_code_disp8);
      code_index_ = IndexFromPPLoadDisp8(pc + 3);
    } else if (MatchesPattern(pc, load_code_disp32,
                              ARRAY_SIZE(load_code_disp32))) {
      pc -= ARRAY_SIZE(load_code_disp32);
      code_index_ = IndexFromPPLoadDisp32(pc + 3);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }
    ASSERT(Object::Handle(object_pool_.ObjectAt(code_index_)).IsCode());
  }

  RawCode* Target() const {
    Code& code = Code::Handle();
    code ^= object_pool_.ObjectAt(code_index_);
    return code.raw();
  }

  void SetTarget(const Code& target) const {
    object_pool_.SetObjectAt(code_index_, target);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  const ObjectPool& object_pool_;
  intptr_t code_index_;

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
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        target_index_(-1),
        data_index_(-1) {
    uword pc = return_address;

    // callq RCX
    static int16_t call_pattern[] = {
        0xff, 0xd1,  //
    };
    if (MatchesPattern(pc, call_pattern, ARRAY_SIZE(call_pattern))) {
      pc -= ARRAY_SIZE(call_pattern);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }

    // movq RBX, [PP + offset]
    static int16_t load_data_disp8[] = {
        0x49, 0x8b, 0x5f, -1,  //
    };
    static int16_t load_data_disp32[] = {
        0x49, 0x8b, 0x9f, -1, -1, -1, -1,
    };
    if (MatchesPattern(pc, load_data_disp8, ARRAY_SIZE(load_data_disp8))) {
      pc -= ARRAY_SIZE(load_data_disp8);
      data_index_ = IndexFromPPLoadDisp8(pc + 3);
    } else if (MatchesPattern(pc, load_data_disp32,
                              ARRAY_SIZE(load_data_disp32))) {
      pc -= ARRAY_SIZE(load_data_disp32);
      data_index_ = IndexFromPPLoadDisp32(pc + 3);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }
    ASSERT(!Object::Handle(object_pool_.ObjectAt(data_index_)).IsCode());

    // movq rcx, [CODE_REG + entrypoint_offset]
    static int16_t load_entry_pattern[] = {
        0x49, 0x8b, 0x4c, 0x24, -1,
    };
    if (MatchesPattern(pc, load_entry_pattern,
                       ARRAY_SIZE(load_entry_pattern))) {
      pc -= ARRAY_SIZE(load_entry_pattern);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }

    // movq CODE_REG, [PP + offset]
    static int16_t load_code_disp8[] = {
        0x4d, 0x8b, 0x67, -1,  //
    };
    static int16_t load_code_disp32[] = {
        0x4d, 0x8b, 0xa7, -1, -1, -1, -1,
    };
    if (MatchesPattern(pc, load_code_disp8, ARRAY_SIZE(load_code_disp8))) {
      pc -= ARRAY_SIZE(load_code_disp8);
      target_index_ = IndexFromPPLoadDisp8(pc + 3);
    } else if (MatchesPattern(pc, load_code_disp32,
                              ARRAY_SIZE(load_code_disp32))) {
      pc -= ARRAY_SIZE(load_code_disp32);
      target_index_ = IndexFromPPLoadDisp32(pc + 3);
    } else {
      FATAL1("Failed to decode at %" Px, pc);
    }
    ASSERT(Object::Handle(object_pool_.ObjectAt(target_index_)).IsCode());
  }

  intptr_t data_index() const { return data_index_; }
  intptr_t target_index() const { return target_index_; }

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
  const ObjectPool& object_pool_;
  intptr_t target_index_;
  intptr_t data_index_;

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
