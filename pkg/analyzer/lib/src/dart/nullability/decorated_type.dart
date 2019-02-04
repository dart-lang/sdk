// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

/// Representation of a type in the code to be migrated.  In addition to
/// tracking the (unmigrated) [DartType], we track the [ConstraintVariable]s
/// indicating whether the type, and the types that compose it, are nullable.
class DecoratedType {
  final DartType type;

  /// [ConstraintVariable] whose value will be set to `true` if migration needs
  /// to make this type nullable.
  ///
  /// If `null`, that means that an external constraint (outside the code being
  /// migrated) forces this type to be non-nullable.
  final ConstraintVariable nullable;

  /// [ConstraintVariable] whose value will be set to `true` if migration
  /// determines that a `null` value stored in an expression having this type
  /// will unconditionally lead to an assertion failure.
  final ConstraintVariable nullAsserts;

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

  DecoratedType(this.type, this.nullable,
      {this.nullAsserts,
      this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.typeArguments = const []}) {
    // The type system doesn't have a non-nullable version of `dynamic`.  So if
    // the type is `dynamic`, verify that `nullable` is `always`.
    assert(!type.isDynamic || identical(nullable, ConstraintVariable.always));
  }

  /// Creates a [DecoratedType] corresponding to the given [element], which is
  /// presumed to have come from code that is already migrated.
  factory DecoratedType.forElement(Element element) {
    DecoratedType decorate(DartType type) {
      assert((type as TypeImpl).nullability ==
          Nullability.indeterminate); // TODO(paulberry)
      if (type is FunctionType) {
        var decoratedType = DecoratedType(type, null,
            returnType: decorate(type.returnType), positionalParameters: []);
        for (var parameter in type.parameters) {
          assert(parameter.isPositional); // TODO(paulberry)
          decoratedType.positionalParameters.add(decorate(parameter.type));
        }
        return decoratedType;
      } else if (type is InterfaceType) {
        assert(type.typeParameters.isEmpty); // TODO(paulberry)
        return DecoratedType(type, null);
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
      Map<TypeParameterElement, DecoratedType> substitution,
      DartType undecoratedResult) {
    if (substitution.isEmpty) return this;
    return _substitute(substitution, undecoratedResult);
  }

  @override
  String toString() {
    var trailing = nullable == null ? '' : '?($nullable)';
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
      // TODO(paulberry): what do we do for nullAsserts here?
      var nullAsserts = null;
      return DecoratedType(undecoratedResult, nullable,
          nullAsserts: nullAsserts,
          returnType: returnType._substitute(
              substitution, undecoratedResult.returnType),
          positionalParameters: newPositionalParameters);
    } else if (type is TypeParameterType) {
      var inner = substitution[type.element];
      // TODO(paulberry): what do we do for nullAsserts here?
      var nullAsserts = null;
      return DecoratedType(
          undecoratedResult, ConstraintVariable.or(inner?.nullable, nullable),
          nullAsserts: nullAsserts);
    } else if (type is VoidType) {
      return this;
    }
    throw '$type.substitute($substitution)'; // TODO(paulberry)
  }
}
