// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for tearing off a method for which a forwarding super stub has been
// inserted.

import 'package:expect/expect.dart';

class Super<T> {
  void method(T t) {}
}

class Mixin {
  void method(int t) {}
}

// A forwarding super stub is inserted:
//
//     void method(/*generic-covariant-impl*/ int t) => super.method(t);
//
class Class = Super<int> with Mixin;

class Subclass extends Class {
  void test() {
    // Test that we can tear off the method.
    void Function(int) f = super.method;
    f(0);
  }
}

main() {
  Super<Object> s = new Subclass()..test();
  // Test that the covariance check is performed.
  Expect.throws(() => s.method(''));
}
