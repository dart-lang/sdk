// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

#include "vm/code_observers.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/simulator.h"
#include "vm/snapshot.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/thread_pool.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DEFINE_FLAG(bool, heap_profile_initialize, false,
            "Writes a heap profile on isolate initialization.");
DECLARE_FLAG(bool, heap_trace);
DECLARE_FLAG(bool, print_bootstrap);
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


// TODO(turnidge): We should add a corresponding Dart::Cleanup.
const char* Dart::InitOnce(Dart_IsolateCreateCallback create,
                           Dart_IsolateInterruptCallback interrupt,
                           Dart_IsolateUnhandledExceptionCallback unhandled,
                           Dart_IsolateShutdownCallback shutdown,
                           Dart_FileOpenCallback file_open,
                           Dart_FileWriteCallback file_write,
                           Dart_FileCloseCallback file_close) {
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return "VM already initialized.";
  }
  Isolate::SetFileCallbacks(file_open, file_write, file_close);
  OS::InitOnce();
  VirtualMemory::InitOnce();
  Isolate::InitOnce();
  PortMap::InitOnce();
  FreeListElement::InitOnce();
  Api::InitOnce();
  CodeObservers::InitOnce();
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
    Heap::Init(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    Object::InitOnce();
    ArgumentsDescriptor::InitOnce();
    StubCode::InitOnce();
    Scanner::InitOnce();
    Symbols::InitOnce(vm_isolate_);
    Object::CreateInternalMetaData();
    CPUFeatures::InitOnce();
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Dart VM requires at least SSE2.
    if (!CPUFeatures::sse2_supported()) {
      return "SSE2 is required.";
    }
#endif
    PremarkingVisitor premarker(vm_isolate_);
    vm_isolate_->heap()->IterateOldObjects(&premarker);
    vm_isolate_->heap()->WriteProtect(true);
  }
  Isolate::SetCurrent(NULL);  // Unregister the VM isolate from this thread.
  Isolate::SetCreateCallback(create);
  Isolate::SetInterruptCallback(interrupt);
  Isolate::SetUnhandledExceptionCallback(unhandled);
  Isolate::SetShutdownCallback(shutdown);
  if (FLAG_heap_trace) {
    HeapTrace::InitOnce(file_open, file_write, file_close);
  }
  return NULL;
}


Isolate* Dart::CreateIsolate(const char* name_prefix) {
  // Create a new isolate.
  Isolate* isolate = Isolate::Init(name_prefix);
  ASSERT(isolate != NULL);
  return isolate;
}


static void PrintLibrarySources(Isolate* isolate) {
  const GrowableObjectArray& libs = GrowableObjectArray::Handle(
      isolate->object_store()->libraries());
  intptr_t lib_count = libs.Length();
  Library& lib = Library::Handle();
  Array& scripts = Array::Handle();
  Script& script = Script::Handle();
  String& url = String::Handle();
  String& source = String::Handle();
  for (int i = 0; i < lib_count; i++) {
    lib ^= libs.At(i);
    url = lib.url();
    OS::Print("Library %s:\n", url.ToCString());
    scripts = lib.LoadedScripts();
    intptr_t script_count = scripts.Length();
    for (intptr_t i = 0; i < script_count; i++) {
      script ^= scripts.At(i);
      url = script.url();
      source = script.Source();
      OS::Print("Source for %s:\n", url.ToCString());
      OS::Print("%s\n", source.ToCString());
    }
  }
}


RawError* Dart::InitializeIsolate(const uint8_t* snapshot_buffer, void* data) {
  // Initialize the new isolate.
  TIMERSCOPE(time_isolate_initialization);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  StackZone zone(isolate);
  HandleScope handle_scope(isolate);
  Heap::Init(isolate);
  ObjectStore::Init(isolate);

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
    ASSERT(snapshot->kind() == Snapshot::kFull);
    if (FLAG_trace_isolates) {
      OS::Print("Size of isolate snapshot = %d\n", snapshot->length());
    }
    SnapshotReader reader(snapshot->content(), snapshot->length(),
                          Snapshot::kFull, isolate);
    reader.ReadFullSnapshot();
    if (FLAG_trace_isolates) {
      isolate->heap()->PrintSizes();
      isolate->megamorphic_cache_table()->PrintSizes();
    }
    if (FLAG_print_bootstrap) {
      PrintLibrarySources(isolate);
    }
  }

  if (FLAG_heap_profile_initialize) {
    isolate->heap()->ProfileToFile("initialize");
  }

  Object::VerifyBuiltinVtables();

  StubCode::Init(isolate);
  // TODO(regis): Reenable this code for arm and mips when possible.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
  isolate->megamorphic_cache_table()->InitMissHandler();
#endif
  if (FLAG_heap_trace) {
    isolate->heap()->trace()->Init(isolate);
  }
  isolate->heap()->EnableGrowthControl();
  isolate->set_init_callback_data(data);
  if (FLAG_print_class_table) {
    isolate->class_table()->Print();
  }
  return Error::null();
}


void Dart::ShutdownIsolate() {
  Isolate* isolate = Isolate::Current();
  void* callback_data = isolate->init_callback_data();
  isolate->Shutdown();
  delete isolate;

  Dart_IsolateShutdownCallback callback = Isolate::ShutdownCallback();
  if (callback != NULL) {
    (callback)(callback_data);
  }
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
