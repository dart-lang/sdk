// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../benchmarks.dart';
import 'utils.dart';

/// benchmarks:
///   - analysis-flutter-analyze
class FlutterAnalyzeBenchmark extends Benchmark implements FlutterBenchmark {
  late final String flutterRepositoryPath;

  FlutterAnalyzeBenchmark()
    : super(
        'analysis-flutter-analyze',
        'Clone the flutter/flutter repo and run '
            "'flutter analyze --flutter-repo' with the current Dart VM and "
            'analysis server.',
        kind: 'cpu',
      );

  @override
  int get maxIterations => 3;

  @override
  Future<BenchMarkResult> run({
    required String dartSdkPath,
    bool quick = false,
    bool verbose = false,
  }) async {
    if (!quick) {
      deleteServerCache();
    }

    var stopwatch = Stopwatch()..start();

    await runProcess(
      '$dartSdkPath/bin/dart',
      [
        'packages/flutter_tools/bin/flutter_tools.dart',
        'analyze',
        '--flutter-repo',
        '--dart-sdk',
        dartSdkPath,
      ],
      cwd: flutterRepositoryPath,
      failOnError: false,
    );

    stopwatch.stop();

    return BenchMarkResult('micros', stopwatch.elapsedMicroseconds);
  }
}
