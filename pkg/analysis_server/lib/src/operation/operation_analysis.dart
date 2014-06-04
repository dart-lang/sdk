// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library operation.analysis;

import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/computer/computer_navigation.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Instances of [PerformAnalysisOperation] perform a single analysis task.
 */
class PerformAnalysisOperation extends ServerOperation {
  final AnalysisContext context;
  final bool isContinue;

  PerformAnalysisOperation(this.context, this.isContinue);

  @override
  ServerOperationPriority get priority {
    if (isContinue) {
      return ServerOperationPriority.ANALYSIS_CONTINUE;
    } else {
      return ServerOperationPriority.ANALYSIS;
    }
  }

  @override
  void perform(AnalysisServer server) {
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
    sendNotices(server, notices);
    // continue analysis
    server.addOperation(new PerformAnalysisOperation(context, true));
  }

  /**
   * Send the information in the given list of notices back to the client.
   */
  void sendNotices(AnalysisServer server, List<ChangeNotice> notices) {
    for (int i = 0; i < notices.length; i++) {
      ChangeNotice notice = notices[i];
      Source source = notice.source;
      CompilationUnit dartUnit = notice.compilationUnit;
      // TODO(scheglov) use default subscriptions
      String file = source.fullName;
      if (dartUnit != null) {
        if (server.hasAnalysisSubscription(AnalysisService.HIGHLIGHTS, file)) {
          sendAnalysisNotificationHighlights(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(AnalysisService.NAVIGATION, file)) {
          sendAnalysisNotificationNavigation(server, file, dartUnit);
        }
      }
      if (!source.isInSystemLibrary) {
        sendAnalysisNotificationErrors(server, file, notice.errors);
      }
    }
  }
}

void sendAnalysisNotificationErrors(AnalysisServer server,
                                    String file, List<AnalysisError> errors) {
  Notification notification = new Notification(NOTIFICATION_ERRORS);
  notification.setParameter(FILE, file);
  notification.setParameter(ERRORS, errors.map(errorToJson).toList());
  server.sendNotification(notification);
}

void sendAnalysisNotificationHighlights(AnalysisServer server,
                                        String file, CompilationUnit dartUnit) {
  Notification notification = new Notification(NOTIFICATION_HIGHLIGHTS);
  notification.setParameter(FILE, file);
  notification.setParameter(
      REGIONS,
      new DartUnitHighlightsComputer(dartUnit).compute());
  server.sendNotification(notification);
}

void sendAnalysisNotificationNavigation(AnalysisServer server,
                                        String file, CompilationUnit dartUnit) {
  Notification notification = new Notification(NOTIFICATION_NAVIGATION);
  notification.setParameter(FILE, file);
  notification.setParameter(
      REGIONS,
      new DartUnitNavigationComputer(dartUnit).compute());
  server.sendNotification(notification);
}

Map<String, Object> errorToJson(AnalysisError analysisError) {
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
