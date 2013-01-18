// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/debugger.h"

namespace dart {

RawInstance* ActivationFrame::GetLocalVarValue(intptr_t slot_index) {
  UNIMPLEMENTED();
  return NULL;
}


RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  UNIMPLEMENTED();
  return NULL;
}


void CodeBreakpoint::PatchFunctionReturn() {
  UNIMPLEMENTED();
}


void CodeBreakpoint::RestoreFunctionReturn() {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
