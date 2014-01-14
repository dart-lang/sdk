// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SERVICE_H_
#define VM_SERVICE_H_

#include "include/dart_api.h"

#include "vm/allocation.h"

namespace dart {

class Instance;
class Isolate;

class Service : public AllStatic {
 public:
  static void HandleServiceMessage(Isolate* isolate, const Instance& message);
  static Isolate* GetServiceIsolate(void* callback_data);
  static bool SendIsolateStartupMessage();
  static bool SendIsolateShutdownMessage();
 private:
  static bool IsRunning();
  static Isolate* service_isolate_;
  static Dart_LibraryTagHandler default_handler_;
  static Dart_Port port_;
  static Dart_Handle GetSource(const char* name);
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag, Dart_Handle library,
                                       Dart_Handle url);
};

}  // namespace dart

#endif  // VM_SERVICE_H_
