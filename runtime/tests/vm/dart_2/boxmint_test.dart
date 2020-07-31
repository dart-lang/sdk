// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test case that tests boxing mint

// VMOptions=--optimization_counter_threshold=10 --deterministic --use-slow-path --shared-slow-path-triggers-gc --stacktrace_filter=foobar

import 'dart:typed_data';
import 'package:expect/expect.dart';

final gSize = 100;
final l = Uint64List(gSize);
int sum = 0;

foobar() {
  for (int i = 0; i < l.length; ++i) {
    sum += l[i];
  }
  Expect.equals(-9223372036854775808, sum);
}

main() {
  for (int i = 0; i < gSize; i++) {
    l[i] = (i + 30) << 62;
  }
  foobar();
}
