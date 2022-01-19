import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';

import 'remote_instance.dart';
import 'serialization.dart';
import '../api.dart';

extension DeserializerExtensions on Deserializer {
  T expectRemoteInstance<T>() {
    int id = expectNum();
    switch (serializationMode) {
      case SerializationMode.client:
        moveNext();
        RemoteInstanceKind kind = RemoteInstanceKind.values[expectNum()];
        switch (kind) {
          case RemoteInstanceKind.classIntrospector:
          case RemoteInstanceKind.namedStaticType:
          case RemoteInstanceKind.staticType:
          case RemoteInstanceKind.typeDeclarationResolver:
          case RemoteInstanceKind.typeResolver:
            // These are simple wrappers, just pass in the kind
            return new RemoteInstanceImpl(id: id, kind: kind) as T;
          case RemoteInstanceKind.classDeclaration:
            moveNext();
            return _expectClassDeclaration(id) as T;
          case RemoteInstanceKind.constructorDeclaration:
            moveNext();
            return _expectConstructorDeclaration(id) as T;
          case RemoteInstanceKind.fieldDeclaration:
            moveNext();
            return _expectFieldDeclaration(id) as T;
          case RemoteInstanceKind.functionDeclaration:
            moveNext();
            return _expectFunctionDeclaration(id) as T;
          case RemoteInstanceKind.functionTypeAnnotation:
            moveNext();
            return _expectFunctionTypeAnnotation(id) as T;
          case RemoteInstanceKind.methodDeclaration:
            moveNext();
            return _expectMethodDeclaration(id) as T;
          case RemoteInstanceKind.namedTypeAnnotation:
            moveNext();
            return _expectNamedTypeAnnotation(id) as T;
          case RemoteInstanceKind.parameterDeclaration:
            moveNext();
            return _expectParameterDeclaration(id) as T;
          case RemoteInstanceKind.typeAliasDeclaration:
            moveNext();
            return _expectTypeAliasDeclaration(id) as T;
          case RemoteInstanceKind.typeParameterDeclaration:
            moveNext();
            return _expectTypeParameterDeclaration(id) as T;
          case RemoteInstanceKind.variableDeclaration:
            moveNext();
            return _expectVariableDeclaration(id) as T;
        }
      case SerializationMode.server:
        return RemoteInstance.cached(id) as T;
    }
  }

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
        name: (this..moveNext()).expectString(),
        typeArguments: (this..moveNext())._expectRemoteInstanceList(),
      );

  FunctionTypeAnnotation _expectFunctionTypeAnnotation(int id) =>
      new FunctionTypeAnnotationImpl(
        id: id,
        isNullable: expectBool(),
        returnType: RemoteInstance.deserialize(this),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  ParameterDeclaration _expectParameterDeclaration(int id) =>
      new ParameterDeclarationImpl(
        id: id,
        name: expectString(),
        defaultValue: (this..moveNext()).checkNull() ? null : expectCode(),
        isNamed: (this..moveNext()).expectBool(),
        isRequired: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  TypeParameterDeclaration _expectTypeParameterDeclaration(int id) =>
      new TypeParameterDeclarationImpl(
        id: id,
        name: expectString(),
        bounds: (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  FunctionDeclaration _expectFunctionDeclaration(int id) =>
      new FunctionDeclarationImpl(
        id: id,
        name: expectString(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
      );

  MethodDeclaration _expectMethodDeclaration(int id) =>
      new MethodDeclarationImpl(
        id: id,
        name: expectString(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingClass: RemoteInstance.deserialize(this),
      );

  ConstructorDeclaration _expectConstructorDeclaration(int id) =>
      new ConstructorDeclarationImpl(
        id: id,
        name: expectString(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        isGetter: (this..moveNext()).expectBool(),
        isSetter: (this..moveNext()).expectBool(),
        namedParameters: (this..moveNext())._expectRemoteInstanceList(),
        positionalParameters: (this..moveNext())._expectRemoteInstanceList(),
        returnType: RemoteInstance.deserialize(this),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        definingClass: RemoteInstance.deserialize(this),
        isFactory: (this..moveNext()).expectBool(),
      );

  VariableDeclaration _expectVariableDeclaration(int id) =>
      new VariableDeclarationImpl(
        id: id,
        name: expectString(),
        initializer: (this..moveNext()).expectNullableCode(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
      );

  FieldDeclaration _expectFieldDeclaration(int id) => new FieldDeclarationImpl(
        id: id,
        name: expectString(),
        initializer: (this..moveNext()).expectNullableCode(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        type: RemoteInstance.deserialize(this),
        definingClass: RemoteInstance.deserialize(this),
      );

  ClassDeclaration _expectClassDeclaration(int id) => new ClassDeclarationImpl(
        id: id,
        name: expectString(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        interfaces: (this..moveNext())._expectRemoteInstanceList(),
        isAbstract: (this..moveNext()).expectBool(),
        isExternal: (this..moveNext()).expectBool(),
        mixins: (this..moveNext())._expectRemoteInstanceList(),
        superclass:
            (this..moveNext()).checkNull() ? null : expectRemoteInstance(),
      );

  TypeAliasDeclaration _expectTypeAliasDeclaration(int id) =>
      new TypeAliasDeclarationImpl(
        id: id,
        name: expectString(),
        typeParameters: (this..moveNext())._expectRemoteInstanceList(),
        type: RemoteInstance.deserialize(this),
      );

  T expectCode<T extends Code>() {
    CodeKind kind = CodeKind.values[expectNum()];
    moveNext();
    expectList();
    List<Object> parts = [];
    while (moveNext()) {
      CodePartKind partKind = CodePartKind.values[expectNum()];
      moveNext();
      switch (partKind) {
        case CodePartKind.code:
          parts.add(expectCode());
          break;
        case CodePartKind.string:
          parts.add(expectString());
          break;
        case CodePartKind.typeAnnotation:
          parts.add(expectRemoteInstance());
          break;
      }
    }

    switch (kind) {
      case CodeKind.raw:
        return new Code.fromParts(parts) as T;
      case CodeKind.declaration:
        return new DeclarationCode.fromParts(parts) as T;
      case CodeKind.element:
        return new ElementCode.fromParts(parts) as T;
      case CodeKind.expression:
        return new ExpressionCode.fromParts(parts) as T;
      case CodeKind.functionBody:
        return new FunctionBodyCode.fromParts(parts) as T;
      case CodeKind.identifier:
        return new IdentifierCode.fromParts(parts) as T;
      case CodeKind.namedArgument:
        return new NamedArgumentCode.fromParts(parts) as T;
      case CodeKind.parameter:
        return new ParameterCode.fromParts(parts) as T;
      case CodeKind.statement:
        return new StatementCode.fromParts(parts) as T;
    }
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
    serializer
      ..addNum(kind.index)
      ..startList();
    for (Object part in parts) {
      if (part is String) {
        serializer
          ..addNum(CodePartKind.string.index)
          ..addString(part);
      } else if (part is Code) {
        serializer.addNum(CodePartKind.code.index);
        part.serialize(serializer);
      } else if (part is TypeAnnotationImpl) {
        serializer.addNum(CodePartKind.typeAnnotation.index);
        part.serialize(serializer);
      } else {
        throw new StateError('Unrecognized code part $part');
      }
    }
    serializer.endList();
  }
}

enum CodePartKind {
  string,
  code,
  typeAnnotation,
}
