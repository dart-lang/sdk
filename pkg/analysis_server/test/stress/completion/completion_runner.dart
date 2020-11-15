// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/utilities/null_string_sink.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// A runner that can request code completion at the location of each identifier
/// in a Dart file.
class CompletionRunner {
  /// The sink to which output is to be written.
  final StringSink output;

  /// A flag indicating whether to produce output about missing suggestions.
  final bool printMissing;

  /// A flag indicating whether to produce output about the quality of the sort
  /// order.
  final bool printQuality;

  /// A flag indicating whether to produce timing information.
  final bool timing;

  /// A flag indicating whether to produce verbose output.
  final bool verbose;

  /// A flag indicating whether we should delete each identifier before
  /// attempting to complete at that offset.
  bool deleteBeforeCompletion = false;

  /// Initialize a newly created completion runner.
  CompletionRunner(
      {StringSink output,
      bool printMissing,
      bool printQuality,
      bool timing,
      bool verbose})
      : output = output ?? NullStringSink(),
        printMissing = printMissing ?? false,
        printQuality = printQuality ?? false,
        timing = timing ?? false,
        verbose = verbose ?? false;

  /// Test the completion engine at the locations of each of the identifiers in
  /// each of the files in the given [analysisRoot].
  Future<void> runAll(String analysisRoot) async {
    var resourceProvider =
        OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
    var collection = AnalysisContextCollection(
        includedPaths: <String>[analysisRoot],
        resourceProvider: resourceProvider);
    var contributor = DartCompletionManager();
    var statistics = CompletionPerformance();
    var stamp = 1;

    var fileCount = 0;
    var identifierCount = 0;
    var expectedCount = 0;
    var missingCount = 0;
    var indexCount = List<int>.filled(20, 0);
    var filteredIndexCount = List<int>.filled(20, 0);

    // Consider getting individual timings so that we can also report the
    // longest and shortest times, or even a distribution.
    var timer = Stopwatch();

    for (var context in collection.contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!path.endsWith('.dart')) {
          continue;
        }
        fileCount++;
        output.write('.');
        var result = await context.currentSession.getResolvedUnit(path);
        var content = result.content;
        var lineInfo = result.lineInfo;
        var identifiers = _identifiersIn(result.unit);

        for (var identifier in identifiers) {
          identifierCount++;
          var offset = identifier.offset;
          if (deleteBeforeCompletion) {
            var modifiedContent = content.substring(0, offset) +
                content.substring(identifier.end);
            resourceProvider.setOverlay(path,
                content: modifiedContent, modificationStamp: stamp++);
            result = await context.currentSession.getResolvedUnit(path);
          }

          timer.start();
          var request = CompletionRequestImpl(result, offset, statistics);
          var suggestions = await request.performance.runRequestOperation(
            (performance) async {
              return await contributor.computeSuggestions(
                performance,
                request,
              );
            },
          );
          timer.stop();

          if (!identifier.inDeclarationContext() &&
              !_isNamedExpressionName(identifier)) {
            expectedCount++;
            suggestions = _sort(suggestions.toList());
            var index = _indexOf(suggestions, identifier.name);
            if (index < 0) {
              missingCount++;
              if (printMissing) {
                CharacterLocation location = lineInfo.getLocation(offset);
                output.writeln('Missing suggestion of "${identifier.name}" at '
                    '$path:${location.lineNumber}:${location.columnNumber}');
                if (verbose) {
                  _printSuggestions(suggestions);
                }
              }
            } else if (printQuality) {
              if (index < indexCount.length) {
                indexCount[index]++;
              }
              var filteredSuggestions =
                  _filterBy(suggestions, identifier.name.substring(0, 1));
              var filteredIndex =
                  _indexOf(filteredSuggestions, identifier.name);
              if (filteredIndex < filteredIndexCount.length) {
                filteredIndexCount[filteredIndex]++;
              }
            }
          }
        }
        if (deleteBeforeCompletion) {
          resourceProvider.removeOverlay(path);
        }
      }
    }
    output.writeln();
    if (printMissing) {
      output.writeln();
    }
    output.writeln('Found $identifierCount identifiers in $fileCount files');
    if (expectedCount > 0) {
      output.writeln('  $expectedCount were expected to code complete');
      if (printQuality) {
        var percent = (missingCount * 100 / expectedCount).round();
        output.writeln('  $percent% of which were missing suggestions '
            '($missingCount)');

        var foundCount = expectedCount - missingCount;

        void printCount(int count) {
          if (count < 10) {
            output.write('      $count  ');
          } else if (count < 100) {
            output.write('     $count  ');
          } else if (count < 1000) {
            output.write('    $count  ');
          } else if (count < 10000) {
            output.write('   $count  ');
          } else {
            output.write('  $count  ');
          }
          var percent = (count * 100 / foundCount).floor();
          for (var j = 0; j < percent; j++) {
            output.write('-');
          }
          output.writeln();
        }

        void _printCounts(List<int> counts) {
          var nearTopCount = 0;
          for (var i = 0; i < counts.length; i++) {
            var count = counts[i];
            printCount(count);
            nearTopCount += count;
          }
          printCount(foundCount - nearTopCount);
        }

        output.writeln();
        output.writeln('By position in the list');
        _printCounts(indexCount);
        output.writeln();
        output.writeln('By position in the list (filtered by first character)');
        _printCounts(filteredIndexCount);
        output.writeln();
      }
    }
    if (timing && identifierCount > 0) {
      var time = timer.elapsedMilliseconds;
      var averageTime = (time / identifierCount).round();
      output.writeln('completion took $time ms, '
          'which is an average of $averageTime ms per completion');
    }
  }

  List<CompletionSuggestion> _filterBy(
      List<CompletionSuggestion> suggestions, String pattern) {
    return suggestions
        .where((suggestion) => suggestion.completion.startsWith(pattern))
        .toList();
  }

  /// Return a list containing information about the identifiers in the given
  /// compilation [unit].
  List<SimpleIdentifier> _identifiersIn(CompilationUnit unit) {
    var visitor = IdentifierCollector();
    unit.accept(visitor);
    return visitor.identifiers;
  }

  /// If the given list of [suggestions] includes a suggestion for the given
  /// [identifier], return the index of the suggestion. Otherwise, return `-1`.
  int _indexOf(List<CompletionSuggestion> suggestions, String identifier) {
    for (var i = 0; i < suggestions.length; i++) {
      if (suggestions[i].completion == identifier) {
        return i;
      }
    }
    return -1;
  }

  /// Return `true` if the given [identifier] is being used as the name of a
  /// named expression.
  bool _isNamedExpressionName(SimpleIdentifier identifier) {
    var parent = identifier.parent;
    return parent is NamedExpression && parent.name.label == identifier;
  }

  /// Print information about the given [suggestions].
  void _printSuggestions(List<CompletionSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      output.writeln('  No suggestions');
      return;
    }
    output.writeln('  Suggestions:');
    for (var suggestion in suggestions) {
      output.writeln('    ${suggestion.completion}');
    }
  }

  List<CompletionSuggestion> _sort(List<CompletionSuggestion> suggestions) {
    suggestions.sort((first, second) => second.relevance - first.relevance);
    return suggestions;
  }
}

/// A visitor that will collect simple identifiers in the AST being visited.
class IdentifierCollector extends RecursiveAstVisitor<void> {
  /// The simple identifiers that were collected.
  final List<SimpleIdentifier> identifiers = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node);
  }
}
