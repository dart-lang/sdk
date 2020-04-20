// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Operators {
  operator +(other) => null;
  operator &(other) => null;
  operator ~() => null;
  operator |(other) => null;
  operator ^(other) => null;
  operator /(other) => null;
  operator ==(other) => null;
  operator >(other) => null;
  operator >=(other) => null;
  operator [](index) => null;
  void operator []=(index, value) {}
  operator <<(other) => null;
  operator <(other) => null;
  operator <=(other) => null;
  operator *(other) => null;
  operator %(other) => null;
  operator >>(other) => null;
  operator -(other) => null;
  operator ~/(other) => null;
  operator -() => null;
}

main(arguments) {
  var a = new Operators();
  var b = new Operators();
  a + b;
  a & b;
  ~a;
  a | b;
  a ^ b;
  a / b;
  a == b;
  a > b;
  a >= b;
  a[0];
  a[0] = b;
  a << b;
  a < b;
  a <= b;
  a * b;
  a % b;
  a >> b;
  a - b;
  a ~/ b;
  -a;
}
