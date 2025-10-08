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

class RemoveNonNullAssertion extends ResolvedCorrectionProducer {
  RemoveNonNullAssertion({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeNonNullAssertion;

  @override
  FixKind get multiFixKind => DartFixKind.removeNonNullAssertionMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var expression = node;

    if (expression is PostfixExpression &&
        expression.operator.type == TokenType.BANG) {
      var bangToken = expression.operator;

      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.entity(bangToken));
      });
    }

    if (expression is NullAssertPattern) {
      var bangToken = expression.operator;

      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(bangToken, bangToken.next!));
      });
    }
  }
}
