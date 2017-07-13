// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ZONE_H_
#define RUNTIME_VM_ZONE_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/handles.h"
#include "vm/json_stream.h"
#include "vm/memory_region.h"
#include "vm/thread.h"

namespace dart {

// Zones support very fast allocation of small chunks of memory. The
// chunks cannot be deallocated individually, but instead zones
// support deallocating all chunks in one fast operation.

class Zone {
 public:
  // Allocate an array sized to hold 'len' elements of type
  // 'ElementType'.  Checks for integer overflow when performing the
  // size computation.
  template <class ElementType>
  inline ElementType* Alloc(intptr_t len);

  // Allocates an array sized to hold 'len' elements of type
  // 'ElementType'.  The new array is initialized from the memory of
  // 'old_array' up to 'old_len'.
  template <class ElementType>
  inline ElementType* Realloc(ElementType* old_array,
                              intptr_t old_len,
                              intptr_t new_len);

  // Allocates 'size' bytes of memory in the zone; expands the zone by
  // allocating new segments of memory on demand using 'new'.
  //
  // It is preferred to use Alloc<T>() instead, as that function can
  // check for integer overflow.  If you use AllocUnsafe, you are
  // responsible for avoiding integer overflow yourself.
  inline uword AllocUnsafe(intptr_t size);

  // Make a copy of the string in the zone allocated area.
  char* MakeCopyOfString(const char* str);

  // Make a copy of the first n characters of a string in the zone
  // allocated area.
  char* MakeCopyOfStringN(const char* str, intptr_t len);

  // Concatenate strings |a| and |b|. |a| may be NULL. If |a| is not NULL,
  // |join| will be inserted between |a| and |b|.
  char* ConcatStrings(const char* a, const char* b, char join = ',');

  // TODO(zra): Remove these calls and replace them with calls to OS::SCreate
  // and OS::VSCreate.
  // These calls are deprecated. Do not add further calls to these functions.
  // instead use OS::SCreate and OS::VSCreate.
  // Make a zone-allocated string based on printf format and args.
  char* PrintToString(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  char* VPrint(const char* format, va_list args);

  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  uintptr_t SizeInBytes() const;

  // Computes the amount of space used in the zone.
  uintptr_t CapacityInBytes() const;

  // Structure for managing handles allocation.
  VMHandles* handles() { return &handles_; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

  Zone* previous() const { return previous_; }

 private:
  Zone();
  ~Zone();  // Delete all memory associated with the zone.

  // All pointers returned from AllocateUnsafe() and New() have this alignment.
  static const intptr_t kAlignment = kDoubleSize;

  // Default initial chunk size.
  static const intptr_t kInitialChunkSize = 1 * KB;

  // Default segment size.
  static const intptr_t kSegmentSize = 64 * KB;

  // Zap value used to indicate deleted zone area (debug purposes).
  static const unsigned char kZapDeletedByte = 0x42;

  // Zap value used to indicate uninitialized zone area (debug purposes).
  static const unsigned char kZapUninitializedByte = 0xab;

  // Expand the zone to accommodate an allocation of 'size' bytes.
  uword AllocateExpand(intptr_t size);

  // Allocate a large segment.
  uword AllocateLargeSegment(intptr_t size);

  // Insert zone into zone chain, after current_zone.
  void Link(Zone* current_zone) { previous_ = current_zone; }

  // Delete all objects and free all memory allocated in the zone.
  void DeleteAll();

  // Does not actually free any memory. Enables templated containers like
  // BaseGrowableArray to use different allocators.
  template <class ElementType>
  void Free(ElementType* old_array, intptr_t len) {
#ifdef DEBUG
    if (len > 0) {
      memset(old_array, kZapUninitializedByte, len * sizeof(ElementType));
    }
#endif
  }

  // Dump the current allocated sizes in the zone object.
  void DumpZoneSizes();

  // Overflow check (FATAL) for array length.
  template <class ElementType>
  static inline void CheckLength(intptr_t len);

  // This buffer is used for allocation before any segments.
  // This would act as the initial stack allocated chunk so that we don't
  // end up calling malloc/free on zone scopes that allocate less than
  // kChunkSize
  COMPILE_ASSERT(kAlignment <= 8);
  ALIGN8 uint8_t buffer_[kInitialChunkSize];
  MemoryRegion initial_buffer_;

  // The free region in the current (head) segment or the initial buffer is
  // represented as the half-open interval [position, limit). The 'position'
  // variable is guaranteed to be aligned as dictated by kAlignment.
  uword position_;
  uword limit_;

  // Zone segments are internal data structures used to hold information
  // about the memory segmentations that constitute a zone. The entire
  // implementation is in zone.cc.
  class Segment;

  // The current head segment; may be NULL.
  Segment* head_;

  // List of large segments allocated in this zone; may be NULL.
  Segment* large_segments_;

  // Structure for managing handles allocation.
  VMHandles handles_;

  // Used for chaining zones in order to allow unwinding of stacks.
  Zone* previous_;

  friend class StackZone;
  friend class ApiZone;
  template <typename T, typename B, typename Allocator>
  friend class BaseGrowableArray;
  template <typename T, typename B, typename Allocator>
  friend class BaseDirectChainedHashMap;
  DISALLOW_COPY_AND_ASSIGN(Zone);
};

class StackZone : public StackResource {
 public:
  // Create an empty zone and set is at the current zone for the Thread.
  explicit StackZone(Thread* thread);

  // Delete all memory associated with the zone.
  ~StackZone();

  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  uintptr_t SizeInBytes() const { return zone_.SizeInBytes(); }

  // Computes the used space in the zone.
  intptr_t CapacityInBytes() const { return zone_.CapacityInBytes(); }

  Zone* GetZone() { return &zone_; }

 private:
  Zone zone_;

  template <typename T>
  friend class GrowableArray;
  template <typename T>
  friend class ZoneGrowableArray;

  DISALLOW_IMPLICIT_CONSTRUCTORS(StackZone);
};

inline uword Zone::AllocUnsafe(intptr_t size) {
  ASSERT(size >= 0);
  // Round up the requested size to fit the alignment.
  if (size > (kIntptrMax - kAlignment)) {
    FATAL1("Zone::Alloc: 'size' is too large: size=%" Pd "", size);
  }
  size = Utils::RoundUp(size, kAlignment);

  // Check if the requested size is available without expanding.
  uword result;
  intptr_t free_size = (limit_ - position_);
  if (free_size >= size) {
    result = position_;
    position_ += size;
  } else {
    result = AllocateExpand(size);
  }

  // Check that the result has the proper alignment and return it.
  ASSERT(Utils::IsAligned(result, kAlignment));
  return result;
}

template <class ElementType>
inline void Zone::CheckLength(intptr_t len) {
  const intptr_t kElementSize = sizeof(ElementType);
  if (len > (kIntptrMax / kElementSize)) {
    FATAL2("Zone::Alloc: 'len' is too large: len=%" Pd ", kElementSize=%" Pd,
           len, kElementSize);
  }
}

template <class ElementType>
inline ElementType* Zone::Alloc(intptr_t len) {
  CheckLength<ElementType>(len);
  return reinterpret_cast<ElementType*>(AllocUnsafe(len * sizeof(ElementType)));
}

template <class ElementType>
inline ElementType* Zone::Realloc(ElementType* old_data,
                                  intptr_t old_len,
                                  intptr_t new_len) {
  CheckLength<ElementType>(new_len);
  const intptr_t kElementSize = sizeof(ElementType);
  uword old_end = reinterpret_cast<uword>(old_data) + (old_len * kElementSize);
  // Resize existing allocation if nothing was allocated in between...
  if (Utils::RoundUp(old_end, kAlignment) == position_) {
    uword new_end =
        reinterpret_cast<uword>(old_data) + (new_len * kElementSize);
    // ...and there is sufficient space.
    if (new_end <= limit_) {
      ASSERT(new_len >= old_len);
      position_ = Utils::RoundUp(new_end, kAlignment);
      return old_data;
    }
  }
  if (new_len <= old_len) {
    return old_data;
  }
  ElementType* new_data = Alloc<ElementType>(new_len);
  if (old_data != 0) {
    memmove(reinterpret_cast<void*>(new_data),
            reinterpret_cast<void*>(old_data), old_len * kElementSize);
  }
  return new_data;
}

}  // namespace dart

#endif  // RUNTIME_VM_ZONE_H_
