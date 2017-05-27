// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future main() async {
  dynamic d;
  List<int> l0 = await /*@typeArgs=int*/ [/*info:DYNAMIC_CAST*/ d];
  List<int> l1 = await new /*@typeArgs=List<int>*/ Future.value(
      /*@typeArgs=int*/ [d]);
}
