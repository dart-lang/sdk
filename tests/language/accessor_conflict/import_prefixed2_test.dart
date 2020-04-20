// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that a getter and its corresponding setter can be imported from two
// different files.  In this test the setter is imported first.

import "package:expect/expect.dart";

import "setter.dart" as p;
import "getter.dart" as p;

main() {
  p.getValue = 123;
  Expect.equals(p.x, 123);
  p.x = 456;
  Expect.equals(p.setValue, 456);
}
