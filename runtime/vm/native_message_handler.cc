// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_message_handler.h"

#include "vm/dart_api_message.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/snapshot.h"

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


bool NativeMessageHandler::HandleMessage(Message* message) {
  if (message->IsOOB()) {
    // We currently do not use OOB messages for native ports.
    UNREACHABLE();
  }
  // We create a native scope for handling the message.
  // All allocation of objects for decoding the message is done in the
  // zone associated with this scope.
  ApiNativeScope scope;
  ApiMessageReader reader(message->data(), message->len());
  Dart_CObject* object = reader.ReadMessage();
  (*func())(message->dest_port(), object);
  delete message;
  return true;
}

}  // namespace dart
