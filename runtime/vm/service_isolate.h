// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SERVICE_ISOLATE_H_
#define RUNTIME_VM_SERVICE_ISOLATE_H_

#include "include/dart_api.h"

#include "vm/allocation.h"
#include "vm/object.h"
#include "vm/os_thread.h"

namespace dart {

class Isolate;
class ObjectPointerVisitor;
class SendPort;

class ServiceIsolate : public AllStatic {
#if !defined(PRODUCT)

 public:
  static const char* kName;
  static bool NameEquals(const char* name);

  static bool Exists();
  static bool IsRunning();
  static bool IsServiceIsolate(const Isolate* isolate);
  static bool IsServiceIsolateDescendant(Isolate* isolate);
  static Dart_Port Port();
  static void WaitForServiceIsolateStartup();

  // Returns `true` if the request was sucessfully sent.  If it was, the
  // [reply_port] will receive a Dart_TypedData_kUint8 response json.
  //
  // If sending the rpc failed and [error] is not `nullptr` then [error] might
  // be set to a string containting the reason for the failure. If so, the
  // caller is responsible for free()ing the error.
  static bool SendServiceRpc(uint8_t* request_json,
                             intptr_t request_json_length,
                             Dart_Port reply_port,
                             char** error);

  static void Run();
  static bool SendIsolateStartupMessage();
  static bool SendIsolateShutdownMessage();
  static void SendServiceExitMessage();
  static void Shutdown();

  static void BootVmServiceLibrary();

  static void RegisterRunningIsolate(Isolate* isolate);

  static void RequestServerInfo(const SendPort& sp);
  static void ControlWebServer(const SendPort& sp,
                               bool enable,
                               const Bool& silenceOutput);

  static void SetServerAddress(const char* address);

  // Returns the server's web address or NULL if none is running.
  static const char* server_address() { return server_address_; }

  static void VisitObjectPointers(ObjectPointerVisitor* visitor);

 private:
  static void KillServiceIsolate();

 protected:
  static void SetServicePort(Dart_Port port);
  static void SetServiceIsolate(Isolate* isolate);
  static void FinishedExiting();
  static void FinishedInitializing();
  static void InitializingFailed(char* error);
  static void MaybeMakeServiceIsolate(Isolate* isolate);
  static Dart_IsolateGroupCreateCallback create_group_callback() {
    return create_group_callback_;
  }

  static Dart_IsolateGroupCreateCallback create_group_callback_;
  static Monitor* monitor_;
  enum State {
    kStopped,
    kStarting,
    kStarted,
    kStopping,
  };
  static State state_;
  static Isolate* isolate_;
  static Dart_Port port_;
  static Dart_Port origin_;
  static char* server_address_;

  // If starting the service-isolate failed, this error might provide the reason
  // for the failure.
  static char* startup_failure_reason_;
#else

 public:
  static bool NameEquals(const char* name) { return false; }
  static bool Exists() { return false; }
  static bool IsRunning() { return false; }
  static bool IsServiceIsolate(const Isolate* isolate) { return false; }
  static bool IsServiceIsolateDescendant(Isolate* isolate) { return false; }
  static void Run() {}
  static bool SendIsolateStartupMessage() { return false; }
  static bool SendIsolateShutdownMessage() { return false; }
  static void SendServiceExitMessage() {}
  static void Shutdown() {}
  static void RegisterRunningIsolate(Isolate* isolate) {}
  static void VisitObjectPointers(ObjectPointerVisitor* visitor) {}

 protected:
  static void SetServiceIsolate(Isolate* isolate) { UNREACHABLE(); }
#endif  // !defined(PRODUCT)

  friend class Dart;
  friend class Isolate;
  friend class RunServiceTask;
  friend class ServiceIsolateNatives;
};

}  // namespace dart

#endif  // RUNTIME_VM_SERVICE_ISOLATE_H_
