// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

#include "vm/code_observers.h"
#include "vm/cpu.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
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
#include "vm/service.h"
#include "vm/simulator.h"
#include "vm/snapshot.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_interrupter.h"
#include "vm/thread_pool.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DEFINE_FLAG(int, new_gen_semi_max_size, (kWordSize <= 4) ? 16 : 32,
            "Max size of new gen semi space in MB");
DEFINE_FLAG(int, old_gen_heap_size, Heap::kHeapSizeInMB,
            "Max size of old gen heap size in MB,"
            "e.g: --old_gen_heap_size=1024 allows up to 1024MB old gen heap");

DECLARE_FLAG(bool, print_class_table);
DECLARE_FLAG(bool, trace_isolates);

Isolate* Dart::vm_isolate_ = NULL;
ThreadPool* Dart::thread_pool_ = NULL;
DebugInfo* Dart::pprof_symbol_generator_ = NULL;
ReadOnlyHandles* Dart::predefined_handles_ = NULL;

// An object visitor which will mark all visited objects. This is used to
// premark all objects in the vm_isolate_ heap.
class PremarkingVisitor : public ObjectVisitor {
 public:
  explicit PremarkingVisitor(Isolate* isolate) : ObjectVisitor(isolate) {}

  void VisitObject(RawObject* obj) {
    // RawInstruction objects are premarked on allocation.
    if (!obj->IsMarked()) {
      obj->SetMarkBit();
    }
  }
};


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

  friend class Dart;
  DISALLOW_COPY_AND_ASSIGN(ReadOnlyHandles);
};


const char* Dart::InitOnce(Dart_IsolateCreateCallback create,
                           Dart_IsolateInterruptCallback interrupt,
                           Dart_IsolateUnhandledExceptionCallback unhandled,
                           Dart_IsolateShutdownCallback shutdown,
                           Dart_FileOpenCallback file_open,
                           Dart_FileReadCallback file_read,
                           Dart_FileWriteCallback file_write,
                           Dart_FileCloseCallback file_close,
                           Dart_EntropySource entropy_source,
                           Dart_ServiceIsolateCreateCalback service_create) {
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return "VM already initialized.";
  }
  Isolate::SetFileCallbacks(file_open, file_read, file_write, file_close);
  Isolate::SetEntropySourceCallback(entropy_source);
  OS::InitOnce();
  VirtualMemory::InitOnce();
  Isolate::InitOnce();
  PortMap::InitOnce();
  FreeListElement::InitOnce();
  Api::InitOnce();
  CodeObservers::InitOnce();
  ThreadInterrupter::InitOnce();
  Profiler::InitOnce();
  SemiSpace::InitOnce();
  Metric::InitOnce();

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
    vm_isolate_ = Isolate::Init("vm-isolate");
    StackZone zone(vm_isolate_);
    HandleScope handle_scope(vm_isolate_);
    Heap::Init(vm_isolate_,
               0,  // New gen size 0; VM isolate should only allocate in old.
               FLAG_old_gen_heap_size * MBInWords);
    ObjectStore::Init(vm_isolate_);
    TargetCPUFeatures::InitOnce();
    Object::InitOnce();
    ArgumentsDescriptor::InitOnce();
    StubCode::InitOnce();
    Symbols::InitOnce(vm_isolate_);
    Scanner::InitOnce();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Dart VM requires at least SSE2.
    if (!TargetCPUFeatures::sse2_supported()) {
      return "SSE2 is required.";
    }
#endif
    PremarkingVisitor premarker(vm_isolate_);
    vm_isolate_->heap()->WriteProtect(false);
    ASSERT(vm_isolate_->heap()->UsedInWords(Heap::kNew) == 0);
    vm_isolate_->heap()->IterateOldObjects(&premarker);
    vm_isolate_->heap()->WriteProtect(true);
  }
  // There is a planned and known asymmetry here: We enter one scope for the VM
  // isolate so that we can allocate the "persistent" scoped handles for the
  // predefined API values (such as Dart_True, Dart_False and Dart_Null).
  Dart_EnterScope();
  Api::InitHandles();

  Isolate::SetCurrent(NULL);  // Unregister the VM isolate from this thread.
  Isolate::SetCreateCallback(create);
  Isolate::SetServiceCreateCallback(service_create);
  Isolate::SetInterruptCallback(interrupt);
  Isolate::SetUnhandledExceptionCallback(unhandled);
  Isolate::SetShutdownCallback(shutdown);
  return NULL;
}


const char* Dart::Cleanup() {
#if 0
  // Ideally we should shutdown the VM isolate here, but the thread pool
  // shutdown does not seem to ensure that all the threads have stopped
  // execution before it terminates, this results in racing isolates.
  if (vm_isolate_ == NULL) {
    return "VM already terminated.";
  }

  ASSERT(Isolate::Current() == NULL);

  delete thread_pool_;
  thread_pool_ = NULL;

  // Set the VM isolate as current isolate.
  Isolate::SetCurrent(vm_isolate_);

  // There is a planned and known asymmetry here: We exit one scope for the VM
  // isolate to account for the scope that was entered in Dart_InitOnce.
  Dart_ExitScope();

  ShutdownIsolate();
  vm_isolate_ = NULL;

  TargetCPUFeatures::Cleanup();
#endif

  Profiler::Shutdown();
  CodeObservers::DeleteAll();

  return NULL;
}


Isolate* Dart::CreateIsolate(const char* name_prefix) {
  // Create a new isolate.
  Isolate* isolate = Isolate::Init(name_prefix);
  ASSERT(isolate != NULL);
  return isolate;
}


RawError* Dart::InitializeIsolate(const uint8_t* snapshot_buffer, void* data) {
  // Initialize the new isolate.
  Isolate* isolate = Isolate::Current();
  TIMERSCOPE(isolate, time_isolate_initialization);
  ASSERT(isolate != NULL);
  StackZone zone(isolate);
  HandleScope handle_scope(isolate);
  Heap::Init(isolate,
             FLAG_new_gen_semi_max_size * MBInWords,
             FLAG_old_gen_heap_size * MBInWords);
  ObjectIdRing::Init(isolate);
  ObjectStore::Init(isolate);

  // Setup for profiling.
  Profiler::InitProfilingForIsolate(isolate);

  if (snapshot_buffer == NULL) {
    const Error& error = Error::Handle(Object::Init(isolate));
    if (!error.IsNull()) {
      return error.raw();
    }
  } else {
    // Initialize from snapshot (this should replicate the functionality
    // of Object::Init(..) in a regular isolate creation path.
    Object::InitFromSnapshot(isolate);

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
    SnapshotReader reader(snapshot->content(), snapshot->length(),
                          Snapshot::kFull, isolate);
    reader.ReadFullSnapshot();
    if (FLAG_trace_isolates) {
      isolate->heap()->PrintSizes();
      isolate->megamorphic_cache_table()->PrintSizes();
    }
  }

  Object::VerifyBuiltinVtables();

  StubCode::Init(isolate);
  if (snapshot_buffer == NULL) {
    if (!isolate->object_store()->PreallocateObjects()) {
      return isolate->object_store()->sticky_error();
    }
  }
  isolate->megamorphic_cache_table()->InitMissHandler();

  isolate->heap()->EnableGrowthControl();
  isolate->set_init_callback_data(data);
  Api::SetupAcquiredError(isolate);
  if (FLAG_print_class_table) {
    isolate->class_table()->Print();
  }


  Service::SendIsolateStartupMessage();
  // Create tag table.
  isolate->set_tag_table(
      GrowableObjectArray::Handle(GrowableObjectArray::New()));
  // Set up default UserTag.
  const UserTag& default_tag = UserTag::Handle(UserTag::DefaultTag());
  isolate->set_current_tag(default_tag);

  return Error::null();
}


void Dart::RunShutdownCallback() {
  Isolate* isolate = Isolate::Current();
  void* callback_data = isolate->init_callback_data();
  Dart_IsolateShutdownCallback callback = Isolate::ShutdownCallback();
  Service::SendIsolateShutdownMessage();
  if (callback != NULL) {
    (callback)(callback_data);
  }
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


bool Dart::IsReadOnlyHandle(uword address) {
  ASSERT(predefined_handles_ != NULL);
  return predefined_handles_->handles_.IsValidScopedHandle(address);
}

}  // namespace dart
