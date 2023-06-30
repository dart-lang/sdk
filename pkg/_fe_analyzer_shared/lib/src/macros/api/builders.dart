// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base interface used to add declarations to the program as well
/// as augment existing ones.
abstract interface class Builder {}

/// Allows you to resolve arbitrary [Identifier]s.
///
/// This class will likely disappear entirely once we have a different
/// mechanism.
abstract interface class IdentifierResolver {
  /// Returns an [Identifier] for a top level [name] in [library].
  ///
  /// You should only do this for libraries that are definitely in the
  /// transitive import graph of the library you are generating code into.
  @Deprecated(
      'This API should eventually be replaced with a different, safer API.')
  Future<Identifier> resolveIdentifier(Uri library, String name);
}

/// The API used by [Macro]s to contribute new type declarations to the
/// current library, and get [TypeAnnotation]s from runtime [Type] objects.
abstract interface class TypeBuilder implements Builder, IdentifierResolver {
  /// Adds a new type declaration to the surrounding library.
  ///
  /// The [name] must match the name of the new [typeDeclaration] (this does
  /// not include any type parameters, just the name).
  void declareType(String name, DeclarationCode typeDeclaration);
}

/// The interface used to create [StaticType] instances, which are used to
/// examine type relationships.
///
/// This API is only available to the declaration and definition phases of
/// macro expansion.
abstract interface class TypeResolver {
  /// Instantiates a new [StaticType] for a given [type] annotation.
  ///
  /// Throws an error if the [type] object contains [Identifier]s which cannot
  /// be resolved. This should only happen in the case of incomplete or invalid
  /// programs, but macros may be asked to run in this state during the
  /// development cycle. It may be helpful for users if macros provide a best
  /// effort implementation in that case or handle the error in a useful way.
  Future<StaticType> resolve(TypeAnnotationCode type);
}

/// The API used to introspect on any [TypeDeclaration] which also has the
/// marker interface [IntrospectableType].
///
/// Can also be used to ask for all the types declared in a [Library].
///
/// Available in the declaration and definition phases.
abstract interface class TypeIntrospector {
  /// The values available for [enuum].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [enuum].
  Future<List<EnumValueDeclaration>> valuesOf(
      covariant IntrospectableEnum enuum);

  /// The fields available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<FieldDeclaration>> fieldsOf(covariant IntrospectableType type);

  /// The methods available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<MethodDeclaration>> methodsOf(covariant IntrospectableType type);

  /// The constructors available for [type].
  ///
  /// This may be incomplete if additional declaration macros are going to run
  /// on [type].
  Future<List<ConstructorDeclaration>> constructorsOf(
      covariant IntrospectableType type);

  /// [TypeDeclaration]s for all the types declared in [library].
  ///
  /// In the declarations phase these will not be [IntrospectableType]s, since
  /// types are still incomplete at that point.
  ///
  /// In the definitions phase, these will be [IntrospectableType]s where
  /// appropriate (but, for instance, type aliases will not be).
  Future<List<TypeDeclaration>> typesOf(covariant Library library);
}

/// The interface used by [Macro]s to resolve any [Identifier]s pointing to
/// types to their type declarations.
///
/// Only available in the declaration and definition phases of macro expansion.
abstract interface class TypeDeclarationResolver {
  /// Resolves an [identifier] to its [TypeDeclaration].
  ///
  /// If [identifier] does not resolve to a [TypeDeclaration], then an
  /// [ArgumentError] is thrown.
  ///
  /// In the declaration phase, this will return [IntrospectableType] instances
  /// only for those types that are introspectable. Specifically, types are only
  /// introspectable if the macro is running on a class declaration, and the
  /// type appears in the type hierarchy of that class.
  ///
  /// In the definition phase, this will return [IntrospectableType] instances
  /// for all type definitions which can have members (ie: not type aliases).
  Future<TypeDeclaration> declarationOf(covariant Identifier identifier);
}

/// The API used by [Macro]s to contribute new (non-type)
/// declarations to the current library.
///
/// Can also be used to do subtype checks on types.
abstract interface class DeclarationBuilder
    implements
        Builder,
        IdentifierResolver,
        TypeIntrospector,
        TypeDeclarationResolver,
        TypeResolver {
  /// Adds a new regular declaration to the surrounding library.
  ///
  /// Note that type declarations are not supported.
  void declareInLibrary(DeclarationCode declaration);
}

/// The API used by [Macro]s to contribute new members to a type.
abstract interface class MemberDeclarationBuilder
    implements DeclarationBuilder {
  /// Adds a new declaration to the surrounding class.
  void declareInType(DeclarationCode declaration);
}

/// The API used by [Macro]s to contribute new members or values to an enum.
abstract interface class EnumDeclarationBuilder
    implements MemberDeclarationBuilder {
  /// Adds a new enum entry declaration to the surrounding enum.
  void declareEnumValue(DeclarationCode declaration);
}

/// The interface used by [Macro]s to get the inferred type for an
/// [OmittedTypeAnnotation].
///
/// Only available in the definition phase of macro expansion.
abstract interface class TypeInferrer {
  /// Infers a real type annotation for [omittedType].
  ///
  /// If no type could be inferred, then a type annotation representing the
  /// dynamic type will be given.
  Future<TypeAnnotation> inferType(covariant OmittedTypeAnnotation omittedType);
}

/// The interface used by [Macro]s to get the list of all declarations in a
/// [Library].
///
/// Only available in the definition phase of macro expansion.
abstract interface class LibraryDeclarationsResolver {
  /// Returns a list of all the [Declaration]s in the given [library].
  ///
  /// Where applicable, these will be introspectable declarations.
  Future<List<Declaration>> topLevelDeclarationsOf(covariant Library library);
}

/// The base class for builders in the definition phase. These can convert
/// any [TypeAnnotation] into its corresponding [TypeDeclaration], and also
/// reflect more deeply on those.
abstract interface class DefinitionBuilder
    implements
        Builder,
        IdentifierResolver,
        TypeIntrospector,
        TypeDeclarationResolver,
        TypeInferrer,
        TypeResolver,
        LibraryDeclarationsResolver {}

/// The APIs used by [Macro]s that run on type declarations, to fill in the
/// definitions of any declarations within that class.
abstract interface class TypeDefinitionBuilder implements DefinitionBuilder {
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

/// The APIs used by [Macro]s that run on enums, to fill in the
/// definitions of any declarations within that enum.
abstract interface class EnumDefinitionBuilder
    implements TypeDefinitionBuilder {
  /// Retrieve an [EnumValueDefinitionBuilder] for an entry with [identifier].
  ///
  /// Throws an [ArgumentError] if [identifier] does not refer to an entry on
  /// this enum.
  Future<EnumValueDefinitionBuilder> buildEnumValue(Identifier identifier);
}

/// The APIs used by [Macro]s to define the body of a constructor
/// or wrap the body of an existing constructor with additional statements.
abstract interface class ConstructorDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments an existing constructor body with [body] and [initializers].
  ///
  /// The [initializers] should not contain trailing or preceding commas.
  ///
  /// If [docComments] are supplied, they will be added above this augment
  /// declaration.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    FunctionBodyCode? body,
    List<Code>? initializers,
    CommentCode? docComments,
  });
}

/// The APIs used by [Macro]s to augment functions or methods.
abstract interface class FunctionDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the function.
  ///
  /// If [docComments] are supplied, they will be added above this augment
  /// declaration.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment(
    FunctionBodyCode body, {
    CommentCode? docComments,
  });
}

/// The API used by [Macro]s to augment a top level variable or instance field.
abstract interface class VariableDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the field.
  ///
  /// For [getter] and [setter] the full function declaration should be
  /// provided, minus the `augment` keyword (which will be implicitly added).
  ///
  /// If [initializerDocComments] are supplied, they will be added above the
  /// augment declaration for [initializer]. It is an error to provide
  /// [initializerDocComments] but not [initializer].
  ///
  /// To provide doc comments for [getter] or [setter], just include them in
  /// the [DeclarationCode] object for those.
  ///
  /// TODO: Link the library augmentations proposal to describe the semantics.
  void augment({
    DeclarationCode? getter,
    DeclarationCode? setter,
    ExpressionCode? initializer,
    CommentCode? initializerDocComments,
  });
}

/// The API used by [Macro]s to augment an enum entry.
abstract interface class EnumValueDefinitionBuilder
    implements DefinitionBuilder {
  /// Augments the entry by replacing it with a new one.
  ///
  /// The name of the produced [entry] must match the original name.
  void augment(DeclarationCode entry);
}
