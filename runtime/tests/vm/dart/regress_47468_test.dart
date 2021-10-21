// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47468.
// Verifies that the sending empty non-const maps works

// VMOptions=--no-enable-isolate-groups

import 'dart:isolate';

void main() async {
  final nonConstMap = <int, Object>{};
  final receivePort = ReceivePort();
  final sendPort = receivePort.sendPort;
  sendPort.send(nonConstMap);
  await receivePort.first;
}
