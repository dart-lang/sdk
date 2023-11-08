// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerTest);
    defineReflectiveTests(ServerDartFixPromptTest);
  });
}

/// Checks server interacts with [DartFixPromptManager] correctly.
///
/// Tests for [DartFixPromptManager]'s behaviour are in
/// test/services/user_prompts/dart_fix_prompt_manager_test.dart.
@reflectiveTest
class ServerDartFixPromptTest extends AbstractLspAnalysisServerTest {
  late TestDartFixPromptManager promptManager;

  @override
  DartFixPromptManager? get dartFixPromptManager => promptManager;

  @override
  void setUp() {
    promptManager = TestDartFixPromptManager();
    super.setUp();
  }

  Future<void> test_trigger_afterInitialAnalysis() async {
    await Future.wait([
      waitForAnalysisComplete(),
      initialize(),
    ]);
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 1);
  }

  Future<void> test_trigger_afterPackageConfigChange() async {
    // Set up and let initial analysis complete.
    await Future.wait([
      waitForAnalysisComplete(),
      initialize(),
    ]);
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 1);

    // Expect that writing package config attempts to trigger another check.
    writePackageConfig(projectFolderPath);
    await waitForAnalysisComplete();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 2);
  }
}

@reflectiveTest
class ServerTest extends AbstractLspAnalysisServerTest {
  List<String> get currentContextPaths => server.contextManager.analysisContexts
      .map((context) => context.contextRoot.root.path)
      .toList();

  /// Ensure an analysis root that doesn't exist does not cause an infinite
  /// rebuild loop.
  /// https://github.com/Dart-Code/Dart-Code/issues/4280
  Future<void> test_analysisRoot_doesNotExist() async {
    final notExistingPath = convertPath('/does/not/exist');
    resourceProvider.emitPathNotFoundExceptionsForPaths.add(notExistingPath);
    await initialize(workspaceFolders: [pathContext.toUri(notExistingPath)]);

    // Wait a short period and ensure there was exactly one context build.
    await pumpEventQueue(times: 10000);
    expect(server.contextBuilds, 1);
    // And that the roots are as expected.
    expect(
      currentContextPaths,
      unorderedEquals([
        // TODO(dantup): It may be a bug that ContextLocator is producing
        //  contexts at the root for missing folders.
        convertPath('/'), // the first existing ancestor of the requested folder
      ]),
    );
  }

  Future<void> test_analysisRoot_existsAndDoesNotExist() async {
    final notExistingPath = convertPath('/does/not/exist');
    resourceProvider.emitPathNotFoundExceptionsForPaths.add(notExistingPath);

    // Track diagnostics for the file to ensure we're analyzing the existing
    // root.
    final diagnosticsFuture = waitForDiagnostics(mainFileUri);
    newFile(mainFilePath, 'NotAClass a;');

    await initialize(
      workspaceFolders: [projectFolderUri, pathContext.toUri(notExistingPath)],
    );

    // Wait a short period and ensure there was exactly one context build.
    await pumpEventQueue(times: 10000);
    expect(server.contextBuilds, 1);
    // And that the roots are as expected.
    expect(
      currentContextPaths,
      unorderedEquals([
        projectFolderPath,
        convertPath('/'), // the first existing ancestor of the requested folder
      ]),
    );

    final diagnostics = await diagnosticsFuture;
    expect(diagnostics, hasLength(1));
    expect(diagnostics!.single.code, 'undefined_class');
  }

  Future<void> test_capturesLatency_afterStartup() async {
    await initialize(includeClientRequestTime: true);
    await openFile(mainFileUri, '');
    await expectLater(
      getHover(mainFileUri, startOfDocPos),
      completes,
    );
    expect(server.performanceAfterStartup!.latencyCount, isPositive);
  }

  Future<void> test_capturesLatency_startup() async {
    await initialize(includeClientRequestTime: true);
    expect(server.performanceDuringStartup.latencyCount, isPositive);
  }

  Future<void> test_capturesRequestPerformance() async {
    await initialize(includeClientRequestTime: true);
    await openFile(mainFileUri, '');
    await expectLater(
      getHover(mainFileUri, startOfDocPos),
      completes,
    );
    final performanceItems = server.recentPerformance.requests.items;
    final hoverItems = performanceItems.where(
        (item) => item.operation == Method.textDocument_hover.toString());
    expect(hoverItems, hasLength(1));
  }

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
        TextDocumentContentChangeEvent.t1(TextDocumentContentChangeEvent1(
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
    final missingFileUri = toUri(join(projectFolderPath, 'missing.dart'));
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
      formatDocument(
        // Add some invalid path characters to the end of a valid file:// URI.
        Uri.parse(mainFileUri.toString() + r'###***\\\///:::.dart'),
      ),
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'File URI did not contain a valid file path')),
    );
  }

  Future<void> test_path_missingDriveLetterWindows() async {
    // This test is only valid on Windows, as a URI in the format:
    //    file:///foo/bar.dart
    // is valid for non-Windows platforms, but not valid on Windows as it does
    // not have a drive letter.
    if (pathContext.style != path.Style.windows) {
      return;
    }
    // This code deliberately does not use pathContext because we're testing a
    // without a drive letter, but pathContext.toUri() would include one.
    final missingDriveLetterFileUri = Uri.parse('file:///foo/bar.dart');
    await initialize();
    await expectLater(
      getHover(missingDriveLetterFileUri, startOfDocPos),
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
    final relativeFileUri = pathContext.toUri('a/b.dart');
    await initialize();
    await expectLater(
      getHover(relativeFileUri, startOfDocPos),
      // The pathContext.toUri() above translates to a non-file:// URI of just
      // 'a/b.dart' so will get the not-file-scheme error message.
      throwsA(isResponseError(ServerErrorCodes.InvalidFilePath,
          message: 'URI was not a valid file:// URI')),
    );
  }

  /// The LSP server relies on pathContext.fromUri() handling encoded colons
  /// in paths, so verify that works as expected.
  Future<void> test_pathContext_fromUri_windows() async {
    expect(path.windows.fromUri('file:///C:/foo'), r'C:\foo');
    expect(path.windows.fromUri('file:///C%3a/foo'), r'C:\foo');
    expect(path.windows.fromUri('file:///C%3A/foo'), r'C:\foo');
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

class TestDartFixPromptManager implements DartFixPromptManager {
  var checksTriggered = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void triggerCheck() {
    checksTriggered++;
  }
}
