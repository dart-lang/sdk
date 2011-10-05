// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

bool Directory::Open(const char* path, intptr_t* dir) {
  UNIMPLEMENTED();
  return false;
}

bool Directory::Close(intptr_t dir) {
  UNIMPLEMENTED();
  return false;
}

void Directory::List(const char* path,
                     intptr_t dir,
                     bool recursive,
                     Dart_Port dir_handler,
                     Dart_Port file_handler,
                     Dart_Port done_handler,
                     Dart_Port dir_error_handler) {
  UNIMPLEMENTED();
}
