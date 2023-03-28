// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_PAGE_H_
#define RUNTIME_VM_HEAP_PAGE_H_

#include "platform/atomic.h"
#include "vm/globals.h"
#include "vm/heap/spaces.h"
#include "vm/pointer_tagging.h"
#include "vm/raw_object.h"
#include "vm/virtual_memory.h"

namespace dart {

class ForwardingPage;
class ObjectVisitor;
class ObjectPointerVisitor;
class FindObjectVisitor;
class Thread;

// Pages are allocated with kPageSize alignment so that the Page of any object
// can be computed by masking the object with kPageMask. This does not apply to
// image pages, whose address is chosen by the system loader rather than the
// Dart VM.
static constexpr intptr_t kPageSize = 512 * KB;
static constexpr intptr_t kPageSizeInWords = kPageSize / kWordSize;
static constexpr intptr_t kPageMask = ~(kPageSize - 1);

// See ForwardingBlock and CountingBlock.
static constexpr intptr_t kBitVectorWordsPerBlock = 1;
static constexpr intptr_t kBlockSize =
    kObjectAlignment * kBitsPerWord * kBitVectorWordsPerBlock;
static constexpr intptr_t kBlockMask = ~(kBlockSize - 1);
static constexpr intptr_t kBlocksPerPage = kPageSize / kBlockSize;

// Simplify initialization in allocation stubs by ensuring it is safe
// to overshoot the object end by up to kAllocationRedZoneSize. (Just as the
// stack red zone allows one to overshoot the stack pointer.)
static constexpr intptr_t kAllocationRedZoneSize = kObjectAlignment;

// A Page is the granuitary at which the Dart heap allocates memory from the OS.
// Pages are usually of size kPageSize, except large objects are allocated on
// their own Page sized to the object.
//
// +----------------------+  <- start
// | struct Page (header) |
// +----------------------+
// | alignment gap        |
// +----------------------+  <- object_start
// | objects              |
// | ...                  |
// | ...                  |
// +----------------------+  <- object_end / top_
// | available            |
// +----------------------+  <- end_
// | red zone or          |
// | forwarding table     |
// +----------------------+  <- memory_->end()
class Page {
 public:
  static void Init();
  static void ClearCache();
  static intptr_t CachedSize();
  static void Cleanup();

  enum PageType : uword { kExecutable = 0, kData, kNew };

  Page* next() const { return next_; }
  void set_next(Page* next) { next_ = next; }

  uword start() const { return memory_->start(); }
  uword end() const { return memory_->end(); }
  bool Contains(uword addr) const { return memory_->Contains(addr); }
  intptr_t AliasOffset() const { return memory_->AliasOffset(); }

  uword object_start() const {
    return type_ == kNew ? new_object_start() : old_object_start();
  }
  uword old_object_start() const {
    return memory_->start() + OldObjectStartOffset();
  }
  uword new_object_start() const {
    return memory_->start() + NewObjectStartOffset();
  }
  uword object_end() const {
    if (owner_ != NULL) return owner_->top();
    return top_;
  }
  intptr_t used() const { return object_end() - object_start(); }

  ForwardingPage* forwarding_page() const { return forwarding_page_; }
  void AllocateForwardingPage();

  PageType type() const { return type_; }

  bool is_image_page() const { return !memory_->vm_owns_region(); }

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

  ObjectPtr FindObject(FindObjectVisitor* visitor) const;

  void WriteProtect(bool read_only);

  constexpr static intptr_t OldObjectStartOffset() {
    return Utils::RoundUp(sizeof(Page), kObjectStartAlignment,
                          kOldObjectAlignmentOffset);
  }
  constexpr static intptr_t NewObjectStartOffset() {
    // Note weaker alignment because the bool/null offset tricks don't apply to
    // new-space.
    return Utils::RoundUp(sizeof(Page), kObjectAlignment,
                          kNewObjectAlignmentOffset);
  }

  // Warning: This does not work for objects on image pages because image pages
  // are not aligned. However, it works for objects on large pages, because
  // only one object is allocated per large page.
  static Page* Of(ObjectPtr obj) {
    ASSERT(obj->IsHeapObject());
    return reinterpret_cast<Page*>(static_cast<uword>(obj) & kPageMask);
  }

  // Warning: This does not work for addresses on image pages or on large pages.
  static Page* Of(uword addr) {
    return reinterpret_cast<Page*>(addr & kPageMask);
  }

  // Warning: This does not work for objects on image pages.
  static ObjectPtr ToExecutable(ObjectPtr obj) {
    Page* page = Of(obj);
    VirtualMemory* memory = page->memory_;
    const intptr_t alias_offset = memory->AliasOffset();
    if (alias_offset == 0) {
      return obj;  // Not aliased.
    }
    uword addr = UntaggedObject::ToAddr(obj);
    if (memory->Contains(addr)) {
      return UntaggedObject::FromAddr(addr + alias_offset);
    }
    // obj is executable.
    ASSERT(memory->ContainsAlias(addr));
    return obj;
  }

  // Warning: This does not work for objects on image pages.
  static ObjectPtr ToWritable(ObjectPtr obj) {
    Page* page = Of(obj);
    VirtualMemory* memory = page->memory_;
    const intptr_t alias_offset = memory->AliasOffset();
    if (alias_offset == 0) {
      return obj;  // Not aliased.
    }
    uword addr = UntaggedObject::ToAddr(obj);
    if (memory->ContainsAlias(addr)) {
      return UntaggedObject::FromAddr(addr - alias_offset);
    }
    // obj is writable.
    ASSERT(memory->Contains(addr));
    return obj;
  }

  // 1 card = 128 slots.
  static const intptr_t kSlotsPerCardLog2 = 7;
  static const intptr_t kBytesPerCardLog2 =
      kCompressedWordSizeLog2 + kSlotsPerCardLog2;

  intptr_t card_table_size() const {
    return memory_->size() >> kBytesPerCardLog2;
  }

  static intptr_t card_table_offset() { return OFFSET_OF(Page, card_table_); }

  void RememberCard(ObjectPtr const* slot) {
    ASSERT(Contains(reinterpret_cast<uword>(slot)));
    if (card_table_ == NULL) {
      card_table_ = reinterpret_cast<uint8_t*>(
          calloc(card_table_size(), sizeof(uint8_t)));
    }
    intptr_t offset =
        reinterpret_cast<uword>(slot) - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    card_table_[index] = 1;
  }
  bool IsCardRemembered(ObjectPtr const* slot) {
    ASSERT(Contains(reinterpret_cast<uword>(slot)));
    if (card_table_ == NULL) {
      return false;
    }
    intptr_t offset =
        reinterpret_cast<uword>(slot) - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    return card_table_[index] != 0;
  }
#if defined(DART_COMPRESSED_POINTERS)
  void RememberCard(CompressedObjectPtr const* slot) {
    ASSERT(Contains(reinterpret_cast<uword>(slot)));
    if (card_table_ == NULL) {
      card_table_ = reinterpret_cast<uint8_t*>(
          calloc(card_table_size(), sizeof(uint8_t)));
    }
    intptr_t offset =
        reinterpret_cast<uword>(slot) - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    card_table_[index] = 1;
  }
  bool IsCardRemembered(CompressedObjectPtr const* slot) {
    ASSERT(Contains(reinterpret_cast<uword>(slot)));
    if (card_table_ == NULL) {
      return false;
    }
    intptr_t offset =
        reinterpret_cast<uword>(slot) - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    return card_table_[index] != 0;
  }
#endif
  void VisitRememberedCards(ObjectPointerVisitor* visitor);
  void ResetProgressBar();

  Thread* owner() const {
    return owner_;
  }

  // Remember the limit to which objects have been copied.
  void RecordSurvivors() {
    survivor_end_ = object_end();
  }

  // Move survivor end to the end of the to_ space, making all surviving
  // objects candidates for promotion next time.
  void EarlyTenure() {
    survivor_end_ = end_;
  }

  uword promo_candidate_words() const {
    return (survivor_end_ - object_start()) / kWordSize;
  }

  void Acquire(Thread* thread) {
    ASSERT(owner_ == nullptr);
    owner_ = thread;
    thread->set_top(top_);
    thread->set_end(end_);
    thread->set_true_end(end_);
  }
  void Release(Thread* thread) {
    ASSERT(owner_ == thread);
    owner_ = nullptr;
    top_ = thread->top();
    thread->set_top(0);
    thread->set_end(0);
    thread->set_true_end(0);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    thread->heap_sampler().HandleReleasedTLAB(Thread::Current());
#endif
  }
  void Release() {
    if (owner_ != nullptr) {
      Release(owner_);
    }
  }

  uword TryAllocateGC(intptr_t size) {
    ASSERT(owner_ == nullptr);
    uword result = top_;
    uword new_top = result + size;
    if (LIKELY(new_top <= end_)) {
      top_ = new_top;
      return result;
    }
    return 0;
  }

  void Unallocate(uword addr, intptr_t size) {
    ASSERT((addr + size) == top_);
    top_ -= size;
  }

  bool IsSurvivor(uword raw_addr) const {
    return raw_addr < survivor_end_;
  }
  bool IsResolved() const {
    return top_ == resolved_top_;
  }

 private:
  void set_object_end(uword value) {
    ASSERT((value & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
    top_ = value;
  }

  // Returns NULL on OOM.
  static Page* Allocate(intptr_t size, PageType type, bool can_use_cache);

  // Deallocate the virtual memory backing this page. The page pointer to this
  // page becomes immediately inaccessible.
  void Deallocate(bool can_use_cache);

  PageType type_;
  VirtualMemory* memory_;
  Page* next_;
  ForwardingPage* forwarding_page_;
  uint8_t* card_table_;  // Remembered set, not marking.
  RelaxedAtomic<intptr_t> progress_bar_;

  // The thread using this page for allocation, otherwise NULL.
  Thread* owner_;

  // The address of the next allocation. If owner is non-NULL, this value is
  // stale and the current value is at owner->top_. Called "NEXT" in the
  // original Cheney paper.
  uword top_;

  // The address after the last allocatable byte in this page.
  uword end_;

  // Objects below this address have survived a scavenge.
  uword survivor_end_;

  // A pointer to the first unprocessed object. Resolution completes when this
  // value meets the allocation top. Called "SCAN" in the original Cheney paper.
  uword resolved_top_;

  template <bool>
  friend class ScavengerVisitorBase;
  friend class SemiSpace;
  friend class PageSpace;
  friend class GCCompactor;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Page);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_PAGE_H_
