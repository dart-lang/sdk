// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef exp1 = T Function<T>(T);
typedef exp2 = void Function<T>();
typedef exp3 = T Function<T>();
typedef exp4 = void Function<T>(T);
typedef exp5 = T Function<T extends S Function<S>(S)>(T);
typedef exp6 = T Function<T, S>(
    T, S, V Function<V extends S, U>(T, U, V, Map<S, U>));

class C1<X extends T Function<T>(T)> {
  C1() {
    expect(exp1, X);
  }
}

class C2<X extends void Function<T>()> {
  C2() {
    expect(exp2, X);
  }
}

class C3<X extends T Function<T>()> {
  C3() {
    expect(exp3, X);
  }
}

class C4<X extends void Function<T>(T)> {
  C4() {
    expect(exp4, X);
  }
}

class C5<X extends T Function<T extends S Function<S>(S)>(T)> {
  C5() {
    expect(exp5, X);
  }
}

class C6<
    X extends T Function<T, S>(
        T, S, V Function<V extends S, U>(T, U, V, Map<S, U>))> {
  C6() {
    expect(exp6, X);
  }
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
