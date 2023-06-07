// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BSS_RELOCS_H_
#define RUNTIME_VM_BSS_RELOCS_H_

#include "platform/allocation.h"

namespace dart {
class Thread;

class BSS : public AllStatic {
 public:
  // Entries found in both the VM and isolate BSS come first. Each has its own
  // portion of the BSS segment, so just the indices are shared, not the values
  // stored at the index.
  enum class Relocation : intptr_t {
    InstructionsRelocatedAddress,
    DRT_GetFfiCallbackMetadata,  // TODO(52579): Remove.
    EndOfVmEntries,

    // We don't have any isolate group specific entries at the moment.
    EndOfIsolateGroupEntries = EndOfVmEntries,
  };

  static constexpr intptr_t kVmEntryCount =
      static_cast<intptr_t>(Relocation::EndOfVmEntries);

  static constexpr intptr_t kIsolateGroupEntryCount =
      static_cast<intptr_t>(Relocation::EndOfIsolateGroupEntries);

  static constexpr intptr_t RelocationIndex(Relocation reloc) {
    return static_cast<intptr_t>(reloc);
  }

  static void Initialize(Thread* current, uword* bss, bool vm);

  // Currently only used externally by LoadedElf::ResolveSymbols() to set the
  // relocated address without changing the embedder interface.
  static void InitializeBSSEntry(BSS::Relocation relocation,
                                 uword new_value,
                                 uword* bss_start);
};

}  // namespace dart

#endif  // RUNTIME_VM_BSS_RELOCS_H_
