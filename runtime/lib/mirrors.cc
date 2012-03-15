// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/message.h"
#include "vm/port.h"

namespace dart {

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DEFINE_NATIVE_ENTRY(Mirrors_send, 3) {
  GET_NATIVE_ARGUMENT(Instance, port, arguments->At(0));
  GET_NATIVE_ARGUMENT(Instance, message, arguments->At(1));
  GET_NATIVE_ARGUMENT(Instance, replyTo, arguments->At(2));

  // Get the send port id.
  Object& result = Object::Handle();
  result = DartLibraryCalls::PortGetId(port);
  if (result.IsError()) {
    Exceptions::PropagateError(result);
  }

  Integer& value = Integer::Handle();
  value ^= result.raw();
  int64_t send_port_id = value.AsInt64Value();

  // Get the reply port id.
  result = DartLibraryCalls::PortGetId(replyTo);
  if (result.IsError()) {
    Exceptions::PropagateError(result);
  }
  value ^= result.raw();
  int64_t reply_port_id = value.AsInt64Value();

  // Construct the message.
  uint8_t* data = NULL;
  SnapshotWriter writer(Snapshot::kMessage, &data, &allocator);
  writer.WriteObject(message.raw());
  writer.FinalizeBuffer();

  // Post the message.
  bool retval = PortMap::PostMessage(new Message(
      send_port_id, reply_port_id, data, Message::kOOBPriority));
  const Bool& retval_obj = Bool::Handle(Bool::Get(retval));
  arguments->SetReturn(retval_obj);
}


DEFINE_NATIVE_ENTRY(IsolateMirrorImpl_buildResponse, 1) {
  GET_NATIVE_ARGUMENT(Instance, map, arguments->At(0));
  String& key = String::Handle();
  Instance& value = Instance::Handle();
  Object& result = Object::Handle();

  key = String::New("debugName");
  value = String::New(isolate->name());
  result = DartLibraryCalls::MapSetAt(map, key, value);
  if (result.IsError()) {
    // TODO(turnidge): Prevent mirror operations from crashing other isolates?
    Exceptions::PropagateError(result);
  }

  key = String::New("ok");
  value = Bool::True();
  result = DartLibraryCalls::MapSetAt(map, key, value);
  if (result.IsError()) {
    Exceptions::PropagateError(result);
  }
}

}  // namespace dart
