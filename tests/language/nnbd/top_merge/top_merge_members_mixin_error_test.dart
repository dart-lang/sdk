// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Tests several aspects of the TOP_MERGE algorithm for merging super-interfaces.
// This tests that TOP_MERGE is not applied when a mixin causes an override.
// Instead, the signature of the mixed in method should apply.

class A<T> {
  T member() {
    throw "Unreachable";
  }
}

mixin M<T> {
  T member() {
    throw "Unreachable";
  }
}

void takesObject(Object x) {}

class D0 extends A<dynamic> with M<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void`
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class D1 extends A<Object?> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

class D2 extends A<void> with M<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void`
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class D3 extends A<Object?> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class D4 extends A<void> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

class D5 extends A<dynamic> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class D6 extends A<void> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class D7 extends A<dynamic> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

// Test the same examples with top level normalization

class ND0 extends A<FutureOr<dynamic>> with M<Object?> {
  void test() {
    var self = this;
    var x = self.member();

    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void`
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class ND1 extends A<FutureOr<Object?>> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

class ND2 extends A<FutureOr<void>> with M<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void`
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class ND3 extends A<FutureOr<Object?>> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class ND4 extends A<FutureOr<void>> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

class ND5 extends A<FutureOr<dynamic>> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class ND6 extends A<FutureOr<void>> with M<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return `dynamic`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object?`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class ND7 extends A<FutureOr<dynamic>> with M<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

// Test the same examples with deep normalization

class DND0 extends A<FutureOr<dynamic> Function()> with M<Object? Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class DND1 extends A<FutureOr<Object?> Function()> with M<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns `dynamic Function()`
  }
}

class DND2 extends A<FutureOr<void> Function()> with M<Object? Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class DND3 extends A<FutureOr<Object?> Function()> with M<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object? Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class DND4 extends A<FutureOr<void> Function()> with M<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns `dynamic Function()`
  }
}

class DND5 extends A<FutureOr<dynamic> Function()> with M<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object? Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class DND6 extends A<FutureOr<void> Function()> with M<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `Object? Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class DND7 extends A<FutureOr<dynamic> Function()> with M<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns `dynamic Function()`
  }
}

// Test the same examples with deep normalization + typedefs

// With all mixin examples, no normalization is specified, and so
// all errors and warnings should look like the `Object?` errors and
// warnings (we don't distinguish between the method sets on `Object?`
// and `FutureOr<T>` for any `T`).

typedef Wrap<T> = FutureOr<T>? Function();

class WND0 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<Object?>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND1 extends A<Wrap<FutureOr<Object?>>> with M<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND2 extends A<Wrap<FutureOr<void>>> with M<Wrap<Object?>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND3 extends A<Wrap<FutureOr<Object?>>> with M<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND4 extends A<Wrap<FutureOr<void>>> with M<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND5 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND6 extends A<Wrap<FutureOr<void>>> with M<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}

class WND7 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return `dynamic Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
    x.toString; // Check that member does not return `void Function()`
    takesObject(x); // Check that member does not return `Object Function()`
    //   ^
    // [analyzer] unspecified
    // [cfe] unspecified
  }
}
