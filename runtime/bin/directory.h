// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DIRECTORY_H_
#define BIN_DIRECTORY_H_

#include "bin/builtin.h"
#include "bin/globals.h"

class Directory {
 public:
  static bool Open(const char* path, intptr_t* dir);
  static bool Close(intptr_t dir);
  static void List(const char* path,
                   intptr_t dir,
                   bool recursive,
                   Dart_Port dir_handler,
                   Dart_Port file_handler,
                   Dart_Port done_handler,
                   Dart_Port dir_error_handler);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Directory);
};

#endif  // BIN_DIRECTORY_H_
