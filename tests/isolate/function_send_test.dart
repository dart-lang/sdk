// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void toplevel(port, message) { port.send("toplevel:$message"); }
Function createFuncToplevel() => (p, m) { p.send(m); };
class C {
  Function initializer;
  Function body;
  C() : initializer = ((p, m) { throw "initializer"; }) {
    body = (p, m) { throw "body"; };
  }
  static void staticFunc(port, message) { port.send("static:$message"); }
  static Function createFuncStatic() => (p, m) { throw "static expr"; };
  void instanceMethod(p, m) { throw "instanceMethod"; }
  Function createFuncMember() => (p, m) { throw "instance expr"; };
  void call(n, p) { throw "C"; }
}

class Callable {
  void call(p, m) { p.send(["callable", m]); }
}


void main() {
  asyncStart();

  // Sendables are top-level functions and static functions only.
  testSendable("toplevel", toplevel);
  testSendable("static", C.staticFunc);
  // Unsendables are any closure - instance methods or function expression.
  var c = new C();
  testUnsendable("instance method", c.instanceMethod);
  testUnsendable("static context expression", createFuncToplevel());
  testUnsendable("static context expression", C.createFuncStatic());
  testUnsendable("initializer context expression", c.initializer);
  testUnsendable("constructor context expression", c.body);
  testUnsendable("instance method context expression", c.createFuncMember());

  // The result of `toplevel.call` and `staticFunc.call` may or may not be
  // identical to `toplevel` and `staticFunc` respectively. If they are not
  // equal, they may or may not be considered toplevel/static functions anyway,
  // and therefore sendable. The VM and dart2js curretnly disagrees on whether
  // `toplevel` and `toplevel.call` are identical, both allow them to be sent.
  // If this is ever specified to something else, use:
  //     testUnsendable("toplevel.call", toplevel.call);
  //     testUnsendable("static.call", C.staticFunc.call);
  // instead.
  // These two tests should be considered canaries for accidental behavior
  // change rather than requirements.
  testSendable("toplevel", toplevel.call);
  testSendable("static", C.staticFunc.call);

  // Callable objects are sendable if general objects are (VM yes, dart2js no).
  // It's unspecified whether arbitrary objects can be sent. If it is specified,
  // add a test that `new Callable()` is either sendable or unsendable.

  // The call method of a callable object is a closure holding the object,
  // not a top-level or static function, so it should be blocked, just as
  // a normal method.
  testUnsendable("callable object", new Callable().call);

  asyncEnd();
  return;
}

// Create a receive port that expects exactly one message.
// Pass the message to `callback` and return the sendPort.
SendPort singleMessagePort(callback) {
  var p;
  p = new RawReceivePort((v) { p.close(); callback(v); });
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
  }).then((port) { port.send(func); });
}

// Creates a new isolate and a pair of ports that expect a single message
// to be sent to the other isolate and back to the callback function.
Future<SendPort> echoPort(callback(value)) {
  Completer completer = new Completer<SendPort>();
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
    requestPort.close();  // Single echo only.
  });
  msg[1].send(requestPort.sendPort);
}

// Creates other isolate that waits for a single message, `msg`, on the returned
// port, and executes it as `msg[0](msg[1],msg[2])` in the other isolate.
Future<SendPort> callPort() {
  Completer completer = new Completer<SendPort>();
  SendPort initPort = singleMessagePort(completer.complete);
  return Isolate.spawn(_call, initPort)
                .then((_) => completer.future);
}

void _call(initPort) {
  initPort.send(singleMessagePort(callFunc));
}

void testUnsendable(name, func) {
  asyncStart();
  Isolate.spawn(nop, func).then((v) => throw "allowed spawn direct?",
                                onError: (e,s){ asyncEnd(); });
  asyncStart();
  Isolate.spawn(nop, [func]).then((v) => throw "allowed spawn wrapped?",
                                  onError: (e,s){ asyncEnd(); });

  asyncStart();
  var noReply = new RawReceivePort((_) { throw "Unexpected message: $_"; });
  // Currently succeedes incorrectly in dart2js.
  Expect.throws(() {                /// 01: ok
    noReply.sendPort.send(func);    /// 01: continued
  }, null, "send direct");          /// 01: continued
  Expect.throws(() {                /// 01: continued
    noReply.sendPort.send([func]);  /// 01: continued
  }, null, "send wrapped");         /// 01: continued
  scheduleMicrotask(() {
    noReply.close();
    asyncEnd();
  });

  // Try sending through other isolate.
  asyncStart();
  echoPort((v) { Expect.equals(0, v); })
    .then((p) {
      try {
        p.send(func);
      } finally {
        p.send(0);   // Closes echo port.
      }
    })
    .then((p) => throw "unreachable 2",
          onError: (e, s) {asyncEnd();});
}

void nop(_) {}

void callFunc(message) {
  message[0](message[1], message[2]);
}
