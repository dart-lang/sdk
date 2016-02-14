// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.summarize_const_expr;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Serialize the given constructor initializer [node].
 */
UnlinkedConstructorInitializer serializeConstructorInitializer(
    ConstructorInitializer node,
    UnlinkedConstBuilder serializeConstExpr(Expression expr)) {
  if (node is ConstructorFieldInitializer) {
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.field,
        name: node.fieldName.name,
        expression: serializeConstExpr(node.expression));
  }
  if (node is RedirectingConstructorInvocation) {
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.thisInvocation,
        name: node?.constructorName?.name,
        arguments:
            node.argumentList.arguments.map(serializeConstExpr).toList());
  }
  if (node is SuperConstructorInvocation) {
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.superInvocation,
        name: node?.constructorName?.name,
        arguments:
            node.argumentList.arguments.map(serializeConstExpr).toList());
  }
  throw new StateError('Unexpected initializer type ${node.runtimeType}');
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single constant [Expression].
 */
abstract class AbstractConstExprSerializer {
  /**
   * See [UnlinkedConstBuilder.isInvalid].
   */
  bool isInvalid = false;

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
   * Return `true` if a constructor initializer expression is being serialized
   * and the given [name] is a constructor parameter reference.
   */
  bool isConstructorParameterName(String name);

  /**
   * Serialize the given [expr] expression into this serializer state.
   */
  void serialize(Expression expr) {
    try {
      _serialize(expr);
    } on StateError {
      isInvalid = true;
    }
  }

  /**
   * Serialize the given [annotation] into this serializer state.
   */
  void serializeAnnotation(Annotation annotation);

  /**
   * Return [EntityRefBuilder] that corresponds to the constructor having name
   * [name] in the class identified by [type].
   */
  EntityRefBuilder serializeConstructorName(
      TypeName type, SimpleIdentifier name);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [identifier].
   */
  EntityRefBuilder serializeIdentifier(Identifier identifier);

  void serializeInstanceCreation(
      EntityRefBuilder constructor, ArgumentList argumentList) {
    List<Expression> arguments = argumentList.arguments;
    // Serialize the arguments.
    List<String> argumentNames = <String>[];
    arguments.forEach((arg) {
      if (arg is NamedExpression) {
        argumentNames.add(arg.name.label.name);
        _serialize(arg.expression);
      } else {
        _serialize(arg);
      }
    });
    // Add the op-code and numbers of named and positional arguments.
    operations.add(UnlinkedConstOperation.invokeConstructor);
    ints.add(argumentNames.length);
    strings.addAll(argumentNames);
    ints.add(arguments.length - argumentNames.length);
    // Serialize the reference.
    references.add(constructor);
  }

  /**
   * Return [EntityRefBuilder] that corresponds to the given [access].
   */
  EntityRefBuilder serializePropertyAccess(PropertyAccess access);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [type].
   */
  EntityRefBuilder serializeType(TypeName type);

  /**
   * Return the [UnlinkedConstBuilder] that corresponds to the state of this
   * serializer.
   */
  UnlinkedConstBuilder toBuilder() {
    if (isInvalid) {
      return new UnlinkedConstBuilder(isInvalid: true);
    }
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
      int numOfComponents = 0;
      ints.add(numOfComponents);
      void pushComponents(int value) {
        if (value >= (1 << 32)) {
          pushComponents(value >> 32);
        }
        numOfComponents++;
        ints.add(value & 0xFFFFFFFF);
      }
      pushComponents(value);
      ints[ints.length - 1 - numOfComponents] = numOfComponents;
      operations.add(UnlinkedConstOperation.pushLongInt);
    } else {
      operations.add(UnlinkedConstOperation.pushInt);
      ints.add(value);
    }
  }

  /**
   * Serialize the given [expr] expression into this serializer state.
   */
  void _serialize(Expression expr) {
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
      operations.add(UnlinkedConstOperation.makeSymbol);
    } else if (expr is NullLiteral) {
      operations.add(UnlinkedConstOperation.pushNull);
    } else if (expr is Identifier) {
      if (expr is SimpleIdentifier && isConstructorParameterName(expr.name)) {
        strings.add(expr.name);
        operations.add(UnlinkedConstOperation.pushConstructorParameter);
      } else {
        references.add(serializeIdentifier(expr));
        operations.add(UnlinkedConstOperation.pushReference);
      }
    } else if (expr is InstanceCreationExpression) {
      serializeInstanceCreation(
          serializeConstructorName(
              expr.constructorName.type, expr.constructorName.name),
          expr.argumentList);
    } else if (expr is ListLiteral) {
      _serializeListLiteral(expr);
    } else if (expr is MapLiteral) {
      _serializeMapLiteral(expr);
    } else if (expr is MethodInvocation) {
      String name = expr.methodName.name;
      if (name != 'identical') {
        throw new StateError('Only "identity" function invocation is allowed.');
      }
      if (expr.argumentList == null ||
          expr.argumentList.arguments.length != 2) {
        throw new StateError(
            'The function "identity" requires exactly 2 arguments.');
      }
      expr.argumentList.arguments.forEach(_serialize);
      operations.add(UnlinkedConstOperation.identical);
    } else if (expr is BinaryExpression) {
      _serializeBinaryExpression(expr);
    } else if (expr is ConditionalExpression) {
      _serialize(expr.condition);
      _serialize(expr.thenExpression);
      _serialize(expr.elseExpression);
      operations.add(UnlinkedConstOperation.conditional);
    } else if (expr is PrefixExpression) {
      _serializePrefixExpression(expr);
    } else if (expr is PropertyAccess) {
      if (expr.target is! PrefixedIdentifier &&
          expr.propertyName.name == 'length') {
        _serialize(expr.target);
        operations.add(UnlinkedConstOperation.length);
      } else {
        references.add(serializePropertyAccess(expr));
        operations.add(UnlinkedConstOperation.pushReference);
      }
    } else if (expr is ParenthesizedExpression) {
      _serialize(expr.expression);
    } else {
      throw new StateError('Unknown expression type: $expr');
    }
  }

  void _serializeBinaryExpression(BinaryExpression expr) {
    _serialize(expr.leftOperand);
    _serialize(expr.rightOperand);
    TokenType operator = expr.operator.type;
    if (operator == TokenType.EQ_EQ) {
      operations.add(UnlinkedConstOperation.equal);
    } else if (operator == TokenType.BANG_EQ) {
      operations.add(UnlinkedConstOperation.notEqual);
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
      throw new StateError('Unknown operator: $operator');
    }
  }

  void _serializeListLiteral(ListLiteral expr) {
    List<Expression> elements = expr.elements;
    elements.forEach(_serialize);
    ints.add(elements.length);
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 1) {
      references.add(serializeType(expr.typeArguments.arguments[0]));
      operations.add(UnlinkedConstOperation.makeTypedList);
    } else {
      operations.add(UnlinkedConstOperation.makeUntypedList);
    }
  }

  void _serializeMapLiteral(MapLiteral expr) {
    for (MapLiteralEntry entry in expr.entries) {
      _serialize(entry.key);
      _serialize(entry.value);
    }
    ints.add(expr.entries.length);
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 2) {
      references.add(serializeType(expr.typeArguments.arguments[0]));
      references.add(serializeType(expr.typeArguments.arguments[1]));
      operations.add(UnlinkedConstOperation.makeTypedMap);
    } else {
      operations.add(UnlinkedConstOperation.makeUntypedMap);
    }
  }

  void _serializePrefixExpression(PrefixExpression expr) {
    _serialize(expr.operand);
    TokenType operator = expr.operator.type;
    if (operator == TokenType.BANG) {
      operations.add(UnlinkedConstOperation.not);
    } else if (operator == TokenType.MINUS) {
      operations.add(UnlinkedConstOperation.negate);
    } else if (operator == TokenType.TILDE) {
      operations.add(UnlinkedConstOperation.complement);
    } else {
      throw new StateError('Unknown operator: $operator');
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
          _serialize((element as InterpolationExpression).expression);
        }
      }
      operations.add(UnlinkedConstOperation.concatenate);
      ints.add(interpolation.elements.length);
    }
  }
}
