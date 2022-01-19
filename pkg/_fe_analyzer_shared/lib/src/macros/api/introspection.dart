// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class for an unresolved reference to a type.
///
/// See the subtypes [FunctionTypeAnnotation] and [NamedTypeAnnotation].
abstract class TypeAnnotation {
  /// Whether or not the type annotation is explicitly nullable (contains a
  /// trailing `?`)
  bool get isNullable;

  /// A [Code] object representation of this type annotation.
  Code get code;
}

/// The base class for function type declarations.
abstract class FunctionTypeAnnotation implements TypeAnnotation {
  /// The return type of this function.
  TypeAnnotation get returnType;

  /// The positional parameters for this function.
  Iterable<ParameterDeclaration> get positionalParameters;

  /// The named parameters for this function.
  Iterable<ParameterDeclaration> get namedParameters;

  /// The type parameters for this function.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// An unresolved reference to a type.
///
/// These can be resolved to a [TypeDeclaration] using the `builder` classes
/// depending on the phase a macro is running in.
abstract class NamedTypeAnnotation implements TypeAnnotation {
  /// The name of the type as it exists in the type annotation.
  String get name;

  /// The type arguments, if applicable.
  Iterable<TypeAnnotation> get typeArguments;
}

/// The interface representing a resolved type.
///
/// Resolved types understand exactly what type they represent, and can be
/// compared to other static types.
abstract class StaticType {
  /// Returns true if this is a subtype of [other].
  Future<bool> isSubtypeOf(covariant StaticType other);

  /// Returns true if this is an identical type to [other].
  Future<bool> isExactly(covariant StaticType other);
}

/// A subtype of [StaticType] representing types that can be resolved by name
/// to a concrete declaration.
abstract class NamedStaticType implements StaticType {}

/// The base class for all declarations.
abstract class Declaration {
  /// The name of this declaration.
  String get name;
}

/// A declaration that defines a new type in the program.
///
/// See subtypes [ClassDeclaration] and [TypeAliasDeclaration].
abstract class TypeDeclaration implements Declaration {
  /// The type parameters defined for this type declaration.
  Iterable<TypeParameterDeclaration> get typeParameters;

  /// Create a static type representing this type with [typeArguments].
  ///
  /// If [isNullable] is `true`, then this type will behave as if it has a
  /// trailing `?`.
  ///
  /// Throws an exception if the type could not be instantiated, typically due
  /// to one of the type arguments not matching the bounds of the corresponding
  /// type parameter.
  Future<StaticType> instantiate(
      {required List<StaticType> typeArguments, required bool isNullable});
}

/// Class (and enum) introspection information.
///
/// Information about fields, methods, and constructors must be retrieved from
/// the `builder` objects.
abstract class ClassDeclaration implements TypeDeclaration {
  /// Whether this class has an `abstract` modifier.
  bool get isAbstract;

  /// Whether this class has an `external` modifier.
  bool get isExternal;

  /// The `extends` type annotation, if present.
  TypeAnnotation? get superclass;

  /// All the `implements` type annotations.
  Iterable<TypeAnnotation> get interfaces;

  /// All the `with` type annotations.
  Iterable<TypeAnnotation> get mixins;

  /// All the type arguments, if applicable.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// Type alias introspection information.
abstract class TypeAliasDeclaration extends TypeDeclaration {
  /// The type annotation this is an alias for.
  TypeAnnotation get type;
}

/// Function introspection information.
abstract class FunctionDeclaration implements Declaration {
  /// Whether this function has an `abstract` modifier.
  bool get isAbstract;

  /// Whether this function has an `external` modifier.
  bool get isExternal;

  /// Whether this function is actually a getter.
  bool get isGetter;

  /// Whether this function is actually a setter.
  bool get isSetter;

  /// The return type of this function.
  TypeAnnotation get returnType;

  /// The positional parameters for this function.
  Iterable<ParameterDeclaration> get positionalParameters;

  /// The named parameters for this function.
  Iterable<ParameterDeclaration> get namedParameters;

  /// The type parameters for this function.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// Method introspection information.
abstract class MethodDeclaration implements FunctionDeclaration {
  /// The class that defines this method.
  TypeAnnotation get definingClass;
}

/// Constructor introspection information.
abstract class ConstructorDeclaration implements MethodDeclaration {
  /// Whether or not this is a factory constructor.
  bool get isFactory;
}

/// Variable introspection information.
abstract class VariableDeclaration implements Declaration {
  /// Whether this function has an `abstract` modifier.
  bool get isAbstract;

  /// Whether this function has an `external` modifier.
  bool get isExternal;

  /// The type of this field.
  TypeAnnotation get type;

  /// A [Code] object representing the initializer for this field, if present.
  Code? get initializer;
}

/// Field introspection information ..
abstract class FieldDeclaration implements VariableDeclaration {
  /// The class that defines this method.
  TypeAnnotation get definingClass;
}

/// Parameter introspection information.
abstract class ParameterDeclaration implements Declaration {
  /// The type of this parameter.
  TypeAnnotation get type;

  /// Whether or not this is a named parameter.
  bool get isNamed;

  /// Whether or not this parameter is either a non-optional positional
  /// parameter or an optional parameter with the `required` keyword.
  bool get isRequired;

  /// A [Code] object representing the default value for this parameter, if
  /// present. Can be used to copy default values to other parameters.
  Code? get defaultValue;
}

/// Type parameter introspection information.
abstract class TypeParameterDeclaration implements Declaration {
  /// The bounds for this type parameter, if it has any.
  TypeAnnotation? get bounds;
}
