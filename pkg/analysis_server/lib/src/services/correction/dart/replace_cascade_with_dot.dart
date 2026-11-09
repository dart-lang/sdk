// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceCascadeWithDot extends ResolvedCorrectionProducer {
  static final Map<TokenType, String> _indexReplacement = {
    TokenType.PERIOD_PERIOD: '',
    TokenType.QUESTION_PERIOD_PERIOD: '?',
  };

  static final Map<TokenType, String> _propertyReplacement = {
    TokenType.PERIOD_PERIOD: '.',
    TokenType.QUESTION_PERIOD_PERIOD: '?.',
  };

  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceCascadeWithDot;

  @override
  FixKind get multiFixKind => DartFixKind.replaceCascadeWithDotMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? cascadeExpression = node;
    if (cascadeExpression is ExtensionOverride) {
      cascadeExpression = cascadeExpression.parent;
    }
    if (cascadeExpression is! CascadeExpression) {
      return;
    }

    var sections = cascadeExpression.cascadeSections;
    if (sections.length == 1) {
      await _replaceFor(builder, cascadeExpression.target, sections[0]);
    }
  }

  Future<void> _replaceFor(
    ChangeBuilder builder,
    Expression target,
    Expression? section,
  ) async {
    if (section is AssignmentExpression) {
      return _replaceFor(builder, target, section.leftHandSide);
    }

    if (section is IndexExpression) {
      var period = section.period;
      if (period != null) {
        return _replaceToken(builder, target, period, _indexReplacement);
      }
      return _replaceFor(builder, target, section.target);
    }

    if (section is MethodInvocation) {
      var operator = section.operator;
      if (operator != null) {
        return _replaceToken(builder, target, operator, _propertyReplacement);
      }
    }

    if (section is PropertyAccess) {
      return _replaceToken(
        builder,
        target,
        section.operator,
        _propertyReplacement,
      );
    }
  }

  Future<void> _replaceToken(
    ChangeBuilder builder,
    Expression target,
    Token token,
    Map<TokenType, String> map,
  ) async {
    var replacement = map[token.type];
    if (replacement != null) {
      // A cascade's target can be any expression, but the operand of a
      // selector must bind tighter than a prefix operator such as `await`.
      var needsParentheses = target.precedence < Precedence.postfix;
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
          builder.addSimpleInsertion(target.end, ')');
        }
        builder.addSimpleReplacement(range.token(token), replacement);
      });
    }
  }
}
