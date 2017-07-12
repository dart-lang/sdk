// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_H_
#define RUNTIME_VM_THREAD_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/atomic.h"
#include "vm/bitfield.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/os_thread.h"
#include "vm/store_buffer.h"
#include "vm/runtime_entry_list.h"
namespace dart {

class AbstractType;
class ApiLocalScope;
class Array;
class CHA;
class Class;
class Code;
class CompilerStats;
class Error;
class ExceptionHandlers;
class Field;
class Function;
class GrowableObjectArray;
class HandleScope;
class Heap;
class Instance;
class Isolate;
class Library;
class LongJumpScope;
class Object;
class OSThread;
class JSONObject;
class PcDescriptors;
class RawBool;
class RawObject;
class RawCode;
class RawError;
class RawGrowableObjectArray;
class RawStackTrace;
class RawString;
class RuntimeEntry;
class Smi;
class StackResource;
class StackTrace;
class String;
class TimelineStream;
class TypeArguments;
class TypeParameter;
class Zone;

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


#if defined(TARGET_ARCH_DBC)
#define CACHED_VM_STUBS_LIST(V)
#else
#define CACHED_VM_STUBS_LIST(V)                                                \
  V(RawCode*, update_store_buffer_code_,                                       \
    StubCode::UpdateStoreBuffer_entry()->code(), NULL)                         \
  V(RawCode*, fix_callers_target_code_,                                        \
    StubCode::FixCallersTarget_entry()->code(), NULL)                          \
  V(RawCode*, fix_allocation_stub_code_,                                       \
    StubCode::FixAllocationStubTarget_entry()->code(), NULL)                   \
  V(RawCode*, invoke_dart_code_stub_,                                          \
    StubCode::InvokeDartCode_entry()->code(), NULL)                            \
  V(RawCode*, call_to_runtime_stub_, StubCode::CallToRuntime_entry()->code(),  \
    NULL)                                                                      \
  V(RawCode*, monomorphic_miss_stub_,                                          \
    StubCode::MonomorphicMiss_entry()->code(), NULL)                           \
  V(RawCode*, ic_lookup_through_code_stub_,                                    \
    StubCode::ICCallThroughCode_entry()->code(), NULL)                         \
  V(RawCode*, lazy_deopt_from_return_stub_,                                    \
    StubCode::DeoptimizeLazyFromReturn_entry()->code(), NULL)                  \
  V(RawCode*, lazy_deopt_from_throw_stub_,                                     \
    StubCode::DeoptimizeLazyFromThrow_entry()->code(), NULL)

#endif

// List of VM-global objects/addresses cached in each Thread object.
#define CACHED_VM_OBJECTS_LIST(V)                                              \
  V(RawObject*, object_null_, Object::null(), NULL)                            \
  V(RawBool*, bool_true_, Object::bool_true().raw(), NULL)                     \
  V(RawBool*, bool_false_, Object::bool_false().raw(), NULL)                   \
  CACHED_VM_STUBS_LIST(V)

#if defined(TARGET_ARCH_DBC)
#define CACHED_VM_STUBS_ADDRESSES_LIST(V)
#else
#define CACHED_VM_STUBS_ADDRESSES_LIST(V)                                      \
  V(uword, update_store_buffer_entry_point_,                                   \
    StubCode::UpdateStoreBuffer_entry()->EntryPoint(), 0)                      \
  V(uword, call_to_runtime_entry_point_,                                       \
    StubCode::CallToRuntime_entry()->EntryPoint(), 0)                          \
  V(uword, megamorphic_call_checked_entry_,                                    \
    StubCode::MegamorphicCall_entry()->EntryPoint(), 0)                        \
  V(uword, monomorphic_miss_entry_,                                            \
    StubCode::MonomorphicMiss_entry()->EntryPoint(), 0)

#endif

#define CACHED_ADDRESSES_LIST(V)                                               \
  CACHED_VM_STUBS_ADDRESSES_LIST(V)                                            \
  V(uword, no_scope_native_wrapper_entry_point_,                               \
    NativeEntry::NoScopeNativeCallWrapperEntry(), 0)                           \
  V(uword, auto_scope_native_wrapper_entry_point_,                             \
    NativeEntry::AutoScopeNativeCallWrapperEntry(), 0)                         \
  V(RawString**, predefined_symbols_address_, Symbols::PredefinedAddress(),    \
    NULL)                                                                      \
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

// A VM thread; may be executing Dart code or performing helper tasks like
// garbage collection or compilation. The Thread structure associated with
// a thread is allocated by EnsureInit before entering an isolate, and destroyed
// automatically when the underlying OS thread exits. NOTE: On Windows, CleanUp
// must currently be called manually (issue 23474).
class Thread : public BaseThread {
 public:
  // The kind of task this thread is performing. Sampled by the profiler.
  enum TaskKind {
    kUnknownTask = 0x0,
    kMutatorTask = 0x1,
    kCompilerTask = 0x2,
    kSweeperTask = 0x4,
    kMarkerTask = 0x8,
  };
  // Converts a TaskKind to its corresponding C-String name.
  static const char* TaskKindToCString(TaskKind kind);

  ~Thread();

  // The currently executing thread, or NULL if not yet initialized.
  static Thread* Current() {
    BaseThread* thread = OSThread::GetCurrentTLS();
    if (thread == NULL || thread->is_os_thread()) {
      return NULL;
    }
    return reinterpret_cast<Thread*>(thread);
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

  // Empties the store buffer block into the isolate.
  void PrepareForGC();

  void SetStackLimit(uword value);
  void SetStackLimitFromStackBase(uword stack_base);
  void ClearStackLimit();

  // Returns the current C++ stack pointer. Equivalent taking the address of a
  // stack allocated local, but plays well with AddressSanitizer.
  static uword GetCurrentStackPointer();

  // Access to the current stack limit for generated code.  This may be
  // overwritten with a special value to trigger interrupts.
  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }
  static intptr_t stack_limit_offset() {
    return OFFSET_OF(Thread, stack_limit_);
  }

  // The true stack limit for this isolate.
  uword saved_stack_limit() const { return saved_stack_limit_; }

#if defined(TARGET_ARCH_DBC)
  // Access to the current stack limit for DBC interpreter.
  uword stack_limit() const { return stack_limit_; }
#endif

  // Stack overflow flags
  enum {
    kOsrRequest = 0x1,  // Current stack overflow caused by OSR request.
  };

  uword stack_overflow_flags_address() const {
    return reinterpret_cast<uword>(&stack_overflow_flags_);
  }
  static intptr_t stack_overflow_flags_offset() {
    return OFFSET_OF(Thread, stack_overflow_flags_);
  }

  int32_t IncrementAndGetStackOverflowCount() {
    return ++stack_overflow_count_;
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
  RawError* HandleInterrupts();
  uword GetAndClearInterrupts();

  // OSThread corresponding to this thread.
  OSThread* os_thread() const { return os_thread_; }
  void set_os_thread(OSThread* os_thread) { os_thread_ = os_thread; }

  // Monitor corresponding to this thread.
  Monitor* thread_lock() const { return thread_lock_; }

  // The topmost zone used for allocation in this thread.
  Zone* zone() const { return zone_; }

  bool ZoneIsOwnedByThread(Zone* zone) const;

  void IncrementMemoryCapacity(uintptr_t value) {
    current_zone_capacity_ += value;
    if (current_zone_capacity_ > zone_high_watermark_) {
      zone_high_watermark_ = current_zone_capacity_;
    }
  }

  void DecrementMemoryCapacity(uintptr_t value) {
    ASSERT(current_zone_capacity_ >= value);
    current_zone_capacity_ -= value;
  }

  uintptr_t current_zone_capacity() { return current_zone_capacity_; }

  uintptr_t zone_high_watermark() const { return zone_high_watermark_; }

  void ResetHighWatermark() { zone_high_watermark_ = current_zone_capacity_; }

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

  // The isolate that this thread is operating on, or NULL if none.
  Isolate* isolate() const { return isolate_; }
  static intptr_t isolate_offset() { return OFFSET_OF(Thread, isolate_); }
  bool IsMutatorThread() const;
  bool CanCollectGarbage() const;

  // Offset of Dart TimelineStream object.
  static intptr_t dart_stream_offset() {
    return OFFSET_OF(Thread, dart_stream_);
  }

  // Is |this| executing Dart code?
  bool IsExecutingDartCode() const;

  // Has |this| exited Dart code?
  bool HasExitedDartCode() const;

  // The (topmost) CHA for the compilation in this thread.
  CHA* cha() const {
    ASSERT(isolate_ != NULL);
    return cha_;
  }

  void set_cha(CHA* value) {
    ASSERT(isolate_ != NULL);
    cha_ = value;
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

  void StoreBufferAddObject(RawObject* obj);
  void StoreBufferAddObjectGC(RawObject* obj);
#if defined(TESTING)
  bool StoreBufferContains(RawObject* obj) const {
    return store_buffer_block_->Contains(obj);
  }
#endif
  void StoreBufferBlockProcess(StoreBuffer::ThresholdPolicy policy);
  static intptr_t store_buffer_block_offset() {
    return OFFSET_OF(Thread, store_buffer_block_);
  }

  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword top_exit_frame_info) {
    top_exit_frame_info_ = top_exit_frame_info;
  }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Thread, top_exit_frame_info_);
  }

  StackResource* top_resource() const { return top_resource_; }
  void set_top_resource(StackResource* value) { top_resource_ = value; }
  static intptr_t top_resource_offset() {
    return OFFSET_OF(Thread, top_resource_);
  }

  // Heap of the isolate that this thread is operating on.
  Heap* heap() const { return heap_; }
  static intptr_t heap_offset() { return OFFSET_OF(Thread, heap_); }

  void set_top(uword value) {
    ASSERT(heap_ != NULL);
    top_ = value;
  }
  void set_end(uword value) {
    ASSERT(heap_ != NULL);
    end_ = value;
  }

  uword top() { return top_; }
  uword end() { return end_; }

  static intptr_t top_offset() { return OFFSET_OF(Thread, top_); }
  static intptr_t end_offset() { return OFFSET_OF(Thread, end_); }

  int32_t no_handle_scope_depth() const {
#if defined(DEBUG)
    return no_handle_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ < INT_MAX);
    no_handle_scope_depth_ += 1;
#endif
  }

  void DecrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ > 0);
    no_handle_scope_depth_ -= 1;
#endif
  }

  HandleScope* top_handle_scope() const {
#if defined(DEBUG)
    return top_handle_scope_;
#else
    return 0;
#endif
  }

  void set_top_handle_scope(HandleScope* handle_scope) {
#if defined(DEBUG)
    top_handle_scope_ = handle_scope;
#endif
  }

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
  static bool ObjectAtOffset(intptr_t offset, Object* object);
  static intptr_t OffsetFromThread(const RuntimeEntry* runtime_entry);

  static const intptr_t kNoDeoptId = -1;
  static const intptr_t kDeoptIdStep = 2;
  static const intptr_t kDeoptIdBeforeOffset = 0;
  static const intptr_t kDeoptIdAfterOffset = 1;
  intptr_t deopt_id() const { return deopt_id_; }
  void set_deopt_id(int value) {
    ASSERT(value >= 0);
    deopt_id_ = value;
  }
  intptr_t GetNextDeoptId() {
    ASSERT(deopt_id_ != kNoDeoptId);
    const intptr_t id = deopt_id_;
    deopt_id_ += kDeoptIdStep;
    return id;
  }

  static intptr_t ToDeoptAfter(intptr_t deopt_id) {
    ASSERT(IsDeoptBefore(deopt_id));
    return deopt_id + kDeoptIdAfterOffset;
  }

  static bool IsDeoptBefore(intptr_t deopt_id) {
    return (deopt_id % kDeoptIdStep) == kDeoptIdBeforeOffset;
  }

  static bool IsDeoptAfter(intptr_t deopt_id) {
    return (deopt_id % kDeoptIdStep) == kDeoptIdAfterOffset;
  }

  LongJumpScope* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJumpScope* value) { long_jump_base_ = value; }

  uword vm_tag() const { return vm_tag_; }
  void set_vm_tag(uword tag) { vm_tag_ = tag; }
  static intptr_t vm_tag_offset() { return OFFSET_OF(Thread, vm_tag_); }

  RawGrowableObjectArray* pending_functions();
  void clear_pending_functions();

  RawObject* active_exception() const { return active_exception_; }
  void set_active_exception(const Object& value);
  static intptr_t active_exception_offset() {
    return OFFSET_OF(Thread, active_exception_);
  }

  RawObject* active_stacktrace() const { return active_stacktrace_; }
  void set_active_stacktrace(const Object& value);
  static intptr_t active_stacktrace_offset() {
    return OFFSET_OF(Thread, active_stacktrace_);
  }

  uword resume_pc() const { return resume_pc_; }
  void set_resume_pc(uword value) { resume_pc_ = value; }
  static uword resume_pc_offset() { return OFFSET_OF(Thread, resume_pc_); }

  RawError* sticky_error() const;
  void set_sticky_error(const Error& value);
  void clear_sticky_error();
  RawError* get_and_clear_sticky_error();

  RawStackTrace* async_stack_trace() const;
  void set_async_stack_trace(const StackTrace& stack_trace);
  void set_raw_async_stack_trace(RawStackTrace* raw_stack_trace);
  void clear_async_stack_trace();
  static intptr_t async_stack_trace_offset() {
    return OFFSET_OF(Thread, async_stack_trace_);
  }

  CompilerStats* compiler_stats() { return compiler_stats_; }

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
  static intptr_t safepoint_state_offset() {
    return OFFSET_OF(Thread, safepoint_state_);
  }
  static bool IsAtSafepoint(uint32_t state) {
    return AtSafepointField::decode(state);
  }
  bool IsAtSafepoint() const {
    return AtSafepointField::decode(safepoint_state_);
  }
  static uint32_t SetAtSafepoint(bool value, uint32_t state) {
    return AtSafepointField::update(value, state);
  }
  void SetAtSafepoint(bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    safepoint_state_ = AtSafepointField::update(value, safepoint_state_);
  }
  bool IsSafepointRequested() const {
    return SafepointRequestedField::decode(safepoint_state_);
  }
  static uint32_t SetSafepointRequested(bool value, uint32_t state) {
    return SafepointRequestedField::update(value, state);
  }
  uint32_t SetSafepointRequested(bool value) {
    ASSERT(thread_lock()->IsOwnedByCurrentThread());
    uint32_t old_state;
    uint32_t new_state;
    do {
      old_state = safepoint_state_;
      new_state = SafepointRequestedField::update(value, old_state);
    } while (AtomicOperations::CompareAndSwapUint32(
                 &safepoint_state_, old_state, new_state) != old_state);
    return old_state;
  }
  static bool IsBlockedForSafepoint(uint32_t state) {
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

  enum ExecutionState {
    kThreadInVM = 0,
    kThreadInGenerated,
    kThreadInNative,
    kThreadInBlockedState
  };

  ExecutionState execution_state() const {
    return static_cast<ExecutionState>(execution_state_);
  }
  void set_execution_state(ExecutionState state) {
    execution_state_ = static_cast<uint32_t>(state);
  }
  static intptr_t execution_state_offset() {
    return OFFSET_OF(Thread, execution_state_);
  }

  void EnterSafepoint() {
    // First try a fast update of the thread state to indicate it is at a
    // safepoint.
    uint32_t new_state = SetAtSafepoint(true, 0);
    uword addr = reinterpret_cast<uword>(this) + safepoint_state_offset();
    if (AtomicOperations::CompareAndSwapUint32(
            reinterpret_cast<uint32_t*>(addr), 0, new_state) != 0) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation.
      EnterSafepointUsingLock();
    }
  }

  void ExitSafepoint() {
    // First try a fast update of the thread state to indicate it is not at a
    // safepoint anymore.
    uint32_t old_state = SetAtSafepoint(true, 0);
    uword addr = reinterpret_cast<uword>(this) + safepoint_state_offset();
    if (AtomicOperations::CompareAndSwapUint32(
            reinterpret_cast<uint32_t*>(addr), old_state, 0) != old_state) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation.
      ExitSafepointUsingLock();
    }
  }

  void CheckForSafepoint() {
    if (IsSafepointRequested()) {
      BlockForSafepoint();
    }
  }

  Thread* next() const { return next_; }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor, bool validate_frames);

  bool IsValidHandle(Dart_Handle object) const;
  bool IsValidLocalHandle(Dart_Handle object) const;
  intptr_t CountLocalHandles() const;
  bool IsValidZoneHandle(Dart_Handle object) const;
  intptr_t CountZoneHandles() const;
  bool IsValidScopedHandle(Dart_Handle object) const;
  intptr_t CountScopedHandles() const;
  int ZoneSizeInBytes() const;
  void UnwindScopes(uword stack_marker);

  void InitVMConstants();

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream) const;
#endif

 private:
  template <class T>
  T* AllocateReusableHandle();

  // Accessed from generated code.
  // ** This block of fields must come first! **
  // For AOT cross-compilation, we rely on these members having the same offsets
  // in SIMARM(IA32) and ARM, and the same offsets in SIMARM64(X64) and ARM64.
  // We use only word-sized fields to avoid differences in struct packing on the
  // different architectures. See also CheckOffsets in dart.cc.
  uword stack_limit_;
  uword stack_overflow_flags_;
  Isolate* isolate_;
  Heap* heap_;
  uword top_;
  uword end_;
  uword top_exit_frame_info_;
  StoreBufferBlock* store_buffer_block_;
  uword vm_tag_;
  TaskKind task_kind_;
  RawStackTrace* async_stack_trace_;
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

  TimelineStream* dart_stream_;
  OSThread* os_thread_;
  Monitor* thread_lock_;
  Zone* zone_;
  uintptr_t current_zone_capacity_;
  uintptr_t zone_high_watermark_;
  ApiLocalScope* api_reusable_scope_;
  ApiLocalScope* api_top_scope_;
  StackResource* top_resource_;
  LongJumpScope* long_jump_base_;
  int32_t no_callback_scope_depth_;
#if defined(DEBUG)
  HandleScope* top_handle_scope_;
  int32_t no_handle_scope_depth_;
  int32_t no_safepoint_scope_depth_;
#endif
  VMHandles reusable_handles_;
  uword saved_stack_limit_;
  intptr_t defer_oob_messages_count_;
  uint16_t deferred_interrupts_mask_;
  uint16_t deferred_interrupts_;
  int32_t stack_overflow_count_;

  // Compiler state:
  CHA* cha_;
  intptr_t deopt_id_;  // Compilation specific counter.
  RawGrowableObjectArray* pending_functions_;

  // JumpToExceptionHandler state:
  RawObject* active_exception_;
  RawObject* active_stacktrace_;
  uword resume_pc_;

  RawError* sticky_error_;

  CompilerStats* compiler_stats_;

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

  class AtSafepointField : public BitField<uint32_t, bool, 0, 1> {};
  class SafepointRequestedField : public BitField<uint32_t, bool, 1, 1> {};
  class BlockedForSafepointField : public BitField<uint32_t, bool, 2, 1> {};
  uint32_t safepoint_state_;
  uint32_t execution_state_;

  Thread* next_;  // Used to chain the thread structures in an isolate.

  explicit Thread(Isolate* isolate);

  void StoreBufferRelease(
      StoreBuffer::ThresholdPolicy policy = StoreBuffer::kCheckThreshold);
  void StoreBufferAcquire();

  void set_zone(Zone* zone) { zone_ = zone; }

  void set_safepoint_state(uint32_t value) { safepoint_state_ = value; }
  void EnterSafepointUsingLock();
  void ExitSafepointUsingLock();
  void BlockForSafepoint();

  static void SetCurrent(Thread* current) {
    OSThread::SetCurrentTLS(reinterpret_cast<uword>(current));
  }

  void DeferOOBMessageInterrupts();
  void RestoreOOBMessageInterrupts();

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
  REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class ApiZone;
  friend class InterruptChecker;
  friend class Isolate;
  friend class IsolateTestHelper;
  friend class NoOOBMessageScope;
  friend class Simulator;
  friend class StackZone;
  friend class ThreadRegistry;
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

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_H_
