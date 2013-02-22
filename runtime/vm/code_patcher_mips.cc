// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/code_patcher.h"

#include "vm/object.h"

namespace dart {

uword CodePatcher::GetStaticCallTargetAt(uword return_address,
                                         const Code& code) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UNIMPLEMENTED();
  return 0;
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UNIMPLEMENTED();
}


void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UNIMPLEMENTED();
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  UNIMPLEMENTED();
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     const Code& code,
                                     ICData* ic_data,
                                     Array* arguments_descriptor) {
  ASSERT(code.ContainsInstructionAt(return_address));
  UNIMPLEMENTED();
  return 0;
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  UNIMPLEMENTED();
  return 0;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
