// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

main() async {
  var /*@type=Future<B>*/ b = new Future<B>.value(new B());
  var /*@type=Future<C>*/ c = new Future<C>.value(new C());
  var /*@type=List<Future<A>>*/ lll = /*@typeArgs=Future<A>*/ [b, c];
  var /*@type=List<A>*/ result =
      await Future. /*@typeArgs=A*/ /*@target=Future::wait*/ wait(lll);
  var /*@type=List<A>*/ result2 =
      await Future. /*@typeArgs=A*/ /*@target=Future::wait*/ wait(
          /*@typeArgs=Future<A>*/ [b, c]);
  List<A> list = result;
  list = result2;
}

class A {}

class B extends A {}

class C extends A {}
