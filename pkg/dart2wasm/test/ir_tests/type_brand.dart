// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// typeFilter=Foo|Bar
// compilerOption=-O0
// compilerOption=--unique-types

main() {
  for (final entry in [...list, ...list]) {
    print(entry);
  }
}

final intValue = int.parse('1');
final doubleValue = double.parse('1.1');
final stringValue = intValue.toString();
final list = [
  Foo1(stringValue, intValue),
  Foo2(stringValue, intValue),
  Foo3(stringValue, intValue),
  Foo4(stringValue, intValue),
  Foo5(stringValue, intValue),
  Foo6(stringValue, intValue),
  Foo7(stringValue, intValue),
  Foo8(stringValue, intValue),
  Foo9(stringValue, intValue),
  Foo10(stringValue, intValue),
  Foo11(stringValue, intValue),
  Bar1(stringValue, doubleValue),
  Bar2(stringValue, doubleValue),
  Bar3(stringValue, doubleValue),
];

class Foo1 {
  final String s1;
  final int a1;
  Foo1(this.s1, this.a1);
  toString() => 'Foo1.$s1.$a1';
}

class Foo2 {
  final String s2;
  final int a2;
  Foo2(this.s2, this.a2);
  toString() => 'Foo2.$s2.$a2';
}

class Foo3 {
  final String s3;
  final int a3;
  Foo3(this.s3, this.a3);
  toString() => 'Foo3.$s3.$a3';
}

class Foo4 {
  final String s4;
  final int a4;
  Foo4(this.s4, this.a4);
  toString() => 'Foo4.$s4.$a4';
}

class Foo5 {
  final String s5;
  final int a5;
  Foo5(this.s5, this.a5);
  toString() => 'Foo5.$s5.$a5';
}

class Foo6 {
  final String s6;
  final int a6;
  Foo6(this.s6, this.a6);
  toString() => 'Foo6.$s6.$a6';
}

class Foo7 {
  final String s7;
  final int a7;
  Foo7(this.s7, this.a7);
  toString() => 'Foo7.$s7.$a7';
}

class Foo8 {
  final String s8;
  final int a8;
  Foo8(this.s8, this.a8);
  toString() => 'Foo8.$s8.$a8';
}

class Foo9 {
  final String s9;
  final int a9;
  Foo9(this.s9, this.a9);
  toString() => 'Foo9.$s9.$a9';
}

class Foo10 {
  final String s10;
  final int a10;
  Foo10(this.s10, this.a10);
  toString() => 'Foo10.$s10.$a10';
}

class Foo11 {
  final String s11;
  final int a11;
  Foo11(this.s11, this.a11);
  toString() => 'Foo11.$s11.$a11';
}

class Bar1 {
  final String s1;
  final double b1;
  Bar1(this.s1, this.b1);
  toString() => 'Bar1.$s1.$b1';
}

class Bar2 {
  final String s2;
  final double b2;
  Bar2(this.s2, this.b2);
  toString() => 'Bar2.$s2.$b2';
}

class Bar3 {
  final String s3;
  final double b3;
  Bar3(this.s3, this.b3);
  toString() => 'Bar3.$s3.$b3';
}
