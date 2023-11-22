// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"
#include "vm/globals.h"

#if !defined(DART_HOST_OS_WINDOWS) ||                                          \
    (!defined(TARGET_ARCH_X64) && !defined(TARGET_ARCH_ARM64))

namespace dart {

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  return nullptr;
}
void UnwindingRecords::RegisterExecutablePage(Page* page) {}
void UnwindingRecords::UnregisterExecutablePage(Page* page) {}

}  // namespace dart

#endif  // !defined(DART_HOST_OS_WINDOWS) || !defined(TARGET_ARCH_X64)
