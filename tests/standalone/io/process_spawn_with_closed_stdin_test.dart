// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/64744

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.contains('--grandchild')) {
    await stdin.drain<void>();
    return;
  }

  if (args.contains('--child')) {
    // Read stdin to EOF, so dart:io closes fd 0.
    await stdin.drain<void>();

    final grandchild = await Process.start(Platform.resolvedExecutable, [
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      '--grandchild',
    ]);
    grandchild.stdin.close();
    final code = await grandchild.exitCode;
    print('grandchild exit=$code');
    return;
  }

  final child = await Process.start(Platform.resolvedExecutable, [
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    '--child',
  ]);
  child.stdin.close();
  final code = await child.exitCode;
  print('child $code');
}
