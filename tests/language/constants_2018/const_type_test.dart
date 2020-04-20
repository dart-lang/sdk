// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that types do matter when an expression is evaluated as constant.

main() {
  const C c = C();
  const T.test01(c); //# 01: compile-time error
  const T.test02(c, c); //# 02: compile-time error
  const T.test03(c, c); //# 03: compile-time error
  const T.test04(c, c); //# 04: compile-time error
  const T.test05(c, c); //# 05: compile-time error
  const T.test06(c, c); //# 06: compile-time error
  const T.test07(c, c); //# 07: compile-time error
  const T.test08(c, c); //# 08: compile-time error
  const T.test09(c, c); //# 09: compile-time error
  const T.test10(c, c); //# 10: compile-time error
  const T.test11(c, c); //# 11: compile-time error
  const T.test12(c, c); //# 12: compile-time error
  const T.test13(c, c); //# 13: compile-time error
  const T.test14(c); //# 14: compile-time error
  const T.test15(c, c); //# 15: compile-time error
  const T.test16(c, c); //# 16: compile-time error
  const T.test17(c, c); //# 17: compile-time error
  const T.test18(c, c); //# 18: compile-time error
  const T.test19(c); //# 19: compile-time error

  const v01 = false ? c : -c; //# 20: compile-time error
  const v02 = false ? c : c + c; //# 21: compile-time error
  const v03 = false ? c : c - c; //# 22: compile-time error
  const v04 = false ? c : c * c; //# 23: compile-time error
  const v05 = false ? c : c / c; //# 24: compile-time error
  const v06 = false ? c : c ~/ c; //# 25: compile-time error
  const v07 = false ? c : c % c; //# 26: compile-time error
  const v08 = false ? c : c << c; //# 27: compile-time error
  const v09 = false ? c : c >> c; //# 28: compile-time error
  const v10 = false ? c : c >>> c; //# 29: compile-time error
  const v11 = false ? c : c & c; //# 30: compile-time error
  const v12 = false ? c : c | c; //# 31: compile-time error
  const v13 = false ? c : c ^ c; //# 32: compile-time error
  const v14 = false ? c : ~c; //# 33: compile-time error
  const v15 = false ? c : c < c; //# 34: compile-time error
  const v16 = false ? c : c > c; //# 35: compile-time error
  const v17 = false ? c : c <= c; //# 36: compile-time error
  const v18 = false ? c : c >= c; //# 37: compile-time error
  const v19 = false ? c : c.length; //# 38: compile-time error
}

// Each expression in the forwarding generative constructors must be
// potentially constant. They are only checked for being actually
// constant when the constructor is invoked.
class T {
  const T(C o);
  const T.test01(C x) : this(-x);
  const T.test02(C x, C y) : this(x + y);
  const T.test03(C x, C y) : this(x - y);
  const T.test04(C x, C y) : this(x * y);
  const T.test05(C x, C y) : this(x / y);
  const T.test06(C x, C y) : this(x ~/ y);
  const T.test07(C x, C y) : this(x % y);
  const T.test08(C x, C y) : this(x << y);
  const T.test09(C x, C y) : this(x >> y);
  const T.test10(C x, C y) : this(x >>> y); //# 10: continued
  const T.test11(C x, C y) : this(x & y);
  const T.test12(C x, C y) : this(x | y);
  const T.test13(C x, C y) : this(x ^ y);
  const T.test14(C x) : this(~x);
  const T.test15(C x, C y) : this(x < y);
  const T.test16(C x, C y) : this(x > y);
  const T.test17(C x, C y) : this(x <= y);
  const T.test18(C x, C y) : this(x >= y);
  const T.test19(C x) : this(x.length);
}

class C {
  const C();
  C operator -() => this;
  C operator +(C other) => this;
  C operator -(C other) => this;
  C operator *(C other) => this;
  C operator /(C other) => this;
  C operator ~/(C other) => this;
  C operator %(C other) => this;
  C operator <<(C other) => this;
  C operator >>(C other) => this;
  // Remove the multi-test markers and one of the lines below,
  // when `>>>` is implemented.
  C operator >>>(C other) => this;  //# 10: continued
  C operator >>>(C other) => this;  //# 29: continued
  C operator &(C other) => this;
  C operator |(C other) => this;
  C operator ^(C other) => this;
  C operator ~() => this;
  C operator <(C other) => this;
  C operator >(C other) => this;
  C operator <=(C other) => this;
  C operator >=(C other) => this;
  C get length => this;
}