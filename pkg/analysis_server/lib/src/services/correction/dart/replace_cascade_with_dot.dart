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

class ReplaceCascadeWithDot extends CorrectionProducer {
  static final Map<TokenType, String> _indexReplacement = {
    TokenType.PERIOD_PERIOD: '',
    TokenType.QUESTION_PERIOD_PERIOD: '?',
  };

  static final Map<TokenType, String> _propertyReplacement = {
    TokenType.PERIOD_PERIOD: '.',
    TokenType.QUESTION_PERIOD_PERIOD: '?.',
  };

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_CASCADE_WITH_DOT;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_CASCADE_WITH_DOT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final cascadeExpression = node;
    if (cascadeExpression is! CascadeExpression) {
      return;
    }

    var sections = cascadeExpression.cascadeSections;
    if (sections.length == 1) {
      await _replaceFor(builder, sections[0]);
    }
  }

  Future<void> _replaceFor(ChangeBuilder builder, Expression? section) async {
    if (section is AssignmentExpression) {
      return _replaceFor(builder, section.leftHandSide);
    }

    if (section is IndexExpression) {
      var period = section.period;
      if (period != null) {
        return _replaceToken(builder, period, _indexReplacement);
      }
      return _replaceFor(builder, section.target);
    }

    if (section is MethodInvocation) {
      var operator = section.operator;
      if (operator != null) {
        return _replaceToken(builder, operator, _propertyReplacement);
      }
    }

    if (section is PropertyAccess) {
      return _replaceToken(builder, section.operator, _propertyReplacement);
    }
  }

  Future<void> _replaceToken(
    ChangeBuilder builder,
    Token token,
    Map<TokenType, String> map,
  ) async {
    var replacement = map[token.type];
    if (replacement != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(token), replacement);
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceCascadeWithDot newInstance() => ReplaceCascadeWithDot();
}
