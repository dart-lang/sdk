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
   * The content overlay for all analysis drivers.
   */
  final nd.FileContentOverlay fileContentOverlay = new nd.FileContentOverlay();

  /**
   * The default options used to create new analysis contexts. This object is
   * also referenced by the ContextManager.
   */
  final AnalysisOptionsImpl defaultContextOptions = new AnalysisOptionsImpl();

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

  /**
   * Initialize a newly created server to send and receive messages to the given
   * [channel].
   */
  LspAnalysisServer(
    this.channel,
    ResourceProvider resourceProvider,
    this.options,
    this.sdkManager,
    this.instrumentationService, {
    ResolverProvider packageResolverProvider: null,
  }) : super(resourceProvider) {
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
        fileContentOverlay,
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
  void done() {
    // TODO(dantup): Do we need to do anything here?
  }

  /**
   * There was an error related to the socket from which messages are being
   * read.
   */
  void error(error, stack) {
    // TODO(dantup): It's not legal to print this!
    print(error);
    print(stack);
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

  /**
   * Handle a [message] that was read from the communication channel.
   */
  void handleMessage(IncomingMessage message) {
    // TODO(dantup): Put in all the things this server is missing, like:
    //     _performance.logRequest(message);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() async {
        try {
          final result = await messageHandler.handleMessage(message);
          if (message is RequestMessage) {
            channel.sendResponse(
                new ResponseMessage(message.id, result, null, jsonRpcVersion));
          }
        } on ResponseError catch (error) {
          sendErrorResponse(message, error);
        } catch (error, stackTrace) {
          sendErrorResponse(
              message,
              new ResponseError(
                  ServerErrorCodes.UnhandledError,
                  'An error occurred while handling ${message.method} message',
                  null));
          logError(error.toString());
          if (stackTrace != null) {
            logError(stackTrace.toString());
          }
        }
      });
    }, onError: (error, stackTrace) {
      sendErrorResponse(
          message,
          new ResponseError(ServerErrorCodes.UnhandledError, error.toString(),
              stackTrace?.toString()));
      return;
    });
  }

  void logError(String message) {
    channel.sendNotification(new NotificationMessage(
        'window/logMessage',
        Either2<List<dynamic>, dynamic>.t2(
            new LogMessageParams(MessageType.Error, message)),
        jsonRpcVersion));
  }

  void sendErrorResponse(IncomingMessage message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(
          new ResponseMessage(message.id, null, error, jsonRpcVersion));
      // Since the LSP client might not show the failed requests to the user,
      // also ensure the error is logged to the client.
      logError(error.message);
    } else {
      channel.sendNotification(new NotificationMessage(
          'window/showMessage',
          Either2<List<dynamic>, dynamic>.t2(
              new ShowMessageParams(MessageType.Error, error.message)),
          jsonRpcVersion));
    }
  }

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(NotificationMessage notification) {
    channel.sendNotification(notification);
  }

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(ResponseMessage response) {
    channel.sendResponse(response);
  }

  void sendServerErrorNotification(String message, exception, stackTrace,
      {bool fatal = false}) {
    // TODO(dantup): Fix this; we can't just write to stdout.
    print(message);
    print(exception);
    print(stackTrace);
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

  Future<void> shutdown() {
    // Defer closing the channel so that the shutdown response can be sent and
    // logged.
    new Future(() {
      channel.close();
    });

    return new Future.value();
  }

  void updateOverlay(String path, String contents) {
    fileContentOverlay[path] = contents;
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
            'textDocument/publishDiagnostics',
            Either2<List<dynamic>, dynamic>.t2(params),
            jsonRpcVersion);
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
    builder.fileContentOverlay = analysisServer.fileContentOverlay;
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
