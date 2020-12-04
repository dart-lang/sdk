// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  test(0, '[]');
  test(1, '[[[1]]]');
  test(2, '[[[1]], [[2], [3, 4]]]');
  test(3, '[[[1]], [[2], [3, 4]], [[5], [6, 7], [8, 9, 10]]]');
}

void test(int i, String expected) {
  // Many nested closures with shadowing variables.
  int c = 0;
  final r = List.generate(
      i, (i) => List.generate(i + 1, (i) => List.generate(i + 1, (i) => ++c)));

  Expect.equals(expected, '$r');
}
