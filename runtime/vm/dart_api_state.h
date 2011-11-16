// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DART_API_STATE_H_
#define VM_DART_API_STATE_H_

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"
#include "vm/flags.h"
#include "vm/handles.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

#include "vm/handles_impl.h"

namespace dart {

// Implementation of Zone support for very fast allocation of small chunks
// of memory. The chunks cannot be deallocated individually, but instead
// zones support deallocating all chunks in one fast operation when the
// scope is exited.
class ApiZone {
 public:
  // Create an empty zone.
  ApiZone() : zone_() { }

  // Delete all memory associated with the zone.
  ~ApiZone() { }

  // Allocate 'size' bytes of memory in the zone; expands the zone by
  // allocating new segments of memory on demand using 'new'.
  uword Allocate(intptr_t size) { return zone_.Allocate(size); }

  // Allocate 'new_size' bytes of memory and copies 'old_size' bytes from
  // 'data' into new allocated memory. Uses current zone.
  uword Reallocate(uword data, intptr_t old_size, intptr_t new_size) {
    return zone_.Reallocate(data, old_size, new_size);
  }

  // Compute the total size of this zone. This includes wasted space that is
  // due to internal fragmentation in the segments.
  intptr_t SizeInBytes() const { return zone_.SizeInBytes(); }

 private:
  BaseZone zone_;

  DISALLOW_COPY_AND_ASSIGN(ApiZone);
};


// Implementation of local handles which are handed out from every
// dart API call, these handles are valid only in the present scope
// and are destroyed when a Dart_ExitScope() is called.
class LocalHandle {
 public:
  // Accessors.
  RawObject* raw() const { return raw_; }
  void set_raw(const Object& object) { raw_ = object.raw(); }
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
void ProtectedHandleCallback();


// Implementation of persistent handles which are handed out through the
// dart API.
class PersistentHandle {
 public:
  enum {
    StrongReference = 0,
    WeakReference,
  };

  // Accessors.
  RawObject* raw() const { return raw_; }
  void set_raw(const LocalHandle& ref) { raw_ = ref.raw(); }
  void set_raw(const Object& object) { raw_ = object.raw(); }
  static intptr_t raw_offset() { return OFFSET_OF(PersistentHandle, raw_); }
  void* callback() const { return callback_; }
  void set_callback(void* value) { callback_ = value; }
  intptr_t type() const { return type_; }
  void set_type(intptr_t value) { type_ = value; }

  // Some handles are protected from being freed via the external dart api.
  bool IsProtected() {
    return callback() == &ProtectedHandleCallback;
  }

 private:
  friend class PersistentHandles;

  PersistentHandle() { }
  ~PersistentHandle() { }

  // Overload the callback_ field as a next pointer when adding freed
  // handles to the free list.
  PersistentHandle* Next() {
    return reinterpret_cast<PersistentHandle*>(callback_);
  }
  void SetNext(PersistentHandle* free_list) {
    callback_ = reinterpret_cast<void*>(free_list);
  }
  void FreeHandle(PersistentHandle* free_list) {
    raw_ = NULL;
    SetNext(free_list);
  }

  RawObject* raw_;
  void* callback_;
  intptr_t type_;
  DISALLOW_ALLOCATION();  // Allocated through AllocateHandle methods.
  DISALLOW_COPY_AND_ASSIGN(PersistentHandle);
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
                           kOffsetOfRawPtrInLocalHandle>() { }
  ~LocalHandles() { }


  // Visit all object pointers stored in the various handles.
  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    Handles<kLocalHandleSizeInWords,
            kLocalHandlesPerChunk,
            kOffsetOfRawPtrInLocalHandle>::VisitObjectPointers(visitor);
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
        free_list_(NULL) { }
  ~PersistentHandles() {
    free_list_ = NULL;
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
    handle->set_callback(NULL);
    handle->set_type(PersistentHandle::StrongReference);
    return handle;
  }

  void FreeHandle(PersistentHandle* handle) {
    handle->FreeHandle(free_list());
    set_free_list(handle);
  }

  // Validate if passed in handle is a Persistent Handle.
  bool IsValidHandle(Dart_Handle object) const {
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


// Structure used for the implementation of local scopes used in dart_api.
// These local scopes manage handles and memory allocated in the scope.
class ApiLocalScope {
 public:
  ApiLocalScope(ApiLocalScope* previous, uword stack_marker) :
      previous_(previous), stack_marker_(stack_marker) { }
  ~ApiLocalScope() {
    previous_ = NULL;
  }

  // Accessors.
  ApiLocalScope* previous() const { return previous_; }
  uword stack_marker() const { return stack_marker_; }
  void set_previous(ApiLocalScope* value) { previous_ = value; }
  LocalHandles* local_handles() { return &local_handles_; }
  ApiZone& zone() { return zone_; }

 private:
  ApiLocalScope* previous_;
  uword stack_marker_;
  LocalHandles local_handles_;
  ApiZone zone_;

  DISALLOW_COPY_AND_ASSIGN(ApiLocalScope);
};


// Implementation of the API State used in dart api for maintaining
// local scopes, persistent handles etc. These are setup on a per isolate
// basis and destroyed when the isolate is shutdown.
class ApiState {
 public:
  ApiState() : top_scope_(NULL), null_(NULL), true_(NULL), false_(NULL) { }
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
  }

  // Accessors.
  ApiLocalScope* top_scope() const { return top_scope_; }
  void set_top_scope(ApiLocalScope* value) { top_scope_ = value; }
  PersistentHandles& persistent_handles() { return persistent_handles_; }

  void UnwindScopes(uword sp) {
    while (top_scope_ != NULL && top_scope_->stack_marker() < sp) {
      ApiLocalScope* scope = top_scope_;
      top_scope_ = top_scope_->previous();
      delete scope;
    }
  }

  void VisitObjectPointers(ObjectPointerVisitor* visitor) {
    ApiLocalScope* scope = top_scope_;
    while (scope != NULL) {
      scope->local_handles()->VisitObjectPointers(visitor);
      scope = scope->previous();
    }
    persistent_handles().VisitObjectPointers(visitor);
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
  bool IsValidPersistentHandle(Dart_Handle object) const {
    return persistent_handles_.IsValidHandle(object);
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
      total += scope->zone().SizeInBytes();
      scope = scope->previous();
    }
    return total;
  }
  PersistentHandle* Null() {
    if (null_ == NULL) {
      DARTSCOPE(Isolate::Current());

      Object& null_object = Object::Handle();
      null_ = persistent_handles().AllocateHandle();
      null_->set_raw(null_object);
      null_->set_callback(reinterpret_cast<void*>(&ProtectedHandleCallback));
    }
    return null_;
  }
  PersistentHandle* True() {
    if (true_ == NULL) {
      DARTSCOPE(Isolate::Current());

      const Object& true_object = Object::Handle(Bool::True());
      true_ = persistent_handles().AllocateHandle();
      true_->set_raw(true_object);
      true_->set_callback(reinterpret_cast<void*>(&ProtectedHandleCallback));
    }
    return true_;
  }
  PersistentHandle* False() {
    if (false_ == NULL) {
      DARTSCOPE(Isolate::Current());

      const Object& false_object = Object::Handle(Bool::False());
      false_ = persistent_handles().AllocateHandle();
      false_->set_raw(false_object);
      false_->set_callback(reinterpret_cast<void*>(&ProtectedHandleCallback));
    }
    return false_;
  }

 private:
  PersistentHandles persistent_handles_;
  ApiLocalScope* top_scope_;

  // Persistent handles to important objects.
  PersistentHandle* null_;
  PersistentHandle* true_;
  PersistentHandle* false_;

  DISALLOW_COPY_AND_ASSIGN(ApiState);
};

}  // namespace dart

#endif  // VM_DART_API_STATE_H_
