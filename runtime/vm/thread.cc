// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/thread.h"

#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/deopt_instructions.h"
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
#include "vm/service.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/zone.h"

namespace dart {

#if !defined(PRODUCT)
DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_verbose);
#endif  // !defined(PRODUCT)

Thread::~Thread() {
  // We should cleanly exit any isolate before destruction.
  ASSERT(isolate_ == nullptr);
  ASSERT(store_buffer_block_ == nullptr);
  ASSERT(old_marking_stack_block_ == nullptr);
  ASSERT(new_marking_stack_block_ == nullptr);
  ASSERT(deferred_marking_stack_block_ == nullptr);
  ASSERT(!ActiveMutatorStolenField::decode(safepoint_state_));
  ASSERT(deopt_context_ ==
         nullptr);  // No deopt in progress when thread is deleted.
#if defined(DART_DYNAMIC_MODULES)
  delete interpreter_;
  interpreter_ = nullptr;
#endif
  // There should be no top api scopes at this point.
  ASSERT(api_top_scope() == nullptr);
  // Delete the reusable api scope if there is one.
  if (api_reusable_scope_ != nullptr) {
    delete api_reusable_scope_;
    api_reusable_scope_ = nullptr;
  }

  DO_IF_TSAN(delete tsan_utils_);
}

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object) object##_handle_(nullptr),

Thread::Thread(bool is_vm_isolate)
    : ThreadState(false),
      write_barrier_mask_(UntaggedObject::kGenerationalBarrierMask),
      active_exception_(Object::null()),
      active_stacktrace_(Object::null()),
      global_object_pool_(ObjectPool::null()),
      resume_pc_(0),
      execution_state_(kThreadInNative),
      safepoint_state_(0),
      api_top_scope_(nullptr),
      double_truncate_round_supported_(
          TargetCPUFeatures::double_truncate_round_supported() ? 1 : 0),
      tsan_utils_(DO_IF_TSAN(new TsanUtils()) DO_IF_NOT_TSAN(nullptr)),
      current_tag_(UserTag::null()),
      default_tag_(UserTag::null()),
      task_kind_(kUnknownTask),
#if defined(SUPPORT_TIMELINE)
      dart_stream_(ASSERT_NOTNULL(Timeline::GetDartStream())),
#else
      dart_stream_(nullptr),
#endif
#if !defined(PRODUCT)
      service_extension_stream_(ASSERT_NOTNULL(&Service::extension_stream)),
#else
      service_extension_stream_(nullptr),
#endif
      thread_lock_(),
      api_reusable_scope_(nullptr),
      no_callback_scope_depth_(0),
#if defined(DEBUG)
      no_safepoint_scope_depth_(0),
#endif
      reusable_handles_(),
      stack_overflow_count_(0),
      hierarchy_info_(nullptr),
      type_usage_info_(nullptr),
      sticky_error_(Error::null()),
      REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_INITIALIZERS)
          REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_INIT)
#if defined(USING_SAFE_STACK)
              saved_safestack_limit_(0),
#endif
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
      next_(nullptr),
      heap_sampler_(this) {
#else
              next_(nullptr) {
#endif

#define DEFAULT_INIT(type_name, member_name, init_expr, default_init_value)    \
  member_name = default_init_value;
  CACHED_CONSTANTS_LIST(DEFAULT_INIT)
#undef DEFAULT_INIT

  for (intptr_t i = 0; i < kNumberOfDartAvailableCpuRegs; ++i) {
    write_barrier_wrappers_entry_points_[i] = 0;
  }

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

#if defined(DART_HOST_OS_FUCHSIA)
  next_task_id_ = trace_generate_nonce();
#else
  next_task_id_ = Random::GlobalNextUInt64();
#endif

  memset(&unboxed_runtime_arg_, 0, sizeof(simd128_value_t));
  set_user_tag(UserTags::kDefaultUserTag);
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
#if defined(DART_COMPRESSED_POINTERS)
  heap_base_ = Object::null()->heap_base();
#endif

#define ASSERT_VM_HEAP(type_name, member_name, init_expr, default_init_value)  \
  ASSERT((init_expr)->IsOldObject());
  CACHED_VM_OBJECTS_LIST(ASSERT_VM_HEAP)
#undef ASSERT_VM_HEAP

#define INIT_VALUE(type_name, member_name, init_expr, default_init_value)      \
  ASSERT(member_name == default_init_value);                                   \
  member_name = (init_expr);
  CACHED_CONSTANTS_LIST(INIT_VALUE)
#undef INIT_VALUE

  for (intptr_t i = 0; i < kNumberOfDartAvailableCpuRegs; ++i) {
    write_barrier_wrappers_entry_points_[i] =
        StubCode::WriteBarrierWrappers().EntryPoint() +
        i * kStoreBufferWrapperSize;
  }

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

#if defined(SIMULATOR_FFI)
  // FfiCallInstr calls this through the CallNativeThroughSafepoint stub instead
  // of like a normal leaf runtime call.
  PropagateError_entry_point_ =
      kPropagateErrorRuntimeEntry.GetEntryPointNoRedirect();
#endif

// Setup the thread specific reusable handles.
#define REUSABLE_HANDLE_ALLOCATION(object)                                     \
  this->object##_handle_ = this->AllocateReusableHandle<object>();
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_ALLOCATION)
#undef REUSABLE_HANDLE_ALLOCATION
}

void Thread::set_active_exception(const Object& value) {
  active_exception_ = value.ptr();
}

void Thread::set_active_exception(LocalHandle* value) {
  active_exception_ = ObjectPtr(reinterpret_cast<uword>(value));
  ASSERT(active_exception_.IsImmediateObject());  // GC won't try to visit this.
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

void Thread::set_current_tag(const UserTag& tag) {
  uword user_tag = tag.tag();
  ASSERT(user_tag < kUwordMax);
  set_user_tag(user_tag);
  current_tag_ = tag.ptr();
}

void Thread::set_default_tag(const UserTag& tag) {
  default_tag_ = tag.ptr();
}

ErrorPtr Thread::StealStickyError() {
  NoSafepointScope no_safepoint;
  ErrorPtr return_value = sticky_error_;
  sticky_error_ = Error::null();
  return return_value;
}

void Thread::AssertNonMutatorInvariants() {
  ASSERT(BypassSafepoints());
  ASSERT(store_buffer_block_ == nullptr);
  ASSERT(old_marking_stack_block_ == nullptr);
  ASSERT(new_marking_stack_block_ == nullptr);
  ASSERT(deferred_marking_stack_block_ == nullptr);
  AssertNonDartMutatorInvariants();
}

void Thread::AssertDartMutatorInvariants() {
  ASSERT(IsDartMutatorThread());
  ASSERT(isolate() == nullptr);
  ASSERT(isolate_group() != nullptr);
  ASSERT(task_kind_ == kMutatorTask);
  DEBUG_ASSERT(!IsAnyReusableHandleScopeActive());
}

void Thread::AssertNonDartMutatorInvariants() {
  ASSERT(!IsDartMutatorThread());
  ASSERT(isolate() == nullptr);
  ASSERT(isolate_group() != nullptr);
  ASSERT(task_kind_ != kMutatorTask);
  DEBUG_ASSERT(!IsAnyReusableHandleScopeActive());
}

void Thread::AssertEmptyStackInvariants() {
  ASSERT(zone() == nullptr);
  ASSERT(top_handle_scope() == nullptr);
  ASSERT(long_jump_base() == nullptr);
  ASSERT(top_resource() == nullptr);
  ASSERT(top_exit_frame_info_ == 0);
  ASSERT(api_top_scope_ == nullptr);
  ASSERT(!pending_deopts_.HasPendingDeopts());
  ASSERT(compiler_state_ == nullptr);
  ASSERT(hierarchy_info_ == nullptr);
  ASSERT(type_usage_info_ == nullptr);
  ASSERT(no_active_isolate_scope_ == nullptr);
  ASSERT(compiler_timings_ == nullptr);
  ASSERT(!exit_through_ffi_);
  ASSERT(runtime_call_deopt_ability_ == RuntimeCallDeoptAbility::kCanLazyDeopt);
  ASSERT(no_callback_scope_depth_ == 0);
  ASSERT(force_growth_scope_depth_ == 0);
  ASSERT(no_reload_scope_depth_ == 0);
  ASSERT(stopped_mutators_scope_depth_ == 0);
  ASSERT(stack_overflow_flags_ == 0);
  DEBUG_ASSERT(!inside_compiler_);
  DEBUG_ASSERT(no_safepoint_scope_depth_ == 0);

  // Avoid running these asserts for `vm-isolate`.
  if (active_stacktrace_.untag() != 0) {
    ASSERT(sticky_error() == Error::null());
    ASSERT(active_exception_ == Object::null());
    ASSERT(active_stacktrace_ == Object::null());
  }
}

void Thread::AssertEmptyThreadInvariants() {
  AssertEmptyStackInvariants();

  ASSERT(top() == 0);
  ASSERT(end_ == 0);
  ASSERT(true_end_ == 0);
  ASSERT(isolate_ == nullptr);
  ASSERT(isolate_group_ == nullptr);
  ASSERT(os_thread() == nullptr);
  ASSERT(vm_tag_ == VMTag::kInvalidTagId);
  ASSERT(task_kind_ == kUnknownTask);
  ASSERT(execution_state_ == Thread::kThreadInNative);
  ASSERT(scheduled_dart_mutator_isolate_ == nullptr);

  ASSERT(write_barrier_mask_ == UntaggedObject::kGenerationalBarrierMask);
  ASSERT(store_buffer_block_ == nullptr);
  ASSERT(old_marking_stack_block_ == nullptr);
  ASSERT(new_marking_stack_block_ == nullptr);
  ASSERT(deferred_marking_stack_block_ == nullptr);
  ASSERT(!is_unwind_in_progress_);

  ASSERT(saved_stack_limit_ == OSThread::kInvalidStackLimit);
  ASSERT(stack_limit_.load() == 0);
  ASSERT(safepoint_state_ == 0);

  ASSERT(default_tag_ == UserTag::null());
  ASSERT(current_tag_ == UserTag::null());

  // Avoid running these asserts for `vm-isolate`.
  if (active_stacktrace_.untag() != 0) {
    ASSERT(field_table_values_ == nullptr);
    ASSERT(shared_field_table_values_ == nullptr);
    ASSERT(global_object_pool_ == Object::null());
#define CHECK_REUSABLE_HANDLE(object) ASSERT(object##_handle_->IsNull());
    REUSABLE_HANDLE_LIST(CHECK_REUSABLE_HANDLE)
#undef CHECK_REUSABLE_HANDLE
  }
}

bool Thread::HasActiveState() {
  // Do we have active dart frames?
  if (top_exit_frame_info() != 0) {
    return true;
  }
  // Do we have active embedder scopes?
  if (api_top_scope() != nullptr) {
    return true;
  }
  // Do we have active vm zone?
  if (zone() != nullptr) {
    return true;
  }
  AssertEmptyStackInvariants();
  return false;
}

void Thread::EnterIsolate(Isolate* isolate) {
  const bool is_resumable = isolate->mutator_thread() != nullptr;

  // To let VM's thread pool (if we run on it) know that this thread is
  // occupying a mutator again (decreases its max size).
  const bool is_nested_reenter =
      (is_resumable && isolate->mutator_thread()->top_exit_frame_info() != 0);

  auto group = isolate->group();
  if (!(is_nested_reenter && isolate->mutator_thread()->OwnsSafepoint())) {
    group->IncreaseMutatorCount(nullptr, is_nested_reenter, false);
  }

  // Two threads cannot enter isolate at same time.
  ASSERT(isolate->scheduled_mutator_thread_ == nullptr);

  // We lazily create a [Thread] structure for the mutator thread, but we'll
  // reuse it until the death of the isolate.
  Thread* thread = nullptr;
  if (is_resumable) {
    thread = isolate->mutator_thread();
    ASSERT(thread->scheduled_dart_mutator_isolate_ == isolate);
    ASSERT(thread->isolate() == isolate);
    ASSERT(thread->isolate_group() == isolate->group());
  } else {
    thread = AddActiveThread(group, isolate, kMutatorTask,
                             /*bypass_safepoint=*/false);
    thread->SetupMutatorState();
    thread->SetupDartMutatorState(isolate);
  }

  isolate->scheduled_mutator_thread_ = thread;
  ResumeDartMutatorThreadInternal(thread);

  if (is_resumable) {
    // Descheduled isolates are reloadable (if nothing else prevents it).
    RawReloadParticipationScope enable_reload(thread);
    thread->ExitSafepoint();
  }

  if (thread->current_tag() == UserTag::null()) {
    // Set up current tag if it was not set up by the callback.
    StackZone zone(thread);
    HANDLESCOPE(thread);
    if (group->tag_table() != GrowableObjectArray::null()) {
      const UserTag& default_tag = UserTag::Handle(UserTag::DefaultTag(thread));
      thread->set_current_tag(default_tag);
    }
  }

  ASSERT(!thread->IsAtSafepoint());
}

static bool ShouldSuspend(bool isolate_shutdown, Thread* thread) {
  // Must destroy thread.
  if (isolate_shutdown) return false;

  // Must retain thread.
  if (thread->HasActiveState() || thread->OwnsSafepoint()) return true;

  // Could do either. When there are few isolates suspend to avoid work
  // entering and leaving. When there are many isolate, destroy the thread to
  // avoid the root set growing too big.
  const intptr_t kMaxSuspendedThreads = 20;
  auto group = thread->isolate_group();
  return group->thread_registry()->active_isolates_count() <
         kMaxSuspendedThreads;
}

void Thread::ExitIsolate(bool isolate_shutdown) {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  ASSERT(thread->IsDartMutatorThread());
  ASSERT(thread->isolate() != nullptr);
  ASSERT(thread->isolate_group() != nullptr);
  ASSERT(thread->isolate()->mutator_thread_ == thread);
  ASSERT(thread->isolate()->scheduled_mutator_thread_ == thread);
  DEBUG_ASSERT(!thread->IsAnyReusableHandleScopeActive());

  auto isolate = thread->isolate();
  auto group = thread->isolate_group();

  thread->set_vm_tag(isolate->is_runnable() ? VMTag::kIdleTagId
                                            : VMTag::kLoadWaitTagId);
  if (thread->sticky_error() != Error::null()) {
    ASSERT(isolate->sticky_error_ == Error::null());
    isolate->sticky_error_ = thread->StealStickyError();
  }

  isolate->scheduled_mutator_thread_ = nullptr;

  ASSERT(!ActiveMutatorStolenField::decode(thread->safepoint_state_.load()));

  // Right now we keep the [Thread] object across the isolate's lifetime. This
  // makes entering/exiting quite fast as it mainly boils down to safepoint
  // transitions. Though any operation that walks over all active threads will
  // see this thread as well (e.g. safepoint operations).
  const bool is_nested_exit = thread->top_exit_frame_info() != 0;
  if (ShouldSuspend(isolate_shutdown, thread)) {
    const auto tag =
        isolate->is_runnable() ? VMTag::kIdleTagId : VMTag::kLoadWaitTagId;
    SuspendDartMutatorThreadInternal(thread, tag);
    {
      // Descheduled isolates are reloadable (if nothing else prevents it).
      RawReloadParticipationScope enable_reload(thread);
      thread->EnterSafepoint();
    }
    thread->set_execution_state(Thread::kThreadInNative);
  } else {
    thread->ResetDartMutatorState();
    thread->ResetMutatorState();
    SuspendDartMutatorThreadInternal(thread, VMTag::kInvalidTagId);
    FreeActiveThread(thread, isolate, /*bypass_safepoint=*/false);
  }

  // To let VM's thread pool (if we run on it) know that this thread is
  // occupying a mutator again (decreases its max size).
  ASSERT(!(isolate_shutdown && is_nested_exit));
  if (!(is_nested_exit && thread->OwnsSafepoint())) {
    group->DecreaseMutatorCount(is_nested_exit);
  }
}

void Thread::EnterIsolateGroupAsHelper(IsolateGroup* isolate_group,
                                       TaskKind kind,
                                       bool bypass_safepoint) {
  Thread* thread = AddActiveThread(isolate_group, /*isolate=*/nullptr, kind,
                                   bypass_safepoint);
  RELEASE_ASSERT(thread != nullptr);
  // Even if [bypass_safepoint] is true, a thread may need mutator state (e.g.
  // parallel scavenger threads write to the [Thread]s storebuffer)
  thread->SetupMutatorState();
  ResumeThreadInternal(thread);

  thread->AssertNonDartMutatorInvariants();
}

void Thread::ExitIsolateGroupAsHelper(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  thread->AssertNonDartMutatorInvariants();

  // Even if [bypass_safepoint] is true, a thread may need mutator state (e.g.
  // parallel scavenger threads write to the [Thread]s storebuffer)
  thread->ResetMutatorState();
  SuspendThreadInternal(thread, VMTag::kInvalidTagId);
  FreeActiveThread(thread, /*isolate=*/nullptr, bypass_safepoint);
}

void Thread::EnterIsolateGroupAsMutator(IsolateGroup* isolate_group,
                                        bool bypass_safepoint) {
  isolate_group->IncreaseMutatorCount(/*thread=*/nullptr,
                                      /*is_nested_reenter=*/true,
                                      /*was_stolen=*/false);
  isolate_group->IncrementIsolateGroupMutatorCount();
  Thread* thread = AddActiveThread(isolate_group, /*isolate=*/nullptr,
                                   kMutatorTask, bypass_safepoint);

  RELEASE_ASSERT(thread != nullptr);
  // Even if [bypass_safepoint] is true, a thread may need mutator state (e.g.
  // parallel scavenger threads write to the [Thread]s storebuffer)
  thread->SetupMutatorState();
  // This forces slow-path for static field access, which allows to enforce
  // no-access to static fields from isolate group mutator thread.
  thread->field_table_values_ = isolate_group->sentinel_field_table()->table();
  thread->SetupDartMutatorStateDependingOnSnapshot(isolate_group);

  ResumeThreadInternal(thread);
#if defined(DART_INCLUDE_SIMULATOR)
  if (FLAG_use_simulator) {
    thread->SetStackLimit(Simulator::Current()->overflow_stack_limit());
  } else {
    thread->SetStackLimit(OSThread::Current()->overflow_stack_limit());
  }
#else
  thread->SetStackLimit(OSThread::Current()->overflow_stack_limit());
#endif

  thread->AssertDartMutatorInvariants();

  StackZone zone(thread);
  HANDLESCOPE(thread);
  if (isolate_group->tag_table() != GrowableObjectArray::null()) {
    // Set up default UserTag.
    const UserTag& default_tag = UserTag::Handle(UserTag::DefaultTag(thread));
    thread->set_current_tag(default_tag);
  }
}

void Thread::ExitIsolateGroupAsMutator(bool bypass_safepoint) {
  Thread* thread = Thread::Current();
  thread->AssertDartMutatorInvariants();

  // Even if [bypass_safepoint] is true, a thread may need mutator state (e.g.
  // parallel scavenger threads write to the [Thread]s storebuffer)
  thread->ResetDartMutatorState();
  thread->ResetMutatorState();
  thread->ClearStackLimit();
  SuspendThreadInternal(thread, VMTag::kInvalidTagId);
  auto group = thread->isolate_group();
  FreeActiveThread(thread, /*isolate=*/nullptr, bypass_safepoint);
  group->DecrementIsolateGroupMutatorCount();
  group->DecreaseMutatorCount(/*is_nested_exit=*/true);
}

void Thread::EnterIsolateGroupAsNonMutator(IsolateGroup* isolate_group,
                                           TaskKind kind) {
  Thread* thread = AddActiveThread(isolate_group, /*isolate=*/nullptr, kind,
                                   /*bypass_safepoint=*/true);
  RELEASE_ASSERT(thread != nullptr);
  ResumeThreadInternal(thread);

  thread->AssertNonMutatorInvariants();
}

void Thread::ExitIsolateGroupAsNonMutator() {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  thread->AssertNonMutatorInvariants();

  SuspendThreadInternal(thread, VMTag::kInvalidTagId);
  FreeActiveThread(thread, /*isolate=*/nullptr, /*bypass_safepoint=*/true);
}

void Thread::ResumeDartMutatorThreadInternal(Thread* thread) {
  ResumeThreadInternal(thread);
  if (Dart::vm_isolate() != nullptr &&
      thread->isolate() != Dart::vm_isolate()) {
#if defined(DART_INCLUDE_SIMULATOR)
    if (FLAG_use_simulator) {
      thread->SetStackLimit(Simulator::Current()->overflow_stack_limit());
    } else {
      thread->SetStackLimit(OSThread::Current()->overflow_stack_limit());
    }
#else
    thread->SetStackLimit(OSThread::Current()->overflow_stack_limit());
#endif
  }
}

void Thread::SuspendDartMutatorThreadInternal(Thread* thread,
                                              VMTag::VMTagId tag) {
  thread->ClearStackLimit();
  SuspendThreadInternal(thread, tag);
}

void Thread::ResumeThreadInternal(Thread* thread) {
  ASSERT(thread->isolate_group() != nullptr);
  ASSERT(thread->execution_state() == Thread::kThreadInNative);
  ASSERT(thread->vm_tag() == VMTag::kInvalidTagId ||
         thread->vm_tag() == VMTag::kIdleTagId ||
         thread->vm_tag() == VMTag::kLoadWaitTagId);

  thread->set_vm_tag(VMTag::kVMTagId);
  thread->set_execution_state(Thread::kThreadInVM);

  OSThread* os_thread = OSThread::Current();
  thread->set_os_thread(os_thread);
  os_thread->set_thread(thread);
  Thread::SetCurrent(thread);
  NOT_IN_PRODUCT(os_thread->EnableThreadInterrupts());

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  thread->heap_sampler().Initialize();
#endif
}

void Thread::SuspendThreadInternal(Thread* thread, VMTag::VMTagId tag) {
  thread->heap()->new_space()->AbandonRemainingTLAB(thread);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  thread->heap_sampler().Cleanup();
#endif

  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != nullptr);
  NOT_IN_PRODUCT(os_thread->DisableThreadInterrupts());
  os_thread->set_thread(nullptr);
  OSThread::SetCurrent(os_thread);
  thread->set_os_thread(nullptr);

  thread->set_vm_tag(tag);
}

Thread* Thread::AddActiveThread(IsolateGroup* group,
                                Isolate* isolate,
                                TaskKind task_kind,
                                bool bypass_safepoint) {
  // NOTE: We cannot just use `Dart::vm_isolate() == this` here, since during
  // VM startup it might not have been set at this point.
  const bool is_vm_isolate =
      Dart::vm_isolate() == nullptr || Dart::vm_isolate() == isolate;

  auto thread_registry = group->thread_registry();
  auto safepoint_handler = group->safepoint_handler();
  MonitorLocker ml(thread_registry->threads_lock());

  if (!bypass_safepoint) {
    while (safepoint_handler->AnySafepointInProgressLocked()) {
      ml.Wait();
    }
  }

  Thread* thread = thread_registry->GetFreeThreadLocked(is_vm_isolate);
  thread->AssertEmptyThreadInvariants();
  thread->SetupStateLocked(task_kind);

  thread->isolate_ = isolate;  // May be nullptr.
  thread->isolate_group_ = group;
  thread->scheduled_dart_mutator_isolate_ = isolate;
  if (task_kind == kMutatorTask) {
    if (isolate != nullptr) {
      isolate->mutator_thread_ = thread;
    } else {
      group->RegisterIsolateGroupMutator(thread);
    }
  }

  // We start at being at-safepoint (in case any safepoint operation is
  // in-progress, we'll check into it once leaving the safepoint)
  thread->set_safepoint_state(Thread::SetBypassSafepoints(bypass_safepoint, 0));
  thread->runtime_call_deopt_ability_ = RuntimeCallDeoptAbility::kCanLazyDeopt;
  ASSERT(!thread->IsAtSafepoint());

  ASSERT(thread->saved_stack_limit_ == OSThread::kInvalidStackLimit);
  return thread;
}

void Thread::FreeActiveThread(Thread* thread,
                              Isolate* isolate,
                              bool bypass_safepoint) {
  ASSERT(!thread->HasActiveState());
  ASSERT(!thread->IsAtSafepoint());

  if (!bypass_safepoint) {
    // GC helper threads don't have any handle state to clear, and the GC might
    // be currently visiting thread state. If this is not a GC helper, the GC
    // can't be visiting thread state because its waiting for this thread to
    // check in.
    thread->ClearReusableHandles();
  }

  auto group = thread->isolate_group_;
  auto thread_registry = group->thread_registry();

  MonitorLocker ml(thread_registry->threads_lock());

  if (!bypass_safepoint) {
    // There may be a pending safepoint operation on another thread that is
    // waiting for us to check-in.
    //
    // Though notice we're holding the thread registrys' threads_lock, which
    // means if this other thread runs code as part of a safepoint operation it
    // will still wait for us to finish here before it tries to iterate the
    // active mutators (e.g. when GC starts/stops incremental marking).
    //
    // The thread is empty and the corresponding isolate (if any) is therefore
    // at event-loop boundary (or shutting down). We participate in reload in
    // those scenarios.
    //
    // (It may be that an active [RELOAD_OPERATION_SCOPE] sent an OOB message to
    // this isolate but it didn't handle the OOB due to shutting down, so we'll
    // still have to update the reloading thread that it's ok to continue)
    RawReloadParticipationScope enable_reload(thread);
    thread->EnterSafepoint();
  }

  thread->isolate_ = nullptr;
  thread->isolate_group_ = nullptr;
  thread->scheduled_dart_mutator_isolate_ = nullptr;
  if (thread->task_kind() == kMutatorTask) {
    if (isolate != nullptr) {
      isolate->mutator_thread_ = nullptr;
    } else {
      group->UnregisterIsolateGroupMutator(thread);
    }
  }
  thread->set_execution_state(Thread::kThreadInNative);
  thread->stack_limit_.store(0);
  thread->safepoint_state_ = 0;
  thread->ResetStateLocked();
  thread->current_tag_ = UserTag::null();
  thread->default_tag_ = UserTag::null();

  thread->AssertEmptyThreadInvariants();
  thread_registry->ReturnThreadLocked(thread);
}

void Thread::ReleaseStoreBuffer() {
  ASSERT(IsAtSafepoint() || OwnsSafepoint() || task_kind_ == kMarkerTask);
  if (store_buffer_block_ == nullptr || store_buffer_block_->IsEmpty()) {
    return;  // Nothing to release.
  }
  // Prevent scheduling another GC by ignoring the threshold.
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
  SetStackLimit(OSThread::kInvalidStackLimit);
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
  return HandleInterrupts(GetAndClearInterrupts());
}

ErrorPtr Thread::HandleInterrupts(uword interrupt_bits) {
  if ((interrupt_bits & kVMInterrupt) != 0) {
    CheckForSafepoint();
    if (isolate_group()->store_buffer()->Overflowed()) {
      // Evacuate: If the popular store buffer targets are copied instead of
      // promoted, the store buffer won't shrink and a second scavenge will
      // occur that does promote them.
      heap()->CollectGarbage(this, GCType::kEvacuate, GCReason::kStoreBuffer);
    }
    heap()->CheckFinalizeMarking(this);

#if !defined(PRODUCT)
    // TODO(dartbug.com/60508): Allow profiling of isolate-group-shared code.
    if (isolate() != nullptr && isolate()->TakeHasCompletedBlocks()) {
      Profiler::ProcessCompletedBlocks(isolate());
    }
#endif  // !defined(PRODUCT)

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
    HeapProfileSampler& sampler = heap_sampler();
    if (sampler.ShouldSetThreadSamplingInterval()) {
      sampler.SetThreadSamplingInterval();
    }
    if (sampler.ShouldUpdateThreadEnable()) {
      sampler.UpdateThreadEnable();
    }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
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
  store_buffer_block_ = nullptr;
  isolate_group()->store_buffer()->PushBlock(block, policy);
}

void Thread::StoreBufferAcquire() {
  store_buffer_block_ = isolate_group()->store_buffer()->PopNonFullBlock();
}

void Thread::StoreBufferReleaseGC() {
  StoreBufferBlock* block = store_buffer_block_;
  store_buffer_block_ = nullptr;
  isolate_group()->store_buffer()->PushBlock(block,
                                             StoreBuffer::kIgnoreThreshold);
}

void Thread::StoreBufferAcquireGC() {
  store_buffer_block_ = isolate_group()->store_buffer()->PopNonFullBlock();
}

void Thread::OldMarkingStackBlockProcess() {
  OldMarkingStackRelease();
  OldMarkingStackAcquire();
}

void Thread::NewMarkingStackBlockProcess() {
  NewMarkingStackRelease();
  NewMarkingStackAcquire();
}

void Thread::DeferredMarkingStackBlockProcess() {
  DeferredMarkingStackRelease();
  DeferredMarkingStackAcquire();
}

void Thread::MarkingStackAddObject(ObjectPtr obj) {
  if (obj->IsNewObject()) {
    NewMarkingStackAddObject(obj);
  } else {
    OldMarkingStackAddObject(obj);
  }
}

void Thread::OldMarkingStackAddObject(ObjectPtr obj) {
  ASSERT(obj->IsOldObject());
  old_marking_stack_block_->Push(obj);
  if (old_marking_stack_block_->IsFull()) {
    OldMarkingStackBlockProcess();
  }
}

void Thread::NewMarkingStackAddObject(ObjectPtr obj) {
  ASSERT(obj->IsNewObject());
  new_marking_stack_block_->Push(obj);
  if (new_marking_stack_block_->IsFull()) {
    NewMarkingStackBlockProcess();
  }
}

void Thread::DeferredMarkingStackAddObject(ObjectPtr obj) {
  deferred_marking_stack_block_->Push(obj);
  if (deferred_marking_stack_block_->IsFull()) {
    DeferredMarkingStackBlockProcess();
  }
}

void Thread::OldMarkingStackRelease() {
  MarkingStackBlock* old_block = old_marking_stack_block_;
  old_marking_stack_block_ = nullptr;
  isolate_group()->old_marking_stack()->PushBlock(old_block);

  write_barrier_mask_ = UntaggedObject::kGenerationalBarrierMask;
}

void Thread::NewMarkingStackRelease() {
  MarkingStackBlock* new_block = new_marking_stack_block_;
  new_marking_stack_block_ = nullptr;
  isolate_group()->new_marking_stack()->PushBlock(new_block);
}

void Thread::OldMarkingStackAcquire() {
  old_marking_stack_block_ =
      isolate_group()->old_marking_stack()->PopEmptyBlock();

  write_barrier_mask_ = UntaggedObject::kGenerationalBarrierMask |
                        UntaggedObject::kIncrementalBarrierMask;
}

void Thread::NewMarkingStackAcquire() {
  new_marking_stack_block_ =
      isolate_group()->new_marking_stack()->PopEmptyBlock();
}

void Thread::DeferredMarkingStackRelease() {
  MarkingStackBlock* block = deferred_marking_stack_block_;
  deferred_marking_stack_block_ = nullptr;
  isolate_group()->deferred_marking_stack()->PushBlock(block);
}

void Thread::DeferredMarkingStackAcquire() {
  deferred_marking_stack_block_ =
      isolate_group()->deferred_marking_stack()->PopEmptyBlock();
}

void Thread::AcquireMarkingStacks() {
  OldMarkingStackAcquire();
  NewMarkingStackAcquire();
  DeferredMarkingStackAcquire();
}

void Thread::ReleaseMarkingStacks() {
  OldMarkingStackRelease();
  NewMarkingStackRelease();
  DeferredMarkingStackRelease();
}

void Thread::FlushMarkingStacks() {
  isolate_group()->old_marking_stack()->PushBlock(old_marking_stack_block_);
  old_marking_stack_block_ =
      isolate_group()->old_marking_stack()->PopEmptyBlock();

  isolate_group()->new_marking_stack()->PushBlock(new_marking_stack_block_);
  new_marking_stack_block_ =
      isolate_group()->new_marking_stack()->PopEmptyBlock();

  isolate_group()->deferred_marking_stack()->PushBlock(
      deferred_marking_stack_block_);
  deferred_marking_stack_block_ =
      isolate_group()->deferred_marking_stack()->PopEmptyBlock();
}

Heap* Thread::heap() const {
  return isolate_group_->heap();
}

bool Thread::IsExecutingDartCode() const {
  return (top_exit_frame_info() == 0) && VMTag::IsDartTag(vm_tag());
}

bool Thread::IsExecutingDartCodeIgnoreRace() const {
  return (top_exit_frame_info_ignore_race() == 0) &&
         VMTag::IsDartTag(vm_tag_ignore_race());
}

bool Thread::HasExitedDartCode() const {
  return (top_exit_frame_info() != 0) && !VMTag::IsDartTag(vm_tag());
}

bool Thread::HasExitedDartCodeIgnoreRace() const {
  return (top_exit_frame_info_ignore_race() != 0) &&
         !VMTag::IsDartTag(vm_tag_ignore_race());
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
  ASSERT(visitor != nullptr);

  if (zone() != nullptr) {
    zone()->VisitObjectPointers(visitor);
  }

  // Visit objects in thread specific handles area.
  reusable_handles_.VisitObjectPointers(visitor);

  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&global_object_pool_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&active_exception_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&active_stacktrace_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&sticky_error_));

#if defined(DART_DYNAMIC_MODULES)
  if (interpreter() != nullptr) {
    interpreter()->VisitObjectPointers(visitor);
  }
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Visit objects that are being used for deoptimization.
  if (deopt_context() != nullptr) {
    deopt_context()->VisitObjectPointers(visitor);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Visit the api local scope as it has all the api local handles.
  ApiLocalScope* scope = api_top_scope_;
  while (scope != nullptr) {
    scope->local_handles()->VisitObjectPointers(visitor);
    scope = scope->previous();
  }

  // Only the mutator thread can run Dart code.
  if (HasDartMutatorStack()) {
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
    visitor->set_gc_root_type("frame");
    while (frame != nullptr) {
      frame->VisitObjectPointers(visitor);
      frame = frames_iterator.NextFrame();
    }
    visitor->clear_gc_root_type();
  } else {
    // We are not on the mutator thread.
    RELEASE_ASSERT(top_exit_frame_info() == 0);
  }

  if (pointers_to_verify_at_exit_.length() != 0) {
    visitor->VisitPointers(&pointers_to_verify_at_exit_[0],
                           pointers_to_verify_at_exit_.length());
  }

  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&current_tag_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&default_tag_));
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

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (; first != last + 1; first++) {
      ObjectPtr obj = *first;
      if (obj->IsImmediateObject()) continue;

      // To avoid adding too much work into the remembered set, skip large
      // arrays. Write barrier elimination will not remove the barrier
      // if we can trigger GC between array allocation and store.
      if (obj->GetClassIdOfHeapObject() == kArrayCid) {
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
          if (obj->IsOldObject()) {
            obj->untag()->EnsureInRememberedSet(current_);
          }
          if (current_->is_marking()) {
            current_->DeferredMarkingStackAddObject(obj);
          }
          break;
        case Thread::RestoreWriteBarrierInvariantOp::kAddToDeferredMarkingStack:
          // Re-scan obj when finalizing marking.
          ASSERT(current_->is_marking());
          current_->DeferredMarkingStackAddObject(obj);
          break;
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    UNREACHABLE();  // Stack slots are not compressed.
  }
#endif

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
// Dart frames preceding an exit frame to the store buffer or deferred
// marking stack.
void Thread::RestoreWriteBarrierInvariant(RestoreWriteBarrierInvariantOp op) {
  ASSERT(IsAtSafepoint() || OwnsGCSafepoint() || this == Thread::Current());

  const StackFrameIterator::CrossThreadPolicy cross_thread_policy =
      StackFrameIterator::kAllowCrossThreadIteration;
  StackFrameIterator frames_iterator(top_exit_frame_info(),
                                     ValidationPolicy::kDontValidateFrames,
                                     this, cross_thread_policy);
  RestoreWriteBarrierInvariantVisitor visitor(isolate_group(), this, op);
  ObjectStore* object_store = isolate_group()->object_store();
  bool scan_next_dart_frame = false;
  for (StackFrame* frame = frames_iterator.NextFrame(); frame != nullptr;
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
  if (runtime_entry == &k##name##RuntimeEntry) {                               \
    return Thread::name##_entry_point_offset();                                \
  }
  RUNTIME_ENTRY_LIST(COMPUTE_OFFSET)
#undef COMPUTE_OFFSET

#define COMPUTE_OFFSET(returntype, name, ...)                                  \
  if (runtime_entry == &k##name##RuntimeEntry) {                               \
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
#if defined(DART_INCLUDE_SIMULATOR) || defined(USING_SAFE_STACK)
  // False positives: simulator stack and native stack are unordered.
  return true;
#else
#if defined(DART_DYNAMIC_MODULES)
  // False positives: interpreter stack and native stack are unordered.
  if ((interpreter_ != nullptr) && interpreter_->HasFrame(top_exit_frame_info_))
    return true;
#endif
  return reinterpret_cast<uword>(long_jump_base()) < top_exit_frame_info_;
#endif
}

bool Thread::TopErrorHandlerIsExitFrame() const {
  if (top_exit_frame_info_ == 0) return false;
  if (long_jump_base() == nullptr) return true;
#if defined(DART_INCLUDE_SIMULATOR) || defined(USING_SAFE_STACK)
  // False positives: simulator stack and native stack are unordered.
  return true;
#else
#if defined(DART_DYNAMIC_MODULES)
  // False positives: interpreter stack and native stack are unordered.
  if ((interpreter_ != nullptr) && interpreter_->HasFrame(top_exit_frame_info_))
    return true;
#endif
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
  while (scope != nullptr) {
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
  while (scope != nullptr) {
    total += scope->local_handles()->CountHandles();
    scope = scope->previous();
  }
  return total;
}

int Thread::ZoneSizeInBytes() const {
  int total = 0;
  ApiLocalScope* scope = api_top_scope_;
  while (scope != nullptr) {
    total += scope->zone()->SizeInBytes();
    scope = scope->previous();
  }
  return total;
}

void Thread::EnterApiScope() {
  ASSERT(MayAllocateHandles());
  ApiLocalScope* new_scope = api_reusable_scope();
  if (new_scope == nullptr) {
    new_scope = new ApiLocalScope(api_top_scope(), top_exit_frame_info());
    ASSERT(new_scope != nullptr);
  } else {
    new_scope->Reinit(this, api_top_scope(), top_exit_frame_info());
    set_api_reusable_scope(nullptr);
  }
  set_api_top_scope(new_scope);  // New scope is now the top scope.
}

void Thread::ExitApiScope() {
  ASSERT(MayAllocateHandles());
  ApiLocalScope* scope = api_top_scope();
  ApiLocalScope* reusable_scope = api_reusable_scope();
  set_api_top_scope(scope->previous());  // Reset top scope to previous.
  if (reusable_scope == nullptr) {
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
  while (scope != nullptr && scope->stack_marker() != 0 &&
         scope->stack_marker() == stack_marker) {
    api_top_scope_ = scope->previous();
    delete scope;
    scope = api_top_scope_;
  }
}

void Thread::HandleStolen() {
  {
    // To make sure we're sequenced after MarkWorkerAsBlocked.
    MonitorLocker ml(isolate_group()->thread_registry()->threads_lock());
  }
  isolate_group()->IncreaseMutatorCount(this, /*is_nested_reenter=*/false,
                                        /*was_stolen=*/true);
}

#ifndef PRODUCT
namespace {

// This visitor simply dereferences every non-Smi |ObjectPtr| it visits and
// checks that its class id is valid.
//
// It is used for fast validation of pointers on the stack: if a pointer is
// invalid it is likely to either cause a crash when dereferenced or have
// a garbage class id.
class FastPointerValidator : public ObjectPointerVisitor {
 public:
  explicit FastPointerValidator(IsolateGroup* isolate_group)
      : ObjectPointerVisitor(isolate_group) {}

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      const auto cid = (*ptr)->GetClassId();
      RELEASE_ASSERT(class_table()->IsValidIndex(cid));
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    // We are not expecting compressed pointers on the stack.
    UNREACHABLE();
  }
#endif

 private:
  DISALLOW_COPY_AND_ASSIGN(FastPointerValidator);
};

}  // namespace

void Thread::ValidateExitFrameState() {
  if (top_exit_frame_info() == 0) {
    return;
  }

  FastPointerValidator fast_pointers_validator(isolate_group());

  StackFrameIterator frames_iterator(
      top_exit_frame_info(), ValidationPolicy::kValidateFrames, this,
      StackFrameIterator::kNoCrossThreadIteration);

  StackFrame* frame = frames_iterator.NextFrame();
  while (frame != nullptr) {
    frame->VisitObjectPointers(&fast_pointers_validator);
    frame = frames_iterator.NextFrame();
  }
}
#endif

void Thread::EnterSafepointUsingLock() {
  isolate_group()->safepoint_handler()->EnterSafepointUsingLock(this);
}

void Thread::ExitSafepointUsingLock() {
  isolate_group()->safepoint_handler()->ExitSafepointUsingLock(this);
}

void Thread::BlockForSafepoint() {
  isolate_group()->safepoint_handler()->BlockForSafepoint(this);
}

bool Thread::OwnsGCSafepoint() const {
  return isolate_group()->safepoint_handler()->InnermostSafepointOperation(
             this) <= SafepointLevel::kGCAndDeopt;
}

bool Thread::OwnsDeoptSafepoint() const {
  return isolate_group()->safepoint_handler()->InnermostSafepointOperation(
             this) == SafepointLevel::kGCAndDeopt;
}

bool Thread::OwnsReloadSafepoint() const {
  return isolate_group()->safepoint_handler()->InnermostSafepointOperation(
             this) <= SafepointLevel::kGCAndDeoptAndReload;
}

bool Thread::OwnsSafepoint() const {
  return isolate_group()->safepoint_handler()->InnermostSafepointOperation(
             this) != SafepointLevel::kNoSafepoint;
}

bool Thread::CanAcquireSafepointLocks() const {
  // A thread may acquire locks and then enter a safepoint operation (e.g.
  // holding program lock, allocating objects which triggers GC).
  //
  // So if this code is called inside safepoint operation, we generally have to
  // assume other threads may hold locks and are blocked on the safepoint,
  // meaning we cannot hold safepoint and acquire locks (deadlock!).
  //
  // Though if we own a reload safepoint operation it means all other mutators
  // are blocked in very specific places, where we know no locks are held. As
  // such we allow the current thread to acquire locks.
  //
  // Example: We own reload safepoint operation, load kernel, which allocates
  // symbols, where the symbol implementation acquires the symbol lock (we know
  // other mutators at reload safepoint do not hold symbol lock).
  if (current_safepoint_level() == SafepointLevel::kGCAndDeoptAndReload) {
    return false;
  }
  return isolate_group()->safepoint_handler()->InnermostSafepointOperation(
             this) >= SafepointLevel::kGCAndDeoptAndReload;
}

void Thread::SetupStateLocked(TaskKind kind) {
  task_kind_ = kind;
}

void Thread::ResetStateLocked() {
  task_kind_ = kUnknownTask;
  vm_tag_ = VMTag::kInvalidTagId;
}

void Thread::SetupMutatorState() {
  ASSERT(store_buffer_block_ == nullptr);

  if (isolate_group()->old_marking_stack() != nullptr) {
    ASSERT(isolate_group()->new_marking_stack() != nullptr);
    ASSERT(isolate_group()->deferred_marking_stack() != nullptr);
    // Concurrent mark in progress. Enable barrier for this thread.
    OldMarkingStackAcquire();
    NewMarkingStackAcquire();
    DeferredMarkingStackAcquire();
  }

  if (task_kind_ == kMutatorTask) {
    StoreBufferAcquire();
  } else {
    store_buffer_block_ = isolate_group()->store_buffer()->PopEmptyBlock();
  }
}

void Thread::ResetMutatorState() {
  ASSERT(execution_state() == Thread::kThreadInVM);
  ASSERT(store_buffer_block_ != nullptr);

  if (is_marking()) {
    OldMarkingStackRelease();
    NewMarkingStackRelease();
    DeferredMarkingStackRelease();
  }
  StoreBufferRelease();
}

void Thread::SetupDartMutatorState(Isolate* isolate) {
  field_table_values_ = isolate->field_table_->table();

  SetupDartMutatorStateDependingOnSnapshot(isolate->group());
}

void Thread::SetupDartMutatorStateDependingOnSnapshot(IsolateGroup* group) {
  // The snapshot may or may not have been read at this point (on isolate group
  // creation, the first isolate is first time entered before the snapshot is
  // read)
  //
  // So we call this code explicitly after snapshot reading time and whenever we
  // enter an isolate with a new thread object.
#if defined(DART_PRECOMPILED_RUNTIME)
  auto object_store = group->object_store();
  if (object_store != nullptr) {
    global_object_pool_ = object_store->global_object_pool();

    auto dispatch_table = group->dispatch_table();
    if (dispatch_table != nullptr) {
      dispatch_table_array_ = dispatch_table->ArrayOrigin();
    }
#define INIT_ENTRY_POINT(name)                                                 \
  if (object_store->name() != Object::null()) {                                \
    name##_entry_point_ = Function::EntryPointOf(object_store->name());        \
  }
    CACHED_FUNCTION_ENTRY_POINTS_LIST(INIT_ENTRY_POINT)
#undef INIT_ENTRY_POINT
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  shared_field_table_values_ = group->shared_field_table()->table();
}

void Thread::ResetDartMutatorState() {
  ASSERT(execution_state() == Thread::kThreadInVM);

  is_unwind_in_progress_ = false;

  field_table_values_ = nullptr;
  shared_field_table_values_ = nullptr;
  ONLY_IN_PRECOMPILED(global_object_pool_ = ObjectPool::null());
  ONLY_IN_PRECOMPILED(dispatch_table_array_ = nullptr);
}

void Thread::set_forward_table_new(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_new_ = std::move(value);
}
void Thread::set_forward_table_old(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_old_ = std::move(value);
}

void Thread::VisitMutators(MutatorThreadVisitor* visitor) {
  if (visitor == nullptr) {
    return;
  }
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->thread_registry()->ForEachThread(
        [&](Thread* thread) { visitor->VisitMutatorThread(thread); });
  });
}

#if !defined(PRODUCT)
DisableThreadInterruptsScope::DisableThreadInterruptsScope(Thread* thread)
    : StackResource(thread) {
  if (thread != nullptr) {
    OSThread* os_thread = thread->os_thread();
    ASSERT(os_thread != nullptr);
    os_thread->DisableThreadInterrupts();
  }
}

DisableThreadInterruptsScope::~DisableThreadInterruptsScope() {
  if (thread() != nullptr) {
    OSThread* os_thread = thread()->os_thread();
    ASSERT(os_thread != nullptr);
    os_thread->EnableThreadInterrupts();
  }
}
#endif

NoReloadScope::NoReloadScope(Thread* thread) : ThreadStackResource(thread) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (thread->no_reload_scope_depth_ == 0) {
    thread->SetNoReloadScope(true);
  }
  thread->no_reload_scope_depth_++;
  ASSERT(thread->no_reload_scope_depth_ >= 0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

NoReloadScope::~NoReloadScope() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  thread()->no_reload_scope_depth_ -= 1;
  ASSERT(thread()->no_reload_scope_depth_ >= 0);
  auto isolate = thread()->isolate();
  const intptr_t state = thread()->safepoint_state();

  if (thread()->no_reload_scope_depth_ == 0) {
    thread()->SetNoReloadScope(false);

    // If we were asked to go to a reload safepoint & block for a reload
    // safepoint operation on another thread - *while* being inside
    // [NoReloadScope] - we may have handled & ignored the OOB message telling
    // us to reload.
    //
    // Since we're exiting now the [NoReloadScope], we'll make another OOB
    // reload request message to ourselves, which will be handled in
    // well-defined place where we can perform reload.
    if (isolate != nullptr &&
        Thread::IsSafepointLevelRequested(
            state, SafepointLevel::kGCAndDeoptAndReload)) {
      isolate->SendInternalLibMessage(Isolate::kCheckForReload,
                                      /*capability=*/-1);
    }
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
