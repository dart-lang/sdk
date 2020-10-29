// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that types do not affect whether an expression is potentially
// constant, they only matter if the expression is evaluated as a constant.

main() {
  const C c = C();
  T.test01(c);
  T.test02(c, c);
  T.test03(c, c);
  T.test04(c, c);
  T.test05(c, c);
  T.test06(c, c);
  T.test07(c, c);
  T.test08(c, c);
  T.test09(c, c);
  T.test10(c, c); //# sh3: ok
  T.test11(c, c);
  T.test12(c, c);
  T.test13(c, c);
  T.test14(c);
  T.test15(c, c);
  T.test16(c, c);
  T.test17(c, c);
  T.test18(c, c);
  T.test19(c);

  const v01 = true ? c : -c;
  const v02 = true ? c : c + c;
  const v03 = true ? c : c - c;
  const v04 = true ? c : c * c;
  const v05 = true ? c : c / c;
  const v06 = true ? c : c ~/ c;
  const v07 = true ? c : c % c;
  const v08 = true ? c : c << c;
  const v09 = true ? c : c >> c;
  const v10 = true ? c : c >>> c; //# sh3: continued
  const v11 = true ? c : c & c;
  const v12 = true ? c : c | c;
  const v13 = true ? c : c ^ c;
  const v14 = true ? c : ~c;
  const v15 = true ? c : c < c;
  const v16 = true ? c : c > c;
  const v17 = true ? c : c <= c;
  const v18 = true ? c : c >= c;
  const v19 = true ? c : c.length;
}

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
  const T.test10(C x, C y) : this(x >>> y); //# sh3: continued
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
  C operator >>>(C other) => this; //# sh3: continued
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
