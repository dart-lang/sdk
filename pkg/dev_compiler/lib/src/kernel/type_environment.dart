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
class ClassTypeEnvironment
    implements DDCTypeEnvironment, ExtendableTypeEnvironment {
  @override
  final List<TypeParameter> _typeParameters;

  ClassTypeEnvironment(this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty
        ? this
        : ExtendedTypeEnvironment<ClassTypeEnvironment>(this, [...parameters]);
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
class RtiTypeEnvironment
    implements DDCTypeEnvironment, ExtendableTypeEnvironment {
  @override
  final List<TypeParameter> _typeParameters;

  RtiTypeEnvironment(this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    /// RtiTypeEnvironments are only used for factories and type signatures. Of
    /// these factories can have generic functions defined in their bodies that
    /// require extending the environment.
    return ExtendedTypeEnvironment<RtiTypeEnvironment>(this, [...parameters]);
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
            ...parameters, ..._typeParameters,
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

abstract class ExtendableTypeEnvironment extends DDCTypeEnvironment {
  List<TypeParameter> get _typeParameters;
}

/// A type environment based on one introduced by a generic environment but
/// extended with additional parameters from methods/functions with generic type
/// parameters.
class ExtendedTypeEnvironment<T extends ExtendableTypeEnvironment>
    implements DDCTypeEnvironment {
  final T _baseTypeEnvironment;
  final List<TypeParameter> _typeParameters;

  ExtendedTypeEnvironment(this._baseTypeEnvironment, this._typeParameters);

  @override
  DDCTypeEnvironment extend(List<TypeParameter> parameters) {
    return parameters.isEmpty
        ? this
        : ExtendedTypeEnvironment(_baseTypeEnvironment, [
            // Place new parameters first so they can effectively shadow
            // parameters already in the environment.
            ...parameters, ..._typeParameters,
          ]);
  }

  @override
  DDCTypeEnvironment prune(Iterable<TypeParameter> requiredParameters) {
    var baseEnvironmentNeeded = requiredParameters.any(
      _baseTypeEnvironment._typeParameters.contains,
    );
    var additionalParameters = requiredParameters
        .where(_typeParameters.contains)
        .toList();
    if (!baseEnvironmentNeeded) {
      return additionalParameters.isEmpty
          // No type parameters are needed from this environment.
          ? const EmptyTypeEnvironment()
          // A binding environment with a single parameter will be reduced to
          // just the parameter.
          : BindingTypeEnvironment(additionalParameters);
    }
    // Simply using the base environment has a compact representation and at
    // runtime it has already been constructed.
    if (additionalParameters.isEmpty) return _baseTypeEnvironment;
    // This is already the exact environment needed.
    if (additionalParameters.length == _typeParameters.length) return this;
    // An extended environment with fewer additional parameters is needed.
    return ExtendedTypeEnvironment(_baseTypeEnvironment, additionalParameters);
  }

  @override
  int recipeIndexOf(TypeParameter parameter) {
    // Search in the extended type parameters first. They can shadow parameters
    // from the base environment.
    var i = _typeParameters.indexOf(parameter);
    // Type parameter was found and should be a one based index. Zero refers to
    // the original rti that is the basis of this environment.
    if (i >= 0) return i + 1;
    i = _baseTypeEnvironment.recipeIndexOf(parameter);
    // The type parameter bindings with the closest scope have the lowest
    // indices. Since the parameter was found in the base binding the index
    // must be offset by the number of extended parameters.
    if (i > 0) return i + _typeParameters.length;
    // Type parameter not found.
    return -1;
  }

  @override
  List<TypeParameter> get classTypeParameters =>
      UnmodifiableListView(_baseTypeEnvironment.classTypeParameters);

  @override
  List<TypeParameter> get functionTypeParameters =>
      UnmodifiableListView(_typeParameters);
}
