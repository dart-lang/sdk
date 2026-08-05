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
#include "vm/virtual_memory_compressed.h"

namespace dart {

#if !defined(DART_COMPRESSED_POINTERS)
// Without compressed pointers, there is a process-wide cache. With compressed
// pointers, there is a cache per isolate group.
static PageCache* cache = nullptr;
#endif

void Page::Init() {
#if !defined(DART_COMPRESSED_POINTERS)
  ASSERT(cache == nullptr);
  cache = new PageCache();
#endif
}

void Page::ClearCache() {
#if !defined(DART_COMPRESSED_POINTERS)
  cache->Clear();
#endif
}

void Page::Cleanup() {
#if !defined(DART_COMPRESSED_POINTERS)
  delete cache;
  cache = nullptr;
#endif
}

intptr_t Page::CachedSize() {
#if !defined(DART_COMPRESSED_POINTERS)
  return cache->Size();
#else
  return 0;
#endif
}

Page* Page::Allocate(Cage* cage, intptr_t size, uword flags) {
  const bool executable = (flags & Page::kExecutable) != 0;
#if defined(DART_COMPRESSED_POINTERS)
  const bool compressed = !executable;
#else
  const bool compressed = false;
#endif
  const char* name = executable ? "dart-code" : "dart-heap";

  VirtualMemory* memory;
#if defined(DART_COMPRESSED_POINTERS)
  memory = cage->cache()->Pop(flags, size);
#else
  memory = cache->Pop(flags, size);
#endif
  if (memory == nullptr) {
    if (compressed) {
#if defined(DART_COMPRESSED_POINTERS)
      memory = cage->Allocate(size, kPageSize);
#else
      UNREACHABLE();
#endif
    } else {
      memory =
          VirtualMemory::AllocateAligned(size, kPageSize, executable, name);
    }
  }
  if (memory == nullptr) {
    return nullptr;  // Out of memory.
  }

  if ((flags & kNew) != 0) {
    // Initialized by generated code.
    MSAN_UNPOISON(memory->address(), size);

#if defined(DEBUG)
    // Allocation stubs check that the TLAB hasn't been corrupted.
    uword* cursor = reinterpret_cast<uword*>(memory->address());
    uword* end = reinterpret_cast<uword*>(memory->end());
    while (cursor < end) {
      *cursor++ = kAllocationCanary;
    }
#endif
  }

  Page* result = reinterpret_cast<Page*>(memory->address());
  ASSERT(result != nullptr);
  result->flags_ = flags;
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
  result->live_bytes_ = 0;

  if ((flags & kNew) != 0) {
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

void Page::Deallocate(Cage* cage) {
  if (is_image()) {
    delete memory_;
    // For a heap page from a snapshot, the Page object lives in the malloc
    // heap rather than the page itself.
    free(this);
    return;
  }

  free(card_table_);

  // Load before unregistering with LSAN, or LSAN will temporarily think it has
  // been leaked.
  VirtualMemory* memory = memory_;

  LSAN_UNREGISTER_ROOT_REGION(this, sizeof(*this));

  const uword flags = flags_;
#if defined(DART_COMPRESSED_POINTERS)
  if (!cage->cache()->Push(flags, memory)) {
    delete memory;
  }
#else
  if (!cache->Push(flags, memory)) {
    delete memory;
  }
#endif
}

void Page::VisitObjects(ObjectVisitor* visitor) const {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kIncrementalCompactorTask));
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

void Page::VisitObjectsUnsafe(ObjectVisitor* visitor) const {
  uword obj_addr = object_start();
  uword end_addr = object_end();
  while (obj_addr < end_addr) {
    ObjectPtr raw_obj = UntaggedObject::FromAddr(obj_addr);
    visitor->VisitObject(raw_obj);
    obj_addr += raw_obj->untag()->HeapSize();
  }
}

void Page::VisitObjectPointers(ObjectPointerVisitor* visitor) const {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
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

void Page::VisitRememberedCards(PredicateObjectPointerVisitor* visitor,
                                bool only_marked) {
  ASSERT(Thread::Current()->OwnsGCSafepoint() ||
         (Thread::Current()->task_kind() == Thread::kScavengerTask) ||
         (Thread::Current()->task_kind() == Thread::kIncrementalCompactorTask));
  NoSafepointScope no_safepoint;

  if (card_table_ == nullptr) {
    return;
  }

  ArrayPtr obj =
      static_cast<ArrayPtr>(UntaggedObject::FromAddr(object_start()));
  ASSERT(obj->IsArray() || obj->IsImmutableArray());
  ASSERT(obj->untag()->IsCardRemembered());
  if (only_marked && !obj->untag()->IsMarked()) return;
  CompressedObjectPtr* obj_from = obj->untag()->from();
  CompressedObjectPtr* obj_to =
      obj->untag()->to(Smi::Value(obj->untag()->length()));
  uword heap_base = obj.heap_base();

  const size_t size_in_bits = card_table_size();
  const size_t size_in_words =
      Utils::RoundUp(size_in_bits, kBitsPerWord) >> kBitsPerWordLog2;
  for (;;) {
    const size_t word_offset = progress_bar_.fetch_add(1);
    if (word_offset >= size_in_words) break;

    uword cell = card_table_[word_offset];
    if (cell == 0) continue;

    for (intptr_t bit_offset = 0; bit_offset < kBitsPerWord; bit_offset++) {
      const uword bit_mask = static_cast<uword>(1) << bit_offset;
      if ((cell & bit_mask) == 0) continue;
      const intptr_t i = (word_offset << kBitsPerWordLog2) + bit_offset;

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

      bool has_new_target = visitor->PredicateVisitCompressedPointers(
          heap_base, card_from, card_to);

      if (!has_new_target) {
        cell ^= bit_mask;
      }
    }
    card_table_[word_offset] = cell;
  }
}

void Page::ResetProgressBar() {
  progress_bar_ = 0;
}

void Page::WriteProtect(bool read_only) {
  ASSERT(!is_image());
  if (is_executable() && read_only) {
    // Handle making code executable in a special way.
    memory_->WriteProtectCode();
  } else {
    memory_->Protect(read_only ? VirtualMemory::kReadOnly
                               : VirtualMemory::kReadWrite);
  }
}

// We do not cached large pages because object initialization assumes that any
// object allocated on a large page is already zero-initialized.
// We do not cache image pages because their memory belongs to the embedder, not
// the VM. Often this memory belongs to dlopen.
// We do not cache frozen pages because they are not writable.
static bool CanUseCache(uword flags) {
  return (flags & (Page::kImage | Page::kLarge | Page::kFrozen)) == 0;
}

// We cache executable and non-executable pages separately. Especially relevant
// when dual mapping, where executable pages have two associated regions but
// data pages have only one.
static intptr_t CacheIndex(uword flags) {
  return (flags & Page::kExecutable) != 0 ? 1 : 0;
}

PageCache::PageCache() {}

PageCache::~PageCache() {
  Clear();
}

VirtualMemory* PageCache::Pop(uword flags, intptr_t size) {
  if (CanUseCache(flags)) {
    ASSERT(size == Page::kPageSize);
    MutexLocker ml(&mutex_);
    intptr_t index = CacheIndex(flags);
    ASSERT(size_[index] >= 0);
    ASSERT(size_[index] <= kCapacity);
    if (size_[index] > 0) {
      return cache_[index][--size_[index]];
    }
  }
  return nullptr;
}

bool PageCache::Push(uword flags, VirtualMemory* memory) {
  if (CanUseCache(flags)) {
    ASSERT(memory->size() == Page::kPageSize);

    // Allow caching up to one new-space worth of pages to avoid the cost of
    // unmap when freeing from-space. Using ThresholdInWords both accounts for
    // new-space scaling with the number of mutators, and prevents the cache
    // from staying big after new-space shrinks.
    intptr_t limit = 0;
    IsolateGroup* group = IsolateGroup::Current();
    if ((group != nullptr) && ((flags & Page::kNew) != 0)) {
      limit = group->heap()->new_space()->ThresholdInWords() /
              Page::kPageSizeInWords;
    }
    limit = Utils::Maximum(limit,
                           FLAG_new_gen_semi_max_size * MB / Page::kPageSize);
    limit = Utils::Minimum(limit, kCapacity);

    MutexLocker ml(&mutex_);
    intptr_t index = CacheIndex(flags);
    ASSERT(size_[index] >= 0);
    ASSERT(size_[index] <= kCapacity);
    if (size_[index] < limit) {
      intptr_t size = memory->size();
      if ((flags & Page::kExecutable) != 0 && FLAG_write_protect_code) {
        // Reset to initial protection.
        memory->Protect(VirtualMemory::kReadWrite);
      }
#if defined(DEBUG)
      if ((flags & Page::kExecutable) != 0) {
        uword* cursor = reinterpret_cast<uword*>(memory->address());
        uword* end = reinterpret_cast<uword*>(memory->end());
        while (cursor < end) {
          *cursor++ = kBreakInstructionFiller;
        }
      } else {
        memset(memory->address(), Heap::kZapByte, size);
      }
#endif
      MSAN_POISON(memory->address(), size);
      cache_[index][size_[index]++] = memory;
      return true;
    }
  }

  return false;
}

intptr_t PageCache::Size() {
  MutexLocker ml(&mutex_);
  intptr_t pages = 0;
  for (intptr_t i = 0; i < 2; i++) {
    pages += size_[i];
  }
  return pages * Page::kPageSize;
}

void PageCache::Abandon() {
  for (intptr_t i = 0; i < 2; i++) {
    size_[i] = 0;
  }
}

void PageCache::Clear() {
  MutexLocker ml(&mutex_);
  for (intptr_t i = 0; i < 2; i++) {
    ASSERT(size_[i] >= 0);
    ASSERT(size_[i] <= kCapacity);
    while (size_[i] > 0) {
      delete cache_[i][--size_[i]];
    }
  }
}

}  // namespace dart
