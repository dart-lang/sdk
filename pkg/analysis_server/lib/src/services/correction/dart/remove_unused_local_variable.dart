// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedLocalVariable extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_LOCAL_VARIABLE;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    final declaration = node.parent;
    if (!(declaration is VariableDeclaration && declaration.name == node)) {
      return;
    }
    Element element = (declaration as VariableDeclaration).declaredElement;
    if (element is! LocalElement) {
      return;
    }

    final sourceRanges = <SourceRange>[];

    final functionBody = declaration.thisOrAncestorOfType<FunctionBody>();
    final references = findLocalElementReferences(functionBody, element);
    for (var reference in references) {
      final node = reference.thisOrAncestorMatching((node) =>
          node is VariableDeclaration || node is AssignmentExpression);
      var sourceRange;
      if (node is VariableDeclaration) {
        VariableDeclarationList parent = node.parent;
        if (parent.variables.length == 1) {
          sourceRange = utils.getLinesRange(range.node(parent.parent));
        } else {
          sourceRange = range.nodeInList(parent.variables, node);
        }
      } else if (node is AssignmentExpression) {
        // todo (pq): consider node.parent is! ExpressionStatement to handle
        // assignments in parens, etc.
        if (node.parent is ArgumentList) {
          sourceRange = range.startStart(node, node.operator.next);
        } else {
          sourceRange = utils.getLinesRange(range.node(node.parent));
        }
      } else {
        return;
      }
      sourceRanges.add(sourceRange);
    }

    await builder.addFileEdit(file, (builder) {
      for (var sourceRange in sourceRanges) {
        builder.addDeletion(sourceRange);
      }
    });
  }
}
