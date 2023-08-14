// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.=> defineTests();

/// This tests the benchmarks in benchmark/benchmark.test, and ensures that our
/// benchmarks can run.
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_utilities/package_root.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() => defineTests();

String get _serverSourcePath {
  return path.join(packageRoot, 'analysis_server');
}

void defineTests() {
  group('benchmarks', () {
    var benchmarks = _listBenchmarks();

    test('can list', () {
      expect(benchmarks, isNotEmpty);
    });

    const benchmarkIdsToSkip = {
      'analysis-flutter-analyze',
      'das-flutter',
      'lsp-flutter',
    };

    // Since these benchmarks can take a while, allow skipping with an env
    // variable.
    final runBenchmarks =
        Platform.environment['TEST_SERVER_BENCHMARKS'] != 'false';
    final skipReason = runBenchmarks
        ? null
        : 'Skipped by TEST_SERVER_BENCHMARKS environment variable';

    for (var benchmarkId in benchmarks) {
      if (benchmarkIdsToSkip.contains(benchmarkId)) {
        continue;
      }

      test(benchmarkId, () {
        var r = Process.runSync(
          Platform.resolvedExecutable,
          [
            path.join('benchmark', 'benchmarks.dart'),
            'run',
            '--repeat=1',
            '--quick',
            benchmarkId
          ],
          workingDirectory: _serverSourcePath,
        );
        expect(r.exitCode, 0,
            reason: 'exit: ${r.exitCode}\n${r.stdout}\n${r.stderr}');
      }, skip: skipReason);
    }
  });
}

List<String> _listBenchmarks() {
  var result = Process.runSync(
    Platform.resolvedExecutable,
    [path.join('benchmark', 'benchmarks.dart'), 'list', '--machine'],
    workingDirectory: _serverSourcePath,
  );
  var output = json.decode(result.stdout as String) as Map<Object?, Object?>;
  var benchmarks = (output['benchmarks'] as List).cast<Map<Object?, Object?>>();
  return benchmarks.map((b) => b['id']).cast<String>().toList();
}
