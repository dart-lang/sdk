// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:platform" as platform;

import "dart:isolate";
import "package:unittest/unittest.dart";

main() {
  var sendPort = spawnFunction(f);
  expect(sendPort.call("platform.executable"), completion(platform.executable));
  if (platform.script != null) {
    expect(sendPort.call("platform.script").then((s) => s.path),
           completion(endsWith('tests/lib/platform/isolate_test.dart')));
  }
  expect(sendPort.call("platform.packageRoot"),
         completion(platform.packageRoot));
  expect(sendPort.call("platform.executableArguments"),
         completion(platform.executableArguments));
}

void f() {
  int count = 0;
  port.receive((msg, reply) {
    if (msg == "platform.executable") {
      reply.send(platform.executable);
    }
    if (msg == "platform.script") {
      reply.send(platform.script);
    }
    if (msg == "platform.packageRoot") {
      reply.send(platform.packageRoot);
    }
    if (msg == "platform.executableArguments") {
      reply.send(platform.executableArguments);
    }
    count++;
    if (count == 4) {
      port.close();
    }
  });
}
