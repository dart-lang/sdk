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
          typeArguments.first,
          for (TypeAnnotation arg in typeArguments.skip(1)) ...[', ', arg],
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
          typeParameters.first.name,
          if (typeParameters.first.bounds != null) ...[
            ' extends ',
            typeParameters.first.bounds!
          ],
          for (TypeParameterDeclaration arg in typeParameters.skip(1)) ...[
            ', ',
            arg.name,
            if (arg.bounds != null) ...[' extends ', arg.bounds!],
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
  final String name;

  DeclarationImpl({required int id, required this.name}) : super(id);

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
    required String name,
    required this.defaultValue,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  }) : super(id: id, name: name);

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
  final TypeAnnotationImpl? bounds;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameterDeclaration;

  TypeParameterDeclarationImpl({
    required int id,
    required String name,
    required this.bounds,
  }) : super(id: id, name: name);

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
    required String name,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id: id, name: name);

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

class MethodDeclarationImpl extends FunctionDeclarationImpl
    implements MethodDeclaration {
  @override
  final TypeAnnotationImpl definingClass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.methodDeclaration;

  MethodDeclarationImpl({
    // Declaration fields
    required int id,
    required String name,
    // Function fields
    required bool isAbstract,
    required bool isExternal,
    required bool isGetter,
    required bool isSetter,
    required List<ParameterDeclarationImpl> namedParameters,
    required List<ParameterDeclarationImpl> positionalParameters,
    required TypeAnnotationImpl returnType,
    required List<TypeParameterDeclarationImpl> typeParameters,
    // Method fields
    required this.definingClass,
  }) : super(
          id: id,
          name: name,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isGetter: isGetter,
          isSetter: isSetter,
          namedParameters: namedParameters,
          positionalParameters: positionalParameters,
          returnType: returnType,
          typeParameters: typeParameters,
        );

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    definingClass.serialize(serializer);
  }
}

class ConstructorDeclarationImpl extends MethodDeclarationImpl
    implements ConstructorDeclaration {
  @override
  final bool isFactory;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.constructorDeclaration;

  ConstructorDeclarationImpl({
    // Declaration fields
    required int id,
    required String name,
    // Function fields
    required bool isAbstract,
    required bool isExternal,
    required bool isGetter,
    required bool isSetter,
    required List<ParameterDeclarationImpl> namedParameters,
    required List<ParameterDeclarationImpl> positionalParameters,
    required TypeAnnotationImpl returnType,
    required List<TypeParameterDeclarationImpl> typeParameters,
    // Method fields
    required TypeAnnotationImpl definingClass,
    // Constructor fields
    required this.isFactory,
  }) : super(
          id: id,
          name: name,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isGetter: isGetter,
          isSetter: isSetter,
          namedParameters: namedParameters,
          positionalParameters: positionalParameters,
          returnType: returnType,
          typeParameters: typeParameters,
          definingClass: definingClass,
        );

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer.addBool(isFactory);
  }
}

class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final Code? initializer;

  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.variableDeclaration;

  VariableDeclarationImpl({
    required int id,
    required String name,
    required this.initializer,
    required this.isAbstract,
    required this.isExternal,
    required this.type,
  }) : super(id: id, name: name);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    initializer.serializeNullable(serializer);
    serializer
      ..addBool(isAbstract)
      ..addBool(isExternal);
    type.serialize(serializer);
  }
}

class FieldDeclarationImpl extends VariableDeclarationImpl
    implements FieldDeclaration {
  @override
  final TypeAnnotationImpl definingClass;

  FieldDeclarationImpl({
    // Declaration fields
    required int id,
    required String name,
    // Variable fields
    required Code? initializer,
    required bool isAbstract,
    required bool isExternal,
    required TypeAnnotationImpl type,
    // Field fields
    required this.definingClass,
  }) : super(
            id: id,
            name: name,
            initializer: initializer,
            isAbstract: isAbstract,
            isExternal: isExternal,
            type: type);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.fieldDeclaration;

  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    definingClass.serialize(serializer);
  }
}

abstract class TypeDeclarationImpl extends DeclarationImpl
    implements TypeDeclaration {
  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  TypeDeclarationImpl({
    required int id,
    required String name,
    required this.typeParameters,
  }) : super(id: id, name: name);

  @override
  Future<StaticType> instantiate(
      {required List<StaticType> typeArguments, required bool isNullable}) {
    // TODO: implement instantiate
    throw new UnimplementedError('instantiate');
  }

  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer..startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}

class ClassDeclarationImpl extends TypeDeclarationImpl
    implements ClassDeclaration {
  @override
  final List<TypeAnnotationImpl> interfaces;

  @override
  final bool isAbstract;

  @override
  final bool isExternal;

  @override
  final List<TypeAnnotationImpl> mixins;

  @override
  final TypeAnnotationImpl? superclass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.classDeclaration;

  ClassDeclarationImpl({
    // Declaration fields
    required int id,
    required String name,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // ClassDeclaration fields
    required this.interfaces,
    required this.isAbstract,
    required this.isExternal,
    required this.mixins,
    required this.superclass,
  }) : super(id: id, name: name, typeParameters: typeParameters);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    serializer.startList();
    for (TypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..addBool(isAbstract)
      ..addBool(isExternal)
      ..startList();
    for (TypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer..endList();
    superclass.serializeNullable(serializer);
  }
}

class TypeAliasDeclarationImpl extends TypeDeclarationImpl
    implements TypeAliasDeclaration {
  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeAliasDeclaration;

  @override
  final TypeAnnotationImpl type;

  TypeAliasDeclarationImpl({
    // Declaration fields
    required int id,
    required String name,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // TypeAlias fields
    required this.type,
  }) : super(id: id, name: name, typeParameters: typeParameters);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    type.serialize(serializer);
  }
}
