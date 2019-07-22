// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.type_recipe;

import '../elements/types.dart';

/// A TypeEnvironmentStructure describes the shape or layout of a reified type
/// environment.
///
/// A type environment maps type parameter variables to type values. The type
/// variables are mostly elided in the runtime representation, replaced by
/// indexes into the reified environment.
abstract class TypeEnvironmentStructure {
  /// Structural equality on [TypeEnvironmentStructure].
  static bool same(TypeEnvironmentStructure a, TypeEnvironmentStructure b) {
    if (a is SingletonTypeEnvironmentStructure) {
      if (b is SingletonTypeEnvironmentStructure) {
        return a.variable == b.variable;
      }
      return false;
    }
    return _sameFullStructure(a, b);
  }

  static bool _sameFullStructure(
      FullTypeEnvironmentStructure a, FullTypeEnvironmentStructure b) {
    if (a.classType != b.classType) return false;
    List<TypeVariableType> aBindings = a.bindings;
    List<TypeVariableType> bBindings = b.bindings;
    if (aBindings.length != bBindings.length) return false;
    for (int i = 0; i < aBindings.length; i++) {
      if (aBindings[i] != bBindings[i]) return false;
    }
    return true;
  }
}

/// A singleton type environment maps a binds a single value.
class SingletonTypeEnvironmentStructure extends TypeEnvironmentStructure {
  final TypeVariableType variable;

  SingletonTypeEnvironmentStructure(this.variable);

  @override
  String toString() => 'SingletonTypeEnvironmentStructure($variable)';
}

/// A type environment containing an interface type and/or a tuple of function
/// type parameters.
class FullTypeEnvironmentStructure extends TypeEnvironmentStructure {
  final InterfaceType classType;
  final List<TypeVariableType> bindings;

  FullTypeEnvironmentStructure({this.classType, this.bindings = const []});

  @override
  String toString() => 'FullTypeEnvironmentStructure($classType, $bindings)';
}

/// A TypeRecipe is evaluated against a type environment to produce either a
/// type, or another type environment.
abstract class TypeRecipe {
  /// Returns `true` is [recipeB] evaluated in an environment described by
  /// [structureB] gives the same type as [recipeA] evaluated in environment
  /// described by [structureA].
  static bool yieldsSameType(
      TypeRecipe recipeA,
      TypeEnvironmentStructure structureA,
      TypeRecipe recipeB,
      TypeEnvironmentStructure structureB) {
    if (recipeA == recipeB &&
        TypeEnvironmentStructure.same(structureA, structureB)) {
      return true;
    }

    // TODO(sra): Type recipes that are different but equal modulo naming also
    // yield the same type, e.g. `List<X> @X` and `List<Y> @Y`.
    return false;
  }
}

/// A recipe that yields a reified type.
class TypeExpressionRecipe extends TypeRecipe {
  final DartType type;

  TypeExpressionRecipe(this.type);

  @override
  bool operator ==(other) {
    return other is TypeExpressionRecipe && type == other.type;
  }

  @override
  String toString() => 'TypeExpressionRecipe($type)';
}

/// A recipe that yields a reified type environment.
abstract class TypeEnvironmentRecipe extends TypeRecipe {}

/// A recipe that yields a reified type environment that binds a single generic
/// function type parameter.
class SingletonTypeEnvironmentRecipe extends TypeEnvironmentRecipe {
  final DartType type;

  SingletonTypeEnvironmentRecipe(this.type);

  @override
  bool operator ==(other) {
    return other is SingletonTypeEnvironmentRecipe && type == other.type;
  }

  @override
  String toString() => 'SingletonTypeEnvironmentRecipe($type)';
}

/// A recipe that yields a reified type environment that binds a class instance
/// type and/or a tuple of types, usually generic function type arguments.
///
/// With no class is also used as a tuple of types.
class FullTypeEnvironmentRecipe extends TypeEnvironmentRecipe {
  /// Type expression for the interface type of a class scope.  `null` for
  /// environments outside a class scope or a class scope where no supertype is
  /// generic, or where optimization has determined that no use of the
  /// environment requires any of the class type variables.
  final InterfaceType classType;

  // Type expressions for the tuple of function type arguments.
  final List<DartType> types;

  FullTypeEnvironmentRecipe({this.classType, this.types = const []});

  @override
  bool operator ==(other) {
    return other is FullTypeEnvironmentRecipe && _equal(this, other);
  }

  static bool _equal(FullTypeEnvironmentRecipe a, FullTypeEnvironmentRecipe b) {
    if (a.classType != b.classType) return false;
    List<DartType> aTypes = a.types;
    List<DartType> bTypes = b.types;
    if (aTypes.length != bTypes.length) return false;
    for (int i = 0; i < aTypes.length; i++) {
      if (aTypes[i] != bTypes[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'FullTypeEnvironmentRecipe($classType, $types)';
}
