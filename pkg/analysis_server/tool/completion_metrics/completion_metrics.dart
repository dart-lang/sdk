// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

import 'visitors.dart';

int includedCount = 0;
int notIncludedCount = 0;

main() {
  List<String> analysisRoots = [''];
  _computeCompletionMetrics(PhysicalResourceProvider.INSTANCE, analysisRoots);
}

/// TODO(jwren) put the following methods into a class
Future _computeCompletionMetrics(
    ResourceProvider resourceProvider, List<String> analysisRoots) async {
  for (var root in analysisRoots) {
    print('Analyzing root... $root');
    final collection = AnalysisContextCollection(
      includedPaths: [root],
      resourceProvider: resourceProvider,
    );

    for (var context in collection.contexts) {
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath)) {
          print('  Analyzing file: $filePath');
          try {
            final result =
                await context.currentSession.getResolvedUnit(filePath);
            final visitor = CompletionMetricVisitor();

            result.unit.accept(visitor);
            var entities = visitor.entities;

            for (var entity in entities) {
              var completionContributor = DartCompletionManager();
              var completionRequestImpl = CompletionRequestImpl(
                result,
                entity.offset,
                CompletionPerformance(),
              );
              var suggestions = await completionContributor
                  .computeSuggestions(completionRequestImpl);
              suggestions.sort(completionComparator);

              var fraction =
                  _placementInSuggestionList(suggestions, entity.toString());
              if (fraction.y != 0) {
                includedCount++;
//                print(
//                    '  Bug - $filePath@${entity.offset} did not include ${entity.toString()}');
              } else {
                notIncludedCount++;
              }
            }
          } catch (e) {
            print('Exception caught analyzing: $filePath');
            print(e.toString());
          }
        }
      }
    }
  }
  print('done $includedCount $notIncludedCount');

  final percentIncluded = includedCount / (includedCount + notIncludedCount);
  final percentNotIncluded =
      notIncludedCount / (includedCount + notIncludedCount);
  print(
      'done ${_formatPercentToString(percentIncluded)} ${_formatPercentToString(percentNotIncluded)}');
}

Point<int> _placementInSuggestionList(
    List<CompletionSuggestion> suggestions, String completion) {
  var i = 1;
  for (var completionSuggestion in suggestions) {
    if (completionSuggestion.completion == completion) {
      return Point(i, suggestions.length);
    }
    i++;
  }
  return Point(0, 0);
}

String _formatPercentToString(double percent, [fractionDigits = 1]) {
  return (percent * 100).toStringAsFixed(fractionDigits) + '%';
}
