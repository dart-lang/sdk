// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

class ConstraintVariableGatherer extends GeneralizingAstVisitor<DecoratedType> {
  final Variables _variables;

  DecoratedType _currentFunctionType;

  ConstraintVariableGatherer(this._variables);

  DecoratedType decorateType(TypeAnnotation type) {
    return type == null
        // TODO(danrubel): Return something other than this
        // to indicate that we should insert a type for the declaration
        // that is missing a type reference.
        ? new DecoratedType(DynamicTypeImpl.instance, ConstraintVariable.always)
        : type.accept(this);
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    return null;
  }

  @override
  DecoratedType visitFormalParameter(FormalParameter node) {
    // Do not visit children
    // TODO(paulberry): handle all types of formal parameters
    // - NormalFormalParameter
    // - SimpleFormalParameter
    // - FieldFormalParameter
    // - FunctionTypedFormalParameter
    // - DefaultFormalParameter
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    _handleExecutableDeclaration(node.declaredElement, node.returnType,
        node.functionExpression.parameters);
    return null;
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(
        node.declaredElement, node.returnType, node.parameters);
    return null;
  }

  @override
  DecoratedType visitSimpleFormalParameter(SimpleFormalParameter node) {
    var type = decorateType(node.type);
    _variables.recordDecoratedElementType(node.declaredElement, type);
    assert(!node.declaredElement.isNamed); // TODO(paulberry)
    _currentFunctionType.positionalParameters.add(type);
    return null;
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    assert(node != null); // TODO(paulberry)
    assert(node is NamedType); // TODO(paulberry)
    var type = node.type;
    if (type.isVoid) return DecoratedType(type, ConstraintVariable.always);
    assert(
        type is InterfaceType || type is TypeParameterType); // TODO(paulberry)
    var typeArguments = const <DecoratedType>[];
    if (type is InterfaceType && type.typeParameters.isNotEmpty) {
      if (node is TypeName) {
        assert(node.typeArguments != null);
        typeArguments =
            node.typeArguments.arguments.map((t) => t.accept(this)).toList();
      } else {
        assert(false); // TODO(paulberry): is this possible?
      }
    }
    var nullable = node.question == null
        ? _variables.nullableForTypeAnnotation(node)
        : ConstraintVariable.always;
    // TODO(paulberry): decide whether to assign a variable for nullAsserts
    var nullAsserts = null;
    var decoratedType = DecoratedType(type, nullable,
        nullAsserts: nullAsserts, typeArguments: typeArguments);
    _variables.recordDecoratedTypeAnnotation(node, decoratedType);
    return decoratedType;
  }

  @override
  DecoratedType visitTypeName(TypeName node) => visitTypeAnnotation(node);

  void _handleExecutableDeclaration(ExecutableElement declaredElement,
      TypeAnnotation returnType, FormalParameterList parameters) {
    var decoratedReturnType = decorateType(returnType);
    var previousFunctionType = _currentFunctionType;
    // TODO(paulberry): test that it's correct to use `null` for the nullability
    // of the function type
    var functionType = DecoratedType(declaredElement.type, null,
        returnType: decoratedReturnType, positionalParameters: []);
    _currentFunctionType = functionType;
    parameters.accept(this);
    _currentFunctionType = previousFunctionType;
    _variables.recordDecoratedElementType(declaredElement, functionType);
  }
}

abstract class Variables {
  ConstraintVariable checkNotNullForExpression(Expression expression);

  DecoratedType decoratedElementType(Element element);

  ConstraintVariable nullableForExpression(Expression expression);

  ConstraintVariable nullableForTypeAnnotation(TypeAnnotation node);

  void recordConditionalDiscard(
      AstNode node, ConditionalDiscard conditionalDiscard);

  void recordDecoratedElementType(Element element, DecoratedType type);

  void recordDecoratedExpressionType(Expression node, DecoratedType type);

  void recordDecoratedTypeAnnotation(TypeAnnotation node, DecoratedType type);

  void recordExpressionChecks(Expression expression, ExpressionChecks checks);
}
