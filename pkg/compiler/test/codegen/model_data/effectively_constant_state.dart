// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { a, b, c }

@pragma('dart2js:never-inline')
tester1() {}

/*member: tester2:params=0*/
@pragma('dart2js:never-inline')
tester2() {}

/*member: tester3:params=0*/
@pragma('dart2js:never-inline')
tester3() {}

class Class {
  /*member: Class.state1:elided*/
  final int state1;

  /*member: Class.state2:elided*/
  final Enum state2;

  Class({this.state1 = 1, this.state2 = Enum.c});

  /*member: Class.method1a:calls=[tester2(0)],params=0*/
  @pragma('dart2js:never-inline')
  method1a() {
    if (state1 == 0) {
      return tester1();
    } else if (state1 == 1) {
      return tester2();
    } else if (state1 == 2) {
      return tester3();
    }
  }

  // TODO(johnniwinther): Inline switch cases with constant expressions.
  /*member: Class.method1b:calls=[tester2(0)],params=0,switch*/
  @pragma('dart2js:never-inline')
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

  /*member: Class.method2a:calls=[tester3(0)],params=0*/
  @pragma('dart2js:never-inline')
  method2a() {
    if (state2 == Enum.a) {
      return tester1();
    } else if (state2 == Enum.b) {
      return tester2();
    } else if (state2 == Enum.c) {
      return tester3();
    }
  }

  /*member: Class.method2b:calls=[tester3(0)],params=0,switch*/
  @pragma('dart2js:never-inline')
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

/*member: main:calls=*,params=0*/
main() {
  var c = Class();
  c.method1a();
  c.method1b();
  c.method2a();
  c.method2b();
}
