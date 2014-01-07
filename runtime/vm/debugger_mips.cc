// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_MIPS)

#include "vm/cpu.h"
#include "vm/debugger.h"
#include "vm/instructions.h"
#include "vm/stub_code.h"

namespace dart {

RawInstance* ActivationFrame::GetInstanceCallReceiver(
                 intptr_t num_actual_args) {
  ASSERT(num_actual_args > 0);  // At minimum we have a receiver on the stack.
  // Stack pointer points to last argument that was pushed on the stack.
  uword receiver_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(receiver_addr));
}


RawObject* ActivationFrame::GetClosureObject(intptr_t num_actual_args) {
  // At a minimum we have the closure object on the stack.
  ASSERT(num_actual_args > 0);
  // Stack pointer points to last argument that was pushed on the stack.
  uword closure_addr = sp() + ((num_actual_args - 1) * kWordSize);
  return reinterpret_cast<RawObject*>(
             *reinterpret_cast<uword*>(closure_addr));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
