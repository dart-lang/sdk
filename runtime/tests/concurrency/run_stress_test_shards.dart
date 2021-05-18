// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../vm/dart/snapshot_test_helper.dart';

void forwardStream(Stream<List<int>> input, IOSink output) {
  // Print the information line-by-line.
  input
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    output.writeln(line);
  });
}

Future<bool> run(String executable, List<String> args) async {
  print('Running "$executable ${args.join(' ')}"');
  final Process process = await Process.start(executable, args);
  forwardStream(process.stdout, stdout);
  forwardStream(process.stderr, stderr);
  final int exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('=> Running "$executable ${args.join(' ')}" failed with $exitCode');
    io.exitCode = 255; // Make this shard fail.
    return false;
  }
  return true;
}

abstract class TestRunner {
  Future runTest();
}

class JitTestRunner extends TestRunner {
  final String buildDir;
  final List<String> arguments;

  JitTestRunner(this.buildDir, this.arguments);

  Future runTest() async {
    await run('$buildDir/dart', arguments);
  }
}

class AotTestRunner extends TestRunner {
  final String buildDir;
  final List<String> arguments;
  final List<String> aotArguments;

  AotTestRunner(this.buildDir, this.arguments, this.aotArguments);

  Future runTest() async {
    await withTempDir((String dir) async {
      final elfFile = path.join(dir, 'app.elf');

      if (await run('$buildDir/gen_snapshot',
          ['--snapshot-kind=app-aot-elf', '--elf=$elfFile', ...arguments])) {
        await run(
            '$buildDir/dart_precompiled_runtime', [...aotArguments, elfFile]);
      }
    });
  }
}

final configurations = <TestRunner>[
  JitTestRunner('out/DebugX64', [
    '--disable-dart-dev',
    '--no-sound-null-safety',
    '--enable-isolate-groups',
    '--experimental-enable-isolate-groups-jit',
    'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
  ]),
  JitTestRunner('out/ReleaseX64', [
    '--disable-dart-dev',
    '--no-sound-null-safety',
    '--enable-isolate-groups',
    '--experimental-enable-isolate-groups-jit',
    '--no-inline-alloc',
    '--use-slow-path',
    '--deoptimize-on-runtime-call-every=3',
    'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
  ]),
  JitTestRunner('out/ReleaseTSANX64', [
    '--disable-dart-dev',
    '--no-sound-null-safety',
    '--enable-isolate-groups',
    '--experimental-enable-isolate-groups-jit',
    'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
  ]),
  AotTestRunner('out/ReleaseX64', [
    '--no-sound-null-safety',
    'runtime/tests/concurrency/generated_stress_test.dart.aot.dill',
  ], [
    '--no-sound-null-safety',
    '--enable-isolate-groups',
  ]),
  AotTestRunner('out/DebugX64', [
    '--no-sound-null-safety',
    'runtime/tests/concurrency/generated_stress_test.dart.aot.dill',
  ], [
    '--no-sound-null-safety',
    '--enable-isolate-groups',
  ]),
];

main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('shards', help: 'number of shards used', defaultsTo: '1')
    ..addOption('shard', help: 'shard id', defaultsTo: '1')
    ..addOption('output-directory',
        help: 'unused parameter to make sharding infra work', defaultsTo: '');

  final options = parser.parse(arguments);
  final shards = int.parse(options['shards']);
  final shard = int.parse(options['shard']) - 1;

  final thisShardsConfigurations = [];
  for (int i = 0; i < configurations.length; i++) {
    if ((i % shards) == shard) {
      thisShardsConfigurations.add(configurations[i]);
    }
  }
  for (final config in thisShardsConfigurations) {
    await config.runTest();
  }
}
