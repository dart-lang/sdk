// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/nullability_node.dart';
import 'package:analysis_server/src/nullability/transitional_api.dart';
import 'package:analysis_server/src/nullability/unit_propagation.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;

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

  /// If `this` is a function type, [ConstraintVariable] for each of its named
  /// parameters indicating whether the given named parameter needs to be
  /// optional (no `required` annotation).
  ///
  /// If there is no entry in this map corresponding to a given named parameter,
  /// that means that it has already been decided (prior to migration) that the
  /// given named parameter is required.  TODO(paulberry): test that this works
  /// for already-migrated code.
  final Map<String, ConstraintVariable> namedParameterOptionalVariables;

  /// If `this` is a parameterized type, the [DecoratedType] of each of its
  /// type parameters.
  ///
  /// TODO(paulberry): how should we handle generic typedefs?
  final List<DecoratedType> typeArguments;

  DecoratedType(this.type, this.node,
      {this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.namedParameterOptionalVariables = const {},
      this.typeArguments = const []}) {
    assert(node != null);
    // The type system doesn't have a non-nullable version of `dynamic`.  So if
    // the type is `dynamic`, verify that `nullable` is `always`.
    assert(
        !type.isDynamic || identical(node.nullable, ConstraintVariable.always));
  }

  /// Creates a [DecoratedType] corresponding to the given [element], which is
  /// presumed to have come from code that is already migrated.
  factory DecoratedType.forElement(Element element) {
    DecoratedType decorate(DartType type) {
      assert((type as TypeImpl).nullability ==
          Nullability.indeterminate); // TODO(paulberry)
      if (type is FunctionType) {
        var decoratedType = DecoratedType(type, NullabilityNode(null),
            returnType: decorate(type.returnType), positionalParameters: []);
        for (var parameter in type.parameters) {
          assert(parameter.isPositional); // TODO(paulberry)
          decoratedType.positionalParameters.add(decorate(parameter.type));
        }
        return decoratedType;
      } else if (type is InterfaceType) {
        assert(type.typeParameters.isEmpty); // TODO(paulberry)
        return DecoratedType(type, NullabilityNode(null));
      } else {
        throw type.runtimeType; // TODO(paulberry)
      }
    }

    DecoratedType decoratedType;
    if (element is MethodElement) {
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
      Constraints constraints,
      Map<TypeParameterElement, DecoratedType> substitution,
      DartType undecoratedResult) {
    if (substitution.isEmpty) return this;
    return _substitute(constraints, substitution, undecoratedResult);
  }

  @override
  String toString() {
    var trailing = node.nullable == null ? '' : '?(${node.nullable})';
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

  /// Internal implementation of [_substitute], used as a recursion target.
  DecoratedType _substitute(
      Constraints constraints,
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
            ._substitute(constraints, substitution, undecoratedParameterType));
      }
      return DecoratedType(undecoratedResult, NullabilityNode(node.nullable),
          returnType: returnType._substitute(
              constraints, substitution, undecoratedResult.returnType),
          positionalParameters: newPositionalParameters);
    } else if (type is TypeParameterType) {
      var inner = substitution[type.element];
      return DecoratedType(
          undecoratedResult,
          NullabilityNode(ConstraintVariable.or(
              constraints, inner?.node?.nullable, node.nullable)));
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
      DartType type, ConstraintVariable nullable, this._offset,
      {List<DecoratedType> typeArguments = const []})
      : super(type, NullabilityNode(nullable), typeArguments: typeArguments);

  @override
  bool get isEmpty =>
      identical(node.nullable, ConstraintVariable.always) ||
      !node.nullable.value;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? [] : [SourceEdit(_offset, 0, '?')];
}

/// Type of a [ConstraintVariable] representing the fact that a type is intended
/// to be non-null.
class NonNullIntent extends ConstraintVariable {
  final int _offset;

  NonNullIntent(this._offset);

  @override
  toString() => 'nonNullIntent($_offset)';
}

/// Type of a [ConstraintVariable] representing the fact that a type is
/// nullable.
class TypeIsNullable extends ConstraintVariable {
  final int _offset;

  TypeIsNullable(this._offset);

  @override
  toString() => 'nullable($_offset)';
}
