// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generates both the dart and dart2 version of this benchmark.

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;

const String benchmarkName = 'InstantiateTypeArgs';

const List<int> instantiateCounts = [1, 5, 10, 100, 1000];

void generateBenchmarkClassesAndUtilities(IOSink output, {required bool nnbd}) {
  output.writeln('''
// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This benchmark suite measures the overhead of instantiating type arguments,
// with a particular aim of measuring the overhead of the caching mechanism.
''');

  if (!nnbd) {
    output.writeln('''
// @dart=2.9"
''');
  }

  output.write('''
import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
''');
  for (final count in instantiateCounts) {
    output.write('''
  const Instantiate$count().report();
''');
  }
  output.writeln('''
}
''');

  for (final count in instantiateCounts) {
    output.write('''
class Instantiate$count extends BenchmarkBase {
  const Instantiate$count() : super('$benchmarkName.Instantiate$count');

  // Normalize the cost across the benchmarks by number of instantiations.
  @override
  void report() => emitter.emit(name, measure() / $count);

  @override
  void run() {
''');

    for (int i = 0; i < count; i++) {
      output.write('''
    D.instantiate<C$i>();
''');
    }

    output.writeln('''
  }
}
''');
  }

  output.write('''
@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:never-inline')
void blackhole<T>() => null;

class D<T> {
  @pragma('vm:never-inline')
  @pragma('wasm:never-inline')
  @pragma('dart2js:never-inline')
  static void instantiate<S>() => blackhole<D<S>>();
}
''');

  final maxCount = instantiateCounts.reduce(max);
  for (int i = 0; i < maxCount; i++) {
    output.write('''

class C$i {}
''');
  }
}

void main() {
  final dartFilePath = path.join(
      path.dirname(Platform.script.path), 'dart', '$benchmarkName.dart');
  final dartSink = File(dartFilePath).openWrite();
  generateBenchmarkClassesAndUtilities(dartSink, nnbd: true);
  dartSink..flush();

  final dart2FilePath = path.join(
      path.dirname(Platform.script.path), 'dart2', '$benchmarkName.dart');
  final dart2Sink = File(dart2FilePath).openWrite();
  generateBenchmarkClassesAndUtilities(dart2Sink, nnbd: false);
  dart2Sink..flush();
}
