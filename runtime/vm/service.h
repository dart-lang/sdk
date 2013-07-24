// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SERVICE_H_
#define VM_SERVICE_H_

#include "include/dart_api.h"

namespace dart {

class Instance;
class Isolate;

class Service : public AllStatic {
 public:
  static void HandleServiceMessage(Isolate* isolate, Dart_Port reply_port,
                                   const Instance& message);
};

}  // namespace dart

#endif  // VM_SERVICE_H_
