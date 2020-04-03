// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 0) {
    return confuse(x + 1);
  } else if (new DateTime.now().millisecondsSinceEpoch == 0) {
    return confuse(x - 1);
  }
  return x;
}

test1() {
  int x = 0;
  // Give x a range of -1 to 0.
  if (confuse(0) == 1) x = -1;

  int y = 0;
  // Give y a range of 0 to 1.
  if (confuse(0) == 1) y = 1;

  var zero = 0;

  var status = "bad";
  if (x < zero) {
    Expect.fail("unreachable");
  } else {
    // Dart2js must not conclude that zero has a range of [-1, 0].
    if (y <= zero) {
      status = "good";
    }
  }
  Expect.equals("good", status);
}

test2() {
  int x = 0;
  // Give x a range of -1 to 0.
  if (confuse(0) == 1) x = -1;

  int y = 0;
  // Give y a range of -1 to 1.
  if (confuse(0) == 1) y = 1;
  if (confuse(1) == 2) y = -1;

  var status = "good";
  if (x < y) {
    Expect.fail("unreachable");
  } else {
    // Dart2js must not conclude that y has a range of [-1, -1].
    if (y == -1) {
      status = "bad";
    }
  }
  Expect.equals("good", status);
}

test3a() {
  int x = 0;
  // Give x a range of -1 to 1.
  if (confuse(0) == 1) x = -1;
  if (confuse(1) == 2) x = 1;

  int y = 0;
  // Give y a range of -1 to 1.
  if (confuse(0) == 1) y = 1;
  if (confuse(1) == 2) y = -1;

  var status = "good";
  if (x < y) {
    Expect.fail("unreachable");
  } else {
    // Test that the range-analysis does not lose a value.
    if (x <= -1) status = "bad";
    if (x >= 1) status = "bad";
    if (x < 0) status = "bad";
    if (x > 0) status = "bad";
    if (-1 >= x) status = "bad";
    if (1 <= x) status = "bad";
    if (0 > x) status = "bad";
    if (0 < x) status = "bad";
    if (y <= -1) status = "bad";
    if (y >= 1) status = "bad";
    if (y < 0) status = "bad";
    if (y > 0) status = "bad";
    if (-1 >= y) status = "bad";
    if (1 <= y) status = "bad";
    if (0 > y) status = "bad";
    if (0 < y) status = "bad";
  }
  Expect.equals("good", status);
}

test3b() {
  int x = 0;
  // Give x a range of -2 to 0.
  if (confuse(0) == 1) x = -2;

  int y = 0;
  // Give y a range of -1 to 1.
  if (confuse(0) == 1) y = 1;
  if (confuse(1) == 2) y = -1;

  var status = "good";
  if (x < y) {
    Expect.fail("unreachable");
  } else {
    // Test that the range-analysis does not lose a value.
    if (x <= -1) status = "bad";
    if (x >= 1) status = "bad";
    if (x < 0) status = "bad";
    if (x > 0) status = "bad";
    if (-1 >= x) status = "bad";
    if (1 <= x) status = "bad";
    if (0 > x) status = "bad";
    if (0 < x) status = "bad";
    if (y <= -1) status = "bad";
    if (y >= 1) status = "bad";
    if (y < 0) status = "bad";
    if (y > 0) status = "bad";
    if (-1 >= y) status = "bad";
    if (1 <= y) status = "bad";
    if (0 > y) status = "bad";
    if (0 < y) status = "bad";
  }
  Expect.equals("good", status);
}

test4a() {
  int x = -1;
  // Give x a range of -1 to 1.
  if (confuse(0) == 1) x = 1;

  int y = 0;
  // Give y a range of -1 to 1.
  if (confuse(0) == 1) y = 1;
  if (confuse(1) == 2) y = -1;

  var status = "good";
  if (x < y) {
    // Test that the range-analysis does not lose a value.
    if (x <= -2) status = "bad";
    if (x >= 0) status = "bad";
    if (x < -1) status = "bad";
    if (x > -1) status = "bad";
    if (-2 >= x) status = "bad";
    if (0 <= x) status = "bad";
    if (-1 > x) status = "bad";
    if (-1 < x) status = "bad";
    if (y <= -1) status = "bad";
    if (y >= 1) status = "bad";
    if (y < 0) status = "bad";
    if (y > 0) status = "bad";
    if (-1 >= y) status = "bad";
    if (1 <= y) status = "bad";
    if (0 > y) status = "bad";
    if (0 < y) status = "bad";
  } else {
    Expect.fail("unreachable");
  }
  Expect.equals("good", status);
}

test4b() {
  int x = -1;
  // Give x a range of -2 to 0.
  if (confuse(0) == 1) x = -2;
  if (confuse(1) == 2) x = 0;

  int y = 0;
  // Give y a range of -1 to 1.
  if (confuse(0) == 1) y = 1;
  if (confuse(1) == 2) y = -1;

  var status = "good";
  if (x < y) {
    // Test that the range-analysis does not lose a value.
    if (x <= -2) status = "bad";
    if (x >= 0) status = "bad";
    if (x < -1) status = "bad";
    if (x > -1) status = "bad";
    if (-2 >= x) status = "bad";
    if (0 <= x) status = "bad";
    if (-1 > x) status = "bad";
    if (-1 < x) status = "bad";
    if (y <= -1) status = "bad";
    if (y >= 1) status = "bad";
    if (y < 0) status = "bad";
    if (y > 0) status = "bad";
    if (-1 >= y) status = "bad";
    if (1 <= y) status = "bad";
    if (0 > y) status = "bad";
    if (0 < y) status = "bad";
  } else {
    Expect.fail("unreachable");
  }
  Expect.equals("good", status);
}

main() {
  test1();
  test2();
  test3a();
  test3b();
  test4a();
  test4b();
}
