// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/embedded_dart_io.h"

#include "bin/directory.h"
#include "bin/eventhandler.h"
#include "bin/platform.h"
#include "bin/thread.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

void BootstrapDartIo() {
  // Bootstrap 'dart:io' event handler.
  Thread::InitOnce();
  TimerUtils::InitOnce();
  EventHandler::Start();
}

void SetSystemTempDirectory(const char* system_temp) {
  Directory::SetSystemTemp(system_temp);
}

void SetExecutableName(const char* executable_name) {
  Platform::SetExecutableName(executable_name);
}

void SetExecutableArguments(int script_index, char** argv) {
  Platform::SetExecutableArguments(script_index, argv);
}

}  // namespace bin
}  // namespace dart
