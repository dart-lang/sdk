// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'binary_md_dill_reader.dart' show BinaryMdDillReader;

import 'incremental_load_from_dill_suite.dart'
    show getOptions, normalCompileToBytes;

import 'utils/io_utils.dart' show computeRepoDir;

main() async {
  await testDart2jsCompile();
}

Future<void> testDart2jsCompile() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  Stopwatch stopwatch = new Stopwatch()..start();
  List<int> bytes = await normalCompileToBytes(dart2jsUrl,
      options: getOptions(target: new NoneTarget(new TargetFlags())));
  print("Compiled dart2js in ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
  String binaryMdContent = binaryMd.readAsStringSync();
  print("Read binary.md in ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  BinaryMdDillReader binaryMdDillReader =
      new BinaryMdDillReader(binaryMdContent, bytes);
  binaryMdDillReader.attemptRead();
  print("Parsed dart2js compiled bytes via binary.md "
      "in ${stopwatch.elapsedMilliseconds} ms");
}

final String repoDir = computeRepoDir();

String get dartVm => Platform.executable;
