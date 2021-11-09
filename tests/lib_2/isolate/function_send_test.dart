// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--no-enable-fast-object-copy
// VMOptions=--enable-fast-object-copy

import "dart:isolate";
import "dart:io";
import "dart:async";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void toplevel(port, message) {
  port.send("toplevel:$message");
}

Function createFuncToplevel() => (p, m) {
      p.send(m);
    };

class C {
  Function initializer;
  Function body;
  C()
      : initializer = ((p, m) {
          throw "initializer";
        }) {
    body = (p, m) {
      throw "body";
    };
  }
  static void staticFunc(port, message) {
    port.send("static:$message");
  }

  static Function createFuncStatic() => (p, m) {
        throw "static expr";
      };
  void instanceMethod(p, m) {
    throw "instanceMethod";
  }

  Function createFuncMember() => (p, m) {
        throw "instance expr";
      };
  void call(n, p) {
    throw "C";
  }
}

class Callable {
  void call(p, m) {
    p.send(["callable", m]);
  }
}

void main() {
  asyncStart();

  // Sendables are top-level functions and static functions only.
  testSendable("toplevel", toplevel);
  testSendable("static", C.staticFunc);

  // The result of `toplevel.call` and `staticFunc.call` may or may not be
  // identical to `toplevel` and `staticFunc` respectively. If they are not
  // equal, they may or may not be considered toplevel/static functions anyway,
  // and therefore sendable. The VM and dart2js currently disagree on whether
  // `toplevel` and `toplevel.call` are identical, both allow them to be sent.
  // These two tests should be considered canaries for accidental behavior
  // change rather than requirements.
  testSendable("toplevel", toplevel.call);
  testSendable("static", C.staticFunc.call);

  asyncEnd();
  return;
}

// Create a receive port that expects exactly one message.
// Pass the message to `callback` and return the sendPort.
SendPort singleMessagePort(callback) {
  var p;
  p = new RawReceivePort((v) {
    p.close();
    callback(v);
  });
  return p.sendPort;
}

// A singleMessagePort that expects the message to be a specific value.
SendPort expectMessagePort(message) {
  asyncStart();
  return singleMessagePort((v) {
    Expect.equals(message, v);
    asyncEnd();
  });
}

void testSendable(name, func) {
  // Function as spawn message.
  Isolate.spawn(callFunc, [func, expectMessagePort("$name:spawn"), "spawn"]);

  // Send function to same isolate.
  var reply = expectMessagePort("$name:direct");
  singleMessagePort(callFunc).send([func, reply, "direct"]);

  // Send function to other isolate, call it there.
  reply = expectMessagePort("$name:other isolate");
  callPort().then((p) {
    p.send([func, reply, "other isolate"]);
  });

  // Round-trip function trough other isolate.
  echoPort((roundtripFunc) {
    Expect.identical(func, roundtripFunc, "$name:send through isolate");
  }).then((port) {
    port.send(func);
  });
}

// Creates a new isolate and a pair of ports that expect a single message
// to be sent to the other isolate and back to the callback function.
Future<SendPort> echoPort(callback(value)) {
  final completer = new Completer<SendPort>();
  SendPort replyPort = singleMessagePort(callback);
  RawReceivePort initPort;
  initPort = new RawReceivePort((p) {
    completer.complete(p);
    initPort.close();
  });
  return Isolate.spawn(_echo, [replyPort, initPort.sendPort])
      .then((isolate) => completer.future);
}

void _echo(msg) {
  var replyPort = msg[0];
  RawReceivePort requestPort;
  requestPort = new RawReceivePort((msg) {
    replyPort.send(msg);
    requestPort.close(); // Single echo only.
  });
  msg[1].send(requestPort.sendPort);
}

// Creates other isolate that waits for a single message, `msg`, on the returned
// port, and executes it as `msg[0](msg[1],msg[2])` in the other isolate.
Future<SendPort> callPort() {
  final completer = new Completer<SendPort>();
  SendPort initPort = singleMessagePort(completer.complete);
  return Isolate.spawn(_call, initPort).then((_) => completer.future);
}

void _call(initPort) {
  initPort.send(singleMessagePort(callFunc));
}

void nop(_) {}

void callFunc(message) {
  message[0](message[1], message[2]);
}
