// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/malloc_hooks.h"

#include "vm/globals.h"

#if defined(HOST_ARCH_ARM64)

namespace dart {

const intptr_t kSkipCount = 5;

}  // namespace dart

#endif  // defined(HOST_ARCH_ARM64)
