// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// A plain class that implements many fields.
class A {
  var fieldA1 = 0x1;
  var fieldA2 = 0x2;
  var fieldA3 = 0x4;
  var fieldA4 = 0x8;

  var fieldB1 = 0x10;
  var fieldB2 = 0x20;
  var fieldB3 = 0x40;
  var fieldB4 = 0x80;

  var fieldC1 = 0x100;
  var fieldC2 = 0x200;
  var fieldC3 = 0x400;
  var fieldC4 = 0x800;

  var fieldD1 = 0x1000;
  var fieldD2 = 0x2000;
  var fieldD3 = 0x4000;
  var fieldD4 = 0x8000;
  
  var fieldXA1 = 0x1;
  var fieldXA2 = 0x2;
  var fieldXA3 = 0x4;
  var fieldXA4 = 0x8;

  var fieldXB1 = 0x10;
  var fieldXB2 = 0x20;
  var fieldXB3 = 0x40;
  var fieldXB4 = 0x80;

  var fieldXC1 = 0x1;
  var fieldXC2 = 0x2;
  var fieldXC3 = 0x4;
  var fieldXC4 = 0x8;

  var fieldXD1 = 0x10;
  var fieldXD2 = 0x20;
  var fieldXD3 = 0x40;
  var fieldXD4 = 0x80;
  
  var fieldYA1 = 0x1;
  var fieldYA2 = 0x200;
  var fieldYA3 = 0x400;
  var fieldYA4 = 0x800;

  var fieldYB1 = 0x10;
  var fieldYB2 = 0x200;
  var fieldYB3 = 0x400;
  var fieldYB4 = 0x800;

  var fieldYC1 = 0x100;
  var fieldYC2 = 0x2000;
  var fieldYC3 = 0x4000;
  var fieldYC4 = 0x8000;

  var fieldYD1 = 0x1000;
  var fieldYD2 = 0x2000;
  var fieldYD3 = 0x4000;
  var fieldYD4 = 0x8000;
}

// Implementing the same fields using inheritance and a mixin.
class B {
  var fieldA1 = 0x0011;
  var fieldA2 = 0x0002;
  var fieldA3 = 0x0044;
  var fieldA4 = 0x0008;

  var fieldB1 = 0x0010;
  var fieldB2 = 0x0220;
  var fieldB3 = 0x0040;
  var fieldB4 = 0x0880;

  var fieldC1 = 0x0101;
  var fieldC2 = 0x0200;
  var fieldC3 = 0x0404;
  var fieldC4 = 0x0810;

  var fieldD1 = 0x1000;
  var fieldD2 = 0x2204;
  var fieldD3 = 0x4040;
  var fieldD4 = 0x8801;
}

class C {
  var fieldXA1 = 0x8001;
  var fieldXA2 = 0x4002;
  var fieldXA3 = 0x2004;
  var fieldXA4 = 0x1008;

  var fieldXB1 = 0x810;
  var fieldXB2 = 0x420;
  var fieldXB3 = 0x240;
  var fieldXB4 = 0x180;

  var fieldXC1 = 0x180;
  var fieldXC2 = 0x240;
  var fieldXC3 = 0x420;
  var fieldXC4 = 0x810;

  var fieldXD1 = 0x1008;
  var fieldXD2 = 0x2004;
  var fieldXD3 = 0x4002;
  var fieldXD4 = 0x8001;
}

class D extends B with C {
  var fieldYA1 = 0x8001;
  var fieldYA2 = 0x4002;
  var fieldYA3 = 0x2004;
  var fieldYA4 = 0x0008;

  var fieldYB1 = 0x810;
  var fieldYB2 = 0x420;
  var fieldYB3 = 0x240;
  var fieldYB4 = 0x080;

  var fieldYC1 = 0x180;
  var fieldYC2 = 0x240;
  var fieldYC3 = 0x420;
  var fieldYC4 = 0x800;

  var fieldYD1 = 0x1008;
  var fieldYD2 = 0x2004;
  var fieldYD3 = 0x4002;
  var fieldYD4 = 0x8000;
}

// Mix in the mixin into the full implementation, shadowing some fields.
class E extends A with C {
}

// Another mixin for block C.
class F {
  var fieldYA1 = 0x0001;
  var fieldYA2 = 0x1022;
  var fieldYA3 = 0x0004;
  var fieldYA4 = 0x0088;

  var fieldYB1 = 0x0410;
  var fieldYB2 = 0x0022;
  var fieldYB3 = 0x0040;
  var fieldYB4 = 0x0880;

  var fieldYC1 = 0x1001;
  var fieldYC2 = 0x2200;
  var fieldYC3 = 0x4400;
  var fieldYC4 = 0x8800;

  var fieldYD1 = 0x1108;
  var fieldYD2 = 0x2200;
  var fieldYD3 = 0x4044;
  var fieldYD4 = 0x8001;
}

// Use two mixins in a single class.
class G extends B with C, F {
}

bool checkFields(cls) {
  var blockA = 
    cls.fieldA1 ^ cls.fieldA2 ^ cls.fieldA3 ^ cls.fieldA4 ^
    cls.fieldB1 ^ cls.fieldB2 ^ cls.fieldB3 ^ cls.fieldB4 ^
    cls.fieldC1 ^ cls.fieldC2 ^ cls.fieldC3 ^ cls.fieldC4 ^
    cls.fieldD1 ^ cls.fieldD2 ^ cls.fieldD3 ^ cls.fieldD4;
  var blockB =
    cls.fieldXA1 ^ cls.fieldXA2 ^ cls.fieldXA3 ^ cls.fieldXA4 ^
    cls.fieldXB1 ^ cls.fieldXB2 ^ cls.fieldXB3 ^ cls.fieldXB4 ^
    cls.fieldXC1 ^ cls.fieldXC2 ^ cls.fieldXC3 ^ cls.fieldXC4 ^
    cls.fieldXD1 ^ cls.fieldXD2 ^ cls.fieldXD3 ^ cls.fieldXD4;
  var blockC =
    cls.fieldYA1 ^ cls.fieldYA2 ^ cls.fieldYA3 ^ cls.fieldYA4 ^
    cls.fieldYB1 ^ cls.fieldYB2 ^ cls.fieldYB3 ^ cls.fieldYB4 ^
    cls.fieldYC1 ^ cls.fieldYC2 ^ cls.fieldYC3 ^ cls.fieldYC4 ^
    cls.fieldYD1 ^ cls.fieldYD2 ^ cls.fieldYD3 ^ cls.fieldYD4;
  return blockA == 0xFFFF && blockB == 0x0000 && blockC == 0x1111;
}

main () {
  var instances = [new A(), new D(), new E(), new G()];
  for (var instance in instances) {
    Expect.isTrue(checkFields(instance));
  }
}
