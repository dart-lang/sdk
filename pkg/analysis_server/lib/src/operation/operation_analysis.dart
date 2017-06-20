// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_highlights.dart';
import 'package:analysis_server/src/computer/computer_highlights2.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/domains/analysis/implemented_dart.dart';
import 'package:analysis_server/src/domains/analysis/navigation.dart';
import 'package:analysis_server/src/domains/analysis/occurrences.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Run the given function [f] with the given [context] made active.
 * Return the result of [f] invocation.
 */
runWithActiveContext(AnalysisContext context, f()) {
  if (context is InternalAnalysisContext && !context.isActive) {
    context.isActive = true;
    try {
      return f();
    } finally {
      context.isActive = false;
    }
  } else {
    return f();
  }
}

Future<Null> scheduleImplementedNotification(
    AnalysisServer server, Iterable<String> files) async {
  SearchEngine searchEngine = server.searchEngine;
  if (searchEngine == null) {
    return;
  }
  for (String file in files) {
    CompilationUnit unit = await server.getResolvedCompilationUnit(file);
    CompilationUnitElement unitElement = unit?.element;
    if (unitElement != null) {
      try {
        ImplementedComputer computer =
            new ImplementedComputer(searchEngine, unitElement);
        await computer.compute();
        var params = new protocol.AnalysisImplementedParams(
            file, computer.classes, computer.members);
        server.sendNotification(params.toNotification());
      } catch (exception, stackTrace) {
        server.sendServerErrorNotification(
            'Failed to send analysis.implemented notification.',
            exception,
            stackTrace);
      }
    }
  }
}

/**
 * Schedules indexing of the given [file] using the resolved [dartUnit].
 */
void scheduleIndexOperation(
    AnalysisServer server, String file, CompilationUnit dartUnit) {
  if (server.index != null) {
    AnalysisContext context =
        resolutionMap.elementDeclaredByCompilationUnit(dartUnit).context;
    server.addOperation(new _DartIndexOperation(context, file, dartUnit));
  }
}

/**
 * Schedules sending notifications for the given [file] using the resolved
 * [resolvedDartUnit].
 */
void scheduleNotificationOperations(
    AnalysisServer server,
    Source source,
    String file,
    LineInfo lineInfo,
    AnalysisContext context,
    CompilationUnit parsedDartUnit,
    CompilationUnit resolvedDartUnit,
    List<AnalysisError> errors) {
  // If the file belongs to any analysis root, check whether we're in it now.
  AnalysisContext containingContext = server.getContainingContext(file);
  if (containingContext != null && context != containingContext) {
    return;
  }
  // Dart
  CompilationUnit dartUnit = resolvedDartUnit ?? parsedDartUnit;
  if (resolvedDartUnit != null) {
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.HIGHLIGHTS, file)) {
      server.scheduleOperation(
          new _DartHighlightsOperation(context, file, resolvedDartUnit));
    }
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.NAVIGATION, file)) {
      server.scheduleOperation(new NavigationOperation(context, source));
    }
    if (server.hasAnalysisSubscription(
        protocol.AnalysisService.OCCURRENCES, file)) {
      server.scheduleOperation(new OccurrencesOperation(context, source));
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
      SourceKind sourceKind = context.getKindOf(source);
      server.scheduleOperation(new _DartOutlineOperation(
          context, file, lineInfo, sourceKind, dartUnit));
    }
  }
  // errors
  if (server.shouldSendErrorsNotificationFor(file)) {
    server.scheduleOperation(
        new _NotificationErrorsOperation(context, file, lineInfo, errors));
  }
}

void sendAnalysisNotificationAnalyzedFiles(AnalysisServer server) {
  _sendNotification(server, () {
    Set<String> analyzedFiles = server.driverMap.values
        .map((driver) => driver.knownFiles)
        .expand((files) => files)
        .toSet();
    Set<String> prevAnalyzedFiles = server.prevAnalyzedFiles;
    if (prevAnalyzedFiles != null &&
        prevAnalyzedFiles.length == analyzedFiles.length &&
        prevAnalyzedFiles.difference(analyzedFiles).isEmpty) {
      // No change to the set of analyzed files.  No need to send another
      // notification.
      return;
    }
    server.prevAnalyzedFiles = analyzedFiles;
    protocol.AnalysisAnalyzedFilesParams params =
        new protocol.AnalysisAnalyzedFilesParams(analyzedFiles.toList());
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationErrors(
    AnalysisServer server,
    AnalysisContext context,
    String file,
    LineInfo lineInfo,
    List<AnalysisError> errors) {
  _sendNotification(server, () {
    if (errors == null) {
      errors = <AnalysisError>[];
    }
    AnalysisOptions analysisOptions = context.analysisOptions;
    var serverErrors = protocol.doAnalysisError_listFromEngine(
        analysisOptions, lineInfo, errors);
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
    List<protocol.HighlightRegion> regions;
    if (server.options.useAnalysisHighlight2) {
      regions = new DartUnitHighlightsComputer2(dartUnit).compute();
    } else {
      regions = new DartUnitHighlightsComputer(dartUnit).compute();
    }
    var params = new protocol.AnalysisHighlightsParams(file, regions);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationNavigation(
    AnalysisServer server, AnalysisContext context, Source source) {
  _sendNotification(server, () {
    NavigationCollectorImpl collector =
        computeNavigation(server, context, source, null, null);
    String file = source.fullName;
    var params = new protocol.AnalysisNavigationParams(
        file, collector.regions, collector.targets, collector.files);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationOccurrences(
    AnalysisServer server, AnalysisContext context, Source source) {
  _sendNotification(server, () {
    OccurrencesCollectorImpl collector =
        computeOccurrences(server, context, source);
    String file = source.fullName;
    var params =
        new protocol.AnalysisOccurrencesParams(file, collector.allOccurrences);
    server.sendNotification(params.toNotification());
  });
}

void sendAnalysisNotificationOutline(AnalysisServer server, String file,
    LineInfo lineInfo, SourceKind sourceKind, CompilationUnit dartUnit) {
  _sendNotification(server, () {
    // compute FileKind
    protocol.FileKind fileKind = protocol.FileKind.LIBRARY;
    if (sourceKind == SourceKind.LIBRARY) {
      fileKind = protocol.FileKind.LIBRARY;
    } else if (sourceKind == SourceKind.PART) {
      fileKind = protocol.FileKind.PART;
    }
    // compute library name
    String libraryName = _computeLibraryName(dartUnit);
    // compute Outline
    var computer = new DartUnitOutlineComputer(file, lineInfo, dartUnit);
    protocol.Outline outline = computer.compute();
    // send notification
    var params = new protocol.AnalysisOutlineParams(file, fileKind, outline,
        libraryName: libraryName);
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

String _computeLibraryName(CompilationUnit unit) {
  for (Directive directive in unit.directives) {
    if (directive is LibraryDirective && directive.name != null) {
      return directive.name.name;
    }
  }
  for (Directive directive in unit.directives) {
    if (directive is PartOfDirective && directive.libraryName != null) {
      return directive.libraryName.name;
    }
  }
  return null;
}

/**
 * Runs the given notification producing function [f], catching exceptions.
 */
void _sendNotification(AnalysisServer server, f()) {
  ServerPerformanceStatistics.notices.makeCurrentWhile(() {
    try {
      f();
    } catch (exception, stackTrace) {
      server.sendServerErrorNotification(
          'Failed to send notification', exception, stackTrace);
    }
  });
}

class NavigationOperation extends _NotificationOperation
    implements MergeableOperation {
  NavigationOperation(AnalysisContext context, Source source)
      : super(context, source);

  @override
  bool merge(ServerOperation other) {
    return other is NavigationOperation &&
        other.context == context &&
        other.source == source;
  }

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationNavigation(server, context, source);
  }
}

class OccurrencesOperation extends _NotificationOperation
    implements MergeableOperation {
  OccurrencesOperation(AnalysisContext context, Source source)
      : super(context, source);

  @override
  bool merge(ServerOperation other) {
    return other is OccurrencesOperation &&
        other.context == context &&
        other.source == source;
  }

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationOccurrences(server, context, source);
  }
}

/**
 * Instances of [PerformAnalysisOperation] perform a single analysis task.
 */
class PerformAnalysisOperation extends ServerOperation {
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

  bool get _isPriorityContext =>
      context is InternalAnalysisContext &&
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
      _setContextActive(true);
    }
    // prepare results
    AnalysisResult result = context.performAnalysisTask();
    List<ChangeNotice> notices = result.changeNotices;
    // nothing to analyze
    if (notices == null) {
      server.scheduleCacheConsistencyValidation(context);
      _setContextActive(false);
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
      scheduleNotificationOperations(server, source, file, notice.lineInfo,
          context, parsedDartUnit, resolvedDartUnit, notice.errors);
      // done
      server.fileAnalyzed(notice);
    }
  }

  /**
   * Make the [context] active or idle.
   */
  void _setContextActive(bool active) {
    AnalysisContext context = this.context;
    if (context is InternalAnalysisContext) {
      context.isActive = active;
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
          scheduleIndexOperation(server, file, dartUnit);
        }
      } catch (exception, stackTrace) {
        server.sendServerErrorNotification(
            'Failed to index Dart file: $file', exception, stackTrace);
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
      try {
        server.index?.indexUnit(unit);
      } catch (exception, stackTrace) {
        server.sendServerErrorNotification(
            'Failed to index: $file', exception, stackTrace);
      }
    });
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

class _DartOutlineOperation extends _DartNotificationOperation {
  final LineInfo lineInfo;
  final SourceKind sourceKind;

  _DartOutlineOperation(AnalysisContext context, String file, this.lineInfo,
      this.sourceKind, CompilationUnit unit)
      : super(context, file, unit);

  @override
  void perform(AnalysisServer server) {
    sendAnalysisNotificationOutline(server, file, lineInfo, sourceKind, unit);
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
    sendAnalysisNotificationErrors(server, context, file, lineInfo, errors);
  }
}

abstract class _NotificationOperation extends SourceSensitiveOperation {
  final Source source;

  _NotificationOperation(AnalysisContext context, this.source) : super(context);

  @override
  ServerOperationPriority get priority {
    return ServerOperationPriority.ANALYSIS_NOTIFICATION;
  }

  @override
  bool shouldBeDiscardedOnSourceChange(Source source) {
    return source == this.source;
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
