// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_VMSERVICE_IMPL_H_
#define BIN_VMSERVICE_IMPL_H_

#include "bin/vmservice.h"

#include "platform/globals.h"

namespace dart {
namespace bin {

class VmService {
 public:
  // Returns false if service could not be started.
  static bool Start(const char *server_ip, intptr_t server_port);
  // Error message if startup failed.
  static const char* GetErrorMessage();

 private:
  static bool _Start(const char *server_ip, intptr_t server_port);
  static Dart_Handle GetSource(const char* name);
  static Dart_Handle LoadScript(const char* name);
  static Dart_Handle LoadSource(Dart_Handle library, const char* name);
  static Dart_Handle LoadResources(Dart_Handle library);
  static Dart_Handle LoadResource(Dart_Handle library, const char* name,
                                  const char* prefix);
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url);
  static void ThreadMain(uword parameters);
  static const char* error_msg_;
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(VmService);
};


}  // namespace bin
}  // namespace dart

#endif  // BIN_VMSERVICE_IMPL_H_
