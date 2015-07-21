// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "vm/globals.h"
#include "vm/os_thread.h"
#include "vm/store_buffer.h"

namespace dart {

class CHA;
class HandleScope;
class Isolate;
class Object;
class RawBool;
class RawObject;
class StackResource;
class Zone;

// List of VM-global objects/addresses cached in each Thread object.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  V(RawObject*, object_null_, Object::null(), NULL)                            \
  V(RawBool*, bool_true_, Object::bool_true().raw(), NULL)                     \
  V(RawBool*, bool_false_, Object::bool_false().raw(), NULL)                   \

#define CACHED_ADDRESSES_LIST(V)                                               \
  V(uword, update_store_buffer_entry_point_,                                   \
    StubCode::UpdateStoreBufferEntryPoint(), 0)

#define CACHED_CONSTANTS_LIST(V)                                               \
  CACHED_VM_OBJECTS_LIST(V)                                                    \
  CACHED_ADDRESSES_LIST(V)


// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation. The Thread structure associated with
// a thread is allocated by EnsureInit before entering an isolate, and destroyed
// automatically when the underlying OS thread exits. NOTE: On Windows, CleanUp
// must currently be called manually (issue 23474).
class Thread {
 public:
  // The currently executing thread, or NULL if not yet initialized.
  static Thread* Current() {
    return reinterpret_cast<Thread*>(OSThread::GetThreadLocal(thread_key_));
  }

  // Initializes the current thread as a VM thread, if not already done.
  static void EnsureInit();

  // Makes the current thread enter 'isolate'.
  static void EnterIsolate(Isolate* isolate);
  // Makes the current thread exit its isolate.
  static void ExitIsolate();

  // A VM thread other than the main mutator thread can enter an isolate as a
  // "helper" to gain limited concurrent access to the isolate. One example is
  // SweeperTask (which uses the class table, which is copy-on-write).
  // TODO(koda): Properly synchronize heap access to expand allowed operations.
  static void EnterIsolateAsHelper(Isolate* isolate);
  static void ExitIsolateAsHelper();

  // Called when the current thread transitions from mutator to collector.
  // Empties the store buffer block into the isolate.
  // TODO(koda): Always run GC in separate thread.
  static void PrepareForGC();

#if defined(TARGET_OS_WINDOWS)
  // Clears the state of the current thread and frees the allocation.
  static void CleanUp();
#endif

  // Called at VM startup.
  static void InitOnceBeforeIsolate();
  static void InitOnceAfterObjectAndStubCode();

  ~Thread();

  // The topmost zone used for allocation in this thread.
  Zone* zone() const { return state_.zone; }

  // The isolate that this thread is operating on, or NULL if none.
  Isolate* isolate() const { return isolate_; }
  static intptr_t isolate_offset() {
    return OFFSET_OF(Thread, isolate_);
  }

  // The (topmost) CHA for the compilation in the isolate of this thread.
  // TODO(23153): Move this out of Isolate/Thread.
  CHA* cha() const;
  void set_cha(CHA* value);

  void StoreBufferAddObject(RawObject* obj);
  void StoreBufferAddObjectGC(RawObject* obj);
#if defined(TESTING)
  bool StoreBufferContains(RawObject* obj) const {
    return store_buffer_block_->Contains(obj);
  }
#endif
  void StoreBufferBlockProcess(bool check_threshold);
  static intptr_t store_buffer_block_offset() {
    return OFFSET_OF(Thread, store_buffer_block_);
  }

  uword top_exit_frame_info() const { return state_.top_exit_frame_info; }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Thread, state_) + OFFSET_OF(State, top_exit_frame_info);
  }

  StackResource* top_resource() const { return state_.top_resource; }
  void set_top_resource(StackResource* value) {
    state_.top_resource = value;
  }
  static intptr_t top_resource_offset() {
    return OFFSET_OF(Thread, state_) + OFFSET_OF(State, top_resource);
  }

  int32_t no_handle_scope_depth() const {
#if defined(DEBUG)
    return state_.no_handle_scope_depth;
#else
    return 0;
#endif
  }

  void IncrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(state_.no_handle_scope_depth < INT_MAX);
    state_.no_handle_scope_depth += 1;
#endif
  }

  void DecrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(state_.no_handle_scope_depth > 0);
    state_.no_handle_scope_depth -= 1;
#endif
  }

  HandleScope* top_handle_scope() const {
#if defined(DEBUG)
    return state_.top_handle_scope;
#else
    return 0;
#endif
  }

  void set_top_handle_scope(HandleScope* handle_scope) {
#if defined(DEBUG)
    state_.top_handle_scope = handle_scope;
#endif
  }

  // Collection of isolate-specific state of a thread that is saved/restored
  // on isolate exit/re-entry.
  struct State {
    Zone* zone;
    uword top_exit_frame_info;
    StackResource* top_resource;
#if defined(DEBUG)
    HandleScope* top_handle_scope;
    intptr_t no_handle_scope_depth;
#endif
  };

#define DEFINE_OFFSET_METHOD(type_name, member_name, expr, default_init_value) \
  static intptr_t member_name##offset() {                                      \
    return OFFSET_OF(Thread, member_name);                                     \
  }
CACHED_CONSTANTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

  static bool CanLoadFromThread(const Object& object);
  static intptr_t OffsetFromThread(const Object& object);

 private:
  static ThreadLocalKey thread_key_;

  Isolate* isolate_;
  State state_;
  StoreBufferBlock* store_buffer_block_;
#define DECLARE_MEMBERS(type_name, member_name, expr, default_init_value)      \
  type_name member_name;
CACHED_CONSTANTS_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

  explicit Thread(bool init_vm_constants = true);

  void InitVMConstants();

  void ClearState() {
    memset(&state_, 0, sizeof(state_));
  }

  void set_zone(Zone* zone) {
    state_.zone = zone;
  }

  void set_top_exit_frame_info(uword top_exit_frame_info) {
    state_.top_exit_frame_info = top_exit_frame_info;
  }

  static void SetCurrent(Thread* current);

  void Schedule(Isolate* isolate);
  void Unschedule();

  friend class Isolate;
  friend class StackZone;
  DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace dart

#endif  // VM_THREAD_H_
