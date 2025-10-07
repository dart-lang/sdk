// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToWhereType extends ResolvedCorrectionProducer {
  ConvertToWhereType({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.convertToWhereType;

  @override
  FixKind get multiFixKind => DartFixKind.convertToWhereTypeMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var methodName = node;
    if (methodName is! SimpleIdentifier) {
      return;
    }

    var invocation = methodName.parent;
    if (invocation is! MethodInvocation) {
      return;
    }

    var arguments = invocation.argumentList.arguments;
    if (arguments.length != 1) {
      return;
    }

    var argument = arguments[0];
    if (argument is! FunctionExpression) {
      return;
    }

    Expression? returnValue;
    var body = argument.body;
    if (body is ExpressionFunctionBody) {
      returnValue = body.expression;
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length != 1) {
        return;
      }
      var returnStatement = statements[0];
      if (returnStatement is! ReturnStatement) {
        return;
      }
      returnValue = returnStatement.expression;
    }

    if (returnValue is! IsExpression) {
      return;
    }
    var isExpression = returnValue;
    if (isExpression.notOperator != null) {
      return;
    }
    var targetType = isExpression.type;

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.startEnd(methodName, invocation), (builder) {
        builder.write('whereType<');
        builder.write(utils.getNodeText(targetType));
        builder.write('>()');
      });
    });
  }
}
