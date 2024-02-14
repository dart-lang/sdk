// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that failing to write to `Process.stdin` results in an exception
// being thrown by `process.stdin.flush()` and `process.stdin.done`.
//
// See https://github.com/dart-lang/sdk/issues/48501
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:math';

import "process_test_util.dart";

Future test(Process process) async {}

void main() async {
  if (!Platform.isLinux && !Platform.isMacOS) {
    print('test not supported on ${Platform.operatingSystem}');
    return;
  }

  final process = await Process.start('false', const <String>[]);
  try {
    for (var i = 0; i < 20; ++i) {
      // Ensure that the pipe is broken while we are writing.
      process.stdin.add([1, 2, 3]);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    try {
      await process.stdin.flush();
      Expect.fail('await process.stdin.flush(): expected exception');
    } on SocketException catch (e) {
      Expect.equals(32, e.osError!.errorCode); // Broken pipe
    }

    try {
      await process.stdin.done;
      Expect.fail('await process.stdin.done: expected exception');
    } on SocketException catch (e) {
      Expect.equals(32, e.osError!.errorCode); // Broken pipe
    }
  } finally {
    process.kill();
  }
}
