// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

DART_EXPORT int return42() {
  return 42;
}

DART_EXPORT double timesFour(double d) {
  return d * 4.0;
}
