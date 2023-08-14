// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// The base class representing an arbitrary chunk of Dart code, which may or
/// may not be syntactically or semantically valid yet.
sealed class Code {
  /// All the chunks of [Code], raw [String]s, or [Identifier]s that
  /// comprise this [Code] object.
  final List<Object> parts;

  /// Can be used to more efficiently detect the kind of code, avoiding is
  /// checks and enabling switch statements.
  CodeKind get kind;

  Code.fromString(String code) : parts = [code];

  Code.fromParts(this.parts)
      : assert(parts.every((element) =>
            element is String || element is Code || element is Identifier));
}

/// An arbitrary chunk of code, which does not have to be syntactically valid
/// on its own. Useful to construct other types of code from several parts.
base class RawCode extends Code {
  @override
  CodeKind get kind => CodeKind.raw;

  RawCode.fromString(super.code) : super.fromString();

  RawCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid declaration.
base class DeclarationCode extends Code {
  @override
  CodeKind get kind => CodeKind.declaration;

  DeclarationCode.fromString(super.code) : super.fromString();

  DeclarationCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a code comment. This may contain identifier
/// references inside of `[]` brackets if the comments are doc comments.
base class CommentCode extends Code {
  @override
  CodeKind get kind => CodeKind.comment;

  CommentCode.fromString(super.code) : super.fromString();

  CommentCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid expression.
base class ExpressionCode extends Code {
  @override
  CodeKind get kind => CodeKind.expression;

  ExpressionCode.fromString(super.code) : super.fromString();

  ExpressionCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code representing a syntactically valid function body.
///
/// This includes any and all code after the parameter list of a function,
/// including modifiers like `async`.
///
/// Both arrow and block function bodies are allowed.
base class FunctionBodyCode extends Code {
  @override
  CodeKind get kind => CodeKind.functionBody;

  FunctionBodyCode.fromString(super.code) : super.fromString();

  FunctionBodyCode.fromParts(super.parts) : super.fromParts();
}

/// A piece of code identifying a syntactically valid function or function type
/// parameter.
///
/// There is no distinction here made between named and positional parameters.
///
/// There is also no distinction between function type parameters and normal
/// function parameters, so the [name] is nullable (it is not required for
/// positional function type parameters).
///
/// It is the job of the user to construct and combine these together in a way
/// that creates valid parameter lists.
base class ParameterCode implements Code {
  final Code? defaultValue;
  final List<String> keywords;
  final String? name;
  final TypeAnnotationCode? type;

  @override
  CodeKind get kind => CodeKind.parameter;

  @override
  List<Object> get parts => [
        if (keywords.isNotEmpty) ...[
          ...keywords.joinAsCode(' '),
          ' ',
        ],
        if (type != null) ...[
          type!,
          ' ',
        ],
        if (name != null) name!,
        if (defaultValue != null) ...[
          ' = ',
          defaultValue!,
        ]
      ];

  ParameterCode({
    this.defaultValue,
    this.keywords = const [],
    this.name,
    this.type,
  });
}

/// A piece of code representing a type annotation.
abstract class TypeAnnotationCode implements Code, TypeAnnotation {
  @override
  TypeAnnotationCode get code => this;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already non-nullable.
  TypeAnnotationCode get asNonNullable => this;

  /// Returns a [TypeAnnotationCode] object which is a non-nullable version
  /// of this one.
  ///
  /// Returns the current instance if it is already nullable.
  NullableTypeAnnotationCode get asNullable =>
      new NullableTypeAnnotationCode(this);

  /// Whether or not this type is nullable.
  @override
  bool get isNullable => false;
}

/// The nullable version of an underlying type annotation.
base class NullableTypeAnnotationCode implements TypeAnnotationCode {
  /// The underlying type that is being made nullable.
  TypeAnnotationCode underlyingType;

  @override
  TypeAnnotationCode get code => this;

  @override
  CodeKind get kind => CodeKind.nullableTypeAnnotation;

  @override
  List<Object> get parts => [...underlyingType.parts, '?'];

  /// Creates a nullable [underlyingType] annotation.
  ///
  /// If [underlyingType] is a NullableTypeAnnotationCode, returns that
  /// same type.
  NullableTypeAnnotationCode(this.underlyingType);

  @override
  TypeAnnotationCode get asNonNullable => underlyingType;

  @override
  NullableTypeAnnotationCode get asNullable => this;

  @override
  bool get isNullable => true;
}

/// A piece of code representing a reference to a named type.
base class NamedTypeAnnotationCode extends TypeAnnotationCode {
  final Identifier name;

  final List<TypeAnnotationCode> typeArguments;

  @override
  CodeKind get kind => CodeKind.namedTypeAnnotation;

  @override
  List<Object> get parts => [
        name,
        if (typeArguments.isNotEmpty) ...[
          '<',
          ...typeArguments.joinAsCode(', '),
          '>',
        ],
      ];

  NamedTypeAnnotationCode({required this.name, this.typeArguments = const []});
}

/// A piece of code representing a function type annotation.
base class FunctionTypeAnnotationCode extends TypeAnnotationCode {
  final List<ParameterCode> namedParameters;

  final List<ParameterCode> positionalParameters;

  final TypeAnnotationCode? returnType;

  final List<TypeParameterCode> typeParameters;

  @override
  CodeKind get kind => CodeKind.functionTypeAnnotation;

  @override
  List<Object> get parts => [
        if (returnType != null) returnType!,
        ' Function',
        if (typeParameters.isNotEmpty) ...[
          '<',
          ...typeParameters.joinAsCode(', '),
          '>',
        ],
        '(',
        for (ParameterCode positional in positionalParameters) ...[
          positional,
          ', ',
        ],
        if (namedParameters.isNotEmpty) ...[
          '{',
          for (ParameterCode named in namedParameters) ...[
            named,
            ', ',
          ],
          '}',
        ],
        ')',
      ];

  FunctionTypeAnnotationCode({
    this.namedParameters = const [],
    this.positionalParameters = const [],
    this.returnType,
    this.typeParameters = const [],
  });
}

/// A piece of code identifying a syntactically valid record field declaration.
/// This is only usable in the context of [RecordTypeAnnotationCode] objects.
///
/// There is no distinction here made between named and positional fields.
///
/// The name is not required because it is optional for positional fields.
///
/// It is the job of the user to construct and combine these together in a way
/// that creates valid record type annotations.
base class RecordFieldCode implements Code {
  final String? name;
  final TypeAnnotationCode type;

  @override
  CodeKind get kind => CodeKind.recordField;

  @override
  List<Object> get parts => [
        type,
        if (name != null) ' ${name!}',
      ];

  RecordFieldCode({
    this.name,
    required this.type,
  });
}

/// A piece of code representing a syntactically valid record type annotation.
base class RecordTypeAnnotationCode extends TypeAnnotationCode {
  final List<RecordFieldCode> namedFields;

  final List<RecordFieldCode> positionalFields;

  @override
  CodeKind get kind => CodeKind.recordTypeAnnotation;

  @override
  List<Object> get parts => [
        '(',
        if (positionalFields.isNotEmpty)
          for (RecordFieldCode positional in positionalFields) ...[
            if (positional != positionalFields.first) ', ',
            positional,
          ],
        if (namedFields.isNotEmpty) ...[
          if (positionalFields.isNotEmpty) ', ',
          '{',
          for (RecordFieldCode named in namedFields) ...[
            if (named != namedFields.first) ', ',
            named,
          ],
          '}',
        ],
        ')',
      ];

  RecordTypeAnnotationCode({
    this.namedFields = const [],
    this.positionalFields = const [],
  });
}

base class OmittedTypeAnnotationCode extends TypeAnnotationCode {
  final OmittedTypeAnnotation typeAnnotation;

  OmittedTypeAnnotationCode(this.typeAnnotation);

  @override
  CodeKind get kind => CodeKind.omittedTypeAnnotation;

  @override
  List<Object> get parts => [typeAnnotation];
}

/// A piece of code representing a valid named type parameter.
base class TypeParameterCode implements Code {
  final TypeAnnotationCode? bound;
  final String name;

  @override
  CodeKind get kind => CodeKind.typeParameter;

  @override
  List<Object> get parts => [
        name,
        if (bound != null) ...[
          ' extends ',
          bound!,
        ]
      ];

  TypeParameterCode({this.bound, required this.name});
}

extension Join<T extends Object> on List<T> {
  /// Joins all the items in [this] with [separator], and returns
  /// a new list.
  List<Object> joinAsCode(String separator) => [
        for (int i = 0; i < length - 1; i++) ...[
          this[i],
          separator,
        ],
        if (isNotEmpty) last,
      ];
}

enum CodeKind {
  comment,
  declaration,
  expression,
  functionBody,
  functionTypeAnnotation,
  namedTypeAnnotation,
  nullableTypeAnnotation,
  omittedTypeAnnotation,
  parameter,
  raw,
  recordField,
  recordTypeAnnotation,
  typeParameter,
}
