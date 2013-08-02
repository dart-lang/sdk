// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unknown_isolate_command_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class UnknownRequestTest extends VmServiceRequestHelper {
  UnknownRequestTest(port, id) :
      super('http://127.0.0.1:$port/isolates/$id/badrequest');

  onRequestCompleted(Map reply) {
    Expect.equals('error', reply['type']);
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  int _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(1);
    tester.checkIsolateNameContains('unknown_isolate_command_script.dart');
    _isolateId = reply['members'][0]['id'];
  }
}


main() {
  var process = new TestLauncher('unknown_isolate_command_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var unknownRequestTest = new UnknownRequestTest(port, test._isolateId);
      unknownRequestTest.makeRequest().then((_) {
        process.requestExit();
      });
    });
  });
}
