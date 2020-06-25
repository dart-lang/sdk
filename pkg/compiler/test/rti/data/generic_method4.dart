// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

/*class: A:deps=[C.method2],direct,explicit=[A.T*],needsArgs*/
class A<T> {
  @pragma('dart2js:noInline')
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB]*/
class BB {}

/*class: B:deps=[C.method1],implicit=[B.T],indirect,needsArgs*/
class B<T> implements BB {
  @pragma('dart2js:noInline')
  foo(c) {
    return c.method2<T>().foo(new B());
  }
}

class C {
  /*member: C.method1:implicit=[method1.T],indirect,needsArgs,selectors=[Selector(call, method1, arity=0, types=1)]*/
  @pragma('dart2js:noInline')
  method1<T>() {
    return new B<T>().foo(this);
  }

  /*member: C.method2:deps=[B],implicit=[method2.T],indirect,needsArgs,selectors=[Selector(call, method2, arity=0, types=1)]*/
  @pragma('dart2js:noInline')
  method2<T>() => new A<T>();
}

main() {
  var c = new C();
  Expect.isTrue(c.method1<BB>());
  Expect.isFalse(c.method1<String>());
}
