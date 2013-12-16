// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "vm/atomic.h"

namespace dart {


uintptr_t AtomicOperations::FetchAndIncrement(uintptr_t* p) {
#if defined(TARGET_ARCH_X64)
  return static_cast<uintptr_t>(
      InterlockedIncrement64(reinterpret_cast<LONGLONG*>(p))) - 1;
#elif defined(TARGET_ARCH_IA32)
  return static_cast<uintptr_t>(
      InterlockedIncrement(reinterpret_cast<LONG*>(p))) - 1;
#else
  UNIMPLEMENTED();
#endif
}


}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
