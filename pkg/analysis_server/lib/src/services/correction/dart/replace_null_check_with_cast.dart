// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNullCheckWithCast extends CorrectionProducer {
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
    final node = this.node;
    if (node is! PostfixExpression) {
      return;
    }
    var operand = node.operand;
    var operator = node.operator;
    var operandType = operand.staticType;
    if (operandType is! TypeParameterType) {
      return;
    }
    // It is possible that there are cases of precedence and syntax which would
    // require additional parentheses, for example converting `p!.hashCode` to
    // `(p as T).hashCode`. However no such cases are known to trigger the lint
    // rule.
    // TODO(srawlins): Follow up on
    // https://github.com/dart-lang/linter/issues/3256.
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(operator),
          ' as ${operandType.getDisplayString(withNullability: false)}');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceNullCheckWithCast newInstance() => ReplaceNullCheckWithCast();
}
