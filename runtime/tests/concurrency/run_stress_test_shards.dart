// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:test_runner/src/options.dart';

import '../vm/dart/snapshot_test_helper.dart';
import '../../tools/dartfuzz/flag_fuzzer.dart';

int crashCounter = 0;

void forwardStream(Stream<List<int>> input, IOSink output) {
  // Print the information line-by-line.
  input.transform(utf8.decoder).transform(const LineSplitter()).listen((
    String line,
  ) {
    output.writeln(line);
  });
}

class PotentialCrash {
  final String test;
  final int pid;
  final List<String> binaries;
  PotentialCrash(this.test, this.pid, this.binaries);
}

Future<bool> run(
  String executable,
  List<String> args,
  List<PotentialCrash> crashes,
) async {
  print('\n\nRunning "$executable ${args.join(' ')}"');
  final sw = Stopwatch()..start();
  final Process process = await Process.start(
    executable,
    args,
    environment: sanitizerEnvironmentVariables,
  );
  forwardStream(process.stdout, stdout);
  forwardStream(process.stderr, stderr);
  final int exitCode = await process.exitCode;
  print('Completed in ${sw.elapsed}');
  if (exitCode != 0) {
    // Ignore normal exceptions and compile-time errors for the purpose of
    // crashdump reporting.
    if (exitCode != 255 && exitCode != 254) {
      final crashNr = crashCounter++;
      print('=> Running "$executable ${args.join(' ')}" failed with $exitCode');
      print('=> Possible crash $crashNr (pid: ${process.pid})');
      crashes.add(PotentialCrash('crash-$crashNr', process.pid, [executable]));
    }
    io.exitCode = 255; // Make this shard fail.
    return false;
  }
  return true;
}

abstract class TestRunner {
  Future runTest(List<PotentialCrash> crashes);
}

class JitTestRunner extends TestRunner {
  final String buildDir;
  final List<String> arguments;

  JitTestRunner(this.buildDir, this.arguments);

  Future runTest(List<PotentialCrash> crashes) async {
    await run('$buildDir/dart', arguments, crashes);
  }
}

class AotTestRunner extends TestRunner {
  final String buildDir;
  final List<String> arguments;
  final List<String> aotArguments;

  AotTestRunner(this.buildDir, this.arguments, this.aotArguments);

  Future runTest(List<PotentialCrash> crashes) async {
    await withTempDir((String dir) async {
      final elfFile = path.join(dir, 'app.elf');

      if (await run('$buildDir/gen_snapshot', [
        '--snapshot-kind=app-aot-elf',
        '--elf=$elfFile',
        ...arguments,
      ], crashes)) {
        await run('$buildDir/dartaotruntime', [
          ...aotArguments,
          elfFile,
        ], crashes);
      }
    });
  }
}

// Produces a name that tools/utils.py:BaseCoredumpArchiver supports.
String getArchiveName(String binary) {
  final parts = binary.split(Platform.pathSeparator);
  late String mode;
  late String arch;
  final buildDir = parts[1];
  for (final prefix in ['Release', 'Debug', 'Product']) {
    if (buildDir.startsWith(prefix)) {
      mode = prefix.toLowerCase();
      arch = buildDir.substring(prefix.length);
    }
  }
  final name = parts.skip(2).join('__');
  return 'binary.${mode}_${arch}_${name}';
}

void writeUnexpectedCrashesFile(List<PotentialCrash> crashes) {
  // The format of this file is:
  //
  //     test-name,pid,binary-file1,binary-file2,...
  //
  const unexpectedCrashesFile = 'unexpected-crashes';

  final buffer = StringBuffer();
  final Set<String> archivedBinaries = {};
  for (final crash in crashes) {
    buffer.write('${crash.test},${crash.pid}');
    for (final binary in crash.binaries) {
      final archivedName = getArchiveName(binary);
      buffer.write(',$archivedName');
      if (!archivedBinaries.contains(archivedName)) {
        File(binary).copySync(archivedName);
        archivedBinaries.add(archivedName);
      }
    }
    buffer.writeln();
  }

  File(unexpectedCrashesFile).writeAsStringSync(buffer.toString());
}

Iterable<String> filterSlowFlags(Iterable<String> flags) =>
    flags.where((flag) => !flag.startsWith('--gc_at_throw'));

const int tsanShards = 64;

late final List<TestRunner> configurations;

main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('shards', help: 'number of shards used', defaultsTo: '1')
    ..addOption('shard', help: 'shard id', defaultsTo: '1')
    ..addOption(
      'output-directory',
      help: 'unused parameter to make sharding infra work',
      defaultsTo: '',
    )
    ..addFlag(
      'copy-coredumps',
      help: 'whether to copy binaries for coredumps',
      defaultsTo: false,
    )
    ..addOption(
      'previous-results',
      help: 'An earlier results.json for balancing tests across shards.',
    )
    ..addOption('arch', help: 'architecture to be tested', defaultsTo: 'X64');

  final options = parser.parse(arguments);
  final shards = int.parse(options['shards']);
  final shard = int.parse(options['shard']) - 1;
  final copyCoredumps = options['copy-coredumps'] as bool;
  final arch = options['arch'].toUpperCase();
  configurations = <TestRunner>[
    JitTestRunner('out/Debug$arch', [
      '--disable-dart-dev',
      ...filterSlowFlags(someJitRuntimeFlags()),
      'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
    ]),
    JitTestRunner('out/Release$arch', [
      '--disable-dart-dev',
      ...filterSlowFlags(someJitRuntimeFlags()),
      'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
    ]),
    AotTestRunner(
      'out/Debug$arch',
      [
        ...someGenSnapshotFlags(),
        'runtime/tests/concurrency/generated_stress_test.dart.aot.dill',
      ],
      [...filterSlowFlags(someAotRuntimeFlags())],
    ),
    AotTestRunner(
      'out/Release$arch',
      [
        ...someGenSnapshotFlags(),
        'runtime/tests/concurrency/generated_stress_test.dart.aot.dill',
      ],
      [...filterSlowFlags(someAotRuntimeFlags())],
    ),
    // TSAN last so the other steps are evenly distributed.
    for (int i = 0; i < tsanShards; ++i)
      JitTestRunner('out/ReleaseTSAN$arch', [
        '--disable-dart-dev',
        ...filterSlowFlags(someJitRuntimeFlags()),
        '--no-profiler', // TODO(https://github.com/dart-lang/sdk/issues/60804, https://github.com/dart-lang/sdk/issues/60805)
        '-Drepeat=4',
        '-Dshard=$i',
        '-Dshards=$tsanShards',
        'runtime/tests/concurrency/generated_stress_test.dart.jit.dill',
      ]),
  ];

  // Tasks will eventually be killed if they do not have any output for some
  // time. So we'll explicitly print something every 4 minutes.
  final sw = Stopwatch()..start();
  final timer = Timer.periodic(const Duration(minutes: 4), (_) {
    print('[${sw.elapsed}] ... still working ...');
  });

  try {
    final thisShardsConfigurations = [];
    for (int i = 0; i < configurations.length; i++) {
      if ((i % shards) == shard) {
        thisShardsConfigurations.add(configurations[i]);
      }
    }
    final crashes = <PotentialCrash>[];
    for (final config in thisShardsConfigurations) {
      await config.runTest(crashes);
    }
    if (!crashes.isEmpty && copyCoredumps) {
      writeUnexpectedCrashesFile(crashes);
    }
  } finally {
    timer.cancel();
  }
}
