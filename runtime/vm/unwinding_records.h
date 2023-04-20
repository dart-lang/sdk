// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for patching compiled code.

#ifndef RUNTIME_VM_UNWINDING_RECORDS_H_
#define RUNTIME_VM_UNWINDING_RECORDS_H_

#include "vm/allocation.h"
#include "vm/heap/page.h"

namespace dart {

class UnwindingRecords : public AllStatic {
 public:
  static void Init();
  static void Cleanup();
  static intptr_t SizeInBytes();
  static void RegisterExecutablePage(Page* page);
  static void UnregisterExecutablePage(Page* page);
};

}  // namespace dart

#endif  // RUNTIME_VM_UNWINDING_RECORDS_H_
