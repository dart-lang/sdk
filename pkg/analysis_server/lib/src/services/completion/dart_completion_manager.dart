// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/completion/imported_type_computer.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:analysis_server/src/services/completion/keyword_computer.dart';
import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The base class for computing code completion suggestions.
 */
abstract class DartCompletionComputer {
  /**
   * Computes the initial set of [CompletionSuggestion]s based on
   * the given completion context. The compilation unit and completion node
   * in the given completion context may not be resolved.
   * This method should execute quickly and not block waiting for any analysis.
   * Returns `true` if the computer's work is complete
   * or `false` if [computeFull] should be called to complete the work.
   */
  bool computeFast(DartCompletionRequest request);

  /**
   * Computes the complete set of [CompletionSuggestion]s based on
   * the given completion context.  The compilation unit and completion node
   * in the given completion context are resolved.
   * Returns `true` if the receiver modified the list of suggestions.
   */
  Future<bool> computeFull(DartCompletionRequest request);
}

/**
 * Manages code completion for a given Dart file completion request.
 */
class DartCompletionManager extends CompletionManager {
  final AnalysisContext context;
  final Source source;
  final int offset;
  DartCompletionRequest request;
  List<DartCompletionComputer> computers;

  DartCompletionManager(this.context, SearchEngine searchEngine, this.source,
      this.offset) {
    request = new DartCompletionRequest(context, searchEngine, source, offset);
  }

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
    request.unit = unit;
    request.node = new NodeLocator.con1(offset).searchWithin(unit);
    computers.removeWhere((DartCompletionComputer c) => c.computeFast(request));
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
      request.unit = unit;
      request.node = new NodeLocator.con1(offset).searchWithin(unit);
      int count = computers.length;
      computers.forEach((c) {
        c.computeFull(request).then((bool changed) {
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
      computers = [
          new KeywordComputer(),
          new LocalComputer(),
          new ImportedTypeComputer(),
          new InvocationComputer()];
    }
  }

  /**
   * Send the current list of suggestions to the client.
   */
  void sendResults(bool last) {
    controller.add(
        new CompletionResult(request.offset, 0, request.suggestions, last));
    if (last) {
      controller.close();
    }
  }

  /**
   * Return a future that completes when analysis is complete.
   * Return `true` if the compilation unit is be resolved.
   */
  Future<CompilationUnit> waitForAnalysis() {
    LibraryElement library = context.getLibraryElement(source);
    if (library != null) {
      CompilationUnit unit =
          context.getResolvedCompilationUnit(source, library);
      if (unit != null) {
        return new Future.value(unit);
      }
    }
    //TODO (danrubel) Determine if analysis is complete but unit not resolved
    return new Future(waitForAnalysis);
  }
}

/**
 * The context in which the completion is requested.
 */
class DartCompletionRequest {
  /**
   * The analysis context in which the completion is requested.
   */
  final AnalysisContext context;

  /**
   * The search engine for use when building suggestions.
   */
  final SearchEngine searchEngine;

  /**
   * The source in which the completion is requested.
   */
  final Source source;

  /**
   * The offset within the source at which the completion is requested.
   */
  final int offset;

  /**
   * The compilation unit in which the completion was requested. This unit
   * may or may not be resolved when [DartCompletionComputer.computeFast]
   * is called but is resolved when [DartCompletionComputer.computeFull].
   */
  CompilationUnit unit;

  /**
   * The node in which the completion occurred. This node
   * may or may not be resolved when [DartCompletionComputer.computeFast]
   * is called but is resolved when [DartCompletionComputer.computeFull].
   */
  AstNode node;

  /**
   * The list of suggestions to be sent to the client.
   */
  final List<CompletionSuggestion> suggestions = [];

  DartCompletionRequest(this.context, this.searchEngine, this.source,
      this.offset);
}
