// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:kernel/ast.dart';

/// Type environments made of type parameters.
///
/// At runtime, type recipes are evaluated in an environment to produce an rti.
/// These compile time representations are used to calculate the indices of type
/// parameters in type recipes.
abstract class DDCTypeEnvironment {
  /// Creates a new environment by adding [parameters] to those already in this
  /// environment.
  DDCTypeEnvironment extend(List<TypeParameter> parameters);

  /// Reduces this environment down to an environment that will contain
  /// [requiredTypes] and be output in a compact representation.
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters);

  /// Returns the index of [parameter] in this environment for use in a type
  /// recipe or a negative value if the parameter was not found.
  int recipeIndexOf(TypeParameter parameter);

  /// Returns all class type parameters in this type environment.
  ///
  /// For the example:
  ///
  /// ```
  /// Class Foo<T> {
  ///   method<U> {
  ///     ... // this
  ///   }
  /// }
  /// ```
  ///
  /// classTypeParameters in this would return ['T'].
  List<TypeParameter> get classTypeParameters;

  /// Returns all class type parameters in this type environment.
  ///
  /// For the example:
  ///
  /// ```
  /// Class Foo<T> {
  ///   method<U> {
  ///     ... // this
  ///   }
  /// }
  /// ```
  ///
  /// functionTypeParameters this would return ['U'].
  List<TypeParameter> get functionTypeParameters;
}

/// An empty environment that signals no type parameters are present or needed.
///
/// Facilitates building other environments.
class EmptyTypeEnvironment implements DDCTypeEnvironment {
  const EmptyTypeEnvironment();

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty ? this : BindingTypeEnvironment(parameters);
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    return this;
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    return -1;
  }

  @override
  List<TypeParameter> get classTypeParameters => UnmodifiableListView([]);

  @override
  List<TypeParameter> get functionTypeParameters => UnmodifiableListView([]);
}

/// A type environment introduced by a class with one or more generic type
/// parameters.
class ClassTypeEnvironment implements DDCTypeEnvironment {
  final List<TypeParameter> _typeParameters;

  ClassTypeEnvironment(this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty
        ? this
        : ExtendedClassTypeEnvironment(this, [...parameters]);
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    // If any parameters are required, the class type environment already
    // exists and a reference to it is suitably compact.
    return requiredParameters.any(_typeParameters.contains)
        ? this
        : const EmptyTypeEnvironment();
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    var i = _typeParameters.indexOf(parameter);
    if (i < 0) return i;
    // Index for class type parameters is one based. Zero refers to the full
    // class rti with all type arguments.
    return i + 1;
  }

  @override
  List<TypeParameter> get classTypeParameters =>
      UnmodifiableListView(_typeParameters);

  @override
  List<TypeParameter> get functionTypeParameters => UnmodifiableListView([]);
}

/// A type environment introduced by a subroutine, wherein an RTI object is
/// explicitly provided.
class RtiTypeEnvironment implements DDCTypeEnvironment {
  final List<TypeParameter> _typeParameters;

  RtiTypeEnvironment(this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    /// RtiTypeEnvironments are only used for constructors, factories, and type
    /// signatures - none of which can accept generic arguments.
    throw Exception(
        'RtiTypeEnvironments should not receive extended type parameters.');
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    // If any parameters are required, the class type environment already
    // exists and a reference to it is suitably compact.
    return requiredParameters.any(_typeParameters.contains)
        ? this
        : const EmptyTypeEnvironment();
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    var i = _typeParameters.indexOf(parameter);
    if (i < 0) return i;
    // Index for class type parameters is one based. Zero refers to the full
    // class rti with all type arguments.
    return i + 1;
  }

  @override
  List<TypeParameter> get classTypeParameters =>
      UnmodifiableListView(_typeParameters);

  @override
  List<TypeParameter> get functionTypeParameters => UnmodifiableListView([]);
}

/// A type environment containing multiple type parameters.
class BindingTypeEnvironment implements DDCTypeEnvironment {
  final List<TypeParameter> _typeParameters;

  BindingTypeEnvironment(this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty
        ? this
        : BindingTypeEnvironment([
            // Place new parameters first so they can effectively shadow
            // parameters already in the environment.
            ...parameters, ..._typeParameters
          ]);
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    var foundParameters = requiredParameters.where(_typeParameters.contains);
    if (foundParameters.isEmpty) return const EmptyTypeEnvironment();
    if (foundParameters.length == _typeParameters.length) return this;
    return BindingTypeEnvironment(foundParameters.toList());
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    var i = _typeParameters.indexOf(parameter);
    if (i < 0) return i;
    // Environments containing a single parameter can have a more compact
    // representation with a zero based index.
    if (isSingleTypeParameter) return i;
    return i + 1;
  }

  @override
  List<TypeParameter> get classTypeParameters => UnmodifiableListView([]);

  @override
  List<TypeParameter> get functionTypeParameters =>
      UnmodifiableListView(_typeParameters);

  /// Returns `true` if this environment only contains a single type parameter.
  bool get isSingleTypeParameter => _typeParameters.length == 1;
}

/// A type environment based on one introduced by a generic class but extended
/// with additional parameters from methods with generic type parameters.
class ExtendedClassTypeEnvironment implements DDCTypeEnvironment {
  final ClassTypeEnvironment _classEnvironment;
  final List<TypeParameter> _typeParameters;

  ExtendedClassTypeEnvironment(this._classEnvironment, this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty
        ? this
        : ExtendedClassTypeEnvironment(_classEnvironment, [
            // Place new parameters first so they can effectively shadow
            // parameters already in the environment.
            ...parameters, ..._typeParameters
          ]);
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    var classEnvironmentNeeded =
        requiredParameters.any(_classEnvironment._typeParameters.contains);
    var additionalParameters =
        requiredParameters.where(_typeParameters.contains);
    if (additionalParameters.isEmpty) {
      return classEnvironmentNeeded
          // Simply using the class environment has a compact representation
          // and is already constructed.
          ? _classEnvironment
          // No type parameters are needed from this environment.
          : const EmptyTypeEnvironment();
    }
    // This is already the exact environment needed.
    if (additionalParameters.length == _typeParameters.length) return this;
    // An extended class environment with fewer additional parameters is needed.
    return ExtendedClassTypeEnvironment(
        _classEnvironment, additionalParameters.toList());
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    // Search in the extended type parameters first. They can shadow parameters
    // from the class.
    var i = _typeParameters.indexOf(parameter);
    // Type parameter was found and should be a one based index. Zero refers to
    // the original class rti that is the basis on this environment.
    if (i >= 0) return i + 1;
    i = _classEnvironment.recipeIndexOf(parameter);
    // The type parameter bindings with the closest scope have the lowest
    // indices. Since the parameter was found in the class binding the index
    // must be offset by the number of extended parameters.
    if (i > 0) return i + _typeParameters.length;
    // Type parameter not found.
    return -1;
  }

  @override
  List<TypeParameter> get classTypeParameters =>
      UnmodifiableListView(_classEnvironment.classTypeParameters);

  @override
  List<TypeParameter> get functionTypeParameters =>
      UnmodifiableListView(_typeParameters);
}
