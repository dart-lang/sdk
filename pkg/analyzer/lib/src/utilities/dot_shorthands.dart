// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
bool hasDependentDotShorthand(AstNode node) {
  if (node case DotShorthandMixin(
    isDotShorthand: true,
    :var correspondingParameter,
  )) {
    // There's no corresponding parameter, so we rely on the type provided by
    // the for-loop or variable declaration.
    if (correspondingParameter == null) return true;

    // The type used to infer the dot shorthand is a type parameter. We need
    // to avoid reporting a lint here.
    if (correspondingParameter.baseElement.type is TypeParameterType) {
      return true;
    }
  } else if (node case MethodInvocation(
    methodName: SimpleIdentifier(:FunctionType staticType),
    typeArguments: null,
    argumentList: ArgumentList(:var arguments2),
  )) {
    return _invocationHasDependentDotShorthand(staticType, arguments2);
  } else if (node case NamedFunctionInvocation(
    :var resolution,
    typeArguments: null,
    argumentList: ArgumentList(:var arguments2),
  )) {
    var staticType = switch (resolution) {
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
    if (staticType is FunctionType) {
      return _invocationHasDependentDotShorthand(staticType, arguments2);
    }
  } else if (node
      case ListLiteral(typeArguments: null, :var elements2) ||
          SetOrMapLiteral(typeArguments: null, :var elements2)) {
    // Lists, maps, and sets that have inferred type arguments need their
    // elements verified for dot shorthands that depend on that type inference.
    for (var element in elements2) {
      if (element is MapLiteralEntry) {
        if (hasDependentDotShorthand(element.key2) ||
            hasDependentDotShorthand(element.value2)) {
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
      case ExpressionFunctionBody(:var expression2):
        return hasDependentDotShorthand(expression2);
      case BlockFunctionBody(block: Block(:var statements)):
        for (var statement in statements) {
          if (statement is ReturnStatement) {
            var expression = statement.expression2;
            if (expression != null && hasDependentDotShorthand(expression)) {
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

    for (var argument in argumentList.arguments2) {
      var parameterTypeParameters = _findTypeParametersForFormalParameter(
        argument.correspondingParameter,
      );
      if (parameterTypeParameters.isEmpty) continue;
      if (hasDependentDotShorthand(argument)) return true;
    }
  }
  return false;
}

/// Whether the [node] is a dot shorthand expression that relies on a context
/// type.
bool isDotShorthand(AstNode node) =>
    node is DotShorthandMixin && node.isDotShorthand;

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

class _TypeParameterVisitor extends RecursiveTypeVisitor {
  Set<TypeParameterElement> typeParameters = {};

  _TypeParameterVisitor() : super(includeTypeAliasArguments: false);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    typeParameters.add(type.element);
    return true;
  }
}
