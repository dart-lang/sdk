// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread.h"

#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/growable_array.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/profiler.h"
#include "vm/runtime_entry.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/zone.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/ffi_callback_trampolines.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#if !defined(PRODUCT)
DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_verbose);
#endif  // !defined(PRODUCT)

Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == NULL);
  ASSERT(store_buffer_block_ == NULL);
  ASSERT(marking_stack_block_ == NULL);
  // There should be no top api scopes at this point.
  ASSERT(api_top_scope() == NULL);
  // Delete the resusable api scope if there is one.
  if (api_reusable_scope_ != nullptr) {
    delete api_reusable_scope_;
    api_reusable_scope_ = NULL;
  }

  DO_IF_TSAN(delete tsan_utils_);
}

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object) object##_handle_(NULL),

Thread::Thread(bool is_vm_isolate)
    : ThreadState(false),
      stack_limit_(0),
      write_barrier_mask_(UntaggedObject::kGenerationalBarrierMask),
      heap_base_(0),
      isolate_(NULL),
      dispatch_table_array_(NULL),
      saved_stack_limit_(0),
      stack_overflow_flags_(0),
      heap_(NULL),
      top_exit_frame_info_(0),
      store_buffer_block_(NULL),
      marking_stack_block_(NULL),
      vm_tag_(0),
      unboxed_int64_runtime_arg_(0),
      unboxed_double_runtime_arg_(0.0),
      active_exception_(Object::null()),
      active_stacktrace_(Object::null()),
      global_object_pool_(ObjectPool::null()),
      resume_pc_(0),
      execution_state_(kThreadInNative),
      safepoint_state_(0),
      ffi_callback_code_(GrowableObjectArray::null()),
      ffi_callback_stack_return_(TypedData::null()),
      api_top_scope_(NULL),
      double_truncate_round_supported_(
          TargetCPUFeatures::double_truncate_round_supported() ? 1 : 0),
      tsan_utils_(DO_IF_TSAN(new TsanUtils()) DO_IF_NOT_TSAN(nullptr)),
      task_kind_(kUnknownTask),
      dart_stream_(NULL),
      thread_lock_(),
      api_reusable_scope_(NULL),
      no_callback_scope_depth_(0),
#if defined(DEBUG)
      no_safepoint_scope_depth_(0),
#endif
      reusable_handles_(),
      stack_overflow_count_(0),
      hierarchy_info_(NULL),
      type_usage_info_(NULL),
      sticky_error_(Error::null()),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
          REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
#if defined(USING_SAFE_STACK)
              saved_safestack_limit_(0),
#endif
      next_(NULL) {
#if defined(SUPPORT_TIMELINE)
  dart_stream_ = Timeline::GetDartStream();
  ASSERT(dart_stream_ != NULL);
#endif
#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
  CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#if !defined(TARGET_ARCH_IA32)
  for (intptr_t i = 0; i < kNumberOfDartAvailableCpuRegs; ++i) {
    write_barrier_wrappers_entry_points_[i] = 0;
  }
#endif

#define DEFAULT_INIT(name) name##_entry_point_ = 0;
  RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

#define DEFAULT_INIT(returntype, name, ...) name##_entry_point_ = 0;
  LEAF_RUNTIME_ENTRY_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

  // We cannot initialize the VM constants here for the vm isolate thread
  // due to boot strapping issues.
  if (!is_vm_isolate) {
    InitVMConstants();
  }
}

static const double double_nan_constant = NAN;

static const struct ALIGN16 {
  uint64_t a;
  uint64_t b;
} double_negate_constant = {0x8000000000000000ULL, 0x8000000000000000ULL};

static const struct ALIGN16 {
  uint64_t a;
  uint64_t b;
} double_abs_constant = {0x7FFFFFFFFFFFFFFFULL, 0x7FFFFFFFFFFFFFFFULL};

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_not_constant = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF};

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_negate_constant = {0x80000000, 0x80000000, 0x80000000, 0x80000000};

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_absolute_constant = {0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF};

static const struct ALIGN16 {
  uint32_t a;
  uint32_t b;
  uint32_t c;
  uint32_t d;
} float_zerow_constant = {0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000000};

void Thread::InitVMConstants() {
  heap_base_ = Object::null()->heap_base();

#define ASSERT_VM_HEAP(type_name, member_name, init_expr, default_init_value)  \
  ASSERT((init_expr)->IsOldObject());
  CACHED_VM_OBJECTS_LIST(ASSERT_VM_HEAP)
#undef ASSERT_VM_HEAP

#define INIT_VALUE(type_name, member_name, init_expr, default_init_value)      \
  ASSERT(member_name == default_init_value);                                   \
  member_name = (init_expr);
  CACHED_CONSTANTS_LIST(INIT_VALUE)
#undef INIT_VALUE

#if !defined(TARGET_ARCH_IA32)
  for (intptr_t i = 0; i < kNumberOfDartAvailableCpuRegs; ++i) {
    write_barrier_wrappers_entry_points_[i] =
        StubCode::WriteBarrierWrappers().EntryPoint() +
        i * kStoreBufferWrapperSize;
  }
#endif

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

void Thread::set_active_exception(const Object& value) {
  active_exception_ = value.ptr();
}

void Thread::set_active_stacktrace(const Object& value) {
  active_stacktrace_ = value.ptr();
}

ErrorPtr Thread::sticky_error() const {
  return sticky_error_;
}

void Thread::set_sticky_error(const Error& value) {
  ASSERT(!value.IsNull());
  sticky_error_ = value.ptr();
}

void Thread::ClearStickyError() {
  sticky_error_ = Error::null();
}

ErrorPtr Thread::StealStickyError() {
  NoSafepointScope no_safepoint;
  ErrorPtr return_value = sticky_error_;
  sticky_error_ = Error::null();
  return return_value;
}

const char* Thread::TaskKindToCString(TaskKind kind) {
  switch (kind) {
    case kUnknownTask:
      return "kUnknownTask";
    case kMutatorTask:
      return "kMutatorTask";
    case kCompilerTask:
      return "kCompilerTask";
    case kSweeperTask:
      return "kSweeperTask";
    case kMarkerTask:
      return "kMarkerTask";
    default:
      UNREACHABLE();
      return "";
  }
}

bool Thread::EnterIsolate(Isolate* isolate, bool is_nested_reenter) {
  const bool kIsMutatorThread = true;
  const bool kBypassSafepoint = false;

  is_nested_reenter = is_nested_reenter ||
                      (isolate->mutator_thread() != nullptr &&
                       isolate->mutator_thread()->top_exit_frame_info() != 0);

  Thread* thread = isolate->ScheduleThread(kIsMutatorThread, is_nested_reenter,
                                           kBypassSafepoint);
  if (thread != NULL) {
    ASSERT(thread->store_buffer_block_ == NULL);
    ASSERT(thread->isolate() == isolate);
    ASSERT(thread->isolate_group() == isolate->group());
    thread->FinishEntering(kMutatorTask);
    return true;
  }
  return false;
}

void Thread::ExitIsolate(bool is_nested_exit) {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  ASSERT(thread->IsMutatorThread());
  ASSERT(thread->isolate() != nullptr);
  ASSERT(thread->isolate_group() != nullptr);
  DEBUG_ASSERT(!thread->IsAnyReusableHandleScopeActive());

  thread->PrepareLeaving();

  Isolate* isolate = thread->isolate();
  thread->set_vm_tag(isolate->is_runnable() ? VMTag::kIdleTagId
                                            : VMTag::kLoadWaitTagId);
  const bool kIsMutatorThread = true;
  const bool kBypassSafepoint = false;
  is_nested_exit =
      is_nested_exit || (isolate->mutator_thread() != nullptr &&
                         isolate->mutator_thread()->top_exit_frame_info() != 0);
  isolate->UnscheduleThread(thread, kIsMutatorThread, is_nested_exit,
                            kBypassSafepoint);
}

bool Thread::EnterIsolateAsHelper(Isolate* isolate,
                                  TaskKind kind,
                                  bool bypass_safepoint) {
  ASSERT(kind != kMutatorTask);
  const bool kIsMutatorThread = false;
  const bool kIsNestedReenter = false;
  Thread* thread = isolate->ScheduleThread(kIsMutatorThread, kIsNestedReenter,
                                           bypass_safepoint);
  if (thread != NULL) {
    ASSERT(!thread->IsMutatorThread());
    ASSERT(thread->isolate() == isolate);
    ASSERT(thread->isolate_group() == isolate->group());
    thread->FinishEntering(kind);
    return true;
  }
  return false;
}

void Thread::ExitIsolateAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  ASSERT(!thread->IsMutatorThread());
  ASSERT(thread->isolate() != nullptr);
  ASSERT(thread->isolate_group() != nullptr);

  thread->PrepareLeaving();

  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  const bool kIsMutatorThread = false;
  const bool kIsNestedExit = false;
  isolate->UnscheduleThread(thread, kIsMutatorThread, kIsNestedExit,
                            bypass_safepoint);
}

bool Thread::EnterIsolateGroupAsHelper(IsolateGroup* isolate_group,
                                       TaskKind kind,
                                       bool bypass_safepoint) {
  ASSERT(kind != kMutatorTask);
  Thread* thread = isolate_group->ScheduleThread(bypass_safepoint);
  if (thread != NULL) {
    ASSERT(!thread->IsMutatorThread());
    ASSERT(thread->isolate() == nullptr);
    ASSERT(thread->isolate_group() == isolate_group);
    thread->FinishEntering(kind);
    return true;
  }
  return false;
}

void Thread::ExitIsolateGroupAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  ASSERT(!thread->IsMutatorThread());
  ASSERT(thread->isolate() == nullptr);
  ASSERT(thread->isolate_group() != nullptr);

  thread->PrepareLeaving();

  const bool kIsMutatorThread = false;
  thread->isolate_group()->UnscheduleThread(thread, kIsMutatorThread,
                                            bypass_safepoint);
}

void Thread::ReleaseStoreBuffer() {
  ASSERT(IsAtSafepoint());
  // Prevent scheduling another GC by ignoring the threshold.
  ASSERT(store_buffer_block_ != NULL);
  StoreBufferRelease(StoreBuffer::kIgnoreThreshold);
  // Make sure to get an *empty* block; the isolate needs all entries
  // at GC time.
  // TODO(koda): Replace with an epilogue (PrepareAfterGC) that acquires.
  store_buffer_block_ = isolate_group()->store_buffer()->PopEmptyBlock();
}

void Thread::SetStackLimit(uword limit) {
  // The thread setting the stack limit is not necessarily the thread which
  // the stack limit is being set on.
  MonitorLocker ml(&thread_lock_);
  if (!HasScheduledInterrupts()) {
    // No interrupt pending, set stack_limit_ too.
    stack_limit_.store(limit);
  }
  saved_stack_limit_ = limit;
}

void Thread::ClearStackLimit() {
  SetStackLimit(~static_cast<uword>(0));
}

static bool IsInterruptLimit(uword limit) {
  return (limit & ~Thread::kInterruptsMask) ==
         (kInterruptStackLimit & ~Thread::kInterruptsMask);
}

void Thread::ScheduleInterrupts(uword interrupt_bits) {
  ASSERT((interrupt_bits & ~kInterruptsMask) == 0);  // Must fit in mask.

  uword old_limit = stack_limit_.load();
  uword new_limit;
  do {
    if (IsInterruptLimit(old_limit)) {
      new_limit = old_limit | interrupt_bits;
    } else {
      new_limit = (kInterruptStackLimit & ~kInterruptsMask) | interrupt_bits;
    }
  } while (!stack_limit_.compare_exchange_weak(old_limit, new_limit));
}

uword Thread::GetAndClearInterrupts() {
  uword interrupt_bits = 0;
  uword old_limit = stack_limit_.load();
  uword new_limit = saved_stack_limit_;
  do {
    if (IsInterruptLimit(old_limit)) {
      interrupt_bits = interrupt_bits | (old_limit & kInterruptsMask);
    } else {
      return interrupt_bits;
    }
  } while (!stack_limit_.compare_exchange_weak(old_limit, new_limit));

  return interrupt_bits;
}

ErrorPtr Thread::HandleInterrupts() {
  uword interrupt_bits = GetAndClearInterrupts();
  if ((interrupt_bits & kVMInterrupt) != 0) {
    CheckForSafepoint();
    if (isolate_group()->store_buffer()->Overflowed()) {
      heap()->CollectGarbage(GCType::kScavenge, GCReason::kStoreBuffer);
    }

#if !defined(PRODUCT)
    // Don't block system isolates to process CPU samples to avoid blocking
    // them during critical tasks (e.g., initial compilation).
    if (!Isolate::IsSystemIsolate(isolate())) {
      // Processes completed SampleBlocks and sends CPU sample events over the
      // service protocol when applicable.
      SampleBlockBuffer* sample_buffer = Profiler::sample_block_buffer();
      if (sample_buffer != nullptr && sample_buffer->process_blocks()) {
        sample_buffer->ProcessCompletedBlocks();
      }
    }
#endif  // !defined(PRODUCT)
  }
  if ((interrupt_bits & kMessageInterrupt) != 0) {
    MessageHandler::MessageStatus status =
        isolate()->message_handler()->HandleOOBMessages();
    if (status != MessageHandler::kOK) {
      // False result from HandleOOBMessages signals that the isolate should
      // be terminating.
      if (FLAG_trace_isolates) {
        OS::PrintErr(
            "[!] Terminating isolate due to OOB message:\n"
            "\tisolate:    %s\n",
            isolate()->name());
      }
      return StealStickyError();
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

void Thread::StoreBufferAddObject(ObjectPtr obj) {
  ASSERT(this == Thread::Current());
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kCheckThreshold);
  }
}

void Thread::StoreBufferAddObjectGC(ObjectPtr obj) {
  store_buffer_block_->Push(obj);
  if (store_buffer_block_->IsFull()) {
    StoreBufferBlockProcess(StoreBuffer::kIgnoreThreshold);
  }
}

void Thread::StoreBufferRelease(StoreBuffer::ThresholdPolicy policy) {
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = NULL;
  isolate_group()->store_buffer()->PushBlock(block, policy);
}

void Thread::StoreBufferAcquire() {
  store_buffer_block_ = isolate_group()->store_buffer()->PopNonFullBlock();
}

void Thread::MarkingStackBlockProcess() {
  MarkingStackRelease();
  MarkingStackAcquire();
}

void Thread::DeferredMarkingStackBlockProcess() {
  DeferredMarkingStackRelease();
  DeferredMarkingStackAcquire();
}

void Thread::MarkingStackAddObject(ObjectPtr obj) {
  marking_stack_block_->Push(obj);
  if (marking_stack_block_->IsFull()) {
    MarkingStackBlockProcess();
  }
}

void Thread::DeferredMarkingStackAddObject(ObjectPtr obj) {
  deferred_marking_stack_block_->Push(obj);
  if (deferred_marking_stack_block_->IsFull()) {
    DeferredMarkingStackBlockProcess();
  }
}

void Thread::MarkingStackRelease() {
  MarkingStackBlock* block = marking_stack_block_;
  marking_stack_block_ = NULL;
  write_barrier_mask_ = UntaggedObject::kGenerationalBarrierMask;
  isolate_group()->marking_stack()->PushBlock(block);
}

void Thread::MarkingStackAcquire() {
  marking_stack_block_ = isolate_group()->marking_stack()->PopEmptyBlock();
  write_barrier_mask_ = UntaggedObject::kGenerationalBarrierMask |
                        UntaggedObject::kIncrementalBarrierMask;
}

void Thread::DeferredMarkingStackRelease() {
  MarkingStackBlock* block = deferred_marking_stack_block_;
  deferred_marking_stack_block_ = NULL;
  isolate_group()->deferred_marking_stack()->PushBlock(block);
}

void Thread::DeferredMarkingStackAcquire() {
  deferred_marking_stack_block_ =
      isolate_group()->deferred_marking_stack()->PopEmptyBlock();
}

bool Thread::CanCollectGarbage() const {
  // We grow the heap instead of triggering a garbage collection when a
  // thread is at a safepoint in the following situations :
  //   - background compiler thread finalizing and installing code
  //   - disassembly of the generated code is done after compilation
  // So essentially we state that garbage collection is possible only
  // when we are not at a safepoint.
  return !IsAtSafepoint();
}

bool Thread::IsExecutingDartCode() const {
  return (top_exit_frame_info() == 0) && VMTag::IsDartTag(vm_tag());
}

bool Thread::HasExitedDartCode() const {
  return (top_exit_frame_info() != 0) && !VMTag::IsDartTag(vm_tag());
}

template <class C>
C* Thread::AllocateReusableHandle() {
  C* handle = reinterpret_cast<C*>(reusable_handles_.AllocateScopedHandle());
  C::initializeHandle(handle, C::null());
  return handle;
}

void Thread::ClearReusableHandles() {
#define CLEAR_REUSABLE_HANDLE(object) *object##_handle_ = object::null();
  REUSABLE_HANDLE_LIST(CLEAR_REUSABLE_HANDLE)
#undef CLEAR_REUSABLE_HANDLE
}

void Thread::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                 ValidationPolicy validation_policy) {
  ASSERT(visitor != NULL);

  if (zone() != NULL) {
    zone()->VisitObjectPointers(visitor);
  }

  // Visit objects in thread specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&global_object_pool_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&active_exception_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&active_stacktrace_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&sticky_error_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&ffi_callback_code_));
  visitor->VisitPointer(
      reinterpret_cast<ObjectPtr*>(&ffi_callback_stack_return_));

  // Visit the api local scope as it has all the api local handles.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL) {
    scope->local_handles()->VisitObjectPointers(visitor);
    scope = scope->previous();
  }

  // Only the mutator thread can run Dart code.
  if (IsMutatorThread()) {
    // The MarkTask, which calls this method, can run on a different thread.  We
    // therefore assume the mutator is at a safepoint and we can iterate its
    // stack.
    // TODO(vm-team): It would be beneficial to be able to ask the mutator
    // thread whether it is in fact blocked at the moment (at a "safepoint") so
    // we can safely iterate its stack.
    //
    // Unfortunately we cannot use `this->IsAtSafepoint()` here because that
    // will return `false` even though the mutator thread is waiting for mark
    // tasks (which iterate its stack) to finish.
    const StackFrameIterator::CrossThreadPolicy cross_thread_policy =
        StackFrameIterator::kAllowCrossThreadIteration;

    // Iterate over all the stack frames and visit objects on the stack.
    StackFrameIterator frames_iterator(top_exit_frame_info(), validation_policy,
                                       this, cross_thread_policy);
    StackFrame* frame = frames_iterator.NextFrame();
    while (frame != NULL) {
      frame->VisitObjectPointers(visitor);
      frame = frames_iterator.NextFrame();
    }
  } else {
    // We are not on the mutator thread.
    RELEASE_ASSERT(top_exit_frame_info() == 0);
  }
}

class RestoreWriteBarrierInvariantVisitor : public ObjectPointerVisitor {
 public:
  RestoreWriteBarrierInvariantVisitor(IsolateGroup* group,
                                      Thread* thread,
                                      Thread::RestoreWriteBarrierInvariantOp op)
      : ObjectPointerVisitor(group),
        thread_(thread),
        current_(Thread::Current()),
        op_(op) {}

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) {
    for (; first != last + 1; first++) {
      ObjectPtr obj = *first;
      // Stores into new-space objects don't need a write barrier.
      if (obj->IsSmiOrNewObject()) continue;

      // To avoid adding too much work into the remembered set, skip large
      // arrays. Write barrier elimination will not remove the barrier
      // if we can trigger GC between array allocation and store.
      if (obj->GetClassId() == kArrayCid) {
        const auto length = Smi::Value(Array::RawCast(obj)->untag()->length());
        if (length > Array::kMaxLengthForWriteBarrierElimination) {
          continue;
        }
      }

      // Dart code won't store into VM-internal objects except Contexts and
      // UnhandledExceptions. This assumption is checked by an assertion in
      // WriteBarrierElimination::UpdateVectorForBlock.
      if (!obj->IsDartInstance() && !obj->IsContext() &&
          !obj->IsUnhandledException())
        continue;

      // Dart code won't store into canonical instances.
      if (obj->untag()->IsCanonical()) continue;

      // Objects in the VM isolate heap are immutable and won't be
      // stored into. Check this condition last because there's no bit
      // in the header for it.
      if (obj->untag()->InVMIsolateHeap()) continue;

      switch (op_) {
        case Thread::RestoreWriteBarrierInvariantOp::kAddToRememberedSet:
          obj->untag()->EnsureInRememberedSet(current_);
          if (current_->is_marking()) {
            current_->DeferredMarkingStackAddObject(obj);
          }
          break;
        case Thread::RestoreWriteBarrierInvariantOp::kAddToDeferredMarkingStack:
          // Re-scan obj when finalizing marking.
          current_->DeferredMarkingStackAddObject(obj);
          break;
      }
    }
  }

  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) {
    UNREACHABLE();  // Stack slots are not compressed.
  }

 private:
  Thread* const thread_;
  Thread* const current_;
  Thread::RestoreWriteBarrierInvariantOp op_;
};

// Write barrier elimination assumes that all live temporaries will be
// in the remembered set after a scavenge triggered by a non-Dart-call
// instruction (see Instruction::CanCallDart()), and additionally they will be
// in the deferred marking stack if concurrent marking started. Specifically,
// this includes any instruction which will always create an exit frame
// below the current frame before any other Dart frames.
//
// Therefore, to support this assumption, we scan the stack after a scavenge
// or when concurrent marking begins and add all live temporaries in
// Dart frames preceeding an exit frame to the store buffer or deferred
// marking stack.
void Thread::RestoreWriteBarrierInvariant(RestoreWriteBarrierInvariantOp op) {
  ASSERT(IsAtSafepoint());
  ASSERT(IsMutatorThread());

  const StackFrameIterator::CrossThreadPolicy cross_thread_policy =
      StackFrameIterator::kAllowCrossThreadIteration;
  StackFrameIterator frames_iterator(top_exit_frame_info(),
                                     ValidationPolicy::kDontValidateFrames,
                                     this, cross_thread_policy);
  RestoreWriteBarrierInvariantVisitor visitor(isolate_group(), this, op);
  ObjectStore* object_store = isolate_group()->object_store();
  bool scan_next_dart_frame = false;
  for (StackFrame* frame = frames_iterator.NextFrame(); frame != NULL;
       frame = frames_iterator.NextFrame()) {
    if (frame->IsExitFrame()) {
      scan_next_dart_frame = true;
    } else if (frame->IsEntryFrame()) {
      /* Continue searching. */
    } else if (frame->IsStubFrame()) {
      const uword pc = frame->pc();
      if (Code::ContainsInstructionAt(
              object_store->init_late_static_field_stub(), pc) ||
          Code::ContainsInstructionAt(
              object_store->init_late_final_static_field_stub(), pc) ||
          Code::ContainsInstructionAt(
              object_store->init_late_instance_field_stub(), pc) ||
          Code::ContainsInstructionAt(
              object_store->init_late_final_instance_field_stub(), pc)) {
        scan_next_dart_frame = true;
      }
    } else {
      ASSERT(frame->IsDartFrame(/*validate=*/false));
      if (scan_next_dart_frame) {
        frame->VisitObjectPointers(&visitor);
      }
      scan_next_dart_frame = false;
    }
  }
}

void Thread::DeferredMarkLiveTemporaries() {
  RestoreWriteBarrierInvariant(
      RestoreWriteBarrierInvariantOp::kAddToDeferredMarkingStack);
}

void Thread::RememberLiveTemporaries() {
  RestoreWriteBarrierInvariant(
      RestoreWriteBarrierInvariantOp::kAddToRememberedSet);
}

bool Thread::CanLoadFromThread(const Object& object) {
  // In order to allow us to use assembler helper routines with non-[Code]
  // objects *before* stubs are initialized, we only loop ver the stubs if the
  // [object] is in fact a [Code] object.
  if (object.IsCode()) {
#define CHECK_OBJECT(type_name, member_name, expr, default_init_value)         \
  if (object.ptr() == expr) {                                                  \
    return true;                                                               \
  }
    CACHED_VM_STUBS_LIST(CHECK_OBJECT)
#undef CHECK_OBJECT
  }

  // For non [Code] objects we check if the object equals to any of the cached
  // non-stub entries.
#define CHECK_OBJECT(type_name, member_name, expr, default_init_value)         \
  if (object.ptr() == expr) {                                                  \
    return true;                                                               \
  }
  CACHED_NON_VM_STUB_LIST(CHECK_OBJECT)
#undef CHECK_OBJECT
  return false;
}

intptr_t Thread::OffsetFromThread(const Object& object) {
  // In order to allow us to use assembler helper routines with non-[Code]
  // objects *before* stubs are initialized, we only loop ver the stubs if the
  // [object] is in fact a [Code] object.
  if (object.IsCode()) {
#define COMPUTE_OFFSET(type_name, member_name, expr, default_init_value)       \
  ASSERT((expr)->untag()->InVMIsolateHeap());                                  \
  if (object.ptr() == expr) {                                                  \
    return Thread::member_name##offset();                                      \
  }
    CACHED_VM_STUBS_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET
  }

  // For non [Code] objects we check if the object equals to any of the cached
  // non-stub entries.
#define COMPUTE_OFFSET(type_name, member_name, expr, default_init_value)       \
  if (object.ptr() == expr) {                                                  \
    return Thread::member_name##offset();                                      \
  }
  CACHED_NON_VM_STUB_LIST(COMPUTE_OFFSET)
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
  if (runtime_entry->function() == k##name##RuntimeEntry.function()) {         \
    return Thread::name##_entry_point_offset();                                \
  }
  RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

#define COMPUTE_OFFSET(returntype, name, ...)                                  \
  if (runtime_entry->function() == k##name##RuntimeEntry.function()) {         \
    return Thread::name##_entry_point_offset();                                \
  }
  LEAF_RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

  UNREACHABLE();
  return -1;
}

#if defined(DEBUG)
bool Thread::TopErrorHandlerIsSetJump() const {
  if (long_jump_base() == nullptr) return false;
  if (top_exit_frame_info_ == 0) return true;
#if defined(USING_SIMULATOR) || defined(USING_SAFE_STACK)
  // False positives: simulator stack and native stack are unordered.
  return true;
#else
  return reinterpret_cast<uword>(long_jump_base()) < top_exit_frame_info_;
#endif
}

bool Thread::TopErrorHandlerIsExitFrame() const {
  if (top_exit_frame_info_ == 0) return false;
  if (long_jump_base() == nullptr) return true;
#if defined(USING_SIMULATOR) || defined(USING_SAFE_STACK)
  // False positives: simulator stack and native stack are unordered.
  return true;
#else
  return top_exit_frame_info_ < reinterpret_cast<uword>(long_jump_base());
#endif
}
#endif  // defined(DEBUG)

bool Thread::IsValidHandle(Dart_Handle object) const {
  return IsValidLocalHandle(object) || IsValidZoneHandle(object) ||
         IsValidScopedHandle(object);
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

intptr_t Thread::CountLocalHandles() const {
  intptr_t total = 0;
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

void Thread::EnterApiScope() {
  ASSERT(MayAllocateHandles());
  ApiLocalScope* new_scope = api_reusable_scope();
  if (new_scope == NULL) {
    new_scope = new ApiLocalScope(api_top_scope(), top_exit_frame_info());
    ASSERT(new_scope != NULL);
  } else {
    new_scope->Reinit(this, api_top_scope(), top_exit_frame_info());
    set_api_reusable_scope(NULL);
  }
  set_api_top_scope(new_scope);  // New scope is now the top scope.
}

void Thread::ExitApiScope() {
  ASSERT(MayAllocateHandles());
  ApiLocalScope* scope = api_top_scope();
  ApiLocalScope* reusable_scope = api_reusable_scope();
  set_api_top_scope(scope->previous());  // Reset top scope to previous.
  if (reusable_scope == NULL) {
    scope->Reset(this);  // Reset the old scope which we just exited.
    set_api_reusable_scope(scope);
  } else {
    ASSERT(reusable_scope != scope);
    delete scope;
  }
}

void Thread::UnwindScopes(uword stack_marker) {
  // Unwind all scopes using the same stack_marker, i.e. all scopes allocated
  // under the same top_exit_frame_info.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != NULL && scope->stack_marker() != 0 &&
         scope->stack_marker() == stack_marker) {
    api_top_scope_ = scope->previous();
    delete scope;
    scope = api_top_scope_;
  }
}

void Thread::EnterSafepointUsingLock() {
  isolate_group()->safepoint_handler()->EnterSafepointUsingLock(this);
}

void Thread::ExitSafepointUsingLock() {
  isolate_group()->safepoint_handler()->ExitSafepointUsingLock(this);
}

void Thread::BlockForSafepoint() {
  isolate_group()->safepoint_handler()->BlockForSafepoint(this);
}

void Thread::FinishEntering(TaskKind kind) {
  ASSERT(store_buffer_block_ == nullptr);

  task_kind_ = kind;
  if (isolate_group()->marking_stack() != NULL) {
    // Concurrent mark in progress. Enable barrier for this thread.
    MarkingStackAcquire();
    DeferredMarkingStackAcquire();
  }

  // TODO(koda): Use StoreBufferAcquire once we properly flush
  // before Scavenge.
  if (kind == kMutatorTask) {
    StoreBufferAcquire();
  } else {
    store_buffer_block_ = isolate_group()->store_buffer()->PopEmptyBlock();
  }
}

void Thread::PrepareLeaving() {
  ASSERT(store_buffer_block_ != nullptr);
  ASSERT(execution_state() == Thread::kThreadInVM);

  task_kind_ = kUnknownTask;
  if (is_marking()) {
    MarkingStackRelease();
    DeferredMarkingStackRelease();
  }
  StoreBufferRelease();
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

const intptr_t kInitialCallbackIdsReserved = 16;
int32_t Thread::AllocateFfiCallbackId() {
  Zone* Z = Thread::Current()->zone();
  if (ffi_callback_code_ == GrowableObjectArray::null()) {
    ffi_callback_code_ = GrowableObjectArray::New(kInitialCallbackIdsReserved);
  }
  const auto& array = GrowableObjectArray::Handle(Z, ffi_callback_code_);
  array.Add(Code::Handle(Z, Code::null()));
  const int32_t id = array.Length() - 1;

  // Allocate a native callback trampoline if necessary.
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (NativeCallbackTrampolines::Enabled()) {
    auto* const tramps = isolate()->native_callback_trampolines();
    ASSERT(tramps->next_callback_id() == id);
    tramps->AllocateTrampoline();
  }
#endif

  return id;
}

void Thread::SetFfiCallbackCode(int32_t callback_id, const Code& code) {
  Zone* Z = Thread::Current()->zone();

  /// In AOT the callback ID might have been allocated during compilation but
  /// 'ffi_callback_code_' is initialized to empty again when the program
  /// starts. Therefore we may need to initialize or expand it to accomodate
  /// the callback ID.

  if (ffi_callback_code_ == GrowableObjectArray::null()) {
    ffi_callback_code_ = GrowableObjectArray::New(kInitialCallbackIdsReserved);
  }

  const auto& array = GrowableObjectArray::Handle(Z, ffi_callback_code_);

  if (callback_id >= array.Length()) {
    const int32_t capacity = array.Capacity();
    if (callback_id >= capacity) {
      // Ensure both that we grow enough and an exponential growth strategy.
      const int32_t new_capacity =
          Utils::Maximum(callback_id + 1, capacity * 2);
      array.Grow(new_capacity);
    }
    array.SetLength(callback_id + 1);
  }

  array.SetAt(callback_id, code);
}

void Thread::SetFfiCallbackStackReturn(int32_t callback_id,
                                       intptr_t stack_return_delta) {
#if defined(TARGET_ARCH_IA32)
#else
  UNREACHABLE();
#endif

  Zone* Z = Thread::Current()->zone();

  /// In AOT the callback ID might have been allocated during compilation but
  /// 'ffi_callback_code_' is initialized to empty again when the program
  /// starts. Therefore we may need to initialize or expand it to accomodate
  /// the callback ID.

  if (ffi_callback_stack_return_ == TypedData::null()) {
    ffi_callback_stack_return_ = TypedData::New(
        kTypedDataInt8ArrayCid, kInitialCallbackIdsReserved, Heap::kOld);
  }

  auto& array = TypedData::Handle(Z, ffi_callback_stack_return_);

  if (callback_id >= array.Length()) {
    const int32_t capacity = array.Length();
    if (callback_id >= capacity) {
      // Ensure both that we grow enough and an exponential growth strategy.
      const int32_t new_capacity =
          Utils::Maximum(callback_id + 1, capacity * 2);
      const auto& new_array = TypedData::Handle(
          Z, TypedData::New(kTypedDataUint8ArrayCid, new_capacity, Heap::kOld));
      for (intptr_t i = 0; i < capacity; i++) {
        new_array.SetUint8(i, array.GetUint8(i));
      }
      array ^= new_array.ptr();
      ffi_callback_stack_return_ = new_array.ptr();
    }
  }

  ASSERT(callback_id < array.Length());
  array.SetUint8(callback_id, stack_return_delta);
}

void Thread::VerifyCallbackIsolate(int32_t callback_id, uword entry) {
  NoSafepointScope _;

  const GrowableObjectArrayPtr array = ffi_callback_code_;
  if (array == GrowableObjectArray::null()) {
    FATAL("Cannot invoke callback on incorrect isolate.");
  }

  const SmiPtr length_smi = GrowableObjectArray::NoSafepointLength(array);
  const intptr_t length = Smi::Value(length_smi);

  if (callback_id < 0 || callback_id >= length) {
    FATAL("Cannot invoke callback on incorrect isolate.");
  }

  if (entry != 0) {
    CompressedObjectPtr* const code_array =
        Array::DataOf(GrowableObjectArray::NoSafepointData(array));
    // RawCast allocates handles in ASSERTs.
    const CodePtr code = static_cast<CodePtr>(
        code_array[callback_id].Decompress(array.heap_base()));
    if (!Code::ContainsInstructionAt(code, entry)) {
      FATAL("Cannot invoke callback on incorrect isolate.");
    }
  }
}

}  // namespace dart
