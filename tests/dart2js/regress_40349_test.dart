// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for Issue #40349:
///
/// Before the fix, this code was accidentally generating a type check twice.
/// In between the two checks, code to update `_foo` was overriding a temporary
/// variable used by the check subexpression, which made the code for the
/// second check invalid.
///
/// The second check should not have been generated, but it was emitted due to
/// a broken invariant of the SSA generate-at-use logic.

void main() {
  // `x` which is used multiple times after inilining, so a temporary is used.
  x.method(40);
}

dynamic x = Wrapper<int>();

class A<E> {
  int _foo = 0;
  List<E?> list = [null];

  @pragma('dart2js:tryInline')
  void internalMethod(E value) {
    // The update and use of `_foo` requires a separate temporary which reuses
    // the same variable given to `x` (technically `x` is no longer live).
    _foo = (_foo + 1) & 0;

    // This use of `value` accidentally contains the second check, which
    // still refers to the temporary assuming it was `x` and not `_foo`.
    list[_foo] = value;
  }
}

class Wrapper<T> {
  A<T> a = A<T>();

  @pragma('dart2js:tryInline')
  method(T t) => a.internalMethod(t);
}
