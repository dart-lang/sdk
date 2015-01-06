// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.instrumentation;

import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:unittest/unittest.dart';
import '../reflective_tests.dart';

main() {
  group('instrumentation', () {
    runReflectiveTests(InstrumentationServiceTest);
  });
}

@ReflectiveTestCase()
class InstrumentationServiceTest extends ReflectiveTestCase {
  void assertNormal(TestInstrumentationServer server, String tag, String message) {
    String sent = server.normalChannel.toString();
    if (!sent.endsWith(':$tag:$message\n')) {
      fail('Expected "...:$tag:$message", found "$sent"');
    }
  }

  void test_logError_withoutColon() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'Error message';
    service.logError(message);
    assertNormal(server, InstrumentationService.TAG_ERROR, message);
  }

  void test_logError_withColon() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    service.logError('Error:message');
    assertNormal(server, InstrumentationService.TAG_ERROR, 'Error::message');
  }

  void test_logException_noTrace() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'exceptionMessage';
    service.logException(message, null);
    assertNormal(server, InstrumentationService.TAG_EXCEPTION, '$message:null');
  }

  void test_logNotification() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'notificationText';
    service.logNotification(message);
    assertNormal(server, InstrumentationService.TAG_NOTIFICATION, message);
  }

  void test_logRequest() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'requestText';
    service.logRequest(message);
    assertNormal(server, InstrumentationService.TAG_REQUEST, message);
  }

  void test_logResponse() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'responseText';
    service.logResponse(message);
    assertNormal(server, InstrumentationService.TAG_RESPONSE, message);
  }
}

class TestInstrumentationServer implements InstrumentationServer {
  StringBuffer normalChannel = new StringBuffer();
  StringBuffer priorityChannel = new StringBuffer();

  @override
  void log(String message) {
    normalChannel.writeln(message);
  }

  @override
  void logWithPriority(String message) {
    priorityChannel.writeln(message);
  }

  @override
  void shutdown() {
    // Ignored
  }
}
