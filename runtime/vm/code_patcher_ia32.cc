// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "platform/unaligned.h"
#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/instructions.h"
#include "vm/object.h"
#include "vm/raw_object.h"

namespace dart {

// The expected pattern of a Dart unoptimized call (static and instance):
//  mov ECX, ic-data
//  mov EDI, target-code-object
//  call target_address (stub)
//  <- return address
class UnoptimizedCall : public ValueObject {
 public:
  UnoptimizedCall(uword return_address, const Code& code)
      : code_(code), start_(return_address - kPatternSize) {
    ASSERT(IsValid());
  }

  ObjectPtr ic_data() const {
    return LoadUnaligned(reinterpret_cast<ObjectPtr*>(start_ + 1));
  }

  static constexpr int kMovInstructionSize = 5;
  static constexpr int kCallInstructionSize = 3;
  static constexpr int kPatternSize =
      2 * kMovInstructionSize + kCallInstructionSize;

 private:
  bool IsValid() {
    uint8_t* code_bytes = reinterpret_cast<uint8_t*>(start_);
    return (code_bytes[0] == 0xB9) &&
           (code_bytes[2 * kMovInstructionSize] == 0xFF);
  }

  uword return_address() const { return start_ + kPatternSize; }

  uword call_address() const { return start_ + 2 * kMovInstructionSize; }

 protected:
  const Code& code_;
  uword start_;

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(UnoptimizedCall);
};

class NativeCall : public UnoptimizedCall {
 public:
  NativeCall(uword return_address, const Code& code)
      : UnoptimizedCall(return_address, code) {}

  NativeFunction native_function() const {
    return LoadUnaligned(reinterpret_cast<NativeFunction*>(start_ + 1));
  }

  void set_native_function(NativeFunction func) const {
    Thread::Current()->isolate_group()->RunWithStoppedMutators([&]() {
      WritableInstructionsScope writable(start_ + 1, sizeof(func));
      StoreUnaligned(reinterpret_cast<NativeFunction*>(start_ + 1), func);
    });
  }

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(NativeCall);
};

// b9xxxxxxxx  mov ecx,<data>
// bfyyyyyyyy  mov edi,<target>
// ff5707      call [edi+<monomorphic-entry-offset>]
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

  ObjectPtr data() const {
    return LoadUnaligned(reinterpret_cast<ObjectPtr*>(start_ + 1));
  }
  void set_data(const Object& data) const {
    // N.B. The pointer is embedded in the Instructions object, but visited
    // through the Code object.
    code_.StorePointerUnaligned(reinterpret_cast<ObjectPtr*>(start_ + 1),
                                data.ptr(), Thread::Current());
  }

  CodePtr target() const {
    return LoadUnaligned(reinterpret_cast<CodePtr*>(start_ + 6));
  }
  void set_target(const Code& target) const {
    // N.B. The pointer is embedded in the Instructions object, but visited
    // through the Code object.
    code_.StorePointerUnaligned(reinterpret_cast<CodePtr*>(start_ + 6),
                                target.ptr(), Thread::Current());
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

// The expected pattern of a dart static call:
//  mov EDX, arguments_descriptor_array (optional in polymorphic calls)
//  mov EDI, Immediate(code_object)
//  call [EDI + entry_point_offset]
//  <- return address
class StaticCall : public ValueObject {
 public:
  StaticCall(uword return_address, const Code& code)
      : code_(code),
        start_(return_address - (kMovInstructionSize + kCallInstructionSize)) {
    ASSERT(IsValid());
  }

  bool IsValid() {
    uint8_t* code_bytes = reinterpret_cast<uint8_t*>(start_);
    return (code_bytes[0] == 0xBF) && (code_bytes[5] == 0xFF);
  }

  CodePtr target() const {
    return LoadUnaligned(reinterpret_cast<CodePtr*>(start_ + 1));
  }

  void set_target(const Code& target) const {
    // N.B. The pointer is embedded in the Instructions object, but visited
    // through the Code object.
    code_.StorePointerUnaligned(reinterpret_cast<CodePtr*>(start_ + 1),
                                target.ptr(), Thread::Current());
  }

  static constexpr int kMovInstructionSize = 5;
  static constexpr int kCallInstructionSize = 3;

 private:
  uword return_address() const {
    return start_ + kMovInstructionSize + kCallInstructionSize;
  }

  uword call_address() const { return start_ + kMovInstructionSize; }

  const Code& code_;
  uword start_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StaticCall);
};

CodePtr CodePatcher::GetStaticCallTargetAt(uword return_address,
                                           const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  StaticCall call(return_address, code);
  return call.target();
}

void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    const Code& new_target) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  const Instructions& instrs = Instructions::Handle(zone, code.instructions());
  thread->isolate_group()->RunWithStoppedMutators([&]() {
    WritableInstructionsScope writable(instrs.WritablePayloadStart(),
                                       instrs.Size());
    ASSERT(code.ContainsInstructionAt(return_address));
    StaticCall call(return_address, code);
    call.set_target(new_target);
  });
}

CodePtr CodePatcher::GetInstanceCallAt(uword return_address,
                                       const Code& caller_code,
                                       Object* data) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  InstanceCall call(return_address, caller_code);
  if (data != nullptr) {
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
  auto zone = thread->zone();
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  const Instructions& instrs =
      Instructions::Handle(zone, caller_code.instructions());
  WritableInstructionsScope writable(instrs.WritablePayloadStart(),
                                     instrs.Size());
  InstanceCall call(return_address, caller_code);
  call.set_data(data);
  call.set_target(target);
}

FunctionPtr CodePatcher::GetUnoptimizedStaticCallAt(uword return_address,
                                                    const Code& caller_code,
                                                    ICData* ic_data_result) {
  ASSERT(caller_code.ContainsInstructionAt(return_address));
  UnoptimizedStaticCall static_call(return_address, caller_code);
  ICData& ic_data = ICData::Handle();
  ic_data ^= static_call.ic_data();
  if (ic_data_result != nullptr) {
    *ic_data_result = ic_data.ptr();
  }
  return ic_data.GetTargetAt(0);
}

void CodePatcher::PatchSwitchableCallAt(uword return_address,
                                        const Code& caller_code,
                                        const Object& data,
                                        const Code& target) {
  PatchInstanceCallAt(return_address, caller_code, data, target);
}

ObjectPtr CodePatcher::GetSwitchableCallTargetAt(uword return_address,
                                                 const Code& caller_code) {
  InstanceCall call(return_address, caller_code);
  return call.target();
}

uword CodePatcher::GetSwitchableCallTargetEntryAt(uword return_address,
                                                  const Code& caller_code) {
  // Switchable instance calls only generated for precompilation.
  UNREACHABLE();
  return 0;
}

ObjectPtr CodePatcher::GetSwitchableCallDataAt(uword return_address,
                                               const Code& caller_code) {
  InstanceCall call(return_address, caller_code);
  return call.data();
}

void CodePatcher::PatchNativeCallAt(uword return_address,
                                    const Code& caller_code,
                                    NativeFunction target,
                                    const Code& trampoline) {
  UNREACHABLE();
}

CodePtr CodePatcher::GetNativeCallAt(uword return_address,
                                     const Code& caller_code,
                                     NativeFunction* target) {
  UNREACHABLE();
  return nullptr;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
