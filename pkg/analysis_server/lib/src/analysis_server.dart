// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;
import 'dart:math' show max;

import 'package:analysis_server/plugin/analyzed_files.dart';
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/source/optimizing_pub_package_map_provider.dart';
import 'package:analysis_server/uri/resolver_provider.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:package_config/packages.dart';
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
  static final String VERSION = '1.8.0';

  /**
   * The number of milliseconds to perform operations before inserting
   * a 1 millisecond delay so that the VM and dart:io can deliver content
   * to stdin. This should be removed once the underlying problem is fixed.
   */
  static int performOperationDelayFreqency = 25;

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
   * The [SearchEngine] for this server, may be `null` if indexing is disabled.
   */
  final SearchEngine searchEngine;

  /**
   * The plugin associated with this analysis server.
   */
  final ServerPlugin serverPlugin;

  /**
   * The [ContextManager] that handles the mapping from analysis roots to
   * context directories.
   */
  ServerContextManager contextManager;

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
   * The current default [DartSdk].
   */
  final DartSdk defaultSdk;

  /**
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * A table mapping [Folder]s to the [AnalysisContext]s associated with them.
   */
  final Map<Folder, AnalysisContext> folderMap =
      new HashMap<Folder, AnalysisContext>();

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
  Map<AnalysisContext, Completer<AnalysisDoneReason>> contextAnalysisDoneCompleters =
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
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   *
   * If a [contextManager] is provided, then the [packageResolverProvider] will
   * be ignored.
   *
   * If [rethrowExceptions] is true, then any exceptions thrown by analysis are
   * propagated up the call stack.  The default is true to allow analysis
   * exceptions to show up in unit tests, but it should be set to false when
   * running a full analysis server.
   */
  AnalysisServer(this.channel, this.resourceProvider,
      OptimizingPubPackageMapProvider packageMapProvider, Index _index,
      this.serverPlugin, AnalysisServerOptions analysisServerOptions,
      this.defaultSdk, this.instrumentationService,
      {ContextManager contextManager: null,
      ResolverProvider packageResolverProvider: null,
      this.rethrowExceptions: true})
      : index = _index,
        searchEngine = _index != null ? createSearchEngine(_index) : null {
    _performance = performanceDuringStartup;
    operationQueue = new ServerOperationQueue();
    if (contextManager == null) {
      contextManager = new ServerContextManager(this, resourceProvider,
          packageResolverProvider, packageMapProvider, instrumentationService);
      AnalysisOptionsImpl options =
          (contextManager as ServerContextManager).defaultOptions;
      options.incremental = true;
      options.incrementalApi =
          analysisServerOptions.enableIncrementalResolutionApi;
      options.incrementalValidation =
          analysisServerOptions.enableIncrementalResolutionValidation;
      options.generateImplicitErrors = false;
    } else if (contextManager is! ServerContextManager) {
      // TODO(brianwilkerson) Remove this when the interface is complete.
      throw new StateError(
          'The contextManager must be an instance of ServerContextManager');
    }
    this.contextManager = contextManager;
    _noErrorNotification = analysisServerOptions.noErrorNotification;
    AnalysisEngine.instance.logger = new AnalysisLogger();
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
  }

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
      contextManager.onContextsChanged;

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
    for (AnalysisContext context in folderMap.values) {
      SourceKind kind = context.getKindOf(source);
      if (kind != SourceKind.UNKNOWN) {
        return context;
      }
    }
    return null;
  }

  /**
   * Return the [AnalysisContext]s that are being used to analyze the analysis
   * roots.
   */
  Iterable<AnalysisContext> getAnalysisContexts() {
    return folderMap.values;
  }

  /**
   * Return the [AnalysisContext] that contains the given [path].
   * Return `null` if no context contains the [path].
   */
  AnalysisContext getContainingContext(String path) {
    Folder containingFolder = null;
    AnalysisContext containingContext = null;
    folderMap.forEach((Folder folder, AnalysisContext context) {
      if (folder.isOrContains(path)) {
        if (containingFolder == null ||
            containingFolder.path.length < folder.path.length) {
          containingFolder = folder;
          containingContext = context;
        }
      }
    });
    return containingContext;
  }

  /**
   * Return the primary [ContextSourcePair] representing the given [path].
   *
   * The [AnalysisContext] of this pair will be the context that explicitly
   * contains the path, if any such context exists, otherwise it will be the
   * first context that implicitly analyzes it.
   *
   * If the [path] is not analyzed by any context, a [ContextSourcePair] with
   * a `null` context and `file` [Source] is returned.
   *
   * If the [path] dosn't represent a file, a [ContextSourcePair] with a `null`
   * context and `null` [Source] is returned.
   *
   * Does not return `null`.
   */
  ContextSourcePair getContextSourcePair(String path) {
    // try SDK
    {
      Uri uri = resourceProvider.pathContext.toUri(path);
      Source sdkSource = defaultSdk.fromFileUri(uri);
      if (sdkSource != null) {
        AnalysisContext anyContext = folderMap.values.first;
        return new ContextSourcePair(anyContext, sdkSource);
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
        Source source = AbstractContextManager.createSourceInContext(
            containingContext, file);
        return new ContextSourcePair(containingContext, source);
      }
    }
    // try to find a context that analysed the file
    for (AnalysisContext context in folderMap.values) {
      Source source =
          AbstractContextManager.createSourceInContext(context, file);
      SourceKind kind = context.getKindOf(source);
      if (kind != SourceKind.UNKNOWN) {
        return new ContextSourcePair(context, source);
      }
    }
    // try to find a context for which the file is a priority source
    for (InternalAnalysisContext context in folderMap.values) {
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
    return getElementsOfNodes(nodes, offset);
  }

  /**
   * Returns [Element]s of the given [nodes].
   *
   * May be empty if not resolved, but not `null`.
   */
  List<Element> getElementsOfNodes(List<AstNode> nodes, int offset) {
    List<Element> elements = <Element>[];
    for (AstNode node in nodes) {
      if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
        node = node.parent;
      }
      if (node is LibraryIdentifier) {
        node = node.parent;
      }
      Element element = ElementLocator.locateWithOffset(node, offset);
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
      sendServerErrorNotification(exception, stackTrace, fatal: true);
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
      AnalysisEngine.instance.logger.logError("${exception}\n${stackTrace}");
      if (rethrowExceptions) {
        throw new AnalysisException('Unexpected exception during analysis',
            new CaughtException(exception, stackTrace));
      }
      sendServerErrorNotification(exception, stackTrace, fatal: true);
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
  void sendServerErrorNotification(exception, stackTrace, {bool fatal: false}) {
    // prepare exception.toString()
    String exceptionString;
    if (exception != null) {
      exceptionString = exception.toString();
    } else {
      exceptionString = 'null exception';
    }
    // prepare stackTrace.toString()
    String stackTraceString;
    if (stackTrace != null) {
      stackTraceString = stackTrace.toString();
    } else {
      try {
        throw 'ignored';
      } catch (ignored, stackTrace) {
        stackTraceString = stackTrace.toString();
      }
      if (stackTraceString == null) {
        // This code should be unreachable.
        stackTraceString = 'null stackTrace';
      }
    }
    // send the notification
    channel.sendNotification(
        new ServerErrorParams(fatal, exceptionString, stackTraceString)
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
        ContextSourcePair contextSource = getContextSourcePair(file);
        // prepare context
        AnalysisContext context = contextSource.context;
        if (context == null) {
          continue;
        }
        // Dart unit notifications.
        if (AnalysisEngine.isDartFileName(file)) {
          Source source = contextSource.source;
          CompilationUnit dartUnit =
              _getResolvedCompilationUnitToResendNotification(context, source);
          if (dartUnit != null) {
            switch (service) {
              case AnalysisService.HIGHLIGHTS:
                sendAnalysisNotificationHighlights(this, file, dartUnit);
                break;
              case AnalysisService.NAVIGATION:
                // TODO(scheglov) consider support for one unit in 2+ libraries
                sendAnalysisNotificationNavigation(this, file, dartUnit);
                break;
              case AnalysisService.OCCURRENCES:
                sendAnalysisNotificationOccurrences(this, file, dartUnit);
                break;
              case AnalysisService.OUTLINE:
                AnalysisContext context = dartUnit.element.context;
                LineInfo lineInfo = context.getLineInfo(source);
                sendAnalysisNotificationOutline(this, file, lineInfo, dartUnit);
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
      ContextSourcePair contextSource = getContextSourcePair(file);
      AnalysisContext preferredContext = contextSource.context;
      Source source = contextSource.source;
      // Try to make the file analyzable.
      // If it is not in any context yet, add it to the first one which
      // could use it, e.g. imports its package, even if not the library.
      if (preferredContext == null) {
        Resource resource = resourceProvider.getResource(file);
        if (resource is File && resource.exists) {
          for (AnalysisContext context in folderMap.values) {
            Uri uri = context.sourceFactory.restoreUri(source);
            if (uri.scheme != 'file') {
              preferredContext = context;
              source = AbstractContextManager.createSourceInContext(
                  context, resource);
              break;
            }
          }
        }
      }
      // Fill the source map.
      bool contextFound = false;
      for (AnalysisContext context in folderMap.values) {
        if (context == preferredContext ||
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
    folderMap.forEach((Folder folder, AnalysisContext context) {
      List<Source> sourceList = sourceMap[context];
      if (sourceList == null) {
        sourceList = Source.EMPTY_LIST;
      }
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
      overlayState.setContents(source, newContents);
      // If the source does not exist, then it was an overlay-only one.
      // Remove it from contexts.
      if (newContents == null && !source.exists()) {
        for (InternalAnalysisContext context in folderMap.values) {
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
      for (InternalAnalysisContext context in folderMap.values) {
        List<Source> sources = context.getSourcesWithFullName(file);
        sources.forEach((Source source) {
          anyContextUpdated = true;
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
                  scheduleNotificationOperations(this, file, errorInfo.lineInfo,
                      context, null, dartUnit, errorInfo.errors);
                  scheduleIndexOperation(this, file, context, dartUnit);
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
    folderMap.forEach((Folder folder, AnalysisContext context) {
      AnalysisOptionsImpl options =
          new AnalysisOptionsImpl.from(context.analysisOptions);
      optionUpdaters.forEach((OptionUpdater optionUpdater) {
        optionUpdater(options);
      });
      context.analysisOptions = options;
      // TODO(brianwilkerson) As far as I can tell, this doesn't cause analysis
      // to be scheduled for this context.
    });
    //
    // Update the defaults used to create new contexts.
    //
    AnalysisOptionsImpl options = contextManager.defaultOptions;
    optionUpdaters.forEach((OptionUpdater optionUpdater) {
      optionUpdater(options);
    });
  }

  /**
   * Return a set of contexts containing all of the resources in the given list
   * of [resources].
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
    if (context.getLibraryElement(librarySource) == null) {
      return null;
    }
    // if library has been already resolved, resolve unit
    return runWithWorkingCacheSize(context, () {
      return context.resolveCompilationUnit2(source, librarySource);
    });
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

class ServerContextManager extends AbstractContextManager {
  final AnalysisServer analysisServer;

  /**
   * The default options used to create new analysis contexts.
   */
  AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();

  /**
   * The controller for sending [ContextsChangedEvent]s.
   */
  StreamController<ContextsChangedEvent> _onContextsChangedController;

  ServerContextManager(this.analysisServer, ResourceProvider resourceProvider,
      ResolverProvider packageResolverProvider,
      OptimizingPubPackageMapProvider packageMapProvider,
      InstrumentationService service)
      : super(resourceProvider, packageResolverProvider, packageMapProvider,
          service) {
    _onContextsChangedController =
        new StreamController<ContextsChangedEvent>.broadcast();
  }

  /**
   * The stream that is notified when contexts are added or removed.
   */
  Stream<ContextsChangedEvent> get onContextsChanged =>
      _onContextsChangedController.stream;

  @override
  AnalysisContext addContext(Folder folder, UriResolver packageUriResolver, Packages packages) {
    InternalAnalysisContext context =
        AnalysisEngine.instance.createAnalysisContext();
    context.contentCache = analysisServer.overlayState;
    analysisServer.folderMap[folder] = context;
    context.sourceFactory = _createSourceFactory(packageUriResolver, packages);
    context.analysisOptions = new AnalysisOptionsImpl.from(defaultOptions);
    _onContextsChangedController
        .add(new ContextsChangedEvent(added: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);
    return context;
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
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

  @override
  void beginComputePackageMap() {
    _computingPackageMap(true);
  }

  @override
  void endComputePackageMap() {
    _computingPackageMap(false);
  }

  @override
  void removeContext(Folder folder) {
    AnalysisContext context = analysisServer.folderMap.remove(folder);

    // See dartbug.com/22689, the AnalysisContext is computed in
    // computeFlushedFiles instead of using the referenced context above, this
    // is an attempt to be careful concerning the referenced issue.
    List<String> flushedFiles = computeFlushedFiles(folder);
    sendAnalysisNotificationFlushResults(analysisServer, flushedFiles);

    if (analysisServer.index != null) {
      analysisServer.index.removeContext(context);
    }
    analysisServer.operationQueue.contextRemoved(context);
    _onContextsChangedController
        .add(new ContextsChangedEvent(removed: [context]));
    analysisServer.sendContextAnalysisDoneNotifications(
        context, AnalysisDoneReason.CONTEXT_REMOVED);
    context.dispose();
  }

  @override
  bool shouldFileBeAnalyzed(File file) {
    List<ShouldAnalyzeFile> functions =
        analysisServer.serverPlugin.analyzeFileFunctions;
    for (ShouldAnalyzeFile shouldAnalyzeFile in functions) {
      if (shouldAnalyzeFile(file)) {
        // Emacs creates dummy links to track the fact that a file is open for
        // editing and has unsaved changes (e.g. having unsaved changes to
        // 'foo.dart' causes a link '.#foo.dart' to be created, which points to
        // the non-existent file 'username@hostname.pid'. To avoid these dummy
        // links causing the analyzer to thrash, just ignore links to
        // non-existent files.
        return file.exists;
      }
    }
    return false;
  }

  @override
  void updateContextPackageUriResolver(
      Folder contextFolder, UriResolver packageUriResolver, Packages packages) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    context.sourceFactory = _createSourceFactory(packageUriResolver, packages);
    _onContextsChangedController
        .add(new ContextsChangedEvent(changed: [context]));
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  void _computingPackageMap(bool computing) {
    if (analysisServer.serverServices.contains(ServerService.STATUS)) {
      PubStatus pubStatus = new PubStatus(computing);
      ServerStatusParams params = new ServerStatusParams(pub: pubStatus);
      analysisServer.sendNotification(params.toNotification());
    }
  }

  /**
   * Set up a [SourceFactory] that resolves packages using the given
   * [packageUriResolver] and [packages] resolution strategy.
   */
  SourceFactory _createSourceFactory(UriResolver packageUriResolver, Packages packages) {
    UriResolver dartResolver = new DartUriResolver(analysisServer.defaultSdk);
    UriResolver resourceResolver = new ResourceUriResolver(resourceProvider);
    List<UriResolver> resolvers = [];
    resolvers.add(dartResolver);
    if (packageUriResolver is PackageMapUriResolver) {
      UriResolver sdkExtResolver =
          new SdkExtUriResolver(packageUriResolver.packageMap);
      resolvers.add(sdkExtResolver);
    }
    if (packageUriResolver != null) {
      resolvers.add(packageUriResolver);
    }
    resolvers.add(resourceResolver);
    return new SourceFactory(resolvers, packages);
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
