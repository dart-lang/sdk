// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
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

  // top-level functions, static functions, closures, instance methods
  // or function expressions are not sendable to an isolate spawned using
  // spawnUri.
  testUnsendable("toplevel", toplevel);
  testUnsendable("static", C.staticFunc);
  var c = new C();
  testUnsendable("instance method", c.instanceMethod);
  testUnsendable("static context expression", createFuncToplevel());
  testUnsendable("static context expression", C.createFuncStatic());
  testUnsendable("initializer context expression", c.initializer);
  testUnsendable("constructor context expression", c.body);
  testUnsendable("instance method context expression", c.createFuncMember());
  testUnsendable("toplevel", toplevel.call);
  testUnsendable("static", C.staticFunc.call);
  testUnsendable("callable object", new Callable().call);

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

// Creates a new isolate and a pair of ports that expect a single message
// to be sent to the other isolate and back to the callback function.
Future<SendPort> echoPort(callback(value)) {
  Completer<SendPort> completer = new Completer<SendPort>();
  SendPort replyPort = singleMessagePort(callback);
  RawReceivePort initPort;
  initPort = new RawReceivePort((p) {
    completer.complete(p);
    initPort.close();
  });
  return Isolate.spawn(_echo, [replyPort, initPort.sendPort]).then(
      (isolate) => completer.future);
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
  Completer<SendPort> completer = new Completer<SendPort>();
  SendPort initPort = singleMessagePort(completer.complete);
  return Isolate.spawn(_call, initPort).then((_) => completer.future);
}

void _call(initPort) {
  initPort.send(singleMessagePort(callFunc));
}

void testUnsendable(name, func) {
  asyncStart();
  Isolate
      .spawnUri(Uri.parse("function_send_test.dart"), [], func)
      .then((v) => throw "allowed spawn direct?", onError: (e, s) {
    asyncEnd();
  });
  asyncStart();
  Isolate.spawnUri(Uri.parse("function_send_test.dart"), [], [func]).then(
      (v) => throw "allowed spawn wrapped?", onError: (e, s) {
    asyncEnd();
  });
}

void callFunc(message) {
  message[0](message[1], message[2]);
}
