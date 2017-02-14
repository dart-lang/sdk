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
#include "vm/lockers.h"

namespace dart {

// A locker-type class to automatically grab and release the
// in_malloc_hook_flag_.
class MallocHookScope {
 public:
  static void InitMallocHookFlag() {
    ASSERT(in_malloc_hook_flag_ == kUnsetThreadLocalKey);
    in_malloc_hook_flag_ = OSThread::CreateThreadLocal();
    OSThread::SetThreadLocal(in_malloc_hook_flag_, 0);
  }

  static void DestroyMallocHookFlag() {
    ASSERT(in_malloc_hook_flag_ != kUnsetThreadLocalKey);
    OSThread::DeleteThreadLocal(in_malloc_hook_flag_);
    in_malloc_hook_flag_ = kUnsetThreadLocalKey;
  }

  MallocHookScope() {
    ASSERT(in_malloc_hook_flag_ != kUnsetThreadLocalKey);
    OSThread::SetThreadLocal(in_malloc_hook_flag_, 1);
  }

  ~MallocHookScope() {
    ASSERT(in_malloc_hook_flag_ != kUnsetThreadLocalKey);
    OSThread::SetThreadLocal(in_malloc_hook_flag_, 0);
  }

  static bool IsInHook() {
    ASSERT(in_malloc_hook_flag_ != kUnsetThreadLocalKey);
    return OSThread::GetThreadLocal(in_malloc_hook_flag_);
  }

 private:
  static ThreadLocalKey in_malloc_hook_flag_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(MallocHookScope);
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
  static intptr_t allocation_count_;
  static intptr_t heap_allocated_memory_in_bytes_;
  static AddressMap* address_map_;

  static const intptr_t kInvalidPid = -1;
};


// MallocHooks state / locks.
ThreadLocalKey MallocHookScope::in_malloc_hook_flag_ = kUnsetThreadLocalKey;
bool MallocHooksState::active_ = false;
intptr_t MallocHooksState::original_pid_ = MallocHooksState::kInvalidPid;
Mutex* MallocHooksState::malloc_hook_mutex_ = new Mutex();

// Memory allocation state information.
intptr_t MallocHooksState::allocation_count_ = 0;
intptr_t MallocHooksState::heap_allocated_memory_in_bytes_ = 0;
AddressMap* MallocHooksState::address_map_ = NULL;


void MallocHooks::InitOnce() {
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  ASSERT(!MallocHooksState::Active());

  MallocHookScope::InitMallocHookFlag();
  MallocHooksState::Init();

  // Register malloc hooks.
  bool success = false;
  success = MallocHook::AddNewHook(&MallocHooksState::RecordAllocHook);
  ASSERT(success);
  success = MallocHook::AddDeleteHook(&MallocHooksState::RecordFreeHook);
  ASSERT(success);
}


void MallocHooks::TearDown() {
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  ASSERT(MallocHooksState::Active());

  // Remove malloc hooks.
  bool success = false;
  success = MallocHook::RemoveNewHook(&MallocHooksState::RecordAllocHook);
  ASSERT(success);
  success = MallocHook::RemoveDeleteHook(&MallocHooksState::RecordFreeHook);
  ASSERT(success);

  MallocHooksState::TearDown();
  MallocHookScope::DestroyMallocHookFlag();
}


void MallocHooks::ResetStats() {
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  if (MallocHooksState::Active()) {
    MallocHooksState::ResetStats();
  }
}


bool MallocHooks::Active() {
  ASSERT(MallocHooksState::malloc_hook_mutex()->IsOwnedByCurrentThread());
  return MallocHooksState::Active();
}


void MallocHooks::PrintToJSONObject(JSONObject* jsobj) {
  intptr_t allocated_memory = 0;
  intptr_t allocation_count = 0;
  bool add_usage = false;
  // AddProperty may call malloc which would result in an attempt
  // to acquire the lock recursively so we extract the values first
  // and then add the JSON properties.
  {
    MutexLocker ml(MallocHooksState::malloc_hook_mutex());
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
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  return MallocHooksState::allocation_count();
}


intptr_t MallocHooks::heap_allocated_memory_in_bytes() {
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  return MallocHooksState::heap_allocated_memory_in_bytes();
}


void MallocHooksState::RecordAllocHook(const void* ptr, size_t size) {
  if (MallocHookScope::IsInHook() || !MallocHooksState::IsOriginalProcess()) {
    return;
  }

  // Set the malloc hook flag before grabbing the mutex to avoid calling hooks
  // again.
  MallocHookScope mhs;
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
  if ((ptr != NULL) && MallocHooksState::Active()) {
    MallocHooksState::IncrementHeapAllocatedMemoryInBytes(size);
    MallocHooksState::address_map()->Insert(ptr, size);
  }
}


void MallocHooksState::RecordFreeHook(const void* ptr) {
  if (MallocHookScope::IsInHook() || !MallocHooksState::IsOriginalProcess()) {
    return;
  }

  // Set the malloc hook flag before grabbing the mutex to avoid calling hooks
  // again.
  MallocHookScope mhs;
  MutexLocker ml(MallocHooksState::malloc_hook_mutex());
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
