// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide expect;
import 'package:unified_analytics/unified_analytics.dart';

import '../mocks.dart';
import '../mocks_lsp.dart';
import '../src/utilities/mock_packages.dart';
import 'change_verifier.dart';
import 'request_helpers_mixin.dart';

const dartLanguageId = 'dart';

/// Useful for debugging locally, setting this to true will cause all JSON
/// communication to be printed to stdout.
const debugPrintCommunication = false;

abstract class AbstractLspAnalysisServerTest
    with
        ResourceProviderMixin,
        ClientCapabilitiesHelperMixin,
        LspRequestHelpersMixin,
        LspAnalysisServerTestMixin,
        ConfigurationFilesMixin {
  late MockLspServerChannel channel;
  late TestPluginManager pluginManager;
  late LspAnalysisServer server;
  late MockProcessRunner processRunner;
  late MockHttpClient httpClient;

  /// The number of context builds that had already occurred the last time
  /// resetContextBuildCounter() was called.
  int _previousContextBuilds = 0;

  DartFixPromptManager? get dartFixPromptManager => null;

  @override
  path.Context get pathContext => server.resourceProvider.pathContext;

  AnalysisServerOptions get serverOptions => AnalysisServerOptions();

  @override
  Stream<Message> get serverToClient => channel.serverToClient;

  DiscoveredPluginInfo configureTestPlugin({
    plugin.ResponseResult? respondWith,
    plugin.Notification? notification,
    plugin.ResponseResult? Function(plugin.RequestParams)? handler,
    Duration respondAfter = Duration.zero,
  }) {
    final info = DiscoveredPluginInfo('a', 'b', 'c', server.notificationManager,
        server.instrumentationService);
    pluginManager.plugins.add(info);

    if (handler != null) {
      pluginManager.handleRequest = (request) {
        final response = handler(request);
        return response == null
            ? null
            : <PluginInfo, Future<plugin.Response>>{
                info: Future.delayed(respondAfter)
                    .then((_) => response.toResponse('-', 1))
              };
      };
    }

    if (respondWith != null) {
      pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
        info: Future.delayed(respondAfter)
            .then((_) => respondWith.toResponse('-', 1))
      };
    }

    if (notification != null) {
      server.notificationManager
          .handlePluginNotification(info.pluginId, notification);
    }

    return info;
  }

  /// Executes [command] which is expected to call back to the client to apply
  /// a [WorkspaceEdit].
  ///
  /// Returns a [LspChangeVerifier] that can be used to verify changes.
  Future<LspChangeVerifier> executeCommandForEdits(
    Command command, {
    ProgressToken? workDoneToken,
  }) async {
    ApplyWorkspaceEditParams? editParams;

    final commandResponse = await handleExpectedRequest<Object?,
        ApplyWorkspaceEditParams, ApplyWorkspaceEditResult>(
      Method.workspace_applyEdit,
      ApplyWorkspaceEditParams.fromJson,
      () => executeCommand(command, workDoneToken: workDoneToken),
      handler: (edit) {
        // When the server sends the edit back, just keep a copy and say we
        // applied successfully (it'll be verified by the caller).
        editParams = edit;
        return ApplyWorkspaceEditResult(applied: true);
      },
    );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the expected change type.
    expect(editParams, isNotNull);
    final edit = editParams!.edit;

    final expectDocumentChanges =
        workspaceCapabilities.workspaceEdit?.documentChanges ?? false;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    return LspChangeVerifier(this, edit);
  }

  void expectContextBuilds() =>
      expect(server.contextBuilds - _previousContextBuilds, greaterThan(0),
          reason: 'Contexts should have been rebuilt');

  void expectNoContextBuilds() =>
      expect(server.contextBuilds - _previousContextBuilds, equals(0),
          reason: 'Contexts should not have been rebuilt');

  /// Sends a request to the server and unwraps the result. Throws if the
  /// response was not successful or returned an error.
  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson) async {
    final resp = await sendRequestToServer(request);
    final error = resp.error;
    if (error != null) {
      throw error;
    } else {
      // resp.result should only be null when error != null if T allows null.
      return resp.result == null ? null as T : fromJson(resp.result as R);
    }
  }

  List<TextDocumentEdit> extractTextDocumentEdits(
          DocumentChanges documentChanges) =>
      // Extract TextDocumentEdits from union of resource changes
      documentChanges
          .map(
            (change) => change.map(
              (create) => null,
              (delete) => null,
              (rename) => null,
              (textDocEdit) => textDocEdit,
            ),
          )
          .whereNotNull()
          .toList();

  @override
  String? getCurrentFileContent(Uri uri) {
    try {
      return server.resourceProvider
          .getFile(pathContext.fromUri(uri))
          .readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  /// Finds the registration for a given LSP method.
  Registration? registrationFor(
    List<Registration> registrations,
    Method method,
  ) {
    return registrations.singleWhereOrNull((r) => r.method == method.toJson());
  }

  /// Finds a single registration for a given LSP method with Dart in its
  /// documentSelector.
  ///
  /// Throws if there is not exactly one match.
  Registration registrationForDart(
    List<Registration> registrations,
    Method method,
  ) =>
      registrationsForDart(registrations, method).single;

  /// Finds the registrations for a given LSP method with Dart in their
  /// documentSelector.
  List<Registration> registrationsForDart(
    List<Registration> registrations,
    Method method,
  ) {
    bool includesDart(Registration r) {
      final options = TextDocumentRegistrationOptions.fromJson(
          r.registerOptions as Map<String, Object?>);

      return options.documentSelector?.any((selector) =>
              selector.language == dartLanguageId ||
              (selector.pattern?.contains('.dart') ?? false)) ??
          false;
    }

    return registrations
        .where((r) => r.method == method.toJson() && includesDart(r))
        .toList();
  }

  void resetContextBuildCounter() {
    _previousContextBuilds = server.contextBuilds;
  }

  @override
  Future<void> sendNotificationToServer(
      NotificationMessage notification) async {
    channel.sendNotificationToServer(notification);
    await pumpEventQueue(times: 5000);
  }

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) {
    return channel.sendRequestToServer(request);
  }

  @override
  void sendResponseToServer(ResponseMessage response) {
    channel.sendResponseToServer(response);
  }

  void setUp() {
    httpClient = MockHttpClient();
    processRunner = MockProcessRunner();
    channel = MockLspServerChannel(debugPrintCommunication);

    // Create an SDK in the mock file system.
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    pluginManager = TestPluginManager();
    server = LspAnalysisServer(
        channel,
        resourceProvider,
        serverOptions,
        DartSdkManager(sdkRoot.path),
        AnalyticsManager(NoOpAnalytics()),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE,
        httpClient: httpClient,
        processRunner: processRunner,
        dartFixPromptManager: dartFixPromptManager);
    server.pluginManager = pluginManager;

    projectFolderPath = convertPath('/home/my_project');
    projectFolderUri = toUri(projectFolderPath);
    newFolder(projectFolderPath);
    newFolder(join(projectFolderPath, 'lib'));
    // Create a folder and file to aid testing that includes imports/completion.
    newFolder(join(projectFolderPath, 'lib', 'folder'));
    newFile(join(projectFolderPath, 'lib', 'file.dart'), '');
    mainFilePath = join(projectFolderPath, 'lib', 'main.dart');
    mainFileUri = toUri(mainFilePath);
    pubspecFilePath = join(projectFolderPath, file_paths.pubspecYaml);
    pubspecFileUri = toUri(pubspecFilePath);
    analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');
    newFile(analysisOptionsPath, '''
analyzer:
  enable-experiment:
    - inline-class
    - records
    - patterns
    - sealed-class
''');

    analysisOptionsUri = pathContext.toUri(analysisOptionsPath);
    writePackageConfig(projectFolderPath);
  }

  Future<void> tearDown() async {
    channel.close();
    await server.shutdown();
  }

  /// Verifies that executing the given command on the server results in an edit
  /// being sent in the client that updates the files to match the expected
  /// content.
  Future<LspChangeVerifier> verifyCommandEdits(
    Command command,
    String expectedContent, {
    ProgressToken? workDoneToken,
  }) async {
    final verifier = await executeCommandForEdits(
      command,
      workDoneToken: workDoneToken,
    );

    verifier.verifyFiles(expectedContent);
    return verifier;
  }

  LspChangeVerifier verifyEdit(
    WorkspaceEdit edit,
    String expected, {
    Map<Uri, int>? expectedVersions,
  }) {
    final expectDocumentChanges =
        workspaceCapabilities.workspaceEdit?.documentChanges ?? false;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    final verifier = LspChangeVerifier(this, edit);
    verifier.verifyFiles(expected, expectedVersions: expectedVersions);
    return verifier;
  }

  /// Encodes any drive letter colon in the URI.
  ///
  /// file:///C:/foo -> file:///C%3A/foo
  Uri withEncodedDriveLetterColon(Uri uri) {
    return uri.replace(path: uri.path.replaceAll(':', '%3A'));
  }

  /// Adds a trailing slash (direction based on path context) to [path].
  ///
  /// Throws if the path already has a trailing slash.
  String withTrailingSlash(String path) {
    final pathSeparator = server.resourceProvider.pathContext.separator;
    expect(path, isNot(endsWith(pathSeparator)));
    return '$path$pathSeparator';
  }

  /// Adds a trailing slash to [uri].
  ///
  /// Throws if the URI already has a trailing slash.
  Uri withTrailingSlashUri(Uri uri) {
    expect(uri.path, isNot(endsWith('/')));
    return uri.replace(path: '${uri.path}/');
  }
}

mixin ClientCapabilitiesHelperMixin {
  final emptyTextDocumentClientCapabilities = TextDocumentClientCapabilities();

  final emptyWorkspaceClientCapabilities = WorkspaceClientCapabilities();

  final emptyWindowClientCapabilities = WindowClientCapabilities();

  /// The set of TextDocument capabilities used if no explicit instance is
  /// passed to [initialize].
  var textDocumentCapabilities = TextDocumentClientCapabilities();

  /// The set of Workspace capabilities used if no explicit instance is
  /// passed to [initialize].
  var workspaceCapabilities = WorkspaceClientCapabilities();

  /// The set of Window capabilities used if no explicit instance is
  /// passed to [initialize].
  var windowCapabilities = WindowClientCapabilities();

  /// The set of experimental capabilities used if no explicit instance is
  /// passed to [initialize].
  var experimentalCapabilities = <String, Object?>{};

  TextDocumentClientCapabilities extendTextDocumentCapabilities(
    TextDocumentClientCapabilities source,
    Map<String, dynamic> textDocumentCapabilities,
  ) {
    final json = source.toJson();
    mergeJson(textDocumentCapabilities, json);
    return TextDocumentClientCapabilities.fromJson(json);
  }

  WindowClientCapabilities extendWindowCapabilities(
    WindowClientCapabilities source,
    Map<String, dynamic> windowCapabilities,
  ) {
    final json = source.toJson();
    mergeJson(windowCapabilities, json);
    return WindowClientCapabilities.fromJson(json);
  }

  WorkspaceClientCapabilities extendWorkspaceCapabilities(
    WorkspaceClientCapabilities source,
    Map<String, dynamic> workspaceCapabilities,
  ) {
    final json = source.toJson();
    mergeJson(workspaceCapabilities, json);
    return WorkspaceClientCapabilities.fromJson(json);
  }

  void mergeJson(Map<String, dynamic> source, Map<String, dynamic> dest) {
    for (var key in source.keys) {
      var sourceValue = source[key];
      var destValue = dest[key];
      if (sourceValue is Map<String, dynamic> &&
          destValue is Map<String, dynamic>) {
        mergeJson(sourceValue, destValue);
      } else {
        dest[key] = source[key];
      }
    }
  }

  void setAllSupportedTextDocumentDynamicRegistrations() {
    // This list (when combined with the workspace list) should match all of
    // the fields listed in `ClientDynamicRegistrations.supported`.

    setTextDocumentDynamicRegistration('synchronization');
    setTextDocumentDynamicRegistration('callHierarchy');
    setTextDocumentDynamicRegistration('completion');
    setTextDocumentDynamicRegistration('hover');
    setTextDocumentDynamicRegistration('inlayHint');
    setTextDocumentDynamicRegistration('signatureHelp');
    setTextDocumentDynamicRegistration('references');
    setTextDocumentDynamicRegistration('documentHighlight');
    setTextDocumentDynamicRegistration('documentSymbol');
    setTextDocumentDynamicRegistration('colorProvider');
    setTextDocumentDynamicRegistration('formatting');
    setTextDocumentDynamicRegistration('onTypeFormatting');
    setTextDocumentDynamicRegistration('rangeFormatting');
    setTextDocumentDynamicRegistration('declaration');
    setTextDocumentDynamicRegistration('definition');
    setTextDocumentDynamicRegistration('implementation');
    setTextDocumentDynamicRegistration('codeAction');
    setTextDocumentDynamicRegistration('rename');
    setTextDocumentDynamicRegistration('foldingRange');
    setTextDocumentDynamicRegistration('selectionRange');
    setTextDocumentDynamicRegistration('semanticTokens');
    setTextDocumentDynamicRegistration('typeDefinition');
    setTextDocumentDynamicRegistration('typeHierarchy');
  }

  void setAllSupportedWorkspaceDynamicRegistrations() {
    // This list (when combined with the textDocument list) should match all of
    // the fields listed in `ClientDynamicRegistrations.supported`.
    setWorkspaceDynamicRegistration('fileOperations');
  }

  void setApplyEditSupport([bool supported = true]) {
    workspaceCapabilities = extendWorkspaceCapabilities(
        workspaceCapabilities, {'applyEdit': supported});
  }

  void setCompletionItemDeprecatedFlagSupport() {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionItem': {'deprecatedSupport': true}
      }
    });
  }

  void setCompletionItemInsertReplaceSupport() {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionItem': {'insertReplaceSupport': true}
      }
    });
  }

  void setCompletionItemInsertTextModeSupport() {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionItem': {
          'insertTextModeSupport': {
            'valueSet': [InsertTextMode.adjustIndentation, InsertTextMode.asIs]
                .map((k) => k.toJson())
                .toList()
          }
        }
      }
    });
  }

  void setCompletionItemKinds(List<CompletionItemKind> kinds) {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionItemKind': {
          'valueSet': kinds.map((k) => k.toJson()).toList()
        }
      }
    });
  }

  void setCompletionItemLabelDetailsSupport([bool supported = true]) {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionItem': {'labelDetailsSupport': supported}
      }
    });
  }

  void setCompletionItemSnippetSupport([bool supported = true]) {
    textDocumentCapabilities =
        withCompletionItemSnippetSupport(textDocumentCapabilities, supported);
  }

  void setCompletionListDefaults(List<String> defaults) {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'completion': {
        'completionList': {
          'itemDefaults': defaults,
        }
      }
    });
  }

  void setConfigurationSupport() {
    workspaceCapabilities = withConfigurationSupport(workspaceCapabilities);
  }

  void setDidChangeConfigurationDynamicRegistration() {
    workspaceCapabilities =
        withDidChangeConfigurationDynamicRegistration(workspaceCapabilities);
  }

  void setDocumentChangesSupport([bool supported = true]) {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'workspaceEdit': {'documentChanges': supported}
    });
  }

  void setDocumentFormattingDynamicRegistration() {
    setTextDocumentDynamicRegistration('formatting');
    setTextDocumentDynamicRegistration('onTypeFormatting');
    setTextDocumentDynamicRegistration('rangeFormatting');
  }

  void setDocumentSymbolKinds(List<SymbolKind> kinds) {
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      'documentSymbol': {
        'symbolKind': {'valueSet': kinds.map((k) => k.toJson()).toList()}
      }
    });
  }

  void setFileCreateSupport([bool supported = true]) {
    if (supported) {
      setDocumentChangesSupport();
      workspaceCapabilities = withResourceOperationKinds(
          workspaceCapabilities, [ResourceOperationKind.Create]);
    } else {
      workspaceCapabilities.workspaceEdit?.resourceOperations
          ?.remove(ResourceOperationKind.Create);
    }
  }

  void setFileOperationDynamicRegistration() {
    setWorkspaceDynamicRegistration('fileOperations');
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'fileOperations': {'dynamicRegistration': true}
    });
  }

  void setFileRenameSupport([bool supported = true]) {
    if (supported) {
      setDocumentChangesSupport();
      workspaceCapabilities = withResourceOperationKinds(
          workspaceCapabilities, [ResourceOperationKind.Rename]);
    } else {
      workspaceCapabilities.workspaceEdit?.resourceOperations
          ?.remove(ResourceOperationKind.Rename);
    }
  }

  void setHoverDynamicRegistration() {
    setTextDocumentDynamicRegistration('hover');
  }

  void setSignatureHelpContentFormat(List<MarkupKind>? formats) {
    textDocumentCapabilities =
        withSignatureHelpContentFormat(textDocumentCapabilities, formats);
  }

  void setSnippetTextEditSupport([bool supported = true]) {
    experimentalCapabilities['snippetTextEdit'] = supported;
  }

  void setSupportedCodeActionKinds(List<CodeActionKind>? kinds) {
    textDocumentCapabilities =
        withCodeActionKinds(textDocumentCapabilities, kinds);
  }

  void setSupportedCommandParameterKinds(Set<String>? kinds) {
    experimentalCapabilities['dartCodeAction'] = {
      'commandParameterSupport': {'supportedKinds': kinds?.toList()},
    };
  }

  void setTextDocumentDynamicRegistration(
    String name,
  ) {
    final json = name == 'semanticTokens'
        ? SemanticTokensClientCapabilities(
            dynamicRegistration: true,
            requests: SemanticTokensClientCapabilitiesRequests(),
            formats: [],
            tokenModifiers: [],
            tokenTypes: []).toJson()
        : {'dynamicRegistration': true};
    textDocumentCapabilities =
        extendTextDocumentCapabilities(textDocumentCapabilities, {
      name: json,
    });
  }

  void setTextSyncDynamicRegistration() {
    setTextDocumentDynamicRegistration('synchronization');
  }

  void setWorkDoneProgressSupport() {
    windowCapabilities = withWorkDoneProgressSupport(windowCapabilities);
  }

  void setWorkspaceDynamicRegistration(
    String name,
  ) {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      name: {'dynamicRegistration': true},
    });
  }

  TextDocumentClientCapabilities withCodeActionKinds(
    TextDocumentClientCapabilities source,
    List<CodeActionKind>? kinds,
  ) {
    return extendTextDocumentCapabilities(source, {
      'codeAction': {
        'codeActionLiteralSupport': kinds != null
            ? {
                'codeActionKind': {
                  'valueSet': kinds.map((k) => k.toJson()).toList()
                }
              }
            : null,
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemSnippetSupport(
    TextDocumentClientCapabilities source, [
    bool supported = true,
  ]) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItem': {'snippetSupport': supported}
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemTagSupport(
    TextDocumentClientCapabilities source,
    List<CompletionItemTag> tags,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItem': {
          'tagSupport': {'valueSet': tags.map((k) => k.toJson()).toList()}
        }
      }
    });
  }

  WorkspaceClientCapabilities withConfigurationSupport(
    WorkspaceClientCapabilities source,
  ) {
    return extendWorkspaceCapabilities(source, {'configuration': true});
  }

  TextDocumentClientCapabilities withDiagnosticCodeDescriptionSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'publishDiagnostics': {
        'codeDescriptionSupport': true,
      }
    });
  }

  TextDocumentClientCapabilities withDiagnosticTagSupport(
    TextDocumentClientCapabilities source,
    List<DiagnosticTag> tags,
  ) {
    return extendTextDocumentCapabilities(source, {
      'publishDiagnostics': {
        'tagSupport': {'valueSet': tags.map((k) => k.toJson()).toList()}
      }
    });
  }

  WorkspaceClientCapabilities withDidChangeConfigurationDynamicRegistration(
    WorkspaceClientCapabilities source,
  ) {
    return extendWorkspaceCapabilities(source, {
      'didChangeConfiguration': {'dynamicRegistration': true}
    });
  }

  WorkspaceClientCapabilities withDocumentChangesSupport(
    WorkspaceClientCapabilities source, [
    bool supported = true,
  ]) {
    return extendWorkspaceCapabilities(source, {
      'workspaceEdit': {'documentChanges': supported}
    });
  }

  WorkspaceClientCapabilities withGivenWorkspaceDynamicRegistrations(
    WorkspaceClientCapabilities source,
    String name,
  ) {
    return extendWorkspaceCapabilities(source, {
      name: {'dynamicRegistration': true},
    });
  }

  TextDocumentClientCapabilities withHierarchicalDocumentSymbolSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'documentSymbol': {'hierarchicalDocumentSymbolSupport': true}
    });
  }

  TextDocumentClientCapabilities withHoverContentFormat(
    TextDocumentClientCapabilities source,
    List<MarkupKind> formats,
  ) {
    return extendTextDocumentCapabilities(source, {
      'hover': {'contentFormat': formats.map((k) => k.toJson()).toList()}
    });
  }

  TextDocumentClientCapabilities withLineFoldingOnly(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'foldingRange': {'lineFoldingOnly': true},
    });
  }

  TextDocumentClientCapabilities withLocationLinkSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'definition': {'linkSupport': true},
      'typeDefinition': {'linkSupport': true},
      'implementation': {'linkSupport': true}
    });
  }

  WorkspaceClientCapabilities withResourceOperationKinds(
    WorkspaceClientCapabilities source,
    List<ResourceOperationKind> kinds,
  ) {
    return extendWorkspaceCapabilities(source, {
      'workspaceEdit': {
        'documentChanges':
            true, // docChanges aren't included in resourceOperations
        'resourceOperations': kinds.map((k) => k.toJson()).toList(),
      }
    });
  }

  TextDocumentClientCapabilities withSignatureHelpContentFormat(
    TextDocumentClientCapabilities source,
    List<MarkupKind>? formats,
  ) {
    return extendTextDocumentCapabilities(source, {
      'signatureHelp': {
        'signatureInformation': {
          'documentationFormat': formats?.map((k) => k.toJson()).toList()
        }
      }
    });
  }

  WindowClientCapabilities withWorkDoneProgressSupport(
      WindowClientCapabilities source) {
    return extendWindowCapabilities(source, {'workDoneProgress': true});
  }
}

mixin ConfigurationFilesMixin on ResourceProviderMixin {
  String get latestLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  String get testPackageLanguageVersion => latestLanguageVersion;

  void writePackageConfig(
    String projectFolderPath, {
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
    bool pedantic = false,
    bool vector_math = false,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: projectFolderPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (meta || flutter) {
      var libFolder = MockPackages.instance.addMeta(resourceProvider);
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = MockPackages.instance.addUI(resourceProvider);
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = MockPackages.instance.addFlutter(resourceProvider);
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    if (pedantic) {
      var libFolder = MockPackages.instance.addPedantic(resourceProvider);
      config.add(name: 'pedantic', rootPath: libFolder.parent.path);
    }

    if (vector_math) {
      var libFolder = MockPackages.instance.addVectorMath(resourceProvider);
      config.add(name: 'vector_math', rootPath: libFolder.parent.path);
    }

    var path = '$projectFolderPath/.dart_tool/package_config.json';
    var content = config.toContent(toUriStr: toUriStr);
    newFile(path, content);
  }
}

mixin LspAnalysisServerTestMixin on LspRequestHelpersMixin
    implements ClientCapabilitiesHelperMixin {
  static const positionMarker = '^';
  static const rangeMarkerStart = '[[';
  static const rangeMarkerEnd = ']]';
  static const allMarkers = [positionMarker, rangeMarkerStart, rangeMarkerEnd];
  static final allMarkersPattern =
      RegExp(allMarkers.map(RegExp.escape).join('|'));

  /// A progress token used in tests where the client-provides the token, which
  /// should not be validated as being created by the server first.
  final clientProvidedTestWorkDoneToken = ProgressToken.t2('client-test');

  late String projectFolderPath,
      mainFilePath,
      pubspecFilePath,
      analysisOptionsPath;
  late Uri projectFolderUri, mainFileUri, pubspecFileUri, analysisOptionsUri;
  final String simplePubspecContent = 'name: my_project';

  /// The client capabilities sent to the server during initialization.
  ///
  /// null if an initialization request has not yet been sent.
  ClientCapabilities? _clientCapabilities;

  /// The capabilities returned from the server during initialization.
  ///
  /// `null` if the server is not initialized, or returned an error during
  /// initialize.
  ServerCapabilities? _serverCapabilities;

  final validProgressTokens = <ProgressToken>{};

  /// Default initialization options to be used if [initialize] is not provided
  /// options explicitly.
  Map<String, Object?>? defaultInitializationOptions;

  /// A stream of [NotificationMessage]s from the server that may be errors.
  Stream<NotificationMessage> get errorNotificationsFromServer {
    return notificationsFromServer.where(_isErrorNotification);
  }

  bool get initialized => _clientCapabilities != null;

  /// A stream of [NotificationMessage]s from the server.
  Stream<NotificationMessage> get notificationsFromServer {
    return serverToClient
        .where((m) => m is NotificationMessage)
        .cast<NotificationMessage>();
  }

  /// A stream of [OpenUriParams] for any `dart/openUri` notifications.
  Stream<OpenUriParams> get openUriNotifications => notificationsFromServer
      .where((notification) => notification.method == CustomMethods.openUri)
      .map((message) =>
          OpenUriParams.fromJson(message.params as Map<String, Object?>));

  path.Context get pathContext;

  /// A stream of [RequestMessage]s from the server.
  Stream<RequestMessage> get requestsFromServer {
    return serverToClient
        .where((m) => m is RequestMessage)
        .cast<RequestMessage>();
  }

  Stream<Message> get serverToClient;

  Future<void> changeFile(
    int newVersion,
    Uri uri,
    List<TextDocumentContentChangeEvent> changes,
  ) async {
    var notification = makeNotification(
      Method.textDocument_didChange,
      DidChangeTextDocumentParams(
        textDocument:
            VersionedTextDocumentIdentifier(version: newVersion, uri: uri),
        contentChanges: changes,
      ),
    );
    await sendNotificationToServer(notification);
  }

  Future<void> changeWorkspaceFolders(
      {List<Uri>? add, List<Uri>? remove}) async {
    var notification = makeNotification(
      Method.workspace_didChangeWorkspaceFolders,
      DidChangeWorkspaceFoldersParams(
        event: WorkspaceFoldersChangeEvent(
          added: add?.map(toWorkspaceFolder).toList() ?? const [],
          removed: remove?.map(toWorkspaceFolder).toList() ?? const [],
        ),
      ),
    );
    await sendNotificationToServer(notification);
  }

  Future<void> closeFile(Uri uri) async {
    var notification = makeNotification(
      Method.textDocument_didClose,
      DidCloseTextDocumentParams(
          textDocument: TextDocumentIdentifier(uri: uri)),
    );
    await sendNotificationToServer(notification);
  }

  Future<Object?> executeCodeAction(
      Either2<Command, CodeAction> codeAction) async {
    final command = codeAction.map(
      (command) => command,
      (codeAction) => codeAction.command!,
    );
    return executeCommand(command);
  }

  Future<T> executeCommand<T>(
    Command command, {
    T Function(Map<String, Object?>)? decoder,
    ProgressToken? workDoneToken,
  }) async {
    final supportedCommands =
        _serverCapabilities?.executeCommandProvider?.commands ?? [];
    if (!supportedCommands.contains(command.command)) {
      throw ArgumentError('Server does not support ${command.command}. '
          'Is it missing from serverSupportedCommands?');
    }
    final request = makeRequest(
      Method.workspace_executeCommand,
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
        workDoneToken: workDoneToken,
      ),
    );
    return expectSuccessfulResponseTo<T, Map<String, Object?>>(
        request, decoder ?? (result) => result as T);
  }

  Future<ShowMessageParams> expectErrorNotification(
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final firstError = errorNotificationsFromServer.first;
    await f();

    final notificationFromServer = await firstError.timeout(timeout);

    expect(notificationFromServer, isNotNull);
    return ShowMessageParams.fromJson(
        notificationFromServer.params as Map<String, Object?>);
  }

  Future<T> expectNotification<T>(
    bool Function(NotificationMessage) test,
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final firstError = notificationsFromServer.firstWhere(test);
    await f();

    final notificationFromServer = await firstError.timeout(timeout);

    expect(notificationFromServer, isNotNull);
    return notificationFromServer.params as T;
  }

  /// Expects a [method] request from the server after executing [f].
  Future<RequestMessage> expectRequest(
    Method method,
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final firstRequest =
        requestsFromServer.firstWhere((n) => n.method == method);
    await f();

    final requestFromServer = await firstRequest.timeout(timeout);

    expect(requestFromServer, isNotNull);
    return requestFromServer;
  }

  /// Gets the current contents of a file.
  ///
  /// This is used to apply edits when the server sends workspace/applyEdit. It
  /// should reflect the content that the client would have in this case, which
  /// would be an overlay (if the file is open) or the underlying file.
  String? getCurrentFileContent(Uri uri);

  /// Executes [f] then waits for a request of type [method] from the server which
  /// is passed to [handler] to process, then waits for (and returns) the
  /// response to the original request.
  ///
  /// This is used for testing things like code actions, where the client initiates
  /// a request but the server does not respond to it until it's sent its own
  /// request to the client and it received a response.
  ///
  ///     Client                                 Server
  ///     1. |- Req: textDocument/codeAction      ->
  ///     1. <- Resp: textDocument/codeAction     -|
  ///
  ///     2. |- Req: workspace/executeCommand  ->
  ///           3. <- Req: textDocument/applyEdits  -|
  ///           3. |- Resp: textDocument/applyEdits ->
  ///     2. <- Resp: workspace/executeCommand -|
  ///
  /// Request 2 from the client is not responded to until the server has its own
  /// response to the request it sends (3).
  Future<T> handleExpectedRequest<T, R, RR>(
    Method method,
    R Function(Map<String, dynamic>) fromJson,
    Future<T> Function() f, {
    required FutureOr<RR> Function(R) handler,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    late Future<T> outboundRequest;

    // Run [f] and wait for the incoming request from the server.
    final incomingRequest = await expectRequest(method, () {
      // Don't return/await the response yet, as this may not complete until
      // after we have handled the request that comes from the server.
      outboundRequest = f();

      // Because we don't await this future until "later", if it throws the
      // error is treated as unhandled and will fail the test. Attaching an
      // error handler prevents that, though since the Future completed with
      // an error it will still be handled as such when the future is later
      // awaited.

      // TODO: Fix this static error.
      // ignore: body_might_complete_normally_catch_error
      outboundRequest.catchError((_) {});
    });

    // Handle the request from the server and send the response back.
    final clientsResponse =
        await handler(fromJson(incomingRequest.params as Map<String, Object?>));
    respondTo(incomingRequest, clientsResponse);

    // Return a future that completes when the response to the original request
    // (from [f]) returns.
    return outboundRequest;
  }

  /// A helper that initializes the server with common values, since the server
  /// will reject any other requests until it is initialized.
  /// Capabilities are overridden by providing JSON to avoid having to construct
  /// full objects just to change one value (the types are immutable) so must
  /// match the spec exactly and are not verified.
  Future<ResponseMessage> initialize({
    String? rootPath,
    Uri? rootUri,
    List<Uri>? workspaceFolders,
    // TODO(dantup): Remove these capabilities fields in favour of methods like
    //  [setApplyEditSupport] which allows extracting initialization in tests
    //  without needing to pass capabilities these all the way through.
    TextDocumentClientCapabilities? textDocumentCapabilities,
    WorkspaceClientCapabilities? workspaceCapabilities,
    WindowClientCapabilities? windowCapabilities,
    Map<String, Object?>? experimentalCapabilities,
    Map<String, Object?>? initializationOptions,
    bool throwOnFailure = true,
    bool allowEmptyRootUri = false,
    bool failTestOnAnyErrorNotification = true,
    bool includeClientRequestTime = false,
  }) async {
    this.includeClientRequestTime = includeClientRequestTime;

    if (failTestOnAnyErrorNotification) {
      errorNotificationsFromServer.listen((NotificationMessage error) {
        fail('${error.toJson()}');
      });
    }

    final clientCapabilities = ClientCapabilities(
      workspace: workspaceCapabilities ?? this.workspaceCapabilities,
      textDocument: textDocumentCapabilities ?? this.textDocumentCapabilities,
      window: windowCapabilities ?? this.windowCapabilities,
      experimental: experimentalCapabilities ?? this.experimentalCapabilities,
    );
    _clientCapabilities = clientCapabilities;

    // Handle any standard incoming requests that aren't test-specific, for example
    // accepting requests to create progress tokens.
    requestsFromServer.listen((request) async {
      if (request.method == Method.window_workDoneProgress_create) {
        respondTo(request, await _handleWorkDoneProgressCreate(request));
      }
    });

    notificationsFromServer.listen((notification) async {
      if (notification.method == Method.progress) {
        await _handleProgress(notification);
      }
    });

    // Assume if none of the project options were set, that we want to default to
    // opening the test project folder.
    if (rootPath == null &&
        rootUri == null &&
        workspaceFolders == null &&
        !allowEmptyRootUri) {
      rootUri = pathContext.toUri(projectFolderPath);
    }
    final request = makeRequest(
        Method.initialize,
        InitializeParams(
          rootPath: rootPath,
          rootUri: rootUri,
          initializationOptions:
              initializationOptions ?? defaultInitializationOptions,
          capabilities: clientCapabilities,
          workspaceFolders: workspaceFolders?.map(toWorkspaceFolder).toList(),
        ));
    final response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));

    final error = response.error;
    if (error == null) {
      final result =
          InitializeResult.fromJson(response.result as Map<String, Object?>);
      _serverCapabilities = result.capabilities;

      final notification =
          makeNotification(Method.initialized, InitializedParams());
      await sendNotificationToServer(notification);
      await pumpEventQueue();
    } else if (throwOnFailure) {
      throw 'Error during initialize request: '
          '${error.code}: ${error.message}';
    }

    return response;
  }

  NotificationMessage makeNotification(Method method, ToJsonable? params) {
    return NotificationMessage(
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
      clientRequestTime: includeClientRequestTime
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
  }

  RequestMessage makeRenameRequest(
      int? version, Uri uri, Position pos, String newName) {
    final docIdentifier = version != null
        ? VersionedTextDocumentIdentifier(version: version, uri: uri)
        : TextDocumentIdentifier(uri: uri);
    final request = makeRequest(
      Method.textDocument_rename,
      RenameParams(
          newName: newName, textDocument: docIdentifier, position: pos),
    );
    return request;
  }

  /// Watches for `client/registerCapability` requests and updates
  /// `registrations`.
  Future<T> monitorDynamicRegistrations<T>(
    List<Registration> registrations,
    Future<T> Function() f,
  ) {
    return handleExpectedRequest<T, RegistrationParams, void>(
      Method.client_registerCapability,
      RegistrationParams.fromJson,
      f,
      handler: (registrationParams) {
        registrations.addAll(registrationParams.registrations);
      },
    );
  }

  /// Expects both unregistration and reregistration.
  Future<T> monitorDynamicReregistration<T>(
    List<Registration> registrations,
    Future<T> Function() f,
  ) =>
      monitorDynamicUnregistrations(
        registrations,
        () => monitorDynamicRegistrations(registrations, f),
      );

  /// Watches for `client/unregisterCapability` requests and updates
  /// `registrations`.
  Future<T> monitorDynamicUnregistrations<T>(
    List<Registration> registrations,
    Future<T> Function() f,
  ) {
    return handleExpectedRequest<T, UnregistrationParams, void>(
      Method.client_unregisterCapability,
      UnregistrationParams.fromJson,
      f,
      handler: (unregistrationParams) {
        registrations.removeWhere((element) => unregistrationParams
            .unregisterations
            .any((u) => u.id == element.id));
      },
    );
  }

  Future<WorkspaceEdit> onWillRename(List<FileRename> renames) {
    final request = makeRequest(
      Method.workspace_willRenameFiles,
      RenameFilesParams(files: renames),
    );
    return expectSuccessfulResponseTo(request, WorkspaceEdit.fromJson);
  }

  Future<void> openFile(Uri uri, String content, {int version = 1}) async {
    var notification = makeNotification(
      Method.textDocument_didOpen,
      DidOpenTextDocumentParams(
          textDocument: TextDocumentItem(
              uri: uri,
              languageId: dartLanguageId,
              version: version,
              text: content)),
    );
    await sendNotificationToServer(notification);
    await pumpEventQueue(times: 128);
  }

  int positionCompare(Position p1, Position p2) {
    if (p1.line < p2.line) return -1;
    if (p1.line > p2.line) return 1;

    if (p1.character < p2.character) return -1;
    if (p1.character > p2.character) return 1;

    return 0;
  }

  Position positionFromMarker(String contents) =>
      positionFromOffset(withoutRangeMarkers(contents).indexOf('^'), contents);

  @override
  Position positionFromOffset(int offset, String contents) {
    return super.positionFromOffset(offset, withoutMarkers(contents));
  }

  /// Calls the supplied function and responds to any `workspace/configuration`
  /// request with the supplied config.
  ///
  /// Automatically enables `workspace/configuration` support.
  Future<T> provideConfig<T>(
    Future<T> Function() f,
    FutureOr<Map<String, Object?>> globalConfig, {
    FutureOr<Map<String, Map<String, Object?>>>? folderConfig,
  }) {
    final self = this;
    if (self is AbstractLspAnalysisServerTest) {
      self.setConfigurationSupport();
    }
    return handleExpectedRequest<T, ConfigurationParams,
        List<Map<String, Object?>>>(
      Method.workspace_configuration,
      ConfigurationParams.fromJson,
      f,
      handler: (configurationParams) async {
        // We must respond to the request for config with items that match the
        // request. For any item in the request without a folder, we will return
        // the global config. For any item in the request with a folder we will
        // return the config for that item in the map, or fall back to the global
        // config if it does not exist.
        final global = await globalConfig;
        final folders = await folderConfig;
        return configurationParams.items.map(
          (requestedConfig) {
            final uri = requestedConfig.scopeUri;
            final path =
                uri != null ? pathContext.fromUri(Uri.parse(uri)) : null;
            // Use the config the test provided for this path, or fall back to
            // global.
            return (folders != null ? folders[path] : null) ?? global;
          },
        ).toList();
      },
    );
  }

  /// Returns the range surrounded by `[[markers]]` in the provided string,
  /// excluding the markers themselves (as well as position markers `^` from
  /// the offsets).
  Range rangeFromMarkers(String contents) {
    final ranges = rangesFromMarkers(contents);
    if (ranges.length == 1) {
      return ranges.first;
    } else if (ranges.isEmpty) {
      throw 'Contents did not include a marked range';
    } else {
      throw 'Contents contained multiple ranges but only one was expected';
    }
  }

  /// Returns the range of [pattern] in [content].
  Range rangeOfPattern(String content, Pattern pattern) {
    content = withoutMarkers(content);
    final match = pattern.allMatches(content).first;
    return Range(
      start: positionFromOffset(match.start, content),
      end: positionFromOffset(match.end, content),
    );
  }

  /// Returns the range of [searchText] in [content].
  Range rangeOfString(String content, String searchText) =>
      rangeOfPattern(content, searchText);

  /// Returns a [Range] that covers the entire of [content].
  Range rangeOfWholeContent(String content) {
    return Range(
      start: positionFromOffset(0, content),
      end: positionFromOffset(content.length, content),
    );
  }

  /// Returns all ranges surrounded by `[[markers]]` in the provided string,
  /// excluding the markers themselves (as well as position markers `^` from
  /// the offsets).
  List<Range> rangesFromMarkers(String content) {
    Iterable<Range> rangesFromMarkersImpl(String content) sync* {
      content = content.replaceAll(positionMarker, '');
      final contentsWithoutMarkers = withoutMarkers(content);
      var searchStartIndex = 0;
      var offsetForEarlierMarkers = 0;
      while (true) {
        final startMarker = content.indexOf(rangeMarkerStart, searchStartIndex);
        if (startMarker == -1) {
          return; // Exit if we didn't find any more.
        }
        final endMarker = content.indexOf(rangeMarkerEnd, startMarker);
        if (endMarker == -1) {
          throw 'Found unclosed range starting at offset $startMarker';
        }
        yield Range(
          start: positionFromOffset(
              startMarker + offsetForEarlierMarkers, contentsWithoutMarkers),
          end: positionFromOffset(
              endMarker + offsetForEarlierMarkers - rangeMarkerStart.length,
              contentsWithoutMarkers),
        );
        // Start the next search after this one, but remember to offset the future
        // results by the lengths of these markers since they shouldn't affect the
        // offsets.
        searchStartIndex = endMarker;
        offsetForEarlierMarkers -=
            rangeMarkerStart.length + rangeMarkerEnd.length;
      }
    }

    return rangesFromMarkersImpl(content).toList();
  }

  /// Gets the range in [content] that beings with the string [prefix] and
  /// has a length matching [text].
  Range rangeStartingAtString(String content, String prefix, String text) {
    content = withoutMarkers(content);
    final offset = content.indexOf(prefix);
    final end = offset + text.length;
    return Range(
      start: positionFromOffset(offset, content),
      end: positionFromOffset(end, content),
    );
  }

  /// Formats a path relative to the project root always using forward slashes.
  ///
  /// This is used in the text format for comparing edits.
  String relativePath(String filePath) => pathContext
      .relative(filePath, from: projectFolderPath)
      .replaceAll(r'\', '/');

  /// Formats a path relative to the project root always using forward slashes.
  ///
  /// This is used in the text format for comparing edits.
  String relativeUri(Uri uri) => relativePath(pathContext.fromUri(uri));

  Future<WorkspaceEdit?> rename(
    Uri uri,
    int? version,
    Position pos,
    String newName,
  ) {
    final request = makeRenameRequest(version, uri, pos, newName);
    return expectSuccessfulResponseTo(request, WorkspaceEdit.fromJson);
  }

  Future<ResponseMessage> renameRaw(
    Uri uri,
    int version,
    Position pos,
    String newName,
  ) {
    final request = makeRenameRequest(version, uri, pos, newName);
    return sendRequestToServer(request);
  }

  Future<void> replaceFile(int newVersion, Uri uri, String content) {
    return changeFile(
      newVersion,
      uri,
      [
        TextDocumentContentChangeEvent.t2(
            TextDocumentContentChangeEvent2(text: content))
      ],
    );
  }

  /// Sends [responseParams] to the server as a successful response to
  /// a server-initiated [request].
  void respondTo<T>(RequestMessage request, T responseParams) {
    sendResponseToServer(ResponseMessage(
        id: request.id, result: responseParams, jsonrpc: jsonRpcVersion));
  }

  Future<ResponseMessage> sendDidChangeConfiguration() {
    final request = makeRequest(
      Method.workspace_didChangeConfiguration,
      DidChangeConfigurationParams(),
    );
    return sendRequestToServer(request);
  }

  void sendExit() {
    final request = makeRequest(Method.exit, null);
    sendRequestToServer(request);
  }

  FutureOr<void> sendNotificationToServer(NotificationMessage notification);

  Future<ResponseMessage> sendRequestToServer(RequestMessage request);

  void sendResponseToServer(ResponseMessage response);

  Future<Null> sendShutdown() {
    final request = makeRequest(Method.shutdown, null);
    return expectSuccessfulResponseTo(request, (result) => result as Null);
  }

  /// Creates a [TextEdit] using the `insert` range of a [InsertReplaceEdit].
  TextEdit textEditForInsert(Either2<InsertReplaceEdit, TextEdit> edit) =>
      edit.map(
        (e) => TextEdit(range: e.insert, newText: e.newText),
        (_) => throw 'Expected InsertReplaceEdit, got TextEdit',
      );

  /// Creates a [TextEdit] using the `replace` range of a [InsertReplaceEdit].
  TextEdit textEditForReplace(Either2<InsertReplaceEdit, TextEdit> edit) =>
      edit.map(
        (e) => TextEdit(range: e.replace, newText: e.newText),
        (_) => throw 'Expected InsertReplaceEdit, got TextEdit',
      );

  TextEdit toTextEdit(Either2<InsertReplaceEdit, TextEdit> edit) => edit.map(
        (_) => throw 'Expected TextEdit, got InsertReplaceEdit',
        (e) => e,
      );

  WorkspaceFolder toWorkspaceFolder(Uri uri) {
    return WorkspaceFolder(
      uri: uri,
      name: path.basename(uri.path),
    );
  }

  /// Records the latest diagnostics for each file in [latestDiagnostics].
  ///
  /// [latestDiagnostics] maps from a file path to the set of current
  /// diagnostics.
  StreamSubscription<PublishDiagnosticsParams> trackDiagnostics(
      Map<String, List<Diagnostic>> latestDiagnostics) {
    return notificationsFromServer
        .where((notification) =>
            notification.method == Method.textDocument_publishDiagnostics)
        .map((notification) => PublishDiagnosticsParams.fromJson(
            notification.params as Map<String, Object?>))
        .listen((diagnostics) {
      latestDiagnostics[pathContext.fromUri(diagnostics.uri)] =
          diagnostics.diagnostics;
    });
  }

  /// Tells the server the config has changed, and provides the supplied config
  /// when it requests the updated config.
  Future<ResponseMessage> updateConfig(Map<String, dynamic> config) {
    return provideConfig(
      sendDidChangeConfiguration,
      config,
    );
  }

  Future<void> waitForAnalysisComplete() => waitForAnalysisStatus(false);

  Future<void> waitForAnalysisStart() => waitForAnalysisStatus(true);

  Future<void> waitForAnalysisStatus(bool analyzing) async {
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.analyzerStatus) {
        if (_clientCapabilities!.window?.workDoneProgress == true) {
          throw Exception(
              'Received ${CustomMethods.analyzerStatus} notification '
              'but client supports workDoneProgress');
        }

        final params = AnalyzerStatusParams.fromJson(
            message.params as Map<String, Object?>);
        return params.isAnalyzing == analyzing;
      } else if (message.method == Method.progress) {
        if (_clientCapabilities!.window?.workDoneProgress != true) {
          throw Exception(
              'Received ${CustomMethods.analyzerStatus} notification '
              'but client supports workDoneProgress');
        }

        final params =
            ProgressParams.fromJson(message.params as Map<String, Object?>);

        // Skip unrelated progress notifications.
        if (params.token != analyzingProgressToken) {
          return false;
        }

        if (params.value is Map<String, dynamic>) {
          final isDesiredStatusMessage = analyzing
              ? WorkDoneProgressBegin.canParse(
                  params.value, nullLspJsonReporter)
              : WorkDoneProgressEnd.canParse(params.value, nullLspJsonReporter);

          return isDesiredStatusMessage;
        } else {
          throw Exception('\$/progress params value was not valid');
        }
      }
      // Message is not what we're waiting for.
      return false;
    });
  }

  Future<List<ClosingLabel>> waitForClosingLabels(Uri uri) async {
    late PublishClosingLabelsParams closingLabelsParams;
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.publishClosingLabels) {
        closingLabelsParams = PublishClosingLabelsParams.fromJson(
            message.params as Map<String, Object?>);

        return closingLabelsParams.uri == uri;
      }
      return false;
    });
    return closingLabelsParams.labels;
  }

  Future<List<Diagnostic>?> waitForDiagnostics(Uri uri) async {
    PublishDiagnosticsParams? diagnosticParams;
    await notificationsFromServer
        .map<NotificationMessage?>((message) => message)
        .firstWhere((message) {
      if (message?.method == Method.textDocument_publishDiagnostics) {
        diagnosticParams = PublishDiagnosticsParams.fromJson(
            message!.params as Map<String, Object?>);
        return diagnosticParams!.uri == uri;
      }
      return false;
    }, orElse: () => null);
    return diagnosticParams?.diagnostics;
  }

  Future<FlutterOutline> waitForFlutterOutline(Uri uri) async {
    late PublishFlutterOutlineParams outlineParams;
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.publishFlutterOutline) {
        outlineParams = PublishFlutterOutlineParams.fromJson(
            message.params as Map<String, Object?>);

        return outlineParams.uri == uri;
      }
      return false;
    });
    return outlineParams.outline;
  }

  Future<Outline> waitForOutline(Uri uri) async {
    late PublishOutlineParams outlineParams;
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.publishOutline) {
        outlineParams = PublishOutlineParams.fromJson(
            message.params as Map<String, Object?>);

        return outlineParams.uri == uri;
      }
      return false;
    });
    return outlineParams.outline;
  }

  /// Removes markers like `[[` and `]]` and `^` that are used for marking
  /// positions/ranges in strings to avoid hard-coding positions in tests.
  String withoutMarkers(String contents) =>
      contents.replaceAll(allMarkersPattern, '');

  /// Removes range markers from strings to give accurate position offsets.
  String withoutRangeMarkers(String contents) =>
      contents.replaceAll(rangeMarkerStart, '').replaceAll(rangeMarkerEnd, '');

  Future<void> _handleProgress(NotificationMessage request) async {
    final params =
        ProgressParams.fromJson(request.params as Map<String, Object?>);
    if (params.token != clientProvidedTestWorkDoneToken &&
        !validProgressTokens.contains(params.token)) {
      throw Exception('Server sent a progress notification for a token '
          'that has not been created: ${params.token}');
    }

    if (WorkDoneProgressEnd.canParse(params.value, nullLspJsonReporter)) {
      validProgressTokens.remove(params.token);
    }
  }

  Future<void> _handleWorkDoneProgressCreate(RequestMessage request) async {
    if (_clientCapabilities!.window?.workDoneProgress != true) {
      throw Exception('Server sent ${Method.window_workDoneProgress_create} '
          'but client capabilities do not allow');
    }
    final params = WorkDoneProgressCreateParams.fromJson(
        request.params as Map<String, Object?>);
    if (validProgressTokens.contains(params.token)) {
      throw Exception('Server tried to create already-active progress token');
    }
    validProgressTokens.add(params.token);
  }

  /// Checks whether a notification is likely an error from the server (for
  /// example a window/showMessage). This is useful for tests that want to
  /// ensure no errors come from the server in response to notifications (which
  /// don't have their own responses).
  bool _isErrorNotification(NotificationMessage notification) {
    return notification.method == Method.window_logMessage ||
        notification.method == Method.window_showMessage;
  }
}
