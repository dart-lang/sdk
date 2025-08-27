// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'arguments.dart';
import 'elements.dart';
import 'proto.dart';
import 'record_fields.dart';
import 'references.dart';
import 'string_literal_parts.dart';
import 'type_annotations.dart';
import 'util.dart';

/// Superclass for all expression nodes.
sealed class Expression {
  /// Returns the [Expression] corresponding to this [Expression] in which all
  /// [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [Expression], `null` is returned.
  Expression? resolve();
}

class InvalidExpression extends Expression {
  @override
  String toString() => 'InvalidExpression()';

  @override
  Expression? resolve() => null;
}

class StaticGet extends Expression {
  final FieldReference reference;

  StaticGet(this.reference);

  @override
  String toString() => 'StaticGet($reference)';

  @override
  Expression? resolve() => null;
}

class FunctionTearOff extends Expression {
  final FunctionReference reference;

  FunctionTearOff(this.reference);

  @override
  String toString() => 'FunctionTearOff($reference)';

  @override
  Expression? resolve() => null;
}

class ConstructorTearOff extends Expression {
  final TypeAnnotation type;
  final ConstructorReference reference;

  ConstructorTearOff(this.type, this.reference);

  @override
  String toString() => 'ConstructorTearOff($type,$reference)';

  @override
  Expression? resolve() {
    TypeAnnotation? newType = type.resolve();
    return newType == null ? null : new ConstructorTearOff(newType, reference);
  }
}

class ConstructorInvocation extends Expression {
  final TypeAnnotation type;
  final Reference constructor;
  final List<Argument> arguments;

  ConstructorInvocation(this.type, this.constructor, this.arguments);

  @override
  String toString() => 'ConstructorInvocation($type,$constructor,$arguments)';

  @override
  Expression? resolve() {
    TypeAnnotation? newType = type.resolve();
    List<Argument>? newArguments = arguments.resolve((a) => a.resolve());
    return newType == null && newArguments == null
        ? null
        : new ConstructorInvocation(
            newType ?? type,
            constructor,
            newArguments ?? arguments,
          );
  }
}

class IntegerLiteral extends Expression {
  final String? text;
  final int? value;

  IntegerLiteral.fromText(String this.text, [this.value]);

  IntegerLiteral.fromValue(int this.value) : text = null;

  @override
  String toString() => 'IntegerLiteral(${value ?? text})';

  @override
  Expression? resolve() => null;
}

class DoubleLiteral extends Expression {
  final String text;
  final double value;

  DoubleLiteral(this.text, this.value);

  @override
  String toString() => 'DoubleLiteral($text)';

  @override
  Expression? resolve() => null;
}

class BooleanLiteral extends Expression {
  final bool value;

  BooleanLiteral(this.value);

  @override
  String toString() => 'BooleanLiteral($value)';

  @override
  Expression? resolve() => null;
}

class NullLiteral extends Expression {
  NullLiteral();

  @override
  String toString() => 'NullLiteral()';

  @override
  Expression? resolve() => null;
}

class SymbolLiteral extends Expression {
  final List<String> parts;

  SymbolLiteral(this.parts);

  @override
  String toString() => 'SymbolLiteral($parts)';

  @override
  Expression? resolve() => null;
}

class StringLiteral extends Expression {
  final List<StringLiteralPart> parts;

  StringLiteral(this.parts);

  @override
  String toString() => 'StringLiteral($parts)';

  @override
  Expression? resolve() {
    List<StringLiteralPart>? newParts = parts.resolve((p) => p.resolve());
    return newParts == null ? null : new StringLiteral(newParts);
  }
}

class AdjacentStringLiterals extends Expression {
  final List<Expression> expressions;

  AdjacentStringLiterals(this.expressions);

  @override
  String toString() => 'AdjacentStringLiterals($expressions)';

  @override
  Expression? resolve() {
    List<Expression>? newExpressions = expressions.resolve((e) => e.resolve());
    return newExpressions == null
        ? null
        : new AdjacentStringLiterals(newExpressions);
  }
}

class ImplicitInvocation extends Expression {
  final Expression receiver;
  final List<TypeAnnotation> typeArguments;
  final List<Argument> arguments;

  ImplicitInvocation(this.receiver, this.typeArguments, this.arguments);

  @override
  String toString() =>
      'ImplicitInvocation($receiver,$typeArguments,$arguments)';

  @override
  Expression? resolve() {
    Expression? newReceiver = receiver.resolve();
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    List<Argument>? newArguments = arguments.resolve((a) => a.resolve());
    return newReceiver == null &&
            newTypeArguments == null &&
            newArguments == null
        ? null
        : new ImplicitInvocation(
            newReceiver ?? receiver,
            newTypeArguments ?? typeArguments,
            newArguments ?? arguments,
          );
  }
}

class StaticInvocation extends Expression {
  final FunctionReference function;
  final List<TypeAnnotation> typeArguments;
  final List<Argument> arguments;

  StaticInvocation(this.function, this.typeArguments, this.arguments);

  @override
  String toString() => 'StaticInvocation($function,$typeArguments,$arguments)';

  @override
  Expression? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    List<Argument>? newArguments = arguments.resolve((a) => a.resolve());
    return newTypeArguments == null && newArguments == null
        ? null
        : new StaticInvocation(
            function,
            newTypeArguments ?? typeArguments,
            newArguments ?? arguments,
          );
  }
}

class Instantiation extends Expression {
  final Expression receiver;
  final List<TypeAnnotation> typeArguments;

  Instantiation(this.receiver, this.typeArguments);

  @override
  String toString() => 'Instantiation($receiver,$typeArguments)';

  @override
  Expression? resolve() {
    Expression? newReceiver = receiver.resolve();
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    return newReceiver == null && newTypeArguments == null
        ? null
        : new Instantiation(
            newReceiver ?? receiver,
            newTypeArguments ?? typeArguments,
          );
  }
}

class MethodInvocation extends Expression {
  final Expression receiver;
  final String name;
  final List<TypeAnnotation> typeArguments;
  final List<Argument> arguments;

  MethodInvocation(
    this.receiver,
    this.name,
    this.typeArguments,
    this.arguments,
  );

  @override
  String toString() =>
      'MethodInvocation($receiver,$name,$typeArguments,$arguments)';

  @override
  Expression? resolve() {
    Expression? newReceiver = receiver.resolve();
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    List<Argument>? newArguments = arguments.resolve((a) => a.resolve());
    return newReceiver == null &&
            newTypeArguments == null &&
            newArguments == null
        ? null
        : new MethodInvocation(
            newReceiver ?? receiver,
            name,
            newTypeArguments ?? typeArguments,
            newArguments ?? arguments,
          );
  }
}

class PropertyGet extends Expression {
  final Expression receiver;
  final String name;

  PropertyGet(this.receiver, this.name);

  @override
  String toString() => 'PropertyGet($receiver,$name)';

  @override
  Expression? resolve() {
    Expression? newReceiver = receiver.resolve();
    return newReceiver == null ? null : new PropertyGet(newReceiver, name);
  }
}

class NullAwarePropertyGet extends Expression {
  final Expression receiver;
  final String name;

  NullAwarePropertyGet(this.receiver, this.name);

  @override
  String toString() => 'NullAwarePropertyGet($receiver,$name)';

  @override
  Expression? resolve() {
    Expression? newReceiver = receiver.resolve();
    return newReceiver == null
        ? null
        : new NullAwarePropertyGet(newReceiver, name);
  }
}

class TypeLiteral extends Expression {
  final TypeAnnotation typeAnnotation;

  TypeLiteral(this.typeAnnotation);

  @override
  String toString() => 'TypeLiteral($typeAnnotation)';

  @override
  Expression? resolve() {
    TypeAnnotation? newTypeAnnotation = typeAnnotation.resolve();
    return newTypeAnnotation == null
        ? null
        : new TypeLiteral(newTypeAnnotation);
  }
}

class ParenthesizedExpression extends Expression {
  final Expression expression;

  ParenthesizedExpression(this.expression);

  @override
  String toString() => 'ParenthesizedExpression($expression)';

  @override
  Expression? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new ParenthesizedExpression(newExpression);
  }
}

class ConditionalExpression extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  ConditionalExpression(this.condition, this.then, this.otherwise);

  @override
  String toString() => 'ConditionalExpression($condition,$then,$otherwise)';

  @override
  Expression? resolve() {
    Expression? newCondition = condition.resolve();
    Expression? newThen = then.resolve();
    Expression? newOtherwise = otherwise.resolve();
    return newCondition == null && newThen == null && newOtherwise == null
        ? null
        : new ConditionalExpression(
            newCondition ?? condition,
            newThen ?? then,
            newOtherwise ?? otherwise,
          );
  }
}

class ListLiteral extends Expression {
  final List<TypeAnnotation> typeArguments;
  final List<Element> elements;

  ListLiteral(this.typeArguments, this.elements);

  @override
  String toString() => 'ListLiteral($typeArguments,$elements)';

  @override
  Expression? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    List<Element>? newElements = elements.resolve((e) => e.resolve());
    return newTypeArguments == null && newElements == null
        ? null
        : new ListLiteral(
            newTypeArguments ?? typeArguments,
            newElements ?? elements,
          );
  }
}

class SetOrMapLiteral extends Expression {
  final List<TypeAnnotation> typeArguments;
  final List<Element> elements;

  SetOrMapLiteral(this.typeArguments, this.elements);

  @override
  String toString() => 'SetOrMapLiteral($typeArguments,$elements)';

  @override
  Expression? resolve() {
    List<TypeAnnotation>? newTypeArguments = typeArguments.resolve(
      (t) => t.resolve(),
    );
    List<Element>? newElements = elements.resolve((e) => e.resolve());
    return newTypeArguments == null && newElements == null
        ? null
        : new SetOrMapLiteral(
            newTypeArguments ?? typeArguments,
            newElements ?? elements,
          );
  }
}

class RecordLiteral extends Expression {
  final List<RecordField> fields;

  RecordLiteral(this.fields);

  @override
  String toString() => 'RecordLiteral($fields)';

  @override
  Expression? resolve() {
    List<RecordField>? newFields = fields.resolve((e) => e.resolve());
    return newFields == null ? null : new RecordLiteral(newFields);
  }
}

class IfNull extends Expression {
  final Expression left;
  final Expression right;

  IfNull(this.left, this.right);

  @override
  String toString() => 'IfNull($left,$right)';

  @override
  Expression? resolve() {
    Expression? newLeft = left.resolve();
    Expression? newRight = right.resolve();
    return newLeft == null && newRight == null
        ? null
        : new IfNull(newLeft ?? left, newRight ?? right);
  }
}

enum LogicalOperator {
  and('&&'),
  or('||');

  final String text;

  const LogicalOperator(this.text);
}

class LogicalExpression extends Expression {
  final Expression left;
  final LogicalOperator operator;
  final Expression right;

  LogicalExpression(this.left, this.operator, this.right);

  @override
  String toString() => 'LogicalExpression($left,$operator,$right)';

  @override
  Expression? resolve() {
    Expression? newLeft = left.resolve();
    Expression? newRight = right.resolve();
    return newLeft == null && newRight == null
        ? null
        : new LogicalExpression(newLeft ?? left, operator, newRight ?? right);
  }
}

class EqualityExpression extends Expression {
  final Expression left;
  final Expression right;
  final bool isNotEquals;

  EqualityExpression(this.left, this.right, {required this.isNotEquals});

  @override
  String toString() =>
      'EqualityExpression($left,$right,isNotEquals=$isNotEquals)';

  @override
  Expression? resolve() {
    Expression? newLeft = left.resolve();
    Expression? newRight = right.resolve();
    return newLeft == null && newRight == null
        ? null
        : new EqualityExpression(
            newLeft ?? left,
            newRight ?? right,
            isNotEquals: isNotEquals,
          );
  }
}

enum BinaryOperator {
  greaterThan('>'),
  greaterThanOrEqual('>='),
  lessThan('<'),
  lessThanOrEqual('<='),
  shiftLeft('<<'),
  signedShiftRight('>>'),
  unsignedShiftRight('>>>'),
  plus('+'),
  minus('-'),
  times('*'),
  divide('/'),
  integerDivide('~/'),
  modulo('%'),
  bitwiseOr('|'),
  bitwiseAnd('&'),
  bitwiseXor('^');

  final String text;

  const BinaryOperator(this.text);
}

class BinaryExpression extends Expression {
  final Expression left;
  final BinaryOperator operator;
  final Expression right;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  String toString() => 'BinaryExpression($left,$operator,$right)';

  @override
  Expression? resolve() {
    Expression? newLeft = left.resolve();
    Expression? newRight = right.resolve();
    return newLeft == null && newRight == null
        ? null
        : new BinaryExpression(newLeft ?? left, operator, newRight ?? right);
  }
}

enum UnaryOperator {
  minus('-'),
  bang('!'),
  tilde('~');

  final String text;

  const UnaryOperator(this.text);
}

class UnaryExpression extends Expression {
  final UnaryOperator operator;
  final Expression expression;

  UnaryExpression(this.operator, this.expression);

  @override
  String toString() => 'UnaryExpression($operator,$expression)';

  @override
  Expression? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null
        ? null
        : new UnaryExpression(operator, newExpression);
  }
}

class IsTest extends Expression {
  final Expression expression;
  final TypeAnnotation type;
  final bool isNot;

  IsTest(this.expression, this.type, {required this.isNot});

  @override
  String toString() => 'IsTest($expression,$type,isNot=$isNot)';

  @override
  Expression? resolve() {
    TypeAnnotation? newType = type.resolve();
    Expression? newExpression = expression.resolve();
    return newType == null && newExpression == null
        ? null
        : new IsTest(
            newExpression ?? expression,
            newType ?? type,
            isNot: isNot,
          );
  }
}

class AsExpression extends Expression {
  final Expression expression;
  final TypeAnnotation type;

  AsExpression(this.expression, this.type);

  @override
  String toString() => 'AsExpression($expression,$type)';

  @override
  Expression? resolve() {
    TypeAnnotation? newType = type.resolve();
    Expression? newExpression = expression.resolve();
    return newType == null && newExpression == null
        ? null
        : new AsExpression(newExpression ?? expression, newType ?? type);
  }
}

class NullCheck extends Expression {
  final Expression expression;

  NullCheck(this.expression);

  @override
  String toString() => 'NullCheck($expression)';

  @override
  Expression? resolve() {
    Expression? newExpression = expression.resolve();
    return newExpression == null ? null : new NullCheck(newExpression);
  }
}

class UnresolvedExpression extends Expression {
  final Unresolved unresolved;

  UnresolvedExpression(this.unresolved);

  @override
  String toString() => 'UnresolvedExpression($unresolved)';

  @override
  Expression? resolve() {
    return unresolved.resolveAsExpression();
  }
}
