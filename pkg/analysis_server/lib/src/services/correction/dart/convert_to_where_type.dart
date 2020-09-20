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
  FixKind get fixKind => DartFixKind.CONVERT_TO_WHERE_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier || node.parent is! MethodInvocation) {
      return;
    }
    var methodName = node as SimpleIdentifier;
    var invocation = node.parent as MethodInvocation;
    var arguments = invocation.argumentList.arguments;
    if (arguments.length != 1 || arguments[0] is! FunctionExpression) {
      return;
    }
    var body = (arguments[0] as FunctionExpression).body;
    Expression returnValue;
    if (body is ExpressionFunctionBody) {
      returnValue = body.expression;
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length != 1 || statements[0] is! ReturnStatement) {
        return;
      }
      returnValue = (statements[0] as ReturnStatement).expression;
    } else {
      return;
    }
    if (returnValue is! IsExpression) {
      return;
    }
    var isExpression = returnValue as IsExpression;
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
