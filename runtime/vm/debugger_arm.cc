// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM)

#include "vm/debugger.h"

namespace dart {

RawInstance* ActivationFrame::GetLocalVarValue(intptr_t slot_index) {
  UNIMPLEMENTED();
  return NULL;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
