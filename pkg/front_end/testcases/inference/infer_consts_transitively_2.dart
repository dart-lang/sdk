// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_consts_transitively_2_a.dart';

const m1 = a1;
const m2 = a2;

foo() {
  int i;
  i = m1;
}

main() {}
