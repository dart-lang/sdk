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
  void declareType(DeclarationCode typeDeclaration);
}

/// The interface to resolve a [TypeAnnotation] to a [StaticType].
///
/// The [StaticType]s can be compared against other [StaticType]s to see how
/// they relate to each other.
///
/// This api is only available to the declaration and definition phases of
/// macro expansion.
abstract class TypeResolver {
  /// Resolves [typeAnnotation] to a [StaticType].
  ///
  /// Throws an error if the type annotation cannot be resolved. This should
  /// only happen in the case of incomplete or invalid programs, but macros
  /// may be asked to run in this state during the development cycle. It is
  /// helpful for users if macros provide a best effort implementation in that
  /// case or handle the error in a useful way.
  Future<StaticType> resolve(covariant TypeAnnotation typeAnnotation);
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

/// The api used by [Macro]s to reflect on the currently available
/// members, superclass, and mixins for a given [ClassDeclaration]
abstract class ClassDeclarationBuilder
    implements ClassMemberDeclarationBuilder, ClassIntrospector {}

/// The interface used by [Macro]s to resolve any [NamedStaticType] to its
/// declaration.
///
/// Only available in the definition phase of macro expansion.
abstract class TypeDeclarationResolver {
  /// Resolves a [NamedStaticType] to its [TypeDeclaration].
  Future<TypeDeclaration> declarationOf(covariant NamedStaticType annotation);
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
  /// Retrieve a [VariableDefinitionBuilder] for a field by [name].
  ///
  /// Throws an [ArgumentError] if there is no field by that name.
  VariableDefinitionBuilder buildField(String name);

  /// Retrieve a [FunctionDefinitionBuilder] for a method by [name].
  ///
  /// Throws an [ArgumentError] if there is no method by that name.
  FunctionDefinitionBuilder buildMethod(String name);

  /// Retrieve a [ConstructorDefinitionBuilder] for a constructor by [name].
  ///
  /// Throws an [ArgumentError] if there is no constructor by that name.
  ConstructorDefinitionBuilder buildConstructor(String name);
}

/// The apis used by [Macro]s to define the body of a constructor
/// or wrap the body of an existing constructor with additional statements.
abstract class ConstructorDefinitionBuilder implements DefinitionBuilder {
  /// Augments an existing constructor body with [body].
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
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer,
  });
}
