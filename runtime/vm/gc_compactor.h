// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_GC_COMPACTOR_H_
#define RUNTIME_VM_GC_COMPACTOR_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

// Forward declarations.
class HeapPage;
class Heap;

// The class GCCompactor is used to relocate objects to fresh pages to remove
// fragmentation.
class GCCompactor : public ValueObject {
 public:
  explicit GCCompactor(Heap* heap) : heap_(heap) {}
  ~GCCompactor() {}

  void EvacuatePage(HeapPage* page);

 private:
  Heap* heap_;
};

}  // namespace dart

#endif  // RUNTIME_VM_GC_COMPACTOR_H_
