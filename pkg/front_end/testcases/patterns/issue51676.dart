// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int case3() {
  switch (null as dynamic) {
    case B(const bool.fromEnvironment('x') ? 0 : 1):
      return 1;
    default:
      return 2;
  }
}
