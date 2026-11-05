// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:matcher/matcher.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceAnalysisCompleteTest);
    defineReflectiveTests(SlowWorkspaceAnalysisCompleteTest);
  });
}

/// Extends WorkspaceAnalysisCompleteTest to run the tests with a small watcher
/// delay to more closely match timing of the disk-backed resource provider.
///
/// This delay allowed the test
/// [test_changeWorkspaceFolders_validRoots_changedImmediately] to reproduce
/// https://github.com/dart-lang/sdk/issues/63868.
@reflectiveTest
class SlowWorkspaceAnalysisCompleteTest extends WorkspaceAnalysisCompleteTest {
  @override
  MemoryResourceProvider resourceProvider = MemoryResourceProvider(
    delayWatcherInitialization: Duration(milliseconds: 1),
  );
}

/// Test that dart/workspace/analysis/complete correctly waits for analysis to
/// complete.
///
/// Tests that this also waits for plugins are in the integration tests:
/// - `test_plugins` in `integration_test\lsp_server\diagnostic_test.dart`
/// - `test_plugin_*` in `integration_test\lsp_server\workspace_analysis_complete_test.dart`
@reflectiveTest
class WorkspaceAnalysisCompleteTest extends AbstractLspAnalysisServerTest {
  /// A map from request IDs to their Methods, to provide more useful text in
  /// the logging ("Response to dart/workspace/analysis/complete").
  final Map<Either2<int, String>, Method> _requestMethodsById = {};

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) {
    _requestMethodsById[request.id] = request.method;
    return super.sendRequestToServer(request);
  }

  @override
  void setUp() {
    super.setUp();

    // Enable progress notifications because we want to check the analysis
    // occurs prior to this request completing.
    setWorkDoneProgressSupport();
  }

  Future<void> test_advertisedCapability() async {
    await initialize();

    expect(
      serverCapabilities.experimental,
      containsPair('workspaceAnalysisComplete', isNotNull),
    );
  }

  Future<void> test_changeWorkspaceFolders_invalidRoots() async {
    failTestOnErrorDiagnostic = false;

    newFile(mainFilePath, 'InvalidCode');

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(allowEmptyRootUri: true);

      await workspaceAnalysisComplete();

      // Send these together, so we can ensure workspaceAnalysisComplete
      // blocks and doesn't get in before the analysis occurs.
      await Future.wait([
        changeWorkspaceFolders(add: [Uri.file('invalid')]),
        workspaceAnalysisComplete(),
      ]);
    });

    expect(messages, [
      // Initial empty workspace.
      r'Response to initialize',
      r'Response to dart/workspace/analysis/complete',
      // When adding a new workspace folder that does not trigger any analysis.
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_changeWorkspaceFolders_validRoots() async {
    failTestOnErrorDiagnostic = false;

    newFile(mainFilePath, 'InvalidCode');

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(allowEmptyRootUri: true);

      await workspaceAnalysisComplete();

      // Send these together, so we can ensure workspaceAnalysisComplete
      // blocks and doesn't get in before the analysis occurs.
      await Future.wait([
        changeWorkspaceFolders(add: [projectFolderUri]),
        workspaceAnalysisComplete(),
      ]);
    });

    expect(messages, [
      // Initial empty workspace.
      r'Response to initialize',
      r'Response to dart/workspace/analysis/complete',
      // When adding a new workspace folder that triggers analysis.
      'window/workDoneProgress/create request',
      r'$/progress notification',
      r'textDocument/publishDiagnostics notification',
      r'$/progress notification',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  /// Verifies that if we change workspace folders _immediately_ after sending
  /// the `initialized` notfication and then immediately wait for analysis, we
  /// do not return prematurely due to a race that would see the first workspace
  /// folder update actually apply the second one and the second one bail out
  /// early (meaning it completed before the first).
  Future<void>
  test_changeWorkspaceFolders_validRoots_changedImmediately() async {
    failTestOnErrorDiagnostic = false;

    newFile(mainFilePath, 'InvalidCode');

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(
        // Start with an empty folder.
        allowEmptyRootUri: true,
        // After the initialized notification is sent, immediately send these
        // two requests without any delays or awaits.
        immediatelyAfterInitialized: () async {
          await Future.wait([
            changeWorkspaceFolders(add: [projectFolderUri]),
            workspaceAnalysisComplete(),
          ]);
        },
      );
    });

    expect(messages, [
      'Response to initialize',
      'window/workDoneProgress/create request',
      r'$/progress notification',
      'textDocument/publishDiagnostics notification',
      r'$/progress notification',
      // This should definitely be last, after the diagnostics. Before the bug
      // was fixed, it would appear before analysis/diagnostics.
      'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_initialAnalysis_invalidRoots_file() async {
    failTestOnErrorDiagnostic = false;

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(rootUri: Uri.file('invalid'));

      await workspaceAnalysisComplete();
    });

    // No analysis happens here, because there are no workspace roots.
    expect(messages, [
      r'Response to initialize',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_initialAnalysis_invalidRoots_missing() async {
    failTestOnErrorDiagnostic = false;

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(allowEmptyRootUri: true);

      await workspaceAnalysisComplete();
    });

    // No analysis happens here, because there are no workspace roots.
    expect(messages, [
      r'Response to initialize',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_initialAnalysis_invalidRoots_nonFile() async {
    failTestOnErrorDiagnostic = false;

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(rootUri: Uri.parse('foo://bar'));

      await workspaceAnalysisComplete();
    });

    // No analysis happens here, because there are no workspace roots.
    expect(messages, [
      r'Response to initialize',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_initialAnalysis_validRoots() async {
    failTestOnErrorDiagnostic = false;

    newFile(mainFilePath, 'InvalidCode');

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize();

      await workspaceAnalysisComplete();
    });

    expect(messages, [
      r'Response to initialize',
      'window/workDoneProgress/create request',
      r'$/progress notification',
      r'textDocument/publishDiagnostics notification',
      r'$/progress notification',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  Future<void> test_initialAnalysis_validRoots_emptyRoots() async {
    var emptyFolderPath = convertPath('/home/empty');
    newFolder(emptyFolderPath);

    var messages = await _captureMessages(() async {
      // Initialize must complete before we send anything else.
      await initialize(rootUri: Uri.file(emptyFolderPath));

      await workspaceAnalysisComplete();
    });

    expect(messages, [
      // Initial empty workspace.
      r'Response to initialize',
      // Analysis of empty workspace.
      'window/workDoneProgress/create request',
      r'$/progress notification',
      r'$/progress notification',
      r'Response to dart/workspace/analysis/complete',
    ]);
  }

  /// Invoke [func], capturing a description of each message from the server.
  Future<List<String>> _captureMessages(Future<void> Function() func) async {
    var messages = <String>[];
    var incomingSub = serverToClient.listen((message) {
      var desc = switch (message) {
        ResponseMessage() => 'Response to ${_requestMethodsById[message.id]}',
        NotificationMessage() => '${message.method} notification',
        RequestMessage() => '${message.method} request',
      };
      messages.add(desc);
    });

    await func();

    await incomingSub.cancel();

    return messages;
  }
}
