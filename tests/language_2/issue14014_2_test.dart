// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a type variable used in a parameter of a constructor that
// has a closure in its initializer list does not lead to a crash in
// dart2js.

class A<T> {
  A(f);
}

class B<T> extends A<T> {
  B({void f(T foo)})
      : super((T a) {
          f = (a) => 42;
        });
}

main() {
  var t = new B<int>();
}
