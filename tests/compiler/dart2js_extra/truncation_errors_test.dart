// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that exception messages for truncating operations contains the
// operands.

import 'package:expect/expect.dart';

@NoInline()
@AssumeDynamic()
confuse(x) => x;

void find1(expected, thunk) {
  if (thunk == null) return;
  var returned, exceptionText;
  try {
    returned = thunk();
  } catch (e) {
    exceptionText = '$e';
  }
  if (exceptionText == null) {
    Expect
        .fail('Expected exception containing "$expected", returned: $returned');
  }
  Expect.isTrue(exceptionText.contains(expected),
      'Expected "$expected" in "$exceptionText"');
}

void find(expected, [thunk1, thunk2, thunk3, thunk4]) {
  find1(expected, thunk1);
  find1(expected, thunk2);
  find1(expected, thunk3);
  find1(expected, thunk4);
}

main() {
  var NaN = double.NAN;
  var Infinity = double.INFINITY;

  find(' Infinity: 123 ~/ 0', () => confuse(123) ~/ confuse(0),
      () => confuse(123) ~/ 0, () => 123 ~/ confuse(0), () => 123 ~/ 0);

  find(
      '-Infinity: 123 ~/ -0.0',
      () => confuse(123) ~/ confuse(-0.0),
      () => confuse(123) ~/ -0.0,
      () => 123 ~/ confuse(-0.0),
      () => 123 ~/ -0.0);

  find(' NaN: NaN ~/ 123', () => confuse(NaN) ~/ confuse(123),
      () => confuse(NaN) ~/ 123, () => NaN ~/ confuse(123), () => NaN ~/ 123);

  find(
      ' Infinity: 1e+200 ~/ 1e-200',
      () => confuse(1e200) ~/ confuse(1e-200),
      () => confuse(1e200) ~/ 1e-200,
      () => 1e200 ~/ confuse(1e-200),
      () => 1e200 ~/ 1e-200);

  find('NaN.toInt()', () => confuse(NaN).toInt(), () => NaN.toInt());
  find(' Infinity.toInt()', () => confuse(Infinity).toInt(),
      () => Infinity.toInt());
  find('-Infinity.toInt()', () => confuse(-Infinity).toInt(),
      () => (-Infinity).toInt());

  find('NaN.ceil()', () => confuse(NaN).ceil(), () => NaN.ceil());
  find(' Infinity.ceil()', () => confuse(Infinity).ceil(),
      () => Infinity.ceil());
  find('-Infinity.ceil()', () => confuse(-Infinity).ceil(),
      () => (-Infinity).ceil());

  find('NaN.floor()', () => confuse(NaN).floor(), () => NaN.floor());
  find(' Infinity.floor()', () => confuse(Infinity).floor(),
      () => Infinity.floor());
  find('-Infinity.floor()', () => confuse(-Infinity).floor(),
      () => (-Infinity).floor());

  find('NaN.round()', () => confuse(NaN).round(), () => NaN.round());
  find(' Infinity.round()', () => confuse(Infinity).round(),
      () => Infinity.round());
  find('-Infinity.round()', () => confuse(-Infinity).round(),
      () => (-Infinity).round());

  // `truncate()` is the same as `toInt()`.
  // We could change the runtime so that `truncate` is reported.
  find('NaN.toInt()', () => confuse(NaN).truncate(), () => NaN.truncate());
  find(' Infinity.toInt()', () => confuse(Infinity).truncate(),
      () => Infinity.truncate());
  find('-Infinity.toInt()', () => confuse(-Infinity).truncate(),
      () => (-Infinity).truncate());
}
