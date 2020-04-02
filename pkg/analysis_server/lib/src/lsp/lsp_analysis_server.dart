// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;

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
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart'
    show CompletionPerformance;
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_state.dart' as nd;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/services/available_declarations.dart';
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

  /// The channel from which messages are received and to which responses should
  /// be sent.
  final LspServerCommunicationChannel channel;

  /// The [SearchEngine] for this server, may be `null` if indexing is disabled.
  SearchEngine searchEngine;

  final NotificationManager notificationManager = NullNotificationManager();

  /// The object used to manage the SDK's known to this server.
  final DartSdkManager sdkManager;

  /// The instrumentation service that is to be used by this analysis server.
  final InstrumentationService instrumentationService;

  /// The default options used to create new analysis contexts. This object is
  /// also referenced by the ContextManager.
  final AnalysisOptionsImpl defaultContextOptions = AnalysisOptionsImpl();

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

  PerformanceLog _analysisPerformanceLogger;

  ServerStateMessageHandler messageHandler;

  int nextRequestId = 1;

  final Map<int, Completer<ResponseMessage>> completers = {};

  /// Capabilities of the server. Will be null prior to initialization as
  /// the server capabilities depend on the client capabilities.
  ServerCapabilities capabilities;

  LspPerformance performanceStats = LspPerformance();

  /// Whether or not the server is controlling the shutdown and will exit
  /// automatically.
  bool willExit = false;

  /// Initialize a newly created server to send and receive messages to the
  /// given [channel].
  LspAnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    AnalysisServerOptions options,
    this.sdkManager,
    CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder,
    this.instrumentationService, {
    DiagnosticServer diagnosticServer,
  }) : super(options, diagnosticServer, crashReportingAttachmentsBuilder,
            baseResourceProvider) {
    messageHandler = UninitializedStateMessageHandler(this);
    // TODO(dantup): This code is almost identical to AnalysisServer, consider
    // moving it the base class that already holds many of these fields.
    defaultContextOptions.generateImplicitErrors = false;
    defaultContextOptions.useFastaParser = options.useFastaParser;

    {
      var name = options.newAnalysisDriverLog;
      StringSink sink = NullStringSink();
      if (name != null) {
        if (name == 'stdout') {
          sink = io.stdout;
        } else if (name.startsWith('file:')) {
          var path = name.substring('file:'.length);
          sink = io.File(path).openWrite(mode: io.FileMode.append);
        }
      }
      _analysisPerformanceLogger = PerformanceLog(sink);
    }
    byteStore = createByteStore(resourceProvider);
    analysisDriverScheduler =
        nd.AnalysisDriverScheduler(_analysisPerformanceLogger);
    analysisDriverScheduler.status.listen(sendStatusNotification);
    analysisDriverScheduler.start();

    if (options.featureSet.completion) {
      declarationsTracker = DeclarationsTracker(byteStore, resourceProvider);
      declarationsTrackerData = DeclarationsTrackerData(declarationsTracker);
      analysisDriverScheduler.outOfBandWorker =
          CompletionLibrariesWorker(declarationsTracker);
    }

    contextManager = ContextManagerImpl(resourceProvider, sdkManager,
        analyzedFilesGlobs, instrumentationService, defaultContextOptions);
    final contextManagerCallbacks =
        LspServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;
    searchEngine = SearchEngineImpl(driverMap.values);

    channel.listen(handleMessage, onDone: done, onError: socketError);
  }

  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities get clientCapabilities => _clientCapabilities;

  Future<void> get exited => channel.closed;

  /// Initialization options provided by the LSP client. Allows opting in/out of
  /// specific server functionality. Will be null prior to initialization.
  LspInitializationOptions get initializationOptions => _initializationOptions;

  RefactoringWorkspace get refactoringWorkspace => _refactoringWorkspace ??=
      RefactoringWorkspace(driverMap.values, searchEngine);

  void addPriorityFile(String path) {
    final didAdd = priorityFiles.add(path);
    assert(didAdd);
    if (didAdd) {
      _updateDriversPriorityFiles();
    }
  }

  /// The socket from which messages are being read has been closed.
  void done() {}

  /// Return the LineInfo for the file with the given [path]. The file is
  /// analyzed in one of the analysis drivers to which the file was added,
  /// otherwise in the first driver, otherwise `null` is returned.
  LineInfo getLineInfo(String path) {
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    return getAnalysisDriver(path)?.getFileSync(path)?.lineInfo;
  }

  /// Gets the version of a document known to the server, returning a
  /// [VersionedTextDocumentIdentifier] with a version of `null` if the document
  /// version is not known.
  VersionedTextDocumentIdentifier getVersionedDocumentIdentifier(String path) {
    return documentVersions[path] ??
        VersionedTextDocumentIdentifier(null, Uri.file(path).toString());
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
    runZonedGuarded(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() async {
        try {
          if (message is ResponseMessage) {
            handleClientResponse(message);
          } else if (message is RequestMessage) {
            final result = await messageHandler.handleMessage(message);
            if (result.isError) {
              sendErrorResponse(message, result.error);
            } else {
              channel.sendResponse(ResponseMessage(
                  message.id, result.result, null, jsonRpcVersion));
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
                ServerErrorCodes.UnhandledError,
                errorMessage,
                null,
              ));
          logException(errorMessage, error, stackTrace);
        }
      });
    }, socketError);
  }

  /// Logs the error on the client using window/logMessage.
  void logErrorToClient(String message) {
    channel.sendNotification(NotificationMessage(
      Method.window_logMessage,
      LogMessageParams(MessageType.Error, message),
      jsonRpcVersion,
    ));
  }

  /// Logs an exception by sending it to the client (window/logMessage) and
  /// recording it in a buffer on the server for diagnostics.
  void logException(String message, exception, stackTrace) {
    if (exception is CaughtException) {
      stackTrace ??= exception.stackTrace;
      message = '$message: ${exception.exception}';
    } else if (exception != null) {
      message = '$message: $exception';
    }

    final fullError = stackTrace == null ? message : '$message\n$stackTrace';

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
  }

  void publishClosingLabels(String path, List<ClosingLabel> labels) {
    final params =
        PublishClosingLabelsParams(Uri.file(path).toString(), labels);
    final message = NotificationMessage(
      CustomMethods.PublishClosingLabels,
      params,
      jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishDiagnostics(String path, List<Diagnostic> errors) {
    final params = PublishDiagnosticsParams(Uri.file(path).toString(), errors);
    final message = NotificationMessage(
      Method.textDocument_publishDiagnostics,
      params,
      jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishFlutterOutline(String path, FlutterOutline outline) {
    final params =
        PublishFlutterOutlineParams(Uri.file(path).toString(), outline);
    final message = NotificationMessage(
      CustomMethods.PublishFlutterOutline,
      params,
      jsonRpcVersion,
    );
    sendNotification(message);
  }

  void publishOutline(String path, Outline outline) {
    final params = PublishOutlineParams(Uri.file(path).toString(), outline);
    final message = NotificationMessage(
      CustomMethods.PublishOutline,
      params,
      jsonRpcVersion,
    );
    sendNotification(message);
  }

  void removePriorityFile(String path) {
    final didRemove = priorityFiles.remove(path);
    assert(didRemove);
    if (didRemove) {
      _updateDriversPriorityFiles();
    }
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(
          ResponseMessage(message.id, null, error, jsonRpcVersion));
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

  /// Send the given [request] to the client and wait for a response.
  Future<ResponseMessage> sendRequest(Method method, Object params) {
    final requestId = nextRequestId++;
    final completer = Completer<ResponseMessage>();
    completers[requestId] = completer;

    channel.sendRequest(RequestMessage(
      Either2<num, String>.t1(requestId),
      method,
      params,
      jsonRpcVersion,
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
  void sendStatusNotification(nd.AnalysisStatus status) {
    channel.sendNotification(NotificationMessage(
      CustomMethods.AnalyzerStatus,
      AnalyzerStatusParams(status.isAnalyzing),
      jsonRpcVersion,
    ));
  }

  void setAnalysisRoots(List<String> includedPaths) {
    declarationsTracker?.discardContexts();
    final uniquePaths = HashSet<String>.of(includedPaths ?? const []);
    contextManager.setRoots(uniquePaths.toList(), [], {});
    addContextsToDeclarationsTracker();
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
    // Errors should not be reported for things that are explicitly skipped
    // during normal analysis (for example dot folders are skipped over in
    // _handleWatchEventImpl).
    return contextManager.isInAnalysisRoot(file) &&
        !contextManager.isContainedInDotFolder(file);
  }

  /// Returns `true` if Flutter outlines should be sent for [file] with the
  /// given absolute path.
  bool shouldSendFlutterOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.flutterOutline &&
        priorityFiles.contains(file) &&
        contextManager.isInAnalysisRoot(file);
  }

  /// Returns `true` if outlines should be sent for [file] with the given
  /// absolute path.
  bool shouldSendOutlineFor(String file) {
    // Outlines should only be sent for open (priority) files in the workspace.
    return initializationOptions.outline &&
        priorityFiles.contains(file) &&
        contextManager.isInAnalysisRoot(file);
  }

  void showErrorMessageToUser(String message) {
    showMessageToUser(MessageType.Error, message);
  }

  void showMessageToUser(MessageType type, String message) {
    channel.sendNotification(NotificationMessage(
      Method.window_showMessage,
      ShowMessageParams(type, message),
      jsonRpcVersion,
    ));
  }

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    Future(() {
      channel.close();
    });

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
    final newPaths =
        HashSet<String>.of(contextManager.includedPaths ?? const [])
          ..addAll(addedPaths ?? const [])
          ..removeAll(removedPaths ?? const []);

    setAnalysisRoots(newPaths.toList());
  }

  void updateOverlay(String path, String contents) {
    if (contents != null) {
      resourceProvider.setOverlay(path,
          content: contents, modificationStamp: 0);
    } else {
      resourceProvider.removeOverlay(path);
    }
    driverMap.values.forEach((driver) => driver.changeFile(path));

    notifyDeclarationsTracker(path);
    notifyFlutterWidgetDescriptions(path);
  }

  void _updateDriversPriorityFiles() {
    driverMap.values.forEach((driver) {
      driver.priorityFiles = priorityFiles.toList();
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
  NotificationManager get notificationManager =>
      analysisServer.notificationManager;

  @override
  nd.AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options) {
    var builder = createContextBuilder(folder, options);
    var analysisDriver = builder.buildDriver(contextRoot);
    analysisDriver.results.listen((result) {
      var path = result.path;
      if (analysisServer.shouldSendErrorsNotificationFor(path)) {
        final serverErrors = protocol.mapEngineErrors(
            result,
            result.errors
                .where((e) => e.errorCode.type != ErrorType.TODO)
                .toList(),
            toDiagnostic);

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
    // TODO: implement plugin broadcastWatchEvent
  }

  @override
  ContextBuilder createContextBuilder(Folder folder, AnalysisOptions options) {
    String defaultPackageFilePath;
    String defaultPackagesDirectoryPath;
    var path = (analysisServer.contextManager as ContextManagerImpl)
        .normalizedPackageRoots[folder.path];
    if (path != null) {
      var resource = resourceProvider.getResource(path);
      if (resource.exists) {
        if (resource is File) {
          defaultPackageFilePath = path;
        } else {
          defaultPackagesDirectoryPath = path;
        }
      }
    }

    var builderOptions = ContextBuilderOptions();
    builderOptions.defaultOptions = options;
    builderOptions.defaultPackageFilePath = defaultPackageFilePath;
    builderOptions.defaultPackagesDirectoryPath = defaultPackagesDirectoryPath;
    var builder = ContextBuilder(
        resourceProvider, analysisServer.sdkManager, null,
        options: builderOptions);
    builder.analysisDriverScheduler = analysisServer.analysisDriverScheduler;
    builder.performanceLog = analysisServer._analysisPerformanceLogger;
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
}

class NullNotificationManager implements NotificationManager {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
