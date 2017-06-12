// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Foo {
  dynamic method(int x) {}
  dynamic method2(int x) {}
}

main() {
  Foo foo = new Foo();

  dynamic dynamicMethod1 = foo.method;
  Expect.throws(() => dynamicMethod1(2.5));

  dynamic dynamicMethod2 = (foo as dynamic).method;
  Expect.throws(() => dynamicMethod2(2.5));

  Expect.equals(dynamicMethod1, dynamicMethod1);
  Expect.equals(dynamicMethod1, dynamicMethod2);
  Expect.equals(dynamicMethod1, foo.method);
  Expect.equals(foo.method2, (foo as dynamic).method2);

  Expect.notEquals(dynamicMethod1, new Foo().method);
  Expect.notEquals(dynamicMethod1, (new Foo() as dynamic).method);
  Expect.notEquals(dynamicMethod1, foo.method2);
  Expect.notEquals(dynamicMethod1, (foo as dynamic).method2);
}
