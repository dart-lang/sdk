// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_isolate_list_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class MultipleIsolateListTest extends VmServiceRequestHelper {
  MultipleIsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(2);
  }
}

main() {
  var process = new TestLauncher('multiple_isolate_list_script.dart');
  process.launch().then((port) {
    var test = new MultipleIsolateListTest(port);
    test.makeRequest().then((_) {
      process.requestExit();
    });
  });
}
