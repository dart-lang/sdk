// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that implicit generic function instantiations are inserted based on
/// the pattern's context type, but not when destructuring.

import "package:expect/expect.dart";

main() {
  testRelational();
  testValueExpression();
  testDestructureRefutable();
}

T id<T>(T t) => t;

class Box<T> {
  final T value;
  Box(this.value);
}

typedef IntFn = int Function(int);
typedef TFn = T Function<T>(T);

class Compare {
  operator <(IntFn f) => f is TFn;
}

void testRelational() {
  const c = id;

  // Instantiates based on the context type of the "<" method parameter type.
  if (Compare() case < c) {
    Expect.fail('"<" should receive instantiation, not generic function.');
  } else {
    // OK.
  }
}

void testValueExpression() {
  // Inserts instantiation in value expression.
  var (IntFn a) = id;
  Expect.isTrue(a is IntFn);
  Expect.isFalse(a is TFn);

  var (IntFn b,) = (id,);
  Expect.isTrue(b is IntFn);
  Expect.isFalse(b is TFn);

  var [IntFn c] = [id];
  Expect.isTrue(c is IntFn);
  Expect.isFalse(c is TFn);

  var {'x': IntFn d} = {'x': id};
  Expect.isTrue(d is IntFn);
  Expect.isFalse(d is TFn);

  var Box<IntFn>(value: e) = Box(id);
  Expect.isTrue(e is IntFn);
  Expect.isFalse(e is TFn);
}

void testDestructureRefutable() {
  // Does not instantiate during destructuring. In a refutable pattern, this
  // means the value doesn't match the tested type.
  (TFn,) record = (id,);
  if (record case (IntFn b,)) {
    Expect.fail('Should not match.');
  }

  List<TFn> list = [id];
  if (list case [IntFn c]) {
    Expect.fail('Should not match.');
  }

  Map<String, TFn> map = {'x': id};
  if (map case {'x': IntFn d}) {
    Expect.fail('Should not match.');
  }

  Box<TFn> box = Box(id);
  if (box case Box(value: IntFn e)) {
    Expect.fail('Should not match.');
  }
}
