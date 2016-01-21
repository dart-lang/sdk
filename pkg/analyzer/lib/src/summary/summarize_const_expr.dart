// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.summarize_const_expr;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/summary/format.dart';

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single constant [Expression].
 */
abstract class AbstractConstExprSerializer {
  /**
   * See [UnlinkedConstBuilder.operations].
   */
  final List<UnlinkedConstOperation> operations = <UnlinkedConstOperation>[];

  /**
   * See [UnlinkedConstBuilder.ints].
   */
  final List<int> ints = <int>[];

  /**
   * See [UnlinkedConstBuilder.doubles].
   */
  final List<double> doubles = <double>[];

  /**
   * See [UnlinkedConstBuilder.strings].
   */
  final List<String> strings = <String>[];

  /**
   * See [UnlinkedConstBuilder.references].
   */
  final List<EntityRefBuilder> references = <EntityRefBuilder>[];

  /**
   * Serialize the given [expr] expression into this serializer state.
   */
  void serialize(Expression expr) {
    if (expr is IntegerLiteral) {
      _pushInt(expr.value);
    } else if (expr is DoubleLiteral) {
      operations.add(UnlinkedConstOperation.pushDouble);
      doubles.add(expr.value);
    } else if (expr is BooleanLiteral) {
      if (expr.value) {
        operations.add(UnlinkedConstOperation.pushTrue);
      } else {
        operations.add(UnlinkedConstOperation.pushFalse);
      }
    } else if (expr is StringLiteral) {
      _serializeString(expr);
    } else if (expr is SymbolLiteral) {
      strings.add(expr.components.map((token) => token.lexeme).join('.'));
      operations.add(UnlinkedConstOperation.pushString);
      operations.add(UnlinkedConstOperation.makeSymbol);
    } else if (expr is NullLiteral) {
      operations.add(UnlinkedConstOperation.pushNull);
    } else if (expr is Identifier) {
      references.add(serializeIdentifier(expr));
      operations.add(UnlinkedConstOperation.pushReference);
    } else if (expr is InstanceCreationExpression) {
      _serializeInstanceCreation(expr);
    } else if (expr is ListLiteral) {
      _serializeListLiteral(expr);
    } else if (expr is MapLiteral) {
      _serializeMapLiteral(expr);
    } else if (expr is MethodInvocation) {
      String name = expr.methodName.name;
      if (name != 'identical') {
        throw new _ConstExprSerializationError(
            'Only "identity" function invocation is allowed.');
      }
      if (expr.argumentList == null ||
          expr.argumentList.arguments.length != 2) {
        throw new _ConstExprSerializationError(
            'The function "identity" requires exactly 2 arguments.');
      }
      expr.argumentList.arguments.forEach(serialize);
      operations.add(UnlinkedConstOperation.identical);
    } else if (expr is BinaryExpression) {
      _serializeBinaryExpression(expr);
    } else if (expr is ConditionalExpression) {
      serialize(expr.condition);
      serialize(expr.thenExpression);
      serialize(expr.elseExpression);
      operations.add(UnlinkedConstOperation.conditional);
    } else if (expr is PrefixExpression) {
      _serializePrefixExpression(expr);
    } else if (expr is PropertyAccess && expr.propertyName.name == 'length') {
      serialize(expr.target);
      operations.add(UnlinkedConstOperation.length);
    } else if (expr is ParenthesizedExpression) {
      serialize(expr.expression);
    } else {
      throw new _ConstExprSerializationError('Unknown expression type: $expr');
    }
  }

  /**
   * Return [EntityRefBuilder] that corresponds to the given [identifier].
   */
  EntityRefBuilder serializeIdentifier(Identifier identifier);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [type].
   */
  EntityRefBuilder serializeType(TypeName type);

  /**
   * Return the [UnlinkedConstBuilder] that corresponds to the state of this
   * serializer.
   */
  UnlinkedConstBuilder toBuilder() {
    return new UnlinkedConstBuilder(
        operations: operations,
        ints: ints,
        doubles: doubles,
        strings: strings,
        references: references);
  }

  void _pushInt(int value) {
    assert(value >= 0);
    if (value >= (1 << 32)) {
      _pushInt(value >> 32);
      operations.add(UnlinkedConstOperation.shiftOr);
      ints.add(value & 0xFFFFFFFF);
    } else {
      operations.add(UnlinkedConstOperation.pushInt);
      ints.add(value);
    }
  }

  void _serializeBinaryExpression(BinaryExpression expr) {
    serialize(expr.leftOperand);
    serialize(expr.rightOperand);
    TokenType operator = expr.operator.type;
    if (operator == TokenType.EQ_EQ) {
      operations.add(UnlinkedConstOperation.equal);
    } else if (operator == TokenType.BANG_EQ) {
      operations.add(UnlinkedConstOperation.equal);
      operations.add(UnlinkedConstOperation.not);
    } else if (operator == TokenType.AMPERSAND_AMPERSAND) {
      operations.add(UnlinkedConstOperation.and);
    } else if (operator == TokenType.BAR_BAR) {
      operations.add(UnlinkedConstOperation.or);
    } else if (operator == TokenType.CARET) {
      operations.add(UnlinkedConstOperation.bitXor);
    } else if (operator == TokenType.AMPERSAND) {
      operations.add(UnlinkedConstOperation.bitAnd);
    } else if (operator == TokenType.BAR) {
      operations.add(UnlinkedConstOperation.bitOr);
    } else if (operator == TokenType.GT_GT) {
      operations.add(UnlinkedConstOperation.bitShiftRight);
    } else if (operator == TokenType.LT_LT) {
      operations.add(UnlinkedConstOperation.bitShiftLeft);
    } else if (operator == TokenType.PLUS) {
      operations.add(UnlinkedConstOperation.add);
    } else if (operator == TokenType.MINUS) {
      operations.add(UnlinkedConstOperation.subtract);
    } else if (operator == TokenType.STAR) {
      operations.add(UnlinkedConstOperation.multiply);
    } else if (operator == TokenType.SLASH) {
      operations.add(UnlinkedConstOperation.divide);
    } else if (operator == TokenType.TILDE_SLASH) {
      operations.add(UnlinkedConstOperation.floorDivide);
    } else if (operator == TokenType.GT) {
      operations.add(UnlinkedConstOperation.greater);
    } else if (operator == TokenType.LT) {
      operations.add(UnlinkedConstOperation.less);
    } else if (operator == TokenType.GT_EQ) {
      operations.add(UnlinkedConstOperation.greaterEqual);
    } else if (operator == TokenType.LT_EQ) {
      operations.add(UnlinkedConstOperation.lessEqual);
    } else if (operator == TokenType.PERCENT) {
      operations.add(UnlinkedConstOperation.modulo);
    } else {
      throw new _ConstExprSerializationError('Unknown operator: $operator');
    }
  }

  void _serializeInstanceCreation(InstanceCreationExpression expr) {
    ConstructorName constructor = expr.constructorName;
    List<Expression> arguments = expr.argumentList.arguments;
    // Serialize the arguments.
    List<String> argumentNames = <String>[];
    arguments.forEach((arg) {
      if (arg is NamedExpression) {
        argumentNames.add(arg.name.label.name);
        serialize(arg.expression);
      } else {
        serialize(arg);
      }
    });
    // Add the op-code and numbers of named and positional arguments.
    operations.add(UnlinkedConstOperation.invokeConstructor);
    ints.add(argumentNames.length);
    strings.addAll(argumentNames);
    ints.add(arguments.length - argumentNames.length);
    // Serialize the reference.
    references.add(serializeType(constructor.type));
    if (constructor.name != null) {
      strings.add(constructor.name.name);
    } else {
      strings.add('');
    }
  }

  void _serializeListLiteral(ListLiteral expr) {
    List<Expression> elements = expr.elements;
    elements.forEach(serialize);
    TypeName typeArgument;
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 1) {
      typeArgument = expr.typeArguments.arguments[0];
    }
    references.add(serializeType(typeArgument));
    ints.add(elements.length);
    operations.add(UnlinkedConstOperation.makeList);
  }

  void _serializeMapLiteral(MapLiteral expr) {
    for (MapLiteralEntry entry in expr.entries) {
      serialize(entry.key);
      serialize(entry.value);
    }
    TypeName keyTypeArgument;
    TypeName valueTypeArgument;
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 2) {
      keyTypeArgument = expr.typeArguments.arguments[0];
      valueTypeArgument = expr.typeArguments.arguments[1];
    }
    references.add(serializeType(keyTypeArgument));
    references.add(serializeType(valueTypeArgument));
    ints.add(expr.entries.length);
    operations.add(UnlinkedConstOperation.makeMap);
  }

  void _serializePrefixExpression(PrefixExpression expr) {
    serialize(expr.operand);
    TokenType operator = expr.operator.type;
    if (operator == TokenType.BANG) {
      operations.add(UnlinkedConstOperation.not);
    } else if (operator == TokenType.MINUS) {
      operations.add(UnlinkedConstOperation.negate);
    } else if (operator == TokenType.TILDE) {
      operations.add(UnlinkedConstOperation.complement);
    } else {
      throw new _ConstExprSerializationError('Unknown operator: $operator');
    }
  }

  void _serializeString(StringLiteral expr) {
    if (expr is AdjacentStrings) {
      if (expr.strings.every((string) => string is SimpleStringLiteral)) {
        operations.add(UnlinkedConstOperation.pushString);
        strings.add(expr.stringValue);
      } else {
        expr.strings.forEach(_serializeString);
        operations.add(UnlinkedConstOperation.concatenate);
        ints.add(expr.strings.length);
      }
    } else if (expr is SimpleStringLiteral) {
      operations.add(UnlinkedConstOperation.pushString);
      strings.add(expr.value);
    } else {
      StringInterpolation interpolation = expr as StringInterpolation;
      for (InterpolationElement element in interpolation.elements) {
        if (element is InterpolationString) {
          operations.add(UnlinkedConstOperation.pushString);
          strings.add(element.value);
        } else {
          serialize((element as InterpolationExpression).expression);
        }
      }
      operations.add(UnlinkedConstOperation.concatenate);
      ints.add(interpolation.elements.length);
    }
  }
}

/**
 * Error that describes a problem during a constant expression serialization.
 */
class _ConstExprSerializationError {
  final String message;

  _ConstExprSerializationError(this.message);

  @override
  String toString() => message;
}
