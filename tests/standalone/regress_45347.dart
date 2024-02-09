// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/45347

import 'dart:developer';
import 'dart:isolate';
import "package:expect/expect.dart";

void sendSetOfEnums(SendPort port) {
  Isolate childIsolate = Isolate.current;
  port.send(childIsolate);
}

void main() async {
  try {
    final id = Service.getIsolateId(Isolate.current) ?? "NA";
    print(id);

    final port = ReceivePort();
    await Isolate.spawn(sendSetOfEnums, port.sendPort);
    Isolate childIsolate = await port.first;
    final did = childIsolate.debugName ?? "NA";
    print(did);
  } catch (e, s) {
    Expect.isTrue(false);
  }
}
