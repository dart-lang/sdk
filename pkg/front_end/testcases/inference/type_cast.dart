// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {}

class B<T> extends A<T> {
  /*@topType=dynamic*/ foo() {}
}

A<num> a = new B<int>();
var /*@topType=B<int>*/ b = (a as B<int>);

main() {
  A<num> a = new B<int>();
  var /*@type=B<int>*/ b = (a as B<int>);
}
