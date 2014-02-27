// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis.server;

import 'dart:async';

import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';

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
   * The name of the parameter whose value is a list of errors.
   */
  static const String ERRORS_PARAM = 'errors';

  /**
   * The name of the parameter whose value is a source.
   */
  static const String SOURCE_PARAM = 'source';

  /**
   * The channel from which requests are received and to which responses should
   * be sent.
   */
  final ServerCommunicationChannel channel;

  /**
   * A flag indicating whether the server is running.
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
   * A list of the analysis contexts for which analysis work needs to be
   * performed.
   */
  final List<AnalysisContext> contextWorkQueue = new List<AnalysisContext>();

  /**
   * Initialize a newly created server to receive requests from and send
   * responses to the given [channel].
   */
  AnalysisServer(this.channel) {
    AnalysisEngine.instance.logger = new AnalysisLogger();
    running = true;
    // TODO set running=false on done or error
    channel.listen(handleRequest);
  }

  /**
   * Add the given [context] to the list of analysis contexts for which analysis
   * work needs to be performed. Ensure that the work will be performed.
   */
  void addContextToWorkQueue(AnalysisContext context) {
    if (!contextWorkQueue.contains(context)) {
      contextWorkQueue.add(context);
      run();
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
  void error() {
    running = false;
  }

  /**
   * Handle a [request] that was read from the communication channel.
   */
  void handleRequest(Request request) {
    int count = handlers.length;
    for (int i = 0; i < count; i++) {
      Response response = handlers[i].handleRequest(request);
      if (response != null) {
        channel.sendResponse(response);
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
    //
    // Look for a context that has work to be done and then perform one task.
    //
    if (!contextWorkQueue.isEmpty) {
      AnalysisContext context = contextWorkQueue[0];
      AnalysisResult result = context.performAnalysisTask();
      List<ChangeNotice> notices = result.changeNotices;
      if (notices == null) {
        contextWorkQueue.removeAt(0);
      } else { //if (context.analysisOptions.provideErrors) {
        sendNotices(notices);
      }
    }
    //
    // Schedule this method to be run again if there is any more work to be done.
    //
    if (contextWorkQueue.isEmpty) {
      running = false;
    } else {
      new Future(performTask).catchError((exception, stackTrace) {
        AnalysisEngine.instance.logger.logError3(exception);
      });
    }
  }

  /**
   * Send the information in the given list of notices back to the client.
   */
  void sendNotices(List<ChangeNotice> notices) {
    for (int i = 0; i < notices.length; i++) {
      ChangeNotice notice = notices[i];
      Notification notification = new Notification(ERROR_NOTIFICATION_NAME);
      notification.setParameter(SOURCE_PARAM, notice.source.encoding);
      notification.setParameter(ERRORS_PARAM, notice.errors);
      sendNotification(notification);
    }
  }

  /**
   * Perform the tasks that are waiting for execution until the server is shut
   * down.
   */
  void run() {
    if (!running) {
      running = true;
      Timer.run(() {
        performTask();
      });
    }
  }

  /**
   * Send the given [notification] to the client.
   */
  void sendNotification(Notification notification) {
    channel.sendNotification(notification);
  }
}
