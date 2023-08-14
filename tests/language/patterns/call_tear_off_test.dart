// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that implicit call tear-offs are inserted based on the pattern's
/// context type, but not when destructuring.

import "package:expect/expect.dart";

main() {
  testValueExpression();
  testDestructureRefutable();
}

class C {
  const C();

  int call(int x) => x;
}

class Box<T> {
  final T value;
  Box(this.value);
}

typedef IntFn = int Function(int);

void testValueExpression() {
  // Inserts tear-off in value expression.
  var (IntFn a) = C();
  Expect.isTrue(a is IntFn);
  Expect.isFalse(a is C);

  var (IntFn b,) = (C(),);
  Expect.isTrue(b is IntFn);
  Expect.isFalse(b is C);

  var [IntFn c] = [C()];
  Expect.isTrue(c is IntFn);
  Expect.isFalse(c is C);

  var {'x': IntFn d} = {'x': C()};
  Expect.isTrue(d is IntFn);
  Expect.isFalse(d is C);

  var Box<IntFn>(value: e) = Box(C());
  Expect.isTrue(e is IntFn);
  Expect.isFalse(e is C);
}

void testDestructureRefutable() {
  // Does not tear-off during destructuring. In a refutable pattern, this means
  // the value doesn't match the tested type.
  (C,) record = (C(),);
  if (record case (IntFn b,)) {
    Expect.fail('Should not match.');
  }

  List<C> list = [C()];
  if (list case [IntFn c]) {
    Expect.fail('Should not match.');
  }

  Map<String, C> map = {'x': C()};
  if (map case {'x': IntFn d}) {
    Expect.fail('Should not match.');
  }

  Box<C> box = Box(C());
  if (box case Box(value: IntFn e)) {
    Expect.fail('Should not match.');
  }
}
