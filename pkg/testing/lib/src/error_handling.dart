// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.error_handling;

import 'dart:async' show Future;

import 'dart:io' show exitCode, stderr;

import 'dart:isolate' show ReceivePort;

Future withErrorHandling(Future f()) async {
  final ReceivePort port = new ReceivePort();
  try {
    return await f();
  } catch (e, trace) {
    exitCode = 1;
    stderr.writeln(e);
    if (trace != null) {
      stderr.writeln(trace);
    }
  } finally {
    port.close();
  }
}
