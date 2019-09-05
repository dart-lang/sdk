// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <vm/bss_relocs.h>
#include <vm/runtime_entry.h>
#include <vm/thread.h>

namespace dart {

void BSS::Initialize(Thread* current, uword* bss_start) {
  bss_start[BSS::RelocationIndex(
      BSS::Relocation::DRT_GetThreadForNativeCallback)] =
      reinterpret_cast<uword>(DLRT_GetThreadForNativeCallback);
}

}  // namespace dart
