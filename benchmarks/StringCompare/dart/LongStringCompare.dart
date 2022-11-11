// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Measure performance of string comparison.

import 'package:benchmark_harness/benchmark_harness.dart';

class LongStringCompare extends BenchmarkBase {
  late String s, t;

  String generateLongString() {
    var s = "abcdefgh";
    for (int i = 0; i < 20; i++) {
      s = "$s ghijkl $s";
    }
    return s;
  }

  LongStringCompare() : super('LongStringCompare') {
    s = generateLongString();
    t = s;
    // Difference in two strings goes in the middle.
    s += "." + s;
    t += "!" + t;
  }

  @override
  void warmup() {
    for (int i = 0; i < 4; i++) {
      run();
    }
  }

  @override
  void run() {
    bool b = true;
    for (int i = 0; i < 5; i++) {
      b &= (s == t);
    }
  }
}

void main() {
  LongStringCompare().report();
}
