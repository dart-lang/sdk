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

#if defined(DART_PRECOMPILED_RUNTIME)
DEFINE_FLAG(bool, print_llvm_constant_pool, false, "Print LLVM constant pool");
#endif

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
Dart_GCEventCallback Dart::gc_event_callback_ = nullptr;

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

// No consistency checks needed for this construct.
#define CHECK_PAYLOAD_SIZEOF(Class, Name, HeaderSize)

#if defined(DART_PRECOMPILED_RUNTIME)
#define CHECK_FIELD(Class, Name)                                               \
  CHECK_OFFSET(Class::Name(), AOT_##Class##_##Name);
#define CHECK_ARRAY(Class, Name)                                               \
  CHECK_OFFSET(Class::ArrayTraits::elements_start_offset(),                    \
               AOT_##Class##_elements_start_offset);                           \
  CHECK_OFFSET(Class::ArrayTraits::kElementSize, AOT_##Class##_element_size)
#define CHECK_SIZEOF(Class, Name, What)                                        \
  CHECK_OFFSET(sizeof(What), AOT_##Class##_##Name);
#define CHECK_RANGE(Class, Getter, Type, First, Last, Filter)                  \
  for (intptr_t i = static_cast<intptr_t>(First);                              \
       i <= static_cast<intptr_t>(Last); i++) {                                \
    if (Filter(static_cast<Type>(i))) {                                        \
      CHECK_OFFSET(Class::Getter(static_cast<Type>(i)),                        \
                   AOT_##Class##_##Getter[i]);                                 \
    }                                                                          \
  }
#define CHECK_CONSTANT(Class, Name)                                            \
  CHECK_OFFSET(Class::Name, AOT_##Class##_##Name);
#else
#define CHECK_FIELD(Class, Name) CHECK_OFFSET(Class::Name(), Class##_##Name);
#define CHECK_ARRAY(Class, Name)                                               \
  CHECK_OFFSET(Class::ArrayTraits::elements_start_offset(),                    \
               Class##_elements_start_offset);                                 \
  CHECK_OFFSET(Class::ArrayTraits::kElementSize, Class##_element_size);
#define CHECK_SIZEOF(Class, Name, What)                                        \
  CHECK_OFFSET(sizeof(What), Class##_##Name);
#define CHECK_RANGE(Class, Getter, Type, First, Last, Filter)                  \
  for (intptr_t i = static_cast<intptr_t>(First);                              \
       i <= static_cast<intptr_t>(Last); i++) {                                \
    if (Filter(static_cast<Type>(i))) {                                        \
      CHECK_OFFSET(Class::Getter(static_cast<Type>(i)), Class##_##Getter[i]);  \
    }                                                                          \
  }
#define CHECK_CONSTANT(Class, Name) CHECK_OFFSET(Class::Name, Class##_##Name);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  COMMON_OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF,
                      CHECK_PAYLOAD_SIZEOF, CHECK_RANGE, CHECK_CONSTANT)

  NOT_IN_PRECOMPILED_RUNTIME(
      JIT_OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF,
                       CHECK_PAYLOAD_SIZEOF, CHECK_RANGE, CHECK_CONSTANT))

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
#undef CHECK_PAYLOAD_SIZEOF
#endif  // !defined(IS_SIMARM_X64)
}

char* Dart::Init(const uint8_t* vm_isolate_snapshot,
                 const uint8_t* instructions_snapshot,
                 Dart_IsolateGroupCreateCallback create_group,
                 Dart_InitializeIsolateCallback initialize_isolate,
                 Dart_IsolateShutdownCallback shutdown,
                 Dart_IsolateCleanupCallback cleanup,
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
    return Utils::StrDup("VM already initialized or flags not initialized.");
  }

  const Snapshot* snapshot = nullptr;
  if (vm_isolate_snapshot != nullptr) {
    snapshot = Snapshot::SetupFromBuffer(vm_isolate_snapshot);
    if (snapshot == nullptr) {
      return Utils::StrDup("Invalid vm isolate snapshot seen");
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
  if (FLAG_causal_async_stacks && FLAG_lazy_async_stacks) {
    return Utils::StrDup(
        "To use --lazy-async-stacks, please disable --causal-async-stacks!");
  }
  // TODO(cskau): Remove once flag deprecation has been completed.
  if (FLAG_causal_async_stacks) {
    return Utils::StrDup("--causal-async-stacks is deprecated!");
  }

  FrameLayout::Init();

  set_thread_exit_callback(thread_exit);
  SetFileCallbacks(file_open, file_read, file_write, file_close);
  set_entropy_source_callback(entropy_source);
  OS::Init();
  NOT_IN_PRODUCT(CodeObservers::Init());
  if (observer != nullptr) {
    NOT_IN_PRODUCT(CodeObservers::RegisterExternal(*observer));
  }
  start_time_micros_ = OS::GetCurrentMonotonicMicros();
  VirtualMemory::Init();
  OSThread::Init();
  Zone::Init();
#if defined(SUPPORT_TIMELINE)
  Timeline::Init();
  TimelineBeginEndScope tbes(Timeline::GetVMStream(), "Dart::Init");
#endif
  IsolateGroup::Init();
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
    api_flags.is_system_isolate = true;

    // We make a fake [IsolateGroupSource] here, since the "vm-isolate" is not
    // really an isolate itself - it acts more as a container for VM-global
    // objects.
    std::unique_ptr<IsolateGroupSource> source(new IsolateGroupSource(
        kVmIsolateName, kVmIsolateName, vm_isolate_snapshot,
        instructions_snapshot, nullptr, -1, api_flags));
    // ObjectStore should be created later, after null objects are initialized.
    auto group = new IsolateGroup(std::move(source), /*embedder_data=*/nullptr,
                                  /*object_store=*/nullptr);
    group->CreateHeap(/*is_vm_isolate=*/true,
                      /*is_service_or_kernel_isolate=*/false);
    IsolateGroup::RegisterIsolateGroup(group);
    vm_isolate_ =
        Isolate::InitIsolate(kVmIsolateName, group, api_flags, is_vm_isolate);
    group->set_initial_spawn_successful();

    // Verify assumptions about executing in the VM isolate.
    ASSERT(vm_isolate_ == Isolate::Current());
    ASSERT(vm_isolate_ == Thread::Current()->isolate());

    Thread* T = Thread::Current();
    ASSERT(T != NULL);
    StackZone zone(T);
    HandleScope handle_scope(T);
    Object::InitNullAndBool(vm_isolate_);
    vm_isolate_->set_object_store(new ObjectStore());
    vm_isolate_->isolate_object_store()->Init();
    vm_isolate_->isolate_group_->object_store_ =
        vm_isolate_->object_store_shared_ptr_;
    TargetCPUFeatures::Init();
    Object::Init(vm_isolate_);
    ArgumentsDescriptor::Init();
    ICData::Init();
    SubtypeTestCache::Init();
    if (vm_isolate_snapshot != NULL) {
#if defined(SUPPORT_TIMELINE)
      TimelineBeginEndScope tbes(Timeline::GetVMStream(), "ReadVMSnapshot");
#endif
      ASSERT(snapshot != nullptr);
      vm_snapshot_kind_ = snapshot->kind();

      if (Snapshot::IncludesCode(vm_snapshot_kind_)) {
        if (vm_snapshot_kind_ == Snapshot::kFullAOT) {
#if !defined(DART_PRECOMPILED_RUNTIME)
          return Utils::StrDup("JIT runtime cannot run a precompiled snapshot");
#endif
        }
        if (instructions_snapshot == NULL) {
          return Utils::StrDup("Missing instructions snapshot");
        }
      } else if (Snapshot::IsFull(vm_snapshot_kind_)) {
#if defined(DART_PRECOMPILED_RUNTIME)
        return Utils::StrDup(
            "Precompiled runtime requires a precompiled snapshot");
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
        return Utils::StrDup("Invalid vm isolate snapshot seen");
      }
      FullSnapshotReader reader(snapshot, instructions_snapshot, T);
      const Error& error = Error::Handle(reader.ReadVMSnapshot());
      if (!error.IsNull()) {
        // Must copy before leaving the zone.
        return Utils::StrDup(error.ToErrorCString());
      }

      Object::FinishInit(vm_isolate_);
#if defined(SUPPORT_TIMELINE)
      if (tbes.enabled()) {
        tbes.SetNumArguments(2);
        tbes.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
        tbes.FormatArgument(
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
      return Utils::StrDup(
          "Precompiled runtime requires a precompiled snapshot");
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
      return Utils::StrDup("SSE2 is required.");
    }
#endif
    {
#if defined(SUPPORT_TIMELINE)
      TimelineBeginEndScope tbes(Timeline::GetVMStream(), "FinalizeVMIsolate");
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

#ifndef PRODUCT
  const bool support_service = true;
  Service::SetGetServiceAssetsCallback(get_service_assets);
#else
  const bool support_service = false;
#endif

  const bool is_dart2_aot_precompiler =
      FLAG_precompiled_mode && !kDartPrecompiledRuntime;

  if (!is_dart2_aot_precompiler &&
      (support_service || !kDartPrecompiledRuntime)) {
    ServiceIsolate::Run();
  }

#ifndef DART_PRECOMPILED_RUNTIME
  if (start_kernel_isolate) {
    KernelIsolate::InitializeState();
  }
#endif  // DART_PRECOMPILED_RUNTIME

  return NULL;
}

static void DumpAliveIsolates(intptr_t num_attempts,
                              bool only_aplication_isolates) {
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) {
      if (!only_aplication_isolates || !Isolate::IsSystemIsolate(isolate)) {
        OS::PrintErr("Attempt:%" Pd " waiting for isolate %s to check in\n",
                     num_attempts, isolate->name());
      }
    });
  });
}

static bool OnlyVmIsolateLeft() {
  intptr_t count = 0;
  bool found_vm_isolate = false;
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) {
      count++;
      if (isolate == Dart::vm_isolate()) {
        found_vm_isolate = true;
      }
    });
  });
  return count == 1 && found_vm_isolate;
}

// This waits until only the VM, service and kernel isolates are in the list.
void Dart::WaitForApplicationIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolate_creation_monitor_);
  intptr_t num_attempts = 0;
  while (IsolateGroup::HasApplicationIsolateGroups()) {
    Monitor::WaitResult retval = ml.Wait(1000);
    if (retval == Monitor::kTimedOut) {
      num_attempts += 1;
      if (num_attempts > 10) {
        DumpAliveIsolates(num_attempts, /*only_application_isolates=*/true);
      }
    }
  }
}

// This waits until only the VM isolate remains in the list.
void Dart::WaitForIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolate_creation_monitor_);
  intptr_t num_attempts = 0;
  while (!IsolateGroup::HasOnlyVMIsolateGroup()) {
    Monitor::WaitResult retval = ml.Wait(1000);
    if (retval == Monitor::kTimedOut) {
      num_attempts += 1;
      if (num_attempts > 10) {
        DumpAliveIsolates(num_attempts, /*only_application_isolates=*/false);
      }
    }
  }

  ASSERT(OnlyVmIsolateLeft());
}

char* Dart::Cleanup() {
  ASSERT(Isolate::Current() == NULL);
  if (vm_isolate_ == NULL) {
    return Utils::StrDup("VM already terminated.");
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
  thread_pool_->Shutdown();
  delete thread_pool_;
  thread_pool_ = NULL;

  Api::Cleanup();
  delete predefined_handles_;
  predefined_handles_ = NULL;

  // Set the VM isolate as current isolate.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Cleaning up vm isolate\n",
                 UptimeMillis());
  }

  // If Dart_Cleanup() is called on a thread which hasn't invoked any Dart API
  // functions before, entering the "vm-isolate" will cause lazy creation of a
  // OSThread (which is attached to the current thread via TLS).
  //
  // If we run in PRODUCT mode this lazy creation of OSThread can happen here,
  // which is why disabling the OSThread creation has to come after entering the
  // "vm-isolate".
  const bool result = Thread::EnterIsolate(vm_isolate_);
  ASSERT(result);

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

  ShutdownIsolate();
  vm_isolate_ = NULL;
  ASSERT(Isolate::IsolateListLength() == 0);
  PortMap::Cleanup();
  IsolateGroup::Cleanup();
  ICData::Cleanup();
  SubtypeTestCache::Cleanup();
  ArgumentsDescriptor::Cleanup();
  TargetCPUFeatures::Cleanup();
  MarkingStack::Cleanup();
  StoreBuffer::Cleanup();
  Object::Cleanup();
  SemiSpace::Cleanup();
  StubCode::Cleanup();
#if defined(SUPPORT_TIMELINE)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down timeline\n",
                 UptimeMillis());
  }
  Timeline::Cleanup();
#endif
  Zone::Cleanup();
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
  OS::Cleanup();
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done\n", UptimeMillis());
  }
  MallocHooks::Cleanup();
  Flags::Cleanup();
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  IsolateGroupReloadContext::SetFileModifiedCallback(NULL);
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

ErrorPtr Dart::InitIsolateFromSnapshot(Thread* T,
                                       Isolate* I,
                                       const uint8_t* snapshot_data,
                                       const uint8_t* snapshot_instructions,
                                       const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_size) {
  if (kernel_buffer != nullptr) {
    SafepointReadRwLocker reader(T, I->group()->program_lock());
    I->field_table()->MarkReadyToUse();
  }

  Error& error = Error::Handle(T->zone());
  error = Object::Init(I, kernel_buffer, kernel_buffer_size);
  if (!error.IsNull()) {
    return error.raw();
  }
  if ((snapshot_data != NULL) && kernel_buffer == NULL) {
    // Read the snapshot and setup the initial state.
#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                               "ReadProgramSnapshot");
#endif  // defined(SUPPORT_TIMELINE)
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
    FullSnapshotReader reader(snapshot, snapshot_instructions, T);
    const Error& error = Error::Handle(reader.ReadProgramSnapshot());
    if (!error.IsNull()) {
      return error.raw();
    }

    {
      SafepointReadRwLocker reader(T, I->group()->program_lock());
      I->set_field_table(T, I->group()->initial_field_table()->Clone(I));
      I->field_table()->MarkReadyToUse();
    }

#if defined(SUPPORT_TIMELINE)
    if (tbes.enabled()) {
      tbes.SetNumArguments(2);
      tbes.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
      tbes.FormatArgument(1, "heapSize", "%" Pd64,
                          I->heap()->UsedInWords(Heap::kOld) * kWordSize);
    }
#endif  // defined(SUPPORT_TIMELINE)
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

  return Error::null();
}

bool Dart::DetectNullSafety(const char* script_uri,
                            const uint8_t* snapshot_data,
                            const uint8_t* snapshot_instructions,
                            const uint8_t* kernel_buffer,
                            intptr_t kernel_buffer_size,
                            const char* package_config,
                            const char* original_working_directory) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Before creating the isolate we first determine the null safety mode
  // in which the isolate needs to run based on one of these factors :
  // - if loading from source, based on opt-in status of the source
  // - if loading from a kernel file, based on the mode used when
  //   generating the kernel file
  // - if loading from an appJIT, based on the mode used
  //   when generating the snapshot.
  ASSERT(FLAG_sound_null_safety == kNullSafetyOptionUnspecified);

  // If snapshot is not a core snapshot we will figure out the mode by
  // sniffing the feature string in the snapshot.
  if (snapshot_data != nullptr) {
    // Read the snapshot and check for null safety option.
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (!Snapshot::IsAgnosticToNullSafety(snapshot->kind())) {
      return SnapshotHeaderReader::NullSafetyFromSnapshot(snapshot);
    }
  }

  // If kernel_buffer is specified, it could be a self contained
  // kernel file or the kernel file of the application,
  // figure out the null safety mode by sniffing the kernel file.
  if (kernel_buffer != nullptr) {
    const char* error = nullptr;
    std::unique_ptr<kernel::Program> program = kernel::Program::ReadFromBuffer(
        kernel_buffer, kernel_buffer_size, &error);
    if (program != nullptr) {
      return program->compilation_mode() == NNBDCompiledMode::kStrong;
    }
    return false;
  }

  // If we are loading from source, figure out the mode from the source.
  if (KernelIsolate::GetExperimentalFlag(ExperimentalFeature::non_nullable)) {
    return KernelIsolate::DetectNullSafety(script_uri, package_config,
                                           original_working_directory);
  }
  return false;
#else
  UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

#if defined(DART_PRECOMPILED_RUNTIME)
static void PrintLLVMConstantPool(Thread* T, Isolate* I) {
  StackZone printing_zone(T);
  HandleScope printing_scope(T);
  TextBuffer b(1000);
  const auto& constants =
      GrowableObjectArray::Handle(I->object_store()->llvm_constant_pool());
  if (constants.IsNull()) {
    b.AddString("No constant pool information in snapshot.\n\n");
  } else {
    auto const len = constants.Length();
    b.Printf("Constant pool contents (length %" Pd "):\n", len);
    auto& obj = Object::Handle();
    for (intptr_t i = 0; i < len; i++) {
      obj = constants.At(i);
      b.Printf("  %5" Pd ": ", i);
      if (obj.IsString()) {
        b.AddChar('"');
        b.AddEscapedString(obj.ToCString());
        b.AddChar('"');
      } else {
        b.AddString(obj.ToCString());
      }
      b.AddChar('\n');
    }
    b.AddString("End of constant pool.\n\n");
  }
  const auto& functions =
      GrowableObjectArray::Handle(I->object_store()->llvm_function_pool());
  if (functions.IsNull()) {
    b.AddString("No function pool information in snapshot.\n\n");
  } else {
    auto const len = functions.Length();
    b.Printf("Function pool contents (length %" Pd "):\n", len);
    auto& obj = Function::Handle();
    for (intptr_t i = 0; i < len; i++) {
      obj ^= functions.At(i);
      ASSERT(!obj.IsNull());
      b.Printf("  %5" Pd ": %s\n", i, obj.ToFullyQualifiedCString());
    }
    b.AddString("End of function pool.\n\n");
  }
  THR_Print("%s", b.buffer());
}
#endif

ErrorPtr Dart::InitializeIsolate(const uint8_t* snapshot_data,
                                 const uint8_t* snapshot_instructions,
                                 const uint8_t* kernel_buffer,
                                 intptr_t kernel_buffer_size,
                                 IsolateGroup* source_isolate_group,
                                 void* isolate_data) {
  // Initialize the new isolate.
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                             "InitializeIsolate");
  tbes.SetNumArguments(1);
  tbes.CopyArgument(0, "isolateName", I->name());
#endif
  ASSERT(I != NULL);
  StackZone zone(T);
  HandleScope handle_scope(T);
  bool was_child_cloned_into_existing_isolate = false;
  if (source_isolate_group != nullptr) {
    I->isolate_object_store()->Init();
    I->isolate_object_store()->PreallocateObjects();

    // If a static field gets registered in [IsolateGroup::RegisterStaticField]:
    //
    //   * before this block it will ignore this isolate. The [Clone] of the
    //     initial field table will pick up the new value.
    //   * after this block it will add the new static field to this isolate.
    {
      SafepointReadRwLocker reader(T, source_isolate_group->program_lock());
      I->set_field_table(T,
                         source_isolate_group->initial_field_table()->Clone(I));
      I->field_table()->MarkReadyToUse();
    }

    was_child_cloned_into_existing_isolate = true;
  } else {
    const Error& error = Error::Handle(
        InitIsolateFromSnapshot(T, I, snapshot_data, snapshot_instructions,
                                kernel_buffer, kernel_buffer_size));
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  Object::VerifyBuiltinVtables();
  DEBUG_ONLY(I->heap()->Verify(kForbidMarked));

#if defined(DART_PRECOMPILED_RUNTIME)
  const bool kIsAotRuntime = true;
#else
  const bool kIsAotRuntime = false;
#endif

  if (kIsAotRuntime || was_child_cloned_into_existing_isolate) {
#if !defined(TARGET_ARCH_IA32)
    ASSERT(I->object_store()->build_method_extractor_code() != Code::null());
#endif
#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_print_llvm_constant_pool) {
      PrintLLVMConstantPool(T, I);
    }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  } else {
#if !defined(TARGET_ARCH_IA32)
    if (I != Dart::vm_isolate()) {
      I->object_store()->set_build_method_extractor_code(
          Code::Handle(StubCode::GetBuildMethodExtractorStub(nullptr)));
    }
#endif  // !defined(TARGET_ARCH_IA32)
  }

  I->set_ic_miss_code(StubCode::SwitchableCallMiss());

  if ((snapshot_data == NULL) || (kernel_buffer != NULL)) {
    Error& error = Error::Handle();
    error ^= I->object_store()->PreallocateObjects();
    if (!error.IsNull()) {
      return error.raw();
    }
    error ^= I->isolate_object_store()->PreallocateObjects();
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  if (!was_child_cloned_into_existing_isolate) {
    I->heap()->InitGrowthControl();
  }
  I->set_init_callback_data(isolate_data);
  if (FLAG_print_class_table) {
    I->class_table()->Print();
  }
#if !defined(PRODUCT)
  ServiceIsolate::MaybeMakeServiceIsolate(I);
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
#define ADD_P(name, T, DV, C) ADD_FLAG(name, FLAG_##name)
#define ADD_R(name, PV, T, DV, C) ADD_FLAG(name, FLAG_##name)
#define ADD_C(name, PCV, PV, T, DV, C) ADD_FLAG(name, FLAG_##name)
#define ADD_D(name, T, DV, C) ADD_FLAG(name, FLAG_##name)

#define ADD_ISOLATE_FLAG(name, isolate_flag, flag)                             \
  do {                                                                         \
    const bool value = (isolate != NULL) ? isolate->name() : flag;             \
    ADD_FLAG(#name, value);                                                    \
  } while (0);

  if (Snapshot::IncludesCode(kind)) {
    VM_GLOBAL_FLAG_LIST(ADD_P, ADD_R, ADD_C, ADD_D);

    // enabling assertions affects deopt ids.
    ADD_ISOLATE_FLAG(asserts, enable_asserts, FLAG_enable_asserts);
    if (kind == Snapshot::kFullJIT) {
      ADD_ISOLATE_FLAG(use_field_guards, use_field_guards,
                       FLAG_use_field_guards);
      ADD_ISOLATE_FLAG(use_osr, use_osr, FLAG_use_osr);
    }
#if !defined(PRODUCT)
    buffer.AddString(FLAG_code_comments ? " code-comments"
                                        : " no-code-comments");
#endif

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

#else
#error What architecture?
#endif
  }

  if (!Snapshot::IsAgnosticToNullSafety(kind)) {
    if (isolate != NULL) {
      if (isolate->null_safety()) {
        buffer.AddString(" null-safety");
      } else {
        buffer.AddString(" no-null-safety");
      }
    } else {
      if (FLAG_sound_null_safety == kNullSafetyOptionStrong) {
        buffer.AddString(" null-safety");
      } else {
        buffer.AddString(" no-null-safety");
      }
    }
  }

#undef ADD_ISOLATE_FLAG
#undef ADD_D
#undef ADD_C
#undef ADD_R
#undef ADD_P
#undef ADD_FLAG

  return buffer.Steal();
}

void Dart::RunShutdownCallback() {
  Thread* thread = Thread::Current();
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  Isolate* isolate = thread->isolate();
  void* isolate_group_data = isolate->group()->embedder_data();
  void* isolate_data = isolate->init_callback_data();
  Dart_IsolateShutdownCallback callback = isolate->on_shutdown_callback();
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
  Isolate::Current()->Shutdown();
}

bool Dart::VmIsolateNameEquals(const char* name) {
  ASSERT(name != NULL);
  return (strcmp(name, kVmIsolateName) == 0);
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
