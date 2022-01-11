// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';

abstract class TypeAnnotationImpl implements TypeAnnotation {
  final bool isNullable;

  TypeAnnotationImpl({required this.isNullable});
}

class NamedTypeAnnotationImpl extends TypeAnnotationImpl
    implements NamedTypeAnnotation {
  @override
  Code get code => new Code.fromParts([
        name,
        if (typeArguments.isNotEmpty) ...[
          '<',
          for (TypeAnnotation arg in typeArguments) ...[arg, ','],
          '>',
        ],
        if (isNullable) '?',
      ]);

  @override
  final String name;

  @override
  final List<TypeAnnotation> typeArguments;

  @override
  TypeAnnotationKind get kind => TypeAnnotationKind.namedType;

  NamedTypeAnnotationImpl({
    required bool isNullable,
    required this.name,
    required this.typeArguments,
  }) : super(isNullable: isNullable);
}

class FunctionTypeAnnotationImpl extends TypeAnnotationImpl
    implements FunctionTypeAnnotation {
  @override
  Code get code => new Code.fromParts([
        returnType,
        'Function',
        if (typeParameters.isNotEmpty) ...[
          '<',
          for (TypeParameterDeclaration arg in typeParameters) ...[
            arg.name,
            if (arg.bounds != null) ...[' extends ', arg.bounds!],
            ','
          ],
          '>',
        ],
        '(',
        for (ParameterDeclaration positional in positionalParameters) ...[
          positional.type,
          ' ${positional.name}',
        ],
        if (namedParameters.isNotEmpty) ...[
          '{',
          for (ParameterDeclaration named in namedParameters) ...[
            named.type,
            ' ${named.name}',
          ],
          '}',
        ],
        ')',
        if (isNullable) '?',
      ]);

  @override
  final List<ParameterDeclaration> namedParameters;

  @override
  final List<ParameterDeclaration> positionalParameters;

  @override
  final TypeAnnotation returnType;

  @override
  final List<TypeParameterDeclaration> typeParameters;

  @override
  TypeAnnotationKind get kind => TypeAnnotationKind.functionType;

  FunctionTypeAnnotationImpl({
    required bool isNullable,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(isNullable: isNullable);
}

class ParameterDeclarationImpl implements ParameterDeclaration {
  @override
  final String name;

  @override
  final Code? defaultValue;

  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final TypeAnnotation type;

  @override
  DeclarationKind get kind => DeclarationKind.parameter;

  ParameterDeclarationImpl({
    required this.name,
    required this.defaultValue,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  });
}

class TypeParameterDeclarationImpl implements TypeParameterDeclaration {
  @override
  final String name;

  @override
  final TypeAnnotation? bounds;

  @override
  DeclarationKind get kind => DeclarationKind.typeParameter;

  TypeParameterDeclarationImpl({required this.name, required this.bounds});
}

class FunctionDeclarationImpl implements FunctionDeclaration {
  @override
  final String name;

  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final bool isGetter;

  @override
  final bool isSetter;

  @override
  final List<ParameterDeclaration> namedParameters;

  @override
  final List<ParameterDeclaration> positionalParameters;

  @override
  final TypeAnnotation returnType;

  @override
  final List<TypeParameterDeclaration> typeParameters;

  @override
  DeclarationKind get kind => DeclarationKind.function;

  FunctionDeclarationImpl({
    required this.name,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });
}
