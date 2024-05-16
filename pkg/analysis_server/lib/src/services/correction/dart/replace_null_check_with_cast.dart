// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNullCheckWithCast extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_NULL_CHECK_WITH_CAST;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_NULL_CHECK_WITH_CAST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    Token? operator;
    DartType? operandType;
    if (node is NullAssertPattern) {
      operator = node.operator;
      operandType = node.matchedValueType;
    }
    if (node is PostfixExpression) {
      var operand = node.operand;
      operator = node.operator;
      if (operand.staticType is! TypeParameterType) {
        return;
      }
      operandType = operand.staticType;
    }
    if (operator == null || operandType == null) {
      return;
    }
    // It is possible that there are cases of precedence and syntax which would
    // require additional parentheses, for example converting `p!.hashCode` to
    // `(p as T).hashCode`. However no such cases are known to trigger the lint
    // rule.
    // TODO(srawlins): Follow up on
    // https://github.com/dart-lang/linter/issues/3256.
    await builder.addDartFileEdit(file, (builder) {
      var operandTypeNonNull =
          (operandType as TypeImpl).withNullability(NullabilitySuffix.none);
      builder.addSimpleReplacement(
        range.token(operator!),
        ' as ${operandTypeNonNull.getDisplayString()}',
      );
    });
  }
}
