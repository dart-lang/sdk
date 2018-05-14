// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PATH_H_
#define RUNTIME_BIN_PATH_H_

#include "bin/builtin.h"
#include "include/dart_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

class Path {
 public:
  Path(const char* raw_path, intptr_t len)
      : raw_path_(strdup(raw_path)), len_(len) {}

  ~Path() { free(const_cast<char*>(raw_path_)); }

  const char* raw_path() const { return raw_path_; }
  intptr_t length() const { return len_; }

  static Path* GetPath(Dart_Handle path_obj);

 private:
  const char* raw_path_;
  intptr_t len_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(Path);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PATH_H_
