// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 17210.

import "package:expect/expect.dart";

void main() {
  // Dart2js must use "-0.0" as if it was 0. In particular, it must do its
  // range-analysis correctly.
  var list = [1, 2, 3];
  if (DateTime.now().millisecondsSinceEpoch == 42) list[1] = 4;
  int sum = 0;
  for (num i = -0.0; i < list.length; i++) {
    sum += list[i as int];
  }
  Expect.equals(6, sum);
}
