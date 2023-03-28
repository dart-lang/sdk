// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file _is_ an entrypoint, but is also imported from several libraries
// in 'perf/'.
// ignore_for_file: unreachable_from_main

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import 'perf/benchmarks_impl.dart';
import 'perf/dart_analyze.dart';
import 'perf/flutter_analyze_benchmark.dart';
import 'perf/flutter_completion_benchmark.dart';

Future<void> main(List<String> args) async {
  var benchmarks = [
    ColdAnalysisBenchmark(ServerBenchmark.das),
    ColdAnalysisBenchmark(ServerBenchmark.lsp),
    AnalysisBenchmark(ServerBenchmark.das),
    AnalysisBenchmark(ServerBenchmark.lsp),
    CmdLineSmallFileBenchmark(),
    CmdLineOneProjectBenchmark(),
    CmdLineSeveralProjectsBenchmark(),
    FlutterAnalyzeBenchmark(),
    FlutterCompletionBenchmark.das,
    FlutterCompletionBenchmark.lsp,
  ];

  var runner = CommandRunner(
    'benchmark',
    'A benchmark runner for the analysis server.',
  );
  runner.addCommand(ListCommand(benchmarks));
  runner.addCommand(RunCommand(benchmarks));
  await runner.run(args);
}

String get analysisServerSrcPath {
  return path.join(packageRoot, 'analysis_server');
}

void deleteServerCache() {
  // ~/.dartServer/.analysis-driver/
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var stateLocation = resourceProvider.getStateLocation('.analysis-driver');
  try {
    stateLocation?.delete();
  } catch (e) {
    // ignore any exception
  }
}

List<String> getProjectRoots({bool quick = false}) {
  return [path.join(packageRoot, quick ? 'meta' : 'analysis_server')];
}

abstract class Benchmark {
  final String id;
  final String description;
  final bool enabled;

  /// One of 'memory', 'cpu', or 'group'.
  final String kind;

  Benchmark(this.id, this.description,
      {this.enabled = true, required this.kind});

  int get maxIterations => 0;

  bool get needsSetup => false;

  Future<void> oneTimeCleanup() => Future.value();

  Future<void> oneTimeSetup() => Future.value();

  Future<BenchMarkResult> run({
    required String dartSdkPath,
    bool quick = false,
    bool verbose = false,
  });

  Map<String, Object?> toJson() =>
      {'id': id, 'description': description, 'enabled': enabled, 'kind': kind};

  @override
  String toString() => '$id: $description';
}

class BenchMarkResult {
  /// One of 'bytes', 'kb', 'micros', or 'compound'.
  final String kindName;

  final int value;

  BenchMarkResult(this.kindName, this.value);

  BenchMarkResult combine(BenchMarkResult other) {
    return BenchMarkResult(kindName, math.min(value, other.value));
  }

  Map<String, Object?> toJson() => {kindName: value};

  @override
  String toString() => '$kindName: $value';
}

class CompoundBenchMarkResult extends BenchMarkResult {
  final String name;

  Map<String, BenchMarkResult> results = {};

  CompoundBenchMarkResult(this.name) : super('compound', 0);

  void add(String name, BenchMarkResult result) {
    results[name] = result;
  }

  @override
  BenchMarkResult combine(covariant CompoundBenchMarkResult other) {
    BenchMarkResult combine(BenchMarkResult? a, BenchMarkResult? b) {
      if (a == null) return b!;
      if (b == null) return a;
      return a.combine(b);
    }

    var combined = CompoundBenchMarkResult(name);
    var keys = {
      ...results.keys,
      ...other.results.keys,
    }.toList();

    for (var key in keys) {
      combined.add(key, combine(results[key], other.results[key]));
    }

    return combined;
  }

  @override
  Map<String, Object?> toJson() {
    return {
      for (var entry in results.entries)
        '$name-${entry.key}': entry.value.toJson(),
    };
  }

  @override
  String toString() => '${toJson()}';
}

/// This interface is implemented by benchmarks that need to know the location
/// of the Flutter repository.
abstract class FlutterBenchmark {
  /// Must be called exactly one time.
  set flutterRepositoryPath(String path);
}

class ListCommand extends Command<void> {
  final List<Benchmark> benchmarks;

  ListCommand(this.benchmarks) {
    argParser.addFlag('machine',
        negatable: false, help: 'Emit the list of benchmarks as json.');
  }

  @override
  String get description => 'List available benchmarks.';

  @override
  String get invocation => '${runner!.executableName} $name';

  @override
  String get name => 'list';

  @override
  void run() {
    if (argResults!['machine'] as bool) {
      var map = <String, Object?>{
        'benchmarks': benchmarks.map((b) => b.toJson()).toList()
      };
      print(JsonEncoder.withIndent('  ').convert(map));
    } else {
      for (var benchmark in benchmarks) {
        print('${benchmark.id}: ${benchmark.description}');
      }
    }
  }
}

class RunCommand extends Command<void> {
  final List<Benchmark> benchmarks;

  RunCommand(this.benchmarks) {
    argParser.addOption('dart-sdk',
        help: 'The absolute normalized path of the Dart SDK.');
    argParser.addOption('flutter-repository',
        help: 'The absolute normalized path of the Flutter repository.');
    argParser.addFlag('quick',
        negatable: false,
        help: 'Run a quick version of the benchmark. This is not useful for '
            'gathering accurate times,\nbut can be used to validate that the '
            'benchmark works.');
    argParser.addOption('repeat',
        defaultsTo: '4', help: 'The number of times to repeat the benchmark.');
    argParser.addFlag('verbose',
        negatable: false,
        help: 'Print all communication to and from the analysis server.');
  }

  @override
  String get description => 'Run a given benchmark.';

  @override
  String get invocation => '${runner!.executableName} $name <benchmark-id>';

  @override
  String get name => 'run';

  @override
  Future<void> run() async {
    var args = argResults;
    if (args == null) {
      throw StateError('argResults have not been set');
    }
    if (args.rest.isEmpty) {
      printUsage();
      exit(1);
    }

    var benchmarkId = args.rest.first;
    var repeatCount = int.parse(args['repeat'] as String);
    var dartSdkPath = args['dart-sdk'] as String?;
    var flutterRepository = args['flutter-repository'] as String?;
    var quick = args['quick'] as bool;
    var verbose = args['verbose'] as bool;

    var benchmark =
        benchmarks.firstWhere((b) => b.id == benchmarkId, orElse: () {
      print("Benchmark '$benchmarkId' not found.");
      exit(1);
    });

    dartSdkPath ??= path.dirname(path.dirname(Platform.resolvedExecutable));

    if (benchmark is FlutterBenchmark) {
      if (flutterRepository != null) {
        if (path.isAbsolute(flutterRepository) &&
            path.normalize(flutterRepository) == flutterRepository) {
          (benchmark as FlutterBenchmark).flutterRepositoryPath =
              flutterRepository;
        } else {
          print('The path must be absolute and normalized: $flutterRepository');
          exit(1);
        }
      } else {
        print('The option --flutter-repository is required to '
            "run '$benchmarkId'.");
        exit(1);
      }
    }

    var actualIterations = repeatCount;
    if (benchmark.maxIterations > 0) {
      actualIterations = math.min(benchmark.maxIterations, repeatCount);
    }

    if (benchmark.needsSetup) {
      print('Setting up $benchmarkId...');
      await benchmark.oneTimeSetup();
    }

    try {
      BenchMarkResult? result;
      var time = Stopwatch()..start();
      print('Running $benchmarkId $actualIterations times...');

      for (var iteration = 0; iteration < actualIterations; iteration++) {
        var newResult = await benchmark.run(
          dartSdkPath: dartSdkPath,
          quick: quick,
          verbose: verbose,
        );
        print('  $newResult');
        result = result == null ? newResult : result.combine(newResult);
      }

      time.stop();
      print('Finished in ${time.elapsed.inSeconds} seconds.\n');
      var m = <String, dynamic>{
        'benchmark': benchmarkId,
        'result': result!.toJson()
      };
      print(json.encode(m));

      await benchmark.oneTimeCleanup();
    } catch (error, st) {
      print('$benchmarkId threw exception: $error');
      print(st);
      exit(1);
    }
  }
}
