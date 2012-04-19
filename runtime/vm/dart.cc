// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/freelist.h"
#include "vm/handles.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/snapshot.h"
#include "vm/stub_code.h"
#include "vm/virtual_memory.h"
#include "vm/zone.h"

namespace dart {

DECLARE_FLAG(bool, trace_isolates);

Isolate* Dart::vm_isolate_ = NULL;
DebugInfo* Dart::pprof_symbol_generator_ = NULL;

bool Dart::InitOnce(Dart_IsolateCreateCallback create,
                    Dart_IsolateInterruptCallback interrupt) {
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL || !Flags::Initialized()) {
    return false;
  }
  OS::InitOnce();
  VirtualMemory::InitOnce();
  Isolate::InitOnce();
  PortMap::InitOnce();
  FreeListElement::InitOnce();
  Api::InitOnce();
  // Create the VM isolate and finish the VM initialization.
  {
    ASSERT(vm_isolate_ == NULL);
    ASSERT(Flags::Initialized());
    vm_isolate_ = Isolate::Init("vm-isolate");
    Zone zone(vm_isolate_);
    HandleScope handle_scope(vm_isolate_);
    Heap::Init(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    Object::InitOnce();
    StubCode::InitOnce();
    Scanner::InitOnce();
  }
  Isolate::SetCurrent(NULL);  // Unregister the VM isolate from this thread.
  Isolate::SetCreateCallback(create);
  Isolate::SetInterruptCallback(interrupt);
  return true;
}


Isolate* Dart::CreateIsolate(const char* name_prefix) {
  // Create a new isolate.
  Isolate* isolate = Isolate::Init(name_prefix);
  ASSERT(isolate != NULL);
  return isolate;
}


RawError* Dart::InitializeIsolate(const uint8_t* snapshot_buffer, void* data) {
  // Initialize the new isolate.
  TIMERSCOPE(time_isolate_initialization);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  Zone zone(isolate);
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
    const Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_buffer);
    if (FLAG_trace_isolates) {
      OS::Print("Size of isolate snapshot = %ld\n", snapshot->length());
    }
    SnapshotReader reader(snapshot, isolate);
    reader.ReadFullSnapshot();
  }

  StubCode::Init(isolate);
  isolate->set_init_callback_data(data);
  return Error::null();
}


void Dart::ShutdownIsolate() {
  Isolate* isolate = Isolate::Current();
  isolate->Shutdown();
  delete isolate;
}

}  // namespace dart
