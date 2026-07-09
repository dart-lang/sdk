// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that OSR gets into nested try-block correctly.
//
// VMOptions=--optimization-counter-threshold=50

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
void bar(i) {
  if (i == 1) throw 'Hey!';
}

void main() {
  int x = int.parse('1');
  for (int i = 0; i < 100; ++i) {
    try {
      for (int j = 0; j < 100; ++j) {
        // OSR at i == 0
        bar(i);
      }
    } catch (e) {
      Expect.equals(x == 2, true);
      return;
    }
    x = 2;
  }
}
