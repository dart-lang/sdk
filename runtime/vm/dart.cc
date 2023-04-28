// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/dart.h"

#include "vm/app_snapshot.h"
#include "vm/code_observers.h"
#include "vm/compiler/runtime_offsets_extracted.h"
#include "vm/compiler/runtime_offsets_list.h"
#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#if defined(DART_PRECOMPILED_RUNTIME) && defined(DART_TARGET_OS_LINUX)
#include "vm/elf.h"
#endif
#include "vm/flags.h"
#include "vm/handles.h"
#include "vm/heap/become.h"
#include "vm/heap/freelist.h"
#include "vm/heap/heap.h"
#include "vm/heap/pointer_block.h"
#include "vm/isolate.h"
#include "vm/isolate_reload.h"
#include "vm/kernel_isolate.h"
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
#include "vm/tags.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"
#include "vm/unwinding_records.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(bool, print_class_table);
DEFINE_FLAG(bool, trace_shutdown, false, "Trace VM shutdown on stderr");

Isolate* Dart::vm_isolate_ = nullptr;
int64_t Dart::start_time_micros_ = 0;
ThreadPool* Dart::thread_pool_ = nullptr;
DebugInfo* Dart::pprof_symbol_generator_ = nullptr;
ReadOnlyHandles* Dart::predefined_handles_ = nullptr;
Snapshot::Kind Dart::vm_snapshot_kind_ = Snapshot::kInvalid;
Dart_ThreadStartCallback Dart::thread_start_callback_ = nullptr;
Dart_ThreadExitCallback Dart::thread_exit_callback_ = nullptr;
Dart_FileOpenCallback Dart::file_open_callback_ = nullptr;
Dart_FileReadCallback Dart::file_read_callback_ = nullptr;
Dart_FileWriteCallback Dart::file_write_callback_ = nullptr;
Dart_FileCloseCallback Dart::file_close_callback_ = nullptr;
Dart_EntropySource Dart::entropy_source_callback_ = nullptr;
Dart_DwarfStackTraceFootnoteCallback Dart::dwarf_stacktrace_footnote_callback_ =
    nullptr;

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

class DartInitializationState : public AllStatic {
 public:
  static bool SetInitializing() {
    ASSERT(in_use_count_.load() == 0);
    uint8_t expected = kUnInitialized;
    return state_.compare_exchange_strong(expected, kInitializing);
  }

  static void ResetInitializing() {
    ASSERT(in_use_count_.load() == 0);
    uint8_t expected = kInitializing;
    bool result = state_.compare_exchange_strong(expected, kUnInitialized);
    ASSERT(result);
  }

  static void SetInitialized() {
    ASSERT(in_use_count_.load() == 0);
    uint8_t expected = kInitializing;
    bool result = state_.compare_exchange_strong(expected, kInitialized);
    ASSERT(result);
  }

  static bool IsInitialized() { return state_.load() == kInitialized; }

  static bool SetCleaningup() {
    uint8_t expected = kInitialized;
    return state_.compare_exchange_strong(expected, kCleaningup);
  }

  static void SetUnInitialized() {
    while (in_use_count_.load() > 0) {
      OS::Sleep(1);  // Sleep for 1 millis waiting for it to not be in use.
    }
    uint8_t expected = kCleaningup;
    bool result = state_.compare_exchange_strong(expected, kUnInitialized);
    ASSERT(result);
  }

  static bool SetInUse() {
    if (state_.load() != kInitialized) {
      return false;
    }
    in_use_count_ += 1;
    return true;
  }

  static void ResetInUse() {
    uint8_t value = state_.load();
    ASSERT((value == kInitialized) || (value == kCleaningup));
    in_use_count_ -= 1;
  }

 private:
  static constexpr uint8_t kUnInitialized = 0;
  static constexpr uint8_t kInitializing = 1;
  static constexpr uint8_t kInitialized = 2;
  static constexpr uint8_t kCleaningup = 3;

  static std::atomic<uint8_t> state_;
  static std::atomic<uint64_t> in_use_count_;
};
std::atomic<uint8_t> DartInitializationState::state_ = {kUnInitialized};
std::atomic<uint64_t> DartInitializationState::in_use_count_ = {0};

#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
static void CheckOffsets() {
#if !defined(IS_SIMARM_HOST64)
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

// No consistency checks needed for these constructs.
#define CHECK_ARRAY_SIZEOF(Class, Name, ElementOffset)
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
#if defined(DART_PRECOMPILER)
// Objects in precompiler may have extra fields only used during
// precompilation (such as Class::target_instance_size_in_words_),
// so size of objects in precompiler doesn't necessarily match
// size of objects at run time.
#define CHECK_SIZEOF(Class, Name, What)
#else
#define CHECK_SIZEOF(Class, Name, What)                                        \
  CHECK_OFFSET(sizeof(What), Class##_##Name);
#endif  // defined(DART_PRECOMPILER)
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
                      CHECK_ARRAY_SIZEOF, CHECK_PAYLOAD_SIZEOF, CHECK_RANGE,
                      CHECK_CONSTANT)

  NOT_IN_PRECOMPILED_RUNTIME(JIT_OFFSETS_LIST(
      CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF, CHECK_ARRAY_SIZEOF,
      CHECK_PAYLOAD_SIZEOF, CHECK_RANGE, CHECK_CONSTANT))

  ONLY_IN_PRECOMPILED(AOT_OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF,
                                       CHECK_ARRAY_SIZEOF, CHECK_PAYLOAD_SIZEOF,
                                       CHECK_RANGE, CHECK_CONSTANT))

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
#endif  // !defined(IS_SIMARM_HOST64)
}
#endif  // defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)

char* Dart::DartInit(const Dart_InitializeParams* params) {
#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
  CheckOffsets();
#elif defined(ARCH_IS_64_BIT) != defined(TARGET_ARCH_IS_64_BIT)
  return Utils::StrDup(
      "JIT cannot simulate target architecture with different word size than "
      "host");
#endif

#if defined(DART_HOST_OS_MACOS) && !defined(DART_HOST_OS_IOS)
  char* error = CheckIsAtLeastMinRequiredMacOSVersion();
  if (error != nullptr) {
    return error;
  }
#endif

  if (!Flags::Initialized()) {
    return Utils::StrDup("VM initialization failed-VM Flags not initialized.");
  }
  if (vm_isolate_ != nullptr) {
    return Utils::StrDup("VM initialization is in an inconsistent state.");
  }

  const Snapshot* snapshot = nullptr;
  if (params->vm_snapshot_data != nullptr) {
    snapshot = Snapshot::SetupFromBuffer(params->vm_snapshot_data);
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

  FrameLayout::Init();

  set_thread_start_callback(params->thread_start);
  set_thread_exit_callback(params->thread_exit);
  SetFileCallbacks(params->file_open, params->file_read, params->file_write,
                   params->file_close);
  set_entropy_source_callback(params->entropy_source);
  OS::Init();
  NOT_IN_PRODUCT(CodeObservers::Init());
  if (params->code_observer != nullptr) {
    NOT_IN_PRODUCT(CodeObservers::RegisterExternal(*params->code_observer));
  }
  start_time_micros_ = OS::GetCurrentMonotonicMicros();
  VirtualMemory::Init();

#if defined(DART_PRECOMPILED_RUNTIME) && defined(DART_TARGET_OS_LINUX)
  if (VirtualMemory::PageSize() > kElfPageSize) {
    return Utils::SCreate(
        "Incompatible page size for AOT compiled ELF: expected at most %" Pd
        ", got %" Pd "",
        kElfPageSize, VirtualMemory::PageSize());
  }
#endif

  OSThread::Init();
  Random::Init();
  Zone::Init();
#if defined(SUPPORT_TIMELINE)
  Timeline::Init();
  TimelineBeginEndScope tbes(Timeline::GetVMStream(), "Dart::Init");
#endif
  IsolateGroup::Init();
  Isolate::InitVM();
  UserTags::Init();
  PortMap::Init();
  Service::Init();
  FreeListElement::Init();
  ForwardingCorpse::Init();
  Api::Init();
  NativeSymbolResolver::Init();
  NOT_IN_PRODUCT(Profiler::Init());
  UnwindingRecords::Init();
  Page::Init();
  StoreBuffer::Init();
  MarkingStack::Init();
  TargetCPUFeatures::Init();

#if defined(USING_SIMULATOR)
  Simulator::Init();
#endif
  // Create the read-only handles area.
  ASSERT(predefined_handles_ == nullptr);
  predefined_handles_ = new ReadOnlyHandles();
  // Create the VM isolate and finish the VM initialization.
  ASSERT(thread_pool_ == nullptr);
  thread_pool_ = new ThreadPool();
  {
    ASSERT(vm_isolate_ == nullptr);
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
        kVmIsolateName, kVmIsolateName, params->vm_snapshot_data,
        params->vm_snapshot_instructions, nullptr, -1, api_flags));
    // ObjectStore should be created later, after null objects are initialized.
    auto group = new IsolateGroup(std::move(source), /*embedder_data=*/nullptr,
                                  /*object_store=*/nullptr, api_flags);
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
    ASSERT(T != nullptr);
    StackZone zone(T);
    HandleScope handle_scope(T);
    Object::InitNullAndBool(vm_isolate_->group());
    vm_isolate_->isolate_group_->set_object_store(new ObjectStore());
    vm_isolate_->isolate_object_store()->Init();
    vm_isolate_->finalizers_ = GrowableObjectArray::null();
    Object::Init(vm_isolate_->group());
    OffsetsTable::Init();
    ArgumentsDescriptor::Init();
    ICData::Init();
    SubtypeTestCache::Init();
    if (params->vm_snapshot_data != nullptr) {
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
        if (params->vm_snapshot_instructions == nullptr) {
          return Utils::StrDup("Missing instructions snapshot");
        }
      } else if (Snapshot::IsFull(vm_snapshot_kind_)) {
#if defined(DART_PRECOMPILED_RUNTIME)
        return Utils::StrDup(
            "Precompiled runtime requires a precompiled snapshot");
#else
        StubCode::Init();
        Object::FinishInit(vm_isolate_->group());
#endif
      } else {
        return Utils::StrDup("Invalid vm isolate snapshot seen");
      }
      FullSnapshotReader reader(snapshot, params->vm_snapshot_instructions, T);
      const Error& error = Error::Handle(reader.ReadVMSnapshot());
      if (!error.IsNull()) {
        // Must copy before leaving the zone.
        return Utils::StrDup(error.ToErrorCString());
      }

      Object::FinishInit(vm_isolate_->group());
#if defined(SUPPORT_TIMELINE)
      if (tbes.enabled()) {
        tbes.SetNumArguments(2);
        tbes.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
        tbes.FormatArgument(
            1, "heapSize", "%" Pd64,
            vm_isolate_group()->heap()->UsedInWords(Heap::kOld) * kWordSize);
      }
#endif  // !defined(PRODUCT)
      if (FLAG_trace_isolates) {
        OS::PrintErr("Size of vm isolate snapshot = %" Pd "\n",
                     snapshot->length());
        vm_isolate_group()->heap()->PrintSizes();
        MegamorphicCacheTable::PrintSizes(vm_isolate_);
        intptr_t size;
        intptr_t capacity;
        Symbols::GetStats(vm_isolate_->group(), &size, &capacity);
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
      Object::FinishInit(vm_isolate_->group());
      Symbols::Init(vm_isolate_->group());
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
      Object::FinalizeVMIsolate(vm_isolate_->group());
    }
#if defined(DEBUG)
    vm_isolate_group()->heap()->Verify("Dart::DartInit", kRequireMarked);
#endif
  }
  // Allocate the "persistent" scoped handles for the predefined API
  // values (such as Dart_True, Dart_False and Dart_Null).
  Api::InitHandles();

  Thread::ExitIsolate();  // Unregister the VM isolate from this thread.
  Isolate::SetCreateGroupCallback(params->create_group);
  Isolate::SetInitializeCallback_(params->initialize_isolate);
  Isolate::SetShutdownCallback(params->shutdown_isolate);
  Isolate::SetCleanupCallback(params->cleanup_isolate);
  Isolate::SetGroupCleanupCallback(params->cleanup_group);
  Isolate::SetRegisterKernelBlobCallback(params->register_kernel_blob);
  Isolate::SetUnregisterKernelBlobCallback(params->unregister_kernel_blob);

#ifndef PRODUCT
  const bool support_service = true;
  Service::SetGetServiceAssetsCallback(params->get_service_assets);
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
  if (params->start_kernel_isolate) {
    KernelIsolate::InitializeState();
  }
#endif  // DART_PRECOMPILED_RUNTIME

  return nullptr;
}

char* Dart::Init(const Dart_InitializeParams* params) {
  if (!DartInitializationState::SetInitializing()) {
    return Utils::StrDup(
        "Bad VM initialization state, "
        "already initialized or "
        "multiple threads initializing the VM.");
  }
  char* retval = DartInit(params);
  if (retval != nullptr) {
    DartInitializationState::ResetInitializing();
    return retval;
  }
  DartInitializationState::SetInitialized();
  return nullptr;
}

static void DumpAliveIsolates(intptr_t num_attempts,
                              bool only_application_isolates) {
  IsolateGroup::ForEach([&](IsolateGroup* group) {
    group->ForEachIsolate([&](Isolate* isolate) {
      if (!only_application_isolates || !Isolate::IsSystemIsolate(isolate)) {
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
  int64_t start_time = 0;
  if (FLAG_trace_shutdown) {
    start_time = UptimeMillis();
    OS::PrintErr("[+%" Pd64
                 "ms] SHUTDOWN: Waiting for service "
                 "and kernel isolates to shutdown\n",
                 start_time);
  }
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
      if (FLAG_trace_shutdown) {
        OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: %" Pd
                     " time out waiting for "
                     "service and kernel isolates to shutdown\n",
                     UptimeMillis(), num_attempts);
      }
    }
  }
  if (FLAG_trace_shutdown) {
    int64_t stop_time = UptimeMillis();
    OS::PrintErr("[+%" Pd64
                 "ms] SHUTDOWN: Done waiting for service "
                 "and kernel isolates to shutdown\n",
                 stop_time);
    if ((stop_time - start_time) > 500) {
      OS::PrintErr("[+%" Pd64
                   "ms] SHUTDOWN: waited too long for service "
                   "and kernel isolates to shutdown\n",
                   (stop_time - start_time));
    }
  }

  ASSERT(OnlyVmIsolateLeft());
}

char* Dart::Cleanup() {
  ASSERT(Isolate::Current() == nullptr);
  if (!DartInitializationState::SetCleaningup()) {
    return Utils::StrDup("VM already terminated.");
  }
  ASSERT(vm_isolate_ != nullptr);

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
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done shutting down app isolates\n",
                   UptimeMillis());
    }
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

  // Wait for the remaining isolate (service/kernel isolate) to shutdown
  // before shutting down the thread pool.
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
    Thread::ExitIsolate();
  }
#endif

  // Shutdown the thread pool. On return, all thread pool threads have exited.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleting thread pool\n",
                 UptimeMillis());
  }
  DartInitializationState::SetUnInitialized();
  thread_pool_->Shutdown();
  delete thread_pool_;
  thread_pool_ = nullptr;
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done deleting thread pool\n",
                 UptimeMillis());
  }

  Api::Cleanup();
  delete predefined_handles_;
  predefined_handles_ = nullptr;

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
  vm_isolate_ = nullptr;
  ASSERT(Isolate::IsolateListLength() == 0);
  Service::Cleanup();
  PortMap::Cleanup();
  UserTags::Cleanup();
  IsolateGroup::Cleanup();
  ICData::Cleanup();
  SubtypeTestCache::Cleanup();
  ArgumentsDescriptor::Cleanup();
  OffsetsTable::Cleanup();
  TargetCPUFeatures::Cleanup();
  MarkingStack::Cleanup();
  StoreBuffer::Cleanup();
  Object::Cleanup();
  Page::Cleanup();
  UnwindingRecords::Cleanup();
  StubCode::Cleanup();
#if defined(SUPPORT_TIMELINE)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down timeline\n",
                 UptimeMillis());
  }
  Timeline::Cleanup();
#endif
  Zone::Cleanup();
  Random::Cleanup();
  // Delete the current thread's TLS and set it's TLS to null.
  // If it is the last thread then the destructor would call
  // OSThread::Cleanup.
  OSThread* os_thread = OSThread::Current();
  OSThread::SetCurrent(nullptr);
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
  Flags::Cleanup();
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  IsolateGroupReloadContext::SetFileModifiedCallback(nullptr);
  Service::SetEmbedderStreamCallbacks(nullptr, nullptr);
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  VirtualMemory::Cleanup();
  return nullptr;
}

bool Dart::IsInitialized() {
  return DartInitializationState::IsInitialized();
}

bool Dart::SetActiveApiCall() {
  return DartInitializationState::SetInUse();
}

void Dart::ResetActiveApiCall() {
  DartInitializationState::ResetInUse();
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
  auto IG = I->group();
  if (kernel_buffer != nullptr) {
    SafepointReadRwLocker reader(T, IG->program_lock());
    I->field_table()->MarkReadyToUse();
  }

  Error& error = Error::Handle(T->zone());
  error = Object::Init(IG, kernel_buffer, kernel_buffer_size);
  if (!error.IsNull()) {
    return error.ptr();
  }
  if ((snapshot_data != nullptr) && kernel_buffer == nullptr) {
    // Read the snapshot and setup the initial state.
#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                               "ReadProgramSnapshot");
#endif  // defined(SUPPORT_TIMELINE)
    // TODO(turnidge): Remove once length is not part of the snapshot.
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (snapshot == nullptr) {
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
      return error.ptr();
    }

    T->SetupDartMutatorStateDependingOnSnapshot(I);
    {
      SafepointReadRwLocker reader(T, IG->program_lock());
      I->set_field_table(T, IG->initial_field_table()->Clone(I));
      I->field_table()->MarkReadyToUse();
    }

#if defined(SUPPORT_TIMELINE)
    if (tbes.enabled()) {
      tbes.SetNumArguments(2);
      tbes.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
      tbes.FormatArgument(1, "heapSize", "%" Pd64,
                          IG->heap()->UsedInWords(Heap::kOld) * kWordSize);
    }
#endif  // defined(SUPPORT_TIMELINE)
    if (FLAG_trace_isolates) {
      IG->heap()->PrintSizes();
      MegamorphicCacheTable::PrintSizes(I);
    }
  } else {
    if ((vm_snapshot_kind_ != Snapshot::kNone) && kernel_buffer == nullptr) {
      const String& message =
          String::Handle(String::New("Missing isolate snapshot"));
      return ApiError::New(message);
    }
  }
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  I->group()->class_table()->PopulateUserVisibleNames();
#endif

  return Error::null();
}

// The runtime assumes it can create certain kinds of objects at-will without
// a check whether their class need to be finalized first.
//
// Some of those objects can end up flowing to user code (i.e. their class is a
// subclass of [Instance]).
//
// We therefore ensure that classes are finalized before objects of them are
// created or at least before such objects can reach user code.
static void FinalizeBuiltinClasses(Thread* thread) {
  auto class_table = thread->isolate_group()->class_table();
  Class& cls = Class::Handle(thread->zone());

#define ENSURE_FINALIZED(clazz)                                                \
  if (class_table->HasValidClassAt(k##clazz##Cid)) {                           \
    cls = class_table->At(k##clazz##Cid);                                      \
    RELEASE_ASSERT(cls.EnsureIsFinalized(thread) == Object::null());           \
  }

  CLASS_LIST_INSTANCE_SINGLETONS(ENSURE_FINALIZED)
  CLASS_LIST_ARRAYS(ENSURE_FINALIZED)
  CLASS_LIST_STRINGS(ENSURE_FINALIZED)
  // No maps/sets.

#define ENSURE_TD_FINALIZED(clazz)                                             \
  ENSURE_FINALIZED(TypedData##clazz)                                           \
  ENSURE_FINALIZED(TypedData##clazz##View)                                     \
  ENSURE_FINALIZED(ExternalTypedData##clazz)                                   \
  ENSURE_FINALIZED(UnmodifiableTypedData##clazz##View)

  CLASS_LIST_TYPED_DATA(ENSURE_TD_FINALIZED)
#undef ENSURE_TD_FINALIZED

  ENSURE_FINALIZED(ByteDataView)
  ENSURE_FINALIZED(UnmodifiableByteDataView)
  ENSURE_FINALIZED(ByteBuffer)
}

ErrorPtr Dart::InitializeIsolate(const uint8_t* snapshot_data,
                                 const uint8_t* snapshot_instructions,
                                 const uint8_t* kernel_buffer,
                                 intptr_t kernel_buffer_size,
                                 IsolateGroup* source_isolate_group,
                                 void* isolate_data) {
  // Initialize the new isolate.
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  auto IG = T->isolate_group();
#if defined(SUPPORT_TIMELINE)
  TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                             "InitializeIsolate");
  tbes.SetNumArguments(1);
  tbes.CopyArgument(0, "isolateName", I->name());
#endif
  ASSERT(I != nullptr);
  StackZone zone(T);
  HandleScope handle_scope(T);
  bool was_child_cloned_into_existing_isolate = false;
  if (source_isolate_group != nullptr) {
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
      return error.ptr();
    }
  }

  Object::VerifyBuiltinVtables();
  if (T->isolate()->origin_id() == 0) {
    DEBUG_ONLY(IG->heap()->Verify("InitializeIsolate", kForbidMarked));
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  const bool kIsAotRuntime = true;
#else
  const bool kIsAotRuntime = false;
#endif

  if (kIsAotRuntime || was_child_cloned_into_existing_isolate) {
#if !defined(TARGET_ARCH_IA32)
    ASSERT(IG->object_store()->build_generic_method_extractor_code() !=
           Code::null());
    ASSERT(IG->object_store()->build_nongeneric_method_extractor_code() !=
           Code::null());
#endif
  } else {
    FinalizeBuiltinClasses(T);
#if !defined(TARGET_ARCH_IA32)
    if (I != Dart::vm_isolate()) {
      if (IG->object_store()->build_generic_method_extractor_code() !=
          nullptr) {
        SafepointWriteRwLocker ml(T, IG->program_lock());
        if (IG->object_store()->build_generic_method_extractor_code() !=
            nullptr) {
          IG->object_store()->set_build_generic_method_extractor_code(
              Code::Handle(
                  StubCode::GetBuildGenericMethodExtractorStub(nullptr)));
        }
      }
      if (IG->object_store()->build_nongeneric_method_extractor_code() !=
          nullptr) {
        SafepointWriteRwLocker ml(T, IG->program_lock());
        if (IG->object_store()->build_nongeneric_method_extractor_code() !=
            nullptr) {
          IG->object_store()->set_build_nongeneric_method_extractor_code(
              Code::Handle(
                  StubCode::GetBuildNonGenericMethodExtractorStub(nullptr)));
        }
      }
    }
#endif  // !defined(TARGET_ARCH_IA32)
  }

  I->set_ic_miss_code(StubCode::SwitchableCallMiss());

  Error& error = Error::Handle();
  if (snapshot_data == nullptr || kernel_buffer != nullptr) {
    error ^= IG->object_store()->PreallocateObjects();
    if (!error.IsNull()) {
      return error.ptr();
    }
  }
  const auto& out_of_memory =
      Object::Handle(IG->object_store()->out_of_memory());
  error ^= I->isolate_object_store()->PreallocateObjects(out_of_memory);
  if (!error.IsNull()) {
    return error.ptr();
  }

  I->set_init_callback_data(isolate_data);
  if (FLAG_print_class_table) {
    IG->class_table()->Print();
  }
#if !defined(PRODUCT)
  ServiceIsolate::MaybeMakeServiceIsolate(I);
  if (!Isolate::IsSystemIsolate(I)) {
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

  I->init_loaded_prefixes_set_storage();

  return Error::null();
}

char* Dart::FeaturesString(IsolateGroup* isolate_group,
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

#define ADD_ISOLATE_GROUP_FLAG(name, isolate_flag, flag)                       \
  do {                                                                         \
    const bool value =                                                         \
        isolate_group != nullptr ? isolate_group->name() : flag;               \
    ADD_FLAG(name, value);                                                     \
  } while (0);

  if (Snapshot::IncludesCode(kind)) {
    VM_GLOBAL_FLAG_LIST(ADD_P, ADD_R, ADD_C, ADD_D);

    // Enabling assertions affects deopt ids.
    ADD_ISOLATE_GROUP_FLAG(asserts, enable_asserts, FLAG_enable_asserts);
    if (kind == Snapshot::kFullJIT) {
      ADD_ISOLATE_GROUP_FLAG(use_field_guards, use_field_guards,
                             FLAG_use_field_guards);
      ADD_ISOLATE_GROUP_FLAG(use_osr, use_osr, FLAG_use_osr);
      ADD_ISOLATE_GROUP_FLAG(branch_coverage, branch_coverage,
                             FLAG_branch_coverage);
    }

    // Generated code must match the host architecture and ABI. We check the
    // strong condition of matching on operating system so that
    // Platform.isAndroid etc can be compile-time constants.
#if defined(TARGET_ARCH_IA32)
    buffer.AddString(" ia32");
#elif defined(TARGET_ARCH_X64)
    buffer.AddString(" x64");
#elif defined(TARGET_ARCH_ARM)
    buffer.AddString(" arm");
#elif defined(TARGET_ARCH_ARM64)
    buffer.AddString(" arm64");
#elif defined(TARGET_ARCH_RISCV32)
    buffer.AddString(" riscv32");
#elif defined(TARGET_ARCH_RISCV64)
    buffer.AddString(" riscv64");
#else
#error What architecture?
#endif

#if defined(DART_TARGET_OS_ANDROID)
    buffer.AddString(" android");
#elif defined(DART_TARGET_OS_FUCHSIA)
    buffer.AddString(" fuchsia");
#elif defined(DART_TARGET_OS_MACOS)
#if defined(DART_TARGET_OS_MACOS_IOS)
    buffer.AddString(" ios");
#else
    buffer.AddString(" macos");
#endif
#elif defined(DART_TARGET_OS_LINUX)
    buffer.AddString(" linux");
#elif defined(DART_TARGET_OS_WINDOWS)
    buffer.AddString(" windows");
#else
#error What operating system?
#endif

#if defined(DART_COMPRESSED_POINTERS)
    buffer.AddString(" compressed-pointers");
#else
    buffer.AddString(" no-compressed-pointers");
#endif
  }

  if (!Snapshot::IsAgnosticToNullSafety(kind)) {
    if (isolate_group != nullptr) {
      if (isolate_group->null_safety()) {
        buffer.AddString(" null-safety");
      } else {
        buffer.AddString(" no-null-safety");
      }
    } else {
      if (FLAG_sound_null_safety) {
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
  if (callback != nullptr) {
    TransitionVMToNative transition(thread);
    (callback)(isolate_group_data, isolate_data);
  }
}

void Dart::ShutdownIsolate(Isolate* isolate) {
  ASSERT(Isolate::Current() == nullptr);
  // We need to enter the isolate in order to shut it down.
  bool result = Thread::EnterIsolate(isolate);
  ASSERT(result);
  ShutdownIsolate();
  // Since the isolate is shutdown and deleted, there is no need to
  // exit the isolate here.
  ASSERT(Isolate::Current() == nullptr);
}

void Dart::ShutdownIsolate() {
  Isolate::Current()->Shutdown();
}

bool Dart::VmIsolateNameEquals(const char* name) {
  ASSERT(name != nullptr);
  return (strcmp(name, kVmIsolateName) == 0);
}

int64_t Dart::UptimeMicros() {
  return OS::GetCurrentMonotonicMicros() - Dart::start_time_micros_;
}

uword Dart::AllocateReadOnlyHandle() {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(predefined_handles_ != nullptr);
  return predefined_handles_->handles_.AllocateScopedHandle();
}

LocalHandle* Dart::AllocateReadOnlyApiHandle() {
  ASSERT(Isolate::Current() == Dart::vm_isolate());
  ASSERT(predefined_handles_ != nullptr);
  return predefined_handles_->api_handles_.AllocateHandle();
}

bool Dart::IsReadOnlyHandle(uword address) {
  ASSERT(predefined_handles_ != nullptr);
  return predefined_handles_->handles_.IsValidScopedHandle(address);
}

bool Dart::IsReadOnlyApiHandle(Dart_Handle handle) {
  ASSERT(predefined_handles_ != nullptr);
  return predefined_handles_->api_handles_.IsValidHandle(handle);
}

}  // namespace dart
