// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/server_capabilities_computer.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializationTest);
  });
}

@reflectiveTest
class InitializationTest extends AbstractLspAnalysisServerTest {
  TextDocumentRegistrationOptions registrationOptionsFor(
    List<Registration> registrations,
    Method method,
  ) {
    return TextDocumentRegistrationOptions.fromJson(
        registrationFor(registrations, method)?.registerOptions);
  }

  Future<void> test_dynamicRegistration_containsAppropriateSettings() async {
    // Basic check that the server responds with the capabilities we'd expect,
    // for ex including analysis_options.yaml in text synchronization but not
    // for hovers.
    final registrations = <Registration>[];
    final initResponse = await monitorDynamicRegistrations(
      registrations,
      () => initialize(
        // Support dynamic registration for both text sync + hovers.
        textDocumentCapabilities: withTextSyncDynamicRegistration(
            withHoverDynamicRegistration(emptyTextDocumentClientCapabilities)),
        // And also file operations.
        workspaceCapabilities: withFileOperationDynamicRegistration(
            emptyWorkspaceClientCapabilities),
      ),
    );

    // Because we support dynamic registration for synchronization, we won't send
    // static registrations for them.
    // https://github.com/dart-lang/sdk/issues/38490
    final initResult = InitializeResult.fromJson(initResponse.result);
    expect(initResult.serverInfo.name, 'Dart SDK LSP Analysis Server');
    expect(initResult.serverInfo.version, isNotNull);
    expect(initResult.capabilities, isNotNull);
    expect(initResult.capabilities.textDocumentSync, isNull);

    // Should contain Hover, DidOpen, DidClose, DidChange, WillRenameFiles.
    expect(registrations, hasLength(5));
    final hover =
        registrationOptionsFor(registrations, Method.textDocument_hover);
    final change =
        registrationOptionsFor(registrations, Method.textDocument_didChange);
    final rename = FileOperationRegistrationOptions.fromJson(
        registrationFor(registrations, Method.workspace_willRenameFiles)
            ?.registerOptions);
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

    expect(rename,
        equals(ServerCapabilitiesComputer.fileOperationRegistrationOptions));
  }

  Future<void> test_dynamicRegistration_notSupportedByClient() async {
    // If the client doesn't send any dynamicRegistration settings then there
    // should be no `client/registerCapability` calls.

    // Set a flag if any registerCapability request comes through.
    var didGetRegisterCapabilityRequest = false;
    requestsFromServer
        .where((n) => n.method == Method.client_registerCapability)
        .listen((_) => didGetRegisterCapabilityRequest = true);

    // Initialize with no dynamic registrations advertised.
    final initResponse = await initialize();
    await pumpEventQueue();

    final initResult = InitializeResult.fromJson(initResponse.result);
    expect(initResult.capabilities, isNotNull);
    // When dynamic registration is not supported, we will always statically
    // request text document open/close and incremental updates.
    expect(initResult.capabilities.textDocumentSync, isNotNull);
    initResult.capabilities.textDocumentSync.map(
      (options) {
        expect(options.openClose, isTrue);
        expect(options.change, equals(TextDocumentSyncKind.Incremental));
      },
      (_) =>
          throw 'Expected textDocumentSync capabilities to be a $TextDocumentSyncOptions',
    );
    expect(initResult.capabilities.completionProvider, isNotNull);
    expect(initResult.capabilities.hoverProvider, isNotNull);
    expect(initResult.capabilities.signatureHelpProvider, isNotNull);
    expect(initResult.capabilities.referencesProvider, isNotNull);
    expect(initResult.capabilities.documentHighlightProvider, isNotNull);
    expect(initResult.capabilities.documentFormattingProvider, isNotNull);
    expect(initResult.capabilities.documentOnTypeFormattingProvider, isNotNull);
    expect(initResult.capabilities.documentRangeFormattingProvider, isNotNull);
    expect(initResult.capabilities.definitionProvider, isNotNull);
    expect(initResult.capabilities.codeActionProvider, isNotNull);
    expect(initResult.capabilities.renameProvider, isNotNull);
    expect(initResult.capabilities.foldingRangeProvider, isNotNull);
    expect(initResult.capabilities.workspace.fileOperations.willRename,
        equals(ServerCapabilitiesComputer.fileOperationRegistrationOptions));
    expect(initResult.capabilities.semanticTokensProvider, isNotNull);

    expect(didGetRegisterCapabilityRequest, isFalse);
  }

  Future<void> test_dynamicRegistration_onlyForClientSupportedMethods() async {
    // Check that when the server calls client/registerCapability it only includes
    // the items we advertised dynamic registration support for.
    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      () => initialize(
          textDocumentCapabilities: withHoverDynamicRegistration(
              emptyTextDocumentClientCapabilities)),
    );

    expect(registrations, hasLength(1));
    expect(registrations.single.method,
        equals(Method.textDocument_hover.toJson()));
  }

  Future<void> test_dynamicRegistration_suppressesStaticRegistration() async {
    // If the client sends dynamicRegistration settings then there
    // should not be static registrations for the same capabilities.
    final registrations = <Registration>[];
    final initResponse = await monitorDynamicRegistrations(
      registrations,
      () => initialize(
        // Support dynamic registration for everything we support.
        textDocumentCapabilities:
            withAllSupportedTextDocumentDynamicRegistrations(
                emptyTextDocumentClientCapabilities),
        workspaceCapabilities: withAllSupportedWorkspaceDynamicRegistrations(
            emptyWorkspaceClientCapabilities),
      ),
    );

    final initResult = InitializeResult.fromJson(initResponse.result);
    expect(initResult.capabilities, isNotNull);

    // Ensure no static registrations. This list should include all server equivilents
    // of the dynamic registrations listed in `ClientDynamicRegistrations.supported`.
    expect(initResult.capabilities.textDocumentSync, isNull);
    expect(initResult.capabilities.completionProvider, isNull);
    expect(initResult.capabilities.hoverProvider, isNull);
    expect(initResult.capabilities.signatureHelpProvider, isNull);
    expect(initResult.capabilities.referencesProvider, isNull);
    expect(initResult.capabilities.documentHighlightProvider, isNull);
    expect(initResult.capabilities.documentFormattingProvider, isNull);
    expect(initResult.capabilities.documentOnTypeFormattingProvider, isNull);
    expect(initResult.capabilities.documentRangeFormattingProvider, isNull);
    expect(initResult.capabilities.definitionProvider, isNull);
    expect(initResult.capabilities.codeActionProvider, isNull);
    expect(initResult.capabilities.renameProvider, isNull);
    expect(initResult.capabilities.foldingRangeProvider, isNull);
    expect(initResult.capabilities.workspace.fileOperations, isNull);
    expect(initResult.capabilities.semanticTokensProvider, isNull);

    // Ensure all expected dynamic registrations.
    for (final expectedRegistration in ClientDynamicRegistrations.supported) {
      final registration =
          registrationOptionsFor(registrations, expectedRegistration);
      expect(registration, isNotNull,
          reason: 'Missing dynamic registration for $expectedRegistration');
    }
  }

  Future<void> test_dynamicRegistration_unregistersOutdatedAfterChange() async {
    // Initialize by supporting dynamic registrations everywhere
    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      () => initialize(
          textDocumentCapabilities:
              withAllSupportedTextDocumentDynamicRegistrations(
                  emptyTextDocumentClientCapabilities)),
    );

    final unregisterRequest =
        await expectRequest(Method.client_unregisterCapability, () {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin)
        ..interestingFiles = ['*.foo'];
      pluginManager.pluginsChangedController.add(null);
    });
    final unregistrations =
        UnregistrationParams.fromJson(unregisterRequest.params)
            .unregisterations;

    // folding method should have been unregistered as the server now supports
    // *.foo files for it as well.
    final registrationIdForFolding = registrations
        .singleWhere((r) => r.method == 'textDocument/foldingRange')
        .id;
    expect(
      unregistrations,
      contains(isA<Unregistration>()
          .having((r) => r.method, 'method', 'textDocument/foldingRange')
          .having((r) => r.id, 'id', registrationIdForFolding)),
    );
  }

  Future<void> test_dynamicRegistration_updatesWithPlugins() async {
    await initialize(
      textDocumentCapabilities:
          extendTextDocumentCapabilities(emptyTextDocumentClientCapabilities, {
        'foldingRange': {'dynamicRegistration': true},
      }),
    );

    // The server will send an unregister request followed by another register
    // request to change document filter on folding. We need to respond to the
    // unregister request as the server awaits that.
    requestsFromServer
        .firstWhere((r) => r.method == Method.client_unregisterCapability)
        .then((request) {
      respondTo(request, null);
      return UnregistrationParams.fromJson(request.params).unregisterations;
    });

    final request = await expectRequest(Method.client_registerCapability, () {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin)
        ..interestingFiles = ['*.sql'];
      pluginManager.pluginsChangedController.add(null);
    });

    final registrations =
        RegistrationParams.fromJson(request.params).registrations;

    final documentFilterSql =
        DocumentFilter(scheme: 'file', pattern: '**/*.sql');
    final documentFilterDart = DocumentFilter(language: 'dart', scheme: 'file');

    expect(
      registrations,
      contains(isA<Registration>()
          .having((r) => r.method, 'method', 'textDocument/foldingRange')
          .having(
            (r) => TextDocumentRegistrationOptions.fromJson(r.registerOptions)
                .documentSelector,
            'registerOptions.documentSelector',
            containsAll([documentFilterSql, documentFilterDart]),
          )),
    );
  }

  Future<void> test_emptyAnalysisRoots_multipleOpenFiles() async {
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = Uri.file(file1);
    newFile(file1);
    final file2 = join(projectFolderPath, 'file2.dart');
    final file2Uri = Uri.file(file2);
    newFile(file2);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    newFile(pubspecPath);

    await initialize(allowEmptyRootUri: true);

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

  Future<void> test_emptyAnalysisRoots_projectWithoutPubspec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    // The project folder shouldn't be added to start with.
    await initialize(allowEmptyRootUri: true);
    expect(server.contextManager.includedPaths, equals([]));

    // Opening the file should trigger the immediate parent folder to be added.
    await openFile(nestedFileUri, '');
    expect(server.contextManager.includedPaths,
        equals([path.dirname(nestedFilePath)]));
  }

  Future<void> test_emptyAnalysisRoots_projectWithPubspec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    newFile(pubspecPath);

    // The project folder shouldn't be added to start with.
    await initialize(allowEmptyRootUri: true);
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

  Future<void> test_excludedFolders_absolute() async {
    final excludedFolderPath = join(projectFolderPath, 'excluded');

    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      // Exclude the folder with a relative path.
      {
        'analysisExcludedFolders': [excludedFolderPath]
      },
    );
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.excludedPaths, equals([excludedFolderPath]));
  }

  Future<void> test_excludedFolders_nonList() async {
    final excludedFolderPath = join(projectFolderPath, 'excluded');

    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      // Include a single string instead of an array since it's an easy mistake
      // to make without editor validation of settings.
      {'analysisExcludedFolders': 'excluded'},
    );
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.excludedPaths, equals([excludedFolderPath]));
  }

  Future<void> test_excludedFolders_relative() async {
    final excludedFolderPath = join(projectFolderPath, 'excluded');

    await provideConfig(
      () => initialize(
          workspaceCapabilities:
              withConfigurationSupport(emptyWorkspaceClientCapabilities)),
      // Exclude the folder with a relative path.
      {
        'analysisExcludedFolders': ['excluded']
      },
    );
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.excludedPaths, equals([excludedFolderPath]));
  }

  Future<void> test_initialize() async {
    final response = await initialize();
    expect(response, isNotNull);
    expect(response.error, isNull);
    expect(response.result, isNotNull);
    expect(InitializeResult.canParse(response.result, nullLspJsonReporter),
        isTrue);
    final result = InitializeResult.fromJson(response.result);
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

  Future<void> test_initialize_invalidParams() async {
    final params = {'processId': 'invalid'};
    final request = RequestMessage(
      id: Either2<num, String>.t1(1),
      method: Method.initialize,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    final response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.error.code, equals(ErrorCodes.InvalidParams));
    expect(response.result, isNull);
  }

  Future<void> test_initialize_onlyAllowedOnce() async {
    await initialize();
    final response = await initialize(throwOnFailure: false);
    expect(response, isNotNull);
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(
        response.error.code, equals(ServerErrorCodes.ServerAlreadyInitialized));
  }

  Future<void> test_initialize_rootPath() async {
    await initialize(rootPath: projectFolderPath);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_rootUri() async {
    await initialize(rootUri: projectFolderUri);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_workspaceFolders() async {
    await initialize(workspaceFolders: [projectFolderUri]);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_multipleFiles() async {
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = Uri.file(file1);
    newFile(file1);
    final file2 = join(projectFolderPath, 'file2.dart');
    final file2Uri = Uri.file(file2);
    newFile(file2);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    newFile(pubspecPath);

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

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_withoutPubpsec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    // The project folder shouldn't be added to start with.
    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Opening the file should trigger the immediate parent folder to be added.
    await openFile(nestedFileUri, '');
    expect(server.contextManager.includedPaths,
        equals([path.dirname(nestedFilePath)]));
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_withPubpsec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);
    final pubspecPath = join(projectFolderPath, 'pubspec.yaml');
    newFile(pubspecPath);

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

  Future<void> test_uninitialized_dropsNotifications() async {
    final notification =
        makeNotification(Method.fromJson('randomNotification'), null);
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

  Future<void> test_uninitialized_rejectsRequests() async {
    final request = makeRequest(Method.fromJson('randomRequest'), null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error.code, ErrorCodes.ServerNotInitialized);
  }
}
