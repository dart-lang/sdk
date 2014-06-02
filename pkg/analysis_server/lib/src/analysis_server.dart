// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';

import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/context_directory_manager.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_queue.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analysis_server/src/computers.dart';
import 'package:analyzer/src/generated/java_engine.dart';


/**
 * An instance of [DirectoryBasedDartSdk] that is shared between
 * [AnalysisServer] instances to improve performance.
 */
final DirectoryBasedDartSdk SHARED_SDK = DirectoryBasedDartSdk.defaultSdk;

class AnalysisServerContextDirectoryManager extends ContextDirectoryManager {
  final AnalysisServer analysisServer;

  AnalysisServerContextDirectoryManager(this.analysisServer, ResourceProvider resourceProvider)
      : super(resourceProvider);

  void addContext(Folder folder, File pubspecFile) {
    ContextDirectory contextDirectory = new ContextDirectory(
        analysisServer.defaultSdk, folder, pubspecFile);
    analysisServer.folderMap[folder] = contextDirectory;
    analysisServer.schedulePerformAnalysisOperation(contextDirectory.context);
  }

  void applyChangesToContext(Folder contextFolder, ChangeSet changeSet) {
    analysisServer.folderMap[contextFolder].context.applyChanges(changeSet);
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
   * [ContextDirectoryManager] which handles the mapping from analysis roots
   * to context directories.
   */
  AnalysisServerContextDirectoryManager contextDirectoryManager;

  /**
   * A flag indicating whether the server is running.  When false, contexts
   * will no longer be added to [contextWorkQueue], and [performOperation] will
   * discard any tasks it finds on [contextWorkQueue].
   */
  bool running;

  /**
   * A list of the request handlers used to handle the requests sent to this
   * server.
   */
  List<RequestHandler> handlers;

  /**
   * The current default [DartSdk].
   */
  DartSdk defaultSdk = SHARED_SDK;

  /**
   * A table mapping [Folder]s to the [ContextDirectory]s associated with them.
   */
  final Map<Folder, ContextDirectory> folderMap = <Folder, ContextDirectory>{};

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
  Set<ServerService> serverServices = new Set<ServerService>();

  /**
   * A table mapping [AnalysisService]s to the file paths for which these
   * notifications should be sent.
   */
  Map<AnalysisService, Set<String>> analysisServices = <AnalysisService, Set<String>>{};

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
  AnalysisServer(this.channel, ResourceProvider resourceProvider,
      {this.rethrowExceptions: true}) {
    operationQueue = new ServerOperationQueue(this);
    contextDirectoryManager = new AnalysisServerContextDirectoryManager(this, resourceProvider);
    AnalysisEngine.instance.logger = new AnalysisLogger();
    running = true;
    Notification notification = new Notification(NOTIFICATION_CONNECTED);
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
  }

  /**
   * Schedules analysis of the given context.
   */
  void schedulePerformAnalysisOperation(AnalysisContext context) {
    scheduleOperation(new PerformAnalysisOperation(context, false));
  }

  /**
   * Schedules execution of the given [ServerOperation].
   */
  void scheduleOperation(ServerOperation operation) {
    bool wasEmpty = operationQueue.isEmpty;
    operationQueue.add(operation);
    if (wasEmpty) {
      _schedulePerformOperation();
    }
  }

  /**
   * The socket from which requests are being read has been closed.
   */
  void done() {
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
   * Handle a [request] that was read from the communication channel.
   */
  void handleRequest(Request request) {
    int count = handlers.length;
    for (int i = 0; i < count; i++) {
      try {
        Response response = handlers[i].handleRequest(request);
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
    } finally {
      if (!operationQueue.isEmpty) {
        _schedulePerformOperation();
      } else {
        sendStatusNotification(null);
      }
    }
  }

  /**
   * Perform analysis in the given [AnalysisContext].
   */
  void internalPerformAnalysis(AnalysisContext context) {
    //
    // TODO(brianwilkerson) Add an optional function-valued parameter to
    // performAnalysisTask that will be called when the task has been computed
    // but before it is performed and send notification in the function:
    //
    // AnalysisResult result = context.performAnalysisTask((taskDescription) {
    //   sendStatusNotification(context.toString(), taskDescription);
    // });
    // prepare results
    AnalysisResult result = context.performAnalysisTask();
    List<ChangeNotice> notices = result.changeNotices;
    if (notices == null) {
      return;
    }
    // TODO(scheglov) remember known sources
    // TODO(scheglov) index units
    // TODO(scheglov) schedule notifications
    sendNotices(notices);
    // continue analysis
    operationQueue.add(new PerformAnalysisOperation(context, true));
  }

  /**
   * Send the information in the given list of notices back to the client.
   */
  void sendNotices(List<ChangeNotice> notices) {
    for (int i = 0; i < notices.length; i++) {
      ChangeNotice notice = notices[i];
      Source source = notice.source;
      CompilationUnit dartUnit = notice.compilationUnit;
      // TODO(scheglov) use default subscriptions
      String file = source.fullName;
      if (dartUnit != null) {
        Set<String> files = analysisServices[AnalysisService.HIGHLIGHTS];
        if (files != null && files.contains(file)) {
          sendAnalysisNotificationHighlights(file, dartUnit);
        }
      }
      if (!source.isInSystemLibrary) {
        // errors
        sendAnalysisNotificationErrors(file, notice.errors);
      }
    }
  }

  void sendAnalysisNotificationErrors(String file, List<AnalysisError> errors) {
    Notification notification = new Notification(NOTIFICATION_ERRORS);
    notification.setParameter(FILE, file);
    notification.setParameter(ERRORS, errors.map(errorToJson).toList());
    sendNotification(notification);
  }

  void sendAnalysisNotificationHighlights(String file, CompilationUnit dartUnit) {
    Notification notification = new Notification(NOTIFICATION_HIGHLIGHTS);
    notification.setParameter(FILE, file);
    notification.setParameter(
        REGIONS,
        new DartUnitHighlightsComputer(dartUnit).compute());
    sendNotification(notification);
  }

  /**
   * Send status notification to the client. The `contextId` indicates
   * the current context being analyzed or `null` if analysis is complete.
   */
  void sendStatusNotification(String contextId) {
//    if (contextId == lastStatusNotificationContextId) {
//      return;
//    }
//    lastStatusNotificationContextId = contextId;
    Notification notification = new Notification(NOTIFICATION_STATUS);
    Map<String, Object> analysis = new Map();
    if (contextId != null) {
      analysis['analyzing'] = true;
      // TODO(danrubel): replace contextId with real analysisTarget
      analysis['analysisTarget'] = contextId;
    } else {
      analysis['analyzing'] = false;
    }
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
      AnalysisContext analysisContext = _getAnalysisContext(file);
      if (analysisContext != null) {
        Source source = _getSource(file);
        if (change.offset == null) {
          analysisContext.setContents(source, change.content);
        } else {
          analysisContext.setChangedContents(source, change.content,
              change.offset, change.oldLength, change.newLength);
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
        if (service == AnalysisService.ERRORS) {
          Source source = _getSource(file);
          AnalysisContext analysisContext = _getAnalysisContext(file);
          List<AnalysisError> errors = analysisContext.getErrors(source).errors;
          sendAnalysisNotificationErrors(file, errors);
        }
        if (service == AnalysisService.HIGHLIGHTS) {
          CompilationUnit dartUnit = test_getResolvedCompilationUnit(file);
          if (dartUnit != null) {
            sendAnalysisNotificationHighlights(file, dartUnit);
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
  AnalysisContext _getAnalysisContext(String path) {
    for (Folder folder in folderMap.keys) {
      if (path.startsWith(folder.path)) {
        return folderMap[folder].context;
      }
    }
    return null;
  }

  /**
   * Return the [Source] of the Dart file with the given [path].
   */
  Source _getSource(String path) {
    File file = contextDirectoryManager.resourceProvider.getResource(path);
    return file.createSource(UriKind.FILE_URI);
  }

  /**
   * Return the [CompilationUnit] of the Dart file with the given [path].
   * Return `null` if the file is not a part of any context.
   */
  CompilationUnit test_getResolvedCompilationUnit(String path) {
    // prepare AnalysisContext
    AnalysisContext context = _getAnalysisContext(path);
    if (context == null) {
      return null;
    }
    // prepare sources
    Source unitSource = _getSource(path);
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

  static Map<String, Object> errorToJson(AnalysisError analysisError) {
    // TODO(paulberry): move this function into the AnalysisError class.
    ErrorCode errorCode = analysisError.errorCode;
    Map<String, Object> result = {
      'file': analysisError.source.fullName,
      // TODO(scheglov) add Enum.fullName ?
      'errorCode': '${errorCode.runtimeType}.${(errorCode as Enum).name}',
      'offset': analysisError.offset,
      'length': analysisError.length,
      'message': analysisError.message
    };
    if (analysisError.correction != null) {
      result['correction'] = analysisError.correction;
    }
    return result;
  }

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification) {
    channel.sendNotification(notification);
  }

  /**
   * Schedules [performOperation] exection.
   */
  void _schedulePerformOperation() {
    new Future(performOperation);
  }
}


/**
 * An enumeration of the services provided by the analysis domain.
 */
class AnalysisService extends Enum2<AnalysisService> {
  static const AnalysisService ERRORS = const AnalysisService('ERRORS', 0);
  static const AnalysisService HIGHLIGHTS = const AnalysisService('HIGHLIGHTS', 1);
  static const AnalysisService NAVIGATION = const AnalysisService('NAVIGATION', 2);
  static const AnalysisService OUTLINE = const AnalysisService('OUTLINE', 3);

  static const List<AnalysisService> VALUES =
      const [ERRORS, HIGHLIGHTS, NAVIGATION, OUTLINE];

  const AnalysisService(String name, int ordinal) : super(name, ordinal);
}


/**
 * Instances of [ContextDirectory] represents a [Folder] associated with an
 * analysis context.  The folder may or may not contain a Pub `pubspec.yaml`.
 *
 * TODO(scheglov) implement complete projects/contexts semantics.
 *
 * This class is intentionally simplified to serve as a base to start working
 * on services while work on complete semantics is being done in parallel.
 */
class ContextDirectory {
  /**
   * The root [Folder] of this [ContextDirectory].
   */
  final Folder _folder;

  /**
   * The `pubspec.yaml` file in [_folder], or null if there isn't one.
   */
  File _pubspecFile;

  /**
   * The [AnalysisContext] of this [_folder].
   */
  AnalysisContext _context;

  ContextDirectory(DartSdk sdk, this._folder, this._pubspecFile) {
    // create AnalysisContext
    _context = AnalysisEngine.instance.createAnalysisContext();
    // TODO(scheglov) replace FileUriResolver with an Resource based resolver
    // TODO(scheglov) create packages resolver
    _context.sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new FileUriResolver(),
      // new PackageUriResolver(),
    ]);
  }

  /**
   * Return the [AnalysisContext] of this folder.
   */
  AnalysisContext get context => _context;
}


/**
 * An enumeration of the services provided by the server domain.
 */
class ServerService extends Enum2<ServerService> {
  static const ServerService STATUS = const ServerService('STATUS', 0);

  static const List<ServerService> VALUES = const [STATUS];

  const ServerService(String name, int ordinal) : super(name, ordinal);
}
