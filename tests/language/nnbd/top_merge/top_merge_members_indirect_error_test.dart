// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Tests several aspects of the TOP_MERGE algorithm for merging members

class A<T> {
  T member() {
    throw "Unreachable";
  }
}

class B<T> extends A<T> {
  T member() {
    throw "Unreachable";
  }
}

class Merge<S, T> extends A<S> implements B<T> {}

void takesObject(Object x) {}

class D0 extends Merge<dynamic, Object?> {
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

class D1 extends Merge<Object?, dynamic> {
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

class D2 extends Merge<void, Object?> {
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

class D3 extends Merge<Object?, void> {
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

class D4 extends Merge<void, dynamic> {
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

class D5 extends Merge<dynamic, void> {
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

class D6 extends Merge<void, void> {
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

class D7 extends Merge<dynamic, dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

// Test the same examples with top level normalization

class ND0 extends Merge<FutureOr<dynamic>, Object?> {
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

class ND1 extends Merge<FutureOr<Object?>, dynamic> {
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

class ND2 extends Merge<FutureOr<void>, Object?> {
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

class ND3 extends Merge<FutureOr<Object?>, void> {
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

class ND4 extends Merge<FutureOr<void>, dynamic> {
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

class ND5 extends Merge<FutureOr<dynamic>, void> {
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

class ND6 extends Merge<FutureOr<void>, void> {
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

class ND7 extends Merge<FutureOr<dynamic>, dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns `dynamic`
  }
}

// Test the same examples with deep normalization

class MergeFn<S, T> extends A<S Function()> implements B<T Function()> {}

class DND0 extends MergeFn<FutureOr<dynamic>, Object?> {
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

class DND1 extends MergeFn<FutureOr<Object?>, dynamic> {
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

class DND2 extends MergeFn<FutureOr<void>, Object?> {
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

class DND3 extends MergeFn<FutureOr<Object?>, void> {
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

class DND4 extends MergeFn<FutureOr<void>, dynamic> {
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

class DND5 extends MergeFn<FutureOr<dynamic>, void> {
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

class DND6 extends MergeFn<FutureOr<void>, void> {
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

class DND7 extends MergeFn<FutureOr<dynamic>, dynamic> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns `dynamic Function()`
  }
}

// Test the same examples with deep normalization + typedefs

typedef Wrap<T> = FutureOr<T>? Function();

class MergeWrappedFn<S, T> extends A<Wrap<S>> implements B<Wrap<T>> {}

class WND0 extends MergeWrappedFn<FutureOr<dynamic>, Object?> {
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

class WND1 extends MergeWrappedFn<FutureOr<Object?>, dynamic> {
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

class WND2 extends MergeWrappedFn<FutureOr<void>, Object?> {
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

class WND3 extends MergeWrappedFn<FutureOr<Object?>, void> {
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

class WND4 extends MergeWrappedFn<FutureOr<void>, dynamic> {
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

class WND5 extends MergeWrappedFn<FutureOr<dynamic>, void> {
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

class WND6 extends MergeWrappedFn<FutureOr<void>, void> {
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

class WND7 extends MergeWrappedFn<FutureOr<dynamic>, dynamic> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns `dynamic Function()`
  }
}
