// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class T {}

class V {}

test() {
  T t;
  V v;
  {
    // This doesn't cause an error as the previous use of T is in an enclosing
    // scope.
    T() {}
  }
  {
    // This doesn't cause an error as the previous use of V is in an enclosing
    // scope.
    var v;
  }
  {
    T t;
    // This doesn't cause a scope error as the named function expression has
    // its own scope.
    var x = T() {};
  }
  {
    V v;
    // This causes an error, V is already used in this scope.
    var V;
  }
  {
    V v;
    // This causes an error, V is already used in this scope.
    var V = null;
  }
  {
    // This causes a scope error as T is already used in the function-type
    // scope (the return type).
    var x = T T() {};
  }
  {
    // This causes a scope error: using the outer definition of `V` as a type
    // when defining `V`.

    V V;
  }
  {
    // This causes a scope error as T is already defined as a type variable in
    // the function-type scope.
    var x = T<T>() {};
  }
  {
    T t;
    T T() {}
  }
  {
    T T() {}
  }
  {
    T t;
    T T(T t) {}
  }
  {
    T T(T t) {}
  }
  {
    void T(T t) {}
  }
}

void main() {}
