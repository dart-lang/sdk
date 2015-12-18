// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/dart_api_state.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"

namespace dart {

Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
}


#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object)                                   \
  object##_handle_(NULL),


Thread::Thread(Isolate* isolate)
    : BaseThread(false),
      os_thread_(NULL),
      isolate_(NULL),
      heap_(NULL),
      zone_(NULL),
      api_reusable_scope_(NULL),
      api_top_scope_(NULL),
      top_exit_frame_info_(0),
      top_resource_(NULL),
      long_jump_base_(NULL),
      store_buffer_block_(NULL),
      no_callback_scope_depth_(0),
#if defined(DEBUG)
      top_handle_scope_(NULL),
      no_handle_scope_depth_(0),
      no_safepoint_scope_depth_(0),
#endif
      reusable_handles_(),
      cha_(NULL),
      deopt_id_(0),
      vm_tag_(0),
      pending_functions_(GrowableObjectArray::null()),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
      next_(NULL) {
#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#define DEFAULT_INIT(name)                                                     \
  name##_entry_point_ = 0;
RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#define DEFAULT_INIT(returntype, name, ...)                                    \
  name##_entry_point_ = 0;
LEAF_RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

  // We cannot initialize the VM constants here for the vm isolate thread
  // due to boot strapping issues.
  if ((Dart::vm_isolate() != NULL) && (isolate != Dart::vm_isolate())) {
    InitVMConstants();
  }
}


static const struct ALIGN16 {
  uint64_t a;
  uint64_t b;
} double_negate_constant =
    {0x8000000000000000LL, 0x8000000000000000LL};

static const struct ALIGN16 {
  uint64_t a;
  uint64_t b;
} double_abs_constant =
    {0x7FFFFFFFFFFFFFFFLL, 0x7FFFFFFFFFFFFFFFLL};

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_not_constant =
    { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_negate_constant =
    { 0x80000000, 0x80000000, 0x80000000, 0x80000000 };

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_absolute_constant =
    { 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF };

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_zerow_constant =
    { 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000 };


void Thread::InitVMConstants() {
#define ASSERT_VM_HEAP(type_name, member_name, init_expr, default_init_value)  \
  ASSERT((init_expr)->IsOldObject());
CACHED_VM_OBJECTS_LIST(ASSERT_VM_HEAP)
#undef ASSERT_VM_HEAP

#define INIT_VALUE(type_name, member_name, init_expr, default_init_value)      \
  ASSERT(member_name == default_init_value);                                   \
  member_name = (init_expr);
CACHED_CONSTANTS_LIST(INIT_VALUE)
#undef INIT_VALUE

#define INIT_VALUE(name)                                                       \
  ASSERT(name##_entry_point_ == 0);                                            \
  name##_entry_point_ = k##name##RuntimeEntry.GetEntryPoint();
RUNTIME_ENTRY_LIST(INIT_VALUE)
#undef INIT_VALUE

#define INIT_VALUE(returntype, name, ...)                                      \
  ASSERT(name##_entry_point_ == 0);                                            \
  name##_entry_point_ = k##name##RuntimeEntry.GetEntryPoint();
LEAF_RUNTIME_ENTRY_LIST(INIT_VALUE)
#undef INIT_VALUE

  // Setup the thread specific reusable handles.
#define REUSABLE_HANDLE_ALLOCATION(object)                                     \
  this->object##_handle_ = this->AllocateReusableHandle<object>();
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ALLOCATION)
#undef REUSABLE_HANDLE_ALLOCATION
}


RawGrowableObjectArray* Thread::pending_functions() {
  if (pending_functions_ == GrowableObjectArray::null()) {
    pending_functions_ = GrowableObjectArray::New(Heap::kOld);
  }
  return pending_functions_;
}


void Thread::EnterIsolate(Isolate* isolate) {
  const bool kIsMutatorThread = true;
  const bool kDontBypassSafepoints = false;
  ThreadRegistry* tr = isolate->thread_registry();
  Thread* thread = tr->Schedule(
      isolate, kIsMutatorThread, kDontBypassSafepoints);
  isolate->MakeCurrentThreadMutator(thread);
  thread->set_vm_tag(VMTag::kVMTagId);
  ASSERT(thread->store_buffer_block_ == NULL);
  thread->StoreBufferAcquire();
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(thread->IsMutatorThread());
#if defined(DEBUG)
  ASSERT(!thread->IsAnyReusableHandleScopeActive());
#endif  // DEBUG
  // Clear since GC will not visit the thread once it is unscheduled.
  thread->ClearReusableHandles();
  thread->StoreBufferRelease();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  if (isolate->is_runnable()) {
    thread->set_vm_tag(VMTag::kIdleTagId);
  } else {
    thread->set_vm_tag(VMTag::kLoadWaitTagId);
  }
  const bool kIsMutatorThread = true;
  const bool kDontBypassSafepoints = false;
  ThreadRegistry* tr = isolate->thread_registry();
  tr->Unschedule(thread, kIsMutatorThread, kDontBypassSafepoints);
  isolate->ClearMutatorThread();
}


void Thread::EnterIsolateAsHelper(Isolate* isolate, bool bypass_safepoint) {
  const bool kIsNotMutatorThread = false;
  ThreadRegistry* tr = isolate->thread_registry();
  Thread* thread = tr->Schedule(isolate, kIsNotMutatorThread, bypass_safepoint);
  ASSERT(thread->store_buffer_block_ == NULL);
  // TODO(koda): Use StoreBufferAcquire once we properly flush before Scavenge.
  thread->store_buffer_block_ =
      thread->isolate()->store_buffer()->PopEmptyBlock();
  // This thread should not be the main mutator.
  ASSERT(!thread->IsMutatorThread());
}


void Thread::ExitIsolateAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(!thread->IsMutatorThread());
  thread->StoreBufferRelease();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  const bool kIsNotMutatorThread = false;
  ThreadRegistry* tr = isolate->thread_registry();
  tr->Unschedule(thread, kIsNotMutatorThread, bypass_safepoint);
}


void Thread::PrepareForGC() {
  ASSERT(isolate()->thread_registry()->AtSafepoint());
  // Prevent scheduling another GC by ignoring the threshold.
  StoreBufferRelease(StoreBuffer::kIgnoreThreshold);
  // Make sure to get an *empty* block; the isolate needs all entries
  // at GC time.
  // TODO(koda): Replace with an epilogue (PrepareAfterGC) that acquires.
  store_buffer_block_ = isolate()->store_buffer()->PopEmptyBlock();
}


void Thread::StoreBufferBlockProcess(StoreBuffer::ThresholdPolicy policy) {
  StoreBufferRelease(policy);
  StoreBufferAcquire();
}


void Thread::StoreBufferAddObject(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
  }
}


void Thread::StoreBufferAddObjectGC(RawObject* obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kIgnoreThreshold);
  }
}


void Thread::StoreBufferRelease(StoreBuffer::ThresholdPolicy policy) {
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = NULL;
  isolate()->store_buffer()->PushBlock(block, policy);
}


void Thread::StoreBufferAcquire() {
  store_buffer_block_ = isolate()->store_buffer()->PopNonFullBlock();
}


bool Thread::IsMutatorThread() const {
  return ((isolate_ != NULL) && (isolate_->mutator_thread() == this));
}


bool Thread::IsExecutingDartCode() const {
  return (top_exit_frame_info() == 0) &&
         (vm_tag() == VMTag::kDartTagId);
}


bool Thread::HasExitedDartCode() const {
  return (top_exit_frame_info() != 0) &&
         (vm_tag() != VMTag::kDartTagId);
}


template<class C>
C* Thread::AllocateReusableHandle() {
  C* handle = reinterpret_cast<C*>(reusable_handles_.AllocateScopedHandle());
  C::initializeHandle(handle, C::null());
  return handle;
}


void Thread::ClearReusableHandles() {
#define CLEAR_REUSABLE_HANDLE(object)                                          \
  *object##_handle_ = object::null();
  REUSABLE_HANDLE_LIST(CLEAR_REUSABLE_HANDLE)
#undef CLEAR_REUSABLE_HANDLE
}


void Thread::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);

  // Visit objects in thread specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

  // Visit the pending functions.
  if (pending_functions_ != GrowableObjectArray::null()) {
    visitor->VisitPointer(
        reinterpret_cast<RawObject**>(&pending_functions_));
  }

  // Visit the api local scope as it has all the api local handles.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    scope->local_handles()->VisitObjectPointers(visitor);
    scope = scope->previous();
  }
}


bool Thread::CanLoadFromThread(const Object& object) {
#define CHECK_OBJECT(type_name, member_name, expr, default_init_value)         \
  if (object.raw() == expr) return true;
CACHED_VM_OBJECTS_LIST(CHECK_OBJECT)
#undef CHECK_OBJECT
  return false;
}


intptr_t Thread::OffsetFromThread(const Object& object) {
#define COMPUTE_OFFSET(type_name, member_name, expr, default_init_value)       \
  ASSERT((expr)->IsVMHeapObject());                                            \
  if (object.raw() == expr) return Thread::member_name##offset();
CACHED_VM_OBJECTS_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET
  UNREACHABLE();
  return -1;
}


bool Thread::ObjectAtOffset(intptr_t offset, Object* object) {
#define COMPUTE_OFFSET(type_name, member_name, expr, default_init_value)       \
  if (Thread::member_name##offset() == offset) {                               \
    *object = expr;                                                            \
    return true;                                                               \
  }
CACHED_VM_OBJECTS_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET
  return false;
}


intptr_t Thread::OffsetFromThread(const RuntimeEntry* runtime_entry) {
#define COMPUTE_OFFSET(name)                                                   \
  if (runtime_entry->function() == k##name##RuntimeEntry.function())         { \
    return Thread::name##_entry_point_offset();                                \
  }
RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

#define COMPUTE_OFFSET(returntype, name, ...)                                  \
  if (runtime_entry->function() == k##name##RuntimeEntry.function())         { \
    return Thread::name##_entry_point_offset();                                \
  }
LEAF_RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

  UNREACHABLE();
  return -1;
}


bool Thread::IsValidLocalHandle(Dart_Handle object) const {
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    if (scope->local_handles()->IsValidHandle(object)) {
      return true;
    }
    scope = scope->previous();
  }
  return false;
}


int Thread::CountLocalHandles() const {
  int total = 0;
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    total += scope->local_handles()->CountHandles();
    scope = scope->previous();
  }
  return total;
}


int Thread::ZoneSizeInBytes() const {
  int total = 0;
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    total += scope->zone()->SizeInBytes();
    scope = scope->previous();
  }
  return total;
}


void Thread::UnwindScopes(uword stack_marker) {
  // Unwind all scopes using the same stack_marker, i.e. all scopes allocated
  // under the same top_exit_frame_info.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL &&
         scope->stack_marker() != 0 &&
         scope->stack_marker() == stack_marker) {
    api_top_scope_ = scope->previous();
    delete scope;
    scope = api_top_scope_;
  }
}


DisableThreadInterruptsScope::DisableThreadInterruptsScope(Thread* thread)
    : StackResource(thread) {
  if (thread != NULL) {
    OSThread* os_thread = thread->os_thread();
    ASSERT(os_thread != NULL);
    os_thread->DisableThreadInterrupts();
  }
}


DisableThreadInterruptsScope::~DisableThreadInterruptsScope() {
  if (thread() != NULL) {
    OSThread* os_thread = thread()->os_thread();
    ASSERT(os_thread != NULL);
    os_thread->EnableThreadInterrupts();
  }
}

}  // namespace dart
