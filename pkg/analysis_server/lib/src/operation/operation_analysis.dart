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
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/source.dart';


void sendAnalysisNotificationErrors(AnalysisServer server, String file,
    LineInfo lineInfo, List<AnalysisError> errors) {
  var serverErrors = protocol.doAnalysisError_listFromEngine(lineInfo, errors);
  var params = new protocol.AnalysisErrorsParams(file, serverErrors);
  server.sendNotification(params.toNotification());
}


void sendAnalysisNotificationHighlights(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  var regions = new DartUnitHighlightsComputer(dartUnit).compute();
  var params = new protocol.AnalysisHighlightsParams(file, regions);
  server.sendNotification(params.toNotification());
}


void sendAnalysisNotificationNavigation(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  var regions = new DartUnitNavigationComputer(dartUnit).compute();
  var params = new protocol.AnalysisNavigationParams(file, regions);
  server.sendNotification(params.toNotification());
}


void sendAnalysisNotificationOccurrences(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  var occurrences = new DartUnitOccurrencesComputer(dartUnit).compute();
  var params = new protocol.AnalysisOccurrencesParams(file, occurrences);
  server.sendNotification(params.toNotification());
}


void sendAnalysisNotificationOutline(AnalysisServer server, Source source,
    LineInfo lineInfo, CompilationUnit dartUnit) {
  var outline =
      new DartUnitOutlineComputer(source, lineInfo, dartUnit).compute();
  var params = new protocol.AnalysisOutlineParams(source.fullName, outline);
  server.sendNotification(params.toNotification());
}


void sendAnalysisNotificationOverrides(AnalysisServer server, String file,
    CompilationUnit dartUnit) {
  var overrides = new DartUnitOverridesComputer(dartUnit).compute();
  var params = new protocol.AnalysisOverridesParams(file, overrides);
  server.sendNotification(params.toNotification());
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
      server.sendContextAnalysisDoneNotifications(
          context,
          AnalysisDoneReason.COMPLETE);
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
        if (server.hasAnalysisSubscription(
            protocol.AnalysisService.HIGHLIGHTS,
            file)) {
          sendAnalysisNotificationHighlights(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(
            protocol.AnalysisService.NAVIGATION,
            file)) {
          sendAnalysisNotificationNavigation(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(
            protocol.AnalysisService.OCCURRENCES,
            file)) {
          sendAnalysisNotificationOccurrences(server, file, dartUnit);
        }
        if (server.hasAnalysisSubscription(
            protocol.AnalysisService.OUTLINE,
            file)) {
          LineInfo lineInfo = notice.lineInfo;
          sendAnalysisNotificationOutline(server, source, lineInfo, dartUnit);
        }
        if (server.hasAnalysisSubscription(
            protocol.AnalysisService.OVERRIDES,
            file)) {
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
      server.fileAnalyzed(notice);
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
