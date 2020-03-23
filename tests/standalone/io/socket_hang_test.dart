// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

void main(List<String> args) async {
  if (args.length != 0) {
    for (int i = 0; i < 100000; i++) {
      print('line $i');
    }
    print('done');
    return;
  } else {
    // Create child process and keeps writing into stdout.
    final p = await io.Process.start(
        io.Platform.executable, [io.Platform.script.toFilePath(), 'child']);
    p.stdout.transform(utf8.decoder).listen((x) => print('stdout: $x'));
    p.stderr.transform(utf8.decoder).listen((x) => print('stderr: $x'));
    final exitCode = await p.exitCode;
    print('process exited with ${exitCode}');
  }
}
