// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/package_map_provider.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';


class ServerContextManager extends ContextManager {
  final AnalysisServer analysisServer;

  /**
   * The default options used to create new analysis contexts.
   */
  AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();

  ServerContextManager(
      this.analysisServer, ResourceProvider resourceProvider,
      PackageMapProvider packageMapProvider)
      : super(resourceProvider, packageMapProvider);

  @override
  void addContext(Folder folder, Map<String, List<Folder>> packageMap) {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    analysisServer.folderMap[folder] = context;
    context.sourceFactory = _createSourceFactory(packageMap);
    context.analysisOptions = new AnalysisOptionsImpl.con1(defaultOptions);
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  @override
  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    if (context != null) {
      context.applyChanges(changeSet);
      analysisServer.schedulePerformAnalysisOperation(context);
    }
  }

  @override
  void removeContext(Folder folder) {
    AnalysisContext context = analysisServer.folderMap.remove(folder);
    analysisServer.sendContextAnalysisCancelledNotifications(
        context,
        'Context was removed');
  }

  @override
  void updateContextPackageMap(Folder contextFolder,
                               Map<String, List<Folder>> packageMap) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    context.sourceFactory = _createSourceFactory(packageMap);
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  /**
   * Set up a [SourceFactory] that resolves packages using the given
   * [packageMap].
   */
  SourceFactory _createSourceFactory(Map<String, List<Folder>> packageMap) {
    List<UriResolver> resolvers = <UriResolver>[
        new DartUriResolver(analysisServer.defaultSdk),
        new ResourceUriResolver(resourceProvider),
        new PackageMapUriResolver(resourceProvider, packageMap)
    ];
    return new SourceFactory(resolvers);
  }
}

/**
 * Instances of the class [AnalysisServer] implement a server that listens on a
 * [CommunicationChannel] for analysis requests and process them.
 */
class AnalysisServer {
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
   * The [Index] for this server.
   */
  final Index index;

  /**
   * The [SearchEngine] for this server.
   */
  SearchEngine searchEngine;

  /**
   * [ContextManager] which handles the mapping from analysis roots
   * to context directories.
   */
  ServerContextManager contextDirectoryManager;

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
   * A table mapping [Folder]s to the [AnalysisContext]s associated with them.
   */
  final Map<Folder, AnalysisContext> folderMap =
      new HashMap<Folder, AnalysisContext>();

  /**
   * A queue of the operations to perform in this server.
   *
   * Invariant: when this queue is non-empty, there is exactly one pending call
   * to [performOperation] on the event queue.  When this list is empty, there are
   * no calls to [performOperation] on the event queue.
   */
  ServerOperationQueue operationQueue;

  /**
   * A set of the [ServerService]s to send notifications for.
   */
  Set<ServerService> serverServices = new HashSet<ServerService>();

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
  Map<AnalysisContext, Completer> contextAnalysisDoneCompleters =
      new HashMap<AnalysisContext, Completer>();

  /**
   * True if any exceptions thrown by analysis should be propagated up the call
   * stack.
   */
  bool rethrowExceptions;

  /**
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   *
   * If [rethrowExceptions] is true, then any exceptions thrown by analysis are
   * propagated up the call stack.  The default is true to allow analysis
   * exceptions to show up in unit tests, but it should be set to false when
   * running a full analysis server.
   */
  AnalysisServer(this.channel, this.resourceProvider,
      PackageMapProvider packageMapProvider, this.index, this.defaultSdk,
      {this.rethrowExceptions: true}) {
    searchEngine = createSearchEngine(index);
    operationQueue = new ServerOperationQueue(this);
    contextDirectoryManager = new ServerContextManager(
        this, resourceProvider, packageMapProvider);
    AnalysisEngine.instance.logger = new AnalysisLogger();
    running = true;
    Notification notification = new Notification(SERVER_CONNECTED);
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
  }

  /**
   * Schedules execution of the given [ServerOperation].
   */
  void scheduleOperation(ServerOperation operation) {
    bool wasEmpty = operationQueue.isEmpty;
    addOperation(operation);
    if (wasEmpty) {
      _schedulePerformOperation();
    }
  }

  /**
   * Schedules analysis of the given context.
   */
  void schedulePerformAnalysisOperation(AnalysisContext context) {
    scheduleOperation(new PerformAnalysisOperation(context, false));
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
   * Set the priority files to the given [files].
   */
  void setPriorityFiles(Request request, List<String> files) {
    Map<AnalysisContext, List<Source>> sourceMap =
        new HashMap<AnalysisContext, List<Source>>();
    List<String> unanalyzed = new List<String>();
    files.forEach((file) {
      AnalysisContext analysisContext = getAnalysisContext(file);
      if (analysisContext == null) {
        unanalyzed.add(file);
      } else {
        List<Source> sourceList = sourceMap[analysisContext];
        if (sourceList == null) {
          sourceList = <Source>[];
          sourceMap[analysisContext] = sourceList;
        }
        sourceList.add(getSource(file));
      }
    });
    if (unanalyzed.isNotEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.writeAll(unanalyzed, ', ');
      throw new RequestFailure(new Response.unanalyzedPriorityFiles(request,
          buffer.toString()));
    }
    folderMap.forEach((Folder folder, AnalysisContext context) {
      List<Source> sourceList = sourceMap[context];
      if (sourceList == null) {
        sourceList = Source.EMPTY_ARRAY;
      }
      context.analysisPriorityOrder = sourceList;
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
      AnalysisOptionsImpl options = new AnalysisOptionsImpl.con1(context.analysisOptions);
      optionUpdaters.forEach((OptionUpdater optionUpdater) {
        optionUpdater(options);
      });
      context.analysisOptions = options;
    });
    //
    // Update the defaults used to create new contexts.
    //
    AnalysisOptionsImpl options = contextDirectoryManager.defaultOptions;
    optionUpdaters.forEach((OptionUpdater optionUpdater) {
      optionUpdater(options);
    });
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
      }
    }
    channel.sendResponse(new Response.unknownRequest(request));
  }

  /**
   * Returns `true` if there is a subscription for the given [server] and [file].
   */
  bool hasAnalysisSubscription(AnalysisService service, String file) {
    Set<String> files = analysisServices[service];
    return files != null && files.contains(file);
  }

  /**
   * Returns `true` if errors should be reported for [file] with the given
   * absolute path.
   */
  bool shouldSendErrorsNotificationFor(String file) {
    // TODO(scheglov) add support for the "--no-error-notification" flag.
    return contextDirectoryManager.isInAnalysisRoot(file);
  }

  /**
   * Returns `true` if the given [AnalysisContext] is a priority one.
   */
  bool isPriorityContext(AnalysisContext context) {
    // TODO(scheglov) implement support for priority sources/contexts
    return false;
  }

  /**
   * Perform the next available [ServerOperation].
   */
  void performOperation() {
    if (!running) {
      // An error has occurred, or the connection to the client has been
      // closed, since this method was scheduled on the event queue.  So
      // don't do anything.  Instead clear the operation queue.
      operationQueue.clear();
      return;
    }
    // prepare next operation
    ServerOperation operation = operationQueue.take();
    sendStatusNotification(operation);
    // perform the operation
    try {
      operation.perform(this);
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logError("${exception}\n${stackTrace}");
      if (rethrowExceptions) {
        throw new AnalysisException(
            'Unexpected exception during analysis',
            new CaughtException(exception, stackTrace));
      }
      _sendServerErrorNotification(exception, stackTrace);
      shutdown();
    } finally {
      if (!operationQueue.isEmpty) {
        _schedulePerformOperation();
      } else {
        sendStatusNotification(null);
      }
    }
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
    Notification notification = new Notification(SERVER_STATUS);
    Map<String, Object> analysis = new HashMap();
    analysis['analyzing'] = isAnalyzing;
    notification.params['analysis'] = analysis;
    channel.sendNotification(notification);
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
  void setAnalysisRoots(String requestId,
                        List<String> includedPaths,
                        List<String> excludedPaths) {
    try {
      contextDirectoryManager.setRoots(includedPaths, excludedPaths);
    } on UnimplementedError catch (e) {
      throw new RequestFailure(
                  new Response.unsupportedFeature(
                      requestId, e.message));
    }
  }

  /**
   * Implementation for `analysis.updateContent`.
   */
  void updateContent(Map<String, ContentChange> changes) {
    changes.forEach((file, change) {
      AnalysisContext analysisContext = getAnalysisContext(file);
      // TODO(paulberry): handle the case where a file is referred to by more
      // than one context (e.g package A depends on package B using a local
      // path, user has both packages open for editing in separate contexts,
      // and user modifies a file in package B).
      if (analysisContext != null) {
        Source source = getSource(file);
        switch (change.type) {
          case ADD:
            analysisContext.setContents(source, change.content);
            break;
          case CHANGE:
            // TODO(paulberry): an error should be generated if source is not
            // currently in the content cache.
            TimestampedData<String> oldContents = analysisContext.getContents(
                source);
            String newContents = Edit.applySequence(oldContents.data, change.changes);
            // TODO(paulberry): to aid in incremental processing it would be
            // better to use setChangedContents.
            analysisContext.setContents(source, newContents);
            break;
          case REMOVE:
            analysisContext.setContents(source, null);
            break;
        }
        schedulePerformAnalysisOperation(analysisContext);
      }
    });
  }

  /**
   * Implementation for `analysis.setSubscriptions`.
   */
  void setAnalysisSubscriptions(Map<AnalysisService, Set<String>> subscriptions) {
    // send notifications for already analyzed sources
    subscriptions.forEach((service, Set<String> newFiles) {
      Set<String> oldFiles = analysisServices[service];
      Set<String> todoFiles = oldFiles != null ? newFiles.difference(oldFiles) : newFiles;
      for (String file in todoFiles) {
        Source source = getSource(file);
        // prepare context
        AnalysisContext context = getAnalysisContext(file);
        if (context == null) {
          continue;
        }
        // Dart unit notifications.
        if (AnalysisEngine.isDartFileName(file)) {
          CompilationUnit dartUnit = getResolvedCompilationUnitToResendNotification(file);
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
                sendAnalysisNotificationOutline(this, context, source, dartUnit);
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
   * Return the [AnalysisContext] that is used to analyze the given [path].
   * Return `null` if there is no such context.
   */
  AnalysisContext getAnalysisContext(String path) {
    // try to find a containing context
    for (Folder folder in folderMap.keys) {
      if (path.startsWith(folder.path)) {
        return folderMap[folder];
      }
    }
    // check if there is a context that analyzed this source
    {
      Source source = getSource(path);
      for (AnalysisContext context in folderMap.values) {
        SourceKind kind = context.getKindOf(source);
        if (kind != null) {
          return context;
        }
      }
    }
    return null;
  }

  /**
   * Return the [Source] of the Dart file with the given [path].
   */
  Source getSource(String path) {
    // try SDK
    {
      Uri uri = resourceProvider.pathContext.toUri(path);
      Source sdkSource = defaultSdk.fromFileUri(uri);
      if (sdkSource != null) {
        return sdkSource;
      }
    }
    // file-based source
    File file = resourceProvider.getResource(path);
    return file.createSource();
  }

  /**
   * Returns the [CompilationUnit] of the Dart file with the given [path] that
   * should be used to resend notifications for already resolved unit.
   * Returns `null` if the file is not a part of any context, library has not
   * been yet resolved, or any problem happened.
   */
  CompilationUnit getResolvedCompilationUnitToResendNotification(String path) {
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(path);
    if (context == null) {
      return null;
    }
    // prepare sources
    Source unitSource = getSource(path);
    List<Source> librarySources = context.getLibrariesContaining(unitSource);
    if (librarySources.isEmpty) {
      return null;
    }
    // if library has not been resolved yet, the unit will be resolved later
    Source librarySource = librarySources[0];
    if (context.getLibraryElement(librarySource) == null) {
      return null;
    }
    // if library has been already resolved, resolve unit
    return context.resolveCompilationUnit2(unitSource, librarySource);
  }

  /**
   * Return an analysis error info containing the array of all of the errors and
   * the line info associated with [file].
   *
   * Returns `null` if [file] does not belong to any [AnalysisContext].
   *
   * The array of errors will be empty if [file] does not exist or if there are
   * no errors in [file]. The errors contained in the array can be incomplete.
   *
   * This method does not wait for all errors to be computed, and returns just
   * the current state.
   */
  AnalysisErrorInfo getErrors(String file) {
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(file);
    if (context == null) {
      return null;
    }
    // get errors for the file
    Source source = getSource(file);
    return context.getErrors(source);
  }

  /**
   * Returns resolved [CompilationUnit]s of the Dart file with the given [path].
   *
   * May be empty, but not `null`.
   */
  List<CompilationUnit> getResolvedCompilationUnits(String path) {
    List<CompilationUnit> units = <CompilationUnit>[];
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(path);
    if (context == null) {
      return units;
    }
    // add a unit for each unit/library combination
    Source unitSource = getSource(path);
    List<Source> librarySources = context.getLibrariesContaining(unitSource);
    for (Source librarySource in librarySources) {
      CompilationUnit unit = context.getResolvedCompilationUnit2(unitSource, librarySource);
      if (unit != null) {
        units.add(unit);
      }
    }
    // done
    return units;
  }

  /**
   * Returns [Element]s of the Dart file with the given [path], at the given
   * offset.
   *
   * May be empty, but not `null`.
   */
  List<Element> getElementsAtOffset(String path, int offset) {
    List<CompilationUnit> units = getResolvedCompilationUnits(path);
    List<Element> elements = <Element>[];
    for (CompilationUnit unit in units) {
      AstNode node = new NodeLocator.con1(offset).searchWithin(unit);
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
   * Returns a [Future] completing when [file] has been completely analyzed, in
   * particular, all its errors have been computed.
   *
   * TODO(scheglov) this method should be improved.
   *
   * 1. The analysis context should be told to analyze this particular file ASAP.
   *
   * 2. We should complete the future as soon as the file is analyzed (not wait
   *    until the context is completely finished)
   */
  Future onFileAnalysisComplete(String file) {
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(file);
    if (context == null) {
      return new Future.value();
    }
    // schedule context analysis
    schedulePerformAnalysisOperation(context);
    // associate with the context completer
    Completer completer = contextAnalysisDoneCompleters[context];
    if (completer == null) {
      completer = new Completer();
      contextAnalysisDoneCompleters[context] = completer;
    }
    return completer.future;
  }

  /**
   * This method is called when analysis of the given [AnalysisContext] is
   * done.
   */
  void sendContextAnalysisDoneNotifications(AnalysisContext context) {
    Completer completer = contextAnalysisDoneCompleters.remove(context);
    if (completer != null) {
      completer.complete();
    }
  }

  /**
   * This method is called when analysis of the given [AnalysisContext] is
   * cancelled.
   */
  void sendContextAnalysisCancelledNotifications(AnalysisContext context, String message) {
    Completer completer = contextAnalysisDoneCompleters.remove(context);
    if (completer != null) {
      completer.completeError(message);
    }
  }

  void shutdown() {
    running = false;
    if (index != null) {
      index.clear();
      index.stop();
    }
    // Defer closing the channel so that the shutdown response can be sent.
    new Future(channel.close);
  }

  /**
   * Return the [CompilationUnit] of the Dart file with the given [path].
   * Return `null` if the file is not a part of any context.
   */
  CompilationUnit test_getResolvedCompilationUnit(String path) {
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(path);
    if (context == null) {
      return null;
    }
    // prepare sources
    Source unitSource = getSource(path);
    List<Source> librarySources = context.getLibrariesContaining(unitSource);
    if (librarySources.isEmpty) {
      return null;
    }
    // get a resolved unit
    return context.getResolvedCompilationUnit2(unitSource, librarySources[0]);
  }

  /**
   * Return `true` if all operations have been performed in this [AnalysisServer].
   */
  bool test_areOperationsFinished() {
    return operationQueue.isEmpty;
  }

  /**
   * Schedules [performOperation] exection.
   */
  void _schedulePerformOperation() {
    new Future(performOperation);
  }

  /**
   * Sends a fatal `server.error` notification.
   */
  void _sendServerErrorNotification(exception, stackTrace) {
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
      stackTraceString = 'null stackTrace';
    }
    // send the notification
    Notification notification = new Notification(SERVER_ERROR);
    notification.setParameter(FATAL, true);
    notification.setParameter(MESSAGE, exceptionString);
    notification.setParameter(STACK_TRACE, stackTraceString);
    channel.sendNotification(notification);
  }
}


/**
 * An enumeration of the services provided by the analysis domain.
 */
class AnalysisService extends Enum2<AnalysisService> {
  static const HIGHLIGHTS = const AnalysisService('HIGHLIGHTS', 1);
  static const NAVIGATION = const AnalysisService('NAVIGATION', 2);
  static const OCCURRENCES = const AnalysisService('OCCURRENCES', 3);
  static const OUTLINE = const AnalysisService('OUTLINE', 4);
  static const OVERRIDES = const AnalysisService('OVERRIDES', 5);

  static const List<AnalysisService> VALUES =
      const [HIGHLIGHTS, NAVIGATION, OCCURRENCES, OUTLINE, OVERRIDES];

  const AnalysisService(String name, int ordinal) : super(name, ordinal);
}


typedef void OptionUpdater(AnalysisOptionsImpl options);

/**
 * An enumeration of the services provided by the server domain.
 */
class ServerService extends Enum2<ServerService> {
  static const ServerService STATUS = const ServerService('STATUS', 0);

  static const List<ServerService> VALUES = const [STATUS];

  const ServerService(String name, int ordinal) : super(name, ordinal);
}
