// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:args/args.dart';

import 'util.dart';

// Tests running the Wasm dev compiler and runtime (`pkg/wasm_dev_rt`).
Future<void> main(List<String> args) async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  final options = (ArgParser()..addFlag('src', negatable: false)).parse(args);
  await withTempDir((String directory) async {
    final runtime = '$directory/wasm_dev_rt';
    final app = '$directory/app.wasm';
    await run([
      'bash',
      'pkg/dart2wasm/tool/compile_benchmark',
      if (options.flag('src')) '--src',
      '--enable-experimental-wasm-interop',
      'pkg/wasm_dev_rt/bin/wasm_dev_rt.dart',
      '$runtime.wasm',
    ]);
    await run([
      Platform.resolvedExecutable,
      'pkg/dart2wasm/bin/dart2wasm_dev.dart',
      app,
    ]);

    final arch = Abi.current().toString().split('_').last;
    final d8 = 'third_party/d8/${Platform.operatingSystem}/$arch/d8';
    final result = Process.runSync(d8, [
      'pkg/dart2wasm/test/dev/run.js',
      '--',
      '$runtime.mjs',
      '$runtime.wasm',
      app,
    ]);
    if (result.exitCode != 0 ||
        (result.stdout as String).trim() != 'Hello, world!') {
      throw 'Unexpected result:\n${result.stdout}\n${result.stderr}';
    }
  });
}
