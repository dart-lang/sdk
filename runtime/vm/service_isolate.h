// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SERVICE_ISOLATE_H_
#define RUNTIME_VM_SERVICE_ISOLATE_H_

#include "include/dart_api.h"

#include "vm/allocation.h"
#include "vm/os_thread.h"

namespace dart {

class ObjectPointerVisitor;
class SendPort;

class ServiceIsolate : public AllStatic {
 public:
  static const char* kName;
  static bool NameEquals(const char* name);

  static bool Exists();
  static bool IsRunning();
  static bool IsServiceIsolate(const Isolate* isolate);
  static bool IsServiceIsolateDescendant(const Isolate* isolate);
  static Dart_Port Port();

  static Dart_Port WaitForLoadPort();
  static Dart_Port LoadPort();

  static void Run();
  static bool SendIsolateStartupMessage();
  static bool SendIsolateShutdownMessage();
  static void SendServiceExitMessage();
  static void Shutdown();

  static void BootVmServiceLibrary();

  static void RequestServerInfo(const SendPort& sp);
  static void ControlWebServer(const SendPort& sp, bool enable);

  static void SetServerAddress(const char* address);

  // Returns the server's web address or NULL if none is running.
  static const char* server_address() { return server_address_; }

  static void VisitObjectPointers(ObjectPointerVisitor* visitor);

 private:
  static void KillServiceIsolate();

 protected:
  static void SetServicePort(Dart_Port port);
  static void SetServiceIsolate(Isolate* isolate);
  static void SetLoadPort(Dart_Port port);
  static void ConstructExitMessageAndCache(Isolate* isolate);
  static void FinishedExiting();
  static void FinishedInitializing();
  static void MaybeMakeServiceIsolate(Isolate* isolate);
  static Dart_IsolateCreateCallback create_callback() {
    return create_callback_;
  }

  static Dart_IsolateCreateCallback create_callback_;
  static uint8_t* exit_message_;
  static intptr_t exit_message_length_;
  static Monitor* monitor_;
  static bool initializing_;
  static bool shutting_down_;
  static Isolate* isolate_;
  static Dart_Port port_;
  static Dart_Port load_port_;
  static Dart_Port origin_;
  static char* server_address_;

  friend class Dart;
  friend class RunServiceTask;
  friend class ServiceIsolateNatives;
};

}  // namespace dart

#endif  // RUNTIME_VM_SERVICE_ISOLATE_H_
