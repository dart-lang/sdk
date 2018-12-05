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
  test_change_badPosition() async {
    final contents = '';
    await initialize();
    await openFile(mainFileUri, contents);

    // Since this is a notification and not a request, the server cannot
    // respond with an error, but instead sends a ShowMessage notification
    // to alert the user to something failing.
    final error = await expectErrorNotification<ShowMessageParams>(() async {
      await changeFile(mainFileUri, [
        new TextDocumentContentChangeEvent(
          new Range(new Position(999, 999), new Position(999, 999)),
          null,
          '   ',
        )
      ]);
    });

    expect(error.message, contains('Invalid line'));
  }

  test_change_fullContents() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(mainFileUri, updatedContent);
    expect(server.fileContentOverlay[mainFilePath], equals(updatedContent));
  }

  test_change_incremental() async {
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

  test_change_unopenedFile() async {
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

  test_close() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(mainFileUri, updatedContent);
    await closeFile(mainFileUri);
    expect(server.fileContentOverlay[mainFilePath], isNull);
  }

  test_open() async {
    const testContent = 'CONTENT';

    await initialize();
    expect(server.fileContentOverlay[mainFilePath], isNull);
    await openFile(mainFileUri, testContent);
    expect(server.fileContentOverlay[mainFilePath], equals(testContent));
  }
}
