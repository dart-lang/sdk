// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartutils.h"
#include "bin/eventhandler.h"

#include "include/dart_api.h"


static const intptr_t kNativeEventHandlerFieldIndex = 0;

/*
 * Returns the reference of the EventHandler stored in the native field.
 */
static EventHandler* GetEventHandler(Dart_Handle handle) {
  intptr_t value = 0;
  Dart_Handle result = Dart_GetNativeInstanceField(
      handle, kNativeEventHandlerFieldIndex, &value);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  EventHandler* event_handler = reinterpret_cast<EventHandler*>(value);
  ASSERT(event_handler != NULL);
  return event_handler;
}


/*
 * Sets the reference of the EventHandler in the native field.
 */
static void SetEventHandler(Dart_Handle handle, EventHandler* event_handler) {
  Dart_SetNativeInstanceField(handle,
                              kNativeEventHandlerFieldIndex,
                              reinterpret_cast<intptr_t>(event_handler));
}


/*
 * Starts the EventHandler thread and stores its reference in the dart
 * EventHandler object. args[0] holds the reference to the dart EventHandler
 * object.
 */
void FUNCTION_NAME(EventHandler_Start)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handle = Dart_GetNativeArgument(args, 0);
  EventHandler* event_handler = EventHandler::StartEventHandler();
  SetEventHandler(handle, event_handler);
  Dart_ExitScope();
}


/*
 * Send data to the EventHandler thread to register for a given instance
 * args[1] a ReceivePort args[2] with a notification event args[3]. args[0]
 * holds the reference to the dart EventHandler object.
 */
void FUNCTION_NAME(EventHandler_SendData)(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle handle = Dart_GetNativeArgument(args, 0);
  EventHandler* event_handler = GetEventHandler(handle);
  intptr_t id = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 1));
  handle = Dart_GetNativeArgument(args, 2);
  Dart_Port dart_port =
      DartUtils::GetIntegerField(handle, DartUtils::kIdFieldName);
  intptr_t data = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  event_handler->SendData(id, dart_port, data);
  Dart_ExitScope();
}
