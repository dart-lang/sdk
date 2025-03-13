// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"
#include "vm/globals.h"

namespace dart {

#if !defined(DART_TARGET_OS_WINDOWS) || !defined(TARGET_ARCH_IS_64_BIT)

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  return nullptr;
}

#endif  // !defined(DART_TARGET_OS_WINDOWS)

// Also use empty definitions when running gen_snapshot on 64-bit Windows, as
// it does not use the ELF loader, which is the client of these methods.
#if !defined(DART_HOST_OS_WINDOWS) || !defined(ARCH_IS_64_BIT) ||              \
    (defined(DART_PRECOMPILER) && !defined(TESTING))

void UnwindingRecords::RegisterExecutablePage(Page* page) {}
void UnwindingRecords::UnregisterExecutablePage(Page* page) {}

#endif  // !defined(DART_HOST_OS_WINDOWS)

}  // namespace dart
