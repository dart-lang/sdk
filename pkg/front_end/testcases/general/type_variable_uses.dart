// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const C();
  static C<T> staticMethod() {
    print(T); // Error
    T t; // Error
    C<T> l; // Error
    C<C<T>> ll; // Error
    <(T, int)>[]; // Error
    <({T a, int b})>[]; // Error
    <void Function<S extends T>()>[]; // Error
    const C<T>(); // Error
    const <T>[]; // Error
    const <C<T>>[]; // Error
    const <Object>[T]; // Error
    const <Object>[const C<T>()]; // Error
    const <(T, int)>[]; // Error
    const <({T a, int b})>[]; // Error
    const <void Function<S extends T>()>[]; // Error
    const C<(T, int)>(); // Error
    const C<({T a, int b})>(); // Error
    const C<void Function<S extends T>()>(); // Error
    throw '';
  }

  C<T> instanceMethod() {
    print(T); // Ok
    T t; // Ok
    C<T> l; // Ok
    C<C<T>> ll; // Ok
    <(T, int)>[]; // Error
    <({T a, int b})>[]; // Error
    <void Function<S extends T>()>[]; // Error
    const C<T>(); // Error
    const <T>[]; // Error
    const <C<T>>[]; // Error
    const <Object>[T]; // Error
    const <Object>[const C<T>()]; // Error
    const <(T, int)>[]; // Error
    const <({T a, int b})>[]; // Error
    const <void Function<S extends T>()>[]; // Error
    const C<(T, int)>(); // Error
    const C<({T a, int b})>(); // Error
    const C<void Function<S extends T>()>(); // Error
    throw '';
  }
}

main() {}
