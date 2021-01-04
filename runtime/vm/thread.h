// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_H_
#define RUNTIME_VM_THREAD_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

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
#include "vm/os_thread.h"
#include "vm/random.h"
#include "vm/runtime_entry_list.h"
#include "vm/thread_stack_resource.h"
#include "vm/thread_state.h"
namespace dart {

class AbstractType;
class ApiLocalScope;
class Array;
class CompilerState;
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
class PcDescriptors;
class RuntimeEntry;
class Smi;
class StackResource;
class StackTrace;
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
  V(Object)                                                                    \
  V(PcDescriptors)                                                             \
  V(Smi)                                                                       \
  V(String)                                                                    \
  V(TypeArguments)                                                             \
  V(TypeParameter)

#define CACHED_VM_STUBS_LIST(V)                                                \
  V(CodePtr, write_barrier_code_, StubCode::WriteBarrier().raw(), nullptr)     \
  V(CodePtr, array_write_barrier_code_, StubCode::ArrayWriteBarrier().raw(),   \
    nullptr)                                                                   \
  V(CodePtr, fix_callers_target_code_, StubCode::FixCallersTarget().raw(),     \
    nullptr)                                                                   \
  V(CodePtr, fix_allocation_stub_code_,                                        \
    StubCode::FixAllocationStubTarget().raw(), nullptr)                        \
  V(CodePtr, invoke_dart_code_stub_, StubCode::InvokeDartCode().raw(),         \
    nullptr)                                                                   \
  V(CodePtr, call_to_runtime_stub_, StubCode::CallToRuntime().raw(), nullptr)  \
  V(CodePtr, late_initialization_error_shared_without_fpu_regs_stub_,          \
    StubCode::LateInitializationErrorSharedWithoutFPURegs().raw(), nullptr)    \
  V(CodePtr, late_initialization_error_shared_with_fpu_regs_stub_,             \
    StubCode::LateInitializationErrorSharedWithFPURegs().raw(), nullptr)       \
  V(CodePtr, null_error_shared_without_fpu_regs_stub_,                         \
    StubCode::NullErrorSharedWithoutFPURegs().raw(), nullptr)                  \
  V(CodePtr, null_error_shared_with_fpu_regs_stub_,                            \
    StubCode::NullErrorSharedWithFPURegs().raw(), nullptr)                     \
  V(CodePtr, null_arg_error_shared_without_fpu_regs_stub_,                     \
    StubCode::NullArgErrorSharedWithoutFPURegs().raw(), nullptr)               \
  V(CodePtr, null_arg_error_shared_with_fpu_regs_stub_,                        \
    StubCode::NullArgErrorSharedWithFPURegs().raw(), nullptr)                  \
  V(CodePtr, null_cast_error_shared_without_fpu_regs_stub_,                    \
    StubCode::NullCastErrorSharedWithoutFPURegs().raw(), nullptr)              \
  V(CodePtr, null_cast_error_shared_with_fpu_regs_stub_,                       \
    StubCode::NullCastErrorSharedWithFPURegs().raw(), nullptr)                 \
  V(CodePtr, range_error_shared_without_fpu_regs_stub_,                        \
    StubCode::RangeErrorSharedWithoutFPURegs().raw(), nullptr)                 \
  V(CodePtr, range_error_shared_with_fpu_regs_stub_,                           \
    StubCode::RangeErrorSharedWithFPURegs().raw(), nullptr)                    \
  V(CodePtr, allocate_mint_with_fpu_regs_stub_,                                \
    StubCode::AllocateMintSharedWithFPURegs().raw(), nullptr)                  \
  V(CodePtr, allocate_mint_without_fpu_regs_stub_,                             \
    StubCode::AllocateMintSharedWithoutFPURegs().raw(), nullptr)               \
  V(CodePtr, allocate_object_stub_, StubCode::AllocateObject().raw(), nullptr) \
  V(CodePtr, allocate_object_parameterized_stub_,                              \
    StubCode::AllocateObjectParameterized().raw(), nullptr)                    \
  V(CodePtr, allocate_object_slow_stub_, StubCode::AllocateObjectSlow().raw(), \
    nullptr)                                                                   \
  V(CodePtr, stack_overflow_shared_without_fpu_regs_stub_,                     \
    StubCode::StackOverflowSharedWithoutFPURegs().raw(), nullptr)              \
  V(CodePtr, stack_overflow_shared_with_fpu_regs_stub_,                        \
    StubCode::StackOverflowSharedWithFPURegs().raw(), nullptr)                 \
  V(CodePtr, switchable_call_miss_stub_, StubCode::SwitchableCallMiss().raw(), \
    nullptr)                                                                   \
  V(CodePtr, throw_stub_, StubCode::Throw().raw(), nullptr)                    \
  V(CodePtr, re_throw_stub_, StubCode::Throw().raw(), nullptr)                 \
  V(CodePtr, assert_boolean_stub_, StubCode::AssertBoolean().raw(), nullptr)   \
  V(CodePtr, optimize_stub_, StubCode::OptimizeFunction().raw(), nullptr)      \
  V(CodePtr, deoptimize_stub_, StubCode::Deoptimize().raw(), nullptr)          \
  V(CodePtr, lazy_deopt_from_return_stub_,                                     \
    StubCode::DeoptimizeLazyFromReturn().raw(), nullptr)                       \
  V(CodePtr, lazy_deopt_from_throw_stub_,                                      \
    StubCode::DeoptimizeLazyFromThrow().raw(), nullptr)                        \
  V(CodePtr, slow_type_test_stub_, StubCode::SlowTypeTest().raw(), nullptr)    \
  V(CodePtr, lazy_specialize_type_test_stub_,                                  \
    StubCode::LazySpecializeTypeTest().raw(), nullptr)                         \
  V(CodePtr, enter_safepoint_stub_, StubCode::EnterSafepoint().raw(), nullptr) \
  V(CodePtr, exit_safepoint_stub_, StubCode::ExitSafepoint().raw(), nullptr)   \
  V(CodePtr, call_native_through_safepoint_stub_,                              \
    StubCode::CallNativeThroughSafepoint().raw(), nullptr)

#define CACHED_NON_VM_STUB_LIST(V)                                             \
  V(ObjectPtr, object_null_, Object::null(), nullptr)                          \
  V(BoolPtr, bool_true_, Object::bool_true().raw(), nullptr)                   \
  V(BoolPtr, bool_false_, Object::bool_false().raw(), nullptr)

// List of VM-global objects/addresses cached in each Thread object.
// Important: constant false must immediately follow constant true.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  CACHED_NON_VM_STUB_LIST(V)                                                   \
  CACHED_VM_STUBS_LIST(V)

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
    NULL)                                                                      \
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
  };
  // Converts a TaskKind to its corresponding C-String name.
  static const char* TaskKindToCString(TaskKind kind);

  ~Thread();

  // The currently executing thread, or NULL if not yet initialized.
  static Thread* Current() {
#if defined(HAS_C11_THREAD_LOCAL)
    return static_cast<Thread*>(OSThread::CurrentVMThread());
#else
    BaseThread* thread = OSThread::GetCurrentTLS();
    if (thread == NULL || thread->is_os_thread()) {
      return NULL;
    }
    return static_cast<Thread*>(thread);
#endif
  }

  // Makes the current thread enter 'isolate'.
  static bool EnterIsolate(Isolate* isolate);
  // Makes the current thread exit its isolate.
  static void ExitIsolate();

  // A VM thread other than the main mutator thread can enter an isolate as a
  // "helper" to gain limited concurrent access to the isolate. One example is
  // SweeperTask (which uses the class table, which is copy-on-write).
  // TODO(koda): Properly synchronize heap access to expand allowed operations.
  static bool EnterIsolateAsHelper(Isolate* isolate,
                                   TaskKind kind,
                                   bool bypass_safepoint = false);
  static void ExitIsolateAsHelper(bool bypass_safepoint = false);

  static bool EnterIsolateGroupAsHelper(IsolateGroup* isolate_group,
                                        TaskKind kind,
                                        bool bypass_safepoint);
  static void ExitIsolateGroupAsHelper(bool bypass_safepoint);

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
  static uword saved_shadow_call_stack_offset() {
    return OFFSET_OF(Thread, saved_shadow_call_stack_);
  }

  // Stack overflow flags
  enum {
    kOsrRequest = 0x1,  // Current stack overflow caused by OSR request.
  };

  uword write_barrier_mask() const { return write_barrier_mask_; }

  static intptr_t write_barrier_mask_offset() {
    return OFFSET_OF(Thread, write_barrier_mask_);
  }
  static intptr_t stack_overflow_flags_offset() {
    return OFFSET_OF(Thread, stack_overflow_flags_);
  }

  int32_t IncrementAndGetStackOverflowCount() {
    return ++stack_overflow_count_;
  }

  static uword stack_overflow_shared_stub_entry_point_offset(bool fpu_regs) {
    return fpu_regs
               ? stack_overflow_shared_with_fpu_regs_entry_point_offset()
               : stack_overflow_shared_without_fpu_regs_entry_point_offset();
  }

  static intptr_t safepoint_state_offset() {
    return OFFSET_OF(Thread, safepoint_state_);
  }

  static intptr_t callback_code_offset() {
    return OFFSET_OF(Thread, ffi_callback_code_);
  }

  static intptr_t callback_stack_return_offset() {
    return OFFSET_OF(Thread, ffi_callback_stack_return_);
  }

  // Tag state is maintained on transitions.
  enum {
    // Always true in generated state.
    kDidNotExit = 0,
    // The VM did exit the generated state through FFI.
    // This can be true in both native and VM state.
    kExitThroughFfi = 1,
    // The VM exited the generated state through FFI.
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
  void ScheduleInterruptsLocked(uword interrupt_bits);
  ErrorPtr HandleInterrupts();
  uword GetAndClearInterrupts();
  bool HasScheduledInterrupts() const {
    return (stack_limit_ & kInterruptsMask) != 0;
  }

  // Monitor corresponding to this thread.
  Monitor* thread_lock() const { return &thread_lock_; }

  // The reusable api local scope for this thread.
  ApiLocalScope* api_reusable_scope() const { return api_reusable_scope_; }
  void set_api_reusable_scope(ApiLocalScope* value) {
    ASSERT(value == NULL || api_reusable_scope_ == NULL);
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

  // The isolate that this thread is operating on, or nullptr if none.
  Isolate* isolate() const { return isolate_; }
  static intptr_t isolate_offset() { return OFFSET_OF(Thread, isolate_); }

  // The isolate group that this thread is operating on, or nullptr if none.
  IsolateGroup* isolate_group() const { return isolate_group_; }

  static intptr_t field_table_values_offset() {
    return OFFSET_OF(Thread, field_table_values_);
  }

  bool IsMutatorThread() const { return is_mutator_thread_; }

#if defined(DEBUG)
  bool IsInsideCompiler() const { return inside_compiler_; }
#endif

  bool CanCollectGarbage() const;

  // Offset of Dart TimelineStream object.
  static intptr_t dart_stream_offset() {
    return OFFSET_OF(Thread, dart_stream_);
  }

  // Is |this| executing Dart code?
  bool IsExecutingDartCode() const;

  // Has |this| exited Dart code?
  bool HasExitedDartCode() const;

  CompilerState& compiler_state() {
    ASSERT(compiler_state_ != nullptr);
    return *compiler_state_;
  }

  HierarchyInfo* hierarchy_info() const {
    ASSERT(isolate_ != NULL);
    return hierarchy_info_;
  }

  void set_hierarchy_info(HierarchyInfo* value) {
    ASSERT(isolate_ != NULL);
    ASSERT((hierarchy_info_ == NULL && value != NULL) ||
           (hierarchy_info_ != NULL && value == NULL));
    hierarchy_info_ = value;
  }

  TypeUsageInfo* type_usage_info() const {
    ASSERT(isolate_ != NULL);
    return type_usage_info_;
  }

  void set_type_usage_info(TypeUsageInfo* value) {
    ASSERT(isolate_ != NULL);
    ASSERT((type_usage_info_ == NULL && value != NULL) ||
           (type_usage_info_ != NULL && value == NULL));
    type_usage_info_ = value;
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

  bool is_marking() const { return marking_stack_block_ != NULL; }
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

  // Heap of the isolate that this thread is operating on.
  Heap* heap() const { return heap_; }
  static intptr_t heap_offset() { return OFFSET_OF(Thread, heap_); }

  uword top() const { return top_; }
  uword end() const { return end_; }
  void set_top(uword top) { top_ = top; }
  void set_end(uword end) { end_ = end; }
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

#define DEFINE_OFFSET_METHOD(type_name, member_name, expr, default_init_value) \
  static intptr_t member_name##offset() {                                      \
    return OFFSET_OF(Thread, member_name);                                     \
  }
  CACHED_CONSTANTS_LIST(DEFINE_OFFSET_METHOD)
#undef DEFINE_OFFSET_METHOD

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64) ||                  \
    defined(TARGET_ARCH_X64)
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
#endif

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
    return unboxed_int64_runtime_arg_;
  }
  void set_unboxed_int64_runtime_arg(int64_t value) {
    unboxed_int64_runtime_arg_ = value;
  }
  static intptr_t unboxed_int64_runtime_arg_offset() {
    return OFFSET_OF(Thread, unboxed_int64_runtime_arg_);
  }

  GrowableObjectArrayPtr pending_functions();
  void clear_pending_functions();

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

  /*
   * Fields used to support safepointing a thread.
   *
   * - Bit 0 of the safepoint_state_ field is used to indicate if the thread is
   *   already at a safepoint,
   * - Bit 1 of the safepoint_state_ field is used to indicate if a safepoint
   *   operation is requested for this thread.
   * - Bit 2 of the safepoint_state_ field is used to indicate that the thread
   *   is blocked for the safepoint operation to complete.
   *
   * The safepoint execution state (described above) for a thread is stored in
   * in the execution_state_ field.
   * Potential execution states a thread could be in:
   *   kThreadInGenerated - The thread is running jitted dart/stub code.
   *   kThreadInVM - The thread is running VM code.
   *   kThreadInNative - The thread is running native code.
   *   kThreadInBlockedState - The thread is blocked waiting for a resource.
   */
  static bool IsAtSafepoint(uword state) {
    return AtSafepointField::decode(state);
  }
  bool IsAtSafepoint() const {
    return AtSafepointField::decode(safepoint_state_);
  }
  static uword SetAtSafepoint(bool value, uword state) {
    return AtSafepointField::update(value, state);
  }
  void SetAtSafepoint(bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    safepoint_state_ = AtSafepointField::update(value, safepoint_state_);
  }
  bool IsSafepointRequested() const {
    return SafepointRequestedField::decode(safepoint_state_);
  }
  static uword SetSafepointRequested(bool value, uword state) {
    return SafepointRequestedField::update(value, state);
  }
  uword SetSafepointRequested(bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    if (value) {
      // acquire pulls from the release in TryEnterSafepoint.
      return safepoint_state_.fetch_or(SafepointRequestedField::encode(true),
                                       std::memory_order_acquire);
    } else {
      // release pushes to the acquire in TryExitSafepoint.
      return safepoint_state_.fetch_and(~SafepointRequestedField::encode(true),
                                        std::memory_order_release);
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

  static uword safepoint_state_unacquired() { return SetAtSafepoint(false, 0); }
  static uword safepoint_state_acquired() { return SetAtSafepoint(true, 0); }

  bool TryEnterSafepoint() {
    uword old_state = 0;
    uword new_state = SetAtSafepoint(true, 0);
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
    uword old_state = SetAtSafepoint(true, 0);
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
    ASSERT(no_safepoint_scope_depth() == 0);
    if (IsSafepointRequested()) {
      BlockForSafepoint();
    }
  }

  int32_t AllocateFfiCallbackId();

  // Store 'code' for the native callback identified by 'callback_id'.
  //
  // Expands the callback code array as necessary to accomodate the callback
  // ID.
  void SetFfiCallbackCode(int32_t callback_id, const Code& code);

  // Store 'stack_return' for the native callback identified by 'callback_id'.
  //
  // Expands the callback stack return array as necessary to accomodate the
  // callback ID.
  void SetFfiCallbackStackReturn(int32_t callback_id,
                                 intptr_t stack_return_delta);

  // Ensure that 'callback_id' refers to a valid callback in this isolate.
  //
  // If "entry != 0", additionally checks that entry is inside the instructions
  // of this callback.
  //
  // Aborts if any of these conditions fails.
  void VerifyCallbackIsolate(int32_t callback_id, uword entry);

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

  uint64_t GetRandomUInt64() { return thread_random_.NextUInt64(); }

  uint64_t* GetFfiMarshalledArguments(intptr_t size) {
    if (ffi_marshalled_arguments_size_ < size) {
      if (ffi_marshalled_arguments_size_ > 0) {
        free(ffi_marshalled_arguments_);
      }
      ffi_marshalled_arguments_ =
          reinterpret_cast<uint64_t*>(malloc(size * sizeof(uint64_t)));
    }
    return ffi_marshalled_arguments_;
  }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

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
  RelaxedAtomic<uword> stack_limit_;
  uword write_barrier_mask_;
  Isolate* isolate_;
  const uword* dispatch_table_array_;
  uword top_ = 0;
  uword end_ = 0;
  // Offsets up to this point can all fit in a byte on X64. All of the above
  // fields are very abundantly accessed from code. Thus, keeping them first
  // is important for code size (although code size on X64 is not a priority).
  uword saved_stack_limit_;
  uword stack_overflow_flags_;
  InstancePtr* field_table_values_;
  Heap* heap_;
  uword volatile top_exit_frame_info_;
  StoreBufferBlock* store_buffer_block_;
  MarkingStackBlock* marking_stack_block_;
  MarkingStackBlock* deferred_marking_stack_block_;
  uword volatile vm_tag_;
  // Memory location dedicated for passing unboxed int64 values from
  // generated code to runtime.
  // TODO(dartbug.com/33549): Clean this up when unboxed values
  // could be passed as arguments.
  ALIGN8 int64_t unboxed_int64_runtime_arg_;

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

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64) ||                  \
    defined(TARGET_ARCH_X64)
  uword write_barrier_wrappers_entry_points_[kNumberOfDartAvailableCpuRegs];
#endif

  // JumpToExceptionHandler state:
  ObjectPtr active_exception_;
  ObjectPtr active_stacktrace_;
  ObjectPoolPtr global_object_pool_;
  uword resume_pc_;
  uword saved_shadow_call_stack_ = 0;
  uword execution_state_;
  std::atomic<uword> safepoint_state_;
  GrowableObjectArrayPtr ffi_callback_code_;
  TypedDataPtr ffi_callback_stack_return_;
  uword exit_through_ffi_ = 0;
  ApiLocalScope* api_top_scope_;

  // ---- End accessed from generated code. ----

  // The layout of Thread object up to this point should not depend
  // on DART_PRECOMPILED_RUNTIME, as it is accessed from generated code.
  // The code is generated without DART_PRECOMPILED_RUNTIME, but used with
  // DART_PRECOMPILED_RUNTIME.

  TaskKind task_kind_;
  TimelineStream* dart_stream_;
  IsolateGroup* isolate_group_ = nullptr;
  mutable Monitor thread_lock_;
  ApiLocalScope* api_reusable_scope_;
  int32_t no_callback_scope_depth_;
#if defined(DEBUG)
  int32_t no_safepoint_scope_depth_;
#endif
  VMHandles reusable_handles_;
  intptr_t defer_oob_messages_count_;
  uint16_t deferred_interrupts_mask_;
  uint16_t deferred_interrupts_;
  int32_t stack_overflow_count_;

  // Compiler state:
  CompilerState* compiler_state_ = nullptr;
  HierarchyInfo* hierarchy_info_;
  TypeUsageInfo* type_usage_info_;
  GrowableObjectArrayPtr pending_functions_;

  ErrorPtr sticky_error_;

  Random thread_random_;

  intptr_t ffi_marshalled_arguments_size_ = 0;
  uint64_t* ffi_marshalled_arguments_;

  InstancePtr* field_table_values() const { return field_table_values_; }

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

  // Generated code assumes that AtSafepointField is the LSB.
  class AtSafepointField : public BitField<uword, bool, 0, 1> {};
  class SafepointRequestedField : public BitField<uword, bool, 1, 1> {};
  class BlockedForSafepointField : public BitField<uword, bool, 2, 1> {};
  class BypassSafepointsField : public BitField<uword, bool, 3, 1> {};

#if defined(USING_SAFE_STACK)
  uword saved_safestack_limit_;
#endif

  Thread* next_;  // Used to chain the thread structures in an isolate.
  bool is_mutator_thread_ = false;

#if defined(DEBUG)
  bool inside_compiler_ = false;
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
  void BlockForSafepoint();

  void FinishEntering(TaskKind kind);
  void PrepareLeaving();

  static void SetCurrent(Thread* current) { OSThread::SetCurrentTLS(current); }

  void DeferOOBMessageInterrupts();
  void RestoreOOBMessageInterrupts();

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
  REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class ApiZone;
  friend class InterruptChecker;
  friend class Isolate;
  friend class IsolateGroup;
  friend class IsolateTestHelper;
  friend class NoOOBMessageScope;
  friend class Simulator;
  friend class StackZone;
  friend class ThreadRegistry;
  friend class NoActiveIsolateScope;
  friend class CompilerState;
  friend class compiler::target::Thread;
  friend class FieldTable;
  friend Isolate* CreateWithinExistingIsolateGroup(IsolateGroup*,
                                                   const char*,
                                                   char**);
  DISALLOW_COPY_AND_ASSIGN(Thread);
};

#if defined(HOST_OS_WINDOWS)
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
