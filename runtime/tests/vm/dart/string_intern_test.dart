// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show intern;
import "package:expect/expect.dart";

@pragma("vm:never-inline")
String genString(int i) => "abc-${i}-xyz";

main() {
  int random = Object().hashCode;
  var a = genString(random);
  var b = genString(random);
  Expect.notIdentical(a, b);

  var internedA = intern(a);
  Expect.equals(a, internedA);
  // Likely, but not guaranteed: Expect.identical(a, internedA);
  var internedB = intern(b);
  Expect.equals(b, internedB);
  // Likely, but not guaranteed: Expect.identical(a, internedB);
  Expect.identical(internedA, internedB);
}
