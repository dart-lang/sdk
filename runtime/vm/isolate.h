// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ISOLATE_H_
#define RUNTIME_VM_ISOLATE_H_

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/atomic.h"
#include "vm/base_isolate.h"
#include "vm/class_table.h"
#include "vm/exceptions.h"
#include "vm/fixed_cache.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/megamorphic_cache_table.h"
#include "vm/metrics.h"
#include "vm/os_thread.h"
#include "vm/random.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/timer.h"
#include "vm/token_position.h"
#include "vm/verifier.h"

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
class IsolateReloadContext;
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
class RawError;
class RawField;
class RawGrowableObjectArray;
class RawMint;
class RawObject;
class RawInteger;
class RawFloat32x4;
class RawInt32x4;
class RawUserTag;
class SafepointHandler;
class SampleBuffer;
class SendPort;
class SerializedObjectBuffer;
class ServiceIdZone;
class Simulator;
class StackResource;
class StackZone;
class StoreBuffer;
class StubCode;
class ThreadRegistry;
class UserTag;

class PendingLazyDeopt {
 public:
  PendingLazyDeopt(uword fp, uword pc) : fp_(fp), pc_(pc) {}
  uword fp() { return fp_; }
  uword pc() { return pc_; }
  void set_pc(uword pc) { pc_ = pc; }

 private:
  uword fp_;
  uword pc_;
};

class IsolateVisitor {
 public:
  IsolateVisitor() {}
  virtual ~IsolateVisitor() {}

  virtual void VisitIsolate(Isolate* isolate) = 0;

 protected:
  // Returns true if |isolate| is the VM or service isolate.
  bool IsVMInternalIsolate(Isolate* isolate) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateVisitor);
};

// Disallow OOB message handling within this scope.
class NoOOBMessageScope : public StackResource {
 public:
  explicit NoOOBMessageScope(Thread* thread);
  ~NoOOBMessageScope();

 private:
  DISALLOW_COPY_AND_ASSIGN(NoOOBMessageScope);
};

// Disallow isolate reload.
class NoReloadScope : public StackResource {
 public:
  NoReloadScope(Isolate* isolate, Thread* thread);
  ~NoReloadScope();

 private:
  Isolate* isolate_;
  DISALLOW_COPY_AND_ASSIGN(NoReloadScope);
};

// Fixed cache for exception handler lookup.
typedef FixedCache<intptr_t, ExceptionHandlerInfo, 16> HandlerInfoCache;
// Fixed cache for catch entry state lookup.
typedef FixedCache<intptr_t, CatchEntryState, 16> CatchEntryStateCache;

// List of Isolate flags with corresponding members of Dart_IsolateFlags and
// corresponding global command line flags.
//
//       V(when, name, Dart_IsolateFlags-member-name, command-line-flag-name)
//
#define ISOLATE_FLAG_LIST(V)                                                   \
  V(NONPRODUCT, type_checks, EnableTypeChecks, enable_type_checks,             \
    FLAG_enable_type_checks)                                                   \
  V(NONPRODUCT, asserts, EnableAsserts, enable_asserts, FLAG_enable_asserts)   \
  V(NONPRODUCT, reify_generic_functions, ReifyGenericFunctions,                \
    reify_generic_functions, FLAG_reify_generic_functions)                     \
  V(NONPRODUCT, strong, Strong, strong, FLAG_strong)                           \
  V(NONPRODUCT, error_on_bad_type, ErrorOnBadType, enable_error_on_bad_type,   \
    FLAG_error_on_bad_type)                                                    \
  V(NONPRODUCT, error_on_bad_override, ErrorOnBadOverride,                     \
    enable_error_on_bad_override, FLAG_error_on_bad_override)                  \
  V(NONPRODUCT, use_field_guards, UseFieldGuards, use_field_guards,            \
    FLAG_use_field_guards)                                                     \
  V(NONPRODUCT, use_osr, UseOsr, use_osr, FLAG_use_osr)                        \
  V(PRECOMPILER, obfuscate, Obfuscate, obfuscate, false_by_default)

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
    kLowMemoryMsg = 12,     // Run compactor, etc.
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
#if defined(DEBUG)
  void ValidateClassTable();
#endif

  void RehashConstants();
#if defined(DEBUG)
  void ValidateConstants();
#endif

  // Visits weak object pointers.
  void VisitWeakPersistentHandles(HandleVisitor* visitor);

  // Prepares all threads in an isolate for Garbage Collection.
  void PrepareForGC();

  StoreBuffer* store_buffer() { return store_buffer_; }

  ThreadRegistry* thread_registry() const { return thread_registry_; }
  SafepointHandler* safepoint_handler() const { return safepoint_handler_; }
  ClassTable* class_table() { return &class_table_; }
  static intptr_t class_table_offset() {
    return OFFSET_OF(Isolate, class_table_);
  }

  // Prefers old classes when we are in the middle of a reload.
  RawClass* GetClassForHeapWalkAt(intptr_t cid);

  static intptr_t ic_miss_code_offset() {
    return OFFSET_OF(Isolate, ic_miss_code_);
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }
  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  Thread* mutator_thread() const;

  // Mutator thread is not scheduled if NULL or no heap is attached
  // to it. The latter only occurs when the mutator thread object
  // is unscheduled by the isolate (or never scheduled).
  bool IsMutatorThreadScheduled() { return scheduled_mutator_thread_ != NULL; }

  const char* name() const { return name_; }
  void set_name(const char* name);

  int64_t UptimeMicros() const;

  Dart_Port main_port() const { return main_port_; }
  void set_main_port(Dart_Port port) {
    ASSERT(main_port_ == 0);  // Only set main port once.
    main_port_ = port;
  }
  Dart_Port origin_id() const { return origin_id_; }
  void set_origin_id(Dart_Port id) {
    ASSERT((id == main_port_ && origin_id_ == 0) || (origin_id_ == main_port_));
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

  ObjectStore* object_store() const { return object_store_; }
  void set_object_store(ObjectStore* value) { object_store_ = value; }
  static intptr_t object_store_offset() {
    return OFFSET_OF(Isolate, object_store_);
  }

  ApiState* api_state() const { return api_state_; }
  void set_api_state(ApiState* value) { api_state_ = value; }

  void set_init_callback_data(void* value) { init_callback_data_ = value; }
  void* init_callback_data() const { return init_callback_data_; }

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

  void SetupImagePage(const uint8_t* snapshot_buffer, bool is_executable);

  void ScheduleMessageInterrupts();

  // Marks all libraries as loaded.
  void DoneLoading();
  void DoneFinalizing();

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // By default the reload context is deleted. This parameter allows
  // the caller to delete is separately if it is still needed.
  bool ReloadSources(JSONStream* js,
                     bool force_reload,
                     const char* root_script_url = NULL,
                     const char* packages_url = NULL,
                     bool dont_delete_reload_context = false);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  bool MakeRunnable();
  void Run();

  MessageHandler* message_handler() const { return message_handler_; }
  void set_message_handler(MessageHandler* value) { message_handler_ = value; }

  bool is_runnable() const { return IsRunnableBit::decode(isolate_flags_); }
  void set_is_runnable(bool value) {
    isolate_flags_ = IsRunnableBit::update(value, isolate_flags_);
#if !defined(PRODUCT)
    if (is_runnable()) {
      set_last_resume_timestamp();
    }
#endif
  }

  void NotifyIdle(int64_t deadline);

  bool compaction_in_progress() const {
    return CompactionInProgressBit::decode(isolate_flags_);
  }
  void set_compaction_in_progress(bool value) {
    isolate_flags_ = CompactionInProgressBit::update(value, isolate_flags_);
  }

  IsolateSpawnState* spawn_state() const { return spawn_state_; }
  void set_spawn_state(IsolateSpawnState* value) { spawn_state_ = value; }

  Mutex* mutex() const { return mutex_; }
  Mutex* symbols_mutex() const { return symbols_mutex_; }
  Mutex* type_canonicalization_mutex() const {
    return type_canonicalization_mutex_;
  }
  Mutex* constant_canonicalization_mutex() const {
    return constant_canonicalization_mutex_;
  }
  Mutex* megamorphic_lookup_mutex() const { return megamorphic_lookup_mutex_; }

#if !defined(PRODUCT)
  Debugger* debugger() const {
    ASSERT(debugger_ != NULL);
    return debugger_;
  }
#endif

  void set_single_step(bool value) { single_step_ = value; }
  bool single_step() const { return single_step_; }
  static intptr_t single_step_offset() {
    return OFFSET_OF(Isolate, single_step_);
  }

#if !defined(PRODUCT)
  bool ResumeRequest() const {
    return ResumeRequestBit::decode(isolate_flags_);
  }
  // Lets the embedder know that a service message resulted in a resume request.
  void SetResumeRequest() {
    isolate_flags_ = ResumeRequestBit::update(true, isolate_flags_);
    set_last_resume_timestamp();
  }

  void set_last_resume_timestamp() {
    last_resume_timestamp_ = OS::GetCurrentTimeMillis();
  }

  int64_t last_resume_timestamp() const { return last_resume_timestamp_; }

  // Returns whether the vm service has requested that the debugger
  // resume execution.
  bool GetAndClearResumeRequest() {
    bool resume_request = ResumeRequestBit::decode(isolate_flags_);
    isolate_flags_ = ResumeRequestBit::update(false, isolate_flags_);
    return resume_request;
  }
#endif

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

  bool ErrorsFatal() const { return ErrorsFatalBit::decode(isolate_flags_); }
  void SetErrorsFatal(bool val) {
    isolate_flags_ = ErrorsFatalBit::update(val, isolate_flags_);
  }

  Random* random() { return &random_; }

  Simulator* simulator() const { return simulator_; }
  void set_simulator(Simulator* value) { simulator_ = value; }

  Monitor* spawn_count_monitor() const { return spawn_count_monitor_; }
  intptr_t* spawn_count() { return &spawn_count_; }

  void IncrementSpawnCount();
  void WaitForOutstandingSpawns();

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

  static void SetCleanupCallback(Dart_IsolateCleanupCallback cb) {
    cleanup_callback_ = cb;
  }
  static Dart_IsolateCleanupCallback CleanupCallback() {
    return cleanup_callback_;
  }

#if !defined(PRODUCT)
  void set_object_id_ring(ObjectIdRing* ring) { object_id_ring_ = ring; }
  ObjectIdRing* object_id_ring() { return object_id_ring_; }
#endif  // !defined(PRODUCT)

  void AddPendingDeopt(uword fp, uword pc);
  uword FindPendingDeopt(uword fp) const;
  void ClearPendingDeoptsAtOrBelow(uword fp) const;
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts() const {
    return pending_deopts_;
  }
  bool IsDeoptimizing() const { return deopt_context_ != NULL; }
  DeoptContext* deopt_context() const { return deopt_context_; }
  void set_deopt_context(DeoptContext* value) {
    ASSERT(value == NULL || deopt_context_ == NULL);
    deopt_context_ = value;
  }

  BackgroundCompiler* background_compiler() const {
    return background_compiler_;
  }

#if !defined(PRODUCT)
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
#endif  // !defined(PRODUCT)

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

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream, bool ref = true);
#endif

  // Mutator thread is used to aggregate compiler stats.
  CompilerStats* aggregate_compiler_stats() {
    return mutator_thread()->compiler_stats();
  }

#if !defined(PRODUCT)
  VMTagCounters* vm_tag_counters() { return &vm_tag_counters_; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool IsReloading() const { return reload_context_ != NULL; }

  IsolateReloadContext* reload_context() { return reload_context_; }

  void DeleteReloadContext();

  bool HasAttemptedReload() const {
    return HasAttemptedReloadBit::decode(isolate_flags_);
  }
  void SetHasAttemptedReload(bool value) {
    isolate_flags_ = HasAttemptedReloadBit::update(value, isolate_flags_);
  }

  bool CanReload() const;

  void set_last_reload_timestamp(int64_t value) {
    last_reload_timestamp_ = value;
  }
  int64_t last_reload_timestamp() const { return last_reload_timestamp_; }
#else
  bool IsReloading() const { return false; }
  bool HasAttemptedReload() const { return false; }
  bool CanReload() const { return false; }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
#endif  // !defined(PRODUCT)

  bool IsPaused() const;

#if !defined(PRODUCT)
  bool should_pause_post_service_request() const {
    return ShouldPausePostServiceRequestBit::decode(isolate_flags_);
  }
  void set_should_pause_post_service_request(bool value) {
    isolate_flags_ =
        ShouldPausePostServiceRequestBit::update(value, isolate_flags_);
  }
#endif  // !defined(PRODUCT)

  bool use_dart_frontend() const {
    return UseDartFrontEndBit::decode(isolate_flags_);
  }
  void set_use_dart_frontend(bool value) {
    isolate_flags_ = UseDartFrontEndBit::update(value, isolate_flags_);
  }

  RawError* PausePostRequest();

  uword user_tag() const { return user_tag_; }
  static intptr_t user_tag_offset() { return OFFSET_OF(Isolate, user_tag_); }
  static intptr_t current_tag_offset() {
    return OFFSET_OF(Isolate, current_tag_);
  }
  static intptr_t default_tag_offset() {
    return OFFSET_OF(Isolate, default_tag_);
  }

#if !defined(PRODUCT)
#define ISOLATE_METRIC_ACCESSOR(type, variable, name, unit)                    \
  type* Get##variable##Metric() { return &metric_##variable##_; }
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_ACCESSOR);
#undef ISOLATE_METRIC_ACCESSOR
#endif  // !defined(PRODUCT)

  static intptr_t IsolateListLength();

  RawGrowableObjectArray* tag_table() const { return tag_table_; }
  void set_tag_table(const GrowableObjectArray& value);

  RawUserTag* current_tag() const { return current_tag_; }
  void set_current_tag(const UserTag& tag);

  RawUserTag* default_tag() const { return default_tag_; }
  void set_default_tag(const UserTag& tag);

  void set_ic_miss_code(const Code& code);

#if !defined(PRODUCT)
  Metric* metrics_list_head() { return metrics_list_head_; }
  void set_metrics_list_head(Metric* metric) { metrics_list_head_ = metric; }
#endif  // !defined(PRODUCT)

  RawGrowableObjectArray* deoptimized_code_array() const {
    return deoptimized_code_array_;
  }
  void set_deoptimized_code_array(const GrowableObjectArray& value);
  void TrackDeoptimizedCode(const Code& code);

  // Also sends a paused at exit event over the service protocol.
  void SetStickyError(RawError* sticky_error);

  RawError* sticky_error() const { return sticky_error_; }
  void clear_sticky_error();

  bool compilation_allowed() const {
    return CompilationAllowedBit::decode(isolate_flags_);
  }
  void set_compilation_allowed(bool allowed) {
    isolate_flags_ = CompilationAllowedBit::update(allowed, isolate_flags_);
  }

  // In precompilation we finalize all regular classes before compiling.
  bool all_classes_finalized() const {
    return AllClassesFinalizedBit::decode(isolate_flags_);
  }
  void set_all_classes_finalized(bool value) {
    isolate_flags_ = AllClassesFinalizedBit::update(value, isolate_flags_);
  }

  bool remapping_cids() const {
    return RemappingCidsBit::decode(isolate_flags_);
  }
  void set_remapping_cids(bool value) {
    isolate_flags_ = RemappingCidsBit::update(value, isolate_flags_);
  }

  // True during top level parsing.
  bool IsTopLevelParsing() {
    const intptr_t value =
        AtomicOperations::LoadRelaxed(&top_level_parsing_count_);
    ASSERT(value >= 0);
    return value > 0;
  }

  void IncrTopLevelParsingCount() {
    AtomicOperations::IncrementBy(&top_level_parsing_count_, 1);
  }
  void DecrTopLevelParsingCount() {
    AtomicOperations::DecrementBy(&top_level_parsing_count_, 1);
  }

  static const intptr_t kInvalidGen = 0;

  void IncrLoadingInvalidationGen() {
    AtomicOperations::IncrementBy(&loading_invalidation_gen_, 1);
    if (loading_invalidation_gen_ == kInvalidGen) {
      AtomicOperations::IncrementBy(&loading_invalidation_gen_, 1);
    }
  }
  intptr_t loading_invalidation_gen() {
    return AtomicOperations::LoadRelaxed(&loading_invalidation_gen_);
  }

  // Used by background compiler which field became boxed and must trigger
  // deoptimization in the mutator thread.
  void AddDeoptimizingBoxedField(const Field& field);
  // Returns Field::null() if none available in the list.
  RawField* GetDeoptimizingBoxedField();

#ifndef PRODUCT
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
#endif

  static void VisitIsolates(IsolateVisitor* visitor);

#if !defined(PRODUCT)
  // Handle service messages until we are told to resume execution.
  void PauseEventHandler();
#endif

  void AddClosureFunction(const Function& function) const;
  RawFunction* LookupClosureFunction(const Function& parent,
                                     TokenPosition token_pos) const;
  intptr_t FindClosureIndex(const Function& needle) const;
  RawFunction* ClosureFunctionFromIndex(intptr_t idx) const;

  bool is_service_isolate() const {
    return IsServiceIsolateBit::decode(isolate_flags_);
  }
  void set_is_service_isolate(bool value) {
    isolate_flags_ = IsServiceIsolateBit::update(value, isolate_flags_);
  }

  bool should_load_vmservice() const {
    return ShouldLoadVmServiceBit::decode(isolate_flags_);
  }
  void set_should_load_vmservice(bool value) {
    isolate_flags_ = ShouldLoadVmServiceBit::update(value, isolate_flags_);
  }

  Dart_QualifiedFunctionName* embedder_entry_points() const {
    return embedder_entry_points_;
  }

  void set_obfuscation_map(const char** map) { obfuscation_map_ = map; }
  const char** obfuscation_map() const { return obfuscation_map_; }

  // Isolate-specific flag handling.
  static void FlagsInitialize(Dart_IsolateFlags* api_flags);
  void FlagsCopyTo(Dart_IsolateFlags* api_flags) const;
  void FlagsCopyFrom(const Dart_IsolateFlags& api_flags);

#if defined(DART_PRECOMPILER)
#define FLAG_FOR_PRECOMPILER(from_field, from_flag) (from_field)
#else
#define FLAG_FOR_PRECOMPILER(from_field, from_flag) (from_flag)
#endif

#if !defined(PRODUCT)
#define FLAG_FOR_NONPRODUCT(from_field, from_flag) (from_field)
#else
#define FLAG_FOR_NONPRODUCT(from_field, from_flag) (from_flag)
#endif

#define DECLARE_GETTER(when, name, bitname, isolate_flag_name, flag_name)      \
  bool name() const {                                                          \
    const bool false_by_default = false;                                       \
    USE(false_by_default);                                                     \
    return FLAG_FOR_##when(bitname##Bit::decode(isolate_flags_), flag_name);   \
  }
  ISOLATE_FLAG_LIST(DECLARE_GETTER)
#undef FLAG_FOR_NONPRODUCT
#undef FLAG_FOR_PRECOMPILER
#undef DECLARE_GETTER

#if defined(PRODUCT)
  void set_use_osr(bool use_osr) { ASSERT(!use_osr); }
#else  // defined(PRODUCT)
  void set_use_osr(bool use_osr) {
    isolate_flags_ = UseOsrBit::update(use_osr, isolate_flags_);
  }
#endif  // defined(PRODUCT)

  // Convenience flag tester indicating whether incoming function arguments
  // should be type checked.
  bool argument_type_checks() { return strong() || type_checks(); }

  static void KillAllIsolates(LibMsgId msg_id);
  static void KillIfExists(Isolate* isolate, LibMsgId msg_id);

  static void DisableIsolateCreation();
  static void EnableIsolateCreation();
  static bool IsolateCreationEnabled();
  static bool IsVMInternalIsolate(Isolate* isolate);

#if !defined(PRODUCT)
  intptr_t reload_every_n_stack_overflow_checks() const {
    return reload_every_n_stack_overflow_checks_;
  }
#endif  // !defined(PRODUCT)

  HandlerInfoCache* handler_info_cache() { return &handler_info_cache_; }

  CatchEntryStateCache* catch_entry_state_cache() {
    return &catch_entry_state_cache_;
  }

  void MaybeIncreaseReloadEveryNStackOverflowChecks();

  static void NotifyLowMemory();

 private:
  friend class Dart;                  // Init, InitOnce, Shutdown.
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
  void VisitStackPointers(ObjectPointerVisitor* visitor, bool validate_frames);

  void set_user_tag(uword tag) { user_tag_ = tag; }

#if !defined(PRODUCT)
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
#endif  // !defined(PRODUCT)

  Monitor* threads_lock() const;
  Thread* ScheduleThread(bool is_mutator, bool bypass_safepoint = false);
  void UnscheduleThread(Thread* thread,
                        bool is_mutator,
                        bool bypass_safepoint = false);

  // DEPRECATED: Use Thread's methods instead. During migration, these default
  // to using the mutator thread (which must also be the current thread).
  Zone* current_zone() const {
    ASSERT(Thread::Current() == mutator_thread());
    return mutator_thread()->zone();
  }

  // Accessed from generated code.
  // ** This block of fields must come first! **
  // For AOT cross-compilation, we rely on these members having the same offsets
  // in SIMARM(IA32) and ARM, and the same offsets in SIMARM64(X64) and ARM64.
  // We use only word-sized fields to avoid differences in struct packing on the
  // different architectures. See also CheckOffsets in dart.cc.
  StoreBuffer* store_buffer_;
  Heap* heap_;
  uword user_tag_;
  RawUserTag* current_tag_;
  RawUserTag* default_tag_;
  RawCode* ic_miss_code_;
  ObjectStore* object_store_;
  ClassTable class_table_;
  bool single_step_;

#define ISOLATE_FLAG_BITS(V)                                                   \
  V(ErrorsFatal)                                                               \
  V(IsRunnable)                                                                \
  V(IsServiceIsolate)                                                          \
  V(CompilationAllowed)                                                        \
  V(AllClassesFinalized)                                                       \
  V(RemappingCids)                                                             \
  V(ResumeRequest)                                                             \
  V(HasAttemptedReload)                                                        \
  V(ShouldPausePostServiceRequest)                                             \
  V(UseDartFrontEnd)                                                           \
  V(EnableTypeChecks)                                                          \
  V(EnableAsserts)                                                             \
  V(ErrorOnBadType)                                                            \
  V(ErrorOnBadOverride)                                                        \
  V(ReifyGenericFunctions)                                                     \
  V(Strong)                                                                    \
  V(UseFieldGuards)                                                            \
  V(UseOsr)                                                                    \
  V(Obfuscate)                                                                 \
  V(CompactionInProgress)                                                      \
  V(ShouldLoadVmService)

  // Isolate specific flags.
  enum FlagBits {
#define DECLARE_BIT(Name) k##Name##Bit,
    ISOLATE_FLAG_BITS(DECLARE_BIT)
#undef DECLARE_BIT
  };

#define DECLARE_BITFIELD(Name)                                                 \
  class Name##Bit : public BitField<uint32_t, bool, k##Name##Bit, 1> {};
  ISOLATE_FLAG_BITS(DECLARE_BITFIELD)
#undef DECLARE_BITFIELD

  uint32_t isolate_flags_;

  // Background compilation.
  BackgroundCompiler* background_compiler_;

// Fields that aren't needed in a product build go here with boolean flags at
// the top.
#if !defined(PRODUCT)
  Debugger* debugger_;
  int64_t last_resume_timestamp_;

  // Timestamps of last operation via service.
  int64_t last_allocationprofile_accumulator_reset_timestamp_;
  int64_t last_allocationprofile_gc_timestamp_;

  VMTagCounters vm_tag_counters_;

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

  // Used to wake the isolate when it is in the pause event loop.
  Monitor* pause_loop_monitor_;

#define ISOLATE_METRIC_VARIABLE(type, variable, name, unit)                    \
  type metric_##variable##_;
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_VARIABLE);
#undef ISOLATE_METRIC_VARIABLE

  intptr_t no_reload_scope_depth_;  // we can only reload when this is 0.
  // Per-isolate copy of FLAG_reload_every.
  intptr_t reload_every_n_stack_overflow_checks_;
  IsolateReloadContext* reload_context_;
  int64_t last_reload_timestamp_;
  // Ring buffer of objects assigned an id.
  ObjectIdRing* object_id_ring_;
#endif  // !defined(PRODUCT)

  // All other fields go here.
  int64_t start_time_micros_;
  ThreadRegistry* thread_registry_;
  SafepointHandler* safepoint_handler_;
  Dart_MessageNotifyCallback message_notify_callback_;
  char* name_;
  Dart_Port main_port_;
  Dart_Port origin_id_;  // Isolates created by spawnFunc have some origin id.
  uint64_t pause_capability_;
  uint64_t terminate_capability_;
  void* init_callback_data_;
  Dart_EnvironmentCallback environment_callback_;
  Dart_LibraryTagHandler library_tag_handler_;
  ApiState* api_state_;
  Random random_;
  Simulator* simulator_;
  Mutex* mutex_;          // Protects compiler stats.
  Mutex* symbols_mutex_;  // Protects concurrent access to the symbol table.
  Mutex* type_canonicalization_mutex_;      // Protects type canonicalization.
  Mutex* constant_canonicalization_mutex_;  // Protects const canonicalization.
  Mutex* megamorphic_lookup_mutex_;  // Protects megamorphic table lookup.
  MessageHandler* message_handler_;
  IsolateSpawnState* spawn_state_;
  intptr_t defer_finalization_count_;
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts_;
  DeoptContext* deopt_context_;

  RawGrowableObjectArray* tag_table_;

  RawGrowableObjectArray* deoptimized_code_array_;

  RawError* sticky_error_;

  // Isolate list next pointer.
  Isolate* next_;

  // Invalidation generations; used to track events occurring in parallel
  // to background compilation. The counters may overflow, which is OK
  // since we check for equality to detect if an event occured.
  intptr_t loading_invalidation_gen_;
  intptr_t top_level_parsing_count_;

  // Protect access to boxed_field_list_.
  Mutex* field_list_mutex_;
  // List of fields that became boxed and that trigger deoptimization.
  RawGrowableObjectArray* boxed_field_list_;

  // This guards spawn_count_. An isolate cannot complete shutdown and be
  // destroyed while there are child isolates in the midst of a spawn.
  Monitor* spawn_count_monitor_;
  intptr_t spawn_count_;

  HandlerInfoCache handler_info_cache_;
  CatchEntryStateCache catch_entry_state_cache_;

  Dart_QualifiedFunctionName* embedder_entry_points_;
  const char** obfuscation_map_;

  static Dart_IsolateCreateCallback create_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;
  static Dart_IsolateCleanupCallback cleanup_callback_;

#if !defined(PRODUCT)
  static void WakePauseEventHandler(Dart_Isolate isolate);
#endif

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

  friend class Become;    // VisitObjectPointers
  friend class GCCompactor;  // VisitObjectPointers
  friend class GCMarker;  // VisitObjectPointers
  friend class SafepointHandler;
  friend class ObjectGraph;  // VisitObjectPointers
  friend class Scavenger;    // VisitObjectPointers
  friend class HeapIterationScope;  // VisitObjectPointers
  friend class ServiceIsolate;
  friend class Thread;
  friend class Timeline;
  friend class NoReloadScope;  // reload_block

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
      Thread::EnterIsolate(new_isolate_);
      // Ensure this is not a nested 'isolate enter' with prior state.
      ASSERT(Thread::Current()->saved_stack_limit() == 0);
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
      ASSERT(Thread::Current()->saved_stack_limit() == 0);
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
                    const char* script_url,
                    const Function& func,
                    SerializedObjectBuffer* message_buffer,
                    Monitor* spawn_count_monitor,
                    intptr_t* spawn_count,
                    const char* package_root,
                    const char* package_config,
                    bool paused,
                    bool errorsAreFatal,
                    Dart_Port onExit,
                    Dart_Port onError);
  IsolateSpawnState(Dart_Port parent_port,
                    void* init_data,
                    const char* script_url,
                    const char* package_root,
                    const char* package_config,
                    SerializedObjectBuffer* args_buffer,
                    SerializedObjectBuffer* message_buffer,
                    Monitor* spawn_count_monitor,
                    intptr_t* spawn_count,
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
  const char* package_config() const { return package_config_; }
  const char* library_url() const { return library_url_; }
  const char* class_name() const { return class_name_; }
  const char* function_name() const { return function_name_; }
  bool is_spawn_uri() const { return library_url_ == NULL; }
  bool paused() const { return paused_; }
  bool errors_are_fatal() const { return errors_are_fatal_; }
  Dart_IsolateFlags* isolate_flags() { return &isolate_flags_; }

  RawObject* ResolveFunction();
  RawInstance* BuildArgs(Thread* thread);
  RawInstance* BuildMessage(Thread* thread);

  void DecrementSpawnCount();

 private:
  Isolate* isolate_;
  Dart_Port parent_port_;
  Dart_Port origin_id_;
  void* init_data_;
  Dart_Port on_exit_port_;
  Dart_Port on_error_port_;
  const char* script_url_;
  const char* package_root_;
  const char* package_config_;
  const char* library_url_;
  const char* class_name_;
  const char* function_name_;
  uint8_t* serialized_args_;
  intptr_t serialized_args_len_;
  uint8_t* serialized_message_;
  intptr_t serialized_message_len_;

  // This counter tracks the number of outstanding calls to spawn by the parent
  // isolate.
  Monitor* spawn_count_monitor_;
  intptr_t* spawn_count_;

  Dart_IsolateFlags isolate_flags_;
  bool paused_;
  bool errors_are_fatal_;
};

}  // namespace dart

#endif  // RUNTIME_VM_ISOLATE_H_
