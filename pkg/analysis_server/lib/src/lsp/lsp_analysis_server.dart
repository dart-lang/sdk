// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/handler_completion.dart';
import 'package:analysis_server/src/lsp/handler_formatting.dart';
import 'package:analysis_server/src/lsp/handler_hover.dart';
import 'package:analysis_server/src/lsp/handler_initialization.dart';
import 'package:analysis_server/src/lsp/handler_signature_help.dart';
import 'package:analysis_server/src/lsp/handler_text_document_changes.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_state.dart' as nd;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/plugin/resolver_provider.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:watcher/watcher.dart';

enum InitializationState {
  /// The initialize request has not been received.
  Uninitialized,

  /// The initialize request has been recieved but the initialized notification
  /// has not.
  Initializing,

  /// Both the initialize request and the initialized notification have been
  /// recieved.
  Initialized
}

/**
 * Instances of the class [LspAnalysisServer] implement an LSP-based server that
 * listens on a [CommunicationChannel] for analysis requests and process them.
 */
class LspAnalysisServer {
  InitializationState state = InitializationState.Uninitialized;

  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities _clientCapabilities;

  /**
   * The options of this server instance.
   */
  AnalysisServerOptions options;

  /**
   * The channel from which requests are received and to which responses should
   * be sent.
   */
  final LspServerCommunicationChannel channel;

  final NotificationManager notificationManager = new NullNotificationManager();

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The [ContextManager] that handles the mapping from analysis roots to
   * context directories.
   */
  ContextManager contextManager;

  /**
   * A list of the request handlers used to handle the requests sent to this
   * server.
   */
  Map<String, MessageHandler> handlers = {};

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
   * The current state of overlays from the client.  This is used as the
   * content cache for all contexts.
   */
  final ContentCache overlayState = new ContentCache();

  /**
   * A list of the globs used to determine which files should be analyzed. The
   * list is lazily created and should be accessed using [analyzedFilesGlobs].
   */
  List<Glob> _analyzedFilesGlobs = null;

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

  /**
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   *
   * If [rethrowExceptions] is true, then any exceptions thrown by analysis are
   * propagated up the call stack.  The default is true to allow analysis
   * exceptions to show up in unit tests, but it should be set to false when
   * running a full analysis server.
   */
  LspAnalysisServer(
    this.channel,
    this.resourceProvider,
    this.options,
    this.sdkManager,
    this.instrumentationService, {
    ResolverProvider packageResolverProvider: null,
  }) {
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

    _registerHandler(new InitializationHandler(this));
    _registerHandler(new TextDocumentChangeHandler(this));
    _registerHandler(new HoverHandler(this));
    _registerHandler(new CompletionHandler(this));
    _registerHandler(new SignatureHelpHandler(this));
    _registerHandler(new FormattingHandler(this));
    channel.listen(handleMessage, onDone: done, onError: error);
  }
  /**
   * Return a list of the globs used to determine which files should be analyzed.
   */
  List<Glob> get analyzedFilesGlobs {
    if (_analyzedFilesGlobs == null) {
      _analyzedFilesGlobs = <Glob>[];
      for (String pattern in analyzableFilePatterns) {
        try {
          _analyzedFilesGlobs
              .add(new Glob(resourceProvider.pathContext.separator, pattern));
        } catch (exception, stackTrace) {
          AnalysisEngine.instance.logger.logError(
              'Invalid glob pattern: "$pattern"',
              new CaughtException(exception, stackTrace));
        }
      }
    }
    return _analyzedFilesGlobs;
  }

  /// The capabilities of the LSP client. Will be null prior to initialization.
  ClientCapabilities get clientCapabilities => _clientCapabilities;

  /**
   * A table mapping [Folder]s to the [AnalysisDriver]s associated with them.
   */
  Map<Folder, nd.AnalysisDriver> get driverMap => contextManager.driverMap;

  void changeTextDocument(VersionedTextDocumentIdentifier id,
      List<TextDocumentContentChangeEvent> changes) {
    final path = Uri.parse(id.uri).toFilePath();
    // TODO(dantup): Should we be tracking the version?

    final oldContents = fileContentOverlay[path];
    final newContents = applyEdits(oldContents, changes);

    fileContentOverlay[path] = newContents;

    driverMap.values.forEach((driver) => driver.changeFile(path));
  }

  void closeTextDocument(TextDocumentIdentifier id) {
    final path = Uri.parse(id.uri).toFilePath();
    // TODO(dantup): Should we be tracking the version?

    fileContentOverlay[path] = null;

    driverMap.values.forEach((driver) => driver.changeFile(path));
  }

  /**
   * The socket from which requests are being read has been closed.
   */
  void done() {
    // TODO(dantup): Do we need to do anything here?
  }

  /**
   * There was an error related to the socket from which requests are being
   * read.
   */
  void error(error, stack) {
    // TODO(dantup): It's not legal to print this!
    print(error);
    print(stack);
  }

  /// Return an analysis driver to which the file with the given [path] is
  /// added if one exists, otherwise a driver in which the file was analyzed if
  /// one exists, otherwise the first driver, otherwise `null`.
  nd.AnalysisDriver getAnalysisDriver(String path) {
    // TODO(dantup): This is copy/pasted from AnalysisServer.
    List<nd.AnalysisDriver> drivers = driverMap.values.toList();
    if (drivers.isNotEmpty) {
      // Sort the drivers so that more deeply nested contexts will be checked
      // before enclosing contexts.
      drivers.sort((first, second) =>
          second.contextRoot.root.length - first.contextRoot.root.length);
      nd.AnalysisDriver driver = drivers.firstWhere(
          (driver) => driver.contextRoot.containsFile(path),
          orElse: () => null);
      driver ??= drivers.firstWhere(
          (driver) => driver.knownFiles.contains(path),
          orElse: () => null);
      driver ??= drivers.first;
      return driver;
    }
    return null;
  }

  /// Return the resolved unit for the file with the given [path]. The file is
  /// analyzed in one of the analysis drivers to which the file was added,
  /// otherwise in the first driver, otherwise `null` is returned.
  Future<ResolvedUnitResult> getResolvedUnit(String path,
      {bool sendCachedToStream: false}) {
    // TODO(dantup): This is copy/pasted from AnalysisServer.
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    nd.AnalysisDriver driver = getAnalysisDriver(path);
    if (driver == null) {
      return new Future.value();
    }

    return driver
        .getResult(path, sendCachedToStream: sendCachedToStream)
        .catchError((_) => null);
  }

  /**
   * Handle a [request] that was read from the communication channel.
   */
  void handleMessage(IncomingMessage message) {
    // TODO(dantup): Put in all the things this server is missing, like:
    //     _performance.logRequest(request);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() async {
        // No requests are allowed before the initialize request/response.
        if ((state == InitializationState.Uninitialized &&
                message.method != 'initialize') ||
            (state == InitializationState.Initializing &&
                message.method != 'initialized')) {
          _sendNotInitializedError(message);
          return;
        }

        final handler = handlers[message.method];
        if (handler == null) {
          _sendUnknownMethodError(message);
          return;
        }

        try {
          final result = await handler.handleMessage(message);
          if (message is RequestMessage) {
            channel.sendResponse(
                new ResponseMessage(message.id, result, null, "2.0"));
          }
        } on ResponseError catch (error) {
          sendErrorResponse(message, error);
        } catch (error, stackTrace) {
          sendErrorResponse(
              message,
              new ResponseError(ServerErrorCodes.UnhandledError,
                  error.toString(), stackTrace?.toString()));
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

  void openTextDocument(TextDocumentItem doc) {
    final path = Uri.parse(doc.uri).toFilePath();
    // TODO(dantup): Should we be tracking the version?

    fileContentOverlay[path] = doc.text;

    driverMap.values.forEach((driver) => driver.changeFile(path));

    // If the file did not exist, and is "overlay only", it still should be
    // analyzed. Add it to driver to which it should have been added.
    contextManager.getDriverFor(path)?.addFile(path);
  }

  void sendErrorResponse(IncomingMessage message, ResponseError error) {
    if (message is RequestMessage) {
      channel.sendResponse(new ResponseMessage(message.id, null, error, "2.0"));
      // TODO(dantup): Figure out if it's necessary to send log events to make
      // errors visible at the client end, or if the normal error responses are
      // usually visible somewhere.
      channel.sendNotification(new NotificationMessage(
          'window/logMessage',
          Either2<List<dynamic>, dynamic>.t2(
              new LogMessageParams(MessageType.Error, error.message)),
          "2.0"));
    } else {
      channel.sendNotification(new NotificationMessage(
          'window/showMessage',
          Either2<List<dynamic>, dynamic>.t2(
              new ShowMessageParams(MessageType.Error, error.message)),
          "2.0"));
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

  _registerHandler(MessageHandler handler) {
    for (final message in handler.handlesMessages) {
      handlers[message] = handler;
    }
  }

  void _sendNotInitializedError(IncomingMessage message) {
    sendErrorResponse(
        message,
        new ResponseError(
            ErrorCodes.ServerNotInitialized,
            'Unable to handle ${message.method} before server is initialized',
            null));
  }

  void _sendUnknownMethodError(IncomingMessage message) {
    sendErrorResponse(
        message,
        new ResponseError(ErrorCodes.MethodNotFound,
            'Unknown method ${message.method}', null));
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
            '2.0');
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
    ContextBuilder builder = new ContextBuilder(resourceProvider,
        analysisServer.sdkManager, analysisServer.overlayState,
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

/**
 * An object that can handle messages and produce responses for requests.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MessageHandler {
  /**
   * The messages that this handler can handle.
   */
  List<String> get handlesMessages;

  T convertParams<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (_) => throw 'Expected dynamic, got List<dynamic>',
      (params) => constructor(params),
    );
  }

  List<T> convertParamsList<T>(
      IncomingMessage message, T Function(Map<String, dynamic>) constructor) {
    return message.params.map(
      (params) => params.map((p) => constructor(p)).toList(),
      (_) => throw 'Expected List<dynamic>, got dynamic',
    );
  }

  /**
   * Handle the given [message]. If the [message] is a [RequestMessage], then the
   * return value will be sent back in a [ResponseMessage].
   * [NotificationMessage]s are not expected to return results.
   */
  FutureOr<Object> handleMessage(IncomingMessage message);
}

class NullNotificationManager implements NotificationManager {
  @override
  noSuchMethod(Invocation invocation) {}
}
