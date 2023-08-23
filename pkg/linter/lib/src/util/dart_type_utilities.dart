// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';

bool argumentsMatchParameters(
    NodeList<Expression> arguments, NodeList<FormalParameter> parameters) {
  var namedParameters = <String, Element?>{};
  var namedArguments = <String, Element>{};
  var positionalParameters = <Element?>[];
  var positionalArguments = <Element>[];
  for (var parameter in parameters) {
    var identifier = parameter.name;
    if (identifier != null) {
      if (parameter.isNamed) {
        namedParameters[identifier.lexeme] = parameter.declaredElement;
      } else {
        positionalParameters.add(parameter.declaredElement);
      }
    }
  }
  for (var argument in arguments) {
    if (argument is NamedExpression) {
      var element = argument.expression.canonicalElement;
      if (element == null) {
        return false;
      }
      namedArguments[argument.name.label.name] = element;
    } else {
      var element = argument.canonicalElement;
      if (element == null) {
        return false;
      }
      positionalArguments.add(element);
    }
  }
  if (positionalParameters.length != positionalArguments.length ||
      namedParameters.keys.length != namedArguments.keys.length) {
    return false;
  }
  for (var i = 0; i < positionalArguments.length; i++) {
    if (positionalArguments[i] != positionalParameters[i]) {
      return false;
    }
  }

  for (var key in namedParameters.keys) {
    if (namedParameters[key] != namedArguments[key]) {
      return false;
    }
  }

  return true;
}

/// Returns whether the canonical elements of [element1] and [element2] are
/// equal.
bool canonicalElementsAreEqual(Element? element1, Element? element2) =>
    element1?.canonicalElement == element2?.canonicalElement;

/// Returns whether the canonical elements from two nodes are equal.
///
/// As in, [NullableAstNodeExtension.canonicalElement], the two nodes must be
/// [Expression]s in order to be compared (otherwise `false` is returned).
///
/// The two nodes must both be a [SimpleIdentifier], [PrefixedIdentifier], or
/// [PropertyAccess] (otherwise `false` is returned).
///
/// If the two nodes are PrefixedIdentifiers, or PropertyAccess nodes, then
/// `true` is returned only if their canonical elements are equal, in
/// addition to their prefixes' and targets' (respectfully) canonical
/// elements.
///
/// There is an inherent assumption about pure getters. For example:
///
///     A a1 = ...
///     A a2 = ...
///     a1.b.c; // statement 1
///     a2.b.c; // statement 2
///     a1.b.c; // statement 3
///
/// The canonical elements from statements 1 and 2 are different, because a1
/// is not the same element as a2.  The canonical elements from statements 1
/// and 3 are considered to be equal, even though `A.b` may have side effects
/// which alter the returned value.
bool canonicalElementsFromIdentifiersAreEqual(
    Expression? rawExpression1, Expression? rawExpression2) {
  if (rawExpression1 == null || rawExpression2 == null) return false;

  var expression1 = rawExpression1.unParenthesized;
  var expression2 = rawExpression2.unParenthesized;

  if (expression1 is SimpleIdentifier) {
    return expression2 is SimpleIdentifier &&
        canonicalElementsAreEqual(getWriteOrReadElement(expression1),
            getWriteOrReadElement(expression2));
  }

  if (expression1 is PrefixedIdentifier) {
    return expression2 is PrefixedIdentifier &&
        canonicalElementsAreEqual(expression1.prefix.staticElement,
            expression2.prefix.staticElement) &&
        canonicalElementsAreEqual(getWriteOrReadElement(expression1.identifier),
            getWriteOrReadElement(expression2.identifier));
  }

  if (expression1 is PropertyAccess && expression2 is PropertyAccess) {
    var target1 = expression1.target;
    var target2 = expression2.target;
    return canonicalElementsFromIdentifiersAreEqual(target1, target2) &&
        canonicalElementsAreEqual(
            getWriteOrReadElement(expression1.propertyName),
            getWriteOrReadElement(expression2.propertyName));
  }

  return false;
}

/// Returns whether [leftType] and [rightType] are _definitely_ unrelated.
///
/// For the purposes of this function, here are some "relation" rules:
/// * `dynamic` and `Null` are considered related to any other type.
/// * Two types which are equal modulo nullability are considered related,
///   e.g. `int` and `int`, `String` and `String?`, `List<String>` and
///   `List<String>`, `List<T>` and `List<T>`, and type variables `A` and `A`.
/// * Two types such that one is a subtype of the other, modulo nullability,
///   such as `List<dynamic>` and `Iterable<dynamic>`, and type variables `A`
///   and `B` where `A extends B`, are considered related.
/// * Two interface types:
///   * are related if they represent the same class, modulo type arguments,
///     modulo nullability, and each of their pair-wise type arguments are
///     related, e.g. `List<dynamic>` and `List<int>`, and `Future<T>` and
///     `Future<S>` where `S extends T`.
///   * are unrelated if [leftType]'s supertype is [Object].
///   * are related if their supertypes are equal, e.g. `List<dynamic>` and
///     `Set<dynamic>`.
/// * Two type variables are related if their bounds are related.
/// * A record type is unrelated to any other type except a record type of
///   the same shape.
/// * Otherwise, any two types are related.
// TODO(srawlins): typedefs and functions in general.
bool typesAreUnrelated(
    TypeSystem typeSystem, DartType? leftType, DartType? rightType) {
  // If we don't have enough information, or can't really compare the types,
  // return false as they _might_ be related.
  if (leftType == null ||
      leftType.isBottom ||
      leftType is DynamicType ||
      rightType == null ||
      rightType.isBottom ||
      rightType is DynamicType) {
    return false;
  }
  var promotedLeftType = typeSystem.promoteToNonNull(leftType);
  var promotedRightType = typeSystem.promoteToNonNull(rightType);
  if (promotedLeftType == promotedRightType ||
      typeSystem.isSubtypeOf(promotedLeftType, promotedRightType) ||
      typeSystem.isSubtypeOf(promotedRightType, promotedLeftType)) {
    return false;
  }
  if (promotedLeftType is InterfaceType && promotedRightType is InterfaceType) {
    return typeSystem.interfaceTypesAreUnrelated(
        promotedLeftType, promotedRightType);
  } else if (promotedLeftType is TypeParameterType &&
      promotedRightType is TypeParameterType) {
    return typesAreUnrelated(typeSystem, promotedLeftType.element.bound,
        promotedRightType.element.bound);
  } else if (promotedLeftType is FunctionType) {
    if (_isFunctionTypeUnrelatedToType(promotedLeftType, promotedRightType)) {
      return true;
    }
  } else if (promotedRightType is FunctionType) {
    if (_isFunctionTypeUnrelatedToType(promotedRightType, promotedLeftType)) {
      return true;
    }
  } else if (promotedLeftType is RecordType ||
      promotedRightType is RecordType) {
    return !typeSystem.isAssignableTo(promotedLeftType, promotedRightType) &&
        !typeSystem.isAssignableTo(promotedRightType, promotedLeftType);
  }
  return false;
}

bool _isFunctionTypeUnrelatedToType(FunctionType type1, DartType type2) {
  if (type2 is FunctionType) {
    return false;
  }
  if (type2 is InterfaceType) {
    var element2 = type2.element;
    if (element2 is ClassElement &&
        element2.lookUpConcreteMethod('call', element2.library) != null) {
      return false;
    }
  }
  return true;
}

typedef AstNodePredicate = bool Function(AstNode node);

class DartTypeUtilities {
  @Deprecated('Replace with `type.extendsClass`')
  static bool extendsClass(
          DartType? type, String? className, String? library) =>
      type.extendsClass(className, library!);

  @Deprecated('Replace with `rawNode.canonicalElement`')
  static Element? getCanonicalElementFromIdentifier(AstNode? rawNode) =>
      rawNode.canonicalElement;

  @Deprecated('Replace with `type.implementsInterface`')
  static bool implementsInterface(
          DartType? type, String interface, String library) =>
      type.implementsInterface(interface, library);

  // todo(pq): remove and replace w/ an extension (pending internal migration)
  @Deprecated('Slated for removal')
  static bool isClass(DartType? type, String? className, String? library) =>
      type is InterfaceType &&
      type.element.name == className &&
      type.element.library.name == library;

  @Deprecated('Replace with `expression.isNullLiteral`')
  static bool isNullLiteral(Expression? expression) => expression.isNullLiteral;

  @Deprecated('Use `argumentsMatchParameters`')
  static bool matchesArgumentsWithParameters(NodeList<Expression> arguments,
          NodeList<FormalParameter> parameters) =>
      argumentsMatchParameters(arguments, parameters);

  @Deprecated('Replace with `node.traverseNodesInDFS`')
  static Iterable<AstNode> traverseNodesInDFS(AstNode node,
          {AstNodePredicate? excludeCriteria}) =>
      node.traverseNodesInDFS(excludeCriteria: excludeCriteria);
}

class InterfaceTypeDefinition {
  final String name;
  final String library;

  InterfaceTypeDefinition(this.name, this.library);

  @override
  int get hashCode => name.hashCode ^ library.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InterfaceTypeDefinition &&
        name == other.name &&
        library == other.library;
  }
}

extension on TypeSystem {
  bool interfaceTypesAreUnrelated(
      InterfaceType leftType, InterfaceType rightType) {
    var leftElement = leftType.element;
    var rightElement = rightType.element;
    if (leftElement == rightElement) {
      // In this case, [leftElement] and [rightElement] represent the same
      // class, modulo generics, e.g. `List<int>` and `List<dynamic>`. Now we
      // need to check type arguments.
      var leftTypeArguments = leftType.typeArguments;
      var rightTypeArguments = rightType.typeArguments;
      if (leftTypeArguments.length != rightTypeArguments.length) {
        // I cannot think of how we would enter this block, but it guards
        // against RangeError below.
        return false;
      }
      for (var i = 0; i < leftTypeArguments.length; i++) {
        // If any of the pair-wise type arguments are unrelated, then
        // [leftType] and [rightType] are unrelated.
        if (typesAreUnrelated(
            this, leftTypeArguments[i], rightTypeArguments[i])) {
          return true;
        }
      }
      // Otherwise, they might be related.
      return false;
    } else {
      var sameSupertypes = leftElement.supertype == rightElement.supertype;

      // Unrelated Enums have the same supertype, but they are not the same element, so
      // they are unrelated.
      if (sameSupertypes && leftElement is EnumElement) {
        return true;
      }

      return (leftElement.supertype?.isDartCoreObject ?? false) ||
          !sameSupertypes;
    }
  }
}

extension DartTypeExtensions on DartType {
  /// Returns the type which should be used when conducting "interface checks"
  /// on `this`.
  ///
  /// If `this` is a type variable, then the type-for-interface-check of its
  /// promoted bound or bound is returned. Otherwise, `this` is returned.
  // TODO(srawlins): Move to extensions.dart.
  DartType get typeForInterfaceCheck {
    var self = this;
    if (self is TypeParameterType) {
      if (self is TypeParameterTypeImpl) {
        var promotedType = self.promotedBound;
        if (promotedType != null) {
          return promotedType.typeForInterfaceCheck;
        }
      }
      return self.bound.typeForInterfaceCheck;
    } else {
      return self;
    }
  }
}
