// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// # Benchmark for iterators of common collections.
///
/// The purpose of this benchmark is to detect performance changes in the
/// iterators for common collections (system Lists, Maps, etc).
///
/// ## Polymorphic benchmarks
///
/// Benchmark names beginning with `Iterators.poly.`.
///
/// These benchmark use the iterators from a common polymorphic for-in loop, so
/// none of the methods involved in iterating are inlined. This gives an
/// indication of worst-case performance.
///
/// Iterables of different sizes (small (N=1) and large (N=100)) are used to
/// give insight into the fixed vs per-element costs.
///
/// Results are normalized by iterating 1000 elements and reporting the time per
/// element. There is an outer loop that calls the iterator loop in `sinkAll`.
///
/// The dispatched (polymorphic) calls are to `get:iterator`, `moveNext` and
/// `get:current`.
///
///  |    N | outer | `get:iterator` | `moveNext` | `get:current` |
///  | ---: | ----: | -------------: | ---------: | ------------: |
///  |   0* |  1000 |           1000 |       1000 |             0 |
///  |   1  |  1000 |           1000 |       2000 |          1000 |
///  |   2* |   500 |            500 |       1500 |          1000 |
///  | 100  |    10 |             10 |       1010 |          1000 |
///
/// * By default only the N=1 and N=100 benchmarks arer run. The N=0 and N=2
/// series are available running manually with `--0` and `--2` command-line
/// arguments.
///
/// Generic Iterables have benchmarks for different element types. There are
/// benchmarks for `int` type arguments, which have a fast type test, and for
/// `Thing<Iterable<Comparable>>`, which is harder to test quickly. These tests
/// are distingished by `int` and `Hard` in the name.
///
/// ## Monomorphic benchmarks
///
/// Benchmark names beginning with `Iterators.mono.`.
///
/// A subset of the polymorphic benchmarks are also implemented with a
/// per-benchmark for-in loop directly iterating a collection of known
/// representation. This gives the compiler the opportunity to inline the
/// methods into the loop and represents the best-case performance.
///
/// ## Example benchmarks
///
/// The name has 4-7 words separated by periods. The first word is always
/// 'Iterators', and the second is either 'mono' for monomorphic loops, or
/// 'poly' for benchmarks using a shared polymorphic loop. The last word is a
/// number which is the size (length) of the Iterable.
///
/// ### Iterators.mono.const.Map.int.values.100
///
/// A for-in loop over the values iterable of a known constant Map with value
/// type `int` and 100 entries.
///
/// ### Iterators.poly.Runes.1
///
/// An interation over the String.runes iterable of a single character String
/// using the shared polymorphic loop.
///
/// ### Iterators.poly.HashMap.Hard.keys.100
///
/// An iteration of over the keys iterable of a HashMap with key type
/// `Thing<Iterable<Comparable>>` and 100 entries.
///
/// ### Iterators.*.UpTo.*
///
/// The UpTo iterable is a minimal iterable that provides successive
/// numbers. The `moveNext` and `get:current` methods are small. Comparing
/// Iterators.poly.UpTo.*.100 to Iterators.poly.*.100 gives an indication of how
/// much work is done by `moveNext` (and sometimes `get:current`).
///
/// ### Iterators.mono.Nothing.*
///
/// The Nothing benchmark has no iteration over an iterable and is used to get a
/// baseline time for running the benchmark loop for monomorphic
/// benchmarks. This can be a substantial fraction of
///
/// Consider the times
///
///     Iterators.mono.CodeUnits.1   = 7.0ns
///     Iterators.mono.Nothing.1     = 3.1ns
///
/// Because the trip count (i.e. 1) of the for-in loop is so small, there is a
/// lot of overhead attributable to the outer loop in `MonoBenchmark.run`. The
/// 1000/1 = 1000 trips of outer loops takes 3.1us (3.1ns * 1000 trips), so
/// CodeUnits is spending only 7.0-3.1 = 3.9ns per character in the for-in
/// loop over the `.codeUnits` of the single-character String.
///
///     Iterators.mono.CodeUnits.100 = 1.83ns
///     Iterators.mono.Nothing.100   = 0.05ns
///
/// Now the outer loop runs only 1000/100 = 10 times, for 0.05us. If we subtract
/// this from 1.83, we get 1.78ns per character for long strings.
///
library iterators_benchmark;

// TODO(48277): Update when fixed:
// ignore_for_file: unnecessary_lambdas

import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'data.dart';

const targetSize = 1000;

class Emitter implements ScoreEmitter {
  @override
  void emit(String testName, double value) {
    // [value] is microseconds per ten calls to `run()`.
    final nanoSeconds = value * 1000;
    final singleElementTimeNs = nanoSeconds / 10 / targetSize;
    print('$testName(RunTimeRaw): $singleElementTimeNs ns.');
  }
}

abstract class Benchmark extends BenchmarkBase {
  final int size;
  bool selected = false;
  Benchmark._(String name, this.size)
      : super('Iterators.$name.$size', emitter: Emitter());

  factory Benchmark(String name, int size, Iterable Function(int) generate) =
      PolyBenchmark;
}

abstract class MonoBenchmark extends Benchmark {
  final int _repeats;
  MonoBenchmark(String name, int size)
      : _repeats = size == 0 ? targetSize : targetSize ~/ size,
        super._('mono.$name', size);

  @override
  void run() {
    for (int i = 0; i < _repeats; i++) {
      sinkMono();
    }
  }

  void sinkMono();
}

class PolyBenchmark extends Benchmark {
  final Iterable Function(int) generate;
  final List<Iterable> inputs = [];

  PolyBenchmark(String name, int size, this.generate)
      : super._('poly.$name', size);

  @override
  void setup() {
    if (inputs.isNotEmpty) return; // Ensure setup() is idempotent.

    int totalSize = 0;
    while (totalSize < targetSize) {
      final sample = generate(size);
      inputs.add(sample);
      totalSize += size == 0 ? 1 : size;
    }
  }

  @override
  void run() {
    for (int i = 0; i < inputs.length; i++) {
      sinkAll(inputs[i]);
    }
  }
}

/// This function is the inner loop of the benchmark.
@pragma('dart2js:noInline')
@pragma('vm:never-inline')
void sinkAll(Iterable iterable) {
  for (final value in iterable) {
    sink = value;
  }
}

Object? sink;

class BenchmarkConstMapIntKeys1 extends MonoBenchmark {
  BenchmarkConstMapIntKeys1() : super('const.Map.int.keys', 1);

  static const _map = constMapIntInt1;

  @override
  void sinkMono() {
    for (final value in _map.keys) {
      sink = value;
    }
  }
}

class BenchmarkConstMapIntKeys2 extends MonoBenchmark {
  BenchmarkConstMapIntKeys2() : super('const.Map.int.keys', 2);

  static const _map = constMapIntInt2;

  @override
  void sinkMono() {
    for (final value in _map.keys) {
      sink = value;
    }
  }
}

class BenchmarkConstMapIntKeys100 extends MonoBenchmark {
  BenchmarkConstMapIntKeys100() : super('const.Map.int.keys', 100);

  static const _map = constMapIntInt100;

  @override
  void sinkMono() {
    for (final value in _map.keys) {
      sink = value;
    }
  }
}

class BenchmarkConstMapIntValues1 extends MonoBenchmark {
  BenchmarkConstMapIntValues1() : super('const.Map.int.values', 1);

  static const _map = constMapIntInt1;

  @override
  void sinkMono() {
    for (final value in _map.values) {
      sink = value;
    }
  }
}

class BenchmarkConstMapIntValues2 extends MonoBenchmark {
  BenchmarkConstMapIntValues2() : super('const.Map.int.values', 2);

  static const _map = constMapIntInt2;

  @override
  void sinkMono() {
    for (final value in _map.values) {
      sink = value;
    }
  }
}

class BenchmarkConstMapIntValues100 extends MonoBenchmark {
  BenchmarkConstMapIntValues100() : super('const.Map.int.values', 100);

  static const _map = constMapIntInt100;

  @override
  void sinkMono() {
    for (final value in _map.values) {
      sink = value;
    }
  }
}

class BenchmarkMapIntKeys extends MonoBenchmark {
  BenchmarkMapIntKeys(int size) : super('Map.int.keys', size) {
    _map.addAll(generateMapIntInt(size));
  }

  final Map<int, int> _map = {};

  @override
  void sinkMono() {
    for (final value in _map.keys) {
      sink = value;
    }
  }
}

class BenchmarkUpTo extends MonoBenchmark {
  BenchmarkUpTo(int size) : super('UpTo', size);

  @override
  void sinkMono() {
    for (final value in UpTo(size)) {
      sink = value;
    }
  }
}

class BenchmarkNothing extends MonoBenchmark {
  BenchmarkNothing(int size) : super('Nothing', size);

  @override
  void sinkMono() {
    sink = size;
  }
}

class BenchmarkCodeUnits extends MonoBenchmark {
  BenchmarkCodeUnits(int size)
      : string = generateString(size),
        super('CodeUnits', size);

  final String string;

  @override
  void sinkMono() {
    for (final value in string.codeUnits) {
      sink = value;
    }
  }
}

class BenchmarkListIntGrowable extends MonoBenchmark {
  BenchmarkListIntGrowable(int size)
      : _list = List.generate(size, (i) => i),
        super('List.int.growable', size);

  final List<int> _list;

  @override
  void sinkMono() {
    for (final value in _list) {
      sink = value;
    }
  }
}

class BenchmarkListIntSystem1 extends MonoBenchmark {
  // The List type here is not quite monomorphic. It is the choice between two
  // 'system' Lists: a const List and a growable List. It is quite common to
  // have growable and const lists at the same use-site (e.g. the const coming
  // from a default argument).
  //
  // Ideally some combination of the class heirarchy or compiler tricks would
  // ensure there is little cost of having this gentle polymorphism.
  BenchmarkListIntSystem1(int size)
      : _list1 = List.generate(size, (i) => i),
        _list2 = generateConstListOfInt(size),
        super('List.int.growable.and.const', size);

  final List<int> _list1;
  final List<int> _list2;
  bool _flip = false;

  @override
  void sinkMono() {
    _flip = !_flip;
    final list = _flip ? _list1 : _list2;
    for (final value in list) {
      sink = value;
    }
  }
}

class BenchmarkListIntSystem2 extends MonoBenchmark {
  // The List type here is not quite monomorphic. It is the choice between two
  // 'system' Lists: a const List and a fixed-length List. It is quite common to
  // have fixed-length and const lists at the same use-site (e.g. the const
  // coming from a default argument).
  //
  // Ideally some combination of the class heirarchy or compiler tricks would
  // ensure there is little cost of having this gentle polymorphism.
  BenchmarkListIntSystem2(int size)
      : _list1 = List.generate(size, (i) => i, growable: false),
        _list2 = generateConstListOfInt(size),
        super('List.int.fixed.and.const', size);

  final List<int> _list1;
  final List<int> _list2;
  bool _flip = false;

  @override
  void sinkMono() {
    _flip = !_flip;
    final list = _flip ? _list1 : _list2;
    for (final value in list) {
      sink = value;
    }
  }
}

/// A simple Iterable that yields the integers 0 through `length`.
///
/// This Iterable serves as the minimal interesting example to serve as a
/// baseline, and is useful in constructing other benchmark inputs.
class UpTo extends IterableBase<int> {
  final int _length;
  UpTo(this._length);

  @override
  Iterator<int> get iterator => UpToIterator(_length);
}

class UpToIterator implements Iterator<int> {
  final int _length;
  int _position = 0;
  int? _current;

  UpToIterator(this._length);

  @override
  int get current => _current!;

  @override
  bool moveNext() {
    if (_position < _length) {
      _current = _position++;
      return true;
    }
    _current = null;
    return false;
  }
}

/// A `Thing` has a type parameter which makes type tests in the Iterators
/// potentially harder, and equality uses the type parameter, making Iterables
/// that do lookups slower.
class Thing<T> {
  static int _nextIndex = 0;
  final int _index;
  Thing() : _index = _nextIndex++;

  @override
  int get hashCode => _index;

  @override
  bool operator ==(Object other) => other is Thing<T> && other._index == _index;
}

final thingGenerators = [
  // TODO(48277): Use instantiated constructor tear-offs when fixed:
  () => Thing<Set<String>>(),
  () => Thing<Set<Duration>>(),
  () => Thing<Set<BigInt>>(),
  () => Thing<Queue<String>>(),
  () => Thing<Queue<Duration>>(),
  () => Thing<Queue<BigInt>>(),
  () => Thing<List<String>>(),
  () => Thing<List<Duration>>(),
  () => Thing<List<BigInt>>(),
];

int _generateThingListState = 0;
List<Thing<Iterable<Comparable>>> generateThingList(int n) {
  Thing nextThing(_) {
    final next = (_generateThingListState++).remainder(thingGenerators.length);
    return thingGenerators[next]();
  }

  return List.from(UpTo(n).map(nextThing));
}

Map<Thing<Iterable<Comparable>>, Thing<Iterable<Comparable>>> generateThingMap(
    int n) {
  return Map.fromIterables(generateThingList(n), generateThingList(n));
}

Map<Thing<Iterable<Comparable>>, Thing<Iterable<Comparable>>>
    generateThingHashMap(int n) {
  return HashMap.fromIterables(generateThingList(n), generateThingList(n));
}

int _generateStringState = 0;
String generateString(int n) {
  return ((_generateStringState++).isEven ? 'x' : '\u2192') * n;
}

Map<int, int> generateMapIntInt(int n) =>
    Map<int, int>.fromIterables(UpTo(n), UpTo(n));

Map<int, int> generateIdentityMapIntInt(int n) {
  return Map<int, int>.identity()..addAll(generateMapIntInt(n));
}

/// Run the benchmark loop on various inputs to pollute type inference and JIT
/// caches.
void pollute() {
  // This iterable reads `sink` mid-loop, making it infeasible for the compiler
  // to move the write to `sink` out of the loop.
  sinkAll(UpTo(100).map((i) {
    if (i > 0 && sink != i - 1) throw StateError('sink');
    return i;
  }));

  // TODO(sra): Do we need to add anything here? There are a lot of benchmarks,
  // so that is probably sufficient to make the necessary places polymorphic.
}

/// Command-line arguments:
///
/// `--0`: Run benchmarks for empty iterables.
/// `--1`: Run benchmarks for singleton iterables.
/// `--2`: Run benchmarks for two-element iterables.
/// `--100`: Run benchmarks for 100-element iterables.
///
///    Default sizes are 1 and 100.
///
/// `--all`: Run all benchmark variants and sizes.
///
/// `foo`, `foo.bar`: a Selector.
///
///    Run benchmarks with name containing all the dot-separated words in the
///    selector, so `--Set.const` will run benchmark
///    'Iterators.const.Set.int.N`, and `--2.UpTo` will select
///    `Iterators.UpTo.2`.  Each selector is matched independently, and if
///    selectors are used, only benchmarks matching some selector are run.
///
void main(List<String> commandLineArguments) {
  final arguments = [...commandLineArguments];

  const allSizes = {0, 1, 2, 100};
  const defaultSizes = {1, 100};
  final allSizeWords = Set.unmodifiable(allSizes.map((size) => '$size'));

  final Set<int> sizes = {};
  final Set<String> selectors = {};

  if (arguments.remove('--0')) sizes.add(0);
  if (arguments.remove('--1')) sizes.add(1);
  if (arguments.remove('--2')) sizes.add(2);
  if (arguments.remove('--100')) sizes.add(100);

  if (arguments.remove('--all')) {
    sizes.addAll(allSizes);
  }

  selectors.addAll(arguments);

  if (sizes.isEmpty) sizes.addAll(defaultSizes);
  if (selectors.isEmpty) selectors.add('Iterators');

  List<Benchmark> makeBenchmarksForSize(int size) {
    return [
      // Simple
      BenchmarkNothing(size),
      BenchmarkUpTo(size),
      BenchmarkCodeUnits(size),
      Benchmark('UpTo', size, (n) => UpTo(n)),
      Benchmark('CodeUnits', size, (n) => generateString(n).codeUnits),
      Benchmark('Runes', size, (n) => generateString(n).runes),
      // ---
      BenchmarkListIntGrowable(size),
      BenchmarkListIntSystem1(size),
      BenchmarkListIntSystem2(size),
      Benchmark('List.int.growable', size,
          (n) => List<int>.of(UpTo(n), growable: true)),
      Benchmark('List.int.fixed', size,
          (n) => List<int>.of(UpTo(n), growable: false)),
      Benchmark('List.int.unmodifiable', size,
          (n) => List<int>.unmodifiable(UpTo(n))),
      // ---
      Benchmark('List.Hard.growable', size, generateThingList),
      // ---
      Benchmark('Set.int', size, (n) => Set<int>.of(UpTo(n))),
      Benchmark('const.Set.int', size, generateConstSetOfInt),
      // ---
      BenchmarkMapIntKeys(size),
      Benchmark('Map.int.keys', size, (n) => generateMapIntInt(n).keys),
      Benchmark('Map.int.values', size, (n) => generateMapIntInt(n).values),
      Benchmark('Map.int.entries', size, (n) => generateMapIntInt(n).entries),
      // ---
      Benchmark('Map.identity.int.keys', size,
          (n) => generateIdentityMapIntInt(n).keys),
      Benchmark('Map.identity.int.values', size,
          (n) => generateIdentityMapIntInt(n).values),
      Benchmark('Map.identity.int.entries', size,
          (n) => generateIdentityMapIntInt(n).entries),
      // ---
      Benchmark(
          'const.Map.int.keys', size, (n) => generateConstMapIntInt(n).keys),
      Benchmark('const.Map.int.values', size,
          (n) => generateConstMapIntInt(n).values),
      Benchmark('const.Map.int.entries', size,
          (n) => generateConstMapIntInt(n).entries),
      // ---
      Benchmark('Map.Hard.keys', size, (n) => generateThingMap(n).keys),
      Benchmark('Map.Hard.values', size, (n) => generateThingMap(n).values),
      // ---
      Benchmark('HashMap.int.keys', size,
          (n) => HashMap<int, int>.fromIterables(UpTo(n), UpTo(n)).keys),
      Benchmark('HashMap.int.values', size,
          (n) => HashMap<int, int>.fromIterables(UpTo(n), UpTo(n)).values),
      Benchmark('HashMap.int.entries', size,
          (n) => HashMap<int, int>.fromIterables(UpTo(n), UpTo(n)).entries),
      // ---
      Benchmark('HashMap.Hard.keys', size, (n) => generateThingHashMap(n).keys),
      Benchmark(
          'HashMap.Hard.values', size, (n) => generateThingHashMap(n).values),
    ];
  }

  final benchmarks = [
    BenchmarkConstMapIntKeys1(),
    BenchmarkConstMapIntKeys2(),
    BenchmarkConstMapIntKeys100(),
    BenchmarkConstMapIntValues1(),
    BenchmarkConstMapIntValues2(),
    BenchmarkConstMapIntValues100(),
    for (final size in allSizes) ...makeBenchmarksForSize(size),
  ];

  // Select benchmarks
  final unusedSelectors = {...selectors};
  for (final benchmark in benchmarks) {
    final nameWords = benchmark.name.split('.').toSet();
    for (final selector in selectors) {
      final selectorWords = selector.split('.').toSet();
      if (nameWords.containsAll(selectorWords)) {
        unusedSelectors.remove(selector);
        if (selectorWords.any(allSizeWords.contains) ||
            sizes.contains(benchmark.size)) {
          benchmark.selected = true;
        }
        // continue matching to remove other matching selectors.
      }
    }
  }
  if (unusedSelectors.isNotEmpty) {
    throw ArgumentError(unusedSelectors, 'selectors match no benchmark');
  }

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (var benchmark in benchmarks) {
    pollute();
    benchmark.setup();
  }

  // Warm up all the benchmarks, including the non-selected ones.
  for (int i = 0; i < 10; i++) {
    for (var benchmark in benchmarks) {
      pollute();
      final marker = Object();
      sink = marker;
      benchmark.warmup();
      if (benchmark.size > 0 && identical(sink, marker)) throw 'unexpected';
    }
  }

  for (var benchmark in benchmarks) {
    // `report` calls `setup`, but `setup` is idempotent.
    if (benchmark.selected) {
      benchmark.report();
    }
  }
}
