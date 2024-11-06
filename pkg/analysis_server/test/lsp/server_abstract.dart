// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_utilities/test/experiments/experiments.dart';
import 'package:analyzer_utilities/test/mock_packages/mock_packages.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' hide expect;
import 'package:unified_analytics/unified_analytics.dart';

import '../mocks.dart';
import '../mocks_lsp.dart';
import '../support/configuration_files.dart';
import '../test_macros.dart';
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
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        LspAnalysisServerTestMixin,
        MockPackagesMixin,
        ConfigurationFilesMixin,
        TestMacros {
  late MockLspServerChannel channel;
  late ErrorNotifier errorNotifier;
  late TestPluginManager pluginManager;
  late LspAnalysisServer server;
  late MockProcessRunner processRunner;
  late MockHttpClient httpClient;

  /// The number of context builds that had already occurred the last time
  /// resetContextBuildCounter() was called.
  int _previousContextBuilds = 0;

  DartFixPromptManager? get dartFixPromptManager => null;

  String get mainFileAugmentationPath => fromUri(mainFileAugmentationUri);

  /// The path that is not in [projectFolderPath], contains external packages.
  @override
  String get packagesRootPath => resourceProvider.convertPath('/packages');

  AnalysisServerOptions get serverOptions => AnalysisServerOptions();

  @override
  Stream<Message> get serverToClient => channel.serverToClient;

  @override
  ClientUriConverter get uriConverter => server.uriConverter;

  DiscoveredPluginInfo configureTestPlugin({
    plugin.ResponseResult? respondWith,
    plugin.Notification? notification,
    plugin.ResponseResult? Function(plugin.RequestParams)? handler,
    Duration respondAfter = Duration.zero,
  }) {
    var info = DiscoveredPluginInfo(
      'a',
      'b',
      'c',
      server.notificationManager,
      server.instrumentationService,
    );
    pluginManager.plugins.add(info);

    if (handler != null) {
      pluginManager.handleRequest = (request) {
        var response = handler(request);
        return response == null
            ? null
            : <PluginInfo, Future<plugin.Response>>{
              info: Future.delayed(
                respondAfter,
              ).then((_) => response.toResponse('-', 1)),
            };
      };
    }

    if (respondWith != null) {
      pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
        info: Future.delayed(
          respondAfter,
        ).then((_) => respondWith.toResponse('-', 1)),
      };
    }

    if (notification != null) {
      server.notificationManager.handlePluginNotification(
        info.pluginId,
        notification,
      );
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

    var commandResponse = await handleExpectedRequest<
      Object?,
      ApplyWorkspaceEditParams,
      ApplyWorkspaceEditResult
    >(
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
    var edit = editParams!.edit;

    var expectDocumentChanges =
        workspaceCapabilities.workspaceEdit?.documentChanges ?? false;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    return LspChangeVerifier(this, edit);
  }

  void expectContextBuilds() => expect(
    server.contextBuilds - _previousContextBuilds,
    greaterThan(0),
    reason: 'Contexts should have been rebuilt',
  );

  void expectNoContextBuilds() => expect(
    server.contextBuilds - _previousContextBuilds,
    equals(0),
    reason: 'Contexts should not have been rebuilt',
  );

  /// Sends a request to the server and unwraps the result. Throws if the
  /// response was not successful or returned an error.
  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage request,
    T Function(R) fromJson,
  ) async {
    var resp = await sendRequestToServer(request);
    var error = resp.error;
    if (error != null) {
      throw error;
    } else {
      // resp.result should only be null when error != null if T allows null.
      return resp.result == null ? null as T : fromJson(resp.result as R);
    }
  }

  List<TextDocumentEdit> extractTextDocumentEdits(
    DocumentChanges documentChanges,
  ) =>
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
          .nonNulls
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
  ) => registrationsForDart(registrations, method).single;

  /// Finds the registrations for a given LSP method with Dart in their
  /// documentSelector.
  List<Registration> registrationsForDart(
    List<Registration> registrations,
    Method method,
  ) {
    bool includesDart(Registration r) {
      var options = TextDocumentRegistrationOptions.fromJson(
        r.registerOptions as Map<String, Object?>,
      );

      return options.documentSelector?.any(
            (selector) =>
                selector.language == dartLanguageId ||
                (selector.pattern?.contains('.dart') ?? false),
          ) ??
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
    NotificationMessage notification,
  ) async {
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
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);

    errorNotifier = ErrorNotifier();
    pluginManager = TestPluginManager();
    server = LspAnalysisServer(
      channel,
      resourceProvider,
      serverOptions,
      DartSdkManager(sdkRoot.path),
      AnalyticsManager(NoOpAnalytics()),
      CrashReportingAttachmentsBuilder.empty,
      errorNotifier,
      httpClient: httpClient,
      processRunner: processRunner,
      dartFixPromptManager: dartFixPromptManager,
    );
    errorNotifier.server = server;
    server.pluginManager = pluginManager;

    projectFolderPath = convertPath('/home/my_project');
    newFolder(projectFolderPath);
    newFolder(join(projectFolderPath, 'lib'));
    // Create a folder and file to aid testing that includes imports/completion.
    newFolder(join(projectFolderPath, 'lib', 'folder'));
    newFile(join(projectFolderPath, 'lib', 'file.dart'), '');
    mainFilePath = join(projectFolderPath, 'lib', 'main.dart');
    nonExistentFilePath = join(projectFolderPath, 'lib', 'not_existing.dart');
    pubspecFilePath = join(projectFolderPath, file_paths.pubspecYaml);
    analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');

    var experiments = StringBuffer();
    for (var experiment in experimentsForTests) {
      experiments.writeln('    - $experiment');
    }

    newFile(analysisOptionsPath, '''
analyzer:
  enable-experiment:
$experiments    
''');

    writeTestPackageConfig();
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
    var verifier = await executeCommandForEdits(
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
    var expectDocumentChanges =
        workspaceCapabilities.workspaceEdit?.documentChanges ?? false;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    var verifier = LspChangeVerifier(this, edit);
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
    var pathSeparator = server.resourceProvider.pathContext.separator;
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
    var json = source.toJson();
    mergeJson(textDocumentCapabilities, json);
    return TextDocumentClientCapabilities.fromJson(json);
  }

  WindowClientCapabilities extendWindowCapabilities(
    WindowClientCapabilities source,
    Map<String, dynamic> windowCapabilities,
  ) {
    var json = source.toJson();
    mergeJson(windowCapabilities, json);
    return WindowClientCapabilities.fromJson(json);
  }

  WorkspaceClientCapabilities extendWorkspaceCapabilities(
    WorkspaceClientCapabilities source,
    Map<String, dynamic> workspaceCapabilities,
  ) {
    var json = source.toJson();
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
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'applyEdit': supported,
    });
  }

  void setChangeAnnotationSupport([bool supported = true]) {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'workspaceEdit': {
        'changeAnnotationSupport':
            supported
                ? <String, Object?>{
                  // This is set to an empty object to indicate support. We don't
                  // currently use any of the child properties.
                }
                : null,
      },
    });
  }

  void setClientSupportedCommands(List<String>? supportedCommands) {
    experimentalCapabilities['commands'] = supportedCommands;
  }

  void setCompletionItemDeprecatedFlagSupport() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {'deprecatedSupport': true},
        },
      },
    );
  }

  void setCompletionItemInsertReplaceSupport() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {'insertReplaceSupport': true},
        },
      },
    );
  }

  void setCompletionItemInsertTextModeSupport() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {
            'insertTextModeSupport': {
              'valueSet':
                  [
                    InsertTextMode.adjustIndentation,
                    InsertTextMode.asIs,
                  ].map((k) => k.toJson()).toList(),
            },
          },
        },
      },
    );
  }

  void setCompletionItemKinds(List<CompletionItemKind> kinds) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItemKind': {
            'valueSet': kinds.map((k) => k.toJson()).toList(),
          },
        },
      },
    );
  }

  void setCompletionItemLabelDetailsSupport([bool supported = true]) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {'labelDetailsSupport': supported},
        },
      },
    );
  }

  void setCompletionItemSnippetSupport([bool supported = true]) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {'snippetSupport': supported},
        },
      },
    );
  }

  void setCompletionItemTagSupport(List<CompletionItemTag> tags) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionItem': {
            'tagSupport': {'valueSet': tags.map((k) => k.toJson()).toList()},
          },
        },
      },
    );
  }

  void setCompletionListDefaults(List<String> defaults) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'completion': {
          'completionList': {'itemDefaults': defaults},
        },
      },
    );
  }

  void setConfigurationSupport() {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'configuration': true,
    });
  }

  void setDartTextDocumentContentProviderSupport([bool supported = true]) {
    // These are temporarily versioned with a suffix during dev so if we ship
    // as an experiment (not LSP standard) without the suffix it will only be
    // active for matching server/clients.
    const key = dartExperimentalTextDocumentContentProviderKey;
    if (supported) {
      experimentalCapabilities[key] = true;
    } else {
      experimentalCapabilities.remove(key);
    }
  }

  void setDiagnosticCodeDescriptionSupport() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'publishDiagnostics': {'codeDescriptionSupport': true},
      },
    );
  }

  void setDiagnosticTagSupport(List<DiagnosticTag> tags) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'publishDiagnostics': {
          'tagSupport': {'valueSet': tags.map((k) => k.toJson()).toList()},
        },
      },
    );
  }

  void setDidChangeConfigurationDynamicRegistration() {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'didChangeConfiguration': {'dynamicRegistration': true},
    });
  }

  void setDocumentChangesSupport([bool supported = true]) {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'workspaceEdit': {'documentChanges': supported},
    });
  }

  void setDocumentFormattingDynamicRegistration() {
    setTextDocumentDynamicRegistration('formatting');
    setTextDocumentDynamicRegistration('onTypeFormatting');
    setTextDocumentDynamicRegistration('rangeFormatting');
  }

  void setDocumentSymbolKinds(List<SymbolKind> kinds) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'documentSymbol': {
          'symbolKind': {'valueSet': kinds.map((k) => k.toJson()).toList()},
        },
      },
    );
  }

  void setFileCreateSupport([bool supported = true]) {
    if (supported) {
      setDocumentChangesSupport();
      workspaceCapabilities = _withResourceOperationKinds(
        workspaceCapabilities,
        [ResourceOperationKind.Create],
      );
    } else {
      workspaceCapabilities.workspaceEdit?.resourceOperations?.remove(
        ResourceOperationKind.Create,
      );
    }
  }

  void setFileOperationDynamicRegistration() {
    setWorkspaceDynamicRegistration('fileOperations');
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      'fileOperations': {'dynamicRegistration': true},
    });
  }

  void setFileRenameSupport([bool supported = true]) {
    if (supported) {
      setDocumentChangesSupport();
      workspaceCapabilities = _withResourceOperationKinds(
        workspaceCapabilities,
        [ResourceOperationKind.Rename],
      );
    } else {
      workspaceCapabilities.workspaceEdit?.resourceOperations?.remove(
        ResourceOperationKind.Rename,
      );
    }
  }

  void setHierarchicalDocumentSymbolSupport() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'documentSymbol': {'hierarchicalDocumentSymbolSupport': true},
      },
    );
  }

  void setHoverContentFormat(List<MarkupKind> formats) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'hover': {'contentFormat': formats.map((k) => k.toJson()).toList()},
      },
    );
  }

  void setHoverDynamicRegistration() {
    setTextDocumentDynamicRegistration('hover');
  }

  void setLineFoldingOnly() {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'foldingRange': {'lineFoldingOnly': true},
      },
    );
  }

  void setLocationLinkSupport([bool supported = true]) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'definition': {'linkSupport': supported},
        'typeDefinition': {'linkSupport': supported},
        'implementation': {'linkSupport': supported},
      },
    );
  }

  void setSignatureHelpContentFormat(List<MarkupKind>? formats) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'signatureHelp': {
          'signatureInformation': {
            'documentationFormat': formats?.map((k) => k.toJson()).toList(),
          },
        },
      },
    );
  }

  void setSnippetTextEditSupport([bool supported = true]) {
    experimentalCapabilities['snippetTextEdit'] = supported;
  }

  void setSupportedCodeActionKinds(List<CodeActionKind>? kinds) {
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {
        'codeAction': {
          'codeActionLiteralSupport':
              kinds != null
                  ? {
                    'codeActionKind': {
                      'valueSet': kinds.map((k) => k.toJson()).toList(),
                    },
                  }
                  : null,
        },
      },
    );
  }

  void setSupportedCommandParameterKinds(Set<String>? kinds) {
    experimentalCapabilities['dartCodeAction'] = {
      'commandParameterSupport': {'supportedKinds': kinds?.toList()},
    };
  }

  void setTextDocumentDynamicRegistration(String name) {
    var json =
        name == 'semanticTokens'
            ? SemanticTokensClientCapabilities(
              dynamicRegistration: true,
              requests: ClientSemanticTokensRequestOptions(),
              formats: [],
              tokenModifiers: [],
              tokenTypes: [],
            ).toJson()
            : {'dynamicRegistration': true};
    textDocumentCapabilities = extendTextDocumentCapabilities(
      textDocumentCapabilities,
      {name: json},
    );
  }

  void setTextSyncDynamicRegistration() {
    setTextDocumentDynamicRegistration('synchronization');
  }

  void setWorkDoneProgressSupport() {
    windowCapabilities = extendWindowCapabilities(windowCapabilities, {
      'workDoneProgress': true,
    });
  }

  void setWorkspaceDynamicRegistration(String name) {
    workspaceCapabilities = extendWorkspaceCapabilities(workspaceCapabilities, {
      name: {'dynamicRegistration': true},
    });
  }

  WorkspaceClientCapabilities _withResourceOperationKinds(
    WorkspaceClientCapabilities source,
    List<ResourceOperationKind> kinds,
  ) {
    return extendWorkspaceCapabilities(source, {
      'workspaceEdit': {
        'documentChanges':
            true, // docChanges aren't included in resourceOperations
        'resourceOperations': kinds.map((k) => k.toJson()).toList(),
      },
    });
  }
}

mixin LspAnalysisServerTestMixin on LspRequestHelpersMixin, LspEditHelpersMixin
    implements ClientCapabilitiesHelperMixin {
  /// A progress token used in tests where the client-provides the token, which
  /// should not be validated as being created by the server first.
  final clientProvidedTestWorkDoneToken = ProgressToken.t2('client-test');

  late String projectFolderPath,
      mainFilePath,
      nonExistentFilePath,
      pubspecFilePath,
      analysisOptionsPath;

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

  /// The current state of all diagnostics from the server.
  ///
  /// A file that has never had diagnostics will not be in the map. A file that
  /// has ever had diagnostics will be in the map, even if the entry is an empty
  /// list.
  final diagnostics = <Uri, List<Diagnostic>>{};

  /// Whether to fail tests if any error notifications are received from the
  /// server.
  ///
  /// This does not need to be set when using [expectErrorNotification].
  bool failTestOnAnyErrorNotification = true;

  /// Whether to fail tests if any error diagnostics are received from the
  /// server.
  bool failTestOnErrorDiagnostic = true;

  /// [analysisOptionsPath] as a 'file:///' [Uri].
  Uri get analysisOptionsUri => pathContext.toUri(analysisOptionsPath);

  /// A stream of [NotificationMessage]s from the server that may be errors.
  Stream<NotificationMessage> get errorNotificationsFromServer {
    return notificationsFromServer.where(_isErrorNotification);
  }

  /// The experimental capabilities returned from the server during initialization.
  Map<String, Object?> get experimentalServerCapabilities =>
      serverCapabilities.experimental as Map<String, Object?>? ?? {};

  /// A [Future] that completes with the first analysis after initialization.
  Future<void> get initialAnalysis =>
      initialized ? Future.value() : waitForAnalysisComplete();

  bool get initialized => _clientCapabilities != null;

  /// The URI for an augmentation for [mainFileUri].
  Uri get mainFileAugmentationUri => mainFileUri.replace(
    path: mainFileUri.path.replaceFirst('.dart', '_augmentation.dart'),
  );

  /// The URI for the macro-generated contents for [mainFileUri].
  Uri get mainFileMacroUri => mainFileUri.replace(scheme: macroClientUriScheme);

  /// [mainFilePath] as a 'file:///' [Uri].
  Uri get mainFileUri => pathContext.toUri(mainFilePath);

  /// [nonExistentFilePath] as a 'file:///' [Uri].
  Uri get nonExistentFileUri => pathContext.toUri(nonExistentFilePath);

  /// A stream of [NotificationMessage]s from the server.
  @override
  Stream<NotificationMessage> get notificationsFromServer {
    return serverToClient
        .where((m) => m is NotificationMessage)
        .cast<NotificationMessage>();
  }

  /// A stream of [OpenUriParams] for any `dart/openUri` notifications.
  Stream<OpenUriParams> get openUriNotifications => notificationsFromServer
      .where((notification) => notification.method == CustomMethods.openUri)
      .map(
        (message) =>
            OpenUriParams.fromJson(message.params as Map<String, Object?>),
      );

  path.Context get pathContext;

  /// [projectFolderPath] as a 'file:///' [Uri].
  Uri get projectFolderUri => pathContext.toUri(projectFolderPath);

  /// A stream of diagnostic notifications from the server.
  Stream<PublishDiagnosticsParams> get publishedDiagnostics {
    return notificationsFromServer
        .where(
          (notification) =>
              notification.method == Method.textDocument_publishDiagnostics,
        )
        .map(
          (notification) => PublishDiagnosticsParams.fromJson(
            notification.params as Map<String, Object?>,
          ),
        );
  }

  /// [pubspecFilePath] as a 'file:///' [Uri].
  Uri get pubspecFileUri => pathContext.toUri(pubspecFilePath);

  /// A stream of [RequestMessage]s from the server.
  Stream<RequestMessage> get requestsFromServer {
    return serverToClient
        .where((m) => m is RequestMessage)
        .cast<RequestMessage>();
  }

  /// The capabilities returned from the server during initialization.
  ServerCapabilities get serverCapabilities => _serverCapabilities!;

  Stream<Message> get serverToClient;

  /// A stream of [ShowMessageParams] for any `window/logMessage` notifications.
  Stream<ShowMessageParams> get showMessageNotifications =>
      notificationsFromServer
          .where(
            (notification) => notification.method == Method.window_showMessage,
          )
          .map(
            (message) => ShowMessageParams.fromJson(
              message.params as Map<String, Object?>,
            ),
          );

  String get testPackageRootPath => projectFolderPath;

  Future<void> changeFile(
    int newVersion,
    Uri uri,
    List<TextDocumentContentChangeEvent> changes,
  ) async {
    var notification = makeNotification(
      Method.textDocument_didChange,
      DidChangeTextDocumentParams(
        textDocument: VersionedTextDocumentIdentifier(
          version: newVersion,
          uri: uri,
        ),
        contentChanges: changes,
      ),
    );
    await sendNotificationToServer(notification);
  }

  Future<void> changeWorkspaceFolders({
    List<Uri>? add,
    List<Uri>? remove,
  }) async {
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
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    await sendNotificationToServer(notification);
  }

  Future<Object?> executeCodeAction(
    Either2<Command, CodeAction> codeAction,
  ) async {
    var command = codeAction.map(
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
    var supportedCommands =
        _serverCapabilities?.executeCommandProvider?.commands ?? [];
    if (!supportedCommands.contains(command.command)) {
      throw ArgumentError(
        'Server does not support ${command.command}. '
        'Is it missing from serverSupportedCommands?',
      );
    }
    var request = makeRequest(
      Method.workspace_executeCommand,
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
        workDoneToken: workDoneToken,
      ),
    );
    return expectSuccessfulResponseTo<T, Map<String, Object?>>(
      request,
      decoder ?? (result) => result as T,
    );
  }

  Future<ShowMessageParams> expectErrorNotification(
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    var firstError = errorNotificationsFromServer.first;

    failTestOnAnyErrorNotification = false;

    await f();
    var notificationFromServer = await firstError.timeout(timeout);

    failTestOnAnyErrorNotification = true;

    expect(notificationFromServer, isNotNull);
    return ShowMessageParams.fromJson(
      notificationFromServer.params as Map<String, Object?>,
    );
  }

  Future<T> expectNotification<T>(
    bool Function(NotificationMessage) test,
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    var firstError = notificationsFromServer.firstWhere(test);
    await f();

    var notificationFromServer = await firstError.timeout(timeout);

    expect(notificationFromServer, isNotNull);
    return notificationFromServer.params as T;
  }

  /// Expects a [method] request from the server after executing [f].
  Future<RequestMessage> expectRequest(
    Method method,
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    var firstRequest = requestsFromServer.firstWhere((n) => n.method == method);
    await f();

    var requestFromServer = await firstRequest.timeout(timeout);

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
    var incomingRequest = await expectRequest(method, () {
      // Don't return/await the response yet, as this may not complete until
      // after we have handled the request that comes from the server.
      outboundRequest = f();

      // Because we don't await this future until "later", if it throws the
      // error is treated as unhandled and will fail the test. Attaching an
      // error handler prevents that, though since the Future completed with
      // an error it will still be handled as such when the future is later
      // awaited.

      // TODO(srawlins): Fix this static error.
      // ignore: body_might_complete_normally_catch_error
      outboundRequest.catchError((_) {});
    });

    // Handle the request from the server and send the response back.
    var clientsResponse = await handler(
      fromJson(incomingRequest.params as Map<String, Object?>),
    );
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
    Map<String, Object?>? experimentalCapabilities,
    Map<String, Object?>? initializationOptions,
    bool throwOnFailure = true,
    bool allowEmptyRootUri = false,
    bool includeClientRequestTime = false,
    void Function()? immediatelyAfterInitialized,
  }) async {
    this.includeClientRequestTime = includeClientRequestTime;

    errorNotificationsFromServer.listen((NotificationMessage error) {
      // Always subscribe to this and check the flag here so it can be toggled
      // during tests (for example automatically by expectErrorNotification).
      if (failTestOnAnyErrorNotification) {
        fail('${error.toJson()}');
      }
    });

    publishedDiagnostics.listen((diagnostics) {
      if (failTestOnErrorDiagnostic &&
          diagnostics.diagnostics.any(
            (diagnostic) => diagnostic.severity == DiagnosticSeverity.Error,
          )) {
        fail('Unexpected diagnostics: ${diagnostics.toJson()}');
      }
    });

    var clientCapabilities = ClientCapabilities(
      workspace: workspaceCapabilities,
      textDocument: textDocumentCapabilities,
      window: windowCapabilities,
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

    // Track diagnostics from the server so tests can easily access the current
    // state.
    trackDiagnostics(diagnostics);

    // Assume if none of the project options were set, that we want to default to
    // opening the test project folder.
    if (rootPath == null &&
        rootUri == null &&
        workspaceFolders == null &&
        !allowEmptyRootUri) {
      rootUri = pathContext.toUri(projectFolderPath);
    }
    var request = makeRequest(
      Method.initialize,
      InitializeParams(
        rootPath: rootPath,
        rootUri: rootUri,
        initializationOptions:
            initializationOptions ?? defaultInitializationOptions,
        capabilities: clientCapabilities,
        workspaceFolders: workspaceFolders?.map(toWorkspaceFolder).toList(),
      ),
    );
    var response = await sendRequestToServer(request);
    expect(response.id, equals(request.id));

    var error = response.error;
    if (error == null) {
      var result = InitializeResult.fromJson(
        response.result as Map<String, Object?>,
      );
      _serverCapabilities = result.capabilities;

      var notification = makeNotification(
        Method.initialized,
        InitializedParams(),
      );

      var initializedNotification = sendNotificationToServer(notification);
      immediatelyAfterInitialized?.call();
      await initializedNotification;
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
      clientRequestTime:
          includeClientRequestTime
              ? DateTime.now().millisecondsSinceEpoch
              : null,
    );
  }

  RequestMessage makeRenameRequest(
    int? version,
    Uri uri,
    Position pos,
    String newName,
  ) {
    var docIdentifier =
        version != null
            ? VersionedTextDocumentIdentifier(version: version, uri: uri)
            : TextDocumentIdentifier(uri: uri);
    var request = makeRequest(
      Method.textDocument_rename,
      RenameParams(
        newName: newName,
        textDocument: docIdentifier,
        position: pos,
      ),
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
  ) => monitorDynamicUnregistrations(
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
        registrations.removeWhere(
          (element) => unregistrationParams.unregisterations.any(
            (u) => u.id == element.id,
          ),
        );
      },
    );
  }

  Future<void> openFile(Uri uri, String content, {int version = 1}) async {
    var notification = makeNotification(
      Method.textDocument_didOpen,
      DidOpenTextDocumentParams(
        textDocument: TextDocumentItem(
          uri: uri,
          languageId: dartLanguageId,
          version: version,
          text: content,
        ),
      ),
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

  /// Calls the supplied function and responds to any `workspace/configuration`
  /// request with the supplied config.
  ///
  /// Automatically enables `workspace/configuration` support.
  Future<T> provideConfig<T>(
    Future<T> Function() f,
    FutureOr<Map<String, Object?>> globalConfig, {
    FutureOr<Map<String, Map<String, Object?>>>? folderConfig,
  }) {
    var self = this;
    if (self is AbstractLspAnalysisServerTest) {
      self.setConfigurationSupport();
    }
    return handleExpectedRequest<
      T,
      ConfigurationParams,
      List<Map<String, Object?>>
    >(
      Method.workspace_configuration,
      ConfigurationParams.fromJson,
      f,
      handler: (configurationParams) async {
        // We must respond to the request for config with items that match the
        // request. For any item in the request without a folder, we will return
        // the global config. For any item in the request with a folder we will
        // return the config for that item in the map, or fall back to the global
        // config if it does not exist.
        var global = await globalConfig;
        var folders = await folderConfig;
        return configurationParams.items.map((requestedConfig) {
          var uri = requestedConfig.scopeUri;
          var path = uri != null ? pathContext.fromUri(uri) : null;
          // Use the config the test provided for this path, or fall back to
          // global.
          return (folders != null ? folders[path] : null) ?? global;
        }).toList();
      },
    );
  }

  /// Returns the range of [pattern] in [code].
  Range rangeOfPattern(TestCode code, Pattern pattern) {
    var content = code.code;
    var match = pattern.allMatches(content).first;
    return Range(
      start: positionFromOffset(match.start, content),
      end: positionFromOffset(match.end, content),
    );
  }

  /// Returns the range of [searchText] in [code].
  Range rangeOfString(TestCode code, String searchText) =>
      rangeOfPattern(code, searchText);

  /// Returns the range of [searchText] in [content].
  Range rangeOfStringInString(String content, String searchText) {
    var match = searchText.allMatches(content).first;
    return Range(
      start: positionFromOffset(match.start, content),
      end: positionFromOffset(match.end, content),
    );
  }

  /// Returns a [Range] that covers the entire of [content].
  Range rangeOfWholeContent(String content) {
    return Range(
      start: positionFromOffset(0, content),
      end: positionFromOffset(content.length, content),
    );
  }

  /// Gets the range in [content] that beings with the string [prefix] and
  /// has a length matching [text].
  Range rangeStartingAtString(String content, String prefix, String text) {
    var offset = content.indexOf(prefix);
    var end = offset + text.length;
    return Range(
      start: positionFromOffset(offset, content),
      end: positionFromOffset(end, content),
    );
  }

  Future<WorkspaceEdit?> rename(
    Uri uri,
    int? version,
    Position pos,
    String newName,
  ) {
    var request = makeRenameRequest(version, uri, pos, newName);
    return expectSuccessfulResponseTo(request, WorkspaceEdit.fromJson);
  }

  Future<ResponseMessage> renameRaw(
    Uri uri,
    int version,
    Position pos,
    String newName,
  ) {
    var request = makeRenameRequest(version, uri, pos, newName);
    return sendRequestToServer(request);
  }

  Future<void> replaceFile(int newVersion, Uri uri, String content) {
    return changeFile(newVersion, uri, [
      TextDocumentContentChangeEvent.t2(
        TextDocumentContentChangeWholeDocument(text: content),
      ),
    ]);
  }

  /// Sends [responseParams] to the server as a successful response to
  /// a server-initiated [request].
  void respondTo<T>(RequestMessage request, T responseParams) {
    sendResponseToServer(
      ResponseMessage(
        id: request.id,
        result: responseParams,
        jsonrpc: jsonRpcVersion,
      ),
    );
  }

  Future<ResponseMessage> sendDidChangeConfiguration() {
    var request = makeRequest(
      Method.workspace_didChangeConfiguration,
      DidChangeConfigurationParams(),
    );
    return sendRequestToServer(request);
  }

  void sendExit() {
    var request = makeRequest(Method.exit, null);
    sendRequestToServer(request);
  }

  FutureOr<void> sendNotificationToServer(NotificationMessage notification);

  Future<ResponseMessage> sendRequestToServer(RequestMessage request);

  void sendResponseToServer(ResponseMessage response);

  // This is the signature expected for LSP.
  // https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#:~:text=Response%3A-,result%3A%20null,-error%3A%20code%20and
  // ignore: prefer_void_to_null
  Future<Null> sendShutdown() {
    var request = makeRequest(Method.shutdown, null);
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
    return WorkspaceFolder(uri: uri, name: path.basename(uri.path));
  }

  /// Records the latest diagnostics for each file in [latestDiagnostics].
  ///
  /// [latestDiagnostics] maps from a URI to the set of current diagnostics.
  StreamSubscription<PublishDiagnosticsParams> trackDiagnostics(
    Map<Uri, List<Diagnostic>> latestDiagnostics,
  ) {
    return publishedDiagnostics.listen((diagnostics) {
      latestDiagnostics[diagnostics.uri] = diagnostics.diagnostics;
    });
  }

  /// Tells the server the config has changed, and provides the supplied config
  /// when it requests the updated config.
  Future<ResponseMessage> updateConfig(Map<String, dynamic> config) {
    return provideConfig(sendDidChangeConfiguration, config);
  }

  Future<void> waitForAnalysisComplete() => waitForAnalysisStatus(false);

  Future<void> waitForAnalysisStart() => waitForAnalysisStatus(true);

  Future<void> waitForAnalysisStatus(bool analyzing) async {
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.analyzerStatus) {
        if (_clientCapabilities!.window?.workDoneProgress == true) {
          throw Exception(
            'Received ${CustomMethods.analyzerStatus} notification '
            'but client supports workDoneProgress',
          );
        }

        var params = AnalyzerStatusParams.fromJson(
          message.params as Map<String, Object?>,
        );
        return params.isAnalyzing == analyzing;
      } else if (message.method == Method.progress) {
        if (_clientCapabilities!.window?.workDoneProgress != true) {
          throw Exception(
            'Received ${CustomMethods.analyzerStatus} notification '
            'but client supports workDoneProgress',
          );
        }

        var params = ProgressParams.fromJson(
          message.params as Map<String, Object?>,
        );

        // Skip unrelated progress notifications.
        if (params.token != analyzingProgressToken) {
          return false;
        }

        if (params.value is Map<String, dynamic>) {
          var isDesiredStatusMessage =
              analyzing
                  ? WorkDoneProgressBegin.canParse(
                    params.value,
                    nullLspJsonReporter,
                  )
                  : WorkDoneProgressEnd.canParse(
                    params.value,
                    nullLspJsonReporter,
                  );

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
          message.params as Map<String, Object?>,
        );

        return closingLabelsParams.uri == uri;
      }
      return false;
    });
    return closingLabelsParams.labels;
  }

  Future<List<Diagnostic>?> waitForDiagnostics(Uri uri) async {
    return publishedDiagnostics
        .where((params) => params.uri == uri)
        .map<List<Diagnostic>?>((params) => params.diagnostics)
        .firstWhere((_) => true, orElse: () => null);
  }

  Future<FlutterOutline> waitForFlutterOutline(Uri uri) async {
    late PublishFlutterOutlineParams outlineParams;
    await notificationsFromServer.firstWhere((message) {
      if (message.method == CustomMethods.publishFlutterOutline) {
        outlineParams = PublishFlutterOutlineParams.fromJson(
          message.params as Map<String, Object?>,
        );

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
          message.params as Map<String, Object?>,
        );

        return outlineParams.uri == uri;
      }
      return false;
    });
    return outlineParams.outline;
  }

  Future<void> _handleProgress(NotificationMessage request) async {
    var params = ProgressParams.fromJson(
      request.params as Map<String, Object?>,
    );
    if (params.token != clientProvidedTestWorkDoneToken &&
        !validProgressTokens.contains(params.token)) {
      throw Exception(
        'Server sent a progress notification for a token '
        'that has not been created: ${params.token}',
      );
    }

    if (WorkDoneProgressEnd.canParse(params.value, nullLspJsonReporter)) {
      validProgressTokens.remove(params.token);
    }
  }

  Future<void> _handleWorkDoneProgressCreate(RequestMessage request) async {
    if (_clientCapabilities!.window?.workDoneProgress != true) {
      throw Exception(
        'Server sent ${Method.window_workDoneProgress_create} '
        'but client capabilities do not allow',
      );
    }
    var params = WorkDoneProgressCreateParams.fromJson(
      request.params as Map<String, Object?>,
    );
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
    var method = notification.method;
    var params = notification.params as Map<String, Object?>?;
    if (method == Method.window_logMessage && params != null) {
      return LogMessageParams.fromJson(params).type == MessageType.Error;
    } else if (method == Method.window_showMessage && params != null) {
      return ShowMessageParams.fromJson(params).type == MessageType.Error;
    } else {
      return false;
    }
  }
}
