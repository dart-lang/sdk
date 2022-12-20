// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/page.h"

#include "platform/assert.h"
#include "platform/leak_sanitizer.h"
#include "vm/dart.h"
#include "vm/heap/become.h"
#include "vm/heap/compactor.h"
#include "vm/heap/marker.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/sweeper.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/object_set.h"
#include "vm/os_thread.h"
#include "vm/virtual_memory.h"

namespace dart {

// This cache needs to be at least as big as FLAG_new_gen_semi_max_size or
// munmap will noticeably impact performance.
static constexpr intptr_t kPageCacheCapacity = 8 * kWordSize;
static Mutex* page_cache_mutex = nullptr;
static VirtualMemory* page_cache[kPageCacheCapacity] = {nullptr};
static intptr_t page_cache_size = 0;

void Page::Init() {
  ASSERT(page_cache_mutex == nullptr);
  page_cache_mutex = new Mutex(NOT_IN_PRODUCT("page_cache_mutex"));
}

void Page::ClearCache() {
  MutexLocker ml(page_cache_mutex);
  ASSERT(page_cache_size >= 0);
  ASSERT(page_cache_size <= kPageCacheCapacity);
  while (page_cache_size > 0) {
    delete page_cache[--page_cache_size];
  }
}

void Page::Cleanup() {
  ClearCache();
  delete page_cache_mutex;
  page_cache_mutex = nullptr;
}

intptr_t Page::CachedSize() {
  MutexLocker ml(page_cache_mutex);
  return page_cache_size * kPageSize;
}

Page* Page::Allocate(intptr_t size, PageType type, bool can_use_cache) {
  const bool executable = type == kExecutable;
  const bool compressed = !executable;
  const char* name = executable ? "dart-code" : "dart-heap";

  VirtualMemory* memory = nullptr;
  if (can_use_cache) {
    // We don't automatically use the cache based on size and type because a
    // large page that happens to be the same size as a regular page can't
    // use the cache. Large pages are expected to be zeroed on allocation but
    // cached pages are dirty.
    ASSERT(size == kPageSize);
    ASSERT(!executable);
    MutexLocker ml(page_cache_mutex);
    ASSERT(page_cache_size >= 0);
    ASSERT(page_cache_size <= kPageCacheCapacity);
    if (page_cache_size > 0) {
      memory = page_cache[--page_cache_size];
    }
  }
  if (memory == nullptr) {
    memory = VirtualMemory::AllocateAligned(size, kPageSize, executable,
                                            compressed, name);
  }
  if (memory == nullptr) {
    return nullptr;  // Out of memory.
  }

  if (type == kNew) {
#if defined(DEBUG)
    memset(memory->address(), Heap::kZapByte, size);
#endif
    // Initialized by generated code.
    MSAN_UNPOISON(memory->address(), size);
  } else {
    // We don't zap old-gen because we rely on implicit zero-initialization
    // of large typed data arrays.
  }

  Page* result = reinterpret_cast<Page*>(memory->address());
  ASSERT(result != NULL);
  result->type_ = type;
  result->memory_ = memory;
  result->next_ = nullptr;
  result->forwarding_page_ = nullptr;
  result->card_table_ = nullptr;
  result->progress_bar_ = 0;
  result->owner_ = nullptr;
  result->top_ = 0;
  result->end_ = 0;
  result->survivor_end_ = 0;
  result->resolved_top_ = 0;

  if (type == kNew) {
    uword top = result->object_start();
    uword end =
        memory->end() - kNewObjectAlignmentOffset - kAllocationRedZoneSize;
    result->top_ = top;
    result->end_ = end;
    result->survivor_end_ = top;
    result->resolved_top_ = top;
  }

  LSAN_REGISTER_ROOT_REGION(result, sizeof(*result));

  return result;
}

void Page::Deallocate(bool can_use_cache) {
  if (is_image_page()) {
    delete memory_;
    // For a heap page from a snapshot, the Page object lives in the malloc
    // heap rather than the page itself.
    free(this);
    return;
  }

  free(card_table_);

  LSAN_UNREGISTER_ROOT_REGION(this, sizeof(*this));

  VirtualMemory* memory = memory_;
  if (can_use_cache) {
    ASSERT(memory->size() == kPageSize);
    ASSERT(type_ != kExecutable);
    MutexLocker ml(page_cache_mutex);
    ASSERT(page_cache_size >= 0);
    ASSERT(page_cache_size <= kPageCacheCapacity);
    if (page_cache_size < kPageCacheCapacity) {
      intptr_t size = memory->size();
#if defined(DEBUG)
      if (type_ == kNew) {
        memset(memory->address(), Heap::kZapByte, size);
      } else {
        // We don't zap old-gen because we rely on implicit zero-initialization
        // of large typed data arrays.
      }
#endif
      MSAN_POISON(memory->address(), size);
      page_cache[page_cache_size++] = memory;
      memory = nullptr;
    }
  }
  delete memory;
}

void Page::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint());
  NoSafepointScope no_safepoint;
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    ObjectPtr raw_obj = UntaggedObject::FromAddr(obj_addr);
    visitor->VisitObject(raw_obj);
    obj_addr += raw_obj->untag()->HeapSize();
  }
  ASSERT(obj_addr == end_addr);
}

void Page::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kCompactorTask) ||
         (Thread::Current()->task_kind() == Thread::kMarkerTask));
  NoSafepointScope no_safepoint;
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    ObjectPtr raw_obj = UntaggedObject::FromAddr(obj_addr);
    obj_addr += raw_obj->untag()->VisitPointers(visitor);
  }
  ASSERT(obj_addr == end_addr);
}

void Page::VisitRememberedCards(ObjectPointerVisitor* visitor) {
  ASSERT(Thread::Current()->IsAtSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kScavengerTask));
  NoSafepointScope no_safepoint;

  if (card_table_ == NULL) {
    return;
  }

  ArrayPtr obj =
      static_cast<ArrayPtr>(UntaggedObject::FromAddr(object_start()));
  ASSERT(obj->IsArray());
  ASSERT(obj->untag()->IsCardRemembered());
  CompressedObjectPtr* obj_from = obj->untag()->from();
  CompressedObjectPtr* obj_to =
      obj->untag()->to(Smi::Value(obj->untag()->length()));
  uword heap_base = obj.heap_base();

  const intptr_t size = card_table_size();
  for (;;) {
    intptr_t i = progress_bar_.fetch_add(1);
    if (i >= size) break;

    if (card_table_[i] != 0) {
      CompressedObjectPtr* card_from =
          reinterpret_cast<CompressedObjectPtr*>(this) +
          (i << kSlotsPerCardLog2);
      CompressedObjectPtr* card_to =
          reinterpret_cast<CompressedObjectPtr*>(card_from) +
          (1 << kSlotsPerCardLog2) - 1;
      // Minus 1 because to is inclusive.

      if (card_from < obj_from) {
        // First card overlaps with header.
        card_from = obj_from;
      }
      if (card_to > obj_to) {
        // Last card(s) may extend past the object. Array truncation can make
        // this happen for more than one card.
        card_to = obj_to;
      }

      visitor->VisitCompressedPointers(heap_base, card_from, card_to);

      bool has_new_target = false;
      for (CompressedObjectPtr* slot = card_from; slot <= card_to; slot++) {
        if ((*slot)->IsNewObjectMayBeSmi()) {
          has_new_target = true;
          break;
        }
      }

      if (!has_new_target) {
        card_table_[i] = 0;
      }
    }
  }
}

void Page::ResetProgressBar() {
  progress_bar_ = 0;
}

ObjectPtr Page::FindObject(FindObjectVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  if (visitor->VisitRange(obj_addr, end_addr)) {
    while (obj_addr < end_addr) {
      ObjectPtr raw_obj = UntaggedObject::FromAddr(obj_addr);
      uword next_obj_addr = obj_addr + raw_obj->untag()->HeapSize();
      if (visitor->VisitRange(obj_addr, next_obj_addr) &&
          raw_obj->untag()->FindObject(visitor)) {
        return raw_obj;  // Found object, return it.
      }
      obj_addr = next_obj_addr;
    }
    ASSERT(obj_addr == end_addr);
  }
  return Object::null();
}

void Page::WriteProtect(bool read_only) {
  ASSERT(!is_image_page());

  VirtualMemory::Protection prot;
  if (read_only) {
    if ((type_ == kExecutable) && (memory_->AliasOffset() == 0)) {
      prot = VirtualMemory::kReadExecute;
    } else {
      prot = VirtualMemory::kReadOnly;
    }
  } else {
    prot = VirtualMemory::kReadWrite;
  }
  memory_->Protect(prot);
}

}  // namespace dart
