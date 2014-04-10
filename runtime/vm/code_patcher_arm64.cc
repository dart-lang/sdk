// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_ARM64.
#if defined(TARGET_ARCH_ARM64)

#include "vm/code_patcher.h"

#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

RawArray* CodePatcher::GetClosureArgDescAt(uword return_address,
                                           const Code& code) {
  UNIMPLEMENTED();
  return NULL;
}


uword CodePatcher::GetStaticCallTargetAt(uword return_address,
                                         const Code& code) {
  UNIMPLEMENTED();
  return 0;
}


void CodePatcher::PatchStaticCallAt(uword return_address,
                                    const Code& code,
                                    uword new_target) {
  UNIMPLEMENTED();
}


void CodePatcher::PatchInstanceCallAt(uword return_address,
                                      const Code& code,
                                      uword new_target) {
  UNIMPLEMENTED();
}


int32_t CodePatcher::GetPoolOffsetAt(uword return_address) {
  UNIMPLEMENTED();
  return 0;
}


void CodePatcher::SetPoolOffsetAt(uword return_address, int32_t offset) {
  UNIMPLEMENTED();
}


void CodePatcher::InsertCallAt(uword start, uword target) {
  UNIMPLEMENTED();
}


uword CodePatcher::GetInstanceCallAt(uword return_address,
                                     const Code& code,
                                     ICData* ic_data) {
  UNIMPLEMENTED();
  return 0;
}


intptr_t CodePatcher::InstanceCallSizeInBytes() {
  // The instance call instruction sequence has a variable size on ARM.
  UNREACHABLE();
  return 0;
}


RawFunction* CodePatcher::GetUnoptimizedStaticCallAt(
    uword return_address, const Code& code, ICData* ic_data_result) {
  UNIMPLEMENTED();
  return NULL;
}


RawObject* CodePatcher::GetEdgeCounterAt(uword pc, const Code& code) {
  UNIMPLEMENTED();
  return NULL;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
