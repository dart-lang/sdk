// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_DIRECTORY_H_
#define BIN_DIRECTORY_H_

#include "bin/builtin.h"
#include "bin/globals.h"

class Directory {
 public:
  static void List(const char* path,
                   bool recursive,
                   Dart_Port dir_port,
                   Dart_Port file_port,
                   Dart_Port done_port,
                   Dart_Port error_port);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Directory);
};

#endif  // BIN_DIRECTORY_H_
