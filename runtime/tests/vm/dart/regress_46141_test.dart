// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/46141.
// Verifies that unboxing of phi corresponding to a late variable doesn't
// happen.

// VMOptions=--deterministic

import 'package:expect/expect.dart';

final values = List.filled(100, 0.0);

double? fn(double day) {
  double? last;
  late int lastDay;

  int i = 0;
  while (i < values.length) {
    final t = values[i];
    if (day > 95) {
      print(lastDay);
      break;
    }
    last = t;
    lastDay = i;
    i++;
  }
  return last;
}

void main() {
  for (int i = 0; i < values.length; i++) {
    bool wasError = false;
    try {
      fn(i.toDouble());
    } on Error {
      wasError = true;
    }
    Expect.isTrue(wasError == (i > 95));
  }
}
