// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Create a user-defined class in a new isolate.
//
// Regression test for vm bug 2235: We were forgetting to finalize
// classes in new isolates started using the v2 api.

library spawn_tests;

import 'dart:isolate';
import 'package:expect/expect.dart';

class MyClass {
  final myVar = 'there';
  myFunc(msg) {
    return '$msg $myVar';
  }
}

isolateEntryPoint(args) {
  final reply = args[1];
  final msg = args[0];
  reply.send('re: ${new MyClass().myFunc(msg)}');
}

Future<void> main([args, port]) async {
  // message - reply chain'
  final exitPort = ReceivePort();
  final replyPort = ReceivePort();

  Isolate.spawn(isolateEntryPoint, ['hi', replyPort.sendPort],
      onExit: exitPort.sendPort);

  replyPort.listen((msg) {
    replyPort.close();
    Expect.equals(msg, 're: hi there');
  });

  // Explicitly await spawned isolate exit to enforce main isolate not
  // completing (and the stand-alone runtime exiting) before the spawned
  // isolate is done.
  await exitPort.first;
}
