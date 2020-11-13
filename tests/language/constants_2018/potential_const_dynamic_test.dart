// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a dynamic type does not affect whether an expression is
// potentially constant, the actual type of the value of an experssion
// only matters if the expression is evaluated as a constant.

main() {
  Object c = C();
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
}

class T {
  const T(Object o);
  const T.test01(dynamic x) : this(-x);
  const T.test02(dynamic x, dynamic y) : this(x + y);
  const T.test03(dynamic x, dynamic y) : this(x - y);
  const T.test04(dynamic x, dynamic y) : this(x * y);
  const T.test05(dynamic x, dynamic y) : this(x / y);
  const T.test06(dynamic x, dynamic y) : this(x ~/ y);
  const T.test07(dynamic x, dynamic y) : this(x % y);
  const T.test08(dynamic x, dynamic y) : this(x << y);
  const T.test09(dynamic x, dynamic y) : this(x >> y);
  const T.test10(dynamic x, dynamic y) : this(x >>> y); //# sh3: continued
  const T.test11(dynamic x, dynamic y) : this(x & y);
  const T.test12(dynamic x, dynamic y) : this(x | y);
  const T.test13(dynamic x, dynamic y) : this(x ^ y);
  const T.test14(dynamic x) : this(~x);
  const T.test15(dynamic x, dynamic y) : this(x < y);
  const T.test16(dynamic x, dynamic y) : this(x > y);
  const T.test17(dynamic x, dynamic y) : this(x <= y);
  const T.test18(dynamic x, dynamic y) : this(x >= y);
  const T.test19(dynamic x) : this(x.length);
}

class C {
  const C();
  dynamic operator -() => this;
  dynamic operator +(dynamic other) => this;
  dynamic operator -(dynamic other) => this;
  dynamic operator *(dynamic other) => this;
  dynamic operator /(dynamic other) => this;
  dynamic operator ~/(dynamic other) => this;
  dynamic operator %(dynamic other) => this;
  dynamic operator <<(dynamic other) => this;
  dynamic operator >>(dynamic other) => this;
  dynamic operator >>>(dynamic other) => this; //# sh3: continued
  dynamic operator &(dynamic other) => this;
  dynamic operator |(dynamic other) => this;
  dynamic operator ^(dynamic other) => this;
  dynamic operator ~() => this;
  dynamic operator <(dynamic other) => this;
  dynamic operator >(dynamic other) => this;
  dynamic operator <=(dynamic other) => this;
  dynamic operator >=(dynamic other) => this;
  dynamic get length => this;
}
