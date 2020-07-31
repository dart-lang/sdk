// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct source positions in stack trace with optimized functions.
import "package:expect/expect.dart";

// (1) Test normal exception.
foo(x) => bar(x);

bar(x) {
  if (x == null) throw 42; // throw at position 11:18
  return x + 1;
}

test1() {
  // First unoptimized.
  try {
    foo(null);
    Expect.fail("Unreachable");
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isFalse(s.contains("-1:-1"), "A");
    RegExp regex =
        new RegExp("optimized_stacktrace_line_test(_none|_01)*\.dart:11");
    Expect.isTrue(regex.hasMatch(s), "B");
  }

  // Optimized.
  for (var i = 0; i < 10000; i++) foo(42);
  try {
    foo(null);
    Expect.fail("Unreachable");
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isFalse(s.contains("-1:-1"), "C");
    RegExp regex =
        new RegExp("optimized_stacktrace_line_test(_none|_01)*\.dart:11");
    Expect.isTrue(regex.hasMatch(s), "D");
  }
}

// (2) Test checked mode exceptions.
maximus(x) => moritz(x);

moritz(x) {
  if (x == 333) return (42 as bool) ? 0 : 1;
  if (x == 777) {
    bool b = x;
    return b;
  }

  return x + 1;
}

test2() {
  for (var i = 0; i < 100000; i++) maximus(42);
  try {
    maximus(333);
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isTrue(s.contains("maximus"), "E");
    Expect.isTrue(s.contains("moritz"), "F");
    Expect.isFalse(s.contains("-1:-1"), "G");
  }

  try {
    maximus(777);
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isTrue(s.contains("maximus"), "H");
    Expect.isTrue(s.contains("moritz"), "I");
    Expect.isFalse(s.contains("-1:-1"), "J");
  }
}

main() {
  test1();
  test2();
}
