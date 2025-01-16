// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../lsp/change_verifier.dart';
import '../lsp/request_helpers_mixin.dart';

/// Shared `workspace/applyEdit` tests that are used by both LSP and legacy
/// server tests.
mixin SharedWorkspaceApplyEditTests
    on LspRequestHelpersMixin, LspVerifyEditHelpersMixin {
  /// Overridden by test subclasses to provide the path of a file for testing.
  String get testFilePath;

  /// The URI for [testFilePath].
  Uri get testFileUri => Uri.file(testFilePath);

  /// Overridden by test subclasses to create a new file.
  void createFile(String path, String content);

  /// Overridden by test subclasses to initialize the server.
  Future<void> initializeServer();

  /// Overridden by test subclasses to send LSP requests from the server to
  /// the client.
  Future<ResponseMessage> sendLspRequestToClient(Method method, Object params);

  test_applyEdit_existingFile() async {
    var code = TestCode.parse('''
void f() {
  print('--/*[0*/replace/*0]*/--');
  // --/*[1*/delete/*1]*/--
  // --^--
}
''');

    var expectedResult = r'''
>>>>>>>>>> lib/test.dart
void f() {
  print('--replacedtext--');
  // ----
  // --insertedtext--
}
''';

    createFile(testFilePath, code.code);

    await initializeServer();

    var fileEdits = [
      FileEditInformation(
        newFile: false,
        OptionalVersionedTextDocumentIdentifier(uri: testFileUri, version: 5),
        LineInfo.fromContent(code.code),
        [
          // replace
          SourceEdit(
            code.ranges[0].sourceRange.offset,
            code.ranges[0].sourceRange.length,
            'replacedtext',
          ),
          // delete
          SourceEdit(
            code.ranges[1].sourceRange.offset,
            code.ranges[1].sourceRange.length,
            '',
          ),
          // insert
          SourceEdit(code.position.offset, 0, 'insertedtext'),
        ],
      ),
    ];

    var (verifier, applyEditResult) = await _sendApplyEdits(
      toWorkspaceEdit(editorClientCapabilities, fileEdits),
    );

    expect(applyEditResult.applied, isTrue);
    verifier.verifyFiles(expectedResult);
  }

  test_applyEdit_newFile() async {
    await initializeServer();

    var fileEdits = [
      FileEditInformation(
        newFile: true,
        OptionalVersionedTextDocumentIdentifier(uri: testFileUri),
        LineInfo.fromContent(''),
        [SourceEdit(0, 0, 'inserted')],
      ),
    ];

    var (verifier, applyEditResult) = await _sendApplyEdits(
      toWorkspaceEdit(editorClientCapabilities, fileEdits),
    );

    expect(applyEditResult.applied, isTrue);
    verifier.verifyFiles('''
>>>>>>>>>> lib/test.dart created
inserted<<<<<<<<<<
''');
  }

  test_bad_failedToApply() async {
    await initializeServer();

    var fileEdits = [
      FileEditInformation(
        newFile: true,
        OptionalVersionedTextDocumentIdentifier(uri: testFileUri),
        LineInfo.fromContent(''),
        [SourceEdit(0, 0, 'inserted')],
      ),
    ];

    var (verifier, applyEditResult) = await _sendApplyEdits(
      toWorkspaceEdit(editorClientCapabilities, fileEdits),
      // Have the client return that it failed to apply.
      applyEditResult: ApplyWorkspaceEditResult(
        applied: false,
        failureReason: 'x',
      ),
    );

    // Ensure the server correctly parsed the clients result.
    expect(applyEditResult.applied, isFalse);
    expect(applyEditResult.failureReason, 'x');
  }

  /// Triggers a `workspace/applyEdit` request from the server, collects the
  /// edits from the client, and returns a [LspChangeVerifier] along with the
  /// [ApplyWorkspaceEditResult] the server got back.
  Future<(LspChangeVerifier, ApplyWorkspaceEditResult)> _sendApplyEdits(
    WorkspaceEdit workspaceEdit, {
    ApplyWorkspaceEditResult? applyEditResult,
  }) async {
    var applyEditResultToSend = applyEditResult;
    ApplyWorkspaceEditResult? receivedApplyEditResult;

    var verifier = await executeForEdits(() async {
      var result = await sendLspRequestToClient(
        Method.workspace_applyEdit,
        ApplyWorkspaceEditParams(edit: workspaceEdit),
      );
      receivedApplyEditResult = ApplyWorkspaceEditResult.fromJson(
        result.result as Map<String, Object?>,
      );
      return null;
    }, applyEditResult: applyEditResultToSend);

    return (verifier, receivedApplyEditResult!);
  }
}
