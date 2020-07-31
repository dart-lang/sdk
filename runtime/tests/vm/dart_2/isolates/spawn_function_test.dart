// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:isolate';
import 'dart:async';

import 'package:expect/expect.dart';

void isolateEntry(args) {
  final SendPort sendPort = args;
  sendPort.send('hello world');
}

main() async {
  final port = ReceivePort();
  final exitPort = ReceivePort();

  await Isolate.spawn(isolateEntry, port.sendPort, onExit: exitPort.sendPort);

  final messages = StreamIterator(port);
  Expect.isTrue(await messages.moveNext());
  Expect.equals('hello world', messages.current);
  await messages.cancel();

  final exit = StreamIterator(exitPort);
  Expect.isTrue(await exit.moveNext());
  await exit.cancel();
}
