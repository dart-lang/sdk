// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_library_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class LibraryTest extends VmServiceRequestHelper {
  LibraryTest(port, id, libId) :
      super('http://127.0.0.1:$port/isolates/$id/objects/$libId');

  onRequestCompleted(Map reply) {
    Expect.equals('Library', reply['type']);
    Expect.equals('isolate_stacktrace_command_script', reply['name']);
  }
}

class RootLibraryTest extends VmServiceRequestHelper {
  RootLibraryTest(port, id) :
      super('http://127.0.0.1:$port/isolates/$id/library');

  int _libId;
  onRequestCompleted(Map reply) {
    Expect.equals('Library', reply['type']);
    Expect.equals('isolate_stacktrace_command_script', reply['name']);
    _libId = reply['id'];
  }
}

class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  int _isolateId;
  onRequestCompleted(Map reply) {
    IsolateListTester tester = new IsolateListTester(reply);
    tester.checkIsolateCount(2);
    tester.checkIsolateNameContains('isolate_stacktrace_command_script.dart');
    _isolateId = tester.checkIsolateNameContains('myIsolateName');
  }
}

main() {
  var process = new TestLauncher('isolate_stacktrace_command_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      var rootLibraryTest =
          new RootLibraryTest(port, test._isolateId);
      rootLibraryTest.makeRequest().then((_) {
        var libraryTest = new LibraryTest(port, test._isolateId,
                                          rootLibraryTest._libId);
        libraryTest.makeRequest().then((_) {
          process.requestExit();
        });
      });
    });
  });
}
