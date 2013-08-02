// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_stacktrace_command_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class StacktraceTest extends VmServiceRequestHelper {
  StacktraceTest(port, id) :
      super('http://127.0.0.1:$port/isolates/$id/stacktrace');

  onRequestCompleted(Map reply) {
    Expect.equals('StackTrace', reply['type'], 'Not a StackTrace message.');
    Expect.equals(4, reply['members'].length, 'Stacktrace is wrong length.');
    Expect.equals('a', reply['members'][0]['name']);
    Expect.equals('b', reply['members'][1]['name']);
    Expect.equals('c', reply['members'][2]['name']);
    Expect.equals('myIsolateName', reply['members'][3]['name']);
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  int _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(2);
    _isolateId = tester.checkIsolateNameContains('myIsolateName');
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
