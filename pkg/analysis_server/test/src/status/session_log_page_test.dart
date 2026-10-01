// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/session_logger_sink.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/session_log_page.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SessionLogPageTest);
  });
}

@reflectiveTest
class SessionLogPageTest extends PubPackageAnalysisServerTest {
  late DiagnosticsSite site;
  late SessionLogPage page;

  @override
  void setUp() {
    super.setUp();
    site = DiagnosticsSite(TestSocketServer(server), []);
    page = SessionLogPage(site);
  }

  Future<void> test_generate_buttonsAndDisclaimer() async {
    var html = await page.generate({});
    expect(html, contains('Copy log to clipboard'));
    expect(html, contains('Download log'));
    expect(html, contains('downloadSessionLog()'));
    expect(html, contains('Copy sanitized log to clipboard'));
    expect(html, contains('Download sanitized log'));
    expect(html, contains('downloadSanitizedSessionLog()'));
    expect(
      html,
      contains(
        'Logs are sanitized using an automated tool which may unintentionally '
        'leave',
      ),
    );
    expect(
      html,
      contains(
        'Be sure to review the sanitized log for sensitive information before '
        'sharing.',
      ),
    );
  }

  Future<void> test_handlePost_toggleCapture() async {
    var sink = server.sessionLogger.sink as SessionLoggerInMemorySink;
    expect(sink.isCapturingEntries, isFalse);

    await page.handlePost({'capture-entries': 'true'});
    expect(sink.isCapturingEntries, isTrue);

    await page.handlePost({'capture-entries': 'false'});
    expect(sink.isCapturingEntries, isFalse);
  }
}
