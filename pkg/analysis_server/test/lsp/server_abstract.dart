// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/analytics/noop_analytics.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
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
import 'package:test/test.dart' as test show expect;

import '../mocks.dart';
import '../mocks_lsp.dart';
import '../src/utilities/mock_packages.dart';

const dartLanguageId = 'dart';

/// Useful for debugging locally, setting this to true will cause all JSON
/// communication to be printed to stdout.
const debugPrintCommunication = false;

abstract class AbstractLspAnalysisServerTest
    with
        ResourceProviderMixin,
        ClientCapabilitiesHelperMixin,
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
        AnalyticsManager(NoopAnalytics()),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE,
        httpClient: httpClient,
        processRunner: processRunner,
        dartFixPromptManager: dartFixPromptManager);
    server.pluginManager = pluginManager;

    projectFolderPath = convertPath('/home/my_project');
    projectFolderUri = Uri.file(projectFolderPath);
    newFolder(projectFolderPath);
    newFolder(join(projectFolderPath, 'lib'));
    // Create a folder and file to aid testing that includes imports/completion.
    newFolder(join(projectFolderPath, 'lib', 'folder'));
    newFile(join(projectFolderPath, 'lib', 'file.dart'), '');
    mainFilePath = join(projectFolderPath, 'lib', 'main.dart');
    mainFileUri = Uri.file(mainFilePath);
    pubspecFilePath = join(projectFolderPath, file_paths.pubspecYaml);
    pubspecFileUri = Uri.file(pubspecFilePath);
    analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');
    newFile(analysisOptionsPath, '''
analyzer:
  enable-experiment:
    - records
    - patterns
    - sealed-class
''');

    analysisOptionsUri = Uri.file(analysisOptionsPath);
    writePackageConfig(projectFolderPath);
  }

  Future<void> tearDown() async {
    channel.close();
    await server.shutdown();
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

  TextDocumentClientCapabilities
      withAllSupportedTextDocumentDynamicRegistrations(
    TextDocumentClientCapabilities source,
  ) {
    // This list (when combined with the workspace list) should match all of
    // the fields listed in `ClientDynamicRegistrations.supported`.
    return extendTextDocumentCapabilities(source, {
      'synchronization': {'dynamicRegistration': true},
      'callHierarchy': {'dynamicRegistration': true},
      'completion': {'dynamicRegistration': true},
      'hover': {'dynamicRegistration': true},
      'inlayHint': {'dynamicRegistration': true},
      'signatureHelp': {'dynamicRegistration': true},
      'references': {'dynamicRegistration': true},
      'documentHighlight': {'dynamicRegistration': true},
      'documentSymbol': {'dynamicRegistration': true},
      'colorProvider': {'dynamicRegistration': true},
      'formatting': {'dynamicRegistration': true},
      'onTypeFormatting': {'dynamicRegistration': true},
      'rangeFormatting': {'dynamicRegistration': true},
      'declaration': {'dynamicRegistration': true},
      'definition': {'dynamicRegistration': true},
      'implementation': {'dynamicRegistration': true},
      'codeAction': {'dynamicRegistration': true},
      'rename': {'dynamicRegistration': true},
      'foldingRange': {'dynamicRegistration': true},
      'selectionRange': {'dynamicRegistration': true},
      'semanticTokens': SemanticTokensClientCapabilities(
          dynamicRegistration: true,
          requests: SemanticTokensClientCapabilitiesRequests(),
          formats: [],
          tokenModifiers: [],
          tokenTypes: []).toJson(),
      'typeDefinition': {'dynamicRegistration': true},
      'typeHierarchy': {'dynamicRegistration': true},
    });
  }

  WorkspaceClientCapabilities withAllSupportedWorkspaceDynamicRegistrations(
    WorkspaceClientCapabilities source,
  ) {
    // This list (when combined with the textDocument list) should match all of
    // the fields listed in `ClientDynamicRegistrations.supported`.
    return extendWorkspaceCapabilities(source, {
      'fileOperations': {'dynamicRegistration': true},
    });
  }

  WorkspaceClientCapabilities withApplyEditSupport(
    WorkspaceClientCapabilities source,
  ) {
    return extendWorkspaceCapabilities(source, {'applyEdit': true});
  }

  TextDocumentClientCapabilities withCodeActionKinds(
    TextDocumentClientCapabilities source,
    List<CodeActionKind> kinds,
  ) {
    return extendTextDocumentCapabilities(source, {
      'codeAction': {
        'codeActionLiteralSupport': {
          'codeActionKind': {'valueSet': kinds.map((k) => k.toJson()).toList()}
        }
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemDeprecatedFlagSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItem': {'deprecatedSupport': true}
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemInsertReplaceSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItem': {'insertReplaceSupport': true}
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemInsertTextModeSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
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

  TextDocumentClientCapabilities withCompletionItemKinds(
    TextDocumentClientCapabilities source,
    List<CompletionItemKind> kinds,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItemKind': {
          'valueSet': kinds.map((k) => k.toJson()).toList()
        }
      }
    });
  }

  TextDocumentClientCapabilities withCompletionItemSnippetSupport(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionItem': {'snippetSupport': true}
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

  TextDocumentClientCapabilities withCompletionListDefaults(
    TextDocumentClientCapabilities source,
    List<String> defaults,
  ) {
    return extendTextDocumentCapabilities(source, {
      'completion': {
        'completionList': {
          'itemDefaults': defaults,
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
    WorkspaceClientCapabilities source,
  ) {
    return extendWorkspaceCapabilities(source, {
      'workspaceEdit': {'documentChanges': true}
    });
  }

  TextDocumentClientCapabilities withDocumentFormattingDynamicRegistration(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'formatting': {'dynamicRegistration': true},
      'onTypeFormatting': {'dynamicRegistration': true},
      'rangeFormatting': {'dynamicRegistration': true},
    });
  }

  TextDocumentClientCapabilities withDocumentSymbolKinds(
    TextDocumentClientCapabilities source,
    List<SymbolKind> kinds,
  ) {
    return extendTextDocumentCapabilities(source, {
      'documentSymbol': {
        'symbolKind': {'valueSet': kinds.map((k) => k.toJson()).toList()}
      }
    });
  }

  WorkspaceClientCapabilities withFileOperationDynamicRegistration(
    WorkspaceClientCapabilities source,
  ) {
    return extendWorkspaceCapabilities(source, {
      'fileOperations': {'dynamicRegistration': true}
    });
  }

  TextDocumentClientCapabilities withGivenTextDocumentDynamicRegistrations(
    TextDocumentClientCapabilities source,
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
    return extendTextDocumentCapabilities(source, {
      name: json,
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

  TextDocumentClientCapabilities withHoverDynamicRegistration(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'hover': {'dynamicRegistration': true}
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
    List<MarkupKind> formats,
  ) {
    return extendTextDocumentCapabilities(source, {
      'signatureHelp': {
        'signatureInformation': {
          'documentationFormat': formats.map((k) => k.toJson()).toList()
        }
      }
    });
  }

  TextDocumentClientCapabilities withTextSyncDynamicRegistration(
    TextDocumentClientCapabilities source,
  ) {
    return extendTextDocumentCapabilities(source, {
      'synchronization': {'dynamicRegistration': true}
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

mixin LspAnalysisServerTestMixin implements ClientCapabilitiesHelperMixin {
  static const positionMarker = '^';
  static const rangeMarkerStart = '[[';
  static const rangeMarkerEnd = ']]';
  static const allMarkers = [positionMarker, rangeMarkerStart, rangeMarkerEnd];
  static final allMarkersPattern =
      RegExp(allMarkers.map(RegExp.escape).join('|'));

  /// A progress token used in tests where the client-provides the token, which
  /// should not be validated as being created by the server first.
  final clientProvidedTestWorkDoneToken = ProgressToken.t2('client-test');

  int _id = 0;
  late String projectFolderPath,
      mainFilePath,
      pubspecFilePath,
      analysisOptionsPath;
  late Uri projectFolderUri, mainFileUri, pubspecFileUri, analysisOptionsUri;
  final String simplePubspecContent = 'name: my_project';
  final startOfDocPos = Position(line: 0, character: 0);
  final startOfDocRange = Range(
      start: Position(line: 0, character: 0),
      end: Position(line: 0, character: 0));

  /// The client capabilities sent to the server during initialization.
  ///
  /// null if an initialization request has not yet been sent.
  ClientCapabilities? _clientCapabilities;

  final validProgressTokens = <ProgressToken>{};

  /// Whether to include 'clientRequestTime' fields in outgoing messages.
  bool includeClientRequestTime = false;

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

  /// A stream of [RequestMessage]s from the server.
  Stream<RequestMessage> get requestsFromServer {
    return serverToClient
        .where((m) => m is RequestMessage)
        .cast<RequestMessage>();
  }

  Stream<Message> get serverToClient;

  void applyChanges(
    Map<String, String> fileContents,
    Map<Uri, List<TextEdit>> changes,
  ) {
    changes.forEach((fileUri, edits) {
      final path = fileUri.toFilePath();
      fileContents[path] = applyTextEdits(fileContents[path]!, edits);
    });
  }

  void applyDocumentChanges(
    Map<String, String> fileContents,
    List<Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>
        documentChanges, {
    Map<String, int>? expectedVersions,
  }) {
    // If we were supplied with expected versions, ensure that all returned
    // edits match the versions.
    if (expectedVersions != null) {
      expectDocumentVersions(documentChanges, expectedVersions);
    }
    applyResourceChanges(fileContents, documentChanges);
  }

  void applyResourceChanges(
    Map<String, String> oldFileContent,
    List<Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>> changes,
  ) {
    for (final change in changes) {
      change.map(
        (create) => applyResourceCreate(oldFileContent, create),
        (delete) => throw 'applyResourceChanges:Delete not currently supported',
        (rename) => applyResourceRename(oldFileContent, rename),
        (textDocEdit) => applyTextDocumentEdits(oldFileContent, [textDocEdit]),
      );
    }
  }

  void applyResourceCreate(
      Map<String, String> oldFileContent, CreateFile create) {
    final path = create.uri.toFilePath();
    if (oldFileContent.containsKey(path)) {
      throw 'Received create instruction for $path which already existed.';
    }
    oldFileContent[path] = '';
  }

  void applyResourceRename(
      Map<String, String> oldFileContent, RenameFile rename) {
    final oldPath = rename.oldUri.toFilePath();
    final newPath = rename.newUri.toFilePath();
    if (!oldFileContent.containsKey(oldPath)) {
      throw 'Received rename instruction for $oldPath which did not exist.';
    }
    oldFileContent[newPath] = oldFileContent[oldPath]!;
    oldFileContent.remove(oldPath);
  }

  String applyTextDocumentEdit(String content, TextDocumentEdit edit) {
    // To simulate the behaviour we'll get from an LSP client, apply edits from
    // the latest offset to the earliest, but with items at the same offset
    // being reversed so that when applied sequentially they appear in the
    // document in-order.
    //
    // This is essentially a stable sort over the offset (descending), but since
    // List.sort() is not stable so we additionally sort by index).
    final indexedEdits =
        edit.edits.mapIndexed(_TextEditWithIndex.fromUnion).toList();
    indexedEdits.sort(_TextEditWithIndex.compare);
    return indexedEdits.map((e) => e.edit).fold(content, applyTextEdit);
  }

  void applyTextDocumentEdits(
      Map<String, String> oldFileContent, List<TextDocumentEdit> edits) {
    for (var edit in edits) {
      final path = edit.textDocument.uri.toFilePath();
      if (!oldFileContent.containsKey(path)) {
        throw 'Received edits for $path which was not provided as a file to be edited. '
            'Perhaps a CreateFile change was missing from the edits?';
      }
      oldFileContent[path] = applyTextDocumentEdit(oldFileContent[path]!, edit);
    }
  }

  String applyTextEdit(String content, TextEdit edit) {
    final startPos = edit.range.start;
    final endPos = edit.range.end;
    final lineInfo = LineInfo.fromContent(content);
    final start = lineInfo.getOffsetOfLine(startPos.line) + startPos.character;
    final end = lineInfo.getOffsetOfLine(endPos.line) + endPos.character;
    return content.replaceRange(start, end, edit.newText);
  }

  String applyTextEdits(String content, List<TextEdit> changes) {
    // Complex text manipulations are described with an array of TextEdit's,
    // representing a single change to the document.
    //
    // All text edits ranges refer to positions in the original document. Text
    // edits ranges must never overlap, that means no part of the original
    // document must be manipulated by more than one edit. It is possible
    // that multiple edits have the same start position (eg. multiple inserts in
    // reverse order), however since that involves complicated tracking and we
    // only apply edits here sequentially, we don't supported them. We do sort
    // edits to ensure we apply the later ones first, so we can assume the locations
    // in the edit are still valid against the new string as each edit is applied.

    /// Ensures changes are simple enough to apply easily without any complicated
    /// logic.
    void validateChangesCanBeApplied() {
      /// Check if a position is before (but not equal) to another position.
      bool isBeforeOrEqual(Position p, Position other) =>
          p.line < other.line ||
          (p.line == other.line && p.character <= other.character);

      /// Check if a position is after (but not equal) to another position.
      bool isAfterOrEqual(Position p, Position other) =>
          p.line > other.line ||
          (p.line == other.line && p.character >= other.character);
      // Check if two ranges intersect.
      bool rangesIntersect(Range r1, Range r2) {
        var endsBefore = isBeforeOrEqual(r1.end, r2.start);
        var startsAfter = isAfterOrEqual(r1.start, r2.end);
        return !(endsBefore || startsAfter);
      }

      for (final change1 in changes) {
        for (final change2 in changes) {
          if (change1 != change2 &&
              rangesIntersect(change1.range, change2.range)) {
            throw 'Test helper applyTextEdits does not support applying multiple edits '
                'where the edits are not in reverse order.';
          }
        }
      }
    }

    validateChangesCanBeApplied();

    final indexedEdits = changes.mapIndexed(_TextEditWithIndex.new).toList();
    indexedEdits.sort(_TextEditWithIndex.compare);
    return indexedEdits.map((e) => e.edit).fold(content, applyTextEdit);
  }

  Future<List<CallHierarchyIncomingCall>?> callHierarchyIncoming(
      CallHierarchyItem item) {
    final request = makeRequest(
      Method.callHierarchy_incomingCalls,
      CallHierarchyIncomingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyIncomingCall.fromJson));
  }

  Future<List<CallHierarchyOutgoingCall>?> callHierarchyOutgoing(
      CallHierarchyItem item) {
    final request = makeRequest(
      Method.callHierarchy_outgoingCalls,
      CallHierarchyOutgoingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyOutgoingCall.fromJson));
  }

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

  /// Gets the entire range for [code].
  Range entireRange(String code) => Range(
        start: startOfDocPos,
        end: positionFromOffset(code.length, code),
      );

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

  void expect(Object? actual, Matcher matcher, {String? reason}) =>
      test.expect(actual, matcher, reason: reason);

  void expectDocumentVersion(
    TextDocumentEdit edit,
    Map<String, int> expectedVersions,
  ) {
    final path = edit.textDocument.uri.toFilePath();
    final expectedVersion = expectedVersions[path];

    expect(edit.textDocument.version, equals(expectedVersion));
  }

  /// Validates the document versions for a set of edits match the versions in
  /// the supplied map.
  void expectDocumentVersions(
    List<Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>
        documentChanges,
    Map<String, int> expectedVersions,
  ) {
    // For resource changes, we only need to validate changes since
    // creates/renames/deletes do not supply versions.
    for (var change in documentChanges) {
      change.map(
        (create) {},
        (delete) {},
        (rename) {},
        (edit) => expectDocumentVersion(edit, expectedVersions),
      );
    }
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

  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson);

  Future<List<TextEdit>?> formatDocument(Uri fileUri) {
    final request = makeRequest(
      Method.textDocument_formatting,
      DocumentFormattingParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<TextEdit>?> formatOnType(
      Uri fileUri, Position pos, String character) {
    final request = makeRequest(
      Method.textDocument_onTypeFormatting,
      DocumentOnTypeFormattingParams(
        ch: character,
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<TextEdit>?> formatRange(Uri fileUri, Range range) {
    final request = makeRequest(
      Method.textDocument_rangeFormatting,
      DocumentRangeFormattingParams(
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<Either2<Command, CodeAction>>> getCodeActions(
    Uri fileUri, {
    Range? range,
    Position? position,
    List<CodeActionKind>? kinds,
    CodeActionTriggerKind? triggerKind,
  }) {
    range ??= position != null
        ? Range(start: position, end: position)
        : throw 'Supply either a Range or Position for CodeActions requests';
    final request = makeRequest(
      Method.textDocument_codeAction,
      CodeActionParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
        context: CodeActionContext(
          // TODO(dantup): We may need to revise the tests/implementation when
          // it's clear how we're supposed to handle diagnostics:
          // https://github.com/Microsoft/language-server-protocol/issues/583
          diagnostics: [],
          only: kinds,
          triggerKind: triggerKind,
        ),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(_generateFromJsonFor(Command.canParse, Command.fromJson,
          CodeAction.canParse, CodeAction.fromJson)),
    );
  }

  Future<List<ColorPresentation>> getColorPresentation(
      Uri fileUri, Range range, Color color) {
    final request = makeRequest(
      Method.textDocument_colorPresentation,
      ColorPresentationParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
        color: color,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(ColorPresentation.fromJson),
    );
  }

  Future<List<CompletionItem>> getCompletion(Uri uri, Position pos,
      {CompletionContext? context}) async {
    final response = await getCompletionList(uri, pos, context: context);
    return response.items;
  }

  Future<CompletionList> getCompletionList(Uri uri, Position pos,
      {CompletionContext? context}) {
    final request = makeRequest(
      Method.textDocument_completion,
      CompletionParams(
        context: context,
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, CompletionList.fromJson);
  }

  Future<Either2<List<Location>, List<LocationLink>>> getDefinition(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_definition,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          _canParseList(Location.canParse),
          _fromJsonList(Location.fromJson),
          _canParseList(LocationLink.canParse),
          _fromJsonList(LocationLink.fromJson)),
    );
  }

  Future<List<Location>> getDefinitionAsLocation(Uri uri, Position pos) async {
    final results = await getDefinition(uri, pos);
    return results.map(
      (locations) => locations,
      (locationLinks) => throw 'Expected List<Location> got List<LocationLink>',
    );
  }

  Future<List<LocationLink>> getDefinitionAsLocationLinks(
      Uri uri, Position pos) async {
    final results = await getDefinition(uri, pos);
    return results.map(
      (locations) => throw 'Expected List<LocationLink> got List<Location>',
      (locationLinks) => locationLinks,
    );
  }

  Future<DartDiagnosticServer> getDiagnosticServer() {
    final request = makeRequest(
      CustomMethods.diagnosticServer,
      null,
    );
    return expectSuccessfulResponseTo(request, DartDiagnosticServer.fromJson);
  }

  Future<List<ColorInformation>> getDocumentColors(Uri fileUri) {
    final request = makeRequest(
      Method.textDocument_documentColor,
      DocumentColorParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(ColorInformation.fromJson),
    );
  }

  Future<List<DocumentHighlight>?> getDocumentHighlights(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_documentHighlight,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(DocumentHighlight.fromJson));
  }

  Future<Either2<List<DocumentSymbol>, List<SymbolInformation>>>
      getDocumentSymbols(Uri uri) {
    final request = makeRequest(
      Method.textDocument_documentSymbol,
      DocumentSymbolParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          _canParseList(DocumentSymbol.canParse),
          _fromJsonList(DocumentSymbol.fromJson),
          _canParseList(SymbolInformation.canParse),
          _fromJsonList(SymbolInformation.fromJson)),
    );
  }

  Future<List<FoldingRange>> getFoldingRanges(Uri uri) {
    final request = makeRequest(
      Method.textDocument_foldingRange,
      FoldingRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(FoldingRange.fromJson));
  }

  Future<Hover?> getHover(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_hover,
      TextDocumentPositionParams(
          textDocument: TextDocumentIdentifier(uri: uri), position: pos),
    );
    return expectSuccessfulResponseTo(request, Hover.fromJson);
  }

  Future<List<Location>> getImplementations(
    Uri uri,
    Position pos, {
    includeDeclarations = false,
  }) {
    final request = makeRequest(
      Method.textDocument_implementation,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(Location.fromJson));
  }

  Future<List<InlayHint>> getInlayHints(Uri uri, Range range) {
    final request = makeRequest(
      Method.textDocument_inlayHint,
      InlayHintParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(InlayHint.fromJson));
  }

  Future<List<Location>> getReferences(
    Uri uri,
    Position pos, {
    bool includeDeclarations = false,
  }) {
    final request = makeRequest(
      Method.textDocument_references,
      ReferenceParams(
        context: ReferenceContext(includeDeclaration: includeDeclarations),
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(Location.fromJson));
  }

  Future<CompletionItem> getResolvedCompletion(
    Uri uri,
    Position pos,
    String label, {
    CompletionContext? context,
  }) async {
    final completions = await getCompletion(uri, pos, context: context);

    final completion = completions.singleWhere((c) => c.label == label);
    expect(completion, isNotNull);

    return resolveCompletion(completion);
  }

  Future<List<SelectionRange>?> getSelectionRanges(
      Uri uri, List<Position> positions) {
    final request = makeRequest(
      Method.textDocument_selectionRange,
      SelectionRangeParams(
          textDocument: TextDocumentIdentifier(uri: uri), positions: positions),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(SelectionRange.fromJson));
  }

  Future<SemanticTokens> getSemanticTokens(Uri uri) {
    final request = makeRequest(
      Method.textDocument_semanticTokens_full,
      SemanticTokensParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SemanticTokens> getSemanticTokensRange(Uri uri, Range range) {
    final request = makeRequest(
      Method.textDocument_semanticTokens_range,
      SemanticTokensRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SignatureHelp?> getSignatureHelp(Uri uri, Position pos,
      [SignatureHelpContext? context]) {
    final request = makeRequest(
      Method.textDocument_signatureHelp,
      SignatureHelpParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
        context: context,
      ),
    );
    return expectSuccessfulResponseTo(request, SignatureHelp.fromJson);
  }

  Future<Location> getSuper(
    Uri uri,
    Position pos,
  ) {
    final request = makeRequest(
      CustomMethods.super_,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Location.fromJson);
  }

  Future<TextDocumentTypeDefinitionResult> getTypeDefinition(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_typeDefinition,
      TypeDefinitionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );

    // TextDocumentTypeDefinitionResult is a nested Either, so we need to handle
    // nested fromJson/canParse here.
    // TextDocumentTypeDefinitionResult: Either2<Definition, List<DefinitionLink>>?
    // Definition: Either2<List<Location>, Location>

    // Definition = Either2<List<Location>, Location>
    final definitionCanParse = _generateCanParseFor(
      _canParseList(Location.canParse),
      Location.canParse,
    );
    final definitionFromJson = _generateFromJsonFor(
      _canParseList(Location.canParse),
      _fromJsonList(Location.fromJson),
      Location.canParse,
      Location.fromJson,
    );

    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          definitionCanParse,
          definitionFromJson,
          _canParseList(DefinitionLink.canParse),
          _fromJsonList(DefinitionLink.fromJson)),
    );
  }

  Future<List<Location>> getTypeDefinitionAsLocation(
      Uri uri, Position pos) async {
    final results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => locationOrList.map(
        (locations) => locations,
        (location) => [location],
      ),
      (locationLinks) => throw 'Expected Locations, got LocationLinks',
    );
  }

  Future<List<LocationLink>> getTypeDefinitionAsLocationLinks(
      Uri uri, Position pos) async {
    final results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => throw 'Expected LocationLinks, got Locations',
      (locationLinks) => locationLinks,
    );
  }

  Future<List<SymbolInformation>> getWorkspaceSymbols(String query) {
    final request = makeRequest(
      Method.workspace_symbol,
      WorkspaceSymbolParams(query: query),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(SymbolInformation.fromJson));
  }

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
      workspace: workspaceCapabilities,
      textDocument: textDocumentCapabilities,
      window: windowCapabilities,
      experimental: experimentalCapabilities,
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
      rootUri = Uri.file(projectFolderPath);
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

  RequestMessage makeRequest(Method method, ToJsonable? params) {
    final id = Either2<int, String>.t1(_id++);
    return RequestMessage(
      id: id,
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
      clientRequestTime: includeClientRequestTime
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
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

  Position positionFromOffset(int offset, String contents) {
    final lineInfo = LineInfo.fromContent(withoutMarkers(contents));
    return toPosition(lineInfo.getLocation(offset));
  }

  Future<List<CallHierarchyItem>?> prepareCallHierarchy(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareCallHierarchy,
      CallHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyItem.fromJson));
  }

  Future<PlaceholderAndRange?> prepareRename(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareRename,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, PlaceholderAndRange.fromJson);
  }

  Future<List<TypeHierarchyItem>?> prepareTypeHierarchy(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareTypeHierarchy,
      TypeHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
  }

  /// Calls the supplied function and responds to any `workspace/configuration`
  /// request with the supplied config.
  Future<T> provideConfig<T>(
    Future<T> Function() f,
    FutureOr<Map<String, Object?>> globalConfig, {
    FutureOr<Map<String, Map<String, Object?>>>? folderConfig,
  }) {
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
            final path = uri != null ? Uri.parse(uri).toFilePath() : null;
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

  Future<CompletionItem> resolveCompletion(CompletionItem item) {
    final request = makeRequest(
      Method.completionItem_resolve,
      item,
    );
    return expectSuccessfulResponseTo(request, CompletionItem.fromJson);
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

  Future<List<TypeHierarchyItem>?> typeHierarchySubtypes(
      TypeHierarchyItem item) {
    final request = makeRequest(
      Method.typeHierarchy_subtypes,
      TypeHierarchySubtypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
  }

  Future<List<TypeHierarchyItem>?> typeHierarchySupertypes(
      TypeHierarchyItem item) {
    final request = makeRequest(
      Method.typeHierarchy_supertypes,
      TypeHierarchySupertypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
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

  bool Function(Object?, LspJsonReporter) _canParseList<T>(
          bool Function(Map<String, Object?>, LspJsonReporter) canParse) =>
      (input, reporter) =>
          input is List &&
          input
              .cast<Map<String, Object?>>()
              .every((item) => canParse(item, reporter));

  List<T> Function(List<Object?>) _fromJsonList<T>(
          T Function(Map<String, Object?>) fromJson) =>
      (input) => input.cast<Map<String, Object?>>().map(fromJson).toList();

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

  /// Creates a `canParse()` function for an `Either2<T1, T2>` using
  /// the `canParse` function for each type.
  static bool Function(Object?, LspJsonReporter) _generateCanParseFor<T1, T2>(
    bool Function(Object?, LspJsonReporter) canParse1,
    bool Function(Object?, LspJsonReporter) canParse2,
  ) {
    return (input, reporter) =>
        canParse1(input, reporter) || canParse2(input, reporter);
  }

  /// Creates a `fromJson()` function for an `Either2<T1, T2>` using
  /// the `canParse` and `fromJson` functions for each type.
  static Either2<T1, T2> Function(Object?) _generateFromJsonFor<T1, T2, R1, R2>(
      bool Function(Object?, LspJsonReporter) canParse1,
      T1 Function(R1) fromJson1,
      bool Function(Object?, LspJsonReporter) canParse2,
      T2 Function(R2) fromJson2,
      [LspJsonReporter? reporter]) {
    reporter ??= nullLspJsonReporter;
    return (input) {
      reporter!;
      if (canParse1(input, reporter)) {
        return Either2<T1, T2>.t1(fromJson1(input as R1));
      }
      if (canParse2(input, reporter)) {
        return Either2<T1, T2>.t2(fromJson2(input as R2));
      }
      throw '$input was not one of ($T1, $T2)';
    };
  }
}

class _TextEditWithIndex {
  final int index;
  final TextEdit edit;

  _TextEditWithIndex(this.index, this.edit);

  _TextEditWithIndex.fromUnion(
      this.index, Either3<AnnotatedTextEdit, SnippetTextEdit, TextEdit> edit)
      : edit = edit.map((e) => e, (e) => e, (e) => e);

  /// Compares two [_TextEditWithIndex] to sort them by the order in which they
  /// can be sequentially applied to a String to match the behaviour of an LSP
  /// client.
  static int compare(_TextEditWithIndex edit1, _TextEditWithIndex edit2) {
    final end1 = edit1.edit.range.end;
    final end2 = edit2.edit.range.end;

    // VS Code's implementation of this is here:
    // https://github.com/microsoft/vscode/blob/856a306d1a9b0879727421daf21a8059e671e3ea/src/vs/editor/common/model/pieceTreeTextBuffer/pieceTreeTextBuffer.ts#L475

    if (end1.line != end2.line) {
      return end1.line.compareTo(end2.line) * -1;
    } else if (end1.character != end2.character) {
      return end1.character.compareTo(end2.character) * -1;
    } else {
      return edit1.index.compareTo(edit2.index) * -1;
    }
  }
}
