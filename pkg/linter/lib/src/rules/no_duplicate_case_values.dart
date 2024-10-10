// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r"Don't use more than one case with same value.";

class NoDuplicateCaseValues extends LintRule {
  NoDuplicateCaseValues()
      : super(
          name: LintNames.no_duplicate_case_values,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.no_duplicate_case_values;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final NoDuplicateCaseValues rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var values = <DartObject, Expression>{};

    for (var member in node.members) {
      if (member is SwitchCase) {
        var expression = member.expression;

        var result = expression.computeConstantValue();
        var value = result.value;

        if (value == null || !value.hasKnownValue) {
          continue;
        }

        var duplicateValue = values[value];
        // TODO(brianwilkeson): This would benefit from having a context message
        //  pointing at the `duplicateValue`.
        if (duplicateValue != null) {
          rule.reportLint(expression,
              arguments: [expression.toString(), duplicateValue.toString()]);
        } else {
          values[value] = expression;
        }
      }
    }
  }
}
