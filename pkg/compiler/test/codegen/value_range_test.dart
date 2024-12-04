// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

enum _Result {
  removed,
  aboveZero,
  belowLength,
  kept,
  oneCheck,
  oneZeroCheck,
  belowZeroCheck,
}

final List<(String, _Result)> tests = [
  (
    """
@pragma('dart2js:assumeDynamic')
test(check) {
  check as bool;
  var a = check ? [1] : [1, 2];
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = [1, 2];
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.aboveZero
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(check) {
  check as bool;
  // Make sure value is an int.
  var value = check ? 42 : 54;
  var a = List.filled(value, 1);
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
test() {
  var a = [];
  return a[0];
}
""",
    _Result.kept
  ),
  (
    """
test() {
  var a = [];
  return a.removeLast();
}
""",
    _Result.kept
  ),
  (
    """
test() {
  var a = List.filled(4, null);
  return a[0];
}
""",
    _Result.removed
  ),
  (
    """
test() {
  var a = List.filled(4, null);
  return a.removeLast();
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(value, null);
  return a[value];
}
""",
    _Result.kept
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(1024, null);
  return a[1023 & value];
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(1024, null);
  return a[1024 & value];
}
""",
    _Result.aboveZero
  ),
  (
    """
test() {
  var a = [];
  return a[1];
}
""",
    _Result.aboveZero
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value, call) {
  value as int;
  call as int Function();
  var a = [];
  return a[value] + call() + a[value];
}
""",
    _Result.oneZeroCheck
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as bool;
  var a = value ? [1, 2, 3] : [];
  return a[1] + a[0];
}
""",
    _Result.oneCheck
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(n) {
  n as int;
  var a = List.filled(n, 1);
  var sum = 0;
  for (int i = 0; i <= a.length - 1; i++) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(n) {
  n as int;
  var a = List.filled(n, 1);
  var sum = 0;
  for (int i = a.length - 1; i >= 0; i--) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(dynamic value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = [];
  if (value > a.length - 1) return;
  if (value < 0) return;
  return a[value];
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = [];
  if (value <= a.length - 1) {
    if (value >= 0) {
      return a[value];
    }
  }
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = [];
  if (value >= a.length) return;
  if (value <= -1) return;
  return a[value];
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(value, 1);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i++;
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List<dynamic>.filled(value, null);
  num sum = 0;
  for (int i = a.length - 1; i >= 0; i--) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(6, value);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
    _Result.removed
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(7, value);
  var sum = 0;
  for (int i = 0; i < a.length;) {
    sum += a[i];
    sum == 0 ? i-- : i++;
  }
  return sum;
}
""",
    _Result.belowZeroCheck
  ),
  (
    """
@pragma('dart2js:assumeDynamic')
test(value) {
  value as int;
  var a = List.filled(7, value);
  var sum = 0;
  for (int i = -2; i < a.length; i = 0) {
    sum += a[i];
  }
  return sum;
}
""",
    _Result.belowZeroCheck
  ),
];

Future expect(String code, _Result kind) {
  return compile(code, entry: 'test', disableTypeInference: false,
      check: (String generated) {
    switch (kind) {
      case _Result.removed:
        Expect.isFalse(generated.contains('ioore'));
        break;

      case _Result.aboveZero:
        Expect.isFalse(generated.contains('< 0') || generated.contains('>= 0'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case _Result.belowZeroCheck:
        // May generate `!(ix < 0)` or `ix >= 0` depending if `ix` can be NaN
        Expect.isTrue(generated.contains('< 0') || generated.contains('>= 0'));
        Expect.isFalse(generated.contains('||') || generated.contains('&&'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case _Result.belowLength:
        Expect.isFalse(generated.contains('||') || generated.contains('&&'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case _Result.kept:
        Expect.isTrue(generated.contains('ioore'));
        break;

      case _Result.oneCheck:
        RegExp regexp = RegExp('ioore');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;

      case _Result.oneZeroCheck:
        RegExp regexp = RegExp('< 0|>>> 0 !==');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;
    }
  });
}

runTests() async {
  for (final (input, expected) in tests) {
    await expect(input, expected);
  }
}

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
