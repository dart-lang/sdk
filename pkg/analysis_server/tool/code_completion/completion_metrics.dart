// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart'
    show
        ClassElement,
        Element,
        ExtensionElement,
        ClassMemberElement,
        ExecutableElement,
        FieldElement,
        VariableElement;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';

import 'metrics_util.dart';
import 'output_utilities.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (!validArguments(parser, result)) {
    return io.exit(1);
  }

  var options = CompletionMetricsOptions(
      availableSuggestions: result[AVAILABLE_SUGGESTIONS],
      overlay: result[OVERLAY],
      printMissedCompletionDetails: result[PRINT_MISSED_COMPLETION_DETAILS],
      printMissedCompletionSummary: result[PRINT_MISSED_COMPLETION_SUMMARY],
      printMissingInformation: result[PRINT_MISSING_INFORMATION],
      printMrrByLocation: result[PRINT_MRR_BY_LOCATION],
      printSlowestResults: result[PRINT_SLOWEST_RESULTS],
      printWorstResults: result[PRINT_WORST_RESULTS]);
  var root = result.rest[0];
  print('Analyzing root: "$root"');
  var stopwatch = Stopwatch()..start();
  var code = await CompletionMetricsComputer(root, options).compute();
  stopwatch.stop();

  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('');
  print('Metrics computed in $duration');
  return io.exit(code);
}

const String AVAILABLE_SUGGESTIONS = 'available-suggestions';

/// An option to control whether and how overlays should be produced.
const String OVERLAY = 'overlay';

/// A mode indicating that no overlays should be produced.
const String OVERLAY_NONE = 'none';

/// A mode indicating that everything from the completion offset to the end of
/// the file should be removed.
const String OVERLAY_REMOVE_REST_OF_FILE = 'remove-rest-of-file';

/// A mode indicating that the token whose offset is the same as the
/// completion offset should be removed.
const String OVERLAY_REMOVE_TOKEN = 'remove-token';

/// A flag that causes detailed information to be printed every time a
/// completion request fails to produce a suggestions matching the expected
/// suggestion.
const String PRINT_MISSED_COMPLETION_DETAILS =
    'print-missed-completion-details';

/// A flag that causes summary information to be printed about the times that a
/// completion request failed to produce a suggestions matching the expected
/// suggestion.
const String PRINT_MISSED_COMPLETION_SUMMARY =
    'print-missed-completion-summary';

/// A flag that causes information to be printed about places where no
/// completion location was computed and about information that's missing in the
/// completion tables.
const String PRINT_MISSING_INFORMATION = 'print-missing-information';

/// A flag that causes information to be printed about the mrr score achieved at
/// each completion location.
const String PRINT_MRR_BY_LOCATION = 'print-mrr-by-location';

/// A flag that causes information to be printed about the completion requests
/// that were the slowest to return suggestions.
const String PRINT_SLOWEST_RESULTS = 'print-slowest-results';

/// A flag that causes information to be printed about the completion requests
/// that had the worst mrr scores.
const String PRINT_WORST_RESULTS = 'print-worst-results';

/// A [Counter] to track the performance of each of the completion strategies
/// that are being compared.
Counter rankComparison = Counter('relevance rank comparison');

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  return ArgParser()
    ..addFlag(AVAILABLE_SUGGESTIONS,
        abbr: 'a',
        help:
            'Use the available suggestions feature in the Analysis Server when '
            'computing the set of code completions. With this feature enabled, '
            'completion will match the support in the Dart Plugin for '
            'IntelliJ, without this enabled the completion support matches the '
            'support in LSP.',
        defaultsTo: false,
        negatable: false)
    ..addOption(
      'help',
      abbr: 'h',
      help: 'Print this help message.',
    )
    ..addOption(OVERLAY,
        allowed: [
          OVERLAY_NONE,
          OVERLAY_REMOVE_TOKEN,
          OVERLAY_REMOVE_REST_OF_FILE
        ],
        defaultsTo: OVERLAY_NONE,
        help:
            'Before attempting a completion at the location of each token, the '
            'token can be removed, or the rest of the file can be removed to '
            'test code completion with diverse methods. The default mode is to '
            'complete at the start of the token without modifying the file.')
    ..addFlag(PRINT_MISSED_COMPLETION_DETAILS,
        defaultsTo: false,
        help:
            'Print detailed information every time a completion request fails '
            'to produce a suggestions matching the expected suggestion.',
        negatable: false)
    ..addFlag(PRINT_MISSED_COMPLETION_SUMMARY,
        defaultsTo: false,
        help: 'Print summary information about the times that a completion '
            'request failed to produce a suggestions matching the expected '
            'suggestion.',
        negatable: false)
    ..addFlag(PRINT_MISSING_INFORMATION,
        defaultsTo: false,
        help: 'Print information about places where no completion location was '
            'computed and about information that is missing in the completion '
            'tables.',
        negatable: false)
    ..addFlag(PRINT_MRR_BY_LOCATION,
        defaultsTo: false,
        help:
            'Print information about the mrr score achieved at each completion '
            'location. This can help focus efforts to improve the overall '
            'score by pointing out the locations that are causing the biggest '
            'impact.',
        negatable: false)
    ..addFlag(PRINT_SLOWEST_RESULTS,
        defaultsTo: false,
        help: 'Print information about the completion requests that were the '
            'slowest to return suggestions.',
        negatable: false)
    ..addFlag(PRINT_WORST_RESULTS,
        defaultsTo: false,
        help:
            'Print information about the completion requests that had the worst '
            'mrr scores.',
        negatable: false);
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

/// An indication of the group in which the completion falls for the purposes of
/// subdividing the results.
enum CompletionGroup {
  instanceMember,
  staticMember,
  typeReference,
  localReference,
  paramReference,
  topLevel
}

/// A wrapper for the collection of [Counter] and [MeanReciprocalRankComputer]
/// objects for a run of [CompletionMetricsComputer].
class CompletionMetrics {
  /// The maximum number of slowest results to collect.
  static const maxSlowestResults = 5;

  /// The maximum number of worst results to collect.
  static const maxWorstResults = 5;

  /// The name associated with this set of metrics.
  final String name;

  /// The function to be executed when this metrics collector is enabled.
  final void Function() enableFunction;

  /// The function to be executed when this metrics collector is disabled.
  final void Function() disableFunction;

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

  MeanReciprocalRankComputer typeRefMrrComputer =
      MeanReciprocalRankComputer('type reference completions');

  MeanReciprocalRankComputer localRefMrrComputer =
      MeanReciprocalRankComputer('local reference completions');

  MeanReciprocalRankComputer paramRefMrrComputer =
      MeanReciprocalRankComputer('param reference completions');

  MeanReciprocalRankComputer topLevelMrrComputer =
      MeanReciprocalRankComputer('non-type member completions');

  Map<String, MeanReciprocalRankComputer> locationMrrComputers = {};

  ArithmeticMeanComputer charsBeforeTop =
      ArithmeticMeanComputer('chars_before_top');

  ArithmeticMeanComputer charsBeforeTopFive =
      ArithmeticMeanComputer('chars_before_top_five');

  ArithmeticMeanComputer insertionLengthTheoretical =
      ArithmeticMeanComputer('insertion_length_theoretical');

  /// The places in which a completion location was requested when none was
  /// available.
  Set<String> missingCompletionLocations = {};

  /// The completion locations for which no relevance table was available.
  Set<String> missingCompletionLocationTables = {};

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to instance members.
  List<CompletionResult> instanceMemberWorstResults = [];

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to static members.
  List<CompletionResult> staticMemberWorstResults = [];

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to type references.
  List<CompletionResult> typeRefWorstResults = [];

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to local references.
  List<CompletionResult> localRefWorstResults = [];

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to parameter references.
  List<CompletionResult> paramRefWorstResults = [];

  /// A list of the top [maxWorstResults] completion results with the highest
  /// (worst) ranks for completing to top-level declarations.
  List<CompletionResult> topLevelWorstResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for instance members.
  List<CompletionResult> instanceMemberSlowestResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for static members.
  List<CompletionResult> staticMemberSlowestResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for type references.
  List<CompletionResult> typeRefSlowestResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for local references.
  List<CompletionResult> localRefSlowestResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for parameter references.
  List<CompletionResult> paramRefSlowestResults = [];

  /// A list of the top [maxSlowestResults] completion results that took the
  /// longest top compute for top-level declarations.
  List<CompletionResult> topLevelSlowestResults = [];

  CompletionMetrics(this.name, this.enableFunction, this.disableFunction);

  /// Perform any operations required in order to revert computing the kind of
  /// completions represented by this metrics collector.
  void disable() {
    if (disableFunction != null) {
      disableFunction();
    }
  }

  /// Perform any initialization required in order to compute the kind of
  /// completions represented by this metrics collector.
  void enable() {
    if (enableFunction != null) {
      enableFunction();
    }
  }

  /// Record this completion result, this method handles the worst ranked items
  /// as well as the longest sets of results to compute.
  void recordCompletionResult(CompletionResult result) {
    _recordTime(result);
    _recordMrr(result);
    _recordWorstResult(result);
    _recordSlowestResult(result);
    _recordMissingInformation(result);
  }

  /// If the completion location was requested but missing when computing the
  /// [result], then record where that happened.
  void _recordMissingInformation(CompletionResult result) {
    var location = result.listener?.missingCompletionLocation;
    if (location != null) {
      missingCompletionLocations.add(location);
    } else {
      location = result.listener?.missingCompletionLocationTable;
      if (location != null) {
        missingCompletionLocationTables.add(location);
      }
    }
  }

  /// Record the MRR for the [result].
  void _recordMrr(CompletionResult result) {
    var rank = result.place.rank;
    // Record globally.
    successfulMrrComputer.addRank(rank);
    // Record by group.
    switch (result.group) {
      case CompletionGroup.instanceMember:
        instanceMemberMrrComputer.addRank(rank);
        break;
      case CompletionGroup.staticMember:
        staticMemberMrrComputer.addRank(rank);
        break;
      case CompletionGroup.typeReference:
        typeRefMrrComputer.addRank(rank);
        break;
      case CompletionGroup.localReference:
        localRefMrrComputer.addRank(rank);
        break;
      case CompletionGroup.paramReference:
        paramRefMrrComputer.addRank(rank);
        break;
      case CompletionGroup.topLevel:
        topLevelMrrComputer.addRank(rank);
        break;
    }
    // Record by completion location.
    var location = result.completionLocation;
    if (location != null) {
      var computer = locationMrrComputers.putIfAbsent(
          location, () => MeanReciprocalRankComputer(location));
      computer.addRank(rank);
    }
  }

  /// If the [result] is took longer than any previously recorded results,
  /// record it.
  void _recordSlowestResult(CompletionResult result) {
    List<CompletionResult> getSlowestResults() {
      switch (result.group) {
        case CompletionGroup.instanceMember:
          return instanceMemberSlowestResults;
        case CompletionGroup.staticMember:
          return staticMemberSlowestResults;
        case CompletionGroup.typeReference:
          return typeRefSlowestResults;
        case CompletionGroup.localReference:
          return localRefSlowestResults;
        case CompletionGroup.paramReference:
          return paramRefSlowestResults;
        case CompletionGroup.topLevel:
          return topLevelSlowestResults;
      }
      return const <CompletionResult>[];
    }

    var slowestResults = getSlowestResults();
    if (slowestResults.length >= maxSlowestResults) {
      if (result.elapsedMS <= slowestResults.last.elapsedMS) {
        return;
      }
      slowestResults.removeLast();
    }
    slowestResults.add(result);
    slowestResults.sort((first, second) => second.elapsedMS - first.elapsedMS);
  }

  /// Record this elapsed ms count for the average ms count.
  void _recordTime(CompletionResult result) {
    meanCompletionMS.addValue(result.elapsedMS);
  }

  /// If the [result] is worse than any previously recorded results, record it.
  void _recordWorstResult(CompletionResult result) {
    List<CompletionResult> getWorstResults() {
      switch (result.group) {
        case CompletionGroup.instanceMember:
          return instanceMemberWorstResults;
        case CompletionGroup.staticMember:
          return staticMemberWorstResults;
        case CompletionGroup.typeReference:
          return typeRefWorstResults;
        case CompletionGroup.localReference:
          return localRefWorstResults;
        case CompletionGroup.paramReference:
          return paramRefWorstResults;
        case CompletionGroup.topLevel:
          return topLevelWorstResults;
      }
      return const <CompletionResult>[];
    }

    var worstResults = getWorstResults();
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

  final CompletionMetricsOptions options;

  ResolvedUnitResult _resolvedUnitResult;

  /// The int to be returned from the [compute] call.
  int resultCode;

  /// A list of the metrics to be computed.
  final List<CompletionMetrics> targetMetrics = [];

  final OverlayResourceProvider _provider =
      OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  int overlayModificationStamp = 0;

  CompletionMetricsComputer(this.rootPath, this.options);

  Future<int> compute() async {
    resultCode = 0;
    // To compare two or more changes to completions, add a `CompletionMetrics`
    // object with enable and disable functions to the list of `targetMetrics`.
    targetMetrics.add(CompletionMetrics('shipping', null, null));
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot);
    }
    printComparison();
    for (var metrics in targetMetrics) {
      printMetrics(metrics);

      print('');
      print('====================');
      rankComparison.printCounterValues();
      print('====================');

      if (options.printMissingInformation) {
        printMissingInformation(metrics);
      }
      if (options.printSlowestResults) {
        printSlowestResults(metrics);
      }
      if (options.printWorstResults) {
        printWorstResults(metrics);
      }
    }
    return resultCode;
  }

  int forEachExpectedCompletion(
      CompletionRequestImpl request,
      MetricsSuggestionListener listener,
      ExpectedCompletion expectedCompletion,
      String completionLocation,
      List<protocol.CompletionSuggestion> suggestions,
      CompletionMetrics metrics,
      int elapsedMS,
      bool doPrintMissedCompletions) {
    assert(suggestions != null);

    var place = placementInSuggestionList(suggestions, expectedCompletion);

    metrics.mrrComputer.addRank(place.rank);

    if (place.denominator != 0) {
      metrics.completionCounter.count('successful');

      metrics.recordCompletionResult(CompletionResult(place, request, listener,
          suggestions, expectedCompletion, completionLocation, elapsedMS));

      var charsBeforeTop =
          _computeCharsBeforeTop(expectedCompletion, suggestions);
      metrics.charsBeforeTop.addValue(charsBeforeTop);
      metrics.charsBeforeTopFive.addValue(
          _computeCharsBeforeTop(expectedCompletion, suggestions, minRank: 5));
      metrics.insertionLengthTheoretical
          .addValue(expectedCompletion.completion.length - charsBeforeTop);

      return place.rank;
    } else {
      metrics.completionCounter.count('unsuccessful');

      metrics.completionMissedTokenCounter.count(expectedCompletion.completion);
      metrics.completionKindCounter.count(expectedCompletion.kind.toString());
      metrics.completionElementKindCounter
          .count(expectedCompletion.elementKind.toString());

      if (doPrintMissedCompletions) {
        protocol.CompletionSuggestion closeMatchSuggestion;
        for (var suggestion in suggestions) {
          if (suggestion.completion == expectedCompletion.completion) {
            closeMatchSuggestion = suggestion;
          }
        }

        print('missing completion (${metrics.name}):');
        print('$expectedCompletion');
        if (closeMatchSuggestion != null) {
          print('    close matching completion that was in the list:');
          print('    $closeMatchSuggestion');
        }
        print('');
      }

      return -1;
    }
  }

  void printComparison() {
    List<String> toRow(Iterable<MeanReciprocalRankComputer> computers) {
      return [
        computers.first.name,
        for (var computer in computers) (1 / computer.mrr).toStringAsFixed(3),
      ];
    }

    var buffer = StringBuffer();
    var table = [
      ['', for (var metrics in targetMetrics) metrics.name],
      toRow(targetMetrics.map((metrics) => metrics.mrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.successfulMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.instanceMemberMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.staticMemberMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.typeRefMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.localRefMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.paramRefMrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.topLevelMrrComputer)),
    ];
    for (var i = 1; i < table[0].length; i++) {
      rightJustifyColumn(i, table);
    }
    buffer.writeTable(table);

    print('');
    print('Comparison of inverse mean reciprocal ranks (lower is better)');
    print('');
    print(buffer.toString());
  }

  void printMetrics(CompletionMetrics metrics) {
    print('====================');
    print('Completion metrics for ${metrics.name}:');
    print('');
    if (options.printMissedCompletionSummary) {
      metrics.completionMissedTokenCounter.printCounterValues();
      print('');

      metrics.completionKindCounter.printCounterValues();
      print('');

      metrics.completionElementKindCounter.printCounterValues();
      print('');
    }

    List<String> toRow(MeanReciprocalRankComputer computer) {
      return [
        computer.name,
        computer.mrr.toStringAsFixed(6),
        (1 / computer.mrr).toStringAsFixed(3),
        computer.mrr_5.toStringAsFixed(6),
        (1 / computer.mrr_5).toStringAsFixed(3),
        computer.count.toString(),
      ];
    }

    var buffer = StringBuffer();
    var table = [
      ['', 'mrr', 'inverse mrr', 'mrr_5', 'inverse mrr_5', 'count'],
      toRow(metrics.mrrComputer),
      toRow(metrics.successfulMrrComputer),
      toRow(metrics.instanceMemberMrrComputer),
      toRow(metrics.staticMemberMrrComputer),
      toRow(metrics.typeRefMrrComputer),
      toRow(metrics.localRefMrrComputer),
      toRow(metrics.paramRefMrrComputer),
      toRow(metrics.topLevelMrrComputer),
    ];
    rightJustifyColumn(2, table);
    rightJustifyColumn(4, table);
    rightJustifyColumn(5, table);
    buffer.writeTable(table);

    print('Mean Reciprocal Rank');
    print('');
    print(buffer.toString());

    if (options.printMrrByLocation) {
      var lines = <LocationTableLine>[];
      for (var entry in metrics.locationMrrComputers.entries) {
        var count = entry.value.count;
        var mrr = (1 / entry.value.mrr);
        var mrr_5 = (1 / entry.value.mrr_5);
        var product = count * mrr;
        lines.add(LocationTableLine(
            label: entry.key,
            product: product,
            count: count,
            mrr: mrr,
            mrr_5: mrr_5));
      }
      lines.sort((first, second) => second.product.compareTo(first.product));
      var table = <List<String>>[];
      table.add(['Location', 'Product', 'Count', 'Mrr', 'Mrr_5']);
      for (var line in lines) {
        var location = line.label;
        var product = line.product.truncate().toString();
        var count = line.count.toString();
        var mrr = line.mrr.toStringAsFixed(3);
        var mrr_5 = line.mrr_5.toStringAsFixed(3);
        table.add([location, product, count, mrr, mrr_5]);
      }
      var buffer = StringBuffer();
      buffer.writeTable(table);
      print(buffer.toString());
      print('');
    }

    metrics.charsBeforeTop.printMean();
    metrics.charsBeforeTopFive.printMean();
    metrics.insertionLengthTheoretical.printMean();
    print('');

    print('Summary for $rootPath:');
    metrics.meanCompletionMS.printMean();
    metrics.completionCounter.printCounterValues();
    print('====================');
  }

  void printMissingInformation(CompletionMetrics metrics) {
    var locations = metrics.missingCompletionLocations;
    if (locations.isNotEmpty) {
      print('');
      print('====================');
      print('Missing completion location in the following places:');
      for (var location in locations.toList()..sort()) {
        print('  $location');
      }
    }

    var tables = metrics.missingCompletionLocationTables;
    if (tables.isNotEmpty) {
      print('');
      print('====================');
      print('Missing tables for the following completion locations:');
      for (var table in tables.toList()..sort()) {
        print('  $table');
      }
    }
  }

  void printSlowestResults(CompletionMetrics metrics) {
    print('');
    print('====================');
    print('The slowest completion results to compute');
    _printSlowestResults(
        'Instance members', metrics.instanceMemberSlowestResults);
    _printSlowestResults('Static members', metrics.staticMemberSlowestResults);
    _printSlowestResults('Type references', metrics.typeRefSlowestResults);
    _printSlowestResults('Local references', metrics.localRefSlowestResults);
    _printSlowestResults(
        'Parameter references', metrics.paramRefSlowestResults);
    _printSlowestResults('Top level', metrics.topLevelSlowestResults);
  }

  void printWorstResults(CompletionMetrics metrics) {
    print('');
    print('====================');
    print('The worst completion results');
    _printWorstResults('Instance members', metrics.instanceMemberWorstResults);
    _printWorstResults('Static members', metrics.staticMemberWorstResults);
    _printWorstResults('Type references', metrics.topLevelWorstResults);
    _printWorstResults('Local references', metrics.localRefWorstResults);
    _printWorstResults('Parameter references', metrics.paramRefWorstResults);
    _printWorstResults('Top level', metrics.topLevelWorstResults);
  }

  int _computeCharsBeforeTop(ExpectedCompletion target,
      List<protocol.CompletionSuggestion> suggestions,
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

  Future<List<protocol.CompletionSuggestion>> _computeCompletionSuggestions(
      MetricsSuggestionListener listener,
      OperationPerformanceImpl performance,
      CompletionRequestImpl request,
      [DeclarationsTracker declarationsTracker,
      protocol.CompletionAvailableSuggestionsParams
          availableSuggestionsParams]) async {
    List<protocol.CompletionSuggestion> suggestions;

    if (declarationsTracker == null) {
      // available suggestions == false
      suggestions = await DartCompletionManager(
        dartdocDirectiveInfo: DartdocDirectiveInfo(),
        listener: listener,
      ).computeSuggestions(performance, request);
    } else {
      // available suggestions == true
      var includedElementKinds = <protocol.ElementKind>{};
      var includedElementNames = <String>{};
      var includedSuggestionRelevanceTagList =
          <protocol.IncludedSuggestionRelevanceTag>[];
      var includedSuggestionSetList = <protocol.IncludedSuggestionSet>[];
      suggestions = await DartCompletionManager(
        dartdocDirectiveInfo: DartdocDirectiveInfo(),
        includedElementKinds: includedElementKinds,
        includedElementNames: includedElementNames,
        includedSuggestionRelevanceTags: includedSuggestionRelevanceTagList,
        listener: listener,
      ).computeSuggestions(performance, request);

      computeIncludedSetList(declarationsTracker, request.result,
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
    DeclarationsTracker declarationsTracker;
    protocol.CompletionAvailableSuggestionsParams availableSuggestionsParams;
    if (options.availableSuggestions) {
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
            var resolvedUnitResult = _resolvedUnitResult;

            // If an overlay option is being used, compute the overlay file, and
            // have the context reanalyze the file
            if (options.overlay != OVERLAY_NONE) {
              var overlayContents = _getOverlayContents(
                  _resolvedUnitResult.content,
                  expectedCompletion,
                  options.overlay);

              _provider.setOverlay(filePath,
                  content: overlayContents,
                  modificationStamp: overlayModificationStamp++);
              (context as DriverBasedAnalysisContext)
                  .driver
                  .changeFile(filePath);
              resolvedUnitResult =
                  await context.currentSession.getResolvedUnit(filePath);
            }

            // As this point the completion suggestions are computed,
            // and results are collected with varying settings for
            // comparison:

            Future<int> handleExpectedCompletion(
                {MetricsSuggestionListener listener,
                @required CompletionMetrics metrics,
                @required bool printMissedCompletions}) async {
              var stopwatch = Stopwatch()..start();
              var request = CompletionRequestImpl(
                resolvedUnitResult,
                expectedCompletion.offset,
                CompletionPerformance(),
              );
              var directiveInfo = DartdocDirectiveInfo();

              OpType opType;
              List<protocol.CompletionSuggestion> suggestions;
              await request.performance.runRequestOperation(
                (performance) async {
                  var dartRequest = await DartCompletionRequestImpl.from(
                      performance, request, directiveInfo);
                  opType =
                      OpType.forCompletion(dartRequest.target, request.offset);
                  suggestions = await _computeCompletionSuggestions(
                    listener,
                    performance,
                    request,
                    declarationsTracker,
                    availableSuggestionsParams,
                  );
                },
              );
              stopwatch.stop();

              return forEachExpectedCompletion(
                  request,
                  listener,
                  expectedCompletion,
                  opType.completionLocation,
                  suggestions,
                  metrics,
                  stopwatch.elapsedMilliseconds,
                  printMissedCompletions);
            }

            var bestRank = -1;
            var bestName = '';
            for (var metrics in targetMetrics) {
              // Compute the completions.
              metrics.enable();
              var listener = MetricsSuggestionListener();
              var rank = await handleExpectedCompletion(
                  listener: listener,
                  metrics: metrics,
                  printMissedCompletions: options.printMissedCompletionDetails);
              if (bestRank < 0 || rank < bestRank) {
                bestRank = rank;
                bestName = metrics.name;
              }
              metrics.disable();
            }
            rankComparison.count(bestName);

            // If an overlay option is being used, remove the overlay applied
            // earlier
            if (options.overlay != OVERLAY_NONE) {
              _provider.removeOverlay(filePath);
            }
          }
        } catch (exception, stackTrace) {
          print('Exception caught analyzing: $filePath');
          print(exception.toString());
          print(stackTrace);
          resultCode = 1;
        }
      }
    }
  }

  List<protocol.CompletionSuggestion> _filterSuggestions(
      String prefix, List<protocol.CompletionSuggestion> suggestions) {
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

  void _printSlowestResults(
      String title, List<CompletionResult> slowestResults) {
    print('');
    print(title);
    for (var result in slowestResults) {
      var elapsedMS = result.elapsedMS;
      var expected = result.expectedCompletion;
      print('');
      print('  Elapsed ms: $elapsedMS');
      print('  Completion: ${expected.completion}');
      print('  Completion kind: ${expected.kind}');
      print('  Element kind: ${expected.elementKind}');
      print('  Location: ${expected.location}');
    }
  }

  void _printWorstResults(String title, List<CompletionResult> worstResults) {
    print('');
    print(title);
    for (var result in worstResults) {
      var rank = result.place.rank;
      var expected = result.expectedCompletion;
      var suggestions = result.suggestions;
      var suggestion = suggestions[rank - 1];

      var features = result.listener?.featureMap[suggestion];
      var topSuggestions =
          suggestions.sublist(0, math.min(10, suggestions.length));
      var topSuggestionCount = topSuggestions.length;

      var preceding = <int, int>{};
      for (var i = 0; i < rank - 1; i++) {
        var relevance = suggestions[i].relevance;
        preceding[relevance] = (preceding[relevance] ?? 0) + 1;
      }
      var precedingRelevances = preceding.keys.toList();
      precedingRelevances.sort();

      print('');
      print('  Rank: $rank');
      print('  Location: ${expected.location}');
      print('  Suggestion: ${suggestion.description}');
      print('  Features: $features');
      print('  Top $topSuggestionCount suggestions:');
      for (var i = 0; i < topSuggestionCount; i++) {
        var topSuggestion = topSuggestions[i];
        print('  $i Suggestion: ${topSuggestion.description}');
        if (result.listener != null) {
          var feature = result.listener.featureMap[topSuggestion];
          if (feature == null || feature.isEmpty) {
            print('    Features: <none>');
          } else {
            print('    Features: $feature');
          }
        }
      }
      print('  Preceding relevance scores and counts:');
      for (var relevance in precedingRelevances.reversed) {
        print('    $relevance: ${preceding[relevance]}');
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

  static Place placementInSuggestionList(
      List<protocol.CompletionSuggestion> suggestions,
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

/// The options specified on the command-line.
class CompletionMetricsOptions {
  /// A flag indicating whether available suggestions should be enabled for this
  /// run.
  final bool availableSuggestions;

  /// The overlay mode that should be used.
  final String overlay;

  /// A flag indicating whether information should be printed every time a
  /// completion request fails to produce a suggestions matching the expected
  /// suggestion.
  final bool printMissedCompletionDetails;

  /// A flag indicating whether information should be printed every time a
  /// completion request fails to produce a suggestions matching the expected
  /// suggestion.
  final bool printMissedCompletionSummary;

  /// A flag indicating whether information should be printed about places where
  /// no completion location was computed and about information that's missing
  /// in the completion tables.
  final bool printMissingInformation;

  /// A flag indicating whether information should be printed about the mrr
  /// score achieved at each completion location.
  final bool printMrrByLocation;

  /// A flag indicating whether information should be printed about the
  /// completion requests that were the slowest to return suggestions.
  final bool printSlowestResults;

  /// A flag indicating whether information should be printed about the
  /// completion requests that had the worst mrr scores.
  final bool printWorstResults;

  CompletionMetricsOptions(
      {@required this.availableSuggestions,
      @required this.overlay,
      @required this.printMissedCompletionDetails,
      @required this.printMissedCompletionSummary,
      @required this.printMissingInformation,
      @required this.printMrrByLocation,
      @required this.printSlowestResults,
      @required this.printWorstResults})
      : assert(overlay == OVERLAY_NONE ||
            overlay == OVERLAY_REMOVE_TOKEN ||
            overlay == OVERLAY_REMOVE_REST_OF_FILE);
}

/// The result of a single completion.
class CompletionResult {
  final Place place;

  final CompletionRequestImpl request;

  final MetricsSuggestionListener listener;

  final List<protocol.CompletionSuggestion> suggestions;

  final ExpectedCompletion expectedCompletion;

  final String completionLocation;

  final int elapsedMS;

  CompletionResult(this.place, this.request, this.listener, this.suggestions,
      this.expectedCompletion, this.completionLocation, this.elapsedMS);

  /// Return the completion group for the location at which completion was
  /// requested.
  CompletionGroup get group {
    var element = _getElement(expectedCompletion.syntacticEntity);
    if (element != null) {
      var parent = element.enclosingElement;
      if (parent is ClassElement || parent is ExtensionElement) {
        if (_isStatic(element)) {
          return CompletionGroup.staticMember;
        } else {
          return CompletionGroup.instanceMember;
        }
      } else if (expectedCompletion.elementKind == ElementKind.CLASS ||
          expectedCompletion.elementKind == ElementKind.MIXIN ||
          expectedCompletion.elementKind == ElementKind.ENUM ||
          expectedCompletion.elementKind == ElementKind.TYPE_PARAMETER) {
        return CompletionGroup.typeReference;
      } else if (expectedCompletion.elementKind == ElementKind.LOCAL_VARIABLE) {
        return CompletionGroup.localReference;
      } else if (expectedCompletion.elementKind == ElementKind.PARAMETER) {
        return CompletionGroup.paramReference;
      }
    }
    return CompletionGroup.topLevel;
  }

  /// Return the element associated with the syntactic [entity], or `null` if
  /// there is no such element.
  Element _getElement(SyntacticEntity entity) {
    if (entity is SimpleIdentifier) {
      return entity.staticElement;
    }
    return null;
  }

  /// Return `true` if the [element] is static (either top-level or a static
  /// member of a class or extension).
  bool _isStatic(Element element) {
    if (element is ClassMemberElement) {
      return element.isStatic;
    } else if (element is ExecutableElement) {
      return element.isStatic;
    } else if (element is FieldElement) {
      return element.isStatic;
    } else if (element is VariableElement) {
      return element.isStatic;
    }
    return true;
  }
}

/// The data to be printed on a single line in the table of mrr values per
/// completion location.
class LocationTableLine {
  final String label;
  final double product;
  final int count;
  final double mrr;
  final double mrr_5;

  LocationTableLine(
      {@required this.label,
      @required this.product,
      @required this.count,
      @required this.mrr,
      @required this.mrr_5});
}

class MetricsSuggestionListener implements SuggestionListener {
  Map<protocol.CompletionSuggestion, String> featureMap = {};

  String cachedFeatures = '';

  String missingCompletionLocation;
  String missingCompletionLocationTable;

  @override
  void builtSuggestion(protocol.CompletionSuggestion suggestion) {
    featureMap[suggestion] = cachedFeatures;
    cachedFeatures = '';
  }

  @override
  void computedFeatures(
      {double contextType,
      double elementKind,
      double hasDeprecated,
      double inheritanceDistance,
      double startsWithDollar,
      double superMatches}) {
    var buffer = StringBuffer();

    bool write(String label, double value, bool needsComma) {
      if (value != null) {
        if (needsComma) {
          buffer.write(', ');
        }
        buffer.write('$label: $value');
        return true;
      }
      return needsComma;
    }

    var needsComma = false;
    needsComma = write('contextType', contextType, needsComma);
    needsComma = write('elementKind', elementKind, needsComma);
    needsComma = write('hasDeprecated', hasDeprecated, needsComma);
    needsComma = write('inheritanceDistance', inheritanceDistance, needsComma);
    needsComma = write('startsWithDollar', startsWithDollar, needsComma);
    needsComma = write('superMatches', superMatches, needsComma);
    cachedFeatures = buffer.toString();
  }

  @override
  void missingCompletionLocationAt(AstNode parent, SyntacticEntity child) {
    if (missingCompletionLocation == null) {
      String className(SyntacticEntity entity) {
        var className = entity.runtimeType.toString();
        if (className.endsWith('Impl')) {
          className = className.substring(0, className.length - 4);
        }
        return className;
      }

      var parentClass = className(parent);
      var childClass = className(child);
      missingCompletionLocation = '$parentClass/$childClass';
    }
  }

  @override
  void missingElementKindTableFor(String completionLocation) {
    missingCompletionLocationTable = completionLocation;
  }
}

extension on protocol.CompletionSuggestion {
  /// A shorter description of the suggestion than [toString] provides.
  String get description =>
      json.encode(toJson()..remove('docSummary')..remove('docComplete'));
}

extension AvailableSuggestionsExtension on protocol.AvailableSuggestion {
  // TODO(jwren) I am not sure if we want CompletionSuggestionKind.INVOCATION in
  // call cases here, to iterate I need to figure out why this algorithm is
  // taking so much time.
  protocol.CompletionSuggestion toCompletionSuggestion(int relevance) =>
      protocol.CompletionSuggestion(
          protocol.CompletionSuggestionKind.INVOCATION,
          relevance,
          label,
          label.length,
          0,
          element.isDeprecated,
          false);
}
