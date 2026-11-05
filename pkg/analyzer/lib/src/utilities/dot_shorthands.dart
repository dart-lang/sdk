// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';

/// Whether the expression is a dot shorthand or has a dot shorthand in its
/// arguments that relies on type inference.
///
/// Note: Use [isDotShorthand] for determining whether the general [node] is a
/// dot shorthand. For this helper, [node] should be a for-loop iterable or a
/// variable initializer that we're attempting to remove a declared type for.
///
/// Example of fixes that use this helper are extract local refactoring and
/// `omit_local_variable_types`.
@ToBeDeprecated('Use hasDependentDotShorthand2 instead.')
bool hasDependentDotShorthand(AstNode node) {
  if (node is Expression && isDotShorthand(node)) {
    return _isDependentDotShorthand(node);
  } else if (node case MethodInvocation(
    methodName: SimpleIdentifier(:FunctionType staticType),
    typeArguments: null,
    :var argumentList,
  )) {
    return _invocationHasDependentDotShorthand(
      staticType,
      argumentList.arguments,
      hasDependentDotShorthand,
    );
  } else if (node
      case ListLiteral(typeArguments: null, :var elements) ||
          SetOrMapLiteral(typeArguments: null, :var elements)) {
    // Lists, maps, and sets that have inferred type arguments need their
    // elements verified for dot shorthands that depend on that type inference.
    for (var element in elements) {
      if (element is MapLiteralEntry) {
        if (hasDependentDotShorthand(element.key) ||
            hasDependentDotShorthand(element.value)) {
          return true;
        }
      } else if (hasDependentDotShorthand(element)) {
        return true;
      }
    }
  } else if (node case FunctionExpression(:var body)) {
    // Check if the return statement(s) of the function expression have a
    // dependent dot shorthand.
    switch (body) {
      case ExpressionFunctionBody(:var expression):
        return hasDependentDotShorthand(expression);
      case BlockFunctionBody(block: Block(:var statements)):
        for (var statement in statements) {
          if (statement is ReturnStatement) {
            var expression = statement.expression;
            if (expression != null && hasDependentDotShorthand(expression)) {
              return true;
            }
          }
        }
      default:
        return false;
    }
  } else if (node case InstanceCreationExpression(
    constructorName: ConstructorName(:var type),
    :var argumentList,
  )) {
    // Type arguments to the constructor are explicitly given. We know that no
    // inference information is required from any parent declared types.
    if (type.typeArguments != null) return false;
    return _constructorArgumentsHaveDependentDotShorthand(
      argumentList.arguments,
      hasDependentDotShorthand,
    );
  }
  return false;
}

/// Whether the expression is a dot shorthand or has a dot shorthand in its
/// arguments that relies on type inference.
///
/// Note: Use [isDotShorthand2] for determining whether the general [node] is a
/// dot shorthand. For this helper, [node] should be a for-loop iterable or a
/// variable initializer that we're attempting to remove a declared type for.
///
/// Example of fixes that use this helper are extract local refactoring and
/// `omit_local_variable_types`.
bool hasDependentDotShorthand2(AstNode node) {
  if (node is Expression && isDotShorthand2(node)) {
    return _isDependentDotShorthand(node);
  } else if (node case NamedFunctionInvocation(
    typeArguments: null,
    :var argumentList,
  )) {
    if (_namedFunctionInvocationType(node) case var staticType?) {
      return _invocationHasDependentDotShorthand(
        staticType,
        argumentList.arguments2,
        hasDependentDotShorthand2,
      );
    }
  } else if (node
      case ListLiteral(typeArguments: null, :var elements2) ||
          SetOrMapLiteral(typeArguments: null, :var elements2)) {
    // Lists, maps, and sets that have inferred type arguments need their
    // elements verified for dot shorthands that depend on that type inference.
    for (var element in elements2) {
      if (element is MapLiteralEntry) {
        if (hasDependentDotShorthand2(element.key2) ||
            hasDependentDotShorthand2(element.value2)) {
          return true;
        }
      } else if (hasDependentDotShorthand2(element)) {
        return true;
      }
    }
  } else if (node case FunctionExpression(:var body)) {
    // Check if the return statement(s) of the function expression have a
    // dependent dot shorthand.
    switch (body) {
      case ExpressionFunctionBody(:var expression2):
        return hasDependentDotShorthand2(expression2);
      case BlockFunctionBody(block: Block(:var statements)):
        for (var statement in statements) {
          if (statement is ReturnStatement) {
            var expression = statement.expression2;
            if (expression != null && hasDependentDotShorthand2(expression)) {
              return true;
            }
          }
        }
      default:
        return false;
    }
  } else if (node case ConstructorInvocationImpl(
    constructorReference: ConstructorReference2(typeReference: var type),
    :var argumentList,
  )) {
    // Type arguments to the constructor are explicitly given. We know that no
    // inference information is required from any parent declared types.
    if (type.typeArguments != null) return false;
    return _constructorArgumentsHaveDependentDotShorthand(
      argumentList.arguments2,
      hasDependentDotShorthand2,
    );
  }
  return false;
}

/// Whether [node] is a complete dot-shorthand selector chain.
///
/// Only receiver and operand edges continue the chain. Parentheses, arguments,
/// index operands, and cascade sections do not. The leading shorthand operation
/// and intermediate selectors are not complete chains when another selector
/// follows them.
@ToBeDeprecated('Use isDotShorthand2 instead.')
bool isDotShorthand(AstNode node) {
  if (identical(_selectorOperand(node.parent), node)) {
    return false;
  }
  AstNode? current = node;
  while (current != null) {
    switch (current) {
      case DotShorthandConstructorInvocation():
      case DotShorthandInvocation():
      case DotShorthandPropertyAccess():
        return true;
    }
    current = _selectorOperand(current);
  }
  return false;
}

/// Whether [node] is a complete dot-shorthand selector chain.
///
/// Only receiver and operand edges continue the chain. Parentheses, arguments,
/// index operands, and cascade sections do not. The leading shorthand operation
/// and intermediate selectors are not complete chains when another selector
/// follows them.
bool isDotShorthand2(AstNode node) {
  if (identical(_selectorOperand2(node.parent2), node)) {
    return false;
  }
  AstNode? current = node;
  while (current != null) {
    switch (current) {
      case ParsedDotShorthandExpression():
      case DotShorthandExpression():
        return true;
    }
    current = _selectorOperand2(current);
  }
  return false;
}

/// Whether any of [arguments] of a constructor invocation, which has no
/// explicit type arguments, has a dot shorthand that relies on inferring them.
bool _constructorArgumentsHaveDependentDotShorthand(
  Iterable<Argument> arguments,
  bool Function(AstNode) hasDependentDotShorthand,
) {
  for (var argument in arguments) {
    var parameterTypeParameters = _findTypeParametersForFormalParameter(
      argument.correspondingParameter,
    );
    if (parameterTypeParameters.isEmpty) continue;
    if (hasDependentDotShorthand(argument)) return true;
  }
  return false;
}

/// Finds and returns all the type parameter elements in the formal parameter,
/// [parameter].
Set<TypeParameterElement> _findTypeParametersForFormalParameter(
  FormalParameterElement? parameter,
) {
  if (parameter == null) return {};
  return _findTypeParametersForType(parameter.baseElement.type);
}

/// Finds and returns all the type parameter elements in [type].
Set<TypeParameterElement> _findTypeParametersForType(DartType type) {
  var typeParameterVisitor = _TypeParameterVisitor();
  type.accept(typeParameterVisitor);
  return typeParameterVisitor.typeParameters;
}

bool _invocationHasDependentDotShorthand(
  FunctionType staticType,
  Iterable<Argument> arguments,
  bool Function(AstNode) hasDependentDotShorthand,
) {
  // When the static type of the invocation is a generic function type with no
  // explicit type arguments, its type arguments are inferred.
  var typeParameters = staticType.typeParameters;
  if (typeParameters.isEmpty) return false;

  // Only type parameters used by the return type can make the invocation's
  // context affect an argument.
  var dependentTypeParameters = _findTypeParametersForType(
    staticType.returnType,
  ).where(typeParameters.contains);
  if (dependentTypeParameters.isEmpty) return false;

  for (var argument in arguments) {
    var parameterTypeParameters = _findTypeParametersForFormalParameter(
      argument.correspondingParameter,
    );
    if (parameterTypeParameters.any(dependentTypeParameters.contains) &&
        hasDependentDotShorthand(argument)) {
      return true;
    }
  }
  return false;
}

/// Whether the dot shorthand [node] relies on the type provided by the
/// enclosing for-loop or variable declaration.
bool _isDependentDotShorthand(Expression node) {
  var correspondingParameter = node.correspondingParameter;
  // There's no corresponding parameter, so we rely on the type provided by
  // the for-loop or variable declaration.
  if (correspondingParameter == null) return true;

  // The type used to infer the dot shorthand is a type parameter. We need
  // to avoid reporting a lint here.
  return correspondingParameter.baseElement.type is TypeParameterType;
}

/// The function type of the invoked function, or `null` if it is not known.
FunctionType? _namedFunctionInvocationType(NamedFunctionInvocation node) {
  var type = switch (node.resolution) {
    ExecutableInvocationResolution(:var element) => element.type,
    InvalidInvocationResolution(
      recovery: ExecutableInvocationResolution(:var element),
    ) =>
      element.type,
    FunctionCallInvocationResolution(:var invokeType) => invokeType,
    InvalidInvocationResolution(
      recovery: FunctionCallInvocationResolution(:var invokeType),
    ) =>
      invokeType,
    _ => null,
  };
  return type is FunctionType ? type : null;
}

/// The preceding expression in a written selector chain. Implicit adaptations
/// retain the same source expression and are transparent to this query.
@ToBeDeprecated('Use _selectorOperand2 instead.')
AstNode? _selectorOperand(AstNode? node) => switch (node) {
  MethodInvocation(:var target) => target,
  PropertyAccess(:var target) => target,
  IndexExpression(:var target) => target,
  FunctionExpressionInvocation(:var function) => function,
  FunctionReference(:var function) => function,
  ImplicitCallReference(:var expression) => expression,
  AnonymousMethodInvocation(:var target) => target,
  PostfixExpression(:var operand, :var operator)
      when operator.type == TokenType.BANG =>
    operand,
  _ => null,
};

/// The preceding expression in a written selector chain. Implicit adaptations
/// retain the same source expression and are transparent to this query.
AstNode? _selectorOperand2(AstNode? node) => switch (node) {
  ReceiverMethodInvocation(:var receiver) => receiver,
  ReceiverPropertyExtraction(:var receiver) => receiver,
  ReceiverIndexExpression(:var receiver) => receiver,
  CallInvocation(:var receiver) => receiver,
  FunctionInstantiation(:var operand) => operand,
  NullAssertionExpression(:var operand) => operand,
  ImplicitCallTearOff(:var operand) => operand,
  ImplicitFunctionInstantiation(:var operand) => operand,
  AnonymousMethodInvocation(:var target2) => target2,
  _ => null,
};

class _TypeParameterVisitor extends RecursiveTypeVisitor {
  Set<TypeParameterElement> typeParameters = {};

  _TypeParameterVisitor() : super(includeTypeAliasArguments: false);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    typeParameters.add(type.element);
    return true;
  }
}
