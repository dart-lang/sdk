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
    final dartFile = '$directory/app.dart';
    File(dartFile).writeAsStringSync('''
class Greeter {
  static String greeting() => 'Hello, world!';
}

void greet(String message) => print(message);

void main() => greet(Greeter.greeting());
''');

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
      if (options.flag('src'))
        '--libraries-spec=sdk/lib/libraries.json'
      else
        '--platform=${_findPlatformFile()}',
      dartFile,
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

/// This test may be run from the built Dart SDK (e.g.
/// out/ReleaseX64/dart-sdk/bin/dart) but the dart2wasm_dev_platform.dill file
/// isn't shipped (yet) with the SDK and is only available in the normal build
/// folder (e.g. out/ReleaseX64).
///
/// => We walk up the parent directory chain to find it, so it will work as long
/// as the `dart` binary is either the one in build dir or the one in the built
/// Dart SDK dir.
String _findPlatformFile() {
  Directory dir = File(Platform.resolvedExecutable).parent;
  while (true) {
    final file = File('${dir.path}/dart2wasm_dev_platform.dill');
    if (file.existsSync()) return file.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find dart2wasm_dev_platform.dill');
    }
    dir = parent;
  }
}
