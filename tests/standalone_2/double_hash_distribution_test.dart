// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the distribution of hash codes for doubles is reasonable.

// VMOptions=--intrinsify
// VMOptions=--no_intrinsify

import 'package:expect/expect.dart';

main() {
  Expect.isTrue(ratio(0, 1) >= 0.95);
  Expect.isTrue(ratio(0, 100) >= 0.95);
  Expect.isTrue(ratio(0, 0xffffff) >= 0.95);
  Expect.isTrue(ratio(0xffffff) >= 0.95);
  Expect.isTrue(ratio(0xffffffff) >= 0.95);
  Expect.isTrue(ratio(0xffffffffffffff) >= 0.95);

  Expect.isTrue(ratio(0, -1) >= 0.95);
  Expect.isTrue(ratio(0, -100) >= 0.95);
  Expect.isTrue(ratio(0, -0xffffff) >= 0.95);
  Expect.isTrue(ratio(-0xffffff) >= 0.95);
  Expect.isTrue(ratio(-0xffffffff) >= 0.95);
  Expect.isTrue(ratio(-0xffffffffffffff) >= 0.95);
}

double ratio(num start, [num end]) {
  final n = 1000;
  end ??= (start + 1) * 2;

  // Collect the set of distinct doubles and the
  // set of distinct hash codes.
  final doubles = new Set<double>();
  final codes = new Set<int>();

  final step = (end.toDouble() - start.toDouble()) / n;
  var current = start.toDouble();
  for (int i = 0; i < n; i++) {
    doubles.add(current);
    codes.add(current.hashCode);
    current += step;
  }

  // Return the ratio between distinct doubles and
  // distinct hash codes.
  return codes.length / doubles.length;
}
