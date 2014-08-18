// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library operation.analysis;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/computer/computer_navigation.dart';
import 'package:analysis_server/src/computer/computer_occurrences.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analysis_server/src/computer/error.dart' as server_prefix;


void sendAnalysisNotificationErrors(AnalysisServer server, String file,
    LineInfo lineInfo, List<AnalysisError> errors) {
  Notification notification = new Notification(ANALYSIS_ERRORS);
  notification.setParameter(FILE, file);
  notification.setParameter(
      ERRORS,
      server_prefix.engineErrorsToJson(lineInfo, errors));
  server.sendNotification(notification);
}


void sendAnalysisNotificationHighlights(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  Notification notification = new Notification(ANALYSIS_HIGHLIGHTS);
  notification.setParameter(FILE, file);
  notification.setParameter(
      REGIONS,
      new DartUnitHighlightsComputer(dartUnit).compute());
  server.sendNotification(notification);
}


void sendAnalysisNotificationNavigation(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  Notification notification = new Notification(ANALYSIS_NAVIGATION);
  notification.setParameter(FILE, file);
  notification.setParameter(
      REGIONS,
      new DartUnitNavigationComputer(dartUnit).compute());
  server.sendNotification(notification);
}


void sendAnalysisNotificationOccurrences(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  Notification notification = new Notification(ANALYSIS_OCCURRENCES);
  notification.setParameter(FILE, file);
  notification.setParameter(
      OCCURRENCES,
      new DartUnitOccurrencesComputer(dartUnit).compute());
  server.sendNotification(notification);
}


void sendAnalysisNotificationOutline(AnalysisServer server,
    AnalysisContext context, Source source, CompilationUnit dartUnit) {
  Notification notification = new Notification(ANALYSIS_OUTLINE);
  notification.setParameter(FILE, source.fullName);
  notification.setParameter(
      OUTLINE,
      new DartUnitOutlineComputer(context, source, dartUnit).compute());
  server.sendNotification(notification);
}


void sendAnalysisNotificationOverrides(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  Notification notification = new Notification(ANALYSIS_OVERRIDES);
  notification.setParameter(FILE, file);
  notification.setParameter(
      OVERRIDES,
      new DartUnitOverridesComputer(dartUnit).compute());
  server.sendNotification(notification);
}


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
      server.sendContextAnalysisDoneNotifications(context);
      return;
    }
    // process results
    sendNotices(server, notices);
    updateIndex(server.index, notices);
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
      String file = source.fullName;
      // Dart
      CompilationUnit dartUnit = notice.compilationUnit;
      if (dartUnit != null) {
        if (server.hasAnalysisSubscription(AnalysisService.HIGHLIGHTS, file)) {
          sendAnalysisNotificationHighlights(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(AnalysisService.NAVIGATION, file)) {
          sendAnalysisNotificationNavigation(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(AnalysisService.OCCURRENCES, file)) {
          sendAnalysisNotificationOccurrences(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(AnalysisService.OUTLINE, file)) {
          sendAnalysisNotificationOutline(server, context, source, dartUnit);
        }
        if (server.hasAnalysisSubscription(AnalysisService.OVERRIDES, file)) {
          sendAnalysisNotificationOverrides(server, file, dartUnit);
        }
      }
      if (server.shouldSendErrorsNotificationFor(file)) {
        sendAnalysisNotificationErrors(
            server,
            file,
            notice.lineInfo,
            notice.errors);
      }
    }
  }

  void updateIndex(Index index, List<ChangeNotice> notices) {
    if (index == null) {
      return;
    }
    for (ChangeNotice notice in notices) {
      // Dart
      {
        CompilationUnit dartUnit = notice.compilationUnit;
        if (dartUnit != null) {
          index.indexUnit(context, dartUnit);
        }
      }
      // HTML
      {
        HtmlUnit htmlUnit = notice.htmlUnit;
        if (htmlUnit != null) {
          index.indexHtmlUnit(context, htmlUnit);
        }
      }
    }
  }
}
