// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/builtin.h"
#include "bin/globals.h"
#include "bin/process.h"

int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_event,
                   char* os_error_message,
                   int os_error_message_len) {
  // Setup info structures.
  STARTUPINFO startup_info;
  PROCESS_INFORMATION process_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.cb = sizeof(startup_info);
  ZeroMemory(&process_info, sizeof(process_info));

  // TODO(ager): Once sockets are implemented, use the supplied
  // arguments as in, out and err in the startup info.

  // Compute command-line length.
  int command_line_length = strlen(path);
  for (int i = 0; i < arguments_length; i++) {
    command_line_length += strlen(arguments[i]);
  }
  // Account for two occurrences of '"' around the command, one
  // space per argument and a terminating '\0'.
  command_line_length += 2 + arguments_length + 1;
  static const int kMaxCommandLineLength = 32768;
  if (command_line_length > kMaxCommandLineLength) {
    return 1;
  }

  // Put together command-line string.
  char* command_line = new char[command_line_length];
  int len = 0;
  int remaining = command_line_length;
  int written = snprintf(command_line + len, remaining, "\"%s\"", path);
  len += written;
  remaining -= written;
  ASSERT(remaining >= 0);
  for (int i = 0; i < arguments_length; i++) {
    written = snprintf(command_line + len, remaining, " %s", arguments[i]);
    len += written;
    remaining -= written;
    ASSERT(remaining >= 0);
  }

  // Create process.
  BOOL result = CreateProcess(NULL,   // ApplicationName
                              command_line,
                              NULL,   // ProcessAttributes
                              NULL,   // ThreadAttributes
                              FALSE,  // InheritHandles
                              0,      // CreationFlags
                              NULL,   // Environment
                              NULL,   // CurrentDirectory,
                              &startup_info,
                              &process_info);

  // Deallocate command-line string.
  delete[] command_line;

  if (result == 0) {
    return 1;
  }

  // Return process handle.
  *id = reinterpret_cast<intptr_t>(process_info.hProcess);
  return 0;
}


bool Process::Kill(intptr_t id) {
  HANDLE process_handle = reinterpret_cast<HANDLE>(id);
  BOOL result = TerminateProcess(process_handle, -1);
  if (result == 0) {
    return false;
  }
  CloseHandle(process_handle);
  return true;
}


void Process::Exit(intptr_t id) {
}
