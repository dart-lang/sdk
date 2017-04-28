// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_statics_transitively3_a.dart' show a1, A;
import 'infer_statics_transitively3_a.dart' as p show a2, A;

const /*@topType=int*/ t1 = 1;
const /*@topType=int*/ t2 = t1;
const /*@topType=dynamic*/ t3 = a1;
const /*@topType=dynamic*/ t4 = p.a2;
const /*@topType=dynamic*/ t5 = A.a3;
const /*@topType=dynamic*/ t6 = p.A.a3;

foo() {
  int i;
  i = t1;
  i = t2;
  i = t3;
  i = t4;
}
