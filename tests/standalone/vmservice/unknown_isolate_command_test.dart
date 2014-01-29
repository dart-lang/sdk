// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_class_table_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class ClassTableTest extends VmServiceRequestHelper {
  ClassTableTest(port, id) :
      super('http://127.0.0.1:$port/$id/classes');

  onRequestCompleted(Map reply) {
    ClassTableHelper helper = new ClassTableHelper(reply);
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
  var process = new TestLauncher('field_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var classTableTest = new ClassTableTest(port, test._isolateId);
      classTableTest.makeRequest().then((_) {
        process.requestExit();
      });
    });
  });
}
