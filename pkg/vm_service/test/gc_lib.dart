// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

void script() {
  void grow(int iterations, int size, Duration duration) {
    if (iterations <= 0) {
      return;
    }
    List<int>.filled(size, 0);
    Timer(duration, () => grow(iterations - 1, size, duration));
  }

  grow(100, 1 << 24, Duration(seconds: 1));
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: script);
}
