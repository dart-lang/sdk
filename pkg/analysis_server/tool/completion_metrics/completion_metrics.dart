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
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:args/args.dart';

import 'metrics_util.dart';
import 'utils.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  ArgParser parser = createArgParser();
  ArgResults result = parser.parse(args);

  if (!validArguments(parser, result)) {
    return io.exit(1);
  }
  var root = result.rest[0];
  print('Analyzing root: "$root"');
  var stopwatch = Stopwatch()..start();
  var code = await CompletionMetricsComputer(root, verbose: result['verbose'])
      .compute();
  stopwatch.stop();

  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('');
  print('Metrics computed in $duration');
  return io.exit(code);
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  ArgParser parser = ArgParser();
  parser.addOption(
    'help',
    abbr: 'h',
    help: 'Print this help message.',
  );
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Print additional information about the analysis',
    negatable: false,
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart completion_metrics.dart [options] packagePath');
  print('');
  print('Compute code completion health metrics.');
  print('');
  print(parser.usage);
}

/// Return `true` if the command-line arguments (represented by the [result] and
/// parsed by the [parser]) are valid.
bool validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    printUsage(parser);
    return false;
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No package path specified.');
    return false;
  }
  var rootPath = result.rest[0];
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// A wrapper for the collection of [Counter] and [MeanReciprocalRankComputer]
/// objects for a run of [CompletionMetricsComputer].
class CompletionMetrics {
  /// The name associated with this set of metrics.
  final String name;

  Counter completionCounter = Counter('successful/ unsuccessful completions');

  Counter completionMissedTokenCounter =
      Counter('unsuccessful completion token counter');

  Counter completionKindCounter =
      Counter('unsuccessful completion kind counter');

  Counter completionElementKindCounter =
      Counter('unsuccessful completion element kind counter');

  ArithmeticMeanComputer meanCompletionMS =
      ArithmeticMeanComputer('ms per completion');

  MeanReciprocalRankComputer mrrComputer =
      MeanReciprocalRankComputer('successful/ unsuccessful completions');

  MeanReciprocalRankComputer successfulMrrComputer =
      MeanReciprocalRankComputer('successful completions');

  MeanReciprocalRankComputer instanceMemberMrrComputer =
      MeanReciprocalRankComputer('instance member completions');

  MeanReciprocalRankComputer staticMemberMrrComputer =
      MeanReciprocalRankComputer('static member completions');

  MeanReciprocalRankComputer nonTypeMemberMrrComputer =
      MeanReciprocalRankComputer('non-type member completions');

  CompletionMetrics(this.name);
}

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
class CompletionMetricsComputer {
  final String rootPath;

  final bool verbose;

  String _currentFilePath;

  ResolvedUnitResult _resolvedUnitResult;

  /// The int to be returned from the [compute] call.
  int resultCode;

  CompletionMetrics metricsOldMode;

  CompletionMetrics metricsNewMode;

  CompletionMetricsComputer(this.rootPath, {this.verbose});

  /// The path to the current file.
  String get currentFilePath => _currentFilePath;

  Future<int> compute() async {
    resultCode = 0;
    metricsOldMode = CompletionMetrics('useNewRelevance = false');
    metricsNewMode = CompletionMetrics('useNewRelevance = true');
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot);
    }
    printMetrics(metricsOldMode);
    printMetrics(metricsNewMode);
    return resultCode;
  }

  void forEachExpectedCompletion(ExpectedCompletion expectedCompletion,
      List<CompletionSuggestion> suggestions, CompletionMetrics metrics) {
    assert(suggestions != null);

    var place = placementInSuggestionList(suggestions, expectedCompletion);

    metrics.mrrComputer.addRank(place.rank);

    if (place.denominator != 0) {
      metrics.successfulMrrComputer.addRank(place.rank);
      metrics.completionCounter.count('successful');

      var element = getElement(expectedCompletion.syntacticEntity);
      if (isInstanceMember(element)) {
        metrics.instanceMemberMrrComputer.addRank(place.rank);
      } else if (isStaticMember(element)) {
        metrics.staticMemberMrrComputer.addRank(place.rank);
      } else {
        metrics.nonTypeMemberMrrComputer.addRank(place.rank);
      }
    } else {
      metrics.completionCounter.count('unsuccessful');

      metrics.completionMissedTokenCounter.count(expectedCompletion.completion);
      metrics.completionKindCounter.count(expectedCompletion.kind.toString());
      metrics.completionElementKindCounter
          .count(expectedCompletion.elementKind.toString());

      if (verbose) {
        // The format "/file/path/foo.dart:3:4" makes for easier input
        // with the Files dialog in IntelliJ.
        var lineNumber = expectedCompletion.lineNumber;
        var columnNumber = expectedCompletion.columnNumber;
        print('$currentFilePath:$lineNumber:$columnNumber');
        print('  missing completion: "${expectedCompletion.completion}"');
        print('  completion kind: ${expectedCompletion.kind}');
        print('  element kind: ${expectedCompletion.elementKind}');
        print('');
      }
    }
  }

  void printMetrics(CompletionMetrics metrics) {
    print('');
    print('');
    print('====================');
    print('Completion metrics for ${metrics.name}:');
    if (verbose) {
      metrics.completionMissedTokenCounter.printCounterValues();
      print('');

      metrics.completionKindCounter.printCounterValues();
      print('');

      metrics.completionElementKindCounter.printCounterValues();
      print('');
    }

    metrics.mrrComputer.printMean();
    print('');

    metrics.successfulMrrComputer.printMean();
    print('');

    metrics.instanceMemberMrrComputer.printMean();
    print('');

    metrics.staticMemberMrrComputer.printMean();
    print('');

    metrics.nonTypeMemberMrrComputer.printMean();
    print('');

    print('Summary for $rootPath:');
    metrics.meanCompletionMS.printMean();
    metrics.completionCounter.printCounterValues();
    print('====================');
  }

  Future<List<CompletionSuggestion>> _computeCompletionSuggestions(
      ResolvedUnitResult resolvedUnitResult,
      int offset,
      CompletionMetrics metrics,
      [DeclarationsTracker declarationsTracker,
      bool useNewRelevance = false]) async {
    var completionRequestImpl = CompletionRequestImpl(
      resolvedUnitResult,
      offset,
      useNewRelevance,
      CompletionPerformance(),
    );

    var stopwatch = Stopwatch()..start();

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
    stopwatch.stop();
    metrics.meanCompletionMS.addValue(stopwatch.elapsedMilliseconds);

    suggestions.sort(completionComparator);
    return suggestions;
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector].
  Future<void> _computeInContext(ContextRoot root) async {
    // Create a new collection to avoid consuming large quantities of memory.
    // TODO(brianwilkerson) Create an OverlayResourceProvider to allow the
    //  content of the files to be modified before computing suggestions.
    final collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];
    // Set the DeclarationsTracker, only call doWork to build up the available
    // suggestions if doComputeCompletionsFromAnalysisServer is true.
    // TODO(brianwilkerson) Add a flag to control whether available suggestions
    //  are to be used.
    var declarationsTracker = DeclarationsTracker(
        MemoryByteStore(), PhysicalResourceProvider.INSTANCE);
    declarationsTracker.addContext(context);
    while (declarationsTracker.hasWork) {
      declarationsTracker.doWork();
    }

    // Loop through each file, resolve the file and call
    // forEachExpectedCompletion
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (AnalysisEngine.isDartFileName(filePath)) {
        _currentFilePath = filePath;
        try {
          _resolvedUnitResult =
              await context.currentSession.getResolvedUnit(filePath);

          var analysisError = getFirstErrorOrNull(_resolvedUnitResult);
          if (analysisError != null) {
            print('File $filePath skipped due to errors such as:');
            print('  ${analysisError.toString()}');
            print('');
            resultCode = 1;
            continue;
          }

          // Use the ExpectedCompletionsVisitor to compute the set of expected
          // completions for this CompilationUnit.
          final visitor = ExpectedCompletionsVisitor();
          _resolvedUnitResult.unit.accept(visitor);

          for (var expectedCompletion in visitor.expectedCompletions) {
            // As this point the completion suggestions are computed,
            // and results are collected with varying settings for
            // comparison:

            // First we compute the completions useNewRelevance set to
            // false:
            var suggestions = await _computeCompletionSuggestions(
                _resolvedUnitResult,
                expectedCompletion.offset,
                metricsOldMode,
                declarationsTracker,
                false);

            forEachExpectedCompletion(
                expectedCompletion, suggestions, metricsOldMode);

            // And again here with useNewRelevance set to true:
            suggestions = await _computeCompletionSuggestions(
                _resolvedUnitResult,
                expectedCompletion.offset,
                metricsNewMode,
                declarationsTracker,
                true);

            forEachExpectedCompletion(
                expectedCompletion, suggestions, metricsNewMode);
          }
        } catch (e) {
          print('Exception caught analyzing: $filePath');
          print(e.toString());
          resultCode = 1;
        }
      }
    }
  }

  /// Given some [ResolvedUnitResult] return the first error of high severity
  /// if such an error exists, `null` otherwise.
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
