// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/elements.dart';
import '../common/names.dart';
import '../elements/entities.dart';

import 'element_map_impl.dart';
import 'kelements.dart';

/// Interface for determining the form of a `noSuchMethod` implementation.
class NoSuchMethodResolver {
  final KernelToElementMapImpl elementMap;

  NoSuchMethodResolver(this.elementMap);

  CommonElements get _commonElements => elementMap.commonElements;

  /// Computes whether [method] is of the form
  ///
  ///     noSuchMethod(i) => super.noSuchMethod(i);
  ///
  bool hasForwardingSyntax(KFunction method) {
    ir.Procedure node = elementMap.lookupProcedure(method);
    if (node.function.positionalParameters.isEmpty) return false;
    ir.VariableDeclaration firstParameter =
        node.function.positionalParameters.first;
    ir.Statement body = node.function.body;
    ir.Expression expr;
    if (body is ir.Block && body.statements.isNotEmpty) {
      ir.Block block = body;
      body = block.statements.first;
    }
    if (body is ir.ReturnStatement) {
      expr = body.expression;
    }
    if (expr is ir.AsExpression &&
        elementMap.getDartType(expr.type) == _commonElements.dynamicType) {
      ir.AsExpression asExpression = expr;
      expr = asExpression.operand;
    }
    if (expr is ir.SuperMethodInvocation &&
        expr.name.text == Identifiers.noSuchMethod_) {
      ir.Arguments arguments = expr.arguments;
      if (arguments.positional.length == 1 &&
          arguments.named.isEmpty &&
          arguments.positional.first is ir.VariableGet) {
        ir.VariableGet get = arguments.positional.first;
        return get.variable == firstParameter;
      }
    }
    return false;
  }

  /// Computes whether [method] is of the form
  ///
  ///     noSuchMethod(i) => throw new Error();
  ///
  bool hasThrowingSyntax(KFunction method) {
    ir.Procedure node = elementMap.lookupProcedure(method);
    ir.Statement body = node.function.body;
    if (body is ir.Block && body.statements.isNotEmpty) {
      ir.Block block = body;
      body = block.statements.first;
    }
    ir.Expression expr;
    if (body is ir.ReturnStatement) {
      expr = body.expression;
    } else if (body is ir.ExpressionStatement) {
      expr = body.expression;
    }
    return expr is ir.Throw;
  }

  /// Returns the `noSuchMethod` that [method] overrides.
  FunctionEntity getSuperNoSuchMethod(FunctionEntity method) {
    return elementMap.getSuperNoSuchMethod(method.enclosingClass);
  }
}
