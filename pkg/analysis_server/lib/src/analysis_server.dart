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
    analysisServer.addContextToWorkQueue(contextDirectory.context);
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
   * will no longer be added to [contextWorkQueue], and [performTask] will
   * discard any tasks it finds on [contextWorkQueue].
   */
  bool running;

  /**
   * A list of the request handlers used to handle the requests sent to this
   * server.
   */
  List<RequestHandler> handlers;

  // TODO(scheglov) remove once setAnalysisRoots() is completely implemented
//  /**
//   * A table mapping context id's to the analysis contexts associated with them.
//   */
//  final Map<String, AnalysisContext> contextMap = new Map<String, AnalysisContext>();
//
//  /**
//   * A table mapping analysis contexts to the context id's associated with them.
//   */
//  final Map<AnalysisContext, String> contextIdMap = new Map<AnalysisContext, String>();

  /**
   * The current default [DartSdk].
   */
  DartSdk defaultSdk = SHARED_SDK;

  /**
   * A table mapping [Folder]s to the [ContextDirectory]s associated with them.
   */
  final Map<Folder, ContextDirectory> folderMap = <Folder, ContextDirectory>{};

  /**
   * The context identifier used in the last status notification.
   */
  String lastStatusNotificationContextId = null;

  /**
   * A list of the analysis contexts for which analysis work needs to be
   * performed.
   *
   * Invariant: when this list is non-empty, there is exactly one pending call
   * to [performTask] on the event queue.  When this list is empty, there are
   * no calls to [performTask] on the event queue.
   */
  final List<AnalysisContext> contextWorkQueue = new List<AnalysisContext>();

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
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   */
  AnalysisServer(this.channel, ResourceProvider resourceProvider) {
    contextDirectoryManager = new AnalysisServerContextDirectoryManager(this, resourceProvider);
    AnalysisEngine.instance.logger = new AnalysisLogger();
    running = true;
    Notification notification = new Notification(NOTIFICATION_CONNECTED);
    channel.sendNotification(notification);
    channel.listen(handleRequest, onDone: done, onError: error);
  }

  /**
   * If [running] is true, add the given [context] to the list of analysis
   * contexts for which analysis work needs to be performed, and ensure that
   * the work will be performed.
   */
  void addContextToWorkQueue(AnalysisContext context) {
    if (!running) {
      return;
    }
    if (!contextWorkQueue.contains(context)) {
      contextWorkQueue.add(context);
      if (contextWorkQueue.length == 1) {
        // Work queue was previously empty, so schedule analysis.
        _scheduleTask();
      }
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
   * Perform the next available task. If a request was received that has not yet
   * been performed, perform it next. Otherwise, look for some analysis that
   * needs to be done and do that. Otherwise, do nothing.
   */
  void performTask() {
    if (!running) {
      // An error has occurred, or the connection to the client has been
      // closed, since performTask() was scheduled on the event queue.  So
      // don't do any analysis.  Instead clear the work queue.
      contextWorkQueue.clear();
    }
    if (contextWorkQueue.isEmpty) {
      // Nothing to do.
      return;
    }
    //
    // Look for a context that has work to be done and then perform one task.
    //
    List<ChangeNotice> notices = null;
    try {
      AnalysisContext context = contextWorkQueue[0];
      //
      // TODO(brianwilkerson) Add an optional function-valued parameter to
      // performAnalysisTask that will be called when the task has been computed
      // but before it is performed and send notification in the function:
      //
      // AnalysisResult result = context.performAnalysisTask((taskDescription) {
      //   sendStatusNotification(context.toString(), taskDescription);
      // });
      //
      sendStatusNotification(context.toString());
      AnalysisResult result = context.performAnalysisTask();
      notices = result.changeNotices;
    } finally {
      if (notices == null) {
        // Either we have no more work to do for this context, or there was an
        // unhandled exception trying to perform the analysis.  In either case,
        // remove the context form the work queue so we won't try to do more
        // analysis on it.
        contextWorkQueue.removeAt(0);
      } else {
        sendNotices(notices);
      }
      //
      // Schedule this method to be run again if there is any more work to be
      // done.
      //
      if (contextWorkQueue.isEmpty) {
        sendStatusNotification(null);
      } else {
        _scheduleTask();
      }
    }
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
    lastStatusNotificationContextId = contextId;
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
        addContextToWorkQueue(analysisContext);
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
   * Return `true` if all tasks are finished in this [AnalysisServer].
   */
  bool test_areTasksFinished() {
    return contextWorkQueue.isEmpty;
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

  void _scheduleTask() {
    new Future(performTask).catchError((ex, st) {
      AnalysisEngine.instance.logger.logError("${ex}\n${st}");
    });
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
