// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';
import '../api.dart';

abstract class TypeAnnotationImpl extends RemoteInstance
    implements TypeAnnotation {
  final bool isNullable;

  TypeAnnotationImpl({required int id, required this.isNullable}) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer.addBool(isNullable);
  }
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
  final List<TypeAnnotationImpl> typeArguments;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.namedTypeAnnotation;

  NamedTypeAnnotationImpl({
    required int id,
    required bool isNullable,
    required this.name,
    required this.typeArguments,
  }) : super(id: id, isNullable: isNullable);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer.addString(name);
    serializer.startList();
    for (TypeAnnotationImpl typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
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
  final List<ParameterDeclarationImpl> namedParameters;

  @override
  final List<ParameterDeclarationImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionTypeAnnotation;

  FunctionTypeAnnotationImpl({
    required int id,
    required bool isNullable,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id: id, isNullable: isNullable);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    returnType.serialize(serializer);

    serializer.startList();
    for (ParameterDeclarationImpl param in positionalParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (ParameterDeclarationImpl param in namedParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (TypeParameterDeclarationImpl typeParam in typeParameters) {
      typeParam.serialize(serializer);
    }
    serializer.endList();
  }
}

abstract class DeclarationImpl extends RemoteInstance implements Declaration {
  DeclarationImpl(int id) : super(id);
  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer.addString(name);
  }
}

class ParameterDeclarationImpl extends DeclarationImpl
    implements ParameterDeclaration {
  @override
  final String name;

  @override
  final Code? defaultValue;

  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.parameterDeclaration;

  ParameterDeclarationImpl({
    required int id,
    required this.name,
    required this.defaultValue,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  }) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    if (defaultValue == null) {
      serializer.addNull();
    } else {
      defaultValue!.serialize(serializer);
    }
    serializer.addBool(isNamed);
    serializer.addBool(isRequired);
    type.serialize(serializer);
  }
}

class TypeParameterDeclarationImpl extends DeclarationImpl
    implements TypeParameterDeclaration {
  @override
  final String name;

  @override
  final TypeAnnotationImpl? bounds;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameterDeclaration;

  TypeParameterDeclarationImpl(
      {required int id, required this.name, required this.bounds})
      : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    TypeAnnotationImpl? bounds = this.bounds;
    if (bounds == null) {
      serializer.addNull();
    } else {
      bounds.serialize(serializer);
    }
  }
}

class FunctionDeclarationImpl extends DeclarationImpl
    implements FunctionDeclaration {
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
  final List<ParameterDeclarationImpl> namedParameters;

  @override
  final List<ParameterDeclarationImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionDeclaration;

  FunctionDeclarationImpl({
    required int id,
    required this.name,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer
      ..addBool(isAbstract)
      ..addBool(isExternal)
      ..addBool(isGetter)
      ..addBool(isSetter)
      ..startList();
    for (ParameterDeclarationImpl named in namedParameters) {
      named.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (ParameterDeclarationImpl positional in positionalParameters) {
      positional.serialize(serializer);
    }
    serializer.endList();
    returnType.serialize(serializer);
    serializer.startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}
