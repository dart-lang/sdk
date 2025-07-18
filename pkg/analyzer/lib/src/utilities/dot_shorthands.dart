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
    argumentList: ArgumentList(:var arguments),
  )) {
    // When the static type of the method invocation is a generic function type
    // with no explicit type arguments given, we will be inferring those types.
    var typeParameters = staticType.typeParameters;
    if (typeParameters.isEmpty) return false;

    // The type parameters that are dependent on type inference are in the
    // return type. We populate those type parameters.
    //
    // As an optimization, we filter the type parameters to only include the
    // type parameters declared on the method invocation.
    var returnType = staticType.returnType;
    var dependentTypeParameters = _findTypeParametersForType(
      returnType,
    ).where((element) => typeParameters.contains(element));
    if (dependentTypeParameters.isEmpty) return false;

    // Then looking at every argument in the method invocation, we recursively
    // check the arguments of parameters that have type parameters that are in
    // the set of dependent type parameters that we calculated above.
    for (var argument in arguments) {
      var parameterTypeParameters = _findTypeParametersForFormalParameter(
        argument.correspondingParameter,
      );
      if (parameterTypeParameters.isEmpty) continue;

      if (parameterTypeParameters.any(
        (type) => dependentTypeParameters.contains(type),
      )) {
        if (hasDependentDotShorthand(argument)) return true;
      }
    }
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
  } else if (node case InstanceCreationExpressionImpl(
    constructorName: ConstructorName(:var type),
    :var argumentList,
  )) {
    // Type arguments to the constructor are explicitly given. We know that no
    // inference information is required from any parent declared types.
    if (type.typeArguments != null) return false;

    for (var argument in argumentList.arguments) {
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

class _TypeParameterVisitor extends RecursiveTypeVisitor {
  Set<TypeParameterElement> typeParameters = {};

  _TypeParameterVisitor() : super(includeTypeAliasArguments: false);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    typeParameters.add(type.element);
    return true;
  }
}
