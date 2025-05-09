// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../lsp/request_helpers_mixin.dart';
import '../lsp/server_abstract.dart';
import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'shared_test_interface.dart';

/// Shared tests used by both LSP + Legacy server tests and/or integration.
mixin SharedApplyCodeActionTests
    on
        SharedTestInterface,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        ClientCapabilitiesHelperMixin {
  /// Verifies a command execution was logged to analytics.
  ///
  /// Implementations are provided by the in-process test base classes. This
  /// method will be a no-op for out-of-process tests because the analytics
  /// manager will not be accessible.
  void expectCommandLogged(String command);

  Future<void> test_bad_actionNotFoundAtLocation() async {
    var code = TestCode.parse('''
var a = [!!]1;
''');

    await initializeServer();
    await openFile(testFileUri, code.code);

    var command = Command(
      title: 'unused',
      command: Commands.applyCodeAction,
      arguments: [
        {
          'textDocument': {'uri': testFileUri.toString(), 'version': 1},
          'range': code.range.range.toJson(),
          'kind': 'refactor.convert.toDoubleQuotedString',
          'loggedAction': 'dart.assist.convert.toDoubleQuotedString',
        },
      ],
    );

    await expectLater(
      executeCommand(command),
      throwsA(
        isResponseError(
          ServerErrorCodes.InvalidCommandArguments,
          message:
              'The code action refactor.convert.toDoubleQuotedString '
              'is not valid at this location',
        ),
      ),
    );
  }

  Future<void> test_bad_editorDoesNotSupportApplyEdit() async {
    setApplyEditSupport(false);
    await initializeServer();

    var command = Command(
      title: 'unused',
      command: Commands.applyCodeAction,
      arguments: [
        {'textDocument': true},
      ],
    );

    await expectLater(
      executeCommand(command),
      throwsA(
        isResponseError(
          ServerErrorCodes.StateError,
          message: 'The editor does not support workspace/applyEdit',
        ),
      ),
    );
  }

  Future<void> test_bad_invalidParams() async {
    await initializeServer();

    var command = Command(
      title: 'unused',
      command: Commands.applyCodeAction,
      arguments: [
        {'textDocument': true},
      ],
    );

    await expectLater(
      executeCommand(command),
      throwsA(
        isResponseError(
          ServerErrorCodes.InvalidCommandArguments,
          message:
              'dart.edit.codeAction.apply requires 3 parameters: '
              'textDocument: Map<String, Object?> (OptionalVersionedTextDocumentIdentifier), '
              'range: Map<String, Object?> (Range), '
              'kind: String (CodeActionKind) '
              'but '
              'textDocument was not a valid OptionalVersionedTextDocumentIdentifier, '
              'range was not a valid Range, '
              'kind was not a valid String',
        ),
      ),
    );
  }

  Future<void> test_bad_wrongDocumentVersion() async {
    var code = TestCode.parse('''
var a = [!!]1;
''');

    await initializeServer();
    await openFile(testFileUri, code.code, version: 111);

    var command = Command(
      title: 'unused',
      command: Commands.applyCodeAction,
      arguments: [
        {
          'textDocument': {
            'uri': testFileUri.toString(),
            // Older document version (we set 111 above)
            'version': 2,
          },
          'range': code.range.range.toJson(),
          'kind': 'refactor.convert.toDoubleQuotedString',
          'loggedAction': 'dart.assist.convert.toDoubleQuotedString',
        },
      ],
    );

    await expectLater(
      executeCommand(command),
      throwsA(
        isResponseError(
          ErrorCodes.ContentModified,
          message: 'Document was modified before operation completed',
        ),
      ),
    );
  }

  Future<void> test_good() async {
    var code = TestCode.parse('''
var a = [!!]'';
''');

    await initializeServer();
    await openFile(testFileUri, code.code);

    var command = Command(
      title: 'unused',
      command: Commands.applyCodeAction,
      arguments: [
        {
          'textDocument': {'uri': testFileUri.toString(), 'version': 1},
          'range': code.range.range.toJson(),
          'kind': 'refactor.convert.toDoubleQuotedString',
          'loggedAction': 'dart.assist.convert.toDoubleQuotedString',
        },
      ],
    );

    // Verify that executing the command produces the correct edits (which will
    // come back via `workspace/applyEdit`).
    await verifyCommandEdits(command, r'''
>>>>>>>>>> lib/test.dart
var a = "";
''');

    expectCommandLogged(Commands.applyCodeAction);
    expectCommandLogged('dart.assist.convert.toDoubleQuotedString');
  }
}
