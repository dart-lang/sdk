// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

main() {
  List<String> analysisRoots = [""];
  _computeCompletionMetrics(PhysicalResourceProvider.INSTANCE, analysisRoots);
}

Future _computeCompletionMetrics(
    ResourceProvider resourceProvider, List<String> analysisRoots) async {
  for (var root in analysisRoots) {
    print('Analyzing... $root');
    final collection = AnalysisContextCollection(
      includedPaths: [root],
      resourceProvider: resourceProvider,
    );

    for (var context in collection.contexts) {
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (AnalysisEngine.isDartFileName(filePath) &&
            !filePath.endsWith("_test.dart")) {
          print("file name $filePath");
          try {
            final result =
                await context.currentSession.getResolvedUnit(filePath);
            final visitor = CompletionMetricVisitor();

            result.unit.accept(visitor);
            var offsets = visitor.offsets;
            assert(offsets.isNotEmpty);
          } catch (e) {
            print('Exception caught analyzing: $filePath');
            print(e.toString());
          }
        }
      }
    }
  }
  print("done");
}

class CompletionMetricVisitor extends RecursiveAstVisitor {
  List<int> offsets;

  CompletionMetricVisitor() {
    offsets = <int>[];
  }

  safelyRecordOffset(SyntacticEntity entity) {
    if (entity != null && entity.offset > 0 && entity.length > 0) {
      // print("${entity.toString()} ${entity.offset}");
      offsets.add(entity.offset);
    }
  }

  @override
  visitDoStatement(DoStatement node) {
    safelyRecordOffset(node.doKeyword);
    return super.visitDoStatement(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    safelyRecordOffset(node.ifKeyword);
    return super.visitIfStatement(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    safelyRecordOffset(node);
    return super.visitSimpleIdentifier(node);
  }
}
