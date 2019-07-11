// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const C();
  static C<T> staticMethod() {
    print(T);
    T t;
    C<T> l;
    C<C<T>> ll;
    const C<T>();
    const <T>[];
    const <C<T>>[];
    const <Object>[T];
    const <Object>[const C<T>()];
  }

  C<T> instanceMethod() {
    print(T);
    T t;
    C<T> l;
    C<C<T>> ll;
    const C<T>();
    const <T>[];
    const <C<T>>[];
    const <Object>[T];
    const <Object>[const C<T>()];
  }
}

main() {}
