// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "vm/globals.h"
#include "vm/os_thread.h"
#include "vm/store_buffer.h"
#include "vm/runtime_entry_list.h"

namespace dart {

class CHA;
class HandleScope;
class Heap;
class Isolate;
class Log;
class LongJumpScope;
class Object;
class RawBool;
class RawObject;
class RawString;
class RuntimeEntry;
class StackResource;
class TimelineEventBlock;
class Zone;

// List of VM-global objects/addresses cached in each Thread object.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  V(RawObject*, object_null_, Object::null(), NULL)                            \
  V(RawBool*, bool_true_, Object::bool_true().raw(), NULL)                     \
  V(RawBool*, bool_false_, Object::bool_false().raw(), NULL)                   \

#define CACHED_ADDRESSES_LIST(V)                                               \
  V(uword, update_store_buffer_entry_point_,                                   \
    StubCode::UpdateStoreBuffer_entry()->EntryPoint(), 0)                      \
  V(RawString**, predefined_symbols_address_,                                  \
    Symbols::PredefinedAddress(), NULL)                                        \

#define CACHED_CONSTANTS_LIST(V)                                               \
  CACHED_VM_OBJECTS_LIST(V)                                                    \
  CACHED_ADDRESSES_LIST(V)                                                     \

struct InterruptedThreadState {
  ThreadId tid;
  uintptr_t pc;
  uintptr_t csp;
  uintptr_t dsp;
  uintptr_t fp;
  uintptr_t lr;
};

// When a thread is interrupted the thread specific interrupt callback will be
// invoked. Each callback is given an InterruptedThreadState and the user data
// pointer. When inside a thread interrupt callback doing any of the following
// is forbidden:
//   * Accessing TLS -- Because on Windows the callback will be running in a
//                      different thread.
//   * Allocating memory -- Because this takes locks which may already be held,
//                          resulting in a dead lock.
//   * Taking a lock -- See above.
typedef void (*ThreadInterruptCallback)(const InterruptedThreadState& state,
                                        void* data);

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
  static void EnterIsolateAsHelper(Isolate* isolate,
                                   bool bypass_safepoint = false);
  static void ExitIsolateAsHelper(bool bypass_safepoint = false);

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

  static intptr_t heap_offset() {
    return OFFSET_OF(Thread, heap_);
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

  int32_t no_safepoint_scope_depth() const {
#if defined(DEBUG)
    return state_.no_safepoint_scope_depth;
#else
    return 0;
#endif
  }

  void IncrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(state_.no_safepoint_scope_depth < INT_MAX);
    state_.no_safepoint_scope_depth += 1;
#endif
  }

  void DecrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(state_.no_safepoint_scope_depth > 0);
    state_.no_safepoint_scope_depth -= 1;
#endif
  }

  // Collection of isolate-specific state of a thread that is saved/restored
  // on isolate exit/re-entry.
  struct State {
    Zone* zone;
    uword top_exit_frame_info;
    StackResource* top_resource;
    TimelineEventBlock* timeline_block;
    LongJumpScope* long_jump_base;
#if defined(DEBUG)
    HandleScope* top_handle_scope;
    intptr_t no_handle_scope_depth;
    int32_t no_safepoint_scope_depth;
#endif
  };

#define DEFINE_OFFSET_METHOD(type_name, member_name, expr, default_init_value) \
  static intptr_t member_name##offset() {                                      \
    return OFFSET_OF(Thread, member_name);                                     \
  }
CACHED_CONSTANTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#define DEFINE_OFFSET_METHOD(name)                                             \
  static intptr_t name##_entry_point_offset() {                                \
    return OFFSET_OF(Thread, name##_entry_point_);                             \
  }
RUNTIME_ENTRY_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#define DEFINE_OFFSET_METHOD(returntype, name, ...)                            \
  static intptr_t name##_entry_point_offset() {                                \
    return OFFSET_OF(Thread, name##_entry_point_);                             \
  }
LEAF_RUNTIME_ENTRY_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

  static bool CanLoadFromThread(const Object& object);
  static intptr_t OffsetFromThread(const Object& object);
  static intptr_t OffsetFromThread(const RuntimeEntry* runtime_entry);

  TimelineEventBlock* timeline_block() const {
    return state_.timeline_block;
  }

  void set_timeline_block(TimelineEventBlock* block) {
    state_.timeline_block = block;
  }

  void CloseTimelineBlock();
  class Log* log() const;

  LongJumpScope* long_jump_base() const { return state_.long_jump_base; }
  void set_long_jump_base(LongJumpScope* value) {
    state_.long_jump_base = value;
  }

  ThreadId id() const {
    ASSERT(id_ != OSThread::kInvalidThreadId);
    return id_;
  }

  void SetThreadInterrupter(ThreadInterruptCallback callback, void* data);

  bool IsThreadInterrupterEnabled(ThreadInterruptCallback* callback,
                                  void** data) const;

 private:
  static ThreadLocalKey thread_key_;

  const ThreadId id_;
  ThreadInterruptCallback thread_interrupt_callback_;
  void* thread_interrupt_data_;
  Isolate* isolate_;
  Heap* heap_;
  State state_;
  StoreBufferBlock* store_buffer_block_;
  class Log* log_;
#define DECLARE_MEMBERS(type_name, member_name, expr, default_init_value)      \
  type_name member_name;
CACHED_CONSTANTS_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(name)      \
  uword name##_entry_point_;
RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(returntype, name, ...)      \
  uword name##_entry_point_;
LEAF_RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

  explicit Thread(bool init_vm_constants = true);

  void InitVMConstants();

  void ClearState() {
    memset(&state_, 0, sizeof(state_));
  }

  void StoreBufferRelease(bool check_threshold = true);
  void StoreBufferAcquire();

  void set_zone(Zone* zone) {
    state_.zone = zone;
  }

  void set_top_exit_frame_info(uword top_exit_frame_info) {
    state_.top_exit_frame_info = top_exit_frame_info;
  }

  static void SetCurrent(Thread* current);

  void Schedule(Isolate* isolate, bool bypass_safepoint = false);
  void Unschedule(bool bypass_safepoint = false);

  friend class ApiZone;
  friend class Isolate;
  friend class StackZone;
  friend class ThreadRegistry;
  DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace dart

#endif  // VM_THREAD_H_
