// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_statics_transitively_a.dart';

final /*@topType=int*/ m1 = a1;
final /*@topType=int*/ m2 = A.a2;

foo() {
  int i;
  i = m1;
}

main() {}
