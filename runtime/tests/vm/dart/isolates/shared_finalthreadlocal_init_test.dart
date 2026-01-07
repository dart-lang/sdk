// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that shared FinalThreadLocal toStringVisiting is properly
// initialized.

import 'dart:async';
import 'dart:isolate';

import "package:expect/expect.dart";

foo(args) {
  int index = args[0];
  SendPort sendPort = args[1];
  Expect.equals(
    'x[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]',
    'x${[for (int i = 0; i < 20; ++i) i]}',
  );
  sendPort.send(index);
}

const nIsolates = 1000;

main() async {
  Set<int> received = Set<int>();
  Completer<bool> allDone = Completer<bool>();
  final rp = ReceivePort()
    ..listen((v) {
      received.add(v);
      if (received.length == nIsolates) {
        allDone.complete(true);
      }
    });
  final isolates = List.generate(
    nIsolates,
    (i) async =>
        await Isolate.spawn(foo, [i, rp.sendPort], debugName: "worker$i"),
  );

  await allDone.future;
  rp.close();
}
