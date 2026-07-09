// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for patching compiled code.

#ifndef RUNTIME_VM_CODE_PATCHER_H_
#define RUNTIME_VM_CODE_PATCHER_H_

#include "vm/allocation.h"
#include "vm/native_entry.h"

namespace dart {

// Forward declaration.
class Code;
class ICData;

#if defined(TARGET_ARCH_IA32)
// Stack-allocated class to create a scope where the specified region
// [address, address + size] has write access enabled. This is used
// when patching generated code. Access is reset to read-execute in
// the destructor of this scope.
// Dual mapping of instructions pages is not supported on these target arch.
class WritableInstructionsScope : public ValueObject {
 public:
  WritableInstructionsScope(uword address, intptr_t size);
  ~WritableInstructionsScope();

 private:
  const uword address_;
  const intptr_t size_;
};
#endif  // defined(TARGET_ARCH_IA32)

class CodePatcher : public AllStatic {
 public:
  // Dart static calls have a distinct, machine-dependent code pattern.

  // Patch static call before return_address in given code to the new target.
  static void PatchStaticCallAt(uword return_address,
                                const Code& code,
                                const Code& new_target);

  // Return the target address of the static call before return_address
  // in given code.
  static CodePtr GetStaticCallTargetAt(uword return_address, const Code& code);

  // Get instance call information. Returns the call target and sets the output
  // parameter data if non-null.
  static CodePtr GetInstanceCallAt(uword return_address,
                                   const Code& caller_code,
                                   Object* data);

  // Change the state of an instance call by patching the corresponding object
  // pool entries (non-IA32) or instructions (IA32).
  static void PatchInstanceCallAt(uword return_address,
                                  const Code& caller_code,
                                  const Object& data,
                                  const Code& target);
  static void PatchInstanceCallAtWithMutatorsStopped(Thread* thread,
                                                     uword return_address,
                                                     const Code& caller_code,
                                                     const Object& data,
                                                     const Code& target);

  // Return target of an unoptimized static call and its ICData object
  // (calls target via a stub).
  static FunctionPtr GetUnoptimizedStaticCallAt(uword return_address,
                                                const Code& code,
                                                ICData* ic_data);

  static void PatchPoolPointerCallAt(uword return_address,
                                     const Code& code,
                                     const Code& new_target);

  static void PatchSwitchableCallAt(uword return_address,
                                    const Code& caller_code,
                                    const Object& data,
                                    const Code& target);
  static ObjectPtr GetSwitchableCallDataAt(uword return_address,
                                           const Code& caller_code);
  static uword GetSwitchableCallTargetEntryAt(uword return_address,
                                              const Code& caller_code);

  static CodePtr GetNativeCallAt(uword return_address,
                                 const Code& caller_code,
                                 NativeFunction* target);

  static void PatchNativeCallAt(uword return_address,
                                const Code& caller_code,
                                NativeFunction target,
                                const Code& trampoline);

  static intptr_t GetSubtypeTestCachePoolIndex(uword return_address);
};

#if !defined(PRODUCT) && defined(DART_DYNAMIC_MODULES)
class BytecodePatcher : public AllStatic {
 public:
  // Patch call instruction prior to return_address to add a breakpoint.
  // Returns the original opcode of the patched instruction.
  static uint32_t AddBreakpointAt(uword return_address,
                                  const Bytecode& bytecode);

  // Patch call instruction prior to return_address to remove a breakpoint.
  // Replaces the breakpoint instruction opcode with the provided opcode.
  static void RemoveBreakpointAt(uword return_address,
                                 const Bytecode& code,
                                 uint32_t opcode);

 private:
  static uint32_t AddBreakpointAtWithMutatorsStopped(Thread* thread,
                                                     uword return_address,
                                                     const Bytecode& bytecode);

  static void RemoveBreakpointAtWithMutatorsStopped(Thread* thread,
                                                    uword return_address,
                                                    const Bytecode& bytecode,
                                                    uint32_t opcode);
};
#endif  // !defined(PRODUCT) && defined(DART_DYNAMIC_MODULES)

// Beginning from [end - size] we compare [size] bytes with [pattern]. All
// [0..255] values in [pattern] have to match, negative values are skipped.
//
// Example pattern: `[0x3d, 0x8b, -1, -1]`.
bool MatchesPattern(uword end, const int16_t* pattern, intptr_t size);

}  // namespace dart

#endif  // RUNTIME_VM_CODE_PATCHER_H_
