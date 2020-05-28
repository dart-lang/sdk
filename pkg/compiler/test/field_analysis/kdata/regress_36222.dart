// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

typedef int BinaryFunc(int x, int y);

class A {
  const A({this.foo = A.defaultFoo});

  static int defaultFoo(int x, int y) {
    return x + y;
  }

  /*member: A.foo:A.=foo:FunctionConstant(A.defaultFoo),initial=NullConstant*/
  final BinaryFunc foo;
}

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
test(dynamic a) => a.foo(1, 2);

main() {
  test(new A());
}
