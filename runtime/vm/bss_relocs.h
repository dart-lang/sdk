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
  enum class Relocation : intptr_t {
    DRT_GetThreadForNativeCallback = 0,
    NumRelocations = 1
  };

  static intptr_t RelocationIndex(Relocation reloc) {
    return static_cast<intptr_t>(reloc);
  }

  static void Initialize(Thread* current, uword* bss);
};

}  // namespace dart

#endif  // RUNTIME_VM_BSS_RELOCS_H_
