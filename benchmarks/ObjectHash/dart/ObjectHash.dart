// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: hash_and_equals

// Benchmark for `Object.hash` and `Object.hashAll`.

import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';

int get nextHash => Random().nextInt(0x20000000);

// An object with a fast hashCode.
class Leaf {
  @override
  final int hashCode = nextHash;
}

abstract class Node5 {
  final item1 = Leaf();
  final item2 = Leaf();
  final item3 = Leaf();
  final item4 = Random().nextBool();
  final item5 = nextHash;
}

class Node5Hash extends Node5 {
  // This is the main subject of the benchmark - a typical use of `Object.hash`.
  @override
  int get hashCode => Object.hash(item1, item2, item3, item4, item5);
}

class Node5Manual extends Node5 {
  // This is a similar quality hashCode but with statically resolvable
  // `hashCode` calls.
  @override
  int get hashCode => _SystemHash.hash5(item1.hashCode, item2.hashCode,
      item3.hashCode, item4.hashCode, item5.hashCode);
}

class Node5List extends Node5 {
  // This is a pattern that is sometimes used, especially for large numbers of
  // items.
  @override
  int get hashCode => Object.hashAll([item1, item2, item3, item4, item5]);
}

/// Returns a list with most values created by [makeValue], and a few objects of
/// different types so that the `hashCode` calls are polymorphic, like the ones
/// in the hashed collections.
List generateData(Object Function(int) makeValue) {
  final List data = List.generate(1000, makeValue);
  final exceptions = [
    Leaf(),
    Node5Hash(),
    Node5Manual(),
    Node5List(),
    '',
    true,
    false,
    123,
    Object()
  ];
  data.setRange(1, 1 + exceptions.length, exceptions);
  return data;
}

class BenchmarkNode5Hash extends BenchmarkBase {
  final List data = generateData((_) => Node5Hash());

  BenchmarkNode5Hash() : super('ObjectHash.hash.5');

  @override
  void run() {
    for (final e in data) {
      sink = e.hashCode;
    }
  }
}

class BenchmarkNode5Manual extends BenchmarkBase {
  final List data = generateData((_) => Node5Manual());

  BenchmarkNode5Manual() : super('ObjectHash.manual.5');

  @override
  void run() {
    for (final e in data) {
      sink = e.hashCode;
    }
  }
}

class BenchmarkNode5List extends BenchmarkBase {
  final List data = generateData((_) => Node5List());

  BenchmarkNode5List() : super('ObjectHash.list.5');

  @override
  void run() {
    for (final e in data) {
      sink = e.hashCode;
    }
  }
}

class BenchmarkNode5HashHashAll extends BenchmarkBase {
  final List data = generateData((_) => Node5Hash());

  BenchmarkNode5HashHashAll() : super('ObjectHash.hash.5.hashAll');

  @override
  void run() {
    sink = Object.hashAll(data);
  }
}

class BenchmarkNode5ManualHashAll extends BenchmarkBase {
  final List data = generateData((_) => Node5Manual());

  BenchmarkNode5ManualHashAll() : super('ObjectHash.manual.5.hashAll');

  @override
  void run() {
    sink = Object.hashAll(data);
  }
}

Object? sink;

void main() {
  generalUses();

  final benchmarks = [
    () => BenchmarkNode5Hash(),
    () => BenchmarkNode5Manual(),
    () => BenchmarkNode5List(),
    () => BenchmarkNode5HashHashAll(),
    () => BenchmarkNode5ManualHashAll(),
  ];

  // Warmup all benchmarks so that JIT compilers see full polymorphism before
  // measuring.
  for (var benchmark in benchmarks) {
    benchmark().warmup();
  }

  if (sink == null) throw StateError('sink unassigned');

  generalUses();

  for (var benchmark in benchmarks) {
    benchmark().report();
  }
}

/// Does a variety of calls to `Object.hash` to ensure the compiler does not
/// over-specialize the code on a few benchmark inputs.
void generalUses() {
  void check(int a, int b) {
    if (a != b) throw StateError('inconsistent');
  }

  // Exercise arity dispatch.
  check(Object.hash(1, 2), Object.hash(1, 2));
  check(Object.hash(1, 2, 3), Object.hash(1, 2, 3));
  check(Object.hash(1, 2, 3, 4), Object.hash(1, 2, 3, 4));
  check(Object.hash(1, 2, 3, 4, 5), Object.hash(1, 2, 3, 4, 5));
  check(Object.hash(1, 2, 3, 4, 5, 6), Object.hash(1, 2, 3, 4, 5, 6));
  check(Object.hash(1, 2, 3, 4, 5, 6, 7), Object.hash(1, 2, 3, 4, 5, 6, 7));

  final xs = Iterable.generate(20).toList();
  check(Function.apply(Object.hash, xs), Function.apply(Object.hash, xs));

  // Exercise internal hashCode dispatch.
  final a1 = 123;
  final a2 = 'hello';
  final a3 = true;
  final a4 = Object();
  final a5 = StringBuffer();
  const a6 = Point<int>(1, 2);
  const a7 = Rectangle<int>(100, 200, 1, 1);

  check(Object.hash(a1, a2, a3, a4, a5), Object.hash(a1, a2, a3, a4, a5));
  check(Object.hash(a2, a3, a4, a5, a6), Object.hash(a2, a3, a4, a5, a6));
  check(Object.hash(a3, a4, a5, a6, a7), Object.hash(a3, a4, a5, a6, a7));
  check(Object.hash(a4, a5, a6, a7, a1), Object.hash(a4, a5, a6, a7, a1));
  check(Object.hash(a5, a6, a7, a1, a2), Object.hash(a5, a6, a7, a1, a2));
  check(Object.hash(a6, a7, a1, a2, a3), Object.hash(a6, a7, a1, a2, a3));
  check(Object.hash(a7, a1, a2, a3, a4), Object.hash(a7, a1, a2, a3, a4));

  check(_SystemHash.hash2(1, 2), _SystemHash.hash2(1, 2));
  check(_SystemHash.hash3(1, 2, 3), _SystemHash.hash3(1, 2, 3));
  check(_SystemHash.hash4(1, 2, 3, 4), _SystemHash.hash4(1, 2, 3, 4));
  check(_SystemHash.hash5(1, 2, 3, 4, 5), _SystemHash.hash5(1, 2, 3, 4, 5));

  // Pollute hashAll argument type.
  check(Object.hashAll({}), Object.hashAll([]));
  check(Object.hashAll({}.values), Object.hashAll({}.keys));
  check(Object.hashAll(''.codeUnits), Object.hashAll(const Iterable.empty()));
  check(Object.hashAll(const [0]), Object.hashAll(Iterable.generate(1)));
}

// Partial copy of dart:internal `SystemHash` that is used by `Object.hash` so
// that we can create comparable manual hashCode methods.
class _SystemHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(int v1, int v2, [int seed = 0]) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    return finish(hash);
  }

  static int hash3(int v1, int v2, int v3, [int seed = 0]) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    return finish(hash);
  }

  static int hash4(int v1, int v2, int v3, int v4, [int seed = 0]) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    return finish(hash);
  }

  static int hash5(int v1, int v2, int v3, int v4, int v5, [int seed = 0]) {
    int hash = seed;
    hash = combine(hash, v1);
    hash = combine(hash, v2);
    hash = combine(hash, v3);
    hash = combine(hash, v4);
    hash = combine(hash, v5);
    return finish(hash);
  }
}
