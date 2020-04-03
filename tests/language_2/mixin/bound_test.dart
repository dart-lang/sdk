// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// library abstract_expressions;

abstract class AbstractExpression {}

abstract class AbstractAddition<E> {
  E operand1, operand2;
  AbstractAddition(this.operand1, this.operand2);
}

abstract class AbstractSubtraction<E> {
  E operand1, operand2;
  AbstractSubtraction(this.operand1, this.operand2);
}

abstract class AbstractNumber {
  int val;
  AbstractNumber(this.val);
}

// library evaluator;

abstract class ExpressionWithEval {
  int get eval;
}

abstract class AdditionWithEval<E extends ExpressionWithEval> {
  E get operand1;
  E get operand2;
  int get eval => operand1.eval + operand2.eval;
}

abstract class SubtractionWithEval<E extends ExpressionWithEval> {
  E get operand1;
  E get operand2;
  int get eval => operand1.eval - operand2.eval;
}

abstract class NumberWithEval {
  int get val;
  int get eval => val;
}

// library multiplication;

abstract class AbstractMultiplication<E> {
  E operand1, operand2;
  AbstractMultiplication(this.operand1, this.operand2);
}

// library multiplicationEvaluator;

// import 'evaluator.dart' show ExpressionWithEval;

abstract class MultiplicationWithEval<E extends ExpressionWithEval> {
  E get operand1;
  E get operand2;
  int get eval => operand1.eval * operand2.eval;
}

// library string_converter;

abstract class ExpressionWithStringConversion {
  String toString();
}

abstract class AdditionWithStringConversion<
    E extends ExpressionWithStringConversion> {
  E get operand1;
  E get operand2;
  String toString() => '($operand1 + $operand2))';
}

abstract class SubtractionWithStringConversion<
    E extends ExpressionWithStringConversion> {
  E get operand1;
  E get operand2;
  String toString() => '($operand1 - $operand2)';
}

abstract class NumberWithStringConversion {
  int get val;
  String toString() => val.toString();
}

abstract class MultiplicationWithStringConversion<
    E extends ExpressionWithStringConversion> {
  E get operand1;
  E get operand2;
  String toString() => '($operand1 * $operand2)';
}

// library expressions;

// import 'abstractExpressions.dart';
// import 'evaluator.dart';
// import 'multiplication.dart';
// import 'multiplicationEvaluator.dart';
// import 'stringConverter.dart';

abstract class Expression = AbstractExpression
    with ExpressionWithEval, ExpressionWithStringConversion;

class Addition = AbstractAddition<Expression>
    with AdditionWithEval<Expression>, AdditionWithStringConversion<Expression>
    implements Expression;

class Subtraction = AbstractSubtraction<Expression>
    with
        SubtractionWithEval<Expression>,
        SubtractionWithStringConversion<Expression>
    implements Expression;

class Number = AbstractNumber
    with NumberWithEval, NumberWithStringConversion
    implements Expression;

class Multiplication = AbstractMultiplication<Expression>
    with
        MultiplicationWithEval<Expression>,
        MultiplicationWithStringConversion<Expression>
    implements Expression;

void main() {
  Expression e = new Multiplication(new Addition(new Number(4), new Number(2)),
      new Subtraction(new Number(10), new Number(7)));
  Expect.equals('((4 + 2)) * (10 - 7)) = 18', '$e = ${e.eval}');
}
