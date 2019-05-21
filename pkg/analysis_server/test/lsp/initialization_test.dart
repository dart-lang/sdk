// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializationTest);
  });
}

@reflectiveTest
class InitializationTest extends AbstractLspAnalysisServerTest {
  test_initialize() async {
    final response = await initialize();
    expect(response, isNotNull);
    expect(response.error, isNull);
    expect(response.result, isNotNull);
    expect(response.result, TypeMatcher<InitializeResult>());
    InitializeResult result = response.result;
    expect(result.capabilities, isNotNull);
    // Check some basic capabilities that are unlikely to change.
    expect(result.capabilities.textDocumentSync, isNotNull);
    result.capabilities.textDocumentSync.map(
      (options) {
        // We'll always request open/closed notifications and incremental updates.
        expect(options.openClose, isTrue);
        expect(options.change, equals(TextDocumentSyncKind.Incremental));
      },
      (_) =>
          throw 'Expected textDocumentSync capabilities to be a $TextDocumentSyncOptions',
    );
  }

  test_initialize_invalidParams() async {
    final params = {'processId': 'invalid'};
    final request = new RequestMessage(
      Either2<num, String>.t1(1),
      Method.initialize,
      params,
      jsonRpcVersion,
    );
    final response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.error.code, equals(ErrorCodes.InvalidParams));
    expect(response.result, isNull);
  }

  test_initialize_onlyAllowedOnce() async {
    await initialize();
    final response = await initialize(throwOnFailure: false);
    expect(response, isNotNull);
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(
        response.error.code, equals(ServerErrorCodes.ServerAlreadyInitialized));
  }

  test_initialize_rootPath() async {
    await initialize(rootPath: projectFolderPath);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  test_initialize_rootUri() async {
    await initialize(rootUri: projectFolderUri);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  test_onlyAnalyzeProjectsWithOpenFiles_withPubpsec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    await newFile(nestedFilePath);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    await newFile(pubspecPath);

    // The project folder shouldn't be added to start with.
    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Opening a file nested within the project should add the project folder.
    await openFile(nestedFileUri, '');
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Closing the file should remove it.
    await closeFile(nestedFileUri);
    expect(server.contextManager.includedPaths, equals([]));
  }

  test_onlyAnalyzeProjectsWithOpenFiles_multipleFiles() async {
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = Uri.file(file1);
    await newFile(file1);
    final file2 = join(projectFolderPath, 'file2.dart');
    final file2Uri = Uri.file(file2);
    await newFile(file2);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    await newFile(pubspecPath);

    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );

    // Opening both files should only add the project folder once.
    await openFile(file1Uri, '');
    await openFile(file2Uri, '');
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Closing only one of the files should not remove the project folder
    // since there are still open files.
    await closeFile(file1Uri);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Closing the last file should remove the project folder.
    await closeFile(file2Uri);
    expect(server.contextManager.includedPaths, equals([]));
  }

  test_onlyAnalyzeProjectsWithOpenFiles_withoutPubpsec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    await newFile(nestedFilePath);

    // The project folder shouldn't be added to start with.
    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Opening a file nested within the project will still not add the project
    // folder because there was no pubspec.
    final messageFromServer = await expectNotification<ShowMessageParams>(
      (notification) => notification.method == Method.window_showMessage,
      () => openFile(nestedFileUri, ''),
    );
    expect(server.contextManager.includedPaths, equals([]));
    expect(messageFromServer.type, MessageType.Warning);
    expect(messageFromServer.message,
        contains('using onlyAnalyzeProjectsWithOpenFiles'));
  }

  test_initialize_workspaceFolders() async {
    await initialize(workspaceFolders: [projectFolderUri]);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  test_uninitialized_dropsNotifications() async {
    final notification =
        makeNotification(new Method.fromJson('randomNotification'), null);
    final nextNotification = errorNotificationsFromServer.first;
    channel.sendNotificationToServer(notification);

    // Wait up to 1sec to ensure no error/log notifications were sent back.
    var didTimeout = false;
    final notificationFromServer = await nextNotification.timeout(
      const Duration(seconds: 1),
      onTimeout: () {
        didTimeout = true;
      },
    );

    expect(notificationFromServer, isNull);
    expect(didTimeout, isTrue);
  }

  test_uninitialized_rejectsRequests() async {
    final request = makeRequest(new Method.fromJson('randomRequest'), null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error.code, ErrorCodes.ServerNotInitialized);
  }
}
