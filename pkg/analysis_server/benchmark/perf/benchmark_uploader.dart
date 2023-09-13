// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script runs the benchmarks in this directory and uploads the
// results to cloud storage. These results are then ingested by our
// performance measurement system.
//
// The script only works when run on a LUCI builder in the dart-ci project,
// and uploads results to paths within gs://dart-test-results/benchmark-results.
//
// This script is needed to run benchmarks on platforms that we only have
// in our LUCI CI system, not in our performance lab, such as Windows.
// The script is currently only used and tested on Windows.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  try {
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < countRuns; ++i) {
      results.addAll(await runBenchmarks(warm: true));
      results.addAll(await runBenchmarks(warm: false));
    }

    if (!Platform.isWindows) {
      print('Analyzer benchmark uploads only run on Windows');
      exit(1);
    }
    final targetResults = [
      for (final result in results)
        {
          'cpu': 'Windows VM',
          'machineType': 'windows-x64',
          'target': 'dart-analysis-server-external',
          ...result,
        }
    ];
    await uploadResults(targetResults);
  } catch (e, st) {
    print('$e\n$st');
  }
}

const countRuns = 2;

Future<List<Map<String, dynamic>>> runBenchmarks({required bool warm}) async {
  final temperature = warm ? 'warm' : 'cold';
  final benchmarkResults = await Process.run(Platform.resolvedExecutable, [
    'pkg/analysis_server/benchmark/benchmarks.dart',
    'run',
    if (warm) 'analysis-server' else 'analysis-server-cold',
  ]);

  print(benchmarkResults.stdout);
  print(benchmarkResults.stderr);
  if (benchmarkResults.exitCode != 0) {
    throw 'Failed to run $temperature benchmarks';
  }
  final result = jsonDecode(LineSplitter()
      .convert(benchmarkResults.stdout as String)
      .where((line) => line.startsWith('{"benchmark":'))
      .single);

  return <Map<String, dynamic>>[
    {
      'benchmark': 'analysis-server-$temperature-memory',
      'metric': 'MemoryUse',
      'score': result['result']['analysis-server-$temperature-memory']['bytes'],
    },
    {
      'benchmark': 'analysis-server-$temperature-analysis',
      'metric': 'RunTimeRaw',
      'score': result['result']['analysis-server-$temperature-analysis']
          ['micros'],
    },
    if (warm)
      {
        'benchmark': 'analysis-server-edit',
        'metric': 'RunTimeRaw',
        'score': result['result']['analysis-server-edit']['micros'],
      },
    if (warm)
      {
        'benchmark': 'analysis-server-completion',
        'metric': 'RunTimeRaw',
        'score': result['result']['analysis-server-completion']['micros'],
      }
  ];
}

Future<void> uploadResults(List<Map<String, dynamic>> results) async {
  // Create JSON results in the desired format
  // Write results file to cloud storage.
  final tempDir =
      await Directory.systemTemp.createTemp('analysis-server-benchmarks');
  try {
    final resultsJson = jsonEncode(results);
    final resultsFile = File.fromUri(tempDir.uri.resolve('results.json'));
    resultsFile.writeAsStringSync(resultsJson, flush: true);

    final taskId = Platform.environment['SWARMING_TASK_ID'] ?? 'test_task_id';
    if (taskId == 'test_task_id') {
      print('Benchmark_uploader requires SWARMING_TASK_ID in the environment.');
    }
    final cloudStoragePath =
        'gs://dart-test-results/benchmarks/$taskId/results.json';
    final args = [
      'third_party/gsutil/gsutil',
      'cp',
      resultsFile.path,
      cloudStoragePath
    ];
    final python = 'python3.exe';
    print('Running $python ${args.join(' ')}');
    final commandResult = await Process.run(python, args);
    final exitCode = commandResult.exitCode;
    print(commandResult.stdout);
    print(commandResult.stderr);
    print('exit code: $exitCode');
    if (exitCode != 0) {
      throw 'Gsutil upload failed. Exit code $exitCode';
    }
  } finally {
    await tempDir.delete(recursive: true);
  }
}
