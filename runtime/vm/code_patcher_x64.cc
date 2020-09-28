// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/raw_object.h"
#include "vm/reverse_pc_lookup_cache.h"

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

  CodePtr target() const {
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
    Object& test_data = Object::Handle(data());
    ASSERT(test_data.IsArray() || test_data.IsICData() ||
           test_data.IsMegamorphicCache());
    if (test_data.IsICData()) {
      ASSERT(ICData::Cast(test_data).NumArgsTested() > 0);
    }
#endif  // DEBUG
  }

  ObjectPtr data() const { return object_pool_.ObjectAt(argument_index()); }
  void set_data(const Object& data) const {
    ASSERT(data.IsArray() || data.IsICData() || data.IsMegamorphicCache());
    object_pool_.SetObjectAt(argument_index(), data);
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(InstanceCall);
};

class UnoptimizedStaticCall : public UnoptimizedCall {
 public:
  UnoptimizedStaticCall(uword return_address, const Code& caller_code)
      : UnoptimizedCall(return_address, caller_code) {
#if defined(DEBUG)
    ICData& test_ic_data = ICData::Handle();
    test_ic_data ^= ic_data();
    ASSERT(test_ic_data.NumArgsTested() >= 0);
#endif  // DEBUG
  }

  ObjectPtr ic_data() const { return object_pool_.ObjectAt(argument_index()); }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedStaticCall);
};

// The expected pattern of a call where the target is loaded from
// the object pool.
class PoolPointerCall : public ValueObject {
 public:
  explicit PoolPointerCall(uword return_address, const Code& caller_code)
      : object_pool_(ObjectPool::Handle(caller_code.GetObjectPool())),
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

  CodePtr Target() const {
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
class SwitchableCallBase : public ValueObject {
 public:
  explicit SwitchableCallBase(const Code& code)
      : object_pool_(ObjectPool::Handle(code.GetObjectPool())),
        target_index_(-1),
        data_index_(-1) {}

  intptr_t data_index() const { return data_index_; }
  intptr_t target_index() const { return target_index_; }

  ObjectPtr data() const { return object_pool_.ObjectAt(data_index()); }

  void SetData(const Object& data) const {
    ASSERT(!Object::Handle(object_pool_.ObjectAt(data_index())).IsCode());
    object_pool_.SetObjectAt(data_index(), data);
    // No need to flush the instruction cache, since the code is not modified.
  }

 protected:
  ObjectPool& object_pool_;
  intptr_t target_index_;
  intptr_t data_index_;

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(SwitchableCallBase);
};

// See [SwitchableCallBase] for a switchable calls in general.
//
// The target slot is always a [Code] object: Either the code of the
// monomorphic function or a stub code.
class SwitchableCall : public SwitchableCallBase {
 public:
  SwitchableCall(uword return_address, const Code& code)
      : SwitchableCallBase(code) {
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

  void SetTarget(const Code& target) const {
    ASSERT(Object::Handle(object_pool_.ObjectAt(target_index())).IsCode());
    object_pool_.SetObjectAt(target_index(), target);
    // No need to flush the instruction cache, since the code is not modified.
  }

  CodePtr target() const {
    return static_cast<CodePtr>(object_pool_.ObjectAt(target_index()));
  }
};

// See [SwitchableCallBase] for a switchable calls in general.
//
// The target slot is always a direct entrypoint address: Either the entry point
// of the monomorphic function or a stub entry point.
class BareSwitchableCall : public SwitchableCallBase {
 public:
  BareSwitchableCall(uword return_address, const Code& code)
      : SwitchableCallBase(code) {
    object_pool_ = ObjectPool::RawCast(
        Isolate::Current()->object_store()->global_object_pool());

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

    // movq RCX, [PP + offset]
    static int16_t load_code_disp8[] = {
        0x49, 0x8b, 0x4f, -1,  //
    };
    static int16_t load_code_disp32[] = {
        0x49, 0x8b, 0x8f, -1, -1, -1, -1,
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
    ASSERT(object_pool_.TypeAt(target_index_) ==
           ObjectPool::EntryType::kImmediate);
  }

  void SetTarget(const Code& target) const {
    ASSERT(object_pool_.TypeAt(target_index()) ==
           ObjectPool::EntryType::kImmediate);
    object_pool_.SetRawValueAt(target_index(), target.MonomorphicEntryPoint());
  }

  CodePtr target() const {
    const uword pc = object_pool_.RawValueAt(target_index());
    CodePtr result = ReversePc::Lookup(IsolateGroup::Current(), pc);
    if (result != Code::null()) {
      return result;
    }
    result = ReversePc::Lookup(Dart::vm_isolate()->group(), pc);
    if (result != Code::null()) {
      return result;
    }
    UNREACHABLE();
  }
};

CodePtr CodePatcher::GetStaticCallTargetAt(uword return_address,
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

CodePtr CodePatcher::GetInstanceCallAt(uword return_address,
                                       const Code& caller_code,
                                       Object* data) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, caller_code);
  if (data != NULL) {
    *data = call.data();
  }
  return call.target();
}

void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& caller_code,
                                      const Object& data,
                                      const Code& target) {
  auto thread = Thread::Current();
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    PatchInstanceCallAtWithMutatorsStopped(thread, return_address, caller_code,
                                           data, target);
  });
}

void CodePatcher::PatchInstanceCallAtWithMutatorsStopped(
    Thread* thread,
    uword return_address,
    const Code& caller_code,
    const Object& data,
    const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, caller_code);
  call.set_data(data);
  call.set_target(target);
}

void CodePatcher::InsertDeoptimizationCallAt(uword start) {
  UNREACHABLE();
}

FunctionPtr CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                    const Code& caller_code,
                                                    ICData* ic_data_result) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  UnoptimizedStaticCall static_call(return_address, caller_code);
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
  auto thread = Thread::Current();
  // Ensure all threads are suspended as we update data and target pair.
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    PatchSwitchableCallAtWithMutatorsStopped(thread, return_address,
                                             caller_code, data, target);
  });
}

void CodePatcher::PatchSwitchableCallAtWithMutatorsStopped(
    Thread* thread,
    uword return_address,
    const Code& caller_code,
    const Object& data,
    const Code& target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCall call(return_address, caller_code);
    call.SetData(data);
    call.SetTarget(target);
  } else {
    SwitchableCall call(return_address, caller_code);
    call.SetData(data);
    call.SetTarget(target);
  }
}

CodePtr CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                               const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCall call(return_address, caller_code);
    return call.target();
  } else {
    SwitchableCall call(return_address, caller_code);
    return call.target();
  }
}

ObjectPtr CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                               const Code& caller_code) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    BareSwitchableCall call(return_address, caller_code);
    return call.data();
  } else {
    SwitchableCall call(return_address, caller_code);
    return call.data();
  }
}

void CodePatcher::PatchNativeCallAt(uword return_address,
                                    const Code& caller_code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  Thread::Current()->isolate_group()->RunWithStoppedMutators([&]() {
    ASSERT(caller_code.ContainsInstructionAt(return_address));
    NativeCall call(return_address, caller_code);
    call.set_target(trampoline);
    call.set_native_function(target);
  });
}

CodePtr CodePatcher::GetNativeCallAt(uword return_address,
                                     const Code& caller_code,
                                     NativeFunction* target) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  NativeCall call(return_address, caller_code);
  *target = call.native_function();
  return call.target();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
