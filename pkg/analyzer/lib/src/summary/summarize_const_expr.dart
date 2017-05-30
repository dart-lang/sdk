// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization.summarize_const_expr;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart' show DartType;
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Serialize the given constructor initializer [node].
 */
UnlinkedConstructorInitializer serializeConstructorInitializer(
    ConstructorInitializer node,
    UnlinkedExprBuilder serializeConstExpr(Expression expr)) {
  if (node is ConstructorFieldInitializer) {
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.field,
        name: node.fieldName.name,
        expression: serializeConstExpr(node.expression));
  }

  List<UnlinkedExprBuilder> arguments = <UnlinkedExprBuilder>[];
  List<String> argumentNames = <String>[];
  void serializeArguments(List<Expression> args) {
    for (Expression arg in args) {
      if (arg is NamedExpression) {
        NamedExpression namedExpression = arg;
        argumentNames.add(namedExpression.name.label.name);
        arg = namedExpression.expression;
      }
      arguments.add(serializeConstExpr(arg));
    }
  }

  if (node is AssertInitializer) {
    serializeArguments(node.message != null
        ? [node.condition, node.message]
        : [node.condition]);
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.assertInvocation,
        arguments: arguments);
  }
  if (node is RedirectingConstructorInvocation) {
    serializeArguments(node.argumentList.arguments);
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.thisInvocation,
        name: node?.constructorName?.name,
        arguments: arguments,
        argumentNames: argumentNames);
  }
  if (node is SuperConstructorInvocation) {
    serializeArguments(node.argumentList.arguments);
    return new UnlinkedConstructorInitializerBuilder(
        kind: UnlinkedConstructorInitializerKind.superInvocation,
        name: node?.constructorName?.name,
        arguments: arguments,
        argumentNames: argumentNames);
  }
  throw new StateError('Unexpected initializer type ${node.runtimeType}');
}

/**
 * Instances of this class keep track of intermediate state during
 * serialization of a single constant [Expression].
 */
abstract class AbstractConstExprSerializer {
  /**
   * Whether an expression that should be a constant is being serialized.
   *
   * For constants we need to store more than we need just for type inference,
   * because we need to be able to restore these AST to evaluate actual values
   * of constants. So, we need to store constructor arguments, elements for
   * list and map literals even if these literals are typed.
   */
  final bool forConst;

  /**
   * See [UnlinkedExprBuilder.isValidConst].
   */
  bool isValidConst = true;

  /**
   * See [UnlinkedExprBuilder.name].
   */
  String name = null;

  /**
   * See [UnlinkedExprBuilder.operations].
   */
  final List<UnlinkedExprOperation> operations = <UnlinkedExprOperation>[];

  /**
   * See [UnlinkedExprBuilder.assignmentOperators].
   */
  final List<UnlinkedExprAssignOperator> assignmentOperators =
      <UnlinkedExprAssignOperator>[];

  /**
   * See [UnlinkedExprBuilder.ints].
   */
  final List<int> ints = <int>[];

  /**
   * See [UnlinkedExprBuilder.doubles].
   */
  final List<double> doubles = <double>[];

  /**
   * See [UnlinkedExprBuilder.strings].
   */
  final List<String> strings = <String>[];

  /**
   * See [UnlinkedExprBuilder.references].
   */
  final List<EntityRefBuilder> references = <EntityRefBuilder>[];

  AbstractConstExprSerializer(this.forConst);

  /**
   * Return `true` if the given [name] is a parameter reference.
   */
  bool isParameterName(String name);

  /**
   * Serialize the given [expr] expression into this serializer state.
   */
  void serialize(Expression expr) {
    try {
      if (expr is NamedExpression) {
        NamedExpression namedExpression = expr;
        name = namedExpression.name.label.name;
        expr = namedExpression.expression;
      }
      _serialize(expr);
    } on StateError {
      isValidConst = false;
      operations.clear();
      assignmentOperators.clear();
      ints.clear();
      doubles.clear();
      strings.clear();
      references.clear();
    }
  }

  /**
   * Serialize the given [annotation] into this serializer state.
   */
  void serializeAnnotation(Annotation annotation);

  /**
   * Return [EntityRefBuilder] that corresponds to the constructor having name
   * [name] in the class identified by [typeName].  It is expected that [type]
   * corresponds to the given [typeName] and [typeArguments].  The parameter
   * [type] might be `null` if the type is not resolved.
   */
  EntityRefBuilder serializeConstructorRef(DartType type, Identifier typeName,
      TypeArgumentList typeArguments, SimpleIdentifier name);

  /**
   * Return a pair of ints showing how the given [functionExpression] is nested
   * within the constant currently being serialized.  The first int indicates
   * how many levels of function nesting must be popped in order to reach the
   * parent of the [functionExpression].  The second int is the index of the
   * [functionExpression] within its parent element.
   *
   * If the constant being summarized is in a context where local function
   * references are not allowed, return `null`.
   */
  List<int> serializeFunctionExpression(FunctionExpression functionExpression);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [identifier].
   */
  EntityRefBuilder serializeIdentifier(Identifier identifier);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [expr], which
   * must be a sequence of identifiers.
   */
  EntityRefBuilder serializeIdentifierSequence(Expression expr);

  void serializeInstanceCreation(
      EntityRefBuilder constructor, ArgumentList argumentList) {
    _serializeArguments(argumentList);
    references.add(constructor);
    operations.add(UnlinkedExprOperation.invokeConstructor);
  }

  /**
   * Return [EntityRefBuilder] that corresponds to the [type] with the given
   * [name] and [arguments].  It is expected that [type] corresponds to the
   * given [name] and [arguments].  The parameter [type] might be `null` if the
   * type is not resolved.
   */
  EntityRefBuilder serializeType(
      DartType type, Identifier name, TypeArgumentList arguments);

  /**
   * Return [EntityRefBuilder] that corresponds to the given [type].
   */
  EntityRefBuilder serializeTypeName(TypeAnnotation type) {
    if (type is TypeName) {
      return serializeType(type?.type, type?.name, type?.typeArguments);
    }
    throw new ArgumentError(
        'Cannot serialize an instance of ${type.runtimeType}');
  }

  /**
   * Return the [UnlinkedExprBuilder] that corresponds to the state of this
   * serializer.
   */
  UnlinkedExprBuilder toBuilder() {
    return new UnlinkedExprBuilder(
        isValidConst: isValidConst,
        operations: operations,
        assignmentOperators: assignmentOperators,
        ints: ints,
        doubles: doubles,
        strings: strings,
        references: references);
  }

  /**
   * Return `true` if the given [expr] is a sequence of identifiers.
   */
  bool _isIdentifierSequence(Expression expr) {
    while (expr != null) {
      if (expr is SimpleIdentifier) {
        AstNode parent = expr.parent;
        if (parent is MethodInvocation && parent.methodName == expr) {
          if (parent.isCascaded) {
            return false;
          }
          return parent.target == null || _isIdentifierSequence(parent.target);
        }
        if (isParameterName(expr.name)) {
          return false;
        }
        return true;
      } else if (expr is PrefixedIdentifier) {
        expr = (expr as PrefixedIdentifier).prefix;
      } else if (expr is PropertyAccess) {
        expr = (expr as PropertyAccess).target;
      } else {
        return false;
      }
    }
    return false;
  }

  /**
   * Push the operation for the given assignable [expr].
   */
  void _pushAssignable(Expression expr) {
    if (_isIdentifierSequence(expr)) {
      EntityRefBuilder ref = serializeIdentifierSequence(expr);
      references.add(ref);
      operations.add(UnlinkedExprOperation.assignToRef);
    } else if (expr is PropertyAccess) {
      if (!expr.isCascaded) {
        _serialize(expr.target);
      }
      strings.add(expr.propertyName.name);
      operations.add(UnlinkedExprOperation.assignToProperty);
    } else if (expr is IndexExpression) {
      if (!expr.isCascaded) {
        _serialize(expr.target);
      }
      _serialize(expr.index);
      operations.add(UnlinkedExprOperation.assignToIndex);
    } else if (expr is PrefixedIdentifier) {
      strings.add(expr.prefix.name);
      operations.add(UnlinkedExprOperation.pushParameter);
      strings.add(expr.identifier.name);
      operations.add(UnlinkedExprOperation.assignToProperty);
    } else {
      throw new StateError('Unsupported assignable: $expr');
    }
  }

  void _pushInt(int value) {
    value ??= 0;
    assert(value >= 0);
    if (value >= 0x100000000) {
      int numOfComponents = 0;
      ints.add(numOfComponents);
      void pushComponents(int value) {
        if (value >= 0x100000000) {
          pushComponents(value ~/ 0x100000000);
        }
        numOfComponents++;
        ints.add(value & 0xFFFFFFFF);
      }

      pushComponents(value);
      ints[ints.length - 1 - numOfComponents] = numOfComponents;
      operations.add(UnlinkedExprOperation.pushLongInt);
    } else {
      operations.add(UnlinkedExprOperation.pushInt);
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
      operations.add(UnlinkedExprOperation.pushDouble);
      doubles.add(expr.value);
    } else if (expr is BooleanLiteral) {
      if (expr.value) {
        operations.add(UnlinkedExprOperation.pushTrue);
      } else {
        operations.add(UnlinkedExprOperation.pushFalse);
      }
    } else if (expr is StringLiteral) {
      _serializeString(expr);
    } else if (expr is SymbolLiteral) {
      strings.add(expr.components.map((token) => token.lexeme).join('.'));
      operations.add(UnlinkedExprOperation.makeSymbol);
    } else if (expr is NullLiteral) {
      operations.add(UnlinkedExprOperation.pushNull);
    } else if (expr is Identifier) {
      if (expr is SimpleIdentifier && isParameterName(expr.name)) {
        strings.add(expr.name);
        operations.add(UnlinkedExprOperation.pushParameter);
      } else if (expr is PrefixedIdentifier &&
          isParameterName(expr.prefix.name)) {
        strings.add(expr.prefix.name);
        operations.add(UnlinkedExprOperation.pushParameter);
        strings.add(expr.identifier.name);
        operations.add(UnlinkedExprOperation.extractProperty);
      } else {
        references.add(serializeIdentifier(expr));
        operations.add(UnlinkedExprOperation.pushReference);
      }
    } else if (expr is InstanceCreationExpression) {
      if (!expr.isConst) {
        isValidConst = false;
      }
      TypeName typeName = expr.constructorName.type;
      serializeInstanceCreation(
          serializeConstructorRef(typeName.type, typeName.name,
              typeName.typeArguments, expr.constructorName.name),
          expr.argumentList);
    } else if (expr is ListLiteral) {
      _serializeListLiteral(expr);
    } else if (expr is MapLiteral) {
      _serializeMapLiteral(expr);
    } else if (expr is MethodInvocation) {
      _serializeMethodInvocation(expr);
    } else if (expr is BinaryExpression) {
      _serializeBinaryExpression(expr);
    } else if (expr is ConditionalExpression) {
      _serialize(expr.condition);
      _serialize(expr.thenExpression);
      _serialize(expr.elseExpression);
      operations.add(UnlinkedExprOperation.conditional);
    } else if (expr is PrefixExpression) {
      _serializePrefixExpression(expr);
    } else if (expr is PostfixExpression) {
      _serializePostfixExpression(expr);
    } else if (expr is PropertyAccess) {
      _serializePropertyAccess(expr);
    } else if (expr is ParenthesizedExpression) {
      _serialize(expr.expression);
    } else if (expr is IndexExpression) {
      isValidConst = false;
      _serialize(expr.target);
      _serialize(expr.index);
      operations.add(UnlinkedExprOperation.extractIndex);
    } else if (expr is AssignmentExpression) {
      _serializeAssignment(expr);
    } else if (expr is CascadeExpression) {
      isValidConst = false;
      _serialize(expr.target);
    } else if (expr is FunctionExpression) {
      isValidConst = false;
      List<int> indices = serializeFunctionExpression(expr);
      if (indices != null) {
        ints.addAll(serializeFunctionExpression(expr));
        operations.add(UnlinkedExprOperation.pushLocalFunctionReference);
      } else {
        // Invalid expression; just push null.
        operations.add(UnlinkedExprOperation.pushNull);
      }
    } else if (expr is FunctionExpressionInvocation) {
      isValidConst = false;
      // TODO(scheglov) implement
      operations.add(UnlinkedExprOperation.pushNull);
    } else if (expr is AsExpression) {
      isValidConst = false;
      _serialize(expr.expression);
      references.add(serializeTypeName(expr.type));
      operations.add(UnlinkedExprOperation.typeCast);
    } else if (expr is IsExpression) {
      isValidConst = false;
      _serialize(expr.expression);
      references.add(serializeTypeName(expr.type));
      operations.add(UnlinkedExprOperation.typeCheck);
    } else if (expr is SuperExpression) {
      operations.add(UnlinkedExprOperation.pushSuper);
    } else if (expr is ThisExpression) {
      operations.add(UnlinkedExprOperation.pushThis);
    } else if (expr is ThrowExpression) {
      isValidConst = false;
      _serialize(expr.expression);
      operations.add(UnlinkedExprOperation.throwException);
    } else if (expr is AwaitExpression) {
      isValidConst = false;
      _serialize(expr.expression);
      operations.add(UnlinkedExprOperation.await);
    } else {
      throw new StateError('Unknown expression type: $expr');
    }
  }

  void _serializeArguments(ArgumentList argumentList) {
    if (forConst) {
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
      // Add numbers of named and positional arguments, and the op-code.
      ints.add(argumentNames.length);
      strings.addAll(argumentNames);
      ints.add(arguments.length - argumentNames.length);
    } else {
      ints.add(0);
      ints.add(0);
    }
  }

  void _serializeAssignment(AssignmentExpression expr) {
    isValidConst = false;
    // Push the value.
    _serialize(expr.rightHandSide);
    // Push the assignment operator.
    TokenType operator = expr.operator.type;
    UnlinkedExprAssignOperator assignmentOperator;
    if (operator == TokenType.EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.assign;
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.ifNull;
    } else if (operator == TokenType.STAR_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.multiply;
    } else if (operator == TokenType.SLASH_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.divide;
    } else if (operator == TokenType.TILDE_SLASH_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.floorDivide;
    } else if (operator == TokenType.PERCENT_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.modulo;
    } else if (operator == TokenType.PLUS_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.plus;
    } else if (operator == TokenType.MINUS_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.minus;
    } else if (operator == TokenType.LT_LT_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.shiftLeft;
    } else if (operator == TokenType.GT_GT_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.shiftRight;
    } else if (operator == TokenType.AMPERSAND_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.bitAnd;
    } else if (operator == TokenType.CARET_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.bitXor;
    } else if (operator == TokenType.BAR_EQ) {
      assignmentOperator = UnlinkedExprAssignOperator.bitOr;
    } else {
      throw new StateError('Unknown assignment operator: $operator');
    }
    assignmentOperators.add(assignmentOperator);
    // Push the assignment to the LHS.
    _pushAssignable(expr.leftHandSide);
  }

  void _serializeBinaryExpression(BinaryExpression expr) {
    _serialize(expr.leftOperand);
    _serialize(expr.rightOperand);
    TokenType operator = expr.operator.type;
    if (operator == TokenType.EQ_EQ) {
      operations.add(UnlinkedExprOperation.equal);
    } else if (operator == TokenType.BANG_EQ) {
      operations.add(UnlinkedExprOperation.notEqual);
    } else if (operator == TokenType.AMPERSAND_AMPERSAND) {
      operations.add(UnlinkedExprOperation.and);
    } else if (operator == TokenType.BAR_BAR) {
      operations.add(UnlinkedExprOperation.or);
    } else if (operator == TokenType.CARET) {
      operations.add(UnlinkedExprOperation.bitXor);
    } else if (operator == TokenType.AMPERSAND) {
      operations.add(UnlinkedExprOperation.bitAnd);
    } else if (operator == TokenType.BAR) {
      operations.add(UnlinkedExprOperation.bitOr);
    } else if (operator == TokenType.GT_GT) {
      operations.add(UnlinkedExprOperation.bitShiftRight);
    } else if (operator == TokenType.LT_LT) {
      operations.add(UnlinkedExprOperation.bitShiftLeft);
    } else if (operator == TokenType.PLUS) {
      operations.add(UnlinkedExprOperation.add);
    } else if (operator == TokenType.MINUS) {
      operations.add(UnlinkedExprOperation.subtract);
    } else if (operator == TokenType.STAR) {
      operations.add(UnlinkedExprOperation.multiply);
    } else if (operator == TokenType.SLASH) {
      operations.add(UnlinkedExprOperation.divide);
    } else if (operator == TokenType.TILDE_SLASH) {
      operations.add(UnlinkedExprOperation.floorDivide);
    } else if (operator == TokenType.GT) {
      operations.add(UnlinkedExprOperation.greater);
    } else if (operator == TokenType.LT) {
      operations.add(UnlinkedExprOperation.less);
    } else if (operator == TokenType.GT_EQ) {
      operations.add(UnlinkedExprOperation.greaterEqual);
    } else if (operator == TokenType.LT_EQ) {
      operations.add(UnlinkedExprOperation.lessEqual);
    } else if (operator == TokenType.PERCENT) {
      operations.add(UnlinkedExprOperation.modulo);
    } else if (operator == TokenType.QUESTION_QUESTION) {
      operations.add(UnlinkedExprOperation.ifNull);
    } else {
      throw new StateError('Unknown operator: $operator');
    }
  }

  void _serializeListLiteral(ListLiteral expr) {
    if (forConst || expr.typeArguments == null) {
      List<Expression> elements = expr.elements;
      elements.forEach(_serialize);
      ints.add(elements.length);
    } else {
      ints.add(0);
    }
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 1) {
      references.add(serializeTypeName(expr.typeArguments.arguments[0]));
      operations.add(UnlinkedExprOperation.makeTypedList);
    } else {
      operations.add(UnlinkedExprOperation.makeUntypedList);
    }
  }

  void _serializeMapLiteral(MapLiteral expr) {
    if (forConst || expr.typeArguments == null) {
      for (MapLiteralEntry entry in expr.entries) {
        _serialize(entry.key);
        _serialize(entry.value);
      }
      ints.add(expr.entries.length);
    } else {
      ints.add(0);
    }
    if (expr.typeArguments != null &&
        expr.typeArguments.arguments.length == 2) {
      references.add(serializeTypeName(expr.typeArguments.arguments[0]));
      references.add(serializeTypeName(expr.typeArguments.arguments[1]));
      operations.add(UnlinkedExprOperation.makeTypedMap);
    } else {
      operations.add(UnlinkedExprOperation.makeUntypedMap);
    }
  }

  void _serializeMethodInvocation(MethodInvocation invocation) {
    if (invocation.target != null ||
        invocation.methodName.name != 'identical') {
      isValidConst = false;
    }
    Expression target = invocation.target;
    SimpleIdentifier methodName = invocation.methodName;
    ArgumentList argumentList = invocation.argumentList;
    if (_isIdentifierSequence(methodName)) {
      EntityRefBuilder ref = serializeIdentifierSequence(methodName);
      _serializeArguments(argumentList);
      references.add(ref);
      _serializeTypeArguments(invocation.typeArguments);
      operations.add(UnlinkedExprOperation.invokeMethodRef);
    } else {
      if (!invocation.isCascaded) {
        _serialize(target);
      }
      _serializeArguments(argumentList);
      strings.add(methodName.name);
      _serializeTypeArguments(invocation.typeArguments);
      operations.add(UnlinkedExprOperation.invokeMethod);
    }
  }

  void _serializePostfixExpression(PostfixExpression expr) {
    TokenType operator = expr.operator.type;
    Expression operand = expr.operand;
    if (operator == TokenType.PLUS_PLUS) {
      _serializePrefixPostfixIncDec(
          operand, UnlinkedExprAssignOperator.postfixIncrement);
    } else if (operator == TokenType.MINUS_MINUS) {
      _serializePrefixPostfixIncDec(
          operand, UnlinkedExprAssignOperator.postfixDecrement);
    } else {
      throw new StateError('Unknown operator: $operator');
    }
  }

  void _serializePrefixExpression(PrefixExpression expr) {
    TokenType operator = expr.operator.type;
    Expression operand = expr.operand;
    if (operator == TokenType.BANG) {
      _serialize(operand);
      operations.add(UnlinkedExprOperation.not);
    } else if (operator == TokenType.MINUS) {
      _serialize(operand);
      operations.add(UnlinkedExprOperation.negate);
    } else if (operator == TokenType.TILDE) {
      _serialize(operand);
      operations.add(UnlinkedExprOperation.complement);
    } else if (operator == TokenType.PLUS_PLUS) {
      _serializePrefixPostfixIncDec(
          operand, UnlinkedExprAssignOperator.prefixIncrement);
    } else if (operator == TokenType.MINUS_MINUS) {
      _serializePrefixPostfixIncDec(
          operand, UnlinkedExprAssignOperator.prefixDecrement);
    } else {
      throw new StateError('Unknown operator: $operator');
    }
  }

  void _serializePrefixPostfixIncDec(
      Expression operand, UnlinkedExprAssignOperator operator) {
    isValidConst = false;
    assignmentOperators.add(operator);
    _pushAssignable(operand);
  }

  void _serializePropertyAccess(PropertyAccess expr) {
    if (_isIdentifierSequence(expr)) {
      EntityRefBuilder ref = serializeIdentifierSequence(expr);
      references.add(ref);
      operations.add(UnlinkedExprOperation.pushReference);
    } else {
      if (!expr.isCascaded) {
        _serialize(expr.target);
      }
      strings.add(expr.propertyName.name);
      operations.add(UnlinkedExprOperation.extractProperty);
    }
  }

  void _serializeString(StringLiteral expr) {
    if (expr is AdjacentStrings) {
      if (expr.strings.every((string) => string is SimpleStringLiteral)) {
        operations.add(UnlinkedExprOperation.pushString);
        strings.add(expr.stringValue);
      } else {
        expr.strings.forEach(_serializeString);
        operations.add(UnlinkedExprOperation.concatenate);
        ints.add(expr.strings.length);
      }
    } else if (expr is SimpleStringLiteral) {
      operations.add(UnlinkedExprOperation.pushString);
      strings.add(expr.value);
    } else {
      StringInterpolation interpolation = expr as StringInterpolation;
      for (InterpolationElement element in interpolation.elements) {
        if (element is InterpolationString) {
          operations.add(UnlinkedExprOperation.pushString);
          strings.add(element.value);
        } else {
          _serialize((element as InterpolationExpression).expression);
        }
      }
      operations.add(UnlinkedExprOperation.concatenate);
      ints.add(interpolation.elements.length);
    }
  }

  void _serializeTypeArguments(TypeArgumentList typeArguments) {
    if (typeArguments == null) {
      ints.add(0);
    } else {
      ints.add(typeArguments.arguments.length);
      for (TypeAnnotation type in typeArguments.arguments) {
        references.add(serializeTypeName(type));
      }
    }
  }
}
