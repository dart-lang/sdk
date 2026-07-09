// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmark for https://github.com/dart-lang/sdk/issues/45908.
//
// Measures the average time needed for a lookup in Maps.

import 'dart:math';

import 'maps.dart';

abstract class MapLookupBenchmark {
  final String name;
  const MapLookupBenchmark(this.name);

  Map<String, String> get myMap;

  // Returns the number of nanoseconds per call.
  double measureFor(Duration duration) {
    final map = myMap;

    // Prevent `sw.elapsedMicroseconds` from dominating with maps with a
    // small number of elements.
    final int batching = max(1000 ~/ map.length, 1);

    int numberOfLookups = 0;
    int totalMicroseconds = 0;

    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    do {
      for (int i = 0; i < batching; i++) {
        String? k = '0';
        while (k != null) {
          k = map[k];
        }
        numberOfLookups += map.length;
      }
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    final int totalNanoseconds = sw.elapsed.inMicroseconds * 1000;
    return totalNanoseconds / numberOfLookups;
  }

  // Runs warmup phase, runs benchmark and reports result.
  void report() {
    // Warmup for 100 ms.
    measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 2 seconds.
    final double nsPerCall = measureFor(const Duration(seconds: 2));

    // Report result.
    print('$name(RunTimeRaw): $nsPerCall ns.');
  }
}

class Constant1 extends MapLookupBenchmark {
  const Constant1() : super('MapLookup.Constant1');

  @override
  Map<String, String> get myMap => const1;
}

class Final1 extends MapLookupBenchmark {
  const Final1() : super('MapLookup.Final1');

  @override
  Map<String, String> get myMap => final1;
}

class Constant5 extends MapLookupBenchmark {
  const Constant5() : super('MapLookup.Constant5');

  @override
  Map<String, String> get myMap => const5;
}

class Final5 extends MapLookupBenchmark {
  const Final5() : super('MapLookup.Final5');

  @override
  Map<String, String> get myMap => final5;
}

class Constant10 extends MapLookupBenchmark {
  const Constant10() : super('MapLookup.Constant10');

  @override
  Map<String, String> get myMap => const10;
}

class Final10 extends MapLookupBenchmark {
  const Final10() : super('MapLookup.Final10');

  @override
  Map<String, String> get myMap => final10;
}

class Constant100 extends MapLookupBenchmark {
  const Constant100() : super('MapLookup.Constant100');

  @override
  Map<String, String> get myMap => const100;
}

class Final100 extends MapLookupBenchmark {
  const Final100() : super('MapLookup.Final100');

  @override
  Map<String, String> get myMap => final100;
}

void main() {
  final benchmarks = [
    () => const Constant1(),
    () => const Constant5(),
    () => const Constant10(),
    () => const Constant100(),
    () => const Final1(),
    () => const Final5(),
    () => const Final10(),
    () => const Final100(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
