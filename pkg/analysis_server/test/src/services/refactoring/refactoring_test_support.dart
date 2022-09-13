// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:test/test.dart';

import '../../../lsp/server_abstract.dart';

abstract class RefactoringTest extends AbstractLspAnalysisServerTest {
  late String _mainFileSource;
  late int _offset;
  late int _length;

  /// Return the title of the refactoring command that is expected to be
  /// available.
  String get refactoringName;

  /// Return the workspace in which refactorings occur.
  Future<ChangeWorkspace> get workspace async {
    var session = await server.getAnalysisSession(mainFilePath);
    if (session == null) {
      fail('Could not get session for the test file');
    }
    return DartChangeWorkspace([session]);
  }

  void addTestSource(String code) {
    _offset = code.indexOf('^');
    if (_offset < 0) {
      _offset = code.indexOf('[[');
      if (_offset < 0) {
        fail("Mark the selection range using either '^' or '[[' and ']]'");
      }
      var end = code.indexOf(']]', _offset + 1);
      if (end < 0) {
        fail("Missing closing ']]'");
      }
      _mainFileSource = code.substring(0, _offset) +
          code.substring(_offset + 2, end) +
          code.substring(end + 2);
      _length = end - _offset - 2;
    } else {
      var nextOffset = code.indexOf('^', _offset + 1);
      expect(nextOffset, equals(-1), reason: "Too many '^' markers");
      _mainFileSource =
          code.substring(0, _offset) + code.substring(_offset + 1);
      _length = 0;
    }
    newFile(mainFilePath, _mainFileSource);
  }

  /// Assert that there is no refactoring at the target location.
  Future<void> assertNoRefactoring() async {
    var actions = await _computeRefactorings();
    for (var action in actions) {
      if (_isTargetRefactoring(action)) {
        fail('Unexpectedly found refactoring');
      }
    }
  }

  /// Asserts that there is a refactoring and that the [changedFiles], and only
  /// the changed files, are updated by the refactoring.
  Future<void> assertRefactoring(Map<String, String> changedFiles) async {
    await initialize();
    var edit = await _assertHasRefactoring();
    var changes = edit.changes!;
    expect(changes.length, changedFiles.length);
    var contents = <String, String>{};
    for (var entry in changes.entries) {
      var filePath = Uri.parse(entry.key).path;
      expect(changedFiles[filePath], isNotNull);
      var file = resourceProvider.getFile(filePath);
      if (file.exists) {
        contents[filePath] = file.readAsStringSync();
      } else {
        contents[filePath] = '';
      }
    }
    applyChanges(contents, changes);
    for (var entry in contents.entries) {
      var filePath = entry.key;
      var actualContent = entry.value;
      var expectedContent = changedFiles[filePath];
      expect(actualContent, expectedContent);
    }
  }

  @override
  void setUp() {
    super.setUp();
    // TODO(brianwilkerson) Set the capability indicating that command
    //  parameters are supported.
    server.clientCapabilities;
  }

  /// Assert that there is a refactoring at the target location.
  Future<WorkspaceEdit> _assertHasRefactoring() async {
    var actions = await _computeRefactorings();
    for (var action in actions) {
      if (_isTargetRefactoring(action)) {
        return await _executeCommand(action.command!);
      }
    }
    fail('Expected to find refactoring in\n${actions.join('\n')}');
  }

  /// Return the code actions for the refactorings that are available at the
  /// given selection.
  Future<List<CodeAction>> _computeRefactorings() async {
    // The more straightforward approach would be to send a
    // `textDocument/codeAction` request to the server to get back the code
    // actions. We don't do that because the result would include fixes and
    // assists, and we don't want to take the time to compute those.
    //
    // We can actually tell the server what `CodeActionKinds` we're interested
    // in to avoid some of that computation. See the `kinds` argument on
    // `LspAnalysisServerTestMixon.getCodeActions` which is passed to the
    // `textDocument/codeAction` request as the `only` argument.
    //
    // If we change this to go through the LSP interface we'll need to set the
    // client's configuration options to say that it supports self-describing
    // refactorings in order to keep the tests working.
    await openFile(mainFileUri, _mainFileSource);
    await server.getAnalysisDriver(mainFilePath)!.applyPendingFileChanges();
    var session = await server.getAnalysisSession(mainFilePath);
    if (session == null) {
      fail('Could not get a session for the test file');
    }
    var result = await session.getResolvedUnit(mainFilePath);
    var context = RefactoringContext(
      server: server,
      resolvedResult: result as ResolvedUnitResult,
      selectionOffset: _offset,
      selectionLength: _length,
    );
    var processor = RefactoringProcessor(context);
    return await processor.compute();
  }

  /// Execute the [command] and return the workspace edit that was sent back to
  /// the client.
  Future<WorkspaceEdit> _executeCommand(Command command) async {
    // TODO(brianwilkerson) Consider moving this method to
    //  `AbstractCodeActionsTest` and invoking it from `verifyCommandEdits`.
    //  There might be other opportunities to generalize and unify the code in
    //  order to make tests easier to write and more uniform.
    ApplyWorkspaceEditParams? editParams;

    final commandResponse = await handleExpectedRequest<Object?,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResult>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(command, workDoneToken: null),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified below).
        editParams = edit;
        return ApplyWorkspaceEditResult(applied: true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the expected changes.
    expect(editParams, isNotNull);
    return editParams!.edit;
  }

  /// Return `true` if the `codeAction` is the refactoring being tested.
  bool _isTargetRefactoring(CodeAction codeAction) {
    return codeAction.command?.command == refactoringName;
  }
}
