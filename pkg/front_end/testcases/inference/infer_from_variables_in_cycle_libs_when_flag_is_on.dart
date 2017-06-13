// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_from_variables_in_cycle_libs_when_flag_is_on_a.dart';

var /*@topType=int*/ y = x; // now ok :)

test1() {
  int t = 3;
  t = x;
  t = y;
}

main() {}
