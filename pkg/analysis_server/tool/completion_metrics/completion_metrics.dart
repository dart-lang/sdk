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

// TODO(jwren) have the analysis root and verbose option be configurable via a
//  command line UX
Future<void> main() async {
  await CompletionMetricsComputer('', true).computeCompletionMetrics();
}

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
class CompletionMetricsComputer {
  /// The analysis root path that this CompletionMetrics class will be computed.
  final String _rootPath;

  /// When enabled, expected, but missing completion tokens will be printed to
  /// stdout.
  final bool _verbose;

  CompletionMetricsComputer(this._rootPath, this._verbose);

  Future computeCompletionMetrics() async {
    int includedCount = 0;
    int notIncludedCount = 0;
    var completionMissedTokenCounter = Counter('missing completion counter');
    var completionKindCounter = Counter('completion kind counter');
    var completionElementKindCounter =
        Counter('completion element kind counter');
    var mRRComputer = MeanReciprocalRankComputer();

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
      var declarationsTracker = DeclarationsTracker(
          MemoryByteStore(), PhysicalResourceProvider.INSTANCE);
      declarationsTracker.addContext(context);

      while (declarationsTracker.hasWork) {
        declarationsTracker.doWork();
      }

      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath)) {
          try {
            final resolvedUnitResult =
                await context.currentSession.getResolvedUnit(filePath);

            var error = _getFirstErrorOrNull(resolvedUnitResult);
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
              var suggestions = await _computeCompletionSuggestions(
                  resolvedUnitResult,
                  expectedCompletion.offset,
                  declarationsTracker);

              var place =
                  _placementInSuggestionList(suggestions, expectedCompletion);

              mRRComputer.addReciprocalRank(place);

              if (place.denominator != 0) {
                includedCount++;
              } else {
                notIncludedCount++;

                completionMissedTokenCounter
                    .count(expectedCompletion.completion);
                completionKindCounter.count(expectedCompletion.kind.toString());
                completionElementKindCounter
                    .count(expectedCompletion.elementKind.toString());

                if (_verbose) {
                  // The format "/file/path/foo.dart:3:4" makes for easier input
                  // with the Files dialog in IntelliJ
                  print(
                      '$filePath:${expectedCompletion.lineNumber}:${expectedCompletion.columnNumber}');
                  print(
                      '\tdid not include the expected completion: \"${expectedCompletion.completion}\", completion kind: ${expectedCompletion.kind.toString()}, element kind: ${expectedCompletion.elementKind.toString()}');
                  print('');
                }
              }
            }
          } catch (e) {
            print('Exception caught analyzing: $filePath');
            print(e.toString());
          }
        }
      }
    }

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

  Future<List<CompletionSuggestion>> _computeCompletionSuggestions(
      ResolvedUnitResult resolvedUnitResult, int offset,
      [DeclarationsTracker declarationsTracker]) async {
    var completionRequestImpl = CompletionRequestImpl(
      resolvedUnitResult,
      offset,
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
  err.AnalysisError _getFirstErrorOrNull(
      ResolvedUnitResult resolvedUnitResult) {
    for (var error in resolvedUnitResult.errors) {
      if (error.severity == Severity.error) {
        return error;
      }
    }
    return null;
  }

  Place _placementInSuggestionList(List<CompletionSuggestion> suggestions,
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
