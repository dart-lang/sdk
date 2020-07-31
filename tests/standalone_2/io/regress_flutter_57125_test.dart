// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that an exception on a non-socket _NativeSocket, e.g. a pipe to
/// another process, is properly thrown as a SocketException. This test confirms
/// the absence of a regression during the dart:io null safety migration where
/// the late localAddress field wasn't initialized in an error path, raising a
/// LateInitializationError instead.
///
/// https://github.com/flutter/flutter/issues/57125

import 'dart:io';

Future<void> main() async {
  final process = await Process.start("exit", [], runInShell: true);
  process.stdout.drain();
  process.stderr.drain();
  bool finished = false;
  // Ensure any other exception is unhandled and fails the test.
  process.stdin.done.catchError((e) {
    finished = true;
  }, test: (e) => e is SocketException);
  while (!finished) {
    process.stdin.write("a");
    await Future.delayed(new Duration(microseconds: 1));
  }
  process.stdin.close();
  await process.exitCode;
  // Windows hangs for some reason.
  exit(0);
}
