// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithNotNullAware extends CorrectionProducer {
  /// The operator that will replace the existing operator.
  String _newOperator;

  @override
  List<Object> get fixArguments => [_newOperator];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_NOT_NULL_AWARE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveredNode;
    if (node is MethodInvocation) {
      _newOperator =
          node.operator.type == TokenType.QUESTION_PERIOD ? '.' : '..';
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(node.operator), _newOperator);
      });
    } else if (node is PropertyAccess) {
      _newOperator =
          node.operator.type == TokenType.QUESTION_PERIOD ? '.' : '..';
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(node.operator), _newOperator);
      });
    } else if (node is IndexExpression) {
      if (node.period != null) {
        _newOperator = '..';
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(node.period), '..');
        });
      } else if (node.question != null) {
        _newOperator = '[';
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.token(node.question));
        });
      }
    } else if (node is SpreadElement) {
      _newOperator = '...';
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
            range.token(node.spreadOperator), _newOperator);
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceWithNotNullAware newInstance() => ReplaceWithNotNullAware();
}
