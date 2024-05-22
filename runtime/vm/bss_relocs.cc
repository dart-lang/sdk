// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bss_relocs.h"
#include "vm/native_symbol.h"
#include "vm/runtime_entry.h"
#include "vm/thread.h"

namespace dart {

void BSS::InitializeBSSEntry(BSS::Relocation relocation,
                             uword new_value,
                             uword* bss_start) {
  std::atomic<uword>* slot = reinterpret_cast<std::atomic<uword>*>(
      &bss_start[BSS::RelocationIndex(relocation)]);
  uword old_value = slot->load(std::memory_order_relaxed);
  // FullSnapshotReader::ReadProgramSnapshot, and thus BSS::Initialize, can
  // get called multiple times for the same isolate in different threads, though
  // the initialized value will be consistent and thus change only once. Avoid
  // calling compare_exchange_strong unless we actually need to change the
  // value, to avoid spurious read/write races by TSAN.
  if (old_value == new_value) return;
  if (!slot->compare_exchange_strong(old_value, new_value,
                                     std::memory_order_relaxed)) {
    RELEASE_ASSERT(old_value == new_value);
  }
}

void BSS::Initialize(Thread* current, uword* bss_start, bool vm) {
  // TODO(https://dartbug.com/52579): Remove.
  InitializeBSSEntry(Relocation::DRT_GetFfiCallbackMetadata,
                     reinterpret_cast<uword>(DLRT_GetFfiCallbackMetadata),
                     bss_start);
  InitializeBSSEntry(Relocation::DRT_ExitTemporaryIsolate,
                     reinterpret_cast<uword>(DLRT_ExitTemporaryIsolate),
                     bss_start);
}

}  // namespace dart
