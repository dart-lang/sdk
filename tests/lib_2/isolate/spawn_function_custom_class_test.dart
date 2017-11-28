// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Create a user-defined class in a new isolate.
//
// Regression test for vm bug 2235: We were forgetting to finalize
// classes in new isolates started using the v2 api.

library spawn_tests;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

class MyClass {
  var myVar = 'there';
  myFunc(msg) {
    return '$msg $myVar';
  }
}

child(args) {
  var reply = args[1];
  var msg = args[0];
  reply.send('re: ${new MyClass().myFunc(msg)}');
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test('message - reply chain', () {
    ReceivePort port = new ReceivePort();
    Isolate.spawn(child, ['hi', port.sendPort]);
    port.listen((msg) {
      port.close();
      expect(msg, equals('re: hi there'));
    });
  });
}
