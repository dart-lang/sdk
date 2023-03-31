// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
  final int finalField;
  int get getter => finalField;

  Class(this.field, this.finalField);
}

int ifCase(o) {
  print('o = $o');
  if (o case 1) {
    return 1;
  }
  if (o case (f: (>=3) as int && (<5) as int)) {
    return 2;
  }
  if (o case 6 || 7) {
    return 3;
  }
  if (o case (g: 8 as int)) {
    return 4;
  }
  if (o case (a: _!)) {
    return 5;
  }
  if (o case (b: _?)) {
    return 6;
  }
  if (o case [1, 2]) {
    return 7;
  }
  if (o case [2, 3, ...]) {
    return 8;
  }
  if (o case [3, 4, ..., 5]) {
    return 9;
  }
  if (o case [4, 5, ...[(<1) as int, (>2) as int]]) {
    return 10;
  }
  if (o case [5, 6, ...[(<1) as int, (>2) as int], 7]) {
    return 11;
  }
  if (o case Class(field: 1)) {
    return 12;
  }
  if (o case Class(finalField: 2)) {
    return 13;
  }
  if (o case Class(field: 3, getter: 4)) {
    return 14;
  }
  if (o case Class()) {
    return 15;
  }
  if (o case == 'foo') {
    return 16;
  }
  if (o case (e: != 'bar')) {
    return 17;
  }
  if (o case <int, int>{5: >= 16}) {
    return 18;
  }
  if (o case [_]) {
    return 19;
  }
  if (o case bool _) {
    return 20;
  }
  if (o case Map() when o.isEmpty) {
    return 21;
  }
  if (o case {0: int _}) {
    return 22;
  }
  if (o case {1: String _}) {
    return 23;
  }
  if (o case {2: var a}) {
    return 24;
  }
  if (o case {3: int b}) {
    return 25;
  }
  if (o case (0, 1)) {
    return 26;
  }
  if (o case (a: 0, b: var c)) {
    return 27;
  }
  if (o case (c: 0, d: var d) when d is int) {
    return 28;
  }
  return 0;
}

int ifCaseElse(o) {
  print('o = $o');
  if (o case 1) {
    return 1;
  } else if (o case (f: (>=3) as int && (<5) as int)) {
    return 2;
  } else if (o case 6 || 7) {
    return 3;
  } else if (o case (g: 8 as int)) {
    return 4;
  } else if (o case (a: _!)) {
    return 5;
  } else if (o case (b: _?)) {
    return 6;
  } else if (o case [1, 2]) {
    return 7;
  } else if (o case [2, 3, ...]) {
    return 8;
  } else if (o case [3, 4, ..., 5]) {
    return 9;
  } else if (o case [4, 5, ...[(<1) as int, (>2) as int]]) {
    return 10;
  } else if (o case [5, 6, ...[(<1) as int, (>2) as int], 7]) {
    return 11;
  } else if (o case Class(field: 1)) {
    return 12;
  } else if (o case Class(finalField: 2)) {
    return 13;
  } else if (o case Class(field: 3, getter: 4)) {
    return 14;
  } else if (o case Class()) {
    return 15;
  } else if (o case == 'foo') {
    return 16;
  } else if (o case (e: != 'bar')) {
    return 17;
  } else if (o case <int, int>{5: >= 16}) {
    return 18;
  } else if (o case [_]) {
    return 19;
  } else if (o case bool _) {
    return 20;
  } else if (o case Map() when o.isEmpty) {
    return 21;
  } else if (o case {0: int _}) {
    return 22;
  } else if (o case {1: String _}) {
    return 23;
  } else if (o case {2: var a}) {
    return 24;
  } else if (o case {3: int b}) {
    return 25;
  } else if (o case (0, 1)) {
    return 26;
  } else if (o case (a: 0, b: var c)) {
    return 27;
  } else if (o case (c: 0, d: var d) when d is int) {
    return 28;
  } else {
    return 0;
  }
}

int switchStatement(o) {
  print('o = $o');
  switch (o) {
    case 1:
      return 1;
    case (f: (>=3) as int && (<5) as int):
      return 2;
    case 6 || 7:
      return 3;
    case (g: 8 as int):
      return 4;
    case (a: _!):
      return 5;
    case (b: _?):
      return 6;
    case [1, 2]:
      return 7;
    case [2, 3, ...]:
      return 8;
    case [3, 4, ..., 5]:
      return 9;
    case [4, 5, ...[(<1) as int, (>2) as int]]:
      return 10;
    case [5, 6, ...[(<1) as int, (>2) as int], 7]:
      return 11;
    case Class(field: 1):
      return 12;
    case Class(finalField: 2):
      return 13;
    case Class(field: 3, getter: 4):
      return 14;
    case Class():
      return 15;
    case == 'foo':
      return 16;
    case (e: != 'bar'):
      return 17;
    case <int, int>{5: >= 16}:
      return 18;
    case [_]:
      return 19;
    case bool _:
      return 20;
    case Map() when o.isEmpty:
      return 21;
    case {0: int _}:
      return 22;
    case {1: String _}:
      return 23;
    case {2: var a}:
      return 24;
    case {3: int b}:
      return 25;
    case (0, 1):
      return 26;
    case (a: 0, b: var c):
      return 27;
    case (c: 0, d: var d) when d is int:
      return 28;
    default:
      return 0;
  }
}

int switchExpression(o) {
  print('o = $o');
  return switch (o) {
    1 => 1,
    (f: (>=3) as int && (<5) as int) => 2,
    6 || 7 => 3,
    (g: 8 as int) => 4,
    (a: _!) => 5,
    (b: _?) => 6,
    [1, 2] => 7,
    [2, 3, ...] => 8,
    [3, 4, ..., 5] => 9,
    [4, 5, ...[(<1) as int, (>2) as int]] => 10,
    [5, 6, ...[(<1) as int, (>2) as int], 7] => 11,
    Class(field: 1) => 12,
    Class(finalField: 2) => 13,
    Class(field: 3, getter: 4) => 14,
    Class() => 15,
    == 'foo' => 16,
    (e: != 'bar') => 17,
    <int, int>{5: >= 16} => 18,
    [_] => 19,
    bool _ => 20,
    Map() when o.isEmpty => 21,
    {0: int _} => 22,
    {1: String _} => 23,
    {2: var a} => 24,
    {3: int b} => 25,
    (0, 1) => 26,
    (a: 0, b: var c) => 27,
    (c: 0, d: var d) when d is int => 28,
    _ => 0,
  };
}

test(expected, value) {
  expect(expected, ifCase(value));
  expect(expected, ifCaseElse(value));
  expect(expected, switchStatement(value));
  expect(expected, switchExpression(value));
}

main() {
  test(0, 0);

  test(1, 1);
  test(2, (f: 3));
  test(2, (f: 4));
  test(3, 6);
  test(3, 7);
  test(4, (g: 8));

  test(5, (a: 1));
  test(6, (b: 2));
  test(0, (b: null));

  test(0, [1, 3]);
  test(7, [1, 2]);
  test(8, [2, 3]);
  test(8, [2, 3, 4]);
  test(8, [2, 3, 4, 5]);
  test(9, [3, 4, 5]);
  test(9, [3, 4, 6, 5]);
  test(10, [4, 5, 0, 3]);
  test(11, [5, 6, 0, 3, 7]);

  test(12, new Class(1, 0));
  test(12, new Class(1, 1));
  test(12, new Class(1, 2));
  test(13, new Class(0, 2));
  test(13, new Class(2, 2));
  test(14, new Class(3, 4));
  test(15, new Class(3, 5));
  test(15, new Class(4, 5));

  test(16, 'foo');
  test(17, (e: 'baz'));
  test(0, (e: 'bar'));

  test(18, <int, int>{5: 16});
  test(18, <int, int>{5: 17});

  test(19, [true]);
  test(19, ['foo']);

  test(20, true);
  test(20, false);

  test(21, {});
  test(22, {0: 0});
  test(22, {0: 1});
  test(0, {0: 'foo'});
  test(23, {1: 'foo'});
  test(23, {1: 'foo', 2: 'bar'});
  test(0, {1: 0});
  test(24, {2: 'foo'});
  test(24, {2: 0});
  test(25, {3: 0});
  test(0, {3: 'foo'});

  test(26, (0, 1));
  test(27, (a: 0, b: 1));
  test(27, (a: 0, b: 'foo'));
  test(28, (c: 0, d: 1));
  test(28, (c: 0, d: 2));
  test(0, (c: 0, d: 'foo'));

  print('success');
}

expect(expected, actual) {
  print('$expected = $actual ?');
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
