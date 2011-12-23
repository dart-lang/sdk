// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_IA32)

#include "vm/debugger.h"

#include "vm/code_patcher.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

// TODO(hausner): Handle captured variables.
RawInstance* ActivationFrame::GetLocalVarValue(intptr_t slot_index) {
  uword var_address = fp() + slot_index * kWordSize;
  return reinterpret_cast<RawInstance*>(
             *reinterpret_cast<uword*>(var_address));
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
