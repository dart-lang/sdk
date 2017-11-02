// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

int globalHash = 0;

class A {
  int get hashCode => globalHash;
  bool operator ==(other) => true;
}

final key = new A();

other(SendPort sendPort) async {
  // We use a different hash than the main isolate, but the re-hashing on our
  // side happens after this line and should therefore also deserialize the map
  // with a new hash, so we should be able to find the value in the map.
  globalHash = 4321;

  final port = new ReceivePort();
  sendPort.send(port.sendPort);

  final Map map = await port.first;
  sendPort.send(map[key]);
  port.close();
}

void launchIsolate(argument) {
  other(argument);
}

main() async {
  final r = new ReceivePort();
  final re = new ReceivePort();
  final map = {};

  globalHash = 1234;
  map[key] = 1;

  await Isolate.spawn(launchIsolate, r.sendPort, onError: re.sendPort);
  re.listen((error) => throw 'Error $error');

  final it = new StreamIterator(r);

  await it.moveNext();
  final SendPort port = it.current;

  port.send(map);
  await it.moveNext();
  final otherIsolateMapEntry = await it.current;
  if (map[key] != otherIsolateMapEntry) {
    throw "test failed";
  }
  r.close();
  re.close();
}
