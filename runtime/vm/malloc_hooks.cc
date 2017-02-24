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

namespace dart {

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


// Custom key/value trait specifically for address/size pairs. Unlike
// RawPointerKeyValueTrait, the default value is -1 as 0 can be a valid entry.
class AddressKeyValueTrait {
 public:
  typedef const void* Key;
  typedef intptr_t Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(NULL), value(-1) {}
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

  inline void Insert(const Key& key, const Value& value) {
    Pair pair(key, value);
    MallocDirectChainedHashMap<AddressKeyValueTrait>::Insert(pair);
  }

  inline bool Lookup(const Key& key, Value* value) {
    ASSERT(value != NULL);
    Pair* pair = MallocDirectChainedHashMap<AddressKeyValueTrait>::Lookup(key);
    if (pair == NULL) {
      return false;
    } else {
      *value = pair->value;
      return true;
    }
  }
};


class MallocHooksState : public AllStatic {
 public:
  static void RecordAllocHook(const void* ptr, size_t size);
  static void RecordFreeHook(const void* ptr);

  static bool Active() { return active_; }
  static void Init() {
    address_map_ = new AddressMap();
    active_ = true;
    original_pid_ = OS::ProcessId();
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

  static void ResetStats() {
    ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
    allocation_count_ = 0;
    heap_allocated_memory_in_bytes_ = 0;
    address_map_->Clear();
  }

  static void TearDown() {
    ASSERT(malloc_hook_mutex()->IsOwnedByCurrentThread());
    active_ = false;
    original_pid_ = kInvalidPid;
    ResetStats();
    delete address_map_;
  }

 private:
  static bool active_;
  static intptr_t original_pid_;
  static Mutex* malloc_hook_mutex_;
  static ThreadId malloc_hook_mutex_owner_;
  static intptr_t allocation_count_;
  static intptr_t heap_allocated_memory_in_bytes_;
  static AddressMap* address_map_;

  static const intptr_t kInvalidPid = -1;
};


// MallocHooks state / locks.
bool MallocHooksState::active_ = false;
intptr_t MallocHooksState::original_pid_ = MallocHooksState::kInvalidPid;
Mutex* MallocHooksState::malloc_hook_mutex_ = new Mutex();
ThreadId MallocHooksState::malloc_hook_mutex_owner_ =
    OSThread::kInvalidThreadId;

// Memory allocation state information.
intptr_t MallocHooksState::allocation_count_ = 0;
intptr_t MallocHooksState::heap_allocated_memory_in_bytes_ = 0;
AddressMap* MallocHooksState::address_map_ = NULL;


void MallocHooks::InitOnce() {
  if (!FLAG_enable_malloc_hooks) {
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
  if (!FLAG_enable_malloc_hooks) {
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


void MallocHooks::ResetStats() {
  if (!FLAG_enable_malloc_hooks) {
    return;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  if (MallocHooksState::Active()) {
    MallocHooksState::ResetStats();
  }
}


bool MallocHooks::Active() {
  if (!FLAG_enable_malloc_hooks) {
    return false;
  }
  ASSERT(MallocHooksState::malloc_hook_mutex()->IsOwnedByCurrentThread());
  return MallocHooksState::Active();
}


void MallocHooks::PrintToJSONObject(JSONObject* jsobj) {
  if (!FLAG_enable_malloc_hooks) {
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
    if (Active()) {
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
  if (!FLAG_enable_malloc_hooks) {
    return 0;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  return MallocHooksState::allocation_count();
}


intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  if (!FLAG_enable_malloc_hooks) {
    return 0;
  }
  MallocLocker ml(MallocHooksState::malloc_hook_mutex(),
                  MallocHooksState::malloc_hook_mutex_owner());
  return MallocHooksState::heap_allocated_memory_in_bytes();
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
    MallocHooksState::address_map()->Insert(ptr, size);
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
    intptr_t size = 0;
    if (MallocHooksState::address_map()->Lookup(ptr, &size)) {
      MallocHooksState::DecrementHeapAllocatedMemoryInBytes(size);
      MallocHooksState::address_map()->Remove(ptr);
    }
  }
}

}  // namespace dart

#endif  // defined(DART_USE_TCMALLOC) && !defined(PRODUCT)
