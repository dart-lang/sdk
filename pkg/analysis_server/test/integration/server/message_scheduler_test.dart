// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analysis_server/src/server/message_scheduler.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import '../../lsp/code_actions_refactor_test.dart';
import '../../utils/test_code_extensions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspServerMessageSchedulerTest);
    defineReflectiveTests(LegacyServerMessageSchedulerTest);
  });
}

void _assertLogContents(MessageScheduler messageScheduler, String expected) {
  var actual = _getLogContents(messageScheduler.testView!.messageLog);
  if (actual != expected) {
    print('-------- Actual --------');
    print('$actual------------------------');
  }
  expect(actual, expected);
}

String _getLogContents(List<String> log) {
  var buffer = StringBuffer();
  for (var event in log) {
    buffer.writeln(event);
  }
  return buffer.toString();
}

@reflectiveTest
class LegacyServerMessageSchedulerTest extends PubPackageAnalysisServerTest {
  late MessageScheduler messageScheduler;

  @override
  bool get retainDataForTesting => true;

  @override
  Future<void> setUp() async {
    super.setUp();
    messageScheduler = server.messageScheduler;
  }

  Future<void> test_initialize() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    _assertLogContents(messageScheduler, r'''
Incoming LegacyMessage: analysis.setAnalysisRoots
Entering process messages loop
  Start LegacyMessage: analysis.setAnalysisRoots
  Complete LegacyMessage: analysis.setAnalysisRoots
Exit process messages loop
''');
  }

  Future<void> test_multipleRequests() async {
    var futures = <Future<void>>[];
    futures.add(setRoots(included: [workspaceRootPath], excluded: []));
    var request = ExecutionCreateContextParams(
      '/a/b.dart',
    ).toRequest('0', clientUriConverter: server.uriConverter);
    futures.add(handleSuccessfulRequest(request));
    await Future.wait(futures);
    _assertLogContents(messageScheduler, r'''
Incoming LegacyMessage: analysis.setAnalysisRoots
Entering process messages loop
  Start LegacyMessage: analysis.setAnalysisRoots
Incoming LegacyMessage: execution.createContext
  Complete LegacyMessage: analysis.setAnalysisRoots
  Start LegacyMessage: execution.createContext
  Complete LegacyMessage: execution.createContext
Exit process messages loop
''');
  }
}

@reflectiveTest
class LspServerMessageSchedulerTest extends RefactorCodeActionsTest {
  late MessageScheduler messageScheduler;

  final extractMethodTitle = 'Extract Method';

  @override
  bool get retainDataForTesting => true;

  @override
  void setUp() {
    super.setUp();
    messageScheduler = server.messageScheduler;
  }

  Future<void> test_documentChange() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    newFile(mainFilePath, content);
    // await initialize();
    // var code = TestCode.parse(content);
    // await openFile(mainFileUri, code.code);
    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
      openTargetFile: true,
    );
    // Use a Completer to control when the refactor handler starts computing.
    var completer = Completer<void>();
    PerformRefactorCommandHandler.delayAfterResolveForTests = completer.future;
    try {
      // Send an edit request immediately after the refactor request.
      var futures = <Future<void>>[];
      var request = makeRequest(
        Method.workspace_executeCommand,
        ExecuteCommandParams(
          command: codeAction.command!.command,
          arguments: codeAction.command!.arguments,
        ),
      );
      futures.add(sendRequestToServer(request));
      futures.add(replaceFile(100, mainFileUri, 'new test content'));
      completer.complete();
      await Future.wait(futures);
    } finally {
      // Ensure we never leave an incomplete future if anything above throws.
      PerformRefactorCommandHandler.delayAfterResolveForTests = null;
    }

    _assertLogContents(messageScheduler, r'''
Incoming RequestMessage: initialize
Entering process messages loop
  Start LspMessage: initialize
  Complete LspMessage: initialize
Exit process messages loop
Incoming NotificationMessage: initialized
Entering process messages loop
  Start LspMessage: initialized
  Complete LspMessage: initialized
Exit process messages loop
Incoming NotificationMessage: textDocument/didOpen
Entering process messages loop
  Start LspMessage: textDocument/didOpen
  Complete LspMessage: textDocument/didOpen
Exit process messages loop
Incoming RequestMessage: textDocument/codeAction
Entering process messages loop
  Start LspMessage: textDocument/codeAction
  Complete LspMessage: textDocument/codeAction
Exit process messages loop
Incoming RequestMessage: workspace/executeCommand
Entering process messages loop
  Start LspMessage: workspace/executeCommand
Incoming NotificationMessage: textDocument/didChange
Canceled in progress request workspace/executeCommand
  Complete LspMessage: workspace/executeCommand
  Start LspMessage: textDocument/didChange
  Complete LspMessage: textDocument/didChange
Exit process messages loop
''');
  }

  Future<void> test_duplicateRequests() async {
    const content = '''
class B {
  @^
}
''';

    newFile(mainFilePath, content);
    await initialize();
    var code = TestCode.parse(content);
    await openFile(mainFileUri, code.code);
    var request = makeRequest(
      Method.textDocument_completion,
      CompletionParams(
        textDocument: TextDocumentIdentifier(uri: mainFileUri),
        position: code.position.position,
      ),
    );
    var futures = <Future<void>>[];
    futures.add(sendRequestToServer(request));
    futures.add(sendRequestToServer(request));
    futures.add(sendRequestToServer(request));
    await Future.wait(futures);
    await pumpEventQueue(times: 5000);

    _assertLogContents(messageScheduler, r'''
Incoming RequestMessage: initialize
Entering process messages loop
  Start LspMessage: initialize
  Complete LspMessage: initialize
Exit process messages loop
Incoming NotificationMessage: initialized
Entering process messages loop
  Start LspMessage: initialized
  Complete LspMessage: initialized
Exit process messages loop
Incoming NotificationMessage: textDocument/didOpen
Entering process messages loop
  Start LspMessage: textDocument/didOpen
  Complete LspMessage: textDocument/didOpen
Exit process messages loop
Incoming RequestMessage: textDocument/completion
Entering process messages loop
  Start LspMessage: textDocument/completion
Incoming RequestMessage: textDocument/completion
Canceled in progress request textDocument/completion
Incoming RequestMessage: textDocument/completion
Canceled in progress request textDocument/completion
Canceled request on queue textDocument/completion
  Complete LspMessage: textDocument/completion
  Start LspMessage: textDocument/completion
  Complete LspMessage: textDocument/completion
  Start LspMessage: textDocument/completion
  Complete LspMessage: textDocument/completion
Exit process messages loop
''');
  }

  Future<void> test_initialize() async {
    await initialize();
    await initialAnalysis;
    await pumpEventQueue(times: 5000);
    _assertLogContents(messageScheduler, r'''
Incoming RequestMessage: initialize
Entering process messages loop
  Start LspMessage: initialize
  Complete LspMessage: initialize
Exit process messages loop
Incoming NotificationMessage: initialized
Entering process messages loop
  Start LspMessage: initialized
  Complete LspMessage: initialized
Exit process messages loop
''');
  }

  Future<void> test_multipleRequests() async {
    const content = '''
void main() {
  print('Hello world!!');
}
''';
    newFile(mainFilePath, content);
    await initialize();
    var futures = <Future<void>>[];
    futures.add(getDocumentSymbols(mainFileUri));
    futures.add(getDocumentLinks(mainFileUri));
    await Future.wait(futures);
    await pumpEventQueue(times: 5000);

    _assertLogContents(messageScheduler, r'''
Incoming RequestMessage: initialize
Entering process messages loop
  Start LspMessage: initialize
  Complete LspMessage: initialize
Exit process messages loop
Incoming NotificationMessage: initialized
Entering process messages loop
  Start LspMessage: initialized
  Complete LspMessage: initialized
Exit process messages loop
Incoming RequestMessage: textDocument/documentSymbol
Entering process messages loop
  Start LspMessage: textDocument/documentSymbol
Incoming RequestMessage: textDocument/documentLink
  Complete LspMessage: textDocument/documentSymbol
  Start LspMessage: textDocument/documentLink
  Complete LspMessage: textDocument/documentLink
Exit process messages loop
''');
  }

  Future<void> test_response() async {
    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    var codeAction = await expectAction(
      content,
      command: Commands.performRefactor,
      title: extractMethodTitle,
    );

    // Respond to any applyEdit requests from the server with successful responses
    // and capturing the last edit.
    requestsFromServer.listen((request) {
      if (request.method == Method.workspace_applyEdit) {
        ApplyWorkspaceEditParams.fromJson(
          request.params as Map<String, Object?>,
        );
        respondTo(request, ApplyWorkspaceEditResult(applied: true));
      }
    });
    await executeCommand(codeAction.command!);
    await pumpEventQueue(times: 5000);

    _assertLogContents(messageScheduler, r'''
Incoming RequestMessage: initialize
Entering process messages loop
  Start LspMessage: initialize
  Complete LspMessage: initialize
Exit process messages loop
Incoming NotificationMessage: initialized
Entering process messages loop
  Start LspMessage: initialized
  Complete LspMessage: initialized
Exit process messages loop
Incoming RequestMessage: textDocument/codeAction
Entering process messages loop
  Start LspMessage: textDocument/codeAction
  Complete LspMessage: textDocument/codeAction
Exit process messages loop
Incoming RequestMessage: workspace/executeCommand
Entering process messages loop
  Start LspMessage: workspace/executeCommand
Incoming ResponseMessage: ResponseMessage
  Complete LspMessage: workspace/executeCommand
Exit process messages loop
''');
  }
}
