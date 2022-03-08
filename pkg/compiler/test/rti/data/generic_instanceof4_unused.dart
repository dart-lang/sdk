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

// This class was previously mark as implicitly tested by the imprecise
// computation of implicit is-tests.
class BB {}

/*class: B:implicit=[B.T],needsArgs,test*/
class B<T> implements BB {
  @pragma('dart2js:noInline')
  foo() {
    return new A<T>().foo(new B());
  }
}

class C<T> {}

class D extends C<BB> {}

main() {
  new B<int>().foo();
  new D();
}
