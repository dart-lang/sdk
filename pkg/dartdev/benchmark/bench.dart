// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:meta/meta.dart';

List<Benchmark> benchmarks = [
  DartStartup(),
  DartRunStartup(),
  SdkSize(),
];

void main(List<String> args) async {
  ArgParser argParser = _createArgParser();

  ArgResults argResults;

  try {
    argResults = argParser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    print('');
    printUsage(argParser, includeDescription: false);
    io.exit(1);
  }

  if (argResults['help'] || argResults.arguments.isEmpty) {
    printUsage(argParser);
    io.exit(0);
  }

  if (!argResults.wasParsed('dart-sdk')) {
    print('No value passed for \`dart-sdk\`.');
    print('');
    printUsage(argParser);
    io.exit(1);
  }

  if (!argResults.wasParsed('run')) {
    print('No value passed for \`run\`.');
    print('');
    printUsage(argParser);
    io.exit(1);
  }

  Context context = Context(argResults['dart-sdk']);

  String benchmarkName = argResults['run'];
  Benchmark benchmark = benchmarks.singleWhere((b) => b.id == benchmarkName);

  BenchmarkResult result = await benchmark.run(context);
  print(result.toJson());
  io.exit(0);
}

void printUsage(ArgParser argParser, {bool includeDescription = true}) {
  print('usage: dart bin/bench.dart <options>');
  print('');
  if (includeDescription) {
    print('Run benchmarks for the dartdev tool.');
    print('');
  }
  print('Options:');
  print(argParser.usage);
}

ArgParser _createArgParser() {
  ArgParser argParser = ArgParser(usageLineLength: io.stdout.terminalColumns);
  argParser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Print this usage information.',
  );
  argParser.addOption(
    'dart-sdk',
    valueHelp: 'sdk path',
    help: 'The path to the Dart SDK to use for benchmarking.',
  );
  argParser.addOption(
    'run',
    valueHelp: 'benchmark',
    allowed: benchmarks.map((b) => b.id).toList(),
    allowedHelp: {
      for (var benchmark in benchmarks) benchmark.id: benchmark.description,
    },
    help: 'The benchmark to run.',
  );
  return argParser;
}

abstract class Benchmark {
  final String id;
  final String description;

  Benchmark(this.id, this.description);

  Future<BenchmarkResult> run(Context context);
}

class DartStartup extends Benchmark {
  DartStartup()
      : super(
          'script-startup',
          'Benchmark the startup time of a minimal Dart script (μs).',
        );

  @override
  Future<BenchmarkResult> run(Context context) async {
    // setup
    io.Directory dir = io.Directory.systemTemp.createTempSync('dartdev');
    io.File file = io.File('${dir.path}/hello.dart');
    file.writeAsStringSync('void main() => print(\'hello\');');

    // perform the benchmark
    Stopwatch timer = Stopwatch()..start();
    io.Process.runSync(
      '${context.sdkPath}/bin/dart',
      [file.absolute.path],
    );
    timer.stop();

    // cleanup
    dir.deleteSync(recursive: true);

    // report the result
    int micros = timer.elapsedMicroseconds;
    return BenchmarkResult(
      id: id,
      value: micros,
      units: 'microseconds',
      userDescription: '${(micros / 1000.0).toStringAsFixed(2)}ms',
    );
  }
}

class DartRunStartup extends Benchmark {
  DartRunStartup()
      : super(
          'run-script-startup',
          'Benchmark the startup time of a minimal Dart script, executed with '
              '\`dart run\` (μs).',
        );

  @override
  Future<BenchmarkResult> run(Context context) async {
    // setup
    io.Directory dir = io.Directory.systemTemp.createTempSync('dartdev');
    io.File file = io.File('${dir.path}/hello.dart');
    file.writeAsStringSync('void main() => print(\'hello\');');

    // perform the benchmark
    Stopwatch timer = Stopwatch()..start();
    io.Process.runSync(
      '${context.sdkPath}/bin/dart',
      ['run', file.absolute.path],
    );
    timer.stop();

    // cleanup
    dir.deleteSync(recursive: true);

    // report the result
    int micros = timer.elapsedMicroseconds;
    return BenchmarkResult(
      id: id,
      value: micros,
      units: 'microseconds',
      userDescription: '${(micros / 1000.0).toStringAsFixed(2)}ms',
    );
  }
}

class SdkSize extends Benchmark {
  SdkSize()
      : super(
          'sdk-size',
          'Benchmark the compressed size of the Dart SDK (bytes).',
        );

  @override
  Future<BenchmarkResult> run(Context context) async {
    // setup
    io.Directory tempDir = io.Directory.systemTemp.createTempSync('dartdev');

    // perform the benchmark
    io.File sdkArchive = compress(io.Directory(context.sdkPath), tempDir);
    int bytes = sdkArchive.lengthSync();

    // cleanup
    tempDir.deleteSync(recursive: true);

    // report the result
    return BenchmarkResult(
      id: id,
      value: bytes,
      units: 'bytes',
      userDescription: '${(bytes / (1024.0 * 1024.0)).toStringAsFixed(1)}MB',
    );
  }

  io.File compress(io.Directory sourceDir, io.Directory targetDir) {
    String name = sourceDir.path.substring(sourceDir.path.lastIndexOf('/') + 1);
    io.File outFile = io.File('${targetDir.absolute.path}/$name.zip');

    if (io.Platform.isMacOS || io.Platform.isLinux) {
      io.Process.runSync('zip', [
        '-r',
        '-9', // optimized for compressed size
        outFile.absolute.path,
        sourceDir.absolute.path,
      ]);
    } else {
      throw Exception('platform not supported: ${io.Platform.operatingSystem}');
    }

    return outFile;
  }
}

class Context {
  final String sdkPath;

  Context(this.sdkPath);
}

class BenchmarkResult {
  final String id;
  final int value;
  final String units;
  final String userDescription;

  BenchmarkResult({
    @required this.id,
    @required this.value,
    @required this.units,
    @required this.userDescription,
  });

  String toJson() {
    Map m = {
      'id': id,
      'value': value,
      'units': units,
      'userDescription': userDescription,
    };
    return JsonEncoder.withIndent('  ').convert(m);
  }
}
