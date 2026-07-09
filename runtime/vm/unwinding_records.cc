// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/unwinding_records.h"

namespace dart {

// The default definition when not precompiling for a Windows target.
#if !defined(UNWINDING_RECORDS_WINDOWS_PRECOMPILER)

const void* UnwindingRecords::GenerateRecordsInto(intptr_t offset,
                                                  uint8_t* target_buffer) {
  return nullptr;
}

#endif  // !defined(UNWINDING_RECORDS_WINDOWS_PRECOMPILER)

// The default definition when the ElfLoader is not used or the VM is not
// running on a Windows system.
#if !defined(UNWINDING_RECORDS_WINDOWS_HOST)

void UnwindingRecords::RegisterExecutablePage(Page* page) {}
void UnwindingRecords::UnregisterExecutablePage(Page* page) {}

#endif  // !defined(UNWINDING_RECORDS_WINDOWS_HOST)

}  // namespace dart
