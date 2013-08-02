// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unknown_command_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class UnknownCommandTest extends VmServiceRequestHelper {
  UnknownCommandTest(port) : super('http://127.0.0.1:$port/badcommand');

  onRequestCompleted(Map reply) {
    Expect.equals('error', reply['type']);
  }
}

main() {
  var process = new TestLauncher('unknown_command_script.dart');
  process.launch().then((port) {
    var test = new UnknownCommandTest(port);
    test.makeRequest().then((_) {
      process.requestExit();
    });
  });
}
