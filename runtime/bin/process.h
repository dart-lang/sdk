// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PROCESS_H_
#define BIN_PROCESS_H_

#include "bin/builtin.h"
#include "bin/globals.h"


class Process {
 public:
  // Start a new process providing access to stdin, stdout, stderr and
  // process exit streams.
  static int Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_handler,
                   char* os_error_message,
                   int os_error_message_len);

  // Kill a process with a given pid.
  static bool Kill(intptr_t id);

  // Indicate that the process with the given pid has exited.
  static void Exit(intptr_t id);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Process);
};

#endif  // BIN_PROCESS_H_
