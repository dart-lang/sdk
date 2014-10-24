// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/protocol.dart' hide Element;
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/java_engine.dart';
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

  ServerContextManager(this.analysisServer, ResourceProvider resourceProvider,
      PackageMapProvider packageMapProvider)
      : super(resourceProvider, packageMapProvider);

  @override
  void addContext(Folder folder, UriResolver packageUriResolver) {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    analysisServer.folderMap[folder] = context;
    context.sourceFactory = _createSourceFactory(packageUriResolver);
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
    if (analysisServer.index != null) {
      analysisServer.index.removeContext(context);
    }
    analysisServer.sendContextAnalysisDoneNotifications(
        context,
        AnalysisDoneReason.CONTEXT_REMOVED);
  }

  @override
  void updateContextPackageUriResolver(Folder contextFolder,
                                       UriResolver packageUriResolver) {
    AnalysisContext context = analysisServer.folderMap[contextFolder];
    context.sourceFactory = _createSourceFactory(packageUriResolver);
    analysisServer.schedulePerformAnalysisOperation(context);
  }

  /**
   * Set up a [SourceFactory] that resolves packages using the given
   * [packageUriResolver].
   */
  SourceFactory _createSourceFactory(UriResolver packageUriResolver) {
    List<UriResolver> resolvers = <UriResolver>[
        new DartUriResolver(analysisServer.defaultSdk),
        new ResourceUriResolver(resourceProvider),
        packageUriResolver];
    return new SourceFactory(resolvers);
  }
}


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
  Map<AnalysisContext, Completer<AnalysisDoneReason>> contextAnalysisDoneCompleters =
      new HashMap<AnalysisContext, Completer<AnalysisDoneReason>>();

  /**
   * The controller that is notified when analysis is started.
   */
  StreamController<AnalysisContext> _onAnalysisStartedController;

  /**
   * The controller that is notified when analysis is complete.
   */
  StreamController _onAnalysisCompleteController;

  /**
   * The controller that is notified when a single file has been analyzed.
   */
  StreamController<ChangeNotice> _onFileAnalyzedController;

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
    contextDirectoryManager =
        new ServerContextManager(this, resourceProvider, packageMapProvider);
    AnalysisEngine.instance.logger = new AnalysisLogger();
    _onAnalysisStartedController = new StreamController.broadcast();
    _onAnalysisCompleteController = new StreamController.broadcast();
    _onFileAnalyzedController = new StreamController.broadcast();
    running = true;
    Notification notification = new ServerConnectedParams().toNotification();
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
  }

  /**
   * If the given notice applies to a file contained within an analysis root,
   * notify interested parties that the file has been (at least partially)
   * analyzed.
   */
  void fileAnalyzed(ChangeNotice notice) {
    if (contextDirectoryManager.isInAnalysisRoot(notice.source.fullName)) {
      _onFileAnalyzedController.add(notice);
    }
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
    _onAnalysisStartedController.add(context);
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
      throw new RequestFailure(
          new Response.unanalyzedPriorityFiles(request, buffer.toString()));
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
      AnalysisOptionsImpl options =
          new AnalysisOptionsImpl.con1(context.analysisOptions);
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
   * The stream that is notified when analysis of a context is started.
   */
  Stream<AnalysisContext> get onAnalysisStarted {
    return _onAnalysisStartedController.stream;
  }

  /**
   * The stream that is notified when analysis is complete.
   */
  Stream get onAnalysisComplete => _onAnalysisCompleteController.stream;

  /**
   * The stream that is notified when a single file has been analyzed.
   */
  Stream get onFileAnalyzed => _onFileAnalyzedController.stream;

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
    runZoned(() {
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
          RequestError error =
              new RequestError(RequestErrorCode.SERVER_ERROR, exception);
          if (stackTrace != null) {
            error.stackTrace = stackTrace.toString();
          }
          Response response = new Response(request.id, error: error);
          channel.sendResponse(response);
          return;
        }
      }
      channel.sendResponse(new Response.unknownRequest(request));
    }, onError: _sendServerErrorNotification);
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
   * Return `true` if analysis is complete.
   */
  bool isAnalysisComplete() {
    return operationQueue.isEmpty;
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
        _onAnalysisCompleteController.add(null);
      }
    }
  }

  /**
   * Trigger reanalysis of all files from disk.
   */
  void reanalyze() {
    // Clear any operations that are pending.
    operationQueue.clear();
    // Instruct the contextDirectoryManager to rebuild all contexts from
    // scratch.
    contextDirectoryManager.refresh();
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
      contextDirectoryManager.setRoots(
          includedPaths,
          excludedPaths,
          packageRoots);
    } on UnimplementedError catch (e) {
      throw new RequestFailure(
          new Response.unsupportedFeature(requestId, e.message));
    }
  }

  /**
   * Implementation for `analysis.updateContent`.
   */
  void updateContent(String id, Map<String, dynamic> changes) {
    changes.forEach((file, change) {
      AnalysisContext analysisContext = getAnalysisContext(file);
      // TODO(paulberry): handle the case where a file is referred to by more
      // than one context (e.g package A depends on package B using a local
      // path, user has both packages open for editing in separate contexts,
      // and user modifies a file in package B).
      if (analysisContext != null) {
        Source source = getSource(file);
        if (change is AddContentOverlay) {
          analysisContext.setContents(source, change.content);
        } else if (change is ChangeContentOverlay) {
          // TODO(paulberry): an error should be generated if source is not
          // currently in the content cache.
          TimestampedData<String> oldContents =
              analysisContext.getContents(source);
          String newContents;
          try {
            newContents =
                SourceEdit.applySequence(oldContents.data, change.edits);
          } on RangeError {
            throw new RequestFailure(
                new Response(
                    id,
                    error: new RequestError(
                        RequestErrorCode.INVALID_OVERLAY_CHANGE,
                        'Invalid overlay change')));
          }
          // TODO(paulberry): to aid in incremental processing it would be
          // better to use setChangedContents.
          analysisContext.setContents(source, newContents);
        } else if (change is RemoveContentOverlay) {
          analysisContext.setContents(source, null);
        } else {
          // Protocol parsing should have ensured that we never get here.
          throw new AnalysisException('Illegal change type');
        }
        schedulePerformAnalysisOperation(analysisContext);
      }
    });
  }

  /**
   * Implementation for `analysis.setSubscriptions`.
   */
  void setAnalysisSubscriptions(Map<AnalysisService,
      Set<String>> subscriptions) {
    // send notifications for already analyzed sources
    subscriptions.forEach((service, Set<String> newFiles) {
      Set<String> oldFiles = analysisServices[service];
      Set<String> todoFiles =
          oldFiles != null ? newFiles.difference(oldFiles) : newFiles;
      for (String file in todoFiles) {
        Source source = getSource(file);
        // prepare context
        AnalysisContext context = getAnalysisContext(file);
        if (context == null) {
          continue;
        }
        // Dart unit notifications.
        if (AnalysisEngine.isDartFileName(file)) {
          CompilationUnit dartUnit =
              getResolvedCompilationUnitToResendNotification(file);
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
                LineInfo lineInfo = context.getLineInfo(source);
                sendAnalysisNotificationOutline(
                    this,
                    source,
                    lineInfo,
                    dartUnit);
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
   * Return the [AnalysisContext]s that are being used to analyze the analysis
   * roots.
   */
  Iterable<AnalysisContext> getAnalysisContexts() {
    return folderMap.values;
  }

  /**
   * Return the [AnalysisContext] that is used to analyze the given [path].
   * Return `null` if there is no such context.
   */
  AnalysisContext getAnalysisContext(String path) {
    // try to find a containing context
    for (Folder folder in folderMap.keys) {
      if (folder.contains(path)) {
        return folderMap[folder];
      }
    }
    // check if there is a context that analyzed this source
    Source source = getSource(path);
    for (AnalysisContext context in folderMap.values) {
      SourceKind kind = context.getKindOf(source);
      if (kind != null) {
        return context;
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
    // prepare AnalysisContext
    AnalysisContext context = getAnalysisContext(file);
    if (context == null) {
      return null;
    }
    // prepare Source
    Source source = getSource(file);
    if (context.getKindOf(source) == SourceKind.UNKNOWN) {
      return null;
    }
    // get errors for the file
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
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, librarySource);
      if (unit != null) {
        units.add(unit);
      }
    }
    // done
    return units;
  }

  /**
   * Returns resolved [AstNode]s at the given [offset] of the given [file].
   *
   * May be empty, but not `null`.
   */
  List<AstNode> getNodesAtOffset(String file, int offset) {
    List<CompilationUnit> units = getResolvedCompilationUnits(file);
    List<AstNode> nodes = <AstNode>[];
    for (CompilationUnit unit in units) {
      AstNode node = new NodeLocator.con1(offset).searchWithin(unit);
      if (node != null) {
        nodes.add(node);
      }
    }
    return nodes;
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
   * This method is called when analysis of the given [AnalysisContext] is
   * done.
   */
  void sendContextAnalysisDoneNotifications(AnalysisContext context,
      AnalysisDoneReason reason) {
    Completer<AnalysisDoneReason> completer =
        contextAnalysisDoneCompleters.remove(context);
    if (completer != null) {
      completer.complete(reason);
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
    channel.sendNotification(
        new ServerErrorParams(
            true,
            exceptionString,
            stackTraceString).toNotification());
  }
}

typedef void OptionUpdater(AnalysisOptionsImpl options);
