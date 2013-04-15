// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct source positions in stack trace with optimized functions.
import "package:expect/expect.dart";

// (1) Test normal exception.
foo(x) => bar(x);

bar(x) {
  if (x == null) throw 42;  // throw at position 11:18
  return x + 1;
}

test1() {
  // First unoptimized.
  try {
    foo(null);
    Expect.fail("Unreachable");
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    Expect.isFalse(s.contains("-1:-1"));
    Expect.isTrue(s.contains("11:18"));
  }

  // Optimized.
  for (var i=0; i<10000; i++) foo(42);
  try {
    foo(null);
    Expect.fail("Unreachable");
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    Expect.isFalse(s.contains("-1:-1"));
    Expect.isTrue(s.contains("11:18"));
  }
}


// (2) Test checked mode exceptions.
maximus(x) => moritz(x);

moritz(x) {
  if (x == 333)  return 42 ? 0 : 1;  // Throws in checked mode.
  if (x == 777)   {
    bool b = x;  // Throws in checked mode.
    return b;
  }

  return x + 1;
}

test2() {
  for (var i=0; i<100000; i++) maximus(42);
  try {
    maximus(333);
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isTrue(s.contains("maximus"));
    Expect.isTrue(s.contains("moritz"));
    Expect.isFalse(s.contains("-1:-1"));
  }

  try {
    maximus(777);
  } catch (e, stacktrace) {
    String s = stacktrace.toString();
    print(s);
    Expect.isTrue(s.contains("maximus"));
    Expect.isTrue(s.contains("moritz"));
    Expect.isFalse(s.contains("-1:-1"));
  }
}

main() {
  test1();
  test2();
}
