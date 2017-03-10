// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.instrumentation.instrumentation_test;

import 'dart:async';

import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveTests(InstrumentationServiceTest);
  defineReflectiveTests(MulticastInstrumentationServerTest);
}

@reflectiveTest
class InstrumentationServiceTest {
  void assertNormal(
      TestInstrumentationServer server, String tag, String message) {
    String sent = server.normalChannel.toString();
    if (!sent.endsWith(':$tag:$message\n')) {
      fail('Expected "...:$tag:$message", found "$sent"');
    }
  }

  void test_logError_withColon() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    service.logError('Error:message');
    assertNormal(server, InstrumentationService.TAG_ERROR, 'Error::message');
  }

  void test_logError_withLeadingColon() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    service.logError(':a:bb');
    assertNormal(server, InstrumentationService.TAG_ERROR, '::a::bb');
  }

  void test_logError_withoutColon() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'Error message';
    service.logError(message);
    assertNormal(server, InstrumentationService.TAG_ERROR, message);
  }

  void test_logException_noTrace() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String message = 'exceptionMessage';
    service.logException(message, null);
    assertNormal(server, InstrumentationService.TAG_EXCEPTION, '$message:null');
  }

  void test_logFileRead() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String path = '/file/path';
    int time = 978336000000;
    String content = 'class C {\n}\n';
    service.logFileRead(path, time, content);
    assertNormal(
        server, InstrumentationService.TAG_FILE_READ, '$path:$time:$content');
  }

  void test_logLogEntry() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    String level = 'level';
    DateTime time = new DateTime(2001);
    String message = 'message';
    String exception = 'exception';
    String stackTraceText = 'stackTrace';
    StackTrace stackTrace = new StackTrace.fromString(stackTraceText);
    service.logLogEntry(level, time, message, exception, stackTrace);
    assertNormal(server, InstrumentationService.TAG_LOG_ENTRY,
        '$level:${time.millisecondsSinceEpoch}:$message:$exception:$stackTraceText');
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

  void test_logVersion() {
    TestInstrumentationServer server = new TestInstrumentationServer();
    InstrumentationService service = new InstrumentationService(server);
    service.logVersion('myUuid', 'someClientId', 'someClientVersion',
        'aServerVersion', 'anSdkVersion');
    expect(server.normalChannel.toString(), '');
    expect(
        server.priorityChannel.toString(),
        endsWith(
            ':myUuid:someClientId:someClientVersion:aServerVersion:anSdkVersion\n'));
  }
}

@reflectiveTest
class MulticastInstrumentationServerTest {
  TestInstrumentationServer serverA = new TestInstrumentationServer();
  TestInstrumentationServer serverB = new TestInstrumentationServer();
  MulticastInstrumentationServer server;

  void setUp() {
    server = new MulticastInstrumentationServer([serverA, serverB]);
  }

  void test_log() {
    server.log('foo bar');
    _assertNormal(serverA, 'foo bar');
    _assertNormal(serverB, 'foo bar');
  }

  void test_logWithPriority() {
    server.logWithPriority('foo bar');
    _assertPriority(serverA, 'foo bar');
    _assertPriority(serverB, 'foo bar');
  }

  void test_shutdown() {
    server.shutdown();
  }

  void _assertNormal(TestInstrumentationServer server, String message) {
    String sent = server.normalChannel.toString();
    if (!sent.endsWith('$message\n')) {
      fail('Expected "...$message", found "$sent"');
    }
  }

  void _assertPriority(TestInstrumentationServer server, String message) {
    String sent = server.priorityChannel.toString();
    if (!sent.endsWith('$message\n')) {
      fail('Expected "...$message", found "$sent"');
    }
  }
}

class TestInstrumentationServer implements InstrumentationServer {
  StringBuffer normalChannel = new StringBuffer();
  StringBuffer priorityChannel = new StringBuffer();

  @override
  String get sessionId => '';

  @override
  String get describe => 'test instrumentation';

  @override
  void log(String message) {
    normalChannel.writeln(message);
  }

  @override
  void logWithPriority(String message) {
    priorityChannel.writeln(message);
  }

  @override
  Future shutdown() async {
    // Ignored
  }
}
