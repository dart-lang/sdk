// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that we don't create duplicate local contexts in the same
// function. It's modeled after the 'startIsolateMock' function which was broken
// in the standard library.
class X {}

typedef dynamic fn(dynamic x);
typedef dynamic fn2(dynamic x, dynamic y);

void startIsolateMock(
    dynamic parentPort,
    dynamic entryPoint,
    dynamic args,
    dynamic message,
    dynamic isSpawnUri,
    dynamic controlPort,
    List<dynamic> capabilities) {
  if (controlPort != null) {
    controlPort.handler = (dynamic _) {};
  }
  if (parentPort != null) {
    dynamic readyMessage = new List<dynamic>(2);
    readyMessage[0] = controlPort.sendPort;
    readyMessage[1] = capabilities;
    capabilities = null;
    parentPort.send(readyMessage);
  }
  assert(capabilities == null);
  dynamic port = "abc";
  port.handler = (dynamic _) {
    port.close();
    if (isSpawnUri) {
      if (entryPoint is fn2) {
        entryPoint.call(args, message);
      } else if (entryPoint is fn) {
        entryPoint.call(args);
      } else {
        entryPoint.call();
      }
    } else {
      entryPoint.call(message);
    }
  };
  port.sendPort.send(null);
}

main() {
  // No code here -- we just check that duplicate contexts aren't created above.
}
