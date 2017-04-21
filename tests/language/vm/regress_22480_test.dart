// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'package:expect/expect.dart';

test(j) {
  var result = true;
  j++;
  for (var i = 0; i < 100; i++) {
    result = (i < 50 || j < (1 << 32)) && result;
  }
  return result;
}

main() {
  Expect.isTrue(test(30));
}
