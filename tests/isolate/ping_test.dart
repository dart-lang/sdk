// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

isomain1(replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    replyPort.send(v);
    if (v == 0) port.close();
  };
  replyPort.send(port.sendPort);
}

void main(){
  asyncStart();
  var completer = new Completer();  // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  Isolate.spawn(isomain1, reply.sendPort).then((Isolate isolate) {
    List result = [];
    completer.future.then((echoPort) {
      reply.handler = (v) {
        result.add(v);
        if (v == 0) {
          Expect.listEquals(["alive", "control", "event"],
                            result.where((x) => x is String).toList(),
                            "control events");
          Expect.listEquals([4, 3, 2, 1, 0],
                            result.where((x) => x is int).toList(),
                            "data events");
          Expect.isTrue(result.indexOf("alive") < result.indexOf(3),
                        "alive index < 3");
          Expect.isTrue(result.indexOf("control") < result.indexOf(2),
                        "control index < 2");
          int eventIndex = result.indexOf("event");
          Expect.isTrue(eventIndex > result.indexOf(2), "event index > 2");
          Expect.isTrue(eventIndex < result.indexOf(1), "event index < 1");
          reply.close();
          asyncEnd();
        }
      };
      SendPort createPingPort(message) {
        var pingPort = new RawReceivePort();
        pingPort.handler = (_) {
          result.add(message);
          pingPort.close();
        };
        return pingPort.sendPort;
      }
      echoPort.send(4);
      isolate.ping(createPingPort("alive"), Isolate.IMMEDIATE);
      echoPort.send(3);
      isolate.ping(createPingPort("control"), Isolate.BEFORE_NEXT_EVENT);
      echoPort.send(2);
      isolate.ping(createPingPort("event"), Isolate.AS_EVENT);
      echoPort.send(1);
      echoPort.send(0);
    });
  });
}
