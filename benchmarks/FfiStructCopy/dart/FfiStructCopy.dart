// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmarks for ffi memory copies.
//
// These micro benchmarks track the speed of doing mem-copies when copying
// structs.

import 'dart:ffi';
import 'dart:math';

import 'package:args/args.dart';
import 'package:ffi/ffi.dart';

import 'benchmark_generated.dart';

abstract class StructCopyBenchmark {
  final String name;
  StructCopyBenchmark(this.name);

  int get copySizeInBytes;
  Pointer get from;
  Pointer get to;

  static const targetBatchSizeInBytes = 32 * 1024;

  late final int batchSize = max(targetBatchSizeInBytes ~/ copySizeInBytes, 1);

  // Returns the number of bytes copied per second.
  double measureFor(Duration duration) {
    // Prevent `sw.elapsedMicroseconds` from dominating with maps with a
    // small number of elements.
    final int batchSizeInBytes = batchSize * copySizeInBytes;

    int numberOfBytesCopied = 0;
    int totalMicroseconds = 0;

    final sw = Stopwatch()..start();
    final durationInMicroseconds = duration.inMicroseconds;

    do {
      run(batchSize);
      numberOfBytesCopied += batchSizeInBytes;
      totalMicroseconds = sw.elapsedMicroseconds;
    } while (totalMicroseconds < durationInMicroseconds);

    const microsecondsInSecond = 1000 * 1000;
    return numberOfBytesCopied * microsecondsInSecond / totalMicroseconds;
  }

  // Runs warmup phase, runs benchmark and reports result.
  void report({bool verbose = false}) {
    setup(batchSize);

    // Warmup for 100 ms.
    measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 2 seconds.
    final double bytesPerSecond = measureFor(const Duration(seconds: 2));

    // Report result.
    print('$name(BytesPerSecond): $bytesPerSecond');
    if (verbose) {
      const nanoSecondsPerSecond = 1000 * 1000 * 1000;
      final nanosecondsPerByte = nanoSecondsPerSecond / bytesPerSecond;
      print('$name(NanosecondsPerChar): $nanosecondsPerByte');
      const bytesPerMegaByte = 1024 * 1024;
      final mbPerSecond = bytesPerSecond / bytesPerMegaByte;
      print('$name: $mbPerSecond MB per second copied.');
    }

    teardown();
  }

  void teardown() {
    calloc.free(from);
    calloc.free(to);
  }

  void setup(int batchSize);

  void run(int batchSize);
}

final argParser = ArgParser()
  ..addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false);

void main(List<String> args) {
  final results = argParser.parse(args);
  final benchmarks = [
    Copy1Bytes.new,
    Copy32Bytes.new,
    Copy1024Bytes.new,
    Copy32768Bytes.new,
  ];

  final filter = results.rest.firstOrNull;
  for (var constructor in benchmarks) {
    final benchmark = constructor();
    if (filter == null || benchmark.name.contains(filter)) {
      benchmark.report(verbose: results['verbose']);
    }
  }
}
