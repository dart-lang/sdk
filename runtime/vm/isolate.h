// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_ISOLATE_H_
#define RUNTIME_VM_ISOLATE_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include <functional>
#include <memory>
#include <utility>

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "vm/base_isolate.h"
#include "vm/class_table.h"
#include "vm/dispatch_table.h"
#include "vm/exceptions.h"
#include "vm/field_table.h"
#include "vm/fixed_cache.h"
#include "vm/growable_array.h"
#include "vm/handles.h"
#include "vm/heap/verifier.h"
#include "vm/intrusive_dlist.h"
#include "vm/megamorphic_cache_table.h"
#include "vm/metrics.h"
#include "vm/os_thread.h"
#include "vm/random.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/thread_pool.h"
#include "vm/thread_stack_resource.h"
#include "vm/token_position.h"
#include "vm/virtual_memory.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/ffi_callback_trampolines.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// Forward declarations.
class ApiState;
class BackgroundCompiler;
class Capability;
class CodeIndexTable;
class Debugger;
class DeoptContext;
class ExternalTypedData;
class HandleScope;
class HandleVisitor;
class Heap;
class ICData;
class IsolateObjectStore;
class IsolateProfilerData;
class IsolateReloadContext;
class Log;
class Message;
class MessageHandler;
class MonitorLocker;
class Mutex;
class Object;
class ObjectIdRing;
class ObjectPointerVisitor;
class ObjectStore;
class PersistentHandle;
class RwLock;
class SafepointRwLock;
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
class WeakTable;

/*
 * Possible values of null safety flag
  0 - not specified
  1 - weak mode
  2 - strong mode)
*/
constexpr int kNullSafetyOptionUnspecified = 0;
constexpr int kNullSafetyOptionWeak = 1;
constexpr int kNullSafetyOptionStrong = 2;
extern int FLAG_sound_null_safety;

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
  bool IsSystemIsolate(Isolate* isolate) const;

 private:
  DISALLOW_COPY_AND_ASSIGN(IsolateVisitor);
};

class Callable : public ValueObject {
 public:
  Callable() {}
  virtual ~Callable() {}

  virtual void Call() = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(Callable);
};

template <typename T>
class LambdaCallable : public Callable {
 public:
  explicit LambdaCallable(T& lambda) : lambda_(lambda) {}
  void Call() { lambda_(); }

 private:
  T& lambda_;
  DISALLOW_COPY_AND_ASSIGN(LambdaCallable);
};

// Disallow OOB message handling within this scope.
class NoOOBMessageScope : public ThreadStackResource {
 public:
  explicit NoOOBMessageScope(Thread* thread);
  ~NoOOBMessageScope();

 private:
  DISALLOW_COPY_AND_ASSIGN(NoOOBMessageScope);
};

// Disallow isolate reload.
class NoReloadScope : public ThreadStackResource {
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
typedef FixedCache<intptr_t, CatchEntryMovesRefPtr, 16> CatchEntryMovesCache;

// List of Isolate flags with corresponding members of Dart_IsolateFlags and
// corresponding global command line flags.
#define BOOL_ISOLATE_FLAG_LIST(V)                                              \
  BOOL_ISOLATE_FLAG_LIST_DEFAULT_GETTER(V)                                     \
  BOOL_ISOLATE_FLAG_LIST_CUSTOM_GETTER(V)

// List of Isolate flags with default getters.
//
//     V(when, name, bit-name, Dart_IsolateFlags-name, command-line-flag-name)
//
#define BOOL_ISOLATE_FLAG_LIST_DEFAULT_GETTER(V)                               \
  V(NONPRODUCT, asserts, EnableAsserts, enable_asserts, FLAG_enable_asserts)   \
  V(NONPRODUCT, use_field_guards, UseFieldGuards, use_field_guards,            \
    FLAG_use_field_guards)                                                     \
  V(NONPRODUCT, use_osr, UseOsr, use_osr, FLAG_use_osr)                        \
  V(PRECOMPILER, obfuscate, Obfuscate, obfuscate, false_by_default)            \
  V(PRODUCT, should_load_vmservice_library, ShouldLoadVmService,               \
    load_vmservice_library, false_by_default)                                  \
  V(PRODUCT, copy_parent_code, CopyParentCode, copy_parent_code,               \
    false_by_default)                                                          \
  V(PRODUCT, is_system_isolate, IsSystemIsolate, is_system_isolate,            \
    false_by_default)

// List of Isolate flags with custom getters named #name().
//
//     V(when, name, bit-name, Dart_IsolateFlags-name, default_value)
//
#define BOOL_ISOLATE_FLAG_LIST_CUSTOM_GETTER(V)                                \
  V(PRODUCT, null_safety, NullSafety, null_safety, false_by_default)

// Represents the information used for spawning the first isolate within an
// isolate group.
//
// Any subsequent isolates created via `Isolate.spawn()` will be created using
// the same [IsolateGroupSource] (the object itself is shared among all isolates
// within the same group).
//
// Issue(http://dartbug.com/36097): It is still possible to run into issues if
// an isolate has spawned another one and then loads more code into the first
// one, which the latter will not get. Though it makes the status quo better
// than what we had before (where the embedder needed to maintain the
// same-source guarantee).
//
// => This is only the first step towards having multiple isolates share the
//    same heap (and therefore the same program structure).
//
class IsolateGroupSource {
 public:
  IsolateGroupSource(const char* script_uri,
                     const char* name,
                     const uint8_t* snapshot_data,
                     const uint8_t* snapshot_instructions,
                     const uint8_t* kernel_buffer,
                     intptr_t kernel_buffer_size,
                     Dart_IsolateFlags flags)
      : script_uri(script_uri == nullptr ? nullptr : Utils::StrDup(script_uri)),
        name(Utils::StrDup(name)),
        snapshot_data(snapshot_data),
        snapshot_instructions(snapshot_instructions),
        kernel_buffer(kernel_buffer),
        kernel_buffer_size(kernel_buffer_size),
        flags(flags),
        script_kernel_buffer(nullptr),
        script_kernel_size(-1),
        loaded_blobs_(nullptr),
        num_blob_loads_(0) {}
  ~IsolateGroupSource() {
    free(script_uri);
    free(name);
  }

  void add_loaded_blob(Zone* zone_,
                       const ExternalTypedData& external_typed_data);

  // The arguments used for spawning in
  // `Dart_CreateIsolateGroupFromKernel` / `Dart_CreateIsolate`.
  char* script_uri;
  char* name;
  const uint8_t* snapshot_data;
  const uint8_t* snapshot_instructions;
  const uint8_t* kernel_buffer;
  const intptr_t kernel_buffer_size;
  Dart_IsolateFlags flags;

  // The kernel buffer used in `Dart_LoadScriptFromKernel`.
  const uint8_t* script_kernel_buffer;
  intptr_t script_kernel_size;

  // During AppJit training we perform a permutation of the class ids before
  // invoking the "main" script.
  // Any newly spawned isolates need to use this permutation map.
  std::unique_ptr<intptr_t[]> cid_permutation_map;

  // List of weak pointers to external typed data for loaded blobs.
  ArrayPtr loaded_blobs_;
  intptr_t num_blob_loads_;
};

// Tracks idle time and notifies heap when idle time expired.
class IdleTimeHandler : public ValueObject {
 public:
  IdleTimeHandler() {}

  // Initializes the idle time handler with the given [heap], to which
  // idle notifications will be sent.
  void InitializeWithHeap(Heap* heap);

  // Returns whether the caller should check for idle timeouts.
  bool ShouldCheckForIdle();

  // Declares that the idle time should be reset to now.
  void UpdateStartIdleTime();

  // Returns whether idle time expired and [NotifyIdle] should be called.
  bool ShouldNotifyIdle(int64_t* expiry);

  // Notifies the heap that now is a good time to do compactions and indicates
  // we have time for the GC until [deadline].
  void NotifyIdle(int64_t deadline);

  // Calls [NotifyIdle] with the default deadline.
  void NotifyIdleUsingDefaultDeadline();

 private:
  friend class DisableIdleTimerScope;

  Mutex mutex_;
  Heap* heap_ = nullptr;
  intptr_t disabled_counter_ = 0;
  int64_t idle_start_time_ = 0;
};

// Disables firing of the idle timer while this object is alive.
class DisableIdleTimerScope : public ValueObject {
 public:
  explicit DisableIdleTimerScope(IdleTimeHandler* handler);
  ~DisableIdleTimerScope();

 private:
  IdleTimeHandler* handler_;
};

class MutatorThreadPool : public ThreadPool {
 public:
  MutatorThreadPool(IsolateGroup* isolate_group, intptr_t max_pool_size)
      : ThreadPool(max_pool_size), isolate_group_(isolate_group) {}
  virtual ~MutatorThreadPool() {}

 protected:
  virtual void OnEnterIdleLocked(MonitorLocker* ml);

 private:
  void NotifyIdle();

  IsolateGroup* isolate_group_ = nullptr;
};

// Represents an isolate group and is shared among all isolates within a group.
class IsolateGroup : public IntrusiveDListEntry<IsolateGroup> {
 public:
  IsolateGroup(std::shared_ptr<IsolateGroupSource> source,
               void* embedder_data,
               ObjectStore* object_store);
  IsolateGroup(std::shared_ptr<IsolateGroupSource> source, void* embedder_data);
  ~IsolateGroup();

  IsolateGroupSource* source() const { return source_.get(); }
  std::shared_ptr<IsolateGroupSource> shareable_source() const {
    return source_;
  }
  void* embedder_data() const { return embedder_data_; }

  bool initial_spawn_successful() { return initial_spawn_successful_; }
  void set_initial_spawn_successful() { initial_spawn_successful_ = true; }

  Heap* heap() const { return heap_.get(); }

  IdleTimeHandler* idle_time_handler() { return &idle_time_handler_; }

  // Returns true if this is the first isolate registered.
  void RegisterIsolate(Isolate* isolate);
  void RegisterIsolateLocked(Isolate* isolate);
  void UnregisterIsolate(Isolate* isolate);
  // Returns `true` if this was the last isolate and the caller is responsible
  // for deleting the isolate group.
  bool UnregisterIsolateDecrementCount(Isolate* isolate);

  bool ContainsOnlyOneIsolate();

  void RunWithLockedGroup(std::function<void()> fun);

  Monitor* threads_lock() const;
  ThreadRegistry* thread_registry() const { return thread_registry_.get(); }
  SafepointHandler* safepoint_handler() { return safepoint_handler_.get(); }

  void CreateHeap(bool is_vm_isolate, bool is_service_or_kernel_isolate);
  void Shutdown();

#define ISOLATE_METRIC_ACCESSOR(type, variable, name, unit)                    \
  type* Get##variable##Metric() { return &metric_##variable##_; }
  ISOLATE_GROUP_METRIC_LIST(ISOLATE_METRIC_ACCESSOR);
#undef ISOLATE_METRIC_ACCESSOR

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

  DispatchTable* dispatch_table() const { return dispatch_table_.get(); }
  void set_dispatch_table(DispatchTable* table) {
    dispatch_table_.reset(table);
  }
  const uint8_t* dispatch_table_snapshot() const {
    return dispatch_table_snapshot_;
  }
  void set_dispatch_table_snapshot(const uint8_t* snapshot) {
    dispatch_table_snapshot_ = snapshot;
  }
  intptr_t dispatch_table_snapshot_size() const {
    return dispatch_table_snapshot_size_;
  }
  void set_dispatch_table_snapshot_size(intptr_t size) {
    dispatch_table_snapshot_size_ = size;
  }

  SharedClassTable* shared_class_table() const {
    return shared_class_table_.get();
  }

  bool is_system_isolate_group() const { return is_system_isolate_group_; }

  StoreBuffer* store_buffer() const { return store_buffer_.get(); }
  ClassTable* class_table() const { return class_table_.get(); }
  ObjectStore* object_store() const { return object_store_.get(); }
  SafepointRwLock* symbols_lock() { return symbols_lock_.get(); }
  Mutex* type_canonicalization_mutex() { return &type_canonicalization_mutex_; }
  Mutex* type_arguments_canonicalization_mutex() {
    return &type_arguments_canonicalization_mutex_;
  }
  Mutex* subtype_test_cache_mutex() { return &subtype_test_cache_mutex_; }
  Mutex* megamorphic_table_mutex() { return &megamorphic_table_mutex_; }
  Mutex* type_feedback_mutex() { return &type_feedback_mutex_; }
  Mutex* patchable_call_mutex() { return &patchable_call_mutex_; }
  Mutex* constant_canonicalization_mutex() {
    return &constant_canonicalization_mutex_;
  }
  Mutex* kernel_data_lib_cache_mutex() { return &kernel_data_lib_cache_mutex_; }
  Mutex* kernel_data_class_cache_mutex() {
    return &kernel_data_class_cache_mutex_;
  }
  Mutex* kernel_constants_mutex() { return &kernel_constants_mutex_; }

#if defined(DART_PRECOMPILED_RUNTIME)
  Mutex* unlinked_call_map_mutex() { return &unlinked_call_map_mutex_; }
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  Mutex* initializer_functions_mutex() { return &initializer_functions_mutex_; }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  SafepointRwLock* program_lock() { return program_lock_.get(); }

  static inline IsolateGroup* Current() {
    Thread* thread = Thread::Current();
    return thread == nullptr ? nullptr : thread->isolate_group();
  }

  Thread* ScheduleThreadLocked(MonitorLocker* ml,
                               Thread* existing_mutator_thread,
                               bool is_vm_isolate,
                               bool is_mutator,
                               bool bypass_safepoint = false);
  void UnscheduleThreadLocked(MonitorLocker* ml,
                              Thread* thread,
                              bool is_mutator,
                              bool bypass_safepoint = false);

  Thread* ScheduleThread(bool bypass_safepoint = false);
  void UnscheduleThread(Thread* thread,
                        bool is_mutator,
                        bool bypass_safepoint = false);

  void IncreaseMutatorCount(Isolate* mutator);
  void DecreaseMutatorCount(Isolate* mutator);

  Dart_LibraryTagHandler library_tag_handler() const {
    return library_tag_handler_;
  }
  void set_library_tag_handler(Dart_LibraryTagHandler handler) {
    library_tag_handler_ = handler;
  }
  Dart_DeferredLoadHandler deferred_load_handler() const {
    return deferred_load_handler_;
  }
  void set_deferred_load_handler(Dart_DeferredLoadHandler handler) {
    deferred_load_handler_ = handler;
  }

  intptr_t GetClassSizeForHeapWalkAt(intptr_t cid);

  // Prepares all threads in an isolate for Garbage Collection.
  void ReleaseStoreBuffers();
  void EnableIncrementalBarrier(MarkingStack* marking_stack,
                                MarkingStack* deferred_marking_stack);
  void DisableIncrementalBarrier();

  MarkingStack* marking_stack() const { return marking_stack_; }
  MarkingStack* deferred_marking_stack() const {
    return deferred_marking_stack_;
  }

  // Runs the given [function] on every isolate in the isolate group.
  //
  // During the duration of this function, no new isolates can be added or
  // removed.
  //
  // If [at_safepoint] is `true`, then the entire isolate group must be in a
  // safepoint. There is therefore no reason to guard against other threads
  // adding/removing isolates, so no locks will be held.
  void ForEachIsolate(std::function<void(Isolate* isolate)> function,
                      bool at_safepoint = false);
  Isolate* FirstIsolate() const;
  Isolate* FirstIsolateLocked() const;

  // Ensures mutators are stopped during execution of the provided function.
  //
  // If the current thread is the only mutator in the isolate group,
  // [single_current_mutator] will be called. Otherwise [otherwise] will be
  // called inside a [SafepointOperationsScope] (or
  // [ForceGrowthSafepointOperationScope] if [use_force_growth_in_otherwise]
  // is set).
  //
  // During the duration of this function, no new isolates can be added to the
  // isolate group.
  void RunWithStoppedMutatorsCallable(
      Callable* single_current_mutator,
      Callable* otherwise,
      bool use_force_growth_in_otherwise = false);

  template <typename T, typename S>
  void RunWithStoppedMutators(T single_current_mutator,
                              S otherwise,
                              bool use_force_growth_in_otherwise = false) {
    LambdaCallable<T> single_callable(single_current_mutator);
    LambdaCallable<S> otherwise_callable(otherwise);
    RunWithStoppedMutatorsCallable(&single_callable, &otherwise_callable,
                                   use_force_growth_in_otherwise);
  }

  template <typename T>
  void RunWithStoppedMutators(T function, bool use_force_growth = false) {
    LambdaCallable<T> callable(function);
    RunWithStoppedMutatorsCallable(&callable, &callable, use_force_growth);
  }

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream, bool ref = true);
  void PrintToJSONObject(JSONObject* jsobj, bool ref);

  // Creates an object with the total heap memory usage statistics for this
  // isolate group.
  void PrintMemoryUsageJSON(JSONStream* stream);
#endif

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // By default the reload context is deleted. This parameter allows
  // the caller to delete is separately if it is still needed.
  bool ReloadSources(JSONStream* js,
                     bool force_reload,
                     const char* root_script_url = nullptr,
                     const char* packages_url = nullptr,
                     bool dont_delete_reload_context = false);

  // If provided, the VM takes ownership of kernel_buffer.
  bool ReloadKernel(JSONStream* js,
                    bool force_reload,
                    const uint8_t* kernel_buffer = nullptr,
                    intptr_t kernel_buffer_size = 0,
                    bool dont_delete_reload_context = false);

  void set_last_reload_timestamp(int64_t value) {
    last_reload_timestamp_ = value;
  }
  int64_t last_reload_timestamp() const { return last_reload_timestamp_; }

  IsolateGroupReloadContext* reload_context() {
    return group_reload_context_.get();
  }

  void DeleteReloadContext();
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  bool IsReloading() const {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
    return group_reload_context_ != nullptr;
#else
    return false;
#endif
  }

  uint64_t id() { return id_; }

  static void Init();
  static void Cleanup();

  static void ForEach(std::function<void(IsolateGroup*)> action);
  static void RunWithIsolateGroup(uint64_t id,
                                  std::function<void(IsolateGroup*)> action,
                                  std::function<void()> not_found);

  // Manage list of existing isolate groups.
  static void RegisterIsolateGroup(IsolateGroup* isolate_group);
  static void UnregisterIsolateGroup(IsolateGroup* isolate_group);

  static bool HasApplicationIsolateGroups();
  static bool HasOnlyVMIsolateGroup();
  static bool IsSystemIsolateGroup(const IsolateGroup* group);

  int64_t UptimeMicros() const;

  ApiState* api_state() const { return api_state_.get(); }

  // Visit all object pointers. Caller must ensure concurrent sweeper is not
  // running, and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           ValidationPolicy validate_frames);
  void VisitStackPointers(ObjectPointerVisitor* visitor,
                          ValidationPolicy validate_frames);
  void VisitObjectIdRingPointers(ObjectPointerVisitor* visitor);
  void VisitWeakPersistentHandles(HandleVisitor* visitor);

  bool compaction_in_progress() const {
    return CompactionInProgressBit::decode(isolate_group_flags_);
  }
  void set_compaction_in_progress(bool value) {
    isolate_group_flags_ =
        CompactionInProgressBit::update(value, isolate_group_flags_);
  }

  uword FindPendingDeoptAtSafepoint(uword fp);

  void RememberLiveTemporaries();
  void DeferredMarkLiveTemporaries();

  ArrayPtr saved_unlinked_calls() const { return saved_unlinked_calls_; }
  void set_saved_unlinked_calls(const Array& saved_unlinked_calls);

  FieldTable* initial_field_table() const { return initial_field_table_.get(); }
  std::shared_ptr<FieldTable> initial_field_table_shareable() {
    return initial_field_table_;
  }
  void set_initial_field_table(std::shared_ptr<FieldTable> field_table) {
    initial_field_table_ = field_table;
  }

  MutatorThreadPool* thread_pool() { return thread_pool_.get(); }

  void RegisterStaticField(const Field& field, const Instance& initial_value);

 private:
  friend class Dart;  // For `object_store_ = ` in Dart::Init
  friend class Heap;
  friend class StackFrame;  // For `[isolates_].First()`.
  // For `object_store_shared_ptr()`, `class_table_shared_ptr()`
  friend class Isolate;

#define ISOLATE_GROUP_FLAG_BITS(V) V(CompactionInProgress)

  // Isolate specific flags.
  enum FlagBits {
#define DECLARE_BIT(Name) k##Name##Bit,
    ISOLATE_GROUP_FLAG_BITS(DECLARE_BIT)
#undef DECLARE_BIT
  };

#define DECLARE_BITFIELD(Name)                                                 \
  class Name##Bit : public BitField<uint32_t, bool, k##Name##Bit, 1> {};
  ISOLATE_GROUP_FLAG_BITS(DECLARE_BITFIELD)
#undef DECLARE_BITFIELD

  void set_heap(std::unique_ptr<Heap> value);

  const std::shared_ptr<ClassTable>& class_table_shared_ptr() const {
    return class_table_;
  }
  const std::shared_ptr<ObjectStore>& object_store_shared_ptr() const {
    return object_store_;
  }

  bool is_vm_isolate_heap_ = false;
  void* embedder_data_ = nullptr;

  IdleTimeHandler idle_time_handler_;
  std::unique_ptr<MutatorThreadPool> thread_pool_;
  std::unique_ptr<SafepointRwLock> isolates_lock_;
  IntrusiveDList<Isolate> isolates_;
  intptr_t isolate_count_ = 0;
  bool initial_spawn_successful_ = false;
  Dart_LibraryTagHandler library_tag_handler_ = nullptr;
  Dart_DeferredLoadHandler deferred_load_handler_ = nullptr;
  int64_t start_time_micros_;
  bool is_system_isolate_group_;

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  int64_t last_reload_timestamp_;
  std::shared_ptr<IsolateGroupReloadContext> group_reload_context_;
#endif

#define ISOLATE_METRIC_VARIABLE(type, variable, name, unit)                    \
  type metric_##variable##_;
  ISOLATE_GROUP_METRIC_LIST(ISOLATE_METRIC_VARIABLE);
#undef ISOLATE_METRIC_VARIABLE

#if !defined(PRODUCT)
  // Timestamps of last operation via service.
  int64_t last_allocationprofile_accumulator_reset_timestamp_ = 0;
  int64_t last_allocationprofile_gc_timestamp_ = 0;

#endif  // !defined(PRODUCT)

  MarkingStack* marking_stack_ = nullptr;
  MarkingStack* deferred_marking_stack_ = nullptr;
  std::shared_ptr<IsolateGroupSource> source_;
  std::unique_ptr<ApiState> api_state_;
  std::unique_ptr<ThreadRegistry> thread_registry_;
  std::unique_ptr<SafepointHandler> safepoint_handler_;

  static RwLock* isolate_groups_rwlock_;
  static IntrusiveDList<IsolateGroup>* isolate_groups_;
  static Random* isolate_group_random_;

  uint64_t id_ = 0;

  std::unique_ptr<SharedClassTable> shared_class_table_;
  std::shared_ptr<ObjectStore> object_store_;
  std::shared_ptr<ClassTable> class_table_;
  std::unique_ptr<StoreBuffer> store_buffer_;
  std::unique_ptr<Heap> heap_;
  std::unique_ptr<DispatchTable> dispatch_table_;
  const uint8_t* dispatch_table_snapshot_ = nullptr;
  intptr_t dispatch_table_snapshot_size_ = 0;
  ArrayPtr saved_unlinked_calls_;
  std::shared_ptr<FieldTable> initial_field_table_;
  uint32_t isolate_group_flags_ = 0;

  std::unique_ptr<SafepointRwLock> symbols_lock_;
  Mutex type_canonicalization_mutex_;
  Mutex type_arguments_canonicalization_mutex_;
  Mutex subtype_test_cache_mutex_;
  Mutex megamorphic_table_mutex_;
  Mutex type_feedback_mutex_;
  Mutex patchable_call_mutex_;
  Mutex constant_canonicalization_mutex_;
  Mutex kernel_data_lib_cache_mutex_;
  Mutex kernel_data_class_cache_mutex_;
  Mutex kernel_constants_mutex_;

#if defined(DART_PRECOMPILED_RUNTIME)
  Mutex unlinked_call_map_mutex_;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  Mutex initializer_functions_mutex_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Ensures synchronized access to classes functions, fields and other
  // program structure elements to accommodate concurrent modification done
  // by multiple isolates and background compiler.
  std::unique_ptr<SafepointRwLock> program_lock_;

  // Allow us to ensure the number of active mutators is limited by a maximum.
  std::unique_ptr<Monitor> active_mutators_monitor_;
  intptr_t active_mutators_ = 0;
  intptr_t waiting_mutators_ = 0;
  intptr_t max_active_mutators_ = 0;
};

// When an isolate sends-and-exits this class represent things that it passed
// to the beneficiary.
class Bequest {
 public:
  Bequest(PersistentHandle* handle, Dart_Port beneficiary)
      : handle_(handle), beneficiary_(beneficiary) {}
  ~Bequest();

  PersistentHandle* handle() { return handle_; }
  Dart_Port beneficiary() { return beneficiary_; }

 private:
  PersistentHandle* handle_;
  Dart_Port beneficiary_;
};

class Isolate : public BaseIsolate, public IntrusiveDListEntry<Isolate> {
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
    kDrainServiceExtensionsMsg = 13,  // Invoke pending service extensions
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
    return thread == nullptr ? nullptr : thread->isolate();
  }

  bool IsScheduled() { return scheduled_mutator_thread() != nullptr; }
  Thread* scheduled_mutator_thread() const { return scheduled_mutator_thread_; }

  // Register a newly introduced class.
  void RegisterClass(const Class& cls);
#if defined(DEBUG)
  void ValidateClassTable();
#endif

  void RehashConstants();
#if defined(DEBUG)
  void ValidateConstants();
#endif

  ThreadRegistry* thread_registry() const { return group()->thread_registry(); }

  SafepointHandler* safepoint_handler() const {
    return group()->safepoint_handler();
  }

  ClassTable* class_table() { return class_table_.get(); }

  ClassPtr* cached_class_table_table() { return cached_class_table_table_; }
  void set_cached_class_table_table(ClassPtr* cached_class_table_table) {
    cached_class_table_table_ = cached_class_table_table;
  }
  static intptr_t cached_class_table_table_offset() {
    return OFFSET_OF(Isolate, cached_class_table_table_);
  }

  SharedClassTable* shared_class_table() const { return shared_class_table_; }
  // Used during isolate creation to re-register isolate with right group.
  void set_shared_class_table(SharedClassTable* table) {
    shared_class_table_ = table;
  }
  // Used by the generated code.
  static intptr_t shared_class_table_offset() {
    return OFFSET_OF(Isolate, shared_class_table_);
  }

  ObjectStore* object_store() const { return object_store_shared_ptr_.get(); }
  void set_object_store(ObjectStore* object_store);
  static intptr_t cached_object_store_offset() {
    return OFFSET_OF(Isolate, cached_object_store_);
  }

  FieldTable* field_table() const { return field_table_; }
  void set_field_table(Thread* T, FieldTable* field_table) {
    delete field_table_;
    field_table_ = field_table;
    T->field_table_values_ = field_table->table();
  }

  IsolateObjectStore* isolate_object_store() const {
    return isolate_object_store_.get();
  }

  // Prefers old classes when we are in the middle of a reload.
  ClassPtr GetClassForHeapWalkAt(intptr_t cid);

  static intptr_t ic_miss_code_offset() {
    return OFFSET_OF(Isolate, ic_miss_code_);
  }

  Dart_MessageNotifyCallback message_notify_callback() const {
    return message_notify_callback_;
  }

  void set_message_notify_callback(Dart_MessageNotifyCallback value) {
    message_notify_callback_ = value;
  }

  void set_on_shutdown_callback(Dart_IsolateShutdownCallback value) {
    on_shutdown_callback_ = value;
  }
  Dart_IsolateShutdownCallback on_shutdown_callback() {
    return on_shutdown_callback_;
  }
  void set_on_cleanup_callback(Dart_IsolateCleanupCallback value) {
    on_cleanup_callback_ = value;
  }
  Dart_IsolateCleanupCallback on_cleanup_callback() {
    return on_cleanup_callback_;
  }

  void bequeath(std::unique_ptr<Bequest> bequest) {
    bequest_ = std::move(bequest);
  }

  IsolateGroupSource* source() const { return isolate_group_->source(); }
  IsolateGroup* group() const { return isolate_group_; }

  bool HasPendingMessages();

  Thread* mutator_thread() const;

  const char* name() const { return name_; }
  void set_name(const char* name);

  int64_t UptimeMicros() const;

  Dart_Port main_port() const { return main_port_; }
  void set_main_port(Dart_Port port) {
    ASSERT(main_port_ == 0);  // Only set main port once.
    main_port_ = port;
  }
  Dart_Port origin_id();
  void set_origin_id(Dart_Port id);
  void set_pause_capability(uint64_t value) { pause_capability_ = value; }
  uint64_t pause_capability() const { return pause_capability_; }
  void set_terminate_capability(uint64_t value) {
    terminate_capability_ = value;
  }
  uint64_t terminate_capability() const { return terminate_capability_; }

  void SendInternalLibMessage(LibMsgId msg_id, uint64_t capability);

  Heap* heap() const { return isolate_group_->heap(); }

  void set_init_callback_data(void* value) { init_callback_data_ = value; }
  void* init_callback_data() const { return init_callback_data_; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  NativeCallbackTrampolines* native_callback_trampolines() {
    return &native_callback_trampolines_;
  }
#endif

  Dart_EnvironmentCallback environment_callback() const {
    return environment_callback_;
  }
  void set_environment_callback(Dart_EnvironmentCallback value) {
    environment_callback_ = value;
  }

  bool HasTagHandler() const {
    return group()->library_tag_handler() != nullptr;
  }
  ObjectPtr CallTagHandler(Dart_LibraryTag tag,
                           const Object& arg1,
                           const Object& arg2);
  bool HasDeferredLoadHandler() const {
    return group()->deferred_load_handler() != nullptr;
  }
  ObjectPtr CallDeferredLoadHandler(intptr_t id);

  void SetupImagePage(const uint8_t* snapshot_buffer, bool is_executable);

  void ScheduleInterrupts(uword interrupt_bits);

  const char* MakeRunnable();
  void MakeRunnableLocked();
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

  Mutex* mutex() { return &mutex_; }

#if !defined(PRODUCT)
  Debugger* debugger() const { return debugger_; }

  void set_single_step(bool value) { single_step_ = value; }
  bool single_step() const { return single_step_; }
  static intptr_t single_step_offset() {
    return OFFSET_OF(Isolate, single_step_);
  }

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
  bool NotifyErrorListeners(const char* msg, const char* stacktrace);

  bool ErrorsFatal() const { return ErrorsFatalBit::decode(isolate_flags_); }
  void SetErrorsFatal(bool val) {
    isolate_flags_ = ErrorsFatalBit::update(val, isolate_flags_);
  }

  Random* random() { return &random_; }

  Simulator* simulator() const { return simulator_; }
  void set_simulator(Simulator* value) { simulator_ = value; }

  void IncrementSpawnCount();
  void DecrementSpawnCount();
  void WaitForOutstandingSpawns();

  static void SetCreateGroupCallback(Dart_IsolateGroupCreateCallback cb) {
    create_group_callback_ = cb;
  }
  static Dart_IsolateGroupCreateCallback CreateGroupCallback() {
    return create_group_callback_;
  }

  static void SetInitializeCallback_(Dart_InitializeIsolateCallback cb) {
    initialize_callback_ = cb;
  }
  static Dart_InitializeIsolateCallback InitializeCallback() {
    return initialize_callback_;
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

  static void SetGroupCleanupCallback(Dart_IsolateGroupCleanupCallback cb) {
    cleanup_group_callback_ = cb;
  }
  static Dart_IsolateGroupCleanupCallback GroupCleanupCallback() {
    return cleanup_group_callback_;
  }

#if !defined(PRODUCT)
  ObjectIdRing* object_id_ring() const { return object_id_ring_; }
  ObjectIdRing* EnsureObjectIdRing();
#endif  // !defined(PRODUCT)

  void AddPendingDeopt(uword fp, uword pc);
  uword FindPendingDeopt(uword fp) const;
  void ClearPendingDeoptsAtOrBelow(uword fp) const;
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts() const {
    return pending_deopts_;
  }
  bool IsDeoptimizing() const { return deopt_context_ != nullptr; }
  DeoptContext* deopt_context() const { return deopt_context_; }
  void set_deopt_context(DeoptContext* value) {
    ASSERT(value == nullptr || deopt_context_ == nullptr);
    deopt_context_ = value;
  }

  BackgroundCompiler* background_compiler() const {
    return background_compiler_;
  }

  BackgroundCompiler* optimizing_background_compiler() const {
    return optimizing_background_compiler_;
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

#ifndef PRODUCT
  void PrintJSON(JSONStream* stream, bool ref = true);

  // Creates an object with the total heap memory usage statistics for this
  // isolate.
  void PrintMemoryUsageJSON(JSONStream* stream);
#endif

#if !defined(PRODUCT)
  VMTagCounters* vm_tag_counters() { return &vm_tag_counters_; }

#if !defined(DART_PRECOMPILED_RUNTIME)
  IsolateReloadContext* reload_context() { return reload_context_; }

  void DeleteReloadContext();

  bool HasAttemptedReload() const {
    return HasAttemptedReloadBit::decode(isolate_flags_);
  }
  void SetHasAttemptedReload(bool value) {
    isolate_flags_ = HasAttemptedReloadBit::update(value, isolate_flags_);
  }

  bool CanReload() const;
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

  ErrorPtr PausePostRequest();

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

  GrowableObjectArrayPtr tag_table() const { return tag_table_; }
  void set_tag_table(const GrowableObjectArray& value);

  UserTagPtr current_tag() const { return current_tag_; }
  void set_current_tag(const UserTag& tag);

  UserTagPtr default_tag() const { return default_tag_; }
  void set_default_tag(const UserTag& tag);

  void set_ic_miss_code(const Code& code);

  GrowableObjectArrayPtr deoptimized_code_array() const {
    return deoptimized_code_array_;
  }
  void set_deoptimized_code_array(const GrowableObjectArray& value);
  void TrackDeoptimizedCode(const Code& code);

  // Also sends a paused at exit event over the service protocol.
  void SetStickyError(ErrorPtr sticky_error);

  ErrorPtr sticky_error() const { return sticky_error_; }
  DART_WARN_UNUSED_RESULT ErrorPtr StealStickyError();

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

  // Used by background compiler which field became boxed and must trigger
  // deoptimization in the mutator thread.
  void AddDeoptimizingBoxedField(const Field& field);
  // Returns Field::null() if none available in the list.
  FieldPtr GetDeoptimizingBoxedField();

#ifndef PRODUCT
  ErrorPtr InvokePendingServiceExtensionCalls();
  void AppendServiceExtensionCall(const Instance& closure,
                                  const String& method_name,
                                  const Array& parameter_keys,
                                  const Array& parameter_values,
                                  const Instance& reply_port,
                                  const Instance& id);
  void RegisterServiceExtensionHandler(const String& name,
                                       const Instance& closure);
  InstancePtr LookupServiceExtensionHandler(const String& name);
#endif

  static void VisitIsolates(IsolateVisitor* visitor);

#if !defined(PRODUCT)
  // Handle service messages until we are told to resume execution.
  void PauseEventHandler();
#endif

  void AddClosureFunction(const Function& function) const;
  FunctionPtr LookupClosureFunction(const Function& parent,
                                    TokenPosition token_pos) const;
  intptr_t FindClosureIndex(const Function& needle) const;
  FunctionPtr ClosureFunctionFromIndex(intptr_t idx) const;

  bool is_service_isolate() const {
    return IsServiceIsolateBit::decode(isolate_flags_);
  }
  void set_is_service_isolate(bool value) {
    isolate_flags_ = IsServiceIsolateBit::update(value, isolate_flags_);
  }

  bool is_kernel_isolate() const {
    return IsKernelIsolateBit::decode(isolate_flags_);
  }
  void set_is_kernel_isolate(bool value) {
    isolate_flags_ = IsKernelIsolateBit::update(value, isolate_flags_);
  }

  // Whether it's possible for unoptimized code to optimize immediately on entry
  // (can happen with random or very low optimization counter thresholds)
  bool CanOptimizeImmediately() const {
    return FLAG_optimization_counter_threshold < 2 ||
           FLAG_randomize_optimization_counter;
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

  const DispatchTable* dispatch_table() const {
    return group()->dispatch_table();
  }

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

#define FLAG_FOR_PRODUCT(from_field, from_flag) (from_field)

#define DECLARE_GETTER(when, name, bitname, isolate_flag_name, flag_name)      \
  bool name() const {                                                          \
    const bool false_by_default = false;                                       \
    USE(false_by_default);                                                     \
    return FLAG_FOR_##when(bitname##Bit::decode(isolate_flags_), flag_name);   \
  }
  BOOL_ISOLATE_FLAG_LIST_DEFAULT_GETTER(DECLARE_GETTER)
#undef FLAG_FOR_NONPRODUCT
#undef FLAG_FOR_PRECOMPILER
#undef FLAG_FOR_PRODUCT
#undef DECLARE_GETTER

#if defined(PRODUCT)
  void set_use_osr(bool use_osr) { ASSERT(!use_osr); }
#else   // defined(PRODUCT)
  void set_use_osr(bool use_osr) {
    isolate_flags_ = UseOsrBit::update(use_osr, isolate_flags_);
  }
#endif  // defined(PRODUCT)

  bool null_safety_not_set() const {
    return !NullSafetySetBit::decode(isolate_flags_);
  }

  bool null_safety() const {
    ASSERT(!null_safety_not_set());
    return NullSafetyBit::decode(isolate_flags_);
  }

  void set_null_safety(bool null_safety) {
    isolate_flags_ = NullSafetySetBit::update(true, isolate_flags_);
    isolate_flags_ = NullSafetyBit::update(null_safety, isolate_flags_);
  }

  bool use_strict_null_safety_checks() const {
    return null_safety() || FLAG_strict_null_safety_checks;
  }

  bool has_attempted_stepping() const {
    return HasAttemptedSteppingBit::decode(isolate_flags_);
  }
  void set_has_attempted_stepping(bool value) {
    isolate_flags_ = HasAttemptedSteppingBit::update(value, isolate_flags_);
  }

  static void KillAllIsolates(LibMsgId msg_id);
  static void KillIfExists(Isolate* isolate, LibMsgId msg_id);

  // Lookup an isolate by its main port. Returns nullptr if no matching isolate
  // is found.
  static Isolate* LookupIsolateByPort(Dart_Port port);

  // Lookup an isolate by its main port and return a copy of its name. Returns
  // nullptr if not matching isolate is found.
  static std::unique_ptr<char[]> LookupIsolateNameByPort(Dart_Port port);

  static void DisableIsolateCreation();
  static void EnableIsolateCreation();
  static bool IsolateCreationEnabled();
  static bool IsSystemIsolate(const Isolate* isolate) {
    return IsolateGroup::IsSystemIsolateGroup(isolate->group());
  }

#if !defined(PRODUCT)
  intptr_t reload_every_n_stack_overflow_checks() const {
    return reload_every_n_stack_overflow_checks_;
  }
#endif  // !defined(PRODUCT)

  HandlerInfoCache* handler_info_cache() { return &handler_info_cache_; }

  CatchEntryMovesCache* catch_entry_moves_cache() {
    return &catch_entry_moves_cache_;
  }

  void MaybeIncreaseReloadEveryNStackOverflowChecks();

  // The weak table used in the snapshot writer for the purpose of fast message
  // sending.
  WeakTable* forward_table_new() { return forward_table_new_.get(); }
  void set_forward_table_new(WeakTable* table);

  WeakTable* forward_table_old() { return forward_table_old_.get(); }
  void set_forward_table_old(WeakTable* table);

  static void NotifyLowMemory();

  void RememberLiveTemporaries();
  void DeferredMarkLiveTemporaries();

  std::unique_ptr<VirtualMemory> TakeRegexpBacktrackStack() {
    return std::move(regexp_backtracking_stack_cache_);
  }

  void CacheRegexpBacktrackStack(std::unique_ptr<VirtualMemory> stack) {
    regexp_backtracking_stack_cache_ = std::move(stack);
  }

 private:
  friend class Dart;                  // Init, InitOnce, Shutdown.
  friend class IsolateKillerVisitor;  // Kill().
  friend Isolate* CreateWithinExistingIsolateGroup(IsolateGroup* g,
                                                   const char* n,
                                                   char** e);

  Isolate(IsolateGroup* group, const Dart_IsolateFlags& api_flags);

  static void InitVM();
  static Isolate* InitIsolate(const char* name_prefix,
                              IsolateGroup* isolate_group,
                              const Dart_IsolateFlags& api_flags,
                              bool is_vm_isolate = false);

  // The isolate_creation_monitor_ should be held when calling Kill().
  void KillLocked(LibMsgId msg_id);

  void Shutdown();
  void LowLevelShutdown();

  // Unregister the [isolate] from the thread, remove it from the isolate group,
  // invoke the cleanup function (if any), delete the isolate and possibly
  // delete the isolate group (if it's the last isolate in the group).
  static void LowLevelCleanup(Isolate* isolate);

  void BuildName(const char* name_prefix);

  void ProfileIdle();

  // Visit all object pointers. Caller must ensure concurrent sweeper is not
  // running, and the visitor must not allocate.
  void VisitObjectPointers(ObjectPointerVisitor* visitor,
                           ValidationPolicy validate_frames);
  void VisitStackPointers(ObjectPointerVisitor* visitor,
                          ValidationPolicy validate_frames);

  void set_user_tag(uword tag) { user_tag_ = tag; }

  void set_is_system_isolate(bool is_system_isolate) {
    is_system_isolate_ = is_system_isolate;
  }

#if !defined(PRODUCT)
  GrowableObjectArrayPtr GetAndClearPendingServiceExtensionCalls();
  GrowableObjectArrayPtr pending_service_extension_calls() const {
    return pending_service_extension_calls_;
  }
  void set_pending_service_extension_calls(const GrowableObjectArray& value);
  GrowableObjectArrayPtr registered_service_extension_handlers() const {
    return registered_service_extension_handlers_;
  }
  void set_registered_service_extension_handlers(
      const GrowableObjectArray& value);
#endif  // !defined(PRODUCT)

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
  uword user_tag_ = 0;
  UserTagPtr current_tag_;
  UserTagPtr default_tag_;
  CodePtr ic_miss_code_;
  // Cached value of object_store_shared_ptr_, here for generated code access
  ObjectStore* cached_object_store_ = nullptr;
  SharedClassTable* shared_class_table_ = nullptr;
  // Cached value of class_table_->table_, here for generated code access
  ClassPtr* cached_class_table_table_ = nullptr;
  FieldTable* field_table_ = nullptr;
  bool single_step_ = false;
  bool is_system_isolate_ = false;
  // End accessed from generated code.

  IsolateGroup* isolate_group_;
  IdleTimeHandler idle_time_handler_;
  std::unique_ptr<IsolateObjectStore> isolate_object_store_;
  // shared in AOT(same pointer as on IsolateGroup), not shared in JIT
  std::shared_ptr<ObjectStore> object_store_shared_ptr_;
  // shared in AOT(same pointer as on IsolateGroup), not shared in JIT
  std::shared_ptr<ClassTable> class_table_;

#if !defined(DART_PRECOMPILED_RUNTIME)
  NativeCallbackTrampolines native_callback_trampolines_;
#endif

#define ISOLATE_FLAG_BITS(V)                                                   \
  V(ErrorsFatal)                                                               \
  V(IsRunnable)                                                                \
  V(IsServiceIsolate)                                                          \
  V(IsKernelIsolate)                                                           \
  V(AllClassesFinalized)                                                       \
  V(RemappingCids)                                                             \
  V(ResumeRequest)                                                             \
  V(HasAttemptedReload)                                                        \
  V(HasAttemptedStepping)                                                      \
  V(ShouldPausePostServiceRequest)                                             \
  V(EnableAsserts)                                                             \
  V(UseFieldGuards)                                                            \
  V(UseOsr)                                                                    \
  V(Obfuscate)                                                                 \
  V(CopyParentCode)                                                            \
  V(ShouldLoadVmService)                                                       \
  V(NullSafety)                                                                \
  V(NullSafetySet)                                                             \
  V(IsSystemIsolate)

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

  uint32_t isolate_flags_ = 0;

  // Unoptimized background compilation.
  BackgroundCompiler* background_compiler_ = nullptr;

  // Optimized background compilation.
  BackgroundCompiler* optimizing_background_compiler_ = nullptr;

// Fields that aren't needed in a product build go here with boolean flags at
// the top.
#if !defined(PRODUCT)
  Debugger* debugger_ = nullptr;
  int64_t last_resume_timestamp_;

  VMTagCounters vm_tag_counters_;

  // We use 6 list entries for each pending service extension calls.
  enum {kPendingHandlerIndex = 0, kPendingMethodNameIndex, kPendingKeysIndex,
        kPendingValuesIndex,      kPendingReplyPortIndex,  kPendingIdIndex,
        kPendingEntrySize};
  GrowableObjectArrayPtr pending_service_extension_calls_;

  // We use 2 list entries for each registered extension handler.
  enum {kRegisteredNameIndex = 0, kRegisteredHandlerIndex,
        kRegisteredEntrySize};
  GrowableObjectArrayPtr registered_service_extension_handlers_;

  // Used to wake the isolate when it is in the pause event loop.
  Monitor* pause_loop_monitor_ = nullptr;

#define ISOLATE_METRIC_VARIABLE(type, variable, name, unit)                    \
  type metric_##variable##_;
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_VARIABLE);
#undef ISOLATE_METRIC_VARIABLE

  RelaxedAtomic<intptr_t> no_reload_scope_depth_ =
      0;  // we can only reload when this is 0.
  // Per-isolate copy of FLAG_reload_every.
  intptr_t reload_every_n_stack_overflow_checks_;
  IsolateReloadContext* reload_context_ = nullptr;
  // Ring buffer of objects assigned an id.
  ObjectIdRing* object_id_ring_ = nullptr;
#endif  // !defined(PRODUCT)

  // All other fields go here.
  int64_t start_time_micros_;
  Dart_MessageNotifyCallback message_notify_callback_ = nullptr;
  Dart_IsolateShutdownCallback on_shutdown_callback_ = nullptr;
  Dart_IsolateCleanupCallback on_cleanup_callback_ = nullptr;
  char* name_ = nullptr;
  Dart_Port main_port_ = 0;
  // Isolates created by Isolate.spawn have the same origin id.
  Dart_Port origin_id_ = 0;
  Mutex origin_id_mutex_;
  uint64_t pause_capability_ = 0;
  uint64_t terminate_capability_ = 0;
  void* init_callback_data_ = nullptr;
  Dart_EnvironmentCallback environment_callback_ = nullptr;
  Random random_;
  Simulator* simulator_ = nullptr;
  Mutex mutex_;                            // Protects compiler stats.
  MessageHandler* message_handler_ = nullptr;
  intptr_t defer_finalization_count_ = 0;
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts_;
  DeoptContext* deopt_context_ = nullptr;

  GrowableObjectArrayPtr tag_table_;

  GrowableObjectArrayPtr deoptimized_code_array_;

  ErrorPtr sticky_error_;

  std::unique_ptr<Bequest> bequest_;
  Dart_Port beneficiary_ = 0;

  // Protect access to boxed_field_list_.
  Mutex field_list_mutex_;
  // List of fields that became boxed and that trigger deoptimization.
  GrowableObjectArrayPtr boxed_field_list_;

  // This guards spawn_count_. An isolate cannot complete shutdown and be
  // destroyed while there are child isolates in the midst of a spawn.
  Monitor spawn_count_monitor_;
  intptr_t spawn_count_ = 0;

  HandlerInfoCache handler_info_cache_;
  CatchEntryMovesCache catch_entry_moves_cache_;

  Dart_QualifiedFunctionName* embedder_entry_points_ = nullptr;
  const char** obfuscation_map_ = nullptr;

  DispatchTable* dispatch_table_ = nullptr;

  // Used during message sending of messages between isolates.
  std::unique_ptr<WeakTable> forward_table_new_;
  std::unique_ptr<WeakTable> forward_table_old_;

  // Signals whether the isolate can receive messages (e.g. KillAllIsolates can
  // send a kill message).
  // This is protected by [isolate_creation_monitor_].
  bool accepts_messages_ = false;

  std::unique_ptr<VirtualMemory> regexp_backtracking_stack_cache_ = nullptr;

  static Dart_IsolateGroupCreateCallback create_group_callback_;
  static Dart_InitializeIsolateCallback initialize_callback_;
  static Dart_IsolateShutdownCallback shutdown_callback_;
  static Dart_IsolateCleanupCallback cleanup_callback_;
  static Dart_IsolateGroupCleanupCallback cleanup_group_callback_;

#if !defined(PRODUCT)
  static void WakePauseEventHandler(Dart_Isolate isolate);
#endif

  // Manage list of existing isolates.
  static bool TryMarkIsolateReady(Isolate* isolate);
  static void UnMarkIsolateReady(Isolate* isolate);
  static void MaybeNotifyVMShutdown();
  bool AcceptsMessagesLocked() {
    ASSERT(isolate_creation_monitor_->IsOwnedByCurrentThread());
    return accepts_messages_;
  }

  // This monitor protects [creation_enabled_].
  static Monitor* isolate_creation_monitor_;
  static bool creation_enabled_;

#define REUSABLE_FRIEND_DECLARATION(name)                                      \
  friend class Reusable##name##HandleScope;
  REUSABLE_HANDLE_LIST(REUSABLE_FRIEND_DECLARATION)
#undef REUSABLE_FRIEND_DECLARATION

  friend class Become;       // VisitObjectPointers
  friend class GCCompactor;  // VisitObjectPointers
  friend class GCMarker;     // VisitObjectPointers
  friend class SafepointHandler;
  friend class ObjectGraph;         // VisitObjectPointers
  friend class HeapSnapshotWriter;  // VisitObjectPointers
  friend class Scavenger;           // VisitObjectPointers
  friend class HeapIterationScope;  // VisitObjectPointers
  friend class ServiceIsolate;
  friend class Thread;
  friend class Timeline;
  friend class NoReloadScope;  // reload_block
  friend class IsolateGroup;   // reload_context_

  DISALLOW_COPY_AND_ASSIGN(Isolate);
};

// When we need to execute code in an isolate, we use the
// StartIsolateScope.
class StartIsolateScope {
 public:
  explicit StartIsolateScope(Isolate* new_isolate)
      : new_isolate_(new_isolate), saved_isolate_(Isolate::Current()) {
    if (new_isolate_ == nullptr) {
      ASSERT(Isolate::Current() == nullptr);
      // Do nothing.
      return;
    }
    if (saved_isolate_ != new_isolate_) {
      ASSERT(Isolate::Current() == nullptr);
      Thread::EnterIsolate(new_isolate_);
      // Ensure this is not a nested 'isolate enter' with prior state.
      ASSERT(Thread::Current()->saved_stack_limit() == 0);
    }
  }

  ~StartIsolateScope() {
    if (new_isolate_ == nullptr) {
      ASSERT(Isolate::Current() == nullptr);
      // Do nothing.
      return;
    }
    if (saved_isolate_ != new_isolate_) {
      ASSERT(saved_isolate_ == nullptr);
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

class EnterIsolateGroupScope {
 public:
  explicit EnterIsolateGroupScope(IsolateGroup* isolate_group)
      : isolate_group_(isolate_group) {
    ASSERT(IsolateGroup::Current() == nullptr);
    const bool result = Thread::EnterIsolateGroupAsHelper(
        isolate_group_, Thread::kUnknownTask, /*bypass_safepoint=*/false);
    ASSERT(result);
  }

  ~EnterIsolateGroupScope() {
    Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/false);
  }

 private:
  IsolateGroup* isolate_group_;

  DISALLOW_COPY_AND_ASSIGN(EnterIsolateGroupScope);
};

}  // namespace dart

#endif  // RUNTIME_VM_ISOLATE_H_
