// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() { foo<num>(false, 0, 0); }

void foo<X>(bool test, X a, X b) {
  if (a is! int) return;
  {
    // UP(T, T) = T
    var c = (test ? a : a)
      ..toRadixString(2) // Allows int method.
      ..st<E<X>>()  // Erases to X.
      ;
    {
      X v1 = c; // Assignable to X.
      int v2 = c; // Assignable to int.
      c.st<E<X>>; // Erases to X.
      c = a as X;
    }
  }

  if (b is! int) return;
  {
    // a : X & int
    // b : X & int
    // "It's the same picture!"
    //
    // Check that even if the type objects aren't 'identical', but equal, the
    // algorithm works the same way.
    //
    // UP(T, T) = T
    var c = (test ? a : b)
      ..toRadixString(2) // Allows int method.
      ..st<E<X>>() // Erases to X.
      ;
    {
      X v1 = c; // Assignable to X.
      int v2 = c; // Assignable to int.
      c.st<E<X>>; // Erases to X.
      c = a as X;
    }
  }
}

extension Ext<T> on T {
  void st<S extends E<T>>(){}
}
typedef E<T> = T Function(T); // Invariant.
