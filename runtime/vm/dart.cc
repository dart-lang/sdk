// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

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
#include "vm/metrics.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/object_id_ring.h"
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
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, trace_isolates);
DECLARE_FLAG(bool, trace_time_all);
DEFINE_FLAG(bool, keep_code, false,
            "Keep deoptimized code for profiling.");
DEFINE_FLAG(bool, shutdown, false, "Do a clean shutdown of the VM");

Isolate* Dart::vm_isolate_ = NULL;
ThreadPool* Dart::thread_pool_ = NULL;
DebugInfo* Dart::pprof_symbol_generator_ = NULL;
ReadOnlyHandles* Dart::predefined_handles_ = NULL;
const uint8_t* Dart::instructions_snapshot_buffer_ = NULL;

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
  ReadOnlyHandles() { }

 private:
  VMHandles handles_;
  LocalHandles api_handles_;

  friend class Dart;
  DISALLOW_COPY_AND_ASSIGN(ReadOnlyHandles);
};


const char* Dart::InitOnce(const uint8_t* vm_isolate_snapshot,
                           const uint8_t* instructions_snapshot,
                           Dart_IsolateCreateCallback create,
                           Dart_IsolateInterruptCallback interrupt,
                           Dart_IsolateUnhandledExceptionCallback unhandled,
                           Dart_IsolateShutdownCallback shutdown,
                           Dart_FileOpenCallback file_open,
                           Dart_FileReadCallback file_read,
                           Dart_FileWriteCallback file_write,
                           Dart_FileCloseCallback file_close,
                           Dart_EntropySource entropy_source,
                           Dart_GetVMServiceAssetsArchive get_service_assets) {
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return "VM already initialized or flags not initialized.";
  }
  Isolate::SetFileCallbacks(file_open, file_read, file_write, file_close);
  Isolate::SetEntropySourceCallback(entropy_source);
  OS::InitOnce();
  VirtualMemory::InitOnce();
  Thread::InitOnceBeforeIsolate();
  Thread::EnsureInit();
  Timeline::InitOnce();
  TimelineDurationScope tds(Timeline::GetVMStream(),
                            "Dart::InitOnce");
  Isolate::InitOnce();
  PortMap::InitOnce();
  FreeListElement::InitOnce();
  Api::InitOnce();
  CodeObservers::InitOnce();
  ThreadInterrupter::InitOnce();
  Profiler::InitOnce();
  SemiSpace::InitOnce();
  Metric::InitOnce();
  StoreBuffer::InitOnce();
  MarkingStack::InitOnce();
  Thread::EnsureInit();

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
    Thread* T = Thread::Current();
    ASSERT(T != NULL);
    ASSERT(vm_isolate_ == NULL);
    ASSERT(Flags::Initialized());
    const bool is_vm_isolate = true;
    const bool precompiled = instructions_snapshot != NULL;

    // Setup default flags for the VM isolate.
    Isolate::Flags vm_flags;
    Dart_IsolateFlags api_flags;
    vm_flags.CopyTo(&api_flags);
    vm_isolate_ = Isolate::Init("vm-isolate", api_flags, is_vm_isolate);
    vm_isolate_->set_compilation_allowed(!precompiled);
    // Verify assumptions about executing in the VM isolate.
    ASSERT(vm_isolate_ == Isolate::Current());
    ASSERT(vm_isolate_ == Thread::Current()->isolate());

    StackZone zone(T);
    HandleScope handle_scope(T);
    Object::InitNull(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    TargetCPUFeatures::InitOnce();
    Object::InitOnce(vm_isolate_);
    ArgumentsDescriptor::InitOnce();
    ICData::InitOnce();
    // When precompiled the stub code is initialized from the snapshot.
    if (!precompiled) {
      StubCode::InitOnce();
    }
    if (vm_isolate_snapshot != NULL) {
      if (instructions_snapshot != NULL) {
        vm_isolate_->SetupInstructionsSnapshotPage(instructions_snapshot);
      }
      const Snapshot* snapshot = Snapshot::SetupFromBuffer(vm_isolate_snapshot);
      if (snapshot == NULL) {
        return "Invalid vm isolate snapshot seen.";
      }
      ASSERT(snapshot->kind() == Snapshot::kFull);
      VmIsolateSnapshotReader reader(snapshot->content(),
                                     snapshot->length(),
                                     instructions_snapshot,
                                     T);
      const Error& error = Error::Handle(reader.ReadVmIsolateSnapshot());
      if (!error.IsNull()) {
        return error.ToCString();
      }
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
      Symbols::InitOnce(vm_isolate_);
    }
    Thread::InitOnceAfterObjectAndStubCode();
    Scanner::InitOnce();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Dart VM requires at least SSE2.
    if (!TargetCPUFeatures::sse2_supported()) {
      return "SSE2 is required.";
    }
#endif
    Object::FinalizeVMIsolate(vm_isolate_);
#if defined(DEBUG)
    vm_isolate_->heap()->Verify(kRequireMarked);
#endif
  }
  // Allocate the "persistent" scoped handles for the predefined API
  // values (such as Dart_True, Dart_False and Dart_Null).
  Api::InitHandles();

  Thread::ExitIsolate();  // Unregister the VM isolate from this thread.
  Isolate::SetCreateCallback(create);
  Isolate::SetInterruptCallback(interrupt);
  Isolate::SetUnhandledExceptionCallback(unhandled);
  Isolate::SetShutdownCallback(shutdown);

  Service::SetGetServiceAssetsCallback(get_service_assets);
  ServiceIsolate::Run();

  return NULL;
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

  // Shut down profiling.
  Profiler::Shutdown();

  if (FLAG_shutdown) {
    // Disable the creation of new isolates.
    Isolate::DisableIsolateCreation();

    // Send the OOB Kill message to all remaining application isolates.
    Isolate::KillAllIsolates(Isolate::kInternalKillMsg);

    // Shutdown the service isolate.
    ServiceIsolate::Shutdown();

    // Wait for all application isolates and the service isolate to shutdown
    // before shutting down the thread pool.
    WaitForIsolateShutdown();

    // Shutdown the thread pool. On return, all thread pool threads have exited.
    delete thread_pool_;
    thread_pool_ = NULL;

    // Set the VM isolate as current isolate.
    Thread::EnsureInit();
    Thread::EnterIsolate(vm_isolate_);

    ShutdownIsolate();
    vm_isolate_ = NULL;
    ASSERT(Isolate::IsolateListLength() == 0);

    TargetCPUFeatures::Cleanup();
    StoreBuffer::ShutDown();

    Thread::Shutdown();
  } else {
    // Shutdown the service isolate.
    ServiceIsolate::Shutdown();
  }

  CodeObservers::DeleteAll();
  Timeline::Shutdown();
  Metric::Cleanup();

  return NULL;
}


Isolate* Dart::CreateIsolate(const char* name_prefix,
                             const Dart_IsolateFlags& api_flags) {
  // Create a new isolate.
  Isolate* isolate = Isolate::Init(name_prefix, api_flags);
  return isolate;
}


RawError* Dart::InitializeIsolate(const uint8_t* snapshot_buffer, void* data) {
  // Initialize the new isolate.
  Thread* T = Thread::Current();
  Isolate* I = T->isolate();
  TimelineDurationScope tds(T, I->GetIsolateStream(), "InitializeIsolate");
  tds.SetNumArguments(1);
  tds.CopyArgument(0, "isolateName", I->name());

  ASSERT(I != NULL);
  StackZone zone(T);
  HandleScope handle_scope(T);
  {
    TimelineDurationScope tds(T, I->GetIsolateStream(), "ObjectStore::Init");
    ObjectStore::Init(I);
  }

  const Error& error = Error::Handle(Object::Init(I));
  if (!error.IsNull()) {
    return error.raw();
  }
  if (snapshot_buffer != NULL) {
    // Read the snapshot and setup the initial state.
    TimelineDurationScope tds(
        T, I->GetIsolateStream(), "IsolateSnapshotReader");
    // TODO(turnidge): Remove once length is not part of the snapshot.
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_buffer);
    if (snapshot == NULL) {
      const String& message = String::Handle(
          String::New("Invalid snapshot."));
      return ApiError::New(message);
    }
    ASSERT(snapshot->kind() == Snapshot::kFull);
    if (FLAG_trace_isolates) {
      OS::Print("Size of isolate snapshot = %" Pd "\n", snapshot->length());
    }
    IsolateSnapshotReader reader(snapshot->content(),
                                 snapshot->length(),
                                 Dart::instructions_snapshot_buffer(),
                                 T);
    const Error& error = Error::Handle(reader.ReadFullSnapshot());
    if (!error.IsNull()) {
      return error.raw();
    }
    if (FLAG_trace_isolates) {
      I->heap()->PrintSizes();
      MegamorphicCacheTable::PrintSizes(I);
    }
  } else {
    // Populate the isolate's symbol table with all symbols from the
    // VM isolate. We do this so that when we generate a full snapshot
    // for the isolate we have a unified symbol table that we can then
    // read into the VM isolate.
    Symbols::AddPredefinedSymbolsToIsolate();
  }

  Object::VerifyBuiltinVtables();
#if defined(DEBUG)
  I->heap()->Verify(kForbidMarked);
#endif

  {
    TimelineDurationScope tds(T, I->GetIsolateStream(), "StubCode::Init");
    StubCode::Init(I);
  }

  // When running precompiled, the megamorphic miss function/code comes from the
  // snapshot.
  if (!Dart::IsRunningPrecompiledCode()) {
    MegamorphicCacheTable::InitMissHandler(I);
  }
  const Code& miss_code =
      Code::Handle(I->object_store()->megamorphic_miss_code());
  I->set_ic_miss_code(miss_code);

  if (snapshot_buffer == NULL) {
    if (!I->object_store()->PreallocateObjects()) {
      return I->object_store()->sticky_error();
    }
  }

  I->heap()->EnableGrowthControl();
  I->set_init_callback_data(data);
  Api::SetupAcquiredError(I);
  if (FLAG_print_class_table) {
    I->class_table()->Print();
  }

  ServiceIsolate::MaybeMakeServiceIsolate(I);

  ServiceIsolate::SendIsolateStartupMessage();
  I->debugger()->NotifyIsolateCreated();

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


void Dart::RunShutdownCallback() {
  Isolate* isolate = Isolate::Current();
  void* callback_data = isolate->init_callback_data();
  Dart_IsolateShutdownCallback callback = Isolate::ShutdownCallback();
  ServiceIsolate::SendIsolateShutdownMessage();
  if (callback != NULL) {
    (callback)(callback_data);
  }
}


void Dart::ShutdownIsolate(Isolate* isolate) {
  ASSERT(Isolate::Current() == NULL);
  // We need to enter the isolate in order to shut it down.
  Thread::EnterIsolate(isolate);
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
