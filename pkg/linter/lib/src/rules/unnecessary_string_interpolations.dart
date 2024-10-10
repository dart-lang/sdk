// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary string interpolation.';

class UnnecessaryStringInterpolations extends LintRule {
  UnnecessaryStringInterpolations()
      : super(
          name: LintNames.unnecessary_string_interpolations,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_string_interpolations;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.parent is AdjacentStrings) return;
    if (node.elements.length == 3) {
      var start = node.elements.first as InterpolationString;
      var interpolation = node.elements[1] as InterpolationExpression;
      var end = node.elements[2] as InterpolationString;
      if (start.value.isEmpty && end.value.isEmpty) {
        var staticType = interpolation.expression.staticType;
        if (staticType != null &&
            staticType.isDartCoreString &&
            staticType.nullabilitySuffix != NullabilitySuffix.question) {
          rule.reportLint(node);
        }
      }
    }
  }
}
