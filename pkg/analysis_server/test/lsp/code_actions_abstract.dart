// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';

import 'server_abstract.dart';

abstract class AbstractCodeActionsTest extends AbstractLspAnalysisServerTest {
  Future<void> checkCodeActionAvailable(
    Uri uri,
    String command,
    String title, {
    bool asCodeActionLiteral = false,
    bool asCommand = false,
  }) async {
    final codeActions = await getCodeActions(uri.toString());
    final codeAction = findCommand(codeActions, command);
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

  Either2<Command, CodeAction> findCommand(
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

  CodeAction findEditAction(List<Either2<Command, CodeAction>> actions,
      CodeActionKind actionKind, String title) {
    for (var codeAction in actions) {
      final codeActionLiteral =
          codeAction.map((cmd) => null, (action) => action);
      if (codeActionLiteral?.kind == actionKind &&
          codeActionLiteral?.title == title) {
        // We're specifically looking for an action that contains an edit.
        assert(codeActionLiteral.command == null);
        assert(codeActionLiteral.edit != null);
        return codeActionLiteral;
      }
    }
    return null;
  }
}
