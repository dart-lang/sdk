// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;
import 'dart:math' show max;

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions, MessageType;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/flutter/flutter_notifications.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_errors.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_hover.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_imported_elements.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_navigation.dart';
import 'package:analysis_server/src/handler/legacy/analysis_get_signature.dart';
import 'package:analysis_server/src/handler/legacy/analysis_reanalyze.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_analysis_roots.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_general_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_priority_files.dart';
import 'package:analysis_server/src/handler/legacy/analysis_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/analysis_update_content.dart';
import 'package:analysis_server/src/handler/legacy/analysis_update_options.dart';
import 'package:analysis_server/src/handler/legacy/analytics_enable.dart';
import 'package:analysis_server/src/handler/legacy/analytics_is_enabled.dart';
import 'package:analysis_server/src/handler/legacy/analytics_send_event.dart';
import 'package:analysis_server/src/handler/legacy/analytics_send_timing.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestion_details.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestion_details2.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestions2.dart';
import 'package:analysis_server/src/handler/legacy/completion_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/diagnostic_get_diagnostics.dart';
import 'package:analysis_server/src/handler/legacy/diagnostic_get_server_port.dart';
import 'package:analysis_server/src/handler/legacy/edit_bulk_fixes.dart';
import 'package:analysis_server/src/handler/legacy/edit_format.dart';
import 'package:analysis_server/src/handler/legacy/edit_format_if_enabled.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_assists.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_available_refactorings.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_fixes.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_postfix_completion.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_refactoring.dart';
import 'package:analysis_server/src/handler/legacy/edit_get_statement_completion.dart';
import 'package:analysis_server/src/handler/legacy/edit_import_elements.dart';
import 'package:analysis_server/src/handler/legacy/edit_is_postfix_completion_applicable.dart';
import 'package:analysis_server/src/handler/legacy/edit_list_postfix_completion_templates.dart';
import 'package:analysis_server/src/handler/legacy/edit_organize_directives.dart';
import 'package:analysis_server/src/handler/legacy/edit_sort_members.dart';
import 'package:analysis_server/src/handler/legacy/execution_create_context.dart';
import 'package:analysis_server/src/handler/legacy/execution_delete_context.dart';
import 'package:analysis_server/src/handler/legacy/execution_get_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/execution_map_uri.dart';
import 'package:analysis_server/src/handler/legacy/execution_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/flutter_get_widget_description.dart';
import 'package:analysis_server/src/handler/legacy/flutter_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/flutter_set_widget_property_value.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/handler/legacy/lsp_over_legacy_handler.dart';
import 'package:analysis_server/src/handler/legacy/search_find_element_references.dart';
import 'package:analysis_server/src/handler/legacy/search_find_member_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_find_member_references.dart';
import 'package:analysis_server/src/handler/legacy/search_find_top_level_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_get_element_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_get_type_hierarchy.dart';
import 'package:analysis_server/src/handler/legacy/server_cancel_request.dart';
import 'package:analysis_server/src/handler/legacy/server_get_version.dart';
import 'package:analysis_server/src/handler/legacy/server_set_client_capabilities.dart';
import 'package:analysis_server/src/handler/legacy/server_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/server_shutdown.dart';
import 'package:analysis_server/src/handler/legacy/unsupported_request.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart' as lsp;
import 'package:analysis_server/src/lsp/client_configuration.dart' as lsp;
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/debounce_requests.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/server/features.dart';
import 'package:analysis_server/src/server/performance.dart';
import 'package:analysis_server/src/server/sdk_configuration.dart';
import 'package:analysis_server/src/services/completion/completion_state.dart';
import 'package:analysis_server/src/services/execution/execution_context.dart';
import 'package:analysis_server/src/services/flutter/widget_descriptions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_manager.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/process.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as analysis;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation_dart.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:telemetry/telemetry.dart' as telemetry;
import 'package:watcher/watcher.dart';

/// A function that can be executed to create a handler for a request.
typedef HandlerGenerator = LegacyHandler Function(
    LegacyAnalysisServer, Request, CancellationToken, OperationPerformanceImpl);

typedef OptionUpdater = void Function(AnalysisOptionsImpl options);

/// Various IDE options.
class AnalysisServerOptions {
  String? newAnalysisDriverLog;

  String? clientId;
  String? clientVersion;

  /// Base path where to cache data.
  String? cacheFolder;

  /// The path to the package config file override.
  /// If `null`, then the default discovery mechanism is used.
  String? packagesFile;

  /// The analytics instance; note, this object can be `null`, and should be
  /// accessed via a null-aware operator.
  telemetry.Analytics? analytics;

  /// The crash report sender instance; note, this object can be `null`, and
  /// should be accessed via a null-aware operator.
  CrashReportSender? crashReportSender;

  /// An optional set of configuration overrides specified by the SDK.
  ///
  /// These overrides can provide new values for configuration settings, and are
  /// generally used in specific SDKs (like the internal google3 one).
  SdkConfiguration? configurationOverrides;

  /// Whether to use the Language Server Protocol.
  bool useLanguageServerProtocol = false;

  /// The set of enabled features.
  FeatureSet featureSet = FeatureSet();

  /// If set, this string will be reported as the protocol version.
  String? reportProtocolVersion;

  /// Experiments which have been enabled (or disabled) via the
  /// `--enable-experiment` command-line option.
  List<String> enabledExperiments = [];
}

/// Instances of the class [LegacyAnalysisServer] implement a server that
/// listens on a [CommunicationChannel] for analysis requests and processes
/// them.
class LegacyAnalysisServer extends AnalysisServer {
  /// A map from the name of a request to a function used to create a request
  /// handler.
  ///
  /// Requests that don't match anything in this map will be passed to
  /// [_LspOverLegacyHandler] for possible handling before returning an error.
  static final Map<String, HandlerGenerator> requestHandlerGenerators = {
    ANALYSIS_REQUEST_GET_ERRORS: AnalysisGetErrorsHandler.new,
    ANALYSIS_REQUEST_GET_HOVER: AnalysisGetHoverHandler.new,
    ANALYSIS_REQUEST_GET_IMPORTED_ELEMENTS:
        AnalysisGetImportedElementsHandler.new,
    ANALYSIS_REQUEST_GET_LIBRARY_DEPENDENCIES: UnsupportedRequestHandler.new,
    ANALYSIS_REQUEST_GET_NAVIGATION: AnalysisGetNavigationHandler.new,
    ANALYSIS_REQUEST_GET_REACHABLE_SOURCES: UnsupportedRequestHandler.new,
    ANALYSIS_REQUEST_GET_SIGNATURE: AnalysisGetSignatureHandler.new,
    ANALYSIS_REQUEST_REANALYZE: AnalysisReanalyzeHandler.new,
    ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS: AnalysisSetAnalysisRootsHandler.new,
    ANALYSIS_REQUEST_SET_GENERAL_SUBSCRIPTIONS:
        AnalysisSetGeneralSubscriptionsHandler.new,
    ANALYSIS_REQUEST_SET_PRIORITY_FILES: AnalysisSetPriorityFilesHandler.new,
    ANALYSIS_REQUEST_SET_SUBSCRIPTIONS: AnalysisSetSubscriptionsHandler.new,
    ANALYSIS_REQUEST_UPDATE_CONTENT: AnalysisUpdateContentHandler.new,
    ANALYSIS_REQUEST_UPDATE_OPTIONS: AnalysisUpdateOptionsHandler.new,
    //
    ANALYTICS_REQUEST_IS_ENABLED: AnalyticsIsEnabledHandler.new,
    ANALYTICS_REQUEST_ENABLE: AnalyticsEnableHandler.new,
    ANALYTICS_REQUEST_SEND_EVENT: AnalyticsSendEventHandler.new,
    ANALYTICS_REQUEST_SEND_TIMING: AnalyticsSendTimingHandler.new,
    //
    COMPLETION_REQUEST_GET_SUGGESTION_DETAILS:
        CompletionGetSuggestionDetailsHandler.new,
    COMPLETION_REQUEST_GET_SUGGESTION_DETAILS2:
        CompletionGetSuggestionDetails2Handler.new,
    COMPLETION_REQUEST_GET_SUGGESTIONS: CompletionGetSuggestionsHandler.new,
    COMPLETION_REQUEST_GET_SUGGESTIONS2: CompletionGetSuggestions2Handler.new,
    COMPLETION_REQUEST_SET_SUBSCRIPTIONS: CompletionSetSubscriptionsHandler.new,
    //
    DIAGNOSTIC_REQUEST_GET_DIAGNOSTICS: DiagnosticGetDiagnosticsHandler.new,
    DIAGNOSTIC_REQUEST_GET_SERVER_PORT: DiagnosticGetServerPortHandler.new,
    //
    EDIT_REQUEST_FORMAT: EditFormatHandler.new,
    EDIT_REQUEST_FORMAT_IF_ENABLED: EditFormatIfEnabledHandler.new,
    EDIT_REQUEST_GET_ASSISTS: EditGetAssistsHandler.new,
    EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS:
        EditGetAvailableRefactoringsHandler.new,
    EDIT_REQUEST_BULK_FIXES: EditBulkFixes.new,
    EDIT_REQUEST_GET_FIXES: EditGetFixesHandler.new,
    EDIT_REQUEST_GET_REFACTORING: EditGetRefactoringHandler.new,
    EDIT_REQUEST_IMPORT_ELEMENTS: EditImportElementsHandler.new,
    EDIT_REQUEST_ORGANIZE_DIRECTIVES: EditOrganizeDirectivesHandler.new,
    EDIT_REQUEST_SORT_MEMBERS: EditSortMembersHandler.new,
    EDIT_REQUEST_GET_STATEMENT_COMPLETION:
        EditGetStatementCompletionHandler.new,
    EDIT_REQUEST_IS_POSTFIX_COMPLETION_APPLICABLE:
        EditIsPostfixCompletionApplicableHandler.new,
    EDIT_REQUEST_GET_POSTFIX_COMPLETION: EditGetPostfixCompletionHandler.new,
    EDIT_REQUEST_LIST_POSTFIX_COMPLETION_TEMPLATES:
        EditListPostfixCompletionTemplatesHandler.new,
    //
    EXECUTION_REQUEST_CREATE_CONTEXT: ExecutionCreateContextHandler.new,
    EXECUTION_REQUEST_DELETE_CONTEXT: ExecutionDeleteContextHandler.new,
    EXECUTION_REQUEST_GET_SUGGESTIONS: ExecutionGetSuggestionsHandler.new,
    EXECUTION_REQUEST_MAP_URI: ExecutionMapUriHandler.new,
    EXECUTION_REQUEST_SET_SUBSCRIPTIONS: ExecutionSetSubscriptionsHandler.new,
    //
    FLUTTER_REQUEST_GET_WIDGET_DESCRIPTION:
        FlutterGetWidgetDescriptionHandler.new,
    FLUTTER_REQUEST_SET_WIDGET_PROPERTY_VALUE:
        FlutterSetWidgetPropertyValueHandler.new,
    FLUTTER_REQUEST_SET_SUBSCRIPTIONS: FlutterSetSubscriptionsHandler.new,
    //
    SEARCH_REQUEST_FIND_ELEMENT_REFERENCES:
        SearchFindElementReferencesHandler.new,
    SEARCH_REQUEST_FIND_MEMBER_DECLARATIONS:
        SearchFindMemberDeclarationsHandler.new,
    SEARCH_REQUEST_FIND_MEMBER_REFERENCES:
        SearchFindMemberReferencesHandler.new,
    SEARCH_REQUEST_FIND_TOP_LEVEL_DECLARATIONS:
        SearchFindTopLevelDeclarationsHandler.new,
    SEARCH_REQUEST_GET_ELEMENT_DECLARATIONS:
        SearchGetElementDeclarationsHandler.new,
    SEARCH_REQUEST_GET_TYPE_HIERARCHY: SearchGetTypeHierarchyHandler.new,
    //
    SERVER_REQUEST_CANCEL_REQUEST: ServerCancelRequestHandler.new,
    SERVER_REQUEST_GET_VERSION: ServerGetVersionHandler.new,
    SERVER_REQUEST_SET_CLIENT_CAPABILITIES:
        ServerSetClientCapabilitiesHandler.new,
    SERVER_REQUEST_SET_SUBSCRIPTIONS: ServerSetSubscriptionsHandler.new,
    SERVER_REQUEST_SHUTDOWN: ServerShutdownHandler.new,

    //
    LSP_REQUEST_HANDLE: LspOverLegacyHandler.new,
  };

  /// The channel from which requests are received and to which responses should
  /// be sent.
  final ServerCommunicationChannel channel;

  /// A flag indicating the value of the 'analyzing' parameter sent in the last
  /// status message to the client.
  bool statusAnalyzing = false;

  /// A set of the [ServerService]s to send notifications for.
  Set<ServerService> serverServices = {};

  /// A table mapping request ids to cancellation tokens that allow cancelling
  /// the request.
  ///
  /// Tokens are removed once a request completes and should not be assumed to
  /// exist in this table just because cancellation was requested.
  Map<String, CancelableToken> cancellationTokens = {};

  /// A set of the [GeneralAnalysisService]s to send notifications for.
  Set<GeneralAnalysisService> generalAnalysisServices = {};

  /// A table mapping [AnalysisService]s to the file paths for which these
  /// notifications should be sent.
  Map<AnalysisService, Set<String>> analysisServices = {};

  /// The most recently registered set of client capabilities. The default is to
  /// have no registered requests.
  ServerSetClientCapabilitiesParams clientCapabilities =
      ServerSetClientCapabilitiesParams([]);

  @override
  final lspClientCapabilities = lsp.LspClientCapabilities(
    lsp.ClientCapabilities(
      textDocument: lsp.TextDocumentClientCapabilities(
        hover: lsp.HoverClientCapabilities(
          contentFormat: [
            lsp.MarkupKind.Markdown,
          ],
        ),
      ),
    ),
  );

  @override
  final lsp.LspClientConfiguration lspClientConfiguration;

  /// A table mapping [FlutterService]s to the file paths for which these
  /// notifications should be sent.
  Map<FlutterService, Set<String>> flutterServices = {};

  /// The support for Flutter properties.
  WidgetDescriptions flutterWidgetDescriptions = WidgetDescriptions();

  /// The state used by the completion domain handlers.
  final CompletionState completionState = CompletionState();

  /// The workspace for rename refactorings.
  late RefactoringWorkspace refactoringWorkspace;

  /// The object used to manage uncompleted refactorings.
  late RefactoringManager? _refactoringManager;

  /// The context used by the execution domain handlers.
  final ExecutionContext executionContext = ExecutionContext();

  /// The next search response id.
  int nextSearchId = 0;

  /// The [Completer] that completes when analysis is complete.
  Completer<void>? _onAnalysisCompleteCompleter;

  /// The controller that is notified when analysis is started.
  final StreamController<bool> _onAnalysisStartedController =
      StreamController.broadcast();

  /// If the "analysis.analyzedFiles" notification is currently being subscribed
  /// to (see [generalAnalysisServices]), and at least one such notification has
  /// been sent since the subscription was enabled, the set of analyzed files
  /// that was delivered in the most recently sent notification.  Otherwise
  /// `null`.
  Set<String>? prevAnalyzedFiles;

  /// The controller for [onAnalysisSetChanged].
  final StreamController<void> _onAnalysisSetChangedController =
      StreamController.broadcast(sync: true);

  /// An optional manager to handle file systems which may not always be
  /// available.
  final DetachableFileSystemManager? detachableFileSystemManager;

  /// The broadcast stream of requests that were discarded because there
  /// was another request that made this one irrelevant.
  @visibleForTesting
  final StreamController<Request> discardedRequests =
      StreamController.broadcast(sync: true);

  /// The index of the next request from the server to the client.
  int nextServerRequestId = 0;

  /// A table mapping the ids of requests sent from the server to the client
  /// that have not yet received a response, to the completer used to return the
  /// response when it has been received.
  Map<String, Completer<Response>> pendingServerRequests = {};

  /// Initialize a newly created server to receive requests from and send
  /// responses to the given [channel].
  ///
  /// If [rethrowExceptions] is true, then any exceptions thrown by analysis are
  /// propagated up the call stack.  The default is true to allow analysis
  /// exceptions to show up in unit tests, but it should be set to false when
  /// running a full analysis server.
  LegacyAnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    AnalysisServerOptions options,
    DartSdkManager sdkManager,
    AnalyticsManager analyticsManager,
    CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder,
    InstrumentationService instrumentationService, {
    http.Client? httpClient,
    ProcessRunner? processRunner,
    RequestStatisticsHelper? requestStatistics,
    DiagnosticServer? diagnosticServer,
    this.detachableFileSystemManager,
    // Disable to avoid using this in unit tests.
    bool enableBlazeWatcher = false,
    DartFixPromptManager? dartFixPromptManager,
  })  : lspClientConfiguration =
            lsp.LspClientConfiguration(baseResourceProvider.pathContext),
        super(
          options,
          sdkManager,
          diagnosticServer,
          analyticsManager,
          crashReportingAttachmentsBuilder,
          baseResourceProvider,
          instrumentationService,
          httpClient,
          processRunner,
          NotificationManager(channel, baseResourceProvider.pathContext),
          requestStatistics: requestStatistics,
          enableBlazeWatcher: enableBlazeWatcher,
          dartFixPromptManager: dartFixPromptManager,
        ) {
    var contextManagerCallbacks =
        ServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;

    analysisDriverScheduler.status.listen(handleAnalysisStatusChange);
    analysisDriverScheduler.start();

    onAnalysisStarted.first.then((_) {
      onAnalysisComplete.then((_) {
        performance = performanceAfterStartup = ServerPerformance();
      });
    });
    channel.sendNotification(
      ServerConnectedParams(
        options.reportProtocolVersion ?? PROTOCOL_VERSION,
        io.pid,
      ).toNotification(),
    );
    debounceRequests(channel, discardedRequests)
        .listen(handleRequestOrResponse, onDone: done, onError: error);
    refactoringWorkspace = RefactoringWorkspace(driverMap.values, searchEngine);
    _newRefactoringManager();
  }

  /// The [Future] that completes when analysis is complete.
  Future<void> get onAnalysisComplete {
    if (isAnalysisComplete()) {
      return Future.value();
    }
    var completer = _onAnalysisCompleteCompleter ??= Completer<void>();
    return completer.future;
  }

  /// The stream that is notified when the analysis set is changed - this might
  /// be a change to a file, external via a watch event, or internal via
  /// overlay. This means that the resolved world might have changed.
  ///
  /// The type of produced elements is not specified and should not be used.
  Stream<void> get onAnalysisSetChanged =>
      _onAnalysisSetChangedController.stream;

  /// The stream that is notified with `true` when analysis is started.
  Stream<bool> get onAnalysisStarted {
    return _onAnalysisStartedController.stream;
  }

  @override
  OpenUriNotificationSender? get openUriNotificationSender {
    if (!clientCapabilities.requests.contains('openUrlRequest')) {
      return null;
    }

    return (Uri uri) async {
      final requestId = '${nextServerRequestId++}';
      await sendRequest(
        ServerOpenUrlRequestParams('$uri').toRequest(requestId),
      );
    };
  }

  RefactoringManager? get refactoringManager {
    var refactoringManager = _refactoringManager;
    if (refactoringManager == null) {
      return null;
    }
    if (refactoringManager.hasPendingRequest) {
      refactoringManager.cancel();
      _newRefactoringManager();
    }
    return _refactoringManager;
  }

  String get sdkPath {
    return sdkManager.defaultSdkDirectory;
  }

  @override
  bool get supportsShowMessageRequest =>
      clientCapabilities.requests.contains('showMessageRequest');

  void cancelRequest(String id) {
    cancellationTokens[id]?.cancel();
  }

  Future<void> dispose() async {}

  /// The socket from which requests are being read has been closed.
  void done() {}

  /// There was an error related to the socket from which requests are being
  /// read.
  void error(argument) {}

  /// Return the cached analysis result for the file with the given [path].
  /// If there is no cached result, return `null`.
  ResolvedUnitResult? getCachedResolvedUnit(String path) {
    if (!file_paths.isDart(resourceProvider.pathContext, path)) {
      return null;
    }

    var driver = getAnalysisDriver(path);
    return driver?.getCachedResult(path);
  }

  @override
  FutureOr<void> handleAnalysisStatusChange(analysis.AnalysisStatus status) {
    super.handleAnalysisStatusChange(status);
    sendStatusNotificationNew(status);
  }

  /// Handle a [request] that was read from the communication channel.
  void handleRequest(Request request) {
    final startTime = DateTime.now();
    performance.logRequestTiming(request.clientRequestTime);

    // Because we don't `await` the execution of the handlers, we wrap the
    // execution in order to have one central place to handle exceptions.
    runZonedGuarded(() async {
      // Record performance information for the request.
      final rootPerformance = OperationPerformanceImpl('<root>');
      RequestPerformance? requestPerformance;
      await rootPerformance.runAsync('request', (performance) async {
        requestPerformance = RequestPerformance(
          operation: request.method,
          performance: performance,
          requestLatency: request.timeSinceRequest,
          startTime: startTime,
        );
        recentPerformance.requests.add(requestPerformance!);

        var cancellationToken = CancelableToken();
        cancellationTokens[request.id] = cancellationToken;
        var generator = requestHandlerGenerators[request.method];
        if (generator != null) {
          var handler =
              generator(this, request, cancellationToken, performance);
          if (!handler.recordsOwnAnalytics) {
            analyticsManager.startedRequest(
                request: request, startTime: startTime);
          }
          await handler.handle();
        } else {
          analyticsManager.startedRequest(
              request: request, startTime: startTime);
          sendResponse(Response.unknownRequest(request));
        }
      });
      if (requestPerformance != null &&
          requestPerformance!.performance.elapsed >
              ServerRecentPerformance.slowRequestsThreshold) {
        recentPerformance.slowRequests.add(requestPerformance!);
      }
    }, (exception, stackTrace) {
      if (exception is InconsistentAnalysisException) {
        sendResponse(Response.contentModified(request));
      } else if (exception is RequestFailure) {
        sendResponse(exception.response);
      } else {
        // Log the exception.
        instrumentationService.logException(
          FatalException(
            'Failed to handle request: ${request.method}',
            exception,
            stackTrace,
          ),
          null,
          crashReportingAttachmentsBuilder.forException(exception),
        );
        // Then return an error response to the client.
        var error =
            RequestError(RequestErrorCode.SERVER_ERROR, exception.toString());
        error.stackTrace = stackTrace.toString();
        var response = Response(request.id, error: error);
        sendResponse(response);
      }
    });
  }

  /// Handle a [request] that was read from the communication channel.
  void handleRequestOrResponse(RequestOrResponse requestOrResponse) {
    if (requestOrResponse is Request) {
      handleRequest(requestOrResponse);
    } else if (requestOrResponse is Response) {
      handleResponse(requestOrResponse);
    }
  }

  /// Handle a [response] that was read from the communication channel.
  void handleResponse(Response response) {
    var completer = pendingServerRequests.remove(response.id);
    if (completer != null) {
      completer.complete(response);
    }
  }

  /// Return `true` if the [path] is both absolute and normalized.
  bool isAbsoluteAndNormalized(String path) {
    var pathContext = resourceProvider.pathContext;
    return pathContext.isAbsolute(path) && pathContext.normalize(path) == path;
  }

  /// Return `true` if analysis is complete.
  bool isAnalysisComplete() {
    return !analysisDriverScheduler.isAnalyzing;
  }

  /// Return `true` if the given path is a valid `FilePath`.
  ///
  /// This means that it is absolute and normalized.
  bool isValidFilePath(String path) {
    return resourceProvider.pathContext.isAbsolute(path) &&
        resourceProvider.pathContext.normalize(path) == path;
  }

  @override
  void notifyFlutterWidgetDescriptions(String path) {
    flutterWidgetDescriptions.flush();
  }

  /// Send the given [notification] to the client.
  void sendNotification(Notification notification) {
    channel.sendNotification(notification);
  }

  /// Send the given [request] to the client.
  Future<Response> sendRequest(Request request) {
    var completer = Completer<Response>();
    pendingServerRequests[request.id] = completer;
    channel.sendRequest(request);
    return completer.future;
  }

  /// Send the given [response] to the client.
  void sendResponse(Response response) {
    channel.sendResponse(response);
    analyticsManager.sentResponse(response: response);
    cancellationTokens.remove(response.id);
  }

  /// If the [path] is not a valid file path, that is absolute and normalized,
  /// send an error response, and return `true`. If OK then return `false`.
  bool sendResponseErrorIfInvalidFilePath(Request request, String path) {
    if (!isAbsoluteAndNormalized(path)) {
      sendResponse(Response.invalidFilePathFormat(request, path));
      return true;
    }
    return false;
  }

  /// Sends a `server.error` notification.
  @override
  void sendServerErrorNotification(
    String message,
    dynamic exception,
    /*StackTrace*/ stackTrace, {
    bool fatal = false,
  }) {
    var msg = exception == null ? message : '$message: $exception';
    if (stackTrace != null && exception is! CaughtException) {
      stackTrace = StackTrace.current;
    }

    // send the notification
    channel.sendNotification(
        ServerErrorParams(fatal, msg, '$stackTrace').toNotification());

    // remember the last few exceptions
    if (exception is CaughtException) {
      stackTrace ??= exception.stackTrace;
    }

    exceptions.add(ServerException(
      message,
      exception,
      stackTrace is StackTrace ? stackTrace : StackTrace.current,
      fatal,
    ));
  }

  /// Send status notification to the client. The state of analysis is given by
  /// the [status] information.
  void sendStatusNotificationNew(analysis.AnalysisStatus status) {
    var isAnalyzing = status.isAnalyzing;
    if (isAnalyzing) {
      _onAnalysisStartedController.add(true);
    }
    var onAnalysisCompleteCompleter = _onAnalysisCompleteCompleter;
    if (onAnalysisCompleteCompleter != null && !isAnalyzing) {
      onAnalysisCompleteCompleter.complete();
      _onAnalysisCompleteCompleter = null;
    }
    // Perform on-idle actions.
    if (!isAnalyzing) {
      if (generalAnalysisServices
          .contains(GeneralAnalysisService.ANALYZED_FILES)) {
        sendAnalysisNotificationAnalyzedFiles(this);
      }
      _scheduleAnalysisImplementedNotification();
    }
    // Only send status when subscribed.
    if (!serverServices.contains(ServerService.STATUS)) {
      return;
    }
    // Only send status when it changes
    if (statusAnalyzing == isAnalyzing) {
      return;
    }
    statusAnalyzing = isAnalyzing;
    if (!isAnalyzing) {
      // Only send analysis analytics after analysis is complete.
      reportAnalysisAnalytics();
    }
    var analysis = AnalysisStatus(isAnalyzing);
    channel.sendNotification(
        ServerStatusParams(analysis: analysis).toNotification());
  }

  /// Implementation for `analysis.setAnalysisRoots`.
  ///
  /// TODO(scheglov) implement complete projects/contexts semantics.
  ///
  /// The current implementation is intentionally simplified and expected
  /// that only folders are given each given folder corresponds to the exactly
  /// one context.
  ///
  /// So, we can start working in parallel on adding services and improving
  /// projects/contexts support.
  Future<void> setAnalysisRoots(String requestId, List<String> includedPaths,
      List<String> excludedPaths) async {
    final completer = analysisContextRebuildCompleter = Completer();
    try {
      notificationManager.setAnalysisRoots(includedPaths, excludedPaths);
      try {
        await contextManager.setRoots(includedPaths, excludedPaths);
      } on UnimplementedError catch (e) {
        throw RequestFailure(Response.unsupportedFeature(
            requestId, e.message ?? 'Unsupported feature.'));
      }
      analysisDriverScheduler.transitionToAnalyzingToIdleIfNoFilesToAnalyze();
    } finally {
      completer.complete();
    }
  }

  /// Implementation for `analysis.setSubscriptions`.
  void setAnalysisSubscriptions(
      Map<AnalysisService, Set<String>> subscriptions) {
    notificationManager.setSubscriptions(subscriptions);
    analysisServices = subscriptions;
    _sendSubscriptions(analysis: true);
  }

  /// Implementation for `flutter.setSubscriptions`.
  void setFlutterSubscriptions(Map<FlutterService, Set<String>> subscriptions) {
    flutterServices = subscriptions;
    _sendSubscriptions(flutter: true);
  }

  /// Implementation for `analysis.setGeneralSubscriptions`.
  void setGeneralAnalysisSubscriptions(
      List<GeneralAnalysisService> subscriptions) {
    var newServices = subscriptions.toSet();
    if (newServices.contains(GeneralAnalysisService.ANALYZED_FILES) &&
        !generalAnalysisServices
            .contains(GeneralAnalysisService.ANALYZED_FILES) &&
        isAnalysisComplete()) {
      sendAnalysisNotificationAnalyzedFiles(this);
    } else if (!newServices.contains(GeneralAnalysisService.ANALYZED_FILES) &&
        generalAnalysisServices
            .contains(GeneralAnalysisService.ANALYZED_FILES)) {
      prevAnalyzedFiles = null;
    }
    generalAnalysisServices = newServices;
  }

  /// Set the priority files to the given [files].
  void setPriorityFiles(String requestId, List<String> files) {
    bool isPubspec(String filePath) =>
        file_paths.isPubspecYaml(resourceProvider.pathContext, filePath);

    // When pubspecs are opened, trigger pre-loading of pub package names and
    // versions.
    final pubspecs = files.where(isPubspec).toList();
    if (pubspecs.isNotEmpty) {
      pubPackageService.beginCachePreloads(pubspecs);
    }

    priorityFiles.clear();
    priorityFiles.addAll(files);
    // Set priority files in drivers.
    for (var driver in driverMap.values) {
      driver.priorityFiles = files;
    }
  }

  @override
  Future<String?> showUserPrompt(
    MessageType type,
    String message,
    List<String> actionLabels,
  ) async {
    assert(supportsShowMessageRequest);
    var requestId = (nextServerRequestId++).toString();
    var actions = actionLabels.map((label) => MessageAction(label)).toList();
    var request =
        ServerShowMessageRequestParams(type.forLegacy, message, actions)
            .toRequest(requestId);
    final response = await sendRequest(request);
    return response.result?['action'] as String?;
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();

    pubApi.close();

    // TODO(brianwilkerson) Remove the following 6 lines when the
    //  analyticsManager is being correctly initialized.
    var analytics = options.analytics;
    if (analytics != null) {
      unawaited(analytics
          .waitForLastPing(timeout: Duration(milliseconds: 200))
          .then((_) {
        analytics.close();
      }));
    }

    detachableFileSystemManager?.dispose();

    // Defer closing the channel and shutting down the instrumentation server so
    // that the shutdown response can be sent and logged.
    unawaited(Future(() {
      instrumentationService.shutdown();
      channel.close();
    }));
  }

  /// Implementation for `analysis.updateContent`.
  void updateContent(String id, Map<String, dynamic> changes) {
    _onAnalysisSetChangedController.add(null);
    changes.forEach((file, change) {
      // Prepare the old overlay contents.
      String? oldContents;
      try {
        if (resourceProvider.hasOverlay(file)) {
          oldContents = resourceProvider.getFile(file).readAsStringSync();
        }
      } catch (_) {}

      // Prepare the new contents.
      String? newContents;
      if (change is AddContentOverlay) {
        newContents = change.content;
      } else if (change is ChangeContentOverlay) {
        if (oldContents == null) {
          // The client may only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw RequestFailure(Response(id,
              error: RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, change.edits);
        } on RangeError {
          throw RequestFailure(Response(id,
              error: RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
      } else if (change is RemoveContentOverlay) {
        newContents = null;
      } else {
        // Protocol parsing should have ensured that we never get here.
        throw AnalysisException('Illegal change type');
      }

      if (newContents != null) {
        resourceProvider.setOverlay(
          file,
          content: newContents,
          modificationStamp: overlayModificationStamp++,
        );
      } else {
        resourceProvider.removeOverlay(file);
      }

      for (var driver in driverMap.values) {
        driver.changeFile(file);
      }

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      contextManager.getDriverFor(file)?.addFile(file);

      notifyDeclarationsTracker(file);
      notifyFlutterWidgetDescriptions(file);

      // TODO(scheglov) implement other cases
    });
  }

  /// Use the given updaters to update the values of the options in every
  /// existing analysis context.
  void updateOptions(List<OptionUpdater> optionUpdaters) {
    // TODO(scheglov) implement for the new analysis driver
//    //
//    // Update existing contexts.
//    //
//    for (AnalysisContext context in analysisContexts) {
//      AnalysisOptionsImpl options =
//          new AnalysisOptionsImpl.from(context.analysisOptions);
//      optionUpdaters.forEach((OptionUpdater optionUpdater) {
//        optionUpdater(options);
//      });
//      context.analysisOptions = options;
//      // TODO(brianwilkerson) As far as I can tell, this doesn't cause analysis
//      // to be scheduled for this context.
//    }
//    //
//    // Update the defaults used to create new contexts.
//    //
//    optionUpdaters.forEach((OptionUpdater optionUpdater) {
//      optionUpdater(defaultContextOptions);
//    });
  }

  /// Returns `true` if there is a subscription for the given [service] and
  /// [file].
  bool _hasAnalysisServiceSubscription(AnalysisService service, String file) {
    return analysisServices[service]?.contains(file) ?? false;
  }

  bool _hasFlutterServiceSubscription(FlutterService service, String file) {
    return flutterServices[service]?.contains(file) ?? false;
  }

  /// Initializes [_refactoringManager] with a new instance.
  void _newRefactoringManager() {
    _refactoringManager = RefactoringManager(this, refactoringWorkspace);
  }

  void _scheduleAnalysisImplementedNotification() {
    var files = analysisServices[AnalysisService.IMPLEMENTED];
    if (files != null) {
      scheduleImplementedNotification(this, files);
    }
  }

  void _sendSubscriptions({bool analysis = false, bool flutter = false}) {
    var files = <String>{};

    if (analysis) {
      for (var serviceFiles in analysisServices.values) {
        files.addAll(serviceFiles);
      }
    }

    if (flutter) {
      for (var serviceFiles in flutterServices.values) {
        files.addAll(serviceFiles);
      }
    }

    for (var file in files) {
      // The result will be produced by the "results" stream with
      // the fully resolved unit, and processed with sending analysis
      // notifications as it happens after content changes.
      if (file_paths.isDart(resourceProvider.pathContext, file)) {
        getResolvedUnit(file, sendCachedToStream: true);
      }
    }
  }
}

class ServerContextManagerCallbacks
    extends CommonServerContextManagerCallbacks {
  @override
  final LegacyAnalysisServer analysisServer;

  ServerContextManagerCallbacks(this.analysisServer, super.resourceProvider);

  AbstractNotificationManager get _notificationManager =>
      analysisServer.notificationManager;

  @override
  void afterContextsCreated() {
    super.afterContextsCreated();
    analysisServer._sendSubscriptions(analysis: true, flutter: true);
  }

  @override
  void afterWatchEvent(WatchEvent event) {
    analysisServer._onAnalysisSetChangedController.add(null);
  }

  @override
  void flushResults(List<String> files) {
    sendAnalysisNotificationFlushResults(analysisServer, files);
  }

  @override
  void handleResolvedUnitResult(ResolvedUnitResult result) {
    var path = result.path;

    var unit = result.unit;
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.HIGHLIGHTS, path)) {
      _runDelayed(() {
        _notificationManager.recordHighlightRegions(
            NotificationManager.serverId, path, _computeHighlightRegions(unit));
      });
    }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.NAVIGATION, path)) {
      _runDelayed(() {
        _notificationManager.recordNavigationParams(
            NotificationManager.serverId,
            path,
            _computeNavigationParams(path, unit));
      });
    }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.OCCURRENCES, path)) {
      _runDelayed(() {
        _notificationManager.recordOccurrences(
            NotificationManager.serverId, path, _computeOccurrences(unit));
      });
    }
    // if (analysisServer._hasAnalysisServiceSubscription(
    //     AnalysisService.OUTLINE, path)) {
    //   _runDelayed(() {
    //     // TODO(brianwilkerson) Change NotificationManager to store params
    //     // so that fileKind and libraryName can be recorded / passed along.
    //     notificationManager.recordOutlines(NotificationManager.serverId, path,
    //         _computeOutlineParams(path, unit, result.lineInfo));
    //   });
    // }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.CLOSING_LABELS, path)) {
      _runDelayed(() {
        sendAnalysisNotificationClosingLabels(
            analysisServer, path, result.lineInfo, unit);
      });
    }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.FOLDING, path)) {
      _runDelayed(() {
        sendAnalysisNotificationFolding(
            analysisServer, path, result.lineInfo, unit);
      });
    }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.OUTLINE, path)) {
      _runDelayed(() {
        sendAnalysisNotificationOutline(analysisServer, result);
      });
    }
    if (analysisServer._hasAnalysisServiceSubscription(
        AnalysisService.OVERRIDES, path)) {
      _runDelayed(() {
        sendAnalysisNotificationOverrides(analysisServer, path, unit);
      });
    }
    if (analysisServer._hasFlutterServiceSubscription(
        FlutterService.OUTLINE, path)) {
      _runDelayed(() {
        sendFlutterNotificationOutline(analysisServer, result);
      });
    }
  }

  List<HighlightRegion> _computeHighlightRegions(CompilationUnit unit) {
    return DartUnitHighlightsComputer(unit).compute();
  }

  server.AnalysisNavigationParams _computeNavigationParams(
      String path, CompilationUnit unit) {
    var collector = NavigationCollectorImpl();
    computeDartNavigation(resourceProvider, collector, unit, null, null);
    collector.createRegions();
    return server.AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  List<Occurrences> _computeOccurrences(CompilationUnit unit) {
    var collector = OccurrencesCollectorImpl();
    addDartOccurrences(collector, unit);
    return collector.allOccurrences;
  }

  /// Run [f] in a new [Future].
  ///
  /// This method is used to delay sending notifications. If there is a more
  /// important consumer of an analysis results, specifically a code completion
  /// computer, we want it to run before spending time of sending notifications.
  ///
  /// TODO(scheglov) Consider replacing this with full priority based scheduler.
  ///
  /// TODO(scheglov) Alternatively, if code completion work in a way that does
  /// not produce (at first) fully resolved unit, but only part of it - a single
  /// method, or a top-level declaration, we would not have this problem - the
  /// completion computer would be the only consumer of the partial analysis
  /// result.
  void _runDelayed(Function() f) {
    Future(f);
  }
}

/// Used to record server exceptions.
class ServerException {
  final String message;
  final dynamic exception;
  final StackTrace stackTrace;
  final bool fatal;

  ServerException(this.message, this.exception, this.stackTrace, this.fatal);

  @override
  String toString() => message;
}

/// A class used by [LegacyAnalysisServer] to record performance information
/// such as request latency.
class ServerPerformance {
  /// The creation time and the time when performance information
  /// started to be recorded here.
  final int startTime = DateTime.now().millisecondsSinceEpoch;

  /// The number of requests.
  int requestCount = 0;

  /// The number of requests that recorded latency information.
  int latencyCount = 0;

  /// The total latency (milliseconds) for all recorded requests.
  int requestLatency = 0;

  /// The maximum latency (milliseconds) for all recorded requests.
  int maxLatency = 0;

  /// The number of requests with latency > 150 milliseconds.
  int slowRequestCount = 0;

  /// Log timing information for a request.
  void logRequestTiming(int? clientRequestTime) {
    ++requestCount;
    if (clientRequestTime != null) {
      var latency = DateTime.now().millisecondsSinceEpoch - clientRequestTime;
      ++latencyCount;
      requestLatency += latency;
      maxLatency = max(maxLatency, latency);
      if (latency > 150) {
        ++slowRequestCount;
      }
    }
  }
}
