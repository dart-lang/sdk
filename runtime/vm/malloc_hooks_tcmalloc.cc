// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(DART_USE_TCMALLOC) && !defined(PRODUCT)

#include "vm/malloc_hooks.h"

#include "gperftools/malloc_hook.h"

#include "platform/assert.h"
#include "vm/hash_map.h"
#include "vm/json_stream.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"

namespace dart {

class AddressMap;

// MallocHooksState contains all of the state related to the configuration of
// the malloc hooks, allocation information, and locks.
class MallocHooksState : public AllStatic {
 public:
  static void RecordAllocHook(const void* ptr, size_t size);
  static void RecordFreeHook(const void* ptr);

  static bool Active() {
    ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
    return active_;
  }
  static void Init();

  static bool ProfilingEnabled() { return (OSThread::TryCurrent() != NULL); }

  static bool stack_trace_collection_enabled() {
    return stack_trace_collection_enabled_;
  }

  static void set_stack_trace_collection_enabled(bool enabled) {
    stack_trace_collection_enabled_ = enabled;
  }

  static bool IsOriginalProcess() {
    ASSERT(original_pid_ != kInvalidPid);
    return original_pid_ == OS::ProcessId();
  }

  static Mutex* malloc_hook_mutex() { return malloc_hook_mutex_; }
  static ThreadId* malloc_hook_mutex_owner() {
    return &malloc_hook_mutex_owner_;
  }
  static bool IsLockHeldByCurrentThread() {
    return (malloc_hook_mutex_owner_ == OSThread::GetCurrentThreadId());
  }

  static intptr_t allocation_count() { return allocation_count_; }

  static intptr_t heap_allocated_memory_in_bytes() {
    return heap_allocated_memory_in_bytes_;
  }

  static void IncrementHeapAllocatedMemoryInBytes(intptr_t size) {
    ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
    ASSERT(size >= 0);
    heap_allocated_memory_in_bytes_ += size;
    ++allocation_count_;
  }

  static void DecrementHeapAllocatedMemoryInBytes(intptr_t size) {
    ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
    ASSERT(size >= 0);
    ASSERT(heap_allocated_memory_in_bytes_ >= size);
    heap_allocated_memory_in_bytes_ -= size;
    --allocation_count_;
    ASSERT(allocation_count_ >= 0);
  }

  static AddressMap* address_map() { return address_map_; }

  static void ResetStats();
  static void TearDown();

 private:
  static Mutex* malloc_hook_mutex_;
  static ThreadId malloc_hook_mutex_owner_;

  // Variables protected by malloc_hook_mutex_.
  static bool active_;
  static bool stack_trace_collection_enabled_;
  static intptr_t allocation_count_;
  static intptr_t heap_allocated_memory_in_bytes_;
  static AddressMap* address_map_;
  // End protected variables.

  static intptr_t original_pid_;
  static const intptr_t kInvalidPid = -1;
};

// A locker-type class similar to MutexLocker which tracks which thread
// currently holds the lock. We use this instead of MutexLocker and
// mutex->IsOwnedByCurrentThread() since IsOwnedByCurrentThread() is only
// enabled for debug mode.
class MallocLocker : public ValueObject {
 public:
  explicit MallocLocker(Mutex* mutex, ThreadId* owner)
      : mutex_(mutex), owner_(owner) {
    ASSERT(owner != NULL);
    mutex_->Lock();
    ASSERT(*owner_ == OSThread::kInvalidThreadId);
    *owner_ = OSThread::GetCurrentThreadId();
  }

  virtual ~MallocLocker() {
    ASSERT(*owner_ == OSThread::GetCurrentThreadId());
    *owner_ = OSThread::kInvalidThreadId;
    mutex_->Unlock();
  }

 private:
  Mutex* mutex_;
  ThreadId* owner_;
};

// AllocationInfo contains all information related to a given allocation
// including:
//   -Allocation size in bytes
//   -Stack trace corresponding to the location of allocation, if applicable
class AllocationInfo {
 public:
  AllocationInfo(uword address, intptr_t allocation_size)
      : sample_(NULL), address_(address), allocation_size_(allocation_size) {
    // Stack trace collection is disabled when we are in the process of creating
    // the first OSThread in order to prevent deadlocks.
    if (MallocHooksState::ProfilingEnabled() &&
        MallocHooksState::stack_trace_collection_enabled()) {
      sample_ = Profiler::SampleNativeAllocation(kSkipCount, address,
                                                 allocation_size);
      ASSERT((sample_ == NULL) ||
             (sample_->native_allocation_address() == address_));
    }
  }

  Sample* sample() const { return sample_; }
  intptr_t allocation_size() const { return allocation_size_; }

 private:
  // Note: sample_ is not owned by AllocationInfo, but by the SampleBuffer
  // created by the profiler. As such, this is only here to track if the sample
  // is still associated with a native allocation, and its fields are never
  // accessed from this class.
  Sample* sample_;
  uword address_;
  intptr_t allocation_size_;
};


// Custom key/value trait specifically for address/size pairs. Unlike
// RawPointerKeyValueTrait, the default value is -1 as 0 can be a valid entry.
class AddressKeyValueTrait : public AllStatic {
 public:
  typedef const void* Key;
  typedef AllocationInfo* Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(NULL), value(NULL) {}
    Pair(const Key key, const Value& value) : key(key), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static intptr_t Hashcode(Key key) { return reinterpret_cast<intptr_t>(key); }
  static bool IsKeyEqual(Pair kv, Key key) { return kv.key == key; }
};


// Map class that will be used to store mappings between ptr -> allocation size.
class AddressMap : public MallocDirectChainedHashMap<AddressKeyValueTrait> {
 public:
  typedef AddressKeyValueTrait::Key Key;
  typedef AddressKeyValueTrait::Value Value;
  typedef AddressKeyValueTrait::Pair Pair;

  virtual ~AddressMap() { Clear(); }

  void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    MallocDirectChainedHashMap<AddressKeyValueTrait>::Insert(pair);
  }

  bool Lookup(const Key& key, Value* value) {
    ASSERT(value != NULL);
    Pair* pair = MallocDirectChainedHashMap<AddressKeyValueTrait>::Lookup(key);
    if (pair == NULL) {
      return false;
    } else {
      *value = pair->value;
      return true;
    }
  }

  void Clear() {
    Iterator iter = GetIterator();
    Pair* result = iter.Next();
    while (result != NULL) {
      delete result->value;
      result->value = NULL;
      result = iter.Next();
    }
    MallocDirectChainedHashMap<AddressKeyValueTrait>::Clear();
  }
};


// MallocHooks state / locks.
bool MallocHooksState::active_ = false;
bool MallocHooksState::stack_trace_collection_enabled_ = false;
intptr_t MallocHooksState::original_pid_ = MallocHooksState::kInvalidPid;
Mutex* MallocHooksState::malloc_hook_mutex_ = new Mutex();
ThreadId MallocHooksState::malloc_hook_mutex_owner_ =
    OSThread::kInvalidThreadId;

// Memory allocation state information.
intptr_t MallocHooksState::allocation_count_ = 0;
intptr_t MallocHooksState::heap_allocated_memory_in_bytes_ = 0;
AddressMap* MallocHooksState::address_map_ = NULL;


void MallocHooksState::Init() {
  address_map_ = new AddressMap();
  active_ = true;
#if defined(DEBUG)
  stack_trace_collection_enabled_ = true;
#else
  stack_trace_collection_enabled_ = false;
#endif  // defined(DEBUG)
  original_pid_ = OS::ProcessId();
}


void MallocHooksState::ResetStats() {
  ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
  allocation_count_ = 0;
  heap_allocated_memory_in_bytes_ = 0;
  address_map_->Clear();
}


void MallocHooksState::TearDown() {
  ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
  active_ = false;
  original_pid_ = kInvalidPid;
  ResetStats();
  delete address_map_;
  address_map_ = NULL;
}


void MallocHooks::InitOnce() {
  if (!FLAG_profiler_native_memory || MallocHooks::Active()) {
    return;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  ASSERT(!MallocHooksState::Active());

  MallocHooksState::Init();

  // Register malloc hooks.
  bool success = false;
  success = MallocHook::AddNewHook(&MallocHooksState::RecordAllocHook);
  ASSERT(success);
  success = MallocHook::AddDeleteHook(&MallocHooksState::RecordFreeHook);
  ASSERT(success);
}


void MallocHooks::TearDown() {
  if (!FLAG_profiler_native_memory || !MallocHooks::Active()) {
    return;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  ASSERT(MallocHooksState::Active());

  // Remove malloc hooks.
  bool success = false;
  success = MallocHook::RemoveNewHook(&MallocHooksState::RecordAllocHook);
  ASSERT(success);
  success = MallocHook::RemoveDeleteHook(&MallocHooksState::RecordFreeHook);
  ASSERT(success);

  MallocHooksState::TearDown();
}


bool MallocHooks::ProfilingEnabled() {
  return MallocHooksState::ProfilingEnabled();
}


bool MallocHooks::stack_trace_collection_enabled() {
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  return MallocHooksState::stack_trace_collection_enabled();
}


void MallocHooks::set_stack_trace_collection_enabled(bool enabled) {
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  MallocHooksState::set_stack_trace_collection_enabled(enabled);
}


void MallocHooks::ResetStats() {
  if (!FLAG_profiler_native_memory) {
    return;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  if (MallocHooksState::Active()) {
    MallocHooksState::ResetStats();
  }
}


bool MallocHooks::Active() {
  if (!FLAG_profiler_native_memory) {
    return false;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());

  return MallocHooksState::Active();
}


void MallocHooks::PrintToJSONObject(JSONObject* jsobj) {
  if (!FLAG_profiler_native_memory) {
    return;
  }
  intptr_t allocated_memory = 0;
  intptr_t allocation_count = 0;
  bool add_usage = false;
  // AddProperty may call malloc which would result in an attempt
  // to acquire the lock recursively so we extract the values first
  // and then add the JSON properties.
  {
    MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                    MallocHooksState::malloc_hook_mutex_owner());
    if (MallocHooksState::Active()) {
      allocated_memory = MallocHooksState::heap_allocated_memory_in_bytes();
      allocation_count = MallocHooksState::allocation_count();
      add_usage = true;
    }
  }
  if (add_usage) {
    jsobj->AddProperty("_heapAllocatedMemoryUsage", allocated_memory);
    jsobj->AddProperty("_heapAllocationCount", allocation_count);
  }
}


intptr_t MallocHooks::allocation_count() {
  if (!FLAG_profiler_native_memory) {
    return 0;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  return MallocHooksState::allocation_count();
}


intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  if (!FLAG_profiler_native_memory) {
    return 0;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  return MallocHooksState::heap_allocated_memory_in_bytes();
}


Sample* MallocHooks::GetSample(const void* ptr) {
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());

  ASSERT(MallocHooksState::Active());

  if (ptr != NULL) {
    AllocationInfo* allocation_info = NULL;
    if (MallocHooksState::address_map()->Lookup(ptr, &allocation_info)) {
      ASSERT(allocation_info != NULL);
      return allocation_info->sample();
    }
  }
  return NULL;
}


void MallocHooksState::RecordAllocHook(const void* ptr, size_t size) {
  if (MallocHooksState::IsLockHeldByCurrentThread() ||
      !MallocHooksState::IsOriginalProcess()) {
    return;
  }

  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  // Now that we hold the lock, check to make sure everything is still active.
  if ((ptr != NULL) && MallocHooksState::Active()) {
    MallocHooksState::IncrementHeapAllocatedMemoryInBytes(size);
    MallocHooksState::address_map()->Insert(
        ptr, new AllocationInfo(reinterpret_cast<uword>(ptr), size));
  }
}


void MallocHooksState::RecordFreeHook(const void* ptr) {
  if (MallocHooksState::IsLockHeldByCurrentThread() ||
      !MallocHooksState::IsOriginalProcess()) {
    return;
  }

  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  // Now that we hold the lock, check to make sure everything is still active.
  if ((ptr != NULL) && MallocHooksState::Active()) {
    AllocationInfo* allocation_info = NULL;
    if (MallocHooksState::address_map()->Lookup(ptr, &allocation_info)) {
      MallocHooksState::DecrementHeapAllocatedMemoryInBytes(
          allocation_info->allocation_size());
      const bool result = MallocHooksState::address_map()->Remove(ptr);
      ASSERT(result);
      delete allocation_info;
    }
  }
}

}  // namespace dart

#endif  // defined(DART_USE_TCMALLOC) && !defined(PRODUCT)
