// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_class_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class MethodTest extends VmServiceRequestHelper {
  MethodTest(port, id, functionId) :
      super('http://127.0.0.1:$port/$id/$functionId');
  onRequestCompleted(Map reply) {
    Expect.equals('Function', reply['type']);
    Expect.equals('c', reply['name']);
    Expect.equals(false, reply['static']);
  }
}

class FunctionTest extends VmServiceRequestHelper {
  FunctionTest(port, id, functionId) :
      super('http://127.0.0.1:$port/$id/$functionId');

  onRequestCompleted(Map reply) {
    Expect.equals('Function', reply['type']);
    Expect.equals('a', reply['name']);
    Expect.equals(true, reply['static']);
  }
}

class StackTraceTest extends VmServiceRequestHelper {
  StackTraceTest(port, id) :
      super('http://127.0.0.1:$port/$id/stacktrace');

  String _aId;
  String _cId;
  onRequestCompleted(Map reply) {
    Expect.equals('StackTrace', reply['type']);
    List members = reply['members'];
    Expect.equals('a', members[0]['function']['name']);
    _aId = members[0]['function']['id'];
    Expect.equals('c', members[2]['function']['name']);
    _cId = members[2]['function']['id'];
  }
}

class VMTest extends VmServiceRequestHelper {
  VMTest(port) : super('http://127.0.0.1:$port/vm');

  String _isolateId;
  onRequestCompleted(Map reply) {
    VMTester tester = new VMTester(reply);
    tester.checkIsolateCount(2);
    // TODO(turnidge): Fragile.  Relies on isolate order in response.
    _isolateId = tester.getIsolateId(0);
  }
}

main() {
  var process = new TestLauncher('isolate_stacktrace_command_script.dart');
  process.launch().then((port) {
    var test = new VMTest(port);
    test.makeRequest().then((_) {
      var stackTraceTest =
          new StackTraceTest(port, test._isolateId);
      stackTraceTest.makeRequest().then((_) {
        var functionTest = new FunctionTest(port, test._isolateId,
                                            stackTraceTest._aId);
        functionTest.makeRequest().then((_) {
          var methodTest = new MethodTest(port, test._isolateId,
                                          stackTraceTest._cId);
          methodTest.makeRequest().then((_) {
            process.requestExit();
          });
        });
      });
    });
  });
}
