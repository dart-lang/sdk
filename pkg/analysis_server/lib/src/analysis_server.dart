// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;
import 'dart:math' show max;

import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide AnalysisOptions, Element;
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index2/index2.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/plugin/embedded_resolver_provider.dart';
import 'package:analyzer/plugin/resolver_provider.dart';
import 'package:analyzer/source/embedder.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/util/glob.dart';
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
  static final String VERSION = '1.14.0';

  /**
   * The number of milliseconds to perform operations before inserting
   * a 1 millisecond delay so that the VM and dart:io can deliver content
   * to stdin. This should be removed once the underlying problem is fixed.
   */
  static int performOperationDelayFreqency = 25;

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
   * The [ResourceProvider] using which paths are converted into [Resource]s.
   */
  final ResourceProvider resourceProvider;

  /**
   * The [Index] for this server, may be `null` if indexing is disabled.
   */
  final Index index;

  /**
   * The [Index2] for this server, may be `null` if indexing is disabled.
   */
  final Index2 index2;

  /**
   * The [SearchEngine] for this server, may be `null` if indexing is disabled.
   */
  final SearchEngine searchEngine;

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
   * The function used to create a new SDK using the default SDK.
   */
  final SdkCreator defaultSdkCreator;

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
   * The option possibly set from the server initialization which disables error notifications.
   */
  bool _noErrorNotification;

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
  StreamController<AnalysisContext> _onAnalysisStartedController;

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
      Index _index,
      Index2 _index2,
      this.serverPlugin,
      this.options,
      this.defaultSdkCreator,
      this.instrumentationService,
      {ResolverProvider packageResolverProvider: null,
      EmbeddedResolverProvider embeddedResolverProvider: null,
      this.rethrowExceptions: true})
      : index = _index,
        index2 = _index2,
        searchEngine = _index != null ? createSearchEngine(_index) : null {
    _performance = performanceDuringStartup;
    defaultContextOptions.incremental = true;
    defaultContextOptions.incrementalApi =
        options.enableIncrementalResolutionApi;
    defaultContextOptions.incrementalValidation =
        options.enableIncrementalResolutionValidation;
    defaultContextOptions.generateImplicitErrors = false;
    operationQueue = new ServerOperationQueue();
    contextManager = new ContextManagerImpl(
        resourceProvider,
        packageResolverProvider,
        embeddedResolverProvider,
        packageMapProvider,
        analyzedFilesGlobs,
        instrumentationService,
        defaultContextOptions);
    ServerContextManagerCallbacks contextManagerCallbacks =
        new ServerContextManagerCallbacks(this, resourceProvider);
    contextManager.callbacks = contextManagerCallbacks;
    _noErrorNotification = options.noErrorNotification;
    AnalysisEngine.instance.logger = new AnalysisLogger(this);
    _onAnalysisStartedController = new StreamController.broadcast();
    _onFileAnalyzedController = new StreamController.broadcast();
    _onPriorityChangeController =
        new StreamController<PriorityChangeEvent>.broadcast();
    running = true;
    onAnalysisStarted.first.then((_) {
      onAnalysisComplete.then((_) {
        performanceAfterStartup = new ServerPerformance();
        _performance = performanceAfterStartup;
      });
    });
    Notification notification =
        new ServerConnectedParams(VERSION).toNotification();
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
    handlers = serverPlugin.createDomains(this);
    sdkManager = new DartSdkManager(defaultSdkCreator);
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
              .add(new Glob(JavaFile.pathContext.separator, pattern));
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
   * The stream that is notified when analysis of a context is started.
   */
  Stream<AnalysisContext> get onAnalysisStarted {
    return _onAnalysisStartedController.stream;
  }

  /**
   * The stream that is notified when contexts are added or removed.
   */
  Stream<ContextsChangedEvent> get onContextsChanged =>
      _onContextsChangedController.stream;

  /**
   * The stream that is notified when a single file has been analyzed.
   */
  Stream get onFileAnalyzed => _onFileAnalyzedController.stream;

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
    index.stop();
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
   * Returns [Element]s at the given [offset] of the given [file].
   *
   * May be empty if cannot be resolved, but not `null`.
   */
  List<Element> getElementsAtOffset(String file, int offset) {
    List<AstNode> nodes = getNodesAtOffset(file, offset);
    return getElementsOfNodes(nodes);
  }

  /**
   * Returns [Element]s of the given [nodes].
   *
   * May be empty if not resolved, but not `null`.
   */
  List<Element> getElementsOfNodes(List<AstNode> nodes) {
    List<Element> elements = <Element>[];
    for (AstNode node in nodes) {
      if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
        node = node.parent;
      }
      if (node is LibraryIdentifier) {
        node = node.parent;
      }
      if (node is StringLiteral && node.parent is UriBasedDirective) {
        continue;
      }
      Element element = ElementLocator.locate(node);
      if (node is SimpleIdentifier && element is PrefixElement) {
        element = getImportElement(node);
      }
      if (element != null) {
        elements.add(element);
      }
    }
    return elements;
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
   * Returns resolved [AstNode]s at the given [offset] of the given [file].
   *
   * May be empty, but not `null`.
   */
  List<AstNode> getNodesAtOffset(String file, int offset) {
    List<CompilationUnit> units = getResolvedCompilationUnits(file);
    List<AstNode> nodes = <AstNode>[];
    for (CompilationUnit unit in units) {
      AstNode node = new NodeLocator(offset).searchWithin(unit);
      if (node != null) {
        nodes.add(node);
      }
    }
    return nodes;
  }

  /**
   * Returns resolved [CompilationUnit]s of the Dart file with the given [path].
   *
   * May be empty, but not `null`.
   */
  List<CompilationUnit> getResolvedCompilationUnits(String path) {
    List<CompilationUnit> units = <CompilationUnit>[];
    ContextSourcePair contextSource = getContextSourcePair(path);
    // prepare AnalysisContext
    AnalysisContext context = contextSource.context;
    if (context == null) {
      return units;
    }
    // add a unit for each unit/library combination
    runWithWorkingCacheSize(context, () {
      Source unitSource = contextSource.source;
      List<Source> librarySources = context.getLibrariesContaining(unitSource);
      for (Source librarySource in librarySources) {
        CompilationUnit unit =
            context.resolveCompilationUnit2(unitSource, librarySource);
        if (unit != null) {
          units.add(unit);
        }
      }
    });
    // done
    return units;
  }

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
    return operationQueue.isEmpty;
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
    _onAnalysisStartedController.add(context);
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
                AnalysisContext context = dartUnit.element.context;
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
    return !_noErrorNotification && contextManager.isInAnalysisRoot(file);
  }

  void shutdown() {
    running = false;
    if (index != null) {
      index.clear();
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
    if (context.getResult(librarySource, LIBRARY_ELEMENT5) == null) {
      return null;
    }
    // if library has been already resolved, resolve unit
    return runWithWorkingCacheSize(context, () {
      return context.resolveCompilationUnit2(source, librarySource);
    });
  }

  _scheduleAnalysisImplementedNotification() async {
    Set<String> files = analysisServices[AnalysisService.IMPLEMENTED];
    if (files != null) {
      scheduleImplementedNotification(this, files);
    }
  }

  /**
   * Schedules [performOperation] exection.
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
     * set performOperationDelayFreqency to zero
     */
    int now = new DateTime.now().millisecondsSinceEpoch;
    if (now > _nextPerformOperationDelayTime &&
        performOperationDelayFreqency > 0) {
      _nextPerformOperationDelayTime = now + performOperationDelayFreqency;
      new Future.delayed(new Duration(milliseconds: 1), performOperation);
    } else {
      new Future(performOperation);
    }
    performOperationPending = true;
  }
}

class AnalysisServerOptions {
  bool enableIncrementalResolutionApi = false;
  bool enableIncrementalResolutionValidation = false;
  bool noErrorNotification = false;
  bool noIndex = false;
  bool useAnalysisHighlight2 = false;
  String fileReadMode = 'as-is';
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
  AnalysisContext addContext(
      Folder folder, AnalysisOptions options, FolderDisposition disposition) {
    InternalAnalysisContext context =
        AnalysisEngine.instance.createAnalysisContext();
    context.contentCache = analysisServer.overlayState;
    analysisServer.folderMap[folder] = context;
    _locateEmbedderYamls(context, disposition);
    context.sourceFactory =
        _createSourceFactory(context, options, disposition, folder);
    context.analysisOptions = options;
    analysisServer._onContextsChangedController
        .add(new ContextsChangedEvent(added: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);
    return context;
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    if (context != null) {
      ApplyChangesStatus changesStatus = context.applyChanges(changeSet);
      if (changesStatus.hasChanges) {
        analysisServer.schedulePerformAnalysisOperation(context);
      }
      List<String> flushedFiles = new List<String>();
      for (Source source in changeSet.removedSources) {
        flushedFiles.add(source.fullName);
      }
      sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);
    }
  }

  @override
  void computingPackageMap(bool computing) =>
      analysisServer._computingPackageMap(computing);

  @override
  void removeContext(Folder folder, List<String> flushedFiles) {
    AnalysisContext context = analysisServer.folderMap.remove(folder);
    sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);

    if (analysisServer.index != null) {
      analysisServer.index.removeContext(context);
    }
    analysisServer.operationQueue.contextRemoved(context);
    analysisServer._onContextsChangedController
        .add(new ContextsChangedEvent(removed: [context]));
    analysisServer.sendContextAnalysisDoneNotifications(
        context, AnalysisDoneReason.CONTEXT_REMOVED);
    context.dispose();
  }

  @override
  void updateContextPackageUriResolver(
      Folder contextFolder, FolderDisposition disposition) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    context.sourceFactory = _createSourceFactory(
        context, context.analysisOptions, disposition, contextFolder);
    analysisServer._onContextsChangedController
        .add(new ContextsChangedEvent(changed: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  /**
   * Set up a [SourceFactory] that resolves packages as appropriate for the
   * given [disposition].
   */
  SourceFactory _createSourceFactory(InternalAnalysisContext context,
      AnalysisOptions options, FolderDisposition disposition, Folder folder) {
    List<UriResolver> resolvers = [];
    List<UriResolver> packageUriResolvers =
        disposition.createPackageUriResolvers(resourceProvider);

    EmbedderUriResolver embedderUriResolver;

    // First check for a resolver provider.
    ContextManager contextManager = analysisServer.contextManager;
    if (contextManager is ContextManagerImpl) {
      EmbeddedResolverProvider resolverProvider =
          contextManager.embeddedUriResolverProvider;
      if (resolverProvider != null) {
        embedderUriResolver = resolverProvider(folder);
      }
    }

    // If no embedded URI resolver was provided, defer to a locator-backed one.
    embedderUriResolver ??=
        new EmbedderUriResolver(context.embedderYamlLocator.embedderYamls);
    if (embedderUriResolver.length == 0) {
      // The embedder uri resolver has no mappings. Use the default Dart SDK
      // uri resolver.
      resolvers.add(new DartUriResolver(
          analysisServer.sdkManager.getSdkForOptions(options)));
    } else {
      // The embedder uri resolver has mappings, use it instead of the default
      // Dart SDK uri resolver.
      resolvers.add(embedderUriResolver);
    }

    resolvers.addAll(packageUriResolvers);
    resolvers.add(new ResourceUriResolver(resourceProvider));
    return new SourceFactory(resolvers, disposition.packages);
  }

  /// If [disposition] has a package map, attempt to locate `_embedder.yaml`
  /// files.
  void _locateEmbedderYamls(
      InternalAnalysisContext context, FolderDisposition disposition) {
    Map<String, List<Folder>> packageMap;
    if (disposition is PackageMapDisposition) {
      packageMap = disposition.packageMap;
    } else if (disposition is PackagesFileDisposition) {
      packageMap = disposition.buildPackageMap(resourceProvider);
    }
    context.embedderYamlLocator.refresh(packageMap);
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
   * Log performation information about the given request.
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
   * The [PerformanceTag] for time spent in server comminication channels.
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
