#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';

const clearLine = '\r\x1b[2K';

void aot(String sourceFile, String snapshotFile, bool enableAsserts,
    bool buildElf, bool tfa, bool noTfa, String packages, List<String> ds) {
  if (!FileSystemEntity.isFileSync(sourceFile)) {
    print('Error: $sourceFile is not a file');
    return;
  }

  String genSnapshotOption = buildElf
      ? '--snapshot-kind=app-aot-assembly'
      : '--snapshot-kind=app-aot-blobs';
  String genSnapshotFilename = buildElf
      ? '--assembly=$snapshotFile.S'
      : '--blobs_container_filename=$snapshotFile';

  String snapDir = dirname(Platform.script.path);
  String binDir = canonicalize(join(snapDir, '..'));
  String sdkDir = canonicalize(join(binDir, '..'));
  String dartCommand = join(binDir, 'dart');
  String snapshot = join(snapDir, 'gen_kernel.dart.snapshot');

  stdout.write('${clearLine}Generating AOT snapshot');
  List<String> dartArgs = <String>[
    snapshot,
    '--platform',
    '${sdkDir}//lib/_internal/vm_platform_strong.dill',
    '--aot',
    '-Ddart.vm.product=true',
    if (tfa) '--tfa',
    if (noTfa) '--no-tfa',
    ...ds,
    if (packages != null) ...['--packages', packages],
    '-o',
    '$snapshotFile.dill',
    sourceFile
  ];

  var cmdResult = Process.runSync(dartCommand, dartArgs);
  if (cmdResult.exitCode != 0) {
    print('\nGenerating AOT snapshot failed\n');
    print(cmdResult.stdout);
    print(cmdResult.stderr);
    return;
  }

  stdout.write("${clearLine}Generating AOT .dill");
  String genSnapshotCommand = join(binDir, 'utils', 'gen_snapshot');
  List<String> genSnapshotArgs = [
    genSnapshotOption,
    genSnapshotFilename,
    if (enableAsserts) '--enable-asserts',
    '$snapshotFile.dill'
  ];
  cmdResult = Process.runSync(genSnapshotCommand, genSnapshotArgs);
  if (cmdResult.exitCode != 0) {
    print('\nGenerating AOT .dill failed\n');
    print(cmdResult.stdout);
    print(cmdResult.stderr);
    return;
  }
  stdout.write("${clearLine}Done.\n");
  stdout.flush();
}

void setupAOTArgs(ArgParser parser) {
  parser.addFlag('build-elf');
  parser.addFlag('enable-asserts');
  parser.addFlag('tfa');
  parser.addFlag('no-tfa');
  parser.addOption('packages');
}
