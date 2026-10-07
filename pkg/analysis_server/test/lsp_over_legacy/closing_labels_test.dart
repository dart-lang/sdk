// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart' as legacy;
import 'package:analysis_server/protocol/protocol_generated.dart' as legacy;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosingLabelsTest);
  });
}

/// More complete tests for textDocument/inlayHint are in
/// 'test/lsp/closing_labels_test.dart'.
@reflectiveTest
class ClosingLabelsTest extends LspOverLegacyTest {
  final List<legacy.AnalysisClosingLabelsParams> legacyLabelsReceived = [];
  final List<PublishClosingLabelsParams> lspLabelsReceived = [];

  StreamSubscription<NotificationMessage>? _lspSubscription;

  @override
  Future<void> setUp() {
    // Collect legacy closing label notifications.
    notificationListener = (notification) {
      switch (notification.event) {
        case legacy.analysisNotificationClosingLabels:
          legacyLabelsReceived.add(
            legacy.AnalysisClosingLabelsParams.fromNotification(
              notification,
              clientUriConverter: server.uriConverter,
            ),
          );
      }
    };

    // Collect LSP closing label notifications.
    _lspSubscription = notificationsFromServer.listen((notification) {
      if (notification.method == CustomMethods.publishClosingLabels) {
        var diagnostics = PublishClosingLabelsParams.fromJson(
          notification.params as Map<String, Object?>,
        );
        lspLabelsReceived.add(diagnostics);
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

  /// If the client hasn't advertised closingLabels in the LSP
  /// ClientCapabilities we will continue to get legacy closing labels as
  /// always.
  test_legacy() async {
    var code = TestCode.parseNormalized('''
Widget build(BuildContext context) {
  return /*[0*/new Row(
    children: /*[1*/<Widget>[
      new Text('a'),
      new Text('b'),
    ]/*1]*/,
  )/*0]*/;
}
''');
    newFile(testFilePath, code.code);

    // Send the client capabilities without enabling LSP closing labels.
    await sendClientCapabilities();
    // And enable closing labels for the test file.
    await addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);

    await initializeServer();

    expect(legacyLabelsReceived, isNotEmpty);
    expect(lspLabelsReceived, isEmpty);

    var labels = legacyLabelsReceived.last.labels;
    expect(labels, hasLength(2));

    expect(labels[0].label, 'Row');
    expect(labels[0].offset, code.ranges[0].sourceRange.offset);
    expect(labels[0].length, code.ranges[0].sourceRange.length);

    expect(labels[1].label, '<Widget>[]');
    expect(labels[1].offset, code.ranges[1].sourceRange.offset);
    expect(labels[1].length, code.ranges[1].sourceRange.length);
  }

  /// If the client has advertised closingLabels in the LSP ClientCapabilities
  /// we will instead get LSP closing labels.
  ///
  /// Note: The client still controls which files closing labels are computed
  /// for using the legacy subscription. When using a native LSP server, this
  /// will be done automatically for all open files.
  test_lsp() async {
    var code = TestCode.parseNormalized('''
Widget build(BuildContext context) {
  return /*[0*/new Row(
    children: /*[1*/<Widget>[
      new Text('a'),
      new Text('b'),
    ]/*1]*/,
  )/*0]*/;
}
''');
    newFile(testFilePath, code.code);

    // Send the client capabilities without LSP closing labels.
    setClosingLabelsSupport();
    await sendClientCapabilities();
    // And configure which files closing labels are desired for.
    await addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);

    await initializeServer();

    expect(legacyLabelsReceived, isEmpty);
    expect(lspLabelsReceived, isNotEmpty);

    var labels = lspLabelsReceived.single.labels;
    expect(labels, hasLength(2));

    expect(labels[0].label, 'Row');
    expect(labels[0].range, code.ranges[0].range);

    expect(labels[1].label, '<Widget>[]');
    expect(labels[1].range, code.ranges[1].range);
  }
}
