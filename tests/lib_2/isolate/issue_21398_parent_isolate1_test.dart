// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=issue_21398_child_isolate1.dart
// OtherScripts=issue_21398_child_isolate11.dart

import 'dart:isolate';
import 'dart:async';
import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';

class FromMainIsolate {
  String toString() => 'from main isolate';
  int get fld => 10;
}

func1Child(args) {
  var receivePort = new ReceivePort();
  var sendPort = args[0];
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) {
    Expect.isTrue(msg is FromMainIsolate);
    Expect.equals(10, msg.fld);
    receivePort.close();
    sendPort.send("done");
  }, onError: (e) => print('$e'));
}

func2Child(args) {
  var receivePort = new ReceivePort();
  var sendPort = args[0];
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) {
    Expect.isTrue(msg is SendPort);
    msg.send(new FromMainIsolate());
    receivePort.close();
  }, onError: (e) => print('$e'));
}

spawnFuncTest() {
  var receive1 = new ReceivePort();
  var receive2 = new ReceivePort();

  var spawnFunctionIsolate1SendPort;
  var spawnFunctionIsolate2SendPort;

  // First spawn the first isolate using spawnFunction, this isolate will
  // create a receivePort and send it's sendPort back and then it will just
  // sit there listening for a message from the second isolate spawned
  // using spawnFunction.
  asyncStart();
  return Isolate.spawn(func1Child, [receive1.sendPort]).then((isolate) {
    receive1.listen((msg) {
      if (msg is SendPort) {
        spawnFunctionIsolate1SendPort = msg;

        // Now spawn the second isolate using spawnFunction, this isolate
        // will create a receivePort and send it's sendPort back and then
        // wait for the third isolate spawned using spawnUri to send it
        // a sendPort to which it will try and send a non "literal-like"
        // object.
        Isolate.spawn(func2Child, [receive2.sendPort]).then((isolate) {
          receive2.listen((msg) {
            spawnFunctionIsolate2SendPort = msg;
            receive2.close();

            // Now spawn an isolate using spawnUri and send these send
            // ports over to it. This isolate will send one of the
            // sendports over to the other.
            Isolate.spawnUri(
                Uri.parse('issue_21398_child_isolate1.dart'),
                [spawnFunctionIsolate1SendPort, spawnFunctionIsolate2SendPort],
                "no-msg");
          }, onError: (e) => print('$e'));
        });
      } else if (msg == "done") {
        receive1.close();
        asyncEnd();
      } else {
        Expect.fail("Invalid message received: $msg");
      }
    }, onError: (e) => print('$e'));
  });
}

uriChild(args) {
  var receivePort = new ReceivePort();
  var sendPort = args[0];
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) {
    Expect.isTrue(msg is String);
    Expect.equals("Invalid Argument(s).", msg);
    receivePort.close();
    sendPort.send("done");
  }, onError: (e) => print('$e'));
}

spawnUriTest() {
  var receive1 = new ReceivePort();
  var receive2 = new ReceivePort();

  var spawnFunctionIsolateSendPort;
  var spawnUriIsolateSendPort;

  // First spawn the first isolate using spawnFunction, this isolate will
  // create a receivePort and send it's sendPort back and then it will just
  // sit there listening for a message from the second isolate spawned
  // using spawnFunction.
  asyncStart();
  Isolate.spawn(uriChild, [receive1.sendPort]).then((isolate) {
    receive1.listen((msg) {
      if (msg is SendPort) {
        spawnFunctionIsolateSendPort = msg;

        // Now spawn the second isolate using spawnUri, this isolate
        // will create a receivePort and send it's sendPort back and then
        // wait for the third isolate spawned using spawnUri to send it
        // a sendPort to which it will try and send a non "literal-like"
        // object.
        Isolate
            .spawnUri(Uri.parse('issue_21398_child_isolate11.dart'), [],
                receive2.sendPort)
            .then((isolate) {
          receive2.listen((msg) {
            spawnUriIsolateSendPort = msg;
            receive2.close();

            // Now spawn an isolate using spawnUri and send these send
            // ports over to it. This isolate will send one of the
            // sendports over to the other.
            Isolate.spawnUri(
                Uri.parse('issue_21398_child_isolate1.dart'),
                [spawnFunctionIsolateSendPort, spawnUriIsolateSendPort],
                "no-msg");
          }, onError: (e) => print('$e'));
        });
      } else if (msg == "done") {
        receive1.close();
        asyncEnd();
      } else {
        Expect.fail("Invalid message received: $msg");
      }
    }, onError: (e) => print('$e'));
  });
}

main() {
  spawnFuncTest();
  spawnUriTest();
}
