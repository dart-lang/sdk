// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

#include "vm/become.h"
#include "vm/clustered_snapshot.h"
#include "vm/code_observers.h"
#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/kernel_isolate.h"
#include "vm/malloc_hooks.h"
#include "vm/message_handler.h"
#include "vm/metrics.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/service_isolate.h"
#include "vm/simulator.h"
#include "vm/snapshot.h"
#include "vm/store_buffer.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, trace_time_all);
DEFINE_FLAG(bool, keep_code, false, "Keep deoptimized code for profiling.");
DEFINE_FLAG(bool, trace_shutdown, false, "Trace VM shutdown on stderr");

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
#define CHECK_OFFSET(expr, offset)                                             \
  if ((expr) != (offset)) {                                                    \
    FATAL2("%s == %" Pd, #expr, (expr));                                       \
  }

#if defined(TARGET_ARCH_ARM)
  // These offsets are embedded in precompiled instructions. We need simarm
  // (compiler) and arm (runtime) to agree.
  CHECK_OFFSET(Thread::stack_limit_offset(), 4);
  CHECK_OFFSET(Thread::object_null_offset(), 48);
  CHECK_OFFSET(SingleTargetCache::upper_limit_offset(), 14);
  CHECK_OFFSET(Isolate::object_store_offset(), 28);
  NOT_IN_PRODUCT(CHECK_OFFSET(sizeof(ClassHeapStats), 120));
#endif
#if defined(TARGET_ARCH_ARM64)
  // These offsets are embedded in precompiled instructions. We need simarm64
  // (compiler) and arm64 (runtime) to agree.
  CHECK_OFFSET(Thread::stack_limit_offset(), 8);
  CHECK_OFFSET(Thread::object_null_offset(), 96);
  CHECK_OFFSET(SingleTargetCache::upper_limit_offset(), 26);
  CHECK_OFFSET(Isolate::object_store_offset(), 56);
  NOT_IN_PRODUCT(CHECK_OFFSET(sizeof(ClassHeapStats), 208));
#endif
#undef CHECK_OFFSET
}

char* Dart::InitOnce(const uint8_t* vm_isolate_snapshot,
                     const uint8_t* instructions_snapshot,
                     Dart_IsolateCreateCallback create,
                     Dart_IsolateShutdownCallback shutdown,
                     Dart_IsolateCleanupCallback cleanup,
                     Dart_ThreadExitCallback thread_exit,
                     Dart_FileOpenCallback file_open,
                     Dart_FileReadCallback file_read,
                     Dart_FileWriteCallback file_write,
                     Dart_FileCloseCallback file_close,
                     Dart_EntropySource entropy_source,
                     Dart_GetVMServiceAssetsArchive get_service_assets) {
  CheckOffsets();
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return strdup("VM already initialized or flags not initialized.");
  }
#if defined(DEBUG)
  // Turn on verify_gc_contains if any of the other GC verification flag
  // is turned on.
  if (FLAG_verify_before_gc || FLAG_verify_after_gc ||
      FLAG_verify_on_transition) {
    FLAG_verify_gc_contains = true;
  }
#endif
  set_thread_exit_callback(thread_exit);
  SetFileCallbacks(file_open, file_read, file_write, file_close);
  set_entropy_source_callback(entropy_source);
  OS::InitOnce();
  start_time_micros_ = OS::GetCurrentMonotonicMicros();
  VirtualMemory::InitOnce();
  OSThread::InitOnce();
  if (FLAG_support_timeline) {
    Timeline::InitOnce();
  }
  NOT_IN_PRODUCT(
      TimelineDurationScope tds(Timeline::GetVMStream(), "Dart::InitOnce"));
  Isolate::InitOnce();
  PortMap::InitOnce();
  FreeListElement::InitOnce();
  ForwardingCorpse::InitOnce();
  Api::InitOnce();
  NOT_IN_PRODUCT(CodeObservers::InitOnce());
  if (FLAG_profiler) {
    ThreadInterrupter::InitOnce();
    Profiler::InitOnce();
  }
  SemiSpace::InitOnce();
  Metric::InitOnce();
  StoreBuffer::InitOnce();
  MarkingStack::InitOnce();

#if defined(USING_SIMULATOR)
  Simulator::InitOnce();
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
    vm_isolate_ = Isolate::Init("vm-isolate", api_flags, is_vm_isolate);
    // Verify assumptions about executing in the VM isolate.
    ASSERT(vm_isolate_ == Isolate::Current());
    ASSERT(vm_isolate_ == Thread::Current()->isolate());

    Thread* T = Thread::Current();
    ASSERT(T != NULL);
    StackZone zone(T);
    HandleScope handle_scope(T);
    Object::InitNull(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    TargetCPUFeatures::InitOnce();
    Object::InitOnce(vm_isolate_);
    ArgumentsDescriptor::InitOnce();
    ICData::InitOnce();
    if (vm_isolate_snapshot != NULL) {
      NOT_IN_PRODUCT(TimelineDurationScope tds(Timeline::GetVMStream(),
                                               "VMIsolateSnapshot"));
      const Snapshot* snapshot = Snapshot::SetupFromBuffer(vm_isolate_snapshot);
      if (snapshot == NULL) {
        return strdup("Invalid vm isolate snapshot seen");
      }
      vm_snapshot_kind_ = snapshot->kind();

      if (Snapshot::IncludesCode(vm_snapshot_kind_)) {
        if (vm_snapshot_kind_ == Snapshot::kFullAOT) {
#if defined(DART_PRECOMPILED_RUNTIME)
          vm_isolate_->set_compilation_allowed(false);
          if (!FLAG_precompiled_runtime) {
            return strdup("Flag --precompilation was not specified");
          }
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
        StubCode::InitOnce();
        // MallocHooks can't be initialized until StubCode has been since stack
        // trace generation relies on stub methods that are generated in
        // StubCode::InitOnce().
        // TODO(bkonyi) Split initialization for stack trace collection from the
        // initialization for the actual malloc hooks to increase accuracy of
        // memory consumption statistics.
        MallocHooks::InitOnce();
#endif
      } else {
        return strdup("Invalid vm isolate snapshot seen");
      }
      FullSnapshotReader reader(snapshot, instructions_snapshot, T);
      const Error& error = Error::Handle(reader.ReadVMSnapshot());
      if (!error.IsNull()) {
        // Must copy before leaving the zone.
        return strdup(error.ToErrorCString());
      }
#if !defined(PRODUCT)
      if (tds.enabled()) {
        tds.SetNumArguments(2);
        tds.FormatArgument(0, "snapshotSize", "%" Pd, snapshot->length());
        tds.FormatArgument(
            1, "heapSize", "%" Pd64,
            vm_isolate_->heap()->UsedInWords(Heap::kOld) * kWordSize);
      }
#endif  // !defined(PRODUCT)
      if (FLAG_trace_isolates) {
        OS::Print("Size of vm isolate snapshot = %" Pd "\n",
                  snapshot->length());
        vm_isolate_->heap()->PrintSizes();
        MegamorphicCacheTable::PrintSizes(vm_isolate_);
        intptr_t size;
        intptr_t capacity;
        Symbols::GetStats(vm_isolate_, &size, &capacity);
        OS::Print("VM Isolate: Number of symbols : %" Pd "\n", size);
        OS::Print("VM Isolate: Symbol table capacity : %" Pd "\n", capacity);
      }
    } else {
#if defined(DART_PRECOMPILED_RUNTIME)
      return strdup("Precompiled runtime requires a precompiled snapshot");
#elif !defined(DART_NO_SNAPSHOT)
      return strdup("Missing vm isolate snapshot");
#else
      vm_snapshot_kind_ = Snapshot::kNone;
      StubCode::InitOnce();
      // MallocHooks can't be initialized until StubCode has been since stack
      // trace generation relies on stub methods that are generated in
      // StubCode::InitOnce().
      // TODO(bkonyi) Split initialization for stack trace collection from the
      // initialization for the actual malloc hooks to increase accuracy of
      // memory consumption statistics.
      MallocHooks::InitOnce();
      Symbols::InitOnce(vm_isolate_);
#endif
    }
    // We need to initialize the constants here for the vm isolate thread due to
    // bootstrapping issues.
    T->InitVMConstants();
    Scanner::InitOnce();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Dart VM requires at least SSE2.
    if (!TargetCPUFeatures::sse2_supported()) {
      return strdup("SSE2 is required.");
    }
#endif
    {
      NOT_IN_PRODUCT(TimelineDurationScope tds(Timeline::GetVMStream(),
                                               "FinalizeVMIsolate"));
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
  Isolate::SetCreateCallback(create);
  Isolate::SetShutdownCallback(shutdown);
  Isolate::SetCleanupCallback(cleanup);

  if (FLAG_support_service) {
    Service::SetGetServiceAssetsCallback(get_service_assets);
  }

  ServiceIsolate::Run();

#ifndef DART_PRECOMPILED_RUNTIME
  KernelIsolate::Run();
#endif  // DART_PRECOMPILED_RUNTIME

  return NULL;
}

// This waits until only the VM isolate and the service isolate remains in the
// list, i.e. list length == 2.
void Dart::WaitForApplicationIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolates_list_monitor_);
  while ((Isolate::isolates_list_head_ != NULL) &&
         (Isolate::isolates_list_head_->next_ != NULL) &&
         (Isolate::isolates_list_head_->next_->next_ != NULL)) {
    ml.Wait();
  }
  ASSERT(
      ((Isolate::isolates_list_head_ == Dart::vm_isolate()) &&
       ServiceIsolate::IsServiceIsolate(Isolate::isolates_list_head_->next_)) ||
      ((Isolate::isolates_list_head_->next_ == Dart::vm_isolate()) &&
       ServiceIsolate::IsServiceIsolate(Isolate::isolates_list_head_)));
}

// This waits until only the VM isolate remains in the list.
void Dart::WaitForIsolateShutdown() {
  ASSERT(!Isolate::creation_enabled_);
  MonitorLocker ml(Isolate::isolates_list_monitor_);
  while ((Isolate::isolates_list_head_ != NULL) &&
         (Isolate::isolates_list_head_->next_ != NULL)) {
    ml.Wait();
  }
  ASSERT(Isolate::isolates_list_head_ == Dart::vm_isolate());
}

const char* Dart::Cleanup() {
  ASSERT(Isolate::Current() == NULL);
  if (vm_isolate_ == NULL) {
    return "VM already terminated.";
  }

  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Starting shutdown\n",
                 UptimeMillis());
  }

  if (FLAG_profiler) {
    // Shut down profiling.
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down profiling\n",
                   UptimeMillis());
    }
    Profiler::Shutdown();
  }

  {
    // Set the VM isolate as current isolate when shutting down
    // Metrics so that we can use a StackZone.
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Entering vm isolate\n",
                   UptimeMillis());
    }
    bool result = Thread::EnterIsolate(vm_isolate_);
    ASSERT(result);
    Metric::Cleanup();
    Thread::ExitIsolate();
  }

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
  if (ServiceIsolate::IsRunning()) {
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down app isolates\n",
                   UptimeMillis());
    }
    WaitForApplicationIsolateShutdown();
  }

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

  // Shutdown the thread pool. On return, all thread pool threads have exited.
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Deleting thread pool\n",
                 UptimeMillis());
  }
  delete thread_pool_;
  thread_pool_ = NULL;

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

  TargetCPUFeatures::Cleanup();
  StoreBuffer::ShutDown();

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
  NOT_IN_PRODUCT(CodeObservers::DeleteAll());
  if (FLAG_support_timeline) {
    if (FLAG_trace_shutdown) {
      OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Shutting down timeline\n",
                   UptimeMillis());
    }
    Timeline::Shutdown();
  }
  if (FLAG_trace_shutdown) {
    OS::PrintErr("[+%" Pd64 "ms] SHUTDOWN: Done\n", UptimeMillis());
  }
  MallocHooks::TearDown();
  return NULL;
}

Isolate* Dart::CreateIsolate(const char* name_prefix,
                             const Dart_IsolateFlags& api_flags) {
  // Create a new isolate.
  Isolate* isolate = Isolate::Init(name_prefix, api_flags);
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
                                  intptr_t snapshot_length,
                                  kernel::Program* kernel_program,
                                  void* data) {
  // Initialize the new isolate.
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  NOT_IN_PRODUCT(TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                                           "InitializeIsolate");
                 tds.SetNumArguments(1);
                 tds.CopyArgument(0, "isolateName", I->name());)
  ASSERT(I != NULL);
  StackZone zone(T);
  HandleScope handle_scope(T);
  {
    NOT_IN_PRODUCT(TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                                             "ObjectStore::Init"));
    ObjectStore::Init(I);
  }

  Error& error = Error::Handle(T->zone());
  error = Object::Init(I, kernel_program);
  if (!error.IsNull()) {
    return error.raw();
  }
  if ((snapshot_data != NULL) && kernel_program == NULL) {
    // Read the snapshot and setup the initial state.
    NOT_IN_PRODUCT(TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                                             "IsolateSnapshotReader"));
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
      OS::Print("Size of isolate snapshot = %" Pd "\n", snapshot->length());
    }
    FullSnapshotReader reader(snapshot, snapshot_instructions, T);
    const Error& error = Error::Handle(reader.ReadIsolateSnapshot());
    if (!error.IsNull()) {
      return error.raw();
    }
#if !defined(PRODUCT)
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
    if ((vm_snapshot_kind_ != Snapshot::kNone) && kernel_program == NULL) {
      const String& message =
          String::Handle(String::New("Missing isolate snapshot"));
      return ApiError::New(message);
    }
  }

  Object::VerifyBuiltinVtables();
  DEBUG_ONLY(I->heap()->Verify(kForbidMarked));

  {
    NOT_IN_PRODUCT(TimelineDurationScope tds(T, Timeline::GetIsolateStream(),
                                             "StubCode::Init"));
    StubCode::Init(I);
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  // AOT: The megamorphic miss function and code come from the snapshot.
  ASSERT(I->object_store()->megamorphic_miss_code() != Code::null());
#else
  // JIT: The megamorphic miss function and code come from the snapshot in JIT
  // app snapshot, otherwise create them.
  if (I->object_store()->megamorphic_miss_code() == Code::null()) {
    MegamorphicCacheTable::InitMissHandler(I);
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  const Code& miss_code =
      Code::Handle(I->object_store()->megamorphic_miss_code());
  I->set_ic_miss_code(miss_code);

  if ((snapshot_data == NULL) || (kernel_program != NULL)) {
    const Error& error = Error::Handle(I->object_store()->PreallocateObjects());
    if (!error.IsNull()) {
      return error.raw();
    }
  }

  I->heap()->InitGrowthControl();
  I->set_init_callback_data(data);
  Api::SetupAcquiredError(I);
  if (FLAG_print_class_table) {
    I->class_table()->Print();
  }

  bool is_kernel_isolate = false;
#ifndef DART_PRECOMPILED_RUNTIME
  KernelIsolate::InitCallback(I);
  is_kernel_isolate = KernelIsolate::IsKernelIsolate(I);
#endif
  ServiceIsolate::MaybeMakeServiceIsolate(I);
  if (!ServiceIsolate::IsServiceIsolate(I) && !is_kernel_isolate) {
    I->message_handler()->set_should_pause_on_start(
        FLAG_pause_isolates_on_start);
    I->message_handler()->set_should_pause_on_exit(FLAG_pause_isolates_on_exit);
  }

  ServiceIsolate::SendIsolateStartupMessage();
  if (FLAG_support_debugger) {
    I->debugger()->NotifyIsolateCreated();
  }
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

const char* Dart::FeaturesString(Isolate* isolate, Snapshot::Kind kind) {
  TextBuffer buffer(64);

// Different fields are included for DEBUG/RELEASE/PRODUCT.
#if defined(DEBUG)
  buffer.AddString("debug");
#elif defined(PRODUCT)
  buffer.AddString("product");
#else
  buffer.AddString("release");
#endif

  if (Snapshot::IncludesCode(kind)) {
    if (FLAG_support_debugger) {
      buffer.AddString(" support-debugger");
    }

// Checked mode affects deopt ids.
#define ADD_FLAG(name, isolate_flag, flag)                                     \
  do {                                                                         \
    const bool name = (isolate != NULL) ? isolate->name() : flag;              \
    buffer.AddString(name ? (" " #name) : (" no-" #name));                     \
  } while (0);
    ADD_FLAG(type_checks, enable_type_checks, FLAG_enable_type_checks);
    ADD_FLAG(asserts, enable_asserts, FLAG_enable_asserts);
    ADD_FLAG(error_on_bad_type, enable_error_on_bad_type,
             FLAG_error_on_bad_type);
    ADD_FLAG(error_on_bad_override, enable_error_on_bad_override,
             FLAG_error_on_bad_override);
    if (kind == Snapshot::kFullJIT) {
      ADD_FLAG(use_field_guards, use_field_guards, FLAG_use_field_guards);
      ADD_FLAG(use_osr, use_osr, FLAG_use_osr);
    }
#undef ADD_FLAG

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
    buffer.AddString(" arm64");
#elif defined(TARGET_ARCH_IA32)
    buffer.AddString(" ia32");
#elif defined(TARGET_ARCH_X64)
#if defined(_WIN64)
    buffer.AddString(" x64-win");
#else
    buffer.AddString(" x64-sysv");
#endif
#elif defined(TARGET_ARCH_DBC)
    buffer.AddString(" dbc");
#elif defined(TARGET_ARCH_DBC64)
    buffer.AddString(" dbc64");
#endif
  }

  if (FLAG_precompiled_mode && FLAG_dwarf_stack_traces) {
    buffer.AddString(" dwarf-stack-traces");
  }

  return buffer.Steal();
}

void Dart::RunShutdownCallback() {
  Isolate* isolate = Isolate::Current();
  void* callback_data = isolate->init_callback_data();
  Dart_IsolateShutdownCallback callback = Isolate::ShutdownCallback();
  if (callback != NULL) {
    (callback)(callback_data);
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
