// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/code_patcher.h"
#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  UNIMPLEMENTED();
  return NULL;
}


RawObject* ActivationFrame::GetClosureObject(intptr_t num_actual_args) {
  UNIMPLEMENTED();
  return NULL;
}


uword CodeBreakpoint::OrigStubAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void CodeBreakpoint::PatchCode() {
  UNIMPLEMENTED();
}


void CodeBreakpoint::RestoreCode() {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
