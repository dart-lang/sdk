// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  Object t = true;
  Object f = false;
  Object o = new Object();
  t || o; // No error
  f || f; // No error
  Expect.throwsTypeError(() {
    o || t;
  });
  Expect.throwsTypeError(() {
    f || o;
  });
  f && o; // No error
  t && t; // No error
  Expect.throwsTypeError(() {
    o && f;
  });
  Expect.throwsTypeError(() {
    t && o;
  });
}
