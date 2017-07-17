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

static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}

class IsolateSaver {
 public:
  explicit IsolateSaver(Isolate* current_isolate)
      : saved_isolate_(current_isolate) {
    if (current_isolate != NULL) {
      ASSERT(current_isolate == Isolate::Current());
      Dart_ExitIsolate();
    }
  }
  ~IsolateSaver() {
    if (saved_isolate_ != NULL) {
      Dart_Isolate I = reinterpret_cast<Dart_Isolate>(saved_isolate_);
      Dart_EnterIsolate(I);
    }
  }

 private:
  Isolate* saved_isolate_;

  DISALLOW_COPY_AND_ASSIGN(IsolateSaver);
};

static bool PostCObjectHelper(Dart_Port port_id, Dart_CObject* message) {
  uint8_t* buffer = NULL;
  ApiMessageWriter writer(&buffer, malloc_allocator);
  bool success = writer.WriteCMessage(message);

  if (!success) {
    free(buffer);
    return success;
  }

  // Post the message at the given port.
  return PortMap::PostMessage(new Message(
      port_id, buffer, writer.BytesWritten(), Message::kNormalPriority));
}

DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message) {
  return PostCObjectHelper(port_id, message);
}

DART_EXPORT bool Dart_PostInteger(Dart_Port port_id, int64_t message) {
  if (Smi::IsValid(message)) {
    return PortMap::PostMessage(
        new Message(port_id, Smi::New(message), Message::kNormalPriority));
  }
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = message;
  return PostCObjectHelper(port_id, &cobj);
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

  NativeMessageHandler* nmh = new NativeMessageHandler(name, handler);
  Dart_Port port_id = PortMap::CreatePort(nmh);
  PortMap::SetPortState(port_id, PortMap::kLivePort);
  nmh->Run(Dart::thread_pool(), NULL, NULL, 0);
  return port_id;
}

DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id) {
  // Close the native port without a current isolate.
  IsolateSaver saver(Isolate::Current());

  // TODO(turnidge): Check that the port is native before trying to close.
  return PortMap::ClosePort(native_port_id);
}

// --- Verification tools ---

static void CompileAll(Thread* thread, Dart_Handle* result) {
  ASSERT(thread != NULL);
  const Error& error = Error::Handle(thread->zone(), Library::CompileAll());
  if (error.IsNull()) {
    *result = Api::Success();
  } else {
    *result = Api::NewHandle(thread, error.raw());
  }
}

DART_EXPORT Dart_Handle Dart_CompileAll() {
  DARTSCOPE(Thread::Current());
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  CompileAll(T, &result);
  return result;
}

static void ParseAll(Thread* thread, Dart_Handle* result) {
  ASSERT(thread != NULL);
  const Error& error = Error::Handle(thread->zone(), Library::ParseAll(thread));
  if (error.IsNull()) {
    *result = Api::Success();
  } else {
    *result = Api::NewHandle(thread, error.raw());
  }
}

DART_EXPORT Dart_Handle Dart_ParseAll() {
  DARTSCOPE(Thread::Current());
  Dart_Handle result = Api::CheckAndFinalizePendingClasses(T);
  if (::Dart_IsError(result)) {
    return result;
  }
  CHECK_CALLBACK_STATE(T);
  ParseAll(T, &result);
  return result;
}

}  // namespace dart
