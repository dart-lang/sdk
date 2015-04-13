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

/**
 * Runs the given function [f] with the working cache size in [context].
 * Returns the result of [f] invocation.
 */
runWithWorkingCacheSize(AnalysisContext context, f()) {
  int currentCacheSize = context.analysisOptions.cacheSize;
  if (currentCacheSize < PerformAnalysisOperation.WORKING_CACHE_SIZE) {
    setCacheSize(context, PerformAnalysisOperation.WORKING_CACHE_SIZE);
    try {
      return f();
    } finally {
      setCacheSize(context, currentCacheSize);
    }
  } else {
    return f();
  }
}

/**
 * Schedules indexing of the given [file] using the resolved [dartUnit].
 */
void scheduleIndexOperation(AnalysisServer server, String file,
    AnalysisContext context, CompilationUnit dartUnit) {
  if (server.index != null) {
    server.addOperation(new _DartIndexOperation(context, file, dartUnit));
  }
}

/**
 * Schedules sending notifications for the given [file] using the resolved
 * [resolvedDartUnit].
 */
void scheduleNotificationOperations(AnalysisServer server, String file,
    LineInfo lineInfo, AnalysisContext context, CompilationUnit parsedDartUnit,
    CompilationUnit resolvedDartUnit, List<AnalysisError> errors) {
  // If the file belongs to any analysis root, check whether we're in it now.
  AnalysisContext containingContext = server.getContainingContext(file);
  if (containingContext != null && context != containingContext) {
    return;
  }
  // Dart
  CompilationUnit dartUnit =
      resolvedDartUnit != null ? resolvedDartUnit : parsedDartUnit;
  if (resolvedDartUnit != null) {
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.HIGHLIGHTS, file)) {
      server.scheduleOperation(
          new _DartHighlightsOperation(context, file, resolvedDartUnit));
    }
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.NAVIGATION, file)) {
      server.scheduleOperation(
          new _DartNavigationOperation(context, file, resolvedDartUnit));
    }
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.OCCURRENCES, file)) {
      server.scheduleOperation(
          new _DartOccurrencesOperation(context, file, resolvedDartUnit));
    }
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.OVERRIDES, file)) {
      server.scheduleOperation(
          new _DartOverridesOperation(context, file, resolvedDartUnit));
    }
  }
  if (dartUnit != null) {
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.OUTLINE, file)) {
      server.scheduleOperation(
          new _DartOutlineOperation(context, file, lineInfo, dartUnit));
    }
  }
  // errors
  if (server.shouldSendErrorsNotificationFor(file)) {
    server.scheduleOperation(
        new _NotificationErrorsOperation(context, file, lineInfo, errors));
  }
}

void sendAnalysisNotificationErrors(AnalysisServer server, String file,
    LineInfo lineInfo, List<AnalysisError> errors) {
  _sendNotification(server, () {
    if (errors == null) {
      errors = <AnalysisError>[];
    }
    var serverErrors =
        protocol.doAnalysisError_listFromEngine(lineInfo, errors);
    var params = new protocol.AnalysisErrorsParams(file, serverErrors);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationFlushResults(
    AnalysisServer server, List<String> files) {
  _sendNotification(server, () {
    if (files != null && files.isNotEmpty) {
      var params = new protocol.AnalysisFlushResultsParams(files);
      server.sendNotification(params.toNotification());
    }
  });
}

void sendAnalysisNotificationHighlights(
    AnalysisServer server, String file, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var regions = new DartUnitHighlightsComputer(dartUnit).compute();
    var params = new protocol.AnalysisHighlightsParams(file, regions);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationNavigation(
    AnalysisServer server, String file, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var computer = new DartUnitNavigationComputer(dartUnit);
    computer.compute();
    var params = new protocol.AnalysisNavigationParams(
        file, computer.regions, computer.targets, computer.files);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationOccurrences(
    AnalysisServer server, String file, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var occurrences = new DartUnitOccurrencesComputer(dartUnit).compute();
    var params = new protocol.AnalysisOccurrencesParams(file, occurrences);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationOutline(AnalysisServer server, String file,
    LineInfo lineInfo, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var computer = new DartUnitOutlineComputer(file, lineInfo, dartUnit);
    var outline = computer.compute();
    var params = new protocol.AnalysisOutlineParams(file, outline);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationOverrides(
    AnalysisServer server, String file, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    var overrides = new DartUnitOverridesComputer(dartUnit).compute();
    var params = new protocol.AnalysisOverridesParams(file, overrides);
    server.sendNotification(params.toNotification());
  });
}

/**
 * Sets the cache size in the given [context] to the given value.
 */
void setCacheSize(AnalysisContext context, int cacheSize) {
  AnalysisOptionsImpl options =
      new AnalysisOptionsImpl.con1(context.analysisOptions);
  options.cacheSize = cacheSize;
  context.analysisOptions = options;
}

/**
 * Runs the given notification producing function [f], catching exceptions.
 */
void _sendNotification(AnalysisServer server, f()) {
  ServerPerformanceStatistics.notices.makeCurrentWhile(() {
    try {
      f();
    } catch (exception, stackTrace) {
      server.sendServerErrorNotification(exception, stackTrace);
    }
  });
}

/**
 * Instances of [PerformAnalysisOperation] perform a single analysis task.
 */
class PerformAnalysisOperation extends ServerOperation {
  static const int IDLE_CACHE_SIZE = AnalysisOptionsImpl.DEFAULT_CACHE_SIZE;
  static const int WORKING_CACHE_SIZE = 512;

  final bool isContinue;

  PerformAnalysisOperation(AnalysisContext context, this.isContinue)
      : super(context);

  @override
  ServerOperationPriority get priority {
    if (_isPriorityContext) {
      if (isContinue) {
        return ServerOperationPriority.PRIORITY_ANALYSIS_CONTINUE;
      } else {
        return ServerOperationPriority.PRIORITY_ANALYSIS;
      }
    } else {
      if (isContinue) {
        return ServerOperationPriority.ANALYSIS_CONTINUE;
      } else {
        return ServerOperationPriority.ANALYSIS;
      }
    }
  }

  bool get _isPriorityContext => context is InternalAnalysisContext &&
      (context as InternalAnalysisContext).prioritySources.isNotEmpty;

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
    if (!isContinue) {
      setCacheSize(context, WORKING_CACHE_SIZE);
    }
    // prepare results
    AnalysisResult result = context.performAnalysisTask();
    List<ChangeNotice> notices = result.changeNotices;
    if (notices == null) {
      setCacheSize(context, IDLE_CACHE_SIZE);
      server.sendContextAnalysisDoneNotifications(
          context, AnalysisDoneReason.COMPLETE);
      return;
    }
    // process results
    ServerPerformanceStatistics.notices.makeCurrentWhile(() {
      _sendNotices(server, notices);
      _updateIndex(server, notices);
    });
    // continue analysis
    server.addOperation(new PerformAnalysisOperation(context, true));
  }

  /**
   * Send the information in the given list of notices back to the client.
   */
  void _sendNotices(AnalysisServer server, List<ChangeNotice> notices) {
    for (int i = 0; i < notices.length; i++) {
      ChangeNotice notice = notices[i];
      Source source = notice.source;
      String file = source.fullName;
      // Dart
      CompilationUnit parsedDartUnit = notice.parsedDartUnit;
      CompilationUnit resolvedDartUnit = notice.resolvedDartUnit;
      scheduleNotificationOperations(server, file, notice.lineInfo, context,
          parsedDartUnit, resolvedDartUnit, notice.errors);
      // done
      server.fileAnalyzed(notice);
    }
  }

  void _updateIndex(AnalysisServer server, List<ChangeNotice> notices) {
    if (server.index == null) {
      return;
    }
    for (ChangeNotice notice in notices) {
      String file = notice.source.fullName;
      // Dart
      try {
        CompilationUnit dartUnit = notice.resolvedDartUnit;
        if (dartUnit != null) {
          server.addOperation(new _DartIndexOperation(context, file, dartUnit));
        }
      } catch (exception, stackTrace) {
        server.sendServerErrorNotification(exception, stackTrace);
      }
      // HTML
      try {
        HtmlUnit htmlUnit = notice.resolvedHtmlUnit;
        if (htmlUnit != null) {
          server.addOperation(new _HtmlIndexOperation(context, file, htmlUnit));
        }
      } catch (exception, stackTrace) {
        server.sendServerErrorNotification(exception, stackTrace);
      }
    }
  }
}

class _DartHighlightsOperation extends _DartNotificationOperation {
  _DartHighlightsOperation(
      AnalysisContext context, String file, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationHighlights(server, file, unit);
  }
}

class _DartIndexOperation extends _SingleFileOperation {
  final CompilationUnit unit;

  _DartIndexOperation(AnalysisContext context, String file, this.unit)
      : super(context, file);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_INDEX;
  }

  @override
  void perform(AnalysisServer server) {
    ServerPerformanceStatistics.indexOperation.makeCurrentWhile(() {
      Index index = server.index;
      index.indexUnit(context, unit);
    });
  }
}

class _DartNavigationOperation extends _DartNotificationOperation {
  _DartNavigationOperation(
      AnalysisContext context, String file, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationNavigation(server, file, unit);
  }
}

abstract class _DartNotificationOperation extends _SingleFileOperation {
  final CompilationUnit unit;

  _DartNotificationOperation(AnalysisContext context, String file, this.unit)
      : super(context, file);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_NOTIFICATION;
  }
}

class _DartOccurrencesOperation extends _DartNotificationOperation {
  _DartOccurrencesOperation(
      AnalysisContext context, String file, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationOccurrences(server, file, unit);
  }
}

class _DartOutlineOperation extends _DartNotificationOperation {
  final LineInfo lineInfo;

  _DartOutlineOperation(
      AnalysisContext context, String file, this.lineInfo, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationOutline(server, file, lineInfo, unit);
  }
}

class _DartOverridesOperation extends _DartNotificationOperation {
  _DartOverridesOperation(
      AnalysisContext context, String file, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationOverrides(server, file, unit);
  }
}

class _HtmlIndexOperation extends _SingleFileOperation {
  final HtmlUnit unit;

  _HtmlIndexOperation(AnalysisContext context, String file, this.unit)
      : super(context, file);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_INDEX;
  }

  @override
  void perform(AnalysisServer server) {
    Index index = server.index;
    index.indexHtmlUnit(context, unit);
  }
}

class _NotificationErrorsOperation extends _SingleFileOperation {
  final LineInfo lineInfo;
  final List<AnalysisError> errors;

  _NotificationErrorsOperation(
      AnalysisContext context, String file, this.lineInfo, this.errors)
      : super(context, file);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_NOTIFICATION;
  }

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationErrors(server, file, lineInfo, errors);
  }
}

abstract class _SingleFileOperation extends SourceSensitiveOperation {
  final String file;

  _SingleFileOperation(AnalysisContext context, this.file) : super(context);

  @override
  bool shouldBeDiscardedOnSourceChange(Source source) {
    return source.fullName == file;
  }
}
