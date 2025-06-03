// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/extensions/code_action.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../../../lsp/code_actions_mixin.dart';
import '../../../lsp/server_abstract.dart';
import '../../../utils/test_code_extensions.dart';

abstract class RefactoringTest extends AbstractLspAnalysisServerTest
    with LspSharedTestMixin, CodeActionsTestMixin {
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

  /// Expects to find a refactor [CodeAction] with the title [title] in
  /// [mainFileUri] at the offset of the marker .
  Future<CodeAction> expectCodeActionWithTitle(String title) async {
    var action = await getCodeActionWithTitle(title);
    expect(action, isNotNull, reason: "Action '$title' should be included");
    return action!;
  }

  /// Expects to not find a refactor [CodeActionLiteral] with the title [title]
  /// in [mainFileUri] at the offset of the marker .
  Future<void> expectNoCodeActionWithTitle(String? title) async {
    expect(await getCodeActionWithTitle(title), isNull);
  }

  /// Attempts to find a refactor Code Action with the title [title] in
  /// [mainFileUri] at the offset of the marker .
  Future<CodeAction?> getCodeActionWithTitle(String? title) async {
    var codeActions = await getCodeActions(
      mainFileUri,
      position: _position,
      range: _range,
      kinds: const [CodeActionKind.Refactor],
    );
    return findCommand(codeActions, refactoringName, title);
  }

  /// Unwraps the 'arguments' field from the arguments object (which is the
  /// single argument for the command).
  List<Object?> getRefactorCommandArguments(CodeAction action) {
    var command = action.command!;
    var commandArguments = command.arguments as List<Object?>;

    // Our refactor command uses a single object in its arguments so we can have
    // named fields instead of having the client have to know which index
    // corresponds to the parameters.
    var argsObject = commandArguments.single as Map<String, Object?>;

    // Within that object, the 'arguments' field is the List<Object?> that
    // contains the values for the parameters.
    var arguments = argsObject['arguments'] as List<Object?>;

    return arguments;
  }

  /// Initializes the server.
  ///
  /// Enables all required client capabilities for new refactors unless the
  /// corresponding flags are set to `false`.
  @override
  Future<void> initializeServer({bool experimentalOptInFlag = true}) async {
    var config = {if (experimentalOptInFlag) 'experimentalRefactors': true};

    await provideConfig(super.initializeServer, config);
  }

  @override
  void setUp() {
    super.setUp();

    // Many refactor tests test with code that produces errors.
    failTestOnErrorDiagnostic = false;

    setApplyEditSupport();
    setDocumentChangesSupport();
  }
}
