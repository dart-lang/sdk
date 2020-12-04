// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmarks for copying typed data lists.

// @dart=2.9

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

abstract class Uint8ListCopyBenchmark extends BenchmarkBase {
  final int size;
  Uint8List input;
  Uint8List result;

  Uint8ListCopyBenchmark(String method, this.size)
      : super('TypedDataDuplicate.Uint8List.$size.$method');

  @override
  void setup() {
    input = Uint8List(size);
    for (var i = 0; i < size; ++i) {
      input[i] = (i + 3) & 0xff;
    }
  }

  @override
  void warmup() {
    for (var i = 0; i < 100; ++i) {
      run();
    }
  }

  @override
  void teardown() {
    for (var i = 0; i < size; ++i) {
      if (result[i] != ((i + 3) & 0xff)) {
        throw 'Unexpected result';
      }
    }
  }
}

class Uint8ListCopyViaFromListBenchmark extends Uint8ListCopyBenchmark {
  Uint8ListCopyViaFromListBenchmark(int size) : super('fromList', size);

  @override
  void run() {
    result = Uint8List.fromList(input);
  }
}

class Uint8ListCopyViaLoopBenchmark extends Uint8ListCopyBenchmark {
  Uint8ListCopyViaLoopBenchmark(int size) : super('loop', size);

  @override
  void run() {
    final input = this.input;
    final result = Uint8List(input.length);
    for (var i = 0; i < input.length; i++) {
      result[i] = input[i];
    }
    this.result = result;
  }
}

abstract class Float64ListCopyBenchmark extends BenchmarkBase {
  final int size;
  Float64List input;
  Float64List result;

  Float64ListCopyBenchmark(String method, this.size)
      : super('TypedDataDuplicate.Float64List.$size.$method');

  @override
  void setup() {
    input = Float64List(size);
    for (var i = 0; i < size; ++i) {
      input[i] = (i - 7).toDouble();
    }
  }

  @override
  void teardown() {
    for (var i = 0; i < size; ++i) {
      if (result[i] != (i - 7).toDouble()) {
        throw 'Unexpected result';
      }
    }
  }
}

class Float64ListCopyViaFromListBenchmark extends Float64ListCopyBenchmark {
  Float64ListCopyViaFromListBenchmark(int size) : super('fromList', size);

  @override
  void run() {
    result = Float64List.fromList(input);
  }
}

class Float64ListCopyViaLoopBenchmark extends Float64ListCopyBenchmark {
  Float64ListCopyViaLoopBenchmark(int size) : super('loop', size);

  @override
  void run() {
    final input = this.input;
    final result = Float64List(input.length);
    for (var i = 0; i < input.length; i++) {
      result[i] = input[i];
    }
    this.result = result;
  }
}

void main() {
  final sizes = [8, 32, 256, 16384];
  final benchmarks = [
    for (int size in sizes) ...[
      Uint8ListCopyViaLoopBenchmark(size),
      Uint8ListCopyViaFromListBenchmark(size)
    ],
    for (int size in sizes) ...[
      Float64ListCopyViaLoopBenchmark(size),
      Float64ListCopyViaFromListBenchmark(size)
    ]
  ];
  for (var bench in benchmarks) {
    bench.report();
  }
}
