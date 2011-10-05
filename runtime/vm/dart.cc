// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart.h"

#include "vm/code_index_table.h"
#include "vm/flags.h"
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

Isolate* Dart::vm_isolate_ = NULL;
DebugInfo* Dart::pprof_symbol_generator_ = NULL;

bool Dart::InitOnce(int argc, char** argv,
                    Dart_IsolateInitCallback callback) {
  // TODO(iposva): Fix race condition here.
  if (vm_isolate_ != NULL) {
    return false;
  }
  OS::InitOnce();
  Flags::ProcessCommandLineFlags(argc, argv);
  VirtualMemory::InitOnce();
  Isolate::InitOnce();
  // Create the VM isolate and finish the VM initialization.
  {
    ASSERT(vm_isolate_ == NULL);
    vm_isolate_ = Isolate::Init();
    Zone zone;
    HandleScope handle_scope;
    Heap::Init(vm_isolate_);
    ObjectStore::Init(vm_isolate_);
    Object::InitOnce();
    StubCode::InitOnce();
    PortMap::InitOnce();
    Scanner::InitOnce();
  }
  Isolate::SetCurrent(NULL);  // Unregister the VM isolate from this thread.
  Isolate::SetInitCallback(callback);
  return true;
}


Isolate* Dart::CreateIsolate(void* snapshot_buffer, void* data) {
  // Create and initialize a new isolate.
  Isolate* isolate = Isolate::Init();
  Zone zone;
  HandleScope handle_scope;
  Heap::Init(isolate);
  ObjectStore::Init(isolate);

  if (snapshot_buffer == NULL) {
    Object::Init(isolate);
  } else {
    // Initialize from snapshot (this should replicate the functionality
    // of Object::Init(..) in a regular isolate creation path.
    Object::InitFromSnapshot(isolate);
    Snapshot* snapshot = Snapshot::SetupFromBuffer(snapshot_buffer);
    SnapshotReader reader(snapshot, isolate->heap(), isolate->object_store());
    reader.ReadFullSnapshot();
  }

  StubCode::Init(isolate);
  CodeIndexTable::Init(isolate);

  // Give the embedder a shot at setting up this isolate.
  // Isolates spawned from within this isolate will be given the callback data
  // returned by the callback.
  data = Isolate::InitCallback()(data);
  // TODO(iposva): Shutdown the isolate on failure.
  isolate->set_init_callback_data(data);
  return isolate;
}


void Dart::ShutdownIsolate() {
  Isolate* isolate = Isolate::Current();
  isolate->Shutdown();
  delete isolate;
}

}  // namespace dart
