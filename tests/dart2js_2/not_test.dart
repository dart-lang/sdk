// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void not1() {
  var x = !true;
  Expect.equals(false, x);
}

void not2() {
  var x = true;
  var y = !x;
  Expect.equals(false, y);
}

void not3() {
  var x = true;
  var y = !x;
  var z = !y;
  Expect.equals(true, z);
}

void not4() {
  var x = true;
  if (!x) Expect.fail('unreachable');
  Expect.equals(true, x);
}

void main() {
  not1();
  not2();
  not3();
  not4();
}
