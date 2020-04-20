// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [ForStatement]s and [ForElement]s.
class ForResolver {
  final ResolverVisitor _resolver;
  final FlowAnalysisHelper _flowAnalysis;

  ForResolver({
    @required ResolverVisitor resolver,
    @required FlowAnalysisHelper flowAnalysis,
  })  : _resolver = resolver,
        _flowAnalysis = flowAnalysis;

  void resolveElement(ForElementImpl node) {
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      _forParts(node, forLoopParts, node.body);
    } else if (forLoopParts is ForEachParts) {
      _forEachParts(node, node.awaitKeyword != null, forLoopParts, node.body);
    }
  }

  void resolveStatement(ForStatementImpl node) {
    _flowAnalysis?.checkUnreachableNode(node);

    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      _forParts(node, forLoopParts, node.body);
    } else if (forLoopParts is ForEachParts) {
      _forEachParts(node, node.awaitKeyword != null, forLoopParts, node.body);
    }
  }

  /// Given an iterable expression from a foreach loop, attempt to infer
  /// a type for the elements being iterated over.  Inference is based
  /// on the type of the iterator or stream over which the foreach loop
  /// is defined.
  DartType _computeForEachElementType(Expression iterable, bool isAsync) {
    DartType iterableType = iterable.staticType;
    if (iterableType == null) return null;
    iterableType =
        iterableType.resolveToBound(_resolver.typeProvider.objectType);

    ClassElement iteratedElement = isAsync
        ? _resolver.typeProvider.streamElement
        : _resolver.typeProvider.iterableElement;

    InterfaceType iteratedType = iterableType is InterfaceTypeImpl
        ? iterableType.asInstanceOf(iteratedElement)
        : null;

    if (iteratedType != null) {
      return iteratedType.typeArguments.single;
    } else {
      return null;
    }
  }

  void _forEachParts(
    AstNode node,
    bool isAsync,
    ForEachParts forEachParts,
    AstNode body,
  ) {
    Expression iterable = forEachParts.iterable;
    DeclaredIdentifier loopVariable;
    SimpleIdentifier identifier;
    Element identifierElement;
    if (forEachParts is ForEachPartsWithDeclaration) {
      loopVariable = forEachParts.loopVariable;
    } else if (forEachParts is ForEachPartsWithIdentifier) {
      identifier = forEachParts.identifier;
      identifier?.accept(_resolver);
    }

    DartType valueType;
    if (loopVariable != null) {
      TypeAnnotation typeAnnotation = loopVariable.type;
      valueType = typeAnnotation?.type ?? UnknownInferredType.instance;
    }
    if (identifier != null) {
      identifierElement = identifier.staticElement;
      if (identifierElement is VariableElement) {
        valueType = identifierElement.type;
      } else if (identifierElement is PropertyAccessorElement) {
        var parameters = identifierElement.parameters;
        if (parameters.isNotEmpty) {
          valueType = parameters[0].type;
        }
      }
    }
    if (valueType != null) {
      InterfaceType targetType = isAsync
          ? _resolver.typeProvider.streamType2(valueType)
          : _resolver.typeProvider.iterableType2(valueType);
      InferenceContext.setType(iterable, targetType);
    }

    iterable?.accept(_resolver);
    iterable = forEachParts.iterable;

    _resolver.nullableDereferenceVerifier.expression(iterable);

    loopVariable?.accept(_resolver);
    var elementType = _computeForEachElementType(iterable, isAsync);
    if (loopVariable != null &&
        elementType != null &&
        loopVariable.type == null) {
      var loopVariableElement =
          loopVariable.declaredElement as LocalVariableElementImpl;
      loopVariableElement.type = elementType;
    }

    if (loopVariable != null) {
      _flowAnalysis?.flow?.declare(loopVariable.declaredElement, true);
    }

    _flowAnalysis?.flow?.forEach_bodyBegin(
      node,
      identifierElement is VariableElement
          ? identifierElement
          : loopVariable?.declaredElement,
      elementType ?? DynamicTypeImpl.instance,
    );

    _resolveBody(body);

    _flowAnalysis?.flow?.forEach_end();
  }

  void _forParts(AstNode node, ForParts forParts, AstNode body) {
    if (forParts is ForPartsWithDeclarations) {
      forParts.variables?.accept(_resolver);
    } else if (forParts is ForPartsWithExpression) {
      forParts.initialization?.accept(_resolver);
    }

    _flowAnalysis?.for_conditionBegin(node);

    var condition = forParts.condition;
    if (condition != null) {
      InferenceContext.setType(condition, _resolver.typeProvider.boolType);
      condition.accept(_resolver);
      condition = forParts.condition;
      _resolver.boolExpressionVerifier.checkForNonBoolCondition(condition);
    }

    _flowAnalysis?.for_bodyBegin(node, condition);
    _resolveBody(body);

    _flowAnalysis?.flow?.for_updaterBegin();
    forParts.updaters.accept(_resolver);

    _flowAnalysis?.flow?.for_end();
  }

  void _resolveBody(AstNode body) {
    if (body is Statement) {
      _resolver.visitStatementInScope(body);
    } else {
      body.accept(_resolver);
    }
  }
}
