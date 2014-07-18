// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_native_api.h"

#include "platform/assert.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/native_message_handler.h"
#include "vm/port.h"

namespace dart {

// --- Message sending/receiving from native code ---

static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, allocator);
  bool success = writer.WriteCMessage(message);

  if (!success) return success;

  // Post the message at the given port.
  return PortMap::PostMessage(new Message(
      port_id, buffer, writer.BytesWritten(), Message::kNormalPriority));
}


DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently) {
  if (name == NULL) {
    name = "<UnnamedNativePort>";
  }
  if (handler == NULL) {
    OS::PrintErr("%s expects argument 'handler' to be non-null.\n",
                 CURRENT_FUNC);
    return ILLEGAL_PORT;
  }
  // Start the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());
  Isolate::SetCurrent(NULL);

  NativeMessageHandler* nmh = new NativeMessageHandler(name, handler);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  nmh->Run(Dart::thread_pool(), NULL, NULL, 0);
  return port_id;
}


DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id) {
  // Close the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());
  Isolate::SetCurrent(NULL);

  // TODO(turnidge): Check that the port is native before trying to close.
  return PortMap::ClosePort(native_port_id);
}


// --- Verification tools ---

static void CompileAll(Isolate* isolate, Dart_Handle* result) {
  ASSERT(isolate != NULL);
  const Error& error = Error::Handle(isolate, Library::CompileAll());
  if (error.IsNull()) {
    *result = Api::Success();
  } else {
    *result = Api::NewHandle(isolate, error.raw());
  }
}


DART_EXPORT Dart_Handle Dart_CompileAll() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Dart_Handle result = Api::CheckIsolateState(isolate);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(isolate);
  CompileAll(isolate, &result);
  return result;
}

}  // namespace dart
