// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:heap_snapshot/intset.dart';

main() {
  for (int every in [16, 8, 4, 3, 2, 1]) {
    iterationBenchmark(every, 1);
    iterationBenchmark(every, 0.5);
  }

  print("OK");
}

void iterationBenchmark(int every, double fillPercent) {
  // Warmup.
  for (int i = 0; i < 10; i++) {
    iterationBenchmarkRun(every, fillPercent);
  }

  Stopwatch stopwatch = Stopwatch()..start();
  for (int i = 0; i < 100; i++) {
    iterationBenchmarkRun(every, fillPercent);
  }
  print("Ran ($every, $fillPercent) in ${stopwatch.elapsedMilliseconds} ms");
}

void iterationBenchmarkRun(int every, double fillPercent) {
  const max = 1024 * 1024;
  SpecializedIntSet set = SpecializedIntSet(max);
  int expectedResult = 0;
  int end = (max * fillPercent).toInt();
  if (end > max) throw "end > max: $end > $max";
  if (end < 0) throw "end < 0: $end < 0";
  for (int i = 0; i < end; i += every) {
    set.add(i);
    expectedResult += i;
  }
  for (int iteration = 0; iteration < 10; iteration++) {
    int thisResult = 0;
    for (int value in set) {
      thisResult += value;
    }
    if (thisResult != expectedResult) throw "Bad";
  }
}
