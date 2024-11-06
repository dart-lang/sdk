// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/computer/computer_closing_labels.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/notification_manager.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/server_capabilities_computer.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/server/message_scheduler.dart';
import 'package:analysis_server/src/server/performance.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/process.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as analysis;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// Instances of the class [LspAnalysisServer] implement an LSP-based server
/// that listens on a [CommunicationChannel] for LSP messages and processes
/// them.
class LspAnalysisServer extends AnalysisServer {
  /// The capabilities of the LSP client. Will be null prior to initialization.
  LspClientCapabilities? _clientCapabilities;

  /// Information about the connected client. Will be null prior to
  /// initialization or if the client did not provide it.
  ClientInfo? _clientInfo;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  LspInitializationOptions? _initializationOptions;

  /// Configuration for the workspace from the client. This is similar to
  /// initializationOptions but can be updated dynamically rather than set
  /// only when the server starts.
  @override
  final LspClientConfiguration lspClientConfiguration;

  /// The channel from which messages are received and to which responses should
  /// be sent.
  final LspServerCommunicationChannel channel;

  /// The versions of each document known to the server (keyed by path), used to
  /// send back to the client for server-initiated edits so that the client can
  /// ensure they have a matching version of the document before applying them.
  ///
  /// Handlers should prefer to use the `getVersionedDocumentIdentifier` method
  /// which will return a null-versioned identifier if the document version is
  /// not known.
  final Map<String, VersionedTextDocumentIdentifier> documentVersions = {};

  /// The message handler for the server based on the current state
  /// (uninitialized, initializing, initialized, etc.).
  late ServerStateMessageHandler messageHandler;

  /// The ID that will be used for the next outbound server-to-client request.
  int nextRequestId = 1;

  /// Completers for the responses to outbound server-to-client requests.
  final Map<int, Completer<ResponseMessage>> completers = {};

  /// Capabilities of the server. Will be null prior to initialization as
  /// the server capabilities depend on the client capabilities.
  ServerCapabilities? capabilities;
  late ServerCapabilitiesComputer capabilitiesComputer;

  /// Whether or not the server is controlling the shutdown and will exit
  /// automatically.
  bool willExit = false;

  StreamSubscription<void>? _pluginChangeSubscription;

  /// The current workspace folders provided by the client. Used as analysis roots.
  final _workspaceFolders = <String>{};

  /// A progress reporter for analysis status.
  ProgressReporter? analyzingProgressReporter;

  /// The number of times contexts have been created/recreated.
  @visibleForTesting
  int contextBuilds = 0;

  /// The subscription to the stream of incoming messages from the client.
  late final StreamSubscription<void> _channelSubscription;

  /// An optional manager to handle file systems which may not always be
  /// available.
  final DetachableFileSystemManager? detachableFileSystemManager;

  /// A flag indicating whether analysis was being performed the last time
  /// `sendStatusNotification` was invoked.
  bool wasAnalyzing = false;

  /// Whether notifications caused by analysis should be suppressed.
  ///
  /// This is used when an operation is temporarily modifying overlays and does
  /// not want the client to be notified of any analysis happening on the
  /// temporary content.
  bool suppressAnalysisResults = false;

  /// Tracks files that have non-empty diagnostics on the client.
  ///
  /// This is an optimization to avoid sending empty diagnostics when they are
  /// unnecessary (at startup, when a file is re-analyzed because a file it
  /// imports was modified, etc).
  final Set<String> _filesWithClientDiagnostics = {};

  /// A completer for [lspInitialized].
  final Completer<InitializedStateMessageHandler> _lspInitializedCompleter =
      Completer<InitializedStateMessageHandler>();

  /// Initialize a newly created server to send and receive messages to the
  /// given [channel].
  LspAnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    AnalysisServerOptions options,
    DartSdkManager sdkManager,
    AnalyticsManager analyticsManager,
    CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder,
    InstrumentationService instrumentationService, {
    http.Client? httpClient,
    ProcessRunner? processRunner,
    DiagnosticServer? diagnosticServer,
    this.detachableFileSystemManager,
    // Disable to avoid using this in unit tests.
    bool enableBlazeWatcher = false,
    DartFixPromptManager? dartFixPromptManager,
  }) : lspClientConfiguration = LspClientConfiguration(
         baseResourceProvider.pathContext,
       ),
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
         LspNotificationManager(baseResourceProvider.pathContext),
         enableBlazeWatcher: enableBlazeWatcher,
         dartFixPromptManager: dartFixPromptManager,
       ) {
    notificationManager.server = this;
    messageHandler = UninitializedStateMessageHandler(this);
    capabilitiesComputer = ServerCapabilitiesComputer(this);

    var contextManagerCallbacks = LspServerContextManagerCallbacks(
      this,
      resourceProvider,
    );
    contextManager.callbacks = contextManagerCallbacks;

    analysisDriverSchedulerEventsSubscription = analysisDriverScheduler.events
        .listen(handleAnalysisEvent);
    analysisDriverScheduler.start();

    _channelSubscription = channel.listen(
      scheduleMessage,
      onDone: done,
      onError: socketError,
    );

    if (AnalysisServer.supportsPlugins) {
      _pluginChangeSubscription = pluginManager.pluginsChanged.listen(
        (_) => _onPluginsChanged(),
      );
    }
  }

  /// The hosted location of the client application.
  ///
  /// This information is not part of the LSP spec so is only provided for
  /// clients extensions that add it to initialization options explicitly
  /// (such as Dart-Code for VS Code where it comes from 'env.appHost').
  ///
  /// This value is usually 'desktop' for desktop installs and for web will be
  /// the name of the web embedder if provided (such as 'github.dev' or
  /// 'codespaces'), else 'web'.
  String? get clientAppHost => _initializationOptions?.appHost;

  /// Information about the connected editor client. Will be `null` prior to
  /// initialization.
  ClientInfo? get clientInfo => _clientInfo;

  /// The name of the remote when the client is running using a remote workspace.
  ///
  /// This information is not part of the LSP spec so is only provided for
  /// clients extensions that add it to initialization options explicitly
  /// (such as Dart-Code for VS Code where it comes from 'env.remoteName').
  ///
  /// This value is `null` for local workspaces and will contain a string such
  /// as 'ssh-remote' or 'wsl' for remote workspaces.
  String? get clientRemoteName => _initializationOptions?.remoteName;

  /// The capabilities of the LSP client. Will be null prior to initialization.
  @override
  LspClientCapabilities? get editorClientCapabilities => _clientCapabilities;

  Future<void> get exited => channel.closed;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  LspInitializationOptions? get initializationOptions => _initializationOptions;

  /// A [Future] that completes with the [InitializedStateMessageHandler] for
  /// the server once it transitions to the initialized state.
  @override
  FutureOr<InitializedStateMessageHandler> get lspInitialized =>
      _lspInitializedCompleter.future;

  @override
  LspNotificationManager get notificationManager =>
      super.notificationManager as LspNotificationManager;

  bool get onlyAnalyzeProjectsWithOpenFiles =>
      _initializationOptions?.onlyAnalyzeProjectsWithOpenFiles ?? false;

  @override
  OpenUriNotificationSender? get openUriNotificationSender {
    if (!(initializationOptions?.allowOpenUri ?? false)) {
      return null;
    }

    return (Uri uri) async {
      var params = OpenUriParams(uri: uri);
      var message = NotificationMessage(
        method: CustomMethods.openUri,
        params: params,
        jsonrpc: jsonRpcVersion,
      );
      sendLspNotification(message);
    };
  }

  path.Context get pathContext => resourceProvider.pathContext;

  @override
  set pluginManager(PluginManager value) {
    if (AnalysisServer.supportsPlugins) {
      // we exchange the plugin manager in tests
      super.pluginManager = value;
      _pluginChangeSubscription?.cancel();

      _pluginChangeSubscription = pluginManager.pluginsChanged.listen(
        (_) => _onPluginsChanged(),
      );
    }
  }

  /// Whether or not the client has advertised support for
  /// 'window/showMessageRequest'.
  ///
  /// Callers should use [userPromptSender] instead of checking this directly.
  @override
  @protected
  bool get supportsShowMessageRequest =>
      editorClientCapabilities?.supportsShowMessageRequest ?? false;

  Future<void> addPriorityFile(String filePath) async {
    // When pubspecs are opened, trigger pre-loading of pub package names and
    // versions.
    if (file_paths.isPubspecYaml(resourceProvider.pathContext, filePath)) {
      pubPackageService.beginCachePreloads([filePath]);
    }

    var didAdd = priorityFiles.add(filePath);
    assert(didAdd);
    if (didAdd) {
      _updateDriversAndPluginsPriorityFiles();
      await _refreshAnalysisRoots();
    }
  }

  /// Completes [lspInitialized], signalling that the server has moved into an
  /// initialized state where it can handle standard LSP requests.
  void completeLspInitialization(InitializedStateMessageHandler handler) {
    _lspInitializedCompleter.complete(handler);
  }

  /// The socket from which messages are being read has been closed.
  void done() {}

  /// Fetches configuration from the client (if supported) and then sends
  /// register/unregister requests for any supported/enabled dynamic registrations.
  Future<void> fetchClientConfigurationAndPerformDynamicRegistration() async {
    if (editorClientCapabilities?.configuration ?? false) {
      // Take a copy of workspace folders because we need to match up the
      // responses to the request by index and it's possible _workspaceFolders
      // will change after we sent the request but before we get the response.
      var folders = _workspaceFolders.toList();

      // Fetch all configuration we care about from the client. This is just
      // "dart" for now, but in future this may be extended to include
      // others (for example "flutter").
      var response = await sendRequest(
        Method.workspace_configuration,
        ConfigurationParams(
          items: [
            // Dart settings for each workspace folder.
            for (var folder in folders)
              ConfigurationItem(
                scopeUri: uriConverter.toClientUri(folder),
                section: 'dart',
              ),
            // Global Dart settings. This comes last to simplify matching up the
            // indexes in the results (folder[i] is the i'th item).
            ConfigurationItem(section: 'dart'),
          ],
        ),
      );

      var result = response.result;

      // Expect the result to be a list with 1 + folders.length items to
      // match the request above, and each should be a standard map of settings.
      // If the above code is extended to support multiple sets of config
      // this will need tweaking to handle the item for each section.
      if (result != null &&
          result is List<dynamic> &&
          result.length == 1 + folders.length) {
        // Config is stored as a map keyed by the workspace folder, and a key of
        // null for the global config
        var workspaceFolderConfig = {
          for (var i = 0; i < folders.length; i++)
            folders[i]: result[i] as Map<String, Object?>? ?? {},
        };
        var newGlobalConfig = result.last as Map<String, Object?>? ?? {};

        var oldGlobalConfig = lspClientConfiguration.global;
        lspClientConfiguration.replace(newGlobalConfig, workspaceFolderConfig);

        if (lspClientConfiguration.affectsAnalysisRoots(oldGlobalConfig)) {
          await _refreshAnalysisRoots();
        } else if (lspClientConfiguration.affectsAnalysisResults(
          oldGlobalConfig,
        )) {
          // Some settings affect analysis results and require re-analysis
          // (such as showTodos).
          await reanalyze();
        }
      }
    }

    // Client config can affect capabilities, so this should only be done after
    // we have the initial/updated config.
    // Don't await this because it involves sending requests to the client (for
    // config) that should not stop/delay initialization.
    unawaited(capabilitiesComputer.performDynamicRegistration());
  }

  /// Gets the current version number of a document.
  @override
  int? getDocumentVersion(String path) => documentVersions[path]?.version;

  /// Gets the current identifier/version of a document known to the server,
  /// returning an [OptionalVersionedTextDocumentIdentifier] with a version of
  /// `null` if the document version is not known.
  ///
  /// Prefer using [LspHandlerHelperMixin.extractDocumentVersion] when you
  /// already have a [TextDocumentIdentifier] from the client because it is
  /// guaranteed to be what the client expected and not just the current version
  /// the server has.
  @override
  OptionalVersionedTextDocumentIdentifier getVersionedDocumentIdentifier(
    String path,
  ) {
    return OptionalVersionedTextDocumentIdentifier(
      uri: uriConverter.toClientUri(path),
      version: getDocumentVersion(path),
    );
  }

  @override
  FutureOr<void> handleAnalysisStatusChange(
    analysis.AnalysisStatus status,
  ) async {
    super.handleAnalysisStatusChange(status);
    await sendStatusNotification(status);
  }

  void handleClientConnection(
    ClientCapabilities capabilities,
    ClientInfo? clientInfo,
    Object? initializationOptions,
  ) {
    _clientCapabilities = LspClientCapabilities(capabilities);
    _clientInfo = clientInfo;
    _initializationOptions = LspInitializationOptions(initializationOptions);

    /// Enable virtual file support.
    var supportsVirtualFiles =
        _clientCapabilities
            ?.supportsDartExperimentalTextDocumentContentProvider ??
        false;
    if (supportsVirtualFiles) {
      uriConverter = ClientUriConverter.withVirtualFileSupport(pathContext);
    }

    performanceAfterStartup = ServerPerformance();
    performance = performanceAfterStartup!;

    _checkAnalytics();
    enableSurveys();

    // Notify the client of any issues parsing experimental capabilities.
    var errors = _clientCapabilities?.experimentalCapabilitiesErrors;
    if (errors != null && errors.isNotEmpty) {
      var message =
          'There were errors parsing your experimental '
          'client capabilities:\n${errors.join(', ')}';

      var params = ShowMessageParams(
        type: MessageType.warning.forLsp,
        message: message,
      );

      channel.sendNotification(
        NotificationMessage(
          method: Method.window_showMessage,
          params: params,
          jsonrpc: jsonRpcVersion,
        ),
      );
    }
  }

  /// Handles a response from the client by invoking the completer that the
  /// outbound request created.
  void handleClientResponse(ResponseMessage message) {
    // The ID from the client is an Either2<num, String>?, though it's not valid
    // for it to be a null or a string because it should match a request we sent
    // to the client (and we always use numeric IDs for outgoing requests).
    var id = message.id;
    if (id == null) {
      showErrorMessageToUser('Unexpected response with no ID!');
      return;
    }

    id.map(
      (id) {
        // It's possible that even if we got a numeric ID that it's not valid.
        // If it's not in our completers list (which is a list of the
        // outstanding requests we've sent) then show an error.
        var completer = completers[id];
        if (completer == null) {
          showErrorMessageToUser('Response with ID $id was unexpected');
        } else {
          completers.remove(id);
          completer.complete(message);
        }
      },
      (stringID) {
        showErrorMessageToUser('Unexpected String ID for response $stringID');
      },
    );
  }

  /// Handle a [message] that was read from the communication channel.
  void handleMessage(Message message, {CancelableToken? cancellationToken}) {
    var startTime = DateTime.now();
    performance.logRequestTiming(message.clientRequestTime);
    runZonedGuarded(() async {
      try {
        if (message is ResponseMessage) {
          handleClientResponse(message);
        } else if (message is IncomingMessage) {
          // Record performance information for the request.
          var rootPerformance = OperationPerformanceImpl('<root>');
          RequestPerformance? requestPerformance;
          await rootPerformance.runAsync('request', (performance) async {
            requestPerformance = RequestPerformance(
              operation: message.method.toString(),
              performance: performance,
              requestLatency: message.timeSinceRequest,
              startTime: startTime,
            );
            recentPerformance.requests.add(requestPerformance!);

            var messageInfo = MessageInfo(
              performance: performance,
              clientCapabilities: editorClientCapabilities,
              timeSinceRequest: message.timeSinceRequest,
            );

            if (message is RequestMessage) {
              analyticsManager.startedRequestMessage(
                request: message,
                startTime: startTime,
              );
              await _handleRequestMessage(
                message,
                messageInfo,
                cancellationToken: cancellationToken,
              );
            } else if (message is NotificationMessage) {
              await _handleNotificationMessage(message, messageInfo);
              analyticsManager.handledNotificationMessage(
                notification: message,
                startTime: startTime,
                endTime: DateTime.now(),
              );
            } else {
              showErrorMessageToUser('Unknown incoming message type');
            }
          });
          if (requestPerformance != null &&
              requestPerformance!.performance.elapsed >
                  ServerRecentPerformance.slowRequestsThreshold) {
            recentPerformance.slowRequests.add(requestPerformance!);
          }
        } else {
          showErrorMessageToUser('Unknown message type');
        }
      } on InconsistentAnalysisException {
        sendErrorResponse(
          message,
          ResponseError(
            code: ErrorCodes.ContentModified,
            message: 'Document was modified before operation completed',
          ),
        );
      } catch (error, stackTrace) {
        var errorMessage =
            message is ResponseMessage
                ? 'An error occurred while handling the response to request ${message.id}'
                : message is RequestMessage
                ? 'An error occurred while handling ${message.method} request'
                : message is NotificationMessage
                ? 'An error occurred while handling ${message.method} notification'
                : 'Unknown message type';
        sendErrorResponse(
          message,
          ResponseError(
            code: ServerErrorCodes.UnhandledError,
            message: errorMessage,
          ),
        );
        logException(errorMessage, error, stackTrace);
      }
    }, socketError);
  }

  /// Locks the server from processing incoming messages until [operation]
  /// completes.
  ///
  /// This can be used to obtain analysis results/resolved units consistent with
  /// the state of a file at the time this method was called, preventing
  /// changes by incoming file modifications.
  ///
  /// The contents of [operation] should be kept as short as possible and since
  /// cancellation requests will also be blocked for the duration of this
  /// operation, handles should generally check the cancellation flag
  /// immediately after this function returns.
  Future<T> lockRequestsWhile<T>(FutureOr<T> Function() operation) async {
    // TODO(dantup): Prevent this method from locking responses from the client
    //  because this can lead to deadlocks if called during initialization where
    //  the server may wait for something (configuration) from the client. This
    //  might fit in with potential upcoming scheduler changes.
    //
    // This is currently used by Completion+FixAll (which are less likely, but
    // possible to be called during init).
    //
    // https://github.com/dart-lang/sdk/issues/56311#issuecomment-2250089185
    var completer = Completer<void>();

    // Pause handling incoming messages until `operation` completes.
    //
    // If this method is called multiple times, the pauses will stack, meaning
    // the subscription will not resume until all operations complete.
    _channelSubscription.pause(completer.future);

    try {
      // `await` here is important to ensure `finally` doesn't execute until
      // `operation()` completes (`whenComplete` is not available on
      // `FutureOr`).
      return await operation();
    } finally {
      completer.complete();
    }
  }

  /// Logs the error on the client using window/logMessage.
  void logErrorToClient(String message) {
    channel.sendNotification(
      NotificationMessage(
        method: Method.window_logMessage,
        params: LogMessageParams(
          type: MessageType.error.forLsp,
          message: message,
        ),
        jsonrpc: jsonRpcVersion,
      ),
    );
  }

  /// Logs an exception by sending it to the client (window/logMessage) and
  /// recording it in a buffer on the server for diagnostics.
  void logException(String message, Object exception, StackTrace? stackTrace) {
    var fullMessage = message;
    if (exception is CaughtException) {
      stackTrace ??= exception.stackTrace;
      fullMessage = '$fullMessage: ${exception.exception}';
    } else {
      fullMessage = '$fullMessage: $exception';
    }

    var fullError =
        stackTrace == null ? fullMessage : '$fullMessage\n$stackTrace';
    stackTrace ??= StackTrace.current;

    // Log the full message since showMessage above may be truncated or
    // formatted badly (eg. VS Code takes the newlines out).
    logErrorToClient(fullError);

    // remember the last few exceptions
    exceptions.add(ServerException(message, exception, stackTrace, false));

    instrumentationService.logException(
      FatalException(message, exception, stackTrace),
      null,
      crashReportingAttachmentsBuilder.forException(exception),
    );
  }

  void onOverlayCreated(String path, String content) {
    resourceProvider.setOverlay(
      path,
      content: content,
      modificationStamp: overlayModificationStamp++,
    );

    // If the overlay is exactly the same as the previous content we can skip
    // notifying drivers which avoids re-analyzing the same content.
    // We use getAnalysisDriver() here because it can get content from
    // dependencies (so the optimization works for them) but below we use
    // `contextManager.driverFor` so we only add to the specific driver.
    var driver = getAnalysisDriver(path);
    var state = driver?.fsState.getExistingFromPath(path);
    // Content is updated if we have no state, we have state that does not exist
    // or the content differs. For a file with state that does not exist, the
    // content will be an empty string, so we must check exists to cover files
    // that are newly created with empty contents.
    var contentIsUpdated =
        state == null || !state.exists || state.content != content;

    if (contentIsUpdated) {
      _afterOverlayChanged(path, plugin.AddContentOverlay(content));

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      contextManager.getDriverFor(path)?.addFile(path);
    } else {
      // If we skip the work above, we still need to ensure plugins are notified
      // of the new overlay (which usually happens in `_afterOverlayChanged`).
      _notifyPluginsOverlayChanged(path, plugin.AddContentOverlay(content));

      // We also need to ensure notifications like Outline can still sent in
      // this case (which are usually triggered by the re-analysis), so force
      // sending the resolved unit to the result stream even if we didn't need
      // to re-analyze it.
      unawaited(getResolvedUnit(path, sendCachedToStream: true));
    }
  }

  void onOverlayDestroyed(String path) {
    resourceProvider.removeOverlay(path);

    _afterOverlayChanged(path, plugin.RemoveContentOverlay());
  }

  /// Updates an overlay on [path] by applying the [edits] to the current
  /// overlay.
  ///
  /// If the result of applying the edits is already known, [newContent] can be
  /// set to avoid doing that calculation twice.
  void onOverlayUpdated(
    String path,
    List<plugin.SourceEdit> edits, {
    String? newContent,
  }) {
    assert(resourceProvider.hasOverlay(path));
    if (newContent == null) {
      var oldContent = resourceProvider.getFile(path).readAsStringSync();
      newContent = plugin.applySequenceOfEdits(oldContent, edits);
    }

    resourceProvider.setOverlay(
      path,
      content: newContent,
      modificationStamp: overlayModificationStamp++,
    );

    _afterOverlayChanged(path, plugin.ChangeContentOverlay(edits));
  }

  void publishClosingLabels(String path, List<ClosingLabel> labels) {
    var params = PublishClosingLabelsParams(
      uri: uriConverter.toClientUri(path),
      labels: labels,
    );
    var message = NotificationMessage(
      method: CustomMethods.publishClosingLabels,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendLspNotification(message);
  }

  void publishDiagnostics(String path, List<Diagnostic> errors) {
    if (errors.isEmpty && !_filesWithClientDiagnostics.contains(path)) {
      // Don't sent empty set if client is already empty.
      return;
    }

    if (errors.isEmpty) {
      _filesWithClientDiagnostics.remove(path);
    } else {
      _filesWithClientDiagnostics.add(path);
    }

    var params = PublishDiagnosticsParams(
      uri: uriConverter.toClientUri(path),
      diagnostics: errors,
    );
    var message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendLspNotification(message);
  }

  void publishFlutterOutline(String path, FlutterOutline outline) {
    var params = PublishFlutterOutlineParams(
      uri: uriConverter.toClientUri(path),
      outline: outline,
    );
    var message = NotificationMessage(
      method: CustomMethods.publishFlutterOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendLspNotification(message);
  }

  void publishOutline(String path, Outline outline) {
    var params = PublishOutlineParams(
      uri: uriConverter.toClientUri(path),
      outline: outline,
    );
    var message = NotificationMessage(
      method: CustomMethods.publishOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendLspNotification(message);
  }

  Future<void> removePriorityFile(String path) async {
    var didRemove = priorityFiles.remove(path);
    assert(didRemove);
    if (didRemove) {
      _updateDriversAndPluginsPriorityFiles();
      await _refreshAnalysisRoots();
    }
  }

  void scheduleMessage(Message message) {
    CancelableToken? cancellationToken;
    // Create a  cancellation token that will allow us to cancel
    // this request if requested.
    if (message is RequestMessage) {
      cancellationToken = messageHandler.cancelHandler.createToken(message);
    }
    messageScheduler.add(
      LspMessage(message: message, cancellationToken: cancellationToken),
    );
    messageScheduler.notify();
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      sendResponse(
        ResponseMessage(id: message.id, error: error, jsonrpc: jsonRpcVersion),
      );
    } else if (message is ResponseMessage) {
      // For bad response messages where we can't respond with an error, send it
      // as show instead of log.
      showErrorMessageToUser(error.message);
    } else {
      // For notifications where we couldn't respond with an error, send it as
      // show instead of log.
      showErrorMessageToUser(error.message);
    }

    // Handle fatal errors where the client/server state is out of sync and we
    // should not continue.
    if (error.code == ServerErrorCodes.ClientServerInconsistentState) {
      // Do not process any further messages.
      messageHandler = FailureStateMessageHandler(this);

      var message = 'An unrecoverable error occurred.';
      logErrorToClient(
        '$message\n\n${error.message}\n\n${error.code}\n\n${error.data}',
      );

      unawaited(shutdown());
    }
  }

  /// Send the given [notification] to the client.
  @override
  void sendLspNotification(NotificationMessage notification) {
    channel.sendNotification(notification);
  }

  /// Send the given [request] to the client and wait for a response. Completes
  /// with the raw [ResponseMessage] which could be an error response.
  Future<ResponseMessage> sendRequest(Method method, Object params) {
    var requestId = nextRequestId++;
    var completer = Completer<ResponseMessage>();
    completers[requestId] = completer;

    channel.sendRequest(
      RequestMessage(
        id: Either2<int, String>.t1(requestId),
        method: method,
        params: params,
        jsonrpc: jsonRpcVersion,
      ),
    );

    return completer.future;
  }

  /// Send the given [response] to the client.
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
    analyticsManager.sentResponseMessage(response: response);
  }

  @override
  void sendServerErrorNotification(
    String message,
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) {
    message = '$message: $exception';

    // Show message (without stack) to the user.
    showErrorMessageToUser(message);
  }

  /// Send status notification to the client. The state of analysis is given by
  /// the [status] information.
  Future<void> sendStatusNotification(analysis.AnalysisStatus status) async {
    // Send old custom notifications to clients that do not support $/progress.
    // TODO(dantup): Remove this custom notification (and related classes) when
    // it's unlikely to be in use by any clients.
    var isAnalyzing = status.isWorking;
    if (wasAnalyzing && !isAnalyzing) {
      wasAnalyzing = isAnalyzing;
      // Only send analysis analytics after analysis is complete.
      reportAnalysisAnalytics();
    }
    if (isAnalyzing && !wasAnalyzing) {
      wasAnalyzing = true;
    }

    if (editorClientCapabilities?.workDoneProgress != true) {
      channel.sendNotification(
        NotificationMessage(
          method: CustomMethods.analyzerStatus,
          params: AnalyzerStatusParams(isAnalyzing: isAnalyzing),
          jsonrpc: jsonRpcVersion,
        ),
      );
      return;
    }

    if (isAnalyzing) {
      analyzingProgressReporter ??= ProgressReporter.serverCreated(
        this,
        analyzingProgressToken,
      )..begin('Analyzing…');
    } else {
      if (analyzingProgressReporter != null) {
        // Do not null this out until after end completes, otherwise we may try
        // to create a new token before it's really completed.
        await analyzingProgressReporter?.end();
        analyzingProgressReporter = null;
      }
    }
  }

  /// Returns `true` if closing labels should be sent for [file] with the given
  /// absolute path.
  bool shouldSendClosingLabelsFor(String file) {
    // Closing labels should only be sent for open (priority) files in the
    // workspace.
    return (initializationOptions?.closingLabels ?? false) &&
        priorityFiles.contains(file) &&
        isAnalyzed(file);
  }

  /// Returns `true` if Flutter outlines should be sent for [file] with the
  /// given absolute path.
  bool shouldSendFlutterOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return (initializationOptions?.flutterOutline ?? false) &&
        priorityFiles.contains(file) &&
        _isInFlutterProject(file);
  }

  /// Returns `true` if outlines should be sent for [file] with the given
  /// absolute path.
  bool shouldSendOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return (initializationOptions?.outline ?? false) &&
        priorityFiles.contains(file);
  }

  void showErrorMessageToUser(String message) {
    showMessageToUser(MessageType.error, message);
  }

  void showMessageToUser(MessageType type, String message) {
    channel.sendNotification(
      NotificationMessage(
        method: Method.window_showMessage,
        params: ShowMessageParams(type: type.forLsp, message: message),
        jsonrpc: jsonRpcVersion,
      ),
    );
  }

  /// Shows the user a prompt with some actions to select from using
  /// 'window/showMessageRequest'.
  ///
  /// Callers should use [userPromptSender] instead of calling this method
  /// directly because it returns null if the client does not support user
  /// prompts.
  @override
  @visibleForOverriding
  Future<String?> showUserPrompt(
    MessageType type,
    String message,
    List<String> actions,
  ) async {
    assert(supportsShowMessageRequest);
    var response = await showUserPromptItems(
      type,
      message,
      actions.map((title) => MessageActionItem(title: title)).toList(),
    );
    return response?.title;
  }

  /// Shows the user a prompt with some actions to select from using
  /// 'window/showMessageRequest'.
  ///
  /// Callers should verify the client supports 'window/showMessageRequest' with
  /// [supportsShowMessageRequest] before calling this, and handle cases where
  /// it is not appropriately.
  ///
  /// For simple cases, [showUserPrompt] provides a slightly simpler API using
  /// [String]s instead of [MessageActionItem]s.
  Future<MessageActionItem?> showUserPromptItems(
    MessageType type,
    String message,
    List<MessageActionItem> actions,
  ) async {
    assert(supportsShowMessageRequest);
    var response = await sendRequest(
      Method.window_showMessageRequest,
      ShowMessageRequestParams(
        type: type.forLsp,
        message: message,
        actions: actions,
      ),
    );

    var result = response.result;
    return result != null
        ? MessageActionItem.fromJson(response.result as Map<String, Object?>)
        : null;
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();

    detachableFileSystemManager?.dispose();

    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    unawaited(
      Future(() {
        channel.close();
      }),
    );
    unawaited(_pluginChangeSubscription?.cancel());
    _pluginChangeSubscription = null;
  }

  /// There was an error related to the socket from which messages are being
  /// read.
  void socketError(Object error, StackTrace? stackTrace) {
    // Don't send to instrumentation service; not an internal error.
    sendServerErrorNotification('Socket error', error, stackTrace);
  }

  Future<void> updateWorkspaceFolders(
    List<String> addedPaths,
    List<String> removedPaths,
  ) async {
    // TODO(dantup): This is currently case-sensitive!

    // Normalize all potential workspace folder paths as these may contain
    // trailing slashes (the LSP spec does not specify whether folders
    // should/should not have them) and the analysis roots must be normalized.
    var pathContext = resourceProvider.pathContext;
    var addedNormalized = addedPaths.map(pathContext.normalize).toList();
    var removedNormalized = removedPaths.map(pathContext.normalize).toList();

    _workspaceFolders
      ..addAll(addedNormalized)
      ..removeAll(removedNormalized);

    await fetchClientConfigurationAndPerformDynamicRegistration();

    await _refreshAnalysisRoots();
  }

  void _afterOverlayChanged(String path, plugin.HasToJson changeForPlugins) {
    for (var driver in driverMap.values) {
      driver.changeFile(path);
    }
    _notifyPluginsOverlayChanged(path, changeForPlugins);

    notifyDeclarationsTracker(path);
    notifyFlutterWidgetDescriptions(path);
  }

  /// Display a message that will allow us to enable analytics on the next run.
  void _checkAnalytics() {
    // TODO(dantup): This code should move to base server.
    var unifiedAnalytics = analyticsManager.analytics;
    var prompt = userPromptSender;
    if (!unifiedAnalytics.shouldShowMessage || prompt == null) {
      return;
    }

    unawaited(
      prompt(MessageType.info, unifiedAnalytics.getConsentMessage, ['Ok']),
    );
    unifiedAnalytics.clientShowedMessage();
  }

  /// Computes analysis roots for a set of open files.
  ///
  /// This is used when there are no workspace folders open directly.
  List<String> _getRootsForOpenFiles() {
    var openFiles = priorityFiles.toList();
    var contextLocator = ContextLocatorImpl(resourceProvider: resourceProvider);
    var roots = contextLocator.locateRoots(includedPaths: openFiles);

    var packages = <String>{};
    var additionalFiles = <String>[];
    for (var file in openFiles) {
      var package = roots
          .where((root) => root.isAnalyzed(file))
          .map((root) => root.workspace.findPackageFor(file)?.root)
          .firstWhereOrNull((p) => p != null);
      if (package != null && !resourceProvider.getFolder(package).isRoot) {
        packages.add(package);
      } else {
        additionalFiles.add(file);
      }
    }

    return [...packages, ...additionalFiles];
  }

  Future<void> _handleNotificationMessage(
    NotificationMessage message,
    MessageInfo messageInfo,
  ) async {
    var result = await messageHandler.handleMessage(message, messageInfo);
    result.ifError((error) => sendErrorResponse(message, error));
  }

  Future<void> _handleRequestMessage(
    RequestMessage message,
    MessageInfo messageInfo, {
    CancelableToken? cancellationToken,
  }) async {
    var result = await messageHandler.handleMessage(
      message,
      messageInfo,
      cancellationToken: cancellationToken,
    );
    result.ifError((error) => sendErrorResponse(message, error));
    result.ifResult(
      (result) => sendResponse(
        ResponseMessage(
          id: message.id,
          result: result,
          jsonrpc: jsonRpcVersion,
        ),
      ),
    );
  }

  /// Returns whether [filePath] is in a project that can resolve
  /// 'package:flutter' libraries.
  bool _isInFlutterProject(String filePath) =>
      getAnalysisDriver(
        filePath,
      )?.currentSession.uriConverter.uriToPath(Uri.parse(widgetsUri)) !=
      null;

  void _notifyPluginsOverlayChanged(
    String path,
    plugin.HasToJson changeForPlugins,
  ) {
    if (AnalysisServer.supportsPlugins) {
      pluginManager.setAnalysisUpdateContentParams(
        plugin.AnalysisUpdateContentParams({path: changeForPlugins}),
      );
    }
  }

  void _onPluginsChanged() {
    capabilitiesComputer.performDynamicRegistration();
  }

  Future<void> _refreshAnalysisRoots() async {
    // When there are open folders, they are always the roots. If there are no
    // open workspace folders, then we use the open (priority) files to compute
    // roots.
    var includedPaths =
        _workspaceFolders.isNotEmpty
            ? _workspaceFolders.toSet()
            : _getRootsForOpenFiles();

    var excludedPaths =
        lspClientConfiguration.global.analysisExcludedFolders
            .expand(
              (excludePath) =>
                  resourceProvider.pathContext.isAbsolute(excludePath)
                      ? [excludePath]
                      // Apply the relative path to each open workspace folder.
                      // TODO(dantup): Consider supporting per-workspace config by
                      // calling workspace/configuration whenever workspace folders change
                      // and caching the config for each one.
                      : _workspaceFolders.map((root) => resourceProvider.pathContext.join(root, excludePath)),
            )
            .map(pathContext.normalize)
            .toSet();

    var completer = analysisContextRebuildCompleter = Completer();
    try {
      var includedPathsList = includedPaths.toList();
      var excludedPathsList = excludedPaths.toList();
      notificationManager.setAnalysisRoots(
        includedPathsList,
        excludedPathsList,
      );
      if (detachableFileSystemManager != null) {
        detachableFileSystemManager?.setAnalysisRoots(
          null,
          includedPathsList,
          excludedPathsList,
        );
      } else {
        await contextManager.setRoots(includedPathsList, excludedPathsList);
      }
    } finally {
      completer.complete();
    }
  }

  void _updateDriversAndPluginsPriorityFiles() {
    var priorityFilesList = priorityFiles.toList();
    for (var driver in driverMap.values) {
      driver.priorityFiles = priorityFilesList;
    }

    if (AnalysisServer.supportsPlugins) {
      var pluginPriorities = plugin.AnalysisSetPriorityFilesParams(
        priorityFilesList,
      );
      pluginManager.setAnalysisSetPriorityFilesParams(pluginPriorities);

      // Plugins send most of their analysis results via notifications, but with
      // LSP we're supposed to have them available per request. Assume that
      // we'll only receive requests for files that are currently open.
      var pluginSubscriptions = plugin.AnalysisSetSubscriptionsParams({
        for (var service in plugin.AnalysisService.VALUES)
          service: priorityFilesList,
      });
      pluginManager.setAnalysisSetSubscriptionsParams(pluginSubscriptions);
    }

    notificationManager.setSubscriptions({
      for (var service in protocol.AnalysisService.VALUES)
        service: priorityFiles,
    });
  }
}

class LspInitializationOptions {
  final Map<String, Object?> raw;
  final String? appHost;
  final String? remoteName;
  final bool onlyAnalyzeProjectsWithOpenFiles;
  final bool suggestFromUnimportedLibraries;
  final bool closingLabels;
  final bool outline;
  final bool flutterOutline;
  final int? completionBudgetMilliseconds;
  final bool allowOpenUri;

  /// A temporary flag passed by Dart-Code to enable using in-editor fixes for
  /// the "dart fix" prompt.
  ///
  /// This allows enabling it once there's been wider testing of the "Fix All in
  /// Workspace" command without requiring a new SDK release. Once enabled in
  /// Dart-Code, this flag can also be removed here for future SDKs.
  final bool useInEditorDartFixPrompt;

  factory LspInitializationOptions(Object? options) =>
      LspInitializationOptions._(
        options is Map<String, Object?> ? options : const {},
      );

  LspInitializationOptions._(Map<String, Object?> options)
    : raw = options,
      appHost = options['appHost'] as String?,
      remoteName = options['remoteName'] as String?,
      onlyAnalyzeProjectsWithOpenFiles =
          options['onlyAnalyzeProjectsWithOpenFiles'] == true,
      // suggestFromUnimportedLibraries defaults to true, so must be
      // explicitly passed as false to disable.
      suggestFromUnimportedLibraries =
          options['suggestFromUnimportedLibraries'] != false,
      closingLabels = options['closingLabels'] == true,
      outline = options['outline'] == true,
      flutterOutline = options['flutterOutline'] == true,
      completionBudgetMilliseconds =
          options['completionBudgetMilliseconds'] as int?,
      allowOpenUri = options['allowOpenUri'] == true,
      useInEditorDartFixPrompt = options['useInEditorDartFixPrompt'] == true;
}

class LspServerContextManagerCallbacks
    extends CommonServerContextManagerCallbacks {
  @override
  final LspAnalysisServer analysisServer;

  LspServerContextManagerCallbacks(this.analysisServer, super.resourceProvider);

  @override
  void afterContextsCreated() {
    super.afterContextsCreated();
    analysisServer.contextBuilds++;
  }

  @override
  void flushResults(List<String> files) {
    for (var file in files) {
      analysisServer.publishDiagnostics(file, []);
    }
  }

  @override
  void handleFileResult(FileResult result) {
    if (analysisServer.suppressAnalysisResults) {
      return;
    }

    super.handleFileResult(result);
  }

  @override
  void handleResolvedUnitResult(ResolvedUnitResult result) {
    var path = result.path;

    var unit = result.unit;
    if (analysisServer.shouldSendClosingLabelsFor(path)) {
      var labels =
          DartUnitClosingLabelsComputer(
            result.lineInfo,
            unit,
          ).compute().map((l) => toClosingLabel(result.lineInfo, l)).toList();

      analysisServer.publishClosingLabels(path, labels);
    }
    if (analysisServer.shouldSendOutlineFor(path)) {
      var outline =
          DartUnitOutlineComputer(result, withBasicFlutter: true).compute();
      var lspOutline = toOutline(result.lineInfo, outline);
      analysisServer.publishOutline(path, lspOutline);
    }
    if (analysisServer.shouldSendFlutterOutlineFor(path)) {
      var outline = FlutterOutlineComputer(result).compute();
      var lspOutline = toFlutterOutline(result.lineInfo, outline);
      analysisServer.publishFlutterOutline(path, lspOutline);
    }
  }

  @override
  void recordAnalysisErrors(String path, List<protocol.AnalysisError> errors) {
    super.recordAnalysisErrors(path, errors.where(_shouldSendError).toList());
  }

  bool _shouldSendError(protocol.AnalysisError error) {
    // Non-TODOs are always shown.
    if (error.type.name != ErrorType.TODO.name) {
      return true;
    }

    // TODOs that are upgraded from INFO are always shown.
    if (error.severity.name != ErrorSeverity.INFO.name) {
      return true;
    }

    // Otherwise, show TODOs based on client configuration (either showing all,
    // or specific types of TODOs).
    if (analysisServer.lspClientConfiguration.global.showAllTodos) {
      return true;
    }
    return analysisServer.lspClientConfiguration.global.showTodoTypes.contains(
      error.code.toUpperCase(),
    );
  }
}
