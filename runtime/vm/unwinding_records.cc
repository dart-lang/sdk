// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"
#include "vm/globals.h"

namespace dart {

#if (!defined(DART_TARGET_OS_WINDOWS) && !defined(DART_HOST_OS_WINDOWS)) ||    \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  return nullptr;
}

#endif

#if !defined(DART_HOST_OS_WINDOWS) ||                                          \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

void UnwindingRecords::RegisterExecutablePage(Page* page) {}
void UnwindingRecords::UnregisterExecutablePage(Page* page) {}

#endif

}  // namespace dart
