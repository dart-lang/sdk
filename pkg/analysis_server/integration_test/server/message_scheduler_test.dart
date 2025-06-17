// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/perform_refactor.dart';
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../test/analysis_server_base.dart';
import '../../test/lsp/code_actions_refactor_test.dart';
import '../../test/utils/message_scheduler_test_view.dart';
import '../../test/utils/test_code_extensions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspServerMessageSchedulerTest);
    defineReflectiveTests(LegacyServerMessageSchedulerTest);
  });
}

void _assertLogContents(MessageSchedulerTestView testView, String expected) {
  var actual = _getLogContents(testView.messageLog);
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
    await waitForTasksFinished();
    _assertLogContents(testView!, r'''
Incoming LegacyMessage: legacy:analysis.setAnalysisRoots
Entering process messages loop
  Start LegacyMessage: legacy:analysis.setAnalysisRoots
  Complete LegacyMessage: legacy:analysis.setAnalysisRoots
Exit process messages loop
''');
  }

  Future<void> test_multipleRequests() async {
    if (MessageScheduler.allowOverlappingHandlers) return;

    var futures = <Future<void>>[];
    futures.add(setRoots(included: [workspaceRootPath], excluded: []));
    var request = ExecutionCreateContextParams(
      '/a/b.dart',
    ).toRequest('0', clientUriConverter: server.uriConverter);
    futures.add(handleSuccessfulRequest(request));
    await Future.wait(futures);
    await waitForTasksFinished();
    _assertLogContents(testView!, r'''
Incoming LegacyMessage: legacy:analysis.setAnalysisRoots
Entering process messages loop
  Start LegacyMessage: legacy:analysis.setAnalysisRoots
Incoming LegacyMessage: legacy:execution.createContext
  Complete LegacyMessage: legacy:analysis.setAnalysisRoots
  Start LegacyMessage: legacy:execution.createContext
  Complete LegacyMessage: legacy:execution.createContext
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
    if (MessageScheduler.allowOverlappingHandlers) return;

    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    newFile(mainFilePath, content);
    var codeAction = await expectCodeActionLiteral(
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

    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
Incoming NotificationMessage: lsp:textDocument/didOpen
Entering process messages loop
  Start LspMessage: lsp:textDocument/didOpen
  Complete LspMessage: lsp:textDocument/didOpen
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/codeAction
Entering process messages loop
  Start LspMessage: lsp:textDocument/codeAction
  Complete LspMessage: lsp:textDocument/codeAction
Exit process messages loop
Incoming RequestMessage: lsp:workspace/executeCommand
Entering process messages loop
  Start LspMessage: lsp:workspace/executeCommand
Incoming NotificationMessage: lsp:textDocument/didChange
Canceled in progress request lsp:workspace/executeCommand
  Complete LspMessage: lsp:workspace/executeCommand
  Start LspMessage: lsp:textDocument/didChange
  Complete LspMessage: lsp:textDocument/didChange
Exit process messages loop
''');
  }

  Future<void> test_duplicateRequests() async {
    if (MessageScheduler.allowOverlappingHandlers) return;

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

    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
Incoming NotificationMessage: lsp:textDocument/didOpen
Entering process messages loop
  Start LspMessage: lsp:textDocument/didOpen
  Complete LspMessage: lsp:textDocument/didOpen
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/completion
Entering process messages loop
  Start LspMessage: lsp:textDocument/completion
Incoming RequestMessage: lsp:textDocument/completion
Canceled in progress request lsp:textDocument/completion
Incoming RequestMessage: lsp:textDocument/completion
Canceled in progress request lsp:textDocument/completion
Canceled request on queue lsp:textDocument/completion
  Complete LspMessage: lsp:textDocument/completion
  Start LspMessage: lsp:textDocument/completion
  Complete LspMessage: lsp:textDocument/completion
  Start LspMessage: lsp:textDocument/completion
  Complete LspMessage: lsp:textDocument/completion
Exit process messages loop
''');
  }

  Future<void> test_initialize() async {
    await initialize();
    await initialAnalysis;
    await pumpEventQueue(times: 5000);
    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
''');
  }

  Future<void> test_multipleRequests() async {
    if (MessageScheduler.allowOverlappingHandlers) return;

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

    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/documentSymbol
Entering process messages loop
  Start LspMessage: lsp:textDocument/documentSymbol
Incoming RequestMessage: lsp:textDocument/documentLink
  Complete LspMessage: lsp:textDocument/documentSymbol
  Start LspMessage: lsp:textDocument/documentLink
  Complete LspMessage: lsp:textDocument/documentLink
Exit process messages loop
''');
  }

  Future<void> test_pauseResume() async {
    // Content isn't important, we just need a valid file to send requests for.
    const content = '';
    newFile(mainFilePath, content);

    await initialize();
    var futures = <Future<void>>[];

    /// Helper to send two hover requests and pump the event queue, but not wait
    /// for the requests to complete.
    Future<void> sendHovers() async {
      futures.add(getHover(mainFileUri, Position(line: 0, character: 0)));
      futures.add(getHover(mainFileUri, Position(line: 0, character: 0)));
      await pumpEventQueue(times: 5000);
    }

    /// Helper to resume the scheduler and pump the event queue to allow time
    /// for processing to ensure the logs are in a consistent order.
    Future<void> resume() async {
      messageScheduler.resume();
      await pumpEventQueue(times: 5000);
    }

    await sendHovers();
    messageScheduler.pause(); // Pause 1
    await sendHovers();
    messageScheduler.pause(); // Pause 2
    await sendHovers();
    await resume(); // Resume 1
    await sendHovers();
    await resume(); // Resume 2

    await Future.wait(futures);

    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/hover
Entering process messages loop
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/hover
Entering process messages loop
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
Exit process messages loop
Pause requested - there are now 1 pauses
Incoming RequestMessage: lsp:textDocument/hover
Incoming RequestMessage: lsp:textDocument/hover
Pause requested - there are now 2 pauses
Incoming RequestMessage: lsp:textDocument/hover
Incoming RequestMessage: lsp:textDocument/hover
Resume requested - there are now 1 pauses
Incoming RequestMessage: lsp:textDocument/hover
Incoming RequestMessage: lsp:textDocument/hover
Resume requested - there are now 0 pauses
Entering process messages loop
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
  Start LspMessage: lsp:textDocument/hover
  Complete LspMessage: lsp:textDocument/hover
Exit process messages loop
''');
  }

  Future<void> test_response() async {
    if (MessageScheduler.allowOverlappingHandlers) return;

    const content = '''
void f() {
  print('Test!');
  [!print('Test!');!]
}
''';

    var codeAction = await expectCodeActionLiteral(
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

    _assertLogContents(testView!, r'''
Incoming RequestMessage: lsp:initialize
Entering process messages loop
  Start LspMessage: lsp:initialize
  Complete LspMessage: lsp:initialize
Exit process messages loop
Incoming NotificationMessage: lsp:initialized
Entering process messages loop
  Start LspMessage: lsp:initialized
  Complete LspMessage: lsp:initialized
Exit process messages loop
Incoming RequestMessage: lsp:textDocument/codeAction
Entering process messages loop
  Start LspMessage: lsp:textDocument/codeAction
  Complete LspMessage: lsp:textDocument/codeAction
Exit process messages loop
Incoming RequestMessage: lsp:workspace/executeCommand
Entering process messages loop
  Start LspMessage: lsp:workspace/executeCommand
Incoming ResponseMessage: ResponseMessage
  Complete LspMessage: lsp:workspace/executeCommand
Exit process messages loop
''');
  }
}
