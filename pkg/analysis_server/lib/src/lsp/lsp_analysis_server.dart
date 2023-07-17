// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/computer/computer_closingLabels.dart';
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
import 'package:analysis_server/src/server/performance.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analysis_server/src/utilities/process.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as analysis;
import 'package:analyzer/src/dart/analysis/status.dart' as analysis;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
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
  InitializeParamsClientInfo? _clientInfo;

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

  /// The workspace for rename refactorings. Should be accessed through the
  /// refactoringWorkspace getter to be automatically created (lazily).
  RefactoringWorkspace? _refactoringWorkspace;

  /// The versions of each document known to the server (keyed by path), used to
  /// send back to the client for server-initiated edits so that the client can
  /// ensure they have a matching version of the document before applying them.
  ///
  /// Handlers should prefer to use the `getVersionedDocumentIdentifier` method
  /// which will return a null-versioned identifier if the document version is
  /// not known.
  final Map<String, VersionedTextDocumentIdentifier> documentVersions = {};

  late ServerStateMessageHandler messageHandler;

  int nextRequestId = 1;

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
  })  : lspClientConfiguration =
            LspClientConfiguration(baseResourceProvider.pathContext),
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
          LspNotificationManager(channel, baseResourceProvider.pathContext),
          enableBlazeWatcher: enableBlazeWatcher,
          dartFixPromptManager: dartFixPromptManager,
        ) {
    notificationManager.server = this;
    messageHandler = UninitializedStateMessageHandler(this);
    capabilitiesComputer = ServerCapabilitiesComputer(this);

    final contextManagerCallbacks =
        LspServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;

    analysisDriverScheduler.status.listen(handleAnalysisStatusChange);
    analysisDriverScheduler.start();

    _channelSubscription =
        channel.listen(handleMessage, onDone: done, onError: socketError);
    if (AnalysisServer.supportsPlugins) {
      _pluginChangeSubscription =
          pluginManager.pluginsChanged.listen((_) => _onPluginsChanged());
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

  /// The capabilities of the LSP client. Will be null prior to initialization.
  InitializeParamsClientInfo? get clientInfo => _clientInfo;

  /// The name of the remote when the client is running using a remote workspace.
  ///
  /// This information is not part of the LSP spec so is only provided for
  /// clients extensions that add it to initialization options explicitly
  /// (such as Dart-Code for VS Code where it comes from 'env.remoteName').
  ///
  /// This value is `null` for local workspaces and will contain a string such
  /// as 'ssh-remote' or 'wsl' for remote workspaces.
  String? get clientRemoteName => _initializationOptions?.remoteName;

  Future<void> get exited => channel.closed;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. This getter is for convenience and will
  /// throw if accessed prior to initialization.
  /// TODO(dantup): Make this nullable and review all uses of it to ensure
  ///  there aren't potential errors here.
  LspInitializationOptions get initializationOptions =>
      _initializationOptions as LspInitializationOptions;

  /// The capabilities of the LSP client. Will be null prior to initialization.
  @override
  LspClientCapabilities? get lspClientCapabilities => _clientCapabilities;

  @override
  LspNotificationManager get notificationManager =>
      super.notificationManager as LspNotificationManager;

  @override
  OpenUriNotificationSender? get openUriNotificationSender {
    if (!initializationOptions.allowOpenUri) {
      return null;
    }

    return (Uri uri) {
      final params = OpenUriParams(uri: uri);
      final message = NotificationMessage(
        method: CustomMethods.openUri,
        params: params,
        jsonrpc: jsonRpcVersion,
      );
      sendNotification(message);
    };
  }

  path.Context get pathContext => resourceProvider.pathContext;

  @override
  set pluginManager(PluginManager value) {
    if (AnalysisServer.supportsPlugins) {
      // we exchange the plugin manager in tests
      super.pluginManager = value;
      _pluginChangeSubscription?.cancel();

      _pluginChangeSubscription =
          pluginManager.pluginsChanged.listen((_) => _onPluginsChanged());
    }
  }

  RefactoringWorkspace get refactoringWorkspace => _refactoringWorkspace ??=
      RefactoringWorkspace(driverMap.values, searchEngine);

  /// Whether or not the client has advertised support for
  /// 'window/showMessageRequest'.
  @override
  bool get supportsShowMessageRequest =>
      lspClientCapabilities?.supportsShowMessageRequest ?? false;

  Future<void> addPriorityFile(String filePath) async {
    // When pubspecs are opened, trigger pre-loading of pub package names and
    // versions.
    if (file_paths.isPubspecYaml(resourceProvider.pathContext, filePath)) {
      pubPackageService.beginCachePreloads([filePath]);
    }

    final didAdd = priorityFiles.add(filePath);
    assert(didAdd);
    if (didAdd) {
      _updateDriversAndPluginsPriorityFiles();
      await _refreshAnalysisRoots();
    }
  }

  /// The socket from which messages are being read has been closed.
  void done() {}

  /// Fetches configuration from the client (if supported) and then sends
  /// register/unregister requests for any supported/enabled dynamic registrations.
  Future<void> fetchClientConfigurationAndPerformDynamicRegistration() async {
    if (lspClientCapabilities?.configuration ?? false) {
      // Take a copy of workspace folders because we need to match up the
      // responses to the request by index and it's possible _workspaceFolders
      // will change after we sent the request but before we get the response.
      final folders = _workspaceFolders.toList();

      // Fetch all configuration we care about from the client. This is just
      // "dart" for now, but in future this may be extended to include
      // others (for example "flutter").
      final response = await sendRequest(
          Method.workspace_configuration,
          ConfigurationParams(items: [
            // Dart settings for each workspace folder.
            for (final folder in folders)
              ConfigurationItem(
                scopeUri: pathContext.toUri(folder).toString(),
                section: 'dart',
              ),
            // Global Dart settings. This comes last to simplify matching up the
            // indexes in the results (folder[i] is the i'th item).
            ConfigurationItem(section: 'dart'),
          ]));

      final result = response.result;

      // Expect the result to be a list with 1 + folders.length items to
      // match the request above, and each should be a standard map of settings.
      // If the above code is extended to support multiple sets of config
      // this will need tweaking to handle the item for each section.
      if (result != null &&
          result is List<dynamic> &&
          result.length == 1 + folders.length) {
        // Config is stored as a map keyed by the workspace folder, and a key of
        // null for the global config
        final workspaceFolderConfig = {
          for (var i = 0; i < folders.length; i++)
            folders[i]: result[i] as Map<String, Object?>? ?? {},
        };
        final newGlobalConfig = result.last as Map<String, Object?>? ?? {};

        final oldGlobalConfig = lspClientConfiguration.global;
        lspClientConfiguration.replace(newGlobalConfig, workspaceFolderConfig);

        if (lspClientConfiguration.affectsAnalysisRoots(oldGlobalConfig)) {
          await _refreshAnalysisRoots();
        } else if (lspClientConfiguration
            .affectsAnalysisResults(oldGlobalConfig)) {
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
  int? getDocumentVersion(String path) => documentVersions[path]?.version;

  /// Return a [LineInfo] for the file with the given [path].
  ///
  /// If the file does not exist or cannot be read, returns `null`.
  ///
  /// This method supports non-Dart files but uses the current content of the
  /// file which may not be the latest analyzed version of the file if it was
  /// recently modified, so using the lineInfo from an analyzed result may be
  /// preferable.
  LineInfo? getLineInfo(String path) {
    try {
      final content = resourceProvider.getFile(path).readAsStringSync();
      return LineInfo.fromContent(content);
    } on FileSystemException {
      // If the file does not exist or cannot be read, return null to allow
      // the caller to decide how to handle this.
      return null;
    }
  }

  /// Gets the version of a document known to the server, returning a
  /// [OptionalVersionedTextDocumentIdentifier] with a version of `null` if the document
  /// version is not known.
  OptionalVersionedTextDocumentIdentifier getVersionedDocumentIdentifier(
      String path) {
    return OptionalVersionedTextDocumentIdentifier(
        uri: pathContext.toUri(path), version: getDocumentVersion(path));
  }

  @override
  FutureOr<void> handleAnalysisStatusChange(
      analysis.AnalysisStatus status) async {
    super.handleAnalysisStatusChange(status);
    await sendStatusNotification(status);
  }

  void handleClientConnection(
    ClientCapabilities capabilities,
    InitializeParamsClientInfo? clientInfo,
    Object? initializationOptions,
  ) {
    _clientCapabilities = LspClientCapabilities(capabilities);
    _clientInfo = clientInfo;
    _initializationOptions = LspInitializationOptions(initializationOptions);

    performanceAfterStartup = ServerPerformance();
    performance = performanceAfterStartup!;

    _checkAnalytics();
  }

  /// Handles a response from the client by invoking the completer that the
  /// outbound request created.
  void handleClientResponse(ResponseMessage message) {
    // The ID from the client is an Either2<num, String>?, though it's not valid
    // for it to be a null or a string because it should match a request we sent
    // to the client (and we always use numeric IDs for outgoing requests).
    final id = message.id;
    if (id == null) {
      showErrorMessageToUser('Unexpected response with no ID!');
      return;
    }

    id.map(
      (id) {
        // It's possible that even if we got a numeric ID that it's not valid.
        // If it's not in our completers list (which is a list of the
        // outstanding requests we've sent) then show an error.
        final completer = completers[id];
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
  void handleMessage(Message message) {
    final startTime = DateTime.now();
    performance.logRequestTiming(message.clientRequestTime);
    runZonedGuarded(() async {
      try {
        if (message is ResponseMessage) {
          handleClientResponse(message);
        } else if (message is IncomingMessage) {
          // Record performance information for the request.
          final rootPerformance = OperationPerformanceImpl('<root>');
          RequestPerformance? requestPerformance;
          await rootPerformance.runAsync('request', (performance) async {
            requestPerformance = RequestPerformance(
              operation: message.method.toString(),
              performance: performance,
              requestLatency: message.timeSinceRequest,
              startTime: startTime,
            );
            recentPerformance.requests.add(requestPerformance!);

            final messageInfo = MessageInfo(
              performance: performance,
              timeSinceRequest: message.timeSinceRequest,
            );

            if (message is RequestMessage) {
              analyticsManager.startedRequestMessage(
                  request: message, startTime: startTime);
              await _handleRequestMessage(message, messageInfo);
            } else if (message is NotificationMessage) {
              await _handleNotificationMessage(message, messageInfo);
              analyticsManager.handledNotificationMessage(
                  notification: message,
                  startTime: startTime,
                  endTime: DateTime.now());
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
            ));
      } catch (error, stackTrace) {
        final errorMessage = message is ResponseMessage
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
            ));
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
    final completer = Completer<void>();

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
    channel.sendNotification(NotificationMessage(
      method: Method.window_logMessage,
      params:
          LogMessageParams(type: MessageType.error.forLsp, message: message),
      jsonrpc: jsonRpcVersion,
    ));
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

    final fullError =
        stackTrace == null ? fullMessage : '$fullMessage\n$stackTrace';
    stackTrace ??= StackTrace.current;

    // Log the full message since showMessage above may be truncated or
    // formatted badly (eg. VS Code takes the newlines out).
    logErrorToClient(fullError);

    // remember the last few exceptions
    exceptions.add(ServerException(
      message,
      exception,
      stackTrace,
      false,
    ));

    instrumentationService.logException(
      FatalException(
        message,
        exception,
        stackTrace,
      ),
      null,
      crashReportingAttachmentsBuilder.forException(exception),
    );
  }

  void onOverlayCreated(String path, String content) {
    resourceProvider.setOverlay(path,
        content: content, modificationStamp: overlayModificationStamp++);

    // If the overlay is exactly the same as the previous content we can skip
    // notifying drivers which avoids re-analyzing the same content.
    final driver = contextManager.getDriverFor(path);
    final contentIsUpdated =
        driver?.fsState.getExistingFromPath(path)?.content != content;

    if (contentIsUpdated) {
      _afterOverlayChanged(path, plugin.AddContentOverlay(content));

      // If the file did not exist, and is "overlay only", it still should be
      // analyzed. Add it to driver to which it should have been added.
      driver?.addFile(path);
    } else {
      // If we skip the work above, we still need to ensure plugins are notified
      // of the new overlay (which usually happens in `_afterOverlayChanged`).
      _notifyPluginsOverlayChanged(path, plugin.AddContentOverlay(content));
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
  void onOverlayUpdated(String path, List<plugin.SourceEdit> edits,
      {String? newContent}) {
    assert(resourceProvider.hasOverlay(path));
    if (newContent == null) {
      final oldContent = resourceProvider.getFile(path).readAsStringSync();
      newContent = plugin.applySequenceOfEdits(oldContent, edits);
    }

    resourceProvider.setOverlay(path,
        content: newContent, modificationStamp: overlayModificationStamp++);

    _afterOverlayChanged(path, plugin.ChangeContentOverlay(edits));
  }

  void publishClosingLabels(String path, List<ClosingLabel> labels) {
    final params = PublishClosingLabelsParams(
        uri: pathContext.toUri(path), labels: labels);
    final message = NotificationMessage(
      method: CustomMethods.publishClosingLabels,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishDiagnostics(String path, List<Diagnostic> errors) {
    final params = PublishDiagnosticsParams(
        uri: pathContext.toUri(path), diagnostics: errors);
    final message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishFlutterOutline(String path, FlutterOutline outline) {
    final params = PublishFlutterOutlineParams(
        uri: pathContext.toUri(path), outline: outline);
    final message = NotificationMessage(
      method: CustomMethods.publishFlutterOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishOutline(String path, Outline outline) {
    final params =
        PublishOutlineParams(uri: pathContext.toUri(path), outline: outline);
    final message = NotificationMessage(
      method: CustomMethods.publishOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  Future<void> removePriorityFile(String path) async {
    final didRemove = priorityFiles.remove(path);
    assert(didRemove);
    if (didRemove) {
      _updateDriversAndPluginsPriorityFiles();
      await _refreshAnalysisRoots();
    }
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      sendResponse(ResponseMessage(
          id: message.id, error: error, jsonrpc: jsonRpcVersion));
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

      final message = 'An unrecoverable error occurred.';
      logErrorToClient(
          '$message\n\n${error.message}\n\n${error.code}\n\n${error.data}');

      unawaited(shutdown());
    }
  }

  /// Send the given [notification] to the client.
  void sendNotification(NotificationMessage notification) {
    channel.sendNotification(notification);
  }

  /// Send the given [request] to the client and wait for a response. Completes
  /// with the raw [ResponseMessage] which could be an error response.
  Future<ResponseMessage> sendRequest(Method method, Object params) {
    final requestId = nextRequestId++;
    final completer = Completer<ResponseMessage>();
    completers[requestId] = completer;

    channel.sendRequest(RequestMessage(
      id: Either2<int, String>.t1(requestId),
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
    ));

    return completer.future;
  }

  /// Send the given [response] to the client.
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
    analyticsManager.sentResponseMessage(response: response);
  }

  @override
  void sendServerErrorNotification(
      String message, Object exception, StackTrace? stackTrace,
      {bool fatal = false}) {
    message = '$message: $exception';

    // Show message (without stack) to the user.
    showErrorMessageToUser(message);

    logException(message, exception, stackTrace);
  }

  /// Send status notification to the client. The state of analysis is given by
  /// the [status] information.
  Future<void> sendStatusNotification(analysis.AnalysisStatus status) async {
    // Send old custom notifications to clients that do not support $/progress.
    // TODO(dantup): Remove this custom notification (and related classes) when
    // it's unlikely to be in use by any clients.
    var isAnalyzing = status.isAnalyzing;
    if (wasAnalyzing && !isAnalyzing) {
      wasAnalyzing = isAnalyzing;
      // Only send analysis analytics after analysis is complete.
      reportAnalysisAnalytics();
    }
    if (isAnalyzing && !wasAnalyzing) {
      wasAnalyzing = true;
    }

    if (lspClientCapabilities?.workDoneProgress != true) {
      channel.sendNotification(NotificationMessage(
        method: CustomMethods.analyzerStatus,
        params: AnalyzerStatusParams(isAnalyzing: isAnalyzing),
        jsonrpc: jsonRpcVersion,
      ));
      return;
    }

    if (isAnalyzing) {
      analyzingProgressReporter ??=
          ProgressReporter.serverCreated(this, analyzingProgressToken)
            ..begin('Analyzing…');
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
    return initializationOptions.closingLabels &&
        priorityFiles.contains(file) &&
        isAnalyzed(file);
  }

  /// Returns `true` if Flutter outlines should be sent for [file] with the
  /// given absolute path.
  bool shouldSendFlutterOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.flutterOutline &&
        priorityFiles.contains(file) &&
        _isInFlutterProject(file);
  }

  /// Returns `true` if outlines should be sent for [file] with the given
  /// absolute path.
  bool shouldSendOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.outline && priorityFiles.contains(file);
  }

  void showErrorMessageToUser(String message) {
    showMessageToUser(MessageType.error, message);
  }

  void showMessageToUser(MessageType type, String message) {
    channel.sendNotification(NotificationMessage(
      method: Method.window_showMessage,
      params: ShowMessageParams(type: type.forLsp, message: message),
      jsonrpc: jsonRpcVersion,
    ));
  }

  /// Shows the user a prompt with some actions to select from using
  /// 'window/showMessageRequest'.
  ///
  /// Callers should verify the client supports 'window/showMessageRequest' with
  /// [supportsShowMessageRequest] before calling this, and handle cases where
  /// it is not appropriately.
  ///
  /// This is just a convenience method over [showUserPromptItems] where only
  /// title strings are used.
  @override
  Future<String?> showUserPrompt(
    MessageType type,
    String message,
    List<String> actions,
  ) async {
    assert(supportsShowMessageRequest);
    final response = await showUserPromptItems(
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
    final response = await sendRequest(
      Method.window_showMessageRequest,
      ShowMessageRequestParams(
          type: type.forLsp, message: message, actions: actions),
    );

    final result = response.result;
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
    unawaited(Future(() {
      channel.close();
    }));
    unawaited(_pluginChangeSubscription?.cancel());
  }

  /// There was an error related to the socket from which messages are being
  /// read.
  void socketError(Object error, StackTrace? stackTrace) {
    // Don't send to instrumentation service; not an internal error.
    sendServerErrorNotification('Socket error', error, stackTrace);
  }

  Future<void> updateWorkspaceFolders(
      List<String> addedPaths, List<String> removedPaths) async {
    // TODO(dantup): This is currently case-sensitive!

    // Normalise all potential workspace folder paths as these may contain
    // trailing slashes (the LSP spec does not specify whether folders
    // should/should not have them) and the analysis roots must be normalized.
    final pathContext = resourceProvider.pathContext;
    final addedNormalized = addedPaths.map(pathContext.normalize).toList();
    final removedNormalized = removedPaths.map(pathContext.normalize).toList();

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
    if (supportsShowMessageRequest && unifiedAnalytics.shouldShowMessage) {
      unawaited(showUserPrompt(
          MessageType.info, unifiedAnalytics.getConsentMessage, ['Ok']));
      unifiedAnalytics.clientShowedMessage();
    }
  }

  /// Computes analysis roots for a set of open files.
  ///
  /// This is used when there are no workspace folders open directly.
  List<String> _getRootsForOpenFiles() {
    final openFiles = priorityFiles.toList();
    final contextLocator = ContextLocator(resourceProvider: resourceProvider);
    final roots = contextLocator.locateRoots(includedPaths: openFiles);

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

    return [
      ...packages,
      ...additionalFiles,
    ];
  }

  Future<void> _handleNotificationMessage(
    NotificationMessage message,
    MessageInfo messageInfo,
  ) async {
    final result = await messageHandler.handleMessage(message, messageInfo);
    if (result.isError) {
      sendErrorResponse(message, result.error);
    }
  }

  Future<void> _handleRequestMessage(
    RequestMessage message,
    MessageInfo messageInfo,
  ) async {
    final result = await messageHandler.handleMessage(message, messageInfo);
    if (result.isError) {
      sendErrorResponse(message, result.error);
    } else {
      sendResponse(ResponseMessage(
        id: message.id,
        result: result.result,
        jsonrpc: jsonRpcVersion,
      ));
    }
  }

  /// Checks whether [file] is in a project that can resolve 'package:flutter'
  /// libraries.
  bool _isInFlutterProject(String file) =>
      contextManager
          .getDriverFor(file)
          ?.currentSession
          .uriConverter
          .uriToPath(Uri.parse(Flutter.instance.widgetsUri)) !=
      null;

  void _notifyPluginsOverlayChanged(
      String path, plugin.HasToJson changeForPlugins) {
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
    final includedPaths = _workspaceFolders.isNotEmpty
        ? _workspaceFolders.toSet()
        : _getRootsForOpenFiles();

    final excludedPaths = lspClientConfiguration.global.analysisExcludedFolders
        .expand((excludePath) => resourceProvider.pathContext
                .isAbsolute(excludePath)
            ? [excludePath]
            // Apply the relative path to each open workspace folder.
            // TODO(dantup): Consider supporting per-workspace config by
            // calling workspace/configuration whenever workspace folders change
            // and caching the config for each one.
            : _workspaceFolders.map(
                (root) => resourceProvider.pathContext.join(root, excludePath)))
        .toSet();

    final completer = analysisContextRebuildCompleter = Completer();
    try {
      var includedPathsList = includedPaths.toList();
      var excludedPathsList = excludedPaths.toList();
      notificationManager.setAnalysisRoots(
          includedPathsList, excludedPathsList);
      if (detachableFileSystemManager != null) {
        detachableFileSystemManager?.setAnalysisRoots(
            null, includedPathsList, excludedPathsList);
      } else {
        await contextManager.setRoots(includedPathsList, excludedPathsList);
      }
    } finally {
      completer.complete();
    }
  }

  void _updateDriversAndPluginsPriorityFiles() {
    final priorityFilesList = priorityFiles.toList();
    for (var driver in driverMap.values) {
      driver.priorityFiles = priorityFilesList;
    }

    if (AnalysisServer.supportsPlugins) {
      final pluginPriorities =
          plugin.AnalysisSetPriorityFilesParams(priorityFilesList);
      pluginManager.setAnalysisSetPriorityFilesParams(pluginPriorities);

      // Plugins send most of their analysis results via notifications, but with
      // LSP we're supposed to have them available per request. Assume that
      // we'll only receive requests for files that are currently open.
      final pluginSubscriptions = plugin.AnalysisSetSubscriptionsParams({
        for (final service in plugin.AnalysisService.VALUES)
          service: priorityFilesList,
      });
      pluginManager.setAnalysisSetSubscriptionsParams(pluginSubscriptions);
    }

    notificationManager.setSubscriptions({
      for (final service in protocol.AnalysisService.VALUES)
        service: priorityFiles
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
        allowOpenUri = options['allowOpenUri'] == true;
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
    for (final file in files) {
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

    final unit = result.unit;
    if (analysisServer.shouldSendClosingLabelsFor(path)) {
      final labels = DartUnitClosingLabelsComputer(result.lineInfo, unit)
          .compute()
          .map((l) => toClosingLabel(result.lineInfo, l))
          .toList();

      analysisServer.publishClosingLabels(path, labels);
    }
    if (analysisServer.shouldSendOutlineFor(path)) {
      final outline = DartUnitOutlineComputer(
        result,
        withBasicFlutter: true,
      ).compute();
      final lspOutline = toOutline(result.lineInfo, outline);
      analysisServer.publishOutline(path, lspOutline);
    }
    if (analysisServer.shouldSendFlutterOutlineFor(path)) {
      final outline = FlutterOutlineComputer(result).compute();
      final lspOutline = toFlutterOutline(result.lineInfo, outline);
      analysisServer.publishFlutterOutline(path, lspOutline);
    }
  }

  @override
  void listenAnalysisDriver(analysis.AnalysisDriver driver) {
    // TODO(dantup): Is this required, or covered by
    // addContextsToDeclarationsTracker? The original server does not appear to
    // have an equivalent call.
    final analysisContext = driver.analysisContext;
    if (analysisContext != null) {
      analysisServer.declarationsTracker?.addContext(analysisContext);
    }

    super.listenAnalysisDriver(driver);
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
    return analysisServer.lspClientConfiguration.global.showTodoTypes
        .contains(error.code.toUpperCase());
  }
}
