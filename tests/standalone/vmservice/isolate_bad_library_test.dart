// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_bad_library_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class NullCollectionTest extends VmServiceRequestHelper {
  NullCollectionTest(port, id, collection) :
      super('http://127.0.0.1:$port/isolates/$id/$collection/-100');

  onRequestCompleted(Map reply) {
    Expect.equals('null', reply['type']);
  }
}

class BadCollectionTest extends VmServiceRequestHelper {
  BadCollectionTest(port, id, collection) :
      super('http://127.0.0.1:$port/isolates/$id/$collection');

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
      var nullCollectionRequest =
          new NullCollectionTest(port, test._isolateId,
                                 'libraries').makeRequest();
      var requests = Future.wait([nullCollectionRequest]);
      requests.then((_) {
        process.requestExit();
      });
    });
  });
}
