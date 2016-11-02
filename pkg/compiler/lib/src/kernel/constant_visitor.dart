// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as ir;

import '../constants/expressions.dart';
import 'kernel.dart';

/// Visitor that converts a [ConstantExpression] into a kernel constant
/// expression.
class ConstantVisitor extends ConstantExpressionVisitor<ir.Node, Kernel> {
  const ConstantVisitor();

  @override
  ir.Node visitNamed(NamedArgumentReference exp, Kernel kernel) {
    throw new UnsupportedError(
        '${exp.toStructuredText()} is not a valid constant.');
  }

  @override
  ir.Node visitPositional(PositionalArgumentReference exp, Kernel kernel) {
    throw new UnsupportedError(
        '${exp.toStructuredText()} is not a valid constant.');
  }

  @override
  ir.Node visitDeferred(DeferredConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitStringFromEnvironment(
      StringFromEnvironmentConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitIntFromEnvironment(
      IntFromEnvironmentConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitBoolFromEnvironment(
      BoolFromEnvironmentConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitConditional(ConditionalConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitStringLength(StringLengthConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitUnary(UnaryConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitIdentical(IdenticalConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitBinary(BinaryConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitFunction(FunctionConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitVariable(VariableConstantExpression exp, Kernel kernel) {
    return new ir.StaticGet(kernel.fieldToIr(exp.element));
  }

  @override
  ir.Node visitType(TypeConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitSymbol(SymbolConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitConcatenate(ConcatenateConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitConstructed(ConstructedConstantExpression exp, Kernel kernel) {
    List<ir.Expression> positional = <ir.Expression>[];
    List<ir.NamedExpression> named = <ir.NamedExpression>[];
    int positionalCount = exp.callStructure.positionalArgumentCount;
    for (int index = 0; index < positionalCount; index++) {
      ir.Expression argument = visit(exp.arguments[index], kernel);
      if (index < exp.callStructure.positionalArgumentCount) {
        positional.add(argument);
      } else {
        named.add(new ir.NamedExpression(
            exp.callStructure.namedArguments[index - positionalCount],
            argument));
      }
    }
    ir.Arguments arguments = new ir.Arguments(positional, named: named);
    return new ir.ConstructorInvocation(
        kernel.functionToIr(exp.target), arguments,
        isConst: true);
  }

  @override
  ir.Node visitMap(MapConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitList(ListConstantExpression exp, Kernel kernel) {
    throw new UnimplementedError('${exp.toStructuredText()} is not supported.');
  }

  @override
  ir.Node visitNull(NullConstantExpression exp, Kernel kernel) {
    return new ir.NullLiteral();
  }

  @override
  ir.Node visitString(StringConstantExpression exp, Kernel kernel) {
    return new ir.StringLiteral(exp.primitiveValue);
  }

  @override
  ir.Node visitDouble(DoubleConstantExpression exp, Kernel kernel) {
    return new ir.DoubleLiteral(exp.primitiveValue);
  }

  @override
  ir.Node visitInt(IntConstantExpression exp, Kernel kernel) {
    return new ir.IntLiteral(exp.primitiveValue);
  }

  @override
  ir.Node visitBool(BoolConstantExpression exp, Kernel kernel) {
    return new ir.BoolLiteral(exp.primitiveValue);
  }
}
