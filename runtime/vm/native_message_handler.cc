// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_message_handler.h"

#include "vm/dart_api_message.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/snapshot.h"
#include "vm/thread.h"

namespace dart {

NativeMessageHandler::NativeMessageHandler(const char* name,
                                           Dart_NativeMessageHandler func)
    : name_(strdup(name)),
      func_(func) {
  // A NativeMessageHandler always has one live port.
  increment_live_ports();
}


NativeMessageHandler::~NativeMessageHandler() {
  free(name_);
}


#if defined(DEBUG)
void NativeMessageHandler::CheckAccess() {
  ASSERT(Isolate::Current() == NULL);
}
#endif


static uint8_t* zone_allocator(
    uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  ApiZone* zone = ApiNativeScope::Current()->zone();
  return reinterpret_cast<uint8_t*>(
      zone->Reallocate(reinterpret_cast<uword>(ptr), old_size, new_size));
}


static void RunWorker(uword parameter) {
  NativeMessageHandler* handler =
      reinterpret_cast<NativeMessageHandler*>(parameter);
#if defined(DEBUG)
    handler->CheckAccess();
#endif

  while (handler->HasLivePorts()) {
    Message* message = handler->Dequeue(0);
    if (message != NULL) {
      if (message->priority() >= Message::kOOBPriority) {
        // TODO(turnidge): Out of band messages will not go through
        // the regular message handler.  Instead they will be
        // dispatched to special vm code.  Implement.
        UNIMPLEMENTED();
      }
      // Enter a native scope for handling the message. This will create a
      // zone for allocating the objects for decoding the message.
      ApiNativeScope scope;

      int32_t length = reinterpret_cast<int32_t*>(
          message->data())[Snapshot::kLengthIndex];
      ApiMessageReader reader(message->data() + Snapshot::kHeaderSize,
                              length,
                              zone_allocator);
      Dart_CObject* object = reader.ReadMessage();
      (*handler->func())(message->dest_port(),
                         message->reply_port(),
                         object);
      delete message;
    }
  }
}


void NativeMessageHandler::StartWorker() {
  int result = Thread::Start(RunWorker, reinterpret_cast<uword>(this));
  if (result != 0) {
    FATAL1("Failed to start native message handler worker thread %d", result);
  }
}


}  // namespace dart
