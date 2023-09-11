// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/server_capabilities_computer.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializationTest);
    defineReflectiveTests(SlowInitializationTest);
  });
}

@reflectiveTest
class InitializationTest extends AbstractLspAnalysisServerTest {
  /// Waits for any in-progress analysis context rebuild.
  ///
  /// Pumps the event queue before and after, to ensure any server code that
  /// runs after the rebuild has had chance to run.
  Future<void> get contextRebuildComplete async {
    await pumpEventQueue(times: 5000);
    await server.analysisContextsRebuilt;
    await pumpEventQueue(times: 5000);
  }

  Future<void> assertDynamicRegistration(
      String name, Set<Method> expectedResult) async {
    setTextDocumentDynamicRegistration(name);
    setWorkspaceDynamicRegistration(name);

    // Check that when the server calls client/registerCapability it only includes
    // the items we advertised dynamic registration support for.
    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      initialize,
    );

    final registeredMethods =
        registrations.map((registration) => registration.method).toSet();
    final result = expectedResult.map((method) => method.toJson()).toSet();

    expect(registeredMethods, equals(result));
  }

  TextDocumentRegistrationOptions registrationOptionsFor(
    List<Registration> registrations,
    Method method,
  ) {
    final options = registrationFor(registrations, method)?.registerOptions;
    if (options == null) {
      throw 'Registration options for $method were not found. '
          'Perhaps dynamicRegistration is missing from '
          'withAllSupportedTextDocumentDynamicRegistrations?';
    }
    return TextDocumentRegistrationOptions.fromJson(
        options as Map<String, Object?>);
  }

  Future<void> test_blazeWorkspace() async {
    var workspacePath = '/home/user/ws';
    // Make it a Blaze workspace.
    newFile('$workspacePath/${file_paths.blazeWorkspaceMarker}', '');

    var packagePath = '$workspacePath/team/project1';

    // Make it a Blaze project.
    newFile(convertPath('$packagePath/BUILD'), '');

    final file1 = convertPath('$packagePath/lib/file1.dart');
    newFile(file1, '');

    await initialize(allowEmptyRootUri: true);

    // Expect that context manager includes a whole package.
    await openFile(pathContext.toUri(file1), '');
    expect(server.contextManager.includedPaths,
        equals([convertPath(packagePath)]));
  }

  Future<void> test_completionRegistrations_triggerCharacters() async {
    // Support dynamic registration for everything we support.
    setAllSupportedTextDocumentDynamicRegistrations();
    setAllSupportedWorkspaceDynamicRegistrations();

    final registrations = <Registration>[];
    final initResponse = await monitorDynamicRegistrations(
      registrations,
      () => initialize(),
    );

    final initResult =
        InitializeResult.fromJson(initResponse.result as Map<String, Object?>);
    expect(initResult.capabilities, isNotNull);

    // Check Dart-only registration.
    final dartRegistration =
        registrationForDart(registrations, Method.textDocument_completion);
    final dartOptions = CompletionRegistrationOptions.fromJson(
        dartRegistration.registerOptions as Map<String, Object?>);
    expect(dartOptions.documentSelector, hasLength(1));
    expect(dartOptions.documentSelector![0].language, dartLanguageId);
    expect(dartOptions.triggerCharacters, isNotEmpty);

    // Check non-Dart registration.
    final nonDartRegistration = registrations.singleWhere((r) =>
        r.method == Method.textDocument_completion.toJson() &&
        r != dartRegistration);
    final nonDartOptions = CompletionRegistrationOptions.fromJson(
        nonDartRegistration.registerOptions as Map<String, Object?>);
    final otherLanguages = nonDartOptions.documentSelector!
        .map((selector) => selector.language)
        .toList();
    expect(otherLanguages, isNot(contains('dart')));
    expect(nonDartOptions.triggerCharacters, isNull);
  }

  Future<void> test_completionRegistrations_withDartPlugin() async {
    if (!AnalysisServer.supportsPlugins) return;

    // This tests for a bug that occurred with an analysis server plugin
    // that works on Dart files. When computing completion registrations we
    // usually have separate registrations for Dart + non-Dart to account for
    // different trigger characters. However, the plugin types were all being
    // included in the non-Dart registration even if they included Dart.
    //
    // The result was two registrations including Dart, which caused duplicate
    // requests for Dart completions, which resulted in duplicate items
    // appearing in the editor.

    setAllSupportedTextDocumentDynamicRegistrations();

    // Track all current registrations.
    final registrations = <Registration>[];

    // Perform normal registration (without plugins) to get the initial set.
    await monitorDynamicRegistrations(registrations, initialize);

    // Expect only a single registration that includes Dart files.
    expect(
      registrationsForDart(registrations, Method.textDocument_completion),
      hasLength(1),
    );

    // Monitor the unregistration/new registrations during the plugin activation.
    await monitorDynamicReregistration(registrations, () async {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin)
        ..interestingFiles = ['*.dart'];
      pluginManager.pluginsChangedController.add(null);
    });

    // Expect that there is still only a single registration for Dart.
    expect(
      registrationsForDart(registrations, Method.textDocument_completion),
      hasLength(1),
    );
  }

  Future<void> test_dynamicRegistration_areNotInterleaved() async {
    if (!AnalysisServer.supportsPlugins) return;

    // Some of the issues in https://github.com/dart-lang/sdk/issues/47851
    // (duplicate hovers/code actions/etc.) were caused by duplicate
    // registrations. This happened when we tried to rebuild registrations
    // concurrently as the code would:
    //
    // 1. compute the new set of registrations
    // 2. compute which had changed
    // 3. send _and await_ the unregistration
    // 4. send _and await_ the new registration
    //
    // If the code was triggered multiple times concurrently, it was possible
    // for step 3 in second request to occur before step 4 in the first, which
    // would result in unregistrations being sent for registrations that had
    // not been sent. They would be silently dropped, and then we'd end up with
    // multiple registrations.
    //
    // This test triggers the rebuild via pluginManager.pluginsChangedController
    // multiple times and ensures the events all arrive in the correct order,
    // that is, no unregistration ever contains the ID of something that is not
    // currently registered.

    setAllSupportedTextDocumentDynamicRegistrations();

    final registrations = <Registration>[];
    await monitorDynamicRegistrations(registrations, initialize);

    final knownRegistrationsIds =
        registrations.map((registration) => registration.id).toSet();

    final numberOfReregistrations = 10;

    // Listen to incoming registrations, ensure they're not in the set, and add
    // them.
    final registrationsDone = requestsFromServer
        .where((n) => n.method == Method.client_registerCapability)
        .take(numberOfReregistrations)
        .listen((request) {
      respondTo(request, null);
      final registrations =
          RegistrationParams.fromJson(request.params as Map<String, Object?>)
              .registrations;
      for (final registration in registrations) {
        final id = registration.id;
        if (!knownRegistrationsIds.add(id)) {
          throw 'Registration $id was already in the existing set!';
        }
      }
    }).asFuture();

    // Listen to incoming unregistrations, verify they're in the set, and remove
    // them.
    final unregistrationsDone = requestsFromServer
        .where((n) => n.method == Method.client_unregisterCapability)
        .take(numberOfReregistrations)
        .listen((request) {
      respondTo(request, null);
      final unregistrations =
          UnregistrationParams.fromJson(request.params as Map<String, Object?>)
              .unregisterations;
      for (final unregistration in unregistrations) {
        final id = unregistration.id;
        if (!knownRegistrationsIds.remove(id)) {
          throw 'Registration $id was not in the existing set!';
        }
      }
    }).asFuture();

    // Trigger multiple plugin events that will rebuild the registrations.
    for (var i = 0; i < numberOfReregistrations; i++) {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin);
      // Ensure they have different file types so the registrations change,
      // otherwise they will be optimised out as not changing.
      plugin.currentSession!.interestingFiles = ['*.foo$i'];
      pluginManager.pluginsChangedController.add(null);
      await null; // Allow the server to begin processing the change.
    }

    // Wait for both streams to have handled all of the numberOfReregistrations
    // expected events (without throwing).
    await Future.wait([registrationsDone, unregistrationsDone]);
  }

  Future<void> test_dynamicRegistration_config_allHierarchy() =>
      assertDynamicRegistration(
          'callHierarchy', {Method.textDocument_prepareCallHierarchy});

  Future<void> test_dynamicRegistration_config_codeAction() =>
      assertDynamicRegistration('codeAction', {Method.textDocument_codeAction});

  Future<void> test_dynamicRegistration_config_colorProvider() =>
      assertDynamicRegistration(
          'colorProvider', {Method.textDocument_documentColor});

  Future<void> test_dynamicRegistration_config_completion() =>
      assertDynamicRegistration('completion', {Method.textDocument_completion});

  Future<void> test_dynamicRegistration_config_definition() =>
      assertDynamicRegistration('definition', {Method.textDocument_definition});

  Future<void> test_dynamicRegistration_config_didChangeConfiguration() =>
      assertDynamicRegistration(
          'didChangeConfiguration', {Method.workspace_didChangeConfiguration});

  Future<void> test_dynamicRegistration_config_documentHighlight() =>
      assertDynamicRegistration(
          'documentHighlight', {Method.textDocument_documentHighlight});

  Future<void> test_dynamicRegistration_config_documentSymbol() =>
      assertDynamicRegistration(
          'documentSymbol', {Method.textDocument_documentSymbol});

  Future<void> test_dynamicRegistration_config_fileOperations() =>
      assertDynamicRegistration(
          'fileOperations', {Method.workspace_willRenameFiles});

  Future<void> test_dynamicRegistration_config_foldingRange() =>
      assertDynamicRegistration(
          'foldingRange', {Method.textDocument_foldingRange});

  Future<void> test_dynamicRegistration_config_formatting() =>
      assertDynamicRegistration('formatting', {Method.textDocument_formatting});

  Future<void> test_dynamicRegistration_config_hover() =>
      assertDynamicRegistration('hover', {Method.textDocument_hover});

  Future<void> test_dynamicRegistration_config_implementation() =>
      assertDynamicRegistration(
          'implementation', {Method.textDocument_implementation});

  Future<void> test_dynamicRegistration_config_inlayHint() =>
      assertDynamicRegistration('inlayHint', {Method.textDocument_inlayHint});

  Future<void> test_dynamicRegistration_config_onTypeFormatting() =>
      assertDynamicRegistration(
          'onTypeFormatting', {Method.textDocument_onTypeFormatting});

  Future<void> test_dynamicRegistration_config_rangeFormatting() =>
      assertDynamicRegistration(
          'rangeFormatting', {Method.textDocument_rangeFormatting});

  Future<void> test_dynamicRegistration_config_references() =>
      assertDynamicRegistration('references', {Method.textDocument_references});

  Future<void> test_dynamicRegistration_config_rename() =>
      assertDynamicRegistration('rename', {Method.textDocument_rename});

  Future<void> test_dynamicRegistration_config_selectionRange() =>
      assertDynamicRegistration(
          'selectionRange', {Method.textDocument_selectionRange});

  Future<void> test_dynamicRegistration_config_semanticTokens() =>
      assertDynamicRegistration(
          'semanticTokens', {CustomMethods.semanticTokenDynamicRegistration});

  Future<void> test_dynamicRegistration_config_signatureHelp() =>
      assertDynamicRegistration(
          'signatureHelp', {Method.textDocument_signatureHelp});

  Future<void> test_dynamicRegistration_config_synchronization() =>
      assertDynamicRegistration('synchronization', {
        Method.textDocument_didOpen,
        Method.textDocument_didChange,
        Method.textDocument_didClose
      });

  Future<void> test_dynamicRegistration_config_typeDefinition() =>
      assertDynamicRegistration(
          'typeDefinition', {Method.textDocument_typeDefinition});

  Future<void> test_dynamicRegistration_config_typeHierarchy() =>
      assertDynamicRegistration(
          'typeHierarchy', {Method.textDocument_prepareTypeHierarchy});

  Future<void> test_dynamicRegistration_containsAppropriateSettings() async {
    // Support file operations.
    setFileOperationDynamicRegistration();
    // Support dynamic registration for both text sync + hovers.
    setTextSyncDynamicRegistration();
    setHoverDynamicRegistration();

    // Basic check that the server responds with the capabilities we'd expect,
    // for ex including analysis_options.yaml in text synchronization but not
    // for hovers.
    final registrations = <Registration>[];
    final initResponse = await monitorDynamicRegistrations(
      registrations,
      initialize,
    );

    // Because we support dynamic registration for synchronization, we won't send
    // static registrations for them.
    // https://github.com/dart-lang/sdk/issues/38490
    final initResult =
        InitializeResult.fromJson(initResponse.result as Map<String, Object?>);
    expect(initResult.serverInfo!.name, 'Dart SDK LSP Analysis Server');
    expect(initResult.serverInfo!.version, isNotNull);
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
            ?.registerOptions as Map<String, Object?>);
    expect(registrationOptionsFor(registrations, Method.textDocument_didOpen),
        isNotNull);
    expect(registrationOptionsFor(registrations, Method.textDocument_didClose),
        isNotNull);

    // The hover capability should only specific Dart.
    expect(hover, isNotNull);
    expect(hover.documentSelector, hasLength(1));
    expect(hover.documentSelector!.single.language, equals('dart'));

    // didChange should also include pubspec + analysis_options.
    expect(change, isNotNull);
    expect(change.documentSelector, hasLength(greaterThanOrEqualTo(3)));
    expect(change.documentSelector!.any((ds) => ds.language == 'dart'), isTrue);
    expect(
        change.documentSelector!.any((ds) => ds.pattern == '**/pubspec.yaml'),
        isTrue);
    expect(
        change.documentSelector!
            .any((ds) => ds.pattern == '**/analysis_options.yaml'),
        isTrue);

    expect(rename, equals(fileOperationRegistrationOptions));
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

    final initResult =
        InitializeResult.fromJson(initResponse.result as Map<String, Object?>);
    expect(initResult.capabilities, isNotNull);
    // When dynamic registration is not supported, we will always statically
    // request text document open/close and incremental updates.
    expect(initResult.capabilities.textDocumentSync, isNotNull);
    initResult.capabilities.textDocumentSync!.map(
      (_) =>
          throw 'Expected textDocumentSync capabilities to be a TextDocumentSyncOptions',
      (options) {
        expect(options.openClose, isTrue);
        expect(options.change, equals(TextDocumentSyncKind.Incremental));
      },
    );
    expect(initResult.capabilities.callHierarchyProvider, isNotNull);
    expect(initResult.capabilities.completionProvider, isNotNull);
    expect(initResult.capabilities.hoverProvider, isNotNull);
    expect(initResult.capabilities.signatureHelpProvider, isNotNull);
    expect(initResult.capabilities.referencesProvider, isNotNull);
    expect(initResult.capabilities.colorProvider, isNotNull);
    expect(initResult.capabilities.documentHighlightProvider, isNotNull);
    expect(initResult.capabilities.documentFormattingProvider, isNotNull);
    expect(initResult.capabilities.documentOnTypeFormattingProvider, isNotNull);
    expect(initResult.capabilities.documentRangeFormattingProvider, isNotNull);
    expect(initResult.capabilities.definitionProvider, isNotNull);
    expect(initResult.capabilities.codeActionProvider, isNotNull);
    expect(initResult.capabilities.renameProvider, isNotNull);
    expect(initResult.capabilities.foldingRangeProvider, isNotNull);
    expect(initResult.capabilities.workspace!.fileOperations!.willRename,
        equals(fileOperationRegistrationOptions));
    expect(initResult.capabilities.selectionRangeProvider, isNotNull);
    expect(initResult.capabilities.semanticTokensProvider, isNotNull);

    expect(didGetRegisterCapabilityRequest, isFalse);
  }

  Future<void> test_dynamicRegistration_suppressesStaticRegistration() async {
    // Support dynamic registration for everything we support.
    setAllSupportedTextDocumentDynamicRegistrations();
    setAllSupportedWorkspaceDynamicRegistrations();

    // If the client sends dynamicRegistration settings then there
    // should not be static registrations for the same capabilities.
    final registrations = <Registration>[];
    final initResponse = await monitorDynamicRegistrations(
      registrations,
      initialize,
    );

    final initResult =
        InitializeResult.fromJson(initResponse.result as Map<String, Object?>);
    expect(initResult.capabilities, isNotNull);

    // Ensure no static registrations. This list should include all server equivalents
    // of the dynamic registrations listed in `ClientDynamicRegistrations.supported`.
    expect(initResult.capabilities.textDocumentSync, isNull);
    expect(initResult.capabilities.callHierarchyProvider, isNull);
    expect(initResult.capabilities.completionProvider, isNull);
    expect(initResult.capabilities.hoverProvider, isNull);
    expect(initResult.capabilities.inlayHintProvider, isNull);
    expect(initResult.capabilities.signatureHelpProvider, isNull);
    expect(initResult.capabilities.referencesProvider, isNull);
    expect(initResult.capabilities.colorProvider, isNull);
    expect(initResult.capabilities.documentHighlightProvider, isNull);
    expect(initResult.capabilities.documentFormattingProvider, isNull);
    expect(initResult.capabilities.documentOnTypeFormattingProvider, isNull);
    expect(initResult.capabilities.documentRangeFormattingProvider, isNull);
    expect(initResult.capabilities.definitionProvider, isNull);
    expect(initResult.capabilities.codeActionProvider, isNull);
    expect(initResult.capabilities.renameProvider, isNull);
    expect(initResult.capabilities.foldingRangeProvider, isNull);
    expect(initResult.capabilities.workspace!.fileOperations, isNull);
    expect(initResult.capabilities.selectionRangeProvider, isNull);
    expect(initResult.capabilities.semanticTokensProvider, isNull);

    // Ensure all expected dynamic registrations.
    for (final expectedRegistration in ClientDynamicRegistrations.supported) {
      // We have two completion registrations (to handle different trigger
      // characters), so exclude that here and check it manually below.
      if (expectedRegistration == Method.textDocument_completion) {
        continue;
      }

      final registration =
          registrationOptionsFor(registrations, expectedRegistration);
      expect(registration, isNotNull,
          reason: 'Missing dynamic registration for $expectedRegistration');
    }

    // Check the were two completion registrations.
    final completionRegistrations = registrations
        .where((reg) => reg.method == Method.textDocument_completion.toJson());
    expect(completionRegistrations, hasLength(2));
  }

  Future<void> test_dynamicRegistration_unregistersOutdatedAfterChange() async {
    if (!AnalysisServer.supportsPlugins) return;

    // Initialize by supporting dynamic registrations everywhere
    setAllSupportedTextDocumentDynamicRegistrations();

    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      initialize,
    );

    final unregisterRequest =
        await expectRequest(Method.client_unregisterCapability, () {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin)
        ..interestingFiles = ['*.foo'];
      pluginManager.pluginsChangedController.add(null);
    });
    final unregistrations = UnregistrationParams.fromJson(
            unregisterRequest.params as Map<String, Object?>)
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
    if (!AnalysisServer.supportsPlugins) return;
    setTextDocumentDynamicRegistration('foldingRange');
    await initialize();

    // The server will send an unregister request followed by another register
    // request to change document filter on folding. We need to respond to the
    // unregister request as the server awaits that.
    // This is set up as a future callback and should not be awaited here.
    unawaited(requestsFromServer
        .firstWhere((r) => r.method == Method.client_unregisterCapability)
        .then((request) {
      respondTo(request, null);
    }));

    final request = await expectRequest(Method.client_registerCapability, () {
      final plugin = configureTestPlugin();
      plugin.currentSession = PluginSession(plugin)
        ..interestingFiles = ['*.sql'];
      pluginManager.pluginsChangedController.add(null);
    });

    final registrations =
        RegistrationParams.fromJson(request.params as Map<String, Object?>)
            .registrations;

    final documentFilterSql =
        TextDocumentFilterWithScheme(scheme: 'file', pattern: '**/*.sql');
    final documentFilterDart =
        TextDocumentFilterWithScheme(language: 'dart', scheme: 'file');

    expect(
      registrations,
      contains(isA<Registration>()
          .having((r) => r.method, 'method', 'textDocument/foldingRange')
          .having(
            (r) => TextDocumentRegistrationOptions.fromJson(
                    r.registerOptions as Map<String, Object?>)
                .documentSelector,
            'registerOptions.documentSelector',
            containsAll([documentFilterSql, documentFilterDart]),
          )),
    );
  }

  /// Tests that when there are no explicit analysis roots (instead they are
  /// implied by open files), requests for open files are successful even if
  /// sent _immediately_ after opening the file.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/3929
  ///
  /// This test uses getDocumentSymbols which requires a resolved result.
  Future<void>
      test_emptyAnalysisRoots_handlesFileRequestsImmediately_resolved() async {
    const content = 'void f() {}';
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = pathContext.toUri(file1);
    newFile(file1, content);
    newPubspecYamlFile(projectFolderPath, '');

    await initialize(allowEmptyRootUri: true);

    unawaited(openFile(file1Uri, content)); // Don't wait
    final result = await getDocumentSymbols(file1Uri);
    final symbols = result.map(
      (docSymbols) => docSymbols,
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(1));
  }

  /// Tests that when there are no explicit analysis roots (instead they are
  /// implied by open files), requests for open files are successful even if
  /// sent _immediately_ after opening the file.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/3929
  ///
  /// This test uses getSelectionRanges which requires only a parsed result.
  Future<void>
      test_emptyAnalysisRoots_handlesFileRequestsImmediately_unresolved() async {
    const content = 'void f() {}';
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = pathContext.toUri(file1);
    newFile(file1, content);
    newPubspecYamlFile(projectFolderPath, '');

    await initialize(allowEmptyRootUri: true);

    unawaited(openFile(file1Uri, content)); // Don't wait
    final result = await getSelectionRanges(file1Uri, [startOfDocPos]);
    expect(result, hasLength(1));
  }

  Future<void> test_emptyAnalysisRoots_multipleOpenFiles() async {
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = pathContext.toUri(file1);
    newFile(file1, '');
    final file2 = join(projectFolderPath, 'file2.dart');
    final file2Uri = pathContext.toUri(file2);
    newFile(file2, '');
    newPubspecYamlFile(projectFolderPath, '');

    await initialize(allowEmptyRootUri: true);

    // Opening both files should only add the project folder once.
    await openFile(file1Uri, '');
    await openFile(file2Uri, '');
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Closing only one of the files should not remove the project folder
    // since there are still open files.
    resetContextBuildCounter();
    await closeFile(file1Uri);
    await pumpEventQueue(times: 5000);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expectNoContextBuilds();

    // Closing the last file should remove the project folder and remove
    // the context.
    resetContextBuildCounter();
    await closeFile(file2Uri);
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([]));
    expect(server.contextManager.driverMap, hasLength(0));
    expectContextBuilds();
  }

  Future<void> test_emptyAnalysisRoots_projectWithoutPubspec() async {
    projectFolderPath = convertPath('/home/empty');
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = pathContext.toUri(nestedFilePath);
    newFile(nestedFilePath, '');

    // The project folder shouldn't be added to start with.
    await initialize(allowEmptyRootUri: true);
    expect(server.contextManager.includedPaths, equals([]));

    // Opening the file will add a root for it.
    await openFile(nestedFileUri, '');
    expect(server.contextManager.includedPaths, equals([nestedFilePath]));
  }

  Future<void> test_emptyAnalysisRoots_projectWithPubspec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = pathContext.toUri(nestedFilePath);
    newFile(nestedFilePath, '');
    newPubspecYamlFile(projectFolderPath, '');

    // The project folder shouldn't be added to start with.
    await initialize(allowEmptyRootUri: true);
    expect(server.contextManager.includedPaths, equals([]));

    // Opening a file nested within the project should add the project folder.
    await openFile(nestedFileUri, '');
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Ensure the file was cached in each driver. This happens as a result of
    // adding to priority files, but if that's done before the file is in an
    // analysis root it will not occur.
    // https://github.com/dart-lang/sdk/issues/37338
    for (var driver in server.driverMap.values) {
      expect(driver.getCachedResult(nestedFilePath), isNotNull);
    }

    // Closing the file should remove it.
    await closeFile(nestedFileUri);
    expect(server.contextManager.includedPaths, equals([]));
  }

  Future<void> test_excludedFolders_absolute() async {
    final excludedFolderPath = join(projectFolderPath, 'excluded');

    await provideConfig(
      initialize,
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
      initialize,
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
      initialize,
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
    final result =
        InitializeResult.fromJson(response.result as Map<String, Object?>);
    expect(result.capabilities, isNotNull);
    // Check some basic capabilities that are unlikely to change.
    expect(result.capabilities.textDocumentSync, isNotNull);
    result.capabilities.textDocumentSync!.map(
      (_) =>
          throw 'Expected textDocumentSync capabilities to be a TextDocumentSyncOptions',
      (options) {
        // We'll always request open/closed notifications and incremental updates.
        expect(options.openClose, isTrue);
        expect(options.change, equals(TextDocumentSyncKind.Incremental));
      },
    );
  }

  Future<void> test_initialize_invalidParams() async {
    final params = {'processId': 'invalid'};
    final request = RequestMessage(
      id: Either2<int, String>.t1(1),
      method: Method.initialize,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    final response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.error!.code, equals(ErrorCodes.InvalidParams));
    expect(response.result, isNull);
  }

  Future<void> test_initialize_onlyAllowedOnce() async {
    await initialize();
    final response = await initialize(throwOnFailure: false);
    expect(response, isNotNull);
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error!.code,
        equals(ServerErrorCodes.ServerAlreadyInitialized));
  }

  Future<void> test_initialize_rootPath() async {
    await initialize(rootPath: projectFolderPath);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_rootPath_trailingSlash() async {
    await initialize(rootPath: withTrailingSlash(projectFolderPath));
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_rootUri() async {
    await initialize(rootUri: projectFolderUri);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_rootUri_encodedDriveLetterColon() async {
    await initialize(rootUri: withEncodedDriveLetterColon(projectFolderUri));
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_rootUri_trailingSlash() async {
    await initialize(rootUri: withTrailingSlashUri(projectFolderUri));
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_workspaceFolders() async {
    await initialize(workspaceFolders: [projectFolderUri]);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void>
      test_initialize_workspaceFolders_encodedDriveLetterColon() async {
    await initialize(
        workspaceFolders: [withEncodedDriveLetterColon(projectFolderUri)]);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_initialize_workspaceFolders_trailingSlash() async {
    await initialize(
        workspaceFolders: [withTrailingSlashUri(projectFolderUri)]);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_nonFileScheme_rootUri() async {
    final rootUri = Uri.parse('vsls://');
    final fileUri = rootUri.replace(path: '/file1.dart');

    await initialize(
      rootUri: rootUri,
      // We expect an error notification about the invalid file we try to open.
      failTestOnAnyErrorNotification: false,
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Also open a non-file file to ensure it doesn't cause the root to be added.
    await openFile(fileUri, '');
    expect(server.contextManager.includedPaths, equals([]));
  }

  Future<void> test_nonFileScheme_workspaceFolders() async {
    newPubspecYamlFile(projectFolderPath, '');

    final rootUri = Uri.parse('vsls://');
    final fileUri = rootUri.replace(path: '/file1.dart');

    await initialize(
      workspaceFolders: [
        rootUri,
        pathContext.toUri(projectFolderPath),
      ],
      // We expect an error notification about the invalid file we try to open.
      failTestOnAnyErrorNotification: false,
    );
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Also open a non-file file to ensure it doesn't cause the root to be added.
    await openFile(fileUri, '');
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
  }

  Future<void> test_nonProjectFiles_basicWorkspace() async {
    final file1 = convertPath('/home/nonProject/file1.dart');
    newFile(file1, '');

    await initialize(allowEmptyRootUri: true);

    // Because the file is not in a project, it should be added itself.
    await openFile(pathContext.toUri(file1), '');
    expect(server.contextManager.includedPaths, equals([file1]));
  }

  Future<void> test_nonProjectFiles_blazeWorkspace() async {
    final file1 = convertPath('/home/nonProject/file1.dart');
    newFile(file1, '');

    // Make /home a Blaze workspace.
    newFile('/home/${file_paths.blazeWorkspaceMarker}', '');

    await initialize(allowEmptyRootUri: true);

    // Because the file is not in a project, it should be added itself.
    await openFile(pathContext.toUri(file1), '');
    expect(server.contextManager.includedPaths, equals([file1]));
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_fullyInitializes() async {
    // Enable some dynamic registrations, else registerCapability will not
    // be called.
    setAllSupportedTextDocumentDynamicRegistrations();

    // Ensure when we use onlyAnalyzeProjectsWithOpenFiles that we still
    // fully initialize (eg. capabilities are registered).
    projectFolderPath = convertPath('/home/empty');

    await expectRequest(
      Method.client_registerCapability,
      () => initialize(
        rootUri: projectFolderUri,
        initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
      ),
    );
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_multipleFiles() async {
    final file1 = join(projectFolderPath, 'file1.dart');
    final file1Uri = pathContext.toUri(file1);
    newFile(file1, '');
    final file2 = join(projectFolderPath, 'file2.dart');
    final file2Uri = pathContext.toUri(file2);
    newFile(file2, '');
    newPubspecYamlFile(projectFolderPath, '');

    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );

    // Opening both files should only add the project folder once.
    await openFile(file1Uri, '');
    await openFile(file2Uri, '');
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.driverMap, hasLength(1));

    // Closing only one of the files should not remove the root or rebuild the context.
    resetContextBuildCounter();
    await closeFile(file1Uri);
    await pumpEventQueue(times: 5000);
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.driverMap, hasLength(1));
    expectNoContextBuilds();

    // Closing the last file should remove the project folder and remove
    // the context.
    resetContextBuildCounter();
    await closeFile(file2Uri);
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([]));
    expect(server.contextManager.driverMap, hasLength(0));
    expectContextBuilds();
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_withoutPubpsec() async {
    projectFolderPath = convertPath('/home/empty');
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = pathContext.toUri(nestedFilePath);
    newFile(nestedFilePath, '');

    // The project folder shouldn't be added to start with.
    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Opening the file should trigger it to be added.
    await openFile(nestedFileUri, '');
    expect(server.contextManager.includedPaths, equals([nestedFilePath]));
  }

  Future<void> test_onlyAnalyzeProjectsWithOpenFiles_withPubpsec() async {
    final nestedFilePath = join(
        projectFolderPath, 'nested', 'deeply', 'in', 'folders', 'test.dart');
    final nestedFileUri = pathContext.toUri(nestedFilePath);
    newFile(nestedFilePath, '');
    newPubspecYamlFile(projectFolderPath, '');

    // The project folder shouldn't be added to start with.
    await initialize(
      rootUri: projectFolderUri,
      initializationOptions: {'onlyAnalyzeProjectsWithOpenFiles': true},
    );
    expect(server.contextManager.includedPaths, equals([]));

    // Opening a file nested within the project should cause the project folder
    // to be added
    await openFile(nestedFileUri, '');
    await contextRebuildComplete;
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));

    // Ensure the file was cached in each driver. This happens as a result of
    // adding to priority files, but if that's done before the file is in an
    // analysis root it will not occur.
    // https://github.com/dart-lang/sdk/issues/37338
    for (var driver in server.driverMap.values) {
      expect(driver.getCachedResult(nestedFilePath), isNotNull);
    }

    // Closing the file should remove it.
    await closeFile(nestedFileUri);
    expect(server.contextManager.includedPaths, equals([]));
  }

  Future<void> test_survey_enabledByPreviewFlag() async {
    await initialize(
      initializationOptions: {'previewSurveys': true},
    );
    expect(server.surveyManager, isNotNull);
  }

  Future<void> test_survey_notEnabledByPreviewFlag() async {
    await initialize();
    expect(server.surveyManager, isNull);
  }

  Future<void> test_uninitialized_dropsNotifications() async {
    final notification =
        makeNotification(Method.fromJson('randomNotification'), null);
    final nextNotification = errorNotificationsFromServer.first;
    channel.sendNotificationToServer(notification);

    // Wait up to 1sec to ensure no error/log notifications were sent back.
    var didTimeout = false;
    final notificationFromServer = await nextNotification
        .then<NotificationMessage?>((notification) => notification)
        .timeout(
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
    expect(response.error!.code, ErrorCodes.ServerNotInitialized);
  }
}

/// Runs all initialization tests with a resource provider that slowly
/// initializes watchers to simulate delays in real fs watchers.
@reflectiveTest
class SlowInitializationTest extends InitializationTest {
  @override
  MemoryResourceProvider resourceProvider = MemoryResourceProvider(
    // Force the in-memory file watchers to be slowly initialized to emulate
    // the physical watchers (for test_concurrentContextRebuilds).
    delayWatcherInitialization: Duration(milliseconds: 1),
  );
}
