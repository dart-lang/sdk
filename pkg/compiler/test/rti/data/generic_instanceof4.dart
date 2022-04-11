// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:deps=[B],explicit=[A.T*],needsArgs,test*/
class A<T> {
  @pragma('dart2js:noInline')
  foo(x) {
    return x is T;
  }
}

/*class: BB:implicit=[BB]*/
class BB {}

/*class: B:implicit=[B.T],needsArgs,test*/
class B<T> implements BB {
  @pragma('dart2js:noInline')
  foo() {
    return new A<T>().foo(new B());
  }
}

main() {
  new B<BB>().foo();
}
