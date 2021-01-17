// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from language/mixin/forwarding_stub_call_test

// Test for calling a method for which a forwarding super stub has been
// inserted.

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
    // Test that we can call the method.
    super.method(0);
  }
}

main() {}
