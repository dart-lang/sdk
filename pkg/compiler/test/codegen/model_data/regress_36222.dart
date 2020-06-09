// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

typedef int BinaryFunc(int x, int y);

class A {
  const A({this.foo = A.defaultFoo});

  /*member: A.defaultFoo:params=2*/
  static int defaultFoo(int x, int y) {
    return x + y;
  }

  /*member: A.foo:elided,stubCalls=[foo$2:call$2(arg0,arg1),foo$2:main_A_defaultFoo$closure(0)]*/
  final BinaryFunc foo;
}

/*member: test:calls=[foo$2(2)],params=1*/
@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
test(dynamic a) => a.foo(1, 2);

/*member: main:calls=[test(1)],params=0*/
main() {
  test(new A());
}
