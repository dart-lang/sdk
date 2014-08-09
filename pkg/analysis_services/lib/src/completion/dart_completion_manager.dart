// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/completion/top_level_computer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Manages code completion for a given Dart file completion request.
 */
class DartCompletionManager extends CompletionManager {
  final AnalysisContext context;
  final Source source;
  final int offset;
  final SearchEngine searchEngine;
  final List<CompletionSuggestion> suggestions = [];
  List<CompletionComputer> computers;

  DartCompletionManager(this.context, this.source, this.offset,
      this.searchEngine);

  @override
  void compute() {
    initComputers();
    computeFast();
    if (!computers.isEmpty) {
      computeFull();
    }
  }

  /**
   * Compute suggestions based upon cached information only
   * then send an initial response to the client.
   */
  void computeFast() {
    CompilationUnit unit = context.parseCompilationUnit(source);
    computers.removeWhere((c) => c.computeFast(unit, suggestions));
    sendResults(computers.isEmpty);
  }

  /**
   * If there is remaining work to be done, then wait for the unit to be
   * resolved and request that each remaining computer finish their work.
   */
  void computeFull() {
    waitForAnalysis().then((CompilationUnit unit) {
      if (unit == null) {
        sendResults(true);
        return;
      }
      int count = computers.length;
      computers.forEach((c) {
        c.computeFull(unit, suggestions).then((bool changed) {
          var last = --count == 0;
          if (changed || last) {
            sendResults(last);
          }
        });
      });
    });
  }

  /**
   * Build and initialize the list of completion computers
   */
  void initComputers() {
    if (computers == null) {
      computers = [new TopLevelComputer()];
    }
    computers.forEach((CompletionComputer c) {
      c.context = context;
      c.source = source;
      c.offset = offset;
      c.searchEngine = searchEngine;
    });
  }

  /**
   * Send the current list of suggestions to the client.
   */
  void sendResults(bool last) {
    controller.add(new CompletionResult(offset, 0, suggestions, last));
    if (last) {
      controller.close();
    }
  }

  /**
   * Wait for analysis to be complete and return the resolved unit
   * or `null` if the unit could not be resolved.
   */
  Future<CompilationUnit> waitForAnalysis() {
    LibraryElement library = context.getLibraryElement(source);
    if (library != null) {
      var unit = context.getResolvedCompilationUnit(source, library);
      if (unit != null) {
        return new Future.value(unit);
      }
    }
    //TODO (danrubel) Determine if analysis is complete but unit not resolved
    return new Future(waitForAnalysis);
  }
}
