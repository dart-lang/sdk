// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToForEach extends ResolvedCorrectionProducer {
  ConvertToForEach({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // This operation may have side effects, so it should not be applied
      // automatically.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.convertToForEach;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! ForStatement) {
      return;
    }
    Expression iterable;
    if (node.forLoopParts case ForEachPartsWithDeclaration(
      iterable: var current,
    )) {
      iterable = current;
    } else {
      return;
    }
    InvocationExpression invocation;
    if (node.body case Block(
      statements: NodeList<Statement>(
        length: 1,
        first: ExpressionStatement(:InvocationExpression expression),
      ),
    )) {
      invocation = expression;
    } else {
      return;
    }
    if (invocation.argumentList.arguments.length != 1) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(node, iterable));
      builder.addSimpleReplacement(
        range.endStart(iterable, invocation),
        '.forEach(',
      );
      builder.addSimpleReplacement(
        range.startEnd(invocation.argumentList, node),
        ');',
      );
    });
  }
}
