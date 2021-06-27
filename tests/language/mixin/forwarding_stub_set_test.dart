// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for assigning to a field for which a forwarding super stub has been
// inserted.

import 'package:expect/expect.dart';

class Super<T> {
  T? field;
}

class Mixin {
  int? field;
}

// A forwarding super stub is inserted:
//
//     void set field(/*generic-covariant-impl*/ int t) => super.field = t;
//
class Class = Super<int> with Mixin;

class Subclass extends Class {
  void test() {
    // Test that we can perform the assignment.
    super.field = 0;
  }
}

main() {
  Super<Object> s = new Subclass()..test();
  // Test that the covariance check is performed.
  Expect.throws(() => s.field = '');
}
