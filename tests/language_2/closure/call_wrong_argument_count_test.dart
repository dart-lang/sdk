// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test mismatch in argument counts.
import 'package:expect/expect.dart';

int melke(f) {
  return f(1, 2, 3);
}

main() {
  kuh(int a, int b) {
    return a + b;
  }

  Expect.throws(() {
    melke(kuh);
  });
}
