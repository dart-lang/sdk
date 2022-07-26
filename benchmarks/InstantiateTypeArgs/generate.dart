// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generates both the dart and dart2 version of this benchmark.

import 'dart:io';

import 'package:path/path.dart' as path;

const String benchmarkName = 'InstantiateTypeArgs';

/// How many classes/calls to create for the InstantiateOnce and
/// RepeatInstantiateOnce benchmarks.
const int instantiateOnceCount = 1000;

/// How many classes/calls to create for the InstantiateMany and
/// RepeatInstantiateMany benchmarks.
const int instantiateManyCount = 1000;

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

  output.writeln('''
import 'package:benchmark_harness/benchmark_harness.dart';

void main() {
  // Instantiates a series of types, each type instantiated with a single type.
  const InstantiateOnce().report();
  // Repeats the instantiations in InstantiateOnce, this time depending
  // on the now-filled caches.
  const RepeatInstantiateOnce().report();
  // Instantiates a single type many times, each type being a new instantiation.
  const InstantiateMany().report();
  // Repeats the instantiations in InstantiateMany, this time depending on the
  // now-filled cache.
  const RepeatInstantiateMany().report();
}

class InstantiateOnce extends BenchmarkBase {
  const InstantiateOnce() : super('$benchmarkName.InstantiateOnce');

  // Only call run once, else the remaining runs will have the cached types.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateOnce<B>();
  }
}

class RepeatInstantiateOnce extends BenchmarkBase {
  const RepeatInstantiateOnce()
      : super('$benchmarkName.RepeatInstantiateOnce');

  @override
  void setup() {
    // Run once to make sure the instantiations are cached, in case this
    // benchmark is run on its own.
    instantiateOnce<B>();
  }

  // Only call run once, so this is directly comparable to InstantiateOnce.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateOnce<B>();
  }
}

class InstantiateMany extends BenchmarkBase {
  const InstantiateMany() : super('$benchmarkName.InstantiateMany');

  // Only call run once, else the remaining runs will have the cached types.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateMany();
  }
}

class RepeatInstantiateMany extends BenchmarkBase {
  const RepeatInstantiateMany()
      : super('$benchmarkName.RepeatInstantiateMany');

  @override
  void setup() {
    // Run once to make sure the instantiations are cached, in case this
    // benchmark is run on its own.
    instantiateMany();
  }

  // Only call run once, so this is directly comparable to InstantiateMany.
  @override
  void exercise() => run();

  @override
  void run() {
    instantiateMany();
  }
}

@pragma('vm:never-inline')
void blackhole<T>() => null;

class B {}

class D<T> {
  @pragma('vm:never-inline')
  static void instantiate<T>() => blackhole<D<T>>();
}
''');
}

void generateInstantiateOnce(IOSink output) {
  for (int i = 0; i < instantiateOnceCount; i++) {
    output
      ..writeln('class A${i}<T> {}')
      ..writeln('');
  }

  output.writeln('void instantiateOnce<T>() {');
  for (int i = 0; i < instantiateOnceCount; i++) {
    output.writeln('  blackhole<A${i}<T>>();');
  }
  output
    ..writeln('}')
    ..writeln('');
}

void generateInstantiateMany(IOSink output) {
  for (int i = 0; i < instantiateManyCount; i++) {
    output
      ..writeln('class C${i} {}')
      ..writeln('');
  }

  output.writeln('void instantiateMany() {');
  for (int i = 0; i < instantiateOnceCount; i++) {
    output.writeln('  D.instantiate<C${i}>();');
  }
  output.writeln('}');
}

void main() {
  final dartFilePath = path.join(
      path.dirname(Platform.script.path), 'dart', '$benchmarkName.dart');
  final dartSink = File(dartFilePath).openWrite();
  generateBenchmarkClassesAndUtilities(dartSink, nnbd: true);
  generateInstantiateOnce(dartSink);
  generateInstantiateMany(dartSink);
  dartSink..flush();

  final dart2FilePath = path.join(
      path.dirname(Platform.script.path), 'dart2', '$benchmarkName.dart');
  final dart2Sink = File(dart2FilePath).openWrite();
  generateBenchmarkClassesAndUtilities(dart2Sink, nnbd: false);
  generateInstantiateOnce(dart2Sink);
  generateInstantiateMany(dart2Sink);
  dart2Sink..flush();
}
