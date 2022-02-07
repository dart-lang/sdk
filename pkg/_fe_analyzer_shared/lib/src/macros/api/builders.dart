// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base interface used to add declarations to the program as well
/// as augment existing ones.
abstract class Builder {}

/// The api used by [Macro]s to contribute new type declarations to the
/// current library, and get [TypeAnnotation]s from runtime [Type] objects.
abstract class TypeBuilder implements Builder {
  /// Adds a new type declaration to the surrounding library.
  ///
  /// The [name] must match the name of the new [typeDeclaration] (this does
  /// not include any type parameters, just the name).
  void declareType(String name, DeclarationCode typeDeclaration);
}

/// The interface used to create [StaticType] instances, which are used to
/// examine type relationships.
///
/// This api is only available to the declaration and definition phases of
/// macro expansion.
abstract class TypeResolver {
  /// Instantiates a new [StaticType] for a given [type] annotation.
  ///
  /// Throws an error if the [type] object contains [Identifier]s which cannot
  /// be resolved. This should only happen in the case of incomplete or invalid
  /// programs, but macros may be asked to run in this state during the
  /// development cycle. It may be helpful for users if macros provide a best
  /// effort implementation in that case or handle the error in a useful way.
  Future<StaticType> resolve(TypeAnnotationCode type);
}

/// The api used to introspect on a [ClassDeclaration].
///
/// Available in the declaration and definition phases, but limited in the
/// declaration phase to immediately annotated [ClassDeclaration]s. This is
/// done by limiting the access to the [TypeDeclarationResolver] to the
/// definition phase.
abstract class ClassIntrospector {
  /// The fields available for [clazz].
  ///
  /// This may be incomplete if in the declaration phase and additional macros
  /// are going to run on this class.
  Future<List<FieldDeclaration>> fieldsOf(covariant ClassDeclaration clazz);

  /// The methods available so far for the current class.
  ///
  /// This may be incomplete if additional declaration macros are running on
  /// this class.
  Future<List<MethodDeclaration>> methodsOf(covariant ClassDeclaration clazz);

  /// The constructors available so far for the current class.
  ///
  /// This may be incomplete if additional declaration macros are running on
  /// this class.
  Future<List<ConstructorDeclaration>> constructorsOf(
      covariant ClassDeclaration clazz);

  /// The class that is directly extended via an `extends` clause.
  Future<ClassDeclaration?> superclassOf(covariant ClassDeclaration clazz);

  /// All of the classes that are mixed in with `with` clauses.
  Future<List<ClassDeclaration>> mixinsOf(covariant ClassDeclaration clazz);

  /// All of the classes that are implemented with an `implements` clause.
  Future<List<ClassDeclaration>> interfacesOf(covariant ClassDeclaration clazz);
}

/// The api used by [Macro]s to contribute new (non-type)
/// declarations to the current library.
///
/// Can also be used to do subtype checks on types.
abstract class DeclarationBuilder
    implements Builder, TypeResolver, ClassIntrospector {
  /// Adds a new regular declaration to the surrounding library.
  ///
  /// Note that type declarations are not supported.
  void declareInLibrary(DeclarationCode declaration);
}

/// The api used by [Macro]s to contribute new members to a class.
abstract class ClassMemberDeclarationBuilder implements DeclarationBuilder {
  /// Adds a new declaration to the surrounding class.
  void declareInClass(DeclarationCode declaration);
}

/// The interface used by [Macro]s to resolve any [Identifier]s pointing to
/// types to their type declarations.
///
/// Only available in the definition phase of macro expansion.
abstract class TypeDeclarationResolver {
  /// Resolves an [identifier] to its [TypeDeclaration].
  ///
  /// If [identifier] does resolve to a [TypeDeclaration], then an
  /// [ArgumentError] is thrown.
  Future<TypeDeclaration> declarationOf(covariant Identifier identifier);
}

/// The base class for builders in the definition phase. These can convert
/// any [TypeAnnotation] into its corresponding [TypeDeclaration], and also
/// reflect more deeply on those.
abstract class DefinitionBuilder
    implements
        Builder,
        TypeResolver,
        ClassIntrospector,
        TypeDeclarationResolver {}

/// The apis used by [Macro]s that run on classes, to fill in the definitions
/// of any external declarations within that class.
abstract class ClassDefinitionBuilder implements DefinitionBuilder {
  /// Retrieve a [VariableDefinitionBuilder] for a field with [identifier].
  ///
  /// Throws an [ArgumentError] if [identifier] does not refer to a field in
  /// this class.
  Future<VariableDefinitionBuilder> buildField(Identifier identifier);

  /// Retrieve a [FunctionDefinitionBuilder] for a method with [identifier].
  ///
  /// Throws an [ArgumentError] if [identifier] does not refer to a method in
  /// this class.
  Future<FunctionDefinitionBuilder> buildMethod(Identifier identifier);

  /// Retrieve a [ConstructorDefinitionBuilder] for a constructor with
  /// [identifier].
  ///
  /// Throws an [ArgumentError] if [identifier] does not refer to a constructor
  /// in this class.
  Future<ConstructorDefinitionBuilder> buildConstructor(Identifier identifier);
}

/// The apis used by [Macro]s to define the body of a constructor
/// or wrap the body of an existing constructor with additional statements.
abstract class ConstructorDefinitionBuilder implements DefinitionBuilder {
  /// Augments an existing constructor body with [body] and [initializers].
  ///
  /// The [initializers] should not contain trailing or preceding commas.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({FunctionBodyCode? body, List<Code>? initializers});
}

/// The apis used by [Macro]s to augment functions or methods.
abstract class FunctionDefinitionBuilder implements DefinitionBuilder {
  /// Augments the function.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment(FunctionBodyCode body);
}

/// The api used by [Macro]s to augment a top level variable or instance field.
abstract class VariableDefinitionBuilder implements DefinitionBuilder {
  /// Augments the field.
  ///
  /// For [getter] and [setter] the full function declaration should be
  /// provided, minus the `augment` keyword (which will be implicitly added).
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer,
  });
}
