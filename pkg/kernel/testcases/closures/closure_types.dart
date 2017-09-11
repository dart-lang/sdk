// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
//
// This tests checks that the runtime types of converted closures are asessed
// correctly in is-tests.

class C<T> {
  void getf() {
    T fn(T x) {
      return x;
    }

    ;
    return fn;
  }
}

typedef void ct(int x);

void test_c() {
  var x = new C<int>().getf();
  assert(x is ct);

  var y = new C<String>().getf();
  assert(y is! ct);
}

class D<T> {
  void getf<S>() {
    T fn(S y) {
      return null;
    }

    return fn;
  }
}

typedef String dt(int x);

void test_d() {
  var x = new D<String>().getf<int>();
  assert(x is dt);

  var y = new D<int>().getf<int>();
  assert(y is! dt);

  var z = new D<int>().getf<String>();
  assert(z is! dt);
}

main() {
  test_c();
  test_d();
}
