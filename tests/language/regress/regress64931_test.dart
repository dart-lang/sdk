// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64931 and
// https://github.com/dart-lang/sdk/issues/64898:
// Switching on `num`, `num?`, or `Object` with `int`, `bool`, or `String`
// cases must not assume the scrutinee has the narrowed case type.

import 'package:expect/expect.dart';

String switchNumIntCases(num score) {
  switch (score) {
    case 0:
      return 'zero';
    case 1:
      return 'one';
    default:
      return 'other';
  }
}

String switchNullableNumIntCases(num? score) {
  switch (score) {
    case null:
      return 'none';
    case 0:
      return 'zero';
    case 1:
      return 'one';
    default:
      return 'other';
  }
}

String switchObjectIntCases(Object obj) {
  switch (obj) {
    case 0:
      return 'zero';
    case 1:
      return 'one';
    default:
      return 'other';
  }
}

String switchObjectBoolCases(Object obj) {
  switch (obj) {
    case true:
      return 'true';
    default:
      return 'other';
  }
}

String switchObjectStringCases(Object obj) {
  switch (obj) {
    case 'a':
      return 'a';
    default:
      return 'other';
  }
}

final List<double> doubles = [0.0, -0.0, 1.0, 1.5, double.nan];

void main() {
  // Scrutinee statically `num` / `num?`, runtime values all `double` (`f64`).
  Expect.equals('zero', switchNumIntCases(doubles[0]));
  Expect.equals('zero', switchNumIntCases(doubles[1]));
  Expect.equals('one', switchNumIntCases(doubles[2]));
  Expect.equals('other', switchNumIntCases(doubles[3]));
  Expect.equals('other', switchNumIntCases(doubles[4]));

  Expect.equals('none', switchNullableNumIntCases(null));
  Expect.equals('zero', switchNullableNumIntCases(doubles[0]));
  Expect.equals('zero', switchNullableNumIntCases(doubles[1]));
  Expect.equals('one', switchNullableNumIntCases(doubles[2]));
  Expect.equals('other', switchNullableNumIntCases(doubles[3]));
  Expect.equals('other', switchNullableNumIntCases(doubles[4]));

  // Scrutinee statically `Object` with int/bool/String-only cases.
  final List<Object> objects = [
    0,
    1,
    0.0,
    -0.0,
    1.0,
    1.5,
    true,
    false,
    'a',
    'b',
    Object(),
  ];
  for (final obj in objects) {
    final expectedInt = obj == 0
        ? 'zero'
        : obj == 1
        ? 'one'
        : 'other';
    Expect.equals(expectedInt, switchObjectIntCases(obj));
    Expect.equals(obj == true ? 'true' : 'other', switchObjectBoolCases(obj));
    Expect.equals(obj == 'a' ? 'a' : 'other', switchObjectStringCases(obj));
  }
}
