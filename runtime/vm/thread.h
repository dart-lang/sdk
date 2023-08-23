// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_H_
#define RUNTIME_VM_THREAD_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include <setjmp.h>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/safe_stack.h"
#include "vm/bitfield.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/heap/pointer_block.h"
#include "vm/heap/sampler.h"
#include "vm/os_thread.h"
#include "vm/pending_deopts.h"
#include "vm/random.h"
#include "vm/runtime_entry_list.h"
#include "vm/tags.h"
#include "vm/thread_stack_resource.h"
#include "vm/thread_state.h"

namespace dart {

class AbstractType;
class ApiLocalScope;
class Array;
class CompilerState;
class CompilerTimings;
class Class;
class Code;
class Error;
class ExceptionHandlers;
class Field;
class FieldTable;
class Function;
class GrowableObjectArray;
class HandleScope;
class Heap;
class HierarchyInfo;
class Instance;
class Isolate;
class IsolateGroup;
class Library;
class Object;
class OSThread;
class JSONObject;
class NoActiveIsolateScope;
class PcDescriptors;
class RuntimeEntry;
class Smi;
class StackResource;
class StackTrace;
class StreamInfo;
class String;
class TimelineStream;
class TypeArguments;
class TypeParameter;
class TypeUsageInfo;
class Zone;

namespace compiler {
namespace target {
class Thread;
}  // namespace target
}  // namespace compiler

#define REUSABLE_HANDLE_LIST(V)                                                \
  V(AbstractType)                                                              \
  V(Array)                                                                     \
  V(Class)                                                                     \
  V(Code)                                                                      \
  V(Error)                                                                     \
  V(ExceptionHandlers)                                                         \
  V(Field)                                                                     \
  V(Function)                                                                  \
  V(GrowableObjectArray)                                                       \
  V(Instance)                                                                  \
  V(Library)                                                                   \
  V(LoadingUnit)                                                               \
  V(Object)                                                                    \
  V(PcDescriptors)                                                             \
  V(Smi)                                                                       \
  V(String)                                                                    \
  V(TypeParameters)                                                            \
  V(TypeArguments)                                                             \
  V(TypeParameter)                                                             \
  V(WeakArray)

#define CACHED_VM_STUBS_LIST(V)                                                \
  V(CodePtr, fix_callers_target_code_, StubCode::FixCallersTarget().ptr(),     \
    nullptr)                                                                   \
  V(CodePtr, fix_allocation_stub_code_,                                        \
    StubCode::FixAllocationStubTarget().ptr(), nullptr)                        \
  V(CodePtr, invoke_dart_code_stub_, StubCode::InvokeDartCode().ptr(),         \
    nullptr)                                                                   \
  V(CodePtr, call_to_runtime_stub_, StubCode::CallToRuntime().ptr(), nullptr)  \
  V(CodePtr, late_initialization_error_shared_without_fpu_regs_stub_,          \
    StubCode::LateInitializationErrorSharedWithoutFPURegs().ptr(), nullptr)    \
  V(CodePtr, late_initialization_error_shared_with_fpu_regs_stub_,             \
    StubCode::LateInitializationErrorSharedWithFPURegs().ptr(), nullptr)       \
  V(CodePtr, null_error_shared_without_fpu_regs_stub_,                         \
    StubCode::NullErrorSharedWithoutFPURegs().ptr(), nullptr)                  \
  V(CodePtr, null_error_shared_with_fpu_regs_stub_,                            \
    StubCode::NullErrorSharedWithFPURegs().ptr(), nullptr)                     \
  V(CodePtr, null_arg_error_shared_without_fpu_regs_stub_,                     \
    StubCode::NullArgErrorSharedWithoutFPURegs().ptr(), nullptr)               \
  V(CodePtr, null_arg_error_shared_with_fpu_regs_stub_,                        \
    StubCode::NullArgErrorSharedWithFPURegs().ptr(), nullptr)                  \
  V(CodePtr, null_cast_error_shared_without_fpu_regs_stub_,                    \
    StubCode::NullCastErrorSharedWithoutFPURegs().ptr(), nullptr)              \
  V(CodePtr, null_cast_error_shared_with_fpu_regs_stub_,                       \
    StubCode::NullCastErrorSharedWithFPURegs().ptr(), nullptr)                 \
  V(CodePtr, range_error_shared_without_fpu_regs_stub_,                        \
    StubCode::RangeErrorSharedWithoutFPURegs().ptr(), nullptr)                 \
  V(CodePtr, range_error_shared_with_fpu_regs_stub_,                           \
    StubCode::RangeErrorSharedWithFPURegs().ptr(), nullptr)                    \
  V(CodePtr, write_error_shared_without_fpu_regs_stub_,                        \
    StubCode::WriteErrorSharedWithoutFPURegs().ptr(), nullptr)                 \
  V(CodePtr, write_error_shared_with_fpu_regs_stub_,                           \
    StubCode::WriteErrorSharedWithFPURegs().ptr(), nullptr)                    \
  V(CodePtr, allocate_mint_with_fpu_regs_stub_,                                \
    StubCode::AllocateMintSharedWithFPURegs().ptr(), nullptr)                  \
  V(CodePtr, allocate_mint_without_fpu_regs_stub_,                             \
    StubCode::AllocateMintSharedWithoutFPURegs().ptr(), nullptr)               \
  V(CodePtr, allocate_object_stub_, StubCode::AllocateObject().ptr(), nullptr) \
  V(CodePtr, allocate_object_parameterized_stub_,                              \
    StubCode::AllocateObjectParameterized().ptr(), nullptr)                    \
  V(CodePtr, allocate_object_slow_stub_, StubCode::AllocateObjectSlow().ptr(), \
    nullptr)                                                                   \
  V(CodePtr, async_exception_handler_stub_,                                    \
    StubCode::AsyncExceptionHandler().ptr(), nullptr)                          \
  V(CodePtr, resume_stub_, StubCode::Resume().ptr(), nullptr)                  \
  V(CodePtr, return_async_stub_, StubCode::ReturnAsync().ptr(), nullptr)       \
  V(CodePtr, return_async_not_future_stub_,                                    \
    StubCode::ReturnAsyncNotFuture().ptr(), nullptr)                           \
  V(CodePtr, return_async_star_stub_, StubCode::ReturnAsyncStar().ptr(),       \
    nullptr)                                                                   \
  V(CodePtr, stack_overflow_shared_without_fpu_regs_stub_,                     \
    StubCode::StackOverflowSharedWithoutFPURegs().ptr(), nullptr)              \
  V(CodePtr, stack_overflow_shared_with_fpu_regs_stub_,                        \
    StubCode::StackOverflowSharedWithFPURegs().ptr(), nullptr)                 \
  V(CodePtr, switchable_call_miss_stub_, StubCode::SwitchableCallMiss().ptr(), \
    nullptr)                                                                   \
  V(CodePtr, throw_stub_, StubCode::Throw().ptr(), nullptr)                    \
  V(CodePtr, re_throw_stub_, StubCode::Throw().ptr(), nullptr)                 \
  V(CodePtr, assert_boolean_stub_, StubCode::AssertBoolean().ptr(), nullptr)   \
  V(CodePtr, optimize_stub_, StubCode::OptimizeFunction().ptr(), nullptr)      \
  V(CodePtr, deoptimize_stub_, StubCode::Deoptimize().ptr(), nullptr)          \
  V(CodePtr, lazy_deopt_from_return_stub_,                                     \
    StubCode::DeoptimizeLazyFromReturn().ptr(), nullptr)                       \
  V(CodePtr, lazy_deopt_from_throw_stub_,                                      \
    StubCode::DeoptimizeLazyFromThrow().ptr(), nullptr)                        \
  V(CodePtr, slow_type_test_stub_, StubCode::SlowTypeTest().ptr(), nullptr)    \
  V(CodePtr, lazy_specialize_type_test_stub_,                                  \
    StubCode::LazySpecializeTypeTest().ptr(), nullptr)                         \
  V(CodePtr, enter_safepoint_stub_, StubCode::EnterSafepoint().ptr(), nullptr) \
  V(CodePtr, exit_safepoint_stub_, StubCode::ExitSafepoint().ptr(), nullptr)   \
  V(CodePtr, exit_safepoint_ignore_unwind_in_progress_stub_,                   \
    StubCode::ExitSafepointIgnoreUnwindInProgress().ptr(), nullptr)            \
  V(CodePtr, call_native_through_safepoint_stub_,                              \
    StubCode::CallNativeThroughSafepoint().ptr(), nullptr)

#define CACHED_NON_VM_STUB_LIST(V)                                             \
  V(ObjectPtr, object_null_, Object::null(), nullptr)                          \
  V(BoolPtr, bool_true_, Object::bool_true().ptr(), nullptr)                   \
  V(BoolPtr, bool_false_, Object::bool_false().ptr(), nullptr)                 \
  V(ArrayPtr, empty_array_, Object::empty_array().ptr(), nullptr)              \
  V(TypePtr, dynamic_type_, Type::dynamic_type().ptr(), nullptr)

// List of VM-global objects/addresses cached in each Thread object.
// Important: constant false must immediately follow constant true.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  CACHED_NON_VM_STUB_LIST(V)                                                   \
  CACHED_VM_STUBS_LIST(V)

#define CACHED_FUNCTION_ENTRY_POINTS_LIST(V)                                   \
  V(suspend_state_init_async)                                                  \
  V(suspend_state_await)                                                       \
  V(suspend_state_await_with_type_check)                                       \
  V(suspend_state_return_async)                                                \
  V(suspend_state_return_async_not_future)                                     \
  V(suspend_state_init_async_star)                                             \
  V(suspend_state_yield_async_star)                                            \
  V(suspend_state_return_async_star)                                           \
  V(suspend_state_init_sync_star)                                              \
  V(suspend_state_suspend_sync_star_at_start)                                  \
  V(suspend_state_handle_exception)

// This assertion marks places which assume that boolean false immediate
// follows bool true in the CACHED_VM_OBJECTS_LIST
#define ASSERT_BOOL_FALSE_FOLLOWS_BOOL_TRUE()                                  \
  ASSERT((Thread::bool_true_offset() + kWordSize) ==                           \
         Thread::bool_false_offset());

#define CACHED_VM_STUBS_ADDRESSES_LIST(V)                                      \
  V(uword, write_barrier_entry_point_, StubCode::WriteBarrier().EntryPoint(),  \
    0)                                                                         \
  V(uword, array_write_barrier_entry_point_,                                   \
    StubCode::ArrayWriteBarrier().EntryPoint(), 0)                             \
  V(uword, call_to_runtime_entry_point_,                                       \
    StubCode::CallToRuntime().EntryPoint(), 0)                                 \
  V(uword, allocate_mint_with_fpu_regs_entry_point_,                           \
    StubCode::AllocateMintSharedWithFPURegs().EntryPoint(), 0)                 \
  V(uword, allocate_mint_without_fpu_regs_entry_point_,                        \
    StubCode::AllocateMintSharedWithoutFPURegs().EntryPoint(), 0)              \
  V(uword, allocate_object_entry_point_,                                       \
    StubCode::AllocateObject().EntryPoint(), 0)                                \
  V(uword, allocate_object_parameterized_entry_point_,                         \
    StubCode::AllocateObjectParameterized().EntryPoint(), 0)                   \
  V(uword, allocate_object_slow_entry_point_,                                  \
    StubCode::AllocateObjectSlow().EntryPoint(), 0)                            \
  V(uword, stack_overflow_shared_without_fpu_regs_entry_point_,                \
    StubCode::StackOverflowSharedWithoutFPURegs().EntryPoint(), 0)             \
  V(uword, stack_overflow_shared_with_fpu_regs_entry_point_,                   \
    StubCode::StackOverflowSharedWithFPURegs().EntryPoint(), 0)                \
  V(uword, megamorphic_call_checked_entry_,                                    \
    StubCode::MegamorphicCall().EntryPoint(), 0)                               \
  V(uword, switchable_call_miss_entry_,                                        \
    StubCode::SwitchableCallMiss().EntryPoint(), 0)                            \
  V(uword, optimize_entry_, StubCode::OptimizeFunction().EntryPoint(), 0)      \
  V(uword, deoptimize_entry_, StubCode::Deoptimize().EntryPoint(), 0)          \
  V(uword, call_native_through_safepoint_entry_point_,                         \
    StubCode::CallNativeThroughSafepoint().EntryPoint(), 0)                    \
  V(uword, jump_to_frame_entry_point_, StubCode::JumpToFrame().EntryPoint(),   \
    0)                                                                         \
  V(uword, slow_type_test_entry_point_, StubCode::SlowTypeTest().EntryPoint(), \
    0)

#define CACHED_ADDRESSES_LIST(V)                                               \
  CACHED_VM_STUBS_ADDRESSES_LIST(V)                                            \
  V(uword, bootstrap_native_wrapper_entry_point_,                              \
    NativeEntry::BootstrapNativeCallWrapperEntry(), 0)                         \
  V(uword, no_scope_native_wrapper_entry_point_,                               \
    NativeEntry::NoScopeNativeCallWrapperEntry(), 0)                           \
  V(uword, auto_scope_native_wrapper_entry_point_,                             \
    NativeEntry::AutoScopeNativeCallWrapperEntry(), 0)                         \
  V(StringPtr*, predefined_symbols_address_, Symbols::PredefinedAddress(),     \
    nullptr)                                                                   \
  V(uword, double_nan_address_, reinterpret_cast<uword>(&double_nan_constant), \
    0)                                                                         \
  V(uword, double_negate_address_,                                             \
    reinterpret_cast<uword>(&double_negate_constant), 0)                       \
  V(uword, double_abs_address_, reinterpret_cast<uword>(&double_abs_constant), \
    0)                                                                         \
  V(uword, float_not_address_, reinterpret_cast<uword>(&float_not_constant),   \
    0)                                                                         \
  V(uword, float_negate_address_,                                              \
    reinterpret_cast<uword>(&float_negate_constant), 0)                        \
  V(uword, float_absolute_address_,                                            \
    reinterpret_cast<uword>(&float_absolute_constant), 0)                      \
  V(uword, float_zerow_address_,                                               \
    reinterpret_cast<uword>(&float_zerow_constant), 0)

#define CACHED_CONSTANTS_LIST(V)                                               \
  CACHED_VM_OBJECTS_LIST(V)                                                    \
  CACHED_ADDRESSES_LIST(V)

enum class ValidationPolicy {
  kValidateFrames = 0,
  kDontValidateFrames = 1,
};

enum class RuntimeCallDeoptAbility {
  // There was no leaf call or a leaf call that can cause deoptimization
  // after-call.
  kCanLazyDeopt,
  // There was a leaf call and the VM cannot cause deoptimize after-call.
  kCannotLazyDeopt,
};

// The safepoint level a thread is on or a safepoint operation is requested for
//
// The higher the number the stronger the guarantees:
//   * the time-to-safepoint latency increases with level
//   * the frequency of hitting possible safe points decreases with level
enum SafepointLevel {
  // Safe to GC
  kGC,
  // Safe to GC as well as Deopt.
  kGCAndDeopt,
  // Safe to GC, Deopt as well as Reload.
  kGCAndDeoptAndReload,
  // Number of levels.
  kNumLevels,

  // No safepoint.
  kNoSafepoint,
};

// Accessed from generated code.
struct TsanUtils {
  // Used to allow unwinding runtime C frames using longjmp() when throwing
  // exceptions. This allows triggering the normal TSAN shadow stack unwinding
  // implementation.
  // -> See https://dartbug.com/47472#issuecomment-948235479 for details.
#if defined(USING_THREAD_SANITIZER)
  void* setjmp_function = reinterpret_cast<void*>(&setjmp);
#else
  // MSVC (on Windows) is not happy with getting address of purely intrinsic.
  void* setjmp_function = nullptr;
#endif
  jmp_buf* setjmp_buffer = nullptr;
  uword exception_pc = 0;
  uword exception_sp = 0;
  uword exception_fp = 0;

  static intptr_t setjmp_function_offset() {
    return OFFSET_OF(TsanUtils, setjmp_function);
  }
  static intptr_t setjmp_buffer_offset() {
    return OFFSET_OF(TsanUtils, setjmp_buffer);
  }
  static intptr_t exception_pc_offset() {
    return OFFSET_OF(TsanUtils, exception_pc);
  }
  static intptr_t exception_sp_offset() {
    return OFFSET_OF(TsanUtils, exception_sp);
  }
  static intptr_t exception_fp_offset() {
    return OFFSET_OF(TsanUtils, exception_fp);
  }
};

// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation. The Thread structure associated with
// a thread is allocated by EnsureInit before entering an isolate, and destroyed
// automatically when the underlying OS thread exits. NOTE: On Windows, CleanUp
// must currently be called manually (issue 23474).
class Thread : public ThreadState {
 public:
  // The kind of task this thread is performing. Sampled by the profiler.
  enum TaskKind {
    kUnknownTask = 0x0,
    kMutatorTask = 0x1,
    kCompilerTask = 0x2,
    kMarkerTask = 0x4,
    kSweeperTask = 0x8,
    kCompactorTask = 0x10,
    kScavengerTask = 0x20,
    kSampleBlockTask = 0x40,
  };
  // Converts a TaskKind to its corresponding C-String name.
  static const char* TaskKindToCString(TaskKind kind);

  ~Thread();

  // The currently executing thread, or nullptr if not yet initialized.
  static Thread* Current() {
    return static_cast<Thread*>(OSThread::CurrentVMThread());
  }

  // Whether there's any active state on the [thread] that needs to be preserved
  // across `Thread::ExitIsolate()` and `Thread::EnterIsolate()`.
  bool HasActiveState();
  void AssertNonMutatorInvariants();
  void AssertNonDartMutatorInvariants();
  void AssertEmptyStackInvariants();
  void AssertEmptyThreadInvariants();

  // Makes the current thread enter 'isolate'.
  static void EnterIsolate(Isolate* isolate);
  // Makes the current thread exit its isolate.
  static void ExitIsolate(bool isolate_shutdown = false);

  static bool EnterIsolateGroupAsHelper(IsolateGroup* isolate_group,
                                        TaskKind kind,
                                        bool bypass_safepoint);
  static void ExitIsolateGroupAsHelper(bool bypass_safepoint);

  static bool EnterIsolateGroupAsNonMutator(IsolateGroup* isolate_group,
                                            TaskKind kind);
  static void ExitIsolateGroupAsNonMutator();

  // Empties the store buffer block into the isolate.
  void ReleaseStoreBuffer();
  void AcquireMarkingStack();
  void ReleaseMarkingStack();

  void SetStackLimit(uword value);
  void ClearStackLimit();

  // Access to the current stack limit for generated code. Either the true OS
  // thread's stack limit minus some headroom, or a special value to trigger
  // interrupts.
  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }
  static intptr_t stack_limit_offset() {
    return OFFSET_OF(Thread, stack_limit_);
  }

  // The true stack limit for this OS thread.
  static intptr_t saved_stack_limit_offset() {
    return OFFSET_OF(Thread, saved_stack_limit_);
  }
  uword saved_stack_limit() const { return saved_stack_limit_; }

#if defined(USING_SAFE_STACK)
  uword saved_safestack_limit() const { return saved_safestack_limit_; }
  void set_saved_safestack_limit(uword limit) {
    saved_safestack_limit_ = limit;
  }
#endif
  uword saved_shadow_call_stack() const { return saved_shadow_call_stack_; }
  static uword saved_shadow_call_stack_offset() {
    return OFFSET_OF(Thread, saved_shadow_call_stack_);
  }

  // Stack overflow flags
  enum {
    kOsrRequest = 0x1,  // Current stack overflow caused by OSR request.
  };

  uword write_barrier_mask() const { return write_barrier_mask_; }
  uword heap_base() const {
#if defined(DART_COMPRESSED_POINTERS)
    return heap_base_;
#else
    return 0;
#endif
  }

  static intptr_t write_barrier_mask_offset() {
    return OFFSET_OF(Thread, write_barrier_mask_);
  }
#if defined(DART_COMPRESSED_POINTERS)
  static intptr_t heap_base_offset() { return OFFSET_OF(Thread, heap_base_); }
#endif
  static intptr_t stack_overflow_flags_offset() {
    return OFFSET_OF(Thread, stack_overflow_flags_);
  }

  int32_t IncrementAndGetStackOverflowCount() {
    return ++stack_overflow_count_;
  }

  uint32_t IncrementAndGetRuntimeCallCount() { return ++runtime_call_count_; }

  static uword stack_overflow_shared_stub_entry_point_offset(bool fpu_regs) {
    return fpu_regs
               ? stack_overflow_shared_with_fpu_regs_entry_point_offset()
               : stack_overflow_shared_without_fpu_regs_entry_point_offset();
  }

  static intptr_t safepoint_state_offset() {
    return OFFSET_OF(Thread, safepoint_state_);
  }


  // Tag state is maintained on transitions.
  enum {
    // Always true in generated state.
    kDidNotExit = 0,
    // The VM exited the generated state through FFI.
    // This can be true in both native and VM state.
    kExitThroughFfi = 1,
    // The VM exited the generated state through a runtime call.
    // This can be true in both native and VM state.
    kExitThroughRuntimeCall = 2,
  };

  static intptr_t exit_through_ffi_offset() {
    return OFFSET_OF(Thread, exit_through_ffi_);
  }

  TaskKind task_kind() const { return task_kind_; }

  // Retrieves and clears the stack overflow flags.  These are set by
  // the generated code before the slow path runtime routine for a
  // stack overflow is called.
  uword GetAndClearStackOverflowFlags();

  // Interrupt bits.
  enum {
    kVMInterrupt = 0x1,  // Internal VM checks: safepoints, store buffers, etc.
    kMessageInterrupt = 0x2,  // An interrupt to process an out of band message.

    kInterruptsMask = (kVMInterrupt | kMessageInterrupt),
  };

  void ScheduleInterrupts(uword interrupt_bits);
  ErrorPtr HandleInterrupts();
  uword GetAndClearInterrupts();
  bool HasScheduledInterrupts() const {
    return (stack_limit_.load() & kInterruptsMask) != 0;
  }

  // Monitor corresponding to this thread.
  Monitor* thread_lock() const { return &thread_lock_; }

  // The reusable api local scope for this thread.
  ApiLocalScope* api_reusable_scope() const { return api_reusable_scope_; }
  void set_api_reusable_scope(ApiLocalScope* value) {
    ASSERT(value == nullptr || api_reusable_scope_ == nullptr);
    api_reusable_scope_ = value;
  }

  // The api local scope for this thread, this where all local handles
  // are allocated.
  ApiLocalScope* api_top_scope() const { return api_top_scope_; }
  void set_api_top_scope(ApiLocalScope* value) { api_top_scope_ = value; }
  static intptr_t api_top_scope_offset() {
    return OFFSET_OF(Thread, api_top_scope_);
  }

  void EnterApiScope();
  void ExitApiScope();

  static intptr_t double_truncate_round_supported_offset() {
    return OFFSET_OF(Thread, double_truncate_round_supported_);
  }

  static intptr_t tsan_utils_offset() { return OFFSET_OF(Thread, tsan_utils_); }

#if defined(USING_THREAD_SANITIZER)
  uword exit_through_ffi() const { return exit_through_ffi_; }
  TsanUtils* tsan_utils() const { return tsan_utils_; }
#endif  // defined(USING_THREAD_SANITIZER)

  // The isolate that this thread is operating on, or nullptr if none.
  Isolate* isolate() const { return isolate_; }
  static intptr_t isolate_offset() { return OFFSET_OF(Thread, isolate_); }
  static intptr_t isolate_group_offset() {
    return OFFSET_OF(Thread, isolate_group_);
  }

  // The isolate group that this thread is operating on, or nullptr if none.
  IsolateGroup* isolate_group() const { return isolate_group_; }

  static intptr_t field_table_values_offset() {
    return OFFSET_OF(Thread, field_table_values_);
  }

  bool IsDartMutatorThread() const {
    return scheduled_dart_mutator_isolate_ != nullptr;
  }

  // Returns the dart mutator [Isolate] this thread belongs to or nullptr.
  //
  // `isolate()` in comparison can return
  //   - `nullptr` for dart mutators (e.g. if the mutator runs under
  //     [NoActiveIsolateScope])
  //   - an incorrect isolate (e.g. if [ActiveIsolateScope] is used to seemingly
  //     enter another isolate)
  Isolate* scheduled_dart_mutator_isolate() const {
    return scheduled_dart_mutator_isolate_;
  }

#if defined(DEBUG)
  bool IsInsideCompiler() const { return inside_compiler_; }
#endif

  // Offset of Dart TimelineStream object.
  static intptr_t dart_stream_offset() {
    return OFFSET_OF(Thread, dart_stream_);
  }

  // Offset of the Dart VM Service Extension StreamInfo object.
  static intptr_t service_extension_stream_offset() {
    return OFFSET_OF(Thread, service_extension_stream_);
  }

  // Is |this| executing Dart code?
  bool IsExecutingDartCode() const;

  // Has |this| exited Dart code?
  bool HasExitedDartCode() const;

  bool HasCompilerState() const { return compiler_state_ != nullptr; }

  CompilerState& compiler_state() {
    ASSERT(HasCompilerState());
    return *compiler_state_;
  }

  HierarchyInfo* hierarchy_info() const {
    ASSERT(isolate_group_ != nullptr);
    return hierarchy_info_;
  }

  void set_hierarchy_info(HierarchyInfo* value) {
    ASSERT(isolate_group_ != nullptr);
    ASSERT((hierarchy_info_ == nullptr && value != nullptr) ||
           (hierarchy_info_ != nullptr && value == nullptr));
    hierarchy_info_ = value;
  }

  TypeUsageInfo* type_usage_info() const {
    ASSERT(isolate_group_ != nullptr);
    return type_usage_info_;
  }

  void set_type_usage_info(TypeUsageInfo* value) {
    ASSERT(isolate_group_ != nullptr);
    ASSERT((type_usage_info_ == nullptr && value != nullptr) ||
           (type_usage_info_ != nullptr && value == nullptr));
    type_usage_info_ = value;
  }

  CompilerTimings* compiler_timings() const { return compiler_timings_; }

  void set_compiler_timings(CompilerTimings* stats) {
    compiler_timings_ = stats;
  }

  int32_t no_callback_scope_depth() const { return no_callback_scope_depth_; }
  void IncrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ < INT_MAX);
    no_callback_scope_depth_ += 1;
  }
  void DecrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ > 0);
    no_callback_scope_depth_ -= 1;
  }

  bool force_growth() const { return force_growth_scope_depth_ != 0; }
  void IncrementForceGrowthScopeDepth() {
    ASSERT(force_growth_scope_depth_ < INT_MAX);
    force_growth_scope_depth_ += 1;
  }
  void DecrementForceGrowthScopeDepth() {
    ASSERT(force_growth_scope_depth_ > 0);
    force_growth_scope_depth_ -= 1;
  }

  bool is_unwind_in_progress() const { return is_unwind_in_progress_; }

  void StartUnwindError() {
    is_unwind_in_progress_ = true;
    SetUnwindErrorInProgress(true);
  }

#if defined(DEBUG)
  void EnterCompiler() {
    ASSERT(!IsInsideCompiler());
    inside_compiler_ = true;
  }

  void LeaveCompiler() {
    ASSERT(IsInsideCompiler());
    inside_compiler_ = false;
  }
#endif

  void StoreBufferAddObject(ObjectPtr obj);
  void StoreBufferAddObjectGC(ObjectPtr obj);
#if defined(TESTING)
  bool StoreBufferContains(ObjectPtr obj) const {
    return store_buffer_block_->Contains(obj);
  }
#endif
  void StoreBufferBlockProcess(StoreBuffer::ThresholdPolicy policy);
  static intptr_t store_buffer_block_offset() {
    return OFFSET_OF(Thread, store_buffer_block_);
  }

  bool is_marking() const { return marking_stack_block_ != nullptr; }
  void MarkingStackAddObject(ObjectPtr obj);
  void DeferredMarkingStackAddObject(ObjectPtr obj);
  void MarkingStackBlockProcess();
  void DeferredMarkingStackBlockProcess();
  static intptr_t marking_stack_block_offset() {
    return OFFSET_OF(Thread, marking_stack_block_);
  }

  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword top_exit_frame_info) {
    top_exit_frame_info_ = top_exit_frame_info;
  }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Thread, top_exit_frame_info_);
  }

  Heap* heap() const;

  // The TLAB memory boundaries.
  //
  // When the heap sampling profiler is enabled, we use the TLAB boundary to
  // trigger slow path allocations so we can take a sample. This means that
  // true_end() >= end(), where true_end() is the actual end address of the
  // TLAB and end() is the chosen sampling boundary for the thread.
  //
  // When the heap sampling profiler is disabled, true_end() == end().
  uword top() const { return top_; }
  uword end() const { return end_; }
  uword true_end() const { return true_end_; }
  void set_top(uword top) { top_ = top; }
  void set_end(uword end) { end_ = end; }
  void set_true_end(uword true_end) { true_end_ = true_end; }
  static intptr_t top_offset() { return OFFSET_OF(Thread, top_); }
  static intptr_t end_offset() { return OFFSET_OF(Thread, end_); }

  int32_t no_safepoint_scope_depth() const {
#if defined(DEBUG)
    return no_safepoint_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ < INT_MAX);
    no_safepoint_scope_depth_ += 1;
#endif
  }

  void DecrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ > 0);
    no_safepoint_scope_depth_ -= 1;
#endif
  }

  bool IsInNoReloadScope() const { return no_reload_scope_depth_ > 0; }

  bool IsInStoppedMutatorsScope() const {
    return stopped_mutators_scope_depth_ > 0;
  }

#define DEFINE_OFFSET_METHOD(type_name, member_name, expr, default_init_value) \
  static intptr_t member_name##offset() {                                      \
    return OFFSET_OF(Thread, member_name);                                     \
  }
  CACHED_CONSTANTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

  static intptr_t write_barrier_wrappers_thread_offset(Register reg) {
    ASSERT((kDartAvailableCpuRegs & (1 << reg)) != 0);
    intptr_t index = 0;
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
      if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;
      if (i == reg) break;
      ++index;
    }
    return OFFSET_OF(Thread, write_barrier_wrappers_entry_points_) +
           index * sizeof(uword);
  }

  static intptr_t WriteBarrierWrappersOffsetForRegister(Register reg) {
    intptr_t index = 0;
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
      if ((kDartAvailableCpuRegs & (1 << i)) == 0) continue;
      if (i == reg) {
        return index * kStoreBufferWrapperSize;
      }
      ++index;
    }
    UNREACHABLE();
    return 0;
  }

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

  ObjectPoolPtr global_object_pool() const { return global_object_pool_; }
  void set_global_object_pool(ObjectPoolPtr raw_value) {
    global_object_pool_ = raw_value;
  }

  const uword* dispatch_table_array() const { return dispatch_table_array_; }
  void set_dispatch_table_array(const uword* array) {
    dispatch_table_array_ = array;
  }

  static bool CanLoadFromThread(const Object& object);
  static intptr_t OffsetFromThread(const Object& object);
  static bool ObjectAtOffset(intptr_t offset, Object* object);
  static intptr_t OffsetFromThread(const RuntimeEntry* runtime_entry);

#define DEFINE_OFFSET_METHOD(name)                                             \
  static intptr_t name##_entry_point_offset() {                                \
    return OFFSET_OF(Thread, name##_entry_point_);                             \
  }
  CACHED_FUNCTION_ENTRY_POINTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#if defined(DEBUG)
  // For asserts only. Has false positives when running with a simulator or
  // SafeStack.
  bool TopErrorHandlerIsSetJump() const;
  bool TopErrorHandlerIsExitFrame() const;
#endif

  uword vm_tag() const { return vm_tag_; }
  void set_vm_tag(uword tag) { vm_tag_ = tag; }
  static intptr_t vm_tag_offset() { return OFFSET_OF(Thread, vm_tag_); }

  int64_t unboxed_int64_runtime_arg() const {
    return unboxed_runtime_arg_.int64_storage[0];
  }
  void set_unboxed_int64_runtime_arg(int64_t value) {
    unboxed_runtime_arg_.int64_storage[0] = value;
  }
  int64_t unboxed_int64_runtime_second_arg() const {
    return unboxed_runtime_arg_.int64_storage[1];
  }
  void set_unboxed_int64_runtime_second_arg(int64_t value) {
    unboxed_runtime_arg_.int64_storage[1] = value;
  }
  double unboxed_double_runtime_arg() const {
    return unboxed_runtime_arg_.double_storage[0];
  }
  void set_unboxed_double_runtime_arg(double value) {
    unboxed_runtime_arg_.double_storage[0] = value;
  }
  simd128_value_t unboxed_simd128_runtime_arg() const {
    return unboxed_runtime_arg_;
  }
  void set_unboxed_simd128_runtime_arg(simd128_value_t value) {
    unboxed_runtime_arg_ = value;
  }
  static intptr_t unboxed_runtime_arg_offset() {
    return OFFSET_OF(Thread, unboxed_runtime_arg_);
  }

  static intptr_t global_object_pool_offset() {
    return OFFSET_OF(Thread, global_object_pool_);
  }

  static intptr_t dispatch_table_array_offset() {
    return OFFSET_OF(Thread, dispatch_table_array_);
  }

  ObjectPtr active_exception() const { return active_exception_; }
  void set_active_exception(const Object& value);
  static intptr_t active_exception_offset() {
    return OFFSET_OF(Thread, active_exception_);
  }

  ObjectPtr active_stacktrace() const { return active_stacktrace_; }
  void set_active_stacktrace(const Object& value);
  static intptr_t active_stacktrace_offset() {
    return OFFSET_OF(Thread, active_stacktrace_);
  }

  uword resume_pc() const { return resume_pc_; }
  void set_resume_pc(uword value) { resume_pc_ = value; }
  static uword resume_pc_offset() { return OFFSET_OF(Thread, resume_pc_); }

  ErrorPtr sticky_error() const;
  void set_sticky_error(const Error& value);
  void ClearStickyError();
  DART_WARN_UNUSED_RESULT ErrorPtr StealStickyError();

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_ACCESSORS(object)                                \
  void set_reusable_##object##_handle_scope_active(bool value) {               \
    reusable_##object##_handle_scope_active_ = value;                          \
  }                                                                            \
  bool reusable_##object##_handle_scope_active() const {                       \
    return reusable_##object##_handle_scope_active_;                           \
  }
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_ACCESSORS)
#undef REUSABLE_HANDLE_SCOPE_ACCESSORS

  bool IsAnyReusableHandleScopeActive() const {
#define IS_REUSABLE_HANDLE_SCOPE_ACTIVE(object)                                \
  if (reusable_##object##_handle_scope_active_) {                              \
    return true;                                                               \
  }
    REUSABLE_HANDLE_LIST(IS_REUSABLE_HANDLE_SCOPE_ACTIVE)
    return false;
#undef IS_REUSABLE_HANDLE_SCOPE_ACTIVE
  }
#endif  // defined(DEBUG)

  void ClearReusableHandles();

#define REUSABLE_HANDLE(object)                                                \
  object& object##Handle() const { return *object##_handle_; }
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE)
#undef REUSABLE_HANDLE

  static bool IsAtSafepoint(SafepointLevel level, uword state) {
    const uword mask = AtSafepointBits(level);
    return (state & mask) == mask;
  }

  // Whether the current thread is owning any safepoint level.
  bool IsAtSafepoint() const {
    // Owning a higher level safepoint implies owning the lower levels as well.
    return IsAtSafepoint(SafepointLevel::kGC);
  }
  bool IsAtSafepoint(SafepointLevel level) const {
    return IsAtSafepoint(level, safepoint_state_.load());
  }
  void SetAtSafepoint(bool value, SafepointLevel level) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    ASSERT(level <= current_safepoint_level());
    if (value) {
      safepoint_state_ |= AtSafepointBits(level);
    } else {
      safepoint_state_ &= ~AtSafepointBits(level);
    }
  }
  bool IsSafepointRequestedLocked(SafepointLevel level) const {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    return IsSafepointRequested(level);
  }
  bool IsSafepointRequested() const {
    return IsSafepointRequested(current_safepoint_level());
  }
  bool IsSafepointRequested(SafepointLevel level) const {
    const uword state = safepoint_state_.load();
    for (intptr_t i = level; i >= 0; --i) {
      if (IsSafepointLevelRequested(state, static_cast<SafepointLevel>(i)))
        return true;
    }
    return false;
  }
  bool IsSafepointLevelRequestedLocked(SafepointLevel level) const {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    if (level > current_safepoint_level()) return false;
    const uword state = safepoint_state_.load();
    return IsSafepointLevelRequested(state, level);
  }

  static bool IsSafepointLevelRequested(uword state, SafepointLevel level) {
    switch (level) {
      case SafepointLevel::kGC:
        return (state & SafepointRequestedField::mask_in_place()) != 0;
      case SafepointLevel::kGCAndDeopt:
        return (state & DeoptSafepointRequestedField::mask_in_place()) != 0;
      case SafepointLevel::kGCAndDeoptAndReload:
        return (state & ReloadSafepointRequestedField::mask_in_place()) != 0;
      default:
        UNREACHABLE();
    }
  }

  void BlockForSafepoint();

  uword SetSafepointRequested(SafepointLevel level, bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());

    uword mask = 0;
    switch (level) {
      case SafepointLevel::kGC:
        mask = SafepointRequestedField::mask_in_place();
        break;
      case SafepointLevel::kGCAndDeopt:
        mask = DeoptSafepointRequestedField::mask_in_place();
        break;
      case SafepointLevel::kGCAndDeoptAndReload:
        mask = ReloadSafepointRequestedField::mask_in_place();
        break;
      default:
        UNREACHABLE();
    }

    if (value) {
      // acquire pulls from the release in TryEnterSafepoint.
      return safepoint_state_.fetch_or(mask, std::memory_order_acquire);
    } else {
      // release pushes to the acquire in TryExitSafepoint.
      return safepoint_state_.fetch_and(~mask, std::memory_order_release);
    }
  }
  static bool IsBlockedForSafepoint(uword state) {
    return BlockedForSafepointField::decode(state);
  }
  bool IsBlockedForSafepoint() const {
    return BlockedForSafepointField::decode(safepoint_state_);
  }
  void SetBlockedForSafepoint(bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    safepoint_state_ =
        BlockedForSafepointField::update(value, safepoint_state_);
  }
  bool BypassSafepoints() const {
    return BypassSafepointsField::decode(safepoint_state_);
  }
  static uword SetBypassSafepoints(bool value, uword state) {
    return BypassSafepointsField::update(value, state);
  }
  bool UnwindErrorInProgress() const {
    return UnwindErrorInProgressField::decode(safepoint_state_);
  }
  void SetUnwindErrorInProgress(bool value) {
    const uword mask = UnwindErrorInProgressField::mask_in_place();
    if (value) {
      safepoint_state_.fetch_or(mask);
    } else {
      safepoint_state_.fetch_and(~mask);
    }
  }

  bool OwnsGCSafepoint() const;
  bool OwnsReloadSafepoint() const;
  bool OwnsDeoptSafepoint() const;
  bool OwnsSafepoint() const;
  bool CanAcquireSafepointLocks() const;

  uword safepoint_state() { return safepoint_state_; }

  enum ExecutionState {
    kThreadInVM = 0,
    kThreadInGenerated,
    kThreadInNative,
    kThreadInBlockedState
  };

  ExecutionState execution_state() const {
    return static_cast<ExecutionState>(execution_state_);
  }
  // Normally execution state is only accessed for the current thread.
  NO_SANITIZE_THREAD
  ExecutionState execution_state_cross_thread_for_testing() const {
    return static_cast<ExecutionState>(execution_state_);
  }
  void set_execution_state(ExecutionState state) {
    execution_state_ = static_cast<uword>(state);
  }
  static intptr_t execution_state_offset() {
    return OFFSET_OF(Thread, execution_state_);
  }

  virtual bool MayAllocateHandles() {
    return (execution_state() == kThreadInVM) ||
           (execution_state() == kThreadInGenerated);
  }

  static uword full_safepoint_state_unacquired() {
    return (0 << AtSafepointField::shift()) |
           (0 << AtDeoptSafepointField::shift());
  }
  static uword full_safepoint_state_acquired() {
    return (1 << AtSafepointField::shift()) |
           (1 << AtDeoptSafepointField::shift());
  }

  bool TryEnterSafepoint() {
    uword old_state = 0;
    uword new_state = AtSafepointBits(current_safepoint_level());
    return safepoint_state_.compare_exchange_strong(old_state, new_state,
                                                    std::memory_order_release);
  }

  void EnterSafepoint() {
    ASSERT(no_safepoint_scope_depth() == 0);
    // First try a fast update of the thread state to indicate it is at a
    // safepoint.
    if (!TryEnterSafepoint()) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation.
      EnterSafepointUsingLock();
    }
  }

  bool TryExitSafepoint() {
    uword old_state = AtSafepointBits(current_safepoint_level());
    uword new_state = 0;
    return safepoint_state_.compare_exchange_strong(old_state, new_state,
                                                    std::memory_order_acquire);
  }

  void ExitSafepoint() {
    // First try a fast update of the thread state to indicate it is not at a
    // safepoint anymore.
    if (!TryExitSafepoint()) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation.
      ExitSafepointUsingLock();
    }
  }

  void CheckForSafepoint() {
    // If we are in a runtime call that doesn't support lazy deopt, we will only
    // respond to gc safepointing requests.
    ASSERT(no_safepoint_scope_depth() == 0);
    if (IsSafepointRequested()) {
      BlockForSafepoint();
    }
  }

  Thread* next() const { return next_; }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           ValidationPolicy validate_frames);
  void RememberLiveTemporaries();
  void DeferredMarkLiveTemporaries();

  bool IsValidHandle(Dart_Handle object) const;
  bool IsValidLocalHandle(Dart_Handle object) const;
  intptr_t CountLocalHandles() const;
  int ZoneSizeInBytes() const;
  void UnwindScopes(uword stack_marker);

  void InitVMConstants();

  int64_t GetNextTaskId() { return next_task_id_++; }
  static intptr_t next_task_id_offset() {
    return OFFSET_OF(Thread, next_task_id_);
  }
  Random* random() { return &thread_random_; }
  static intptr_t random_offset() { return OFFSET_OF(Thread, thread_random_); }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler& heap_sampler() { return heap_sampler_; }
#endif

  PendingDeopts& pending_deopts() { return pending_deopts_; }

  SafepointLevel current_safepoint_level() const {
    if (runtime_call_deopt_ability_ ==
        RuntimeCallDeoptAbility::kCannotLazyDeopt) {
      return SafepointLevel::kGC;
    }
    if (no_reload_scope_depth_ > 0 || allow_reload_scope_depth_ <= 0) {
      return SafepointLevel::kGCAndDeopt;
    }
    return SafepointLevel::kGCAndDeoptAndReload;
  }

 private:
  template <class T>
  T* AllocateReusableHandle();

  enum class RestoreWriteBarrierInvariantOp {
    kAddToRememberedSet,
    kAddToDeferredMarkingStack
  };
  friend class RestoreWriteBarrierInvariantVisitor;
  void RestoreWriteBarrierInvariant(RestoreWriteBarrierInvariantOp op);

  // Set the current compiler state and return the previous compiler state.
  CompilerState* SetCompilerState(CompilerState* state) {
    CompilerState* previous = compiler_state_;
    compiler_state_ = state;
    return previous;
  }

  // Accessed from generated code.
  // ** This block of fields must come first! **
  // For AOT cross-compilation, we rely on these members having the same offsets
  // in SIMARM(IA32) and ARM, and the same offsets in SIMARM64(X64) and ARM64.
  // We use only word-sized fields to avoid differences in struct packing on the
  // different architectures. See also CheckOffsets in dart.cc.
  volatile RelaxedAtomic<uword> stack_limit_ = 0;
  uword write_barrier_mask_;
#if defined(DART_COMPRESSED_POINTERS)
  uword heap_base_ = 0;
#endif
  uword top_ = 0;
  uword end_ = 0;
  const uword* dispatch_table_array_ = nullptr;
  ObjectPtr* field_table_values_ = nullptr;

  // Offsets up to this point can all fit in a byte on X64. All of the above
  // fields are very abundantly accessed from code. Thus, keeping them first
  // is important for code size (although code size on X64 is not a priority).

// State that is cached in the TLS for fast access in generated code.
#define DECLARE_MEMBERS(type_name, member_name, expr, default_init_value)      \
  type_name member_name;
  CACHED_CONSTANTS_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(name) uword name##_entry_point_;
  RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

#define DECLARE_MEMBERS(returntype, name, ...) uword name##_entry_point_;
  LEAF_RUNTIME_ENTRY_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

  uword write_barrier_wrappers_entry_points_[kNumberOfDartAvailableCpuRegs];

#define DECLARE_MEMBERS(name) uword name##_entry_point_ = 0;
  CACHED_FUNCTION_ENTRY_POINTS_LIST(DECLARE_MEMBERS)
#undef DECLARE_MEMBERS

  Isolate* isolate_ = nullptr;
  IsolateGroup* isolate_group_ = nullptr;

  uword saved_stack_limit_ = OSThread::kInvalidStackLimit;
  // The mutator uses this to indicate it wants to OSR (by
  // setting [Thread::kOsrRequest]) before going to runtime which will see this
  // bit.
  uword stack_overflow_flags_ = 0;
  uword volatile top_exit_frame_info_ = 0;
  StoreBufferBlock* store_buffer_block_ = nullptr;
  MarkingStackBlock* marking_stack_block_ = nullptr;
  MarkingStackBlock* deferred_marking_stack_block_ = nullptr;
  uword volatile vm_tag_ = 0;
  // Memory locations dedicated for passing unboxed int64 and double
  // values from generated code to runtime.
  // TODO(dartbug.com/33549): Clean this up when unboxed values
  // could be passed as arguments.
  ALIGN8 simd128_value_t unboxed_runtime_arg_;

  // JumpToExceptionHandler state:
  ObjectPtr active_exception_;
  ObjectPtr active_stacktrace_;

  ObjectPoolPtr global_object_pool_;
  uword resume_pc_;
  uword saved_shadow_call_stack_ = 0;

  /*
   * The execution state for a thread.
   *
   * Potential execution states a thread could be in:
   *   kThreadInGenerated - The thread is running jitted dart/stub code.
   *   kThreadInVM - The thread is running VM code.
   *   kThreadInNative - The thread is running native code.
   *   kThreadInBlockedState - The thread is blocked waiting for a resource.
   *
   * Warning: Execution state doesn't imply the safepoint state. It's possible
   * to be in [kThreadInNative] and still not be at-safepoint (e.g. due to a
   * pending Dart_TypedDataAcquire() that increases no-callback-scope)
   */
  uword execution_state_;

  /*
   * Stores
   *
   *   - whether the thread is at a safepoint (current thread sets these)
   *     [AtSafepointField]
   *     [AtDeoptSafepointField]
   *     [AtReloadSafepointField]
   *
   *   - whether the thread is requested to safepoint (other thread sets these)
   *     [SafepointRequestedField]
   *     [DeoptSafepointRequestedField]
   *     [ReloadSafepointRequestedField]
   *
   *   - whether the thread is blocked due to safepoint request and needs to
   *     be resumed after safepoint is done (current thread sets this)
   *     [BlockedForSafepointField]
   *
   *   - whether the thread should be ignored for safepointing purposes
   *     [BypassSafepointsField]
   *
   *   - whether the isolate running this thread has triggered an unwind error,
   *     which requires enforced exit on a transition from native back to
   *     generated.
   *     [UnwindErrorInProgressField]
   */
  std::atomic<uword> safepoint_state_;
  uword exit_through_ffi_ = 0;
  ApiLocalScope* api_top_scope_;
  uint8_t double_truncate_round_supported_;
  ALIGN8 int64_t next_task_id_;
  ALIGN8 Random thread_random_;

  TsanUtils* tsan_utils_ = nullptr;

  // ---- End accessed from generated code. ----

  // The layout of Thread object up to this point should not depend
  // on DART_PRECOMPILED_RUNTIME, as it is accessed from generated code.
  // The code is generated without DART_PRECOMPILED_RUNTIME, but used with
  // DART_PRECOMPILED_RUNTIME.

  uword true_end_ = 0;
  TaskKind task_kind_;
  TimelineStream* dart_stream_;
  StreamInfo* service_extension_stream_;
  mutable Monitor thread_lock_;
  ApiLocalScope* api_reusable_scope_;
  int32_t no_callback_scope_depth_;
  int32_t force_growth_scope_depth_ = 0;
  intptr_t no_reload_scope_depth_ = 0;
  intptr_t allow_reload_scope_depth_ = 0;
  intptr_t stopped_mutators_scope_depth_ = 0;
#if defined(DEBUG)
  int32_t no_safepoint_scope_depth_;
#endif
  VMHandles reusable_handles_;
  int32_t stack_overflow_count_;
  uint32_t runtime_call_count_ = 0;

  // Deoptimization of stack frames.
  RuntimeCallDeoptAbility runtime_call_deopt_ability_ =
      RuntimeCallDeoptAbility::kCanLazyDeopt;
  PendingDeopts pending_deopts_;

  // Compiler state:
  CompilerState* compiler_state_ = nullptr;
  HierarchyInfo* hierarchy_info_;
  TypeUsageInfo* type_usage_info_;
  NoActiveIsolateScope* no_active_isolate_scope_ = nullptr;

  CompilerTimings* compiler_timings_ = nullptr;

  ErrorPtr sticky_error_;

  ObjectPtr* field_table_values() const { return field_table_values_; }

// Reusable handles support.
#define REUSABLE_HANDLE_FIELDS(object) object* object##_handle_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_FIELDS)
#undef REUSABLE_HANDLE_FIELDS

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_VARIABLE(object)                                 \
  bool reusable_##object##_handle_scope_active_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_VARIABLE);
#undef REUSABLE_HANDLE_SCOPE_VARIABLE
#endif  // defined(DEBUG)

  class AtSafepointField : public BitField<uword, bool, 0, 1> {};
  class SafepointRequestedField
      : public BitField<uword, bool, AtSafepointField::kNextBit, 1> {};

  class AtDeoptSafepointField
      : public BitField<uword, bool, SafepointRequestedField::kNextBit, 1> {};
  class DeoptSafepointRequestedField
      : public BitField<uword, bool, AtDeoptSafepointField::kNextBit, 1> {};

  class AtReloadSafepointField
      : public BitField<uword,
                        bool,
                        DeoptSafepointRequestedField::kNextBit,
                        1> {};
  class ReloadSafepointRequestedField
      : public BitField<uword, bool, AtReloadSafepointField::kNextBit, 1> {};

  class BlockedForSafepointField
      : public BitField<uword,
                        bool,
                        ReloadSafepointRequestedField::kNextBit,
                        1> {};
  class BypassSafepointsField
      : public BitField<uword, bool, BlockedForSafepointField::kNextBit, 1> {};
  class UnwindErrorInProgressField
      : public BitField<uword, bool, BypassSafepointsField::kNextBit, 1> {};

  static uword AtSafepointBits(SafepointLevel level) {
    switch (level) {
      case SafepointLevel::kGC:
        return AtSafepointField::mask_in_place();
      case SafepointLevel::kGCAndDeopt:
        return AtSafepointField::mask_in_place() |
               AtDeoptSafepointField::mask_in_place();
      case SafepointLevel::kGCAndDeoptAndReload:
        return AtSafepointField::mask_in_place() |
               AtDeoptSafepointField::mask_in_place() |
               AtReloadSafepointField::mask_in_place();
      default:
        UNREACHABLE();
    }
  }

#if defined(USING_SAFE_STACK)
  uword saved_safestack_limit_;
#endif

  Thread* next_;  // Used to chain the thread structures in an isolate.
  Isolate* scheduled_dart_mutator_isolate_ = nullptr;

  bool is_unwind_in_progress_ = false;

#if defined(DEBUG)
  bool inside_compiler_ = false;
#endif

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  HeapProfileSampler heap_sampler_;
#endif

  explicit Thread(bool is_vm_isolate);

  void StoreBufferRelease(
      StoreBuffer::ThresholdPolicy policy = StoreBuffer::kCheckThreshold);
  void StoreBufferAcquire();

  void MarkingStackRelease();
  void MarkingStackAcquire();
  void DeferredMarkingStackRelease();
  void DeferredMarkingStackAcquire();

  void set_safepoint_state(uint32_t value) { safepoint_state_ = value; }
  void EnterSafepointUsingLock();
  void ExitSafepointUsingLock();

  void SetupState(TaskKind kind);
  void ResetState();

  void SetupMutatorState(TaskKind kind);
  void ResetMutatorState();

  void SetupDartMutatorState(Isolate* isolate);
  void SetupDartMutatorStateDependingOnSnapshot(IsolateGroup* group);
  void ResetDartMutatorState(Isolate* isolate);

  static void SuspendDartMutatorThreadInternal(Thread* thread,
                                               VMTag::VMTagId tag);
  static void ResumeDartMutatorThreadInternal(Thread* thread);

  static void SuspendThreadInternal(Thread* thread, VMTag::VMTagId tag);
  static void ResumeThreadInternal(Thread* thread);

  // Adds a new active mutator thread to thread registry while associating it
  // with the given isolate (group).
  //
  // All existing safepoint operations are waited for before adding the thread
  // to the thread registry.
  //
  // => Anyone who iterates the active threads will first have to get us to
  // safepoint (but can access `Thread::isolate()`).
  static Thread* AddActiveThread(IsolateGroup* group,
                                 Isolate* isolate,
                                 bool is_dart_mutator,
                                 bool bypass_safepoint);

  // Releases a active mutator threads from the thread registry.
  //
  // Thread needs to be at-safepoint.
  static void FreeActiveThread(Thread* thread, bool bypass_safepoint);

  static void SetCurrent(Thread* current) { OSThread::SetCurrentTLS(current); }

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
  REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class ApiZone;
  friend class ActiveIsolateScope;
  friend class InterruptChecker;
  friend class Isolate;
  friend class IsolateGroup;
  friend class NoActiveIsolateScope;
  friend class NoReloadScope;
  friend class RawReloadParticipationScope;
  friend class Simulator;
  friend class StackZone;
  friend class StoppedMutatorsScope;
  friend class ThreadRegistry;
  friend class CompilerState;
  friend class compiler::target::Thread;
  friend class FieldTable;
  friend class RuntimeCallDeoptScope;
  friend class Dart;  // Calls SetupCachedEntryPoints after snapshot reading
  friend class
      TransitionGeneratedToVM;  // IsSafepointRequested/BlockForSafepoint
  friend class
      TransitionVMToGenerated;  // IsSafepointRequested/BlockForSafepoint
  friend class MonitorLocker;   // ExitSafepointUsingLock
  friend Isolate* CreateWithinExistingIsolateGroup(IsolateGroup*,
                                                   const char*,
                                                   char**);
  DISALLOW_COPY_AND_ASSIGN(Thread);
};

class RuntimeCallDeoptScope : public StackResource {
 public:
  RuntimeCallDeoptScope(Thread* thread, RuntimeCallDeoptAbility kind)
      : StackResource(thread) {
    // We cannot have nested calls into the VM without deopt support.
    ASSERT(thread->runtime_call_deopt_ability_ ==
           RuntimeCallDeoptAbility::kCanLazyDeopt);
    thread->runtime_call_deopt_ability_ = kind;
  }
  virtual ~RuntimeCallDeoptScope() {
    thread()->runtime_call_deopt_ability_ =
        RuntimeCallDeoptAbility::kCanLazyDeopt;
  }

 private:
  Thread* thread() {
    return reinterpret_cast<Thread*>(StackResource::thread());
  }
};

#if defined(DART_HOST_OS_WINDOWS)
// Clears the state of the current thread and frees the allocation.
void WindowsThreadCleanUp();
#endif

// Disable thread interrupts.
class DisableThreadInterruptsScope : public StackResource {
 public:
  explicit DisableThreadInterruptsScope(Thread* thread);
  ~DisableThreadInterruptsScope();
};

// Within a NoSafepointScope, the thread must not reach any safepoint. Used
// around code that manipulates raw object pointers directly without handles.
#if defined(DEBUG)
class NoSafepointScope : public ThreadStackResource {
 public:
  explicit NoSafepointScope(Thread* thread = nullptr)
      : ThreadStackResource(thread != nullptr ? thread : Thread::Current()) {
    this->thread()->IncrementNoSafepointScopeDepth();
  }
  ~NoSafepointScope() { thread()->DecrementNoSafepointScopeDepth(); }

 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#else   // defined(DEBUG)
class NoSafepointScope : public ValueObject {
 public:
  explicit NoSafepointScope(Thread* thread = nullptr) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(NoSafepointScope);
};
#endif  // defined(DEBUG)

// Disables initiating a reload operation as well as participating in another
// threads reload operation.
//
// Reload triggered by a mutator thread happens by sending all other mutator
// threads (that are running) OOB messages to check into a safepoint. The thread
// initiating the reload operation will block until all mutators are at a reload
// safepoint.
//
// When running under this scope, the processing of those OOB messages will
// ignore reload safepoint checkin requests. Yet we'll have to ensure that the
// dropped message is still acted upon.
//
// => To solve this we make the [~NoReloadScope] destructor resend a new reload
// OOB request to itself (the [~NoReloadScope] destructor is not necessarily at
// well-defined place where reload can happen - those places will explicitly
// opt-in via [ReloadParticipationScope]).
//
class NoReloadScope : public ThreadStackResource {
 public:
  explicit NoReloadScope(Thread* thread);
  ~NoReloadScope();

 private:
  DISALLOW_COPY_AND_ASSIGN(NoReloadScope);
};

// Allows triggering reload safepoint operations as well as participating in
// reload operations (at safepoint checks).
//
// By-default safepoint checkins will not participate in reload operations, as
// reload has to happen at very well-defined places. This scope is intended
// for those places where we explicitly want to allow safepoint checkins to
// participate in reload operations (triggered by other threads).
//
// If there is any [NoReloadScope] active we will still disable the safepoint
// checkins to participate in reload.
//
// We also require the thread inititating a reload operation to explicitly
// opt-in via this scope.
class RawReloadParticipationScope {
 public:
  explicit RawReloadParticipationScope(Thread* thread) : thread_(thread) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    if (thread->allow_reload_scope_depth_ == 0) {
      ASSERT(thread->current_safepoint_level() == SafepointLevel::kGCAndDeopt);
    }
    thread->allow_reload_scope_depth_++;
    ASSERT(thread->allow_reload_scope_depth_ >= 0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  }

  ~RawReloadParticipationScope() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    thread_->allow_reload_scope_depth_ -= 1;
    ASSERT(thread_->allow_reload_scope_depth_ >= 0);
    if (thread_->allow_reload_scope_depth_ == 0) {
      ASSERT(thread_->current_safepoint_level() == SafepointLevel::kGCAndDeopt);
    }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  }

 private:
  Thread* thread_;

  DISALLOW_COPY_AND_ASSIGN(RawReloadParticipationScope);
};

using ReloadParticipationScope =
    AsThreadStackResource<RawReloadParticipationScope>;

class StoppedMutatorsScope : public ThreadStackResource {
 public:
  explicit StoppedMutatorsScope(Thread* thread) : ThreadStackResource(thread) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    thread->stopped_mutators_scope_depth_++;
    ASSERT(thread->stopped_mutators_scope_depth_ >= 0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  }

  ~StoppedMutatorsScope() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    thread()->stopped_mutators_scope_depth_ -= 1;
    ASSERT(thread()->stopped_mutators_scope_depth_ >= 0);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(StoppedMutatorsScope);
};

// Within a EnterCompilerScope, the thread must operate on cloned fields.
#if defined(DEBUG)
class EnterCompilerScope : public ThreadStackResource {
 public:
  explicit EnterCompilerScope(Thread* thread = nullptr)
      : ThreadStackResource(thread != nullptr ? thread : Thread::Current()) {
    previously_is_inside_compiler_ = this->thread()->IsInsideCompiler();
    if (!previously_is_inside_compiler_) {
      this->thread()->EnterCompiler();
    }
  }
  ~EnterCompilerScope() {
    if (!previously_is_inside_compiler_) {
      thread()->LeaveCompiler();
    }
  }

 private:
  bool previously_is_inside_compiler_;
  DISALLOW_COPY_AND_ASSIGN(EnterCompilerScope);
};
#else   // defined(DEBUG)
class EnterCompilerScope : public ValueObject {
 public:
  explicit EnterCompilerScope(Thread* thread = nullptr) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(EnterCompilerScope);
};
#endif  // defined(DEBUG)

// Within a LeaveCompilerScope, the thread must operate on cloned fields.
#if defined(DEBUG)
class LeaveCompilerScope : public ThreadStackResource {
 public:
  explicit LeaveCompilerScope(Thread* thread = nullptr)
      : ThreadStackResource(thread != nullptr ? thread : Thread::Current()) {
    previously_is_inside_compiler_ = this->thread()->IsInsideCompiler();
    if (previously_is_inside_compiler_) {
      this->thread()->LeaveCompiler();
    }
  }
  ~LeaveCompilerScope() {
    if (previously_is_inside_compiler_) {
      thread()->EnterCompiler();
    }
  }

 private:
  bool previously_is_inside_compiler_;
  DISALLOW_COPY_AND_ASSIGN(LeaveCompilerScope);
};
#else   // defined(DEBUG)
class LeaveCompilerScope : public ValueObject {
 public:
  explicit LeaveCompilerScope(Thread* thread = nullptr) {}

 private:
  DISALLOW_COPY_AND_ASSIGN(LeaveCompilerScope);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_H_
