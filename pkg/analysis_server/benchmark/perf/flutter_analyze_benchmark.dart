// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../benchmarks.dart';

/// benchmarks:
///   - analysis-flutter-analyze
class FlutterAnalyzeBenchmark extends Benchmark {
  FlutterAnalyzeBenchmark()
      : super(
          'analysis-flutter-analyze',
          "Clone the flutter/flutter repo and run "
              "'flutter analyze --flutter-repo' with the current Dart VM and "
              "analysis server.",
          kind: 'cpu',
        );

  bool get needsSetup => true;

  Directory flutterDir;

  Future oneTimeSetup() async {
    flutterDir = Directory.systemTemp.createTempSync('flutter');

    // git clone https://github.com/flutter/flutter $flutterDir
    await _runProcess('git', [
      'clone',
      'https://github.com/flutter/flutter',
      path.canonicalize(flutterDir.path)
    ]);

    String flutterTool = path.join(flutterDir.path, 'bin', 'flutter');

    // flutter --version
    await _runProcess(flutterTool, ['--version'], cwd: flutterDir.path);

    // flutter precache
    await _runProcess(flutterTool, ['precache'], cwd: flutterDir.path);

    // flutter update-packages
    await _runProcess(flutterTool, ['update-packages'], cwd: flutterDir.path);
  }

  Future oneTimeCleanup() {
    try {
      flutterDir.deleteSync(recursive: true);
    } on FileSystemException catch (e) {
      print(e);
    }

    return new Future.value();
  }

  int get maxIterations => 3;

  @override
  Future<BenchMarkResult> run({
    bool quick: false,
    bool useCFE: false,
    bool verbose: false,
  }) async {
    if (!quick) {
      deleteServerCache();
    }

    final String dartSdkPath =
        path.dirname(path.dirname(Platform.resolvedExecutable));

    final Stopwatch stopwatch = new Stopwatch()..start();

    await _runProcess(
      Platform.resolvedExecutable,
      [
        'packages/flutter_tools/bin/flutter_tools.dart',
        'analyze',
        '--flutter-repo',
        '--dart-sdk',
        dartSdkPath,
      ],
      cwd: flutterDir.path,
      failOnError: false,
    );

    stopwatch.stop();

    return new BenchMarkResult('micros', stopwatch.elapsedMicroseconds);
  }
}

Future<int> _runProcess(
  String command,
  List<String> args, {
  String cwd,
  bool failOnError = true,
}) async {
  print('\n$command ${args.join(' ')}');

  Process process = await Process.start(command, args, workingDirectory: cwd);

  process.stdout
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) {
    print('  $line');
  });
  process.stderr
      .transform(utf8.decoder)
      .transform(new LineSplitter())
      .listen((line) => print('  $line'));

  int exitCode = await process.exitCode;
  if (exitCode != 0 && failOnError) {
    throw '$command exited with $exitCode';
  }

  return exitCode;
}
