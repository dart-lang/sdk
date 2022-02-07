// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';
import '../api.dart';

class IdentifierImpl extends RemoteInstance implements Identifier {
  final String name;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.identifier;

  IdentifierImpl({required int id, required this.name}) : super(id);

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
        identifier,
        if (typeArguments.isNotEmpty) ...[
          '<',
          typeArguments.first.code,
          for (TypeAnnotation arg in typeArguments.skip(1)) ...[', ', arg.code],
          '>',
        ],
        if (isNullable) '?',
      ]);

  @override
  final IdentifierImpl identifier;

  @override
  final List<TypeAnnotationImpl> typeArguments;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.namedTypeAnnotation;

  NamedTypeAnnotationImpl({
    required int id,
    required bool isNullable,
    required this.identifier,
    required this.typeArguments,
  }) : super(id: id, isNullable: isNullable);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    identifier.serialize(serializer);
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
        returnType.code,
        'Function',
        if (typeParameters.isNotEmpty) ...[
          '<',
          typeParameters.first.identifier.name,
          if (typeParameters.first.bounds != null) ...[
            ' extends ',
            typeParameters.first.bounds!.code,
          ],
          for (TypeParameterDeclaration arg in typeParameters.skip(1)) ...[
            ', ',
            arg.identifier.name,
            if (arg.bounds != null) ...[' extends ', arg.bounds!.code],
          ],
          '>',
        ],
        '(',
        for (ParameterDeclaration positional in positionalParameters) ...[
          positional.type.code,
          ' ${positional.identifier.name}',
        ],
        if (namedParameters.isNotEmpty) ...[
          '{',
          for (ParameterDeclaration named in namedParameters) ...[
            named.type.code,
            ' ${named.identifier.name}',
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
  final IdentifierImpl identifier;

  DeclarationImpl({required int id, required this.identifier}) : super(id);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    identifier.serialize(serializer);
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
    required IdentifierImpl identifier,
    required this.defaultValue,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  }) : super(id: id, identifier: identifier);

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
    required IdentifierImpl identifier,
    required this.bounds,
  }) : super(id: id, identifier: identifier);

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
    required IdentifierImpl identifier,
    required this.isAbstract,
    required this.isExternal,
    required this.isGetter,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  }) : super(id: id, identifier: identifier);

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
  final IdentifierImpl definingClass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.methodDeclaration;

  MethodDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
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
          identifier: identifier,
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
    required IdentifierImpl identifier,
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
    required IdentifierImpl definingClass,
    // Constructor fields
    required this.isFactory,
  }) : super(
          id: id,
          identifier: identifier,
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
  final ExpressionCode? initializer;

  @override
  final bool isExternal;

  @override
  final bool isFinal;

  @override
  final bool isLate;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.variableDeclaration;

  VariableDeclarationImpl({
    required int id,
    required IdentifierImpl identifier,
    required this.initializer,
    required this.isExternal,
    required this.isFinal,
    required this.isLate,
    required this.type,
  }) : super(id: id, identifier: identifier);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    initializer.serializeNullable(serializer);
    serializer
      ..addBool(isExternal)
      ..addBool(isFinal)
      ..addBool(isLate);
    type.serialize(serializer);
  }
}

class FieldDeclarationImpl extends VariableDeclarationImpl
    implements FieldDeclaration {
  @override
  final IdentifierImpl definingClass;

  FieldDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // Variable fields
    required ExpressionCode? initializer,
    required bool isExternal,
    required bool isFinal,
    required bool isLate,
    required TypeAnnotationImpl type,
    // Field fields
    required this.definingClass,
  }) : super(
            id: id,
            identifier: identifier,
            initializer: initializer,
            isExternal: isExternal,
            isFinal: isFinal,
            isLate: isLate,
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
    required IdentifierImpl identifier,
    required this.typeParameters,
  }) : super(id: id, identifier: identifier);

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
    required IdentifierImpl identifier,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // ClassDeclaration fields
    required this.interfaces,
    required this.isAbstract,
    required this.isExternal,
    required this.mixins,
    required this.superclass,
  }) : super(id: id, identifier: identifier, typeParameters: typeParameters);

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
  /// The type being aliased.
  final TypeAnnotationImpl aliasedType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeAliasDeclaration;

  TypeAliasDeclarationImpl({
    // Declaration fields
    required int id,
    required IdentifierImpl identifier,
    // TypeDeclaration fields
    required List<TypeParameterDeclarationImpl> typeParameters,
    // TypeAlias fields
    required this.aliasedType,
  }) : super(id: id, identifier: identifier, typeParameters: typeParameters);

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    // Client side we don't encode anything but the ID.
    if (serializationMode == SerializationMode.client) {
      return;
    }

    aliasedType.serialize(serializer);
  }
}
