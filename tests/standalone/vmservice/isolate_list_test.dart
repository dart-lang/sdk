// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_list_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';


class VMTest extends VmServiceRequestHelper {
  VMTest(port) : super('http://127.0.0.1:$port/vm');

  onRequestCompleted(Map reply) {
    VMTester tester = new VMTester(reply);
    tester.checkIsolateCount(1);
  }
}


main() {
  var process = new TestLauncher('isolate_list_script.dart');
  process.launch().then((port) {
    var test = new VMTest(port);
    test.makeRequest().then((_) {
      process.requestExit();
    });
  });
}
