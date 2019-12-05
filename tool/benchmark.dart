// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:linter/src/util/ascii_utils.dart';
import 'package:linter/src/utils.dart';

import '../test/ascii_utils_test.dart' as utils_test;

/// Micro-benchmarks.
///
/// More comprehensive benchmarks are run like so:
///
///     dart bin/linter.dart --benchmark -q -c example/all.yaml .
void main() {
  FileNameRegexpTestBenchmarkGood().report();
  FileNameCharLoopTestBenchmarkGood().report();
  FileNameRegexpTestBenchmarkBad().report();
  FileNameCharLoopTestBenchmarkBad().report();
  AllMatchesBenchmark().report();
  DotScanBenchmark().report();
}

final badFileNames = utils_test.badFileNames;

final goodFileNames = utils_test.goodFileNames;

class AllMatchesBenchmark extends BaseBenchmark {
  const AllMatchesBenchmark() : super('AllMatches');

  @override
  void run() {
    for (var name in ['foo.dart', 'a-b.dart', 'a-b.css.dart', 'foo']) {
      //Test.
      '\.'.allMatches(name).length;
    }
  }
}

class BaseBenchmark extends BenchmarkBase {
  const BaseBenchmark(String name) : super(name);

  @override
  void exercise() {
    for (var i = 0; i < 100; i++) {
      run();
    }
  }
}

class DotScanBenchmark extends BaseBenchmark {
  const DotScanBenchmark() : super('DotScan');

  bool hasOneDot(String name) {
    var count = 0;
    for (var i = 0; i < name.length; ++i) {
      final character = name.codeUnitAt(i);
      count += isDot(character) ? 1 : 0;
      if (count > 1) {
        return false;
      }
    }
    return count == 1;
  }

  @override
  void run() {
    // ignore: prefer_foreach
    for (var name in ['foo.dart', 'a-b.dart', 'a-b.css.dart', 'foo']) {
      hasOneDot(name);
    }
  }
}

class FileNameCharLoopTestBenchmarkBad extends BenchmarkBase {
  const FileNameCharLoopTestBenchmarkBad() : super('Loop:Bad');

  @override
  void run() {
    badFileNames.forEach(isValidDartFileName);
  }
}

class FileNameCharLoopTestBenchmarkGood extends BenchmarkBase {
  const FileNameCharLoopTestBenchmarkGood() : super('Loop:Good');

  @override
  void run() {
    goodFileNames.forEach(isValidDartFileName);
  }
}

class FileNameRegexpTestBenchmarkBad extends BenchmarkBase {
  const FileNameRegexpTestBenchmarkBad() : super('Regexp:Bad');

  @override
  void run() {
    badFileNames.forEach(isLowerCaseUnderScoreWithDots);
  }
}

class FileNameRegexpTestBenchmarkGood extends BaseBenchmark {
  const FileNameRegexpTestBenchmarkGood() : super('Regexp:Good');

  @override
  void run() {
    goodFileNames.forEach(isLowerCaseUnderScoreWithDots);
  }
}
