// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_tests;
import "package:expect/expect.dart";
import 'dart:isolate';
import '../async_helper.dart';

funcFoo(x) => x + 2;

echo() {
  port.receive((msg, reply) {
    reply.send("echoing ${msg(1)}}");
  });
}

main() {
  var snd = spawnFunction(echo);
  var caught_exception = false;
  try {
    snd.send(funcFoo, port.toSendPort());
  } catch (e) {
    caught_exception = true;
  }

  if (caught_exception) {
    port.close();
  } else {
    asyncStart();
    port.receive((msg, reply) {
      print("from worker ${msg}");
      asyncEnd();
    });
  }
  Expect.isTrue(caught_exception);
}
