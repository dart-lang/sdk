// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/server/crash_reporting.dart';
import 'package:analyzer/instrumentation/plugin_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CrashReportingInstrumentationTest);
  });
}

@reflectiveTest
class CrashReportingInstrumentationTest {
  late Completer<http.BaseRequest> requestCompleter;
  late CrashReportSender sender;
  late CrashReportingInstrumentation instrumentation;

  void setUp() {
    requestCompleter = Completer<http.BaseRequest>();
    var mockClient = MockClient((request) async {
      requestCompleter.complete(request);
      return http.Response('crash-report-001', 200);
    });
    sender = CrashReportSender.prod(
      'Dart_analysis_server',
      () => true,
      httpClient: mockClient,
    );
    instrumentation = CrashReportingInstrumentation(sender);
  }

  void tearDown() {
    sender.dispose();
  }

  Future<void> test_logException_sendsReport() async {
    instrumentation.logException(
      StateError('server crash'),
      StackTrace.current,
    );

    await requestCompleter.future;
    expect(sender.reportsSent, 1);
  }

  Future<void> test_logPluginException_doesNotSendReport() async {
    var plugin = PluginData('plugin_id', 'my_plugin', '1.0.0');
    instrumentation.logPluginException(
      plugin,
      StateError('plugin crash'),
      StackTrace.current,
    );

    await pumpEventQueue();
    expect(sender.reportsSent, 0);
    expect(requestCompleter.isCompleted, isFalse);
  }
}
