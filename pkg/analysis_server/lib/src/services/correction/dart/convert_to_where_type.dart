// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToWhereType extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_WHERE_TYPE;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_WHERE_TYPE_MULTI;

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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToWhereType newInstance() => ConvertToWhereType();
}
