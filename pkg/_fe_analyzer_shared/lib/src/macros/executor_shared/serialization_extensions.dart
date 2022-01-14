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
          case RemoteInstanceKind.namedTypeAnnotation:
            moveNext();
            return _expectNamedTypeAnnotation(id) as T;
          case RemoteInstanceKind.functionTypeAnnotation:
            moveNext();
            return _expectFunctionTypeAnnotation(id) as T;
          case RemoteInstanceKind.functionDeclaration:
            moveNext();
            return _expectFunctionDeclaration(id) as T;
          case RemoteInstanceKind.parameterDeclaration:
            moveNext();
            return _expectParameterDeclaration(id) as T;
          case RemoteInstanceKind.typeParameterDeclaration:
            moveNext();
            return _expectTypeParameterDeclaration(id) as T;
          case RemoteInstanceKind.instance:
            return new RemoteInstanceImpl(id: id) as T;
          default:
            throw new UnsupportedError('Unsupported remote object kind: $kind');
        }
      case SerializationMode.server:
        return RemoteInstance.cached(id) as T;
    }
  }

  NamedTypeAnnotation _expectNamedTypeAnnotation(int id) {
    bool isNullable = expectBool();
    moveNext();
    String name = expectString();
    moveNext();
    expectList();
    List<TypeAnnotationImpl> typeArguments = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];
    return new NamedTypeAnnotationImpl(
        id: id,
        isNullable: isNullable,
        name: name,
        typeArguments: typeArguments);
  }

  FunctionTypeAnnotation _expectFunctionTypeAnnotation(int id) {
    bool isNullable = expectBool();

    TypeAnnotationImpl returnType = RemoteInstance.deserialize(this);

    moveNext();
    expectList();
    List<ParameterDeclarationImpl> positionalParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];

    moveNext();
    expectList();
    List<ParameterDeclarationImpl> namedParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];

    moveNext();
    expectList();
    List<TypeParameterDeclarationImpl> typeParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];

    return new FunctionTypeAnnotationImpl(
      id: id,
      isNullable: isNullable,
      returnType: returnType,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      typeParameters: typeParameters,
    );
  }

  ParameterDeclaration _expectParameterDeclaration(int id) {
    String name = expectString();
    moveNext();
    Code? defaultValue;
    if (!checkNull()) {
      defaultValue = expectCode();
    }
    bool isNamed = expectBool();
    moveNext();
    bool isRequired = expectBool();

    TypeAnnotationImpl type = RemoteInstance.deserialize(this);

    return new ParameterDeclarationImpl(
        id: id,
        defaultValue: defaultValue,
        isNamed: isNamed,
        isRequired: isRequired,
        name: name,
        type: type);
  }

  TypeParameterDeclaration _expectTypeParameterDeclaration(int id) {
    String name = expectString();
    moveNext();
    TypeAnnotationImpl? bounds;
    if (!checkNull()) {
      bounds = expectRemoteInstance();
    }
    return new TypeParameterDeclarationImpl(id: id, name: name, bounds: bounds);
  }

  FunctionDeclaration _expectFunctionDeclaration(int id) {
    String name = expectString();
    moveNext();
    bool isAbstract = expectBool();
    moveNext();
    bool isExternal = expectBool();
    moveNext();
    bool isGetter = expectBool();
    moveNext();
    bool isSetter = expectBool();

    moveNext();
    expectList();
    List<ParameterDeclarationImpl> namedParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];

    moveNext();
    expectList();
    List<ParameterDeclarationImpl> positionalParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];

    TypeAnnotationImpl returnType = RemoteInstance.deserialize(this);

    moveNext();
    expectList();
    List<TypeParameterDeclarationImpl> typeParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectRemoteInstance(),
    ];
    return new FunctionDeclarationImpl(
        id: id,
        name: name,
        isAbstract: isAbstract,
        isExternal: isExternal,
        isGetter: isGetter,
        isSetter: isSetter,
        namedParameters: namedParameters,
        positionalParameters: positionalParameters,
        returnType: returnType,
        typeParameters: typeParameters);
  }

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
