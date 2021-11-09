// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../benchmarks.dart';

Future<int> _runProcess(
  String command,
  List<String> args, {
  String? cwd,
  bool failOnError = true,
}) async {
  print('\n$command ${args.join(' ')}');

  var process = await Process.start(command, args, workingDirectory: cwd);

  process.stdout
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) {
    print('  $line');
  });
  process.stderr
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .listen((line) => print('  $line'));

  var exitCode = await process.exitCode;
  if (exitCode != 0 && failOnError) {
    throw '$command exited with $exitCode';
  }

  return exitCode;
}

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
    bool quick = false,
    bool verbose = false,
  }) async {
    if (!quick) {
      deleteServerCache();
    }

    var dartSdkPath = path.dirname(path.dirname(Platform.resolvedExecutable));

    var stopwatch = Stopwatch()..start();

    await _runProcess(
      Platform.resolvedExecutable,
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
