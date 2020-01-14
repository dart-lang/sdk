// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

int includedCount = 0;
int notIncludedCount = 0;

/// Sort by relevance first, highest to lowest, and then by the completion, alphabetically
Comparator<CompletionSuggestion> _completionComparator = (sug1, sug2) {
  if (sug1.relevance == sug2.relevance) {
    return sug1.completion.compareTo(sug2.completion);
  }
  return sug2.relevance.compareTo(sug1.relevance);
};

main() {
  List<String> analysisRoots = [""];
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
          print("  Analyzing file: $filePath");
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
              suggestions.sort(_completionComparator);

              var fraction =
                  _placementInSuggestionList(suggestions, entity.toString());
              if (fraction.y != 0) {
                includedCount++;
//                print(
//                    "  Bug - $filePath@${entity.offset} did not include ${entity.toString()}");
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
  print("done $includedCount $notIncludedCount");

  final percentIncluded = includedCount / (includedCount + notIncludedCount);
  final percentNotIncluded =
      notIncludedCount / (includedCount + notIncludedCount);
  print("done $percentIncluded% $percentNotIncluded%");
}

Point<int> _placementInSuggestionList(
    List<CompletionSuggestion> suggestions, String completion) {
  int i = 1;
  for (CompletionSuggestion completionSuggestion in suggestions) {
    if (completionSuggestion.completion == completion) {
      return Point(i, suggestions.length);
    }
    i++;
  }
  return Point(0, 0);
}

class CompletionMetricVisitor extends RecursiveAstVisitor {
  // TODO(jwren) move this class into a different file
  // TODO(jwren) implement missing visit* methods

  List<SyntacticEntity> entities;

  CompletionMetricVisitor() {
    entities = <SyntacticEntity>[];
  }

  safelyRecordEntity(SyntacticEntity entity) {
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      entities.add(entity);
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    safelyRecordEntity(node.doKeyword);
    return super.visitDoStatement(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    safelyRecordEntity(node.ifKeyword);
    return super.visitIfStatement(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    safelyRecordEntity(node.keyword);
    safelyRecordEntity(node.asKeyword);
    return super.visitImportDirective(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      safelyRecordEntity(node);
    }
    return super.visitSimpleIdentifier(node);
  }
}
