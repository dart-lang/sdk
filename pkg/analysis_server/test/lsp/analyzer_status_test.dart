// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisStandardProgressTest);
    defineReflectiveTests(AnalyzerCustomStatusTest);
  });
}

/// Tests analysis status notifications using LSP-standard $/progress
/// notifications.
@reflectiveTest
class AnalysisStandardProgressTest extends AnalyzerStatusTest {
  @override
  bool get progressSupport => true;
}

/// Tests analysis status notifications using (legacy) custom notifications.
@reflectiveTest
class AnalyzerCustomStatusTest extends AnalyzerStatusTest {
  @override
  bool get progressSupport => false;
}

abstract class AnalyzerStatusTest extends AbstractLspAnalysisServerTest {
  bool get progressSupport;

  ClientCapabilitiesWindow get _windowCapabilities => progressSupport
      ? withWorkDoneProgressSupport(emptyWindowClientCapabilities)
      : emptyWindowClientCapabilities;

  Future<void> test_afterDocumentEdits() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    final initialAnalysis = waitForAnalysisComplete();

    await initialize(windowCapabilities: _windowCapabilities);
    await initialAnalysis;

    // Set up futures to wait for the new events.
    final startNotification = waitForAnalysisStart();
    final completeNotification = waitForAnalysisComplete();

    // Send a modification
    await openFile(mainFileUri, initialContents);
    await replaceFile(222, mainFileUri, 'String a = 1;');

    // Ensure the notifications come through again.
    await startNotification;
    await completeNotification;
  }

  Future<void> test_afterInitialize() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    // To avoid races, set up listeners for the notifications before we initialise
    // and track which event came first to ensure they arrived in the expected
    // order.
    bool firstNotificationWasAnalyzing;
    final startNotification = waitForAnalysisStart()
        .then((_) => firstNotificationWasAnalyzing ??= true);
    final completeNotification = waitForAnalysisComplete()
        .then((_) => firstNotificationWasAnalyzing ??= false);

    await initialize();
    await startNotification;
    await completeNotification;

    expect(firstNotificationWasAnalyzing, isTrue);
  }
}
