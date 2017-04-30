// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future test() async {
  dynamic d;
  List<int> l0 =
      await /*@typeArgs=int*/ [/*info:DYNAMIC_CAST*/ /*@promotedType=none*/ d];
  List<int> l1 = await /*@typeArgs=List<int>*/ new Future.value(
      /*@typeArgs=dynamic*/ [/*@promotedType=none*/ d]);
}
