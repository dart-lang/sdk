// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.error;

import 'dart:async';

import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'integration_tests.dart';

/**
 * Verify that the server's input and output streams are asynchronous by
 * attempting to flood its input buffer with commands without listening to
 * its output buffer for responses.  The server should continue to train its
 * input buffer even though its output buffer is full.
 *
 * Once enough commands have been sent, we begin reading from the server's
 * output buffer, and verify that it responds to the last command.
 */
@ReflectiveTestCase()
class AsynchronyIntegrationTest {
  /**
   * Connection to the analysis server.
   */
  final Server server = new Server();

  /**
   * Number of messages to queue up before listening for responses.
   */
  static const MESSAGE_COUNT = 10000;

  Future setUp() {
    return server.start();
  }

  test_asynchrony() {
    // Send MESSAGE_COUNT messages to the server without listening for
    // responses.
    Future lastMessageResult;
    for (int i = 0; i < MESSAGE_COUNT; i++) {
      lastMessageResult = server.send('server.getVersion', null);
    }

    // Flush the server's standard input stream to verify that it has really
    // received them all.  If the server is blocked waiting for us to read
    // its responses, the flush will never complete.
    return server.flushCommands().then((_) {

      // Begin processing responses from the server.
      server.listenToOutput((String event, params) {
        // The only expected notification is server.connected.
        if (event != 'server.connected') {
          fail('Unexpected notification: $event');
        }
      });

      // Terminate the test when the response to the last message is received.
      return lastMessageResult.then((_) {
        server.send("server.shutdown", null).then((_) {
          return server.exitCode;
        });
      });
    });
  }
}

main() {
  runReflectiveTests(AsynchronyIntegrationTest);
}
