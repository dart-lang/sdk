// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generates both the dart and dart2 version of this benchmark.

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;

const String benchmarkName = 'SubtypeTestCache';

const List<int> assertionCounts = [
  1,
  5,
  10,
  25,
  50,
  75,
  100,
  250,
  500,
  750,
  1000
];

void generateBenchmarkClassesAndUtilities(IOSink output) {
  final maxCount = assertionCounts.reduce(max);
  output.writeln('''
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This benchmark suite measures the overhead of looking up elements of
// SubtypeTestCaches, which are used when a type testing stub cannot determine
// whether a given type is assignable.

import 'package:benchmark_harness/benchmark_harness.dart';

void main() {''');

  // We must run the benchmarks from smallest count to largest, since a single
  // STC is shared across all the benchmarks (due to the single call site in
  // [check]). This ensures that benchmarks that are testing counts small
  // enough for a linear STC use a linear STC.
  final sortedCounts = assertionCounts.toList(growable: false);
  sortedCounts.sort();
  for (final count in sortedCounts) {
    output.write('''
  const STC$count().report();
''');
  }
  // We need to run the STCSame<max> benchmark only after running all the
  // STC<count> benchmarks, so that we ensure the shared STC is properly primed.
  output.write('''
  const STCSame$maxCount().report();
''');
  output.writeln('''
}

class STCBenchmarkBase extends BenchmarkBase {
  final int count;
  const STCBenchmarkBase(String name, this.count) : super(name);

  // Normalize the cost across the benchmarks by number of type tests.
  @override
  void report() => emitter.emit(name, measure() / count);
}
''');

  for (final count in assertionCounts) {
    output.write('''
class STC$count extends STCBenchmarkBase {
  const STC$count() : super('$benchmarkName.STC$count', $count);

  @override
  void run() {
''');

    for (int i = 0; i < count; i++) {
      output.write('''
    check<int>(instances[$i]);
''');
    }

    output.writeln('''
  }
}
''');
  }

  output.write('''
class STCSame$maxCount extends STCBenchmarkBase {
  const STCSame$maxCount() : super('$benchmarkName.STCSame$maxCount', $maxCount);

  @override
  void run() {
    // Do $maxCount AssertAssignable checks for the last type checked in the
    // STC$maxCount benchmark.
''');

  for (int i = 0; i < maxCount; i++) {
    output.write('''
    check<int>(instances[${maxCount - 1}]);
''');
  }

  output.writeln('''
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
void check<S>(dynamic s) => s as C<S> Function();

class C<T> {}
''');

  for (int i = 0; i < maxCount; i++) {
    output.write('''
class C$i<T> extends C<T> {}

C$i<S> closure$i<S>() => C$i<S>();

''');
  }

  // We create constant tearoffs of the closures above to use for our values
  // in the `as` checks. We could make constant instances of the classes, but
  // the specialized TTS for the `C` class hierarchy means that we'll never
  // actually hit the SubtypeTestCache!
  //
  // Using closures both avoids the likelihood of eventually optimizing the TTS
  // for this check and making this benchmark outdated and also ensures the VM
  // performs the most intensive check for each STC entry, i.e., the
  // Subtype7TestCache stub is called.
  output.write('''
const instances = <dynamic>[
''');
  for (int i = 0; i < maxCount; i++) {
    output.write('''
  closure$i<int>,
''');
  }
  output.write('''
];
''');
}

void main() {
  final dartFilePath = path.join(
      path.dirname(Platform.script.path), 'dart', '$benchmarkName.dart');
  final dartSink = File(dartFilePath).openWrite();
  generateBenchmarkClassesAndUtilities(dartSink);
  dartSink..flush();
}
