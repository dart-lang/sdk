// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analysis_server_abstract.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_state.dart' as nd;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:watcher/watcher.dart';

/**
 * Instances of the class [LspAnalysisServer] implement an LSP-based server that
 * listens on a [CommunicationChannel] for LSP messages and processes them.
 */
class LspAnalysisServer extends AbstractAnalysisServer {
  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities _clientCapabilities;

  /**
   * The options of this server instance.
   */
  AnalysisServerOptions options;

  /**
   * The channel from which messages are received and to which responses should
   * be sent.
   */
  final LspServerCommunicationChannel channel;

  /// The [SearchEngine] for this server, may be `null` if indexing is disabled.
  SearchEngine searchEngine;

  final NotificationManager notificationManager = new NullNotificationManager();

  /**
   * The object used to manage the SDK's known to this server.
   */
  final DartSdkManager sdkManager;

  /**
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * The default options used to create new analysis contexts. This object is
   * also referenced by the ContextManager.
   */
  final AnalysisOptionsImpl defaultContextOptions = new AnalysisOptionsImpl();

  /**
   * The versions of each document known to the server (keyed by path), used to
   * send back to the client for server-initiated edits so that the client can
   * ensure they have a matching version of the document before applying them.
   * 
   * Handlers should prefer to use the `getVersionedDocumentIdentifier` method
   * which will return a null-versioned identifier if the document version is
   * not known.
   */
  final Map<String, VersionedTextDocumentIdentifier> documentVersions = {};

  /**
   * The file resolver provider used to override the way file URI's are
   * resolved in some contexts.
   */
  ResolverProvider fileResolverProvider;

  /**
   * The package resolver provider used to override the way package URI's are
   * resolved in some contexts.
   */
  ResolverProvider packageResolverProvider;

  PerformanceLog _analysisPerformanceLogger;

  ByteStore byteStore;

  nd.AnalysisDriverScheduler analysisDriverScheduler;

  ServerStateMessageHandler messageHandler;

  int nextRequestId = 1;

  Map<int, Completer<ResponseMessage>> completers = {};

  /**
   * Initialize a newly created server to send and receive messages to the given
   * [channel].
   */
  LspAnalysisServer(
    this.channel,
    ResourceProvider baseResourceProvider,
    this.options,
    this.sdkManager,
    this.instrumentationService, {
    ResolverProvider packageResolverProvider: null,
  }) : super(baseResourceProvider) {
    messageHandler = new UninitializedStateMessageHandler(this);
    defaultContextOptions.generateImplicitErrors = false;
    defaultContextOptions.useFastaParser = options.useFastaParser;

    {
      String name = options.newAnalysisDriverLog;
      StringSink sink = new NullStringSink();
      if (name != null) {
        if (name == 'stdout') {
          sink = io.stdout;
        } else if (name.startsWith('file:')) {
          String path = name.substring('file:'.length);
          sink = new io.File(path).openWrite(mode: io.FileMode.append);
        }
      }
      _analysisPerformanceLogger = new PerformanceLog(sink);
    }
    byteStore = createByteStore(resourceProvider);
    analysisDriverScheduler =
        new nd.AnalysisDriverScheduler(_analysisPerformanceLogger);
    analysisDriverScheduler.start();

    contextManager = new ContextManagerImpl(
        resourceProvider,
        sdkManager,
        packageResolverProvider,
        analyzedFilesGlobs,
        instrumentationService,
        defaultContextOptions);
    final contextManagerCallbacks =
        new LspServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;
    searchEngine = new SearchEngineImpl(driverMap.values);

    channel.listen(handleMessage, onDone: done, onError: error);
  }

  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities get clientCapabilities => _clientCapabilities;

  /**
   * The socket from which messages are being read has been closed.
   */
  void done() {}

  /**
   * There was an error related to the socket from which messages are being
   * read.
   */
  void error(error, stack) {
    sendServerErrorNotification('Server error', error, stack);
  }

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
        new VersionedTextDocumentIdentifier(
            null, new Uri.file(path).toString());
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
        // If it's not in our completers list (which is a list of the outstanding
        // requests we've sent) then show an error.
        final completer = completers[id];
        if (completer == null) {
          showError('Response with ID $id was unexpected');
        } else {
          completers.remove(id);
          completer.complete(message);
        }
      },
      (stringID) {
        showError('Unexpected String ID for response $stringID');
      },
    );
  }

  /**
   * Handle a [message] that was read from the communication channel.
   */
  void handleMessage(Message message) {
    // TODO(dantup): Put in all the things this server is missing, like:
    //     _performance.logRequest(message);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() async {
        try {
          if (message is ResponseMessage) {
            handleClientResponse(message);
          } else if (message is RequestMessage) {
            final result = await messageHandler.handleMessage(message);
            if (result.isError) {
              sendErrorResponse(message, result.error);
            } else {
              channel.sendResponse(new ResponseMessage(
                  message.id, result.result, null, jsonRpcVersion));
            }
          } else if (message is NotificationMessage) {
            final result = await messageHandler.handleMessage(message);
            if (result.isError) {
              sendErrorResponse(message, result.error);
            }
          } else {
            showError('Unknown message type');
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
              new ResponseError(
                ServerErrorCodes.UnhandledError,
                errorMessage,
                null,
              ));
          logError(error.toString());
          if (stackTrace != null) {
            logError(stackTrace.toString());
          }
        }
      });
    }, onError: error);
  }

  void logError(String message) {
    channel.sendNotification(new NotificationMessage(
      Method.window_logMessage,
      new LogMessageParams(MessageType.Error, message),
      jsonRpcVersion,
    ));
  }

  void sendErrorResponse(Message message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(
          new ResponseMessage(message.id, null, error, jsonRpcVersion));
      // Since the LSP client might not show the failed requests to the user,
      // also ensure the error is logged to the client.
      logError(error.message);
    } else if (message is ResponseMessage) {
      // For notifications where we couldn't respond with an error, send it as
      // show instead of log.
      showError(error.message);
    } else {
      // For notifications where we couldn't respond with an error, send it as
      // show instead of log.
      showError(error.message);
    }
  }

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(NotificationMessage notification) {
    channel.sendNotification(notification);
  }

  /**
   * Send the given [request] to the client and wait for a response.
   */
  Future<ResponseMessage> sendRequest(Method method, Object params) {
    final requestId = nextRequestId++;
    final completer = new Completer<ResponseMessage>();
    completers[requestId] = completer;

    channel.sendRequest(new RequestMessage(
      Either2<num, String>.t1(requestId),
      method,
      params,
      jsonRpcVersion,
    ));

    return completer.future;
  }

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
  }

  void sendServerErrorNotification(String message, exception, stackTrace) {
    final fullError = new StringBuffer();
    fullError.writeln(message);
    if (exception != null) {
      fullError.writeln(exception.toString());
    }
    if (stackTrace != null) {
      fullError.writeln(stackTrace.toString());
    }
    showError(message); // Show message to the user.
    logError(fullError.toString()); // Log the full message.
  }

  void setAnalysisRoots(List<String> includedPaths, List<String> excludedPaths,
      Map<String, String> packageRoots) {
    contextManager.setRoots(includedPaths, excludedPaths, packageRoots);
  }

  void setClientCapabilities(ClientCapabilities capabilities) {
    _clientCapabilities = capabilities;
  }

  /**
   * Returns `true` if errors should be reported for [file] with the given
   * absolute path.
   */
  bool shouldSendErrorsNotificationFor(String file) {
    return contextManager.isInAnalysisRoot(file);
  }

  void showError(String message) {
    channel.sendNotification(new NotificationMessage(
      Method.window_showMessage,
      new ShowMessageParams(MessageType.Error, message),
      jsonRpcVersion,
    ));
  }

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    new Future(() {
      channel.close();
    });

    return new Future.value();
  }

  void updateOverlay(String path, String contents) {
    if (contents != null) {
      resourceProvider.setOverlay(path,
          content: contents, modificationStamp: 0);
    } else {
      resourceProvider.removeOverlay(path);
    }
    driverMap.values.forEach((driver) => driver.changeFile(path));
  }
}

class LspServerContextManagerCallbacks extends ContextManagerCallbacks {
  // TODO(dantup): Lots of copy/paste from the Analysis Server one here.

  final LspAnalysisServer analysisServer;

  /**
   * The [ResourceProvider] by which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  LspServerContextManagerCallbacks(this.analysisServer, this.resourceProvider);

  @override
  NotificationManager get notificationManager =>
      analysisServer.notificationManager;

  @override
  nd.AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options) {
    ContextBuilder builder = createContextBuilder(folder, options);
    nd.AnalysisDriver analysisDriver = builder.buildDriver(contextRoot);
    analysisDriver.results.listen((result) {
      String path = result.path;
      if (analysisServer.shouldSendErrorsNotificationFor(path)) {
        final serverErrors = protocol.mapEngineErrors(
            result.session.analysisContext.analysisOptions,
            result.lineInfo,
            result.errors,
            toDiagnostic);

        final params = new PublishDiagnosticsParams(
            Uri.file(result.path).toString(), serverErrors);
        // TODO(dantup): Move all these method names to constants.
        final message = new NotificationMessage(
          Method.textDocument_publishDiagnostics,
          params,
          jsonRpcVersion,
        );
        analysisServer.sendNotification(message);
      }
    });
    analysisDriver.exceptions.listen((nd.ExceptionResult result) {
      String message = 'Analysis failed: ${result.path}';
      if (result.contextKey != null) {
        message += ' context: ${result.contextKey}';
      }
      AnalysisEngine.instance.logger.logError(message, result.exception);
    });
    analysisServer.driverMap[folder] = analysisDriver;
    return analysisDriver;
  }

  @override
  void afterWatchEvent(WatchEvent event) {
    // TODO: implement afterWatchEvent
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    nd.AnalysisDriver analysisDriver = analysisServer.driverMap[contextFolder];
    if (analysisDriver != null) {
      changeSet.addedSources.forEach((source) {
        analysisDriver.addFile(source.fullName);
      });
      changeSet.changedSources.forEach((source) {
        analysisDriver.changeFile(source.fullName);
      });
      changeSet.removedSources.forEach((source) {
        analysisDriver.removeFile(source.fullName);
      });
    }
  }

  @override
  void applyFileRemoved(nd.AnalysisDriver driver, String file) {
    driver.removeFile(file);
    // sendAnalysisNotificationFlushResults(analysisServer, [file]);
  }

  @override
  void broadcastWatchEvent(WatchEvent event) {
    // TODO: implement broadcastWatchEvent
  }

  @override
  ContextBuilder createContextBuilder(Folder folder, AnalysisOptions options) {
    String defaultPackageFilePath = null;
    String defaultPackagesDirectoryPath = null;
    String path = (analysisServer.contextManager as ContextManagerImpl)
        .normalizedPackageRoots[folder.path];
    if (path != null) {
      Resource resource = resourceProvider.getResource(path);
      if (resource.exists) {
        if (resource is File) {
          defaultPackageFilePath = path;
        } else {
          defaultPackagesDirectoryPath = path;
        }
      }
    }

    ContextBuilderOptions builderOptions = new ContextBuilderOptions();
    builderOptions.defaultOptions = options;
    builderOptions.defaultPackageFilePath = defaultPackageFilePath;
    builderOptions.defaultPackagesDirectoryPath = defaultPackagesDirectoryPath;
    ContextBuilder builder = new ContextBuilder(
        resourceProvider, analysisServer.sdkManager, null,
        options: builderOptions);
    builder.fileResolverProvider = analysisServer.fileResolverProvider;
    builder.packageResolverProvider = analysisServer.packageResolverProvider;
    builder.analysisDriverScheduler = analysisServer.analysisDriverScheduler;
    builder.performanceLog = analysisServer._analysisPerformanceLogger;
    builder.byteStore = analysisServer.byteStore;
    builder.enableIndex = true;
    return builder;
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    // sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);
    nd.AnalysisDriver driver = analysisServer.driverMap.remove(folder);
    driver.dispose();
  }
}

class NullNotificationManager implements NotificationManager {
  @override
  noSuchMethod(Invocation invocation) {}
}
