// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int iterations = 100000;

void main() {
  SyncCallBenchmark('TypeLiteral.GenericFunction.T.dynamic', () {
    for (int i = 0; i < iterations; ++i) {
      getT<dynamic>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.T.int', () {
    for (int i = 0; i < iterations; ++i) {
      getT<int>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.T.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      getT<int?>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.ListOfT.int', () {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.ListOfT.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int?>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.NullableT.int', () {
    for (int i = 0; i < iterations; ++i) {
      getNullableT<int>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.NullableT.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      getNullableT<int?>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.ListOfNullableT.int', () {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int>();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericFunction.ListOfNullableT.nullableInt',
      () {
    for (int i = 0; i < iterations; ++i) {
      getListOfNullableT<int?>();
    }
    return iterations;
  }).report();
  final foos = <Foo<Object?>>[
    Foo<int>(),
    Foo<int?>(),
    Foo<dynamic>(),
  ];
  final Foo fooInt = foos[int.parse('0')];
  final Foo fooNullableInt = foos[int.parse('1')];
  final Foo fooDynamic = foos[int.parse('2')];
  SyncCallBenchmark('TypeLiteral.GenericClass.T.dynamic', () {
    for (int i = 0; i < iterations; ++i) {
      fooDynamic.getT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.T.int', () {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.T.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.ListOfT.int', () {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getListOfT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.ListOfT.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getListOfT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.NullableT.int', () {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getNullableT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.NullableT.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getNullableT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.ListOfNullableT.int', () {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getListOfT();
    }
    return iterations;
  }).report();
  SyncCallBenchmark('TypeLiteral.GenericClass.ListOfNullableT.nullableInt', () {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getListOfNullableT();
    }
    return iterations;
  }).report();
}

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Type getT<T>() => T;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Type getNullableT<T>() => MakeNullable<T?>;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Type getListOfT<T>() => List<T>;

@pragma('vm:never-inline')
@pragma('dart2js:noInline')
Type getListOfNullableT<T>() => List<T?>;

class Foo<T> {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Type getT() => T;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Type getNullableT() => MakeNullable<T?>;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Type getListOfT() => List<T>;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Type getListOfNullableT() => List<T?>;
}

typedef MakeNullable<X> = X?;

// Same as from [Calls] benchmark.
class SyncCallBenchmark {
  final String name;
  final int Function() performCalls;

  SyncCallBenchmark(this.name, this.performCalls);

  // Returns the number of nanoseconds per call.
  double measureFor(Duration duration) {
    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    int numberOfCalls = 0;
    int totalMicroseconds = 0;
    do {
      numberOfCalls += performCalls();
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    final int totalNanoseconds = sw.elapsed.inMicroseconds * 1000;
    return totalNanoseconds / numberOfCalls;
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
