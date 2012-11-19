// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for patching compiled code.

#ifndef VM_CODE_PATCHER_H_
#define VM_CODE_PATCHER_H_

#include "vm/allocation.h"

namespace dart {

// Forward declaration.
class Array;
class Code;
class ExternalLabel;
class Function;
class RawArray;
class RawICData;
class String;

class CodePatcher : public AllStatic {
 public:
  // Dart static calls have a distinct, machine-dependent code pattern.

  // Patch static call to the new target.
  static void PatchStaticCallAt(uword addr, uword new_target_address);

  // Patch instance call to the new target.
  static void PatchInstanceCallAt(uword addr, uword new_target_address);

  // Patch entry point with a jump as specified in the code's patch region.
  static void PatchEntry(const Code& code);

  // Restore entry point with original code (i.e., before patching).
  static void RestoreEntry(const Code& code);

  // Returns true if the code can be patched with a jump at beginnning (checks
  // that there are no conflicts with object pointers). Used in ASSERTs.
  static bool CodeIsPatchable(const Code& code);

  // Returns true if the code before return_address is a static
  // or dynamic Dart call.
  static bool IsDartCall(uword return_address);

  static uword GetStaticCallTargetAt(uword return_address);

  // Get instance call information.
  static void GetInstanceCallAt(uword return_address,
                                String* function_name,
                                int* num_arguments,
                                int* num_named_arguments,
                                uword* target);

  static RawICData* GetInstanceCallIcDataAt(uword return_address);

  static intptr_t InstanceCallSizeInBytes();

  static void InsertCallAt(uword start, uword target);
};

}  // namespace dart

#endif  // VM_CODE_PATCHER_H_
