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
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:args/args.dart';

import 'metrics_util.dart';
import 'utils.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (!validArguments(parser, result)) {
    return io.exit(1);
  }

  var root = result.rest[0];
  print('Analyzing root: "$root"');
  var stopwatch = Stopwatch()..start();
  var code = await CompletionMetricsComputer(root,
          verbose: result['verbose'],
          availableSuggestions: result[AVAILABLE_SUGGESTIONS],
          overlay: result[OVERLAY])
      .compute();
  stopwatch.stop();

  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('');
  print('Metrics computed in $duration');
  return io.exit(code);
}

const String AVAILABLE_SUGGESTIONS = 'available-suggestions';

const String OVERLAY = 'overlay';

const String OVERLAY_NONE = 'none';

const String OVERLAY_REMOVE_REST_OF_FILE = 'remove-rest-of-file';

const String OVERLAY_REMOVE_TOKEN = 'remove-token';

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  return ArgParser()
    ..addOption(
      'help',
      abbr: 'h',
      help: 'Print this help message.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Print additional information about the analysis',
      negatable: false,
    )
    ..addFlag(AVAILABLE_SUGGESTIONS,
        abbr: 'a',
        help: 'Use the available suggestions feature in the Analysis Server '
            'when computing the set of code completions. With this feature '
            'enabled, completion will match the support in the Dart Plugin for '
            'IntelliJ, without this enabled the completion support matches '
            'the support in LSP.',
        defaultsTo: false,
        negatable: false)
    ..addOption(OVERLAY,
        allowed: [
          OVERLAY_NONE,
          OVERLAY_REMOVE_TOKEN,
          OVERLAY_REMOVE_REST_OF_FILE
        ],
        defaultsTo: OVERLAY_NONE,
        help:
            'Before attempting a completion at the location of each token, the '
            'token can be removed, or the rest of the file can be removed to test '
            'code completion with diverse methods. The default mode is to '
            'complete at the start of the token without modifying the file.');
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
  /// The maximum number of worst results to collect.
  static const maxWorstResults = 10;

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

  ArithmeticMeanComputer charsBeforeTop =
      ArithmeticMeanComputer('chars_before_top');

  ArithmeticMeanComputer charsBeforeTopFive =
      ArithmeticMeanComputer('chars_before_top_five');

  ArithmeticMeanComputer insertionLengthTheoretical =
      ArithmeticMeanComputer('insertion_length_theoretical');

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks.
  List<CompletionResult> worstResults = [];

  CompletionMetrics(this.name);

  /// If the [result] is worse than any previously recorded results, record it.
  void recordCompletionResult(CompletionResult result) {
    if (worstResults.length >= maxWorstResults) {
      if (result.place.rank <= worstResults.last.place.rank) {
        return;
      }
      worstResults.removeLast();
    }
    worstResults.add(result);
    worstResults.sort((first, second) => second.place.rank - first.place.rank);
  }
}

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
class CompletionMetricsComputer {
  final String rootPath;

  final bool verbose;

  final bool availableSuggestions;

  final String overlay;

  ResolvedUnitResult _resolvedUnitResult;

  /// The int to be returned from the [compute] call.
  int resultCode;

  CompletionMetrics metricsOldMode;

  CompletionMetrics metricsNewMode;

  final OverlayResourceProvider _provider =
      OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  int overlayModificationStamp = 0;

  CompletionMetricsComputer(this.rootPath,
      {this.verbose, this.availableSuggestions, this.overlay})
      : assert(overlay == OVERLAY_NONE ||
            overlay == OVERLAY_REMOVE_TOKEN ||
            overlay == OVERLAY_REMOVE_REST_OF_FILE);

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
    if (verbose) {
      printWorstResults(metricsNewMode);
    }
    return resultCode;
  }

  bool forEachExpectedCompletion(
      ExpectedCompletion expectedCompletion,
      List<CompletionSuggestion> suggestions,
      CompletionMetrics metrics,
      bool doPrintMissedCompletions) {
    assert(suggestions != null);

    var successfulCompletion;

    var place = placementInSuggestionList(suggestions, expectedCompletion);

    metrics.mrrComputer.addRank(place.rank);

    if (place.denominator != 0) {
      successfulCompletion = true;

      metrics.successfulMrrComputer.addRank(place.rank);
      metrics.completionCounter.count('successful');

      metrics.recordCompletionResult(
          CompletionResult(place, suggestions, expectedCompletion));

      var element = getElement(expectedCompletion.syntacticEntity);
      if (isInstanceMember(element)) {
        metrics.instanceMemberMrrComputer.addRank(place.rank);
      } else if (isStaticMember(element)) {
        metrics.staticMemberMrrComputer.addRank(place.rank);
      } else {
        metrics.nonTypeMemberMrrComputer.addRank(place.rank);
      }

      var charsBeforeTop =
          _computeCharsBeforeTop(expectedCompletion, suggestions);
      metrics.charsBeforeTop.addValue(charsBeforeTop);
      metrics.charsBeforeTopFive.addValue(
          _computeCharsBeforeTop(expectedCompletion, suggestions, minRank: 5));
      metrics.insertionLengthTheoretical
          .addValue(expectedCompletion.completion.length - charsBeforeTop);
    } else {
      successfulCompletion = false;

      metrics.completionCounter.count('unsuccessful');

      metrics.completionMissedTokenCounter.count(expectedCompletion.completion);
      metrics.completionKindCounter.count(expectedCompletion.kind.toString());
      metrics.completionElementKindCounter
          .count(expectedCompletion.elementKind.toString());

      if (doPrintMissedCompletions) {
        var closeMatchSuggestion;
        for (var suggestion in suggestions) {
          if (suggestion.completion == expectedCompletion.completion) {
            closeMatchSuggestion = suggestion;
          }
        }

        print('missing completion (`useNewRelevance = true`):');
        print('$expectedCompletion');
        if (closeMatchSuggestion != null) {
          print('    close matching completion that was in the list:');
          print('    $closeMatchSuggestion');
        }
        print('');
      }
    }
    return successfulCompletion;
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

    metrics.charsBeforeTop.printMean();
    metrics.charsBeforeTopFive.printMean();
    metrics.insertionLengthTheoretical.printMean();
    print('');

    print('Summary for $rootPath:');
    metrics.meanCompletionMS.printMean();
    metrics.completionCounter.printCounterValues();
    print('====================');
  }

  void printWorstResults(CompletionMetrics metrics) {
    print('');
    print('====================');
    print('The worst completion results:');
    for (var result in metrics.worstResults) {
      var rank = result.place.rank;
      var expected = result.expectedCompletion;
      var suggestions = result.suggestions;
      var preceeding = StringBuffer();
      for (var i = 0; i < rank - 1; i++) {
        if (i > 0) {
          preceeding.write(', ');
        }
        preceeding.write(suggestions[i].relevance);
      }
      print('');
      print('Rank: $rank');
      print('Completion: ${expected.completion}');
      print('Completion kind: ${expected.kind}');
      print('Element kind: ${expected.elementKind}');
      print('Offset: ${expected.offset}');
      print('Preceeding: $preceeding');
      print('Suggestion: ${suggestions[rank - 1]}');
    }
  }

  int _computeCharsBeforeTop(
      ExpectedCompletion target, List<CompletionSuggestion> suggestions,
      {int minRank = 1}) {
    var rank = placementInSuggestionList(suggestions, target).rank;
    if (rank <= minRank) {
      return 0;
    }
    var expected = target.completion;
    for (var i = 1; i < expected.length + 1; i++) {
      var prefix = expected.substring(0, i);
      var filteredSuggestions = _filterSuggestions(prefix, suggestions);
      rank = placementInSuggestionList(filteredSuggestions, target).rank;
      if (rank <= minRank) {
        return i;
      }
    }
    return expected.length;
  }

  Future<List<CompletionSuggestion>> _computeCompletionSuggestions(
      ResolvedUnitResult resolvedUnitResult,
      int offset,
      CompletionMetrics metrics,
      [bool useNewRelevance = false,
      DeclarationsTracker declarationsTracker,
      CompletionAvailableSuggestionsParams availableSuggestionsParams]) async {
    var completionRequest = CompletionRequestImpl(
      resolvedUnitResult,
      offset,
      useNewRelevance,
      CompletionPerformance(),
    );

    var stopwatch = Stopwatch()..start();

    var suggestions;

    if (declarationsTracker == null) {
      // available suggestions == false
      suggestions =
          await DartCompletionManager().computeSuggestions(completionRequest);
    } else {
      // available suggestions == true
      var includedElementKinds = <ElementKind>{};
      var includedElementNames = <String>{};
      var includedSuggestionRelevanceTagList =
          <IncludedSuggestionRelevanceTag>[];
      var includedSuggestionSetList = <IncludedSuggestionSet>[];
      suggestions = await DartCompletionManager(
              includedElementKinds: includedElementKinds,
              includedElementNames: includedElementNames,
              includedSuggestionRelevanceTags:
                  includedSuggestionRelevanceTagList)
          .computeSuggestions(completionRequest);

      computeIncludedSetList(declarationsTracker, resolvedUnitResult,
          includedSuggestionSetList, includedElementNames);

      var includedSuggestionSetMap = {
        for (var includedSuggestionSet in includedSuggestionSetList)
          includedSuggestionSet.id: includedSuggestionSet,
      };

      var includedSuggestionRelevanceTagMap = {
        for (var includedSuggestionRelevanceTag
            in includedSuggestionRelevanceTagList)
          includedSuggestionRelevanceTag.tag:
              includedSuggestionRelevanceTag.relevanceBoost,
      };

      for (var availableSuggestionSet
          in availableSuggestionsParams.changedLibraries) {
        var id = availableSuggestionSet.id;
        for (var availableSuggestion in availableSuggestionSet.items) {
          // Exclude available suggestions where this element kind doesn't match
          // an element kind in includedElementKinds.
          var elementKind = availableSuggestion.element?.kind;
          if (elementKind != null &&
              includedElementKinds.contains(elementKind)) {
            if (includedSuggestionSetMap.containsKey(id)) {
              var relevance = includedSuggestionSetMap[id].relevance;

              // Search for any matching relevance tags to apply any boosts
              if (includedSuggestionRelevanceTagList.isNotEmpty &&
                  availableSuggestion.relevanceTags != null &&
                  availableSuggestion.relevanceTags.isNotEmpty) {
                for (var tag in availableSuggestion.relevanceTags) {
                  if (includedSuggestionRelevanceTagMap.containsKey(tag)) {
                    // apply the boost
                    relevance += includedSuggestionRelevanceTagMap[tag];
                  }
                }
              }
              suggestions
                  .add(availableSuggestion.toCompletionSuggestion(relevance));
            }
          }
        }
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
    final collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: _provider,
    );

    var context = collection.contexts[0];

    // Set the DeclarationsTracker, only call doWork to build up the available
    // suggestions if doComputeCompletionsFromAnalysisServer is true.
    var declarationsTracker;
    var availableSuggestionsParams;
    if (availableSuggestions) {
      declarationsTracker = DeclarationsTracker(
          MemoryByteStore(), PhysicalResourceProvider.INSTANCE);
      declarationsTracker.addContext(context);
      while (declarationsTracker.hasWork) {
        declarationsTracker.doWork();
      }

      // Have the AvailableDeclarationsSet computed to use later.
      availableSuggestionsParams = createCompletionAvailableSuggestions(
          declarationsTracker.allLibraries.toList(), []);

      // assert that this object is not null, throw if it is.
      if (availableSuggestionsParams == null) {
        throw Exception('availableSuggestionsParam not computable.');
      }
    }

    // Loop through each file, resolve the file and call
    // forEachExpectedCompletion
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (AnalysisEngine.isDartFileName(filePath)) {
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
          final visitor = ExpectedCompletionsVisitor(filePath);
          _resolvedUnitResult.unit.accept(visitor);

          for (var expectedCompletion in visitor.expectedCompletions) {
            var resolvedUnitResultWithOverlay = _resolvedUnitResult;

            // If an overlay option is being used, compute the overlay file, and
            // have the context reanalyze the file
            if (overlay != OVERLAY_NONE) {
              var overlayContents = _getOverlayContents(
                  _resolvedUnitResult.content, expectedCompletion, overlay);

              _provider.setOverlay(filePath,
                  content: overlayContents,
                  modificationStamp: overlayModificationStamp++);
              (context as DriverBasedAnalysisContext)
                  .driver
                  .changeFile(filePath);
              resolvedUnitResultWithOverlay =
                  await context.currentSession.getResolvedUnit(filePath);
            }

            // As this point the completion suggestions are computed,
            // and results are collected with varying settings for
            // comparison:

            // First we compute the completions useNewRelevance set to
            // false:
            var suggestions = await _computeCompletionSuggestions(
                resolvedUnitResultWithOverlay,
                expectedCompletion.offset,
                metricsOldMode,
                false,
                declarationsTracker,
                availableSuggestionsParams);

            var successfulnessUseOldRelevance = forEachExpectedCompletion(
                expectedCompletion, suggestions, metricsOldMode, false);

            // And again here with useNewRelevance set to true:
            suggestions = await _computeCompletionSuggestions(
                resolvedUnitResultWithOverlay,
                expectedCompletion.offset,
                metricsNewMode,
                true,
                declarationsTracker,
                availableSuggestionsParams);

            var successfulnessUseNewRelevance = forEachExpectedCompletion(
                expectedCompletion, suggestions, metricsNewMode, verbose);

            if (verbose &&
                successfulnessUseOldRelevance !=
                    successfulnessUseNewRelevance) {
              if (successfulnessUseNewRelevance &&
                  !successfulnessUseOldRelevance) {
                print('    ===========');
                print(
                    '    The `useNewRelevance = true` generated a completion that `useNewRelevance = false` did not:');
                print('    $expectedCompletion');
                print('    ===========');
                print('');
              } else {
                print('    ===========');
                print(
                    '    The `useNewRelevance = false` generated a completion that `useNewRelevance = true` did not:');
                print('    $expectedCompletion');
                print('    ===========');
                print('');
              }
            }

            // If an overlay option is being used, remove the overlay applied
            // earlier
            if (overlay != OVERLAY_NONE) {
              _provider.removeOverlay(filePath);
            }
          }
        } catch (e) {
          print('Exception caught analyzing: $filePath');
          print(e.toString());
          resultCode = 1;
        }
      }
    }
  }

  List<CompletionSuggestion> _filterSuggestions(
      String prefix, List<CompletionSuggestion> suggestions) {
    // TODO(brianwilkerson) Replace this with a more realistic filtering algorithm.
    return suggestions
        .where((suggestion) => suggestion.completion.startsWith(prefix))
        .toList();
  }

  String _getOverlayContents(String contents,
      ExpectedCompletion expectedCompletion, String overlayMode) {
    assert(contents.isNotEmpty);
    var offset = expectedCompletion.offset;
    var length = expectedCompletion.syntacticEntity.length;
    assert(offset >= 0);
    assert(length > 0);
    if (overlayMode == OVERLAY_REMOVE_TOKEN) {
      return contents.substring(0, offset) +
          contents.substring(offset + length);
    } else if (overlayMode == OVERLAY_REMOVE_REST_OF_FILE) {
      return contents.substring(0, offset);
    } else {
      throw Exception('\'_getOverlayContents\' called with option other than'
          '$OVERLAY_REMOVE_TOKEN and $OVERLAY_REMOVE_REST_OF_FILE: $overlayMode');
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

/// The result of a single completion.
class CompletionResult {
  final Place place;

  final List<CompletionSuggestion> suggestions;

  final ExpectedCompletion expectedCompletion;

  CompletionResult(this.place, this.suggestions, this.expectedCompletion);
}

extension AvailableSuggestionsExtension on AvailableSuggestion {
  // TODO(jwren) I am not sure if we want CompletionSuggestionKind.INVOCATION in
  // call cases here, to iterate I need to figure out why this algorithm is
  // taking so much time.
  CompletionSuggestion toCompletionSuggestion(int relevance) =>
      CompletionSuggestion(CompletionSuggestionKind.INVOCATION, relevance,
          label, label.length, 0, element.isDeprecated, false);
}
