// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart' as legacy;
import 'package:analysis_server/protocol/protocol_generated.dart' as legacy;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/lsp_protocol_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticsTest);
  });
}

@reflectiveTest
class DiagnosticsTest extends LspOverLegacyTest {
  final List<legacy.AnalysisErrorsParams> legacyDiagnosticsReceived = [];
  final List<PublishDiagnosticsParams> lspDiagnosticsReceived = [];

  StreamSubscription<NotificationMessage>? _lspSubscription;

  @override
  Future<void> setUp() {
    // Collect legacy diagnostic notifications.
    notificationListener = (notification) {
      switch (notification.event) {
        case legacy.analysisNotificationErrors:
          legacyDiagnosticsReceived.add(
            legacy.AnalysisErrorsParams.fromNotification(
              notification,
              clientUriConverter: server.uriConverter,
            ),
          );
      }
    };

    // Collect LSP diagnostic notifications.
    _lspSubscription = notificationsFromServer.listen((notification) {
      if (notification.method == Method.textDocument_publishDiagnostics) {
        var diagnostics = PublishDiagnosticsParams.fromJson(
          notification.params as Map<String, Object?>,
        );
        lspDiagnosticsReceived.add(diagnostics);
      }
    });
    return super.setUp();
  }

  @override
  Future<void> tearDown() async {
    notificationListener = null;
    await _lspSubscription?.cancel();
    return super.tearDown();
  }

  /// LSP diagnostics are not supported by the client, so legacy diagnostics
  /// are sent.
  Future<void> test_notSupported() async {
    newFile(
      testFilePath,
      '1',
    ); // Expected a method, getter, setter or operator declaration.

    await initializeServer();

    expect(legacyDiagnosticsReceived, isNotEmpty);
    expect(lspDiagnosticsReceived, isEmpty);

    var params = legacyDiagnosticsReceived.singleWhere(
      (notification) => notification.file == testFilePath,
    );
    var error = params.errors.single;
    expect(
      error.message,
      'Expected a method, getter, setter or operator declaration.',
    );
  }

  /// LSP diagnostics are are supported by the client.
  Future<void> test_supported() async {
    setPublishDiagnosticsSupport();
    setDiagnosticCodeDescriptionSupport();
    await sendClientCapabilities();

    newFile(testFilePath, 'int a, a;');
    await initializeServer();

    expect(legacyDiagnosticsReceived, isEmpty);
    expect(lspDiagnosticsReceived, isNotEmpty);

    var params = lspDiagnosticsReceived.singleWhere(
      (notification) => notification.uri == testFileUri,
    );
    var error = params.diagnostics.singleWhere(
      (diagnostic) => diagnostic.code == 'duplicate_definition',
    );

    expect(error.code, 'duplicate_definition');
    expect(
      error.message.asString,
      "The name 'a' is already defined.\n"
      'Try renaming one of the declarations.',
    );
    expect(
      error.codeDescription?.href.toString(),
      'https://dart.dev/diagnostics/duplicate_definition',
    );
    expect(error.relatedInformation, hasLength(1));
    expect(
      error.relatedInformation![0].message,
      'The first definition of this name.',
    );
    expect(error.range, isNotNull);
    expect(error.severity, DiagnosticSeverity.Error);
  }
}
