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
  FixKind get fixKind => DartFixKind.REPLACE_CASCADE_WITH_DOT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is CascadeExpression) {
      var sections = node.cascadeSections;
      if (sections.length == 1) {
        await _replaceFor(builder, sections[0]);
      }
    }
  }

  Future<void> _replaceFor(ChangeBuilder builder, Expression section) async {
    if (section is AssignmentExpression) {
      return _replaceFor(builder, section.leftHandSide);
    }

    if (section is IndexExpression) {
      if (section.period != null) {
        return _replaceToken(builder, section.period, _indexReplacement);
      }
      return _replaceFor(builder, section.target);
    }

    if (section is MethodInvocation) {
      return _replaceToken(builder, section.operator, _propertyReplacement);
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
