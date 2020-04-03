// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileModificationTest);
  });
}

@reflectiveTest
class FileModificationTest extends AbstractLspAnalysisServerTest {
  Future<void> test_change_badPosition() async {
    final contents = '';
    await initialize();
    await openFile(mainFileUri, contents);

    // Since this is a notification and not a request, the server cannot
    // respond with an error, but instead sends a ShowMessage notification
    // to alert the user to something failing.
    final error = await expectErrorNotification<ShowMessageParams>(() async {
      await changeFile(222, mainFileUri, [
        TextDocumentContentChangeEvent(
          Range(Position(999, 999), Position(999, 999)),
          null,
          '   ',
        )
      ]);
    });

    expect(error.message, contains('Invalid line'));
  }

  Future<void> test_change_fullContents() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(222, mainFileUri, updatedContent);
    expect(_getOverlay(mainFilePath), equals(updatedContent));

    final documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, equals(222));
  }

  Future<void> test_change_incremental() async {
    final initialContent = '0123456789\n0123456789';
    final expectedUpdatedContent = '0123456789\n01234   89';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await changeFile(222, mainFileUri, [
      // Replace line1:5-1:8 with spaces.
      TextDocumentContentChangeEvent(
        Range(Position(1, 5), Position(1, 8)),
        null,
        '   ',
      )
    ]);
    expect(_getOverlay(mainFilePath), equals(expectedUpdatedContent));

    final documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, equals(222));
  }

  Future<void> test_change_unopenedFile() async {
    // It's not valid for a client to send a request to modify a file that it
    // has not opened, but Visual Studio has done it in the past so we should
    // ensure it generates an obvious error that the user can understand.
    final simpleEdit = TextDocumentContentChangeEvent(
      Range(Position(1, 1), Position(1, 1)),
      null,
      'test',
    );
    await initialize();
    final notificationParams = await expectErrorNotification<ShowMessageParams>(
      () => changeFile(222, mainFileUri, [simpleEdit]),
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

  Future<void> test_close() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(222, mainFileUri, updatedContent);
    await closeFile(mainFileUri);
    expect(_getOverlay(mainFilePath), isNull);

    // When we close a file, we expect the version in the versioned identifier to
    // return to `null`.
    final documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, isNull);
  }

  Future<void> test_open() async {
    const testContent = 'CONTENT';

    await initialize();
    expect(_getOverlay(mainFilePath), isNull);
    await openFile(mainFileUri, testContent, version: 2);
    expect(_getOverlay(mainFilePath), equals(testContent));

    // The version for a file that's just been opened (and never modified) is
    // `null` (this means the contents match what's on disk).
    final documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, 2);
  }

  Future<void> test_open_invalidPath() async {
    await initialize();

    final notificationParams = await expectErrorNotification<ShowMessageParams>(
      () => openFile(Uri.http('localhost', 'not-a-file'), ''),
    );
    expect(notificationParams, isNotNull);
    expect(
      notificationParams.message,
      contains('URI was not a valid file:// URI'),
    );
  }

  String _getOverlay(String path) {
    if (server.resourceProvider.hasOverlay(path)) {
      return server.resourceProvider.getFile(path).readAsStringSync();
    }
    return null;
  }
}
