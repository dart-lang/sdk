// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unknown_command_test;

import 'test_helper.dart';
import 'package:expect/expect.dart';

class ClientsRequestTest extends ServiceWebSocketRequestHelper {
  ClientsRequestTest(port) : super('ws://127.0.0.1:$port/ws');
  int _count = 0;

  onResponse(var seq, Map response) {
    if (seq == null) {
      // Ignore push events.
      return;
    }
    if (seq == 'cli') {
      // Verify response is correct for 'cli' sequence id.
      Expect.equals('ClientList', response['type']);
      Expect.equals(1, response['members'].length);
      _count++;
    } else if (seq == 'vm') {
      // Verify response is correct for 'vm' sequence id.
      Expect.equals('VM', response['type']);
      _count++;
    } else {
      Expect.fail('Unexpected response from $seq: $response');
    }
    if (_count == 2) {
      // After receiving both responses, the test is complete.
      complete();
    }
  }

  runTest() {
    // Send a request for clients with 'cli' sequence id.
    sendMessage('cli', 'clients');
    // Send a request for vm info with 'vm' sequence id.
    sendMessage('vm', 'vm');
  }
}

main() {
  var process = new TestLauncher('unknown_command_script.dart');
  process.launch().then((port) {
    new ClientsRequestTest(port).connect().then((test) {
      test.completed.then((_) {
        process.requestExit();
      });
      test.runTest();
    });
  });
}
