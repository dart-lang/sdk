// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_echo_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class EchoRequestTest extends VmServiceRequestHelper {
  EchoRequestTest(port, id) :
      super('http://127.0.0.1:$port/$id/_echo/foo/bar?a=b&k=&d=e&z=w');

  onRequestCompleted(Map reply) {
    Expect.equals('message', reply['type']);

    Expect.equals(3, reply['message']['arguments'].length);
    Expect.equals('_echo', reply['message']['arguments'][0]);
    Expect.equals('foo', reply['message']['arguments'][1]);
    Expect.equals('bar', reply['message']['arguments'][2]);

    Expect.equals(4, reply['message']['option_keys'].length);
    Expect.equals('a', reply['message']['option_keys'][0]);
    Expect.equals('k', reply['message']['option_keys'][1]);
    Expect.equals('d', reply['message']['option_keys'][2]);
    Expect.equals('z', reply['message']['option_keys'][3]);

    Expect.equals(4, reply['message']['option_values'].length);
    Expect.equals('b', reply['message']['option_values'][0]);
    Expect.equals('', reply['message']['option_values'][1]);
    Expect.equals('e', reply['message']['option_values'][2]);
    Expect.equals('w', reply['message']['option_values'][3]);
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  String _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(1);
    _isolateId = tester.getIsolateId(0);
  }
}


main() {
  var process = new TestLauncher('isolate_echo_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var echoRequestTest = new EchoRequestTest(port, test._isolateId);
      echoRequestTest.makeRequest().then((_) {
        process.requestExit();
      });
    });
  });
}
