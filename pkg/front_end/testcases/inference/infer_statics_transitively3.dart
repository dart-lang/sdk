// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_statics_transitively3_a.dart' show a1, A;
import 'infer_statics_transitively3_a.dart' as p show a2, A;

const t1 = 1;
const t2 = t1;
const t3 = a1;
const t4 = p.a2;
const t5 = A.a3;
const t6 = p.A.a3;

foo() {
  int i;
  i = t1;
  i = t2;
  i = t3;
  i = t4;
}

main() {}
