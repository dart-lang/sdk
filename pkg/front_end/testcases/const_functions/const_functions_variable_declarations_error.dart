// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous variable declaration usage within const functions.

import "package:expect/expect.dart";

const var1 = fn1();
int fn1() {
  var a;
  return a;
}

const var2 = fn2();
int fn2() {
  var x;
  x = "string";
  return x;
}

void main() {}
