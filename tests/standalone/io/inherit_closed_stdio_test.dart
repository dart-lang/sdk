// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/64744

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (Platform.isFuchsia) return; // inheritStdio not supported

  if (args.contains('--grandchild')) {
    stdout.writeln("something");
    stderr.writeln("something");
    await stdin.drain<void>().timeout(
      Duration(seconds: 1),
      onTimeout: () => "okay",
    );
    exitCode = 10;
    return;
  }

  if (args.contains('--child')) {
    await stdin.drain<void>();
    stdout.close();
    stderr.close();
    final grandchild = await Process.start(Platform.resolvedExecutable, [
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      '--grandchild',
    ], mode: ProcessStartMode.inheritStdio);
    final code = await grandchild.exitCode;
    print('grandchild exit=$code');
    if (code != 10) throw "bad exit";
    exitCode = 20;
    return;
  }

  final child = await Process.start(Platform.resolvedExecutable, [
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    '--child',
  ]);
  child.stdin.close();
  child.stdout.listen(stdout.add);
  child.stderr.listen(stderr.add);
  final code = await child.exitCode;
  print('child $code');
  if (code != 20) {
    throw "bad exit";
  }
}
