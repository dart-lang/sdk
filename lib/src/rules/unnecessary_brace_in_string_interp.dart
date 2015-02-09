// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unnecessary_brace_in_string_interp;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:dart_lint/src/linter.dart';

final RegExp alphaNumeric = new RegExp(r'^[a-zA-Z0-9]');

const desc = 'AVOID bracketed interpolation of simple identifiers';

bool isAlphaNumeric(Token token) =>
    token is StringToken && token.lexeme.startsWith(alphaNumeric);

class UnnecessaryBraceInStringInterp extends LintRule {
  UnnecessaryBraceInStringInterp() : super(
          name: 'UnnecessaryBraceInStringInterp',
          description: desc,
          group: Group.STYLE_GUIDE,
          kind: Kind.AVOID);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitStringInterpolation(StringInterpolation node) {
    var expressions = node.elements.where((e) => e is InterpolationExpression);
    for (InterpolationExpression expression in expressions) {
      if (expression.expression is SimpleIdentifier) {
        Token bracket = expression.rightBracket;
        if (bracket != null && !isAlphaNumeric(bracket.next)) {
          rule.reporter.reportErrorForNode(
              new LintCode(rule.name.value, rule.description), expression, []);
        }
      }
    }
  }
}
