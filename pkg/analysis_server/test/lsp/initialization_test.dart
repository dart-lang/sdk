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

    // Ensure the file was cached in each driver. This happens as a result of
    // adding to priority files, but if that's done before the file is in an
    // analysis root it will not occur.
    // https://github.com/dart-lang/sdk/issues/37338
    server.driverMap.values.forEach((driver) {
      expect(driver.getCachedResult(nestedFilePath), isNotNull);
    });

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
        return null;
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

  test_dynamicRegistration_notSupportedByClient() async {
    // If the client doesn't send any dynamicRegistration settings then there
    // should be no `client/registerCapability` calls.

    // Set a flag if any registerCapability request comes through.
    bool didGetRegisterCapabilityRequest = false;
    requestsFromServer
        .firstWhere((n) => n.method == Method.client_registerCapability)
        .then((params) {
      didGetRegisterCapabilityRequest = true;
    });

    // Initialize with no dynamic registrations advertised.
    await initialize();
    await pumpEventQueue();

    expect(didGetRegisterCapabilityRequest, isFalse);
  }

  test_dynamicRegistration_onlyForClientSupportedMethods() async {
    // Check that when the server calls client/registerCapability it only includes
    // the items we advertised dynamic registration support for.
    List<Registration> registrations;
    await handleExpectedRequest<void, RegistrationParams, void>(
      Method.client_registerCapability,
      () => initialize(
          textDocumentCapabilities: withHoverDynamicRegistration(
              emptyTextDocumentClientCapabilities)),
      handler: (registrationParams) =>
          registrations = registrationParams.registrations,
    );

    expect(registrations, hasLength(1));
    expect(registrations.single.method,
        equals(Method.textDocument_hover.toJson()));
  }

  test_dynamicRegistration_containsAppropriateSettings() async {
    // Basic check that the server responds with the capabilities we'd expect,
    // for ex including analysis_options.yaml in text synchronization but not
    // for hovers.
    List<Registration> registrations;
    await handleExpectedRequest<void, RegistrationParams, void>(
      Method.client_registerCapability,
      () => initialize(
          // Support dynamic registration for both text sync + hovers.
          textDocumentCapabilities: withTextSyncDynamicRegistration(
              withHoverDynamicRegistration(
                  emptyTextDocumentClientCapabilities))),
      handler: (registrationParams) =>
          registrations = registrationParams.registrations,
    );

    // Should container Hover, DidOpen, DidClose, DidChange.
    expect(registrations, hasLength(4));
    final hover =
        registrationOptionsFor(registrations, Method.textDocument_hover);
    final change =
        registrationOptionsFor(registrations, Method.textDocument_didChange);
    expect(registrationOptionsFor(registrations, Method.textDocument_didOpen),
        isNotNull);
    expect(registrationOptionsFor(registrations, Method.textDocument_didClose),
        isNotNull);

    // The hover capability should only specific Dart.
    expect(hover, isNotNull);
    expect(hover.documentSelector, hasLength(1));
    expect(hover.documentSelector.single.language, equals('dart'));

    // didChange should also include pubspec + analysis_options.
    expect(change, isNotNull);
    expect(change.documentSelector, hasLength(greaterThanOrEqualTo(3)));
    expect(change.documentSelector.any((ds) => ds.language == 'dart'), isTrue);
    expect(change.documentSelector.any((ds) => ds.pattern == '**/pubspec.yaml'),
        isTrue);
    expect(
        change.documentSelector
            .any((ds) => ds.pattern == '**/analysis_options.yaml'),
        isTrue);
  }

  TextDocumentRegistrationOptions registrationOptionsFor(
    List<Registration> registrations,
    Method method,
  ) {
    return registrations
        .singleWhere((r) => r.method == method.toJson(), orElse: () => null)
        ?.registerOptions;
  }
}
