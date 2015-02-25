// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SERVICE_H_
#define VM_SERVICE_H_

#include "include/dart_api.h"

#include "vm/allocation.h"
#include "vm/os_thread.h"

namespace dart {

class Array;
class DebuggerEvent;
class EmbedderServiceHandler;
class GCEvent;
class Instance;
class Isolate;
class JSONStream;
class Object;
class RawInstance;
class String;

class Service : public AllStatic {
 public:
  // Handles a message which is not directed to an isolate.
  static void HandleRootMessage(const Array& message);

  // Handles a message which is directed to a particular isolate.
  static void HandleIsolateMessage(Isolate* isolate, const Array& message);

  static bool EventMaskHas(uint32_t mask);
  static void SetEventMask(uint32_t mask);
  static bool NeedsDebuggerEvents();
  static bool NeedsGCEvents();

  static void HandleDebuggerEvent(DebuggerEvent* event);
  static void HandleGCEvent(GCEvent* event);

  static void RegisterIsolateEmbedderCallback(
      const char* name,
      Dart_ServiceRequestCallback callback,
      void* user_data);

  static void RegisterRootEmbedderCallback(
      const char* name,
      Dart_ServiceRequestCallback callback,
      void* user_data);

  static void SendEchoEvent(Isolate* isolate, const char* text);
  static void SendGraphEvent(Isolate* isolate);

 private:
  static void InvokeMethod(Isolate* isolate, const Array& message);

  // These must be kept in sync with service/constants.dart
  static const int kEventFamilyDebug = 0;
  static const int kEventFamilyGC = 1;
  static const uint32_t kEventFamilyDebugMask = (1 << kEventFamilyDebug);
  static const uint32_t kEventFamilyGCMask = (1 << kEventFamilyGC);

  static void EmbedderHandleMessage(EmbedderServiceHandler* handler,
                                    JSONStream* js);

  static EmbedderServiceHandler* FindIsolateEmbedderHandler(const char* name);
  static EmbedderServiceHandler* FindRootEmbedderHandler(const char* name);

  static void SendEvent(intptr_t eventId, const Object& eventMessage);
  // Does not take ownership of 'data'.
  static void SendEvent(intptr_t eventId,
                        const String& meta,
                        const uint8_t* data,
                        intptr_t size);

  static EmbedderServiceHandler* isolate_service_handler_head_;
  static EmbedderServiceHandler* root_service_handler_head_;

  static uint32_t event_mask_;
};

}  // namespace dart

#endif  // VM_SERVICE_H_
