// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/embedded_dart_io.h"

#include "bin/eventhandler.h"
#include "bin/thread.h"

namespace dart {
namespace bin {

void BootstrapDartIo() {
  // Bootstrap 'dart:io' event handler.
  Thread::InitOnce();
  EventHandler::Start();
}

}  // namespace bin
}  // namespace dart
