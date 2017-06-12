// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_in_isolate2_test;

import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

import 'deferred_in_isolate2_lib.dart' deferred as lib;

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
