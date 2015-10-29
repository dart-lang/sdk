// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/vmservice_dartium.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/platform.h"
#include "bin/thread.h"
#include "bin/vmservice_impl.h"

namespace dart {
namespace bin {

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    fprintf(stderr, "CHECK_RESULT failed: %s", Dart_GetError(result));         \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return 0;                                                                  \
  }                                                                            \



static const char* DEFAULT_VM_SERVICE_SERVER_IP = "127.0.0.1";
static const int DEFAULT_VM_SERVICE_SERVER_PORT = 0;

void VmServiceServer::Bootstrap() {
  if (!Platform::Initialize()) {
    fprintf(stderr, "Platform::Initialize() failed\n");
  }
  DartUtils::SetOriginalWorkingDirectory();
  Thread::InitOnce();
  EventHandler::Start();
}


Dart_Isolate VmServiceServer::CreateIsolate(const uint8_t* snapshot_buffer) {
  ASSERT(snapshot_buffer != NULL);
  // Create the isolate.
  char* error = 0;
  Dart_Isolate isolate = Dart_CreateIsolate(DART_VM_SERVICE_ISOLATE_NAME,
                                            "main",
                                            snapshot_buffer,
                                            NULL,
                                            NULL,
                                            &error);
  if (!isolate) {
    fprintf(stderr, "Dart_CreateIsolate failed: %s\n", error);
    return 0;
  }

  Dart_EnterScope();
  Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
  Builtin::SetNativeResolver(Builtin::kIOLibrary);

  Dart_Handle builtin_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kBuiltinLibrary);
  CHECK_RESULT(builtin_lib);

  Dart_Handle result;

  // Prepare for script loading by setting up the 'print' and 'timer'
  // closures and setting up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(
      NULL, NULL, NULL, true, false, builtin_lib);
  CHECK_RESULT(result);

  ASSERT(Dart_IsServiceIsolate(isolate));
  if (!VmService::Setup(DEFAULT_VM_SERVICE_SERVER_IP,
                        DEFAULT_VM_SERVICE_SERVER_PORT,
                        false /* running_precompiled */)) {
    fprintf(stderr,
            "Vmservice::Setup failed: %s\n", VmService::GetErrorMessage());
    isolate = NULL;
  }
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}


const char* VmServiceServer::GetServerIP() {
  return VmService::GetServerIP();
}


intptr_t VmServiceServer::GetServerPort() {
  return VmService::GetServerPort();
}


/* DISALLOW_ALLOCATION */
void VmServiceServer::operator delete(void* pointer)  {
  fprintf(stderr, "unreachable code\n");
  abort();
}

}  // namespace bin
}  // namespace dart
