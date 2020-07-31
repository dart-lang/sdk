// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

enum Enum {
  a,

  b,

  c,
}

@pragma('dart2js:noInline')
tester1() {}

@pragma('dart2js:noInline')
tester2() {}

@pragma('dart2js:noInline')
tester3() {}

class Class {
  /*member: Class.state1:constant=IntConstant(1)*/
  final int state1;

  /*member: Class.state2:constant=ConstructedConstant(Enum(_name=StringConstant("Enum.c"),index=IntConstant(2)))*/
  final Enum state2;

  Class({this.state1: 1, this.state2: Enum.c});

  @pragma('dart2js:noInline')
  method1a() {
    if (state1 == 0) {
      return tester1();
    } else if (state1 == 1) {
      return tester2();
    } else if (state1 == 2) {
      return tester3();
    }
  }

  @pragma('dart2js:noInline')
  method1b() {
    switch (state1) {
      case 0:
        return tester1();
      case 1:
        return tester2();
      case 2:
        return tester3();
    }
  }

  @pragma('dart2js:noInline')
  method2a() {
    if (state2 == Enum.a) {
      return tester1();
    } else if (state2 == Enum.b) {
      return tester2();
    } else if (state2 == Enum.c) {
      return tester3();
    }
  }

  @pragma('dart2js:noInline')
  method2b() {
    switch (state2) {
      case Enum.a:
        return tester1();
      case Enum.b:
        return tester2();
      case Enum.c:
        return tester3();
    }
  }
}

main() {
  var c = new Class();
  c.method1a();
  c.method1b();
  c.method2a();
  c.method2b();
}
