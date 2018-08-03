// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_from_variables_in_non_cycle_imports_with_flag2_a.dart';

class B {
  static var /*@topType=int*/ y = A.x;
}

test1() {
  A.x = /*error:INVALID_ASSIGNMENT*/ "hi";
  B.y = /*error:INVALID_ASSIGNMENT*/ "hi";
}

main() {}
