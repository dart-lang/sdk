// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertIntoFinalField extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_INTO_FINAL_FIELD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the enclosing getter.
    MethodDeclaration getter;
    for (var n = node; n != null; n = n.parent) {
      if (n is MethodDeclaration) {
        getter = n;
        break;
      }
      if (n is SimpleIdentifier ||
          n is TypeAnnotation ||
          n is TypeArgumentList) {
        continue;
      }
      break;
    }
    if (getter == null || !getter.isGetter) {
      return;
    }
    // Check that there is no corresponding setter.
    {
      var element = getter.declaredElement;
      if (element == null) {
        return;
      }
      var enclosing = element.enclosingElement;
      if (enclosing is ClassElement) {
        if (enclosing.getSetter(element.name) != null) {
          return;
        }
      }
    }
    // Try to find the returned expression.
    Expression expression;
    {
      var body = getter.body;
      if (body is ExpressionFunctionBody) {
        expression = body.expression;
      } else if (body is BlockFunctionBody) {
        List<Statement> statements = body.block.statements;
        if (statements.length == 1) {
          var statement = statements.first;
          if (statement is ReturnStatement) {
            expression = statement.expression;
          }
        }
      }
    }
    // Use the returned expression as the field initializer.
    if (expression != null) {
      var code = 'final';
      if (getter.returnType != null) {
        code += ' ' + utils.getNodeText(getter.returnType);
      }
      code += ' ' + utils.getNodeText(getter.name);
      if (expression is! NullLiteral) {
        code += ' = ' + utils.getNodeText(expression);
      }
      code += ';';
      var replacementRange =
          range.startEnd(getter.returnType ?? getter.propertyKeyword, getter);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(replacementRange, code);
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertIntoFinalField newInstance() => ConvertIntoFinalField();
}
