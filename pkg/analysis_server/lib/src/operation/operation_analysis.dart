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
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
    CompilationUnit unit = server.getCachedAnalysisResult(file)?.unit;
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
