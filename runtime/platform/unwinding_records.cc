// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unwinding_records.h"
#include "platform/globals.h"

namespace dart {

#if (!defined(DART_TARGET_OS_WINDOWS) && !defined(DART_HOST_OS_WINDOWS)) ||    \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

intptr_t UnwindingRecordsPlatform::SizeInBytes() {
  return 0;
}

#endif  // (!defined(DART_TARGET_OS_WINDOWS) && !defined(DART_HOST_OS_WINDOWS))

#if !defined(DART_HOST_OS_WINDOWS) ||                                          \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

void UnwindingRecordsPlatform::RegisterExecutableMemory(
    void* start,
    intptr_t size,
    void** pp_dynamic_table) {}
void UnwindingRecordsPlatform::UnregisterDynamicTable(void* p_dynamic_table) {}

#endif  // !defined(DART_HOST_OS_WINDOWS) ...

}  // namespace dart
