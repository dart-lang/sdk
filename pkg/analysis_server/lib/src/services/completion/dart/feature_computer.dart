// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to compute the value of the features used for code
/// completion.
import 'dart:math' as math;

import 'package:analysis_server/src/protocol_server.dart'
    show ElementKind, convertElementToElementKind;
import 'package:analysis_server/src/services/completion/dart/relevance_tables.g.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, Element, FieldElement, LibraryElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';

/// Convert a relevance score (assumed to be between `0.0` and `1.0` inclusive)
/// to a relevance value between `0` and `1000`. If the score is outside that
/// range, return the [defaultValue].
int toRelevance(double score, int defaultValue) {
  if (score < 0.0 || score > 1.0) {
    return defaultValue;
  }
  return (score * 1000).truncate();
}

/// Return the weighted average of the given [values], applying the given
/// [weights]. The number of weights must be equal to the number of values.
/// Values less than `0.0` are ignored. If there are no non-negative values then
/// a negative value will be returned.
double weightedAverage(List<double> values, List<double> weights) {
  assert(values.length == weights.length);
  var totalValue = 0.0;
  var totalWeight = 0.0;
  for (var i = 0; i < values.length; i++) {
    var value = values[i];
    if (value >= 0.0) {
      var weight = weights[i];
      totalValue += value * weight;
      totalWeight += weight;
    }
  }
  if (totalWeight == 0.0) {
    return -1.0;
  }
  return totalValue / totalWeight;
}

/// An object that computes the values of features.
class FeatureComputer {
  /// The type system used to perform operations on types.
  final TypeSystem typeSystem;

  /// The type provider used to access types defined by the spec.
  final TypeProvider typeProvider;

  /// Initialize a newly created feature computer.
  FeatureComputer(this.typeSystem, this.typeProvider);

  /// Return the type imposed on the given [node] based on its context, or
  /// `null` if the context does not impose any type.
  DartType computeContextType(AstNode node) {
    var type = node.parent?.accept(_ContextTypeVisitor(typeProvider, node));
    if (type == null || type.isDynamic) {
      return null;
    }
    return type;
  }

  /// Return the value of the _context type_ feature for an element with the
  /// given [elementType] when completing in a location with the given
  /// [contextType].
  double contextTypeFeature(DartType contextType, DartType elementType) {
    if (contextType == null || elementType == null) {
      // Disable the feature if we don't have both types.
      return -1.0;
    }
    if (elementType == contextType) {
      // Exact match.
      return 1.0;
    } else if (typeSystem.isSubtypeOf(elementType, contextType)) {
      // Subtype.
      return 0.40;
    } else if (typeSystem.isSubtypeOf(contextType, elementType)) {
      // Supertype.
      return 0.02;
    } else {
      // Unrelated.
      return 0.13;
    }
  }

  /// Return the value of the _element kind_ feature for the [element] when
  /// completing at the given [completionLocation]. If a [distance] is given it
  /// will be used to provide finer-grained relevance scores.
  double elementKindFeature(Element element, String completionLocation,
      {int distance}) {
    if (completionLocation == null) {
      return -1.0;
    }
    var locationTable = elementKindRelevance[completionLocation];
    if (locationTable == null) {
      return -1.0;
    }
    ElementKind kind;
    if (element is LibraryElement) {
      kind = ElementKind.PREFIX;
    } else {
      kind = convertElementToElementKind(element);
    }
    var range = locationTable[kind];
    if (range == null) {
      return 0.0;
    }
    if (distance == null) {
      return range.upper;
    }
    return range.conditionalProbability(_distanceToPercent(distance));
  }

  /// Return the value of the _has deprecated_ feature for the given [element].
  double hasDeprecatedFeature(Element element) {
    return element.hasOrInheritsDeprecated ? 0.0 : 1.0;
  }

  /// Return the inheritance distance between the [subclass] and the
  /// [superclass]. We define the inheritance distance between two types to be
  /// zero if the two types are the same and the minimum number of edges that
  /// must be traversed in the type graph to get from the subtype to the
  /// supertype if the two types are not the same. Return `-1` if the [subclass]
  /// is not a subclass of the [superclass].
  int inheritanceDistance(ClassElement subclass, ClassElement superclass) {
    // This method is only visible for the metrics computation and might be made
    // private at some future date.
    return _inheritanceDistance(subclass, superclass, {});
  }

  /// Return the value of the _inheritance distance_ feature for a member
  /// defined in the [superclass] that is being accessed through an expression
  /// whose static type is the [subclass].
  double inheritanceDistanceFeature(
      ClassElement subclass, ClassElement superclass) {
    var distance = _inheritanceDistance(subclass, superclass, {});
    if (distance < 0) {
      return 0.0;
    }
    return _distanceToPercent(distance);
  }

  /// Return the value of the _starts with dollar_ feature.
  double startsWithDollarFeature(String name) =>
      name.startsWith('\$') ? 0.0 : 1.0;

  /// Return the value of the _super matches_ feature.
  double superMatchesFeature(
          String containingMethodName, String proposedMemberName) =>
      containingMethodName == null
          ? -1.0
          : (proposedMemberName == containingMethodName ? 1.0 : 0.0);

  /// Convert a [distance] to a percentage value and return the percentage.
  double _distanceToPercent(int distance) => math.pow(0.95, distance);

  /// Return the inheritance distance between the [subclass] and the
  /// [superclass]. The set of [visited] elements is used to guard against
  /// cycles in the type graph.
  ///
  /// This is the implementation of [inheritanceDistance].
  int _inheritanceDistance(ClassElement subclass, ClassElement superclass,
      Set<ClassElement> visited) {
    if (subclass == null) {
      return -1;
    } else if (subclass == superclass) {
      return 0;
    } else if (!visited.add(subclass)) {
      return -1;
    }
    var minDepth =
        _inheritanceDistance(subclass.supertype?.element, superclass, visited);

    void visitTypes(List<InterfaceType> types) {
      for (var type in types) {
        var depth = _inheritanceDistance(type.element, superclass, visited);
        if (minDepth < 0 || (depth >= 0 && depth < minDepth)) {
          minDepth = depth;
        }
      }
    }

    visitTypes(subclass.superclassConstraints);
    visitTypes(subclass.mixins);
    visitTypes(subclass.interfaces);

    visited.remove(subclass);
    if (minDepth < 0) {
      return minDepth;
    }
    return minDepth + 1;
  }
}

/// An visitor used to compute the required type of an expression or identifier
/// based on its context. The visitor should be initialized with the node whose
/// context type is to be computed and the parent of that node should be
/// visited.
class _ContextTypeVisitor extends SimpleAstVisitor<DartType> {
  final TypeProvider typeProvider;

  AstNode childNode;

  _ContextTypeVisitor(this.typeProvider, this.childNode);

  @override
  DartType visitAdjacentStrings(AdjacentStrings node) {
    if (childNode == node.strings[0]) {
      return _visitParent(node);
    }
    return typeProvider.stringType;
  }

  @override
  DartType visitArgumentList(ArgumentList node) {
    return (childNode as Expression).staticParameterElement?.type;
  }

  @override
  DartType visitAssertInitializer(AssertInitializer node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitAssertStatement(AssertStatement node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitAssignmentExpression(AssignmentExpression node) {
    if (childNode == node.rightHandSide) {
      return node.leftHandSide.staticType;
    }
    return null;
  }

  @override
  DartType visitAwaitExpression(AwaitExpression node) {
    return _visitParent(node);
  }

  @override
  DartType visitBinaryExpression(BinaryExpression node) {
    if (childNode == node.rightOperand) {
      return (childNode as Expression).staticParameterElement?.type;
    }
    return _visitParent(node);
  }

  @override
  DartType visitCascadeExpression(CascadeExpression node) {
    if (childNode == node.target) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType visitConditionalExpression(ConditionalExpression node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    } else {
      return _visitParent(node);
    }
  }

  @override
  DartType visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (childNode == node.expression) {
      var element = node.fieldName.staticElement;
      if (element is FieldElement) {
        return element.type;
      }
    }
    return null;
  }

  @override
  DartType visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (childNode == node.defaultValue) {
      return node.parameter.declaredElement.type;
    }
    return null;
  }

  @override
  DartType visitDoStatement(DoStatement node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (childNode == node.expression) {
      var parent = node.parent;
      if (parent is MethodDeclaration) {
        return BodyInferenceContext.of(parent.body).contextType;
      } else if (parent is FunctionExpression) {
        var grandparent = parent.parent;
        if (grandparent is FunctionDeclaration) {
          return BodyInferenceContext.of(parent.body).contextType;
        }
        return _visitParent(parent);
      }
    }
    return null;
  }

  @override
  DartType visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (childNode == node.iterable) {
      var parent = node.parent;
      if ((parent is ForStatement && parent.awaitKeyword != null) ||
          (parent is ForElement && parent.awaitKeyword != null)) {
        return typeProvider.streamDynamicType;
      }
      return typeProvider.iterableDynamicType;
    }
    return null;
  }

  @override
  DartType visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (childNode == node.iterable) {
      var parent = node.parent;
      if ((parent is ForStatement && parent.awaitKeyword != null) ||
          (parent is ForElement && parent.awaitKeyword != null)) {
        return typeProvider.streamDynamicType;
      }
      return typeProvider.iterableDynamicType;
    }
    return null;
  }

  @override
  DartType visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitForPartsWithExpression(ForPartsWithExpression node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    if (childNode == node.function) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType visitIfElement(IfElement node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitIfStatement(IfStatement node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitIndexExpression(IndexExpression node) {
    if (childNode == node.index) {
      var parameters = node.staticElement?.parameters;
      if (parameters != null && parameters.isNotEmpty) {
        return parameters[0].type;
      }
    }
    return null;
  }

  @override
  DartType visitListLiteral(ListLiteral node) {
    if (node.elements.contains(childNode)) {
      return (node.staticType as InterfaceType).typeArguments[0];
    }
    return null;
  }

  @override
  DartType visitMapLiteralEntry(MapLiteralEntry node) {
    var literal = node.thisOrAncestorOfType<SetOrMapLiteral>();
    if (literal != null && literal.staticType.isDartCoreMap) {
      var typeArguments = (literal.staticType as InterfaceType).typeArguments;
      if (childNode == node.key) {
        return typeArguments[0];
      } else {
        return typeArguments[1];
      }
    }
    return null;
  }

  @override
  DartType visitMethodInvocation(MethodInvocation node) {
    if (childNode == node.target || childNode == node.methodName) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType visitNamedExpression(NamedExpression node) {
    if (childNode == node.expression) {
      return _visitParent(node);
    }
    return super.visitNamedExpression(node);
  }

  @override
  DartType visitParenthesizedExpression(ParenthesizedExpression node) {
    return _visitParent(node);
  }

  @override
  DartType visitPostfixExpression(PostfixExpression node) {
    return (childNode as Expression).staticParameterElement?.type;
  }

  @override
  DartType visitPrefixedIdentifier(PrefixedIdentifier node) {
    return _visitParent(node);
  }

  @override
  DartType visitPrefixExpression(PrefixExpression node) {
    return (childNode as Expression).staticParameterElement?.type;
  }

  @override
  DartType visitPropertyAccess(PropertyAccess node) {
    return _visitParent(node);
  }

  @override
  DartType visitReturnStatement(ReturnStatement node) {
    if (childNode == node.expression) {
      var functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody != null) {
        return BodyInferenceContext.of(functionBody).contextType;
      }
    }
    return null;
  }

  @override
  DartType visitSetOrMapLiteral(SetOrMapLiteral node) {
    var type = node.staticType;
    if (node.elements.contains(childNode) &&
        (type.isDartCoreMap || type.isDartCoreSet)) {
      return (type as InterfaceType).typeArguments[0];
    }
    return null;
  }

  @override
  DartType visitSpreadElement(SpreadElement node) {
    if (childNode == node.expression) {
      var currentNode = node.parent;
      while (currentNode != null) {
        if (currentNode is ListLiteral) {
          return typeProvider.iterableDynamicType;
        } else if (currentNode is SetOrMapLiteral) {
          if (currentNode.isSet) {
            return typeProvider.iterableDynamicType;
          }
          return typeProvider.mapType2(
              typeProvider.dynamicType, typeProvider.dynamicType);
        }
        currentNode = currentNode.parent;
      }
    }
    return null;
  }

  @override
  DartType visitVariableDeclaration(VariableDeclaration node) {
    if (childNode == node.initializer) {
      var parent = node.parent;
      if (parent is VariableDeclarationList) {
        return parent.type?.type;
      }
    }
    return null;
  }

  @override
  DartType visitWhileStatement(WhileStatement node) {
    if (childNode == node.condition) {
      return typeProvider.boolType;
    }
    return null;
  }

  @override
  DartType visitYieldStatement(YieldStatement node) {
    if (childNode == node.expression) {
      var functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody != null) {
        return BodyInferenceContext.of(functionBody).contextType;
      }
    }
    return null;
  }

  /// Return the result of visiting the parent of the [node] after setting the
  /// [childNode] to the [node]. Note that this method is destructive in that it
  /// does not reset the [childNode] before returning.
  DartType _visitParent(AstNode node) {
    var parent = node.parent;
    if (parent == null) {
      return null;
    }
    childNode = node;
    return parent.accept(this);
  }
}
