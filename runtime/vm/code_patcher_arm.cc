// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM.
#if defined(TARGET_ARCH_ARM)

#include "vm/code_patcher.h"

namespace dart {

void CodePatcher::GetStaticCallAt(uword return_address,
                                  Function* function,
                                  uword* target) {
  UNIMPLEMENTED();
}


void CodePatcher::PatchStaticCallAt(uword return_address, uword new_target) {
  UNIMPLEMENTED();
}


void CodePatcher::PatchInstanceCallAt(uword return_address, uword new_target) {
  UNIMPLEMENTED();
}


bool CodePatcher::IsDartCall(uword return_address) {
  UNIMPLEMENTED();
  return false;
}


void CodePatcher::GetInstanceCallAt(uword return_address,
                                    String* function_name,
                                    int* num_arguments,
                                    int* num_named_arguments,
                                    uword* target) {
  UNIMPLEMENTED();
}


void CodePatcher::PatchEntry(const Code& code) {
  UNIMPLEMENTED();
}


void CodePatcher::RestoreEntry(const Code& code) {
  UNIMPLEMENTED();
}


bool CodePatcher::CodeIsPatchable(const Code& code) {
  UNIMPLEMENTED();
  return false;
}


RawICData* CodePatcher::GetInstanceCallIcDataAt(uword return_address) {
  UNIMPLEMENTED();
  return NULL;
}



void CodePatcher::InsertCallAt(uword start, uword target) {
  UNIMPLEMENTED();
}



}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
