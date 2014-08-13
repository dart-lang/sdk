// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_STATE_H_
#define VM_DART_API_STATE_H_

#include "include/dart_api.h"

#include "platform/utils.h"
#include "vm/bitfield.h"
#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/thread.h"
#include "vm/visitor.h"

#include "vm/handles_impl.h"

namespace dart {

DECLARE_DEBUG_FLAG(bool, trace_zones);
DECLARE_DEBUG_FLAG(bool, trace_handles);

// Implementation of Zone support for very fast allocation of small chunks
// of memory. The chunks cannot be deallocated individually, but instead
// zones support deallocating all chunks in one fast operation when the
// scope is exited.
class ApiZone {
 public:
  // Create an empty zone.
  ApiZone() : zone_() {
    Isolate* isolate = Isolate::Current();
    Zone* current_zone = isolate != NULL ? isolate->current_zone() : NULL;
    zone_.Link(current_zone);
    if (isolate != NULL) {
      isolate->set_current_zone(&zone_);
    }
#ifdef DEBUG
    if (FLAG_trace_zones) {
      OS::PrintErr("*** Starting a new Api zone 0x%" Px "(0x%" Px ")\n",
                   reinterpret_cast<intptr_t>(this),
                   reinterpret_cast<intptr_t>(&zone_));
    }
#endif
  }

  // Delete all memory associated with the zone.
  ~ApiZone() {
    Isolate* isolate = Isolate::Current();
    if ((isolate != NULL) && (isolate->current_zone() == &zone_)) {
      isolate->set_current_zone(zone_.previous_);
    }
#ifdef DEBUG
    if (FLAG_trace_zones) {
      OS::PrintErr("*** Deleting Api zone 0x%" Px "(0x%" Px ")\n",
                   reinterpret_cast<intptr_t>(this),
                   reinterpret_cast<intptr_t>(&zone_));
    }
#endif
  }

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

  Zone* GetZone() { return &zone_; }

  void Reinit(Isolate* isolate) {
    if (isolate == NULL) {
      zone_.Link(NULL);
    } else {
      zone_.Link(isolate->current_zone());
      isolate->set_current_zone(&zone_);
    }
  }

  void Reset(Isolate* isolate) {
    if ((isolate != NULL) && (isolate->current_zone() == &zone_)) {
      isolate->set_current_zone(zone_.previous_);
    }
    zone_.DeleteAll();
  }

 private:
  Zone zone_;

  template<typename T> friend class ApiGrowableArray;
  DISALLOW_COPY_AND_ASSIGN(ApiZone);
};


// Implementation of local handles which are handed out from every
// dart API call, these handles are valid only in the present scope
// and are destroyed when a Dart_ExitScope() is called.
class LocalHandle {
 public:
  // Accessors.
  RawObject* raw() const { return raw_; }
  void set_raw(RawObject* raw) { raw_ = raw; }
  static intptr_t raw_offset() { return OFFSET_OF(LocalHandle, raw_); }

 private:
  LocalHandle() { }
  ~LocalHandle() { }

  RawObject* raw_;
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
  RawObject* raw() const { return raw_; }
  void set_raw(RawObject* ref) { raw_ = ref; }
  void set_raw(const LocalHandle& ref) { raw_ = ref.raw(); }
  void set_raw(const Object& object) { raw_ = object.raw(); }
  RawObject** raw_addr() { return &raw_; }
  Dart_PersistentHandle apiHandle() {
    return reinterpret_cast<Dart_PersistentHandle>(this);
  }

  static intptr_t raw_offset() { return OFFSET_OF(PersistentHandle, raw_); }

  static PersistentHandle* Cast(Dart_PersistentHandle handle);

 private:
  friend class PersistentHandles;

  PersistentHandle() { }
  ~PersistentHandle() { }

  // Overload the raw_ field as a next pointer when adding freed
  // handles to the free list.
  PersistentHandle* Next() {
    return reinterpret_cast<PersistentHandle*>(raw_);
  }
  void SetNext(PersistentHandle* free_list) {
    raw_ = reinterpret_cast<RawObject*>(free_list);
    ASSERT(!raw_->IsHeapObject());
  }
  void FreeHandle(PersistentHandle* free_list) {
    SetNext(free_list);
  }

  RawObject* raw_;
  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(PersistentHandle);
};


// Implementation of persistent handles which are handed out through the
// dart API.
class FinalizablePersistentHandle {
 public:
  static FinalizablePersistentHandle* New(
      Isolate* isolate,
      bool is_prologue,
      const Object& object,
      void* peer,
      Dart_WeakPersistentHandleFinalizer callback,
      intptr_t external_size);

  // Accessors.
  RawObject* raw() const { return raw_; }
  RawObject** raw_addr() { return &raw_; }
  static intptr_t raw_offset() {
    return OFFSET_OF(FinalizablePersistentHandle, raw_);
  }
  void* peer() const { return peer_; }
  Dart_WeakPersistentHandleFinalizer callback() const { return callback_; }
  Dart_WeakPersistentHandle apiHandle() {
    return reinterpret_cast<Dart_WeakPersistentHandle>(this);
  }

  void SetExternalSize(intptr_t size, Isolate* isolate) {
    ASSERT(size >= 0);
    set_external_size(Utils::RoundUp(size, kObjectAlignment));
    if (SpaceForExternal() == Heap::kNew) {
      SetExternalNewSpaceBit();
    }
    isolate->heap()->AllocateExternal(external_size(), SpaceForExternal());
  }

  // Called when the referent becomes unreachable.
  void UpdateUnreachable(Isolate* isolate) {
    EnsureFreeExternal(isolate);
    Finalize(isolate, this);
  }

  // Called when the referent has moved, potentially between generations.
  void UpdateRelocated(Isolate* isolate) {
    if (IsSetNewSpaceBit() && (SpaceForExternal() == Heap::kOld)) {
      isolate->heap()->PromoteExternal(external_size());
      ClearExternalNewSpaceBit();
    }
  }

  // Idempotent. Called when the handle is explicitly deleted or the
  // referent becomes unreachable.
  void EnsureFreeExternal(Isolate* isolate) {
    isolate->heap()->FreeExternal(external_size(), SpaceForExternal());
    set_external_size(0);
  }

  bool IsPrologueWeakPersistent() {
    return PrologueWeakBit::decode(external_data_);
  }

  void SetPrologueWeakPersistent(bool value) {
    external_data_ = PrologueWeakBit::update(value, external_data_);
  }

  static FinalizablePersistentHandle* Cast(Dart_WeakPersistentHandle handle);

 private:
  enum {
    kExternalNewSpaceBit = 0,
    kPrologueWeakBit = 1,
    kExternalSizeBits = 2,
    kExternalSizeBitsSize = (kBitsPerWord - 2),
  };

  // This part of external_data_ is the number of externally allocated bytes.
  // TODO(koda): Measure size in words instead.
  class ExternalSizeBits : public BitField<intptr_t,
                                           kExternalSizeBits,
                                           kExternalSizeBitsSize> {};  // NOLINT
  // This bit of external_data_ is true if the referent was created in new
  // space and UpdateRelocated has not yet detected any promotion.
  class ExternalNewSpaceBit : public BitField<bool, kExternalNewSpaceBit, 1> {};
  // This bit is used to indicate that it is a prologue weak persistent handle.
  class PrologueWeakBit : public BitField<bool, kPrologueWeakBit, 1> {};

  friend class FinalizablePersistentHandles;

  FinalizablePersistentHandle()
      : raw_(NULL),
        peer_(NULL),
        external_data_(0),
        callback_(NULL) { }
  ~FinalizablePersistentHandle() { }

  static void Finalize(Isolate* isolate, FinalizablePersistentHandle* handle);

  // Overload the raw_ field as a next pointer when adding freed
  // handles to the free list.
  FinalizablePersistentHandle* Next() {
    return reinterpret_cast<FinalizablePersistentHandle*>(raw_);
  }
  void SetNext(FinalizablePersistentHandle* free_list) {
    raw_ = reinterpret_cast<RawObject*>(free_list);
    ASSERT(!raw_->IsHeapObject());
  }
  void FreeHandle(FinalizablePersistentHandle* free_list) {
    Clear();
    SetNext(free_list);
  }

  void Clear() {
    raw_ = Object::null();
    peer_ = NULL;
    external_data_ = 0;
    callback_ = NULL;
  }

  void set_raw(RawObject* raw) { raw_ = raw; }
  void set_raw(const LocalHandle& ref) { raw_ = ref.raw(); }
  void set_raw(const Object& object) { raw_ = object.raw(); }

  void set_peer(void* peer) { peer_ = peer; }

  void set_callback(Dart_WeakPersistentHandleFinalizer callback) {
    callback_ = callback;
  }

  intptr_t external_size() const {
    return ExternalSizeBits::decode(external_data_);
  }

  void set_external_size(intptr_t size) {
    ASSERT(ExternalSizeBits::is_valid(size));
    external_data_ = ExternalSizeBits::update(size, external_data_);
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
    return (raw_->IsHeapObject() && raw_->IsNewObject()) ?
           Heap::kNew : Heap::kOld;
  }

  RawObject* raw_;
  void* peer_;
  uword external_data_;
  Dart_WeakPersistentHandleFinalizer callback_;
  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(FinalizablePersistentHandle);
};


// Local handles repository structure.
static const int kLocalHandleSizeInWords = sizeof(LocalHandle) / kWordSize;
static const int kLocalHandlesPerChunk = 64;
static const int kOffsetOfRawPtrInLocalHandle = 0;
class LocalHandles : Handles<kLocalHandleSizeInWords,
                             kLocalHandlesPerChunk,
                             kOffsetOfRawPtrInLocalHandle> {
 public:
  LocalHandles() : Handles<kLocalHandleSizeInWords,
                           kLocalHandlesPerChunk,
                           kOffsetOfRawPtrInLocalHandle>() {
#ifdef DEBUG
    if (FLAG_trace_handles) {
      OS::PrintErr("*** Starting a new Local handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
#endif
  }
  ~LocalHandles() {
#ifdef DEBUG
    if (FLAG_trace_handles) {
      OS::PrintErr("***   Handle Counts for 0x(%" Px "):Scoped = %d\n",
                   reinterpret_cast<intptr_t>(this),
                   CountHandles());
      OS::PrintErr("*** Deleting Local handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
#endif
  }


  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    Handles<kLocalHandleSizeInWords,
            kLocalHandlesPerChunk,
            kOffsetOfRawPtrInLocalHandle>::VisitObjectPointers(visitor);
  }

  // Reset the local handles block for reuse.
  void Reset() {
    Handles<kLocalHandleSizeInWords,
            kLocalHandlesPerChunk,
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
  int CountHandles() const {
    return CountScopedHandles();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(LocalHandles);
};


// Persistent handles repository structure.
static const int kPersistentHandleSizeInWords =
    sizeof(PersistentHandle) / kWordSize;
static const int kPersistentHandlesPerChunk = 64;
static const int kOffsetOfRawPtrInPersistentHandle = 0;
class PersistentHandles : Handles<kPersistentHandleSizeInWords,
                                  kPersistentHandlesPerChunk,
                                  kOffsetOfRawPtrInPersistentHandle> {
 public:
  PersistentHandles() : Handles<kPersistentHandleSizeInWords,
                                kPersistentHandlesPerChunk,
                                kOffsetOfRawPtrInPersistentHandle>(),
        free_list_(NULL) {
#ifdef DEBUG
    if (FLAG_trace_handles) {
      OS::PrintErr("*** Starting a new Persistent handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
#endif
  }
  ~PersistentHandles() {
    free_list_ = NULL;
#ifdef DEBUG
    if (FLAG_trace_handles) {
      OS::PrintErr("***   Handle Counts for 0x(%" Px "):Scoped = %d\n",
                   reinterpret_cast<intptr_t>(this),
                   CountHandles());
      OS::PrintErr("*** Deleting Persistent handle block 0x%" Px "\n",
                   reinterpret_cast<intptr_t>(this));
    }
#endif
  }

  // Accessors.
  PersistentHandle* free_list() const { return free_list_; }
  void set_free_list(PersistentHandle* value) { free_list_ = value; }

  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    Handles<kPersistentHandleSizeInWords,
            kPersistentHandlesPerChunk,
            kOffsetOfRawPtrInPersistentHandle>::VisitObjectPointers(visitor);
  }

  // Allocates a persistent handle, these have to be destroyed explicitly
  // by calling FreeHandle.
  PersistentHandle* AllocateHandle() {
    PersistentHandle* handle;
    if (free_list_ != NULL) {
      handle = free_list_;
      free_list_ = handle->Next();
    } else {
      handle = reinterpret_cast<PersistentHandle*>(AllocateScopedHandle());
    }
    handle->set_raw(Object::null());
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

  // Returns a count of active handles (used for testing purposes).
  int CountHandles() const {
    return CountScopedHandles();
  }

 private:
  PersistentHandle* free_list_;
  DISALLOW_COPY_AND_ASSIGN(PersistentHandles);
};


// Finalizable persistent handles repository structure.
static const int kFinalizablePersistentHandleSizeInWords =
     sizeof(FinalizablePersistentHandle) / kWordSize;
static const int kFinalizablePersistentHandlesPerChunk = 64;
static const int kOffsetOfRawPtrInFinalizablePersistentHandle = 0;
class FinalizablePersistentHandles
    : Handles<kFinalizablePersistentHandleSizeInWords,
              kFinalizablePersistentHandlesPerChunk,
              kOffsetOfRawPtrInFinalizablePersistentHandle> {
 public:
  FinalizablePersistentHandles()
      : Handles<kFinalizablePersistentHandleSizeInWords,
                kFinalizablePersistentHandlesPerChunk,
                kOffsetOfRawPtrInFinalizablePersistentHandle>(),
        free_list_(NULL) { }
  ~FinalizablePersistentHandles() {
    free_list_ = NULL;
  }

  // Accessors.
  FinalizablePersistentHandle* free_list() const { return free_list_; }
  void set_free_list(FinalizablePersistentHandle* value) { free_list_ = value; }

  // Visit all handles stored in the various handle blocks.
  void VisitHandles(HandleVisitor* visitor) {
    Handles<kFinalizablePersistentHandleSizeInWords,
            kFinalizablePersistentHandlesPerChunk,
            kOffsetOfRawPtrInFinalizablePersistentHandle>::Visit(
                visitor);
  }

  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    Handles<kFinalizablePersistentHandleSizeInWords,
            kFinalizablePersistentHandlesPerChunk,
            kOffsetOfRawPtrInFinalizablePersistentHandle>::VisitObjectPointers(
                visitor);
  }

  // Allocates a persistent handle, these have to be destroyed explicitly
  // by calling FreeHandle.
  FinalizablePersistentHandle* AllocateHandle() {
    FinalizablePersistentHandle* handle;
    if (free_list_ != NULL) {
      handle = free_list_;
      free_list_ = handle->Next();
      handle->set_raw(Object::null());
    } else {
      handle = reinterpret_cast<FinalizablePersistentHandle*>(
          AllocateScopedHandle());
      handle->Clear();
    }
    return handle;
  }

  void FreeHandle(FinalizablePersistentHandle* handle) {
    handle->FreeHandle(free_list());
    set_free_list(handle);
  }

  // Validate if passed in handle is a Persistent Handle.
  bool IsValidHandle(Dart_WeakPersistentHandle object) const {
    return IsValidScopedHandle(reinterpret_cast<uword>(object));
  }

  // Returns a count of active handles (used for testing purposes).
  int CountHandles() const {
    return CountScopedHandles();
  }

 private:
  FinalizablePersistentHandle* free_list_;
  DISALLOW_COPY_AND_ASSIGN(FinalizablePersistentHandles);
};


// Structure used for the implementation of local scopes used in dart_api.
// These local scopes manage handles and memory allocated in the scope.
class ApiLocalScope {
 public:
  ApiLocalScope(ApiLocalScope* previous, uword stack_marker) :
      previous_(previous), stack_marker_(stack_marker) { }
  ~ApiLocalScope() {
    previous_ = NULL;
  }

  // Reinit the ApiLocalScope to new values.
  void Reinit(Isolate* isolate, ApiLocalScope* previous, uword stack_marker) {
    previous_ = previous;
    stack_marker_ = stack_marker;
    zone_.Reinit(isolate);
  }

  // Reset the ApiLocalScope so that it can be reused again.
  void Reset(Isolate* isolate) {
    local_handles_.Reset();
    zone_.Reset(isolate);
    previous_ = NULL;
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
    ASSERT(Current() == NULL);
    Thread::SetThreadLocal(Api::api_native_key_, reinterpret_cast<uword>(this));
  }

  ~ApiNativeScope() {
    ASSERT(Current() == this);
    Thread::SetThreadLocal(Api::api_native_key_, 0);
  }

  static inline ApiNativeScope* Current() {
    return reinterpret_cast<ApiNativeScope*>(
        Thread::GetThreadLocal(Api::api_native_key_));
  }

  Zone* zone() { return zone_.GetZone(); }

 private:
  ApiZone zone_;
};


// Api growable arrays use a zone for allocation. The constructor
// picks the zone from the current isolate if in an isolate
// environment. When outside an isolate environment it picks the zone
// from the current native scope.
template<typename T>
class ApiGrowableArray : public BaseGrowableArray<T, ValueObject> {
 public:
  explicit ApiGrowableArray(int initial_capacity)
      : BaseGrowableArray<T, ValueObject>(
          initial_capacity,
          ApiNativeScope::Current()->zone()) {}
  ApiGrowableArray()
      : BaseGrowableArray<T, ValueObject>(
          ApiNativeScope::Current()->zone()) {}
  ApiGrowableArray(intptr_t initial_capacity, Zone* zone)
      : BaseGrowableArray<T, ValueObject>(initial_capacity, zone) {}
};


// Forward declarations.
class WeakReferenceSetBuilder;
class WeakReferenceSet;


// Implementation of the API State used in dart api for maintaining
// local scopes, persistent handles etc. These are setup on a per isolate
// basis and destroyed when the isolate is shutdown.
class ApiState {
 public:
  ApiState() : persistent_handles_(),
               weak_persistent_handles_(),
               prologue_weak_persistent_handles_(),
               reusable_scope_(NULL),
               top_scope_(NULL),
               delayed_weak_reference_sets_(NULL),
               null_(NULL),
               true_(NULL),
               false_(NULL),
               acquired_error_(NULL) {}
  ~ApiState() {
    while (top_scope_ != NULL) {
      ApiLocalScope* scope = top_scope_;
      top_scope_ = top_scope_->previous();
      delete scope;
    }
    if (null_ != NULL) {
      persistent_handles().FreeHandle(null_);
      null_ = NULL;
    }
    if (true_ != NULL) {
      persistent_handles().FreeHandle(true_);
      true_ = NULL;
    }
    if (false_ != NULL) {
      persistent_handles().FreeHandle(false_);
      false_ = NULL;
    }
    if (acquired_error_ != NULL) {
      persistent_handles().FreeHandle(acquired_error_);
      acquired_error_ = NULL;
    }
  }

  // Accessors.
  ApiLocalScope* reusable_scope() const { return reusable_scope_; }
  void set_reusable_scope(ApiLocalScope* value) {
    ASSERT(value == NULL || reusable_scope_ == NULL);
    reusable_scope_ = value;
  }
  ApiLocalScope* top_scope() const { return top_scope_; }
  void set_top_scope(ApiLocalScope* value) { top_scope_ = value; }

  PersistentHandles& persistent_handles() { return persistent_handles_; }

  FinalizablePersistentHandles& weak_persistent_handles() {
    return weak_persistent_handles_;
  }

  FinalizablePersistentHandles& prologue_weak_persistent_handles() {
    return prologue_weak_persistent_handles_;
  }

  WeakReferenceSet* delayed_weak_reference_sets() {
    return delayed_weak_reference_sets_;
  }
  void set_delayed_weak_reference_sets(WeakReferenceSet* reference_set) {
    delayed_weak_reference_sets_ = reference_set;
  }

  void UnwindScopes(uword stack_marker) {
    // Unwind all scopes using the same stack_marker, i.e. all scopes allocated
    // under the same top_exit_frame_info.
    while (top_scope_ != NULL &&
           top_scope_->stack_marker() != 0 &&
           top_scope_->stack_marker() == stack_marker) {
      ApiLocalScope* scope = top_scope_;
      top_scope_ = top_scope_->previous();
      delete scope;
    }
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           bool visit_prologue_weak_handles) {
    ApiLocalScope* scope = top_scope_;
    while (scope != NULL) {
      scope->local_handles()->VisitObjectPointers(visitor);
      scope = scope->previous();
    }
    persistent_handles().VisitObjectPointers(visitor);
    if (visit_prologue_weak_handles) {
      prologue_weak_persistent_handles().VisitObjectPointers(visitor);
    }
  }

  void VisitWeakHandles(HandleVisitor* visitor,
                        bool visit_prologue_weak_handles) {
    weak_persistent_handles().VisitHandles(visitor);
    if (visit_prologue_weak_handles) {
      prologue_weak_persistent_handles().VisitHandles(visitor);
    }
  }

  void VisitPrologueWeakHandles(HandleVisitor* visitor) {
    prologue_weak_persistent_handles().VisitHandles(visitor);
  }

  bool IsValidLocalHandle(Dart_Handle object) const {
    ApiLocalScope* scope = top_scope_;
    while (scope != NULL) {
      if (scope->local_handles()->IsValidHandle(object)) {
        return true;
      }
      scope = scope->previous();
    }
    return false;
  }

  bool IsValidPersistentHandle(Dart_PersistentHandle object) const {
    return persistent_handles_.IsValidHandle(object);
  }

  bool IsValidWeakPersistentHandle(Dart_WeakPersistentHandle object) const {
    return weak_persistent_handles_.IsValidHandle(object);
  }

  bool IsValidPrologueWeakPersistentHandle(
      Dart_WeakPersistentHandle object) const {
    return prologue_weak_persistent_handles_.IsValidHandle(object);
  }

  bool IsProtectedHandle(PersistentHandle* object) const {
    if (object == NULL) return false;
    return object == null_ || object == true_ || object == false_;
  }

  int CountLocalHandles() const {
    int total = 0;
    ApiLocalScope* scope = top_scope_;
    while (scope != NULL) {
      total += scope->local_handles()->CountHandles();
      scope = scope->previous();
    }
    return total;
  }
  int CountPersistentHandles() const {
    return persistent_handles_.CountHandles();
  }
  int ZoneSizeInBytes() const {
    int total = 0;
    ApiLocalScope* scope = top_scope_;
    while (scope != NULL) {
      total += scope->zone()->SizeInBytes();
      scope = scope->previous();
    }
    return total;
  }

  void SetupAcquiredError() {
    ASSERT(acquired_error_ == NULL);
    acquired_error_ = persistent_handles().AllocateHandle();
    acquired_error_->set_raw(
        String::New("Internal Dart data pointers have been acquired, "
                    "please release them using Dart_TypedDataReleaseData."));
  }

  PersistentHandle* AcquiredError() const {
    ASSERT(acquired_error_ != NULL);
    return acquired_error_;
  }

  WeakReferenceSetBuilder* NewWeakReferenceSetBuilder();

  void DelayWeakReferenceSet(WeakReferenceSet* reference_set);

 private:
  PersistentHandles persistent_handles_;
  FinalizablePersistentHandles weak_persistent_handles_;
  FinalizablePersistentHandles prologue_weak_persistent_handles_;
  ApiLocalScope* reusable_scope_;
  ApiLocalScope* top_scope_;
  WeakReferenceSet* delayed_weak_reference_sets_;

  // Persistent handles to important objects.
  PersistentHandle* null_;
  PersistentHandle* true_;
  PersistentHandle* false_;
  PersistentHandle* acquired_error_;

  DISALLOW_COPY_AND_ASSIGN(ApiState);
};


class WeakReferenceSet {
 public:
  explicit WeakReferenceSet(Zone* zone)
      : next_(NULL),
        keys_(1, zone),
        values_(1, zone) {
  }
  ~WeakReferenceSet() {}

  WeakReferenceSet* next() const { return next_; }

  intptr_t num_keys() const { return keys_.length(); }
  RawObject** get_key(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < num_keys());
    FinalizablePersistentHandle* ref =
        FinalizablePersistentHandle::Cast(keys_[i]);
    return ref->raw_addr();
  }

  intptr_t num_values() const { return values_.length(); }
  RawObject** get_value(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < num_values());
    FinalizablePersistentHandle* ref =
        FinalizablePersistentHandle::Cast(values_[i]);
    return ref->raw_addr();
  }

  bool SingletonKeyEqualsValue() const {
    ASSERT((num_keys() == 1) && (num_values() == 1));
    return (keys_[0] == values_[0]);
  }

  void Append(Dart_WeakPersistentHandle key, Dart_WeakPersistentHandle value) {
    keys_.Add(key);
    values_.Add(value);
  }

  void AppendKey(Dart_WeakPersistentHandle key) {
    keys_.Add(key);
  }

  void AppendValue(Dart_WeakPersistentHandle value) {
    values_.Add(value);
  }

  static WeakReferenceSet* Pop(WeakReferenceSet** queue) {
    ASSERT(queue != NULL);
    WeakReferenceSet* head = *queue;
    if (head != NULL) {
      *queue = head->next();
      head->next_ = NULL;
    }
    return head;
  }

  static void Push(WeakReferenceSet* reference_set, WeakReferenceSet** queue) {
    ASSERT(reference_set != NULL);
    ASSERT(queue != NULL);
    reference_set->next_ = *queue;
    *queue = reference_set;
  }

  void* operator new(uword size, Zone* zone) {
    return reinterpret_cast<void*>(zone->AllocUnsafe(size));
  }

  // Disallow explicit deallocation of WeakReferenceSet.
  void operator delete(void* pointer) { UNREACHABLE(); }

 private:
  WeakReferenceSet* next_;
  ApiGrowableArray<Dart_WeakPersistentHandle> keys_;
  ApiGrowableArray<Dart_WeakPersistentHandle> values_;

  DISALLOW_COPY_AND_ASSIGN(WeakReferenceSet);
};


class WeakReferenceSetBuilder {
 public:
  ApiState* api_state() const {
    return api_state_;
  }

  WeakReferenceSet* NewWeakReferenceSet() {
    return new (zone_) WeakReferenceSet(zone_);
  }

 private:
  explicit WeakReferenceSetBuilder(ApiState* api_state)
      : api_state_(api_state),
        zone_(api_state->top_scope()->zone()) {
  }

  ApiState* api_state_;
  Zone* zone_;

  friend class ApiState;
  DISALLOW_IMPLICIT_CONSTRUCTORS(WeakReferenceSetBuilder);
};


inline FinalizablePersistentHandle* FinalizablePersistentHandle::New(
    Isolate* isolate,
    bool is_prologue,
    const Object& object,
    void* peer,
    Dart_WeakPersistentHandleFinalizer callback,
    intptr_t external_size) {
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  FinalizablePersistentHandle* ref = is_prologue ?
      state->prologue_weak_persistent_handles().AllocateHandle() :
      state->weak_persistent_handles().AllocateHandle();
  ref->SetPrologueWeakPersistent(is_prologue);
  ref->set_raw(object);
  ref->set_peer(peer);
  ref->set_callback(callback);
  // This may trigger GC, so it must be called last.
  ref->SetExternalSize(external_size, isolate);
  return ref;
}

}  // namespace dart

#endif  // VM_DART_API_STATE_H_
