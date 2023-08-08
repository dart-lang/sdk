// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <utility>

#include "vm/isolate.h"

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/text_buffer.h"
#include "vm/canonical_tables.h"
#include "vm/class_finalizer.h"
#include "vm/code_observers.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/dispatch_table.h"
#include "vm/ffi_callback_metadata.h"
#include "vm/flags.h"
#include "vm/heap/heap.h"
#include "vm/heap/pointer_block.h"
#include "vm/heap/safepoint.h"
#include "vm/heap/verifier.h"
#include "vm/image_snapshot.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/os_thread.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reusable_handles.h"
#include "vm/reverse_pc_lookup_cache.h"
#include "vm/service.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/simulator.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/tags.h"
#include "vm/thread.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_registry.h"
#include "vm/timeline.h"
#include "vm/visitor.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/stub_code_compiler.h"
#endif

namespace dart {

DECLARE_FLAG(bool, print_metrics);
DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_shutdown);
DECLARE_FLAG(bool, warn_on_pause_with_no_debugger);
DECLARE_FLAG(int, old_gen_growth_time_ratio);

// Reload flags.
DECLARE_FLAG(int, reload_every);
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
DECLARE_FLAG(bool, check_reloaded);
DECLARE_FLAG(bool, reload_every_back_off);
DECLARE_FLAG(bool, trace_reload);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

static void DeterministicModeHandler(bool value) {
  if (value) {
    FLAG_background_compilation = false;  // Timing dependent.
    FLAG_concurrent_mark = false;         // Timing dependent.
    FLAG_concurrent_sweep = false;        // Timing dependent.
    FLAG_scavenger_tasks = 0;             // Timing dependent.
    FLAG_old_gen_growth_time_ratio = 0;   // Timing dependent.
    FLAG_random_seed = 0x44617274;        // "Dart"
  }
}

DEFINE_FLAG_HANDLER(DeterministicModeHandler,
                    deterministic,
                    "Enable deterministic mode.");

DEFINE_FLAG(bool,
            disable_thread_pool_limit,
            false,
            "Disables the limit of the thread pool (simulates custom embedder "
            "with custom message handler on unlimited number of threads).");

// Quick access to the locally defined thread() and isolate() methods.
#define T (thread())
#define I (isolate())
#define IG (isolate_group())

#if defined(DEBUG)
// Helper class to ensure that a live origin_id is never reused
// and assigned to an isolate.
class VerifyOriginId : public IsolateVisitor {
 public:
  explicit VerifyOriginId(Dart_Port id) : id_(id) {}

  void VisitIsolate(Isolate* isolate) { ASSERT(isolate->origin_id() != id_); }

 private:
  Dart_Port id_;
  DISALLOW_COPY_AND_ASSIGN(VerifyOriginId);
};
#endif

static std::unique_ptr<Message> SerializeMessage(Dart_Port dest_port,
                                                 const Instance& obj) {
  return WriteMessage(/* same_group */ false, obj, dest_port,
                      Message::kNormalPriority);
}

static std::unique_ptr<Message> SerializeMessage(Zone* zone,
                                                 Dart_Port dest_port,
                                                 Dart_CObject* obj) {
  return WriteApiMessage(zone, obj, dest_port, Message::kNormalPriority);
}

void IsolateGroupSource::add_loaded_blob(
    Zone* zone,
    const ExternalTypedData& external_typed_data) {
  Array& loaded_blobs = Array::Handle();
  bool saved_external_typed_data = false;
  if (loaded_blobs_ != nullptr) {
    loaded_blobs = loaded_blobs_;

    // Walk the array, and (if stuff was removed) compact and reuse the space.
    // Note that the space has to be compacted as the ordering is important.
    WeakProperty& weak_property = WeakProperty::Handle();
    WeakProperty& weak_property_tmp = WeakProperty::Handle();
    ExternalTypedData& existing_entry = ExternalTypedData::Handle(zone);
    intptr_t next_entry_index = 0;
    for (intptr_t i = 0; i < loaded_blobs.Length(); i++) {
      weak_property ^= loaded_blobs.At(i);
      if (weak_property.key() != ExternalTypedData::null()) {
        if (i != next_entry_index) {
          existing_entry = ExternalTypedData::RawCast(weak_property.key());
          weak_property_tmp ^= loaded_blobs.At(next_entry_index);
          weak_property_tmp.set_key(existing_entry);
        }
        next_entry_index++;
      }
    }
    if (next_entry_index < loaded_blobs.Length()) {
      // There's now space to re-use.
      weak_property ^= loaded_blobs.At(next_entry_index);
      weak_property.set_key(external_typed_data);
      next_entry_index++;
      saved_external_typed_data = true;
    }
    if (next_entry_index < loaded_blobs.Length()) {
      ExternalTypedData& nullExternalTypedData =
          ExternalTypedData::Handle(zone);
      while (next_entry_index < loaded_blobs.Length()) {
        // Null out any extra spaces.
        weak_property ^= loaded_blobs.At(next_entry_index);
        weak_property.set_key(nullExternalTypedData);
        next_entry_index++;
      }
    }
  }
  if (!saved_external_typed_data) {
    const WeakProperty& weak_property =
        WeakProperty::Handle(WeakProperty::New(Heap::kOld));
    weak_property.set_key(external_typed_data);

    intptr_t length = loaded_blobs.IsNull() ? 0 : loaded_blobs.Length();
    Array& new_array =
        Array::Handle(Array::Grow(loaded_blobs, length + 1, Heap::kOld));
    new_array.SetAt(length, weak_property);
    loaded_blobs_ = new_array.ptr();
  }
  num_blob_loads_++;
}

void IdleTimeHandler::InitializeWithHeap(Heap* heap) {
  MutexLocker ml(&mutex_);
  ASSERT(heap_ == nullptr && heap != nullptr);
  heap_ = heap;
}

bool IdleTimeHandler::ShouldCheckForIdle() {
  MutexLocker ml(&mutex_);
  return idle_start_time_ > 0 && FLAG_idle_timeout_micros != 0 &&
         disabled_counter_ == 0;
}

void IdleTimeHandler::UpdateStartIdleTime() {
  MutexLocker ml(&mutex_);
  if (disabled_counter_ == 0) {
    idle_start_time_ = OS::GetCurrentMonotonicMicros();
  }
}

bool IdleTimeHandler::ShouldNotifyIdle(int64_t* expiry) {
  const int64_t now = OS::GetCurrentMonotonicMicros();

  MutexLocker ml(&mutex_);
  if (idle_start_time_ > 0 && disabled_counter_ == 0) {
    const int64_t expiry_time = idle_start_time_ + FLAG_idle_timeout_micros;
    if (expiry_time < now) {
      idle_start_time_ = 0;
      return true;
    }
  }

  *expiry = now + FLAG_idle_timeout_micros;
  return false;
}

void IdleTimeHandler::NotifyIdle(int64_t deadline) {
  {
    MutexLocker ml(&mutex_);
    disabled_counter_++;
  }
  if (heap_ != nullptr) {
    heap_->NotifyIdle(deadline);
  }
  {
    MutexLocker ml(&mutex_);
    disabled_counter_--;
    idle_start_time_ = 0;
  }
}

void IdleTimeHandler::NotifyIdleUsingDefaultDeadline() {
  const int64_t now = OS::GetCurrentMonotonicMicros();
  NotifyIdle(now + FLAG_idle_duration_micros);
}

DisableIdleTimerScope::DisableIdleTimerScope(IdleTimeHandler* handler)
    : handler_(handler) {
  if (handler_ != nullptr) {
    MutexLocker ml(&handler_->mutex_);
    ++handler_->disabled_counter_;
    handler_->idle_start_time_ = 0;
  }
}

DisableIdleTimerScope::~DisableIdleTimerScope() {
  if (handler_ != nullptr) {
    MutexLocker ml(&handler_->mutex_);
    --handler_->disabled_counter_;
    ASSERT(handler_->disabled_counter_ >= 0);
  }
}

class FinalizeWeakPersistentHandlesVisitor : public HandleVisitor {
 public:
  explicit FinalizeWeakPersistentHandlesVisitor(IsolateGroup* isolate_group)
      : HandleVisitor(Thread::Current()), isolate_group_(isolate_group) {}

  void VisitHandle(uword addr) override {
    auto handle = reinterpret_cast<FinalizablePersistentHandle*>(addr);
    handle->UpdateUnreachable(isolate_group_);
  }

 private:
  IsolateGroup* isolate_group_;

  DISALLOW_COPY_AND_ASSIGN(FinalizeWeakPersistentHandlesVisitor);
};

void MutatorThreadPool::OnEnterIdleLocked(MonitorLocker* ml) {
  if (FLAG_idle_timeout_micros == 0) return;

  // If the isolate has not started running application code yet, we ignore the
  // idle time.
  if (!isolate_group_->initial_spawn_successful()) return;

  int64_t idle_expiry = 0;
  // Obtain the idle time we should wait.
  if (isolate_group_->idle_time_handler()->ShouldNotifyIdle(&idle_expiry)) {
    MonitorLeaveScope mls(ml);
    NotifyIdle();
    return;
  }

  // Avoid shutdown having to wait for the timeout to expire.
  if (ShuttingDownLocked()) return;

  // Wait for the recommended idle timeout.
  // We can be woken up because of a), b) or c)
  const auto result =
      ml->WaitMicros(idle_expiry - OS::GetCurrentMonotonicMicros());

  // a) If there are new tasks we have to run them.
  if (TasksWaitingToRunLocked()) return;

  // b) If the thread pool is shutting down we're done.
  if (ShuttingDownLocked()) return;

  // c) We timed out and should run the idle notifier.
  if (result == Monitor::kTimedOut &&
      isolate_group_->idle_time_handler()->ShouldNotifyIdle(&idle_expiry)) {
    MonitorLeaveScope mls(ml);
    NotifyIdle();
    return;
  }

  // There must've been another thread doing active work in the meantime.
  // If that thread becomes idle and is the last idle thread it will run this
  // code again.
}

void MutatorThreadPool::NotifyIdle() {
  EnterIsolateGroupScope isolate_group_scope(isolate_group_);
  isolate_group_->idle_time_handler()->NotifyIdleUsingDefaultDeadline();
}

IsolateGroup::IsolateGroup(std::shared_ptr<IsolateGroupSource> source,
                           void* embedder_data,
                           ObjectStore* object_store,
                           Dart_IsolateFlags api_flags)
    : class_table_(nullptr),
      cached_class_table_table_(nullptr),
      object_store_(object_store),
      class_table_allocator_(),
      embedder_data_(embedder_data),
      thread_pool_(),
      isolates_lock_(new SafepointRwLock()),
      isolates_(),
      start_time_micros_(OS::GetCurrentMonotonicMicros()),
      is_system_isolate_group_(source->flags.is_system_isolate),
      random_(),
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
      last_reload_timestamp_(OS::GetCurrentTimeMillis()),
      reload_every_n_stack_overflow_checks_(FLAG_reload_every),
#endif
      source_(std::move(source)),
      api_state_(new ApiState()),
      thread_registry_(new ThreadRegistry()),
      safepoint_handler_(new SafepointHandler(this)),
      store_buffer_(new StoreBuffer()),
      heap_(nullptr),
      saved_unlinked_calls_(Array::null()),
      initial_field_table_(new FieldTable(/*isolate=*/nullptr)),
#if !defined(DART_PRECOMPILED_RUNTIME)
      background_compiler_(new BackgroundCompiler(this)),
#endif
      symbols_mutex_(NOT_IN_PRODUCT("IsolateGroup::symbols_mutex_")),
      type_canonicalization_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::type_canonicalization_mutex_")),
      type_arguments_canonicalization_mutex_(NOT_IN_PRODUCT(
          "IsolateGroup::type_arguments_canonicalization_mutex_")),
      subtype_test_cache_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::subtype_test_cache_mutex_")),
      megamorphic_table_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::megamorphic_table_mutex_")),
      type_feedback_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::type_feedback_mutex_")),
      patchable_call_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::patchable_call_mutex_")),
      constant_canonicalization_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::constant_canonicalization_mutex_")),
      kernel_data_lib_cache_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::kernel_data_lib_cache_mutex_")),
      kernel_data_class_cache_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::kernel_data_class_cache_mutex_")),
      kernel_constants_mutex_(
          NOT_IN_PRODUCT("IsolateGroup::kernel_constants_mutex_")),
      field_list_mutex_(NOT_IN_PRODUCT("Isolate::field_list_mutex_")),
      boxed_field_list_(GrowableObjectArray::null()),
      program_lock_(new SafepointRwLock()),
      active_mutators_monitor_(new Monitor()),
      max_active_mutators_(Scavenger::MaxMutatorThreadCount())
#if !defined(PRODUCT)
      ,
      debugger_(new GroupDebugger(this))
#endif
{
  FlagsCopyFrom(api_flags);
  const bool is_vm_isolate = Dart::VmIsolateNameEquals(source_->name);
  if (!is_vm_isolate) {
    thread_pool_.reset(
        new MutatorThreadPool(this, FLAG_disable_thread_pool_limit
                                        ? 0
                                        : Scavenger::MaxMutatorThreadCount()));
  }
  {
    WriteRwLocker wl(ThreadState::Current(), isolate_groups_rwlock_);
    // Keep isolate IDs less than 2^53 so web clients of the service
    // protocol can process it properly.
    //
    // See https://github.com/dart-lang/sdk/issues/53081.
    id_ = isolate_group_random_->NextJSInt();
  }
  heap_walk_class_table_ = class_table_ =
      new ClassTable(&class_table_allocator_);
  cached_class_table_table_.store(class_table_->table());
}

IsolateGroup::IsolateGroup(std::shared_ptr<IsolateGroupSource> source,
                           void* embedder_data,
                           Dart_IsolateFlags api_flags)
    : IsolateGroup(source, embedder_data, new ObjectStore(), api_flags) {
  if (object_store() != nullptr) {
    object_store()->InitStubs();
  }
}

IsolateGroup::~IsolateGroup() {
  // Ensure we destroy the heap before the other members.
  heap_ = nullptr;
  ASSERT(marking_stack_ == nullptr);

  if (obfuscation_map_ != nullptr) {
    for (intptr_t i = 0; obfuscation_map_[i] != nullptr; i++) {
      delete[] obfuscation_map_[i];
    }
    delete[] obfuscation_map_;
  }

  class_table_allocator_.Free(class_table_);
  if (heap_walk_class_table_ != class_table_) {
    class_table_allocator_.Free(heap_walk_class_table_);
  }

#if !defined(PRODUCT)
  delete debugger_;
  debugger_ = nullptr;
#endif
}

void IsolateGroup::RegisterIsolate(Isolate* isolate) {
  SafepointWriteRwLocker ml(Thread::Current(), isolates_lock_.get());
  ASSERT(isolates_lock_->IsCurrentThreadWriter());
  isolates_.Append(isolate);
  isolate_count_++;
}

bool IsolateGroup::ContainsOnlyOneIsolate() {
  SafepointReadRwLocker ml(Thread::Current(), isolates_lock_.get());
  // We do allow 0 here as well, because the background compiler might call
  // this method while the mutator thread is in shutdown procedure and
  // unregistered itself already.
  return isolate_count_ == 0 || isolate_count_ == 1;
}

void IsolateGroup::RunWithLockedGroup(std::function<void()> fun) {
  SafepointWriteRwLocker ml(Thread::Current(), isolates_lock_.get());
  fun();
}

void IsolateGroup::UnregisterIsolate(Isolate* isolate) {
  SafepointWriteRwLocker ml(Thread::Current(), isolates_lock_.get());
  isolates_.Remove(isolate);
}

bool IsolateGroup::UnregisterIsolateDecrementCount() {
  SafepointWriteRwLocker ml(Thread::Current(), isolates_lock_.get());
  isolate_count_--;
  return isolate_count_ == 0;
}

void IsolateGroup::CreateHeap(bool is_vm_isolate,
                              bool is_service_or_kernel_isolate) {
  Heap::Init(this, is_vm_isolate,
             is_vm_isolate
                 ? 0  // New gen size 0; VM isolate should only allocate in old.
                 : FLAG_new_gen_semi_max_size * MBInWords,
             (is_service_or_kernel_isolate ? kDefaultMaxOldGenHeapSize
                                           : FLAG_old_gen_heap_size) *
                 MBInWords);

  is_vm_isolate_heap_ = is_vm_isolate;

#define ISOLATE_GROUP_METRIC_CONSTRUCTORS(type, variable, name, unit)          \
  metric_##variable##_.InitInstance(this, name, nullptr, Metric::unit);
  ISOLATE_GROUP_METRIC_LIST(ISOLATE_GROUP_METRIC_CONSTRUCTORS)
#undef ISOLATE_GROUP_METRIC_CONSTRUCTORS
}

void IsolateGroup::Shutdown() {
  char* name = nullptr;
  // We retrieve the flag value once to avoid the compiler complaining about the
  // possibly uninitialized value of name, as the compiler is unaware that when
  // the flag variable is non-const, it is set once during VM initialization and
  // never changed after, and that modification never runs concurrently with
  // this method.
  const bool trace_shutdown = FLAG_trace_shutdown;

  if (trace_shutdown) {
    name = Utils::StrDup(source()->name);
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutdown starting for group %s\n",
                 Dart::UptimeMillis(), name);
  }
  // Ensure to join all threads before waiting for pending GC tasks (the thread
  // pool can trigger idle notification, which can start new GC tasks).
  //
  // (The vm-isolate doesn't have a thread pool.)
  if (!Dart::VmIsolateNameEquals(source()->name)) {
    ASSERT(thread_pool_ != nullptr);
    thread_pool_->Shutdown();
    thread_pool_.reset();
  }

  // Wait for any pending GC tasks.
  if (heap_ != nullptr) {
    // Wait for any concurrent GC tasks to finish before shutting down.
    // TODO(rmacnak): Interrupt tasks for faster shutdown.
    PageSpace* old_space = heap_->old_space();
    MonitorLocker ml(old_space->tasks_lock());
    while (old_space->tasks() > 0) {
      ml.Wait();
    }
    // Needs to happen before ~PageSpace so TLS and the thread registry are
    // still valid.
    old_space->AbandonMarkingForShutdown();
  }

  UnregisterIsolateGroup(this);

  // If the creation of the isolate group (or the first isolate within the
  // isolate group) failed, we do not invoke the cleanup callback (the
  // embedder is responsible for handling the creation error).
  if (initial_spawn_successful_) {
    auto group_shutdown_callback = Isolate::GroupCleanupCallback();
    if (group_shutdown_callback != nullptr) {
      group_shutdown_callback(embedder_data());
    }
  }

  delete this;

  // After this isolate group has died we might need to notify a pending
  // `Dart_Cleanup()` call.
  {
    if (trace_shutdown) {
      OS::PrintErr("[+%" Pd64
                   "ms] SHUTDOWN: Notifying "
                   "isolate group shutdown (%s)\n",
                   Dart::UptimeMillis(), name);
    }
    MonitorLocker ml(Isolate::isolate_creation_monitor_);
    if (!Isolate::creation_enabled_ &&
        !IsolateGroup::HasApplicationIsolateGroups()) {
      ml.Notify();
    }
    if (trace_shutdown) {
      OS::PrintErr("[+%" Pd64
                   "ms] SHUTDOWN: Done Notifying "
                   "isolate group shutdown (%s)\n",
                   Dart::UptimeMillis(), name);
    }
  }
  if (trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done shutdown for group %s\n",
                 Dart::UptimeMillis(), name);
    free(name);
  }
}

void IsolateGroup::set_heap(std::unique_ptr<Heap> heap) {
  idle_time_handler_.InitializeWithHeap(heap.get());
  heap_ = std::move(heap);
}

void IsolateGroup::set_saved_unlinked_calls(const Array& saved_unlinked_calls) {
  saved_unlinked_calls_ = saved_unlinked_calls.ptr();
}

void IsolateGroup::IncreaseMutatorCount(Isolate* mutator,
                                        bool is_nested_reenter) {
  ASSERT(mutator->group() == this);

  // If the mutator was temporarily blocked on a worker thread, we have to
  // unblock the worker thread again.
  if (is_nested_reenter) {
    ASSERT(mutator->mutator_thread() != nullptr);
    thread_pool()->MarkCurrentWorkerAsUnBlocked();
  }

  // Prevent too many mutators from entering the isolate group to avoid
  // pathological behavior where many threads are fighting for obtaining TLABs.
  {
    // NOTE: This is performance critical code, we should avoid monitors and use
    // std::atomics in the fast case (where active_mutators <
    // max_active_mutators) and only use monitors in the uncommon case.
    MonitorLocker ml(active_mutators_monitor_.get());
    ASSERT(active_mutators_ <= max_active_mutators_);
    while (active_mutators_ == max_active_mutators_) {
      waiting_mutators_++;
      ml.Wait();
      waiting_mutators_--;
    }
    active_mutators_++;
  }
}

void IsolateGroup::DecreaseMutatorCount(Isolate* mutator, bool is_nested_exit) {
  ASSERT(mutator->group() == this);

  // If the mutator thread has an active stack and runs on our thread pool we
  // will mark the worker as blocked, thereby possibly spawning a new worker for
  // pending tasks (if there are any).
  if (is_nested_exit) {
    ASSERT(mutator->mutator_thread() != nullptr);
    thread_pool()->MarkCurrentWorkerAsBlocked();
  }

  {
    // NOTE: This is performance critical code, we should avoid monitors and use
    // std::atomics in the fast case (where active_mutators <
    // max_active_mutators) and only use monitors in the uncommon case.
    MonitorLocker ml(active_mutators_monitor_.get());
    ASSERT(active_mutators_ <= max_active_mutators_);
    active_mutators_--;
    if (waiting_mutators_ > 0) {
      ml.Notify();
    }
  }
}

#ifndef PRODUCT
void IsolateGroup::PrintJSON(JSONStream* stream, bool ref) {
  JSONObject jsobj(stream);
  PrintToJSONObject(&jsobj, ref);
}

void IsolateGroup::PrintToJSONObject(JSONObject* jsobj, bool ref) {
  jsobj->AddProperty("type", (ref ? "@IsolateGroup" : "IsolateGroup"));
  jsobj->AddServiceId(ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING, id());

  jsobj->AddProperty("name", source()->script_uri);
  jsobj->AddPropertyF("number", "%" Pu64 "", id());
  jsobj->AddProperty("isSystemIsolateGroup", is_system_isolate_group());
  if (ref) {
    return;
  }

  {
    JSONArray isolate_array(jsobj, "isolates");
    for (auto it = isolates_.Begin(); it != isolates_.End(); ++it) {
      Isolate* isolate = *it;
      isolate_array.AddValue(isolate, /*ref=*/true);
    }
  }
}

void IsolateGroup::PrintMemoryUsageJSON(JSONStream* stream) {
  int64_t used = heap()->TotalUsedInWords();
  int64_t capacity = heap()->TotalCapacityInWords();
  int64_t external_used = heap()->TotalExternalInWords();

  JSONObject jsobj(stream);
  // This is the same "MemoryUsage" that the isolate-specific "getMemoryUsage"
  // rpc method returns.
  jsobj.AddProperty("type", "MemoryUsage");
  jsobj.AddProperty64("heapUsage", used * kWordSize);
  jsobj.AddProperty64("heapCapacity", capacity * kWordSize);
  jsobj.AddProperty64("externalUsage", external_used * kWordSize);
}
#endif

void IsolateGroup::ForEach(std::function<void(IsolateGroup*)> action) {
  ReadRwLocker wl(Thread::Current(), isolate_groups_rwlock_);
  for (auto isolate_group : *isolate_groups_) {
    action(isolate_group);
  }
}

void IsolateGroup::RunWithIsolateGroup(
    uint64_t id,
    std::function<void(IsolateGroup*)> action,
    std::function<void()> not_found) {
  ReadRwLocker wl(Thread::Current(), isolate_groups_rwlock_);
  for (auto isolate_group : *isolate_groups_) {
    if (isolate_group->id() == id) {
      action(isolate_group);
      return;
    }
  }
  not_found();
}

void IsolateGroup::RegisterIsolateGroup(IsolateGroup* isolate_group) {
  WriteRwLocker wl(ThreadState::Current(), isolate_groups_rwlock_);
  isolate_groups_->Append(isolate_group);
}

void IsolateGroup::UnregisterIsolateGroup(IsolateGroup* isolate_group) {
  WriteRwLocker wl(ThreadState::Current(), isolate_groups_rwlock_);
  isolate_groups_->Remove(isolate_group);
}

bool IsolateGroup::HasApplicationIsolateGroups() {
  ReadRwLocker wl(ThreadState::Current(), isolate_groups_rwlock_);
  for (auto group : *isolate_groups_) {
    if (!IsolateGroup::IsSystemIsolateGroup(group)) {
      return true;
    }
  }
  return false;
}

bool IsolateGroup::HasOnlyVMIsolateGroup() {
  ReadRwLocker wl(ThreadState::Current(), isolate_groups_rwlock_);
  for (auto group : *isolate_groups_) {
    if (!Dart::VmIsolateNameEquals(group->source()->name)) {
      return false;
    }
  }
  return true;
}

void IsolateGroup::Init() {
  ASSERT(isolate_groups_rwlock_ == nullptr);
  isolate_groups_rwlock_ = new RwLock();
  ASSERT(isolate_groups_ == nullptr);
  isolate_groups_ = new IntrusiveDList<IsolateGroup>();
  isolate_group_random_ = new Random();
}

void IsolateGroup::Cleanup() {
  delete isolate_group_random_;
  isolate_group_random_ = nullptr;
  delete isolate_groups_rwlock_;
  isolate_groups_rwlock_ = nullptr;
  ASSERT(isolate_groups_->IsEmpty());
  delete isolate_groups_;
  isolate_groups_ = nullptr;
}

bool IsolateVisitor::IsSystemIsolate(Isolate* isolate) const {
  return Isolate::IsSystemIsolate(isolate);
}

Bequest::~Bequest() {
  if (handle_ == nullptr) {
    return;
  }

  IsolateGroup* isolate_group = IsolateGroup::Current();
  CHECK_ISOLATE_GROUP(isolate_group);
  NoSafepointScope no_safepoint_scope;
  ApiState* state = isolate_group->api_state();
  ASSERT(state != nullptr);
  state->FreePersistentHandle(handle_);
}

void IsolateGroup::RegisterClass(const Class& cls) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (IsReloading()) {
    program_reload_context()->RegisterClass(cls);
    return;
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (cls.IsTopLevel()) {
    class_table()->RegisterTopLevel(cls);
  } else {
    class_table()->Register(cls);
  }
}

#if defined(DEBUG)
void IsolateGroup::ValidateClassTable() {
  class_table()->Validate();
}
#endif  // DEBUG

void IsolateGroup::RegisterStaticField(const Field& field,
                                       const Object& initial_value) {
  ASSERT(program_lock()->IsCurrentThreadWriter());

  ASSERT(field.is_static());
  const bool need_to_grow_backing_store =
      initial_field_table()->Register(field);
  const intptr_t field_id = field.field_id();
  initial_field_table()->SetAt(field_id, initial_value.ptr());

  SafepointReadRwLocker ml(Thread::Current(), isolates_lock_.get());
  if (need_to_grow_backing_store) {
    // We have to stop other isolates from accessing their field state, since
    // we'll have to grow the backing store.
    GcSafepointOperationScope scope(Thread::Current());
    for (auto isolate : isolates_) {
      auto field_table = isolate->field_table();
      if (field_table->IsReadyToUse()) {
        field_table->Register(field, field_id);
        field_table->SetAt(field_id, initial_value.ptr());
      }
    }
  } else {
    for (auto isolate : isolates_) {
      auto field_table = isolate->field_table();
      if (field_table->IsReadyToUse()) {
        field_table->Register(field, field_id);
        field_table->SetAt(field_id, initial_value.ptr());
      }
    }
  }
}

void IsolateGroup::FreeStaticField(const Field& field) {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // This can only be called during hot-reload.
  ASSERT(program_reload_context() != nullptr);
#endif

  const intptr_t field_id = field.field_id();
  initial_field_table()->Free(field_id);
  ForEachIsolate([&](Isolate* isolate) {
    auto field_table = isolate->field_table();
    // The isolate might've just been created and is now participating in
    // the reload request inside `IsolateGroup::RegisterIsolate()`.
    // At that point it doesn't have the field table setup yet.
    if (field_table->IsReadyToUse()) {
      field_table->Free(field_id);
    }
  });
}

Isolate* IsolateGroup::EnterTemporaryIsolate() {
  Dart_IsolateFlags flags;
  Isolate::FlagsInitialize(&flags);
  Isolate* const isolate = Isolate::InitIsolate("temp", this, flags);
  ASSERT(isolate != nullptr);
  ASSERT(Isolate::Current() == isolate);
  return isolate;
}

void IsolateGroup::ExitTemporaryIsolate() {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  thread->set_execution_state(Thread::kThreadInVM);
  Dart::ShutdownIsolate(thread);
}

void IsolateGroup::RehashConstants(Become* become) {
  // Even though no individual constant contains a cycle, there can be "cycles"
  // between the canonical tables if some const instances of A have fields that
  // are const instance of B and vice versa. So set all the old tables to the
  // side and clear all the tables attached to the classes before rehashing
  // instead of resetting and rehash one class at a time.

  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();

  intptr_t num_cids = class_table()->NumCids();
  Array** old_constant_tables = zone->Alloc<Array*>(num_cids);
  for (intptr_t i = 0; i < num_cids; i++) {
    old_constant_tables[i] = nullptr;
  }

  Class& cls = Class::Handle(zone);
  for (intptr_t cid = kInstanceCid; cid < num_cids; cid++) {
    if (!class_table()->IsValidIndex(cid) ||
        !class_table()->HasValidClassAt(cid)) {
      continue;
    }
    if ((cid == kTypeArgumentsCid) || IsStringClassId(cid)) {
      // TypeArguments and Symbols have special tables for canonical objects
      // that aren't based on address.
      continue;
    }
    if ((cid == kMintCid) || (cid == kDoubleCid)) {
      // Constants stored as a plain list or in a hashset with a stable
      // hashcode, which only depends on the actual value of the constant.
      continue;
    }

    cls = class_table()->At(cid);
    if (cls.constants() == Array::null()) continue;
    old_constant_tables[cid] = &Array::Handle(zone, cls.constants());
    cls.set_constants(Object::null_array());
  }

  // Clear invalid hashes.
  heap()->ResetCanonicalHashTable();

  Instance& constant = Instance::Handle(zone);
  Field& field = Field::Handle(zone);
  String& name = String::Handle(zone);
  Array& new_values = Array::Handle(zone);
  Instance& old_value = Instance::Handle(zone);
  Instance& new_value = Instance::Handle(zone);
  Instance& deleted = Instance::Handle(zone);
  for (intptr_t cid = kInstanceCid; cid < num_cids; cid++) {
    Array* old_constants = old_constant_tables[cid];
    if (old_constants == nullptr) continue;

    cls = class_table()->At(cid);
    CanonicalInstancesSet set(zone, old_constants->ptr());
    CanonicalInstancesSet::Iterator it(&set);

    if (cls.is_enum_class() && (become != nullptr)) {
      field = cls.LookupStaticField(Symbols::_DeletedEnumSentinel());
      deleted ^= field.StaticConstFieldValue();
      if (deleted.IsNull()) {
        deleted = Instance::New(cls, Heap::kOld);
        field = object_store()->enum_name_field();
        name = cls.ScrubbedName();
        name = Symbols::FromConcat(thread, Symbols::_DeletedEnumPrefix(), name);
        deleted.SetField(field, name);
        field = object_store()->enum_index_field();
        new_value = Smi::New(-1);
        deleted.SetField(field, new_value);
        field = cls.LookupStaticField(Symbols::_DeletedEnumSentinel());
        // The static const field contains `Object::null()` instead of
        // `Object::sentinel()` - so it's not considered an initializing store.
        field.SetStaticConstFieldValue(deleted,
                                       /*assert_initializing_store*/ false);
      }

      field = cls.LookupField(Symbols::Values());
      new_values ^= field.StaticConstFieldValue();

      field = object_store()->enum_name_field();
      while (it.MoveNext()) {
        old_value ^= set.GetKey(it.Current());
        ASSERT(old_value.GetClassId() == cid);
        bool found = false;
        for (intptr_t j = 0; j < new_values.Length(); j++) {
          new_value ^= new_values.At(j);
          ASSERT(new_value.GetClassId() == cid);
          if (old_value.GetField(field) == new_value.GetField(field)) {
            found = true;
            break;
          }
        }
        if (!found) {
          new_value = deleted.ptr();
        }

        if (old_value.ptr() != new_value.ptr()) {
          become->Add(old_value, new_value);
        }
        if (new_value.IsCanonical()) {
          cls.InsertCanonicalConstant(zone, new_value);
        }
      }
    } else {
      while (it.MoveNext()) {
        constant ^= set.GetKey(it.Current());
        ASSERT(!constant.IsNull());
        // Shape changes lose the canonical bit because they may result/ in
        // merging constants. E.g., [x1, y1], [x1, y2] -> [x1].
        DEBUG_ASSERT(constant.IsCanonical() || HasAttemptedReload());
        cls.InsertCanonicalConstant(zone, constant);
      }
    }
    set.Release();
  }

  // Save memory.
  heap()->ResetCanonicalHashTable();
}

void Isolate::SendInternalLibMessage(LibMsgId msg_id, uint64_t capability) {
  const bool ok = SendInternalLibMessage(main_port(), msg_id, capability);
  if (!ok) UNREACHABLE();
}

bool Isolate::SendInternalLibMessage(Dart_Port main_port,
                                     LibMsgId msg_id,
                                     uint64_t capability) {
  Dart_CObject array_entry_msg_kind;
  array_entry_msg_kind.type = Dart_CObject_kInt64;
  array_entry_msg_kind.value.as_int64 = Message::kIsolateLibOOBMsg;

  Dart_CObject array_entry_msg_id;
  array_entry_msg_id.type = Dart_CObject_kInt64;
  array_entry_msg_id.value.as_int64 = msg_id;

  Dart_CObject array_entry_capability;
  array_entry_capability.type = Dart_CObject_kCapability;
  array_entry_capability.value.as_capability.id = capability;

  Dart_CObject* array_entries[3] = {
      &array_entry_msg_kind,
      &array_entry_msg_id,
      &array_entry_capability,
  };

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  message.value.as_array.values = array_entries;
  message.value.as_array.length = ARRAY_SIZE(array_entries);

  AllocOnlyStackZone zone;
  std::unique_ptr<Message> msg = WriteApiMessage(
      zone.GetZone(), &message, main_port, Message::kOOBPriority);
  if (msg == nullptr) UNREACHABLE();

  return PortMap::PostMessage(std::move(msg));
}

void IsolateGroup::set_object_store(ObjectStore* object_store) {
  object_store_.reset(object_store);
}

class IsolateMessageHandler : public MessageHandler {
 public:
  explicit IsolateMessageHandler(Isolate* isolate);
  ~IsolateMessageHandler();

  const char* name() const;
  void MessageNotify(Message::Priority priority);
  MessageStatus HandleMessage(std::unique_ptr<Message> message);
#ifndef PRODUCT
  void NotifyPauseOnStart();
  void NotifyPauseOnExit();
#endif  // !PRODUCT

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess();
#endif
  bool IsCurrentIsolate() const;
  virtual Isolate* isolate() const { return isolate_; }
  virtual IsolateGroup* isolate_group() const { return isolate_->group(); }

 private:
  // A result of false indicates that the isolate should terminate the
  // processing of further events.
  ErrorPtr HandleLibMessage(const Array& message);

  MessageStatus ProcessUnhandledException(const Error& result);
  Isolate* isolate_;
};

IsolateMessageHandler::IsolateMessageHandler(Isolate* isolate)
    : isolate_(isolate) {}

IsolateMessageHandler::~IsolateMessageHandler() {}

const char* IsolateMessageHandler::name() const {
  return isolate_->name();
}

// Isolate library OOB messages are fixed sized arrays which have the
// following format:
// [ OOB dispatch, Isolate library dispatch, <message specific data> ]
ErrorPtr IsolateMessageHandler::HandleLibMessage(const Array& message) {
  if (message.Length() < 2) return Error::null();
  Zone* zone = T->zone();
  const Object& type = Object::Handle(zone, message.At(1));
  if (!type.IsSmi()) return Error::null();
  const intptr_t msg_type = Smi::Cast(type).Value();
  switch (msg_type) {
    case Isolate::kPauseMsg: {
      // [ OOB, kPauseMsg, pause capability, resume capability ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();
      obj = message.At(3);
      if (!obj.IsCapability()) return Error::null();
      if (I->AddResumeCapability(Capability::Cast(obj))) {
        increment_paused();
      }
      break;
    }
    case Isolate::kResumeMsg: {
      // [ OOB, kResumeMsg, pause capability, resume capability ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();
      obj = message.At(3);
      if (!obj.IsCapability()) return Error::null();
      if (I->RemoveResumeCapability(Capability::Cast(obj))) {
        decrement_paused();
      }
      break;
    }
    case Isolate::kPingMsg: {
      // [ OOB, kPingMsg, responsePort, priority, response ]
      if (message.Length() != 5) return Error::null();
      const Object& obj2 = Object::Handle(zone, message.At(2));
      if (!obj2.IsSendPort()) return Error::null();
      const SendPort& send_port = SendPort::Cast(obj2);
      const Object& obj3 = Object::Handle(zone, message.At(3));
      if (!obj3.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj3).Value();
      const Object& obj4 = Object::Handle(zone, message.At(4));
      if (!obj4.IsInstance() && !obj4.IsNull()) return Error::null();
      const Instance& response =
          obj4.IsNull() ? Instance::null_instance() : Instance::Cast(obj4);
      if (priority == Isolate::kImmediateAction) {
        PortMap::PostMessage(SerializeMessage(send_port.Id(), response));
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case Isolate::kKillMsg:
    case Isolate::kInternalKillMsg: {
      // [ OOB, kKillMsg, terminate capability, priority ]
      if (message.Length() != 4) return Error::null();
      Object& obj = Object::Handle(zone, message.At(3));
      if (!obj.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj).Value();
      if (priority == Isolate::kImmediateAction) {
        Thread::Current()->StartUnwindError();
        obj = message.At(2);
        if (I->VerifyTerminateCapability(obj)) {
          // We will kill the current isolate by returning an UnwindError.
          if (msg_type == Isolate::kKillMsg) {
            const String& msg = String::Handle(
                String::New("isolate terminated by Isolate.kill"));
            const UnwindError& error =
                UnwindError::Handle(UnwindError::New(msg));
            error.set_is_user_initiated(true);
            return error.ptr();
          } else if (msg_type == Isolate::kInternalKillMsg) {
            const String& msg =
                String::Handle(String::New("isolate terminated by vm"));
            return UnwindError::New(msg);
          } else {
            UNREACHABLE();
          }
        } else {
          return Error::null();
        }
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(3,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
      break;
    }
    case Isolate::kInterruptMsg: {
      // [ OOB, kInterruptMsg, pause capability ]
      if (message.Length() != 3) return Error::null();
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyPauseCapability(obj)) return Error::null();

#if !defined(PRODUCT)
      // If we are already paused, don't pause again.
      if (I->debugger()->PauseEvent() == nullptr) {
        return I->debugger()->PauseInterrupted();
      }
#endif
      break;
    }
    case Isolate::kDrainServiceExtensionsMsg: {
#ifndef PRODUCT
      Object& obj = Object::Handle(zone, message.At(2));
      if (!obj.IsSmi()) return Error::null();
      const intptr_t priority = Smi::Cast(obj).Value();
      if (priority == Isolate::kImmediateAction) {
        return I->InvokePendingServiceExtensionCalls();
      } else {
        ASSERT((priority == Isolate::kBeforeNextEventAction) ||
               (priority == Isolate::kAsEventAction));
        // Update the message so that it will be handled immediately when it
        // is picked up from the message queue the next time.
        message.SetAt(
            0, Smi::Handle(zone, Smi::New(Message::kDelayedIsolateLibOOBMsg)));
        message.SetAt(2,
                      Smi::Handle(zone, Smi::New(Isolate::kImmediateAction)));
        this->PostMessage(
            SerializeMessage(Message::kIllegalPort, message),
            priority == Isolate::kBeforeNextEventAction /* at_head */);
      }
#else
      UNREACHABLE();
#endif  // !PRODUCT
      break;
    }

    case Isolate::kAddExitMsg:
    case Isolate::kDelExitMsg:
    case Isolate::kAddErrorMsg:
    case Isolate::kDelErrorMsg: {
      // [ OOB, msg, listener port ]
      if (message.Length() < 3) return Error::null();
      const Object& obj = Object::Handle(zone, message.At(2));
      if (!obj.IsSendPort()) return Error::null();
      const SendPort& listener = SendPort::Cast(obj);
      switch (msg_type) {
        case Isolate::kAddExitMsg: {
          if (message.Length() != 4) return Error::null();
          // [ OOB, msg, listener port, response object ]
          const Object& response = Object::Handle(zone, message.At(3));
          if (!response.IsInstance() && !response.IsNull()) {
            return Error::null();
          }
          I->AddExitListener(listener, response.IsNull()
                                           ? Instance::null_instance()
                                           : Instance::Cast(response));
          break;
        }
        case Isolate::kDelExitMsg:
          if (message.Length() != 3) return Error::null();
          I->RemoveExitListener(listener);
          break;
        case Isolate::kAddErrorMsg:
          if (message.Length() != 3) return Error::null();
          I->AddErrorListener(listener);
          break;
        case Isolate::kDelErrorMsg:
          if (message.Length() != 3) return Error::null();
          I->RemoveErrorListener(listener);
          break;
        default:
          UNREACHABLE();
      }
      break;
    }
    case Isolate::kErrorFatalMsg: {
      // [ OOB, kErrorFatalMsg, terminate capability, val ]
      if (message.Length() != 4) return Error::null();
      // Check that the terminate capability has been passed correctly.
      Object& obj = Object::Handle(zone, message.At(2));
      if (!I->VerifyTerminateCapability(obj)) return Error::null();
      // Get the value to be set.
      obj = message.At(3);
      if (!obj.IsBool()) return Error::null();
      I->SetErrorsFatal(Bool::Cast(obj).value());
      break;
    }
    case Isolate::kCheckForReload: {
      // [ OOB, kCheckForReload, ignored ]
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
      {
        ReloadParticipationScope allow_reload(T);
        T->CheckForSafepoint();
      }
#else
      UNREACHABLE();
#endif
      break;
    }
#if defined(DEBUG)
    // Malformed OOB messages are silently ignored in release builds.
    default:
      FATAL("Unknown OOB message type: %" Pd "\n", msg_type);
      break;
#endif  // defined(DEBUG)
  }
  return Error::null();
}

void IsolateMessageHandler::MessageNotify(Message::Priority priority) {
  if (priority >= Message::kOOBPriority) {
    // Handle out of band messages even if the mutator thread is busy.
    I->ScheduleInterrupts(Thread::kMessageInterrupt);
  }
  Dart_MessageNotifyCallback callback = I->message_notify_callback();
  if (callback != nullptr) {
    // Allow the embedder to handle message notification.
    (*callback)(Api::CastIsolate(I));
  }
}

bool Isolate::HasPendingMessages() {
  return message_handler_->HasMessages() || message_handler_->HasOOBMessages();
}

MessageHandler::MessageStatus IsolateMessageHandler::HandleMessage(
    std::unique_ptr<Message> message) {
  ASSERT(IsCurrentIsolate());
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  Zone* zone = stack_zone.GetZone();
  HandleScope handle_scope(thread);
#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(
      thread, Timeline::GetIsolateStream(),
      message->IsOOB() ? "HandleOOBMessage" : "HandleMessage");
  tbes.SetNumArguments(1);
  tbes.CopyArgument(0, "isolateName", I->name());
#endif

  // Parse the message.
  Object& msg_obj = Object::Handle(zone, ReadMessage(thread, message.get()));
  if (msg_obj.IsError()) {
    // An error occurred while reading the message.
    return ProcessUnhandledException(Error::Cast(msg_obj));
  }
  if (!msg_obj.IsNull() && !msg_obj.IsInstance()) {
    // TODO(turnidge): We need to decide what an isolate does with
    // malformed messages.  If they (eventually) come from a remote
    // machine, then it might make sense to drop the message entirely.
    // In the case that the message originated locally, which is
    // always true for now, then this should never occur.
    UNREACHABLE();
  }
  Instance& msg = Instance::Handle(zone);
  msg ^= msg_obj.ptr();  // Can't use Instance::Cast because may be null.

  MessageStatus status = kOK;
  if (message->IsOOB()) {
    // OOB messages are expected to be fixed length arrays where the first
    // element is a Smi describing the OOB destination. Messages that do not
    // confirm to this layout are silently ignored.
    if (msg.IsArray()) {
      const Array& oob_msg = Array::Cast(msg);
      if (oob_msg.Length() > 0) {
        const Object& oob_tag = Object::Handle(zone, oob_msg.At(0));
        if (oob_tag.IsSmi()) {
          switch (Smi::Cast(oob_tag).Value()) {
            case Message::kServiceOOBMsg: {
#ifndef PRODUCT
              const Error& error =
                  Error::Handle(Service::HandleIsolateMessage(I, oob_msg));
              if (!error.IsNull()) {
                status = ProcessUnhandledException(error);
              }
#else
              UNREACHABLE();
#endif
              break;
            }
            case Message::kIsolateLibOOBMsg: {
              const Error& error = Error::Handle(HandleLibMessage(oob_msg));
              if (!error.IsNull()) {
                status = ProcessUnhandledException(error);
              }
              break;
            }
#if defined(DEBUG)
            // Malformed OOB messages are silently ignored in release builds.
            default: {
              UNREACHABLE();
              break;
            }
#endif  // defined(DEBUG)
          }
        }
      }
    }
  } else if (message->IsFinalizerInvocationRequest()) {
    const Object& msg_handler = Object::Handle(
        zone,
        DartLibraryCalls::HandleFinalizerMessage(FinalizerBase::Cast(msg)));
    if (msg_handler.IsError()) {
      status = ProcessUnhandledException(Error::Cast(msg_handler));
    } else {
      // The handler closure which was used to successfully handle the message.
    }
  } else if (message->dest_port() == Message::kIllegalPort) {
    // Check whether this is a delayed OOB message which needed handling as
    // part of the regular message dispatch. All other messages are dropped on
    // the floor.
    if (msg.IsArray()) {
      const Array& msg_arr = Array::Cast(msg);
      if (msg_arr.Length() > 0) {
        const Object& oob_tag = Object::Handle(zone, msg_arr.At(0));
        if (oob_tag.IsSmi() &&
            (Smi::Cast(oob_tag).Value() == Message::kDelayedIsolateLibOOBMsg)) {
          const Error& error = Error::Handle(HandleLibMessage(msg_arr));
          if (!error.IsNull()) {
            status = ProcessUnhandledException(error);
          }
        }
      }
    }
  } else {
    const Object& msg_handler = Object::Handle(
        zone, DartLibraryCalls::HandleMessage(message->dest_port(), msg));
    if (msg_handler.IsError()) {
      status = ProcessUnhandledException(Error::Cast(msg_handler));
    } else if (msg_handler.IsNull()) {
      // If the port has been closed then the message will be dropped at this
      // point. Make sure to post to the delivery failure port in that case.
    } else {
      // The handler closure which was used to successfully handle the message.
    }
  }
  return status;
}

#ifndef PRODUCT
void IsolateMessageHandler::NotifyPauseOnStart() {
  if (Isolate::IsSystemIsolate(I)) {
    return;
  }
  if (Service::debug_stream.enabled() || FLAG_warn_on_pause_with_no_debugger) {
    StartIsolateScope start_isolate(I);
    StackZone zone(T);
    HandleScope handle_scope(T);
    ServiceEvent pause_event(I, ServiceEvent::kPauseStart);
    Service::HandleEvent(&pause_event);
  } else if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Dropping event of type PauseStart (%s)\n",
                 I->name());
  }
}

void IsolateMessageHandler::NotifyPauseOnExit() {
  if (Isolate::IsSystemIsolate(I)) {
    return;
  }
  if (Service::debug_stream.enabled() || FLAG_warn_on_pause_with_no_debugger) {
    StartIsolateScope start_isolate(I);
    StackZone zone(T);
    HandleScope handle_scope(T);
    ServiceEvent pause_event(I, ServiceEvent::kPauseExit);
    Service::HandleEvent(&pause_event);
  } else if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Dropping event of type PauseExit (%s)\n",
                 I->name());
  }
}
#endif  // !PRODUCT

#if defined(DEBUG)
void IsolateMessageHandler::CheckAccess() {
  ASSERT(IsCurrentIsolate());
}
#endif

bool IsolateMessageHandler::IsCurrentIsolate() const {
  return (I == Isolate::Current());
}

static MessageHandler::MessageStatus StoreError(Thread* thread,
                                                const Error& error) {
  thread->set_sticky_error(error);
  if (error.IsUnwindError()) {
    const UnwindError& unwind = UnwindError::Cast(error);
    if (!unwind.is_user_initiated()) {
      return MessageHandler::kShutdown;
    }
  }
  return MessageHandler::kError;
}

MessageHandler::MessageStatus IsolateMessageHandler::ProcessUnhandledException(
    const Error& result) {
  if (FLAG_trace_isolates) {
    OS::PrintErr(
        "[!] Unhandled exception in %s:\n"
        "         exception: %s\n",
        T->isolate()->name(), result.ToErrorCString());
  }

  NoReloadScope no_reload(T);
  // Generate the error and stacktrace strings for the error message.
  const char* exception_cstr = nullptr;
  const char* stacktrace_cstr = nullptr;
  if (result.IsUnhandledException()) {
    Zone* zone = T->zone();
    const UnhandledException& uhe = UnhandledException::Cast(result);
    const Instance& exception = Instance::Handle(zone, uhe.exception());
    if (exception.ptr() == IG->object_store()->out_of_memory()) {
      exception_cstr = "Out of Memory";  // Cf. OutOfMemoryError.toString().
    } else if (exception.ptr() == IG->object_store()->stack_overflow()) {
      exception_cstr = "Stack Overflow";  // Cf. StackOverflowError.toString().
    } else {
      const Object& exception_str =
          Object::Handle(zone, DartLibraryCalls::ToString(exception));
      if (!exception_str.IsString()) {
        exception_cstr = exception.ToCString();
      } else {
        exception_cstr = exception_str.ToCString();
      }
    }

    const Instance& stacktrace = Instance::Handle(zone, uhe.stacktrace());
    stacktrace_cstr = stacktrace.ToCString();
  } else {
    exception_cstr = result.ToErrorCString();
  }
  if (result.IsUnwindError()) {
    // When unwinding we don't notify error listeners and we ignore
    // whether errors are fatal for the current isolate.
    return StoreError(T, result);
  } else {
    bool has_listener =
        I->NotifyErrorListeners(exception_cstr, stacktrace_cstr);
    if (I->ErrorsFatal()) {
      if (has_listener) {
        T->ClearStickyError();
      } else {
        T->set_sticky_error(result);
      }
#if !defined(PRODUCT)
      // Notify the debugger about specific unhandled exceptions which are
      // withheld when being thrown. Do this after setting the sticky error
      // so the isolate has an error set when paused with the unhandled
      // exception.
      if (result.IsUnhandledException()) {
        const UnhandledException& error = UnhandledException::Cast(result);
        InstancePtr exception = error.exception();
        if ((exception == IG->object_store()->out_of_memory()) ||
            (exception == IG->object_store()->stack_overflow())) {
          // We didn't notify the debugger when the stack was full. Do it now.
          I->debugger()->PauseException(Instance::Handle(exception));
        }
      }
#endif  // !defined(PRODUCT)
      return kError;
    }
  }
  return kOK;
}

void IsolateGroup::FlagsInitialize(Dart_IsolateFlags* api_flags) {
  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FLAG(when, name, bitname, isolate_flag, flag)                \
  api_flags->isolate_flag = flag;
  BOOL_ISOLATE_GROUP_FLAG_LIST(INIT_FROM_FLAG)
#undef INIT_FROM_FLAG
  api_flags->copy_parent_code = false;
}

void IsolateGroup::FlagsCopyTo(Dart_IsolateFlags* api_flags) {
  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FIELD(when, name, bitname, isolate_flag, flag)               \
  api_flags->isolate_flag = name();
  BOOL_ISOLATE_GROUP_FLAG_LIST(INIT_FROM_FIELD)
#undef INIT_FROM_FIELD
  api_flags->copy_parent_code = false;
}

void IsolateGroup::FlagsCopyFrom(const Dart_IsolateFlags& api_flags) {
#if defined(DART_PRECOMPILER)
#define FLAG_FOR_PRECOMPILER(action) action
#else
#define FLAG_FOR_PRECOMPILER(action)
#endif

#if !defined(PRODUCT)
#define FLAG_FOR_NONPRODUCT(action) action
#else
#define FLAG_FOR_NONPRODUCT(action)
#endif

#define FLAG_FOR_PRODUCT(action) action

#define SET_FROM_FLAG(when, name, bitname, isolate_flag, flag)                 \
  FLAG_FOR_##when(isolate_group_flags_ = bitname##Bit::update(                 \
                      api_flags.isolate_flag, isolate_group_flags_));

  BOOL_ISOLATE_GROUP_FLAG_LIST(SET_FROM_FLAG)
  // Needs to be called manually, otherwise we don't set the null_safety_set
  // bit.
  set_null_safety(api_flags.null_safety);
#undef FLAG_FOR_NONPRODUCT
#undef FLAG_FOR_PRECOMPILER
#undef FLAG_FOR_PRODUCT
#undef SET_FROM_FLAG
}

void Isolate::FlagsInitialize(Dart_IsolateFlags* api_flags) {
  IsolateGroup::FlagsInitialize(api_flags);

  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FLAG(when, name, bitname, isolate_flag, flag)                \
  api_flags->isolate_flag = flag;
  BOOL_ISOLATE_FLAG_LIST(INIT_FROM_FLAG)
#undef INIT_FROM_FLAG
  api_flags->copy_parent_code = false;
}

void Isolate::FlagsCopyTo(Dart_IsolateFlags* api_flags) const {
  group()->FlagsCopyTo(api_flags);

  api_flags->version = DART_FLAGS_CURRENT_VERSION;
#define INIT_FROM_FIELD(when, name, bitname, isolate_flag, flag)               \
  api_flags->isolate_flag = name();
  BOOL_ISOLATE_FLAG_LIST(INIT_FROM_FIELD)
#undef INIT_FROM_FIELD
  api_flags->copy_parent_code = false;
}

void Isolate::FlagsCopyFrom(const Dart_IsolateFlags& api_flags) {
  const bool copy_parent_code_ = copy_parent_code();
#if defined(DART_PRECOMPILER)
#define FLAG_FOR_PRECOMPILER(action) action
#else
#define FLAG_FOR_PRECOMPILER(action)
#endif

#if !defined(PRODUCT)
#define FLAG_FOR_NONPRODUCT(action) action
#else
#define FLAG_FOR_NONPRODUCT(action)
#endif

#define FLAG_FOR_PRODUCT(action) action

#define SET_FROM_FLAG(when, name, bitname, isolate_flag, flag)                 \
  FLAG_FOR_##when(isolate_flags_ = bitname##Bit::update(                       \
                      api_flags.isolate_flag, isolate_flags_));

  BOOL_ISOLATE_FLAG_LIST(SET_FROM_FLAG)
  isolate_flags_ = CopyParentCodeBit::update(copy_parent_code_, isolate_flags_);
#undef FLAG_FOR_NONPRODUCT
#undef FLAG_FOR_PRECOMPILER
#undef FLAG_FOR_PRODUCT
#undef SET_FROM_FLAG
}

#if defined(DEBUG)
// static
void BaseIsolate::AssertCurrent(BaseIsolate* isolate) {
  ASSERT(isolate == Isolate::Current());
}
#endif  // defined(DEBUG)

#if defined(DEBUG)
#define REUSABLE_HANDLE_SCOPE_INIT(object)                                     \
  reusable_##object##_handle_scope_active_(false),
#else
#define REUSABLE_HANDLE_SCOPE_INIT(object)
#endif  // defined(DEBUG)

#define REUSABLE_HANDLE_INITIALIZERS(object) object##_handle_(nullptr),

class LibraryPrefixMapTraits {
 public:
  static bool ReportStats() { return false; }
  static const char* Name() { return "LibraryPrefixMapTraits"; }

  static bool IsMatch(const Object& a, const Object& b) {
    if (!a.IsLibraryPrefix() || !b.IsLibraryPrefix()) {
      return false;
    }
    return a.ptr() == b.ptr();
  }

  static uword Hash(const Object& obj) {
    auto& prefix = LibraryPrefix::Cast(obj);
    return String::Hash(prefix.name());
  }
};

// TODO(srdjan): Some Isolate monitors can be shared. Replace their usage with
// that shared monitor.
Isolate::Isolate(IsolateGroup* isolate_group,
                 const Dart_IsolateFlags& api_flags)
    : BaseIsolate(),
      current_tag_(UserTag::null()),
      default_tag_(UserTag::null()),
      field_table_(new FieldTable(/*isolate=*/this)),
      finalizers_(GrowableObjectArray::null()),
      isolate_group_(isolate_group),
      isolate_object_store_(new IsolateObjectStore()),
      isolate_flags_(0),
#if !defined(PRODUCT)
      last_resume_timestamp_(OS::GetCurrentTimeMillis()),
      vm_tag_counters_(),
      pending_service_extension_calls_(GrowableObjectArray::null()),
      registered_service_extension_handlers_(GrowableObjectArray::null()),
#define ISOLATE_METRIC_CONSTRUCTORS(type, variable, name, unit)                \
  metric_##variable##_(),
      ISOLATE_METRIC_LIST(ISOLATE_METRIC_CONSTRUCTORS)
#undef ISOLATE_METRIC_CONSTRUCTORS
#endif  // !defined(PRODUCT)
          start_time_micros_(OS::GetCurrentMonotonicMicros()),
      message_notify_callback_(nullptr),
      on_shutdown_callback_(Isolate::ShutdownCallback()),
      on_cleanup_callback_(Isolate::CleanupCallback()),
      random_(),
      mutex_(NOT_IN_PRODUCT("Isolate::mutex_")),
      tag_table_(GrowableObjectArray::null()),
      sticky_error_(Error::null()),
      spawn_count_monitor_(),
      handler_info_cache_(),
      catch_entry_moves_cache_(),
      wake_pause_event_handler_count_(0),
      loaded_prefixes_set_storage_(nullptr) {
  FlagsCopyFrom(api_flags);
  SetErrorsFatal(true);
  // TODO(asiva): A Thread is not available here, need to figure out
  // how the vm_tag (kEmbedderTagId) can be set, these tags need to
  // move to the OSThread structure.
  set_user_tag(UserTags::kDefaultUserTag);
}

#undef REUSABLE_HANDLE_SCOPE_INIT
#undef REUSABLE_HANDLE_INITIALIZERS

Isolate::~Isolate() {
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // TODO(32796): Re-enable assertion.
  // RELEASE_ASSERT(program_reload_context_ == nullptr);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(PRODUCT)
  delete debugger_;
  debugger_ = nullptr;
  delete object_id_ring_;
  object_id_ring_ = nullptr;
  delete pause_loop_monitor_;
  pause_loop_monitor_ = nullptr;
#endif  // !defined(PRODUCT)

  free(name_);
  delete field_table_;
#if defined(USING_SIMULATOR)
  delete simulator_;
#endif
  delete message_handler_;
  message_handler_ =
      nullptr;  // Fail fast if we send messages to a dead isolate.
  ASSERT(deopt_context_ ==
         nullptr);  // No deopt in progress when isolate deleted.
  ASSERT(spawn_count_ == 0);

  // The [Thread] object should've been released on the last
  // `Thread::ExitIsolate()` call.
  ASSERT(scheduled_mutator_thread_ == nullptr);
  ASSERT(mutator_thread_ == nullptr);
}

void Isolate::InitVM() {
  create_group_callback_ = nullptr;
  initialize_callback_ = nullptr;
  shutdown_callback_ = nullptr;
  cleanup_callback_ = nullptr;
  cleanup_group_callback_ = nullptr;
  register_kernel_blob_callback_ = nullptr;
  unregister_kernel_blob_callback_ = nullptr;
  if (isolate_creation_monitor_ == nullptr) {
    isolate_creation_monitor_ = new Monitor();
  }
  ASSERT(isolate_creation_monitor_ != nullptr);
  EnableIsolateCreation();
}

Isolate* Isolate::InitIsolate(const char* name_prefix,
                              IsolateGroup* isolate_group,
                              const Dart_IsolateFlags& api_flags,
                              bool is_vm_isolate) {
  Isolate* result = new Isolate(isolate_group, api_flags);
  result->BuildName(name_prefix);
  if (!is_vm_isolate) {
    // vm isolate object store is initialized later, after null instance
    // is created (in Dart::Init).
    // Non-vm isolates need to have isolate object store initialized is that
    // exit_listeners have to be null-initialized as they will be used if
    // we fail to create isolate below, have to do low level shutdown.
    ASSERT(result->group()->object_store() != nullptr);
    result->isolate_object_store()->Init();
  }

  ASSERT(result != nullptr);

#if !defined(PRODUCT)
// Initialize metrics.
#define ISOLATE_METRIC_INIT(type, variable, name, unit)                        \
  result->metric_##variable##_.InitInstance(result, name, nullptr,             \
                                            Metric::unit);
  ISOLATE_METRIC_LIST(ISOLATE_METRIC_INIT);
#undef ISOLATE_METRIC_INIT
#endif  // !defined(PRODUCT)

  // First we ensure we enter the isolate. This will ensure we're participating
  // in any safepointing requests from this point on. Other threads requesting a
  // safepoint operation will therefore wait until we've stopped.
  //
  // Though the [result] isolate is still in a state where no memory has been
  // allocated, which means it's safe to GC the isolate group until here.
  Thread::EnterIsolate(result);

  // Setup the isolate message handler.
  MessageHandler* handler = new IsolateMessageHandler(result);
  ASSERT(handler != nullptr);
  result->set_message_handler(handler);

  result->set_main_port(
      PortMap::CreatePort(result->message_handler(), PortMap::kControlPort));
#if defined(DEBUG)
  // Verify that we are never reusing a live origin id.
  VerifyOriginId id_verifier(result->main_port());
  Isolate::VisitIsolates(&id_verifier);
#endif
  result->set_origin_id(result->main_port());

  // Keep capability IDs less than 2^53 so web clients of the service
  // protocol can process it properly.
  //
  // See https://github.com/dart-lang/sdk/issues/53081.
  result->set_pause_capability(result->random()->NextJSInt());
  result->set_terminate_capability(result->random()->NextJSInt());

#if !defined(PRODUCT)
  result->debugger_ = new Debugger(result);
#endif

  // Now we register the isolate in the group. From this point on any GC would
  // traverse the isolate roots (before this point, the roots are only pointing
  // to vm-isolate objects, e.g. null)
  isolate_group->RegisterIsolate(result);

  if (ServiceIsolate::NameEquals(name_prefix)) {
    ASSERT(!ServiceIsolate::Exists());
    ServiceIsolate::SetServiceIsolate(result);
#if !defined(DART_PRECOMPILED_RUNTIME)
  } else if (KernelIsolate::NameEquals(name_prefix)) {
    ASSERT(!KernelIsolate::Exists());
    KernelIsolate::SetKernelIsolate(result);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }

  if (FLAG_trace_isolates) {
    if (name_prefix == nullptr || strcmp(name_prefix, "vm-isolate") != 0) {
      OS::PrintErr(
          "[+] Starting isolate:\n"
          "\tisolate:    %s\n",
          result->name());
    }
  }

  // Add to isolate list. Shutdown and delete the isolate on failure.
  if (!TryMarkIsolateReady(result)) {
    result->LowLevelShutdown();
    Isolate::LowLevelCleanup(result);
    return nullptr;
  }

  return result;
}

Thread* Isolate::mutator_thread() const {
  ASSERT(thread_registry() != nullptr);
  return mutator_thread_;
}

ObjectPtr IsolateGroup::CallTagHandler(Dart_LibraryTag tag,
                                       const Object& arg1,
                                       const Object& arg2) {
  Thread* thread = Thread::Current();
  Api::Scope api_scope(thread);
  Dart_Handle api_arg1 = Api::NewHandle(thread, arg1.ptr());
  Dart_Handle api_arg2 = Api::NewHandle(thread, arg2.ptr());
  Dart_Handle api_result;
  {
    TransitionVMToNative transition(thread);
    ASSERT(HasTagHandler());
    api_result = library_tag_handler()(tag, api_arg1, api_arg2);
  }
  return Api::UnwrapHandle(api_result);
}

ObjectPtr Isolate::CallDeferredLoadHandler(intptr_t id) {
  Thread* thread = Thread::Current();
  Api::Scope api_scope(thread);
  Dart_Handle api_result;
  {
    TransitionVMToNative transition(thread);
    RELEASE_ASSERT(HasDeferredLoadHandler());
    api_result = group()->deferred_load_handler()(id);
  }
  return Api::UnwrapHandle(api_result);
}

void IsolateGroup::SetupImagePage(const uint8_t* image_buffer,
                                  bool is_executable) {
  Image image(image_buffer);
  heap()->SetupImagePage(image.object_start(), image.object_size(),
                         is_executable);
}

void Isolate::ScheduleInterrupts(uword interrupt_bits) {
  // We take the threads lock here to ensure that the mutator thread does not
  // exit the isolate while we are trying to schedule interrupts on it.
  MonitorLocker ml(group()->thread_registry()->threads_lock());
  Thread* mthread = mutator_thread();
  if (mthread != nullptr) {
    mthread->ScheduleInterrupts(interrupt_bits);
  }
}

void Isolate::set_name(const char* name) {
  free(name_);
  name_ = Utils::StrDup(name);
}

int64_t IsolateGroup::UptimeMicros() const {
  return OS::GetCurrentMonotonicMicros() - start_time_micros_;
}

int64_t Isolate::UptimeMicros() const {
  return OS::GetCurrentMonotonicMicros() - start_time_micros_;
}

Dart_Port Isolate::origin_id() {
  MutexLocker ml(&origin_id_mutex_);
  return origin_id_;
}

void Isolate::set_origin_id(Dart_Port id) {
  MutexLocker ml(&origin_id_mutex_);
  ASSERT((id == main_port_ && origin_id_ == 0) || (origin_id_ == main_port_));
  origin_id_ = id;
}

void Isolate::set_finalizers(const GrowableObjectArray& value) {
  finalizers_ = value.ptr();
}

bool Isolate::IsPaused() const {
#if defined(PRODUCT)
  return false;
#else
  return (debugger_ != nullptr) && (debugger_->PauseEvent() != nullptr);
#endif  // !defined(PRODUCT)
}

ErrorPtr Isolate::PausePostRequest() {
#if !defined(PRODUCT)
  if (debugger_ == nullptr) {
    return Error::null();
  }
  ASSERT(!IsPaused());
  const Error& error = Error::Handle(debugger_->PausePostRequest());
  if (!error.IsNull()) {
    if (Thread::Current()->top_exit_frame_info() == 0) {
      return error.ptr();
    } else {
      Exceptions::PropagateError(error);
      UNREACHABLE();
    }
  }
#endif
  return Error::null();
}

void Isolate::BuildName(const char* name_prefix) {
  ASSERT(name_ == nullptr);
  if (name_prefix == nullptr) {
    name_ = OS::SCreate(nullptr, "isolate-%" Pd64 "", main_port());
  } else {
    name_ = Utils::StrDup(name_prefix);
  }
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
bool IsolateGroup::CanReload() {
  // We only call this method on the mutator thread. Normally the caller is
  // inside of the "reloadSources" service OOB message handler. Though
  // we also use it in the slow path of StackOverflowCheck in the artificial
  // --hot-reload-test-mode like flags.
  //
  // During reload itself we don't process OOB messages and don't execute Dart
  // code, so the caller should implicitly have a guarantee we're not reloading
  // already.
  RELEASE_ASSERT(!Thread::Current()->OwnsReloadSafepoint());

  // We only allow reload to take place from the point on where the first
  // isolate within an isolate group has setup it's root library. From that
  // point on it's safe to perform hot-reload.
  auto thread = Thread::Current();
  if (object_store()->root_library() == Library::null()) {
    return false;
  }

  // We only care about the current thread's [NoReloadScope]. If we're inside
  // one we cannot reload right now. Though if another isolate's mutator
  // thread is inside such a scope, the multi-isolate reload will simply wait
  // until it's out of that scope again.
  if (thread->no_reload_scope_depth_ != 0) {
    return false;
  }

  return !IsolateGroup::IsSystemIsolateGroup(this) &&
         OSThread::Current()->HasStackHeadroom(64 * KB);
}

bool IsolateGroup::ReloadSources(JSONStream* js,
                                 bool force_reload,
                                 const char* root_script_url,
                                 const char* packages_url,
                                 bool dont_delete_reload_context) {
  ASSERT(!IsReloading());

  // Ensure all isolates inside the isolate group are paused at a place where we
  // can safely do a reload.
  RELOAD_OPERATION_SCOPE(Thread::Current());

  auto class_table = IsolateGroup::Current()->class_table();
  std::shared_ptr<IsolateGroupReloadContext> group_reload_context(
      new IsolateGroupReloadContext(this, class_table, js));
  group_reload_context_ = group_reload_context;

  SetHasAttemptedReload(true);
  program_reload_context_ =
      new ProgramReloadContext(group_reload_context_, this);
  const bool success =
      group_reload_context_->Reload(force_reload, root_script_url, packages_url,
                                    /*kernel_buffer=*/nullptr,
                                    /*kernel_buffer_size=*/0);
  if (!dont_delete_reload_context) {
    DeleteReloadContext();
  }
  return success;
}

bool IsolateGroup::ReloadKernel(JSONStream* js,
                                bool force_reload,
                                const uint8_t* kernel_buffer,
                                intptr_t kernel_buffer_size,
                                bool dont_delete_reload_context) {
  ASSERT(!IsReloading());

  // Ensure all isolates inside the isolate group are paused at a place where we
  // can safely do a reload.
  RELOAD_OPERATION_SCOPE(Thread::Current());

  auto class_table = IsolateGroup::Current()->class_table();
  std::shared_ptr<IsolateGroupReloadContext> group_reload_context(
      new IsolateGroupReloadContext(this, class_table, js));
  group_reload_context_ = group_reload_context;

  SetHasAttemptedReload(true);
  program_reload_context_ =
      new ProgramReloadContext(group_reload_context_, this);
  const bool success = group_reload_context_->Reload(
      force_reload,
      /*root_script_url=*/nullptr,
      /*packages_url=*/nullptr, kernel_buffer, kernel_buffer_size);
  if (!dont_delete_reload_context) {
    DeleteReloadContext();
  }
  return success;
}

void IsolateGroup::DeleteReloadContext() {
  GcSafepointOperationScope safepoint_scope(Thread::Current());
  group_reload_context_.reset();

  delete program_reload_context_;
  program_reload_context_ = nullptr;
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

const char* Isolate::MakeRunnable() {
  MutexLocker ml(&mutex_);
  // Check if we are in a valid state to make the isolate runnable.
  if (is_runnable() == true) {
    return "Isolate is already runnable";
  }
  if (group()->object_store()->root_library() == Library::null()) {
    return "The embedder has to ensure there is a root library (e.g. by "
           "calling Dart_LoadScriptFromKernel ).";
  }
  MakeRunnableLocked();
  return nullptr;
}

void Isolate::MakeRunnableLocked() {
  ASSERT(mutex_.IsOwnedByCurrentThread());
  ASSERT(!is_runnable());
  ASSERT(group()->object_store()->root_library() != Library::null());

  // Set the isolate as runnable and if we are being spawned schedule
  // isolate on thread pool for execution.
  set_is_runnable(true);
#ifndef PRODUCT
  if (!Isolate::IsSystemIsolate(this)) {
    if (FLAG_pause_isolates_on_unhandled_exceptions) {
      debugger()->SetExceptionPauseInfo(kPauseOnUnhandledExceptions);
    }
  }
#endif  // !PRODUCT
#if defined(SUPPORT_TIMELINE)
  TimelineStream* stream = Timeline::GetIsolateStream();
  ASSERT(stream != nullptr);
  TimelineEvent* event = stream->StartEvent();
  if (event != nullptr) {
    event->Instant("Runnable");
    event->Complete();
  }
#endif
#ifndef PRODUCT
  if (!Isolate::IsSystemIsolate(this) && Service::isolate_stream.enabled()) {
    ServiceEvent runnableEvent(this, ServiceEvent::kIsolateRunnable);
    Service::HandleEvent(&runnableEvent, /* enter_safepoint */ false);
  }
  GetRunnableLatencyMetric()->set_value(UptimeMicros());
#endif  // !PRODUCT
}

bool Isolate::VerifyPauseCapability(const Object& capability) const {
  return !capability.IsNull() && capability.IsCapability() &&
         (pause_capability() == Capability::Cast(capability).Id());
}

bool Isolate::VerifyTerminateCapability(const Object& capability) const {
  return !capability.IsNull() && capability.IsCapability() &&
         (terminate_capability() == Capability::Cast(capability).Id());
}

bool Isolate::AddResumeCapability(const Capability& capability) {
  // Ensure a limit for the number of resume capabilities remembered.
  const intptr_t kMaxResumeCapabilities =
      compiler::target::kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& caps = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->resume_capabilities());
  Capability& current = Capability::Handle(current_zone());
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < caps.Length(); i++) {
    current ^= caps.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == capability.Id()) {
      return false;
    }
  }
  if (insertion_index < 0) {
    if (caps.Length() >= kMaxResumeCapabilities) {
      // Cannot grow the array of resume capabilities beyond its max. Additional
      // pause requests are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return false;
    }
    caps.Add(capability);
  } else {
    caps.SetAt(insertion_index, capability);
  }
  return true;
}

bool Isolate::RemoveResumeCapability(const Capability& capability) {
  const GrowableObjectArray& caps = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->resume_capabilities());
  Capability& current = Capability::Handle(current_zone());
  for (intptr_t i = 0; i < caps.Length(); i++) {
    current ^= caps.At(i);
    if (!current.IsNull() && (current.Id() == capability.Id())) {
      // Remove the matching capability from the list.
      current = Capability::null();
      caps.SetAt(i, current);
      return true;
    }
  }
  return false;
}

// TODO(iposva): Remove duplicated code and start using some hash based
// structure instead of these linear lookups.
void Isolate::AddExitListener(const SendPort& listener,
                              const Instance& response) {
  // Ensure a limit for the number of listeners remembered.
  const intptr_t kMaxListeners = compiler::target::kSmiMax / (12 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(current_zone());
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    current ^= listeners.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == listener.Id()) {
      listeners.SetAt(i + 1, response);
      return;
    }
  }
  if (insertion_index < 0) {
    if (listeners.Length() >= kMaxListeners) {
      // Cannot grow the array of listeners beyond its max. Additional
      // listeners are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return;
    }
    listeners.Add(listener);
    listeners.Add(response);
  } else {
    listeners.SetAt(insertion_index, listener);
    listeners.SetAt(insertion_index + 1, response);
  }
}

void Isolate::RemoveExitListener(const SendPort& listener) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->exit_listeners());
  SendPort& current = SendPort::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    current ^= listeners.At(i);
    if (!current.IsNull() && (current.Id() == listener.Id())) {
      // Remove the matching listener from the list.
      current = SendPort::null();
      listeners.SetAt(i, current);
      listeners.SetAt(i + 1, Object::null_instance());
      return;
    }
  }
}

void Isolate::NotifyExitListeners() {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->exit_listeners());
  if (listeners.IsNull()) return;

  SendPort& listener = SendPort::Handle(current_zone());
  Instance& response = Instance::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i += 2) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      response ^= listeners.At(i + 1);
      PortMap::PostMessage(SerializeMessage(port_id, response));
    }
  }
}

void Isolate::AddErrorListener(const SendPort& listener) {
  // Ensure a limit for the number of listeners remembered.
  const intptr_t kMaxListeners = compiler::target::kSmiMax / (6 * kWordSize);

  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->error_listeners());
  SendPort& current = SendPort::Handle(current_zone());
  intptr_t insertion_index = -1;
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    current ^= listeners.At(i);
    if (current.IsNull()) {
      if (insertion_index < 0) {
        insertion_index = i;
      }
    } else if (current.Id() == listener.Id()) {
      return;
    }
  }
  if (insertion_index < 0) {
    if (listeners.Length() >= kMaxListeners) {
      // Cannot grow the array of listeners beyond its max. Additional
      // listeners are ignored. In practice will never happen as we will
      // run out of memory beforehand.
      return;
    }
    listeners.Add(listener);
  } else {
    listeners.SetAt(insertion_index, listener);
  }
}

void Isolate::RemoveErrorListener(const SendPort& listener) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->error_listeners());
  SendPort& current = SendPort::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    current ^= listeners.At(i);
    if (!current.IsNull() && (current.Id() == listener.Id())) {
      // Remove the matching listener from the list.
      current = SendPort::null();
      listeners.SetAt(i, current);
      return;
    }
  }
}

bool Isolate::NotifyErrorListeners(const char* message,
                                   const char* stacktrace) {
  const GrowableObjectArray& listeners = GrowableObjectArray::Handle(
      current_zone(), isolate_object_store()->error_listeners());
  if (listeners.IsNull()) return false;

  Dart_CObject arr;
  Dart_CObject* arr_values[2];
  arr.type = Dart_CObject_kArray;
  arr.value.as_array.length = 2;
  arr.value.as_array.values = arr_values;
  Dart_CObject msg;
  msg.type = Dart_CObject_kString;
  msg.value.as_string = const_cast<char*>(message);
  arr_values[0] = &msg;
  Dart_CObject stack;
  if (stacktrace == nullptr) {
    stack.type = Dart_CObject_kNull;
  } else {
    stack.type = Dart_CObject_kString;
    stack.value.as_string = const_cast<char*>(stacktrace);
  }
  arr_values[1] = &stack;

  SendPort& listener = SendPort::Handle(current_zone());
  for (intptr_t i = 0; i < listeners.Length(); i++) {
    listener ^= listeners.At(i);
    if (!listener.IsNull()) {
      Dart_Port port_id = listener.Id();
      PortMap::PostMessage(SerializeMessage(current_zone(), port_id, &arr));
    }
  }
  return listeners.Length() > 0;
}

static void ShutdownIsolate(uword parameter) {
  Dart_EnterIsolate(reinterpret_cast<Dart_Isolate>(parameter));
  Dart_ShutdownIsolate();
}

void Isolate::SetStickyError(ErrorPtr sticky_error) {
  ASSERT(
      ((sticky_error_ == Error::null()) || (sticky_error == Error::null())) &&
      (sticky_error != sticky_error_));
  sticky_error_ = sticky_error;
}

void Isolate::Run() {
  message_handler()->Run(group()->thread_pool(), nullptr, ShutdownIsolate,
                         reinterpret_cast<uword>(this));
}

void Isolate::RunAndCleanupFinalizersOnShutdown() {
  if (finalizers_ == GrowableObjectArray::null()) return;

  // Ensure we have a zone and handle scope so that we can call VM functions,
  // but we no longer allocate new heap objects.
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);
  NoSafepointScope no_safepoint_scope;

  // Set live finalizers isolate to null, before deleting the message handler.
  const auto& finalizers =
      GrowableObjectArray::Handle(stack_zone.GetZone(), finalizers_);
  if (!finalizers.IsNull()) {
    const intptr_t num_finalizers = finalizers.Length();
    auto& weak_reference = WeakReference::Handle(stack_zone.GetZone());
    auto& finalizer = FinalizerBase::Handle(stack_zone.GetZone());
    auto& current_entry = FinalizerEntry::Handle(stack_zone.GetZone());
    auto& all_entries = Set::Handle(stack_zone.GetZone());
    for (int i = 0; i < num_finalizers; i++) {
      weak_reference ^= finalizers.At(i);
      finalizer ^= weak_reference.target();
      if (!finalizer.IsNull()) {
        if (finalizer.isolate() == this) {
          if (FLAG_trace_finalizers) {
            THR_Print("Isolate %p Setting finalizer %p isolate to null\n", this,
                      finalizer.ptr()->untag());
          }
          // Finalizer was not sent to another isolate with send and exit.
          finalizer.set_isolate(nullptr);
        } else {
          // TODO(http://dartbug.com/47777): Send and exit support.
          UNREACHABLE();
        }

        if (finalizer.IsNativeFinalizer()) {
          // Immediately call native callback.
          const auto& native_finalizer = NativeFinalizer::Cast(finalizer);
          all_entries = finalizer.all_entries();
          Set::Iterator iterator(all_entries);
          while (iterator.MoveNext()) {
            current_entry ^= iterator.CurrentKey();
            native_finalizer.RunCallback(current_entry, "Isolate shutdown");
          }
        }
      }
    }
  }
}

void Isolate::LowLevelShutdown() {
  // Ensure we have a zone and handle scope so that we can call VM functions,
  // but we no longer allocate new heap objects.
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  HandleScope handle_scope(thread);
  NoSafepointScope no_safepoint_scope;

  // Notify exit listeners that this isolate is shutting down.
  if (group()->object_store() != nullptr) {
    const Error& error = Error::Handle(thread->sticky_error());
    if (error.IsNull() || !error.IsUnwindError() ||
        UnwindError::Cast(error).is_user_initiated()) {
      NotifyExitListeners();
    }
  }

  // Close all the ports owned by this isolate.
  PortMap::ClosePorts(message_handler());

  // Fail fast if anybody tries to post any more messages to this isolate.
  delete message_handler();
  set_message_handler(nullptr);

  // Clean up any synchronous FFI callbacks registered with this isolate. Skip
  // if this isolate never registered any.
  if (ffi_callback_list_head_ != nullptr) {
    FfiCallbackMetadata::Instance()->DeleteAllCallbacks(
        &ffi_callback_list_head_);
  }

#if !defined(PRODUCT)
  if (FLAG_dump_megamorphic_stats) {
    MegamorphicCacheTable::PrintSizes(thread);
  }
  if (FLAG_dump_symbol_stats) {
    Symbols::DumpStats(group());
  }
  if (FLAG_trace_isolates) {
    group()->heap()->PrintSizes();
    OS::PrintErr(
        "[-] Stopping isolate:\n"
        "\tisolate:    %s\n",
        name());
  }
  if (FLAG_print_metrics) {
    LogBlock lb;
    OS::PrintErr("Printing metrics for %s\n", name());
#define ISOLATE_GROUP_METRIC_PRINT(type, variable, name, unit)                 \
  OS::PrintErr("%s\n", isolate_group_->Get##variable##Metric()->ToString());
    ISOLATE_GROUP_METRIC_LIST(ISOLATE_GROUP_METRIC_PRINT)
#undef ISOLATE_GROUP_METRIC_PRINT
#define ISOLATE_METRIC_PRINT(type, variable, name, unit)                       \
  OS::PrintErr("%s\n", metric_##variable##_.ToString());
    ISOLATE_METRIC_LIST(ISOLATE_METRIC_PRINT)
#undef ISOLATE_METRIC_PRINT
    OS::PrintErr("\n");
  }
#endif  // !defined(PRODUCT)
}

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
void IsolateGroup::MaybeIncreaseReloadEveryNStackOverflowChecks() {
  if (FLAG_reload_every_back_off) {
    if (reload_every_n_stack_overflow_checks_ < 5000) {
      reload_every_n_stack_overflow_checks_ += 99;
    } else {
      const auto old_value = reload_every_n_stack_overflow_checks_;
      reload_every_n_stack_overflow_checks_ = old_value * old_value;
    }
    // Cap the value.
    if (reload_every_n_stack_overflow_checks_ > 1000000) {
      reload_every_n_stack_overflow_checks_ = 1000000;
    }
  }
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

void Isolate::set_forward_table_new(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_new_ = std::move(value);
}
void Isolate::set_forward_table_old(WeakTable* table) {
  std::unique_ptr<WeakTable> value(table);
  forward_table_old_ = std::move(value);
}

void Isolate::Shutdown() {
  Thread* thread = Thread::Current();
  ASSERT(this == thread->isolate());

  // Don't allow anymore dart code to execution on this isolate.
  thread->ClearStackLimit();

  {
    StackZone zone(thread);
    ServiceIsolate::SendIsolateShutdownMessage();
#if !defined(PRODUCT)
    HandleScope handle_scope(thread);
    debugger()->Shutdown();
    Profiler::IsolateShutdown(thread);
#endif
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_check_reloaded && is_runnable() && !Isolate::IsSystemIsolate(this)) {
    if (!group()->HasAttemptedReload()) {
      FATAL(
          "Isolate did not reload before exiting and "
          "--check-reloaded is enabled.\n");
    }
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  // Then, proceed with low-level teardown.
  Isolate::UnMarkIsolateReady(this);

  // Ensure native finalizers are run before isolate has shutdown message is
  // sent. This way users can rely on the exit message that an isolate will not
  // run any Dart code anymore _and_ will not run any native finalizers anymore.
  RunAndCleanupFinalizersOnShutdown();

  // Post message before LowLevelShutdown that sends onExit message.
  // This ensures that exit message comes last.
  if (bequest_ != nullptr) {
    auto beneficiary = bequest_->beneficiary();
    auto handle = bequest_->TakeHandle();
    PortMap::PostMessage(
        Message::New(beneficiary, handle, Message::kNormalPriority));
    bequest_.reset();
  }

  LowLevelShutdown();

  // Now we can unregister from the thread, invoke cleanup callback, delete the
  // isolate (and possibly the isolate group).
  Isolate::LowLevelCleanup(this);
}

void Isolate::LowLevelCleanup(Isolate* isolate) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (KernelIsolate::IsKernelIsolate(isolate)) {
    KernelIsolate::SetKernelIsolate(nullptr);
  }
#endif
  if (ServiceIsolate::IsServiceIsolate(isolate)) {
    ServiceIsolate::SetServiceIsolate(nullptr);
  }

  // Cache these two fields, since they are no longer available after the
  // `delete isolate` further down.
  IsolateGroup* isolate_group = isolate->isolate_group_;
  Dart_IsolateCleanupCallback cleanup = isolate->on_cleanup_callback();
  auto callback_data = isolate->init_callback_data_;

  // From this point on the isolate is no longer visited by GC (which is ok,
  // since we're just going to delete it anyway).
  isolate_group->UnregisterIsolate(isolate);

  // From this point on the isolate doesn't participate in safepointing
  // requests anymore.
  ASSERT(!Thread::Current()->HasActiveState());
  Thread::ExitIsolate(/*isolate_shutdown=*/true);

  // Now it's safe to delete the isolate.
  delete isolate;

  // Run isolate specific cleanup function for all non "vm-isolate's.
  const bool is_vm_isolate = Dart::vm_isolate() == isolate;
  if (!is_vm_isolate) {
    if (cleanup != nullptr) {
      cleanup(isolate_group->embedder_data(), callback_data);
    }
  }

  const bool shutdown_group = isolate_group->UnregisterIsolateDecrementCount();
  if (shutdown_group) {
    KernelIsolate::NotifyAboutIsolateGroupShutdown(isolate_group);

    if (!is_vm_isolate) {
      Thread::EnterIsolateGroupAsHelper(isolate_group, Thread::kUnknownTask,
                                        /*bypass_safepoint=*/false);
#if !defined(DART_PRECOMPILED_RUNTIME)
      BackgroundCompiler::Stop(isolate_group);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

      // Finalize any weak persistent handles with a non-null referent with
      // isolate group still being available.
      FinalizeWeakPersistentHandlesVisitor visitor(isolate_group);
      isolate_group->api_state()->VisitWeakHandlesUnlocked(&visitor);

      Thread::ExitIsolateGroupAsHelper(/*bypass_safepoint=*/false);
    }

    // The "vm-isolate" does not have a thread pool.
    ASSERT(is_vm_isolate == (isolate_group->thread_pool() == nullptr));
    if (is_vm_isolate ||
        !isolate_group->thread_pool()->CurrentThreadIsWorker()) {
      isolate_group->Shutdown();
    } else {
      class ShutdownGroupTask : public ThreadPool::Task {
       public:
        explicit ShutdownGroupTask(IsolateGroup* isolate_group)
            : isolate_group_(isolate_group) {}

        virtual void Run() { isolate_group_->Shutdown(); }

       private:
        IsolateGroup* isolate_group_;
      };
      // The current thread is running on the isolate group's thread pool.
      // So we cannot safely delete the isolate group (and it's pool).
      // Instead we will destroy the isolate group on the VM-global pool.
      if (FLAG_trace_shutdown) {
        OS::PrintErr("[+%" Pd64 "ms] : Scheduling shutdown on VM pool %s\n",
                     Dart::UptimeMillis(), isolate_group->source()->name);
      }
      Dart::thread_pool()->Run<ShutdownGroupTask>(isolate_group);
    }
  } else {
    // TODO(dartbug.com/36097): An isolate just died. A significant amount of
    // memory might have become unreachable. We should evaluate how to best
    // inform the GC about this situation.
  }
}

Dart_InitializeIsolateCallback Isolate::initialize_callback_ = nullptr;
Dart_IsolateGroupCreateCallback Isolate::create_group_callback_ = nullptr;
Dart_IsolateShutdownCallback Isolate::shutdown_callback_ = nullptr;
Dart_IsolateCleanupCallback Isolate::cleanup_callback_ = nullptr;
Dart_IsolateGroupCleanupCallback Isolate::cleanup_group_callback_ = nullptr;
Dart_RegisterKernelBlobCallback Isolate::register_kernel_blob_callback_ =
    nullptr;
Dart_UnregisterKernelBlobCallback Isolate::unregister_kernel_blob_callback_ =
    nullptr;

Random* IsolateGroup::isolate_group_random_ = nullptr;
Monitor* Isolate::isolate_creation_monitor_ = nullptr;
bool Isolate::creation_enabled_ = false;

RwLock* IsolateGroup::isolate_groups_rwlock_ = nullptr;
IntrusiveDList<IsolateGroup>* IsolateGroup::isolate_groups_ = nullptr;

void Isolate::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                  ValidationPolicy validate_frames) {
  ASSERT(visitor != nullptr);

  // Visit objects in the field table.
  // N.B.: The heap snapshot writer requires visiting the field table first, so
  // that the pointer visitation order aligns with order of field name metadata.
  if (!visitor->trace_values_through_fields()) {
    field_table()->VisitObjectPointers(visitor);
  }

  // Visit objects in the isolate object store.
  if (isolate_object_store() != nullptr) {
    isolate_object_store()->VisitObjectPointers(visitor);
  }

  visitor->clear_gc_root_type();
  // Visit the objects directly referenced from the isolate structure.
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&current_tag_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&default_tag_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&tag_table_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&sticky_error_));
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&finalizers_));
#if !defined(PRODUCT)
  visitor->VisitPointer(
      reinterpret_cast<ObjectPtr*>(&pending_service_extension_calls_));
  visitor->VisitPointer(
      reinterpret_cast<ObjectPtr*>(&registered_service_extension_handlers_));
#endif  // !defined(PRODUCT)

#if !defined(PRODUCT)
  // Visit objects in the debugger.
  if (debugger() != nullptr) {
    debugger()->VisitObjectPointers(visitor);
  }
  if (ServiceIsolate::IsServiceIsolate(this)) {
    ServiceIsolate::VisitObjectPointers(visitor);
  }
#endif  // !defined(PRODUCT)

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Visit objects that are being used for deoptimization.
  if (deopt_context() != nullptr) {
    deopt_context()->VisitObjectPointers(visitor);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  visitor->VisitPointer(
      reinterpret_cast<ObjectPtr*>(&loaded_prefixes_set_storage_));

  if (pointers_to_verify_at_exit_.length() != 0) {
    visitor->VisitPointers(&pointers_to_verify_at_exit_[0],
                           pointers_to_verify_at_exit_.length());
  }
}

void Isolate::VisitStackPointers(ObjectPointerVisitor* visitor,
                                 ValidationPolicy validate_frames) {
  if (mutator_thread_ != nullptr) {
    mutator_thread_->VisitObjectPointers(visitor, validate_frames);
  }
}

void IsolateGroup::ReleaseStoreBuffers() {
  thread_registry()->ReleaseStoreBuffers();
}

void Isolate::RememberLiveTemporaries() {
  if (mutator_thread_ != nullptr) {
    mutator_thread_->RememberLiveTemporaries();
  }
}

void Isolate::DeferredMarkLiveTemporaries() {
  if (mutator_thread_ != nullptr) {
    mutator_thread_->DeferredMarkLiveTemporaries();
  }
}

void Isolate::init_loaded_prefixes_set_storage() {
  ASSERT(loaded_prefixes_set_storage_ == nullptr);
  loaded_prefixes_set_storage_ =
      HashTables::New<UnorderedHashSet<LibraryPrefixMapTraits> >(4);
}

bool Isolate::IsPrefixLoaded(const LibraryPrefix& prefix) const {
  UnorderedHashSet<LibraryPrefixMapTraits> loaded_prefixes_set(
      loaded_prefixes_set_storage_);
  bool result = loaded_prefixes_set.GetOrNull(prefix) != Object::null();
  loaded_prefixes_set.Release();
  return result;
}

void Isolate::SetPrefixIsLoaded(const LibraryPrefix& prefix) {
  UnorderedHashSet<LibraryPrefixMapTraits> loaded_prefixes_set(
      loaded_prefixes_set_storage_);
  loaded_prefixes_set.InsertOrGet(prefix);
  loaded_prefixes_set_storage_ = loaded_prefixes_set.Release().ptr();
}

void IsolateGroup::EnableIncrementalBarrier(
    MarkingStack* marking_stack,
    MarkingStack* deferred_marking_stack) {
  ASSERT(marking_stack_ == nullptr);
  marking_stack_ = marking_stack;
  deferred_marking_stack_ = deferred_marking_stack;
  thread_registry()->AcquireMarkingStacks();
  ASSERT(Thread::Current()->is_marking());
}

void IsolateGroup::DisableIncrementalBarrier() {
  thread_registry()->ReleaseMarkingStacks();
  ASSERT(marking_stack_ != nullptr);
  marking_stack_ = nullptr;
  deferred_marking_stack_ = nullptr;
}

void IsolateGroup::ForEachIsolate(
    std::function<void(Isolate* isolate)> function,
    bool at_safepoint) {
  auto thread = Thread::Current();
  if (at_safepoint) {
    ASSERT(thread->OwnsSafepoint() ||
           (thread->task_kind() == Thread::kMutatorTask) ||
           (thread->task_kind() == Thread::kMarkerTask) ||
           (thread->task_kind() == Thread::kCompactorTask) ||
           (thread->task_kind() == Thread::kScavengerTask));
    for (Isolate* isolate : isolates_) {
      function(isolate);
    }
    return;
  }
  if (thread != nullptr && thread->OwnsSafepoint()) {
    for (Isolate* isolate : isolates_) {
      function(isolate);
    }
    return;
  }
  SafepointReadRwLocker ml(thread, isolates_lock_.get());
  for (Isolate* isolate : isolates_) {
    function(isolate);
  }
}

Isolate* IsolateGroup::FirstIsolate() const {
  SafepointReadRwLocker ml(Thread::Current(), isolates_lock_.get());
  return FirstIsolateLocked();
}

Isolate* IsolateGroup::FirstIsolateLocked() const {
  return isolates_.IsEmpty() ? nullptr : isolates_.First();
}

void IsolateGroup::RunWithStoppedMutatorsCallable(
    Callable* single_current_mutator,
    Callable* otherwise,
    bool use_force_growth_in_otherwise) {
  auto thread = Thread::Current();
  StoppedMutatorsScope stopped_mutators_scope(thread);

  if (thread->OwnsSafepoint()) {
    RELEASE_ASSERT(thread->OwnsSafepoint());
    single_current_mutator->Call();
    return;
  }

  {
    SafepointReadRwLocker ml(thread, isolates_lock_.get());
    if (thread->IsDartMutatorThread() && ContainsOnlyOneIsolate()) {
      single_current_mutator->Call();
      return;
    }
  }

  // We use the more strict safepoint operation scope here (which ensures that
  // all other threads, including auxiliary threads are at a safepoint), even
  // though we only need to ensure that the mutator threads are stopped.
  if (use_force_growth_in_otherwise) {
    ForceGrowthSafepointOperationScope safepoint_scope(
        thread, SafepointLevel::kGCAndDeopt);
    otherwise->Call();
  } else {
    DeoptSafepointOperationScope safepoint_scope(thread);
    otherwise->Call();
  }
}

void IsolateGroup::VisitObjectPointers(ObjectPointerVisitor* visitor,
                                       ValidationPolicy validate_frames) {
  VisitSharedPointers(visitor);
  for (Isolate* isolate : isolates_) {
    isolate->VisitObjectPointers(visitor, validate_frames);
  }
  VisitStackPointers(visitor, validate_frames);
}

void IsolateGroup::VisitSharedPointers(ObjectPointerVisitor* visitor) {
  // Visit objects in the class table.
  class_table()->VisitObjectPointers(visitor);
  if (heap_walk_class_table() != class_table()) {
    heap_walk_class_table()->VisitObjectPointers(visitor);
  }
  api_state()->VisitObjectPointersUnlocked(visitor);
  // Visit objects in the object store.
  if (object_store() != nullptr) {
    object_store()->VisitObjectPointers(visitor);
  }
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&saved_unlinked_calls_));
  initial_field_table()->VisitObjectPointers(visitor);

  // Visit the boxed_field_list_.
  // 'boxed_field_list_' access via mutator and background compilation threads
  // is guarded with a monitor. This means that we can visit it only
  // when at safepoint or the field_list_mutex_ lock has been taken.
  visitor->VisitPointer(reinterpret_cast<ObjectPtr*>(&boxed_field_list_));

  NOT_IN_PRECOMPILED(background_compiler()->VisitPointers(visitor));

#if !defined(PRODUCT)
  if (debugger() != nullptr) {
    debugger()->VisitObjectPointers(visitor);
  }
#endif

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // Visit objects that are being used for isolate reload.
  if (program_reload_context() != nullptr) {
    program_reload_context()->VisitObjectPointers(visitor);
    program_reload_context()->group_reload_context()->VisitObjectPointers(
        visitor);
  }
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

  if (source()->loaded_blobs_ != nullptr) {
    visitor->VisitPointer(
        reinterpret_cast<ObjectPtr*>(&(source()->loaded_blobs_)));
  }

  if (become() != nullptr) {
    become()->VisitObjectPointers(visitor);
  }
}

void IsolateGroup::VisitStackPointers(ObjectPointerVisitor* visitor,
                                      ValidationPolicy validate_frames) {
  visitor->set_gc_root_type("stack");

  // Visit objects in all threads (e.g. Dart stack, handles in zones), except
  // for the mutator threads themselves.
  thread_registry()->VisitObjectPointers(this, visitor, validate_frames);

  for (Isolate* isolate : isolates_) {
    // Visit mutator thread, even if the isolate isn't entered/scheduled
    // (there might be live API handles to visit).
    isolate->VisitStackPointers(visitor, validate_frames);
  }

  visitor->clear_gc_root_type();
}

void IsolateGroup::VisitObjectIdRingPointers(ObjectPointerVisitor* visitor) {
#if !defined(PRODUCT)
  for (Isolate* isolate : isolates_) {
    ObjectIdRing* ring = isolate->object_id_ring();
    if (ring != nullptr) {
      ring->VisitPointers(visitor);
    }
  }
#endif  // !defined(PRODUCT)
}

void IsolateGroup::VisitWeakPersistentHandles(HandleVisitor* visitor) {
  api_state()->VisitWeakHandlesUnlocked(visitor);
}

void IsolateGroup::DeferredMarkLiveTemporaries() {
  ForEachIsolate(
      [&](Isolate* isolate) { isolate->DeferredMarkLiveTemporaries(); },
      /*at_safepoint=*/true);
}

void IsolateGroup::RememberLiveTemporaries() {
  ForEachIsolate([&](Isolate* isolate) { isolate->RememberLiveTemporaries(); },
                 /*at_safepoint=*/true);
}

#if !defined(PRODUCT)
ObjectIdRing* Isolate::EnsureObjectIdRing() {
  if (object_id_ring_ == nullptr) {
    object_id_ring_ = new ObjectIdRing();
  }
  return object_id_ring_;
}
#endif  // !defined(PRODUCT)

#ifndef PRODUCT
static const char* ExceptionPauseInfoToServiceEnum(Dart_ExceptionPauseInfo pi) {
  switch (pi) {
    case kPauseOnAllExceptions:
      return "All";
    case kNoPauseOnExceptions:
      return "None";
    case kPauseOnUnhandledExceptions:
      return "Unhandled";
    default:
      UNIMPLEMENTED();
      return nullptr;
  }
}

static ServiceEvent IsolatePauseEvent(Isolate* isolate) {
  if (!isolate->is_runnable()) {
    // Isolate is not yet runnable.
    ASSERT((isolate->debugger() == nullptr) ||
           (isolate->debugger()->PauseEvent() == nullptr));
    return ServiceEvent(isolate, ServiceEvent::kNone);
  } else if (isolate->message_handler()->should_pause_on_start()) {
    if (isolate->message_handler()->is_paused_on_start()) {
      ASSERT((isolate->debugger() == nullptr) ||
             (isolate->debugger()->PauseEvent() == nullptr));
      return ServiceEvent(isolate, ServiceEvent::kPauseStart);
    } else {
      // Isolate is runnable but not paused on start.
      // Some service clients get confused if they see:
      // NotRunnable -> Runnable -> PausedAtStart
      // Treat Runnable+ShouldPauseOnStart as NotRunnable so they see:
      // NonRunnable -> PausedAtStart
      // The should_pause_on_start flag is set to false after resume.
      ASSERT((isolate->debugger() == nullptr) ||
             (isolate->debugger()->PauseEvent() == nullptr));
      return ServiceEvent(isolate, ServiceEvent::kNone);
    }
  } else if (isolate->message_handler()->is_paused_on_exit() &&
             ((isolate->debugger() == nullptr) ||
              (isolate->debugger()->PauseEvent() == nullptr))) {
    return ServiceEvent(isolate, ServiceEvent::kPauseExit);
  } else if ((isolate->debugger() != nullptr) &&
             (isolate->debugger()->PauseEvent() != nullptr) &&
             !isolate->ResumeRequest()) {
    return *(isolate->debugger()->PauseEvent());
  } else {
    ServiceEvent pause_event(isolate, ServiceEvent::kResume);

    if (isolate->debugger() != nullptr) {
      // TODO(turnidge): Don't compute a full stack trace.
      DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
      if (stack->Length() > 0) {
        pause_event.set_top_frame(stack->FrameAt(0));
      }
    }

    return pause_event;
  }
}

void Isolate::PrintJSON(JSONStream* stream, bool ref) {
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", (ref ? "@Isolate" : "Isolate"));
  jsobj.AddServiceId(ISOLATE_SERVICE_ID_FORMAT_STRING,
                     static_cast<int64_t>(main_port()));

  jsobj.AddProperty("name", name());
  jsobj.AddPropertyF("number", "%" Pd64 "", static_cast<int64_t>(main_port()));
  jsobj.AddProperty("isSystemIsolate", is_system_isolate());
  jsobj.AddPropertyF("isolateGroupId", ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING,
                     group()->id());
  if (ref) {
    return;
  }
  jsobj.AddPropertyF("_originNumber", "%" Pd64 "",
                     static_cast<int64_t>(origin_id()));
  int64_t uptime_millis = UptimeMicros() / kMicrosecondsPerMillisecond;
  int64_t start_time = OS::GetCurrentTimeMillis() - uptime_millis;
  jsobj.AddPropertyTimeMillis("startTime", start_time);
  {
    JSONObject jsheap(&jsobj, "_heaps");
    group()->heap()->PrintToJSONObject(Heap::kNew, &jsheap);
    group()->heap()->PrintToJSONObject(Heap::kOld, &jsheap);
  }

  {
// Stringification macros
// See https://gcc.gnu.org/onlinedocs/gcc-4.8.5/cpp/Stringification.html
#define TO_STRING(s) STR(s)
#define STR(s) #s

#define ADD_ISOLATE_FLAGS(when, name, bitname, isolate_flag_name, flag_name)   \
  {                                                                            \
    JSONObject jsflag(&jsflags);                                               \
    jsflag.AddProperty("name", TO_STRING(name));                               \
    jsflag.AddProperty("valueAsString", name() ? "true" : "false");            \
  }
    JSONArray jsflags(&jsobj, "isolateFlags");
    BOOL_ISOLATE_FLAG_LIST(ADD_ISOLATE_FLAGS)
#undef ADD_ISOLATE_FLAGS
#undef TO_STRING
#undef STR
  }

  jsobj.AddProperty("runnable", is_runnable());
  jsobj.AddProperty("livePorts", message_handler()->live_ports());
  jsobj.AddProperty("pauseOnExit", message_handler()->should_pause_on_exit());
#if !defined(DART_PRECOMPILED_RUNTIME)
  jsobj.AddProperty("_isReloading", group()->IsReloading());
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  ServiceEvent pause_event = IsolatePauseEvent(this);
  jsobj.AddProperty("pauseEvent", &pause_event);

  const Library& lib = Library::Handle(group()->object_store()->root_library());
  if (!lib.IsNull()) {
    jsobj.AddProperty("rootLib", lib);
  }

  if (FLAG_profiler) {
    JSONObject tagCounters(&jsobj, "_tagCounters");
    vm_tag_counters()->PrintToJSONObject(&tagCounters);
  }
  if (Thread::Current()->sticky_error() != Object::null()) {
    Error& error = Error::Handle(Thread::Current()->sticky_error());
    ASSERT(!error.IsNull());
    jsobj.AddProperty("error", error, false);
  } else if (sticky_error() != Object::null()) {
    Error& error = Error::Handle(sticky_error());
    ASSERT(!error.IsNull());
    jsobj.AddProperty("error", error, false);
  }

  {
    const GrowableObjectArray& libs =
        GrowableObjectArray::Handle(group()->object_store()->libraries());
    intptr_t num_libs = libs.Length();
    Library& lib = Library::Handle();

    JSONArray lib_array(&jsobj, "libraries");
    for (intptr_t i = 0; i < num_libs; i++) {
      lib ^= libs.At(i);
      ASSERT(!lib.IsNull());
      lib_array.AddValue(lib);
    }
  }

  {
    JSONArray breakpoints(&jsobj, "breakpoints");
    if (debugger() != nullptr) {
      debugger()->PrintBreakpointsToJSONArray(&breakpoints);
    }
  }

  Dart_ExceptionPauseInfo pause_info = (debugger() != nullptr)
                                           ? debugger()->GetExceptionPauseInfo()
                                           : kNoPauseOnExceptions;
  jsobj.AddProperty("exceptionPauseMode",
                    ExceptionPauseInfoToServiceEnum(pause_info));

  if (debugger() != nullptr) {
    JSONObject settings(&jsobj, "_debuggerSettings");
    debugger()->PrintSettingsToJSONObject(&settings);
  }

  {
    GrowableObjectArray& handlers =
        GrowableObjectArray::Handle(registered_service_extension_handlers());
    if (!handlers.IsNull()) {
      JSONArray extensions(&jsobj, "extensionRPCs");
      String& handler_name = String::Handle();
      for (intptr_t i = 0; i < handlers.Length(); i += kRegisteredEntrySize) {
        handler_name ^= handlers.At(i + kRegisteredNameIndex);
        extensions.AddValue(handler_name.ToCString());
      }
    }
  }

  {
    JSONObject isolate_group(&jsobj, "isolate_group");
    group()->PrintToJSONObject(&isolate_group, /*ref=*/true);
  }
}

void Isolate::PrintMemoryUsageJSON(JSONStream* stream) {
  group()->heap()->PrintMemoryUsageJSON(stream);
}

void Isolate::PrintPauseEventJSON(JSONStream* stream) {
  IsolatePauseEvent(this).PrintJSON(stream);
}

#endif

void Isolate::set_tag_table(const GrowableObjectArray& value) {
  tag_table_ = value.ptr();
}

void Isolate::set_current_tag(const UserTag& tag) {
  uword user_tag = tag.tag();
  ASSERT(user_tag < kUwordMax);
  set_user_tag(user_tag);
  current_tag_ = tag.ptr();
}

void Isolate::set_default_tag(const UserTag& tag) {
  default_tag_ = tag.ptr();
}

ErrorPtr Isolate::StealStickyError() {
  NoSafepointScope no_safepoint;
  ErrorPtr return_value = sticky_error_;
  sticky_error_ = Error::null();
  return return_value;
}

#if !defined(PRODUCT)
void Isolate::set_pending_service_extension_calls(
    const GrowableObjectArray& value) {
  pending_service_extension_calls_ = value.ptr();
}

void Isolate::set_registered_service_extension_handlers(
    const GrowableObjectArray& value) {
  registered_service_extension_handlers_ = value.ptr();
}
#endif  // !defined(PRODUCT)

#ifndef PRODUCT
ErrorPtr Isolate::InvokePendingServiceExtensionCalls() {
  GrowableObjectArray& calls =
      GrowableObjectArray::Handle(GetAndClearPendingServiceExtensionCalls());
  if (calls.IsNull()) {
    return Error::null();
  }
  // Grab run function.
  const Library& developer_lib = Library::Handle(Library::DeveloperLibrary());
  ASSERT(!developer_lib.IsNull());
  const Function& run_extension = Function::Handle(
      developer_lib.LookupLocalFunction(Symbols::_runExtension()));
  ASSERT(!run_extension.IsNull());

  const Array& arguments =
      Array::Handle(Array::New(kPendingEntrySize + 1, Heap::kNew));
  Object& result = Object::Handle();
  String& method_name = String::Handle();
  Instance& closure = Instance::Handle();
  Array& parameter_keys = Array::Handle();
  Array& parameter_values = Array::Handle();
  Instance& reply_port = Instance::Handle();
  Instance& id = Instance::Handle();
  for (intptr_t i = 0; i < calls.Length(); i += kPendingEntrySize) {
    // Grab arguments for call.
    closure ^= calls.At(i + kPendingHandlerIndex);
    ASSERT(!closure.IsNull());
    arguments.SetAt(kPendingHandlerIndex, closure);
    method_name ^= calls.At(i + kPendingMethodNameIndex);
    ASSERT(!method_name.IsNull());
    arguments.SetAt(kPendingMethodNameIndex, method_name);
    parameter_keys ^= calls.At(i + kPendingKeysIndex);
    ASSERT(!parameter_keys.IsNull());
    arguments.SetAt(kPendingKeysIndex, parameter_keys);
    parameter_values ^= calls.At(i + kPendingValuesIndex);
    ASSERT(!parameter_values.IsNull());
    arguments.SetAt(kPendingValuesIndex, parameter_values);
    reply_port ^= calls.At(i + kPendingReplyPortIndex);
    ASSERT(!reply_port.IsNull());
    arguments.SetAt(kPendingReplyPortIndex, reply_port);
    id ^= calls.At(i + kPendingIdIndex);
    arguments.SetAt(kPendingIdIndex, id);
    arguments.SetAt(kPendingEntrySize, Bool::Get(FLAG_trace_service));

    if (FLAG_trace_service) {
      OS::PrintErr("[+%" Pd64 "ms] Isolate %s invoking _runExtension for %s\n",
                   Dart::UptimeMillis(), name(), method_name.ToCString());
    }
    result = DartEntry::InvokeFunction(run_extension, arguments);
    if (FLAG_trace_service) {
      OS::PrintErr("[+%" Pd64 "ms] Isolate %s _runExtension complete for %s\n",
                   Dart::UptimeMillis(), name(), method_name.ToCString());
    }
    // Propagate the error.
    if (result.IsError()) {
      // Remaining service extension calls are dropped.
      if (!result.IsUnwindError()) {
        // Send error back over the protocol.
        Service::PostError(method_name, parameter_keys, parameter_values,
                           reply_port, id, Error::Cast(result));
      }
      return Error::Cast(result).ptr();
    }
    // Drain the microtask queue.
    result = DartLibraryCalls::DrainMicrotaskQueue();
    // Propagate the error.
    if (result.IsError()) {
      // Remaining service extension calls are dropped.
      return Error::Cast(result).ptr();
    }
  }
  return Error::null();
}

GrowableObjectArrayPtr Isolate::GetAndClearPendingServiceExtensionCalls() {
  GrowableObjectArrayPtr r = pending_service_extension_calls_;
  pending_service_extension_calls_ = GrowableObjectArray::null();
  return r;
}

void Isolate::AppendServiceExtensionCall(const Instance& closure,
                                         const String& method_name,
                                         const Array& parameter_keys,
                                         const Array& parameter_values,
                                         const Instance& reply_port,
                                         const Instance& id) {
  if (FLAG_trace_service) {
    OS::PrintErr("[+%" Pd64
                 "ms] Isolate %s ENQUEUING request for extension %s\n",
                 Dart::UptimeMillis(), name(), method_name.ToCString());
  }
  GrowableObjectArray& calls =
      GrowableObjectArray::Handle(pending_service_extension_calls());
  bool schedule_drain = false;
  if (calls.IsNull()) {
    calls = GrowableObjectArray::New();
    ASSERT(!calls.IsNull());
    set_pending_service_extension_calls(calls);
    schedule_drain = true;
  }
  ASSERT(kPendingHandlerIndex == 0);
  calls.Add(closure);
  ASSERT(kPendingMethodNameIndex == 1);
  calls.Add(method_name);
  ASSERT(kPendingKeysIndex == 2);
  calls.Add(parameter_keys);
  ASSERT(kPendingValuesIndex == 3);
  calls.Add(parameter_values);
  ASSERT(kPendingReplyPortIndex == 4);
  calls.Add(reply_port);
  ASSERT(kPendingIdIndex == 5);
  calls.Add(id);

  if (schedule_drain) {
    const Array& msg = Array::Handle(Array::New(3));
    Object& element = Object::Handle();
    element = Smi::New(Message::kIsolateLibOOBMsg);
    msg.SetAt(0, element);
    element = Smi::New(Isolate::kDrainServiceExtensionsMsg);
    msg.SetAt(1, element);
    element = Smi::New(Isolate::kBeforeNextEventAction);
    msg.SetAt(2, element);
    std::unique_ptr<Message> message = WriteMessage(
        /* same_group */ false, msg, main_port(), Message::kOOBPriority);
    bool posted = PortMap::PostMessage(std::move(message));
    ASSERT(posted);
  }
}

// This function is written in C++ and not Dart because we must do this
// operation atomically in the face of random OOB messages. Do not port
// to Dart code unless you can ensure that the operations will can be
// done atomically.
void Isolate::RegisterServiceExtensionHandler(const String& name,
                                              const Instance& closure) {
  // Don't allow for service extensions to be registered for internal isolates.
  if (Isolate::IsVMInternalIsolate(this)) {
    return;
  }
  GrowableObjectArray& handlers =
      GrowableObjectArray::Handle(registered_service_extension_handlers());
  if (handlers.IsNull()) {
    handlers = GrowableObjectArray::New(Heap::kOld);
    set_registered_service_extension_handlers(handlers);
  }
#if defined(DEBUG)
  {
    // Sanity check.
    const Instance& existing_handler =
        Instance::Handle(LookupServiceExtensionHandler(name));
    ASSERT(existing_handler.IsNull());
  }
#endif
  ASSERT(kRegisteredNameIndex == 0);
  handlers.Add(name, Heap::kOld);
  ASSERT(kRegisteredHandlerIndex == 1);
  handlers.Add(closure, Heap::kOld);
  {
    // Fire off an event.
    ServiceEvent event(this, ServiceEvent::kServiceExtensionAdded);
    event.set_extension_rpc(&name);
    Service::HandleEvent(&event);
  }
}

// This function is written in C++ and not Dart because we must do this
// operation atomically in the face of random OOB messages. Do not port
// to Dart code unless you can ensure that the operations will can be
// done atomically.
InstancePtr Isolate::LookupServiceExtensionHandler(const String& name) {
  const GrowableObjectArray& handlers =
      GrowableObjectArray::Handle(registered_service_extension_handlers());
  if (handlers.IsNull()) {
    return Instance::null();
  }
  String& handler_name = String::Handle();
  for (intptr_t i = 0; i < handlers.Length(); i += kRegisteredEntrySize) {
    handler_name ^= handlers.At(i + kRegisteredNameIndex);
    ASSERT(!handler_name.IsNull());
    if (handler_name.Equals(name)) {
      return Instance::RawCast(handlers.At(i + kRegisteredHandlerIndex));
    }
  }
  return Instance::null();
}

void Isolate::WakePauseEventHandler(Dart_Isolate isolate) {
  Isolate* iso = reinterpret_cast<Isolate*>(isolate);
  MonitorLocker ml(iso->pause_loop_monitor_);
  ml.Notify();

  Dart_MessageNotifyCallback current_notify_callback =
      iso->message_notify_callback();
  // It is possible that WakePauseEventHandler was replaced by original callback
  // while waiting for pause_loop_monitor_. In that case PauseEventHandler
  // is no longer running and the original callback needs to be invoked instead
  // of incrementing wake_pause_event_handler_count_.
  if (current_notify_callback != Isolate::WakePauseEventHandler) {
    if (current_notify_callback != nullptr) {
      current_notify_callback(isolate);
    }
  } else {
    ++iso->wake_pause_event_handler_count_;
  }
}

void Isolate::PauseEventHandler() {
  // We are stealing a pause event (like a breakpoint) from the
  // embedder.  We don't know what kind of thread we are on -- it
  // could be from our thread pool or it could be a thread from the
  // embedder.  Sit on the current thread handling service events
  // until we are told to resume.
  if (pause_loop_monitor_ == nullptr) {
    pause_loop_monitor_ = new Monitor();
  }
  Dart_EnterScope();
  MonitorLocker ml(pause_loop_monitor_, false);

  Dart_MessageNotifyCallback saved_notify_callback = message_notify_callback();
  ASSERT(wake_pause_event_handler_count_ == 0);
  set_message_notify_callback(Isolate::WakePauseEventHandler);

#if !defined(DART_PRECOMPILED_RUNTIME)
  const bool had_program_reload_context =
      group()->program_reload_context() != nullptr;
  const int64_t start_time_micros = !had_program_reload_context
                                        ? 0
                                        : group()
                                              ->program_reload_context()
                                              ->group_reload_context()
                                              ->start_time_micros();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  bool resume = false;
  while (true) {
    // Handle all available vm service messages, up to a resume
    // request.
    while (!resume && Dart_HasServiceMessages()) {
      ml.Exit();
      resume = Dart_HandleServiceMessages();
      ml.Enter();
    }
    if (resume) {
      break;
    }

#if !defined(DART_PRECOMPILED_RUNTIME)
    if (had_program_reload_context &&
        (group()->program_reload_context() == nullptr)) {
      if (FLAG_trace_reload) {
        const int64_t reload_time_micros =
            OS::GetCurrentMonotonicMicros() - start_time_micros;
        double reload_millis = MicrosecondsToMilliseconds(reload_time_micros);
        OS::PrintErr("Reloading has finished! (%.2f ms)\n", reload_millis);
      }
      break;
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

    // Wait for more service messages.
    Monitor::WaitResult res = ml.Wait();
    ASSERT(res == Monitor::kNotified);
  }
  // If any non-service messages came in, we need to notify the registered
  // message notify callback to check for unhandled messages. Otherwise, events
  // may be left unhandled until the next event comes in. See
  // https://github.com/dart-lang/sdk/issues/37312.
  if (saved_notify_callback != nullptr) {
    while (wake_pause_event_handler_count_ > 0) {
      saved_notify_callback(Api::CastIsolate(this));
      --wake_pause_event_handler_count_;
    }
  } else {
    wake_pause_event_handler_count_ = 0;
  }
  set_message_notify_callback(saved_notify_callback);
  Dart_ExitScope();
}
#endif  // !PRODUCT

void Isolate::VisitIsolates(IsolateVisitor* visitor) {
  if (visitor == nullptr) {
    return;
  }
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate(
        [&](Isolate* isolate) { visitor->VisitIsolate(isolate); });
  });
}

intptr_t Isolate::IsolateListLength() {
  intptr_t count = 0;
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) { count++; });
  });
  return count;
}

Isolate* Isolate::LookupIsolateByPort(Dart_Port port) {
  Isolate* match = nullptr;
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) {
      if (isolate->main_port() == port) {
        match = isolate;
      }
    });
  });
  return match;
}

std::unique_ptr<char[]> Isolate::LookupIsolateNameByPort(Dart_Port port) {
  MonitorLocker ml(isolate_creation_monitor_);
  std::unique_ptr<char[]> result;
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) {
      if (isolate->main_port() == port) {
        const size_t len = strlen(isolate->name()) + 1;
        result = std::unique_ptr<char[]>(new char[len]);
        strncpy(result.get(), isolate->name(), len);
      }
    });
  });
  return result;
}

bool Isolate::TryMarkIsolateReady(Isolate* isolate) {
  MonitorLocker ml(isolate_creation_monitor_);
  if (!creation_enabled_) {
    return false;
  }
  isolate->accepts_messages_ = true;
  return true;
}

void Isolate::UnMarkIsolateReady(Isolate* isolate) {
  MonitorLocker ml(isolate_creation_monitor_);
  isolate->accepts_messages_ = false;
}

void Isolate::DisableIsolateCreation() {
  MonitorLocker ml(isolate_creation_monitor_);
  creation_enabled_ = false;
}

void Isolate::EnableIsolateCreation() {
  MonitorLocker ml(isolate_creation_monitor_);
  creation_enabled_ = true;
}

bool Isolate::IsolateCreationEnabled() {
  MonitorLocker ml(isolate_creation_monitor_);
  return creation_enabled_;
}

bool IsolateGroup::IsSystemIsolateGroup(const IsolateGroup* group) {
  return group->source()->flags.is_system_isolate;
}

bool Isolate::IsVMInternalIsolate(const Isolate* isolate) {
  return isolate->is_kernel_isolate() || isolate->is_service_isolate() ||
         (Dart::vm_isolate() == isolate);
}

void Isolate::KillLocked(LibMsgId msg_id) {
  Dart_CObject kill_msg;
  Dart_CObject* list_values[4];
  kill_msg.type = Dart_CObject_kArray;
  kill_msg.value.as_array.length = 4;
  kill_msg.value.as_array.values = list_values;

  Dart_CObject oob;
  oob.type = Dart_CObject_kInt32;
  oob.value.as_int32 = Message::kIsolateLibOOBMsg;
  list_values[0] = &oob;

  Dart_CObject msg_type;
  msg_type.type = Dart_CObject_kInt32;
  msg_type.value.as_int32 = msg_id;
  list_values[1] = &msg_type;

  Dart_CObject cap;
  cap.type = Dart_CObject_kCapability;
  cap.value.as_capability.id = terminate_capability();
  list_values[2] = &cap;

  Dart_CObject imm;
  imm.type = Dart_CObject_kInt32;
  imm.value.as_int32 = Isolate::kImmediateAction;
  list_values[3] = &imm;

  {
    AllocOnlyStackZone zone;
    std::unique_ptr<Message> message = WriteApiMessage(
        zone.GetZone(), &kill_msg, main_port(), Message::kOOBPriority);
    ASSERT(message != nullptr);

    // Post the message at the given port.
    bool success = PortMap::PostMessage(std::move(message));
    ASSERT(success);
  }
}

class IsolateKillerVisitor : public IsolateVisitor {
 public:
  explicit IsolateKillerVisitor(Isolate::LibMsgId msg_id)
      : target_(nullptr), msg_id_(msg_id) {}

  IsolateKillerVisitor(Isolate* isolate, Isolate::LibMsgId msg_id)
      : target_(isolate), msg_id_(msg_id) {
    ASSERT(isolate != Dart::vm_isolate());
  }

  virtual ~IsolateKillerVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    MonitorLocker ml(Isolate::isolate_creation_monitor_);
    ASSERT(isolate != nullptr);
    if (ShouldKill(isolate)) {
      if (isolate->AcceptsMessagesLocked()) {
        isolate->KillLocked(msg_id_);
      }
    }
  }

 private:
  bool ShouldKill(Isolate* isolate) {
    // If a target_ is specified, then only kill the target_.
    // Otherwise, don't kill the service isolate or vm isolate.
    return (((target_ != nullptr) && (isolate == target_)) ||
            ((target_ == nullptr) && !IsSystemIsolate(isolate)));
  }

  Isolate* target_;
  Isolate::LibMsgId msg_id_;
};

void Isolate::KillAllIsolates(LibMsgId msg_id) {
  IsolateKillerVisitor visitor(msg_id);
  VisitIsolates(&visitor);
}

void Isolate::KillIfExists(Isolate* isolate, LibMsgId msg_id) {
  IsolateKillerVisitor visitor(isolate, msg_id);
  VisitIsolates(&visitor);
}

void Isolate::IncrementSpawnCount() {
  MonitorLocker ml(&spawn_count_monitor_);
  spawn_count_++;
}

void Isolate::DecrementSpawnCount() {
  MonitorLocker ml(&spawn_count_monitor_);
  ASSERT(spawn_count_ > 0);
  spawn_count_--;
  ml.Notify();
}

void Isolate::WaitForOutstandingSpawns() {
  Thread* thread = Thread::Current();
  ASSERT(thread != nullptr);
  MonitorLocker ml(&spawn_count_monitor_);
  while (spawn_count_ > 0) {
    ml.WaitWithSafepointCheck(thread);
  }
}

FfiCallbackMetadata::Trampoline Isolate::CreateSyncFfiCallback(
    Zone* zone,
    const Function& function) {
  return FfiCallbackMetadata::Instance()->CreateSyncFfiCallback(
      this, zone, function, &ffi_callback_list_head_);
}

FfiCallbackMetadata::Trampoline Isolate::CreateAsyncFfiCallback(
    Zone* zone,
    const Function& send_function,
    Dart_Port send_port) {
  return FfiCallbackMetadata::Instance()->CreateAsyncFfiCallback(
      this, zone, send_function, send_port, &ffi_callback_list_head_);
}

void Isolate::DeleteFfiCallback(FfiCallbackMetadata::Trampoline callback) {
  FfiCallbackMetadata::Instance()->DeleteCallback(callback,
                                                  &ffi_callback_list_head_);
}

#if !defined(PRODUCT)
void IsolateGroup::CloneClassTableForReload() {
  RELEASE_ASSERT(class_table_ == heap_walk_class_table_);
  class_table_ = class_table_->Clone();
  set_cached_class_table_table(nullptr);
}

void IsolateGroup::RestoreOriginalClassTable() {
  RELEASE_ASSERT(class_table_ != heap_walk_class_table_);
  class_table_allocator_.Free(class_table_);
  class_table_ = heap_walk_class_table_;
  set_cached_class_table_table(class_table_->table());
}

void IsolateGroup::DropOriginalClassTable() {
  RELEASE_ASSERT(class_table_ != heap_walk_class_table_);
  class_table_allocator_.Free(heap_walk_class_table_);
  heap_walk_class_table_ = class_table_;
  set_cached_class_table_table(class_table_->table());
}
#endif

}  // namespace dart
