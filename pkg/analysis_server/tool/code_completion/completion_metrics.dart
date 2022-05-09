// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/documentation_cache.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/completion/dart/probability_range.dart';
import 'package:analysis_server/src/services/completion/dart/relevance_tables.g.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart'
    show
        ClassElement,
        ClassMemberElement,
        CompilationUnitElement,
        Element,
        ExecutableElement,
        ExtensionElement,
        FieldElement,
        FunctionElement,
        LocalVariableElement,
        ParameterElement,
        PrefixElement,
        TypeParameterElement,
        VariableElement;
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:args/args.dart';

import 'metrics_util.dart';
import 'output_utilities.dart';
import 'relevance_table_generator.dart';
import 'visitors.dart';

/// Completion metrics are computed by taking a single package and iterating
/// over the compilation units in the package. For each unit we visit the AST
/// structure to find all of the places where completion suggestions should be
/// offered (essentially, everywhere that there's a keyword or identifier). At
/// each location we compute the completion suggestions using the same code path
/// used by the analysis server. We then compare the suggestions against the
/// token that was actually at that location in the file.
///
/// This approach has several drawbacks:
///
/// - The AST is always complete and correct, and that's rarely the case for
///   real completion requests. Usually the tree is incomplete and often has a
///   completely different structure because of the way recovery works. We
///   currently have no way of measuring completions under realistic conditions.
///
/// - We can't measure completions for several keywords because the presence of
///   the keyword in the AST causes it to not be suggested.
///
/// - The time it takes to compute the suggestions doesn't include the time
///   required to finish analyzing the file if the analysis hasn't been
///   completed before suggestions are requested. While the times are accurate
///   (within the accuracy of the `Stopwatch` class) they are the minimum
///   possible time. This doesn't give us a measure of how completion will
///   perform in production, but does give us an optimistic approximation.
///
/// The first is arguably the worst of the limitations of our current approach.
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (!validArguments(parser, result)) {
    return;
  }

  var options = CompletionMetricsOptions(result);
  var provider = PhysicalResourceProvider.INSTANCE;
  if (result.wasParsed('reduceDir')) {
    var targetMetrics = <CompletionMetrics>[];
    var dir = provider.getFolder(result['reduceDir'] as String);
    var computer = CompletionMetricsComputer('', options);
    for (var child in dir.getChildren()) {
      if (child is File) {
        var metricsList =
            (json.decode(child.readAsStringSync()) as List<dynamic>)
                .map((map) =>
                    CompletionMetrics.fromJson(map as Map<String, dynamic>))
                .toList();
        if (targetMetrics.isEmpty) {
          targetMetrics.addAll(metricsList);
        } else if (targetMetrics.length != metricsList.length) {
          throw StateError('metrics lengths differ');
        } else {
          for (var i = 0; i < targetMetrics.length; i++) {
            targetMetrics[i].addData(metricsList[i]);
          }
        }
      }
    }
    computer.targetMetrics.addAll(targetMetrics);
    computer.printResults();
    return;
  }

  var rootPath = result.rest[0];
  print('Analyzing root: "$rootPath"');
  var stopwatch = Stopwatch()..start();
  var computer = CompletionMetricsComputer(rootPath, options);
  await computer.computeMetrics();
  stopwatch.stop();

  var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
  print('');
  print('Metrics computed in $duration');

  if (result.wasParsed('mapFile')) {
    var mapFile = provider.getFile(result['mapFile'] as String);
    var map =
        computer.targetMetrics.map((metrics) => metrics.toJson()).toList();
    mapFile.writeAsStringSync(json.encode(map));
  } else {
    computer.printResults();
  }
}

/// A [Counter] to track the performance of each of the completion strategies
/// that are being compared.
Counter rankComparison = Counter('relevance rank comparison');

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  return ArgParser()
    ..addOption(
      'help',
      abbr: 'h',
      help: 'Print this help message.',
    )
    ..addOption(CompletionMetricsOptions.OVERLAY,
        allowed: [
          CompletionMetricsOptions.OVERLAY_NONE,
          CompletionMetricsOptions.OVERLAY_REMOVE_TOKEN,
          CompletionMetricsOptions.OVERLAY_REMOVE_REST_OF_FILE
        ],
        defaultsTo: CompletionMetricsOptions.OVERLAY_NONE,
        help:
            'Before attempting a completion at the location of each token, the '
            'token can be removed, or the rest of the file can be removed to '
            'test code completion with diverse methods. The default mode is to '
            'complete at the start of the token without modifying the file.')
    ..addFlag(CompletionMetricsOptions.PRINT_MISSED_COMPLETION_DETAILS,
        defaultsTo: false,
        help:
            'Print detailed information every time a completion request fails '
            'to produce a suggestions matching the expected suggestion.',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_MISSED_COMPLETION_SUMMARY,
        defaultsTo: false,
        help: 'Print summary information about the times that a completion '
            'request failed to produce a suggestions matching the expected '
            'suggestion.',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_MISSING_INFORMATION,
        defaultsTo: false,
        help: 'Print information about places where no completion location was '
            'computed and about information that is missing in the completion '
            'tables.',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_MRR_BY_LOCATION,
        defaultsTo: false,
        help:
            'Print information about the mrr score achieved at each completion '
            'location. This can help focus efforts to improve the overall '
            'score by pointing out the locations that are causing the biggest '
            'impact.',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_SHADOWED_COMPLETION_DETAILS,
        defaultsTo: false,
        help: 'Print detailed information every time a completion request '
            'produces a suggestions whose name matches the expected suggestion '
            'but that is referencing a different element',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_SLOWEST_RESULTS,
        defaultsTo: false,
        help: 'Print information about the completion requests that were the '
            'slowest to return suggestions.',
        negatable: false)
    ..addFlag(CompletionMetricsOptions.PRINT_WORST_RESULTS,
        defaultsTo: false,
        help: 'Print information about the completion requests that had the '
            'worst mrr scores.',
        negatable: false)
    ..addOption(
      'mapFile',
      help: 'The absolute path of the file to which the completion metrics '
          'data will be written. Using this option will prevent the completion '
          'results from being written in a textual form.',
    )
    ..addOption(
      'reduceDir',
      help: 'The absolute path of the directory from which the completion '
          'metrics data will be read.',
    );
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String? error}) {
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
  } else if (result.wasParsed('reduceDir')) {
    return validateDir(parser, result['reduceDir'] as String);
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No package path specified.');
    return false;
  }
  if (result.wasParsed('mapFile')) {
    var mapFilePath = result['mapFile'];
    if (mapFilePath is! String ||
        !PhysicalResourceProvider.INSTANCE.pathContext
            .isAbsolute(mapFilePath)) {
      printUsage(parser,
          error: 'The path "$mapFilePath" must be an absolute path.');
      return false;
    }
  }
  return validateDir(parser, result.rest[0]);
}

/// An indication of the group in which the completion falls for the purposes of
/// subdividing the results.
enum CompletionGroup {
  classElement,
  constructorElement,
  enumElement,
  extensionElement,

  /// An instance member of a class, enum, mixin or extension.
  instanceMember,

  labelElement,
  localFunctionElement,
  localVariableElement,
  mixinElement,
  parameterElement,
  prefixElement,

  /// A static member of a class, enum, mixin or extension.
  staticMember,

  topLevelMember,
  typeParameterElement,

  // Groups for keywords.

  keywordDynamic,
  keywordVoid,

  /// Anything that doesn't fit in one of the other groups.
  unknown,
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

  /// A flag indicating whether available suggestions should be enabled for this
  /// run.
  final bool availableSuggestions;

  /// A flag indicating whether the new protocol should be used for this run.
  final bool useNewProtocol;

  /// The function to be executed when this metrics collector is enabled.
  final void Function()? enableFunction;

  /// The function to be executed when this metrics collector is disabled.
  final void Function()? disableFunction;

  /// The tag used to profile performance of completions for this set of metrics.
  final UserTag userTag;

  final Counter completionCounter = Counter('all completions');

  final Counter completionMissedTokenCounter =
      Counter('unsuccessful completion token counter');

  final Counter completionKindCounter =
      Counter('unsuccessful completion kind counter');

  final Counter completionElementKindCounter =
      Counter('unsuccessful completion element kind counter');

  final ArithmeticMeanComputer meanCompletionMS =
      ArithmeticMeanComputer('ms per completion');

  final DistributionComputer distributionCompletionMS = DistributionComputer();

  final MeanReciprocalRankComputer mrrComputer =
      MeanReciprocalRankComputer('all completions');

  final MeanReciprocalRankComputer successfulMrrComputer =
      MeanReciprocalRankComputer('successful completions');

  /// A table mapping completion groups to the mrr computer used to track the
  /// quality of suggestions for those groups.
  final Map<CompletionGroup, MeanReciprocalRankComputer> groupMrrComputers = {};

  /// A table mapping locations to the mrr computer used to track the quality of
  /// suggestions for those locations.
  final Map<String, MeanReciprocalRankComputer> locationMrrComputers = {};

  final ArithmeticMeanComputer charsBeforeTop =
      ArithmeticMeanComputer('chars_before_top');

  final ArithmeticMeanComputer charsBeforeTopFive =
      ArithmeticMeanComputer('chars_before_top_five');

  final ArithmeticMeanComputer insertionLengthTheoretical =
      ArithmeticMeanComputer('insertion_length_theoretical');

  /// The places in which a completion location was requested when none was
  /// available.
  final Set<String> missingCompletionLocations = {};

  /// The completion locations for which no relevance table was available.
  final Set<String> missingCompletionLocationTables = {};

  /// A map, keyed by completion location of the missed completions at those
  /// locations.
  Map<String, List<ExpectedCompletion>> missedCompletions = {};

  /// A map, keyed by completion location of the completions at those locations
  /// where a shadowed element was suggested rather than the visible one.
  Map<String, List<ShadowedCompletion>> shadowedCompletions = {};

  final Map<CompletionGroup, List<CompletionResult>> slowestResults = {};

  final Map<CompletionGroup, List<CompletionResult>> worstResults = {};

  CompletionMetrics(this.name,
      {required this.availableSuggestions,
      this.useNewProtocol = false,
      this.enableFunction,
      this.disableFunction})
      : assert(!(availableSuggestions && useNewProtocol)),
        userTag = UserTag(name);

  /// Return an instance extracted from the decoded JSON [map].
  factory CompletionMetrics.fromJson(Map<String, dynamic> map) {
    var metrics = CompletionMetrics(map['name'] as String,
        availableSuggestions: map['availableSuggestions'] as bool);
    metrics.completionCounter
        .fromJson(map['completionCounter'] as Map<String, dynamic>);
    metrics.completionMissedTokenCounter
        .fromJson(map['completionMissedTokenCounter'] as Map<String, dynamic>);
    metrics.completionKindCounter
        .fromJson(map['completionKindCounter'] as Map<String, dynamic>);
    metrics.completionElementKindCounter
        .fromJson(map['completionElementKindCounter'] as Map<String, dynamic>);
    metrics.meanCompletionMS
        .fromJson(map['meanCompletionMS'] as Map<String, dynamic>);
    metrics.distributionCompletionMS
        .fromJson(map['distributionCompletionMS'] as Map<String, dynamic>);
    metrics.mrrComputer.fromJson(map['mrrComputer'] as Map<String, dynamic>);
    metrics.successfulMrrComputer
        .fromJson(map['successfulMrrComputer'] as Map<String, dynamic>);
    for (var entry
        in (map['groupMrrComputers'] as Map<String, dynamic>).entries) {
      var group = CompletionGroup.values[int.parse(entry.key)];
      metrics.groupMrrComputers[group] = MeanReciprocalRankComputer(group.name)
        ..fromJson(entry.value as Map<String, Object?>);
    }
    for (var entry
        in (map['locationMrrComputers'] as Map<String, dynamic>).entries) {
      var location = entry.key;
      metrics.locationMrrComputers[location] =
          MeanReciprocalRankComputer(location)
            ..fromJson(entry.value as Map<String, Object?>);
    }
    metrics.charsBeforeTop
        .fromJson(map['charsBeforeTop'] as Map<String, dynamic>);
    metrics.charsBeforeTopFive
        .fromJson(map['charsBeforeTopFive'] as Map<String, dynamic>);
    metrics.insertionLengthTheoretical
        .fromJson(map['insertionLengthTheoretical'] as Map<String, dynamic>);
    for (var element in map['missingCompletionLocations'] as List<dynamic>) {
      metrics.missingCompletionLocations.add(element as String);
    }
    for (var element
        in map['missingCompletionLocationTables'] as List<dynamic>) {
      metrics.missingCompletionLocationTables.add(element as String);
    }
    for (var entry in (map['slowestResults'] as Map<String, dynamic>).entries) {
      var group = CompletionGroup.values[int.parse(entry.key)];
      var results = (entry.value as List<dynamic>)
          .map((map) => CompletionResult.fromJson(map as Map<String, dynamic>))
          .toList();
      metrics.slowestResults[group] = results;
    }
    for (var entry in (map['worstResults'] as Map<String, dynamic>).entries) {
      var group = CompletionGroup.values[int.parse(entry.key)];
      var results = (entry.value as List<dynamic>)
          .map((map) => CompletionResult.fromJson(map as Map<String, dynamic>))
          .toList();
      metrics.worstResults[group] = results;
    }
    return metrics;
  }

  /// Add the data from the given [metrics] to this metrics.
  void addData(CompletionMetrics metrics) {
    completionCounter.addData(metrics.completionCounter);
    completionMissedTokenCounter.addData(metrics.completionMissedTokenCounter);
    completionKindCounter.addData(metrics.completionKindCounter);
    completionElementKindCounter.addData(metrics.completionElementKindCounter);
    meanCompletionMS.addData(metrics.meanCompletionMS);
    distributionCompletionMS.addData(metrics.distributionCompletionMS);
    mrrComputer.addData(metrics.mrrComputer);
    successfulMrrComputer.addData(metrics.successfulMrrComputer);
    for (var entry in metrics.groupMrrComputers.entries) {
      var group = entry.key;
      groupMrrComputers
          .putIfAbsent(group, () => MeanReciprocalRankComputer(group.name))
          .addData(entry.value);
    }
    for (var entry in metrics.locationMrrComputers.entries) {
      var location = entry.key;
      locationMrrComputers
          .putIfAbsent(location, () => MeanReciprocalRankComputer(location))
          .addData(entry.value);
    }
    charsBeforeTop.addData(metrics.charsBeforeTop);
    charsBeforeTopFive.addData(metrics.charsBeforeTopFive);
    insertionLengthTheoretical.addData(metrics.insertionLengthTheoretical);
    missingCompletionLocations.addAll(metrics.missingCompletionLocations);
    missingCompletionLocationTables
        .addAll(metrics.missingCompletionLocationTables);
    for (var resultList in metrics.slowestResults.values) {
      for (var result in resultList) {
        _recordSlowestResult(result);
      }
    }
    for (var resultList in metrics.worstResults.values) {
      for (var result in resultList) {
        _recordWorstResult(result);
      }
    }
  }

  /// Perform any operations required in order to revert computing the kind of
  /// completions represented by this metrics collector.
  void disable() {
    final disableFunction = this.disableFunction;
    if (disableFunction != null) {
      disableFunction();
    }
  }

  /// Perform any initialization required in order to compute the kind of
  /// completions represented by this metrics collector.
  void enable() {
    final enableFunction = this.enableFunction;
    if (enableFunction != null) {
      enableFunction();
    }
  }

  /// Record the completion [result]. This method handles the worst ranked items
  /// as well as the longest sets of results to compute.
  void recordCompletionResult(
      CompletionResult result, MetricsSuggestionListener listener) {
    _recordTime(result);
    _recordMrr(result);
    _recordWorstResult(result);
    _recordSlowestResult(result);
    _recordMissingInformation(listener);
  }

  /// Record an [expectedCompletion] at the [completionLocation] for which no
  /// suggestion was produced.
  void recordMissedCompletion(
      String? completionLocation, ExpectedCompletion expectedCompletion) {
    missedCompletions
        .putIfAbsent(completionLocation ?? 'unknown', () => [])
        .add(expectedCompletion);
  }

  /// Record an [expectedCompletion] at the [completionLocation] for which a
  /// suggestion (the [closeMatchSuggestion]) was produced when the suggestion
  /// was for a different element but with the same name.
  void recordShadowedCompletion(
      String? completionLocation,
      ExpectedCompletion expectedCompletion,
      protocol.CompletionSuggestion closeMatchSuggestion) {
    shadowedCompletions
        .putIfAbsent(completionLocation ?? 'unknown', () => [])
        .add(ShadowedCompletion(expectedCompletion, closeMatchSuggestion));
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'availableSuggestions': availableSuggestions,
      'completionCounter': completionCounter.toJson(),
      'completionMissedTokenCounter': completionMissedTokenCounter.toJson(),
      'completionKindCounter': completionKindCounter.toJson(),
      'completionElementKindCounter': completionElementKindCounter.toJson(),
      'meanCompletionMS': meanCompletionMS.toJson(),
      'distributionCompletionMS': distributionCompletionMS.toJson(),
      'mrrComputer': mrrComputer.toJson(),
      'successfulMrrComputer': successfulMrrComputer.toJson(),
      'groupMrrComputers': groupMrrComputers
          .map((key, value) => MapEntry(key.index.toString(), value.toJson())),
      'locationMrrComputers': locationMrrComputers
          .map((key, value) => MapEntry(key, value.toJson())),
      'charsBeforeTop': charsBeforeTop.toJson(),
      'charsBeforeTopFive': charsBeforeTopFive.toJson(),
      'insertionLengthTheoretical': insertionLengthTheoretical.toJson(),
      'missingCompletionLocations': missingCompletionLocations.toList(),
      'missingCompletionLocationTables':
          missingCompletionLocationTables.toList(),
      'slowestResults': slowestResults.map((key, value) => MapEntry(
          key.index.toString(),
          value.map((result) => result.toJson()).toList())),
      'worstResults': worstResults.map((key, value) => MapEntry(
          key.index.toString(),
          value.map((result) => result.toJson()).toList())),
    };
  }

  /// If the completion location was requested but missing when computing the
  /// [result], then record where that happened.
  void _recordMissingInformation(MetricsSuggestionListener listener) {
    var location = listener.missingCompletionLocation;
    if (location != null) {
      missingCompletionLocations.add(location);
    } else {
      location = listener.missingCompletionLocationTable;
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
    var group = result.group;
    groupMrrComputers
        .putIfAbsent(group, () => MeanReciprocalRankComputer(group.name))
        .addRank(rank);
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
    var results = slowestResults.putIfAbsent(result.group, () => []);
    if (results.length >= maxSlowestResults) {
      if (result.elapsedMS <= results.last.elapsedMS) {
        return;
      }
      results.removeLast();
    }
    results.add(result);
    results.sort((first, second) => second.elapsedMS - first.elapsedMS);
  }

  /// Record this elapsed ms count for the average ms count.
  void _recordTime(CompletionResult result) {
    meanCompletionMS.addValue(result.elapsedMS);
    distributionCompletionMS.addValue(result.elapsedMS);
  }

  /// If the [result] is worse than any previously recorded results, record it.
  void _recordWorstResult(CompletionResult result) {
    var results = worstResults.putIfAbsent(result.group, () => []);
    if (results.length >= maxWorstResults) {
      if (result.place.rank <= results.last.place.rank) {
        return;
      }
      results.removeLast();
    }
    results.add(result);
    results.sort((first, second) => second.place.rank - first.place.rank);
  }
}

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
class CompletionMetricsComputer {
  final String rootPath;

  final CompletionMetricsOptions options;

  late ResolvedUnitResult _resolvedUnitResult;

  /// A list of the metrics to be computed.
  final List<CompletionMetrics> targetMetrics = [];

  final OverlayResourceProvider _provider =
      OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);

  int overlayModificationStamp = 0;

  CompletionMetricsComputer(this.rootPath, this.options);

  /// Compare the metrics when each feature is used in isolation.
  void compareIndividualFeatures({bool availableSuggestions = false}) {
    var featureNames = FeatureComputer.featureNames;
    var featureCount = featureNames.length;
    for (var i = 0; i < featureCount; i++) {
      var weights = List.filled(featureCount, 0.00);
      weights[i] = 1.00;
      targetMetrics.add(CompletionMetrics(
        featureNames[i],
        availableSuggestions: availableSuggestions,
        enableFunction: () {
          FeatureComputer.featureWeights = weights;
        },
        disableFunction: () {
          FeatureComputer.featureWeights =
              FeatureComputer.defaultFeatureWeights;
        },
      ));
    }
  }

  /// Compare the relevance [tables] to the default relevance tables.
  void compareRelevanceTables(List<RelevanceTables> tables,
      {bool availableSuggestions = false}) {
    assert(tables.isNotEmpty);
    for (var tablePair in tables) {
      targetMetrics.add(CompletionMetrics(
        tablePair.name,
        availableSuggestions: availableSuggestions,
        enableFunction: () {
          elementKindRelevance = tablePair.elementKindRelevance;
          keywordRelevance = tablePair.keywordRelevance;
        },
        disableFunction: () {
          elementKindRelevance = defaultElementKindRelevance;
          keywordRelevance = defaultKeywordRelevance;
        },
      ));
    }
  }

  Future<void> computeMetrics() async {
    // To compare two or more changes to completions, add a `CompletionMetrics`
    // object with enable and disable functions to the list of `targetMetrics`.
    targetMetrics.add(CompletionMetrics('shipping',
        availableSuggestions: true,
        enableFunction: null,
        disableFunction: null));

    // To compare two or more relevance tables, uncomment the line below and
    // add the `RelevanceTables` to the list. The default relevance tables
    // should not be included in the list.
//    compareRelevanceTables([], availableSuggestions: false);

    // To compare the relative benefit from each of the features, uncomment the
    // line below.
//    compareIndividualFeatures(availableSuggestions: false);

    // To compare the new protocol to the old, uncomment the lines below.
//    targetMetrics.add(CompletionMetrics('new protocol',
//        availableSuggestions: false, useNewProtocol: true));

    final collection = AnalysisContextCollectionImpl(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot);
    }
  }

  int forEachExpectedCompletion(
      DartCompletionRequest request,
      MetricsSuggestionListener listener,
      ExpectedCompletion expectedCompletion,
      String? completionLocation,
      List<protocol.CompletionSuggestion> suggestions,
      CompletionMetrics metrics,
      int elapsedMS) {
    var place = placementInSuggestionList(suggestions, expectedCompletion);

    metrics.mrrComputer.addRank(place.rank);

    if (place.denominator != 0) {
      metrics.completionCounter.count('successful');

      var rank = place.rank;
      var suggestion = suggestions[rank - 1];
      var features = listener.featureMap[suggestion] ??
          MetricsSuggestionListener.noFeatures;
      var actualSuggestion = SuggestionData(suggestion, features);
      List<SuggestionData>? topSuggestions;
      Map<int, int>? precedingRelevanceCounts;
      if (options.printWorstResults) {
        var features = listener.featureMap[suggestion] ??
            MetricsSuggestionListener.noFeatures;
        topSuggestions = suggestions
            .sublist(0, math.min(10, suggestions.length))
            .map((suggestion) => SuggestionData(suggestion, features))
            .toList();
        precedingRelevanceCounts = <int, int>{};
        for (var i = 0; i < rank - 1; i++) {
          var relevance = suggestions[i].relevance;
          precedingRelevanceCounts[relevance] =
              (precedingRelevanceCounts[relevance] ?? 0) + 1;
        }
      }
      metrics.recordCompletionResult(
          CompletionResult(
              place,
              request,
              actualSuggestion,
              topSuggestions,
              precedingRelevanceCounts,
              expectedCompletion,
              completionLocation,
              elapsedMS),
          listener);

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

      if (options.printMissedCompletionDetails ||
          options.printShadowedCompletionDetails) {
        protocol.CompletionSuggestion? closeMatchSuggestion;
        for (var suggestion in suggestions) {
          if (suggestion.completion == expectedCompletion.completion) {
            closeMatchSuggestion = suggestion;
          }
        }

        if (closeMatchSuggestion == null &&
            options.printMissedCompletionDetails) {
          metrics.recordMissedCompletion(
              completionLocation, expectedCompletion);
        } else if (closeMatchSuggestion != null &&
            options.printShadowedCompletionDetails) {
          metrics.recordShadowedCompletion(
              completionLocation, expectedCompletion, closeMatchSuggestion);
        }
      }
      return -1;
    }
  }

  void printComparisonOfCompletionCounts() {
    String toString(int count, int totalCount) {
      return '$count (${printPercentage(count / totalCount, 2)})';
    }

    var counters = targetMetrics.map((metrics) => metrics.completionCounter);
    var table = [
      ['', for (var metrics in targetMetrics) metrics.name],
      ['total', for (var counter in counters) counter.totalCount.toString()],
      [
        'successful',
        for (var counter in counters)
          toString(counter.getCountOf('successful'), counter.totalCount)
      ],
      [
        'unsuccessful',
        for (var counter in counters)
          toString(counter.getCountOf('unsuccessful'), counter.totalCount)
      ],
    ];
    rightJustifyColumns(table, range(1, table[0].length));

    printHeading(2, 'Comparison of completion counts');
    printTable(table);
  }

  void printComparisonOfOtherMetrics() {
    List<String> toRow(Iterable<ArithmeticMeanComputer> sources) {
      var computers = sources.toList();
      var row = [computers.first.name];
      for (var computer in computers) {
        var min = computer.min;
        var mean = computer.mean.toStringAsFixed(6);
        var max = computer.max;
        row.add('$min, $mean, $max');
      }
      return row;
    }

    var table = [
      ['', for (var metrics in targetMetrics) metrics.name],
      toRow(targetMetrics.map((metrics) => metrics.meanCompletionMS)),
      toRow(targetMetrics.map((metrics) => metrics.charsBeforeTop)),
      toRow(targetMetrics.map((metrics) => metrics.charsBeforeTopFive)),
      toRow(targetMetrics.map((metrics) => metrics.insertionLengthTheoretical)),
    ];
    rightJustifyColumns(table, range(1, table[0].length));

    printHeading(2, 'Comparison of other metrics');
    printTable(table);

    for (var metrics in targetMetrics) {
      var distribution = metrics.distributionCompletionMS.displayString();
      print('${metrics.name}: $distribution');
    }
    print('');
  }

  void printComparisons() {
    printHeading(1, 'Comparison of experiments');
    printMrrComparison();
    printCounter(rankComparison);
    printComparisonOfOtherMetrics();
    printComparisonOfCompletionCounts();
  }

  void printCompletionCounts(CompletionMetrics metrics) {
    String toString(int count, int totalCount) {
      return '$count (${printPercentage(count / totalCount, 2)})';
    }

    var counter = metrics.completionCounter;
    var table = [
      ['', metrics.name],
      ['total', counter.totalCount.toString()],
      [
        'successful',
        toString(counter.getCountOf('successful'), counter.totalCount)
      ],
      [
        'unsuccessful',
        toString(counter.getCountOf('unsuccessful'), counter.totalCount)
      ],
    ];
    rightJustifyColumns(table, range(1, table[0].length));

    printHeading(2, 'Completion counts');
    printTable(table);
  }

  void printCounter(Counter counter) {
    var name = counter.name;
    var total = counter.totalCount;
    printHeading(2, "Counts for '$name' (total = $total)");
    counter.printCounterValues();
  }

  void printHeading(int level, String heading) {
    var prefix = '#' * level;
    print('$prefix $heading');
    print('');
  }

  void printMetrics(CompletionMetrics metrics) {
    printHeading(1, 'Completion metrics for ${metrics.name}');

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

    var entries = metrics.groupMrrComputers.entries.toList();
    entries.sort((first, second) => first.key.name.compareTo(second.key.name));
    var table = [
      ['', 'mrr', 'inverse mrr', 'mrr_5', 'inverse mrr_5', 'count'],
      toRow(metrics.mrrComputer),
      toRow(metrics.successfulMrrComputer),
      ['', '', '', '', '', ''],
      for (var entry in entries) toRow(entry.value),
    ];
    rightJustifyColumns(table, [2, 4, 5]);

    printHeading(2, 'Mean Reciprocal Rank');
    printTable(table);

    if (options.printMrrByLocation) {
      var lines = <LocationTableLine>[];
      for (var entry in metrics.locationMrrComputers.entries) {
        var count = entry.value.count;
        var mrr = 1 / entry.value.mrr;
        var mrr_5 = 1 / entry.value.mrr_5;
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
      printTable(table);
    }
    //
    // Print information that would normally appear in the comparison section
    // when there is no comparison section.
    //
    if (targetMetrics.length == 1) {
      printOtherMetrics(metrics);
      printCompletionCounts(metrics);
    }
    //
    // Print information about missed completions.
    //
    if (options.printMissedCompletionSummary) {
      printCounter(metrics.completionMissedTokenCounter);
      printCounter(metrics.completionKindCounter);
      printCounter(metrics.completionElementKindCounter);
    }
    printMissedCompletionDetails(metrics);
    printShadowedCompletionDetails(metrics);
  }

  void printMissedCompletionDetails(CompletionMetrics metrics) {
    if (options.printMissedCompletionDetails) {
      printHeading(2, 'Missed Completions');
      var needsBlankLine = false;
      var entries = metrics.missedCompletions.entries.toList()
        ..sort((first, second) => first.key.compareTo(second.key));
      for (var entry in entries) {
        if (needsBlankLine) {
          print('');
        } else {
          needsBlankLine = true;
        }
        printHeading(3, entry.key);
        for (var expectedCompletion in entry.value) {
          print('- $expectedCompletion');
        }
      }
    }
  }

  void printMissingInformation(CompletionMetrics metrics) {
    var locations = metrics.missingCompletionLocations;
    if (locations.isNotEmpty) {
      print('');
      printHeading(2, 'Missing completion location in the following places');
      for (var location in locations.toList()..sort()) {
        print('- $location');
      }
    }

    var tables = metrics.missingCompletionLocationTables;
    if (tables.isNotEmpty) {
      print('');
      printHeading(2, 'Missing tables for the following completion locations');
      for (var table in tables.toList()..sort()) {
        print('- $table');
      }
    }
  }

  void printMrrComparison() {
    List<String> toRow(Iterable<MeanReciprocalRankComputer> sources) {
      var computers = sources.toList();
      var baseComputer = computers.first;
      var row = [baseComputer.name];
      var baseInverseMrr = 1 / baseComputer.mrr;
      row.add(baseInverseMrr.toStringAsFixed(3));
      for (var i = 1; i < computers.length; i++) {
        var inverseMrr = 1 / computers[i].mrr;
        var delta = inverseMrr - baseInverseMrr;
        row.add('|');
        row.add(inverseMrr.toStringAsFixed(3));
        row.add(delta.toStringAsFixed(3));
      }
      return row;
    }

    var columnHeaders = [' ', targetMetrics[0].name];
    for (var i = 1; i < targetMetrics.length; i++) {
      columnHeaders.add('|');
      columnHeaders.add('${targetMetrics[i].name}');
      columnHeaders.add('delta');
    }
    var blankRow = [for (int i = 0; i < columnHeaders.length; i++) ''];
    var table = [
      columnHeaders,
      toRow(targetMetrics.map((metrics) => metrics.mrrComputer)),
      toRow(targetMetrics.map((metrics) => metrics.successfulMrrComputer)),
      blankRow,
    ];
    var elementKinds = targetMetrics
        .expand((metrics) => metrics.groupMrrComputers.keys)
        .toSet()
        .toList();
    elementKinds.sort((first, second) => first.name.compareTo(second.name));
    for (var kind in elementKinds) {
      table.add(toRow(targetMetrics.map((metrics) =>
          metrics.groupMrrComputers[kind] ??
          MeanReciprocalRankComputer(kind.name))));
    }
    if (options.printMrrByLocation) {
      table.add(blankRow);
      var locations = targetMetrics
          .expand((metrics) => metrics.locationMrrComputers.keys)
          .toSet()
          .toList();
      locations.sort();
      for (var location in locations) {
        table.add(toRow(targetMetrics.map((metrics) =>
            metrics.locationMrrComputers[location] ??
            MeanReciprocalRankComputer(location))));
      }
    }
    rightJustifyColumns(table, range(1, table[0].length));

    printHeading(2, 'Comparison of inverse mean reciprocal ranks');
    print('A lower value is better, so a negative delta is good.');
    print('');
    printTable(table);
  }

  void printOtherMetrics(CompletionMetrics metrics) {
    List<String> toRow(ArithmeticMeanComputer computer) {
      var min = computer.min;
      var mean = computer.mean.toStringAsFixed(6);
      var max = computer.max;
      return [computer.name, '$min, $mean, $max'];
    }

    var table = [
      toRow(metrics.meanCompletionMS),
      toRow(metrics.charsBeforeTop),
      toRow(metrics.charsBeforeTopFive),
      toRow(metrics.insertionLengthTheoretical),
    ];
    rightJustifyColumns(table, range(1, table[0].length));

    printHeading(2, 'Other metrics');
    printTable(table);

    var distribution = metrics.distributionCompletionMS.displayString();
    print('${metrics.name}: $distribution');
    print('');
  }

  void printResults() {
    print('');
    if (targetMetrics.length > 1) {
      printComparisons();
    }
    var needsBlankLine = false;
    for (var metrics in targetMetrics) {
      if (needsBlankLine) {
        print('');
      } else {
        needsBlankLine = true;
      }
      printMetrics(metrics);

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
  }

  void printShadowedCompletionDetails(CompletionMetrics metrics) {
    if (options.printShadowedCompletionDetails) {
      printHeading(2, 'Shadowed Completions');
      var needsBlankLine = false;
      var entries = metrics.shadowedCompletions.entries.toList()
        ..sort((first, second) => first.key.compareTo(second.key));
      for (var entry in entries) {
        if (needsBlankLine) {
          print('');
        } else {
          needsBlankLine = true;
        }
        printHeading(3, entry.key);
        for (var shadowedCompletion in entry.value) {
          print('- ${shadowedCompletion.expectedCompletion}');
          print('    close matching completion that was in the list:');
          print('    ${shadowedCompletion.closeMatchSuggestion}');
        }
      }
    }
  }

  void printSlowestResults(CompletionMetrics metrics) {
    var slowestResults = metrics.slowestResults;
    var entries = slowestResults.entries.toList();
    entries.sort((first, second) => first.key.name.compareTo(second.key.name));
    print('');
    printHeading(2, 'The slowest completion results to compute');
    for (var entry in entries) {
      _printSlowestResults('In ${entry.key.name}', entry.value);
    }
  }

  void printWorstResults(CompletionMetrics metrics) {
    var worstResults = metrics.worstResults;
    var entries = worstResults.entries.toList();
    entries.sort((first, second) => first.key.name.compareTo(second.key.name));
    print('');
    printHeading(2, 'The worst completion results');
    for (var entry in entries) {
      _printWorstResults('In ${entry.key.name}', entry.value);
    }
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
      DartCompletionRequest dartRequest,
      [DeclarationsTracker? declarationsTracker,
      protocol.CompletionAvailableSuggestionsParams? availableSuggestionsParams,
      NotImportedSuggestions? notImportedSuggestions]) async {
    List<protocol.CompletionSuggestion> suggestions;

    var budget = CompletionBudget(Duration(seconds: 30));
    if (declarationsTracker == null) {
      // available suggestions == false
      var serverSuggestions = await DartCompletionManager(
        budget: budget,
        listener: listener,
        notImportedSuggestions: notImportedSuggestions,
      ).computeSuggestions(dartRequest, performance);
      suggestions = serverSuggestions.map((serverSuggestion) {
        return serverSuggestion.build();
      }).toList();
    } else {
      // available suggestions == true
      var includedElementKinds = <protocol.ElementKind>{};
      var includedElementNames = <String>{};
      var includedSuggestionRelevanceTagList =
          <protocol.IncludedSuggestionRelevanceTag>[];
      var includedSuggestionSetList = <protocol.IncludedSuggestionSet>[];
      var serverSuggestions = await DartCompletionManager(
        budget: budget,
        includedElementKinds: includedElementKinds,
        includedElementNames: includedElementNames,
        includedSuggestionRelevanceTags: includedSuggestionRelevanceTagList,
        listener: listener,
      ).computeSuggestions(dartRequest, performance);
      suggestions = serverSuggestions.map((serverSuggestion) {
        return serverSuggestion.build();
      }).toList();

      computeIncludedSetList(declarationsTracker, dartRequest,
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
          in availableSuggestionsParams!.changedLibraries!) {
        var id = availableSuggestionSet.id;
        for (var availableSuggestion in availableSuggestionSet.items) {
          // Exclude available suggestions where this element kind doesn't match
          // an element kind in includedElementKinds.
          var elementKind = availableSuggestion.element.kind;
          if (includedElementKinds.contains(elementKind)) {
            if (includedSuggestionSetMap.containsKey(id)) {
              var relevance = includedSuggestionSetMap[id]!.relevance;

              // Search for any matching relevance tags to apply any boosts
              if (includedSuggestionRelevanceTagList.isNotEmpty &&
                  availableSuggestion.relevanceTags != null &&
                  availableSuggestion.relevanceTags!.isNotEmpty) {
                for (var tag in availableSuggestion.relevanceTags!) {
                  if (includedSuggestionRelevanceTagMap.containsKey(tag)) {
                    // apply the boost
                    relevance += includedSuggestionRelevanceTagMap[tag]!;
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
    final collection = AnalysisContextCollectionImpl(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: _provider,
    );

    var context = collection.contexts[0];

    // Set the DeclarationsTracker, only call doWork to build up the available
    // suggestions if doComputeCompletionsFromAnalysisServer is true.
    DeclarationsTracker? declarationsTracker;
    protocol.CompletionAvailableSuggestionsParams? availableSuggestionsParams;
    if (targetMetrics.any((metrics) => metrics.availableSuggestions)) {
      declarationsTracker = DeclarationsTracker(
          MemoryByteStore(), PhysicalResourceProvider.INSTANCE);
      declarationsTracker.addContext(context);
      while (declarationsTracker.hasWork) {
        declarationsTracker.doWork();
      }

      // Have the AvailableDeclarationsSet computed to use later.
      availableSuggestionsParams = createCompletionAvailableSuggestions(
          declarationsTracker.allLibraries.toList(), []);
    }

    // Loop through each file, resolve the file and call
    // forEachExpectedCompletion

    var dartdocDirectiveInfo = DartdocDirectiveInfo();
    var documentationCache = DocumentationCache(dartdocDirectiveInfo);
    var results = <ResolvedUnitResult>[];
    var pathContext = context.contextRoot.resourceProvider.pathContext;
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (file_paths.isDart(pathContext, filePath)) {
        try {
          var result = await context.currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

          var analysisError = getFirstErrorOrNull(result);
          if (analysisError != null) {
            print('File $filePath skipped due to errors such as:');
            print('  ${analysisError.toString()}');
            print('');
            continue;
          } else {
            results.add(result);
            documentationCache.cacheFromResult(result);
          }
        } catch (exception, stackTrace) {
          print('Exception caught analyzing: $filePath');
          print(exception.toString());
          print(stackTrace);
        }
      }
    }
    for (var result in results) {
      _resolvedUnitResult = result;
      var filePath = result.path;
      // Use the ExpectedCompletionsVisitor to compute the set of expected
      // completions for this CompilationUnit.
      final visitor = ExpectedCompletionsVisitor(result);
      _resolvedUnitResult.unit.accept(visitor);

      for (var expectedCompletion in visitor.expectedCompletions) {
        var resolvedUnitResult = _resolvedUnitResult;

        // If an overlay option is being used, compute the overlay file, and
        // have the context reanalyze the file
        if (options.overlay != CompletionMetricsOptions.OVERLAY_NONE) {
          var overlayContents = _getOverlayContents(
              _resolvedUnitResult.content, expectedCompletion);

          _provider.setOverlay(filePath,
              content: overlayContents,
              modificationStamp: overlayModificationStamp++);
          context.driver.changeFile(filePath);
          resolvedUnitResult = await context.currentSession
              .getResolvedUnit(filePath) as ResolvedUnitResult;
        }

        // As this point the completion suggestions are computed,
        // and results are collected with varying settings for
        // comparison:

        Future<int> handleExpectedCompletion(
            {required MetricsSuggestionListener listener,
            required CompletionMetrics metrics}) async {
          var stopwatch = Stopwatch()..start();
          var request = DartCompletionRequest.forResolvedUnit(
            resolvedUnit: resolvedUnitResult,
            offset: expectedCompletion.offset,
            documentationCache: documentationCache,
          );

          var opType = OpType.forCompletion(request.target, request.offset);
          var suggestions = await _computeCompletionSuggestions(
            listener,
            OperationPerformanceImpl('<root>'),
            request,
            metrics.availableSuggestions ? declarationsTracker : null,
            metrics.availableSuggestions ? availableSuggestionsParams : null,
            metrics.useNewProtocol ? NotImportedSuggestions() : null,
          );
          stopwatch.stop();

          return forEachExpectedCompletion(
              request,
              listener,
              expectedCompletion,
              opType.completionLocation,
              suggestions,
              metrics,
              stopwatch.elapsedMilliseconds);
        }

        var bestRank = -1;
        var bestName = '';
        var defaultTag = getCurrentTag();
        for (var metrics in targetMetrics) {
          // Compute the completions.
          metrics.enable();
          metrics.userTag.makeCurrent();
          var listener = MetricsSuggestionListener();
          var rank = await handleExpectedCompletion(
              listener: listener, metrics: metrics);
          if (bestRank < 0 || rank < bestRank) {
            bestRank = rank;
            bestName = metrics.name;
          }
          defaultTag.makeCurrent();
          metrics.disable();
        }
        rankComparison.count(bestName);

        // If an overlay option is being used, remove the overlay applied
        // earlier.
        if (options.overlay != CompletionMetricsOptions.OVERLAY_NONE) {
          _provider.removeOverlay(filePath);
        }
      }
    }
  }

  List<protocol.CompletionSuggestion> _filterSuggestions(
      String prefix, List<protocol.CompletionSuggestion> suggestions) {
    // TODO(brianwilkerson) Replace this with a more realistic filtering
    //  algorithm.
    return suggestions
        .where((suggestion) => suggestion.completion.startsWith(prefix))
        .toList();
  }

  String _getOverlayContents(
      String contents, ExpectedCompletion expectedCompletion) {
    assert(contents.isNotEmpty);
    var offset = expectedCompletion.offset;
    var length = expectedCompletion.syntacticEntity.length;
    assert(offset >= 0);
    assert(length > 0);
    if (options.overlay == CompletionMetricsOptions.OVERLAY_REMOVE_TOKEN) {
      return contents.substring(0, offset) +
          contents.substring(offset + length);
    } else if (options.overlay ==
        CompletionMetricsOptions.OVERLAY_REMOVE_REST_OF_FILE) {
      return contents.substring(0, offset);
    } else {
      var removeToken = CompletionMetricsOptions.OVERLAY_REMOVE_TOKEN;
      var removeRest = CompletionMetricsOptions.OVERLAY_REMOVE_REST_OF_FILE;
      throw Exception('\'_getOverlayContents\' called with option other than'
          '$removeToken and $removeRest: ${options.overlay}');
    }
  }

  void _printSlowestResults(
      String title, List<CompletionResult> slowestResults) {
    printHeading(3, title);
    var needsBlankLine = false;
    for (var result in slowestResults) {
      var elapsedMS = result.elapsedMS;
      var expected = result.expectedCompletion;
      if (needsBlankLine) {
        print('');
      } else {
        needsBlankLine = true;
      }
      print('  Elapsed ms: $elapsedMS');
      print('  Completion: ${expected.completion}');
      print('  Completion kind: ${expected.kind}');
      print('  Element kind: ${expected.elementKind}');
      print('  Location: ${expected.location}');
    }
  }

  void _printWorstResults(String title, List<CompletionResult> worstResults) {
    List<String> suggestionRow(int rank, SuggestionData data) {
      var suggestion = data.suggestion;
      return [
        rank.toString(),
        suggestion.relevance.toString(),
        suggestion.completion,
        suggestion.kind.toString()
      ];
    }

    List<String> featuresRow(int rank, SuggestionData data) {
      var features = data.features;
      return [
        rank.toString(),
        for (var feature in features) feature.toStringAsFixed(4)
      ];
    }

    printHeading(3, title);
    var needsBlankLine = false;
    for (var result in worstResults) {
      var rank = result.place.rank;
      var actualSuggestion = result.actualSuggestion;
      var expected = result.expectedCompletion;

      var topSuggestions = result.topSuggestions!;
      var topSuggestionCount = topSuggestions.length;

      var preceding = result.precedingRelevanceCounts!;
      var precedingRelevances = preceding.keys.toList();
      precedingRelevances.sort();

      var suggestionsTable = [
        ['Rank', 'Relevance', 'Completion', 'Kind']
      ];
      for (var i = 0; i < topSuggestionCount; i++) {
        suggestionsTable.add(suggestionRow(i, topSuggestions[i]));
      }
      suggestionsTable.add(suggestionRow(rank, actualSuggestion));
      rightJustifyColumns(suggestionsTable, [0, 1]);

      var featuresTable = [
        [
          'Rank',
          'contextType',
          'elementKind',
          'hasDeprecated',
          'isConstant',
          'isNoSuchMethod',
          'keyword',
          'startsWithDollar',
          'superMatches',
          'inheritanceDistance',
          'localVariableDistance',
        ]
      ];
      for (var i = 0; i < topSuggestionCount; i++) {
        featuresTable.add(featuresRow(i, topSuggestions[i]));
      }
      featuresTable.add(featuresRow(rank, actualSuggestion));
      rightJustifyColumns(featuresTable, range(0, featuresTable[0].length));

      if (needsBlankLine) {
        print('');
      } else {
        needsBlankLine = true;
      }
      print('  Rank: $rank');
      print('  Location: ${expected.location}');
      print('  Comparison with the top $topSuggestionCount suggestions:');
      printTable(suggestionsTable);
      print('  Comparison of features with the top $topSuggestionCount '
          'suggestions:');
      printTable(featuresTable);
      print('  Preceding relevance scores and counts:');
      for (var relevance in precedingRelevances.reversed) {
        print('    $relevance: ${preceding[relevance]}');
      }
    }
  }

  /// Given some [ResolvedUnitResult] return the first error of high severity
  /// if such an error exists, `null` otherwise.
  static err.AnalysisError? getFirstErrorOrNull(
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
  /// An option to control whether and how overlays should be produced.
  static const String OVERLAY = 'overlay';

  /// A mode indicating that no overlays should be produced.
  static const String OVERLAY_NONE = 'none';

  /// A mode indicating that everything from the completion offset to the end of
  /// the file should be removed.
  static const String OVERLAY_REMOVE_REST_OF_FILE = 'remove-rest-of-file';

  /// A mode indicating that the token whose offset is the same as the
  /// completion offset should be removed.
  static const String OVERLAY_REMOVE_TOKEN = 'remove-token';

  /// A flag that causes detailed information to be printed every time a
  /// completion request fails to produce a suggestions matching the expected
  /// suggestion.
  static const String PRINT_MISSED_COMPLETION_DETAILS =
      'print-missed-completion-details';

  /// A flag that causes summary information to be printed about the times that
  /// a completion request failed to produce a suggestions matching the expected
  /// suggestion.
  static const String PRINT_MISSED_COMPLETION_SUMMARY =
      'print-missed-completion-summary';

  /// A flag that causes information to be printed about places where no
  /// completion location was computed and about information that's missing in
  /// the completion tables.
  static const String PRINT_MISSING_INFORMATION = 'print-missing-information';

  /// A flag that causes information to be printed about the mrr score achieved
  /// at each completion location.
  static const String PRINT_MRR_BY_LOCATION = 'print-mrr-by-location';

  /// A flag that causes detailed information to be printed every time a
  /// completion request produce a suggestions whose name matches the expected
  /// suggestion but that is referencing a different element (one that's
  /// shadowed by the correct element).
  static const String PRINT_SHADOWED_COMPLETION_DETAILS =
      'print-shadowed-completion-details';

  /// A flag that causes information to be printed about the completion requests
  /// that were the slowest to return suggestions.
  static const String PRINT_SLOWEST_RESULTS = 'print-slowest-results';

  /// A flag that causes information to be printed about the completion requests
  /// that had the worst mrr scores.
  static const String PRINT_WORST_RESULTS = 'print-worst-results';

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

  /// A flag indicating whether information should be printed every time a
  /// completion request fails to produce a suggestions matching the expected
  /// suggestion.
  final bool printShadowedCompletionDetails;

  /// A flag indicating whether information should be printed about the
  /// completion requests that were the slowest to return suggestions.
  final bool printSlowestResults;

  /// A flag indicating whether information should be printed about the
  /// completion requests that had the worst mrr scores.
  final bool printWorstResults;

  factory CompletionMetricsOptions(results) {
    return CompletionMetricsOptions._(
        overlay: results[OVERLAY] as String,
        printMissedCompletionDetails:
            results[PRINT_MISSED_COMPLETION_DETAILS] as bool,
        printMissedCompletionSummary:
            results[PRINT_MISSED_COMPLETION_SUMMARY] as bool,
        printMissingInformation: results[PRINT_MISSING_INFORMATION] as bool,
        printMrrByLocation: results[PRINT_MRR_BY_LOCATION] as bool,
        printShadowedCompletionDetails:
            results[PRINT_SHADOWED_COMPLETION_DETAILS] as bool,
        printSlowestResults: results[PRINT_SLOWEST_RESULTS] as bool,
        printWorstResults: results[PRINT_WORST_RESULTS] as bool);
  }

  CompletionMetricsOptions._(
      {required this.overlay,
      required this.printMissedCompletionDetails,
      required this.printMissedCompletionSummary,
      required this.printMissingInformation,
      required this.printMrrByLocation,
      required this.printShadowedCompletionDetails,
      required this.printSlowestResults,
      required this.printWorstResults})
      : assert(overlay == OVERLAY_NONE ||
            overlay == OVERLAY_REMOVE_TOKEN ||
            overlay == OVERLAY_REMOVE_REST_OF_FILE);
}

/// The result of a single completion.
class CompletionResult {
  final Place place;

  final DartCompletionRequest? request;

  final SuggestionData actualSuggestion;

  final List<SuggestionData>? topSuggestions;

  final ExpectedCompletion expectedCompletion;

  final String? completionLocation;

  final int elapsedMS;

  final Map<int, int>? precedingRelevanceCounts;

  CompletionResult(
      this.place,
      this.request,
      this.actualSuggestion,
      this.topSuggestions,
      this.precedingRelevanceCounts,
      this.expectedCompletion,
      this.completionLocation,
      this.elapsedMS);

  /// Return an instance extracted from the decoded JSON [map].
  factory CompletionResult.fromJson(Map<String, dynamic> map) {
    var place = Place.fromJson(map['place'] as Map<String, dynamic>);
    var actualSuggestion = SuggestionData.fromJson(
        map['actualSuggestion'] as Map<String, dynamic>);
    var topSuggestions = (map['topSuggestions'] as List<dynamic>)
        .map((map) => SuggestionData.fromJson(map as Map<String, dynamic>))
        .toList();
    var precedingRelevanceCounts =
        (map['precedingRelevanceCounts'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(int.parse(key), value as int));
    var expectedCompletion = ExpectedCompletion.fromJson(
        map['expectedCompletion'] as Map<String, dynamic>);
    var completionLocation = map['completionLocation'] as String;
    var elapsedMS = map['elapsedMS'] as int;
    return CompletionResult(
        place,
        null,
        actualSuggestion,
        topSuggestions,
        precedingRelevanceCounts,
        expectedCompletion,
        completionLocation,
        elapsedMS);
  }

  /// Return the completion group for the location at which completion was
  /// requested.
  CompletionGroup get group {
    var entity = expectedCompletion.syntacticEntity;
    var element = _getElement(entity);
    if (element != null) {
      var parent = element.enclosingElement;
      if (parent is ClassElement || parent is ExtensionElement) {
        if (_isStatic(element)) {
          return CompletionGroup.staticMember;
        } else {
          return CompletionGroup.instanceMember;
        }
      } else if (parent is CompilationUnitElement &&
          element is! ClassElement &&
          element is! ExtensionElement) {
        return CompletionGroup.topLevelMember;
      }
      if (element is ClassElement) {
        if (element.isEnum) {
          return CompletionGroup.enumElement;
        } else if (element.isMixin) {
          return CompletionGroup.mixinElement;
        }
        if (entity is SimpleIdentifier &&
            entity.parent is NamedType &&
            entity.parent!.parent is ConstructorName &&
            entity.parent!.parent!.parent is InstanceCreationExpression) {
          return CompletionGroup.constructorElement;
        }
        return CompletionGroup.classElement;
      } else if (element is ExtensionElement) {
        return CompletionGroup.extensionElement;
      } else if (element is FunctionElement) {
        return CompletionGroup.localFunctionElement;
      } else if (element is LocalVariableElement) {
        return CompletionGroup.localVariableElement;
      } else if (element is ParameterElement) {
        return CompletionGroup.parameterElement;
      } else if (element is PrefixElement) {
        return CompletionGroup.prefixElement;
      } else if (element is TypeParameterElement) {
        return CompletionGroup.typeParameterElement;
      }
    }
    if (entity is SimpleIdentifier) {
      var name = entity.name;
      if (name == 'void') {
        return CompletionGroup.keywordVoid;
      } else if (name == 'dynamic') {
        return CompletionGroup.keywordDynamic;
      }
    }
    return CompletionGroup.unknown;
  }

  /// Return a map used to represent this completion result in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'place': place.toJson(),
      'actualSuggestion': actualSuggestion.toJson(),
      if (topSuggestions != null)
        'topSuggestions':
            topSuggestions!.map((suggestion) => suggestion.toJson()).toList(),
      if (precedingRelevanceCounts != null)
        'precedingRelevanceCounts': precedingRelevanceCounts!
            .map((key, value) => MapEntry(key.toString(), value)),
      'expectedCompletion': expectedCompletion.toJson(),
      'completionLocation': completionLocation,
      'elapsedMS': elapsedMS,
    };
  }

  /// Return the element associated with the syntactic [entity], or `null` if
  /// there is no such element.
  Element? _getElement(SyntacticEntity entity) {
    if (entity is SimpleIdentifier) {
      var element = entity.staticElement;
      if (element != null) {
        return element;
      }
      AstNode? node = entity;
      while (node != null) {
        var parent = node.parent;
        if (parent is AssignmentExpression) {
          if (node == parent.leftHandSide) {
            return parent.readElement ?? parent.writeElement;
          }
          return null;
        } else if (parent is PrefixExpression) {
          if (parent.operator.type == TokenType.PLUS_PLUS ||
              parent.operator.type == TokenType.MINUS_MINUS) {
            return parent.readElement ?? parent.writeElement;
          }
        } else if (parent is PostfixExpression) {
          return parent.readElement ?? parent.writeElement;
        }
        node = parent;
      }
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
      {required this.label,
      required this.product,
      required this.count,
      required this.mrr,
      required this.mrr_5});
}

class MetricsSuggestionListener implements SuggestionListener {
  /// The feature values to use when there are no features for a suggestion.
  static const List<double> noFeatures = [
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0
  ];

  Map<protocol.CompletionSuggestion, List<double>> featureMap = Map.identity();

  List<double> cachedFeatures = noFeatures;

  String? missingCompletionLocation;

  String? missingCompletionLocationTable;

  @override
  void builtSuggestion(CompletionSuggestionBuilder suggestionBuilder) {
    var suggestion = suggestionBuilder.build();
    featureMap[suggestion] = cachedFeatures;
    cachedFeatures = noFeatures;
  }

  @override
  void computedFeatures(
      {double contextType = 0.0,
      double elementKind = 0.0,
      double hasDeprecated = 0.0,
      double isConstant = 0.0,
      double isNoSuchMethod = 0.0,
      double isNotImported = 0.0,
      double keyword = 0.0,
      double startsWithDollar = 0.0,
      double superMatches = 0.0,
      // Dependent features
      double inheritanceDistance = 0.0,
      double localVariableDistance = 0.0}) {
    cachedFeatures = [
      contextType,
      elementKind,
      hasDeprecated,
      isConstant,
      isNoSuchMethod,
      isNotImported,
      keyword,
      startsWithDollar,
      superMatches,
      // Dependent features
      inheritanceDistance,
      localVariableDistance,
    ];
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

/// A description of a pair of relevance tables to be used in an experiment.
class RelevanceTables {
  /// The name of the experiment using the tables.
  final String name;

  /// The relevance table used for element kinds.
  final Map<String, Map<protocol.ElementKind, ProbabilityRange>>
      elementKindRelevance;

  /// The relevance table used for keywords.
  final Map<String, Map<String, ProbabilityRange>> keywordRelevance;

  /// Initialize a newly created description of a pair of relevance tables.
  RelevanceTables(this.name, this.elementKindRelevance, this.keywordRelevance);
}

/// Information about a completion suggestion that suggested a shadowed element.
class ShadowedCompletion {
  final ExpectedCompletion expectedCompletion;

  final protocol.CompletionSuggestion closeMatchSuggestion;

  ShadowedCompletion(this.expectedCompletion, this.closeMatchSuggestion);
}

/// The information being remembered about an individual suggestion.
class SuggestionData {
  /// The suggestion that was produced.
  protocol.CompletionSuggestion suggestion;

  /// The values of the features used to compute the suggestion.
  List<double> features;

  SuggestionData(this.suggestion, this.features);

  /// Return an instance extracted from the decoded JSON [map].
  factory SuggestionData.fromJson(Map<String, dynamic> map) {
    return SuggestionData(
        protocol.CompletionSuggestion.fromJson(ResponseDecoder(null), '',
            map['suggestion'] as Map<String, dynamic>),
        (map['features'] as List<dynamic>).cast<double>());
  }

  /// Return a map used to represent this suggestion data in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'suggestion': suggestion.toJson(),
      'features': features,
    };
  }
}

extension on CompletionGroup {
  String get name {
    switch (this) {
      case CompletionGroup.classElement:
        return 'class';
      case CompletionGroup.constructorElement:
        return 'constructor';
      case CompletionGroup.enumElement:
        return 'enum';
      case CompletionGroup.extensionElement:
        return 'extension';
      case CompletionGroup.instanceMember:
        return 'instance member';
      case CompletionGroup.labelElement:
        return 'label';
      case CompletionGroup.localFunctionElement:
        return 'local function';
      case CompletionGroup.localVariableElement:
        return 'local variable';
      case CompletionGroup.mixinElement:
        return 'mixin';
      case CompletionGroup.parameterElement:
        return 'parameter';
      case CompletionGroup.prefixElement:
        return 'prefix';
      case CompletionGroup.staticMember:
        return 'static member';
      case CompletionGroup.topLevelMember:
        return 'top level member';
      case CompletionGroup.typeParameterElement:
        return 'type parameter';

      case CompletionGroup.keywordDynamic:
        return 'keyword dynamic';
      case CompletionGroup.keywordVoid:
        return 'keyword void';

      case CompletionGroup.unknown:
        return 'unknown';
    }
  }
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
