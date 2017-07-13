// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone.h"

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/handles_impl.h"
#include "vm/heap.h"
#include "vm/os.h"

namespace dart {

// Zone segments represent chunks of memory: They have starting
// address encoded in the this pointer and a size in bytes. They are
// chained together to form the backing storage for an expanding zone.
class Zone::Segment {
 public:
  Segment* next() const { return next_; }
  intptr_t size() const { return size_; }

  uword start() { return address(sizeof(Segment)); }
  uword end() { return address(size_); }

  // Allocate or delete individual segments.
  static Segment* New(intptr_t size, Segment* next);
  static void DeleteSegmentList(Segment* segment);
  static void IncrementMemoryCapacity(uintptr_t size);
  static void DecrementMemoryCapacity(uintptr_t size);

 private:
  Segment* next_;
  intptr_t size_;

  // Computes the address of the nth byte in this segment.
  uword address(int n) { return reinterpret_cast<uword>(this) + n; }

  static void Delete(Segment* segment) { free(segment); }

  DISALLOW_IMPLICIT_CONSTRUCTORS(Segment);
};

Zone::Segment* Zone::Segment::New(intptr_t size, Zone::Segment* next) {
  ASSERT(size >= 0);
  Segment* result = reinterpret_cast<Segment*>(malloc(size));
  if (result == NULL) {
    OUT_OF_MEMORY();
  }
  ASSERT(Utils::IsAligned(result->start(), Zone::kAlignment));
#ifdef DEBUG
  // Zap the entire allocated segment (including the header).
  memset(result, kZapUninitializedByte, size);
#endif
  result->next_ = next;
  result->size_ = size;
  IncrementMemoryCapacity(size);
  return result;
}

void Zone::Segment::DeleteSegmentList(Segment* head) {
  Segment* current = head;
  while (current != NULL) {
    DecrementMemoryCapacity(current->size());
    Segment* next = current->next();
#ifdef DEBUG
    // Zap the entire current segment (including the header).
    memset(current, kZapDeletedByte, current->size());
#endif
    Segment::Delete(current);
    current = next;
  }
}

void Zone::Segment::IncrementMemoryCapacity(uintptr_t size) {
  Thread* current_thread = Thread::Current();
  if (current_thread != NULL) {
    current_thread->IncrementMemoryCapacity(size);
  } else if (ApiNativeScope::Current() != NULL) {
    // If there is no current thread, we might be inside of a native scope.
    ApiNativeScope::IncrementNativeScopeMemoryCapacity(size);
  }
}

void Zone::Segment::DecrementMemoryCapacity(uintptr_t size) {
  Thread* current_thread = Thread::Current();
  if (current_thread != NULL) {
    current_thread->DecrementMemoryCapacity(size);
  } else if (ApiNativeScope::Current() != NULL) {
    // If there is no current thread, we might be inside of a native scope.
    ApiNativeScope::DecrementNativeScopeMemoryCapacity(size);
  }
}

// TODO(bkonyi): We need to account for the initial chunk size when a new zone
// is created within a new thread or ApiNativeScope when calculating high
// watermarks or memory consumption.
Zone::Zone()
    : initial_buffer_(buffer_, kInitialChunkSize),
      position_(initial_buffer_.start()),
      limit_(initial_buffer_.end()),
      head_(NULL),
      large_segments_(NULL),
      handles_(),
      previous_(NULL) {
  ASSERT(Utils::IsAligned(position_, kAlignment));
  Segment::IncrementMemoryCapacity(kInitialChunkSize);
#ifdef DEBUG
  // Zap the entire initial buffer.
  memset(initial_buffer_.pointer(), kZapUninitializedByte,
         initial_buffer_.size());
#endif
}

Zone::~Zone() {
  if (FLAG_trace_zones) {
    DumpZoneSizes();
  }
  DeleteAll();
  Segment::DecrementMemoryCapacity(kInitialChunkSize);
}

void Zone::DeleteAll() {
  // Traverse the chained list of segments, zapping (in debug mode)
  // and freeing every zone segment.
  if (head_ != NULL) {
    Segment::DeleteSegmentList(head_);
  }
  if (large_segments_ != NULL) {
    Segment::DeleteSegmentList(large_segments_);
  }
// Reset zone state.
#ifdef DEBUG
  memset(initial_buffer_.pointer(), kZapDeletedByte, initial_buffer_.size());
#endif
  position_ = initial_buffer_.start();
  limit_ = initial_buffer_.end();
  head_ = NULL;
  large_segments_ = NULL;
  previous_ = NULL;
  handles_.Reset();
}

uintptr_t Zone::SizeInBytes() const {
  uintptr_t size = 0;
  for (Segment* s = large_segments_; s != NULL; s = s->next()) {
    size += s->size();
  }
  if (head_ == NULL) {
    return size + (position_ - initial_buffer_.start());
  }
  size += initial_buffer_.size();
  for (Segment* s = head_->next(); s != NULL; s = s->next()) {
    size += s->size();
  }
  return size + (position_ - head_->start());
}

uintptr_t Zone::CapacityInBytes() const {
  uintptr_t size = 0;
  for (Segment* s = large_segments_; s != NULL; s = s->next()) {
    size += s->size();
  }
  if (head_ == NULL) {
    return size + initial_buffer_.size();
  }
  size += initial_buffer_.size();
  for (Segment* s = head_; s != NULL; s = s->next()) {
    size += s->size();
  }
  return size;
}

uword Zone::AllocateExpand(intptr_t size) {
  ASSERT(size >= 0);
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Expanding zone 0x%" Px "\n",
                 reinterpret_cast<intptr_t>(this));
    DumpZoneSizes();
  }
  // Make sure the requested size is already properly aligned and that
  // there isn't enough room in the Zone to satisfy the request.
  ASSERT(Utils::IsAligned(size, kAlignment));
  intptr_t free_size = (limit_ - position_);
  ASSERT(free_size < size);

  // First check to see if we should just chain it as a large segment.
  intptr_t max_size =
      Utils::RoundDown(kSegmentSize - sizeof(Segment), kAlignment);
  ASSERT(max_size > 0);
  if (size > max_size) {
    return AllocateLargeSegment(size);
  }

  // Allocate another segment and chain it up.
  head_ = Segment::New(kSegmentSize, head_);

  // Recompute 'position' and 'limit' based on the new head segment.
  uword result = Utils::RoundUp(head_->start(), kAlignment);
  position_ = result + size;
  limit_ = head_->end();
  ASSERT(position_ <= limit_);
  return result;
}

uword Zone::AllocateLargeSegment(intptr_t size) {
  ASSERT(size >= 0);
  // Make sure the requested size is already properly aligned and that
  // there isn't enough room in the Zone to satisfy the request.
  ASSERT(Utils::IsAligned(size, kAlignment));
  intptr_t free_size = (limit_ - position_);
  ASSERT(free_size < size);

  // Create a new large segment and chain it up.
  ASSERT(Utils::IsAligned(sizeof(Segment), kAlignment));
  size += sizeof(Segment);  // Account for book keeping fields in size.
  large_segments_ = Segment::New(size, large_segments_);

  uword result = Utils::RoundUp(large_segments_->start(), kAlignment);
  return result;
}

char* Zone::MakeCopyOfString(const char* str) {
  intptr_t len = strlen(str) + 1;  // '\0'-terminated.
  char* copy = Alloc<char>(len);
  strncpy(copy, str, len);
  return copy;
}

char* Zone::MakeCopyOfStringN(const char* str, intptr_t len) {
  ASSERT(len >= 0);
  for (intptr_t i = 0; i < len; i++) {
    if (str[i] == '\0') {
      len = i;
      break;
    }
  }
  char* copy = Alloc<char>(len + 1);  // +1 for '\0'
  strncpy(copy, str, len);
  copy[len] = '\0';
  return copy;
}

char* Zone::ConcatStrings(const char* a, const char* b, char join) {
  intptr_t a_len = (a == NULL) ? 0 : strlen(a);
  const intptr_t b_len = strlen(b) + 1;  // '\0'-terminated.
  const intptr_t len = a_len + b_len;
  char* copy = Alloc<char>(len);
  if (a_len > 0) {
    strncpy(copy, a, a_len);
    // Insert join character.
    copy[a_len++] = join;
  }
  strncpy(&copy[a_len], b, b_len);
  return copy;
}

void Zone::DumpZoneSizes() {
  intptr_t size = 0;
  for (Segment* s = large_segments_; s != NULL; s = s->next()) {
    size += s->size();
  }
  OS::PrintErr("***   Zone(0x%" Px
               ") size in bytes,"
               " Total = %" Pd " Large Segments = %" Pd "\n",
               reinterpret_cast<intptr_t>(this), SizeInBytes(), size);
}

void Zone::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  Zone* zone = this;
  while (zone != NULL) {
    zone->handles()->VisitObjectPointers(visitor);
    zone = zone->previous_;
  }
}

char* Zone::PrintToString(const char* format, ...) {
  va_list args;
  va_start(args, format);
  char* buffer = OS::VSCreate(this, format, args);
  va_end(args);
  return buffer;
}

char* Zone::VPrint(const char* format, va_list args) {
  return OS::VSCreate(this, format, args);
}

StackZone::StackZone(Thread* thread) : StackResource(thread), zone_() {
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Starting a new Stack zone 0x%" Px "(0x%" Px ")\n",
                 reinterpret_cast<intptr_t>(this),
                 reinterpret_cast<intptr_t>(&zone_));
  }
  zone_.Link(thread->zone());
  thread->set_zone(&zone_);
}

StackZone::~StackZone() {
  ASSERT(thread()->zone() == &zone_);
  thread()->set_zone(zone_.previous_);
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Deleting Stack zone 0x%" Px "(0x%" Px ")\n",
                 reinterpret_cast<intptr_t>(this),
                 reinterpret_cast<intptr_t>(&zone_));
  }
}

}  // namespace dart
