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
class Thread;
class UnwindingRecords;

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

  enum PageFlags : uword {
    kExecutable = 1 << 0,
    kLarge = 1 << 1,
    kImage = 1 << 2,
    kVMIsolate = 1 << 3,
    kNew = 1 << 4,
    kEvacuationCandidate = 1 << 5,
  };
  bool is_executable() const { return (flags_ & kExecutable) != 0; }
  bool is_large() const { return (flags_ & kLarge) != 0; }
  bool is_image() const { return (flags_ & kImage) != 0; }
  bool is_vm_isolate() const { return (flags_ & kVMIsolate) != 0; }
  bool is_new() const { return (flags_ & kNew) != 0; }
  bool is_old() const { return !is_new(); }
  bool is_evacuation_candidate() const {
    return (flags_ & kEvacuationCandidate) != 0;
  }

  Page* next() const { return next_; }
  void set_next(Page* next) { next_ = next; }

  uword start() const { return memory_->start(); }
  uword end() const { return memory_->end(); }
  bool Contains(uword addr) const { return memory_->Contains(addr); }
  intptr_t AliasOffset() const { return memory_->AliasOffset(); }

  uword object_start() const {
    return is_new() ? new_object_start() : old_object_start();
  }
  uword old_object_start() const {
    return memory_->start() + OldObjectStartOffset();
  }
  uword new_object_start() const {
    return memory_->start() + NewObjectStartOffset();
  }
  uword object_end() const {
    if (owner_ != nullptr) return owner_->top();
    return top_;
  }
  intptr_t used() const { return object_end() - object_start(); }

  ForwardingPage* forwarding_page() const { return forwarding_page_; }
  void RegisterUnwindingRecords();
  void UnregisterUnwindingRecords();
  void AllocateForwardingPage();

  void VisitObjects(ObjectVisitor* visitor) const;
  void VisitObjectPointers(ObjectPointerVisitor* visitor) const;

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
  // These are "original" in the sense that they reflect TLAB boundaries when
  // the TLAB was acquired, not the current boundaries. An object between
  // original_top and top may still be in use by Dart code that has eliminated
  // write barriers.
  uword original_top() const { return LoadAcquire(&top_); }
  uword original_end() const { return LoadRelaxed(&end_); }
  static intptr_t original_top_offset() { return OFFSET_OF(Page, top_); }
  static intptr_t original_end_offset() { return OFFSET_OF(Page, end_); }

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

  // 1 card = 32 slots.
  static constexpr intptr_t kSlotsPerCardLog2 = 5;
  static constexpr intptr_t kBytesPerCardLog2 =
      kCompressedWordSizeLog2 + kSlotsPerCardLog2;

  intptr_t card_table_size() const {
    return memory_->size() >> kBytesPerCardLog2;
  }

  static intptr_t card_table_offset() { return OFFSET_OF(Page, card_table_); }

  void RememberCard(ObjectPtr const* slot) {
    RememberCard(reinterpret_cast<uword>(slot));
  }
  bool IsCardRemembered(ObjectPtr const* slot) {
    return IsCardRemembered(reinterpret_cast<uword>(slot));
  }
#if defined(DART_COMPRESSED_POINTERS)
  void RememberCard(CompressedObjectPtr const* slot) {
    RememberCard(reinterpret_cast<uword>(slot));
  }
  bool IsCardRemembered(CompressedObjectPtr const* slot) {
    return IsCardRemembered(reinterpret_cast<uword>(slot));
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
    ASSERT(thread->top() == 0);
    ASSERT(thread->end() == 0);
    thread->set_top(top_);
    thread->set_end(end_);
    thread->set_true_end(end_);
  }
  intptr_t Release(Thread* thread) {
    ASSERT(owner_ == thread);
    owner_ = nullptr;
    uword old_top = top_;
    uword new_top = thread->top();
    StoreRelease(&top_, new_top);
    thread->set_top(0);
    thread->set_end(0);
    thread->set_true_end(0);
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    thread->heap_sampler().HandleReleasedTLAB(Thread::Current());
#endif
    ASSERT(new_top >= old_top);
    return new_top - old_top;
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

#if defined(DEBUG)
    uword* cursor = reinterpret_cast<uword*>(addr);
    uword* end = reinterpret_cast<uword*>(addr + size);
    while (cursor < end) {
      *cursor++ = kAllocationCanary;
    }
#endif

    top_ -= size;
  }

  bool IsSurvivor(uword raw_addr) const {
    return raw_addr < survivor_end_;
  }
  bool IsResolved() const {
    return top_ == resolved_top_;
  }

 private:
  void RememberCard(uword slot) {
    ASSERT(Contains(slot));
    if (card_table_ == nullptr) {
      size_t size_in_bits = card_table_size();
      size_t size_in_bytes =
          Utils::RoundUp(size_in_bits, kBitsPerWord) >> kBitsPerByteLog2;
      card_table_ =
          reinterpret_cast<uword*>(calloc(size_in_bytes, sizeof(uint8_t)));
    }
    intptr_t offset = slot - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    intptr_t word_offset = index >> kBitsPerWordLog2;
    intptr_t bit_offset = index & (kBitsPerWord - 1);
    uword bit_mask = static_cast<uword>(1) << bit_offset;
    card_table_[word_offset] |= bit_mask;
  }
  bool IsCardRemembered(uword slot) {
    ASSERT(Contains(slot));
    if (card_table_ == nullptr) {
      return false;
    }
    intptr_t offset = slot - reinterpret_cast<uword>(this);
    intptr_t index = offset >> kBytesPerCardLog2;
    ASSERT((index >= 0) && (index < card_table_size()));
    intptr_t word_offset = index >> kBitsPerWordLog2;
    intptr_t bit_offset = index & (kBitsPerWord - 1);
    uword bit_mask = static_cast<uword>(1) << bit_offset;
    return (card_table_[word_offset] & bit_mask) != 0;
  }

  void set_object_end(uword value) {
    ASSERT((value & kObjectAlignmentMask) == kOldObjectAlignmentOffset);
    top_ = value;
  }

  // Returns nullptr on OOM.
  static Page* Allocate(intptr_t size, uword flags);

  // Deallocate the virtual memory backing this page. The page pointer to this
  // page becomes immediately inaccessible.
  void Deallocate();

  uword flags_;
  VirtualMemory* memory_;
  Page* next_;
  ForwardingPage* forwarding_page_;
  uword* card_table_;  // Remembered set, not marking.
  RelaxedAtomic<intptr_t> progress_bar_;

  // The thread using this page for allocation, otherwise nullptr.
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

  friend class CheckStoreBufferVisitor;
  friend class GCCompactor;
  friend class PageSpace;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class SemiSpace;
  friend class UnwindingRecords;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Page);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_PAGE_H_
