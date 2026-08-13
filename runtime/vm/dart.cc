// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/dart.h"

#include "platform/unwinding_records.h"

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
#include "vm/ffi_callback_metadata.h"
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
#include "vm/microtask_mirror_queues.h"
#include "vm/native_entry.h"
#include "vm/native_message_handler.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/raw_object_fields.h"
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
DEFINE_FLAG(bool,
            check_core_snapshot_match,
            false,
            "Also check core snapshot matches on OS and arch");

int64_t Dart::start_time_micros_ = 0;
ThreadPool* Dart::thread_pool_ = nullptr;
Dart_ThreadStartCallback Dart::thread_start_callback_ = nullptr;
Dart_ThreadExitCallback Dart::thread_exit_callback_ = nullptr;
Dart_FileOpenCallback Dart::file_open_callback_ = nullptr;
Dart_FileReadCallback Dart::file_read_callback_ = nullptr;
Dart_FileWriteCallback Dart::file_write_callback_ = nullptr;
Dart_FileCloseCallback Dart::file_close_callback_ = nullptr;
Dart_EntropySource Dart::entropy_source_callback_ = nullptr;
Dart_DwarfStackTraceFootnoteCallback Dart::dwarf_stacktrace_footnote_callback_ =
    nullptr;

class DartInitializationState : public AllStatic {
 public:
  static bool StartInit() {
    uword expected = PhaseField::encode(kUnInitialized) | CountField::encode(0);
    uword desired = PhaseField::encode(kInitializing) | CountField::encode(0);
    return state_.compare_exchange_strong(expected, desired,
                                          std::memory_order_acquire);
  }

  static void AbandonInit() {
    uword expected = PhaseField::encode(kInitializing) | CountField::encode(0);
    uword desired = PhaseField::encode(kUnInitialized) | CountField::encode(0);
    bool result = state_.compare_exchange_strong(expected, desired,
                                                 std::memory_order_release);
    ASSERT(result);
  }

  static void FinishInit() {
    uword expected = PhaseField::encode(kInitializing) | CountField::encode(0);
    uword desired = PhaseField::encode(kInitialized) | CountField::encode(0);
    bool result = state_.compare_exchange_strong(expected, desired,
                                                 std::memory_order_release);
    ASSERT(result);
  }

  static bool IsInitialized() {
    return PhaseField::decode(state_.load()) == kInitialized;
  }
  static bool IsShuttingDown() {
    return PhaseField::decode(state_.load()) == kCleaningup;
  }

  static bool StartCleanup() {
    uword expected = state_.load(std::memory_order_acquire);
    uword desired;
    do {
      if (PhaseField::decode(expected) != kInitialized) {
        return false;
      }
      desired = PhaseField::update(kCleaningup, expected);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_relaxed));

    while (CountField::decode(expected) != 0) {
      OS::Sleep(1);
      expected = state_.load(std::memory_order_acquire);
    }
    return true;
  }

  static void FinishCleanup() {
    uword expected = PhaseField::encode(kCleaningup) | CountField::encode(0);
    uword desired = PhaseField::encode(kUnInitialized) | CountField::encode(0);
    bool result = state_.compare_exchange_strong(expected, desired,
                                                 std::memory_order_release);
    ASSERT(result);
  }

  static bool SetInUse() {
    uword expected = state_.load(std::memory_order_relaxed);
    uword desired;
    do {
      if (PhaseField::decode(expected) != kInitialized) {
        return false;
      }
      desired = PhaseField::encode(kInitialized) |
                CountField::encode(CountField::decode(expected) + 1);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_relaxed));
    return true;
  }

  static void ResetInUse() {
    uword expected = state_.load(std::memory_order_relaxed);
    uword desired;
    do {
      ASSERT(PhaseField::decode(expected) == kInitialized ||
             PhaseField::decode(expected) == kCleaningup);
      desired = CountField::update(CountField::decode(expected) - 1, expected);
    } while (!state_.compare_exchange_weak(expected, desired,
                                           std::memory_order_release));
  }

 private:
  static constexpr uword kUnInitialized = 0;
  static constexpr uword kInitializing = 1;
  static constexpr uword kInitialized = 2;
  static constexpr uword kCleaningup = 3;

  using PhaseField = BitField<uword, uword, 0, 2>;
  using CountField =
      BitField<uword, uword, PhaseField::kNextBit, kBitsPerWord - 2>;

  static std::atomic<uword> state_;
};

std::atomic<uword> DartInitializationState::state_ = {
    PhaseField::encode(kUnInitialized) | CountField::encode(0)};

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
#define CHECK_ENUM(Name, Elements)

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
                   AOT_##Class##_##Getter[i - static_cast<intptr_t>(First)]);  \
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
      CHECK_OFFSET(Class::Getter(static_cast<Type>(i)),                        \
                   Class##_##Getter[i - static_cast<intptr_t>(First)]);        \
    }                                                                          \
  }
#define CHECK_CONSTANT(Class, Name) CHECK_OFFSET(Class::Name, Class##_##Name);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  COMMON_OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF,
                      CHECK_ARRAY_SIZEOF, CHECK_PAYLOAD_SIZEOF, CHECK_RANGE,
                      CHECK_CONSTANT, CHECK_ENUM)

  NOT_IN_PRECOMPILED_RUNTIME(JIT_OFFSETS_LIST(
      CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF, CHECK_ARRAY_SIZEOF,
      CHECK_PAYLOAD_SIZEOF, CHECK_RANGE, CHECK_CONSTANT, CHECK_ENUM))

  ONLY_IN_PRECOMPILED(AOT_OFFSETS_LIST(CHECK_FIELD, CHECK_ARRAY, CHECK_SIZEOF,
                                       CHECK_ARRAY_SIZEOF, CHECK_PAYLOAD_SIZEOF,
                                       CHECK_RANGE, CHECK_CONSTANT, CHECK_ENUM))

  if (!ok) {
    FATAL(
        "CheckOffsets failed. Try updating offsets by running "
        "./tools/run_offsets_extractor.dart");
  }
#undef CHECK_FIELD
#undef CHECK_ARRAY
#undef CHECK_ARRAY_STRUCTFIELD
#undef CHECK_SIZEOF
#undef CHECK_RANGE
#undef CHECK_CONSTANT
#undef CHECK_OFFSET
#undef CHECK_PAYLOAD_SIZEOF
#undef CHECK_ENUM
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
  char* error = CheckIsAtLeastMinRequiredMacOSXVersion();
  if (error != nullptr) {
    return error;
  }
#endif

  if (!Flags::Initialized()) {
    return Utils::StrDup("VM initialization failed-VM Flags not initialized.");
  }
  if (((FLAG_target_address_sanitizer ? 1 : 0) +
       (FLAG_target_memory_sanitizer ? 1 : 0) +
       (FLAG_target_thread_sanitizer ? 1 : 0)) > 1) {
    return Utils::StrDup("Can only target one sanitizer at a time");
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
  Zone::Init();
#if defined(SUPPORT_TIMELINE)
  Timeline::Init();
  TimelineBeginEndScope tbes(Timeline::GetVMStream(), "Dart::Init");
#endif
  IsolateGroup::Init();
  Isolate::InitVM();
  PortMap::Init();
  NativeMessageHandler::Init();
  Service::Init();
  FreeListElement::Init();
  ForwardingCorpse::Init();
  NativeSymbolResolver::Init();
  Page::Init();
  StoreBuffer::Init();
  MarkingStack::Init();
  TargetCPUFeatures::Init();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  // Dart VM requires at least SSE2.
  if (!TargetCPUFeatures::sse2_supported()) {
    return Utils::StrDup("SSE2 is required.");
  }
#endif

#if defined(DART_INCLUDE_SIMULATOR)
  Simulator::Init();
#endif
  Object::InitVtables();
  OffsetsTable::Init();
  ASSERT(thread_pool_ == nullptr);
  thread_pool_ = new ThreadPool();

#if defined(DART_INCLUDE_PROFILER)
  Profiler::Init();
#endif

  Isolate::SetCreateGroupCallback(params->create_group);
  Isolate::SetInitializeCallback_(params->initialize_isolate);
  Isolate::SetShutdownCallback(params->shutdown_isolate);
  Isolate::SetCleanupCallback(params->cleanup_isolate);
  Isolate::SetGroupCleanupCallback(params->cleanup_group);

  return nullptr;
}

char* Dart::Init(const Dart_InitializeParams* params) {
  if (!DartInitializationState::StartInit()) {
    return Utils::StrDup(
        "Bad VM initialization state, "
        "already initialized or "
        "multiple threads initializing the VM.");
  }
  char* retval = DartInit(params);
  if (retval != nullptr) {
    DartInitializationState::AbandonInit();
    return retval;
  }
  DartInitializationState::FinishInit();

  // The service and kernel isolates require the VM state to be initialized.
  // The embedder, not the VM, should trigger creation of the service and kernel
  // isolates. https://github.com/dart-lang/sdk/issues/33433
#if !defined(PRODUCT)
  ServiceIsolate::Run();
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (params->start_kernel_isolate) {
    KernelIsolate::InitializeState();
  }
#endif

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
  while (IsolateGroup::HasIsolateGroups() ||
         (Isolate::pending_shutdowns_ != 0)) {
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

  ASSERT(!IsolateGroup::HasIsolateGroups());
}

char* Dart::Cleanup() {
  ASSERT(Isolate::Current() == nullptr);
  // Wait for the service and kernel isolates to finish starting up
  // BEFORE we transition to kCleaningup. This ensures that their
  // asynchronous boot sequences (which may perform DNS lookups or
  // allocate native ports) can run to completion while the VM is
  // still in the kInitialized phase.
#if !defined(DART_PRECOMPILED_RUNTIME)
  KernelIsolate::WaitForKernelPort();
#endif
#if !defined(PRODUCT)
  ServiceIsolate::WaitForServiceIsolateStartup();
#endif

  if (!DartInitializationState::StartCleanup()) {
    return Utils::StrDup("VM already terminated.");
  }

  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Starting shutdown\n",
                 UptimeMillis());
  }

#if defined(DART_INCLUDE_PROFILER)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Stopping profiling\n",
                 UptimeMillis());
  }
  Profiler::SetConfig({.enabled = false});
#endif  // defined(DART_INCLUDE_PROFILER)

#if defined(SUPPORT_TIMELINE)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Stopping timeline streaming\n",
                 UptimeMillis());
  }
  Timeline::StopStreaming(/*reinitialize=*/false);
#endif

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

  // Wait for all isolates, but the service and the kernel isolate to shut down.
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

  Isolate::KillAllSystemIsolates(Isolate::kInternalKillMsg);

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

  // Shutdown the thread pool. On return, all thread pool threads have exited.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleting thread pool\n",
                 UptimeMillis());
  }

  NativeMessageHandler::Cleanup();
  PortMap::Shutdown();
  thread_pool_->Shutdown();
  delete thread_pool_;
  thread_pool_ = nullptr;
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done deleting thread pool\n",
                 UptimeMillis());
  }

#if defined(DART_INCLUDE_PROFILER)
  // Destroy profiler state.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Destroying profiler state\n",
                 UptimeMillis());
  }
  Profiler::Cleanup();
#endif  // defined(DART_INCLUDE_PROFILER)

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

  ASSERT(Isolate::IsolateListLength() == 0);
  Service::Cleanup();
  PortMap::Cleanup();
  IsolateGroup::Cleanup();
  OffsetsTable::Cleanup();
  TargetCPUFeatures::Cleanup();
  MarkingStack::Cleanup();
  StoreBuffer::Cleanup();
  Page::Cleanup();
#if defined(SUPPORT_TIMELINE)
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down timeline\n",
                 UptimeMillis());
  }
  Timeline::Cleanup();
#endif
  NOT_IN_PRODUCT(MicrotaskMirrorQueues::CleanUp());
  Zone::Cleanup();
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

  DartInitializationState::FinishCleanup();
  return nullptr;
}

bool Dart::IsInitialized() {
  return DartInitializationState::IsInitialized();
}

bool Dart::IsShuttingDown() {
  return DartInitializationState::IsShuttingDown();
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

char* Dart::InitIsolateGroupFromSnapshot(Thread* T,
                                         const uint8_t* snapshot_data,
                                         const uint8_t* snapshot_text,
                                         const uint8_t* kernel_buffer,
                                         intptr_t kernel_buffer_size) {
  auto IG = T->isolate_group();
  Error& error = Error::Handle(T->zone());
  error = Object::Init(IG, kernel_buffer, kernel_buffer_size);
  if (!error.IsNull()) {
    return Utils::StrDup(error.ToCString());
  }
  if (snapshot_data != nullptr && kernel_buffer == nullptr) {
    // Read the snapshot and setup the initial state.
#if defined(SUPPORT_TIMELINE)
    TimelineBeginEndScope tbes(T, Timeline::GetIsolateStream(),
                               "ReadProgramSnapshot");
#endif  // defined(SUPPORT_TIMELINE)
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    if (snapshot == nullptr) {
      return Utils::StrDup("Invalid snapshot");
    }
#if defined(DART_PRECOMPILED_RUNTIME)
    if (snapshot->kind() != Snapshot::kFullAOT) {
      return Utils::StrDup("AOT runtime cannot run a JIT snapshot");
    }
#else
    if (snapshot->kind() == Snapshot::kFullAOT) {
      return Utils::StrDup("JIT runtime cannot run an AOT snapshot");
    }
#endif
    if (FLAG_trace_isolates) {
      OS::PrintErr("Size of isolate snapshot = %" Pd "\n", snapshot->length());
    }
    FullSnapshotReader reader(snapshot, snapshot_text, T);
    char* error = reader.ReadProgramSnapshot();
    if (error != nullptr) {
      return error;
    }
    {
      // Initialize sentinel field table, which should have sentinel values for
      // all fields.
      auto len = IG->initial_field_table()->Capacity();
      IG->sentinel_field_table()->AllocateIndex(len);
      for (intptr_t i = 0; i < len; i++) {
        IG->sentinel_field_table()->SetAt(i, Object::sentinel().ptr());
      }
    }

    T->SetupDartMutatorStateDependingOnSnapshot(IG);

#if defined(SUPPORT_TIMELINE)
    if (tbes.enabled()) {
      tbes.SetNumArguments(2);
      tbes.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
      tbes.FormatArgument(1, "heapSize", "%" Pd,
                          IG->heap()->UsedInWords(Heap::kOld) * kWordSize);
    }
#endif  // defined(SUPPORT_TIMELINE)
    if (FLAG_trace_isolates) {
      IG->heap()->PrintSizes();
      MegamorphicCacheTable::PrintSizes(T);
    }
  } else {
    if (kernel_buffer == nullptr) {
      return Utils::StrDup("Missing isolate snapshot");
    }
  }
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_SAMPLING_HEAP_PROFILER)
  IG->class_table()->PopulateUserVisibleNames();
#endif

  return nullptr;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
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
  for (intptr_t cid = kInstanceCid; cid < kNumPredefinedCids; cid++) {
    if (class_table->HasValidClassAt(cid)) {
      cls = class_table->At(cid);
      RELEASE_ASSERT(cls.EnsureIsFinalized(thread) == Object::null());
    }
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

char* Dart::InitializeIsolateGroup(Thread* T,
                                   const uint8_t* snapshot_data,
                                   const uint8_t* snapshot_text,
                                   const uint8_t* kernel_buffer,
                                   intptr_t kernel_buffer_size) {
  // TODO(bootstrap-only-in-gen-snapshot)
  bool skip_bootstrap = false;
  if (snapshot_data != nullptr && kernel_buffer == nullptr) {
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_data);
    skip_bootstrap = snapshot->kind() == Snapshot::kFullAOT ||
                     snapshot->kind() == Snapshot::kFullJIT;
    char* error =
        SnapshotHeaderReader::InitializeIsolateGroupFlagsFromSnapshot(snapshot);
    if (error != nullptr) {
      return error;
    }
  }

  {
    StackZone zone(T);
    IsolateGroup* IG = T->isolate_group();
    Object::InitNullAndBool(IG);

    // Fix fields that were initialized with Object::null() before it pointed to
    // the null objects and so currently have Smi 0.
    T->isolate()->FixInitiallyNullFields();
    T->FixInitiallyNullFields();

    IG->set_object_store(new ObjectStore());
    if (!skip_bootstrap) {
#if defined(DART_PRECOMPILED_RUNTIME)
      UNREACHABLE();
#else
      Object::Init(IG);
      ArgumentsDescriptor::Init();
      ICData::Init();
      StubCode::Init();
      T->InitVMConstants();
      Symbols::Init(IG);
      Object::FinishInit(IG);
      Api::InitHandles();
#endif
    }
  }

  char* error = InitIsolateGroupFromSnapshot(T, snapshot_data, snapshot_text,
                                             kernel_buffer, kernel_buffer_size);
  if (error != nullptr) {
    return error;
  }
  T->isolate_group()->set_bootstrapping(false);

  Object::VerifyBuiltinVtables();

  auto IG = T->isolate_group();
  {
    SafepointReadRwLocker reader(T, IG->program_lock());
    IG->set_shared_field_table(T, IG->shared_initial_field_table()->Clone(
                                      /*for_isolate=*/nullptr,
                                      /*for_isolate_group=*/IG));
  }
  DEBUG_ONLY(IG->heap()->Verify("InitializeIsolate", kForbidMarked));

#if !defined(DART_PRECOMPILED_RUNTIME)
  FinalizeBuiltinClasses(T);
#endif

  if (snapshot_data == nullptr || kernel_buffer != nullptr) {
    auto object_store = IG->object_store();
    const Error& error = Error::Handle(object_store->PreallocateObjects());
    if (!error.IsNull()) {
      return Utils::StrDup(error.ToErrorCString());
    }
  }

  if (FLAG_print_class_table) {
    IG->class_table()->Print();
  }

  IG->object_store()->set_tag_table(
      GrowableObjectArray::Handle(GrowableObjectArray::New()));

  return nullptr;
}

ErrorPtr Dart::InitializeIsolate(Thread* T,
                                 bool is_first_isolate_in_group,
                                 void* isolate_data) {
  auto I = T->isolate();
  auto IG = T->isolate_group();
  auto Z = T->zone();

  // If a static field gets registered in [IsolateGroup::RegisterStaticField]:
  //
  //   * before this block it will ignore this isolate. The [Clone] of the
  //     initial field table will pick up the new value.
  //   * after this block it will add the new static field to this isolate.
  {
    SafepointReadRwLocker reader(T, IG->program_lock());
    I->set_field_table(T, IG->initial_field_table()->Clone(I));
    I->field_table()->MarkReadyToUse();
  }

  T->set_thread_locals(Object::empty_array());

  const auto& error =
      Error::Handle(Z, I->isolate_object_store()->PreallocateObjects());
  if (!error.IsNull()) {
    return error.ptr();
  }

  I->set_init_callback_data(isolate_data);

#if !defined(PRODUCT)
  if (Isolate::IsSystemIsolate(I)) {
    ServiceIsolate::MaybeMakeServiceIsolate(I);
  } else {
    I->message_handler()->set_should_pause_on_start(
        FLAG_pause_isolates_on_start);
    I->message_handler()->set_should_pause_on_exit(FLAG_pause_isolates_on_exit);
  }
#endif  // !defined(PRODUCT)

  ServiceIsolate::SendIsolateStartupMessage();
#if !defined(PRODUCT)
  I->debugger()->NotifyIsolateCreated();
#endif

  if (is_first_isolate_in_group) {
    // IsolateGroup tag_table was not available when isolate was first
    // created, but now it is.
    ASSERT(T->current_tag() == UserTag::null());
    const UserTag& default_tag = UserTag::Handle(UserTag::DefaultTag(T));
    T->set_current_tag(default_tag);
  }

  I->init_loaded_prefixes_set_storage();

  return Error::null();
}

char* Dart::FeaturesString(IsolateGroup* isolate_group, Snapshot::Kind kind) {
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
    ADD_FLAG(asan, FLAG_target_address_sanitizer)
    ADD_FLAG(msan, FLAG_target_memory_sanitizer)
    ADD_FLAG(tsan, FLAG_target_thread_sanitizer)
    ADD_FLAG(shared_data, FLAG_experimental_shared_data)

    if (kind == Snapshot::kFullJIT) {
      // Enabling assertions affects deopt ids.
      //
      // This flag is only used at compile time for AOT, so it's only relevant
      // when running JIT snapshots. We can omit this flag for AOT snapshots so
      // feature verification won't fail if --enable-snapshots isn't provided
      // at runtime.
      ADD_ISOLATE_GROUP_FLAG(asserts, enable_asserts, FLAG_enable_asserts);
      ADD_ISOLATE_GROUP_FLAG(use_field_guards, use_field_guards,
                             FLAG_use_field_guards);
      ADD_ISOLATE_GROUP_FLAG(use_osr, use_osr, FLAG_use_osr);
      ADD_ISOLATE_GROUP_FLAG(branch_coverage, branch_coverage,
                             FLAG_branch_coverage);
      ADD_ISOLATE_GROUP_FLAG(coverage, coverage, FLAG_coverage);
    }
    ADD_ISOLATE_GROUP_FLAG(code_comments, code_comments, FLAG_code_comments);
    ADD_ISOLATE_GROUP_FLAG(dwarf_stack_traces, dwarf_stack_traces,
                           FLAG_dwarf_stack_traces_mode);
  }

  if (Snapshot::IncludesCode(kind) || FLAG_check_core_snapshot_match) {
    // Generated code must match the host architecture and ABI. We check the
    // strong condition of matching on operating system so that
    // Platform.isAndroid etc can be compile-time constants.
#if defined(TARGET_ARCH_IA32)
    buffer.AddString(" ia32");
#elif defined(TARGET_ARCH_X64)
    buffer.AddString(" x64");
#elif defined(TARGET_ARCH_ARM)
    buffer.AddString(" arm");
#elif defined(TARGET_ARCH_ARM64E)
    buffer.AddString(" arm64e");
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

void Dart::ShutdownIsolate(Thread* T) {
  T->isolate()->Shutdown();
}

int64_t Dart::UptimeMicros() {
  return OS::GetCurrentMonotonicMicros() - Dart::start_time_micros_;
}

}  // namespace dart
