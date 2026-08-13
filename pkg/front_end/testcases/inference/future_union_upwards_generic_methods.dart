// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

main() async {
  var b = new Future<B>.value(new B());
  var c = new Future<C>.value(new C());
  var lll = [b, c];
  var result = await Future.wait(lll);
  var result2 = await Future.wait([b, c]);
  List<A> list = result;
  list = result2;
}

class A {}

class B extends A {}

class C extends A {}
