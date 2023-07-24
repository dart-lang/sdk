#!tools/sdks/dart-sdk/bin/dart
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:pool/pool.dart';

final pool = Pool(Platform.numberOfProcessors);

main() async {
  final sdkRoot = Platform.script.resolve('../').toFilePath();
  Directory.current = Directory(sdkRoot);

  final extractedOffsetsFile =
      'runtime/vm/compiler/runtime_offsets_extracted.h';

  final old = File(extractedOffsetsFile).readAsStringSync();
  final header = old.substring(0, old.indexOf('\n#if '));
  final footer = old.substring(old.lastIndexOf('\n#endif '));

  // Build all configurations
  await forAllConfigurationsMode(
      (String buildDir, String mode, String arch) async {
    print('Building $buildDir');
    await run([
      'tools/build.py',
      '-a$arch',
      '-m$mode',
      'offsets_extractor',
      'offsets_extractor_precompiled_runtime'
    ]);
    print('Building $buildDir - done');
  });

  final (jit, aot) = await (
    forAllConfigurationsMode((String buildDir, _, __) async {
      return await run(['$buildDir/offsets_extractor']);
    }).then<String>((lines) => lines.join('\n')),
    forAllConfigurationsMode((String buildDir, _, __) async {
      return await run(['$buildDir/offsets_extractor_precompiled_runtime']);
    }).then<String>((lines) => lines.join('\n')),
  ).wait;

  if (exitCode == 0) {
    final output = StringBuffer();
    output.writeln(header);
    output.writeln(jit);
    output.writeln(aot);
    output.writeln(footer);
    File(extractedOffsetsFile).writeAsStringSync(output.toString());
    print('Written $extractedOffsetsFile');
    print('Running `git cl format $extractedOffsetsFile');
    await run(['git', 'cl', 'format', extractedOffsetsFile]);
  }
}

Future<List<T>> forAllConfigurationsMode<T>(
    Future<T> Function(String buildDir, String mode, String arch) fun) async {
  final archs = [
    'simarm',
    'x64',
    'ia32',
    'simarm64',
    'x64c',
    'simarm64c',
    'simriscv32',
    'simriscv64',
  ];
  final futures = <Future<T>>[];
  for (final mode in ['release', 'product']) {
    for (final arch in archs) {
      final buildDir = 'out/${mode.capitalized}${arch.upper}/';
      futures.add(pool.withResource(() => fun(buildDir, mode, arch)));
    }
  }
  return await Future.wait(futures);
}

Future<String> run(List<String> args) async {
  final result =
      await Process.run(args.first, args.skip(1).toList(), runInShell: true);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    print('Running ${args.join(' ')} has failed with exit code $exitCode:');
    print('${result.stdout}');
    print('${result.stderr}');
  }
  return result.stdout;
}

extension on String {
  String get capitalized => substring(0, 1).toUpperCase() + substring(1);
  String get upper => toUpperCase();
}
