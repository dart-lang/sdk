// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  var benchmarks = <Benchmark>[
    ColdAnalysisBenchmark(),
    AnalysisBenchmark(),
    FlutterAnalyzeBenchmark(),
  ];

  var runner =
      CommandRunner('benchmark', 'A benchmark runner for the analysis server.');
  runner.addCommand(ListCommand(benchmarks));
  runner.addCommand(RunCommand(benchmarks));
  runner.run(args);
}

String get analysisServerSrcPath {
  var script = Platform.script.toFilePath(windows: Platform.isWindows);
  var pkgPath = path.normalize(path.join(path.dirname(script), '..', '..'));
  return path.join(pkgPath, 'analysis_server');
}

void deleteServerCache() {
  // ~/.dartServer/.analysis-driver/
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var stateLocation = resourceProvider.getStateLocation('.analysis-driver');
  try {
    if (stateLocation.exists) {
      stateLocation.delete();
    }
  } catch (e) {
    // ignore any exception
  }
}

List<String> getProjectRoots({bool quick = false}) {
  var script = Platform.script.toFilePath(windows: Platform.isWindows);
  var pkgPath = path.normalize(path.join(path.dirname(script), '..', '..'));
  return <String>[path.join(pkgPath, quick ? 'meta' : 'analysis_server')];
}

abstract class Benchmark {
  final String id;
  final String description;
  final bool enabled;

  /// One of 'memory', 'cpu', or 'group'.
  final String kind;

  Benchmark(this.id, this.description,
      {this.enabled = true, this.kind = 'cpu'});

  int get maxIterations => 0;

  bool get needsSetup => false;

  Future oneTimeCleanup() => Future.value();

  Future oneTimeSetup() => Future.value();

  Future<BenchMarkResult> run({
    bool quick = false,
    bool verbose = false,
  });

  Map toJson() =>
      {'id': id, 'description': description, 'enabled': enabled, 'kind': kind};

  @override
  String toString() => '$id: $description';
}

class BenchMarkResult {
  static final NumberFormat nf = NumberFormat.decimalPattern();

  /// One of 'bytes', 'micros', or 'compound'.
  final String kindName;

  final int value;

  BenchMarkResult(this.kindName, this.value);

  BenchMarkResult combine(BenchMarkResult other) {
    return BenchMarkResult(kindName, math.min(value, other.value));
  }

  Map toJson() => {kindName: value};

  @override
  String toString() => '$kindName: ${nf.format(value)}';
}

class CompoundBenchMarkResult extends BenchMarkResult {
  final String name;

  Map<String, BenchMarkResult> results = {};

  CompoundBenchMarkResult(this.name) : super('compound', 0);

  void add(String name, BenchMarkResult result) {
    results[name] = result;
  }

  @override
  BenchMarkResult combine(BenchMarkResult other) {
    BenchMarkResult _combine(BenchMarkResult a, BenchMarkResult b) {
      if (a == null) return b;
      if (b == null) return a;
      return a.combine(b);
    }

    var o = other as CompoundBenchMarkResult;

    var combined = CompoundBenchMarkResult(name);
    var keys =
        (<String>{}..addAll(results.keys)..addAll(o.results.keys)).toList();

    for (var key in keys) {
      combined.add(key, _combine(results[key], o.results[key]));
    }

    return combined;
  }

  @override
  Map toJson() {
    var m = <String, dynamic>{};
    for (var key in results.keys) {
      m['$name-$key'] = results[key].toJson();
    }
    return m;
  }

  @override
  String toString() => '${toJson()}';
}

class ListCommand extends Command {
  final List<Benchmark> benchmarks;

  ListCommand(this.benchmarks) {
    argParser.addFlag('machine',
        negatable: false, help: 'Emit the list of benchmarks as json.');
  }

  @override
  String get description => 'List available benchmarks.';

  @override
  String get invocation => '${runner.executableName} $name';

  @override
  String get name => 'list';

  @override
  void run() {
    if (argResults['machine'] as bool) {
      var map = <String, dynamic>{
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

class RunCommand extends Command {
  final List<Benchmark> benchmarks;

  RunCommand(this.benchmarks) {
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
  String get invocation => '${runner.executableName} $name <benchmark-id>';

  @override
  String get name => 'run';

  @override
  Future run() async {
    if (argResults.rest.isEmpty) {
      printUsage();
      exit(1);
    }

    var benchmarkId = argResults.rest.first;
    var repeatCount = int.parse(argResults['repeat'] as String);
    var quick = argResults['quick'];
    var verbose = argResults['verbose'];

    var benchmark =
        benchmarks.firstWhere((b) => b.id == benchmarkId, orElse: () {
      print("Benchmark '$benchmarkId' not found.");
      exit(1);
    });

    var actualIterations = repeatCount;
    if (benchmark.maxIterations > 0) {
      actualIterations = math.min(benchmark.maxIterations, repeatCount);
    }

    if (benchmark.needsSetup) {
      print('Setting up $benchmarkId...');
      await benchmark.oneTimeSetup();
    }

    try {
      BenchMarkResult result;
      var time = Stopwatch()..start();
      print('Running $benchmarkId $actualIterations times...');

      for (var iteration = 0; iteration < actualIterations; iteration++) {
        var newResult = await benchmark.run(
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
        'result': result.toJson()
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
