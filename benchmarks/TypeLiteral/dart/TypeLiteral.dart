// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int iterations = 100000;

void main() {
  @pragma('vm:align-loops')
  int genericFunctionTDynamic() {
    for (int i = 0; i < iterations; ++i) {
      getT<dynamic>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.T.dynamic',
    genericFunctionTDynamic,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionTInt() {
    for (int i = 0; i < iterations; ++i) {
      getT<int>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.T.int',
    genericFunctionTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      getT<int?>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.T.nullableInt',
    genericFunctionTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionListOfTInt() {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.ListOfT.int',
    genericFunctionListOfTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionListOfTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int?>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.ListOfT.nullableInt',
    genericFunctionListOfTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionNullableTInt() {
    for (int i = 0; i < iterations; ++i) {
      getNullableT<int>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.NullableT.int',
    genericFunctionNullableTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionNullableTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      getNullableT<int?>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.NullableT.nullableInt',
    genericFunctionNullableTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionListOfNullableTInt() {
    for (int i = 0; i < iterations; ++i) {
      getListOfT<int>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.ListOfNullableT.int',
    genericFunctionListOfNullableTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericFunctionListOfNullableTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      getListOfNullableT<int?>();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericFunction.ListOfNullableT.nullableInt',
    genericFunctionListOfNullableTNullableInt,
  ).report();
  final foos = <Foo<Object?>>[Foo<int>(), Foo<int?>(), Foo<dynamic>()];
  final Foo fooInt = foos[int.parse('0')];
  final Foo fooNullableInt = foos[int.parse('1')];
  final Foo fooDynamic = foos[int.parse('2')];
  @pragma('vm:align-loops')
  int genericClassTDynamic() {
    for (int i = 0; i < iterations; ++i) {
      fooDynamic.getT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.T.dynamic',
    genericClassTDynamic,
  ).report();
  @pragma('vm:align-loops')
  int genericClassTInt() {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.T.int',
    genericClassTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.T.nullableInt',
    genericClassTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassListOfTInt() {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getListOfT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.ListOfT.int',
    genericClassListOfTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassListOfTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getListOfT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.ListOfT.nullableInt',
    genericClassListOfTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassNullableTInt() {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getNullableT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.NullableT.int',
    genericClassNullableTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassNullableTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getNullableT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.NullableT.nullableInt',
    genericClassNullableTNullableInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassListOfNullableTInt() {
    for (int i = 0; i < iterations; ++i) {
      fooInt.getListOfT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.ListOfNullableT.int',
    genericClassListOfNullableTInt,
  ).report();
  @pragma('vm:align-loops')
  int genericClassListOfNullableTNullableInt() {
    for (int i = 0; i < iterations; ++i) {
      fooNullableInt.getListOfNullableT();
    }
    return iterations;
  }

  SyncCallBenchmark(
    'TypeLiteral.GenericClass.ListOfNullableT.nullableInt',
    genericClassListOfNullableTNullableInt,
  ).report();
}

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
Type getT<T>() => T;

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
Type getNullableT<T>() => MakeNullable<T?>;

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
Type getListOfT<T>() => List<T>;

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
Type getListOfNullableT<T>() => List<T?>;

class Foo<T> {
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:noInline')
  Type getT() => T;

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:noInline')
  Type getNullableT() => MakeNullable<T?>;

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:noInline')
  Type getListOfT() => List<T>;

  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
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
