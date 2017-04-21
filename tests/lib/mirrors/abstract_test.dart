// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test abstract classes are retained.

library test.abstract_test;

@MirrorsUsed(targets: "test.abstract_test")
import 'dart:mirrors';

import 'stringify.dart';

abstract class Foo {}

void main() {
  expect(
      'Class(s(Foo) in s(test.abstract_test), top-level)', reflectClass(Foo));
}
