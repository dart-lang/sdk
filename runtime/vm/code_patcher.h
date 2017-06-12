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
class Array;
class Code;
class ExternalLabel;
class Function;
class ICData;
class RawArray;
class RawCode;
class RawFunction;
class RawICData;
class RawObject;
class String;


// Stack-allocated class to create a scope where the specified region
// [address, address + size] has write access enabled. This is used
// when patching generated code. Access is reset to read-execute in
// the destructor of this scope.
class WritableInstructionsScope : public ValueObject {
 public:
  WritableInstructionsScope(uword address, intptr_t size);
  ~WritableInstructionsScope();

 private:
  const uword address_;
  const intptr_t size_;
};


class CodePatcher : public AllStatic {
 public:
  // Dart static calls have a distinct, machine-dependent code pattern.

  // Patch static call before return_address in given code to the new target.
  static void PatchStaticCallAt(uword return_address,
                                const Code& code,
                                const Code& new_target);

  // Return the target address of the static call before return_address
  // in given code.
  static RawCode* GetStaticCallTargetAt(uword return_address, const Code& code);

  // Get instance call information.  Returns the call target and sets each
  // of the output parameters ic_data and arguments_descriptor if they are
  // non-NULL.
  static RawCode* GetInstanceCallAt(uword return_address,
                                    const Code& code,
                                    ICData* ic_data);

  // Return target of an unoptimized static call and its ICData object
  // (calls target via a stub).
  static RawFunction* GetUnoptimizedStaticCallAt(uword return_address,
                                                 const Code& code,
                                                 ICData* ic_data);

  static intptr_t InstanceCallSizeInBytes();

  static void InsertDeoptimizationCallAt(uword start);

  static void PatchPoolPointerCallAt(uword return_address,
                                     const Code& code,
                                     const Code& new_target);

  static void PatchSwitchableCallAt(uword return_address,
                                    const Code& caller_code,
                                    const Object& data,
                                    const Code& target);
  static RawObject* GetSwitchableCallDataAt(uword return_address,
                                            const Code& caller_code);
  static RawCode* GetSwitchableCallTargetAt(uword return_address,
                                            const Code& caller_code);

  static RawCode* GetNativeCallAt(uword return_address,
                                  const Code& code,
                                  NativeFunction* target);

  static void PatchNativeCallAt(uword return_address,
                                const Code& code,
                                NativeFunction target,
                                const Code& trampoline);
};

}  // namespace dart

#endif  // RUNTIME_VM_CODE_PATCHER_H_
