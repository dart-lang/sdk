// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for static checks on situations where expressions of type void
// can be used. The point is simply that there are no compile-time errors.

// We need expressions of type `void`; `void x` would do, but using
// `void get x` will work with tools that do not yet handle `void x`.
void get x => null;

void use(dynamic x) {}

main() {
  // In an expressionStatement `e;`, e may have type void.
  x;

  // In the initialization and increment expressions of a for-loop,
  // `for (e1; e2; e3) {..}`, `e1` and `e3` may have type void.
  for (x;; x) {
    break;
  }

  // In a typeCast `e as T`, `e` may have type void.
  var y = x as Object?;

  // In a parenthesized expression `(e)`, `e` may have type void.
  (x);

  // In a return statement `return e;`, when the return type of the
  // innermost enclosing function is the type void, e may have type void.
  void f() => x;

  void g() {
    return x;
  }
}
