// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bss_relocs.h"
#include "vm/runtime_entry.h"
#include "vm/thread.h"

namespace dart {

void BSS::Initialize(Thread* current, uword* bss_start) {
  std::atomic<uword>* slot =
      reinterpret_cast<std::atomic<uword>*>(&bss_start[BSS::RelocationIndex(
          BSS::Relocation::DRT_GetThreadForNativeCallback)]);
  uword old_value = slot->load(std::memory_order_relaxed);
  uword new_value = reinterpret_cast<uword>(DLRT_GetThreadForNativeCallback);
  if (!slot->compare_exchange_strong(old_value, new_value,
                                     std::memory_order_relaxed)) {
    RELEASE_ASSERT(old_value == new_value);
  }
}

}  // namespace dart
