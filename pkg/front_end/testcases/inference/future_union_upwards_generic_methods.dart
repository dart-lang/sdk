// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

main() async {
  var /*@type=Future<B>*/ b = new Future<B>.value(new B());
  var /*@type=Future<C>*/ c = new Future<C>.value(new C());
  var /*@type=List<Future<A>>*/ lll = /*@typeArgs=Future<A>*/ [
    /*@promotedType=none*/ b,
    /*@promotedType=none*/ c
  ];
  var /*@type=List<A>*/ result = await Future.wait(/*@promotedType=none*/ lll);
  var /*@type=List<A>*/ result2 = await Future.wait(/*@typeArgs=Future<A>*/ [
    /*@promotedType=none*/ b,
    /*@promotedType=none*/ c
  ]);
  List<A> list = /*@promotedType=none*/ result;
  list = /*@promotedType=none*/ result2;
}

class A {}

class B extends A {}

class C extends A {}
