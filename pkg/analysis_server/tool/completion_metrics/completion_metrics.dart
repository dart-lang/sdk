// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/available_declarations.dart';

import 'metrics_util.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: a single absolute file path to analyze.');
    io.exit(1);
  }
  await CompletionCoverageMetrics(args[0]).compute();
  io.exit(0);
}

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
abstract class AbstractCompletionMetricsComputer {
  // TODO(brianwilkerson) Consider merging this class into the single concrete
  //  subclass.
  final String _rootPath;

  String _currentFilePath;

  ResolvedUnitResult _resolvedUnitResult;

  AbstractCompletionMetricsComputer(this._rootPath);

  /// The path to the current file.
  String get currentFilePath => _currentFilePath;

  /// If the concrete class has this getter return true, then when
  /// [forEachExpectedCompletion] is called, the [List] of
  /// [CompletionSuggestion]s will be passed.
  bool get doComputeCompletionsFromAnalysisServer;

  /// The current [ResolvedUnitResult].
  ResolvedUnitResult get resolvedUnitResult => _resolvedUnitResult;

  /// The analysis root path that this CompletionMetrics class will be computed.
  String get rootPath => _rootPath;

  void compute() async {
    print('Analyzing root: \"$_rootPath\"');

    if (!io.Directory(_rootPath).existsSync()) {
      print('\tError: No such directory exists on this machine.\n');
      return;
    }

    final collection = AnalysisContextCollection(
      includedPaths: [_rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    for (var context in collection.contexts) {
      // Set the DeclarationsTracker, only call doWork to build up the available
      // suggestions if doComputeCompletionsFromAnalysisServer is true.
      var declarationsTracker = DeclarationsTracker(
          MemoryByteStore(), PhysicalResourceProvider.INSTANCE);
      declarationsTracker.addContext(context);
      if (doComputeCompletionsFromAnalysisServer) {
        while (declarationsTracker.hasWork) {
          declarationsTracker.doWork();
        }
      }

      // Loop through each file, resolve the file and call
      // forEachExpectedCompletion
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath)) {
          _currentFilePath = filePath;
          try {
            _resolvedUnitResult =
                await context.currentSession.getResolvedUnit(filePath);

            var error = getFirstErrorOrNull(resolvedUnitResult);
            if (error != null) {
              print('File $filePath skipped due to errors such as:');
              print('  ${error.toString()}');
              print('');
              continue;
            }

            // Use the ExpectedCompletionsVisitor to compute the set of expected
            // completions for this CompilationUnit.
            final visitor = ExpectedCompletionsVisitor();
            resolvedUnitResult.unit.accept(visitor);

            for (var expectedCompletion in visitor.expectedCompletions) {
              // Call forEachExpectedCompletion, passing in the computed
              // suggestions only if doComputeCompletionsFromAnalysisServer is
              // true:
              forEachExpectedCompletion(
                  expectedCompletion,
                  doComputeCompletionsFromAnalysisServer
                      ? await _computeCompletionSuggestions(resolvedUnitResult,
                          expectedCompletion.offset, declarationsTracker)
                      : null);
            }
          } catch (e) {
            print('Exception caught analyzing: $filePath');
            print(e.toString());
          }
        }
      }
    }
    printAndClearComputers();
  }

  /// Overridden by each subclass, this method gathers some set of data from
  /// each [ExpectedCompletion], and each [CompletionSuggestion] list (if
  /// [doComputeCompletionsFromAnalysisServer] is set to true.)
  void forEachExpectedCompletion(ExpectedCompletion expectedCompletion,
      List<CompletionSuggestion> suggestions);

  /// This method is called to print a summary of the data collected.
  void printAndClearComputers();

  Future<List<CompletionSuggestion>> _computeCompletionSuggestions(
      ResolvedUnitResult resolvedUnitResult, int offset,
      [DeclarationsTracker declarationsTracker]) async {
    var completionRequestImpl = CompletionRequestImpl(
      resolvedUnitResult,
      offset,
      false,
      CompletionPerformance(),
    );

    // This gets all of the suggestions with relevances.
    var suggestions =
        await DartCompletionManager().computeSuggestions(completionRequestImpl);

    // If a non-null declarationsTracker was passed, use it to call
    // computeIncludedSetList, this current implementation just adds the set of
    // included element names with relevance 0, future implementations should
    // compute out the relevance that clients will set to each value.
    if (declarationsTracker != null) {
      var includedSuggestionSets = <IncludedSuggestionSet>[];
      var includedElementNames = <String>{};

      computeIncludedSetList(declarationsTracker, resolvedUnitResult,
          includedSuggestionSets, includedElementNames);

      for (var eltName in includedElementNames) {
        suggestions.add(CompletionSuggestion(
            CompletionSuggestionKind.INVOCATION,
            0,
            eltName,
            0,
            eltName.length,
            false,
            false));
      }
    }

    suggestions.sort(completionComparator);
    return suggestions;
  }

  /// Given some [ResolvedUnitResult] return the first error of high severity
  /// if such an error exists, null otherwise.
  static err.AnalysisError getFirstErrorOrNull(
      ResolvedUnitResult resolvedUnitResult) {
    for (var error in resolvedUnitResult.errors) {
      if (error.severity == Severity.error) {
        return error;
      }
    }
    return null;
  }

  static Place placementInSuggestionList(List<CompletionSuggestion> suggestions,
      ExpectedCompletion expectedCompletion) {
    var placeCounter = 1;
    for (var completionSuggestion in suggestions) {
      if (expectedCompletion.matches(completionSuggestion)) {
        return Place(placeCounter, suggestions.length);
      }
      placeCounter++;
    }
    return Place.none();
  }
}

class CompletionCoverageMetrics extends AbstractCompletionMetricsComputer {
  int includedCount = 0;
  int notIncludedCount = 0;
  var completionMissedTokenCounter = Counter('missing completion counter');
  var completionKindCounter = Counter('completion kind counter');
  var completionElementKindCounter = Counter('completion element kind counter');
  var mRRComputer = MeanReciprocalRankComputer();

  CompletionCoverageMetrics(String rootPath) : super(rootPath);

  @override
  bool get doComputeCompletionsFromAnalysisServer => true;

  @override
  void forEachExpectedCompletion(ExpectedCompletion expectedCompletion,
      List<CompletionSuggestion> suggestions) {
    assert(suggestions != null);

    var place = AbstractCompletionMetricsComputer.placementInSuggestionList(
        suggestions, expectedCompletion);

    mRRComputer.addRank(place.rank);

    if (place.denominator != 0) {
      includedCount++;
    } else {
      notIncludedCount++;

      completionMissedTokenCounter.count(expectedCompletion.completion);
      completionKindCounter.count(expectedCompletion.kind.toString());
      completionElementKindCounter
          .count(expectedCompletion.elementKind.toString());

      // The format "/file/path/foo.dart:3:4" makes for easier input
      // with the Files dialog in IntelliJ
      print(
          '$currentFilePath:${expectedCompletion.lineNumber}:${expectedCompletion.columnNumber}');
      print(
          '\tdid not include the expected completion: \"${expectedCompletion.completion}\", completion kind: ${expectedCompletion.kind.toString()}, element kind: ${expectedCompletion.elementKind.toString()}');
      print('');
    }
  }

  @override
  void printAndClearComputers() {
    final totalCompletionCount = includedCount + notIncludedCount;
    final percentIncluded = includedCount / totalCompletionCount;
    final percentNotIncluded = 1 - percentIncluded;

    completionMissedTokenCounter.printCounterValues();
    print('');

    completionKindCounter.printCounterValues();
    print('');

    completionElementKindCounter.printCounterValues();
    print('');

    mRRComputer.printMean();
    print('');

    print('Summary for $_rootPath:');
    print('Total number of completion tests   = $totalCompletionCount');
    print(
        'Number of successful completions   = $includedCount (${printPercentage(percentIncluded)})');
    print(
        'Number of unsuccessful completions = $notIncludedCount (${printPercentage(percentNotIncluded)})');

    includedCount = 0;
    notIncludedCount = 0;
    completionMissedTokenCounter.clear();
    completionKindCounter.clear();
    completionElementKindCounter.clear();
    mRRComputer.clear();
  }
}
