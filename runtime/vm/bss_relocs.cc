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
  auto const instructions = reinterpret_cast<uword>(
      current->isolate_group()->source()->snapshot_instructions);
  uword dso_base;
  // Needed for assembly snapshots. For ELF snapshots, we set up the relocated
  // address information directly in the text segment InstructionsSection.
  if (NativeSymbolResolver::LookupSharedObject(instructions, &dso_base)) {
    InitializeBSSEntry(Relocation::InstructionsRelocatedAddress,
                       instructions - dso_base, bss_start);
  }

  if (!vm) {
    // Fill values at isolate-only indices.
    InitializeBSSEntry(Relocation::DRT_GetThreadForNativeCallback,
                       reinterpret_cast<uword>(DLRT_GetThreadForNativeCallback),
                       bss_start);
  }
}

}  // namespace dart
