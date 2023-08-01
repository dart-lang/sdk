// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'remote_instance.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';
import '../api.dart';

class IdentifierImpl extends RemoteInstance implements Identifier {
  @override
  final String name;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.identifier;

  IdentifierImpl({required int id, required this.name}) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addString(name);
  }

  @override
  bool operator ==(Object other) => other is IdentifierImpl && other.id == id;

  @override
  int get hashCode => id;
}

abstract class TypeAnnotationImpl extends RemoteInstance
    implements TypeAnnotation {
  @override
  final bool isNullable;

  TypeAnnotationImpl({required int id, required this.isNullable}) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addBool(isNullable);
  }
}

class NamedTypeAnnotationImpl extends TypeAnnotationImpl
    implements NamedTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    NamedTypeAnnotationCode underlyingType =
        new NamedTypeAnnotationCode(name: identifier, typeArguments: [
      for (TypeAnnotation typeArg in typeArguments) typeArg.code,
    ]);
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final IdentifierImpl identifier;

  @override
  final List<TypeAnnotationImpl> typeArguments;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.namedTypeAnnotation;

  NamedTypeAnnotationImpl({
    required super.id,
    required super.isNullable,
    required this.identifier,
    required this.typeArguments,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
    serializer.startList();
    for (TypeAnnotationImpl typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
}

class RecordTypeAnnotationImpl extends TypeAnnotationImpl
    implements RecordTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    RecordTypeAnnotationCode underlyingType = new RecordTypeAnnotationCode(
      namedFields: [
        for (RecordFieldDeclarationImpl field in namedFields) field.code
      ],
      positionalFields: [
        for (RecordFieldDeclarationImpl field in positionalFields) field.code
      ],
    );
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final List<RecordFieldDeclarationImpl> namedFields;

  @override
  final List<RecordFieldDeclarationImpl> positionalFields;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.recordTypeAnnotation;

  RecordTypeAnnotationImpl({
    required super.id,
    required super.isNullable,
    required this.namedFields,
    required this.positionalFields,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (RecordFieldDeclarationImpl field in namedFields) {
      field.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (RecordFieldDeclarationImpl field in positionalFields) {
      field.serialize(serializer);
    }
    serializer.endList();
  }
}

// TODO: Currently the `name` is duplicated (if present) in both the
// `identifier` and the `name` fields, because for positional fields they will
// not be the same. We could optimize it to read the name from the `identifier`
// field for named record fields though.
class RecordFieldDeclarationImpl extends DeclarationImpl
    implements RecordFieldDeclaration {
  @override
  RecordFieldCode get code {
    return new RecordFieldCode(type: type.code, name: name);
  }

  @override
  final String? name;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.recordFieldDeclaration;

  RecordFieldDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.name,
    required this.type,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addNullableString(name);
    type.serialize(serializer);
  }
}

class FunctionTypeAnnotationImpl extends TypeAnnotationImpl
    implements FunctionTypeAnnotation {
  @override
  TypeAnnotationCode get code {
    FunctionTypeAnnotationCode underlyingType = new FunctionTypeAnnotationCode(
      returnType: returnType.code,
      typeParameters: [
        for (TypeParameterDeclaration typeParam in typeParameters)
          typeParam.code,
      ],
      positionalParameters: [
        for (FunctionTypeParameter positional in positionalParameters)
          positional.code,
      ],
      namedParameters: [
        for (FunctionTypeParameter named in namedParameters) named.code,
      ],
    );
    return isNullable ? underlyingType.asNullable : underlyingType;
  }

  @override
  final List<FunctionTypeParameterImpl> namedParameters;

  @override
  final List<FunctionTypeParameterImpl> positionalParameters;

  @override
  final TypeAnnotationImpl returnType;

  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionTypeAnnotation;

  FunctionTypeAnnotationImpl({
    required super.id,
    required super.isNullable,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    returnType.serialize(serializer);

    serializer.startList();
    for (FunctionTypeParameterImpl param in positionalParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (FunctionTypeParameterImpl param in namedParameters) {
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

class OmittedTypeAnnotationImpl extends TypeAnnotationImpl
    implements OmittedTypeAnnotation {
  OmittedTypeAnnotationImpl({required super.id}) : super(isNullable: false);

  @override
  TypeAnnotationCode get code => new OmittedTypeAnnotationCode(this);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.omittedTypeAnnotation;
}

abstract class MetadataAnnotationImpl extends RemoteInstance
    implements MetadataAnnotation {
  MetadataAnnotationImpl(super.id);
}

class IdentifierMetadataAnnotationImpl extends MetadataAnnotationImpl
    implements IdentifierMetadataAnnotation {
  @override
  final IdentifierImpl identifier;

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.identifierMetadataAnnotation;

  IdentifierMetadataAnnotationImpl({required int id, required this.identifier})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
  }
}

class ConstructorMetadataAnnotationImpl extends MetadataAnnotationImpl
    implements ConstructorMetadataAnnotation {
  @override
  final IdentifierImpl constructor;

  @override
  final IdentifierImpl type;

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.constructorMetadataAnnotation;

  ConstructorMetadataAnnotationImpl(
      {required int id, required this.constructor, required this.type})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    constructor.serialize(serializer);
    type.serialize(serializer);
  }
}

abstract class DeclarationImpl extends RemoteInstance implements Declaration {
  @override
  final IdentifierImpl identifier;

  @override
  final LibraryImpl library;

  @override
  final List<MetadataAnnotationImpl> metadata;

  DeclarationImpl({
    required int id,
    required this.identifier,
    required this.library,
    required this.metadata,
  }) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    identifier.serialize(serializer);
    library.serialize(serializer);
    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
  }
}

class ParameterDeclarationImpl extends DeclarationImpl
    implements ParameterDeclaration {
  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.parameterDeclaration;

  ParameterDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.isNamed,
    required this.isRequired,
    required this.type,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addBool(isNamed);
    serializer.addBool(isRequired);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      new ParameterCode(name: identifier.name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class FunctionTypeParameterImpl extends RemoteInstance
    implements FunctionTypeParameter {
  @override
  final bool isNamed;

  @override
  final bool isRequired;

  @override
  final List<MetadataAnnotationImpl> metadata;

  @override
  final String? name;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.functionTypeParameter;

  FunctionTypeParameterImpl({
    required int id,
    required this.isNamed,
    required this.isRequired,
    required this.metadata,
    required this.name,
    required this.type,
  }) : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addBool(isNamed);
    serializer.addBool(isRequired);

    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
    serializer.addNullableString(name);
    type.serialize(serializer);
  }

  @override
  ParameterCode get code =>
      new ParameterCode(name: name, type: type.code, keywords: [
        if (isNamed && isRequired) 'required',
      ]);
}

class TypeParameterDeclarationImpl extends DeclarationImpl
    implements TypeParameterDeclaration {
  @override
  final TypeAnnotationImpl? bound;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeParameterDeclaration;

  TypeParameterDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.bound,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    TypeAnnotationImpl? bound = this.bound;
    if (bound == null) {
      serializer.addNull();
    } else {
      bound.serialize(serializer);
    }
  }

  @override
  TypeParameterCode get code =>
      new TypeParameterCode(name: identifier.name, bound: bound?.code);
}

class FunctionDeclarationImpl extends DeclarationImpl
    implements FunctionDeclaration {
  @override
  final bool hasAbstract;

  @override
  final bool hasBody;

  @override
  final bool hasExternal;

  @override
  final bool isGetter;

  @override
  final bool isOperator;

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
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.hasAbstract,
    required this.hasBody,
    required this.hasExternal,
    required this.isGetter,
    required this.isOperator,
    required this.isSetter,
    required this.namedParameters,
    required this.positionalParameters,
    required this.returnType,
    required this.typeParameters,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer
      ..addBool(hasAbstract)
      ..addBool(hasBody)
      ..addBool(hasExternal)
      ..addBool(isGetter)
      ..addBool(isOperator)
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
  final IdentifierImpl definingType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.methodDeclaration;

  @override
  final bool isStatic;

  MethodDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.hasAbstract,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required this.definingType,
    required this.isStatic,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    definingType.serialize(serializer);
    serializer.addBool(isStatic);
  }
}

class ConstructorDeclarationImpl extends MethodDeclarationImpl
    implements ConstructorDeclaration {
  @override
  final bool isFactory;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.constructorDeclaration;

  ConstructorDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Function fields.
    required super.hasAbstract,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    // Method fields.
    required super.definingType,
    // Constructor fields.
    required this.isFactory,
  }) : super(
          isStatic: true,
        );

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.addBool(isFactory);
  }
}

class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final bool hasExternal;

  @override
  final bool hasFinal;

  @override
  final bool hasLate;

  @override
  final TypeAnnotationImpl type;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.variableDeclaration;

  VariableDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.hasExternal,
    required this.hasFinal,
    required this.hasLate,
    required this.type,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer
      ..addBool(hasExternal)
      ..addBool(hasFinal)
      ..addBool(hasLate);
    type.serialize(serializer);
  }
}

class FieldDeclarationImpl extends VariableDeclarationImpl
    implements FieldDeclaration {
  @override
  final IdentifierImpl definingType;

  @override
  final bool isStatic;

  FieldDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // Variable fields.
    required super.hasExternal,
    required super.hasFinal,
    required super.hasLate,
    required super.type,
    // Field fields.
    required this.definingType,
    required this.isStatic,
  });

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.fieldDeclaration;

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    definingType.serialize(serializer);
    serializer.addBool(isStatic);
  }
}

abstract interface class TypeDeclarationImpl
    implements DeclarationImpl, TypeDeclaration {}

abstract class ParameterizedTypeDeclarationImpl extends DeclarationImpl
    implements ParameterizedTypeDeclaration, TypeDeclarationImpl {
  @override
  final List<TypeParameterDeclarationImpl> typeParameters;

  ParameterizedTypeDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.typeParameters,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer..startList();
    for (TypeParameterDeclarationImpl param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
  }
}

mixin _IntrospectableClass on ClassDeclarationImpl
    implements IntrospectableClassDeclaration {
  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.introspectableClassDeclaration;
}

class IntrospectableClassDeclarationImpl = ClassDeclarationImpl
    with _IntrospectableClass;

class ClassDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ClassDeclaration {
  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final bool hasAbstract;

  @override
  final bool hasBase;

  @override
  final bool hasExternal;

  @override
  final bool hasFinal;

  @override
  final bool hasInterface;

  @override
  final bool hasMixin;

  @override
  final bool hasSealed;

  @override
  final List<NamedTypeAnnotationImpl> mixins;

  @override
  final NamedTypeAnnotationImpl? superclass;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.classDeclaration;

  ClassDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // ClassDeclaration fields.
    required this.interfaces,
    required this.hasAbstract,
    required this.hasBase,
    required this.hasExternal,
    required this.hasFinal,
    required this.hasInterface,
    required this.hasMixin,
    required this.hasSealed,
    required this.mixins,
    required this.superclass,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..addBool(hasAbstract)
      ..addBool(hasBase)
      ..addBool(hasExternal)
      ..addBool(hasFinal)
      ..addBool(hasInterface)
      ..addBool(hasMixin)
      ..addBool(hasSealed)
      ..startList();
    for (NamedTypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer..endList();
    superclass.serializeNullable(serializer);
  }
}

mixin _IntrospectableEnum on EnumDeclarationImpl
    implements IntrospectableEnumDeclaration {
  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.introspectableEnumDeclaration;
}

class IntrospectableEnumDeclarationImpl = EnumDeclarationImpl
    with _IntrospectableEnum;

class EnumDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements EnumDeclaration {
  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final List<NamedTypeAnnotationImpl> mixins;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.enumDeclaration;

  EnumDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // EnumDeclaration fields.
    required this.interfaces,
    required this.mixins,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer.startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (NamedTypeAnnotationImpl mixin in mixins) {
      mixin.serialize(serializer);
    }
    serializer..endList();
  }
}

class EnumValueDeclarationImpl extends DeclarationImpl
    implements EnumValueDeclaration {
  @override
  final IdentifierImpl definingEnum;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.enumValueDeclaration;

  EnumValueDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required this.definingEnum,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    definingEnum.serialize(serializer);
  }
}

mixin _IntrospectableExtension on ExtensionDeclarationImpl
    implements IntrospectableType, IntrospectableExtensionDeclaration {
  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.introspectableExtensionDeclaration;
}

class IntrospectableExtensionDeclarationImpl = ExtensionDeclarationImpl
    with _IntrospectableExtension;

class ExtensionDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements ExtensionDeclaration {
  @override
  final TypeAnnotationImpl onType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.extensionDeclaration;

  ExtensionDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // ParameterizedTypeDeclaration fields.
    required super.typeParameters,
    // ExtensionDeclaration fields.
    required this.onType,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    onType.serialize(serializer);
  }
}

mixin _IntrospectableMixin on MixinDeclarationImpl
    implements IntrospectableMixinDeclaration {
  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.introspectableMixinDeclaration;
}

class IntrospectableMixinDeclarationImpl = MixinDeclarationImpl
    with _IntrospectableMixin;

class MixinDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements MixinDeclaration {
  @override
  final bool hasBase;

  @override
  final List<NamedTypeAnnotationImpl> interfaces;

  @override
  final List<NamedTypeAnnotationImpl> superclassConstraints;

  @override
  RemoteInstanceKind get kind => this is IntrospectableMixinDeclaration
      ? RemoteInstanceKind.introspectableMixinDeclaration
      : RemoteInstanceKind.mixinDeclaration;

  MixinDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // MixinDeclaration fields.
    required this.hasBase,
    required this.interfaces,
    required this.superclassConstraints,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    serializer
      ..addBool(hasBase)
      ..startList();
    for (NamedTypeAnnotationImpl interface in interfaces) {
      interface.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (NamedTypeAnnotationImpl constraint in superclassConstraints) {
      constraint.serialize(serializer);
    }
    serializer..endList();
  }
}

class TypeAliasDeclarationImpl extends ParameterizedTypeDeclarationImpl
    implements TypeAliasDeclaration {
  /// The type being aliased.
  @override
  final TypeAnnotationImpl aliasedType;

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.typeAliasDeclaration;

  TypeAliasDeclarationImpl({
    // Declaration fields.
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    // TypeDeclaration fields.
    required super.typeParameters,
    // TypeAlias fields.
    required this.aliasedType,
  });

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    aliasedType.serialize(serializer);
  }
}

class LibraryImpl extends RemoteInstance implements Library {
  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.library;

  @override
  final LanguageVersionImpl languageVersion;

  @override
  final List<MetadataAnnotationImpl> metadata;

  @override
  final Uri uri;

  LibraryImpl(
      {required int id,
      required this.languageVersion,
      required this.metadata,
      required this.uri})
      : super(id);

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);

    languageVersion.serialize(serializer);
    serializer.startList();
    for (MetadataAnnotationImpl annotation in metadata) {
      annotation.serialize(serializer);
    }
    serializer.endList();
    serializer.addUri(uri);
  }
}

/// This class doesn't implement [RemoteInstance] as it is always attached to a
/// [Library] and doesn't need its own kind or ID.
class LanguageVersionImpl implements LanguageVersion, Serializable {
  @override
  final int major;

  @override
  final int minor;

  LanguageVersionImpl(this.major, this.minor);

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(major)
      ..addInt(minor);
  }
}
