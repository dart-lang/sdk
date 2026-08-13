// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 17210.

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
num minusZero() => -0;

void main() {
  // Dart2js must not infer that the type-intersection of int and -0.0 is empty.
  // It must get an interceptor for the addition (`i += 3`), or use the native
  // JS + operation.
  int i = minusZero() as int;
  i += 3;
  Expect.equals(3, i);
}
