// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test case that tests boxing mint

// VMOptions=--shared-slow-path-triggers-gc

import 'dart:typed_data';
import 'package:expect/expect.dart';

final l = Uint64List(10);
int sum = 0;

foobar() {
  for (int i = 0; i < l.length; ++i) {
    sum += l[i];
  }
  Expect.equals(sum, 1481763717120);
}

main() {
  for (int i = 0; i < 10; i++) {
    l[i] = (i + 30) << 32;
  }
  foobar();
}
