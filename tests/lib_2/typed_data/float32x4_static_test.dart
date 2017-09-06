// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library tag to be able to run in html test framework.
library float32x4_static_test;

import 'dart:typed_data';

main() {
  var str = "foo";
  /*@compile-error=unspecified*/ new Float32x4(str, 2.0, 3.0, 4.0);
}
