// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';

// Benchmark for polymorphic map copying.
//
// The set of benchmarks compares the cost of copying default Maps
// (LinkedHashMaps) and HashMaps, for small and large maps.
//
// The maps have a key type `Object?`, since we want to use Strings, ints and
// user-defined types.  The class `Thing` is a used-defined type with an
// inexpensive hashCode operation. String keys are interesting because they are
// quite common, and are special-cased in the JavaScript runtime.
//
// Benchmarks have names following this pattern:
//
//     MapCopy.{Map,HashMap}.{String,Thing}.of.{Map,HashMap}.{N}
//     MapCopy.{Map,HashMap}.{String,Thing}.copyOf.{Map,HashMap}.{N}
//     MapCopy.{Map,HashMap}.{String,Thing}.fromEntries.{Map,HashMap}.{N}
//
// For example, MapCopy.Map.String.of.HashMap.2 would call
//
//     Map<Object, Object>.of(m)
//
// where `m` is a `HashMap<String, Object>` with 2 entries.
//
// The `copyOf` variant creates an empty map and populates it using `forEach`,
// so MapCopy.HashMap.Thing.copyOf.HashMap.100 would call:
//
//    HashMap<Object, Object> result = HashMap();
//    m.forEach((key, value) { result[key] = value; });
//
// where `m` is a `HashMap<Thing, Object>` with 100 entries.
//
// The `fromEntries` variant creates a map via `Map.fromEntries(other.entries)`.
//
// Benchmarks are run for small maps (e.g. 2 entries, names ending in `.2`) and
// 'large' maps (100 entries or `.100`). The benchmarks are normalized on the
// number of elements to make benchmarks with different input sizes more
// comparable.

abstract class Benchmark<K> extends BenchmarkBase {
  final String targetKind; // 'Map' or 'HashMap'.
  late final String keyKind = _keyKind(K); // 'String' or 'Thing' or 'int'.
  final String methodKind; // 'of' or 'copyOf' or 'fromEntries'.
  final String sourceKind; // 'Map' or 'HashMap'.
  final int length;
  final List<Map<Object?, Object>> inputs = [];

  Benchmark(this.targetKind, this.methodKind, this.sourceKind, this.length)
      : super('MapCopy.$targetKind.${_keyKind(K)}.$methodKind.$sourceKind'
            '.$length');

  static String _keyKind(Type type) {
    if (type == String) return 'String';
    if (type == int) return 'int';
    if (type == Thing) return 'Thing';
    throw UnsupportedError('Unsupported type $type');
  }

  /// Override this method with one that will copy [input] to [output].
  void copy();

  @override
  void setup() {
    // Ensure setup() is idempotent.
    if (inputs.isNotEmpty) return;

    const totalEntries = 1000;

    int totalLength = 0;
    while (totalLength < totalEntries) {
      final sample = makeSample();
      inputs.add(sample);
      totalLength += sample.length;
    }

    // Sanity checks.
    for (var sample in inputs) {
      if (sample.length != length) throw 'Wrong length: $length $sample';
    }
    if (totalLength != totalEntries) {
      throw 'totalLength $totalLength != expected $totalEntries';
    }
  }

  int _sequence = 0;

  Map<Object?, Object> makeSample() {
    late final Map<K, Object> sample;
    if (sourceKind == 'Map') sample = {};
    if (sourceKind == 'HashMap') sample = HashMap();
    for (int i = 1; i <= length; i++) {
      _sequence = (_sequence + 119) & 0x1ffffff;
      final K key = makeKey(_sequence);
      sample[key] = i;
    }
    return sample;
  }

  K makeKey(int i) {
    if (keyKind == 'String') return 'key-$i' as K;
    if (keyKind == 'int') return i as K;
    if (keyKind == 'Thing') return Thing() as K;
    throw UnsupportedError('Unsupported type $K');
  }

  @override
  void run() {
    for (var sample in inputs) {
      input = sample;
      copy();
    }
    if (output.length != inputs.first.length) throw 'Bad result: $output';
  }
}

class Thing {
  static int _counter = 0;
  final int _index;
  Thing() : _index = ++_counter;

  @override
  bool operator ==(Object other) => other is Thing && _index == other._index;

  @override
  int get hashCode => _index;
}

// All the 'copy' methods use [input] and [output] rather than a parameter and
// return value to avoid the possibility of a parametric covariance type check
// in the call sequence.
Map<Object?, Object> input = {};
var output;

class BaselineBenchmark extends Benchmark<String> {
  BaselineBenchmark(int length) : super('Map', 'baseline', 'Map', length);

  @override
  void copy() {
    // Dummy 'copy' to measure overhead of benchmarking loops.
    output = input;
  }
}

class MapOfBenchmark<K> extends Benchmark<K> {
  MapOfBenchmark(String sourceKind, int length)
      : super('Map', 'of', sourceKind, length);

  @override
  void copy() {
    output = Map<Object?, Object>.of(input);
  }
}

class HashMapOfBenchmark<K> extends Benchmark<K> {
  HashMapOfBenchmark(String sourceKind, int length)
      : super('HashMap', 'of', sourceKind, length);

  @override
  void copy() {
    output = HashMap<Object?, Object>.of(input);
  }
}

class MapCopyOfBenchmark<K> extends Benchmark<K> {
  MapCopyOfBenchmark(String sourceKind, int length)
      : super('Map', 'copyOf', sourceKind, length);

  @override
  void copy() {
    final map = <Object?, Object>{};
    input.forEach((k, v) {
      map[k] = v;
    });
    output = map;
  }
}

class HashMapCopyOfBenchmark<K> extends Benchmark<K> {
  HashMapCopyOfBenchmark(String sourceKind, int length)
      : super('HashMap', 'copyOf', sourceKind, length);

  @override
  void copy() {
    final map = HashMap<Object?, Object>();
    input.forEach((k, v) {
      map[k] = v;
    });
    output = map;
  }
}

class MapFromEntriesBenchmark<K> extends Benchmark<K> {
  MapFromEntriesBenchmark(String sourceKind, int length)
      : super('Map', 'fromEntries', sourceKind, length);

  @override
  void copy() {
    output = Map<Object?, Object>.fromEntries(input.entries);
  }
}

class HashMapFromEntriesBenchmark<K> extends Benchmark<K> {
  HashMapFromEntriesBenchmark(String sourceKind, int length)
      : super('HashMap', 'fromEntries', sourceKind, length);

  @override
  void copy() {
    output = HashMap<Object?, Object>.fromEntries(input.entries);
  }
}

/// Use the common methods for many different kinds of Map to make the calls in
/// the runtime implementation polymorphic.
void pollute() {
  final Map<String, Object> m1 = Map.of({'hello': 66});
  final Map<String, Object> m2 = HashMap.of(m1);
  final Map<int, Object> m3 = Map.of({1: 66});
  final Map<int, Object> m4 = HashMap.of({1: 66});
  final Map<Object, Object> m5 = Map.identity()
    ..[Thing()] = 1
    ..[Thing()] = 2;
  final Map<Object, Object> m6 = HashMap.identity()
    ..[Thing()] = 1
    ..[Thing()] = 2;
  final Map<Object, Object> m7 = UnmodifiableMapView(m1);
  final Map<Object, Object> m8 = UnmodifiableMapView(m2);
  final Map<Object, Object> m9 = UnmodifiableMapView(m3);
  final Map<Object, Object> m10 = UnmodifiableMapView(m4);

  int c = 0;
  for (final m in [m1, m2, m3, m4, m5, m6, m7, m8, m9, m10]) {
    final Map<Object, Object> d1 = Map.of(m);
    final Map<Object, Object> d2 = HashMap.of(m);
    // ignore: prefer_collection_literals
    final Map<Object, Object> d3 = Map()..addAll(m);
    final Map<Object, Object> d4 = {...m, ...m};
    final Map<Object, Object> d5 = HashMap()..addAll(m);
    final Map<Object, Object> d6 = Map.identity()..addAll(m);
    final Map<Object, Object> d7 = HashMap.identity()..addAll(m);
    final Map<Object, Object> d8 = Map.fromEntries(m.entries);
    final Map<Object, Object> d9 = HashMap.fromEntries(m.entries);
    for (final z in [d1, d2, d3, d4, d5, d6, d7, d8, d9]) {
      z.forEach((k, v) {
        c++;
      });
    }
  }
  const totalElements = 108;
  if (c != totalElements) throw StateError('c: $c != $totalElements');
}

/// Command-line arguments:
///
/// `--baseline`: Run additional benchmarks to measure the benchmarking loop
/// component.
///
/// `--cross`: Run additional benchmarks for copying between Map and
/// HashMap.
///
/// `--int`: Run additional benchmarks with `int` keys.
///
/// `--1`: Run additional benchmarks for singleton maps.
///
/// `--all`: Run all benchmark variants.
void main(List<String> commandLineArguments) {
  final arguments = [...commandLineArguments];

  bool includeBaseline = false;
  final Set<String> kinds = {'same'};
  final Set<String> types = {'String', 'Thing'};
  final Set<int> sizes = {2, 100};

  if (arguments.remove('--reset')) {
    kinds.clear();
    types.clear();
    sizes.clear();
  }

  if (arguments.remove('--baseline')) includeBaseline = true;
  if (arguments.remove('--cross')) kinds.add('cross');

  if (arguments.remove('--string')) types.add('String');
  if (arguments.remove('--thing')) types.add('Thing');
  if (arguments.remove('--int')) types.add('int');

  if (arguments.remove('--1')) sizes.add(1);
  if (arguments.remove('--2')) sizes.add(2);
  if (arguments.remove('--100')) sizes.add(100);

  if (arguments.remove('--all')) {
    kinds.addAll(['baseline', 'same', 'cross']);
    types.addAll(['String', 'Thing', 'int']);
    sizes.addAll([1, 2, 100]);
  }

  if (arguments.isNotEmpty) {
    throw ArgumentError('Unused command line arguments: $arguments');
  }

  if (kinds.isEmpty) kinds.add('same');
  if (types.isEmpty) types.add('String');
  if (sizes.isEmpty) sizes.add(2);

  List<Benchmark> makeBenchmarks<K>(int length) {
    return [
      // Map from Map
      if (kinds.contains('same')) ...[
        MapOfBenchmark<K>('Map', length),
        MapCopyOfBenchmark<K>('Map', length),
        MapFromEntriesBenchmark<K>('Map', length),
      ],
      // Map from HashMap
      if (kinds.contains('cross')) ...[
        MapOfBenchmark<K>('HashMap', length),
        MapCopyOfBenchmark<K>('HashMap', length),
        MapFromEntriesBenchmark<K>('HashMap', length),
      ],
      // HashMap from HashMap
      if (kinds.contains('same')) ...[
        HashMapOfBenchmark<K>('HashMap', length),
        HashMapCopyOfBenchmark<K>('HashMap', length),
        HashMapFromEntriesBenchmark<K>('HashMap', length),
      ],
      // HashMap from Map
      if (kinds.contains('cross')) ...[
        HashMapOfBenchmark<K>('Map', length),
        HashMapCopyOfBenchmark<K>('Map', length),
        HashMapFromEntriesBenchmark<K>('Map', length),
      ],
    ];
  }

  List<Benchmark> makeBenchmarksForLength(int length) {
    return [
      if (includeBaseline) BaselineBenchmark(length),
      if (types.contains('String')) ...makeBenchmarks<String>(length),
      if (types.contains('Thing')) ...makeBenchmarks<Thing>(length),
      if (types.contains('int')) ...makeBenchmarks<int>(length),
    ];
  }

  final benchmarks = [
    for (final length in sizes) ...makeBenchmarksForLength(length),
  ];

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (var benchmark in benchmarks) {
    pollute();
    benchmark.setup();
  }

  for (var benchmark in benchmarks) {
    pollute();
    benchmark.warmup();
  }

  for (var benchmark in benchmarks) {
    // `report` calls `setup`, but `setup` is idempotent.
    benchmark.report();
  }
}
