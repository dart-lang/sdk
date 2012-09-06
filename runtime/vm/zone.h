// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ZONE_H_
#define VM_ZONE_H_

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/handles.h"
#include "vm/memory_region.h"

namespace dart {

// Zones support very fast allocation of small chunks of memory. The
// chunks cannot be deallocated individually, but instead zones
// support deallocating all chunks in one fast operation.

class BaseZone {
 private:
  BaseZone();
  ~BaseZone();  // Delete all memory associated with the zone.

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

  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  intptr_t SizeInBytes() const;

  // Make a copy of the string in the zone allocated area.
  char* MakeCopyOfString(const char* str);

  // All pointers returned from AllocateUnsafe() and New() have this alignment.
  static const intptr_t kAlignment = kWordSize;

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

  // Delete all objects and free all memory allocated in the zone.
  void DeleteAll();

#if defined(DEBUG)
  // Dump the current allocated sizes in the zone object.
  void DumpZoneSizes();
#endif

  // This buffer is used for allocation before any segments.
  // This would act as the initial stack allocated chunk so that we don't
  // end up calling malloc/free on zone scopes that allocate less than
  // kChunkSize
  uint8_t buffer_[kInitialChunkSize];
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

  friend class Zone;
  friend class ApiZone;
  template<typename T, typename B> friend class BaseGrowableArray;
  DISALLOW_COPY_AND_ASSIGN(BaseZone);
};


class Zone : public StackResource {
 public:
  // Create an empty zone and set is at the current zone for the Isolate.
  explicit Zone(BaseIsolate* isolate);

  // Delete all memory associated with the zone.
  ~Zone();

  // Allocates an array sized to hold 'len' elements of type
  // 'ElementType'.  Checks for integer overflow when performing the
  // size computation.
  template <class ElementType>
  ElementType* Alloc(intptr_t len) { return zone_.Alloc<ElementType>(len); }

  // Allocates an array sized to hold 'len' elements of type
  // 'ElementType'.  The new array is initialized from the memory of
  // 'old_array' up to 'old_len'.
  template <class ElementType>
  ElementType* Realloc(ElementType* old_array,
                       intptr_t old_len,
                       intptr_t new_len) {
    return zone_.Realloc<ElementType>(old_array, old_len, new_len);
  }

  // Allocates 'size' bytes of memory in the zone; expands the zone by
  // allocating new segments of memory on demand using 'new'.
  //
  // It is preferred to use Alloc<T>() instead, as that function can
  // check for integer overflow.  If you use AllocUnsafe, you are
  // responsible for avoiding integer overflow yourself.
  uword AllocUnsafe(intptr_t size) { return zone_.AllocUnsafe(size); }

  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  intptr_t SizeInBytes() const { return zone_.SizeInBytes(); }

  // Make a copy of the string in the zone allocated area.
  char* MakeCopyOfString(const char* str) {
    return zone_.MakeCopyOfString(str);
  }

  // Make a zone-allocated string based on printf format and args.
  char* PrintToString(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  VMHandles* handles() { return &handles_; }

  void VisitObjectPointers(ObjectPointerVisitor* visitor);

 private:
  BaseZone* GetBaseZone() { return &zone_; }

  BaseZone zone_;

  // Structure for managing handles allocation.
  VMHandles handles_;

  // Used for chaining zones in order to allow unwinding of stacks.
  Zone* previous_;

  template<typename T> friend class GrowableArray;
  template<typename T> friend class ZoneGrowableArray;

  DISALLOW_IMPLICIT_CONSTRUCTORS(Zone);
};

inline uword BaseZone::AllocUnsafe(intptr_t size) {
  ASSERT(size >= 0);

  // Round up the requested size to fit the alignment.
  if (size > (kIntptrMax - kAlignment)) {
    FATAL1("BaseZone::Alloc: 'size' is too large: size=%"Pd"", size);
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
inline ElementType* BaseZone::Alloc(intptr_t len) {
  const intptr_t element_size = sizeof(ElementType);
  if (len > (kIntptrMax / element_size)) {
    FATAL2("BaseZone::Alloc: 'len' is too large: len=%"Pd", element_size=%"Pd,
           len, element_size);
  }
  return reinterpret_cast<ElementType*>(AllocUnsafe(len * element_size));
}

template <class ElementType>
inline ElementType* BaseZone::Realloc(ElementType* old_data,
                                      intptr_t old_len,
                                      intptr_t new_len) {
  ElementType* new_data = Alloc<ElementType>(new_len);
  if (old_data != 0) {
    memmove(reinterpret_cast<void*>(new_data),
            reinterpret_cast<void*>(old_data),
            Utils::Minimum(old_len * sizeof(ElementType),
                           new_len * sizeof(ElementType)));
  }
  return new_data;
}

}  // namespace dart

#endif  // VM_ZONE_H_
