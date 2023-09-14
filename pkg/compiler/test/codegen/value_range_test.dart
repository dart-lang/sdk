// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const int REMOVED = 0;
const int ABOVE_ZERO = 1;
const int BELOW_LENGTH = 2;
const int KEPT = 3;
const int ONE_CHECK = 4;
const int ONE_ZERO_CHECK = 5;
const int BELOW_ZERO_CHECK = 6;

final List TESTS = [
  """
main(bool check) {
  var a = check ? [1] : [1, 2];
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
  }
  return sum;
}
""",
  REMOVED,
  """
main(int value) {
  var a = [1, 2];
  var sum = 0;
  for (int i = 0; i < value; i++) {
    sum += a[i];
  }
  return sum;
}
""",
  ABOVE_ZERO,
  """
main(bool check) {
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
  REMOVED,
  """
main() {
  var a = [];
  return a[0];
}
""",
  KEPT,
  """
main() {
  var a = [];
  return a.removeLast();
}
""",
  KEPT,
  """
main() {
  var a = List.filled(4, null);
  return a[0];
}
""",
  REMOVED,
  """
main() {
  var a = List.filled(4, null);
  return a.removeLast();
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(value, null);
  return a[value];
}
""",
  KEPT,
  """
main(int value) {
  var a = List.filled(1024, null);
  return a[1023 & value];
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(1024, null);
  return a[1024 & value];
}
""",
  ABOVE_ZERO,
  """
main() {
  var a = [];
  return a[1];
}
""",
  ABOVE_ZERO,
  """
main(int value, int Function() call) {
  var a = [];
  return a[value] + call() + a[value];
}
""",
  ONE_ZERO_CHECK,
  """
main(bool value) {
  var a = value ? [1, 2, 3] : [];
  return a[1] + a[0];
}
""",
  ONE_CHECK,
  """
main(int n) {
  var a = List.filled(n, 1);
  var sum = 0;
  for (int i = 0; i <= a.length - 1; i++) {
    sum += a[i];
  }
  return sum;
}
""",
  REMOVED,
  """
main(int n) {
  var a = List.filled(n, 1);
  var sum = 0;
  for (int i = a.length - 1; i >= 0; i--) {
    sum += a[i];
  }
  return sum;
}
""",
  REMOVED,
  """
main(dynamic value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = [];
  if (value > a.length - 1) return;
  if (value < 0) return;
  return a[value];
}
""",
  REMOVED,
  """
main(value) {
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
  REMOVED,
  """
main(value) {
  value = value is int ? value as int : 42;
  int sum = ~value;
  for (int i = 0; i < 42; i++) sum += (value & 4);
  var a = [];
  if (value >= a.length) return;
  if (value <= -1) return;
  return a[value];
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(value, 1);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i++;
  }
  return sum;
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(value, null);
  var sum = 0;
  for (int i = a.length - 1; i >= 0; i--) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(6, value);
  var sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += a[i];
    if (sum == 0) i--;
  }
  return sum;
}
""",
  REMOVED,
  """
main(int value) {
  var a = List.filled(7, value);
  var sum = 0;
  for (int i = 0; i < a.length;) {
    sum += a[i];
    sum == 0 ? i-- : i++;
  }
  return sum;
}
""",
  BELOW_ZERO_CHECK,
  """
main(int value) {
  var a = List.filled(7, value);
  var sum = 0;
  for (int i = -2; i < a.length; i = 0) {
    sum += a[i];
  }
  return sum;
}
""",
  BELOW_ZERO_CHECK,
];

Future expect(String code, int kind) {
  return compile(code, disableTypeInference: false, check: (String generated) {
    switch (kind) {
      case REMOVED:
        Expect.isFalse(generated.contains('ioore'));
        break;

      case ABOVE_ZERO:
        Expect.isFalse(generated.contains('< 0') || generated.contains('>= 0'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case BELOW_ZERO_CHECK:
        // May generate `!(ix < 0)` or `ix >= 0` depending if `ix` can be NaN
        Expect.isTrue(generated.contains('< 0') || generated.contains('>= 0'));
        Expect.isFalse(generated.contains('||') || generated.contains('&&'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case BELOW_LENGTH:
        Expect.isFalse(generated.contains('||') || generated.contains('&&'));
        Expect.isTrue(generated.contains('ioore'));
        break;

      case KEPT:
        Expect.isTrue(generated.contains('ioore'));
        break;

      case ONE_CHECK:
        RegExp regexp = RegExp('ioore');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;

      case ONE_ZERO_CHECK:
        RegExp regexp = RegExp('< 0|>>> 0 !==');
        Iterator matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
        break;
    }
  });
}

runTests() async {
  for (int i = 0; i < TESTS.length; i += 2) {
    await expect(TESTS[i], TESTS[i + 1]);
  }
}

main() {
  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
