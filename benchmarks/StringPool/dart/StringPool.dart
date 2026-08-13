// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

import 'version1a.dart';
import 'version1b.dart';
import 'version2.dart';

// ## Organization
//
// version1a.dart is the same version1b.dart except for renaming of functions.
//
// Both contain the same ~1500 distinct large string literals. An application
// will be smaller if compiled with sharing of the string constant values
// between the corresponding functions in version1a.dart and version1b.dart.
//
// version2.dart has the same general pattern as version1{a,b}.dart, but with
// unique string literals. As these literals have only one occurrence in the
// program, they will not be pooled for access from multiple functions.
//
// StringPool100.dart is a separate benchmark program that, after tree-shaking,
// has a 'small' string pool of ~100 strings rather than the ~1500 strings in
// this file. This has to be a separate program since the string pool generated
// by dart2js is for the whole-program (or whole deferred fragment).
//
// ## Interpretation
//
// Displayed results are normalized by the number of String literals accessed.
//
// StringPool.N.pooled uses N strings from the string pool.
// StringPool.N.unpooled uses N strings without string pooling.
//
// Comparing StringPool.1500.{pooled,unpooled} gives an indication of the cost
// of a large string pool.
//
// Comparing StringPool.100.{pooled,unpooled} gives an indication of the cost
// of a small string pool.
//
// Comparing StringPool.{100,1500}.pooled gives an indication of the cost
// of a large string pool compared to a small string pool.

const kStringLiteralsPerRun = 100000;

typedef Gen = List<String> Function(String);

abstract class StringPoolBase extends BenchmarkBase {
  StringPoolBase(String name) : super('StringPool.$name');

  // A list of functions that generate a list of strings.
  List<Gen> get functions;

  // The input list of generators is padded to a fixed length with one of the
  // generators.
  List<Gen> get _functions => __functions ?? complete(List.of(functions), 50);
  List<Gen>? __functions;

  List<Gen> complete(List<Gen> list, int targetLength) {
    while (list.length != targetLength) {
      // The List is stretched using the same function so that one function is
      // similarly hot and potentially JIT-ed in the `.1500.` and `.100.`
      // benchmarks.
      list.add(list.first);
    }
    return list;
  }

  @override
  void run() {
    int count = 0;
    LOOP:
    while (true) {
      for (final f in _functions) {
        final result = f(name);
        sink = result;
        count += result.length - 1; // First string is parameter
        if (count >= kStringLiteralsPerRun) break LOOP;
      }
    }
  }

  @override
  void exercise() {
    // Run once instead of default 10 times since we do a lot of work in `run`.
    run();
  }
}

class V1 extends StringPoolBase {
  V1() : super('1500.pooled');

  @override
  late final functions = version1ax1500();
}

class V1Copy extends StringPoolBase {
  V1Copy() : super('1500.pooled.copy');

  @override
  late final functions = version1bx1500();
}

class V2 extends StringPoolBase {
  V2() : super('1500.unpooled');

  @override
  late final functions = version2x1500();
}

dynamic sink;

void main() {
  // Compare results of V1 and V1Copy to ensure both classes and their reachable
  // functions are in the program.
  V1()
    ..setup()
    ..run()
    ..run();
  final sink1a = sink;
  V1Copy()
    ..setup()
    ..run()
    ..run();
  final sink1b = sink;
  if (sink1a.length != sink1b.length) throw StateError('Not same length');

  V2()
    ..setup()
    ..run()
    ..run();
  final sink2 = sink;
  if (sink1a.length != sink2.length) throw StateError('Not same length');

  V1().report();
  V2().report();
}
