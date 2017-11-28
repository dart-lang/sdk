// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  Object b = false;
  while (b) {} // No error
  b = new Object();
  Expect.throwsTypeError(() {
    while (b) {}
  });
}
