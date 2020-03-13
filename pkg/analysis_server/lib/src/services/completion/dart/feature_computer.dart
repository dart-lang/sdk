// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to compute the value of the features used for code
/// completion.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, FieldElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Convert a relevance score (assumed to be between `0.0` and `1.0` inclusive)
/// to a relevance value between `0` and `1000`.
int toRelevance(double score) {
  if (score < 0.0) {
    return 0;
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
  for (int i = 0; i < values.length; i++) {
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
    return 1.0 / (distance + 1);
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

/// An object used to compute metrics for a single file or directory.
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
      if (parameters != null && parameters.length == 1) {
        return parameters[0].type;
      }
    }
    return null;
  }

  @override
  DartType visitListLiteral(ListLiteral node) {
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments != null && typeArguments.length == 1) {
      return typeArguments[0].type;
    }
    return null;
  }

  @override
  DartType visitMapLiteralEntry(MapLiteralEntry node) {
    var typeArguments =
        node.thisOrAncestorOfType<SetOrMapLiteral>()?.typeArguments;
    if (typeArguments != null && typeArguments.length == 2) {
      if (childNode == node.key) {
        return typeArguments.arguments[0].type;
      } else {
        return typeArguments.arguments[1].type;
      }
    }
    return null;
  }

  @override
  DartType visitMethodInvocation(MethodInvocation node) {
    if (childNode == node.target) {
      return _visitParent(node);
    }
    return null;
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
  DartType visitPrefixExpression(PrefixExpression node) {
    return (childNode as Expression).staticParameterElement?.type;
  }

  @override
  DartType visitPropertyAccess(PropertyAccess node) {
    if (childNode == node.target) {
      return _visitParent(node);
    }
    return null;
  }

  @override
  DartType visitReturnStatement(ReturnStatement node) {
    if (childNode == node.expression) {
      return _returnType(node);
    }
    return null;
  }

  @override
  DartType visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isSet) {
      var typeArguments = node.typeArguments?.arguments;
      if (typeArguments != null && typeArguments.length == 1) {
        return typeArguments[0].type;
      }
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
      if (parent is VariableDeclarationList && parent.type != null) {
        return parent.type.type;
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
      return _returnType(node);
    }
    return null;
  }

  DartType _returnType(AstNode node) {
    DartType unwrap(DartType returnType, FunctionBody body) {
      if (returnType is InterfaceTypeImpl) {
        DartType unwrapAs(ClassElement superclass) {
          var convertedType = returnType.asInstanceOf(superclass);
          if (convertedType != null) {
            return convertedType.typeArguments[0];
          }
          return null;
        }

        if (body.isAsynchronous) {
          if (body.isGenerator) {
            // async* implies Stream<T>
            return unwrapAs(typeProvider.streamElement);
          } else {
            // async implies Future<T>
            return unwrapAs(typeProvider.futureElement);
          }
        } else if (body.isGenerator) {
          // sync* implies Iterable<T>
          return unwrapAs(typeProvider.iterableElement);
        }
      }
      return returnType;
    }

    var parent = node.parent;
    while (parent != null) {
      if (parent is MethodDeclaration) {
        return unwrap(parent.declaredElement.returnType, parent.body);
      } else if (parent is ConstructorDeclaration) {
        return parent.declaredElement.returnType;
      } else if (parent is FunctionDeclaration) {
        return unwrap(
            parent.declaredElement.returnType, parent.functionExpression.body);
      }
      parent = parent.parent;
    }
    return null;
  }

  DartType _visitParent(AstNode node) {
    if (node.parent != null) {
      childNode = node;
      return node.parent.accept(this);
    }
    return null;
  }
}
