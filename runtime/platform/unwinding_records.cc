// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/unwinding_records.h"
#include "platform/globals.h"

#if !defined(DART_HOST_OS_WINDOWS) ||                                          \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

namespace dart {

void UnwindingRecordsPlatform::Init() {}
void UnwindingRecordsPlatform::Cleanup() {}
void UnwindingRecordsPlatform::RegisterExecutableMemory(
    void* start,
    intptr_t size,
    void** pp_dynamic_table) {}
void UnwindingRecordsPlatform::UnregisterDynamicTable(void* p_dynamic_table) {}
intptr_t UnwindingRecordsPlatform::SizeInBytes() {
  return 0;
}

}  // namespace dart

#endif  // !defined(DART_HOST_OS_WINDOWS) || !defined(TARGET_ARCH_X64)
