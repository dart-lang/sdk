// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/test_utils.h"
#include "bin/file.h"

namespace dart {
namespace bin {
namespace test {

const char* GetFileName(const char* name) {
  if (bin::File::Exists(nullptr, name)) {
    return name;
  } else {
    const int kRuntimeLength = strlen("runtime/");
    return name + kRuntimeLength;
  }
}

}  // namespace test
}  // namespace bin
}  // namespace dart
