// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
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
    var contents = '';
    await initialize();
    await openFile(mainFileUri, contents);

    // Since this is a notification and not a request, the server cannot
    // respond with an error, but instead sends a ShowMessage notification
    // to alert the user to something failing.
    var error = await expectErrorNotification(() async {
      await changeFile(222, mainFileUri, [
        TextDocumentContentChangeEvent.t1(
          TextDocumentContentChangePartial(
            range: Range(
              start: Position(line: 999, character: 999),
              end: Position(line: 999, character: 999),
            ),
            text: '   ',
          ),
        ),
      ]);
    });

    expect(error.message, contains('Invalid line'));
  }

  Future<void> test_change_fullContents() async {
    var initialContent = 'int a = 1;';
    var updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(222, mainFileUri, updatedContent);
    expect(_getOverlay(mainFilePath), equals(updatedContent));

    var documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, equals(222));
  }

  Future<void> test_change_incremental() async {
    var initialContent = '// 0123456789\n// 0123456789';
    var expectedUpdatedContent = '// 0123456789\n// 01234   89';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await changeFile(222, mainFileUri, [
      // Replace line1:5-1:8 with spaces.
      TextDocumentContentChangeEvent.t1(
        TextDocumentContentChangePartial(
          range: Range(
            start: Position(line: 1, character: 8),
            end: Position(line: 1, character: 11),
          ),
          text: '   ',
        ),
      ),
    ]);
    expect(_getOverlay(mainFilePath), equals(expectedUpdatedContent));

    var documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, equals(222));
  }

  Future<void> test_change_unopenedFile() async {
    // It's not valid for a client to send a request to modify a file that it
    // has not opened, but Visual Studio has done it in the past so we should
    // ensure it generates an obvious error that the user can understand.
    var simpleEdit = TextDocumentContentChangeEvent.t1(
      TextDocumentContentChangePartial(
        range: Range(
          start: Position(line: 1, character: 1),
          end: Position(line: 1, character: 1),
        ),
        text: 'test',
      ),
    );
    await initialize();
    var notificationParams = await expectErrorNotification(
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
    var initialContent = 'int a = 1;';
    var updatedContent = 'int a = 2;';

    await initialize();
    await openFile(mainFileUri, initialContent);
    await replaceFile(222, mainFileUri, updatedContent);
    await closeFile(mainFileUri);
    expect(_getOverlay(mainFilePath), isNull);

    // When we close a file, we expect the version in the versioned identifier to
    // return to `null`.
    var documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, isNull);
  }

  Future<void> test_open() async {
    const testContent = '// CONTENT';

    await initialize();
    expect(_getOverlay(mainFilePath), isNull);
    await openFile(mainFileUri, testContent, version: 2);
    expect(_getOverlay(mainFilePath), equals(testContent));

    // The version for a file that's just been opened (and never modified) is
    // `null` (this means the contents match what's on disk).
    var documentVersion = server.getVersionedDocumentIdentifier(mainFilePath);
    expect(documentVersion.version, 2);
  }

  Future<void> test_open_invalidPath() async {
    await initialize();

    var notificationParams = await expectErrorNotification(
      () => openFile(Uri.http('localhost', 'not-a-file'), ''),
    );
    expect(notificationParams, isNotNull);
    expect(
      notificationParams.message,
      contains(
        "URI scheme 'http' is not supported. Allowed schemes are 'file'.",
      ),
    );
  }

  String? _getOverlay(String path) {
    if (server.resourceProvider.hasOverlay(path)) {
      return server.resourceProvider.getFile(path).readAsStringSync();
    }
    return null;
  }
}
