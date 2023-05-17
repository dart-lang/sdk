// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that switch statement with non-integer expression and
// int case constants is handled correctly.
// Regression test for https://github.com/dart-lang/sdk/issues/52214.

import 'package:expect/expect.dart';

String test1() {
  num switcher = 3.0;
  switch (switcher) {
    case 3:
      return 'in case(3)';
    default:
      return 'in default';
  }
}

String test2(Object switcher) {
  switch (switcher) {
    case 3:
      return 'in case(3)';
    default:
      return 'in default';
  }
}

String test3(dynamic switcher) {
  switch (switcher) {
    case 3:
      return 'in case(3)';
    default:
      return 'in default';
  }
}

String test4(switcher) {
  switch (switcher) {
    case 1:
      return 'in case(1)';
    case 2:
      return 'in case(2)';
    case 3:
      return 'in case(3)';
    case 4:
      return 'in case(4)';
    case 5:
      return 'in case(5)';
    case 6:
      return 'in case(6)';
    case 7:
      return 'in case(7)';
    case 8:
      return 'in case(8)';
    case 9:
      return 'in case(9)';
    case 10:
      return 'in case(10)';
    case 11:
      return 'in case(11)';
    case 12:
      return 'in case(12)';
    case 13:
      return 'in case(13)';
    case 14:
      return 'in case(14)';
    case 15:
      return 'in case(15)';
    case 16:
      return 'in case(16)';
    default:
      return 'in default';
  }
}

void main() {
  Expect.equals('in case(3)', test1());
  Expect.equals('in case(3)', test2(3.0));
  Expect.equals('in case(3)', test3(3.0));
  Expect.equals('in case(5)', test4(5.0));
  Expect.equals('in case(7)', test4(7.0));
  Expect.equals('in default', test4(0.0));
}
