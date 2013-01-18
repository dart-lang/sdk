// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/code_patcher.h"

namespace dart {

uword CodePatcher::GetStaticCallTargetAt(uword return_address) {
  UNIMPLEMENTED();
  return 0;
}


void CodePatcher::PatchStaticCallAt(uword return_address, uword new_target) {
  UNIMPLEMENTED();
}


void CodePatcher::PatchInstanceCallAt(uword return_address, uword new_target) {
  UNIMPLEMENTED();
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  UNIMPLEMENTED();
}


bool CodePatcher::IsDartCall(uword return_address) {
  UNIMPLEMENTED();
  return false;
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     ICData* ic_data,
                                     Array* arguments_descriptor) {
  UNIMPLEMENTED();
  return 0;
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  UNIMPLEMENTED();
  return 0;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
