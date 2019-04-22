// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/error_exit.h"

#include "bin/eventhandler.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

void ErrorExit(int exit_code, const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  Syslog::VPrintErr(format, arguments);
  va_end(arguments);

  Dart_ShutdownIsolate();

  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  char* error = Dart_Cleanup();
  if (error != NULL) {
    Syslog::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }

  Process::ClearAllSignalHandlers();
  EventHandler::Stop();
  Platform::Exit(exit_code);
}

}  // namespace bin
}  // namespace dart
