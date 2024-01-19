// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The interface for classes that can be targeted by macros.
///
/// Could be a [Declaration] or [Library].
abstract interface class MacroTarget {}

/// The interface for things that can be annotated with [MetadataAnnotation]s.
abstract interface class Annotatable {
  Iterable<MetadataAnnotation> get metadata;
}

/// A concrete reference to a named declaration, which may or may not yet be
/// resolved.
///
/// These can be passed directly to [Code] objects, which will automatically do
/// any necessary prefixing when emitting references.
///
/// Identifier equality/identity is not specified. To check for type equality, a
/// [StaticType] should be used.
abstract interface class Identifier {
  String get name;
}

/// The interface for an unresolved reference to a type.
///
/// See the subtypes [FunctionTypeAnnotation] and [NamedTypeAnnotation].
abstract interface class TypeAnnotation {
  /// Whether or not the type annotation is explicitly nullable (contains a
  /// trailing `?`)
  bool get isNullable;

  /// A convenience method to get a [Code] object equivalent to this type
  /// annotation.
  TypeAnnotationCode get code;
}

/// The interface for function type declarations.
abstract interface class FunctionTypeAnnotation implements TypeAnnotation {
  /// The return type of this function.
  TypeAnnotation get returnType;

  /// The positional parameters for this function.
  Iterable<FunctionTypeParameter> get positionalParameters;

  /// The named parameters for this function.
  Iterable<FunctionTypeParameter> get namedParameters;

  /// The type parameters for this function.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// An unresolved reference to a type.
///
/// These can be resolved to a [TypeDeclaration] using the `builder` classes
/// depending on the phase a macro is running in.
abstract interface class NamedTypeAnnotation implements TypeAnnotation {
  /// An identifier pointing to this named type.
  Identifier get identifier;

  /// The type arguments, if applicable.
  Iterable<TypeAnnotation> get typeArguments;
}

/// The interface for record type declarations.
abstract interface class RecordTypeAnnotation implements TypeAnnotation {
  /// The positional fields for this record.
  Iterable<RecordFieldDeclaration> get positionalFields;

  /// The named fields for this record.
  Iterable<RecordFieldDeclaration> get namedFields;
}

/// An omitted type annotation.
///
/// This will be given whenever there is no explicit type annotation for a
/// declaration.
///
/// These type annotations can still produce valid [Code] objects, which will
/// result in the inferred type being emitted into the resulting code (or
/// dynamic).
///
/// In the definition phase, you may also ask explicitly for the inferred type
/// using the `inferType` API.
abstract interface class OmittedTypeAnnotation implements TypeAnnotation {}

/// The interface representing a resolved type.
///
/// Resolved types understand exactly what type they represent, and can be
/// compared to other static types.
abstract interface class StaticType {
  /// Returns true if this is a subtype of [other].
  Future<bool> isSubtypeOf(covariant StaticType other);

  /// Returns true if this is an identical type to [other].
  Future<bool> isExactly(covariant StaticType other);
}

/// A subtype of [StaticType] representing types that can be resolved by name
/// to a concrete declaration.
abstract interface class NamedStaticType implements StaticType {}

/// The interface for all declarations.
abstract interface class Declaration implements Annotatable, MacroTarget {
  /// The library in which this declaration is defined.
  Library get library;

  ///  An identifier pointing to this named declaration.
  Identifier get identifier;
}

/// Interface for all Declarations which are a member of a surrounding type
/// declaration.
abstract interface class MemberDeclaration implements Declaration {
  /// The type that defines this member.
  Identifier get definingType;

  /// Whether or not this is a static member.
  bool get isStatic;
}

/// Marker interface for a declaration that defines a new type in the program.
///
/// See [ParameterizedTypeDeclaration] and [TypeParameterDeclaration].
abstract interface class TypeDeclaration implements Declaration {}

/// A [TypeDeclaration] which may have type parameters.
///
/// See subtypes [ClassDeclaration], [EnumDeclaration], [MixinDeclaration], and
/// [TypeAliasDeclaration].
abstract interface class ParameterizedTypeDeclaration
    implements TypeDeclaration {
  /// The type parameters defined for this type declaration.
  Iterable<TypeParameterDeclaration> get typeParameters;
}

/// Class introspection information.
///
/// Information about fields, methods, and constructors must be retrieved from
/// the `builder` objects.
abstract interface class ClassDeclaration
    implements ParameterizedTypeDeclaration {
  /// Whether this class has an `abstract` modifier.
  bool get hasAbstract;

  /// Whether this class has a `base` modifier.
  bool get hasBase;

  /// Whether this class has an `external` modifier.
  bool get hasExternal;

  /// Whether this class has a `final` modifier.
  bool get hasFinal;

  /// Whether this class has an `interface` modifier.
  bool get hasInterface;

  /// Whether this class has a `mixin` modifier.
  bool get hasMixin;

  /// Whether this class has a `sealed` modifier.
  bool get hasSealed;

  /// The `extends` type annotation, if present.
  NamedTypeAnnotation? get superclass;

  /// All the `implements` type annotations.
  Iterable<NamedTypeAnnotation> get interfaces;

  /// All the `with` type annotations.
  Iterable<NamedTypeAnnotation> get mixins;
}

/// Enum introspection information.
///
/// Information about values, fields, methods, and constructors must be
/// retrieved from the `builder` objects.
abstract interface class EnumDeclaration
    implements ParameterizedTypeDeclaration {
  /// All the `implements` type annotations.
  Iterable<NamedTypeAnnotation> get interfaces;

  /// All the `with` type annotations.
  Iterable<NamedTypeAnnotation> get mixins;
}

/// Enum entry introspection information.
///
/// Note that enum values are not introspectable, because they can be augmented.
///
/// You can however do const evaluation of enum values, if they are not in a
/// library cycle with the current library.
abstract interface class EnumValueDeclaration implements Declaration {
  /// The enum that surrounds this entry.
  Identifier get definingEnum;
}

/// The class for introspecting on an extension.
///
/// Note that extensions do not actually introduce a new type, but we model them
/// as [ParameterizedTypeDeclaration]s anyway, because they generally look
/// exactly like other type declarations, and are treated the same.
abstract interface class ExtensionDeclaration
    implements ParameterizedTypeDeclaration, Declaration {
  /// The type that appears on the `on` clause of this extension.
  TypeAnnotation get onType;
}

/// The class for introspecting on an extension type.
abstract interface class ExtensionTypeDeclaration
    implements ParameterizedTypeDeclaration, Declaration {
  /// The representation type of this extension type.
  TypeAnnotation get representationType;
}

/// Mixin introspection information.
///
/// Information about fields and methods must be retrieved from the `builder`
/// objects.
abstract interface class MixinDeclaration
    implements ParameterizedTypeDeclaration {
  /// Whether this mixin has a `base` modifier.
  bool get hasBase;

  /// All the `implements` type annotations.
  Iterable<NamedTypeAnnotation> get interfaces;

  /// All the `on` clause type annotations.
  Iterable<NamedTypeAnnotation> get superclassConstraints;
}

/// Type alias introspection information.
abstract interface class TypeAliasDeclaration
    implements ParameterizedTypeDeclaration {
  /// The type annotation this is an alias for.
  TypeAnnotation get aliasedType;
}

/// Function introspection information.
abstract interface class FunctionDeclaration implements Declaration {
  /// Whether or not this function has a body.
  ///
  /// This is useful when augmenting a function, so you know whether an
  /// `augment super` call would be valid or not.
  ///
  /// Note that for external functions, this may return `false` even though
  /// there is actually a body that is filled in later by another tool.
  bool get hasBody;

  /// Whether this function has an `external` modifier.
  bool get hasExternal;

  /// Whether this function is an operator.
  bool get isOperator;

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
abstract interface class MethodDeclaration
    implements FunctionDeclaration, MemberDeclaration {}

/// Constructor introspection information.
abstract interface class ConstructorDeclaration implements MethodDeclaration {
  /// Whether or not this is a factory constructor.
  bool get isFactory;
}

/// Variable introspection information.
abstract interface class VariableDeclaration implements Declaration {
  /// Whether this variable has an `external` modifier.
  bool get hasExternal;

  /// Whether this variable has a `final` modifier.
  bool get hasFinal;

  /// Whether this variable has a `late` modifier.
  bool get hasLate;

  /// The type of this field.
  TypeAnnotation get type;
}

/// Field introspection information.
abstract interface class FieldDeclaration
    implements VariableDeclaration, MemberDeclaration {
  /// Whether this field has an `abstract` modifier.
  bool get hasAbstract;
}

/// General parameter introspection information, see the subtypes
/// [FunctionTypeParameter] and [ParameterDeclaration].
abstract interface class Parameter implements Annotatable {
  /// The type of this parameter.
  TypeAnnotation get type;

  /// Whether or not this is a named parameter.
  bool get isNamed;

  /// Whether or not this parameter is either a non-optional positional
  /// parameter or an optional parameter with the `required` keyword.
  bool get isRequired;

  /// A convenience method to get a `code` object equivalent to this parameter.
  ///
  /// Note that the original default value will not be included, as it is not a
  /// part of this API.
  ParameterCode get code;
}

/// Parameters of normal functions/methods, which always have an identifier.
abstract interface class ParameterDeclaration
    implements Parameter, Declaration {}

/// Function type parameters don't always have names, and it is never useful to
/// get an [Identifier] for them, so they do not implement [Declaration] and
/// instead have an optional name.
abstract interface class FunctionTypeParameter implements Parameter {
  String? get name;
}

/// Generic type parameter introspection information.
abstract interface class TypeParameterDeclaration implements TypeDeclaration {
  /// The bound for this type parameter, if it has any.
  TypeAnnotation? get bound;

  /// A convenience method to get a `code` object equivalent to this type
  /// parameter.
  TypeParameterCode get code;
}

/// Introspection information for a field declaration on a Record type.
///
/// Note that for positional fields the [identifier] will be the synthesized
/// one (`$1` etc), while for named fields it will be the declared name.
abstract interface class RecordFieldDeclaration implements Declaration {
  /// A convenience method to get a `code` object equivalent to this field
  /// declaration.
  RecordFieldCode get code;

  /// Record fields don't always have names (if they are positional).
  ///
  /// If you want to reference the getter for a field, you should use
  /// [identifier] instead.
  String? get name;

  /// The type of this field.
  TypeAnnotation get type;
}

/// Introspection information for a Library.
abstract interface class Library implements Annotatable, MacroTarget {
  /// The language version of this library.
  LanguageVersion get languageVersion;

  /// The uri identifying this library.
  Uri get uri;
}

/// The language version of a library, see
/// https://dart.dev/guides/language/evolution#language-version-numbers.
abstract interface class LanguageVersion {
  int get major;

  int get minor;
}

/// A metadata annotation on a declaration or library directive.
abstract interface class MetadataAnnotation {}

/// A [MetadataAnnotation] which is a reference to a const value.
abstract interface class IdentifierMetadataAnnotation
    implements MetadataAnnotation {
  /// The [Identifier] for the const reference.
  Identifier get identifier;
}

/// A [Metadata] annotation which is a constructor call.
abstract interface class ConstructorMetadataAnnotation
    implements MetadataAnnotation {
  /// And [Identifier] referring to the type that is being constructed.
  Identifier get type;

  /// An [Identifier] referring to the specific constructor being called.
  ///
  /// For unnamed constructors, the name of this identifier will be the empty
  /// String.
  Identifier get constructor;

  /// The positional arguments of this constructor call.
  Iterable<ExpressionCode> get positionalArguments;

  /// The named arguments of this constructor call.
  Map<String, ExpressionCode> get namedArguments;
}
