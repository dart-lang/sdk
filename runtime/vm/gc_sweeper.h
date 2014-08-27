// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GC_SWEEPER_H_
#define VM_GC_SWEEPER_H_

#include "vm/globals.h"

namespace dart {

// Forward declarations.
class FreeList;
class Heap;
class HeapPage;
class Isolate;
class PageSpace;

// The class GCSweeper is used to visit the heap after marking to reclaim unused
// memory.
class GCSweeper {
 public:
  explicit GCSweeper(Heap* heap) : heap_(heap) {}
  ~GCSweeper() {}

  // Sweep the memory area for the page while clearing the mark bits and adding
  // all the unmarked objects to the pre-locked freelist.
  // Returns true if the page is in use.
  bool SweepPage(HeapPage* page, FreeList* freelist);

  // Returns the number of words from page->object_start() to the end of the
  // last marked object.
  intptr_t SweepLargePage(HeapPage* page);

  // Sweep the regular sized data pages between first and last inclusive.
  static void SweepConcurrent(Isolate* isolate,
                              HeapPage* first,
                              HeapPage* last,
                              FreeList* freelist);

 private:
  Heap* heap_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(GCSweeper);
};

}  // namespace dart

#endif  // VM_GC_SWEEPER_H_
