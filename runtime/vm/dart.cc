// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/dart.h"

#include "vm/clustered_snapshot.h"
#include "vm/code_observers.h"
#include "vm/compiler/runtime_offsets_extracted.h"
#include "vm/compiler/runtime_offsets_list.h"
#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/handles.h"
#include "vm/heap/become.h"
#include "vm/heap/freelist.h"
#include "vm/heap/heap.h"
#include "vm/heap/pointer_block.h"
#include "vm/isolate.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
#include "vm/malloc_hooks.h"
#include "vm/message_handler.h"
#include "vm/metrics.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/reverse_pc_lookup_cache.h"
#include "vm/service_isolate.h"
#include "vm/simulator.h"
#include "vm/snapshot.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(bool, print_class_table);
DEFINE_FLAG(bool, keep_code, false, "Keep deoptimized code for profiling.");
DEFINE_FLAG(bool, trace_shutdown, false, "Trace VM shutdown on stderr");
DECLARE_FLAG(bool, strong);

Isolate* Dart::vm_isolate_ = NULL;
int64_t Dart::start_time_micros_ = 0;
ThreadPool* Dart::thread_pool_ = NULL;
DebugInfo* Dart::pprof_symbol_generator_ = NULL;
ReadOnlyHandles* Dart::predefined_handles_ = NULL;
Snapshot::Kind Dart::vm_snapshot_kind_ = Snapshot::kInvalid;
Dart_ThreadExitCallback Dart::thread_exit_callback_ = NULL;
Dart_FileOpenCallback Dart::file_open_callback_ = NULL;
Dart_FileReadCallback Dart::file_read_callback_ = NULL;
Dart_FileWriteCallback Dart::file_write_callback_ = NULL;
Dart_FileCloseCallback Dart::file_close_callback_ = NULL;
Dart_EntropySource Dart::entropy_source_callback_ = NULL;

// Structure for managing read-only global handles allocation used for
// creating global read-only handles that are pre created and initialized
// for use across all isolates. Having these global pre created handles
// stored in the vm isolate ensures that we don't constantly create and
// destroy handles for read-only objects referred in the VM code
// (e.g: symbols, null object, empty array etc.)
// The ReadOnlyHandles C++ Wrapper around VMHandles which is a ValueObject is
// to ensure that the handles area is not trashed by automatic running of C++
// static destructors when 'exit()" is called by any isolate. There might be
// other isolates running at the same time and trashing the handles area will
// have unintended consequences.
class ReadOnlyHandles {
 public:
  ReadOnlyHandles() {}

 private:
  VMHandles handles_;
  LocalHandles api_handles_;

  friend class Dart;
  DISALLOW_COPY_AND_ASSIGN(ReadOnlyHandles);
};

static void CheckOffsets() {
#if !defined(IS_SIMARM_X64)
  // These offsets are embedded in precompiled instructions. We need the
  // compiler and the runtime to agree.
  bool ok = true;
#define CHECK_OFFSET(expr, offset)                                             \
  if ((expr) != (offset)) {                                                    \
    OS::PrintErr("%s got %" Pd ", %s expected %" Pd "\n", #expr,               \
                 static_cast<intptr_t>(expr), #offset,                         \
                 static_cast<intptr_t>(offset));                               \
    ok = false;                                                                \
  }

#define CHECK_FIELD(Class, Name) CHECK_OFFSET(Class::Name(), Class##_##Name)
#define CHECK_ARRAY(Class, Name)                                               \
  CHECK_OFFSET(Class::ArrayLayout::elements_start_offset(),                    \
               Class##_elements_start_offset)                                  \
  CHECK_OFFSET(Class::ArrayLayout::kElementSize, Class##_element_size)
#define CHECK_ARRAY_STRUCTFIELD(Class, Name, ElementOffsetName, FieldOffset)
#define CHECK_SIZEOF(Class, Name, What)                                        \
  CHECK_OFFSET(sizeof(What), Class##_##Name)
#define CHECK_RANGE(Class, Name, Type, First, Last, Filter)
#define CHECK_CONSTANT(Class, Name) CHECK_OFFSET(Class::Name, Class##_##Name)

  OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_ARRAY_STRUCTFIELD, CHECK_SIZEOF,
               CHECK_RANGE, CHECK_CONSTANT, NOT_IN_PRECOMPILED_RUNTIME)

  if (!ok) {
    FATAL(
        "CheckOffsets failed. Try updating offsets by running "
        "./tools/run_offsets_extractor.sh");
  }
#undef CHECK_FIELD
#undef CHECK_ARRAY
#undef CHECK_ARRAY_STRUCTFIELD
#undef CHECK_SIZEOF
#undef CHECK_RANGE
#undef CHECK_CONSTANT
#undef CHECK_OFFSET
#endif  // !defined(IS_SIMARM_X64)
}

char* Dart::Init(const uint8_t* vm_isolate_snapshot,
                 const uint8_t* instructions_snapshot,
                 Dart_IsolateGroupCreateCallback create_group,
                 Dart_InitializeIsolateCallback initialize_isolate,
                 Dart_IsolateShutdownCallback shutdown,
                 Dart_IsolateShutdownCallback cleanup,
                 Dart_IsolateGroupCleanupCallback cleanup_group,
                 Dart_ThreadExitCallback thread_exit,
                 Dart_FileOpenCallback file_open,
                 Dart_FileReadCallback file_read,
                 Dart_FileWriteCallback file_write,
                 Dart_FileCloseCallback file_close,
                 Dart_EntropySource entropy_source,
                 Dart_GetVMServiceAssetsArchive get_service_assets,
                 bool start_kernel_isolate,
                 Dart_CodeObserver* observer) {
  CheckOffsets();
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return strdup("VM already initialized or flags not initialized.");
  }

  const Snapshot* snapshot = nullptr;
  if (vm_isolate_snapshot != nullptr) {
    snapshot = Snapshot::SetupFromBuffer(vm_isolate_snapshot);
    if (snapshot == nullptr) {
      return strdup("Invalid vm isolate snapshot seen");
    }
  }

  // We are initializing the VM. We will take the VM-global flags used
  // during snapshot generation time also at runtime (this avoids the need
  // for the embedder to pass the same flags used during snapshot generation
  // also to the runtime).
  if (snapshot != nullptr) {
    char* error =
        SnapshotHeaderReader::InitializeGlobalVMFlagsFromSnapshot(snapshot);
    if (error != nullptr) {
      return error;
    }
  }

#if defined(DEBUG)
  // Turn on verify_gc_contains if any of the other GC verification flag
  // is turned on.
  if (FLAG_verify_before_gc || FLAG_verify_after_gc ||
      FLAG_verify_on_transition) {
    FLAG_verify_gc_contains = true;
  }
#endif

#if defined(TARGET_ARCH_DBC)
  // DBC instructions are never executable.
  FLAG_write_protect_code = false;
#endif

  if (FLAG_enable_interpreter) {
#if defined(TARGET_ARCH_DBC)
    return strdup("--enable-interpreter is not supported with DBC");
#endif  // defined(TARGET_ARCH_DBC)
  }

  FrameLayout::Init();

  set_thread_exit_callback(thread_exit);
  SetFileCallbacks(file_open, file_read, file_write, file_close);
  set_entropy_source_callback(entropy_source);
  OS::Init();
  NOT_IN_PRODUCT(CodeObservers::Init());
  NOT_IN_PRODUCT(CodeObservers::RegisterExternal(observer));
  start_time_micros_ = OS::GetCurrentMonotonicMicros();
  VirtualMemory::Init();
  OSThread::Init();
#if defined(SUPPORT_TIMELINE)
  Timeline::Init();
  TimelineDurationScope tds(Timeline::GetVMStream(), "Dart::Init");
#endif
  Isolate::InitVM();
  PortMap::Init();
  FreeListElement::Init();
  ForwardingCorpse::Init();
  Api::Init();
  NativeSymbolResolver::Init();
  NOT_IN_PRODUCT(Profiler::Init());
  SemiSpace::Init();
  NOT_IN_PRODUCT(Metric::Init());
  StoreBuffer::Init();
  MarkingStack::Init();

#if defined(USING_SIMULATOR)
  Simulator::Init();
#endif
  // Create the read-only handles area.
  ASSERT(predefined_handles_ == NULL);
  predefined_handles_ = new ReadOnlyHandles();
  // Create the VM isolate and finish the VM initialization.
  ASSERT(thread_pool_ == NULL);
  thread_pool_ = new ThreadPool();
  {
    ASSERT(vm_isolate_ == NULL);
    ASSERT(Flags::Initialized());
    const bool is_vm_isolate = true;

    // Setup default flags for the VM isolate.
    Dart_IsolateFlags api_flags;
    Isolate::FlagsInitialize(&api_flags);

    // We make a fake [IsolateGroupSource] here, since the "vm-isolate" is not
    // really an isolate itself - it acts more as a container for VM-global
    // objects.
    std::unique_ptr<IsolateGroupSource> source(
        new IsolateGroupSource(nullptr, "vm-isolate", nullptr, nullptr, nullptr,
                               nullptr, nullptr, -1, api_flags));
    auto group = new IsolateGroup(std::move(source), /*embedder_data=*/nullptr);
    vm_isolate_ =
        Isolate::InitIsolate("vm-isolate", group, api_flags, is_vm_isolate);
    group->set_initial_spawn_successful();

    // Verify assumptions about executing in the VM isolate.
    ASSERT(vm_isolate_ == Isolate::Current());
    ASSERT(vm_isolate_ == Thread::Current()->isolate());

    Thread* T = Thread::Current();
    ASSERT(T != NULL);
    StackZone zone(T);
    HandleScope handle_scope(T);
    Object::InitNull(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    TargetCPUFeatures::Init();
    Object::Init(vm_isolate_);
    ArgumentsDescriptor::Init();
    ICData::Init();
    if (vm_isolate_snapshot != NULL) {
#if defined(SUPPORT_TIMELINE)
      TimelineDurationScope tds(Timeline::GetVMStream(), "ReadVMSnapshot");
#endif
      ASSERT(snapshot != nullptr);
      vm_snapshot_kind_ = snapshot->kind();

      if (Snapshot::IncludesCode(vm_snapshot_kind_)) {
        if (vm_snapshot_kind_ == Snapshot::kFullAOT) {
#if defined(DART_PRECOMPILED_RUNTIME)
          vm_isolate_->set_compilation_allowed(false);
#else
          return strdup("JIT runtime cannot run a precompiled snapshot");
#endif
        }
        if (instructions_snapshot == NULL) {
          return strdup("Missing instructions snapshot");
        }
      } else if (Snapshot::IsFull(vm_snapshot_kind_)) {
#if defined(DART_PRECOMPILED_RUNTIME)
        return strdup("Precompiled runtime requires a precompiled snapshot");
#else
        StubCode::Init();
        Object::FinishInit(vm_isolate_);
        // MallocHooks can't be initialized until StubCode has been since stack
        // trace generation relies on stub methods that are generated in
        // StubCode::Init().
        // TODO(bkonyi) Split initialization for stack trace collection from the
        // initialization for the actual malloc hooks to increase accuracy of
        // memory consumption statistics.
        MallocHooks::Init();
#endif
      } else {
        return strdup("Invalid vm isolate snapshot seen");
      }
      FullSnapshotReader reader(snapshot, instructions_snapshot, NULL, NULL, T);
      const Error& error = Error::Handle(reader.ReadVMSnapshot());
      if (!error.IsNull()) {
        // Must copy before leaving the zone.
        return strdup(error.ToErrorCString());
      }

      ReversePcLookupCache::BuildAndAttachToIsolate(vm_isolate_);

      Object::FinishInit(vm_isolate_);
#if defined(SUPPORT_TIMELINE)
      if (tds.enabled()) {
        tds.SetNumArguments(2);
        tds.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
        tds.FormatArgument(
            1, "heapSize", "%" Pd64,
            vm_isolate_->heap()->UsedInWords(Heap::kOld) * kWordSize);
      }
#endif  // !defined(PRODUCT)
      if (FLAG_trace_isolates) {
        OS::PrintErr("Size of vm isolate snapshot = %" Pd "\n",
                     snapshot->length());
        vm_isolate_->heap()->PrintSizes();
        MegamorphicCacheTable::PrintSizes(vm_isolate_);
        intptr_t size;
        intptr_t capacity;
        Symbols::GetStats(vm_isolate_, &size, &capacity);
        OS::PrintErr("VM Isolate: Number of symbols : %" Pd "\n", size);
        OS::PrintErr("VM Isolate: Symbol table capacity : %" Pd "\n", capacity);
      }
    } else {
#if defined(DART_PRECOMPILED_RUNTIME)
      return strdup("Precompiled runtime requires a precompiled snapshot");
#elif !defined(DART_NO_SNAPSHOT)
      return strdup("Missing vm isolate snapshot");
#else
      vm_snapshot_kind_ = Snapshot::kNone;
      StubCode::Init();
      Object::FinishInit(vm_isolate_);
      // MallocHooks can't be initialized until StubCode has been since stack
      // trace generation relies on stub methods that are generated in
      // StubCode::Init().
      // TODO(bkonyi) Split initialization for stack trace collection from the
      // initialization for the actual malloc hooks to increase accuracy of
      // memory consumption statistics.
      MallocHooks::Init();
      Symbols::Init(vm_isolate_);
#endif
    }
    // We need to initialize the constants here for the vm isolate thread due to
    // bootstrapping issues.
    T->InitVMConstants();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Dart VM requires at least SSE2.
    if (!TargetCPUFeatures::sse2_supported()) {
      return strdup("SSE2 is required.");
    }
#endif
    {
#if defined(SUPPORT_TIMELINE)
      TimelineDurationScope tds(Timeline::GetVMStream(), "FinalizeVMIsolate");
#endif
      Object::FinalizeVMIsolate(vm_isolate_);
    }
#if defined(DEBUG)
    vm_isolate_->heap()->Verify(kRequireMarked);
#endif
  }
  // Allocate the "persistent" scoped handles for the predefined API
  // values (such as Dart_True, Dart_False and Dart_Null).
  Api::InitHandles();

  Thread::ExitIsolate();  // Unregister the VM isolate from this thread.
  Isolate::SetCreateGroupCallback(create_group);
  Isolate::SetInitializeCallback_(initialize_isolate);
  Isolate::SetShutdownCallback(shutdown);
  Isolate::SetCleanupCallback(cleanup);
  Isolate::SetGroupCleanupCallback(cleanup_group);

  if (FLAG_support_service) {
    Service::SetGetServiceAssetsCallback(get_service_assets);
  }

  const bool is_dart2_aot_precompiler =
      FLAG_precompiled_mode && !kDartPrecompiledRuntime;

  if (!is_dart2_aot_precompiler &&
      (FLAG_support_service || !kDartPrecompiledRuntime)) {
    ServiceIsolate::Run();
  }

#ifndef DART_PRECOMPILED_RUNTIME
  if (start_kernel_isolate) {
    KernelIsolate::Run();
  }
#endif  // DART_PRECOMPILED_RUNTIME

  return NULL;
}

bool Dart::HasApplicationIsolateLocked() {
  for (Isolate* isolate = Isolate::isolates_list_head_; isolate != NULL;
       isolate = isolate->next_) {
    if (!Isolate::IsVMInternalIsolate(isolate)) return true;
  }
  return false;
}

// This waits until only the VM, service and kernel isolates are in the list.
void Dart::WaitForApplicationIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolates_list_monitor_);
  intptr_t num_attempts = 0;
  while (HasApplicationIsolateLocked()) {
    Monitor::WaitResult retval = ml.Wait(1000);
    if (retval == Monitor::kTimedOut) {
      num_attempts += 1;
      if (num_attempts > 10) {
        for (Isolate* isolate = Isolate::isolates_list_head_; isolate != NULL;
             isolate = isolate->next_) {
          if (!Isolate::IsVMInternalIsolate(isolate)) {
            OS::PrintErr("Attempt:%" Pd " waiting for isolate %s to check in\n",
                         num_attempts, isolate->name_);
          }
        }
      }
    }
  }
}

// This waits until only the VM isolate remains in the list.
void Dart::WaitForIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolates_list_monitor_);
  intptr_t num_attempts = 0;
  while ((Isolate::isolates_list_head_ != NULL) &&
         (Isolate::isolates_list_head_->next_ != NULL)) {
    Monitor::WaitResult retval = ml.Wait(1000);
    if (retval == Monitor::kTimedOut) {
      num_attempts += 1;
      if (num_attempts > 10) {
        for (Isolate* isolate = Isolate::isolates_list_head_; isolate != NULL;
             isolate = isolate->next_)
          OS::PrintErr("Attempt:%" Pd " waiting for isolate %s to check in\n",
                       num_attempts, isolate->name_);
      }
    }
  }
  ASSERT(Isolate::isolates_list_head_ == Dart::vm_isolate());
}

char* Dart::Cleanup() {
  ASSERT(Isolate::Current() == NULL);
  if (vm_isolate_ == NULL) {
    return strdup("VM already terminated.");
  }

  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Starting shutdown\n",
                 UptimeMillis());
  }

#if !defined(PRODUCT)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down profiling\n",
                 UptimeMillis());
  }
  Profiler::Cleanup();
#endif  // !defined(PRODUCT)

  NativeSymbolResolver::Cleanup();

  // Disable the creation of new isolates.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Disabling isolate creation\n",
                 UptimeMillis());
  }
  Isolate::DisableIsolateCreation();

  // Send the OOB Kill message to all remaining application isolates.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Killing all app isolates\n",
                 UptimeMillis());
  }
  Isolate::KillAllIsolates(Isolate::kInternalKillMsg);

  // Wait for all isolates, but the service and the vm isolate to shut down.
  // Only do that if there is a service isolate running.
  if (ServiceIsolate::IsRunning() || KernelIsolate::IsRunning()) {
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down app isolates\n",
                   UptimeMillis());
    }
    WaitForApplicationIsolateShutdown();
  }

  // Shutdown the kernel isolate.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down kernel isolate\n",
                 UptimeMillis());
  }
  KernelIsolate::Shutdown();

  // Shutdown the service isolate.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down service isolate\n",
                 UptimeMillis());
  }
  ServiceIsolate::Shutdown();

  // Wait for the remaining isolate (service isolate) to shutdown
  // before shutting down the thread pool.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Waiting for isolate shutdown\n",
                 UptimeMillis());
  }
  WaitForIsolateShutdown();

#if !defined(PRODUCT)
  {
    // IMPORTANT: the code below enters VM isolate so that Metric::Cleanup could
    // create a StackZone. We *must* wait for all other isolate to shutdown
    // before entering VM isolate because code in the isolate initialization
    // calls VerifyBootstrapClasses, which calls Heap::Verify which calls
    // Scavenger::VisitObjects on the VM isolate's new space without taking
    // any sort of locks: assuming that vm isolate is immutable and never
    // entered by a mutator thread - which is in general true, but is violated
    // by the code below.
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Entering vm isolate\n",
                   UptimeMillis());
    }
    bool result = Thread::EnterIsolate(vm_isolate_);
    ASSERT(result);
    Metric::Cleanup();
    Thread::ExitIsolate();
  }
#endif

  // Shutdown the thread pool. On return, all thread pool threads have exited.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleting thread pool\n",
                 UptimeMillis());
  }
  delete thread_pool_;
  thread_pool_ = NULL;

  Api::Cleanup();
  delete predefined_handles_;
  predefined_handles_ = NULL;

  // Disable creation of any new OSThread structures which means no more new
  // threads can do an EnterIsolate. This must come after isolate shutdown
  // because new threads may need to be spawned to shutdown the isolates.
  // This must come after deletion of the thread pool to avoid a race in which
  // a thread spawned by the thread pool does not exit through the thread
  // pool, messing up its bookkeeping.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Disabling OS Thread creation\n",
                 UptimeMillis());
  }
  OSThread::DisableOSThreadCreation();

  // Set the VM isolate as current isolate.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Cleaning up vm isolate\n",
                 UptimeMillis());
  }
  bool result = Thread::EnterIsolate(vm_isolate_);
  ASSERT(result);

  ShutdownIsolate();
  vm_isolate_ = NULL;
  ASSERT(Isolate::IsolateListLength() == 0);
  PortMap::Cleanup();
  ICData::Cleanup();
  ArgumentsDescriptor::Cleanup();
  TargetCPUFeatures::Cleanup();
  MarkingStack::Cleanup();
  StoreBuffer::Cleanup();
  Object::Cleanup();
  SemiSpace::Cleanup();
  StubCode::Cleanup();
  // Delete the current thread's TLS and set it's TLS to null.
  // If it is the last thread then the destructor would call
  // OSThread::Cleanup.
  OSThread* os_thread = OSThread::Current();
  OSThread::SetCurrent(NULL);
  delete os_thread;
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleted os_thread\n",
                 UptimeMillis());
  }

  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleting code observers\n",
                 UptimeMillis());
  }
  NOT_IN_PRODUCT(CodeObservers::Cleanup());
#if defined(SUPPORT_TIMELINE)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down timeline\n",
                 UptimeMillis());
  }
  Timeline::Cleanup();
#endif
  OS::Cleanup();
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done\n", UptimeMillis());
  }
  MallocHooks::Cleanup();
  Flags::Cleanup();
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  IsolateReloadContext::SetFileModifiedCallback(NULL);
  Service::SetEmbedderStreamCallbacks(NULL, NULL);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  return NULL;
}

Isolate* Dart::CreateIsolate(const char* name_prefix,
                             const Dart_IsolateFlags& api_flags,
                             IsolateGroup* isolate_group) {
  // Create a new isolate.
  Isolate* isolate =
      Isolate::InitIsolate(name_prefix, isolate_group, api_flags);
  return isolate;
}

static bool IsSnapshotCompatible(Snapshot::Kind vm_kind,
                                 Snapshot::Kind isolate_kind) {
  if (vm_kind == isolate_kind) return true;
  if (vm_kind == Snapshot::kFull && isolate_kind == Snapshot::kFullJIT)
    return true;
  return Snapshot::IsFull(isolate_kind);
}

RawError* Dart::InitializeIsolate(const uint8_t* snapshot_data,
                                  const uint8_t* snapshot_instructions,
                                  const uint8_t* shared_data,
                                  const uint8_t* shared_instructions,
                                  const uint8_t* kernel_buffer,
                                  intptr_t kernel_buffer_size,
                                  void* isolate_data) {
  // Initialize the new isolate.
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
#if defined(SUPPORT_TIMLINE)
  TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                            "InitializeIsolate");
  tds.SetNumArguments(1);
  tds.CopyArgument(0, "isolateName", I->name());
#endif
  ASSERT(I != NULL);
  StackZone zone(T);
  HandleScope handle_scope(T);
  ObjectStore::Init(I);

  Error& error = Error::Handle(T->zone());
  error = Object::Init(I, kernel_buffer, kernel_buffer_size);
  if (!error.IsNull()) {
    return error.raw();
  }
  if ((snapshot_data != NULL) && kernel_buffer == NULL) {
    // Read the snapshot and setup the initial state.
#if defined(SUPPORT_TIMELINE)
    TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                              "ReadIsolateSnapshot");
#endif
    // TODO(turnidge): Remove once length is not part of the snapshot.
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (snapshot == NULL) {
      const String& message = String::Handle(String::New("Invalid snapshot"));
      return ApiError::New(message);
    }
    if (!IsSnapshotCompatible(vm_snapshot_kind_, snapshot->kind())) {
      const String& message = String::Handle(String::NewFormatted(
          "Incompatible snapshot kinds: vm '%s', isolate '%s'",
          Snapshot::KindToCString(vm_snapshot_kind_),
          Snapshot::KindToCString(snapshot->kind())));
      return ApiError::New(message);
    }
    if (FLAG_trace_isolates) {
      OS::PrintErr("Size of isolate snapshot = %" Pd "\n", snapshot->length());
    }
    FullSnapshotReader reader(snapshot, snapshot_instructions, shared_data,
                              shared_instructions, T);
    const Error& error = Error::Handle(reader.ReadIsolateSnapshot());
    if (!error.IsNull()) {
      return error.raw();
    }

    ReversePcLookupCache::BuildAndAttachToIsolate(I);

#if defined(SUPPORT_TIMELINE)
    if (tds.enabled()) {
      tds.SetNumArguments(2);
      tds.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
      tds.FormatArgument(1, "heapSize", "%" Pd64,
                         I->heap()->UsedInWords(Heap::kOld) * kWordSize);
    }
#endif  // !defined(PRODUCT)
    if (FLAG_trace_isolates) {
      I->heap()->PrintSizes();
      MegamorphicCacheTable::PrintSizes(I);
    }
  } else {
    if ((vm_snapshot_kind_ != Snapshot::kNone) && kernel_buffer == NULL) {
      const String& message =
          String::Handle(String::New("Missing isolate snapshot"));
      return ApiError::New(message);
    }
  }

  Object::VerifyBuiltinVtables();
  DEBUG_ONLY(I->heap()->Verify(kForbidMarked));

#if defined(DART_PRECOMPILED_RUNTIME)
  // AOT: The megamorphic miss function and code come from the snapshot.
  ASSERT(I->object_store()->megamorphic_miss_code() != Code::null());
  ASSERT(I->object_store()->build_method_extractor_code() != Code::null());
#else
  // JIT: The megamorphic miss function and code come from the snapshot in JIT
  // app snapshot, otherwise create them.
  if (I->object_store()->megamorphic_miss_code() == Code::null()) {
    MegamorphicCacheTable::InitMissHandler(I);
  }
#if !defined(TARGET_ARCH_DBC) && !defined(TARGET_ARCH_IA32)
  if (I != Dart::vm_isolate()) {
    I->object_store()->set_build_method_extractor_code(
        Code::Handle(StubCode::GetBuildMethodExtractorStub(nullptr)));
  }
#endif
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  const Code& miss_code =
      Code::Handle(I->object_store()->megamorphic_miss_code());
  I->set_ic_miss_code(miss_code);

  if ((snapshot_data == NULL) || (kernel_buffer != NULL)) {
    const Error& error = Error::Handle(I->object_store()->PreallocateObjects());
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  I->heap()->InitGrowthControl();
  I->set_init_callback_data(isolate_data);
  Api::SetupAcquiredError(I);
  if (FLAG_print_class_table) {
    I->class_table()->Print();
  }
  ServiceIsolate::MaybeMakeServiceIsolate(I);

#if !defined(PRODUCT)
  if (!ServiceIsolate::IsServiceIsolate(I) &&
      !KernelIsolate::IsKernelIsolate(I)) {
    I->message_handler()->set_should_pause_on_start(
        FLAG_pause_isolates_on_start);
    I->message_handler()->set_should_pause_on_exit(FLAG_pause_isolates_on_exit);
  }
#endif  // !defined(PRODUCT)

  ServiceIsolate::SendIsolateStartupMessage();
#if !defined(PRODUCT)
  I->debugger()->NotifyIsolateCreated();
#endif

  // Create tag table.
  I->set_tag_table(GrowableObjectArray::Handle(GrowableObjectArray::New()));
  // Set up default UserTag.
  const UserTag& default_tag = UserTag::Handle(UserTag::DefaultTag());
  I->set_current_tag(default_tag);

  if (FLAG_keep_code) {
    I->set_deoptimized_code_array(
        GrowableObjectArray::Handle(GrowableObjectArray::New()));
  }
  return Error::null();
}

const char* Dart::FeaturesString(Isolate* isolate,
                                 bool is_vm_isolate,
                                 Snapshot::Kind kind) {
  TextBuffer buffer(64);

// Different fields are included for DEBUG/RELEASE/PRODUCT.
#if defined(DEBUG)
  buffer.AddString("debug");
#elif defined(PRODUCT)
  buffer.AddString("product");
#else
  buffer.AddString("release");
#endif

#define ADD_FLAG(name, value)                                                  \
  do {                                                                         \
    buffer.AddString(value ? (" " #name) : (" no-" #name));                    \
  } while (0);

#define ADD_ISOLATE_FLAG(name, isolate_flag, flag)                             \
  do {                                                                         \
    const bool value = (isolate != NULL) ? isolate->name() : flag;             \
    ADD_FLAG(#name, value);                                                    \
  } while (0);

  VM_GLOBAL_FLAG_LIST(ADD_FLAG);
  if (Snapshot::IncludesCode(kind)) {
    // enabling assertions affects deopt ids.
    ADD_ISOLATE_FLAG(asserts, enable_asserts, FLAG_enable_asserts);
    if (kind == Snapshot::kFullJIT) {
      ADD_ISOLATE_FLAG(use_field_guards, use_field_guards,
                       FLAG_use_field_guards);
      ADD_ISOLATE_FLAG(use_osr, use_osr, FLAG_use_osr);
    }
    buffer.AddString(FLAG_causal_async_stacks ? " causal_async_stacks"
                                              : " no-causal_async_stacks");

    buffer.AddString((FLAG_enable_interpreter || FLAG_use_bytecode_compiler)
                         ? " bytecode"
                         : " no-bytecode");

// Generated code must match the host architecture and ABI.
#if defined(TARGET_ARCH_ARM)
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
    buffer.AddString(" arm-ios");
#else
    buffer.AddString(" arm-eabi");
#endif
    buffer.AddString(TargetCPUFeatures::hardfp_supported() ? " hardfp"
                                                           : " softfp");
#elif defined(TARGET_ARCH_ARM64)
#if defined(TARGET_OS_FUCHSIA)
    // See signal handler cheat in Assembler::EnterFrame.
    buffer.AddString(" arm64-fuchsia");
#else
    buffer.AddString(" arm64-sysv");
#endif
#elif defined(TARGET_ARCH_IA32)
    buffer.AddString(" ia32");
#elif defined(TARGET_ARCH_X64)
#if defined(TARGET_OS_WINDOWS)
    buffer.AddString(" x64-win");
#else
    buffer.AddString(" x64-sysv");
#endif

#elif defined(TARGET_ARCH_DBC)
#if defined(ARCH_IS_32_BIT)
    buffer.AddString(" dbc32");
#elif defined(ARCH_IS_64_BIT)
    buffer.AddString(" dbc64");
#else
#error What word size?
#endif
#else
#error What architecture?
#endif
  }

  if (FLAG_precompiled_mode && FLAG_dwarf_stack_traces) {
    buffer.AddString(" dwarf-stack-traces");
  }
#undef ADD_ISOLATE_FLAG
#undef ADD_FLAG

  return buffer.Steal();
}

void Dart::RunShutdownCallback() {
  Thread* thread = Thread::Current();
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  Isolate* isolate = thread->isolate();
  void* isolate_group_data = isolate->group()->embedder_data();
  void* isolate_data = isolate->init_callback_data();
  Dart_IsolateShutdownCallback callback = Isolate::ShutdownCallback();
  if (callback != NULL) {
    TransitionVMToNative transition(thread);
    (callback)(isolate_group_data, isolate_data);
  }
}

void Dart::ShutdownIsolate(Isolate* isolate) {
  ASSERT(Isolate::Current() == NULL);
  // We need to enter the isolate in order to shut it down.
  bool result = Thread::EnterIsolate(isolate);
  ASSERT(result);
  ShutdownIsolate();
  // Since the isolate is shutdown and deleted, there is no need to
  // exit the isolate here.
  ASSERT(Isolate::Current() == NULL);
}

void Dart::ShutdownIsolate() {
  Isolate* isolate = Isolate::Current();
  isolate->Shutdown();
  if (KernelIsolate::IsKernelIsolate(isolate)) {
    KernelIsolate::SetKernelIsolate(NULL);
  }
  delete isolate;
}

int64_t Dart::UptimeMicros() {
  return OS::GetCurrentMonotonicMicros() - Dart::start_time_micros_;
}

uword Dart::AllocateReadOnlyHandle() {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(predefined_handles_ != NULL);
  return predefined_handles_->handles_.AllocateScopedHandle();
}

LocalHandle* Dart::AllocateReadOnlyApiHandle() {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(predefined_handles_ != NULL);
  return predefined_handles_->api_handles_.AllocateHandle();
}

bool Dart::IsReadOnlyHandle(uword address) {
  ASSERT(predefined_handles_ != NULL);
  return predefined_handles_->handles_.IsValidScopedHandle(address);
}

bool Dart::IsReadOnlyApiHandle(Dart_Handle handle) {
  ASSERT(predefined_handles_ != NULL);
  return predefined_handles_->api_handles_.IsValidHandle(handle);
}

}  // namespace dart
