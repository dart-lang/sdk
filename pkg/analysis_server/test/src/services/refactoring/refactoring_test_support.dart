// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../../../lsp/code_actions_abstract.dart';
import '../../../utils/test_code_extensions.dart';

abstract class RefactoringTest extends AbstractCodeActionsTest {
  /// Position of the marker where the refactor will be invoked.
  Position? _position;

  /// The range of characters that were selected.
  Range? _range;

  /// Return the title of the refactoring command that is expected to be
  /// available.
  String get refactoringName;

  void addTestSource(String markedCode) {
    var testCode = TestCode.parse(markedCode);
    var positions = testCode.positions;
    if (positions.isNotEmpty) {
      _position = positions[0].position;
    } else {
      var ranges = testCode.ranges;
      if (ranges.isNotEmpty) {
        _range = ranges[0].range;
      }
    }
    newFile(mainFilePath, testCode.code);
  }

  void assertTextExpectation(String actual, String expected) {
    if (actual != expected) {
      print('-' * 64);
      print(actual.trimRight());
      print('-' * 64);
    }
    expect(actual, expected);
  }

  /// Executes the refactor in [action].
  Future<void> executeRefactor(CodeAction action) async {
    await executeCommandForEdits(action.command!);
  }

  /// Expects to find a refactor [CodeAction] in [mainFileUri] at the offset of
  /// the marker with the title [title].
  Future<CodeAction> expectCodeAction(String title) async {
    final action = await getCodeAction(title);
    expect(action, isNotNull, reason: "Action '$title' should be included");
    return action!;
  }

  /// Expects to not find a refactor [CodeAction] in [mainFileUri] at the offset
  /// of the marker with the title [title].
  Future<void> expectNoCodeAction(String? title) async {
    expect(await getCodeAction(title), isNull);
  }

  /// Attempts to find a refactor [CodeAction] in [mainFileUri] at the offset of
  /// the marker with the title [title].
  Future<CodeAction?> getCodeAction(String? title) async {
    final codeActions = await getCodeActions(
      mainFileUri,
      position: _position,
      range: _range,
      kinds: const [CodeActionKind.Refactor],
    );
    final commandOrCodeAction =
        findCommand(codeActions, refactoringName, title);
    final codeAction = commandOrCodeAction?.map(
      (command) => throw 'Expected CodeAction, got Command',
      (codeAction) => codeAction,
    );
    return codeAction;
  }

  /// Unwraps the 'arguments' field from the arguments object (which is the
  /// single argument for the command).
  List<Object?> getRefactorCommandArguments(CodeAction action) {
    final commandArguments = action.command!.arguments as List<Object?>;

    // Our refactor command uses a single object in its arguments so we can have
    // named fields instead of having the client have to know which index
    // corresponds to the parameters.
    final argsObject = commandArguments.single as Map<String, Object?>;

    // Within that object, the 'arguments' field is the List<Object?> that
    // contains the values for the parameters.
    final arguments = argsObject['arguments'] as List<Object?>;

    return arguments;
  }

  /// Initializes the server.
  ///
  /// Enables all required client capabilities for new refactors unless the
  /// corresponding flags are set to `false`.
  Future<void> initializeServer({
    bool experimentalOptInFlag = true,
  }) async {
    final config = {
      if (experimentalOptInFlag) 'experimentalRefactors': true,
    };

    await provideConfig(super.initialize, config);
  }
}
