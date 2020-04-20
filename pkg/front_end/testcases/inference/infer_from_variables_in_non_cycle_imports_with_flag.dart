// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_from_variables_in_non_cycle_imports_with_flag_a.dart';

var y = x;

test1() {
  x = /*error:INVALID_ASSIGNMENT*/ "hi";
  y = /*error:INVALID_ASSIGNMENT*/ "hi";
}

main() {}
