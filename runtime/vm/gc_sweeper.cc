// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/gc_sweeper.h"

#include "vm/freelist.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/pages.h"

namespace dart {

bool GCSweeper::SweepPage(HeapPage* page, FreeList* freelist) {
  // Keep track whether this page is still in use.
  bool in_use = false;

  bool is_executable = (page->type() == HeapPage::kExecutable);
  uword start = page->object_start();
  uword end = page->object_end();
  uword current = start;

  while (current < end) {
    intptr_t obj_size;
    RawObject* raw_obj = RawObject::FromAddr(current);
    if (raw_obj->IsMarked()) {
      // Found marked object. Clear the mark bit and update swept bytes.
      raw_obj->ClearMarkBit();
      obj_size = raw_obj->Size();
      in_use = true;
    } else {
      uword free_end = current + raw_obj->Size();
      while (free_end < end) {
        RawObject* next_obj = RawObject::FromAddr(free_end);
        if (next_obj->IsMarked()) {
          // Reached the end of the free block.
          break;
        }
        // Expand the free block by the size of this object.
        free_end += next_obj->Size();
      }
      obj_size = free_end - current;
      if (is_executable) {
        memset(reinterpret_cast<void*>(current), 0xcc, obj_size);
      }
      if ((current != start) || (free_end != end)) {
        // Only add to the free list if not covering the whole page.
        freelist->FreeLocked(current, obj_size);
      }
    }
    current += obj_size;
  }
  ASSERT(current == end);

  return in_use;
}


intptr_t GCSweeper::SweepLargePage(HeapPage* page) {
  intptr_t words_to_end = 0;
  RawObject* raw_obj = RawObject::FromAddr(page->object_start());
  if (raw_obj->IsMarked()) {
    raw_obj->ClearMarkBit();
    words_to_end = (raw_obj->Size() >> kWordSizeLog2);
  }
#ifdef DEBUG
  // String::MakeExternal and Array::MakeArray create trailing filler objects,
  // but they are always unreachable. Verify that they are not marked.
  uword current = RawObject::ToAddr(raw_obj) + raw_obj->Size();
  uword end = page->object_end();
  while (current < end) {
    RawObject* cur_obj = RawObject::FromAddr(current);
    ASSERT(!cur_obj->IsMarked());
    current += cur_obj->Size();
  }
#endif  // DEBUG
  return words_to_end;
}

}  // namespace dart
