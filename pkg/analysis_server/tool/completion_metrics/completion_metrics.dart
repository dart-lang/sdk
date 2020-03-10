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
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as err;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'metrics_util.dart';
import 'utils.dart';
import 'visitors.dart';

Future<void> main(List<String> args) async {
  ArgParser parser = createArgParser();
  ArgResults result = parser.parse(args);

  if (validArguments(parser, result)) {
    var code = await CompletionCoverageMetrics(result.rest[0])
        .compute(corpus: result['corpus'], verbose: result['verbose']);
    io.exit(code);
  }
  return io.exit(1);
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  ArgParser parser = ArgParser();
  parser.addFlag(
    'corpus',
    help: 'Analyze each of the subdirectories separately',
    negatable: false,
  );
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

/// This is the main metrics computer class for code completions. After the
/// object is constructed, [computeCompletionMetrics] is executed to do analysis
/// and print a summary of the metrics gathered from the completion tests.
class CompletionCoverageMetrics {
  final String _rootPath;

  String _currentFilePath;

  bool _verbose;

  ResolvedUnitResult _resolvedUnitResult;

  /// The int to be returned from the [compute] call.
  int resultCode;

  var completionCounter = Counter('successful/ unsuccessful completions');
  var completionMissedTokenCounter =
      Counter('unsuccessful completion token counter');
  var completionKindCounter = Counter('unsuccessful completion kind counter');
  var completionElementKindCounter =
      Counter('unsuccessful completion element kind counter');
  var mRRComputer =
      MeanReciprocalRankComputer('successful/ unsuccessful completions');
  var typeMemberMRRComputer =
      MeanReciprocalRankComputer('type member completions');
  var nonTypeMemberMRRComputer =
      MeanReciprocalRankComputer('non-type member completions');

  CompletionCoverageMetrics(this._rootPath);

  /// The path to the current file.
  String get currentFilePath => _currentFilePath;

  /// The analysis root path that this CompletionMetrics class will be computed.
  String get rootPath => _rootPath;

  Future<int> compute({bool corpus = false, bool verbose = false}) async {
    _verbose = verbose;
    resultCode = 0;

    var roots = _computeRootPaths(_rootPath, corpus);
    for (var root in roots) {
      print('Analyzing root: \"$root\"');
      final collection = AnalysisContextCollection(
        includedPaths: [root],
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );

      for (var context in collection.contexts) {
        // Set the DeclarationsTracker, only call doWork to build up the available
        // suggestions if doComputeCompletionsFromAnalysisServer is true.
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
                forEachExpectedCompletion(
                    expectedCompletion,
                    await _computeCompletionSuggestions(_resolvedUnitResult,
                        expectedCompletion.offset, declarationsTracker));
              }
            } catch (e) {
              print('Exception caught analyzing: $filePath');
              print(e.toString());
              resultCode = 1;
            }
          }
        }
      }
    }
    printAndClearComputers();
    return resultCode;
  }

  void forEachExpectedCompletion(ExpectedCompletion expectedCompletion,
      List<CompletionSuggestion> suggestions) {
    assert(suggestions != null);

    var place = placementInSuggestionList(suggestions, expectedCompletion);

    mRRComputer.addRank(place.rank);

    if (place.denominator != 0) {
      completionCounter.count('successful');

      if (isTypeMember(expectedCompletion.syntacticEntity)) {
        typeMemberMRRComputer.addRank(place.rank);
      } else {
        nonTypeMemberMRRComputer.addRank(place.rank);
      }
    } else {
      completionCounter.count('unsuccessful');

      completionMissedTokenCounter.count(expectedCompletion.completion);
      completionKindCounter.count(expectedCompletion.kind.toString());
      completionElementKindCounter
          .count(expectedCompletion.elementKind.toString());

      if (_verbose) {
        // The format "/file/path/foo.dart:3:4" makes for easier input
        // with the Files dialog in IntelliJ
        print(
            '$currentFilePath:${expectedCompletion.lineNumber}:${expectedCompletion.columnNumber}');
        print(
            '\tdid not include the expected completion: \"${expectedCompletion.completion}\", completion kind: ${expectedCompletion.kind.toString()}, element kind: ${expectedCompletion.elementKind.toString()}');
        print('');
      }
    }
  }

  void printAndClearComputers() {
    print('');
    completionMissedTokenCounter.printCounterValues();
    print('');

    completionKindCounter.printCounterValues();
    print('');

    completionElementKindCounter.printCounterValues();
    print('');

    mRRComputer.printMean();
    print('');

    typeMemberMRRComputer.printMean();
    print('');

    nonTypeMemberMRRComputer.printMean();
    print('');

    print('Summary for $_rootPath:');
    completionCounter.printCounterValues();

    completionMissedTokenCounter.clear();
    completionKindCounter.clear();
    completionElementKindCounter.clear();
    completionCounter.clear();
    mRRComputer.clear();
    typeMemberMRRComputer.clear();
    nonTypeMemberMRRComputer.clear();
  }

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

  static List<String> _computeRootPaths(String rootPath, bool corpus) {
    var roots = <String>[];
    if (!corpus) {
      roots.add(rootPath);
    } else {
      for (var child in io.Directory(rootPath).listSync()) {
        if (child is io.Directory) {
          roots.add(path.join(rootPath, child.path));
        }
      }
    }
    return roots;
  }
}
