// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

foo() async {
  Future<List<A>> f1 = null;
  Future<List<A>> f2 = null;
  List<List<A>> merged = await Future. /*@typeArgs=List<A>*/ wait(
      /*@typeArgs=Future<List<A>>*/ [f1, f2]);
}

class A {}

main() {}
