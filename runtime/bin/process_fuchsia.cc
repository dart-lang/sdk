// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/process.h"

#include "bin/lockers.h"
#include "platform/assert.h"


namespace dart {
namespace bin {

int Process::global_exit_code_ = 0;
Mutex* Process::global_exit_code_mutex_ = new Mutex();
Process::ExitHook Process::exit_hook_ = NULL;

void Process::TerminateExitCodeHandler() {}

intptr_t Process::CurrentProcessId() {
  UNIMPLEMENTED();
  return 0;
}

intptr_t Process::SetSignalHandler(intptr_t signal) {
  UNIMPLEMENTED();
  return -1;
}


void Process::ClearSignalHandler(intptr_t signal) {
  UNIMPLEMENTED();
}

bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
  UNIMPLEMENTED();
  return false;
}

bool Process::Kill(intptr_t id, int signal) {
  UNIMPLEMENTED();
  return false;
}

int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   const char* working_directory,
                   char* environment[],
                   intptr_t environment_length,
                   ProcessStartMode mode,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_event,
                   char** os_error_message) {
  UNIMPLEMENTED();
  return -1;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
