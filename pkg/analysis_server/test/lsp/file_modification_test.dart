// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileModificationTest);
  });
}

@reflectiveTest
class FileModificationTest extends AbstractLspAnalysisServerTest {
  test_document_change_in_unopened_file() async {
    // It's not valid for a client to send a request to modify a file that it
    // has not opened, but Visual Studio has done it in the past so we should
    // ensure it generates an obvious error that the user can understand.
    final simpleEdit = new TextDocumentContentChangeEvent(
      new Range(new Position(1, 1), new Position(1, 1)),
      null,
      'test',
    );
    await initialize();
    final notificationParams = await expectErrorNotification<ShowMessageParams>(
      () => changeFile(mainFileUri, [simpleEdit]),
    );
    expect(notificationParams, isNotNull);
    expect(
      notificationParams.message,
      allOf(
        contains('because the file was not previously opened'),
        contains(mainFilePath),
      ),
    );
  }

  test_document_change_partial() async {
    final initialContent = '0123456789\n0123456789';
    final expectedUpdatedContent = '0123456789\n01234   89';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await changeFile(mainFileUri, [
      // Replace line1:5-1:8 with spaces.
      new TextDocumentContentChangeEvent(
        new Range(new Position(1, 5), new Position(1, 8)),
        null,
        '   ',
      )
    ]);
    expect(server.fileContentOverlay[mainFilePath],
        equals(expectedUpdatedContent));
  }

  test_document_change_replace() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(mainFileUri, updatedContent);
    expect(server.fileContentOverlay[mainFilePath], equals(updatedContent));
  }

  test_document_close() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(mainFileUri, updatedContent);
    await closeFile(mainFileUri);
    expect(server.fileContentOverlay[mainFilePath], isNull);
  }

  test_document_open() async {
    const testContent = 'CONTENT';

    await initialize();
    expect(server.fileContentOverlay[mainFilePath], isNull);
    await openFile(mainFileUri, testContent);
    expect(server.fileContentOverlay[mainFilePath], equals(testContent));
  }
}
