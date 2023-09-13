// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer_utilities/package_root.dart';

import '../benchmarks.dart';
import 'utils.dart';

abstract class AbstractCmdLineBenchmark extends Benchmark {
  AbstractCmdLineBenchmark(super.id, super.description, {required super.kind});

  @override
  int get maxIterations => 3;

  String get workingDir;

  List<String> analyzeWhat(bool quick);

  void cleanup() {}

  @override
  Future<BenchMarkResult> run(
      {required String dartSdkPath,
      bool quick = false,
      bool verbose = false}) async {
    if (!quick) {
      deleteServerCache();
    }

    setup();
    var analyzeThis = analyzeWhat(quick);

    var stopwatchNoCache = Stopwatch()..start();
    await runProcess(
      '$dartSdkPath/bin/dart',
      ['analyze', '--suppress-analytics', ...analyzeThis],
      cwd: workingDir,
      failOnError: true,
      verbose: false,
    );
    stopwatchNoCache.stop();

    var stopwatchWithCache = Stopwatch()..start();
    await runProcess(
      '$dartSdkPath/bin/dart',
      ['analyze', '--suppress-analytics', ...analyzeThis],
      cwd: workingDir,
      failOnError: true,
      verbose: false,
    );
    stopwatchWithCache.stop();

    var result = CompoundBenchMarkResult(id);
    result.add('no-cache',
        BenchMarkResult('micros', stopwatchNoCache.elapsedMicroseconds));
    result.add('with-cache',
        BenchMarkResult('micros', stopwatchWithCache.elapsedMicroseconds));

    if (!quick) {
      deleteServerCache();
      List<String> stdout = [];
      await runProcess(
        '$dartSdkPath/bin/dart',
        [
          'analyze',
          '--suppress-analytics',
          '--format=json',
          '--memory',
          ...analyzeThis
        ],
        cwd: workingDir,
        failOnError: true,
        verbose: false,
        stdout: stdout,
      );
      int kbNoCache = jsonDecode(stdout[1])['memory'] as int;
      result.add('no-cache-memory', BenchMarkResult('bytes', kbNoCache * 1024));

      stdout = [];
      await runProcess(
        '$dartSdkPath/bin/dart',
        [
          'analyze',
          '--suppress-analytics',
          '--format=json',
          '--memory',
          ...analyzeThis
        ],
        cwd: workingDir,
        failOnError: true,
        verbose: false,
        stdout: stdout,
      );
      int kbWithCache = jsonDecode(stdout[1])['memory'] as int;
      result.add(
          'with-cache-memory', BenchMarkResult('bytes', kbWithCache * 1024));
    }

    cleanup();

    return result;
  }

  void setup() {}
}

class CmdLineOneProjectBenchmark extends AbstractCmdLineBenchmark {
  CmdLineOneProjectBenchmark()
      : super('dart-analyze-one-project',
            'Run dart analyze on one project with and without a cache',
            kind: 'group');

  @override
  String get workingDir => packageRoot;

  @override
  List<String> analyzeWhat(bool quick) =>
      quick ? ['meta'] : ['analysis_server'];
}

class CmdLineSeveralProjectsBenchmark extends AbstractCmdLineBenchmark {
  CmdLineSeveralProjectsBenchmark()
      : super('dart-analyze-several-projects',
            'Run dart analyze on several projects with and without a cache',
            kind: 'group');

  @override
  String get workingDir => packageRoot;

  @override
  List<String> analyzeWhat(bool quick) => quick
      ? ['meta']
      : [
          'analysis_server',
          'analysis_server_client',
          'analyzer',
          'analyzer_cli',
          'analyzer_plugin',
          'analyzer_utilities',
          '_fe_analyzer_shared',
        ];
}

class CmdLineSmallFileBenchmark extends AbstractCmdLineBenchmark {
  Directory? _tempDir;

  CmdLineSmallFileBenchmark()
      : super('dart-analyze-small-file',
            'Run dart analyze on a small file with and without a cache',
            kind: 'group');

  @override
  String get workingDir => _tempDir!.path;

  @override
  List<String> analyzeWhat(bool quick) => ['t.dart'];

  @override
  void cleanup() {
    _tempDir!.deleteSync(recursive: true);
    _tempDir = null;
  }

  @override
  void setup() {
    var dir = Directory.systemTemp.createTempSync('analyzer-benchmark');
    var file = File.fromUri(dir.uri.resolve('t.dart'));
    file.writeAsStringSync('''
void main() {
  print("Hello, world!");
}''');
    _tempDir = dir;
  }
}
