// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
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

  test_initialize_onlyAllowedOnce() async {
    await initialize();
    final response = await initialize();
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
    final logParams = await expectErrorNotification<LogMessageParams>(() async {
      final response = await channel.sendRequestToServer(request);
      expect(response.id, equals(request.id));
      expect(response.result, isNull);
      expect(response.error, isNotNull);
      expect(response.error.code, ErrorCodes.ServerNotInitialized);
    });
    expect(logParams.type, equals(MessageType.Error));
  }
}
