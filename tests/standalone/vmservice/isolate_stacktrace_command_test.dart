// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_stacktrace_command_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class StacktraceTest extends VmServiceRequestHelper {
  StacktraceTest(port, id) :
      super('http://127.0.0.1:$port/$id/stacktrace');

  onRequestCompleted(Map reply) {
    Expect.equals('StackTrace', reply['type'], 'Not a StackTrace message.');
    Expect.isTrue(4 <= reply['members'].length, 'Stacktrace is wrong length.');
    // The number of frames involved in isolate message dispatch is an
    // implementation detail. Only check that we got all the frames for user
    // code.
    Expect.equals('a', reply['members'][0]['function']['name']);
    Expect.equals('b', reply['members'][1]['function']['name']);
    Expect.equals('c', reply['members'][2]['function']['name']);
    Expect.equals('myIsolateName', reply['members'][3]['function']['name']);
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  String _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(2);
    // TODO(turnidge): Fragile.  Relies on isolate order in response.
    _isolateId = tester.getIsolateId(1);
  }
}


main() {
  var process = new TestLauncher('isolate_stacktrace_command_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var stacktraceTest = new StacktraceTest(port, test._isolateId);
      stacktraceTest.makeRequest().then((_) {
        process.requestExit();
      });
    });
  });
}
