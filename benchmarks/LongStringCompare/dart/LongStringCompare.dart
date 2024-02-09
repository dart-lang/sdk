// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Measure performance of string comparison.

// Using string interpolation could change what this test is measuring.
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:benchmark_harness/benchmark_harness.dart';

int equalCount = 0;

class LongStringCompare extends BenchmarkBase {
  final int reps;
  final List<String> s = [];

  String generateLongString(int lengthPower) {
    return 'abc' * (1 << lengthPower) + 'def';
  }

  LongStringCompare(int lengthPower, this.reps)
      : super('LongStringCompare.${1 << lengthPower}.${reps}reps') {
    final single = generateLongString(lengthPower);
    s.add(single + '.' + single);
    s.add(single + '!' + single);
  }

  @override
  void warmup() {
    for (int i = 0; i < reps / 2; i++) {
      run();
    }
  }

  @override
  void run() {
    for (int i = 0; i < reps; i++) {
      // Make string comparison code hoisting harder for the compiler to do.
      final bool comparison = s[i % 2] == s[(i + 1) % 2];
      if (comparison) {
        equalCount++;
      }
    }
  }
}

void main() {
  LongStringCompare(1, 3000).report();
  LongStringCompare(5, 1000).report();
  LongStringCompare(10, 30).report();
  if (equalCount > 0) throw StateError('Unexpected equalCount: $equalCount');
}
