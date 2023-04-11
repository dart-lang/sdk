// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

const classCount = 10000;
const subclassCount = 5000;

// Generates an example that causes generation of a TypeTestingStub checking for
// 10000 classes - thereby making the TTS larger than 32 KB.
//
// We alternate classes to be subclasses of I0 and I1 to ensure that subclasses
// of I0 do not have consecutive class ids.
String generateExample() {
  final sb = StringBuffer()..writeln('''
class I0 {}
class I1 {}
  ''');
  for (int i = 0; i < classCount; ++i) {
    sb.writeln('class S$i extends I${i % 2} {}');
  }
  sb.writeln('final all = <Object>[');
  for (int i = 0; i < classCount; ++i) {
    sb.writeln('  S$i(),');
  }
  sb.writeln('];');
  sb.writeln('''
main() {
  int succeeded = 0;
  int failed = 0;
  for (dynamic obj in all) {
    try {
      obj as I0;
      succeeded++;
    } on TypeError catch (e, s) {
      failed++;
    }
  }
  if (succeeded != $subclassCount ||
      failed != $subclassCount) {
    throw 'Error: succeeded: \$succeeded, failed: \$failed';
  }
}
  ''');
  return sb.toString();
}

void main(List<String> args) async {
  if (!Platform.isLinux) {
    // We want this test to run in (sim)arm, (sim)arm64 on Linux in JIT/AOT.
    // As written it wouldn't run on Windows / Android due to testing setup.
    return;
  }

  final bool isAot = Platform.executable.contains('dart_precompiled_runtime');

  await withTempDir('tts', (String temp) async {
    final script = path.join(temp, 'script.dart');
    await File(script).writeAsString(generateExample());

    // We always compile to .dill file because simarm/simarm64 runs really slow
    // from source (and this dart2kernel compilation happens with checked-in
    // binaries).
    final scriptDill = path.join(temp, 'script.dart.dill');
    await run('pkg/vm/tool/gen_kernel', <String>[
      isAot ? '--aot' : '--no-aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    String mainFile = scriptDill;
    if (isAot) {
      final elfFile = path.join(temp, 'script.dart.dill.elf');
      await run(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--elf=$elfFile',
        scriptDill,
      ]);
      mainFile = elfFile;
    }
    await run(Platform.executable, [mainFile]);
  });
}
