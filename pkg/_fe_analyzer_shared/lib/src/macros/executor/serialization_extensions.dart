import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';

import 'remote_instance.dart';
import 'serialization.dart';
import '../api.dart';

extension DeserializerExtensions on Deserializer {
  T expectRemoteInstance<T extends Object>() {
    int id = expectInt();

    // If cached, just return the instance. Only the ID should be sent.
    RemoteInstance? cached = RemoteInstance.cached(id);
    if (cached != null) {
      return cached as T;
    }

    moveNext();
    RemoteInstanceKind kind = RemoteInstanceKind.values[expectInt()];
    final RemoteInstance instance = switch (kind) {
      RemoteInstanceKind.declarationPhaseIntrospector ||
      RemoteInstanceKind.definitionPhaseIntrospector ||
      RemoteInstanceKind.typePhaseIntrospector ||
      RemoteInstanceKind.namedStaticType ||
      RemoteInstanceKind.staticType =>
        // These are simple wrappers, just pass in the kind
        new RemoteInstanceImpl(id: id, kind: kind),
      RemoteInstanceKind.classDeclaration =>
        (this..moveNext())._expectClassDeclaration(id),
      RemoteInstanceKind.constructorMetadataAnnotation =>
        (this..moveNext())._expectConstructorMetadataAnnotation(id),
      RemoteInstanceKind.enumDeclaration =>
        (this..moveNext())._expectEnumDeclaration(id),
      RemoteInstanceKind.enumValueDeclaration =>
        (this..moveNext())._expectEnumValueDeclaration(id),
      RemoteInstanceKind.extensionDeclaration =>
        (this..moveNext())._expectExtensionDeclaration(id),
      RemoteInstanceKind.mixinDeclaration =>
        (this..moveNext())._expectMixinDeclaration(id),
      RemoteInstanceKind.constructorDeclaration =>
        (this..moveNext())._expectConstructorDeclaration(id),
      RemoteInstanceKind.fieldDeclaration =>
        (this..moveNext())._expectFieldDeclaration(id),
      RemoteInstanceKind.functionDeclaration =>
        (this..moveNext())._expectFunctionDeclaration(id),
      RemoteInstanceKind.functionTypeAnnotation =>
        (this..moveNext())._expectFunctionTypeAnnotation(id),
      RemoteInstanceKind.functionTypeParameter =>
        (this..moveNext())._expectFunctionTypeParameter(id),
      RemoteInstanceKind.identifier => (this..moveNext())._expectIdentifier(id),
      RemoteInstanceKind.identifierMetadataAnnotation =>
        (this..moveNext())._expectIdentifierMetadataAnnotation(id),
      RemoteInstanceKind.introspectableClassDeclaration =>
        (this..moveNext())._expectIntrospectableClassDeclaration(id),
      RemoteInstanceKind.introspectableEnumDeclaration =>
        (this..moveNext())._expectIntrospectableEnumDeclaration(id),
      RemoteInstanceKind.introspectableExtensionDeclaration =>
        (this..moveNext())._expectIntrospectableExtensionDeclaration(id),
      RemoteInstanceKind.introspectableMixinDeclaration =>
        (this..moveNext())._expectIntrospectableMixinDeclaration(id),
      RemoteInstanceKind.library => (this..moveNext())._expectLibrary(id),
      RemoteInstanceKind.methodDeclaration =>
        (this..moveNext())._expectMethodDeclaration(id),
      RemoteInstanceKind.namedTypeAnnotation =>
        (this..moveNext())._expectNamedTypeAnnotation(id),
      RemoteInstanceKind.omittedTypeAnnotation =>
        (this..moveNext())._expectOmittedTypeAnnotation(id),
      RemoteInstanceKind.parameterDeclaration =>
        (this..moveNext())._expectParameterDeclaration(id),
      RemoteInstanceKind.recordFieldDeclaration =>
        (this..moveNext())._expectRecordFieldDeclaration(id),
      RemoteInstanceKind.recordTypeAnnotation =>
        (this..moveNext())._expectRecordTypeAnnotation(id),
      RemoteInstanceKind.typeAliasDeclaration =>
        (this..moveNext())._expectTypeAliasDeclaration(id),
      RemoteInstanceKind.typeParameterDeclaration =>
        (this..moveNext())._expectTypeParameterDeclaration(id),
      RemoteInstanceKind.variableDeclaration =>
        (this..moveNext())._expectVariableDeclaration(id),
    };
    RemoteInstance.cache(instance);
    return instance as T;
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

  NamedTypeAnnotationImpl _expectNamedTypeAnnotation(int id) =>
      new NamedTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        identifier: RemoteInstance.deserialize(this),
        typeArguments: (this..moveNext())._expectRemoteInstanceList(),
      );

  OmittedTypeAnnotationImpl _expectOmittedTypeAnnotation(int id) {
    expectBool(); // Always `false`.
    return new OmittedTypeAnnotationImpl(
      id: id,
    );
  }

  FunctionTypeAnnotationImpl _expectFunctionTypeAnnotation(int id) =>
      new FunctionTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        returnType: RemoteInstance.deserialize(this),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  FunctionTypeParameterImpl _expectFunctionTypeParameter(int id) =>
      new FunctionTypeParameterImpl(
        id: id,
        isNamed: expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        name: (this..moveNext()).expectNullableString(),
        type: RemoteInstance.deserialize(this),
      );

  IdentifierImpl _expectIdentifier(int id) => new IdentifierImpl(
        id: id,
        name: expectString(),
      );

  ParameterDeclarationImpl _expectParameterDeclaration(int id) =>
      new ParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        isNamed: (this..moveNext()).expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  RecordFieldDeclarationImpl _expectRecordFieldDeclaration(int id) =>
      new RecordFieldDeclarationImpl(
          id: id,
          identifier: expectRemoteInstance(),
          library: RemoteInstance.deserialize(this),
          metadata: (this..moveNext())._expectRemoteInstanceList(),
          name: (this..moveNext()).expectNullableString(),
          type: (this..moveNext()).expectRemoteInstance());

  RecordTypeAnnotationImpl _expectRecordTypeAnnotation(int id) =>
      new RecordTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        namedFields: (this..moveNext())._expectRemoteInstanceList(),
        positionalFields: (this..moveNext())._expectRemoteInstanceList(),
      );

  TypeParameterDeclarationImpl _expectTypeParameterDeclaration(int id) =>
      new TypeParameterDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        bound: (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  FunctionDeclarationImpl _expectFunctionDeclaration(int id) =>
      new FunctionDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
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

  MethodDeclarationImpl _expectMethodDeclaration(int id) =>
      new MethodDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
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

  ConstructorDeclarationImpl _expectConstructorDeclaration(int id) =>
      new ConstructorDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
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

  VariableDeclarationImpl _expectVariableDeclaration(int id) =>
      new VariableDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  FieldDeclarationImpl _expectFieldDeclaration(int id) =>
      new FieldDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        isExternal: (this..moveNext()).expectBool(),
        isFinal: (this..moveNext()).expectBool(),
        isLate: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
        definingType: RemoteInstance.deserialize(this),
        isStatic: (this..moveNext()).expectBool(),
      );

  ClassDeclarationImpl _expectClassDeclaration(int id) =>
      new ClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
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

  ConstructorMetadataAnnotationImpl _expectConstructorMetadataAnnotation(
          int id) =>
      new ConstructorMetadataAnnotationImpl(
          id: id,
          constructor: expectRemoteInstance(),
          type: RemoteInstance.deserialize(this));

  IdentifierMetadataAnnotationImpl _expectIdentifierMetadataAnnotation(
          int id) =>
      new IdentifierMetadataAnnotationImpl(
        id: id,
        identifier: expectRemoteInstance(),
      );

  IntrospectableClassDeclarationImpl _expectIntrospectableClassDeclaration(
          int id) =>
      new IntrospectableClassDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
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

  EnumDeclarationImpl _expectEnumDeclaration(int id) => new EnumDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
      );

  IntrospectableEnumDeclarationImpl _expectIntrospectableEnumDeclaration(
          int id) =>
      new IntrospectableEnumDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
      );

  MixinDeclarationImpl _expectMixinDeclaration(int id) =>
      new MixinDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        hasBase: (this..moveNext()).expectBool(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        superclassConstraints: (this..moveNext())._expectRemoteInstanceList(),
      );

  IntrospectableMixinDeclarationImpl _expectIntrospectableMixinDeclaration(
          int id) =>
      new IntrospectableMixinDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        hasBase: (this..moveNext()).expectBool(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        superclassConstraints: (this..moveNext())._expectRemoteInstanceList(),
      );

  EnumValueDeclarationImpl _expectEnumValueDeclaration(int id) =>
      new EnumValueDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        definingEnum: RemoteInstance.deserialize(this),
      );

  ExtensionDeclarationImpl _expectExtensionDeclaration(int id) =>
      new ExtensionDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        onType: RemoteInstance.deserialize(this),
      );
  IntrospectableExtensionDeclarationImpl
      _expectIntrospectableExtensionDeclaration(int id) =>
          new IntrospectableExtensionDeclarationImpl(
            id: id,
            identifier: expectRemoteInstance(),
            library: RemoteInstance.deserialize(this),
            metadata: (this..moveNext())._expectRemoteInstanceList(),
            typeParameters: (this..moveNext())._expectRemoteInstanceList(),
            onType: RemoteInstance.deserialize(this),
          );

  TypeAliasDeclarationImpl _expectTypeAliasDeclaration(int id) =>
      new TypeAliasDeclarationImpl(
        id: id,
        identifier: expectRemoteInstance(),
        library: RemoteInstance.deserialize(this),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        aliasedType: RemoteInstance.deserialize(this),
      );

  LibraryImpl _expectLibrary(int id) => new LibraryImpl(
        id: id,
        languageVersion: new LanguageVersionImpl(
            this.expectInt(), (this..moveNext()).expectInt()),
        metadata: (this..moveNext())._expectRemoteInstanceList(),
        uri: (this..moveNext()).expectUri(),
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
      CodeKind.rawTypeAnnotation =>
        RawTypeAnnotationCode.fromParts(_readParts()) as T,
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
          name: RemoteInstance.deserialize(this) as Identifier,
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
      case CodeKind.rawTypeAnnotation:
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
