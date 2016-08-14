// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/compiler_stats.h"
#include "vm/dart_api_state.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"

namespace dart {


DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_verbose);


Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
  if (compiler_stats_ != NULL) {
    delete compiler_stats_;
    compiler_stats_ = NULL;
  }
  // There should be no top api scopes at this point.
  ASSERT(api_top_scope() == NULL);
  // Delete the resusable api scope if there is one.
  if (api_reusable_scope_) {
    delete api_reusable_scope_;
    api_reusable_scope_ = NULL;
  }
  delete thread_lock_;
  thread_lock_ = NULL;
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
      stack_limit_(0),
      stack_overflow_flags_(0),
      isolate_(NULL),
      heap_(NULL),
      top_exit_frame_info_(0),
      store_buffer_block_(NULL),
      vm_tag_(0),
      task_kind_(kUnknownTask),
      dart_stream_(NULL),
      os_thread_(NULL),
      thread_lock_(new Monitor()),
      zone_(NULL),
      api_reusable_scope_(NULL),
      api_top_scope_(NULL),
      top_resource_(NULL),
      long_jump_base_(NULL),
      no_callback_scope_depth_(0),
#if defined(DEBUG)
      top_handle_scope_(NULL),
      no_handle_scope_depth_(0),
      no_safepoint_scope_depth_(0),
#endif
      reusable_handles_(),
      saved_stack_limit_(0),
      defer_oob_messages_count_(0),
      deferred_interrupts_mask_(0),
      deferred_interrupts_(0),
      stack_overflow_count_(0),
      cha_(NULL),
      deopt_id_(0),
      pending_functions_(GrowableObjectArray::null()),
      sticky_error_(Error::null()),
      compiler_stats_(NULL),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
      safepoint_state_(0),
      execution_state_(kThreadInNative),
      next_(NULL) {
NOT_IN_PRODUCT(
  dart_stream_ = Timeline::GetDartStream();
  ASSERT(dart_stream_ != NULL);
)
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

  if (FLAG_support_compiler_stats) {
    compiler_stats_ = new CompilerStats(isolate);
    if (FLAG_compiler_benchmark) {
      compiler_stats_->EnableBenchmark();
    }
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


void Thread::clear_pending_functions() {
  pending_functions_ = GrowableObjectArray::null();
}


RawError* Thread::sticky_error() const {
  return sticky_error_;
}


void Thread::set_sticky_error(const Error& value) {
  ASSERT(!value.IsNull());
  sticky_error_ = value.raw();
}


void Thread::clear_sticky_error() {
  sticky_error_ = Error::null();
}


bool Thread::EnterIsolate(Isolate* isolate) {
  const bool kIsMutatorThread = true;
  Thread* thread = isolate->ScheduleThread(kIsMutatorThread);
  if (thread != NULL) {
    ASSERT(thread->store_buffer_block_ == NULL);
    thread->task_kind_ = kMutatorTask;
    thread->StoreBufferAcquire();
    return true;
  }
  return false;
}


void Thread::ExitIsolate() {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL && thread->IsMutatorThread());
  DEBUG_ASSERT(!thread->IsAnyReusableHandleScopeActive());
  thread->task_kind_ = kUnknownTask;
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  // Clear since GC will not visit the thread once it is unscheduled.
  thread->ClearReusableHandles();
  thread->StoreBufferRelease();
  if (isolate->is_runnable()) {
    thread->set_vm_tag(VMTag::kIdleTagId);
  } else {
    thread->set_vm_tag(VMTag::kLoadWaitTagId);
  }
  const bool kIsMutatorThread = true;
  isolate->UnscheduleThread(thread, kIsMutatorThread);
}


bool Thread::EnterIsolateAsHelper(Isolate* isolate,
                                  TaskKind kind,
                                  bool bypass_safepoint) {
  ASSERT(kind != kMutatorTask);
  const bool kIsNotMutatorThread = false;
  Thread* thread = isolate->ScheduleThread(kIsNotMutatorThread,
                                           bypass_safepoint);
  if (thread != NULL) {
    ASSERT(thread->store_buffer_block_ == NULL);
    // TODO(koda): Use StoreBufferAcquire once we properly flush
    // before Scavenge.
    thread->store_buffer_block_ =
        thread->isolate()->store_buffer()->PopEmptyBlock();
    // This thread should not be the main mutator.
    thread->task_kind_ = kind;
    ASSERT(!thread->IsMutatorThread());
    return true;
  }
  return false;
}


void Thread::ExitIsolateAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  ASSERT(thread != NULL);
  ASSERT(!thread->IsMutatorThread());
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  thread->task_kind_ = kUnknownTask;
  // Clear since GC will not visit the thread once it is unscheduled.
  thread->ClearReusableHandles();
  thread->StoreBufferRelease();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  const bool kIsNotMutatorThread = false;
  isolate->UnscheduleThread(thread, kIsNotMutatorThread, bypass_safepoint);
}


void Thread::PrepareForGC() {
  ASSERT(IsAtSafepoint());
  // Prevent scheduling another GC by ignoring the threshold.
  ASSERT(store_buffer_block_ != NULL);
  StoreBufferRelease(StoreBuffer::kIgnoreThreshold);
  // Make sure to get an *empty* block; the isolate needs all entries
  // at GC time.
  // TODO(koda): Replace with an epilogue (PrepareAfterGC) that acquires.
  store_buffer_block_ = isolate()->store_buffer()->PopEmptyBlock();
}


void Thread::SetStackLimitFromStackBase(uword stack_base) {
  // Set stack limit.
#if !defined(TARGET_ARCH_DBC)
#if defined(USING_SIMULATOR)
  // Ignore passed-in native stack top and use Simulator stack top.
  Simulator* sim = Simulator::Current();  // May allocate a simulator.
  ASSERT(isolate()->simulator() == sim);  // Isolate's simulator is current one.
  stack_base = sim->StackTop();
  // The overflow area is accounted for by the simulator.
#endif
  SetStackLimit(stack_base - OSThread::GetSpecifiedStackSize());
#else
  SetStackLimit(Simulator::Current()->StackTop());
#endif  // !defined(TARGET_ARCH_DBC)
}


void Thread::SetStackLimit(uword limit) {
  // The thread setting the stack limit is not necessarily the thread which
  // the stack limit is being set on.
  MonitorLocker ml(thread_lock_);
  if (stack_limit_ == saved_stack_limit_) {
    // No interrupt pending, set stack_limit_ too.
    stack_limit_ = limit;
  }
  saved_stack_limit_ = limit;
}


void Thread::ClearStackLimit() {
  SetStackLimit(~static_cast<uword>(0));
}


/* static */
uword Thread::GetCurrentStackPointer() {
#if !defined(TARGET_ARCH_DBC)
  // Since AddressSanitizer's detect_stack_use_after_return instruments the
  // C++ code to give out fake stack addresses, we call a stub in that case.
  ASSERT(StubCode::GetStackPointer_entry() != NULL);
  uword (*func)() = reinterpret_cast<uword (*)()>(
      StubCode::GetStackPointer_entry()->EntryPoint());
#else
  uword (*func)() = NULL;
#endif
  // But for performance (and to support simulators), we normally use a local.
#if defined(__has_feature)
#if __has_feature(address_sanitizer)
  uword current_sp = func();
  return current_sp;
#else
  uword stack_allocated_local_address = reinterpret_cast<uword>(&func);
  return stack_allocated_local_address;
#endif
#else
  uword stack_allocated_local_address = reinterpret_cast<uword>(&func);
  return stack_allocated_local_address;
#endif
}


void Thread::ScheduleInterrupts(uword interrupt_bits) {
  MonitorLocker ml(thread_lock_);
  ScheduleInterruptsLocked(interrupt_bits);
}


void Thread::ScheduleInterruptsLocked(uword interrupt_bits) {
  ASSERT(thread_lock_->IsOwnedByCurrentThread());
  ASSERT((interrupt_bits & ~kInterruptsMask) == 0);  // Must fit in mask.

  // Check to see if any of the requested interrupts should be deferred.
  uword defer_bits = interrupt_bits & deferred_interrupts_mask_;
  if (defer_bits != 0) {
    deferred_interrupts_ |= defer_bits;
    interrupt_bits &= ~deferred_interrupts_mask_;
    if (interrupt_bits == 0) {
      return;
    }
  }

  if (stack_limit_ == saved_stack_limit_) {
    stack_limit_ = kInterruptStackLimit & ~kInterruptsMask;
  }
  stack_limit_ |= interrupt_bits;
}


uword Thread::GetAndClearInterrupts() {
  MonitorLocker ml(thread_lock_);
  if (stack_limit_ == saved_stack_limit_) {
    return 0;  // No interrupt was requested.
  }
  uword interrupt_bits = stack_limit_ & kInterruptsMask;
  stack_limit_ = saved_stack_limit_;
  return interrupt_bits;
}


void Thread::DeferOOBMessageInterrupts() {
  MonitorLocker ml(thread_lock_);
  defer_oob_messages_count_++;
  if (defer_oob_messages_count_ > 1) {
    // OOB message interrupts are already deferred.
    return;
  }
  ASSERT(deferred_interrupts_mask_ == 0);
  deferred_interrupts_mask_ = kMessageInterrupt;

  if (stack_limit_ != saved_stack_limit_) {
    // Defer any interrupts which are currently pending.
    deferred_interrupts_ = stack_limit_ & deferred_interrupts_mask_;

    // Clear deferrable interrupts, if present.
    stack_limit_ &= ~deferred_interrupts_mask_;

    if ((stack_limit_ & kInterruptsMask) == 0) {
      // No other pending interrupts.  Restore normal stack limit.
      stack_limit_ = saved_stack_limit_;
    }
  }
  if (FLAG_trace_service && FLAG_trace_service_verbose) {
    OS::Print("[+%" Pd64 "ms] Isolate %s deferring OOB interrupts\n",
              Dart::timestamp(), isolate()->name());
  }
}


void Thread::RestoreOOBMessageInterrupts() {
  MonitorLocker ml(thread_lock_);
  defer_oob_messages_count_--;
  if (defer_oob_messages_count_ > 0) {
    return;
  }
  ASSERT(defer_oob_messages_count_ == 0);
  ASSERT(deferred_interrupts_mask_ == kMessageInterrupt);
  deferred_interrupts_mask_ = 0;
  if (deferred_interrupts_ != 0) {
    if (stack_limit_ == saved_stack_limit_) {
      stack_limit_ = kInterruptStackLimit & ~kInterruptsMask;
    }
    stack_limit_ |= deferred_interrupts_;
    deferred_interrupts_ = 0;
  }
  if (FLAG_trace_service && FLAG_trace_service_verbose) {
    OS::Print("[+%" Pd64 "ms] Isolate %s restoring OOB interrupts\n",
              Dart::timestamp(), isolate()->name());
  }
}


RawError* Thread::HandleInterrupts() {
  uword interrupt_bits = GetAndClearInterrupts();
  if ((interrupt_bits & kVMInterrupt) != 0) {
    if (isolate()->store_buffer()->Overflowed()) {
      if (FLAG_verbose_gc) {
        OS::PrintErr("Scavenge scheduled by store buffer overflow.\n");
      }
      heap()->CollectGarbage(Heap::kNew);
    }
  }
  if ((interrupt_bits & kMessageInterrupt) != 0) {
    MessageHandler::MessageStatus status =
        isolate()->message_handler()->HandleOOBMessages();
    if (status != MessageHandler::kOK) {
      // False result from HandleOOBMessages signals that the isolate should
      // be terminating.
      if (FLAG_trace_isolates) {
        OS::Print("[!] Terminating isolate due to OOB message:\n"
                  "\tisolate:    %s\n", isolate()->name());
      }
      Thread* thread = Thread::Current();
      const Error& error = Error::Handle(thread->sticky_error());
      ASSERT(!error.IsNull() && error.IsUnwindError());
      thread->clear_sticky_error();
      return error.raw();
    }
  }
  return Error::null();
}


uword Thread::GetAndClearStackOverflowFlags() {
  uword stack_overflow_flags = stack_overflow_flags_;
  stack_overflow_flags_ = 0;
  return stack_overflow_flags;
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


bool Thread::CanCollectGarbage() const {
  // We have non mutator threads grow the heap instead of triggering
  // a garbage collection when they are at a safepoint (e.g: background
  // compiler thread finalizing and installing code at a safepoint).
  return (IsMutatorThread() || IsAtSafepoint());
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


void Thread::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                 bool validate_frames) {
  ASSERT(visitor != NULL);

  if (zone_ != NULL) {
    zone_->VisitObjectPointers(visitor);
  }

  // Visit objects in thread specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&pending_functions_));
  visitor->VisitPointer(
      reinterpret_cast<RawObject**>(&sticky_error_));

  // Visit the api local scope as it has all the api local handles.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    scope->local_handles()->VisitObjectPointers(visitor);
    scope = scope->previous();
  }

  // Iterate over all the stack frames and visit objects on the stack.
  StackFrameIterator frames_iterator(top_exit_frame_info(),
                                     validate_frames);
  StackFrame* frame = frames_iterator.NextFrame();
  while (frame != NULL) {
    frame->VisitObjectPointers(visitor);
    frame = frames_iterator.NextFrame();
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
  if (Isolate::Current() == Dart::vm_isolate()) {
    // --disassemble-stubs runs before all the references through
    // thread have targets
    return false;
  }

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


void Thread::EnterSafepointUsingLock() {
  isolate()->safepoint_handler()->EnterSafepointUsingLock(this);
}


void Thread::ExitSafepointUsingLock() {
  isolate()->safepoint_handler()->ExitSafepointUsingLock(this);
}


void Thread::BlockForSafepoint() {
  isolate()->safepoint_handler()->BlockForSafepoint(this);
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
