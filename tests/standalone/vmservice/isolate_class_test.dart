// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_class_test;

import 'dart:async';
import 'test_helper.dart';
import 'package:expect/expect.dart';

class ClassTest extends VmServiceRequestHelper {
  ClassTest(port, id, classId) :
      super('http://127.0.0.1:$port/isolates/$id/classes/$classId');

  onRequestCompleted(Map reply) {
    Expect.equals('Class', reply['type']);
    Expect.equals('C', reply['name']);
    Expect.equals('isolate_stacktrace_command_script',
                  reply['library']['name']);
  }
}

class LibraryTest extends VmServiceRequestHelper {
  LibraryTest(port, id, libId) :
      super('http://127.0.0.1:$port/isolates/$id/libraries/$libId');

  int _classId;
  onRequestCompleted(Map reply) {
    Expect.equals('Library', reply['type']);
    Expect.equals('isolate_stacktrace_command_script', reply['name']);
    Expect.equals(1, reply['classes'].length);
    Expect.equals('@Class', reply['classes'][0]['type']);
    Expect.equals('C', reply['classes'][0]['name']);
    _classId = reply['classes'][0]['id'];
  }
}

class RootLibraryTest extends VmServiceRequestHelper {
  RootLibraryTest(port, id) :
      super('http://127.0.0.1:$port/isolates/$id/libraries');

  int _libId;
  onRequestCompleted(Map reply) {
    Expect.equals('@Library', reply['type']);
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
          var classTest = new ClassTest(port, test._isolateId,
                                        libraryTest._classId);
          classTest.makeRequest().then((_) {
            process.requestExit();
          });
        });
      });
    });
  });
}
