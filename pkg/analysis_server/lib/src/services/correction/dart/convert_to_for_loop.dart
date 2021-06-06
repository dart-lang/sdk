// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertForEachToForLoop extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_FOR_EACH_TO_FOR_LOOP;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_FOR_EACH_TO_FOR_LOOP_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var invocation = node.parent;
    if (invocation is! MethodInvocation) {
      return;
    }
    var statement = invocation.parent;
    if (statement is! ExpressionStatement) {
      return;
    }
    var argument = invocation.argumentList.arguments[0];
    if (argument is! FunctionExpression) {
      return;
    }
    var parameters = argument.parameters?.parameters;
    if (parameters == null || parameters.length != 1) {
      return;
    }
    var parameter = parameters[0];
    if (parameter is! NormalFormalParameter) {
      return;
    }
    var loopVariableName = parameter.identifier?.name;
    if (loopVariableName == null) {
      return;
    }
    var target = utils.getNodeText(invocation.target!);
    var body = argument.body;
    if (body is BlockFunctionBody) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.startStart(invocation, body), (builder) {
          builder.write('for (var ');
          builder.write(loopVariableName);
          builder.write(' in ');
          builder.write(target);
          builder.write(') ');
        });
        builder.addDeletion(range.endEnd(body, statement));
      });
    } else if (body is ExpressionFunctionBody) {
      await builder.addDartFileEdit(file, (builder) {
        var expression = body.expression;
        var prefix = utils.getPrefix(statement.offset);
        builder.addReplacement(range.startStart(invocation, expression),
            (builder) {
          builder.write('for (var ');
          builder.write(loopVariableName);
          builder.write(' in ');
          builder.write(target);
          builder.writeln(') {');
          builder.write(prefix);
          builder.write('  ');
        });
        builder.addReplacement(range.endEnd(expression, statement), (builder) {
          builder.writeln(';');
          builder.write(prefix);
          builder.write('}');
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertForEachToForLoop newInstance() => ConvertForEachToForLoop();
}
