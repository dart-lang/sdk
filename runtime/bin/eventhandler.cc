// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/socket.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

static const intptr_t kTimerId = -1;
static const intptr_t kInvalidId = -2;

void TimeoutQueue::UpdateTimeout(Dart_Port port, int64_t timeout) {
  // Find port if present.
  Timeout* last = NULL;
  Timeout* current = timeouts_;
  while (current != NULL) {
    if (current->port() == port) {
      // Found.
      if (timeout < 0) {
        // Remove from list and delete existing.
        if (last != NULL) {
          last->set_next(current->next());
        } else {
          timeouts_ = current->next();
        }
        delete current;
      } else {
        // Update timeout.
        current->set_timeout(timeout);
      }
      break;
    }
    last = current;
    current = current->next();
  }
  if (current == NULL && timeout >= 0) {
    // Not found, create a new.
    timeouts_ = new Timeout(port, timeout, timeouts_);
  }
  // Clear and find next timeout.
  next_timeout_ = NULL;
  current = timeouts_;
  while (current != NULL) {
    if (next_timeout_ == NULL ||
        current->timeout() < next_timeout_->timeout()) {
      next_timeout_ = current;
    }
    current = current->next();
  }
}


static EventHandler* event_handler = NULL;


void EventHandler::Start() {
  ASSERT(event_handler == NULL);
  event_handler = new EventHandler();
  event_handler->delegate_.Start(event_handler);
}


void EventHandler::Stop() {
  if (event_handler == NULL) return;
  event_handler->delegate_.Shutdown();
  event_handler = NULL;
}


EventHandlerImplementation* EventHandler::delegate() {
  if (event_handler == NULL) return NULL;
  return &event_handler->delegate_;
}


/*
 * Send data to the EventHandler thread to register for a given instance
 * args[0] a ReceivePort args[1] with a notification event args[2].
 */
void FUNCTION_NAME(EventHandler_SendData)(Dart_NativeArguments args) {
  Dart_Handle sender = Dart_GetNativeArgument(args, 0);
  intptr_t id = kInvalidId;
  if (Dart_IsNull(sender)) {
    id = kTimerId;
  } else {
    id = Socket::GetSocketIdNativeField(sender);
  }
  // Get the id out of the send port. If the handle is not a send port
  // we will get an error and propagate that out.
  Dart_Handle handle = Dart_GetNativeArgument(args, 1);
  Dart_Port dart_port;
  handle = Dart_SendPortGetId(handle, &dart_port);
  if (Dart_IsError(handle)) {
    Dart_PropagateError(handle);
    UNREACHABLE();
  }
  int64_t data = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  event_handler->SendData(id, dart_port, data);
}

}  // namespace bin
}  // namespace dart
