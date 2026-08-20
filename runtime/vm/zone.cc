// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/zone.h"

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
#include <sys/prctl.h>
#elif defined(DART_HOST_OS_MACOS)
#if __has_include(<os/security_config.h>)
#include <os/security_config.h>
#endif
#endif

#include "platform/assert.h"
#include "platform/leak_sanitizer.h"
#include "platform/utils.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/handles_impl.h"
#include "vm/heap/heap.h"
#include "vm/os.h"
#include "vm/virtual_memory.h"

namespace dart {

RelaxedAtomic<intptr_t> Zone::total_size_ = {0};
bool Zone::memory_tagging_enabled_ = false;

// Zone segments represent chunks of memory: They have starting
// address encoded in the this pointer and a size in bytes. They are
// chained together to form the backing storage for an expanding zone.
class Zone::Segment {
 public:
  Segment* next() const { return next_; }
  intptr_t size() const { return size_; }
  VirtualMemory* memory() const { return memory_; }

  uword start() { return address(sizeof(Segment)); }
  uword end() { return address(size_); }

  // Allocate or delete individual segments.
  static Segment* New(intptr_t size, Segment* next);
  static void DeleteSegmentList(Segment* segment);

 private:
  Segment* next_;
  intptr_t size_;
  VirtualMemory* memory_;
  void* alignment_;

  // Computes the address of the nth byte in this segment.
  uword address(intptr_t n) { return reinterpret_cast<uword>(this) + n; }

  DISALLOW_IMPLICIT_CONSTRUCTORS(Segment);
};

// tcmalloc and jemalloc have both been observed to hold onto lots of free'd
// zone segments (jemalloc to the point of causing OOM), so instead of using
// malloc to allocate segments, we allocate directly from mmap/zx_vmo_create/
// VirtualAlloc, and cache a small number of the normal sized segments.
static constexpr intptr_t kSegmentCacheCapacity = 16;  // 1 MB of Segments
static Mutex* segment_cache_mutex = nullptr;
static VirtualMemory* segment_cache[kSegmentCacheCapacity] = {nullptr};
static intptr_t segment_cache_size = 0;

void Zone::Init() {
  ASSERT(segment_cache_mutex == nullptr);
  segment_cache_mutex = new Mutex();

#if defined(HOST_ARCH_ARM64) &&                                                \
    (defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX))

#if !defined(PR_SET_TAGGED_ADDR_CTRL)
#define PR_SET_TAGGED_ADDR_CTRL 55
#endif
#if !defined(PR_GET_TAGGED_ADDR_CTRL)
#define PR_GET_TAGGED_ADDR_CTRL 56
#endif
#if !defined(PR_TAGGED_ADDR_ENABLE)
#define PR_TAGGED_ADDR_ENABLE (1UL << 0)
#endif
#if !defined(PR_MTE_TCF_SYNC)
#define PR_MTE_TCF_SYNC (1UL << 1)
#endif
#if !defined(PR_MTE_TCF_ASYNC)
#define PR_MTE_TCF_ASYNC (1UL << 2)
#endif
#if !defined(PR_MTE_TAG_SHIFT)
#define PR_MTE_TAG_SHIFT 3
#endif

  // Enable memory tagging, with either sync or async failures, with random tag
  // generation creating any value except 0.
  prctl(PR_SET_TAGGED_ADDR_CTRL,
        PR_TAGGED_ADDR_ENABLE | PR_MTE_TCF_SYNC | PR_MTE_TCF_ASYNC |
            (0xfffe << PR_MTE_TAG_SHIFT),
        0L, 0L, 0L);
  int result = prctl(PR_GET_TAGGED_ADDR_CTRL, 0L, 0L, 0L, 0L);
  if (result == -1) {
    memory_tagging_enabled_ = false;
  } else {
    memory_tagging_enabled_ = (result & PR_TAGGED_ADDR_ENABLE) != 0;
  }
#endif

#if defined(HOST_ARCH_ARM64) && defined(DART_HOST_OS_MACOS)
#if __has_include(<os/security_config.h>)
  if (__builtin_available(macOS 26, iOS 26, *)) {
    memory_tagging_enabled_ =
        (os_security_config_get() & OS_SECURITY_CONFIG_MTE) != 0;
  } else {
    memory_tagging_enabled_ = false;
  }
#else
  memory_tagging_enabled_ = false;
#endif
#endif

  if (FLAG_trace_zones) {
    OS::PrintErr("Zone memory_tagging_enabled=%d use_initial_chunk=%d\n",
                 static_cast<int>(memory_tagging_enabled()),
                 static_cast<int>(use_initial_chunk()));
  }
}

void Zone::Cleanup() {
  ClearCache();
  delete segment_cache_mutex;
  segment_cache_mutex = nullptr;
}

void Zone::ClearCache() {
  MutexLocker ml(segment_cache_mutex);
  ASSERT(segment_cache_size >= 0);
  ASSERT(segment_cache_size <= kSegmentCacheCapacity);
  while (segment_cache_size > 0) {
    delete segment_cache[--segment_cache_size];
  }
}

#if defined(HOST_ARCH_ARM64) && defined(__GNUC__)
__attribute__((target("+mte")))
#endif
static void Zap(void* address, size_t size, unsigned char value) {
#ifdef DEBUG
  ASAN_UNPOISON(address, size);
  // If memory tagging is enabled, this will fault.
  if (!Zone::memory_tagging_enabled()) {
    memset(address, value, size);
  }
#endif

#if defined(HOST_ARCH_ARM64) && defined(__GNUC__)
  if (Zone::memory_tagging_enabled()) {
    uint8_t* start = reinterpret_cast<uint8_t*>(address);
    uint8_t* cursor = start;
    uint8_t* end = start + size;
    ASSERT(size > 0);
    ASSERT(Utils::IsAligned(size, 32));
    do {
      __builtin_arm_stg(cursor);
      cursor += 16;
    } while (cursor < end);
  }
#endif
}

Zone::Segment* Zone::Segment::New(intptr_t size, Zone::Segment* next) {
  size = Utils::RoundUp(size, VirtualMemory::PageSize());
  VirtualMemory* memory = nullptr;
  if (size == kSegmentSize) {
    MutexLocker ml(segment_cache_mutex);
    ASSERT(segment_cache_size >= 0);
    ASSERT(segment_cache_size <= kSegmentCacheCapacity);
    if (segment_cache_size > 0) {
      memory = segment_cache[--segment_cache_size];
    }
  }
  if (memory == nullptr) {
    if (memory_tagging_enabled_) {
      memory = VirtualMemory::AllocateMTE(size, "dart-zone");
    } else {
      bool executable = false;
      memory = VirtualMemory::Allocate(size, executable, "dart-zone");
    }
    total_size_.fetch_add(size);
  }
  if (memory == nullptr) {
    OUT_OF_MEMORY();
  }
  Segment* result = reinterpret_cast<Segment*>(memory->start());
  // Zap the entire allocated segment (including the header).
  Zap(reinterpret_cast<void*>(result), size, kZapUninitializedByte);
  result->next_ = next;
  result->size_ = size;
  result->memory_ = memory;
  result->alignment_ = nullptr;  // Avoid unused variable warnings.

  LSAN_REGISTER_ROOT_REGION(result, sizeof(*result));

  return result;
}

void Zone::Segment::DeleteSegmentList(Segment* head) {
  Segment* current = head;
  while (current != nullptr) {
    intptr_t size = current->size();
    Segment* next = current->next();
    VirtualMemory* memory = current->memory();
    // Zap the entire current segment (including the header).
    Zap(reinterpret_cast<void*>(current), current->size(), kZapDeletedByte);
    LSAN_UNREGISTER_ROOT_REGION(current, sizeof(*current));

    if (size == kSegmentSize) {
      MutexLocker ml(segment_cache_mutex);
      ASSERT(segment_cache_size >= 0);
      ASSERT(segment_cache_size <= kSegmentCacheCapacity);
      if (segment_cache_size < kSegmentCacheCapacity) {
        segment_cache[segment_cache_size++] = memory;
        memory = nullptr;
      }
    }
    if (memory != nullptr) {
      total_size_.fetch_sub(size);
      delete memory;
    }
    current = next;
  }
}

Zone::Zone()
    : position_(reinterpret_cast<uword>(&buffer_)),
      limit_(position_ + kInitialChunkSize),
      segments_(nullptr),
      previous_(nullptr),
      handles_() {
  ASSERT(Utils::IsAligned(position_, kAlignment));
  if (use_initial_chunk()) {
    Zap(&buffer_, kInitialChunkSize, kZapUninitializedByte);
  } else {
    position_ = limit_ = 0;
  }
}

Zone::~Zone() {
  if (FLAG_trace_zones) {
    Print();
  }
  Segment::DeleteSegmentList(segments_);
}

void Zone::Reset() {
  // Traverse the chained list of segments, zapping (in debug mode)
  // and freeing every zone segment.
  Segment::DeleteSegmentList(segments_);
  segments_ = nullptr;

  if (use_initial_chunk()) {
    Zap(&buffer_, kInitialChunkSize, kZapDeletedByte);
    position_ = reinterpret_cast<uword>(&buffer_);
    limit_ = position_ + kInitialChunkSize;
  } else {
    position_ = limit_ = 0;
  }
  size_ = 0;
  small_segment_capacity_ = 0;
  previous_ = nullptr;
  handles_.Reset();
}

uintptr_t Zone::SizeInBytes() const {
  return size_;
}

uintptr_t Zone::CapacityInBytes() const {
  uintptr_t size = kInitialChunkSize;
  for (Segment* s = segments_; s != nullptr; s = s->next()) {
    size += s->size();
  }
  return size;
}

void Zone::Print() const {
  intptr_t segment_size = CapacityInBytes();
  intptr_t scoped_handle_size = handles_.ScopedHandlesCapacityInBytes();
  intptr_t zone_handle_size = handles_.ZoneHandlesCapacityInBytes();
  intptr_t total_size = segment_size + scoped_handle_size + zone_handle_size;
  OS::PrintErr("Zone(%p, segments: %" Pd ", scoped_handles: %" Pd
               ", zone_handles: %" Pd ", total: %" Pd ")\n",
               this, segment_size, scoped_handle_size, zone_handle_size,
               total_size);
}

uword Zone::AllocateExpand(intptr_t size) {
  ASSERT(size >= 0);
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Expanding zone 0x%" Px "\n",
                 reinterpret_cast<intptr_t>(this));
    Print();
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

  const intptr_t kSuperPageSize = 2 * MB;
  intptr_t next_size;
  if (small_segment_capacity_ < kSuperPageSize) {
    // When the Zone is small, grow linearly to reduce size and use the segment
    // cache to avoid expensive mmap calls.
    next_size = kSegmentSize;
  } else {
    // When the Zone is large, grow geometrically to avoid Page Table Entry
    // exhaustion. Using 1.125 ratio.
    next_size = Utils::RoundUp(small_segment_capacity_ >> 3, kSuperPageSize);
  }
  ASSERT(next_size >= kSegmentSize);

  // Allocate another segment and chain it up.
  segments_ = Segment::New(next_size, segments_);
  small_segment_capacity_ += next_size;

  // Recompute 'position' and 'limit' based on the new head segment.
  uword result = Utils::RoundUp(segments_->start(), kAlignment);
  position_ = result + size;
  limit_ = segments_->end();
  size_ += size;
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
  // Account for book keeping fields in size.
  size_ += size;
  size += Utils::RoundUp(sizeof(Segment), kAlignment);
  segments_ = Segment::New(size, segments_);

  uword result = Utils::RoundUp(segments_->start(), kAlignment);
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
  intptr_t a_len = (a == nullptr) ? 0 : strlen(a);
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

void Zone::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  Zone* zone = this;
  while (zone != nullptr) {
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

StackZone::StackZone(ThreadState* thread)
#if defined(DART_USE_ABSL)
    // DART_USE_ABSL encodes the use of fibers in the Dart VM for threading.
    : StackResource(thread), zone_(new Zone()) {
#else
    : StackResource(thread), zone_() {
#endif  // defined(DART_USE_ABSL)
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Starting a new Stack zone 0x%" Px "(0x%" Px ")\n",
                 reinterpret_cast<intptr_t>(this),
                 reinterpret_cast<intptr_t>(GetZone()));
  }

  // This thread must be preventing safepoints or the GC could be visiting the
  // chain of handle blocks we're about the mutate.
  ASSERT(Thread::Current()->MayAllocateHandles());

  Zone* lzone = GetZone();
  lzone->Link(thread->zone());
  thread->set_zone(lzone);
}

StackZone::~StackZone() {
  // This thread must be preventing safepoints or the GC could be visiting the
  // chain of handle blocks we're about the mutate.
  ASSERT(Thread::Current()->MayAllocateHandles());

  Zone* lzone = GetZone();
  ASSERT(thread()->zone() == lzone);
  thread()->set_zone(lzone->previous_);
  if (FLAG_trace_zones) {
    OS::PrintErr("*** Deleting Stack zone 0x%" Px "(0x%" Px ")\n",
                 reinterpret_cast<intptr_t>(this),
                 reinterpret_cast<intptr_t>(lzone));
  }

#if defined(DART_USE_ABSL)
  // DART_USE_ABSL encodes the use of fibers in the Dart VM for threading.
  delete zone_;
#endif  // defined(DART_USE_ABSL)
}

}  // namespace dart
