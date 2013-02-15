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
class ICData;
class RawArray;
class RawICData;
class String;

class CodePatcher : public AllStatic {
 public:
  // Dart static calls have a distinct, machine-dependent code pattern.

  // Patch static call before return_address in given code to the new target.
  static void PatchStaticCallAt(uword return_address,
                                const Code& code,
                                uword new_target_address);

  // Patch instance call before return_address in given code to the new target.
  static void PatchInstanceCallAt(uword return_address,
                                  const Code& code,
                                  uword new_target_address);

  // Patch entry point with a jump as specified in the code's patch region.
  static void PatchEntry(const Code& code);

  // Restore entry point with original code (i.e., before patching).
  static void RestoreEntry(const Code& code);

  // Returns true if the code can be patched with a jump at beginnning (checks
  // that there are no conflicts with object pointers). Used in ASSERTs.
  static bool CodeIsPatchable(const Code& code);

  // Return the target address of the static call before return_address
  // in given code.
  static uword GetStaticCallTargetAt(uword return_address, const Code& code);

  // Get instance call information.  Returns the call target and sets each
  // of the output parameters ic_data and arguments_descriptor if they are
  // non-NULL.
  static uword GetInstanceCallAt(uword return_address,
                                 const Code& code,
                                 ICData* ic_data,
                                 Array* arguments_descriptor);

  static intptr_t InstanceCallSizeInBytes();

  static void InsertCallAt(uword start, uword target);
};

}  // namespace dart

#endif  // VM_CODE_PATCHER_H_
