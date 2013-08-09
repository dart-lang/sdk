// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/socket.h"
#include "bin/thread.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

static const intptr_t kTimerId = -1;
static const intptr_t kInvalidId = -2;

static EventHandler* event_handler = NULL;
// TODO(ajohnsen): Consider removing mutex_ if we can enforce an invariant
//    that eventhandler is kept alive untill all isolates are closed.
static dart::Mutex* mutex_ = new dart::Mutex();


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


void EventHandler::Stop() {
  MutexLocker locker(mutex_);
  if (event_handler == NULL) return;
  event_handler->Shutdown();
  event_handler = NULL;
}


/*
 * Starts the EventHandler thread and stores its reference in the dart
 * EventHandler object. args[0] holds the reference to the dart EventHandler
 * object.
 */
void FUNCTION_NAME(EventHandler_Start)(Dart_NativeArguments args) {
  MutexLocker locker(mutex_);
  if (event_handler != NULL) return;
  event_handler = EventHandler::Start();
}


/*
 * Send data to the EventHandler thread to register for a given instance
 * args[1] a ReceivePort args[2] with a notification event args[3]. args[0]
 * holds the reference to the dart EventHandler object.
 */
void FUNCTION_NAME(EventHandler_SendData)(Dart_NativeArguments args) {
  Dart_Handle sender = Dart_GetNativeArgument(args, 1);
  intptr_t id = kInvalidId;
  if (Dart_IsNull(sender)) {
    id = kTimerId;
  } else {
    Socket::GetSocketIdNativeField(sender, &id);
  }
  Dart_Handle handle = Dart_GetNativeArgument(args, 2);
  Dart_Port dart_port =
      DartUtils::GetIntegerField(handle, DartUtils::kIdFieldName);
  int64_t data = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  {
    MutexLocker locker(mutex_);
    // Only send if the event_handler is not NULL. This means that the handler
    // shut down, and a message is send later on.
    if (event_handler != NULL) {
      event_handler->SendData(id, dart_port, data);
    }
  }
}

}  // namespace bin
}  // namespace dart
