// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'sound_splay_tree.dart';

List<int> sieve(List<int> initialCandidates) {
  final candidates = SplayTreeSet<int>.from(initialCandidates);
  final int last = candidates.last;
  final primes = <int>[];
  // ignore: literal_only_boolean_expressions
  while (true) {
    final int prime = candidates.first;
    if (prime * prime > last) break;
    primes.add(prime);
    for (int i = prime; i <= last; i += prime) {
      candidates.remove(i);
    }
  }
  return primes..addAll(candidates);
}

List<int> sieveSound(List<int> initialCandidates) {
  final candidates = SoundSplayTreeSet<int>.from(initialCandidates);
  final int last = candidates.last;
  final primes = <int>[];
  // ignore: literal_only_boolean_expressions
  while (true) {
    final int prime = candidates.first;
    if (prime * prime > last) break;
    primes.add(prime);
    for (int i = prime; i <= last; i += prime) {
      candidates.remove(i);
    }
  }
  return primes..addAll(candidates);
}

/// Returns a list of integers from [first] to [last], both inclusive.
List<int> range(int first, int last) {
  return List<int>.generate(last - first + 1, (int i) => i + first);
}

int id(int x) => x;
int add1(int i) => 1 + i;
bool isEven(int i) => i.isEven;
void exercise(Iterable<int> hello) {
  if (hello.toList().length != 5) throw 'x1';
  if (List.from(hello).length != 5) throw 'x1';
  if (Set.from(hello).length != 4) throw 'x1';
  if (List<int>.from(hello).where(isEven).length != 3) throw 'x1';
  if (hello.where(isEven).length != 3) throw 'x1';
  if (hello.map(add1).where(isEven).length != 2) throw 'x1';
  if (hello.where(isEven).map(add1).length != 3) throw 'x1';
}

void busyWork() {
  // A lot of busy-work calling map/where/toList/List.from to ensure the core
  // library is used with some degree of polymorphism.
  final L1 = 'hello'.codeUnits;
  final L2 = Uint16List(5)..setRange(0, 5, L1);
  final L3 = Uint32List(5)..setRange(0, 5, L1);
  exercise(L1);
  exercise(L2);
  exercise(L3);
  exercise(UnmodifiableListView<int>(L1));
  exercise(UnmodifiableListView<int>(L2));
  exercise(UnmodifiableListView<int>(L3));
  exercise(L1.asMap().values);
  exercise(L1.toList().asMap().values);
  final M1 =
      Map<String, int>.fromIterables(<String>['a', 'b', 'c', 'd', 'e'], L1);
  final M2 = const <String, int>{
    'a': 104,
    'b': 101,
    'c': 108,
    'd': 108,
    'e': 111
  };
  exercise(M1.values);
  exercise(M2.values);
}

main() {
  final benchmarks = [
    Base(sieve, 'CollectionSieves-SplayTreeSet-removeLoop'),
    Base(sieveSound, 'CollectionSieves-SoundSplayTreeSet-removeLoop'),
  ];
  for (int i = 0; i < 10; i++) {
    busyWork();
    for (var bm in benchmarks) {
      bm.run();
    }
  }
  for (var bm in benchmarks) {
    bm.report();
  }
}

class Base extends BenchmarkBase {
  final algorithm;
  Base(this.algorithm, String name) : super(name);
  static final input = range(2, 5000);
  void run() {
    final primes = algorithm(input);
    if (primes.length != 669) throw 'Wrong result for $name: ${primes.length}';
  }
}
