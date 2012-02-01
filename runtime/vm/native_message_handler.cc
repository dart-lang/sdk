// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_message_handler.h"

#include "vm/isolate.h"
#include "vm/message.h"
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


static void RunWorker(uword parameter) {
  NativeMessageHandler* handler =
      reinterpret_cast<NativeMessageHandler*>(parameter);
#if defined(DEBUG)
    handler->CheckAccess();
#endif

  while (handler->HasLivePorts()) {
    Message* message = handler->queue()->Dequeue(0);
    if (message != NULL) {
      if (message->priority() >= Message::kOOBPriority) {
        // TODO(turnidge): Out of band messages will not go through
        // the regular message handler.  Instead they will be
        // dispatched to special vm code.  Implement.
        UNIMPLEMENTED();
      }
      // TODO(sgjesse): Once CMessageReader::ReadObject is committed,
      // use that here and pass the resulting data object to the
      // handler instead.
      (*handler->func())(message->dest_port(),
                         message->reply_port(),
                         message->data());
      delete message;
    }
  }
}


void NativeMessageHandler::StartWorker() {
  new Thread(RunWorker, reinterpret_cast<uword>(this));
}


}  // namespace dart
