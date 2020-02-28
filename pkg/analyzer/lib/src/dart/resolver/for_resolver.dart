// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
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
    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(_resolver);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(_resolver);
      }

      var condition = forLoopParts.condition;

      _flowAnalysis?.for_conditionBegin(node);
      if (condition != null) {
        InferenceContext.setType(condition, _resolver.typeProvider.boolType);
        condition.accept(_resolver);
        condition = forLoopParts.condition;
        _resolver.boolExpressionVerifier.checkForNonBoolCondition(condition);
      }

      _flowAnalysis?.for_bodyBegin(node, condition);
      node.body?.accept(_resolver);

      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(_resolver);

      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      DartType valueType;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
        valueType = loopVariable?.type?.type ?? UnknownInferredType.instance;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        SimpleIdentifier identifier = forLoopParts.identifier;
        identifier?.accept(_resolver);
        identifierElement = identifier?.staticElement;
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
        InterfaceType targetType = (node.awaitKeyword == null)
            ? _resolver.typeProvider.iterableType2(valueType)
            : _resolver.typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop
      // variable cannot be in scope while visiting the iterator.
      //
      iterable?.accept(_resolver);
      // Note: the iterable could have been rewritten so grab it from
      // forLoopParts again.
      iterable = forLoopParts.iterable;
      loopVariable?.accept(_resolver);
      var elementType =
          _computeForEachElementType(iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }
      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable?.declaredElement,
          elementType ?? DynamicTypeImpl.instance);
      node.body?.accept(_resolver);
      _flowAnalysis?.flow?.forEach_end();
    }
  }

  void resolveStatement(ForStatementImpl node) {
    _flowAnalysis?.checkUnreachableNode(node);

    ForLoopParts forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(_resolver);
      } else if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(_resolver);
      }

      var condition = forLoopParts.condition;

      _flowAnalysis?.for_conditionBegin(node);
      if (condition != null) {
        InferenceContext.setType(condition, _resolver.typeProvider.boolType);
        condition.accept(_resolver);
        condition = forLoopParts.condition;
        _resolver.boolExpressionVerifier.checkForNonBoolCondition(condition);
      }

      _flowAnalysis?.for_bodyBegin(node, condition);
      _resolver.visitStatementInScope(node.body);

      _flowAnalysis?.flow?.for_updaterBegin();
      forLoopParts.updaters.accept(_resolver);

      _flowAnalysis?.flow?.for_end();
    } else if (forLoopParts is ForEachParts) {
      Expression iterable = forLoopParts.iterable;
      DeclaredIdentifier loopVariable;
      SimpleIdentifier identifier;
      Element identifierElement;
      if (forLoopParts is ForEachPartsWithDeclaration) {
        loopVariable = forLoopParts.loopVariable;
      } else if (forLoopParts is ForEachPartsWithIdentifier) {
        identifier = forLoopParts.identifier;
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
        InterfaceType targetType = (node.awaitKeyword == null)
            ? _resolver.typeProvider.iterableType2(valueType)
            : _resolver.typeProvider.streamType2(valueType);
        InferenceContext.setType(iterable, targetType);
      }
      //
      // We visit the iterator before the loop variable because the loop variable
      // cannot be in scope while visiting the iterator.
      //
      iterable?.accept(_resolver);
      // Note: the iterable could have been rewritten so grab it again.
      iterable = forLoopParts.iterable;

      _resolver.nullableDereferenceVerifier.expression(iterable);

      loopVariable?.accept(_resolver);
      var elementType =
          _computeForEachElementType(iterable, node.awaitKeyword != null);
      if (loopVariable != null &&
          elementType != null &&
          loopVariable.type == null) {
        var loopVariableElement =
            loopVariable.declaredElement as LocalVariableElementImpl;
        loopVariableElement.type = elementType;
      }

      _flowAnalysis?.flow?.forEach_bodyBegin(
          node,
          identifierElement is VariableElement
              ? identifierElement
              : loopVariable?.declaredElement,
          elementType ?? DynamicTypeImpl.instance);

      Statement body = node.body;
      if (body != null) {
        _resolver.visitStatementInScope(body);
      }

      _flowAnalysis?.flow?.forEach_end();
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
}
