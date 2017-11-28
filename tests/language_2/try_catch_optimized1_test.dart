// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

maythrow(x) {
  if (x == null) throw 42;
  return 99;
}

f1(x) {
  var result = 123;
  try {
    result = maythrow(x);
    if (result > 100) throw 42;
  } catch (e) {
    Expect.equals(result, 123);
    Expect.equals(42, e);
    result = 0;
  }
  return result;
}

class A {
  maythrow(x) {
    if (x == null) throw 42;
    return 99;
  }
}

f2(x) {
  var result = 123;
  var a = new A();
  try {
    result++;
    result = a.maythrow(x);
  } catch (e) {
    Expect.equals(124, result);
    result = x;
  }
  return result;
}

f3(x, y) {
  var result = 123;
  var a = new A();
  try {
    result++;
    result = a.maythrow(x);
  } catch (e) {
    result = y + 1; // Deopt on overflow
  }
  return result;
}

f4(x) {
  try {
    maythrow(x);
  } catch (e) {
    check_f4(e, "abc");
  }
}

check_f4(e, s) {
  if (e != 42) throw "ERROR";
  if (s != "abc") throw "ERROR";
}

f5(x) {
  try {
    maythrow(x);
  } catch (e) {
    check_f5(e, "abc");
  }

  try {
    maythrow(x);
  } catch (e) {
    check_f5(e, "abc");
  }
}

check_f5(e, s) {
  if (e != 42) throw "ERROR";
  if (s != "abc") throw "ERROR";
}

f6(x, y) {
  var a = x;
  var b = y;
  var c = 123;
  check_f6(42, null, 1, 123, null, 1);
  try {
    maythrow(x);
  } catch (e) {
    check_f6(e, a, b, c, x, y);
  }
}

check_f6(e, a, b, c, x, y) {
  if (e != 42) throw "ERROR";
  if (a != null) throw "ERROR";
  if (b != 1) throw "ERROR";
  if (c != 123) throw "ERROR";
  if (x != null) throw "ERROR";
  if (y != 1) throw "ERROR";
}

bool f7(String str) {
  double d = double.parse(str);
  var t = d;
  try {
    var a = d.toInt();
    return false;
  } on UnsupportedError catch (e) {
    Expect.equals(true, identical(t, d));
    return true;
  }
}

f8(x, [a = 3, b = 4]) {
  var c = 123;
  var y = a;
  try {
    maythrow(x);
  } catch (e, s) {
    check_f8(e, s, a, b, c, x, y);
  }
}

check_f8(e, s, a, b, c, x, y) {
  if (e != 42) throw "ERROR";
  if (s is! StackTrace) throw "ERROR";
  if (a != 3) {
    print(a);
    throw "ERROR";
  }
  if (b != 4) throw "ERROR";
  if (c != 123) throw "ERROR";
  if (x != null) throw "ERROR";
  if (y != a) throw "ERROR";
}

f9(x, [a = 3, b = 4]) {
  var c = 123;
  var y = a;
  try {
    if (x < a) maythrow(null);
    maythrow(x);
  } catch (e, s) {
    check_f9(e, s, a, b, c, x, y);
  }
}

check_f9(e, s, a, b, c, x, y) {
  if (e != 42) throw "ERROR";
  if (s is! StackTrace) throw "ERROR";
  if (a != 3) {
    print(a);
    throw "ERROR";
  }
  if (b != 4) throw "ERROR";
  if (c != 123) throw "ERROR";
  if (x != null) throw "ERROR";
  if (y != a) throw "ERROR";
}

f10(x, y) {
  var result = 123;
  try {
    result = maythrow(x);
  } catch (e) {
    Expect.equals(123, result);
    Expect.equals(0.5, y / 2.0);
    result = 0;
  }
  return result;
}

f11(x) {
  var result = 123;
  var tmp = x;
  try {
    result = maythrow(x);
    if (result > 100) throw 42;
  } catch (e, s) {
    Expect.equals(123, result);
    Expect.equals(true, identical(tmp, x));
    Expect.equals(true, s is StackTrace);
    result = 0;
  }
  return result;
}

f12([x = null]) {
  try {
    maythrow(x);
  } catch (e) {
    check_f12(e, x);
  }
}

check_f12(e, x) {
  if (e != 42) throw "ERROR";
  if (x != null) throw "ERROR";
}

f13(x) {
  var result = 123;
  try {
    try {
      result = maythrow(x);
      if (result > 100) throw 42;
    } catch (e) {
      Expect.equals(123, result);
      result = 0;
    }
    maythrow(x);
  } catch (e) {
    result++;
  }
  return result;
}

main() {
  for (var i = 0; i < 20; i++) f1("abc");
  Expect.equals(99, f1("abc"));
  Expect.equals(0, f1(null));

  for (var i = 0; i < 20; i++) f2("abc");
  Expect.equals(99, f2("abc"));
  Expect.equals(null, f2(null));

  f3("123", 0);
  for (var i = 0; i < 20; i++) f3(null, 0);
  Expect.equals(99, f3("123", 0));
  Expect.equals(0x40000000, f3(null, 0x3fffffff));

  f4(null);
  for (var i = 0; i < 20; i++) f4(123);
  f4(null);

  f5(null);
  for (var i = 0; i < 20; i++) f5(123);
  f5(null);

  f6(null, 1);
  for (var i = 0; i < 20; i++) f6(123, 1);
  f6(null, 1);

  f7("1.2");
  f7("Infinity");
  f7("-Infinity");
  for (var i = 0; i < 20; i++) f7("1.2");
  Expect.equals(false, f7("1.2"));
  Expect.equals(true, f7("Infinity"));
  Expect.equals(true, f7("-Infinity"));
  Expect.equals(false, f7("123456789012345")); // Deopt.
  for (var i = 0; i < 20; i++) f7("123456789012345");
  Expect.equals(true, f7("Infinity"));
  Expect.equals(true, f7("-Infinity"));

  for (var i = 0; i < 20; i++) f8(null);
  f8(null);

  f9(5);
  f9(5.0);
  for (var i = 0; i < 20; i++) f9(3);
  f9(3);

  var y = 1.0;
  Expect.equals(0, f10(null, y));
  for (var i = 0; i < 20; i++) f10("abc", y);
  Expect.equals(99, f10("abc", y));
  Expect.equals(0, f10(null, y));

  for (var i = 0; i < 20; i++) f11("abc");
  Expect.equals(99, f11("abc"));
  Expect.equals(0, f11(null));

  for (var i = 0; i < 20; i++) f12(null);
  f12(null);

  f13(null);
  for (var i = 0; i < 20; i++) f13("abc");
  Expect.equals(99, f13("abc"));
  Expect.equals(1, f13(null));
}
