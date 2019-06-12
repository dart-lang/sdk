// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

/// Representation of a type in the code to be migrated.  In addition to
/// tracking the (unmigrated) [DartType], we track the [ConstraintVariable]s
/// indicating whether the type, and the types that compose it, are nullable.
class DecoratedType {
  final DartType type;

  final NullabilityNode node;

  /// If `this` is a function type, the [DecoratedType] of its return type.
  final DecoratedType returnType;

  /// If `this` is a function type, the [DecoratedType] of each of its
  /// positional parameters (including both required and optional positional
  /// parameters).
  final List<DecoratedType> positionalParameters;

  /// If `this` is a function type, the [DecoratedType] of each of its named
  /// parameters.
  final Map<String, DecoratedType> namedParameters;

  /// If `this` is a parameterized type, the [DecoratedType] of each of its
  /// type parameters.
  ///
  /// TODO(paulberry): how should we handle generic typedefs?
  final List<DecoratedType> typeArguments;

  DecoratedType(this.type, this.node,
      {this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.typeArguments = const []}) {
    assert(node != null);
  }

  /// Creates a [DecoratedType] corresponding to the given [element], which is
  /// presumed to have come from code that is already migrated.
  factory DecoratedType.forElement(Element element, NullabilityGraph graph) {
    DecoratedType decorate(DartType type) {
      assert((type as TypeImpl).nullabilitySuffix ==
          NullabilitySuffix.star); // TODO(paulberry)
      if (type is FunctionType) {
        var decoratedType = DecoratedType(type, graph.never,
            returnType: decorate(type.returnType), positionalParameters: []);
        for (var parameter in type.parameters) {
          assert(parameter.isPositional); // TODO(paulberry)
          decoratedType.positionalParameters.add(decorate(parameter.type));
        }
        return decoratedType;
      } else if (type is InterfaceType) {
        assert(type.typeParameters.isEmpty); // TODO(paulberry)
        return DecoratedType(type, graph.never);
      } else {
        throw type.runtimeType; // TODO(paulberry)
      }
    }

    DecoratedType decoratedType;
    if (element is MethodElement) {
      decoratedType = decorate(element.type);
    } else if (element is PropertyAccessorElement) {
      decoratedType = decorate(element.type);
    } else if (element is ConstructorElement) {
      decoratedType = decorate(element.type);
    } else {
      throw element.runtimeType; // TODO(paulberry)
    }
    return decoratedType;
  }

  /// Apply the given [substitution] to this type.
  ///
  /// [undecoratedResult] is the result of the substitution, as determined by
  /// the normal type system.
  DecoratedType substitute(
      Map<TypeParameterElement, DecoratedType> substitution,
      DartType undecoratedResult) {
    if (substitution.isEmpty) return this;
    return _substitute(substitution, undecoratedResult);
  }

  @override
  String toString() {
    var trailing = node.debugSuffix;
    var type = this.type;
    if (type is TypeParameterType || type is VoidType) {
      return '$type$trailing';
    } else if (type is InterfaceType) {
      var name = type.element.name;
      var args = '';
      if (type.typeArguments.isNotEmpty) {
        args = '<${type.typeArguments.join(', ')}>';
      }
      return '$name$args$trailing';
    } else if (type is FunctionType) {
      assert(type.typeFormals.isEmpty); // TODO(paulberry)
      assert(type.namedParameterTypes.isEmpty &&
          namedParameters.isEmpty); // TODO(paulberry)
      var args = positionalParameters.map((p) => p.toString()).join(', ');
      return '$returnType Function($args)$trailing';
    } else if (type is DynamicTypeImpl) {
      return 'dynamic';
    } else {
      throw '$type'; // TODO(paulberry)
    }
  }

  /// Creates a shallow copy of `this`, replacing the nullability node.
  DecoratedType withNode(NullabilityNode node) => DecoratedType(type, node,
      returnType: returnType,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      typeArguments: typeArguments);

  /// Internal implementation of [_substitute], used as a recursion target.
  DecoratedType _substitute(
      Map<TypeParameterElement, DecoratedType> substitution,
      DartType undecoratedResult) {
    var type = this.type;
    if (type is FunctionType && undecoratedResult is FunctionType) {
      assert(type.typeFormals.isEmpty); // TODO(paulberry)
      var newPositionalParameters = <DecoratedType>[];
      for (int i = 0; i < positionalParameters.length; i++) {
        var numRequiredParameters =
            undecoratedResult.normalParameterTypes.length;
        var undecoratedParameterType = i < numRequiredParameters
            ? undecoratedResult.normalParameterTypes[i]
            : undecoratedResult
                .optionalParameterTypes[i - numRequiredParameters];
        newPositionalParameters.add(positionalParameters[i]
            ._substitute(substitution, undecoratedParameterType));
      }
      return DecoratedType(undecoratedResult, node,
          returnType: returnType._substitute(
              substitution, undecoratedResult.returnType),
          positionalParameters: newPositionalParameters);
    } else if (type is TypeParameterType) {
      var inner = substitution[type.element];
      return DecoratedType(undecoratedResult,
          NullabilityNode.forSubstitution(inner?.node, node));
    } else if (type is VoidType) {
      return this;
    }
    throw '$type.substitute($substitution)'; // TODO(paulberry)
  }
}

/// A [DecoratedType] based on a type annotation appearing explicitly in the
/// source code.
///
/// This class implements [PotentialModification] because it knows how to update
/// the source code to reflect its nullability.
class DecoratedTypeAnnotation extends DecoratedType
    implements PotentialModification {
  final int _offset;

  DecoratedTypeAnnotation(
      DartType type, NullabilityNode nullabilityNode, this._offset,
      {List<DecoratedType> typeArguments = const [],
      DecoratedType returnType,
      List<DecoratedType> positionalParameters = const [],
      Map<String, DecoratedType> namedParameters = const {}})
      : super(type, nullabilityNode,
            typeArguments: typeArguments,
            returnType: returnType,
            positionalParameters: positionalParameters,
            namedParameters: namedParameters);

  @override
  bool get isEmpty => !node.isNullable;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? [] : [SourceEdit(_offset, 0, '?')];
}
