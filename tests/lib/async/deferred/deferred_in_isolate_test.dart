import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

import 'deferred_in_isolate_lib.dart' deferred as lib;

loadDeferred(port) {
  lib.loadLibrary().then((_) {
    port.send(lib.f());
  });
}

main() {
  test("Deferred loading in isolate", () {
    ReceivePort port = new ReceivePort();
    port.first.then(expectAsync((msg) {
       expect(msg, equals("hi"));
    }));
    Isolate.spawn(loadDeferred, port.sendPort);
  });
}
