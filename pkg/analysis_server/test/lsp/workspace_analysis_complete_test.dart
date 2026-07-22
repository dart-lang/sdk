// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:matcher/matcher.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceAnalysisCompleteTest);
    defineReflectiveTests(WorkspaceAnalysisCompleteTest);
  });
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
      r'$/analyzerStatus notification',
      r'textDocument/publishDiagnostics notification',
      r'$/analyzerStatus notification',
      r'Response to dart/workspace/analysis/complete',
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
      r'$/analyzerStatus notification',
      r'textDocument/publishDiagnostics notification',
      r'$/analyzerStatus notification',
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
      r'$/analyzerStatus notification',
      r'$/analyzerStatus notification',
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
