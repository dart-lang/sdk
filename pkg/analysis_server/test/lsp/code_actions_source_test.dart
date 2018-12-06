// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_actions_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceCodeActionsTest);
  });
}

@reflectiveTest
class SourceCodeActionsTest extends AbstractCodeActionsTest {
  Future<void> checkCodeActionAvailable(
    Uri uri,
    String command,
    String title, {
    bool asCodeActionLiteral = false,
    bool asCommand = false,
  }) async {
    final codeActions = await getCodeActions(uri.toString());
    final codeAction = _findCommand(codeActions, command);
    expect(codeAction, isNotNull);

    codeAction.map(
      (command) {
        if (!asCommand) {
          throw 'Got Command but expected CodeAction literal';
        }
        expect(command.title, equals(title));
        expect(command.arguments, equals([uri.toFilePath()]));
      },
      (codeAction) {
        if (!asCodeActionLiteral) {
          throw 'Got CodeAction literal but expected Command';
        }
        expect(codeAction, isNotNull);
        expect(codeAction.title, equals(title));
        expect(codeAction.command.title, equals(title));
        expect(codeAction.command.arguments, equals([uri.toFilePath()]));
      },
    );
  }

  test_organizeImports_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Source]);

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCodeActionLiteral: true,
    );
  }

  test_organizeImports_availableAsCommand() async {
    await newFile(mainFilePath);
    await initialize();

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.organizeImports,
      'Organize Imports',
      asCommand: true,
    );
  }

  test_organizeImports_unavailableWhenNotRequested() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Refactor]);

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.organizeImports);
    expect(codeAction, isNull);
  }

  test_sortMembers_availableAsCodeActionLiteral() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Source]);

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCodeActionLiteral: true,
    );
  }

  test_sortMembers_availableAsCommand() async {
    await newFile(mainFilePath);
    await initialize();

    await checkCodeActionAvailable(
      mainFileUri,
      Commands.sortMembers,
      'Sort Members',
      asCommand: true,
    );
  }

  test_sortMembers_unavailableWhenNotRequested() async {
    await newFile(mainFilePath);
    await initializeWithSupportForKinds([CodeActionKind.Refactor]);

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction = _findCommand(codeActions, Commands.sortMembers);
    expect(codeAction, isNull);
  }

  Either2<Command, CodeAction> _findCommand(
      List<Either2<Command, CodeAction>> actions, String commandID) {
    for (var codeAction in actions) {
      final id = codeAction.map(
          (cmd) => cmd.command, (action) => action.command.command);
      if (id == commandID) {
        return codeAction;
      }
    }
    return null;
  }

  // TODO(dantup): Tests that actuall execute the command and verify the edits.
}
