// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_VMSERVICE_IMPL_H_
#define BIN_VMSERVICE_IMPL_H_

#include "bin/vmservice.h"
#include "platform/thread.h"


namespace dart {
namespace bin {

class VmService {
 public:
  // Returns false if service could not be started.
  static bool Start(intptr_t server_port);
  // Error message if startup failed.
  static const char* GetErrorMessage();

  static Dart_Port port();

  static bool IsRunning();

  static bool SendIsolateStartupMessage(Dart_Port port);
  static bool SendIsolateShutdownMessage(Dart_Port port);

  static void VmServiceShutdownCallback(void* callback_data);

 private:
  static bool _Start(intptr_t server_port);
  static void _Stop();
  static Dart_Handle GetSource(const char* name);
  static Dart_Handle LoadScript(const char* name);
  static Dart_Handle LoadSources(Dart_Handle library, const char** names);
  static Dart_Handle LoadSource(Dart_Handle library, const char* name);
  static Dart_Handle LoadResources(Dart_Handle library);
  static Dart_Handle LoadResource(Dart_Handle library, const char* name,
                                  const char* prefix);

  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url);

  static void ThreadMain(uword parameters);

  static Dart_Isolate isolate_;
  static Dart_Port port_;
  static const char* error_msg_;
  static dart::Monitor* monitor_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(VmService);
};


}  // namespace bin
}  // namespace dart

#endif  // BIN_VMSERVICE_IMPL_H_
