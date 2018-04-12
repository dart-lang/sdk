// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/command_runner.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import 'perf/benchmarks_impl.dart';
import 'perf/flutter_analyze_benchmark.dart';

Future main(List<String> args) async {
  final List<Benchmark> benchmarks = [
    new ColdAnalysisBenchmark(),
    new AnalysisBenchmark(),
    new FlutterAnalyzeBenchmark(),
  ];

  CommandRunner runner = new CommandRunner(
      'benchmark', 'A benchmark runner for the analysis server.');
  runner.addCommand(new ListCommand(benchmarks));
  runner.addCommand(new RunCommand(benchmarks));
  runner.run(args);
}

class ListCommand extends Command {
  final List<Benchmark> benchmarks;

  ListCommand(this.benchmarks) {
    argParser.addFlag('machine',
        negatable: false, help: 'Emit the list of benchmarks as json.');
  }

  @override
  String get name => 'list';

  @override
  String get description => 'List available benchmarks.';

  @override
  String get invocation => '${runner.executableName} $name';

  void run() {
    if (argResults['machine']) {
      final Map map = {
        'benchmarks': benchmarks.map((b) => b.toJson()).toList()
      };
      print(new JsonEncoder.withIndent('  ').convert(map));
    } else {
      for (Benchmark benchmark in benchmarks) {
        print('${benchmark.id}: ${benchmark.description}');
      }
    }
  }
}

class RunCommand extends Command {
  final List<Benchmark> benchmarks;

  RunCommand(this.benchmarks) {
    argParser.addFlag('quick',
        negatable: false,
        help: 'Run a quick version of the benchmark. This is not useful for '
            'gathering accurate times,\nbut can be used to validate that the '
            'benchmark works.');
    argParser.addFlag('use-cfe',
        negatable: false,
        help: 'Benchmark against the Dart 2.0 front end implementation.');
    argParser.addOption('repeat',
        defaultsTo: '10', help: 'The number of times to repeat the benchmark.');
    argParser.addFlag('verbose',
        negatable: false,
        help: 'Print all communication to and from the analysis server.');
  }

  @override
  String get name => 'run';

  @override
  String get description => 'Run a given benchmark.';

  @override
  String get invocation => '${runner.executableName} $name <benchmark-id>';

  Future run() async {
    if (argResults.rest.isEmpty) {
      printUsage();
      exit(1);
    }

    final String benchmarkId = argResults.rest.first;
    final int repeatCount = int.parse(argResults['repeat']);
    final bool quick = argResults['quick'];
    final bool useCFE = argResults['use-cfe'];
    final bool verbose = argResults['verbose'];

    final Benchmark benchmark =
        benchmarks.firstWhere((b) => b.id == benchmarkId, orElse: () {
      print("Benchmark '$benchmarkId' not found.");
      exit(1);
    });

    int actualIterations = repeatCount;
    if (benchmark.maxIterations > 0) {
      actualIterations = math.min(benchmark.maxIterations, repeatCount);
    }

    if (benchmark.needsSetup) {
      print('Setting up $benchmarkId...');
      await benchmark.oneTimeSetup();
    }

    try {
      BenchMarkResult result;
      Stopwatch time = new Stopwatch()..start();
      print('Running $benchmarkId $actualIterations times...');

      for (int iteration = 0; iteration < actualIterations; iteration++) {
        BenchMarkResult newResult = await benchmark.run(
          quick: quick,
          useCFE: useCFE,
          verbose: verbose,
        );
        print('  $newResult');
        result = result == null ? newResult : result.combine(newResult);
      }

      time.stop();
      print('Finished in ${time.elapsed.inSeconds} seconds.\n');
      Map m = {'benchmark': benchmarkId, 'result': result.toJson()};
      print(json.encode(m));

      await benchmark.oneTimeCleanup();
    } catch (error, st) {
      print('$benchmarkId threw exception: $error');
      print(st);
      exit(1);
    }
  }
}

abstract class Benchmark {
  final String id;
  final String description;
  final bool enabled;

  /// One of 'memory', 'cpu', or 'group'.
  final String kind;

  Benchmark(this.id, this.description, {this.enabled: true, this.kind: 'cpu'});

  bool get needsSetup => false;

  Future oneTimeSetup() => new Future.value();

  Future oneTimeCleanup() => new Future.value();

  Future<BenchMarkResult> run({
    bool quick: false,
    bool useCFE: false,
    bool verbose: false,
  });

  int get maxIterations => 0;

  Map toJson() =>
      {'id': id, 'description': description, 'enabled': enabled, 'kind': kind};

  String toString() => '$id: $description';
}

class BenchMarkResult {
  static final NumberFormat nf = new NumberFormat.decimalPattern();

  /// One of 'bytes', 'micros', or 'compound'.
  final String kindName;

  final int value;

  BenchMarkResult(this.kindName, this.value);

  BenchMarkResult combine(BenchMarkResult other) {
    return new BenchMarkResult(kindName, math.min(value, other.value));
  }

  Map toJson() => {kindName: value};

  String toString() => '$kindName: ${nf.format(value)}';
}

class CompoundBenchMarkResult extends BenchMarkResult {
  final String name;

  CompoundBenchMarkResult(this.name) : super('compound', 0);

  Map<String, BenchMarkResult> results = {};

  void add(String name, BenchMarkResult result) {
    results[name] = result;
  }

  BenchMarkResult combine(BenchMarkResult other) {
    BenchMarkResult _combine(BenchMarkResult a, BenchMarkResult b) {
      if (a == null) return b;
      if (b == null) return a;
      return a.combine(b);
    }

    CompoundBenchMarkResult o = other as CompoundBenchMarkResult;

    CompoundBenchMarkResult combined = new CompoundBenchMarkResult(name);
    List<String> keys =
        (new Set()..addAll(results.keys)..addAll(o.results.keys)).toList();

    for (String key in keys) {
      combined.add(key, _combine(results[key], o.results[key]));
    }

    return combined;
  }

  Map toJson() {
    Map m = {};
    for (String key in results.keys) {
      m['$name-$key'] = results[key].toJson();
    }
    return m;
  }

  String toString() => '${toJson()}';
}

List<String> getProjectRoots({bool quick: false}) {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = path.normalize(path.join(path.dirname(script), '..', '..'));
  return <String>[path.join(pkgPath, quick ? 'meta' : 'analysis_server')];
}

String get analysisServerSrcPath {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = path.normalize(path.join(path.dirname(script), '..', '..'));
  return path.join(pkgPath, 'analysis_server');
}

void deleteServerCache() {
  // ~/.dartServer/.analysis-driver/
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  Folder stateLocation = resourceProvider.getStateLocation('.analysis-driver');
  try {
    if (stateLocation.exists) {
      stateLocation.delete();
    }
  } catch (e) {
    // ignore any exception
  }
}
