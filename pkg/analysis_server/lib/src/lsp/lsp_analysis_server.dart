// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analysis_server_abstract.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/computer_closingLabels.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_completion.dart'
    show CompletionDomainHandler;
import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
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
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/server/error_notifier.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart'
    show CompletionPerformance;
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

/// Instances of the class [LspAnalysisServer] implement an LSP-based server
/// that listens on a [CommunicationChannel] for LSP messages and processes
/// them.
class LspAnalysisServer extends AbstractAnalysisServer {
  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities _clientCapabilities;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  LspInitializationOptions _initializationOptions;

  /// Configuration for the workspace from the client. This is similar to
  /// initializationOptions but can be updated dynamically rather than set
  /// only when the server starts.
  final LspClientConfiguration clientConfiguration = LspClientConfiguration();

  /// The channel from which messages are received and to which responses should
  /// be sent.
  final LspServerCommunicationChannel channel;

  /// The workspace for rename refactorings. Should be accessed through the
  /// refactoringWorkspace getter to be automatically created (lazily).
  RefactoringWorkspace _refactoringWorkspace;

  /// The versions of each document known to the server (keyed by path), used to
  /// send back to the client for server-initiated edits so that the client can
  /// ensure they have a matching version of the document before applying them.
  ///
  /// Handlers should prefer to use the `getVersionedDocumentIdentifier` method
  /// which will return a null-versioned identifier if the document version is
  /// not known.
  final Map<String, VersionedTextDocumentIdentifier> documentVersions = {};

  ServerStateMessageHandler messageHandler;

  int nextRequestId = 1;

  final Map<int, Completer<ResponseMessage>> completers = {};

  /// Capabilities of the server. Will be null prior to initialization as
  /// the server capabilities depend on the client capabilities.
  ServerCapabilities capabilities;
  ServerCapabilitiesComputer capabilitiesComputer;

  LspPerformance performanceStats = LspPerformance();

  /// Whether or not the server is controlling the shutdown and will exit
  /// automatically.
  bool willExit = false;

  StreamSubscription _pluginChangeSubscription;

  /// Temporary analysis roots for open files.
  ///
  /// When a file is opened and there is no driver available (for example no
  /// folder was opened in the editor, so the set of analysis roots is empty)
  /// we add temporary roots for the project (or containing) folder. When the
  /// file is closed, it is removed from this map and if no other open file
  /// uses that root, it will be removed from the set of analysis roots.
  ///
  /// key: file path of the open file
  /// value: folder to be used as a root.
  final _temporaryAnalysisRoots = <String, String>{};

  /// The set of analysis roots explicitly added to the workspace.
  final _explicitAnalysisRoots = HashSet<String>();

  /// A progress reporter for analysis status.
  ProgressReporter analyzingProgressReporter;

  /// Initialize a newly created server to send and receive messages to the
  /// given [channel].
  LspAnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    AnalysisServerOptions options,
    DartSdkManager sdkManager,
    CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder,
    InstrumentationService instrumentationService, {
    DiagnosticServer diagnosticServer,
  }) : super(
          options,
          sdkManager,
          diagnosticServer,
          crashReportingAttachmentsBuilder,
          baseResourceProvider,
          instrumentationService,
          LspNotificationManager(channel, baseResourceProvider.pathContext),
        ) {
    notificationManager.server = this;
    messageHandler = UninitializedStateMessageHandler(this);
    capabilitiesComputer = ServerCapabilitiesComputer(this);

    final contextManagerCallbacks =
        LspServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;

    analysisDriverScheduler.status.listen(sendStatusNotification);
    analysisDriverScheduler.start();

    channel.listen(handleMessage, onDone: done, onError: socketError);
    _pluginChangeSubscription =
        pluginManager.pluginsChanged.listen((_) => _onPluginsChanged());
  }

  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities get clientCapabilities => _clientCapabilities;

  Future<void> get exited => channel.closed;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  LspInitializationOptions get initializationOptions => _initializationOptions;

  @override
  LspNotificationManager get notificationManager => super.notificationManager;

  @override
  set pluginManager(PluginManager value) {
    // we exchange the plugin manager in tests
    super.pluginManager = value;
    _pluginChangeSubscription?.cancel();

    _pluginChangeSubscription =
        pluginManager.pluginsChanged.listen((_) => _onPluginsChanged());
  }

  RefactoringWorkspace get refactoringWorkspace => _refactoringWorkspace ??=
      RefactoringWorkspace(driverMap.values, searchEngine);

  void addPriorityFile(String path) {
    final didAdd = priorityFiles.add(path);
    assert(didAdd);
    if (didAdd) {
      _updateDriversAndPluginsPriorityFiles();
    }
  }

  /// Adds a temporary analysis root for an open file.
  void addTemporaryAnalysisRoot(String filePath, String folderPath) {
    _temporaryAnalysisRoots[filePath] = folderPath;
    _refreshAnalysisRoots();
  }

  /// The socket from which messages are being read has been closed.
  void done() {}

  /// Fetches configuration from the client (if supported) and then sends
  /// register/unregister requests for any supported/enabled dynamic registrations.
  Future<void> fetchClientConfigurationAndPerformDynamicRegistration() async {
    if (clientCapabilities.workspace?.configuration ?? false) {
      // Fetch all configuration we care about from the client. This is just
      // "dart" for now, but in future this may be extended to include
      // others (for example "flutter").
      final response = await sendRequest(
          Method.workspace_configuration,
          ConfigurationParams(items: [
            ConfigurationItem(section: 'dart'),
          ]));

      final result = response.result;

      // Expect the result to be a single list (to match the single
      // ConfigurationItem we requested above) and that it should be
      // a standard map of settings.
      // If the above code is extended to support multiple sets of config
      // this will need tweaking to handle each group appropriately.
      if (result != null &&
          result is List<dynamic> &&
          result.length == 1 &&
          result.first is Map<String, dynamic>) {
        final newConfig = result.first;
        final refreshRoots =
            clientConfiguration.affectsAnalysisRoots(newConfig);

        clientConfiguration.replace(newConfig);

        if (refreshRoots) {
          _refreshAnalysisRoots();
        }
      }
    }

    // Client config can affect capabilities, so this should only be done after
    // we have the initial/updated config.
    capabilitiesComputer.performDynamicRegistration();
  }

  /// Return the LineInfo for the file with the given [path]. The file is
  /// analyzed in one of the analysis drivers to which the file was added,
  /// otherwise in the first driver, otherwise `null` is returned.
  LineInfo getLineInfo(String path) {
    return getAnalysisDriver(path)?.getFileSync(path)?.lineInfo;
  }

  /// Gets the version of a document known to the server, returning a
  /// [OptionalVersionedTextDocumentIdentifier] with a version of `null` if the document
  /// version is not known.
  OptionalVersionedTextDocumentIdentifier getVersionedDocumentIdentifier(
      String path) {
    return OptionalVersionedTextDocumentIdentifier(
        uri: Uri.file(path).toString(),
        version: documentVersions[path]?.version);
  }

  void handleClientConnection(
      ClientCapabilities capabilities, dynamic initializationOptions) {
    _clientCapabilities = capabilities;
    _initializationOptions = LspInitializationOptions(initializationOptions);

    performanceAfterStartup = ServerPerformance();
    performance = performanceAfterStartup;
  }

  /// Handles a response from the client by invoking the completer that the
  /// outbound request created.
  void handleClientResponse(ResponseMessage message) {
    // The ID from the client is an Either2<num, String>, though it's not valid
    // for it to be a string because it should match a request we sent to the
    // client (and we always use numeric IDs for outgoing requests).
    message.id.map(
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
    performance.logRequestTiming(null);
    runZonedGuarded(() async {
      try {
        if (message is ResponseMessage) {
          handleClientResponse(message);
        } else if (message is RequestMessage) {
          final result = await messageHandler.handleMessage(message);
          if (result.isError) {
            sendErrorResponse(message, result.error);
          } else {
            channel.sendResponse(ResponseMessage(
                id: message.id,
                result: result.result,
                jsonrpc: jsonRpcVersion));
          }
        } else if (message is NotificationMessage) {
          final result = await messageHandler.handleMessage(message);
          if (result.isError) {
            sendErrorResponse(message, result.error);
          }
        } else {
          showErrorMessageToUser('Unknown message type');
        }
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

  /// Returns `true` if the [file] with the given absolute path is included
  /// in an analysis root and not excluded.
  bool isAnalyzedFile(String file) {
    return contextManager.isInAnalysisRoot(file) &&
        // Dot folders are not analyzed (skipped over in _handleWatchEventImpl)
        !contextManager.isContainedInDotFolder(file) &&
        !contextManager.isIgnored(file);
  }

  /// Logs the error on the client using window/logMessage.
  void logErrorToClient(String message) {
    channel.sendNotification(NotificationMessage(
      method: Method.window_logMessage,
      params: LogMessageParams(type: MessageType.Error, message: message),
      jsonrpc: jsonRpcVersion,
    ));
  }

  /// Logs an exception by sending it to the client (window/logMessage) and
  /// recording it in a buffer on the server for diagnostics.
  void logException(String message, exception, stackTrace) {
    var fullMessage = message;
    if (exception is CaughtException) {
      stackTrace ??= exception.stackTrace;
      fullMessage = '$fullMessage: ${exception.exception}';
    } else if (exception != null) {
      fullMessage = '$fullMessage: $exception';
    }

    final fullError =
        stackTrace == null ? fullMessage : '$fullMessage\n$stackTrace';

    // Log the full message since showMessage above may be truncated or
    // formatted badly (eg. VS Code takes the newlines out).
    logErrorToClient(fullError);

    // remember the last few exceptions
    exceptions.add(ServerException(
      message,
      exception,
      stackTrace is StackTrace ? stackTrace : null,
      false,
    ));

    AnalysisEngine.instance.instrumentationService.logException(
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

    _afterOverlayChanged(path, plugin.AddContentOverlay(content));
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
  void onOverlayUpdated(String path, Iterable<plugin.SourceEdit> edits,
      {String newContent}) {
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
        uri: Uri.file(path).toString(), labels: labels);
    final message = NotificationMessage(
      method: CustomMethods.publishClosingLabels,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishDiagnostics(String path, List<Diagnostic> errors) {
    final params = PublishDiagnosticsParams(
        uri: Uri.file(path).toString(), diagnostics: errors);
    final message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishFlutterOutline(String path, FlutterOutline outline) {
    final params = PublishFlutterOutlineParams(
        uri: Uri.file(path).toString(), outline: outline);
    final message = NotificationMessage(
      method: CustomMethods.publishFlutterOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishOutline(String path, Outline outline) {
    final params =
        PublishOutlineParams(uri: Uri.file(path).toString(), outline: outline);
    final message = NotificationMessage(
      method: CustomMethods.publishOutline,
      params: params,
      jsonrpc: jsonRpcVersion,
    );
    sendNotification(message);
  }

  void removePriorityFile(String path) {
    final didRemove = priorityFiles.remove(path);
    assert(didRemove);
    if (didRemove) {
      _updateDriversAndPluginsPriorityFiles();
    }
  }

  /// Removes any temporary analysis root for a file that was closed.
  void removeTemporaryAnalysisRoot(String filePath) {
    _temporaryAnalysisRoots.remove(filePath);
    _refreshAnalysisRoots();
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(ResponseMessage(
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

      shutdown();
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
      id: Either2<num, String>.t1(requestId),
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
    ));

    return completer.future;
  }

  /// Send the given [response] to the client.
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
  }

  @override
  void sendServerErrorNotification(String message, exception, stackTrace,
      {bool fatal = false}) {
    message = exception == null ? message : '$message: $exception';

    // Show message (without stack) to the user.
    showErrorMessageToUser(message);

    logException(message, exception, stackTrace);
  }

  /// Send status notification to the client. The state of analysis is given by
  /// the [status] information.
  Future<void> sendStatusNotification(nd.AnalysisStatus status) async {
    // Send old custom notifications to clients that do not support $/progress.
    // TODO(dantup): Remove this custom notification (and related classes) when
    // it's unlikely to be in use by any clients.
    if (clientCapabilities.window?.workDoneProgress != true) {
      channel.sendNotification(NotificationMessage(
        method: CustomMethods.analyzerStatus,
        params: AnalyzerStatusParams(isAnalyzing: status.isAnalyzing),
        jsonrpc: jsonRpcVersion,
      ));
      return;
    }

    if (status.isAnalyzing) {
      analyzingProgressReporter ??=
          ProgressReporter.serverCreated(this, analyzingProgressToken)
            ..begin('Analyzing…');
    } else {
      if (analyzingProgressReporter != null) {
        // Do not null this out until after end completes, otherwise we may try
        // to create a new token before it's really completed.
        await analyzingProgressReporter.end();
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
        contextManager.isInAnalysisRoot(file);
  }

  /// Returns `true` if errors should be reported for [file] with the given
  /// absolute path.
  bool shouldSendErrorsNotificationFor(String file) {
    return isAnalyzedFile(file);
  }

  /// Returns `true` if Flutter outlines should be sent for [file] with the
  /// given absolute path.
  bool shouldSendFlutterOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.flutterOutline && priorityFiles.contains(file);
  }

  /// Returns `true` if outlines should be sent for [file] with the given
  /// absolute path.
  bool shouldSendOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.outline && priorityFiles.contains(file);
  }

  void showErrorMessageToUser(String message) {
    showMessageToUser(MessageType.Error, message);
  }

  void showMessageToUser(MessageType type, String message) {
    channel.sendNotification(NotificationMessage(
      method: Method.window_showMessage,
      params: ShowMessageParams(type: type, message: message),
      jsonrpc: jsonRpcVersion,
    ));
  }

  /// Shows the user a prompt with some actions to select using ShowMessageRequest.
  Future<MessageActionItem> showUserPrompt(
      MessageType type, String message, List<MessageActionItem> actions) async {
    final response = await sendRequest(
      Method.window_showMessageRequest,
      ShowMessageRequestParams(type: type, message: message, actions: actions),
    );

    return MessageActionItem.fromJson(response.result);
  }

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    Future(() {
      channel.close();
    });
    _pluginChangeSubscription?.cancel();

    return Future.value();
  }

  /// There was an error related to the socket from which messages are being
  /// read.
  void socketError(error, stack) {
    // Don't send to instrumentation service; not an internal error.
    sendServerErrorNotification('Socket error', error, stack);
  }

  void updateAnalysisRoots(List<String> addedPaths, List<String> removedPaths) {
    // TODO(dantup): This is currently case-sensitive!

    _explicitAnalysisRoots
      ..addAll(addedPaths ?? const [])
      ..removeAll(removedPaths ?? const []);

    _refreshAnalysisRoots();
  }

  void _afterOverlayChanged(String path, dynamic changeForPlugins) {
    driverMap.values.forEach((driver) => driver.changeFile(path));
    pluginManager.setAnalysisUpdateContentParams(
      plugin.AnalysisUpdateContentParams({path: changeForPlugins}),
    );

    notifyDeclarationsTracker(path);
    notifyFlutterWidgetDescriptions(path);
  }

  void _onPluginsChanged() {
    capabilitiesComputer.performDynamicRegistration();
  }

  void _refreshAnalysisRoots() {
    // Always include any temporary analysis roots for open files.
    final includedPaths = HashSet<String>.of(_explicitAnalysisRoots)
      ..addAll(_temporaryAnalysisRoots.values)
      ..toList();

    final excludedPaths = clientConfiguration.analysisExcludedFolders
        .expand((excludePath) => isAbsolute(excludePath)
            ? [excludePath]
            // Apply the relative path to each open workspace folder.
            // TODO(dantup): Consider supporting per-workspace config by
            // calling workspace/configuration whenever workspace folders change
            // and caching the config for each one.
            : _explicitAnalysisRoots.map((root) => join(root, excludePath)))
        .toList();

    declarationsTracker?.discardContexts();
    notificationManager.setAnalysisRoots(includedPaths.toList(), excludedPaths);
    contextManager.setRoots(includedPaths.toList(), excludedPaths);
    addContextsToDeclarationsTracker();
  }

  void _updateDriversAndPluginsPriorityFiles() {
    final priorityFilesList = priorityFiles.toList();
    driverMap.values.forEach((driver) {
      driver.priorityFiles = priorityFilesList;
    });

    final pluginPriorities =
        plugin.AnalysisSetPriorityFilesParams(priorityFilesList);
    pluginManager.setAnalysisSetPriorityFilesParams(pluginPriorities);

    // Plugins send most of their analysis results via notifications, but with
    // LSP we're supposed to have them available per request. Assume that we'll
    // only receive requests for files that are currently open.
    final pluginSubscriptions = plugin.AnalysisSetSubscriptionsParams({
      for (final service in plugin.AnalysisService.VALUES)
        service: priorityFilesList,
    });
    pluginManager.setAnalysisSetSubscriptionsParams(pluginSubscriptions);

    notificationManager.setSubscriptions({
      for (final service in protocol.AnalysisService.VALUES)
        service: priorityFiles
    });
  }
}

class LspInitializationOptions {
  final bool onlyAnalyzeProjectsWithOpenFiles;
  final bool suggestFromUnimportedLibraries;
  final bool closingLabels;
  final bool outline;
  final bool flutterOutline;

  LspInitializationOptions(dynamic options)
      : onlyAnalyzeProjectsWithOpenFiles = options != null &&
            options['onlyAnalyzeProjectsWithOpenFiles'] == true,
        // suggestFromUnimportedLibraries defaults to true, so must be
        // explicitly passed as false to disable.
        suggestFromUnimportedLibraries = options == null ||
            options['suggestFromUnimportedLibraries'] != false,
        closingLabels = options != null && options['closingLabels'] == true,
        outline = options != null && options['outline'] == true,
        flutterOutline = options != null && options['flutterOutline'] == true;
}

class LspPerformance {
  /// A list of code completion performance measurements for the latest
  /// completion operation up to [performanceListMaxLength] measurements.
  final RecentBuffer<CompletionPerformance> completion =
      RecentBuffer<CompletionPerformance>(
          CompletionDomainHandler.performanceListMaxLength);
}

class LspServerContextManagerCallbacks extends ContextManagerCallbacks {
  // TODO(dantup): Lots of copy/paste from the Analysis Server one here.

  final LspAnalysisServer analysisServer;

  /// The [ResourceProvider] by which paths are converted into [Resource]s.
  final ResourceProvider resourceProvider;

  LspServerContextManagerCallbacks(this.analysisServer, this.resourceProvider);

  @override
  LspNotificationManager get notificationManager =>
      analysisServer.notificationManager;

  @override
  nd.AnalysisDriver addAnalysisDriver(Folder folder, ContextRoot contextRoot) {
    var builder = createContextBuilder(folder);
    var analysisDriver = builder.buildDriver(contextRoot);
    final textDocumentCapabilities =
        analysisServer.clientCapabilities?.textDocument;
    final supportedDiagnosticTags = HashSet<DiagnosticTag>.of(
        textDocumentCapabilities?.publishDiagnostics?.tagSupport?.valueSet ??
            []);
    analysisDriver.results.listen((result) {
      var path = result.path;
      if (analysisServer.shouldSendErrorsNotificationFor(path)) {
        final serverErrors = protocol.mapEngineErrors(
            result,
            result.errors.where(_shouldSendDiagnostic).toList(),
            (result, error, [severity]) => toDiagnostic(
                  result,
                  error,
                  supportedTags: supportedDiagnosticTags,
                  errorSeverity: severity,
                ));

        analysisServer.publishDiagnostics(result.path, serverErrors);
      }
      if (result.unit != null) {
        if (analysisServer.shouldSendClosingLabelsFor(path)) {
          final labels =
              DartUnitClosingLabelsComputer(result.lineInfo, result.unit)
                  .compute()
                  .map((l) => toClosingLabel(result.lineInfo, l))
                  .toList();

          analysisServer.publishClosingLabels(result.path, labels);
        }
        if (analysisServer.shouldSendOutlineFor(path)) {
          final outline = DartUnitOutlineComputer(
            result,
            withBasicFlutter: true,
          ).compute();
          final lspOutline = toOutline(result.lineInfo, outline);
          analysisServer.publishOutline(result.path, lspOutline);
        }
        if (analysisServer.shouldSendFlutterOutlineFor(path)) {
          final outline = FlutterOutlineComputer(result).compute();
          final lspOutline = toFlutterOutline(result.lineInfo, outline);
          analysisServer.publishFlutterOutline(result.path, lspOutline);
        }
      }
    });
    analysisDriver.exceptions.listen(analysisServer.logExceptionResult);
    analysisDriver.priorityFiles = analysisServer.priorityFiles.toList();
    analysisServer.driverMap[folder] = analysisDriver;
    return analysisDriver;
  }

  @override
  void afterWatchEvent(WatchEvent event) {
    // TODO: implement afterWatchEvent
  }

  @override
  void analysisOptionsUpdated(nd.AnalysisDriver driver) {
    // TODO: implement analysisOptionsUpdated
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    var analysisDriver = analysisServer.driverMap[contextFolder];
    if (analysisDriver != null) {
      changeSet.addedFiles.forEach((path) {
        analysisDriver.addFile(path);
      });
      changeSet.changedFiles.forEach((path) {
        analysisDriver.changeFile(path);
      });
      changeSet.removedFiles.forEach((path) {
        analysisDriver.removeFile(path);
      });
    }
  }

  @override
  void applyFileRemoved(nd.AnalysisDriver driver, String file) {
    driver.removeFile(file);
    analysisServer.publishDiagnostics(file, []);
  }

  @override
  void broadcastWatchEvent(WatchEvent event) {
    analysisServer.notifyDeclarationsTracker(event.path);
    analysisServer.notifyFlutterWidgetDescriptions(event.path);
    analysisServer.pluginManager.broadcastWatchEvent(event);
  }

  @override
  ContextBuilder createContextBuilder(Folder folder) {
    var builderOptions = ContextBuilderOptions();
    var builder = ContextBuilder(
        resourceProvider, analysisServer.sdkManager, null,
        options: builderOptions);
    builder.analysisDriverScheduler = analysisServer.analysisDriverScheduler;
    builder.performanceLog = analysisServer.analysisPerformanceLogger;
    builder.byteStore = analysisServer.byteStore;
    builder.enableIndex = true;
    return builder;
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    var driver = analysisServer.driverMap.remove(folder);
    // Flush any errors for these files that the client may be displaying.
    flushedFiles
        ?.forEach((path) => analysisServer.publishDiagnostics(path, const []));
    driver.dispose();
  }

  bool _shouldSendDiagnostic(AnalysisError error) =>
      error.errorCode.type != ErrorType.TODO ||
      analysisServer.clientConfiguration.showTodos;
}
