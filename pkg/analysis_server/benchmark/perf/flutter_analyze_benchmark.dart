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
  String cwd,
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
class FlutterAnalyzeBenchmark extends Benchmark {
  Directory flutterDir;

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
  bool get needsSetup => true;

  @override
  Future oneTimeCleanup() {
    try {
      flutterDir.deleteSync(recursive: true);
    } on FileSystemException catch (e) {
      print(e);
    }

    return Future.value();
  }

  @override
  Future oneTimeSetup() async {
    flutterDir = Directory.systemTemp.createTempSync('flutter');

    // git clone https://github.com/flutter/flutter $flutterDir
    await _runProcess('git', [
      'clone',
      'https://github.com/flutter/flutter',
      path.canonicalize(flutterDir.path)
    ]);

    var flutterTool = path.join(flutterDir.path, 'bin', 'flutter');

    // flutter --version
    await _runProcess(flutterTool, ['--version'], cwd: flutterDir.path);

    // flutter precache
    await _runProcess(flutterTool, ['precache'], cwd: flutterDir.path);

    // flutter update-packages
    await _runProcess(flutterTool, ['update-packages'], cwd: flutterDir.path);
  }

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
      cwd: flutterDir.path,
      failOnError: false,
    );

    stopwatch.stop();

    return BenchMarkResult('micros', stopwatch.elapsedMicroseconds);
  }
}
