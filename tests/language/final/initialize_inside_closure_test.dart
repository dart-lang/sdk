// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test - see https://github.com/dart-lang/sdk/issues/47991

import 'dart:math';

void main() {
  () {
    final should = Random().nextBool() || Random().nextBool();
    final int a;

    if (should) {
      a = 1;
    } else {
      a = 2;
    }
  };
}
