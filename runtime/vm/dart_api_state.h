// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DART_API_STATE_H_
#define RUNTIME_VM_DART_API_STATE_H_

#include "include/dart_api.h"
#include "platform/utils.h"
#include "vm/bitfield.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/handles_impl.h"
#include "vm/heap/weak_table.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/os_thread.h"
#include "vm/raw_object.h"
#include "vm/thread_pool.h"
#include "vm/visitor.h"

namespace dart {

// Implementation of Zone support for very fast allocation of small chunks
// of memory. The chunks cannot be deallocated individually, but instead
// zones support deallocating all chunks in one fast operation when the
// scope is exited.
class ApiZone {
 public:
  // Create an empty zone.
  ApiZone() : zone_() {
    Thread* thread = Thread::Current();
    Zone* zone = thread != nullptr ? thread->zone() : nullptr;
    zone_.Link(zone);
    if (thread != nullptr) {
      thread->set_zone(&zone_);
    }
    if (FLAG_trace_zones) {
      OS::PrintErr("*** Starting a new Api zone 0x%" Px "(0x%" Px ")\n",
                   reinterpret_cast<intptr_t>(this),
                   reinterpret_cast<intptr_t>(&zone_));
    }
  }

  // Delete all memory associated with the zone.
  ~ApiZone() {
    Thread* thread = Thread::Current();
#if defined(DEBUG)
    if (thread == nullptr) {
      ASSERT(zone_.handles()->CountScopedHandles() == 0);
      ASSERT(zone_.handles()->CountZoneHandles() == 0);
    }
#endif
    if ((thread != nullptr) && (thread->zone() == &zone_)) {
      thread->set_zone(zone_.previous_);
    }
    if (FLAG_trace_zones) {
      OS::PrintErr("*** Deleting Api zone 0x%" Px "(0x%" Px ")\n",
                   reinterpret_cast<intptr_t>(this),
                   reinterpret_cast<intptr_t>(&zone_));
    }
  }

  // Allocates an array sized to hold 'len' elements of type
  // 'ElementType'.  Checks for integer overflow when performing the
  // size computation.
  template <class ElementType>
  ElementType* Alloc(intptr_t len) {
    return zone_.Alloc<ElementType>(len);
  }

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

  Zone* GetZone() { return &zone_; }

  void Reinit(Thread* thread) {
    if (thread == nullptr) {
      zone_.Link(nullptr);
    } else {
      zone_.Link(thread->zone());
      thread->set_zone(&zone_);
    }
  }

  void Reset(Thread* thread) {
    if ((thread != nullptr) && (thread->zone() == &zone_)) {
      thread->set_zone(zone_.previous_);
    }
    zone_.Reset();
  }

 private:
  Zone zone_;

  template <typename T>
  friend class ApiGrowableArray;
  DISALLOW_COPY_AND_ASSIGN(ApiZone);
};

// Implementation of local handles which are handed out from every
// dart API call, these handles are valid only in the present scope
// and are destroyed when a Dart_ExitScope() is called.
class LocalHandle {
 public:
  // Accessors.
  ObjectPtr ptr() const { return ptr_; }
  void set_ptr(ObjectPtr ptr) { ptr_ = ptr; }
  static intptr_t ptr_offset() { return OFFSET_OF(LocalHandle, ptr_); }

  Dart_Handle apiHandle() { return reinterpret_cast<Dart_Handle>(this); }

 private:
  LocalHandle() {}
  ~LocalHandle() {}

  ObjectPtr ptr_;
  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(LocalHandle);
};

// A distinguished callback which indicates that a persistent handle
// should not be deleted from the dart api.
void ProtectedHandleCallback(void* peer);

// Implementation of persistent handles which are handed out through the
// dart API.
class PersistentHandle {
 public:
  // Accessors.
  ObjectPtr ptr() const { return ptr_; }
  void set_ptr(ObjectPtr ref) { ptr_ = ref; }
  void set_ptr(const LocalHandle& ref) { ptr_ = ref.ptr(); }
  void set_ptr(const Object& object) { ptr_ = object.ptr(); }
  ObjectPtr* raw_addr() { return &ptr_; }

  Dart_PersistentHandle apiHandle() {
    return reinterpret_cast<Dart_PersistentHandle>(this);
  }

  static intptr_t ptr_offset() { return OFFSET_OF(PersistentHandle, ptr_); }

  static PersistentHandle* Cast(Dart_PersistentHandle handle);

 private:
  friend class PersistentHandles;

  PersistentHandle() {}
  ~PersistentHandle() {}

  // Overload the ptr_ field as a next pointer when adding freed
  // handles to the free list.
  PersistentHandle* Next() {
    return reinterpret_cast<PersistentHandle*>(static_cast<uword>(ptr_));
  }
  void SetNext(PersistentHandle* free_list) {
    ptr_ = static_cast<ObjectPtr>(reinterpret_cast<uword>(free_list));
    ASSERT(!ptr_->IsHeapObject());
  }
  void FreeHandle(PersistentHandle* free_list) { SetNext(free_list); }

  ObjectPtr ptr_;
  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(PersistentHandle);
};

// Implementation of persistent handles which are handed out through the
// dart API.
class FinalizablePersistentHandle {
 public:
  static FinalizablePersistentHandle* New(IsolateGroup* isolate_group,
                                          const Object& object,
                                          void* peer,
                                          Dart_HandleFinalizer callback,
                                          intptr_t external_size,
                                          bool auto_delete);

  // Accessors.
  ObjectPtr ptr() const { return ptr_; }
  ObjectPtr* ptr_addr() { return &ptr_; }
  static intptr_t ptr_offset() {
    return OFFSET_OF(FinalizablePersistentHandle, ptr_);
  }
  void* peer() const { return peer_; }
  Dart_HandleFinalizer callback() const { return callback_; }
  Dart_WeakPersistentHandle ApiWeakPersistentHandle() {
    return reinterpret_cast<Dart_WeakPersistentHandle>(this);
  }
  Dart_FinalizableHandle ApiFinalizableHandle() {
    return reinterpret_cast<Dart_FinalizableHandle>(this);
  }

  bool auto_delete() const { return auto_delete_; }

  bool IsFinalizedNotFreed() const {
    return ptr_ == static_cast<ObjectPtr>(reinterpret_cast<uword>(this));
  }

  intptr_t external_size() const {
    return ExternalSizeInWordsBits::decode(external_data_) * kWordSize;
  }

  bool SetExternalSize(intptr_t size, IsolateGroup* isolate_group) {
    // This method only behaves correctly when external_size() has not been
    // previously modified.
    ASSERT(external_size() == 0);
    if (size < 0 || (size >> kWordSizeLog2) > kMaxAddrSpaceInWords) {
      return false;
    }
    set_external_size(size);
    if (SpaceForExternal() == Heap::kNew) {
      SetExternalNewSpaceBit();
    }
    return isolate_group->heap()->AllocatedExternal(external_size(),
                                                    SpaceForExternal());
  }

  // Called when the referent becomes unreachable.
  void UpdateUnreachable(IsolateGroup* isolate_group) {
    EnsureFreedExternal(isolate_group);
    Finalize(isolate_group, this);
  }

  // Called when the referent has moved, potentially between generations.
  void UpdateRelocated(IsolateGroup* isolate_group) {
    if (IsSetNewSpaceBit() && (SpaceForExternal() == Heap::kOld)) {
      isolate_group->heap()->PromotedExternal(external_size());
      ClearExternalNewSpaceBit();
    }
  }

  // Idempotent. Called when the handle is explicitly deleted or the
  // referent becomes unreachable.
  void EnsureFreedExternal(IsolateGroup* isolate_group) {
    isolate_group->heap()->FreedExternal(external_size(), SpaceForExternal());
    set_external_size(0);
  }

  static FinalizablePersistentHandle* Cast(Dart_WeakPersistentHandle handle);
  static FinalizablePersistentHandle* Cast(Dart_FinalizableHandle handle);

 private:
  enum {
    kExternalNewSpaceBit = 0,
    kExternalSizeBits = 1,
    kExternalSizeBitsSize = (kBitsPerWord - 1),
  };

  // This part of external_data_ is the number of externally allocated bytes.
  class ExternalSizeInWordsBits : public BitField<uword,
                                                  intptr_t,
                                                  kExternalSizeBits,
                                                  kExternalSizeBitsSize> {};
  // This bit of external_data_ is true if the referent was created in new
  // space and UpdateRelocated has not yet detected any promotion.
  class ExternalNewSpaceBit
      : public BitField<uword, bool, kExternalNewSpaceBit, 1> {};

  friend class FinalizablePersistentHandles;

  FinalizablePersistentHandle()
      : ptr_(nullptr), peer_(nullptr), external_data_(0), callback_(nullptr) {}
  ~FinalizablePersistentHandle() {}

  static void Finalize(IsolateGroup* isolate_group,
                       FinalizablePersistentHandle* handle);

  // Overload the ptr_ field as a next pointer when adding freed
  // handles to the free list.
  FinalizablePersistentHandle* Next() {
    return reinterpret_cast<FinalizablePersistentHandle*>(
        static_cast<uword>(ptr_));
  }
  void SetNext(FinalizablePersistentHandle* free_list) {
    ptr_ = static_cast<ObjectPtr>(reinterpret_cast<uword>(free_list));
    ASSERT(!ptr_->IsHeapObject());
  }

  void SetFinalizedNotFreed() {
    // `handle->raw_ != Object::null()` or the GC will finalize again.
    SetNext(this);
  }

  void FreeHandle(FinalizablePersistentHandle* free_list) {
    Clear();
    SetNext(free_list);
  }

  void Clear() {
    ptr_ = Object::null();
    peer_ = nullptr;
    external_data_ = 0;
    callback_ = nullptr;
    auto_delete_ = false;
  }

  void set_ptr(ObjectPtr raw) { ptr_ = raw; }
  void set_ptr(const LocalHandle& ref) { ptr_ = ref.ptr(); }
  void set_ptr(const Object& object) { ptr_ = object.ptr(); }

  void set_peer(void* peer) { peer_ = peer; }

  void set_callback(Dart_HandleFinalizer callback) { callback_ = callback; }

  void set_auto_delete(bool auto_delete) { auto_delete_ = auto_delete; }

  void set_external_size(intptr_t size) {
    intptr_t size_in_words = Utils::RoundUp(size, kObjectAlignment) / kWordSize;
    ASSERT(ExternalSizeInWordsBits::is_valid(size_in_words));
    external_data_ =
        ExternalSizeInWordsBits::update(size_in_words, external_data_);
  }

  bool IsSetNewSpaceBit() const {
    return ExternalNewSpaceBit::decode(external_data_);
  }

  void SetExternalNewSpaceBit() {
    external_data_ = ExternalNewSpaceBit::update(true, external_data_);
  }

  void ClearExternalNewSpaceBit() {
    external_data_ = ExternalNewSpaceBit::update(false, external_data_);
  }

  // Returns the space to charge for the external size.
  Heap::Space SpaceForExternal() const {
    // Non-heap and VM-heap objects count as old space here.
    return ptr_->IsImmediateOrOldObject() ? Heap::kOld : Heap::kNew;
  }

  ObjectPtr ptr_;
  void* peer_;
  uword external_data_;
  Dart_HandleFinalizer callback_;
  bool auto_delete_;

  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(FinalizablePersistentHandle);
};

// Local handles repository structure.
static constexpr int kLocalHandleSizeInWords = sizeof(LocalHandle) / kWordSize;
static constexpr int kLocalHandlesPerChunk = 64;
static constexpr int kOffsetOfRawPtrInLocalHandle = 0;
class LocalHandles : Handles<kLocalHandleSizeInWords,
                             kLocalHandlesPerChunk,
                             kOffsetOfRawPtrInLocalHandle> {
 public:
  LocalHandles()
      : Handles<kLocalHandleSizeInWords,
                kLocalHandlesPerChunk,
                kOffsetOfRawPtrInLocalHandle>() {
    if (FLAG_trace_handles) {
      OS::PrintErr("*** Starting a new Local handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
  }
  ~LocalHandles() {
    if (FLAG_trace_handles) {
      OS::PrintErr("***   Handle Counts for 0x(%" Px "):Scoped = %d\n",
                   reinterpret_cast<intptr_t>(this), CountHandles());
      OS::PrintErr("*** Deleting Local handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
  }

  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    visitor->set_gc_root_type("local handle");
    Handles<kLocalHandleSizeInWords, kLocalHandlesPerChunk,
            kOffsetOfRawPtrInLocalHandle>::VisitObjectPointers(visitor);
    visitor->clear_gc_root_type();
  }

  // Reset the local handles block for reuse.
  void Reset() {
    Handles<kLocalHandleSizeInWords, kLocalHandlesPerChunk,
            kOffsetOfRawPtrInLocalHandle>::Reset();
  }

  // Allocates a handle in the current handle scope. This handle is valid only
  // in the current handle scope and is destroyed when the current handle
  // scope ends.
  LocalHandle* AllocateHandle() {
    return reinterpret_cast<LocalHandle*>(AllocateScopedHandle());
  }

  // Validate if passed in handle is a Local Handle.
  bool IsValidHandle(Dart_Handle object) const {
    return IsValidScopedHandle(reinterpret_cast<uword>(object));
  }

  // Returns a count of active handles (used for testing purposes).
  int CountHandles() const { return CountScopedHandles(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(LocalHandles);
};

// Persistent handles repository structure.
static constexpr int kPersistentHandleSizeInWords =
    sizeof(PersistentHandle) / kWordSize;
static constexpr int kPersistentHandlesPerChunk = 64;
static constexpr int kOffsetOfRawPtrInPersistentHandle = 0;
class PersistentHandles : Handles<kPersistentHandleSizeInWords,
                                  kPersistentHandlesPerChunk,
                                  kOffsetOfRawPtrInPersistentHandle> {
 public:
  PersistentHandles()
      : Handles<kPersistentHandleSizeInWords,
                kPersistentHandlesPerChunk,
                kOffsetOfRawPtrInPersistentHandle>(),
        free_list_(nullptr) {
    if (FLAG_trace_handles) {
      OS::PrintErr("*** Starting a new Persistent handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
  }
  ~PersistentHandles() {
    free_list_ = nullptr;
    if (FLAG_trace_handles) {
      OS::PrintErr("***   Handle Counts for 0x(%" Px "):Scoped = %d\n",
                   reinterpret_cast<intptr_t>(this), CountHandles());
      OS::PrintErr("*** Deleting Persistent handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
  }

  // Accessors.
  PersistentHandle* free_list() const { return free_list_; }
  void set_free_list(PersistentHandle* value) { free_list_ = value; }

  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    visitor->set_gc_root_type("persistent handle");
    Handles<kPersistentHandleSizeInWords, kPersistentHandlesPerChunk,
            kOffsetOfRawPtrInPersistentHandle>::VisitObjectPointers(visitor);
    visitor->clear_gc_root_type();
  }

  // Visit all the handles.
  void Visit(HandleVisitor* visitor) {
    Handles<kPersistentHandleSizeInWords, kPersistentHandlesPerChunk,
            kOffsetOfRawPtrInPersistentHandle>::Visit(visitor);
  }

  // Allocates a persistent handle, these have to be destroyed explicitly
  // by calling FreeHandle.
  PersistentHandle* AllocateHandle() {
    PersistentHandle* handle;
    if (free_list_ != nullptr) {
      handle = free_list_;
      free_list_ = handle->Next();
    } else {
      handle = reinterpret_cast<PersistentHandle*>(AllocateScopedHandle());
    }
    handle->set_ptr(Object::null());
    return handle;
  }

  void FreeHandle(PersistentHandle* handle) {
    handle->FreeHandle(free_list());
    set_free_list(handle);
  }

  // Validate if passed in handle is a Persistent Handle.
  bool IsValidHandle(Dart_PersistentHandle object) const {
    return IsValidScopedHandle(reinterpret_cast<uword>(object));
  }

  bool IsFreeHandle(Dart_PersistentHandle object) const {
    PersistentHandle* handle = free_list_;
    while (handle != nullptr) {
      if (handle == reinterpret_cast<PersistentHandle*>(object)) {
        return true;
      }
      handle = handle->Next();
    }
    return false;
  }

  // Returns a count of active handles (used for testing purposes).
  int CountHandles() const { return CountScopedHandles(); }

 private:
  PersistentHandle* free_list_;
  DISALLOW_COPY_AND_ASSIGN(PersistentHandles);
};

// Finalizable persistent handles repository structure.
static constexpr int kFinalizablePersistentHandleSizeInWords =
    sizeof(FinalizablePersistentHandle) / kWordSize;
static constexpr int kFinalizablePersistentHandlesPerChunk = 64;
static constexpr int kOffsetOfRawPtrInFinalizablePersistentHandle = 0;
class FinalizablePersistentHandles
    : Handles<kFinalizablePersistentHandleSizeInWords,
              kFinalizablePersistentHandlesPerChunk,
              kOffsetOfRawPtrInFinalizablePersistentHandle> {
 public:
  FinalizablePersistentHandles()
      : Handles<kFinalizablePersistentHandleSizeInWords,
                kFinalizablePersistentHandlesPerChunk,
                kOffsetOfRawPtrInFinalizablePersistentHandle>(),
        free_list_(nullptr) {}
  ~FinalizablePersistentHandles() { free_list_ = nullptr; }

  // Accessors.
  FinalizablePersistentHandle* free_list() const { return free_list_; }
  void set_free_list(FinalizablePersistentHandle* value) { free_list_ = value; }

  // Visit all handles stored in the various handle blocks.
  void VisitHandles(HandleVisitor* visitor) {
    Handles<kFinalizablePersistentHandleSizeInWords,
            kFinalizablePersistentHandlesPerChunk,
            kOffsetOfRawPtrInFinalizablePersistentHandle>::Visit(visitor);
  }

  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    visitor->set_gc_root_type("weak persistent handle");
    Handles<kFinalizablePersistentHandleSizeInWords,
            kFinalizablePersistentHandlesPerChunk,
            kOffsetOfRawPtrInFinalizablePersistentHandle>::
        VisitObjectPointers(visitor);
    visitor->clear_gc_root_type();
  }

  // Allocates a persistent handle, these have to be destroyed explicitly
  // by calling FreeHandle.
  FinalizablePersistentHandle* AllocateHandle() {
    FinalizablePersistentHandle* handle;
    if (free_list_ != nullptr) {
      handle = free_list_;
      free_list_ = handle->Next();
      handle->set_ptr(Object::null());
      return handle;
    }

    handle =
        reinterpret_cast<FinalizablePersistentHandle*>(AllocateScopedHandle());
    handle->Clear();
    return handle;
  }

  void ClearHandle(FinalizablePersistentHandle* handle) {
    handle->Clear();
    handle->SetFinalizedNotFreed();
  }

  void FreeHandle(FinalizablePersistentHandle* handle) {
    handle->FreeHandle(free_list());
    set_free_list(handle);
  }

  // Validate if passed in handle is a Persistent Handle.
  bool IsValidHandle(Dart_WeakPersistentHandle object) const {
    return IsValidScopedHandle(reinterpret_cast<uword>(object));
  }

  bool IsValidHandle(Dart_FinalizableHandle object) const {
    return IsValidScopedHandle(reinterpret_cast<uword>(object));
  }

  bool IsFreeHandle(Dart_WeakPersistentHandle object) const {
    FinalizablePersistentHandle* handle = free_list_;
    while (handle != nullptr) {
      if (handle == reinterpret_cast<FinalizablePersistentHandle*>(object)) {
        return true;
      }
      handle = handle->Next();
    }
    return false;
  }

  // Returns a count of active handles (used for testing purposes).
  int CountHandles() const { return CountScopedHandles(); }

 private:
  FinalizablePersistentHandle* free_list_;
  DISALLOW_COPY_AND_ASSIGN(FinalizablePersistentHandles);
};

// Structure used for the implementation of local scopes used in dart_api.
// These local scopes manage handles and memory allocated in the scope.
class ApiLocalScope {
 public:
  ApiLocalScope(ApiLocalScope* previous, uword stack_marker)
      : previous_(previous), stack_marker_(stack_marker) {}
  ~ApiLocalScope() { previous_ = nullptr; }

  // Reinit the ApiLocalScope to new values.
  void Reinit(Thread* thread, ApiLocalScope* previous, uword stack_marker) {
    previous_ = previous;
    stack_marker_ = stack_marker;
    zone_.Reinit(thread);
  }

  // Reset the ApiLocalScope so that it can be reused again.
  void Reset(Thread* thread) {
    local_handles_.Reset();
    zone_.Reset(thread);
    previous_ = nullptr;
    stack_marker_ = 0;
  }

  // Accessors.
  ApiLocalScope* previous() const { return previous_; }
  uword stack_marker() const { return stack_marker_; }
  void set_previous(ApiLocalScope* value) { previous_ = value; }
  LocalHandles* local_handles() { return &local_handles_; }
  Zone* zone() { return zone_.GetZone(); }

 private:
  ApiLocalScope* previous_;
  uword stack_marker_;
  LocalHandles local_handles_;
  ApiZone zone_;

  DISALLOW_COPY_AND_ASSIGN(ApiLocalScope);
};

class ApiNativeScope {
 public:
  ApiNativeScope() {
    // Currently no support for nesting native scopes.
    ASSERT(Current() == nullptr);
    OSThread::SetThreadLocal(Api::api_native_key_,
                             reinterpret_cast<uword>(this));
  }

  ~ApiNativeScope() {
    ASSERT(Current() == this);
    OSThread::SetThreadLocal(Api::api_native_key_, 0);
  }

  static inline ApiNativeScope* Current() {
    return reinterpret_cast<ApiNativeScope*>(
        OSThread::GetThreadLocal(Api::api_native_key_));
  }

  Zone* zone() {
    Zone* result = zone_.GetZone();
    ASSERT(result->handles()->CountScopedHandles() == 0);
    ASSERT(result->handles()->CountZoneHandles() == 0);
    return result;
  }

 private:
  ApiZone zone_;
};

// Api growable arrays use a zone for allocation. The constructor
// picks the zone from the current isolate if in an isolate
// environment. When outside an isolate environment it picks the zone
// from the current native scope.
template <typename T>
class ApiGrowableArray : public BaseGrowableArray<T, ValueObject, Zone> {
 public:
  explicit ApiGrowableArray(int initial_capacity)
      : BaseGrowableArray<T, ValueObject, Zone>(
            initial_capacity,
            ApiNativeScope::Current()->zone()) {}
  ApiGrowableArray()
      : BaseGrowableArray<T, ValueObject, Zone>(
            ApiNativeScope::Current()->zone()) {}
  ApiGrowableArray(intptr_t initial_capacity, Zone* zone)
      : BaseGrowableArray<T, ValueObject, Zone>(initial_capacity, zone) {}
};

// Implementation of the API State used in dart api for maintaining
// local scopes, persistent handles etc. These are setup on a per isolate
// group basis and destroyed when the isolate group is shutdown.
class ApiState {
 public:
  ApiState() : persistent_handles_(), weak_persistent_handles_() {}

  void MergeOtherApiState(ApiState* api_state);

  void VisitObjectPointersUnlocked(ObjectPointerVisitor* visitor) {
    persistent_handles_.VisitObjectPointers(visitor);
    if (visitor->visit_weak_persistent_handles()) {
      weak_persistent_handles_.VisitObjectPointers(visitor);
    }
  }

  void VisitWeakHandlesUnlocked(HandleVisitor* visitor) {
    weak_persistent_handles_.VisitHandles(visitor);
  }

  PersistentHandle* AllocatePersistentHandle() {
    MutexLocker ml(&mutex_);
    return persistent_handles_.AllocateHandle();
  }
  void FreePersistentHandle(PersistentHandle* ref) {
    MutexLocker ml(&mutex_);
    persistent_handles_.FreeHandle(ref);
  }

  FinalizablePersistentHandle* AllocateWeakPersistentHandle() {
    MutexLocker ml(&mutex_);
    return weak_persistent_handles_.AllocateHandle();
  }
  void ClearWeakPersistentHandle(FinalizablePersistentHandle* weak_ref) {
    MutexLocker ml(&mutex_);
    weak_persistent_handles_.ClearHandle(weak_ref);
  }
  void FreeWeakPersistentHandle(FinalizablePersistentHandle* weak_ref) {
    MutexLocker ml(&mutex_);
    weak_persistent_handles_.FreeHandle(weak_ref);
  }

  bool IsValidPersistentHandle(Dart_PersistentHandle object) {
    MutexLocker ml(&mutex_);
    return persistent_handles_.IsValidHandle(object);
  }

  bool IsActivePersistentHandle(Dart_PersistentHandle object) {
    MutexLocker ml(&mutex_);
    return persistent_handles_.IsValidHandle(object) &&
           !persistent_handles_.IsFreeHandle(object);
  }

  bool IsValidWeakPersistentHandle(Dart_WeakPersistentHandle object) {
    MutexLocker ml(&mutex_);
    return weak_persistent_handles_.IsValidHandle(object);
  }

  bool IsValidFinalizableHandle(Dart_FinalizableHandle object) {
    MutexLocker ml(&mutex_);
    return weak_persistent_handles_.IsValidHandle(object);
  }

  bool IsActiveWeakPersistentHandle(Dart_WeakPersistentHandle object) {
    MutexLocker ml(&mutex_);
    return weak_persistent_handles_.IsValidHandle(object) &&
           !weak_persistent_handles_.IsFreeHandle(object);
  }

  int CountPersistentHandles() {
    MutexLocker ml(&mutex_);
    return persistent_handles_.CountHandles();
  }

  void RunWithLockedPersistentHandles(
      std::function<void(PersistentHandles&)> fun) {
    MutexLocker ml(&mutex_);
    fun(persistent_handles_);
  }

  void RunWithLockedWeakPersistentHandles(
      std::function<void(FinalizablePersistentHandles&)> fun) {
    MutexLocker ml(&mutex_);
    fun(weak_persistent_handles_);
  }

  WeakTable* acquired_table() { return &acquired_table_; }

 private:
  Mutex mutex_;

  PersistentHandles persistent_handles_;
  FinalizablePersistentHandles weak_persistent_handles_;
  WeakTable acquired_table_;

  DISALLOW_COPY_AND_ASSIGN(ApiState);
};

inline FinalizablePersistentHandle* FinalizablePersistentHandle::New(
    IsolateGroup* isolate_group,
    const Object& object,
    void* peer,
    Dart_HandleFinalizer callback,
    intptr_t external_size,
    bool auto_delete) {
  ApiState* state = isolate_group->api_state();
  ASSERT(state != nullptr);
  FinalizablePersistentHandle* ref = state->AllocateWeakPersistentHandle();
  ref->set_ptr(object);
  ref->set_peer(peer);
  ref->set_callback(callback);
  ref->set_auto_delete(auto_delete);
  // This may trigger GC, so it must be called last.
  if (!(ref->SetExternalSize(external_size, isolate_group))) {
    state->FreeWeakPersistentHandle(ref);
    return nullptr;
  }
  return ref;
}

}  // namespace dart

#endif  // RUNTIME_VM_DART_API_STATE_H_
