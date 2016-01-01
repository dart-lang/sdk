// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ISOLATE_H_
#define VM_ISOLATE_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/atomic.h"
#include "vm/base_isolate.h"
#include "vm/class_table.h"
#include "vm/handles.h"
#include "vm/megamorphic_cache_table.h"
#include "vm/metrics.h"
#include "vm/random.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/os_thread.h"
#include "vm/timeline.h"
#include "vm/timer.h"
#include "vm/trace_buffer.h"

namespace dart {

// Forward declarations.
class ApiState;
class BackgroundCompiler;
class Capability;
class CodeIndexTable;
class CompilerStats;
class Debugger;
class DeoptContext;
class HandleScope;
class HandleVisitor;
class Heap;
class ICData;
class IsolateProfilerData;
class IsolateSpawnState;
class Log;
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
class SendPort;
class ServiceIdZone;
class Simulator;
class StackResource;
class StackZone;
class StoreBuffer;
class StubCode;
class ThreadRegistry;
class UserTag;


class IsolateVisitor {
 public:
  IsolateVisitor() {}
  virtual ~IsolateVisitor() {}

  virtual void VisitIsolate(Isolate* isolate) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateVisitor);
};


class Isolate : public BaseIsolate {
 public:
  // Keep both these enums in sync with isolate_patch.dart.
  // The different Isolate API message types.
  enum LibMsgId {
    kPauseMsg = 1,
    kResumeMsg = 2,
    kPingMsg = 3,
    kKillMsg = 4,
    kAddExitMsg = 5,
    kDelExitMsg = 6,
    kAddErrorMsg = 7,
    kDelErrorMsg = 8,
    kErrorFatalMsg = 9,

    // Internal message ids.
    kInterruptMsg = 10,     // Break in the debugger.
    kInternalKillMsg = 11,  // Like kill, but does not run exit listeners, etc.
    kVMRestartMsg = 12,     // Sent to isolates when vm is restarting.
  };
  // The different Isolate API message priorities for ping and kill messages.
  enum LibMsgPriority {
    kImmediateAction = 0,
    kBeforeNextEventAction = 1,
    kAsEventAction = 2
  };

  ~Isolate();

  static inline Isolate* Current() {
    Thread* thread = Thread::Current();
    return thread == NULL ? NULL : thread->isolate();
  }

  // Register a newly introduced class.
  void RegisterClass(const Class& cls);
  void RegisterClassAt(intptr_t index, const Class& cls);
  void ValidateClassTable();

  // Visit all object pointers.
  void IterateObjectPointers(ObjectPointerVisitor* visitor,
                             bool validate_frames);

  // Visits weak object pointers.
  void VisitWeakPersistentHandles(HandleVisitor* visitor);

  StoreBuffer* store_buffer() { return store_buffer_; }

  ThreadRegistry* thread_registry() { return thread_registry_; }

  ClassTable* class_table() { return &class_table_; }
  static intptr_t class_table_offset() {
    return OFFSET_OF(Isolate, class_table_);
  }

  static intptr_t ic_miss_code_offset() {
    return OFFSET_OF(Isolate, ic_miss_code_);
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }
  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  // Limited public access to BaseIsolate::mutator_thread_ for code that
  // must treat the mutator as the default or a special case. Prefer code
  // that works uniformly across all threads.
  bool HasMutatorThread() {
    return mutator_thread_ != NULL;
  }
  Thread* mutator_thread() const {
    return mutator_thread_;
  }

  const char* name() const { return name_; }
  const char* debugger_name() const { return debugger_name_; }
  void set_debugger_name(const char* name);

  int64_t start_time() const { return start_time_; }

  Dart_Port main_port() const { return main_port_; }
  void set_main_port(Dart_Port port) {
    ASSERT(main_port_ == 0);  // Only set main port once.
    main_port_ = port;
  }
  Dart_Port origin_id() const { return origin_id_; }
  void set_origin_id(Dart_Port id) {
    ASSERT((id == main_port_ && origin_id_ == 0) ||
           (origin_id_ == main_port_));
    origin_id_ = id;
  }
  void set_pause_capability(uint64_t value) { pause_capability_ = value; }
  uint64_t pause_capability() const { return pause_capability_; }
  void set_terminate_capability(uint64_t value) {
    terminate_capability_ = value;
  }
  uint64_t terminate_capability() const { return terminate_capability_; }

  void SendInternalLibMessage(LibMsgId msg_id, uint64_t capability);

  Heap* heap() const { return heap_; }
  void set_heap(Heap* value) { heap_ = value; }
  static intptr_t heap_offset() { return OFFSET_OF(Isolate, heap_); }

  ObjectStore* object_store() const { return object_store_; }
  void set_object_store(ObjectStore* value) { object_store_ = value; }

  ApiState* api_state() const { return api_state_; }
  void set_api_state(ApiState* value) { api_state_ = value; }

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
  void SetStackLimitFromStackBase(uword stack_base);
  void ClearStackLimit();

  // Returns the current C++ stack pointer. Equivalent taking the address of a
  // stack allocated local, but plays well with AddressSanitizer.
  // TODO(koda): Move to Thread.
  static uword GetCurrentStackPointer();

  void SetupInstructionsSnapshotPage(
      const uint8_t* instructions_snapshot_buffer);

  // Returns true if any of the interrupts specified by 'interrupt_bits' are
  // currently scheduled for this isolate, but leaves them unchanged.
  //
  // NOTE: The read uses relaxed memory ordering, i.e., it is atomic and
  // an interrupt is guaranteed to be observed eventually, but any further
  // order guarantees must be ensured by other synchronization. See the
  // tests in isolate_test.cc for example usage.
  bool HasInterruptsScheduled(uword interrupt_bits) {
    ASSERT(interrupt_bits == (interrupt_bits & kInterruptsMask));
    uword limit = AtomicOperations::LoadRelaxed(&stack_limit_);
    return (limit != saved_stack_limit_) &&
        (((limit & kInterruptsMask) & interrupt_bits) != 0);
  }

  // Access to the current stack limit for generated code.  This may be
  // overwritten with a special value to trigger interrupts.
  uword stack_limit_address() const {
    return reinterpret_cast<uword>(&stack_limit_);
  }
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

  // Interrupt bits.
  enum {
    kVMInterrupt = 0x1,  // Internal VM checks: safepoints, store buffers, etc.
    kMessageInterrupt = 0x2,  // An interrupt to process an out of band message.

    kInterruptsMask = (kVMInterrupt | kMessageInterrupt),
  };

  void ScheduleInterrupts(uword interrupt_bits);
  RawError* HandleInterrupts();
  uword GetAndClearInterrupts();

  // Marks all libraries as loaded.
  void DoneLoading();

  bool MakeRunnable();
  void Run();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  bool is_runnable() const { return is_runnable_; }
  void set_is_runnable(bool value) { is_runnable_ = value; }

  IsolateSpawnState* spawn_state() const { return spawn_state_; }
  void set_spawn_state(IsolateSpawnState* value) { spawn_state_ = value; }

  Mutex* mutex() const { return mutex_; }

  Debugger* debugger() const {
    ASSERT(debugger_ != NULL);
    return debugger_;
  }

  void set_single_step(bool value) { single_step_ = value; }
  bool single_step() const { return single_step_; }
  static intptr_t single_step_offset() {
    return OFFSET_OF(Isolate, single_step_);
  }

  void set_has_compiled_code(bool value) { has_compiled_code_ = value; }
  bool has_compiled_code() const { return has_compiled_code_; }

  // TODO(iposva): Evaluate whether two different isolate flag structures are
  // needed. Currently it serves as a separation between publicly visible flags
  // and VM internal flags.
  class Flags : public ValueObject {
   public:
    // Construct default flags as specified by the options.
    Flags();

    bool type_checks() const { return type_checks_; }
    bool asserts() const { return asserts_; }
    bool error_on_bad_type() const { return error_on_bad_type_; }
    bool error_on_bad_override() const { return error_on_bad_override_; }

    void set_checked(bool val) {
      type_checks_ = val;
      asserts_ = val;
    }

    void CopyFrom(const Flags& orig);
    void CopyFrom(const Dart_IsolateFlags& api_flags);
    void CopyTo(Dart_IsolateFlags* api_flags) const;

   private:
    bool type_checks_;
    bool asserts_;
    bool error_on_bad_type_;
    bool error_on_bad_override_;

    friend class Isolate;

    DISALLOW_ALLOCATION();
    DISALLOW_COPY_AND_ASSIGN(Flags);
  };

  const Flags& flags() const { return flags_; }

  // Set the checks in the compiler to the highest level. Statically and when
  // executing generated code. Needs to be called before any code has been
  // compiled.
  void set_strict_compilation() {
    ASSERT(!has_compiled_code());
    flags_.type_checks_ = true;
    flags_.asserts_ = true;
    flags_.error_on_bad_type_ = true;
    flags_.error_on_bad_override_ = true;
  }

  // Requests that the debugger resume execution.
  void Resume() {
    resume_request_ = true;
    set_last_resume_timestamp();
  }

  void set_last_resume_timestamp() {
    last_resume_timestamp_ = OS::GetCurrentTimeMillis();
  }

  int64_t last_resume_timestamp() const {
    return last_resume_timestamp_;
  }

  // Returns whether the vm service has requested that the debugger
  // resume execution.
  bool GetAndClearResumeRequest() {
    bool resume_request = resume_request_;
    resume_request_ = false;
    return resume_request;
  }

  // Verify that the sender has the capability to pause or terminate the
  // isolate.
  bool VerifyPauseCapability(const Object& capability) const;
  bool VerifyTerminateCapability(const Object& capability) const;

  // Returns true if the capability was added or removed from this isolate's
  // list of pause events.
  bool AddResumeCapability(const Capability& capability);
  bool RemoveResumeCapability(const Capability& capability);

  void AddExitListener(const SendPort& listener, const Instance& response);
  void RemoveExitListener(const SendPort& listener);
  void NotifyExitListeners();

  void AddErrorListener(const SendPort& listener);
  void RemoveErrorListener(const SendPort& listener);
  bool NotifyErrorListeners(const String& msg, const String& stacktrace);

  bool ErrorsFatal() const { return errors_fatal_; }
  void SetErrorsFatal(bool val) { errors_fatal_ = val; }

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

  BackgroundCompiler* background_compiler() const {
    return background_compiler_;
  }
  void set_background_compiler(BackgroundCompiler* value) {
    background_compiler_ = value;
  }

  void UpdateLastAllocationProfileAccumulatorResetTimestamp() {
    last_allocationprofile_accumulator_reset_timestamp_ =
        OS::GetCurrentTimeMillis();
  }

  int64_t last_allocationprofile_accumulator_reset_timestamp() const {
    return last_allocationprofile_accumulator_reset_timestamp_;
  }

  void UpdateLastAllocationProfileGCTimestamp() {
    last_allocationprofile_gc_timestamp_ = OS::GetCurrentTimeMillis();
  }

  int64_t last_allocationprofile_gc_timestamp() const {
    return last_allocationprofile_gc_timestamp_;
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

  void PrintJSON(JSONStream* stream, bool ref = true);

  CompilerStats* compiler_stats() {
    return compiler_stats_;
  }

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
  static intptr_t default_tag_offset() {
    return OFFSET_OF(Isolate, default_tag_);
  }

#define ISOLATE_METRIC_ACCESSOR(type, variable, name, unit)                    \
  type* Get##variable##Metric() { return &metric_##variable##_; }
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_ACCESSOR);
#undef ISOLATE_METRIC_ACCESSOR

#define ISOLATE_TIMELINE_STREAM_ACCESSOR(name, not_used)                       \
  TimelineStream* Get##name##Stream() { return &stream_##name##_; }
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_ACCESSOR)
#undef ISOLATE_TIMELINE_STREAM_ACCESSOR

  static intptr_t IsolateListLength();

  RawGrowableObjectArray* tag_table() const { return tag_table_; }
  void set_tag_table(const GrowableObjectArray& value);

  RawUserTag* current_tag() const { return current_tag_; }
  void set_current_tag(const UserTag& tag);

  RawUserTag* default_tag() const { return default_tag_; }
  void set_default_tag(const UserTag& tag);

  void set_ic_miss_code(const Code& code);

  Metric* metrics_list_head() {
    return metrics_list_head_;
  }

  void set_metrics_list_head(Metric* metric) {
    metrics_list_head_ = metric;
  }

  RawGrowableObjectArray* deoptimized_code_array() const {
    return deoptimized_code_array_;
  }
  void set_deoptimized_code_array(const GrowableObjectArray& value);
  void TrackDeoptimizedCode(const Code& code);

  bool compilation_allowed() const { return compilation_allowed_; }
  void set_compilation_allowed(bool allowed) {
    compilation_allowed_ = allowed;
  }

  // In precompilation we finalize all regular classes before compiling.
  bool all_classes_finalized() const { return all_classes_finalized_; }
  void set_all_classes_finalized(bool value) {
    all_classes_finalized_ = value;
  }

  static const uint32_t kInvalidGen = 0;

  void IncrCHAInvalidationGen() {
    cha_invalidation_gen_++;
    if (cha_invalidation_gen_ == kInvalidGen) cha_invalidation_gen_++;
  }
  void ResetCHAInvalidationGen() { cha_invalidation_gen_ = kInvalidGen; }
  uint32_t cha_invalidation_gen() const { return cha_invalidation_gen_; }


  void IncrFieldInvalidationGen() {
    field_invalidation_gen_++;
    if (field_invalidation_gen_ == kInvalidGen) field_invalidation_gen_++;
  }

  void ResetFieldInvalidationGen() { field_invalidation_gen_ = kInvalidGen; }
  uint32_t field_invalidation_gen() const { return field_invalidation_gen_; }

  void IncrPrefixInvalidationGen() {
    prefix_invalidation_gen_++;
    if (prefix_invalidation_gen_ == kInvalidGen) prefix_invalidation_gen_++;
  }
  void ResetPrefixInvalidationGen() { prefix_invalidation_gen_ = kInvalidGen; }
  uint32_t prefix_invalidation_gen() const { return prefix_invalidation_gen_; }

  RawObject* InvokePendingServiceExtensionCalls();
  void AppendServiceExtensionCall(const Instance& closure,
                           const String& method_name,
                           const Array& parameter_keys,
                           const Array& parameter_values,
                           const Instance& reply_port,
                           const Instance& id);
  void RegisterServiceExtensionHandler(const String& name,
                                       const Instance& closure);
  RawInstance* LookupServiceExtensionHandler(const String& name);

  static void VisitIsolates(IsolateVisitor* visitor);

  // Handle service messages until we are told to resume execution.
  void PauseEventHandler();

  void AddClosureFunction(const Function& function) const;
  RawFunction* LookupClosureFunction(const Function& parent,
                                     intptr_t token_pos) const;
  intptr_t FindClosureIndex(const Function& needle) const;
  RawFunction* ClosureFunctionFromIndex(intptr_t idx) const;

  bool is_service_isolate() const { return is_service_isolate_; }

  static void KillAllIsolates(LibMsgId msg_id);
  static void KillIfExists(Isolate* isolate, LibMsgId msg_id);

  static void DisableIsolateCreation();
  static void EnableIsolateCreation();

 private:
  friend class Dart;  // Init, InitOnce, Shutdown.
  friend class IsolateKillerVisitor;  // Kill().

  explicit Isolate(const Dart_IsolateFlags& api_flags);

  static void InitOnce();
  static Isolate* Init(const char* name_prefix,
                       const Dart_IsolateFlags& api_flags,
                       bool is_vm_isolate = false);

  // The isolates_list_monitor_ should be held when calling Kill().
  void KillLocked(LibMsgId msg_id);

  void LowLevelShutdown();
  void Shutdown();

  void BuildName(const char* name_prefix);

  void ProfileIdle();

  // Visit all object pointers. Caller must ensure concurrent sweeper is not
  // running, and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor, bool validate_frames);

  void set_user_tag(uword tag) {
    user_tag_ = tag;
  }

  RawGrowableObjectArray* GetAndClearPendingServiceExtensionCalls();
  RawGrowableObjectArray* pending_service_extension_calls() const {
    return pending_service_extension_calls_;
  }
  void set_pending_service_extension_calls(const GrowableObjectArray& value);
  RawGrowableObjectArray* registered_service_extension_handlers() const {
    return registered_service_extension_handlers_;
  }
  void set_registered_service_extension_handlers(
      const GrowableObjectArray& value);

  void ClearMutatorThread() {
    mutator_thread_ = NULL;
  }
  void MakeCurrentThreadMutator(Thread* thread) {
    ASSERT(thread == Thread::Current());
    DEBUG_ASSERT(IsIsolateOf(thread));
    mutator_thread_ = thread;
  }
#if defined(DEBUG)
  bool IsIsolateOf(Thread* thread);
#endif  // DEBUG

  // DEPRECATED: Use Thread's methods instead. During migration, these default
  // to using the mutator thread (which must also be the current thread).
  Zone* current_zone() const {
    ASSERT(Thread::Current() == mutator_thread_);
    return mutator_thread_->zone();
  }

  // Accessed from generated code:
  // TODO(asiva): Need to consider moving the stack_limit_ from isolate to
  // being thread specific.
  uword stack_limit_;
  StoreBuffer* store_buffer_;
  Heap* heap_;
  uword user_tag_;
  RawUserTag* current_tag_;
  RawUserTag* default_tag_;
  RawCode* ic_miss_code_;
  ClassTable class_table_;
  bool single_step_;

  ThreadRegistry* thread_registry_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
  char* debugger_name_;
  int64_t start_time_;
  Dart_Port main_port_;
  Dart_Port origin_id_;  // Isolates created by spawnFunc have some origin id.
  uint64_t pause_capability_;
  uint64_t terminate_capability_;
  bool errors_fatal_;
  ObjectStore* object_store_;
  uword top_exit_frame_info_;
  void* init_callback_data_;
  Dart_EnvironmentCallback environment_callback_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  Debugger* debugger_;
  bool resume_request_;
  int64_t last_resume_timestamp_;
  bool has_compiled_code_;  // Can check that no compilation occured.
  Flags flags_;
  Random random_;
  Simulator* simulator_;
  Mutex* mutex_;  // protects stack_limit_, saved_stack_limit_, compiler stats.
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

  CompilerStats* compiler_stats_;

  bool is_service_isolate_;

  // Status support.
  char* stacktrace_;
  intptr_t stack_frame_index_;

  // Timestamps of last operation via service.
  int64_t last_allocationprofile_accumulator_reset_timestamp_;
  int64_t last_allocationprofile_gc_timestamp_;

  // Ring buffer of objects assigned an id.
  ObjectIdRing* object_id_ring_;

  // Trace buffer support.
  TraceBuffer* trace_buffer_;

  VMTagCounters vm_tag_counters_;
  RawGrowableObjectArray* tag_table_;

  RawGrowableObjectArray* deoptimized_code_array_;

  // Background compilation.
  BackgroundCompiler* background_compiler_;

  // We use 6 list entries for each pending service extension calls.
  enum {
    kPendingHandlerIndex = 0,
    kPendingMethodNameIndex,
    kPendingKeysIndex,
    kPendingValuesIndex,
    kPendingReplyPortIndex,
    kPendingIdIndex,
    kPendingEntrySize
  };
  RawGrowableObjectArray* pending_service_extension_calls_;

  // We use 2 list entries for each registered extension handler.
  enum {
    kRegisteredNameIndex = 0,
    kRegisteredHandlerIndex,
    kRegisteredEntrySize
  };
  RawGrowableObjectArray* registered_service_extension_handlers_;

  Metric* metrics_list_head_;

  bool compilation_allowed_;
  bool all_classes_finalized_;

  // Isolate list next pointer.
  Isolate* next_;

  // Used to wake the isolate when it is in the pause event loop.
  Monitor* pause_loop_monitor_;

  // Invalidation generations; used to track events occuring in parallel
  // to background compilation. The counters may overflow, which is OK
  // since we check for equality to detect if an event occured.
  uint32_t cha_invalidation_gen_;
  uint32_t field_invalidation_gen_;
  uint32_t prefix_invalidation_gen_;

#define ISOLATE_METRIC_VARIABLE(type, variable, name, unit)                    \
  type metric_##variable##_;
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_VARIABLE);
#undef ISOLATE_METRIC_VARIABLE

#define ISOLATE_TIMELINE_STREAM_VARIABLE(name, not_used)                       \
  TimelineStream stream_##name##_;
  ISOLATE_TIMELINE_STREAM_LIST(ISOLATE_TIMELINE_STREAM_VARIABLE)
#undef ISOLATE_TIMELINE_STREAM_VARIABLE

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;
  static Dart_FileOpenCallback file_open_callback_;
  static Dart_FileReadCallback file_read_callback_;
  static Dart_FileWriteCallback file_write_callback_;
  static Dart_FileCloseCallback file_close_callback_;
  static Dart_EntropySource entropy_source_callback_;
  static Dart_IsolateInterruptCallback vmstats_callback_;

  static void WakePauseEventHandler(Dart_Isolate isolate);

  // Manage list of existing isolates.
  static bool AddIsolateToList(Isolate* isolate);
  static void RemoveIsolateFromList(Isolate* isolate);

  // This monitor protects isolates_list_head_, and creation_enabled_.
  static Monitor* isolates_list_monitor_;
  static Isolate* isolates_list_head_;
  static bool creation_enabled_;

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class GCMarker;  // VisitObjectPointers
  friend class Scavenger;  // VisitObjectPointers
  friend class ServiceIsolate;
  friend class Thread;
  friend class Timeline;

  DISALLOW_COPY_AND_ASSIGN(Isolate);
};


// When we need to execute code in an isolate, we use the
// StartIsolateScope.
class StartIsolateScope {
 public:
  explicit StartIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate), saved_isolate_(Isolate::Current()) {
    // TODO(koda): Audit users; passing NULL goes against naming of this class.
    if (new_isolate_ == NULL) {
      ASSERT(Isolate::Current() == NULL);
      // Do nothing.
      return;
    }
    if (saved_isolate_ != new_isolate_) {
      ASSERT(Isolate::Current() == NULL);
      // Ensure this is not a nested 'isolate enter' with prior state.
      ASSERT(new_isolate_->saved_stack_limit() == 0);
      Thread::EnterIsolate(new_isolate_);
    }
  }

  ~StartIsolateScope() {
    if (new_isolate_ == NULL) {
      ASSERT(Isolate::Current() == NULL);
      // Do nothing.
      return;
    }
    if (saved_isolate_ != new_isolate_) {
      ASSERT(saved_isolate_ == NULL);
      // ASSERT that we have bottomed out of all Dart invocations.
      ASSERT(new_isolate_->saved_stack_limit() == 0);
      Thread::ExitIsolate();
    }
  }

 private:
  Isolate* new_isolate_;
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(StartIsolateScope);
};


class IsolateSpawnState {
 public:
  IsolateSpawnState(Dart_Port parent_port,
                    Dart_Port origin_id,
                    void* init_data,
                    const Function& func,
                    const Instance& message,
                    bool paused,
                    bool errorsAreFatal,
                    Dart_Port onExit,
                    Dart_Port onError);
  IsolateSpawnState(Dart_Port parent_port,
                    void* init_data,
                    const char* script_url,
                    const char* package_root,
                    const char** package_map,
                    const Instance& args,
                    const Instance& message,
                    bool paused,
                    bool errorsAreFatal,
                    Dart_Port onExit,
                    Dart_Port onError);
  ~IsolateSpawnState();

  Isolate* isolate() const { return isolate_; }
  void set_isolate(Isolate* value) { isolate_ = value; }

  Dart_Port parent_port() const { return parent_port_; }
  Dart_Port origin_id() const { return origin_id_; }
  void* init_data() const { return init_data_; }
  Dart_Port on_exit_port() const { return on_exit_port_; }
  Dart_Port on_error_port() const { return on_error_port_; }
  const char* script_url() const { return script_url_; }
  const char* package_root() const { return package_root_; }
  const char** package_map() const { return package_map_; }
  const char* library_url() const { return library_url_; }
  const char* class_name() const { return class_name_; }
  const char* function_name() const { return function_name_; }
  bool is_spawn_uri() const { return library_url_ == NULL; }
  bool paused() const { return paused_; }
  bool errors_are_fatal() const { return errors_are_fatal_; }
  Isolate::Flags* isolate_flags() { return &isolate_flags_; }

  RawObject* ResolveFunction();
  RawInstance* BuildArgs(Thread* thread);
  RawInstance* BuildMessage(Thread* thread);

 private:
  Isolate* isolate_;
  Dart_Port parent_port_;
  Dart_Port origin_id_;
  void* init_data_;
  Dart_Port on_exit_port_;
  Dart_Port on_error_port_;
  const char* script_url_;
  const char* package_root_;
  const char** package_map_;
  const char* library_url_;
  const char* class_name_;
  const char* function_name_;
  uint8_t* serialized_args_;
  intptr_t serialized_args_len_;
  uint8_t* serialized_message_;
  intptr_t serialized_message_len_;
  Isolate::Flags isolate_flags_;
  bool paused_;
  bool errors_are_fatal_;
};

}  // namespace dart

#endif  // VM_ISOLATE_H_
