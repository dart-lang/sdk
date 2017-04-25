// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io' as io;
import 'dart:math' show max;

import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide AnalysisOptions, Element;
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/computer/computer_highlights2.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/computer/new_notifications.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domains/analysis/navigation.dart';
import 'package:analysis_server/src/domains/analysis/navigation_dart.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/domains/analysis/occurrences_dart.dart';
import 'package:analysis_server/src/ide_options.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/plugin/plugin_watcher.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/services/search/search_engine_internal2.dart';
import 'package:analysis_server/src/single_context_manager.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_context.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' as nd;
import 'package:analyzer/src/dart/analysis/file_byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as nd;
import 'package:analyzer/src/dart/analysis/status.dart' as nd;
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/util/glob.dart';
import 'package:analyzer/task/dart.dart';
import 'package:plugin/plugin.dart';

typedef void OptionUpdater(AnalysisOptionsImpl options);

/**
 * Enum representing reasons why analysis might be done for a given file.
 */
class AnalysisDoneReason {
  /**
   * Analysis of the file completed successfully.
   */
  static const AnalysisDoneReason COMPLETE =
      const AnalysisDoneReason._('COMPLETE');

  /**
   * Analysis of the file was aborted because the context was removed.
   */
  static const AnalysisDoneReason CONTEXT_REMOVED =
      const AnalysisDoneReason._('CONTEXT_REMOVED');

  /**
   * Textual description of this [AnalysisDoneReason].
   */
  final String text;

  const AnalysisDoneReason._(this.text);
}

/**
 * Instances of the class [AnalysisServer] implement a server that listens on a
 * [CommunicationChannel] for analysis requests and process them.
 */
class AnalysisServer {
  /**
   * The version of the analysis server. The value should be replaced
   * automatically during the build.
   */
  static final String VERSION = '1.18.0';

  /**
   * The number of milliseconds to perform operations before inserting
   * a 1 millisecond delay so that the VM and dart:io can deliver content
   * to stdin. This should be removed once the underlying problem is fixed.
   */
  static int performOperationDelayFrequency = 25;

  /**
   * IDE options for this server instance.
   */
  IdeOptions ideOptions;

  /**
   * The options of this server instance.
   */
  AnalysisServerOptions options;

  /**
   * The channel from which requests are received and to which responses should
   * be sent.
   */
  final ServerCommunicationChannel channel;

  /**
   * The object used to manage sending a subset of notifications to the client.
   * The subset of notifications are those to which plugins may contribute.
   * This field is `null` when the new plugin support is disabled.
   */
  final NotificationManager notificationManager;

  /**
   * The object used to manage the execution of plugins.
   */
  PluginManager pluginManager;

  /**
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The [Index] for this server, may be `null` if indexing is disabled.
   */
  final Index index;

  /**
   * The [SearchEngine] for this server, may be `null` if indexing is disabled.
   */
  SearchEngine searchEngine;

  /**
   * The plugin associated with this analysis server.
   */
  final ServerPlugin serverPlugin;

  /**
   * A list of the globs used to determine which files should be analyzed. The
   * list is lazily created and should be accessed using [analyzedFilesGlobs].
   */
  List<Glob> _analyzedFilesGlobs = null;

  /**
   * The [ContextManager] that handles the mapping from analysis roots to
   * context directories.
   */
  ContextManager contextManager;

  /**
   * A flag indicating whether the server is running.  When false, contexts
   * will no longer be added to [contextWorkQueue], and [performOperation] will
   * discard any tasks it finds on [contextWorkQueue].
   */
  bool running;

  /**
   * A flag indicating the value of the 'analyzing' parameter sent in the last
   * status message to the client.
   */
  bool statusAnalyzing = false;

  /**
   * A list of the request handlers used to handle the requests sent to this
   * server.
   */
  List<RequestHandler> handlers;

  /**
   * The object used to manage the SDK's known to this server.
   */
  DartSdkManager sdkManager;

  /**
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * A queue of the operations to perform in this server.
   */
  ServerOperationQueue operationQueue;

  /**
   * True if there is a pending future which will execute [performOperation].
   */
  bool performOperationPending = false;

  /**
   * A set of the [ServerService]s to send notifications for.
   */
  Set<ServerService> serverServices = new HashSet<ServerService>();

  /**
   * A set of the [GeneralAnalysisService]s to send notifications for.
   */
  Set<GeneralAnalysisService> generalAnalysisServices =
      new HashSet<GeneralAnalysisService>();

  /**
   * A table mapping [AnalysisService]s to the file paths for which these
   * notifications should be sent.
   */
  Map<AnalysisService, Set<String>> analysisServices =
      new HashMap<AnalysisService, Set<String>>();

  /**
   * A table mapping [AnalysisContext]s to the completers that should be
   * completed when analysis of this context is finished.
   */
  Map<AnalysisContext, Completer<AnalysisDoneReason>>
      contextAnalysisDoneCompleters =
      new HashMap<AnalysisContext, Completer<AnalysisDoneReason>>();

  /**
   * Performance information before initial analysis is complete.
   */
  ServerPerformance performanceDuringStartup = new ServerPerformance();

  /**
   * Performance information after initial analysis is complete
   * or `null` if the initial analysis is not yet complete
   */
  ServerPerformance performanceAfterStartup;

  /**
   * The class into which performance information is currently being recorded.
   * During startup, this will be the same as [performanceDuringStartup]
   * and after startup is complete, this switches to [performanceAfterStartup].
   */
  ServerPerformance _performance;

  /**
   * The [Completer] that completes when analysis is complete.
   */
  Completer _onAnalysisCompleteCompleter;

  /**
   * The [Completer] that completes when the next operation is performed.
   */
  Completer _test_onOperationPerformedCompleter;

  /**
   * The controller that is notified when analysis is started.
   */
  StreamController<bool> _onAnalysisStartedController;

  /**
   * The controller that is notified when a single file has been analyzed.
   */
  StreamController<ChangeNotice> _onFileAnalyzedController;

  /**
   * The controller used to notify others when priority sources change.
   */
  StreamController<PriorityChangeEvent> _onPriorityChangeController;

  /**
   * True if any exceptions thrown by analysis should be propagated up the call
   * stack.
   */
  bool rethrowExceptions;

  /**
   * The next time (milliseconds since epoch) after which the analysis server
   * should pause so that pending requests can be fetched by the system.
   */
  // Add 1 sec to prevent delay from impacting short running tests
  int _nextPerformOperationDelayTime =
      new DateTime.now().millisecondsSinceEpoch + 1000;

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
   * The plugins that are defined outside the analysis_server package.
   */
  List<Plugin> userDefinedPlugins;

  /**
   * If the "analysis.analyzedFiles" notification is currently being subscribed
   * to (see [generalAnalysisServices]), and at least one such notification has
   * been sent since the subscription was enabled, the set of analyzed files
   * that was delivered in the most recently sent notification.  Otherwise
   * `null`.
   */
  Set<String> prevAnalyzedFiles;

  /**
   * The default options used to create new analysis contexts. This object is
   * also referenced by the ContextManager.
   */
  final AnalysisOptionsImpl defaultContextOptions = new AnalysisOptionsImpl();

  /**
   * The controller for sending [ContextsChangedEvent]s.
   */
  StreamController<ContextsChangedEvent> _onContextsChangedController =
      new StreamController<ContextsChangedEvent>.broadcast();

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

  nd.PerformanceLog _analysisPerformanceLogger;
  ByteStore byteStore;
  nd.AnalysisDriverScheduler analysisDriverScheduler;

  /**
   * This exists as a temporary stopgap for plugins, until the official plugin
   * API is complete.
   */
  StreamController<String> _onFileAddedController;

  /**
   * This exists as a temporary stopgap for plugins, until the official plugin
   * API is complete.
   */
  StreamController<String> _onFileChangedController;

  /**
   * This exists as a temporary stopgap for plugins, until the official plugin
   * API is complete.
   */
  Function onResultErrorSupplementor;

  /**
   * This exists as a temporary stopgap for plugins, until the official plugin
   * API is complete.
   */
  Function onNoAnalysisResult;

  /**
   * This exists as a temporary stopgap for plugins, until the official plugin
   * API is complete.
   */
  Function onNoAnalysisCompletion;

  /**
   * The set of the files that are currently priority.
   */
  final Set<String> priorityFiles = new Set<String>();

  /**
   * The DiagnosticServer for this AnalysisServer. If available, it can be used
   * to start an http diagnostics server or return the port for an existing
   * server.
   */
  DiagnosticServer diagnosticServer;

  /**
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   *
   * If [rethrowExceptions] is true, then any exceptions thrown by analysis are
   * propagated up the call stack.  The default is true to allow analysis
   * exceptions to show up in unit tests, but it should be set to false when
   * running a full analysis server.
   */
  AnalysisServer(
      this.channel,
      this.resourceProvider,
      PubPackageMapProvider packageMapProvider,
      this.index,
      this.serverPlugin,
      this.options,
      this.sdkManager,
      this.instrumentationService,
      {this.diagnosticServer,
      ResolverProvider fileResolverProvider: null,
      ResolverProvider packageResolverProvider: null,
      bool useSingleContextManager: false,
      this.rethrowExceptions: true})
      : notificationManager =
            new NotificationManager(channel, resourceProvider) {
    _performance = performanceDuringStartup;

    pluginManager = new PluginManager(resourceProvider, _getByteStorePath(),
        notificationManager, instrumentationService);
    PluginWatcher pluginWatcher =
        new PluginWatcher(resourceProvider, pluginManager);

    defaultContextOptions.incremental = true;
    defaultContextOptions.incrementalApi =
        options.enableIncrementalResolutionApi;
    defaultContextOptions.incrementalValidation =
        options.enableIncrementalResolutionValidation;
    defaultContextOptions.generateImplicitErrors = false;
    operationQueue = new ServerOperationQueue();

    {
      String name = options.newAnalysisDriverLog;
      StringSink sink = new NullStringSink();
      if (name != null) {
        if (name == 'stdout') {
          sink = io.stdout;
        } else if (name.startsWith('file:')) {
          String path = name.substring('file:'.length);
          sink = new io.File(path).openWrite(mode: io.FileMode.APPEND);
        }
      }
      _analysisPerformanceLogger = new nd.PerformanceLog(sink);
    }
    byteStore = _createByteStore();
    analysisDriverScheduler = new nd.AnalysisDriverScheduler(
        _analysisPerformanceLogger,
        driverWatcher: pluginWatcher);
    analysisDriverScheduler.status.listen(sendStatusNotificationNew);
    analysisDriverScheduler.start();

    if (useSingleContextManager) {
      contextManager = new SingleContextManager(resourceProvider, sdkManager,
          packageResolverProvider, analyzedFilesGlobs, defaultContextOptions);
    } else {
      contextManager = new ContextManagerImpl(
          resourceProvider,
          sdkManager,
          packageResolverProvider,
          packageMapProvider,
          analyzedFilesGlobs,
          instrumentationService,
          defaultContextOptions,
          options.enableNewAnalysisDriver);
    }
    this.fileResolverProvider = fileResolverProvider;
    this.packageResolverProvider = packageResolverProvider;
    ServerContextManagerCallbacks contextManagerCallbacks =
        new ServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;
    AnalysisEngine.instance.logger = new AnalysisLogger(this);
    _onAnalysisStartedController = new StreamController.broadcast();
    _onFileAnalyzedController = new StreamController.broadcast();
    // temporary plugin support:
    _onFileAddedController = new StreamController.broadcast();
    // temporary plugin support:
    _onFileChangedController = new StreamController.broadcast();
    _onPriorityChangeController =
        new StreamController<PriorityChangeEvent>.broadcast();
    running = true;
    onAnalysisStarted.first.then((_) {
      onAnalysisComplete.then((_) {
        performanceAfterStartup = new ServerPerformance();
        _performance = performanceAfterStartup;
      });
    });
    _setupIndexInvalidation();
    if (options.enableNewAnalysisDriver) {
      searchEngine = new SearchEngineImpl2(driverMap.values);
    } else if (index != null) {
      searchEngine = new SearchEngineImpl(index, getAstProvider);
    }
    Notification notification = new ServerConnectedParams(VERSION, io.pid,
            sessionId: instrumentationService.sessionId)
        .toNotification();
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
    handlers = serverPlugin.createDomains(this);
    ideOptions = new IdeOptions.from(options);
  }

  /**
   * Return the [AnalysisContext]s that are being used to analyze the analysis
   * roots.
   */
  Iterable<AnalysisContext> get analysisContexts =>
      contextManager.analysisContexts;

  /**
   * Return a list of the globs used to determine which files should be analyzed.
   */
  List<Glob> get analyzedFilesGlobs {
    if (_analyzedFilesGlobs == null) {
      _analyzedFilesGlobs = <Glob>[];
      List<String> patterns = serverPlugin.analyzedFilePatterns;
      for (String pattern in patterns) {
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

  /**
   * A table mapping [Folder]s to the [AnalysisDriver]s associated with them.
   */
  Map<Folder, nd.AnalysisDriver> get driverMap => contextManager.driverMap;

  /**
   * Return a table mapping [Folder]s to the [AnalysisContext]s associated with
   * them.
   */
  Map<Folder, AnalysisContext> get folderMap => contextManager.folderMap;

  /**
   * The [Future] that completes when analysis is complete.
   */
  Future get onAnalysisComplete {
    if (isAnalysisComplete()) {
      return new Future.value();
    }
    if (_onAnalysisCompleteCompleter == null) {
      _onAnalysisCompleteCompleter = new Completer();
    }
    return _onAnalysisCompleteCompleter.future;
  }

  /**
   * The stream that is notified with `true` when analysis is started.
   */
  Stream<bool> get onAnalysisStarted {
    return _onAnalysisStartedController.stream;
  }

  /**
   * The stream that is notified when contexts are added or removed.
   */
  Stream<ContextsChangedEvent> get onContextsChanged =>
      _onContextsChangedController.stream;

  /**
   * The stream that is notified when a single file has been added. This exists
   * as a temporary stopgap for plugins, until the official plugin API is
   * complete.
   */
  Stream get onFileAdded => _onFileAddedController.stream;

  /**
   * The stream that is notified when a single file has been analyzed.
   */
  Stream get onFileAnalyzed => _onFileAnalyzedController.stream;

  /**
   * The stream that is notified when a single file has been changed. This
   * exists as a temporary stopgap for plugins, until the official plugin API is
   * complete.
   */
  Stream get onFileChanged => _onFileChangedController.stream;

  /**
   * The stream that is notified when priority sources change.
   */
  Stream<PriorityChangeEvent> get onPriorityChange =>
      _onPriorityChangeController.stream;

  /**
   * The [Future] that completes when the next operation is performed.
   */
  Future get test_onOperationPerformed {
    if (_test_onOperationPerformedCompleter == null) {
      _test_onOperationPerformedCompleter = new Completer();
    }
    return _test_onOperationPerformedCompleter.future;
  }

  /**
   * Adds the given [ServerOperation] to the queue, but does not schedule
   * operations execution.
   */
  void addOperation(ServerOperation operation) {
    operationQueue.add(operation);
  }

  /**
   * The socket from which requests are being read has been closed.
   */
  void done() {
    index?.stop();
    running = false;
  }

  /**
   * There was an error related to the socket from which requests are being
   * read.
   */
  void error(argument) {
    running = false;
  }

  /**
   * If the given notice applies to a file contained within an analysis root,
   * notify interested parties that the file has been (at least partially)
   * analyzed.
   */
  void fileAnalyzed(ChangeNotice notice) {
    if (contextManager.isInAnalysisRoot(notice.source.fullName)) {
      _onFileAnalyzedController.add(notice);
    }
  }

  /**
   * Return one of the SDKs that has been created, or `null` if no SDKs have
   * been created yet.
   */
  DartSdk findSdk() {
    DartSdk sdk = sdkManager.anySdk;
    if (sdk != null) {
      return sdk;
    }
    // TODO(brianwilkerson) Should we create an SDK using the default options?
    return null;
  }

  /**
   * Return the preferred [AnalysisContext] for analyzing the given [path].
   * This will be the context that explicitly contains the path, if any such
   * context exists, otherwise it will be the first analysis context that
   * implicitly analyzes it.  Return `null` if no context is analyzing the
   * path.
   */
  AnalysisContext getAnalysisContext(String path) {
    return getContextSourcePair(path).context;
  }

  /**
   * Return any [AnalysisContext] that is analyzing the given [source], either
   * explicitly or implicitly.  Return `null` if there is no such context.
   */
  AnalysisContext getAnalysisContextForSource(Source source) {
    for (AnalysisContext context in analysisContexts) {
      SourceKind kind = context.getKindOf(source);
      if (kind != SourceKind.UNKNOWN) {
        return context;
      }
    }
    return null;
  }

  /**
   * Return an analysis driver to which the file with the given [path] is
   * added if one exists, otherwise a driver in which the file was analyzed if
   * one exists, otherwise the first driver, otherwise `null`.
   */
  nd.AnalysisDriver getAnalysisDriver(String path) {
    Iterable<nd.AnalysisDriver> drivers = driverMap.values;
    if (drivers.isNotEmpty) {
      nd.AnalysisDriver driver = drivers.firstWhere(
          (driver) => driver.addedFiles.contains(path),
          orElse: () => null);
      driver ??= drivers.firstWhere(
          (driver) => driver.knownFiles.contains(path),
          orElse: () => null);
      driver ??= drivers.first;
      return driver;
    }
    return null;
  }

  /**
   * Return the analysis result for the file with the given [path]. The file is
   * analyzed in one of the analysis drivers to which the file was added,
   * otherwise in the first driver, otherwise `null` is returned.
   */
  Future<nd.AnalysisResult> getAnalysisResult(String path) async {
    if (!AnalysisEngine.isDartFileName(path)) {
      return null;
    }

    try {
      nd.AnalysisDriver driver = getAnalysisDriver(path);
      return await driver?.getResult(path);
    } catch (e) {
      // Ignore the exception.
      // We don't want to log the same exception again and again.
      return null;
    }
  }

  /**
   * Return the [AstProvider] for the given [path].
   */
  AstProvider getAstProvider(String path) {
    if (options.enableNewAnalysisDriver) {
      var analysisDriver = getAnalysisDriver(path);
      return new AstProviderForDriver(analysisDriver);
    } else {
      var analysisContext = getAnalysisContext(path);
      return new AstProviderForContext(analysisContext);
    }
  }

  CompilationUnitElement getCompilationUnitElement(String file) {
    ContextSourcePair pair = getContextSourcePair(file);
    if (pair == null) {
      return null;
    }
    // prepare AnalysisContext and Source
    AnalysisContext context = pair.context;
    Source unitSource = pair.source;
    if (context == null || unitSource == null) {
      return null;
    }
    // get element in the first library
    List<Source> librarySources = context.getLibrariesContaining(unitSource);
    if (!librarySources.isNotEmpty) {
      return null;
    }
    Source librarySource = librarySources.first;
    return context.getCompilationUnitElement(unitSource, librarySource);
  }

  /**
   * Return the [AnalysisContext] for the "innermost" context whose associated
   * folder is or contains the given path.  ("innermost" refers to the nesting
   * of contexts, so if there is a context for path /foo and a context for
   * path /foo/bar, then the innermost context containing /foo/bar/baz.dart is
   * the context for /foo/bar.)
   *
   * If no context contains the given path, `null` is returned.
   */
  AnalysisContext getContainingContext(String path) {
    return contextManager.getContextFor(path);
  }

  /**
   * Return the [nd.AnalysisDriver] for the "innermost" context whose associated
   * folder is or contains the given path.  ("innermost" refers to the nesting
   * of contexts, so if there is a context for path /foo and a context for
   * path /foo/bar, then the innermost context containing /foo/bar/baz.dart is
   * the context for /foo/bar.)
   *
   * If no context contains the given path, `null` is returned.
   */
  nd.AnalysisDriver getContainingDriver(String path) {
    return contextManager.getDriverFor(path);
  }

  /**
   * Return the primary [ContextSourcePair] representing the given [path].
   *
   * The [AnalysisContext] of this pair will be the context that explicitly
   * contains the path, if any such context exists, otherwise it will be the
   * first context that implicitly analyzes it.
   *
   * If the [path] is not analyzed by any context, a [ContextSourcePair] with
   * a `null` context and a `file` [Source] is returned.
   *
   * If the [path] doesn't represent a file, a [ContextSourcePair] with a `null`
   * context and `null` [Source] is returned.
   *
   * Does not return `null`.
   */
  ContextSourcePair getContextSourcePair(String path) {
    // try SDK
    {
      DartSdk sdk = findSdk();
      if (sdk != null) {
        Uri uri = resourceProvider.pathContext.toUri(path);
        Source sdkSource = sdk.fromFileUri(uri);
        if (sdkSource != null) {
          return new ContextSourcePair(sdk.context, sdkSource);
        }
      }
    }
    // try to find the deep-most containing context
    Resource resource = resourceProvider.getResource(path);
    if (resource is! File) {
      return new ContextSourcePair(null, null);
    }
    File file = resource;
    {
      AnalysisContext containingContext = getContainingContext(path);
      if (containingContext != null) {
        Source source =
            ContextManagerImpl.createSourceInContext(containingContext, file);
        return new ContextSourcePair(containingContext, source);
      }
    }
    // try to find a context that analysed the file
    for (AnalysisContext context in analysisContexts) {
      Source source = ContextManagerImpl.createSourceInContext(context, file);
      SourceKind kind = context.getKindOf(source);
      if (kind != SourceKind.UNKNOWN) {
        return new ContextSourcePair(context, source);
      }
    }
    // try to find a context for which the file is a priority source
    for (InternalAnalysisContext context in analysisContexts) {
      List<Source> sources = context.getSourcesWithFullName(path);
      if (sources.isNotEmpty) {
        Source source = sources.first;
        return new ContextSourcePair(context, source);
      }
    }
    // file-based source
    Source fileSource = file.createSource();
    return new ContextSourcePair(null, fileSource);
  }

  /**
   * Return a [Future] that completes with the [Element] at the given
   * [offset] of the given [file], or with `null` if there is no node at the
   * [offset] or the node does not have an element.
   */
  Future<Element> getElementAtOffset(String file, int offset) async {
    AstNode node = await getNodeAtOffset(file, offset);
    return getElementOfNode(node);
  }

  /**
   * Return the [Element] of the given [node], or `null` if [node] is `null` or
   * does not have an element.
   */
  Element getElementOfNode(AstNode node) {
    if (node == null) {
      return null;
    }
    if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is LibraryIdentifier) {
      node = node.parent;
    }
    if (node is StringLiteral && node.parent is UriBasedDirective) {
      return null;
    }
    Element element = ElementLocator.locate(node);
    if (node is SimpleIdentifier && element is PrefixElement) {
      element = getImportElement(node);
    }
    return element;
  }

  /**
   * Return an analysis error info containing the array of all of the errors and
   * the line info associated with [file].
   *
   * Returns `null` if [file] does not belong to any [AnalysisContext], or the
   * file does not exist.
   *
   * The array of errors will be empty if there are no errors in [file]. The
   * errors contained in the array can be incomplete.
   *
   * This method does not wait for all errors to be computed, and returns just
   * the current state.
   */
  AnalysisErrorInfo getErrors(String file) {
    ContextSourcePair contextSource = getContextSourcePair(file);
    AnalysisContext context = contextSource.context;
    Source source = contextSource.source;
    if (context == null) {
      return null;
    }
    if (!context.exists(source)) {
      return null;
    }
    return context.getErrors(source);
  }

  /**
   * Return a [Future] that completes with the resolved [AstNode] at the
   * given [offset] of the given [file], or with `null` if there is no node as
   * the [offset].
   */
  Future<AstNode> getNodeAtOffset(String file, int offset) async {
    CompilationUnit unit;
    if (options.enableNewAnalysisDriver) {
      nd.AnalysisResult result = await getAnalysisResult(file);
      unit = result?.unit;
    } else {
      unit = await getResolvedCompilationUnit(file);
    }
    if (unit != null) {
      return new NodeLocator(offset).searchWithin(unit);
    }
    return null;
  }

  /**
   * Return a [Future] that completes with the resolved [CompilationUnit] for
   * the Dart file with the given [path], or with `null` if the file is not a
   * Dart file or cannot be resolved.
   */
  Future<CompilationUnit> getResolvedCompilationUnit(String path) async {
    if (options.enableNewAnalysisDriver) {
      nd.AnalysisResult result = await getAnalysisResult(path);
      return result?.unit;
    }
    ContextSourcePair contextSource = getContextSourcePair(path);
    AnalysisContext context = contextSource.context;
    if (context == null) {
      return null;
    }
    return runWithActiveContext(context, () {
      Source unitSource = contextSource.source;
      List<Source> librarySources = context.getLibrariesContaining(unitSource);
      for (Source librarySource in librarySources) {
        return context.resolveCompilationUnit2(unitSource, librarySource);
      }
      return null;
    });
  }

// TODO(brianwilkerson) Add the following method after 'prioritySources' has
// been added to InternalAnalysisContext.
//  /**
//   * Return a list containing the full names of all of the sources that are
//   * priority sources.
//   */
//  List<String> getPriorityFiles() {
//    List<String> priorityFiles = new List<String>();
//    folderMap.values.forEach((ContextDirectory directory) {
//      InternalAnalysisContext context = directory.context;
//      context.prioritySources.forEach((Source source) {
//        priorityFiles.add(source.fullName);
//      });
//    });
//    return priorityFiles;
//  }

  /**
   * Handle a [request] that was read from the communication channel.
   */
  void handleRequest(Request request) {
    _performance.logRequest(request);
    runZoned(() {
      ServerPerformanceStatistics.serverRequests.makeCurrentWhile(() {
        int count = handlers.length;
        for (int i = 0; i < count; i++) {
          try {
            Response response = handlers[i].handleRequest(request);
            if (response == Response.DELAYED_RESPONSE) {
              return;
            }
            if (response != null) {
              channel.sendResponse(response);
              return;
            }
          } on RequestFailure catch (exception) {
            channel.sendResponse(exception.response);
            return;
          } catch (exception, stackTrace) {
            RequestError error = new RequestError(
                RequestErrorCode.SERVER_ERROR, exception.toString());
            if (stackTrace != null) {
              error.stackTrace = stackTrace.toString();
            }
            Response response = new Response(request.id, error: error);
            channel.sendResponse(response);
            return;
          }
        }
        channel.sendResponse(new Response.unknownRequest(request));
      });
    }, onError: (exception, stackTrace) {
      sendServerErrorNotification(
          'Failed to handle request: ${request.toJson()}',
          exception,
          stackTrace,
          fatal: true);
    });
  }

  /**
   * Returns `true` if there is a subscription for the given [service] and
   * [file].
   */
  bool hasAnalysisSubscription(AnalysisService service, String file) {
    Set<String> files = analysisServices[service];
    return files != null && files.contains(file);
  }

  /**
   * Return `true` if analysis is complete.
   */
  bool isAnalysisComplete() {
    return operationQueue.isEmpty && !analysisDriverScheduler.isAnalyzing;
  }

  /**
   * Return `true` if the given path is a valid `FilePath`.
   *
   * This means that it is absolute and normalized.
   */
  bool isValidFilePath(String path) {
    return resourceProvider.absolutePathContext.isValid(path);
  }

  /**
   * Returns a [Future] completing when [file] has been completely analyzed, in
   * particular, all its errors have been computed.  The future is completed
   * with an [AnalysisDoneReason] indicating what caused the file's analysis to
   * be considered complete.
   *
   * If the given file doesn't belong to any context, null is returned.
   *
   * TODO(scheglov) this method should be improved.
   *
   * 1. The analysis context should be told to analyze this particular file ASAP.
   *
   * 2. We should complete the future as soon as the file is analyzed (not wait
   *    until the context is completely finished)
   */
  Future<AnalysisDoneReason> onFileAnalysisComplete(String file) {
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(file);
    if (context == null) {
      return null;
    }
    // done if everything is already analyzed
    if (isAnalysisComplete()) {
      return new Future.value(AnalysisDoneReason.COMPLETE);
    }
    // schedule context analysis
    schedulePerformAnalysisOperation(context);
    // associate with the context completer
    Completer<AnalysisDoneReason> completer =
        contextAnalysisDoneCompleters[context];
    if (completer == null) {
      completer = new Completer<AnalysisDoneReason>();
      contextAnalysisDoneCompleters[context] = completer;
    }
    return completer.future;
  }

  /**
   * Perform the next available [ServerOperation].
   */
  void performOperation() {
    assert(performOperationPending);
    PerformanceTag.UNKNOWN.makeCurrent();
    performOperationPending = false;
    if (!running) {
      // An error has occurred, or the connection to the client has been
      // closed, since this method was scheduled on the event queue.  So
      // don't do anything.  Instead clear the operation queue.
      operationQueue.clear();
      return;
    }
    // prepare next operation
    ServerOperation operation = operationQueue.take();
    if (operation == null) {
      // This can happen if the operation queue is cleared while the operation
      // loop is in progress.  No problem; we just need to exit the operation
      // loop and wait for the next operation to be added.
      ServerPerformanceStatistics.idle.makeCurrent();
      return;
    }
    sendStatusNotification(operation);
    // perform the operation
    try {
      operation.perform(this);
    } catch (exception, stackTrace) {
      sendServerErrorNotification(
          'Failed to perform operation: $operation', exception, stackTrace,
          fatal: true);
      if (rethrowExceptions) {
        throw new AnalysisException('Unexpected exception during analysis',
            new CaughtException(exception, stackTrace));
      }
      shutdown();
    } finally {
      if (_test_onOperationPerformedCompleter != null) {
        _test_onOperationPerformedCompleter.complete(operation);
        _test_onOperationPerformedCompleter = null;
      }
      if (!operationQueue.isEmpty) {
        ServerPerformanceStatistics.intertask.makeCurrent();
        _schedulePerformOperation();
      } else {
        if (generalAnalysisServices
            .contains(GeneralAnalysisService.ANALYZED_FILES)) {
          sendAnalysisNotificationAnalyzedFiles(this);
        }
        sendStatusNotification(null);
        _scheduleAnalysisImplementedNotification();
        if (_onAnalysisCompleteCompleter != null) {
          _onAnalysisCompleteCompleter.complete();
          _onAnalysisCompleteCompleter = null;
        }
        ServerPerformanceStatistics.idle.makeCurrent();
      }
    }
  }

  /**
   * Trigger reanalysis of all files in the given list of analysis [roots], or
   * everything if the analysis roots is `null`.
   */
  void reanalyze(List<Resource> roots) {
    // Clear any operations that are pending.
    if (roots == null) {
      operationQueue.clear();
    } else {
      for (AnalysisContext context in _getContexts(roots)) {
        operationQueue.contextRemoved(context);
      }
    }
    // Instruct the contextDirectoryManager to rebuild all contexts from
    // scratch.
    contextManager.refresh(roots);
  }

  /**
   * Schedule cache consistency validation in [context].
   * The most of the validation must be done asynchronously.
   */
  void scheduleCacheConsistencyValidation(AnalysisContext context) {
    if (context is InternalAnalysisContext) {
      CacheConsistencyValidator validator = context.cacheConsistencyValidator;
      List<Source> sources = validator.getSourcesToComputeModificationTimes();
      // Compute modification times and notify the validator asynchronously.
      new Future(() async {
        try {
          List<int> modificationTimes =
              await resourceProvider.getModificationTimes(sources);
          bool cacheInconsistencyFixed = validator
              .sourceModificationTimesComputed(sources, modificationTimes);
          if (cacheInconsistencyFixed) {
            scheduleOperation(new PerformAnalysisOperation(context, false));
          }
        } catch (exception, stackTrace) {
          sendServerErrorNotification(
              'Failed to check cache consistency', exception, stackTrace);
        }
      });
    }
  }

  /**
   * Schedules execution of the given [ServerOperation].
   */
  void scheduleOperation(ServerOperation operation) {
    addOperation(operation);
    _schedulePerformOperation();
  }

  /**
   * Schedules analysis of the given context.
   */
  void schedulePerformAnalysisOperation(AnalysisContext context) {
    _onAnalysisStartedController.add(true);
    scheduleOperation(new PerformAnalysisOperation(context, false));
  }

  /**
   * This method is called when analysis of the given [AnalysisContext] is
   * done.
   */
  void sendContextAnalysisDoneNotifications(
      AnalysisContext context, AnalysisDoneReason reason) {
    Completer<AnalysisDoneReason> completer =
        contextAnalysisDoneCompleters.remove(context);
    if (completer != null) {
      completer.complete(reason);
    }
  }

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification) {
    channel.sendNotification(notification);
  }

  /**
   * Send the given [response] to the client.
   */
  void sendResponse(Response response) {
    channel.sendResponse(response);
  }

  /**
   * Sends a `server.error` notification.
   */
  void sendServerErrorNotification(String message, exception, stackTrace,
      {bool fatal: false}) {
    StringBuffer buffer = new StringBuffer();
    if (exception != null) {
      buffer.write(exception);
    } else {
      buffer.write('null exception');
    }
    if (stackTrace != null) {
      buffer.writeln();
      buffer.write(stackTrace);
    } else if (exception is! CaughtException) {
      try {
        throw 'ignored';
      } catch (ignored, stackTrace) {
        buffer.writeln();
        buffer.write(stackTrace);
      }
    }
    // send the notification
    channel.sendNotification(
        new ServerErrorParams(fatal, message, buffer.toString())
            .toNotification());
  }

  /**
   * Send status notification to the client. The `operation` is the operation
   * being performed or `null` if analysis is complete.
   */
  void sendStatusNotification(ServerOperation operation) {
    // Only send status when subscribed.
    if (!serverServices.contains(ServerService.STATUS)) {
      return;
    }
    // Only send status when it changes
    bool isAnalyzing = operation != null;
    if (statusAnalyzing == isAnalyzing) {
      return;
    }
    statusAnalyzing = isAnalyzing;
    AnalysisStatus analysis = new AnalysisStatus(isAnalyzing);
    channel.sendNotification(
        new ServerStatusParams(analysis: analysis).toNotification());
  }

  /**
   * Send status notification to the client. The state of analysis is given by
   * the [status] information.
   */
  void sendStatusNotificationNew(nd.AnalysisStatus status) {
    if (status.isAnalyzing) {
      _onAnalysisStartedController.add(true);
    }
    if (_onAnalysisCompleteCompleter != null && !status.isAnalyzing) {
      _onAnalysisCompleteCompleter.complete();
      _onAnalysisCompleteCompleter = null;
    }
    // Perform on-idle actions.
    if (!status.isAnalyzing) {
      if (generalAnalysisServices
          .contains(GeneralAnalysisService.ANALYZED_FILES)) {
        sendAnalysisNotificationAnalyzedFiles(this);
      }
    }
    // Only send status when subscribed.
    if (!serverServices.contains(ServerService.STATUS)) {
      return;
    }
    // Only send status when it changes
    if (statusAnalyzing == status.isAnalyzing) {
      return;
    }
    statusAnalyzing = status.isAnalyzing;
    AnalysisStatus analysis = new AnalysisStatus(status.isAnalyzing);
    channel.sendNotification(
        new ServerStatusParams(analysis: analysis).toNotification());
  }

  /**
   * Implementation for `analysis.setAnalysisRoots`.
   *
   * TODO(scheglov) implement complete projects/contexts semantics.
   *
   * The current implementation is intentionally simplified and expected
   * that only folders are given each given folder corresponds to the exactly
   * one context.
   *
   * So, we can start working in parallel on adding services and improving
   * projects/contexts support.
   */
  void setAnalysisRoots(String requestId, List<String> includedPaths,
      List<String> excludedPaths, Map<String, String> packageRoots) {
    if (notificationManager != null) {
      notificationManager.setAnalysisRoots(includedPaths, excludedPaths);
    }
    try {
      contextManager.setRoots(includedPaths, excludedPaths, packageRoots);
    } on UnimplementedError catch (e) {
      throw new RequestFailure(
          new Response.unsupportedFeature(requestId, e.message));
    }
  }

  /**
   * Implementation for `analysis.setSubscriptions`.
   */
  void setAnalysisSubscriptions(
      Map<AnalysisService, Set<String>> subscriptions) {
    if (notificationManager != null) {
      notificationManager.setSubscriptions(subscriptions);
    }
    if (options.enableNewAnalysisDriver) {
      this.analysisServices = subscriptions;
      Set<String> allNewFiles =
          subscriptions.values.expand((files) => files).toSet();
      for (String file in allNewFiles) {
        // The result will be produced by the "results" stream with
        // the fully resolved unit, and processed with sending analysis
        // notifications as it happens after content changes.
        if (AnalysisEngine.isDartFileName(file)) {
          getAnalysisResult(file);
        }
      }
      return;
    }
    // send notifications for already analyzed sources
    subscriptions.forEach((service, Set<String> newFiles) {
      Set<String> oldFiles = analysisServices[service];
      Set<String> todoFiles =
          oldFiles != null ? newFiles.difference(oldFiles) : newFiles;
      for (String file in todoFiles) {
        if (contextManager.isIgnored(file)) {
          continue;
        }
        // prepare context
        ContextSourcePair contextSource = getContextSourcePair(file);
        AnalysisContext context = contextSource.context;
        if (context == null) {
          continue;
        }
        Source source = contextSource.source;
        // Ensure that if the AST is flushed / not ready, it will be
        // computed eventually.
        if (AnalysisEngine.isDartFileName(file)) {
          (context as InternalAnalysisContext).ensureResolvedDartUnits(source);
        }
        // Send notifications that don't directly take an AST.
        switch (service) {
          case AnalysisService.NAVIGATION:
            sendAnalysisNotificationNavigation(this, context, source);
            continue;
          case AnalysisService.OCCURRENCES:
            sendAnalysisNotificationOccurrences(this, context, source);
            continue;
        }
        // Dart unit notifications.
        if (AnalysisEngine.isDartFileName(file)) {
          // TODO(scheglov) This way to get resolved information is very Dart
          // specific. OTOH as it is planned now Angular results are not
          // flushable.
          CompilationUnit dartUnit =
              _getResolvedCompilationUnitToResendNotification(context, source);
          if (dartUnit != null) {
            switch (service) {
              case AnalysisService.HIGHLIGHTS:
                sendAnalysisNotificationHighlights(this, file, dartUnit);
                break;
              case AnalysisService.OUTLINE:
                AnalysisContext context = resolutionMap
                    .elementDeclaredByCompilationUnit(dartUnit)
                    .context;
                LineInfo lineInfo = context.getLineInfo(source);
                SourceKind kind = context.getKindOf(source);
                sendAnalysisNotificationOutline(
                    this, file, lineInfo, kind, dartUnit);
                break;
              case AnalysisService.OVERRIDES:
                sendAnalysisNotificationOverrides(this, file, dartUnit);
                break;
            }
          }
        }
      }
    });
    // remember new subscriptions
    this.analysisServices = subscriptions;
    // special case for implemented elements
    if (analysisServices.containsKey(AnalysisService.IMPLEMENTED) &&
        isAnalysisComplete()) {
      _scheduleAnalysisImplementedNotification();
    }
  }

  /**
   * Implementation for `analysis.setGeneralSubscriptions`.
   */
  void setGeneralAnalysisSubscriptions(
      List<GeneralAnalysisService> subscriptions) {
    Set<GeneralAnalysisService> newServices = subscriptions.toSet();
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

  /**
   * Set the priority files to the given [files].
   */
  void setPriorityFiles(String requestId, List<String> files) {
    if (options.enableNewAnalysisDriver) {
      priorityFiles.clear();
      priorityFiles.addAll(files);
      // Set priority files in drivers.
      driverMap.values.forEach((driver) {
        driver.priorityFiles = files;
      });
      return;
    }
    // Note: when a file is a priority file, that information needs to be
    // propagated to all contexts that analyze the file, so that all contexts
    // will be able to do incremental resolution of the file.  See
    // dartbug.com/22209.
    Map<AnalysisContext, List<Source>> sourceMap =
        new HashMap<AnalysisContext, List<Source>>();
    List<String> unanalyzed = new List<String>();
    Source firstSource = null;
    files.forEach((String file) {
      if (contextManager.isIgnored(file)) {
        unanalyzed.add(file);
        return;
      }
      // Prepare the context/source pair.
      ContextSourcePair contextSource = getContextSourcePair(file);
      AnalysisContext preferredContext = contextSource.context;
      Source source = contextSource.source;
      // Try to make the file analyzable.
      // If it is not in any context yet, add it to the first one which
      // could use it, e.g. imports its package, even if not the library.
      if (preferredContext == null) {
        Resource resource = resourceProvider.getResource(file);
        if (resource is File && resource.exists) {
          for (AnalysisContext context in analysisContexts) {
            Uri uri = context.sourceFactory.restoreUri(source);
            if (uri.scheme != 'file') {
              preferredContext = context;
              source =
                  ContextManagerImpl.createSourceInContext(context, resource);
              break;
            }
          }
        }
      }
      // Fill the source map.
      bool contextFound = false;
      if (preferredContext != null) {
        sourceMap.putIfAbsent(preferredContext, () => <Source>[]).add(source);
        contextFound = true;
      }
      for (AnalysisContext context in analysisContexts) {
        if (context != preferredContext &&
            context.getKindOf(source) != SourceKind.UNKNOWN) {
          sourceMap.putIfAbsent(context, () => <Source>[]).add(source);
          contextFound = true;
        }
      }
      if (firstSource == null) {
        firstSource = source;
      }
      if (!contextFound) {
        unanalyzed.add(file);
      }
    });
    if (unanalyzed.isNotEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.writeAll(unanalyzed, ', ');
      throw new RequestFailure(
          new Response.unanalyzedPriorityFiles(requestId, buffer.toString()));
    }
    sourceMap.forEach((context, List<Source> sourceList) {
      context.analysisPriorityOrder = sourceList;
      // Schedule the context for analysis so that it has the opportunity to
      // cache the AST's for the priority sources as soon as possible.
      schedulePerformAnalysisOperation(context);
    });
    operationQueue.reschedule();
    _onPriorityChangeController.add(new PriorityChangeEvent(firstSource));
  }

  /**
   * Returns `true` if errors should be reported for [file] with the given
   * absolute path.
   */
  bool shouldSendErrorsNotificationFor(String file) {
    return contextManager.isInAnalysisRoot(file);
  }

  void shutdown() {
    running = false;
    if (index != null) {
      index.stop();
    }
    // Defer closing the channel and shutting down the instrumentation server so
    // that the shutdown response can be sent and logged.
    new Future(() {
      instrumentationService.shutdown();
      channel.close();
    });
  }

  void test_flushAstStructures(String file) {
    if (AnalysisEngine.isDartFileName(file)) {
      ContextSourcePair contextSource = getContextSourcePair(file);
      InternalAnalysisContext context = contextSource.context;
      Source source = contextSource.source;
      context.test_flushAstStructures(source);
    }
  }

  /**
   * Performs all scheduled analysis operations.
   */
  void test_performAllAnalysisOperations() {
    while (true) {
      ServerOperation operation = operationQueue.takeIf((operation) {
        return operation is PerformAnalysisOperation;
      });
      if (operation == null) {
        break;
      }
      operation.perform(this);
    }
  }

  /**
   * Implementation for `analysis.updateContent`.
   */
  void updateContent(String id, Map<String, dynamic> changes) {
    if (options.enableNewAnalysisDriver) {
      changes.forEach((file, change) {
        // Prepare the new contents.
        String oldContents = fileContentOverlay[file];
        String newContents;
        if (change is AddContentOverlay) {
          newContents = change.content;
        } else if (change is ChangeContentOverlay) {
          if (oldContents == null) {
            // The client may only send a ChangeContentOverlay if there is
            // already an existing overlay for the source.
            throw new RequestFailure(new Response(id,
                error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                    'Invalid overlay change')));
          }
          try {
            newContents = SourceEdit.applySequence(oldContents, change.edits);
          } on RangeError {
            throw new RequestFailure(new Response(id,
                error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                    'Invalid overlay change')));
          }
        } else if (change is RemoveContentOverlay) {
          newContents = null;
        } else {
          // Protocol parsing should have ensured that we never get here.
          throw new AnalysisException('Illegal change type');
        }

        fileContentOverlay[file] = newContents;

        driverMap.values.forEach((driver) {
          driver.changeFile(file);
        });

        // temporary plugin support:
        _onFileChangedController.add(file);

        // If the file did not exist, and is "overlay only", it still should be
        // analyzed. Add it to driver to which it should have been added.
        contextManager.getDriverFor(file)?.addFile(file);

        // TODO(scheglov) implement other cases
      });
      return;
    }
    changes.forEach((file, change) {
      ContextSourcePair contextSource = getContextSourcePair(file);
      Source source = contextSource.source;
      operationQueue.sourceAboutToChange(source);
      // Prepare the new contents.
      String oldContents = overlayState.getContents(source);
      String newContents;
      if (change is AddContentOverlay) {
        newContents = change.content;
      } else if (change is ChangeContentOverlay) {
        if (oldContents == null) {
          // The client may only send a ChangeContentOverlay if there is
          // already an existing overlay for the source.
          throw new RequestFailure(new Response(id,
              error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
        try {
          newContents = SourceEdit.applySequence(oldContents, change.edits);
        } on RangeError {
          throw new RequestFailure(new Response(id,
              error: new RequestError(RequestErrorCode.INVALID_OVERLAY_CHANGE,
                  'Invalid overlay change')));
        }
      } else if (change is RemoveContentOverlay) {
        newContents = null;
      } else {
        // Protocol parsing should have ensured that we never get here.
        throw new AnalysisException('Illegal change type');
      }

      AnalysisContext containingContext = getContainingContext(file);

      // Check for an implicitly added but missing source.
      // (For example, the target of an import might not exist yet.)
      // We need to do this before setContents, which changes the stamp.
      bool wasMissing = containingContext?.getModificationStamp(source) == -1;

      overlayState.setContents(source, newContents);
      // If the source does not exist, then it was an overlay-only one.
      // Remove it from contexts.
      if (newContents == null && !source.exists()) {
        for (InternalAnalysisContext context in analysisContexts) {
          List<Source> sources = context.getSourcesWithFullName(file);
          ChangeSet changeSet = new ChangeSet();
          sources.forEach(changeSet.removedSource);
          context.applyChanges(changeSet);
          schedulePerformAnalysisOperation(context);
        }
        return;
      }
      // Update all contexts.
      bool anyContextUpdated = false;
      for (InternalAnalysisContext context in analysisContexts) {
        List<Source> sources = context.getSourcesWithFullName(file);
        sources.forEach((Source source) {
          anyContextUpdated = true;
          if (context == containingContext && wasMissing) {
            // Promote missing source to an explicitly added Source.
            context.applyChanges(new ChangeSet()..addedSource(source));
            schedulePerformAnalysisOperation(context);
          }
          if (context.handleContentsChanged(
              source, oldContents, newContents, true)) {
            schedulePerformAnalysisOperation(context);
          } else {
            // When the client sends any change for a source, we should resend
            // subscribed notifications, even if there were no changes in the
            // source contents.
            // TODO(scheglov) consider checking if there are subscriptions.
            if (AnalysisEngine.isDartFileName(file)) {
              List<CompilationUnit> dartUnits =
                  context.ensureResolvedDartUnits(source);
              if (dartUnits != null) {
                AnalysisErrorInfo errorInfo = context.getErrors(source);
                for (var dartUnit in dartUnits) {
                  scheduleNotificationOperations(
                      this,
                      source,
                      file,
                      errorInfo.lineInfo,
                      context,
                      null,
                      dartUnit,
                      errorInfo.errors);
                  scheduleIndexOperation(this, file, dartUnit);
                }
              } else {
                schedulePerformAnalysisOperation(context);
              }
            }
          }
        });
      }
      // The source is not analyzed by any context, add to the containing one.
      if (!anyContextUpdated) {
        AnalysisContext context = contextSource.context;
        if (context != null && source != null) {
          ChangeSet changeSet = new ChangeSet();
          changeSet.addedSource(source);
          context.applyChanges(changeSet);
          schedulePerformAnalysisOperation(context);
        }
      }
    });
  }

  /**
   * Use the given updaters to update the values of the options in every
   * existing analysis context.
   */
  void updateOptions(List<OptionUpdater> optionUpdaters) {
    if (options.enableNewAnalysisDriver) {
      // TODO(scheglov) implement for the new analysis driver
      return;
    }
    //
    // Update existing contexts.
    //
    for (AnalysisContext context in analysisContexts) {
      AnalysisOptionsImpl options =
          new AnalysisOptionsImpl.from(context.analysisOptions);
      optionUpdaters.forEach((OptionUpdater optionUpdater) {
        optionUpdater(options);
      });
      context.analysisOptions = options;
      // TODO(brianwilkerson) As far as I can tell, this doesn't cause analysis
      // to be scheduled for this context.
    }
    //
    // Update the defaults used to create new contexts.
    //
    optionUpdaters.forEach((OptionUpdater optionUpdater) {
      optionUpdater(defaultContextOptions);
    });
  }

  void _computingPackageMap(bool computing) {
    if (serverServices.contains(ServerService.STATUS)) {
      PubStatus pubStatus = new PubStatus(computing);
      ServerStatusParams params = new ServerStatusParams(pub: pubStatus);
      sendNotification(params.toNotification());
    }
  }

  /**
   * If the state location can be accessed, return the file byte store,
   * otherwise return the memory byte store.
   */
  ByteStore _createByteStore() {
    const int M = 1024 * 1024 /*1 MiB*/;
    const int G = 1024 * 1024 * 1024 /*1 GiB*/;
    if (resourceProvider is PhysicalResourceProvider) {
      Folder stateLocation =
          resourceProvider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        return new MemoryCachingByteStore(
            new EvictingFileByteStore(stateLocation.path, G), 64 * M);
      }
    }
    return new MemoryCachingByteStore(new NullByteStore(), 64 * M);
  }

  /**
   * Return the path to the location of the byte store on disk, or `null` if
   * there is no on-disk byte store.
   */
  String _getByteStorePath() {
    if (resourceProvider is PhysicalResourceProvider) {
      Folder stateLocation =
          resourceProvider.getStateLocation('.analysis-driver');
      if (stateLocation != null) {
        return stateLocation.path;
      }
    }
    return null;
  }

  /**
   * Return a set of all contexts whose associated folder is contained within,
   * or equal to, one of the resources in the given list of [resources].
   */
  Set<AnalysisContext> _getContexts(List<Resource> resources) {
    Set<AnalysisContext> contexts = new HashSet<AnalysisContext>();
    resources.forEach((Resource resource) {
      if (resource is Folder) {
        contexts.addAll(contextManager.contextsInAnalysisRoot(resource));
      }
    });
    return contexts;
  }

  /**
   * Returns the [CompilationUnit] of the Dart file with the given [source] that
   * should be used to resend notifications for already resolved unit.
   * Returns `null` if the file is not a part of any context, library has not
   * been yet resolved, or any problem happened.
   */
  CompilationUnit _getResolvedCompilationUnitToResendNotification(
      AnalysisContext context, Source source) {
    List<Source> librarySources = context.getLibrariesContaining(source);
    if (librarySources.isEmpty) {
      return null;
    }
    // if library has not been resolved yet, the unit will be resolved later
    Source librarySource = librarySources[0];
    if (context.getResult(librarySource, LIBRARY_ELEMENT6) == null) {
      return null;
    }
    // if library has been already resolved, resolve unit
    return runWithActiveContext(context, () {
      return context.resolveCompilationUnit2(source, librarySource);
    });
  }

  bool _hasAnalysisServiceSubscription(AnalysisService service, String file) {
    return analysisServices[service]?.contains(file) ?? false;
  }

  _scheduleAnalysisImplementedNotification() async {
    Set<String> files = analysisServices[AnalysisService.IMPLEMENTED];
    if (files != null) {
      scheduleImplementedNotification(this, files);
    }
  }

  /**
   * Schedules [performOperation] execution.
   */
  void _schedulePerformOperation() {
    if (performOperationPending) {
      return;
    }
    /*
     * TODO (danrubel) Rip out this workaround once the underlying problem
     * is fixed. Currently, the VM and dart:io do not deliver content
     * on stdin in a timely manner if the event loop is busy.
     * To work around this problem, we delay for 1 millisecond
     * every 25 milliseconds.
     *
     * To disable this workaround and see the underlying problem,
     * set performOperationDelayFrequency to zero
     */
    int now = new DateTime.now().millisecondsSinceEpoch;
    if (now > _nextPerformOperationDelayTime &&
        performOperationDelayFrequency > 0) {
      _nextPerformOperationDelayTime = now + performOperationDelayFrequency;
      new Future.delayed(new Duration(milliseconds: 1), performOperation);
    } else {
      new Future(performOperation);
    }
    performOperationPending = true;
  }

  /**
   * Listen for context events and invalidate index.
   *
   * It is possible that this method will do more in the future, e.g. listening
   * for summary information and linking pre-indexed packages into the index,
   * but for now we only invalidate project specific index information.
   */
  void _setupIndexInvalidation() {
    if (index == null) {
      return;
    }
    onContextsChanged.listen((ContextsChangedEvent event) {
      for (AnalysisContext context in event.added) {
        context
            .onResultChanged(RESOLVED_UNIT3)
            .listen((ResultChangedEvent event) {
          if (event.wasComputed) {
            Object value = event.value;
            if (value is CompilationUnit) {
              index.indexDeclarations(value);
            }
          }
        });
        context
            .onResultChanged(RESOLVED_UNIT)
            .listen((ResultChangedEvent event) {
          if (event.wasInvalidated) {
            LibrarySpecificUnit target = event.target;
            index.removeUnit(event.context, target.library, target.unit);
          }
        });
      }
      for (AnalysisContext context in event.removed) {
        index.removeContext(context);
      }
    });
  }
}

class AnalysisServerOptions {
  bool enableIncrementalResolutionApi = false;
  bool enableIncrementalResolutionValidation = false;
  bool enableNewAnalysisDriver = false;
  bool noIndex = false;
  bool useAnalysisHighlight2 = false;
  String fileReadMode = 'as-is';
  String newAnalysisDriverLog;
  // IDE options
  bool enableVerboseFlutterCompletions = false;
}

/**
 * Information about a file - an [AnalysisContext] that analyses the file,
 * and the [Source] representing the file in this context.
 */
class ContextSourcePair {
  /**
   * A context that analysis the file.
   * May be `null` if the file is not analyzed by any context.
   */
  final AnalysisContext context;

  /**
   * The source that corresponds to the file.
   * May be `null` if the file is not a regular file.
   * If the file cannot be found in the [context], then it has a `file` uri.
   */
  final Source source;

  ContextSourcePair(this.context, this.source);
}

/**
 * A [PriorityChangeEvent] indicates the set the priority files has changed.
 */
class PriorityChangeEvent {
  final Source firstSource;

  PriorityChangeEvent(this.firstSource);
}

class ServerContextManagerCallbacks extends ContextManagerCallbacks {
  final AnalysisServer analysisServer;

  /**
   * The [ResourceProvider] by which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  ServerContextManagerCallbacks(this.analysisServer, this.resourceProvider);

  @override
  nd.AnalysisDriver addAnalysisDriver(
      Folder folder, ContextRoot contextRoot, AnalysisOptions options) {
    ContextBuilder builder = createContextBuilder(folder, options);
    nd.AnalysisDriver analysisDriver = builder.buildDriver(contextRoot);
    analysisDriver.results.listen((result) {
      NotificationManager notificationManager =
          analysisServer.notificationManager;
      String path = result.path;
      if (analysisServer.shouldSendErrorsNotificationFor(path)) {
        if (notificationManager != null) {
          notificationManager.recordAnalysisErrors(
              NotificationManager.serverId,
              path,
              server.doAnalysisError_listFromEngine(
                  result.driver.analysisOptions,
                  result.lineInfo,
                  result.errors));
        } else {
          new_sendErrorNotification(analysisServer, result);
        }
      }
      CompilationUnit unit = result.unit;
      if (unit != null) {
        if (notificationManager != null) {
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.HIGHLIGHTS, path)) {
            _runDelayed(() {
              notificationManager.recordHighlightRegions(
                  NotificationManager.serverId,
                  path,
                  _computeHighlightRegions(unit));
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.NAVIGATION, path)) {
            _runDelayed(() {
              notificationManager.recordNavigationParams(
                  NotificationManager.serverId,
                  path,
                  _computeNavigationParams(path, unit));
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.OCCURRENCES, path)) {
            _runDelayed(() {
              notificationManager.recordOccurrences(
                  NotificationManager.serverId,
                  path,
                  _computeOccurrences(unit));
            });
          }
//          if (analysisServer._hasAnalysisServiceSubscription(
//              AnalysisService.OUTLINE, path)) {
//            _runDelayed(() {
//              // TODO(brianwilkerson) Change NotificationManager to store params
//              // so that fileKind and libraryName can be recorded / passed along.
//              notificationManager.recordOutlines(NotificationManager.serverId,
//                  path, _computeOutlineParams(path, unit, result.lineInfo));
//            });
//          }
        } else {
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.HIGHLIGHTS, path)) {
            _runDelayed(() {
              sendAnalysisNotificationHighlights(analysisServer, path, unit);
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.NAVIGATION, path)) {
            _runDelayed(() {
              new_sendDartNotificationNavigation(analysisServer, result);
            });
          }
          if (analysisServer._hasAnalysisServiceSubscription(
              AnalysisService.OCCURRENCES, path)) {
            _runDelayed(() {
              new_sendDartNotificationOccurrences(analysisServer, result);
            });
          }
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.OUTLINE, path)) {
          _runDelayed(() {
            SourceKind sourceKind =
                unit.directives.any((d) => d is PartOfDirective)
                    ? SourceKind.PART
                    : SourceKind.LIBRARY;
            sendAnalysisNotificationOutline(
                analysisServer, path, result.lineInfo, sourceKind, unit);
          });
        }
        if (analysisServer._hasAnalysisServiceSubscription(
            AnalysisService.OVERRIDES, path)) {
          _runDelayed(() {
            sendAnalysisNotificationOverrides(analysisServer, path, unit);
          });
        }
        // TODO(scheglov) Implement notifications for AnalysisService.IMPLEMENTED.
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
  AnalysisContext addContext(Folder folder, AnalysisOptions options) {
    ContextBuilder builder = createContextBuilder(folder, options);
    AnalysisContext context = builder.buildContext(folder.path);

    analysisServer.folderMap[folder] = context;
    analysisServer._onContextsChangedController
        .add(new ContextsChangedEvent(added: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);

    return context;
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    if (analysisServer.options.enableNewAnalysisDriver) {
      nd.AnalysisDriver analysisDriver =
          analysisServer.driverMap[contextFolder];
      if (analysisDriver != null) {
        changeSet.addedSources.forEach((source) {
          analysisDriver.addFile(source.fullName);
          // temporary plugin support:
          analysisServer._onFileAddedController.add(source.fullName);
        });
        changeSet.changedSources.forEach((source) {
          analysisDriver.changeFile(source.fullName);
          // temporary plugin support:
          analysisServer._onFileChangedController.add(source.fullName);
        });
        changeSet.removedSources.forEach((source) {
          analysisDriver.removeFile(source.fullName);
        });
      }
    } else {
      AnalysisContext context = analysisServer.folderMap[contextFolder];
      if (context != null) {
        context.applyChanges(changeSet);
        analysisServer.schedulePerformAnalysisOperation(context);
        List<String> flushedFiles = new List<String>();
        for (Source source in changeSet.removedSources) {
          flushedFiles.add(source.fullName);
        }
        sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);
      }
    }
  }

  @override
  void applyFileRemoved(nd.AnalysisDriver driver, String file) {
    driver.removeFile(file);
    sendAnalysisNotificationFlushResults(analysisServer, [file]);
  }

  @override
  void computingPackageMap(bool computing) =>
      analysisServer._computingPackageMap(computing);

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
    builder.fileContentOverlay = analysisServer.fileContentOverlay;
    return builder;
  }

  @override
  void moveContext(Folder from, Folder to) {
    // There is nothing to do.
    // This method is mostly for tests.
    // Context managers manage folders and contexts themselves.
  }

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    if (analysisServer.options.enableNewAnalysisDriver) {
      sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);
      nd.AnalysisDriver driver = analysisServer.driverMap.remove(folder);
      driver.dispose();
    } else {
      AnalysisContext context = analysisServer.folderMap.remove(folder);
      sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);

      analysisServer.operationQueue.contextRemoved(context);
      analysisServer._onContextsChangedController
          .add(new ContextsChangedEvent(removed: [context]));
      analysisServer.sendContextAnalysisDoneNotifications(
          context, AnalysisDoneReason.CONTEXT_REMOVED);
      context.dispose();
    }
  }

  @override
  void updateContextPackageUriResolver(AnalysisContext context) {
    analysisServer._onContextsChangedController
        .add(new ContextsChangedEvent(changed: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  List<server.HighlightRegion> _computeHighlightRegions(CompilationUnit unit) {
    if (analysisServer.options.useAnalysisHighlight2) {
      return new DartUnitHighlightsComputer2(unit).compute();
    } else {
      return new DartUnitHighlightsComputer(unit).compute();
    }
  }

  String _computeLibraryName(CompilationUnit unit) {
    for (Directive directive in unit.directives) {
      if (directive is LibraryDirective && directive.name != null) {
        return directive.name.name;
      }
    }
    for (Directive directive in unit.directives) {
      if (directive is PartOfDirective && directive.libraryName != null) {
        return directive.libraryName.name;
      }
    }
    return null;
  }

  server.AnalysisNavigationParams _computeNavigationParams(
      String path, CompilationUnit unit) {
    NavigationCollectorImpl collector = new NavigationCollectorImpl();
    computeDartNavigation(collector, unit, null, null);
    collector.createRegions();
    return new server.AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  List<Occurrences> _computeOccurrences(CompilationUnit unit) {
    OccurrencesCollectorImpl collector = new OccurrencesCollectorImpl();
    addDartOccurrences(collector, unit);
    return collector.allOccurrences;
  }

  server.AnalysisOutlineParams _computeOutlineParams(
      String path, CompilationUnit unit, LineInfo lineInfo) {
    // compute FileKind
    SourceKind sourceKind = unit.directives.any((d) => d is PartOfDirective)
        ? SourceKind.PART
        : SourceKind.LIBRARY;
    server.FileKind fileKind = server.FileKind.LIBRARY;
    if (sourceKind == SourceKind.LIBRARY) {
      fileKind = server.FileKind.LIBRARY;
    } else if (sourceKind == SourceKind.PART) {
      fileKind = server.FileKind.PART;
    }
    // compute library name
    String libraryName = _computeLibraryName(unit);
    // compute Outline
    DartUnitOutlineComputer computer =
        new DartUnitOutlineComputer(path, lineInfo, unit);
    server.Outline outline = computer.compute();
    return new server.AnalysisOutlineParams(path, fileKind, outline,
        libraryName: libraryName);
  }

  /**
   * Run [f] in a new [Future].
   *
   * This method is used to delay sending notifications. If there is a more
   * important consumer of an analysis results, specifically a code completion
   * computer, we want it to run before spending time of sending notifications.
   *
   * TODO(scheglov) Consider replacing this with full priority based scheduler.
   *
   * TODO(scheglov) Alternatively, if code completion work in a way that does
   * not produce (at first) fully resolved unit, but only part of it - a single
   * method, or a top-level declaration, we would not have this problem - the
   * completion computer would be the only consumer of the partial analysis
   * result.
   */
  void _runDelayed(f()) {
    new Future(f);
  }
}

/**
 * A class used by [AnalysisServer] to record performance information
 * such as request latency.
 */
class ServerPerformance {
  /**
   * The creation time and the time when performance information
   * started to be recorded here.
   */
  int startTime = new DateTime.now().millisecondsSinceEpoch;

  /**
   * The number of requests.
   */
  int requestCount = 0;

  /**
   * The total latency (milliseconds) for all recorded requests.
   */
  int requestLatency = 0;

  /**
   * The maximum latency (milliseconds) for all recorded requests.
   */
  int maxLatency = 0;

  /**
   * The number of requests with latency > 150 milliseconds.
   */
  int slowRequestCount = 0;

  /**
   * Log performance information about the given request.
   */
  void logRequest(Request request) {
    ++requestCount;
    if (request.clientRequestTime != null) {
      int latency =
          new DateTime.now().millisecondsSinceEpoch - request.clientRequestTime;
      requestLatency += latency;
      maxLatency = max(maxLatency, latency);
      if (latency > 150) {
        ++slowRequestCount;
      }
    }
  }
}

/**
 * Container with global [AnalysisServer] performance statistics.
 */
class ServerPerformanceStatistics {
  /**
   * The [PerformanceTag] for time spent in [ExecutionDomainHandler].
   */
  static PerformanceTag executionNotifications =
      new PerformanceTag('executionNotifications');

  /**
   * The [PerformanceTag] for time spent performing a _DartIndexOperation.
   */
  static PerformanceTag indexOperation = new PerformanceTag('indexOperation');

  /**
   * The [PerformanceTag] for time spent between calls to
   * AnalysisServer.performOperation when the server is not idle.
   */
  static PerformanceTag intertask = new PerformanceTag('intertask');

  /**
   * The [PerformanceTag] for time spent between calls to
   * AnalysisServer.performOperation when the server is idle.
   */
  static PerformanceTag idle = new PerformanceTag('idle');

  /**
   * The [PerformanceTag] for time spent in
   * PerformAnalysisOperation._sendNotices.
   */
  static PerformanceTag notices = new PerformanceTag('notices');

  /**
   * The [PerformanceTag] for time spent running pub.
   */
  static PerformanceTag pub = new PerformanceTag('pub');

  /**
   * The [PerformanceTag] for time spent in server communication channels.
   */
  static PerformanceTag serverChannel = new PerformanceTag('serverChannel');

  /**
   * The [PerformanceTag] for time spent in server request handlers.
   */
  static PerformanceTag serverRequests = new PerformanceTag('serverRequests');

  /**
   * The [PerformanceTag] for time spent in split store microtasks.
   */
  static PerformanceTag splitStore = new PerformanceTag('splitStore');
}
