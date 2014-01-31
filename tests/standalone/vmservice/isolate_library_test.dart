// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_library_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class LibraryTest extends VmServiceRequestHelper {
  LibraryTest(port, id, libId) :
      super('http://127.0.0.1:$port/$id/$libId');

  onRequestCompleted(Map reply) {
    Expect.equals('Library', reply['type']);
    Expect.equals('isolate_stacktrace_command_script', reply['name']);
  }
}

class IsolateSummaryTest extends VmServiceRequestHelper {
  IsolateSummaryTest(port, id) :
      super('http://127.0.0.1:$port/$id/');

  String _libId;
  onRequestCompleted(Map reply) {
    Expect.equals('Isolate', reply['type']);
    Expect.equals('isolate_stacktrace_command_script', reply['rootLib']['name']);
    _libId = reply['rootLib']['id'];
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
      var isolateSummaryTest =
          new IsolateSummaryTest(port, test._isolateId);
      isolateSummaryTest.makeRequest().then((_) {
        var libraryTest = new LibraryTest(port, test._isolateId,
                                          isolateSummaryTest._libId);
        libraryTest.makeRequest().then((_) {
          process.requestExit();
        });
      });
    });
  });
}
