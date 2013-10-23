// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an is check on a function type involving type parameters
// does not crash dart2js, when the is test is in the initializer list
// of a constructor.

class A<T> {
  var f;
  A(this.f);
}

typedef foo<T>(T a);

class B<T> extends A<T> {
  B({void f(T foo)}) : super(() => f is foo<T>);
}

main() {
  var t = new B<int>(f: (int a) => 42);
  if (!t.f()) {
    throw 'Test failed';
  }
}
