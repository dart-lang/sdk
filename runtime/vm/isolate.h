// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_H_
#define VM_ISOLATE_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/thread.h"
#include "vm/base_isolate.h"
#include "vm/class_table.h"
#include "vm/counters.h"
#include "vm/handles.h"
#include "vm/megamorphic_cache_table.h"
#include "vm/random.h"
#include "vm/store_buffer.h"
#include "vm/tags.h"
#include "vm/trace_buffer.h"
#include "vm/timer.h"

namespace dart {

// Forward declarations.
class AbstractType;
class ApiState;
class Array;
class Class;
class Code;
class CodeIndexTable;
class Debugger;
class DeoptContext;
class Error;
class Field;
class Function;
class GrowableObjectArray;
class HandleScope;
class HandleVisitor;
class Heap;
class ICData;
class Instance;
class IsolateProfilerData;
class IsolateSpawnState;
class InterruptableThreadState;
class Library;
class LongJumpScope;
class MessageHandler;
class Mutex;
class Object;
class ObjectIdRing;
class ObjectPointerVisitor;
class ObjectStore;
class RawInstance;
class RawArray;
class RawContext;
class RawDouble;
class RawGrowableObjectArray;
class RawMint;
class RawObject;
class RawInteger;
class RawError;
class RawFloat32x4;
class RawInt32x4;
class RawUserTag;
class SampleBuffer;
class Simulator;
class StackResource;
class StackZone;
class StubCode;
class TypeArguments;
class TypeParameter;
class UserTag;


class IsolateVisitor {
 public:
  IsolateVisitor() {}
  virtual ~IsolateVisitor() {}

  virtual void VisitIsolate(Isolate* isolate) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateVisitor);
};

#define REUSABLE_HANDLE_LIST(V)                                                \
  V(AbstractType)                                                              \
  V(Array)                                                                     \
  V(Class)                                                                     \
  V(Code)                                                                      \
  V(Error)                                                                     \
  V(Field)                                                                     \
  V(Function)                                                                  \
  V(GrowableObjectArray)                                                       \
  V(Instance)                                                                  \
  V(Library)                                                                   \
  V(Object)                                                                    \
  V(String)                                                                    \
  V(TypeArguments)                                                             \
  V(TypeParameter)                                                             \

class Isolate : public BaseIsolate {
 public:
  ~Isolate();

  static inline Isolate* Current() {
    return reinterpret_cast<Isolate*>(Thread::GetThreadLocal(isolate_key));
  }

  static void SetCurrent(Isolate* isolate);

  static void InitOnce();
  static Isolate* Init(const char* name_prefix);
  void Shutdown();

  // Register a newly introduced class.
  void RegisterClass(const Class& cls);
  void RegisterClassAt(intptr_t index, const Class& cls);
  void ValidateClassTable();

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           bool visit_prologue_weak_persistent_handles,
                           bool validate_frames);

  // Visits weak object pointers.
  void VisitWeakPersistentHandles(HandleVisitor* visitor,
                                  bool visit_prologue_weak_persistent_handles);
  void VisitPrologueWeakPersistentHandles(HandleVisitor* visitor);

  StoreBuffer* store_buffer() { return &store_buffer_; }
  static intptr_t store_buffer_offset() {
    return OFFSET_OF(Isolate, store_buffer_);
  }

  ClassTable* class_table() { return &class_table_; }
  static intptr_t class_table_offset() {
    return OFFSET_OF(Isolate, class_table_);
  }

  bool cha_used() const { return cha_used_; }
  void set_cha_used(bool value) { cha_used_ = value; }

  MegamorphicCacheTable* megamorphic_cache_table() {
    return &megamorphic_cache_table_;
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }
  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  const char* name() const { return name_; }

  int64_t start_time() const { return start_time_; }

  Dart_Port main_port() const { return main_port_; }
  void set_main_port(Dart_Port port) {
    ASSERT(main_port_ == 0);  // Only set main port once.
    main_port_ = port;
  }

  Heap* heap() const { return heap_; }
  void set_heap(Heap* value) { heap_ = value; }
  static intptr_t heap_offset() { return OFFSET_OF(Isolate, heap_); }

  ObjectStore* object_store() const { return object_store_; }
  void set_object_store(ObjectStore* value) { object_store_ = value; }
  static intptr_t object_store_offset() {
    return OFFSET_OF(Isolate, object_store_);
  }

  RawContext* top_context() const { return top_context_; }
  void set_top_context(RawContext* value) { top_context_ = value; }
  static intptr_t top_context_offset() {
    return OFFSET_OF(Isolate, top_context_);
  }

  uword top_exit_frame_info() const { return top_exit_frame_info_; }
  void set_top_exit_frame_info(uword value) { top_exit_frame_info_ = value; }
  static intptr_t top_exit_frame_info_offset() {
    return OFFSET_OF(Isolate, top_exit_frame_info_);
  }

  static intptr_t vm_tag_offset() {
    return OFFSET_OF(Isolate, vm_tag_);
  }

  ApiState* api_state() const { return api_state_; }
  void set_api_state(ApiState* value) { api_state_ = value; }

  StubCode* stub_code() const { return stub_code_; }
  void set_stub_code(StubCode* value) { stub_code_ = value; }

  LongJumpScope* long_jump_base() const { return long_jump_base_; }
  void set_long_jump_base(LongJumpScope* value) { long_jump_base_ = value; }

  TimerList& timer_list() { return timer_list_; }

  static intptr_t current_zone_offset() {
    return OFFSET_OF(Isolate, current_zone_);
  }

  void set_init_callback_data(void* value) {
    init_callback_data_ = value;
  }
  void* init_callback_data() const {
    return init_callback_data_;
  }

  Dart_EnvironmentCallback environment_callback() const {
    return environment_callback_;
  }
  void set_environment_callback(Dart_EnvironmentCallback value) {
    environment_callback_ = value;
  }

  Dart_LibraryTagHandler library_tag_handler() const {
    return library_tag_handler_;
  }
  void set_library_tag_handler(Dart_LibraryTagHandler value) {
    library_tag_handler_ = value;
  }

  void SetStackLimit(uword value);
  void SetStackLimitFromCurrentTOS(uword isolate_stack_top);

  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }

  // The current stack limit.  This may be overwritten with a special
  // value to trigger interrupts.
  uword stack_limit() const { return stack_limit_; }
  static intptr_t stack_limit_offset() {
    return OFFSET_OF(Isolate, stack_limit_);
  }

  // The true stack limit for this isolate.
  uword saved_stack_limit() const { return saved_stack_limit_; }

  // Stack overflow flags
  enum {
    kOsrRequest = 0x1,  // Current stack overflow caused by OSR request.
  };

  uword stack_overflow_flags_address() const {
    return reinterpret_cast<uword>(&stack_overflow_flags_);
  }

  int32_t IncrementAndGetStackOverflowCount() {
    return ++stack_overflow_count_;
  }

  // Retrieves and clears the stack overflow flags.  These are set by
  // the generated code before the slow path runtime routine for a
  // stack overflow is called.
  uword GetAndClearStackOverflowFlags();

  // Retrieve the stack address bounds.
  bool GetStackBounds(uword* lower, uword* upper);

  static uword GetSpecifiedStackSize();

  static const intptr_t kStackSizeBuffer = (4 * KB * kWordSize);

  // Interrupt bits.
  enum {
    kApiInterrupt = 0x1,      // An interrupt from Dart_InterruptIsolate.
    kMessageInterrupt = 0x2,  // An interrupt to process an out of band message.
    kStoreBufferInterrupt = 0x4,  // An interrupt to process the store buffer.
    kVmStatusInterrupt = 0x8,     // An interrupt to process a status request.

    kInterruptsMask =
        kApiInterrupt |
        kMessageInterrupt |
        kStoreBufferInterrupt |
        kVmStatusInterrupt,
  };

  void ScheduleInterrupts(uword interrupt_bits);
  uword GetAndClearInterrupts();

  bool MakeRunnable();
  void Run();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  bool is_runnable() const { return is_runnable_; }
  void set_is_runnable(bool value) { is_runnable_ = value; }

  IsolateSpawnState* spawn_state() const { return spawn_state_; }
  void set_spawn_state(IsolateSpawnState* value) { spawn_state_ = value; }

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

  Mutex* mutex() const { return mutex_; }

  Debugger* debugger() const { return debugger_; }

  void set_single_step(bool value) { single_step_ = value; }
  bool single_step() const { return single_step_; }
  static intptr_t single_step_offset() {
    return OFFSET_OF(Isolate, single_step_);
  }

  // Requests that the debugger resume execution.
  void Resume() {
    resume_request_ = true;
  }

  // Returns whether the vm service has requested that the debugger
  // resume execution.
  bool GetAndClearResumeRequest() {
    bool resume_request = resume_request_;
    resume_request_ = false;
    return resume_request;
  }

  Random* random() { return &random_; }

  Simulator* simulator() const { return simulator_; }
  void set_simulator(Simulator* value) { simulator_ = value; }

  Dart_GcPrologueCallback gc_prologue_callback() const {
    return gc_prologue_callback_;
  }

  void set_gc_prologue_callback(Dart_GcPrologueCallback callback) {
    gc_prologue_callback_ = callback;
  }

  Dart_GcEpilogueCallback gc_epilogue_callback() const {
    return gc_epilogue_callback_;
  }

  void set_gc_epilogue_callback(Dart_GcEpilogueCallback callback) {
    gc_epilogue_callback_ = callback;
  }

  static void SetCreateCallback(Dart_IsolateCreateCallback cb) {
    create_callback_ = cb;
  }
  static Dart_IsolateCreateCallback CreateCallback() {
    return create_callback_;
  }

  static void SetServiceCreateCallback(Dart_ServiceIsolateCreateCalback cb) {
    service_create_callback_ = cb;
  }
  static Dart_ServiceIsolateCreateCalback ServiceCreateCallback() {
    return service_create_callback_;
  }

  static void SetInterruptCallback(Dart_IsolateInterruptCallback cb) {
    interrupt_callback_ = cb;
  }
  static Dart_IsolateInterruptCallback InterruptCallback() {
    return interrupt_callback_;
  }

  static void SetVmStatsCallback(Dart_IsolateInterruptCallback cb) {
    vmstats_callback_ = cb;
  }
  static Dart_IsolateInterruptCallback VmStatsCallback() {
    return vmstats_callback_;
  }

  static void SetUnhandledExceptionCallback(
      Dart_IsolateUnhandledExceptionCallback cb) {
    unhandled_exception_callback_ = cb;
  }
  static Dart_IsolateUnhandledExceptionCallback UnhandledExceptionCallback() {
    return unhandled_exception_callback_;
  }

  static void SetShutdownCallback(Dart_IsolateShutdownCallback cb) {
    shutdown_callback_ = cb;
  }
  static Dart_IsolateShutdownCallback ShutdownCallback() {
    return shutdown_callback_;
  }

  static void SetFileCallbacks(Dart_FileOpenCallback file_open,
                               Dart_FileReadCallback file_read,
                               Dart_FileWriteCallback file_write,
                               Dart_FileCloseCallback file_close) {
    file_open_callback_ = file_open;
    file_read_callback_ = file_read;
    file_write_callback_ = file_write;
    file_close_callback_ = file_close;
  }

  static Dart_FileOpenCallback file_open_callback() {
    return file_open_callback_;
  }
  static Dart_FileReadCallback file_read_callback() {
    return file_read_callback_;
  }
  static Dart_FileWriteCallback file_write_callback() {
    return file_write_callback_;
  }
  static Dart_FileCloseCallback file_close_callback() {
    return file_close_callback_;
  }

  static void SetEntropySourceCallback(Dart_EntropySource entropy_source) {
    entropy_source_callback_ = entropy_source;
  }
  static Dart_EntropySource entropy_source_callback() {
    return entropy_source_callback_;
  }

  void set_object_id_ring(ObjectIdRing* ring) {
    object_id_ring_ = ring;
  }
  ObjectIdRing* object_id_ring() {
    return object_id_ring_;
  }

  void set_trace_buffer(TraceBuffer* buffer) {
    trace_buffer_ = buffer;
  }
  TraceBuffer* trace_buffer() {
    return trace_buffer_;
  }

  DeoptContext* deopt_context() const { return deopt_context_; }
  void set_deopt_context(DeoptContext* value) {
    ASSERT(value == NULL || deopt_context_ == NULL);
    deopt_context_ = value;
  }

  intptr_t BlockClassFinalization() {
    ASSERT(defer_finalization_count_ >= 0);
    return defer_finalization_count_++;
  }

  intptr_t UnblockClassFinalization() {
    ASSERT(defer_finalization_count_ > 0);
    return defer_finalization_count_--;
  }

  bool AllowClassFinalization() {
    ASSERT(defer_finalization_count_ >= 0);
    return defer_finalization_count_ == 0;
  }

  Mutex* profiler_data_mutex() {
    return &profiler_data_mutex_;
  }

  void set_profiler_data(IsolateProfilerData* profiler_data) {
    profiler_data_ = profiler_data;
  }

  IsolateProfilerData* profiler_data() const {
    return profiler_data_;
  }

  void PrintJSON(JSONStream* stream, bool ref = true);

  void set_thread_state(InterruptableThreadState* state) {
    ASSERT((thread_state_ == NULL) || (state == NULL));
    thread_state_ = state;
  }

  InterruptableThreadState* thread_state() const {
    return thread_state_;
  }

  // Returns the number of sampled threads.
  intptr_t ProfileInterrupt();

  VMTagCounters* vm_tag_counters() {
    return &vm_tag_counters_;
  }

  uword user_tag() const {
    return user_tag_;
  }
  static intptr_t user_tag_offset() {
    return OFFSET_OF(Isolate, user_tag_);
  }
  static intptr_t current_tag_offset() {
    return OFFSET_OF(Isolate, current_tag_);
  }

  RawGrowableObjectArray* tag_table() const { return tag_table_; }
  void set_tag_table(const GrowableObjectArray& value);

  RawUserTag* current_tag() const { return current_tag_; }
  void set_current_tag(const UserTag& tag);

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
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE(object)                                                \
  object& object##Handle() const {                                             \
    return *object##_handle_;                                                  \
  }
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE)
#undef REUSABLE_HANDLE

  static void VisitIsolates(IsolateVisitor* visitor);

  Counters* counters() { return &counters_; }

 private:
  Isolate();

  void BuildName(const char* name_prefix);
  void PrintInvokedFunctions();

  void ProfileIdle();

  void set_user_tag(uword tag) {
    user_tag_ = tag;
  }


  template<class T> T* AllocateReusableHandle();

  static ThreadLocalKey isolate_key;

  StoreBuffer store_buffer_;
  ClassTable class_table_;
  MegamorphicCacheTable megamorphic_cache_table_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
  int64_t start_time_;
  Dart_Port main_port_;
  Heap* heap_;
  ObjectStore* object_store_;
  RawContext* top_context_;
  uword top_exit_frame_info_;
  void* init_callback_data_;
  Dart_EnvironmentCallback environment_callback_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  StubCode* stub_code_;
  Debugger* debugger_;
  bool single_step_;
  bool resume_request_;
  Random random_;
  Simulator* simulator_;
  LongJumpScope* long_jump_base_;
  TimerList timer_list_;
  intptr_t deopt_id_;
  Mutex* mutex_;  // protects stack_limit_ and saved_stack_limit_.
  uword stack_limit_;
  uword saved_stack_limit_;
  uword stack_overflow_flags_;
  int32_t stack_overflow_count_;
  MessageHandler* message_handler_;
  IsolateSpawnState* spawn_state_;
  bool is_runnable_;
  Dart_GcPrologueCallback gc_prologue_callback_;
  Dart_GcEpilogueCallback gc_epilogue_callback_;
  intptr_t defer_finalization_count_;
  DeoptContext* deopt_context_;

  // Status support.
  char* stacktrace_;
  intptr_t stack_frame_index_;

  bool cha_used_;

  // Ring buffer of objects assigned an id.
  ObjectIdRing* object_id_ring_;

  // Trace buffer support.
  TraceBuffer* trace_buffer_;

  IsolateProfilerData* profiler_data_;
  Mutex profiler_data_mutex_;
  InterruptableThreadState* thread_state_;

  VMTagCounters vm_tag_counters_;
  uword user_tag_;
  RawGrowableObjectArray* tag_table_;
  RawUserTag* current_tag_;

  Counters counters_;

  // Isolate list next pointer.
  Isolate* next_;

  // Reusable handles support.
#define REUSABLE_HANDLE_FIELDS(object)                                         \
  object* object##_handle_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_FIELDS)
#undef REUSABLE_HANDLE_FIELDS

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_VARIABLE(object)                                 \
  bool reusable_##object##_handle_scope_active_;
  REUSABLE_HANDLE_LIST(REUSABLE_HANDLE_SCOPE_VARIABLE);
#undef REUSABLE_HANDLE_SCOPE_VARIABLE
#endif  // defined(DEBUG)

  VMHandles reusable_handles_;

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateInterruptCallback interrupt_callback_;
  static Dart_IsolateUnhandledExceptionCallback unhandled_exception_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;
  static Dart_FileOpenCallback file_open_callback_;
  static Dart_FileReadCallback file_read_callback_;
  static Dart_FileWriteCallback file_write_callback_;
  static Dart_FileCloseCallback file_close_callback_;
  static Dart_EntropySource entropy_source_callback_;
  static Dart_IsolateInterruptCallback vmstats_callback_;
  static Dart_ServiceIsolateCreateCalback service_create_callback_;

  // Manage list of existing isolates.
  static void AddIsolateTolist(Isolate* isolate);
  static void RemoveIsolateFromList(Isolate* isolate);
  static void CheckForDuplicateThreadState(InterruptableThreadState* state);
  static Monitor* isolates_list_monitor_;
  static Isolate* isolates_list_head_;

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  DISALLOW_COPY_AND_ASSIGN(Isolate);
};


// When we need to execute code in an isolate, we use the
// StartIsolateScope.
class StartIsolateScope {
 public:
  explicit StartIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate), saved_isolate_(Isolate::Current()) {
    ASSERT(new_isolate_ != NULL);
    if (saved_isolate_ != new_isolate_) {
      ASSERT(Isolate::Current() == NULL);
      Isolate::SetCurrent(new_isolate_);
      new_isolate_->SetStackLimitFromCurrentTOS(reinterpret_cast<uword>(this));
    }
  }

  ~StartIsolateScope() {
    if (saved_isolate_ != new_isolate_) {
      new_isolate_->SetStackLimit(~static_cast<uword>(0));
      Isolate::SetCurrent(saved_isolate_);
    }
  }

 private:
  Isolate* new_isolate_;
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(StartIsolateScope);
};

// When we need to temporarily become another isolate, we use the
// SwitchIsolateScope.  It is not permitted to run dart code while in
// a SwitchIsolateScope.
class SwitchIsolateScope {
 public:
  explicit SwitchIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate),
        saved_isolate_(Isolate::Current()),
        saved_stack_limit_(saved_isolate_
                           ? saved_isolate_->saved_stack_limit() : 0) {
    if (saved_isolate_ != new_isolate_) {
      Isolate::SetCurrent(new_isolate_);
      if (new_isolate_ != NULL) {
        // Don't allow dart code to execute.
        new_isolate_->SetStackLimit(~static_cast<uword>(0));
      }
    }
  }

  ~SwitchIsolateScope() {
    if (saved_isolate_ != new_isolate_) {
      Isolate::SetCurrent(saved_isolate_);
      if (saved_isolate_ != NULL) {
        saved_isolate_->SetStackLimit(saved_stack_limit_);
      }
    }
  }

 private:
  Isolate* new_isolate_;
  Isolate* saved_isolate_;
  uword saved_stack_limit_;

  DISALLOW_COPY_AND_ASSIGN(SwitchIsolateScope);
};


class IsolateSpawnState {
 public:
  explicit IsolateSpawnState(const Function& func);
  explicit IsolateSpawnState(const char* script_url);
  ~IsolateSpawnState();

  Isolate* isolate() const { return isolate_; }
  void set_isolate(Isolate* value) { isolate_ = value; }
  char* script_url() const { return script_url_; }
  char* library_url() const { return library_url_; }
  char* class_name() const { return class_name_; }
  char* function_name() const { return function_name_; }
  char* exception_callback_name() const { return exception_callback_name_; }
  bool is_spawn_uri() const { return library_url_ == NULL; }

  RawObject* ResolveFunction();
  void Cleanup();

 private:
  Isolate* isolate_;
  char* script_url_;
  char* library_url_;
  char* class_name_;
  char* function_name_;
  char* exception_callback_name_;
};

}  // namespace dart

#endif  // VM_ISOLATE_H_
