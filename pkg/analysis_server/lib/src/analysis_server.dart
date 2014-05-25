// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';

import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';

/**
 * Instances of the class [AnalysisServer] implement a server that listens on a
 * [CommunicationChannel] for analysis requests and process them.
 */
class AnalysisServer {
  /**
   * The name of the notification of new errors associated with a source.
   */
  static const String ERROR_NOTIFICATION_NAME = 'context.errors';

  /**
   * The name of the contextId parameter.
   */
  static const String CONTEXT_ID_PARAM = 'contextId';

  /**
   * The name of the parameter whose value is a list of errors.
   */
  static const String ERRORS_PARAM = 'errors';

  /**
   * The name of the parameter whose value is a source.
   */
  static const String SOURCE_PARAM = 'source';

  /**
   * The event name of the connected notification.
   */
  static const String CONNECTED_NOTIFICATION = 'server.connected';

  /**
   * The channel from which requests are received and to which responses should
   * be sent.
   */
  final ServerCommunicationChannel channel;

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

  /**
   * A table mapping context id's to the analysis contexts associated with them.
   */
  final Map<String, AnalysisContext> contextMap = new Map<String, AnalysisContext>();

  /**
   * A table mapping analysis contexts to the context id's associated with them.
   */
  final Map<AnalysisContext, String> contextIdMap = new Map<AnalysisContext, String>();

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
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   */
  AnalysisServer(this.channel) {
    AnalysisEngine.instance.logger = new AnalysisLogger();
    running = true;
    Notification notification = new Notification(CONNECTED_NOTIFICATION);
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
    String contextId;
    try {
      AnalysisContext context = contextWorkQueue[0];
      contextId = contextIdMap[context];
      AnalysisResult result = context.performAnalysisTask();
      notices = result.changeNotices;
    } finally {
      if (notices == null) {
        // Either we have no more work to do for this context, or there was an
        // unhandled exception trying to perform the analysis.  In either case,
        // remove the context form the work queue so we won't try to do more
        // analysis on it.
        contextWorkQueue.removeAt(0);
      }
      //
      // Schedule this method to be run again if there is any more work to be
      // done.
      //
      if (!contextWorkQueue.isEmpty) {
        _scheduleTask();
      }
    }
    if (notices != null) {
      sendNotices(contextId, notices);
    }
  }

  /**
   * Send the information in the given list of notices back to the client.
   */
  void sendNotices(String contextId, List<ChangeNotice> notices) {
    for (int i = 0; i < notices.length; i++) {
      ChangeNotice notice = notices[i];
      Notification notification = new Notification(ERROR_NOTIFICATION_NAME);
      notification.setParameter(CONTEXT_ID_PARAM, contextId);
      notification.setParameter(SOURCE_PARAM, notice.source.encoding);
      notification.setParameter(ERRORS_PARAM, notice.errors.map(
          errorToJson).toList());
      sendNotification(notification);
    }
  }

  static Map<String, Object> errorToJson(AnalysisError analysisError) {
    // TODO(paulberry): move this function into the AnalysisError class.

    // TODO(paulberry): we really shouldn't be exposing errorCode.ordinal
    // outside the analyzer, since the ordinal numbers change whenever we
    // regenerate the analysis engine.
    Map<String, Object> result = {
      'source': analysisError.source.encoding,
      'errorCode': (analysisError.errorCode as Enum).ordinal,
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
 * An enumeration of the services provided by the server domain.
 */
class ServerService extends Enum2<ServerService> {
  static const ServerService STATUS = const ServerService('STATUS', 0);

  static const List<ServerService> VALUES = const [STATUS];

  const ServerService(String name, int ordinal) : super(name, ordinal);
}
