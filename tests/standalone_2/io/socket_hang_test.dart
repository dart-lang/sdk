// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';

import 'package:expect/expect.dart';

// A regression test for: https://github.com/dart-lang/sdk/issues/40589
Future<void> main(List<String> args) async {
  if (args.length != 0) {
    for (int i = 0; i < 100000; i++) {
      print('line $i');
    }
    print('done');
    return;
  } else {
    // Create child process and keeps writing into stdout.
    final p = await Process.start(
        Platform.executable, [Platform.script.toFilePath(), 'child']);
    p.stdout.drain();
    p.stderr.drain();
    final exitCode = await p.exitCode;
    if (exitCode != 0) {
      Expect.fail('process failed with ${exitCode}');
    }
    return;
  }
}
