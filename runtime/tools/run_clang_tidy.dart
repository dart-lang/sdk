// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:pool/pool.dart';

const String clangTidy = './buildtools/linux-x64/clang/bin/clang-tidy';

List<String> compilerFlagsForFile(String filepath) {
  final flags = <String>[
    '-I.',
    '-Iruntime',
    '-Iruntime/include',
    '-Ithird_party/tcmalloc/gperftools/src ',
    '-DTARGET_ARCH_X64',
    '-DDEBUG',
    '-DTARGET_OS_LINUX',
  ];
  if (filepath.endsWith("_test.cc")) {
    flags.add('-DTESTING');
  }
  return flags;
}

Future<ProcessResult> runClangTidyOn(String filepath) async {
  // The `runtime/.clang-tidy` file has the enabled checks in it.
  final args = <String>['-quiet', filepath, '--']
    ..addAll(compilerFlagsForFile(filepath));
  return await Process.run(clangTidy, args);
}

final pool = new Pool(max(1, Platform.numberOfProcessors ~/ 2));

// TODO(dartbug.com/38196): Ensure all VM sources are clang-tidy clean.
final Set<String> migratedFiles = Set<String>.from([
  'runtime/vm/native_api_impl.cc',
]);

main(List<String> files) async {
  bool isFirstFailure = true;

  files = files.where((filepath) => migratedFiles.contains(filepath)).toList();

  // Analyze the [files] in parallel.
  await Future.wait(files.map((String filepath) async {
    final processResult =
        await pool.withResource(() => runClangTidyOn(filepath));

    final int exitCode = processResult.exitCode;
    final String stdout = processResult.stdout.trim();
    final String stderr = processResult.stderr.trim();

    if (exitCode != 0 || stdout.isNotEmpty) {
      if (!isFirstFailure) {
        print('');
        print('--------------------------------------------------------------');
        print('');
      }
      isFirstFailure = false;
    }

    if (exitCode != 0) {
      print('exit-code: $exitCode');
      print('stdout:');
      print('${stdout}');
      print('stderr:');
      print('${stderr}');
    } else if (stdout.isNotEmpty) {
      // The actual lints go to stdout.
      print(stdout);
    }
  }));
}
