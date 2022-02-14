// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerTest);
  });
}

@reflectiveTest
class ServerTest extends AbstractLspAnalysisServerTest {
  Future<void> test_inconsistentStateError() async {
    await initialize(
      // Error is expected and checked below.
      failTestOnAnyErrorNotification: false,
    );
    await openFile(mainFileUri, '');
    // Attempt to make an illegal modification to the file. This indicates the
    // client and server are out of sync and we expect the server to shut down.
    final error = await expectErrorNotification(() async {
      await changeFile(222, mainFileUri, [
        Either2<TextDocumentContentChangeEvent1,
                TextDocumentContentChangeEvent2>.t1(
            TextDocumentContentChangeEvent1(
                range: Range(
                    start: Position(line: 99, character: 99),
                    end: Position(line: 99, character: 99)),
                text: ' ')),
      ]);
    });

    expect(error, isNotNull);
    expect(error.message, contains('Invalid line'));

    // Wait for up to 10 seconds for the server to shutdown.
    await server.exited.timeout(const Duration(seconds: 10));
  }

  Future<void> test_path_doesNotExist() async {
    final missingFileUri = Uri.file(join(projectFolderPath, 'missing.dart'));
    await initialize();
    await expectLater(
      getHover(missingFileUri, startOfDocPos),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'File does not exist')),
    );
  }

  Future<void> test_path_invalidFormat() async {
    await initialize();
    await expectLater(
      // Add some invalid path characters to the end of a valid file:// URI.
      formatDocument(mainFileUri.toString() + r'***###\\\///:::.dart'),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'File URI did not contain a valid file path')),
    );
  }

  Future<void> test_path_missingDriveLetterWindows() async {
    // This test is only valid on Windows, as a URI in the format:
    //    file:///foo/bar.dart
    // is valid for non-Windows platforms, but not valid on Windows as it does
    // not have a drive letter.
    if (!Platform.isWindows) {
      return;
    }
    final missingDriveLetterFileUri = Uri.file('/foo/bar.dart');
    await initialize();
    await expectLater(
      getHover(missingDriveLetterFileUri, startOfDocPos),
      // The Uri.file() above translates to a non-file:// URI of just 'a/b.dart'
      // so will get the not-file-scheme error message.
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'URI was not an absolute file path (missing drive letter)')),
    );
  }

  Future<void> test_path_notFileScheme() async {
    final relativeFileUri = Uri(scheme: 'foo', path: '/a/b.dart');
    await initialize();
    await expectLater(
      getHover(relativeFileUri, startOfDocPos),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'URI was not a valid file:// URI')),
    );
  }

  Future<void> test_path_relative() async {
    final relativeFileUri = Uri.file('a/b.dart');
    await initialize();
    await expectLater(
      getHover(relativeFileUri, startOfDocPos),
      // The Uri.file() above translates to a non-file:// URI of just 'a/b.dart'
      // so will get the not-file-scheme error message.
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'URI was not a valid file:// URI')),
    );
  }

  Future<void> test_shutdown_initialized() async {
    await initialize();
    final response = await sendShutdown();
    expect(response, isNull);
  }

  Future<void> test_shutdown_uninitialized() async {
    final response = await sendShutdown();
    expect(response, isNull);
  }

  Future<void> test_unknownNotifications_logError() async {
    await initialize(
      // Error is expected and checked below.
      failTestOnAnyErrorNotification: false,
    );

    final notification =
        makeNotification(Method.fromJson(r'some/randomNotification'), null);

    final notificationParams = await expectErrorNotification(
      () => channel.sendNotificationToServer(notification),
    );
    expect(notificationParams, isNotNull);
    expect(
      notificationParams.message,
      contains('Unknown method some/randomNotification'),
    );
  }

  Future<void> test_unknownOptionalNotifications_silentlyDropped() async {
    await initialize();
    final notification =
        makeNotification(Method.fromJson(r'$/randomNotification'), null);
    final firstError = errorNotificationsFromServer.first;
    channel.sendNotificationToServer(notification);

    // Wait up to 1sec to ensure no error/log notifications were sent back.
    var didTimeout = false;
    final notificationFromServer =
        await firstError.then<NotificationMessage?>((error) => error).timeout(
      const Duration(seconds: 1),
      onTimeout: () {
        didTimeout = true;
        return null;
      },
    );

    expect(notificationFromServer, isNull);
    expect(didTimeout, isTrue);
  }

  Future<void> test_unknownOptionalRequest_rejected() async {
    await initialize();
    final request = makeRequest(Method.fromJson(r'$/randomRequest'), null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.error!.code, equals(ErrorCodes.MethodNotFound));
    expect(response.result, isNull);
  }

  Future<void> test_unknownRequest_rejected() async {
    await initialize();
    final request = makeRequest(Method.fromJson('randomRequest'), null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.error!.code, equals(ErrorCodes.MethodNotFound));
    expect(response.result, isNull);
  }
}
