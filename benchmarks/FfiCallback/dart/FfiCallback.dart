// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These micro benchmarks track the speed of reading and writing C memory from
// Dart with a specific marshalling and unmarshalling of data.

import 'dart:ffi';
import 'dart:io';

import 'package:args/args.dart';

import 'dlopen_helper.dart';

// The native library that holds all the native functions being called.
DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific(
  'native_functions',
  path: Platform.script.resolve('../native/out/').path,
);

abstract class FfiCallbackBenchmark {
  final String name;

  FfiCallbackBenchmark(this.name);

  // Returns ns per callback.
  double measureFor(Duration duration) {
    const int batchSize = 100000;

    int numberOfCalls = 0;
    int totalMicroseconds = 0;

    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    do {
      run(batchSize);
      numberOfCalls += batchSize;
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    final totalNanoSeconds = totalMicroseconds * 1000;
    return totalNanoSeconds / numberOfCalls;
  }

  // Runs warmup phase, runs benchmark and reports result.
  void report({bool verbose = false}) {
    // Warmup for 100 ms.
    measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 2 seconds.
    final double nsPerCall = measureFor(const Duration(seconds: 2));

    // Report result.
    print('$name(RunTimeRaw): $nsPerCall ns.');
    if (verbose) {
      final callsPerSecond = (1000 * 1000 * 1000 / nsPerCall).toInt();
      print('$name: $callsPerSecond calls per second.');
    }

    shutdown();
  }

  void run(int batchSize);

  void shutdown();

  void expectEquals(actual, expected) {
    if (actual != expected) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }
}

final class Uint8x1 extends FfiCallbackBenchmark {
  Uint8x1() : super('FfiCallbackBenchmark.Uint8x1');

  final function = ffiTestFunctions
      .lookupFunction<
        Void Function(Pointer<NativeFunction<Void Function(Uint8)>>, Uint32),
        void Function(Pointer<NativeFunction<Void Function(Uint8)>>, int)
      >('CallFunction1Uint8');

  static int x = 0;

  static void callback(int value) {
    x += value;
  }

  static final nativeCallable =
      NativeCallable<Void Function(Uint8)>.isolateLocal(callback);

  static final pointer = nativeCallable.nativeFunction;

  @override
  void run(int batchSize) {
    x = 0;
    function(pointer, batchSize);
    expectEquals(x, batchSize);
  }

  @override
  void shutdown() {
    nativeCallable.close();
  }
}

final argParser = ArgParser()
  ..addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false);

void main(List<String> args) {
  final results = argParser.parse(args);
  final benchmarks = [Uint8x1.new];

  final filter = results.rest.firstOrNull;
  for (var constructor in benchmarks) {
    final benchmark = constructor();
    if (filter == null || benchmark.name.contains(filter)) {
      benchmark.report(verbose: results['verbose']);
    }
  }
}
