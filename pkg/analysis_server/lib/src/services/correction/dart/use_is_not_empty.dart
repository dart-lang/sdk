// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseIsNotEmpty extends ResolvedCorrectionProducer {
  UseIsNotEmpty({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.useIsNotEmpty;

  @override
  FixKind get multiFixKind => DartFixKind.useIsNotEmptyMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var prefixExpression = node;
    if (prefixExpression is! PrefixExpression) {
      return;
    }
    var negation = prefixExpression.operator;
    if (negation.type != TokenType.BANG) {
      return;
    }
    SimpleIdentifier identifier;
    var expression = prefixExpression.operand;
    if (expression is PrefixedIdentifier) {
      identifier = expression.identifier;
    } else if (expression is PropertyAccess) {
      identifier = expression.propertyName;
    } else {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.token(negation));
      builder.addSimpleReplacement(range.node(identifier), 'isNotEmpty');
    });
  }
}
