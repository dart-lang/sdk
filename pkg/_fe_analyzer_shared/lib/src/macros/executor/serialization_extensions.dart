import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';

import 'remote_instance.dart';
import 'serialization.dart';
import '../api.dart';

extension DeserializerExtensions on Deserializer {
  T expectRemoteInstance<T>() {
    int id = expectInt();

    // Server side we just return the cached remote instance by ID.
    if (!serializationMode.isClient) {
      return RemoteInstance.cached(id) as T;
    }

    moveNext();
    RemoteInstanceKind kind = RemoteInstanceKind.values[expectInt()];
    return switch (kind) {
      RemoteInstanceKind.typeIntrospector ||
      RemoteInstanceKind.identifierResolver ||
      RemoteInstanceKind.namedStaticType ||
      RemoteInstanceKind.staticType ||
      RemoteInstanceKind.typeDeclarationResolver ||
      RemoteInstanceKind.typeResolver ||
      RemoteInstanceKind.typeInferrer =>
        // These are simple wrappers, just pass in the kind
        new RemoteInstanceImpl(id: id, kind: kind) as T,
      RemoteInstanceKind.classDeclaration =>
        (this..moveNext())._expectClassDeclaration(id) as T,
      RemoteInstanceKind.enumDeclaration =>
        (this..moveNext())._expectEnumDeclaration(id) as T,
      RemoteInstanceKind.enumValueDeclaration =>
        (this..moveNext())._expectEnumValueDeclaration(id) as T,
      RemoteInstanceKind.mixinDeclaration =>
        (this..moveNext())._expectMixinDeclaration(id) as T,
      RemoteInstanceKind.constructorDeclaration =>
        (this..moveNext())._expectConstructorDeclaration(id) as T,
      RemoteInstanceKind.fieldDeclaration =>
        (this..moveNext())._expectFieldDeclaration(id) as T,
      RemoteInstanceKind.functionDeclaration =>
        (this..moveNext())._expectFunctionDeclaration(id) as T,
      RemoteInstanceKind.functionTypeAnnotation =>
        (this..moveNext())._expectFunctionTypeAnnotation(id) as T,
      RemoteInstanceKind.functionTypeParameter =>
        (this..moveNext())._expectFunctionTypeParameter(id) as T,
      RemoteInstanceKind.identifier =>
        (this..moveNext())._expectIdentifier(id) as T,
      RemoteInstanceKind.introspectableClassDeclaration =>
        (this..moveNext())._expectIntrospectableClassDeclaration(id) as T,
      RemoteInstanceKind.introspectableEnumDeclaration =>
        (this..moveNext())._expectIntrospectableEnumDeclaration(id) as T,
      RemoteInstanceKind.introspectableMixinDeclaration =>
        (this..moveNext())._expectIntrospectableMixinDeclaration(id) as T,
      RemoteInstanceKind.methodDeclaration =>
        (this..moveNext())._expectMethodDeclaration(id) as T,
      RemoteInstanceKind.namedTypeAnnotation =>
        (this..moveNext())._expectNamedTypeAnnotation(id) as T,
      RemoteInstanceKind.omittedTypeAnnotation =>
        (this..moveNext())._expectOmittedTypeAnnotation(id) as T,
      RemoteInstanceKind.parameterDeclaration =>
        (this..moveNext())._expectParameterDeclaration(id) as T,
      RemoteInstanceKind.recordFieldDeclaration =>
        (this..moveNext())._expectRecordFieldDeclaration(id) as T,
      RemoteInstanceKind.recordTypeAnnotation =>
        (this..moveNext())._expectRecordTypeAnnotation(id) as T,
      RemoteInstanceKind.typeAliasDeclaration =>
        (this..moveNext())._expectTypeAliasDeclaration(id) as T,
      RemoteInstanceKind.typeParameterDeclaration =>
        (this..moveNext())._expectTypeParameterDeclaration(id) as T,
      RemoteInstanceKind.variableDeclaration =>
        (this..moveNext())._expectVariableDeclaration(id) as T,
    };
  }

  Uri expectUri() => Uri.parse(expectString());

  /// Helper method to read a list of [RemoteInstance]s.
  List<T> _expectRemoteInstanceList<T extends RemoteInstance>() {
    expectList();
    return [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];
  }

  NamedTypeAnnotation _expectNamedTypeAnnotation(int id) =>
      new NamedTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        identifier: RemoteInstance.deserialize(this),
        typeArguments: (this..moveNext())._expectRemoteInstanceList(),
      );

  OmittedTypeAnnotation _expectOmittedTypeAnnotation(int id) {
    expectBool(); // Always `false`.
    return new OmittedTypeAnnotationImpl(
      id: id,
    );
  }

  FunctionTypeAnnotation _expectFunctionTypeAnnotation(int id) =>
      new FunctionTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        returnType: RemoteInstance.deserialize(this),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  FunctionTypeParameter _expectFunctionTypeParameter(int id) =>
      new FunctionTypeParameterImpl(
        id: id,
        isNamed: expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        name: (this..moveNext()).expectNullableString(),
        type: RemoteInstance.deserialize(this),
      );

  Identifier _expectIdentifier(int id) => new IdentifierImpl(
        id: id,
        name: expectString(),
      );

  ParameterDeclaration _expectParameterDeclaration(int id) =>
      new ParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isNamed: (this..moveNext()).expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  RecordFieldDeclaration _expectRecordFieldDeclaration(int id) =>
      new RecordFieldDeclarationImpl(
          id: id,
          identifier: expectRemoteInstance(),
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectRemoteInstance());

  RecordTypeAnnotation _expectRecordTypeAnnotation(int id) =>
      new RecordTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        namedFields: (this..moveNext())._expectRemoteInstanceList(),
        positionalFields: (this..moveNext())._expectRemoteInstanceList(),
      );

  TypeParameterDeclaration _expectTypeParameterDeclaration(int id) =>
      new TypeParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        bound: (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  FunctionDeclaration _expectFunctionDeclaration(int id) =>
      new FunctionDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  MethodDeclaration _expectMethodDeclaration(int id) =>
      new MethodDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingType: RemoteInstance.deserialize(this),
        isStatic: (this..moveNext()).expectBool(),
      );

  ConstructorDeclaration _expectConstructorDeclaration(int id) =>
      new ConstructorDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isOperator: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingType: RemoteInstance.deserialize(this),
        // There is an extra boolean here representing the `isStatic` field
        // which we just skip past.
        isFactory: (this
              ..moveNext()
              ..expectBool()
              ..moveNext())
            .expectBool(),
      );

  VariableDeclaration _expectVariableDeclaration(int id) =>
      new VariableDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  FieldDeclaration _expectFieldDeclaration(int id) => new FieldDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
        definingType: RemoteInstance.deserialize(this),
        isStatic: (this..moveNext()).expectBool(),
      );

  ClassDeclaration _expectClassDeclaration(int id) => new ClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        hasAbstract: (this..moveNext()).expectBool(),
        hasBase: (this..moveNext()).expectBool(),
        hasExternal: (this..moveNext()).expectBool(),
        hasFinal: (this..moveNext()).expectBool(),
        hasInterface: (this..moveNext()).expectBool(),
        hasMixin: (this..moveNext()).expectBool(),
        hasSealed: (this..moveNext()).expectBool(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  IntrospectableClassDeclaration _expectIntrospectableClassDeclaration(
          int id) =>
      new IntrospectableClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        hasAbstract: (this..moveNext()).expectBool(),
        hasBase: (this..moveNext()).expectBool(),
        hasExternal: (this..moveNext()).expectBool(),
        hasFinal: (this..moveNext()).expectBool(),
        hasInterface: (this..moveNext()).expectBool(),
        hasMixin: (this..moveNext()).expectBool(),
        hasSealed: (this..moveNext()).expectBool(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  EnumDeclaration _expectEnumDeclaration(int id) => new EnumDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
      );

  IntrospectableEnumDeclaration _expectIntrospectableEnumDeclaration(int id) =>
      new IntrospectableEnumDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
      );

  MixinDeclaration _expectMixinDeclaration(int id) => new MixinDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        hasBase: (this..moveNext()).expectBool(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        superclassConstraints: (this..moveNext())._expectRemoteInstanceList(),
      );

  IntrospectableMixinDeclaration _expectIntrospectableMixinDeclaration(
          int id) =>
      new IntrospectableMixinDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        hasBase: (this..moveNext()).expectBool(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        superclassConstraints: (this..moveNext())._expectRemoteInstanceList(),
      );

  EnumValueDeclaration _expectEnumValueDeclaration(int id) =>
      new EnumValueDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        definingEnum: RemoteInstance.deserialize(this),
      );

  TypeAliasDeclaration _expectTypeAliasDeclaration(int id) =>
      new TypeAliasDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        aliasedType: RemoteInstance.deserialize(this),
      );

  List<String> _readStringList() => [
        for (bool hasNext = (this
                  ..moveNext()
                  ..expectList())
                .moveNext();
            hasNext;
            hasNext = moveNext())
          expectString(),
      ];

  List<T> _readCodeList<T extends Code>() => [
        for (bool hasNext = (this
                  ..moveNext()
                  ..expectList())
                .moveNext();
            hasNext;
            hasNext = moveNext())
          expectCode(),
      ];

  List<Object> _readParts() {
    moveNext();
    expectList();
    List<Object> parts = [];
    while (moveNext()) {
      _CodePartKind partKind = _CodePartKind.values[expectInt()];
      moveNext();
      switch (partKind) {
        case _CodePartKind.code:
          parts.add(expectCode());
          break;
        case _CodePartKind.string:
          parts.add(expectString());
          break;
        case _CodePartKind.identifier:
          parts.add(expectRemoteInstance());
          break;
      }
    }
    return parts;
  }

  T expectCode<T extends Code>() {
    CodeKind kind = CodeKind.values[expectInt()];

    return switch (kind) {
      CodeKind.raw => new RawCode.fromParts(_readParts()) as T,
      CodeKind.comment => new CommentCode.fromParts(_readParts()) as T,
      CodeKind.declaration => new DeclarationCode.fromParts(_readParts()) as T,
      CodeKind.expression => new ExpressionCode.fromParts(_readParts()) as T,
      CodeKind.functionBody =>
        new FunctionBodyCode.fromParts(_readParts()) as T,
      CodeKind.functionTypeAnnotation => new FunctionTypeAnnotationCode(
          namedParameters: _readCodeList(),
          positionalParameters: _readCodeList(),
          returnType: (this..moveNext()).expectNullableCode(),
          typeParameters: _readCodeList()) as T,
      CodeKind.namedTypeAnnotation => new NamedTypeAnnotationCode(
          name: RemoteInstance.deserialize(this),
          typeArguments: _readCodeList()) as T,
      CodeKind.nullableTypeAnnotation =>
        new NullableTypeAnnotationCode((this..moveNext()).expectCode()) as T,
      CodeKind.omittedTypeAnnotation =>
        new OmittedTypeAnnotationCode(RemoteInstance.deserialize(this)) as T,
      CodeKind.parameter => new ParameterCode(
          defaultValue: (this..moveNext()).expectNullableCode(),
          keywords: _readStringList(),
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectNullableCode()) as T,
      CodeKind.recordField => new RecordFieldCode(
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectCode()) as T,
      CodeKind.recordTypeAnnotation => new RecordTypeAnnotationCode(
          namedFields: _readCodeList(), positionalFields: _readCodeList()) as T,
      CodeKind.typeParameter => new TypeParameterCode(
          bound: (this..moveNext()).expectNullableCode(),
          name: (this..moveNext()).expectString()) as T,
    };
  }

  T? expectNullableCode<T extends Code>() {
    if (checkNull()) return null;
    return expectCode();
  }
}

extension SerializeNullable on Serializable? {
  /// Either serializes a `null` literal or the object.
  void serializeNullable(Serializer serializer) {
    Serializable? self = this;
    if (self == null) {
      serializer.addNull();
    } else {
      self.serialize(serializer);
    }
  }
}

extension SerializeNullableCode on Code? {
  /// Either serializes a `null` literal or the code object.
  void serializeNullable(Serializer serializer) {
    Code? self = this;
    if (self == null) {
      serializer.addNull();
    } else {
      self.serialize(serializer);
    }
  }
}

extension SerializeCode on Code {
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
    switch (kind) {
      case CodeKind.namedTypeAnnotation:
        NamedTypeAnnotationCode self = this as NamedTypeAnnotationCode;
        (self.name as IdentifierImpl).serialize(serializer);
        serializer.startList();
        for (TypeAnnotationCode typeArg in self.typeArguments) {
          typeArg.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.functionTypeAnnotation:
        FunctionTypeAnnotationCode self = this as FunctionTypeAnnotationCode;
        serializer.startList();
        for (ParameterCode named in self.namedParameters) {
          named.serialize(serializer);
        }
        serializer
          ..endList()
          ..startList();
        for (ParameterCode positional in self.positionalParameters) {
          positional.serialize(serializer);
        }
        serializer..endList();
        self.returnType.serializeNullable(serializer);
        serializer.startList();
        for (TypeParameterCode typeParam in self.typeParameters) {
          typeParam.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.nullableTypeAnnotation:
        NullableTypeAnnotationCode self = this as NullableTypeAnnotationCode;
        self.underlyingType.serialize(serializer);
        return;
      case CodeKind.omittedTypeAnnotation:
        OmittedTypeAnnotationCode self = this as OmittedTypeAnnotationCode;
        (self.typeAnnotation as OmittedTypeAnnotationImpl)
            .serialize(serializer);
        return;
      case CodeKind.recordField:
        RecordFieldCode self = this as RecordFieldCode;
        serializer.addNullableString(self.name);
        self.type.serialize(serializer);
        return;
      case CodeKind.recordTypeAnnotation:
        RecordTypeAnnotationCode self = this as RecordTypeAnnotationCode;
        serializer.startList();
        for (RecordFieldCode field in self.namedFields) {
          field.serialize(serializer);
        }
        serializer
          ..endList()
          ..startList();
        for (RecordFieldCode field in self.positionalFields) {
          field.serialize(serializer);
        }
        serializer.endList();
        return;
      case CodeKind.parameter:
        ParameterCode self = this as ParameterCode;
        self.defaultValue.serializeNullable(serializer);
        serializer.startList();
        for (String keyword in self.keywords) {
          serializer.addString(keyword);
        }
        serializer
          ..endList()
          ..addNullableString(self.name);
        self.type.serializeNullable(serializer);
        return;
      case CodeKind.typeParameter:
        TypeParameterCode self = this as TypeParameterCode;
        self.bound.serializeNullable(serializer);
        serializer.addString(self.name);
        return;
      case CodeKind.comment:
      case CodeKind.declaration:
      case CodeKind.expression:
      case CodeKind.raw:
      case CodeKind.functionBody:
        serializer.startList();
        for (Object part in parts) {
          if (part is String) {
            serializer
              ..addInt(_CodePartKind.string.index)
              ..addString(part);
          } else if (part is Code) {
            serializer.addInt(_CodePartKind.code.index);
            part.serialize(serializer);
          } else if (part is IdentifierImpl) {
            serializer.addInt(_CodePartKind.identifier.index);
            part.serialize(serializer);
          } else {
            throw new StateError('Unrecognized code part $part');
          }
        }
        serializer.endList();
        return;
    }
  }
}

extension Helpers on Serializer {
  void addUri(Uri uri) => addString('$uri');

  void addSerializable(Serializable serializable) =>
      serializable.serialize(this);
}

enum _CodePartKind {
  string,
  code,
  identifier,
}
