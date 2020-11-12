// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'configuration.dart';
import 'utils.dart';

Future buildConfigurations(List<TestConfiguration> configurations) async {
  var startTime = DateTime.now();
  if (!configurations.first.build) return;
  final buildTargets = <String>{};
  final modes = <Mode>{};
  final architectures = <Architecture>{};
  final systems = <System>{};
  for (final configuration in configurations) {
    final inner = configuration.configuration;
    buildTargets.addAll(_selectBuildTargets(inner));
    modes.add(inner.mode);
    architectures.add(inner.architecture);
    systems.add(inner.system);
  }
  if (buildTargets.isEmpty) return;
  if (systems.length > 1) {
    print('Unimplemented: building for multiple systems ${systems.join(',')}');
    exit(1);
  }
  final system = systems.single;
  final osFlags = <String>[];
  if (system == System.android) {
    osFlags.addAll(['--os', 'android']);
  } else if (system == System.fuchsia) {
    osFlags.addAll(['--os', 'fuchsia']);
  } else {
    final host = System.find(Platform.operatingSystem);
    if (system != host) {
      print('Unimplemented: running tests for $system on $host');
      exit(1);
    }
  }
  final command = [
    'tools/build.py',
    '-m',
    modes.join(','),
    '-a',
    architectures.join(','),
    ...osFlags,
    ...buildTargets
  ];
  print('Running command: python ${command.join(' ')}');
  final process = await Process.start('python', command);
  stdout.nonBlocking.addStream(process.stdout);
  stderr.nonBlocking.addStream(process.stderr);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('exit code: $exitCode');
  }
  var buildTime = niceTime(DateTime.now().difference(startTime));
  print('--- Build time: $buildTime ---');
}

List<String> _selectBuildTargets(Configuration inner) {
  final result = <String>[];
  final compiler = inner.compiler;
  const targetsForCompilers = {
    Compiler.dartk: ['runtime'],
    Compiler.dartkp: ['runtime', 'dart_precompiled_runtime'],
    Compiler.appJitk: ['runtime'],
    Compiler.fasta: ['create_sdk', 'dartdevc_test', 'kernel_platform_files'],
    Compiler.dartdevk: ['dartdevc_test'],
    Compiler.dart2js: ['create_sdk'],
    Compiler.dart2analyzer: ['create_sdk'],
    Compiler.specParser: <String>[],
  };
  result.addAll(targetsForCompilers[compiler]);

  if (compiler == Compiler.dartkp &&
      [Architecture.arm, Architecture.arm64, Architecture.arm_x64]
          .contains(inner.architecture)) {
    result.add('gen_snapshot');
  }

  if (compiler == Compiler.dartdevk && !inner.useSdk) {
    result
      ..remove('dartdevc_test')
      ..add('dartdevc_test_local');
  }

  return result;
}
