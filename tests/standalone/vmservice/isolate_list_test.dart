// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
//
// Test:
//   *) Connect to VM Service and obtain list of running isolates.

library isolate_list_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';


class IsolateListTest extends VmServiceRequestHelper {
  IsolateListTest(port) : super('http://127.0.0.1:$port/isolates');

  onRequestCompleted(Map reply) {
    // The reply is an IsolateList.
    Expect.equals('IsolateList', reply['type']);
    // There is 1 running isolate.
    Expect.equals(1, reply['members'].length);
    // It's id is 7116.
    Expect.equals(7116, reply['members'][0]['id']);
    // It's this isolate.
    Expect.isTrue(
        reply['members'][0]['name'].startsWith('isolate_list_script.dart'));
  }
}


main() {
  var process = new TestLauncher('isolate_list_script.dart');
  process.launch().then((port) {
    var test = new IsolateListTest(port);
    test.makeRequest().then((_) {
      process.requestExit();
    });
  });
}
