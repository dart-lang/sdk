import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';

import 'serialization.dart';
import '../api.dart';

extension DeserializerExtensions on Deserializer {
  TypeAnnotation expectTypeAnnotation() {
    int id = expectNum();
    switch (serializationMode) {
      case SerializationMode.server:
        return _typeAnnotationsById[id]!;
      case SerializationMode.client:
        TypeAnnotation typeAnnotation;
        moveNext();
        TypeAnnotationKind type = TypeAnnotationKind.values[expectNum()];
        moveNext();
        switch (type) {
          case TypeAnnotationKind.namedType:
            typeAnnotation = _expectNamedTypeAnnotation();
            break;
          case TypeAnnotationKind.functionType:
            typeAnnotation = _expectFunctionTypeAnnotation();
            break;
        }
        _typeAnnotationIds[typeAnnotation] = id;
        return typeAnnotation;
    }
  }

  NamedTypeAnnotation _expectNamedTypeAnnotation() {
    bool isNullable = expectBool();
    moveNext();
    String name = expectString();
    moveNext();
    expectList();
    List<TypeAnnotation> typeArguments = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectTypeAnnotation(),
    ];
    return new NamedTypeAnnotationImpl(
        isNullable: isNullable, name: name, typeArguments: typeArguments);
  }

  FunctionTypeAnnotation _expectFunctionTypeAnnotation() {
    bool isNullable = expectBool();

    moveNext();
    TypeAnnotation returnType = expectTypeAnnotation();

    moveNext();
    expectList();
    List<ParameterDeclaration> positionalParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration(),
    ];

    moveNext();
    expectList();
    List<ParameterDeclaration> namedParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration(),
    ];

    moveNext();
    expectList();
    List<TypeParameterDeclaration> typeParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration(),
    ];

    return new FunctionTypeAnnotationImpl(
        isNullable: isNullable,
        returnType: returnType,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        typeParameters: typeParameters);
  }

  T expectDeclaration<T extends Declaration>() {
    DeclarationKind kind = DeclarationKind.values[expectNum()];
    moveNext();
    switch (kind) {
      case DeclarationKind.parameter:
        return _expectParameterDeclaration() as T;
      case DeclarationKind.typeParameter:
        return _expectTypeParameterDeclaration() as T;
      case DeclarationKind.function:
        return _expectFunctionDeclaration() as T;
      default:
        throw new UnimplementedError('Cant deserialize $kind yet');
    }
  }

  ParameterDeclaration _expectParameterDeclaration() {
    String name = expectString();
    moveNext();
    Code? defaultValue;
    if (!checkNull()) {
      defaultValue = expectCode();
    }
    bool isNamed = expectBool();
    moveNext();
    bool isRequired = expectBool();
    moveNext();
    TypeAnnotation type = expectTypeAnnotation();

    return new ParameterDeclarationImpl(
        defaultValue: defaultValue,
        isNamed: isNamed,
        isRequired: isRequired,
        name: name,
        type: type);
  }

  TypeParameterDeclaration _expectTypeParameterDeclaration() {
    String name = expectString();
    moveNext();
    TypeAnnotation? bounds;
    if (!checkNull()) {
      bounds = expectTypeAnnotation();
    }
    return new TypeParameterDeclarationImpl(name: name, bounds: bounds);
  }

  FunctionDeclaration _expectFunctionDeclaration() {
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
    List<ParameterDeclaration> namedParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration()
    ];

    moveNext();
    expectList();
    List<ParameterDeclaration> positionalParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration()
    ];

    moveNext();
    TypeAnnotation returnType = expectTypeAnnotation();

    moveNext();
    expectList();
    List<TypeParameterDeclaration> typeParameters = [
      for (bool hasNext = moveNext(); hasNext; hasNext = moveNext())
        expectDeclaration()
    ];
    return new FunctionDeclarationImpl(
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
          parts.add(expectTypeAnnotation());
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

/// On the server side we keep track of type annotations by their ID.
final _typeAnnotationsById = <int, TypeAnnotation>{};

/// On the client side we keep an expando of ids on [TypeAnnotation]s.
final _typeAnnotationIds = new Expando<int>();

/// Incrementing ids for [TypeAnnotationImpl]s
int _nextTypeAnnotationId = 0;

extension SerializeTypeAnnotation on TypeAnnotation {
  void serialize(Serializer serializer) {
    TypeAnnotation self = this;
    if (self is NamedTypeAnnotationImpl) {
      self.serialize(serializer);
    } else if (self is FunctionTypeAnnotationImpl) {
      self.serialize(serializer);
    } else {
      throw new UnsupportedError(
          'Type ${this.runtimeType} is not supported for serialization.');
    }
  }
}

/// Does the parts of serialization for type annotations that is shared between
/// implementations.
///
/// Returns `false` if we should continue serializing the rest of the object, or
/// `true` if the object is fully serialized (just an ID).
bool _doSharedTypeAnnotationSerialization(Serializer serializer,
    TypeAnnotation typeAnnotation, TypeAnnotationKind kind) {
  switch (serializationMode) {
    case SerializationMode.client:
      // Only send the ID from the client side, and assume we have one.
      int id = _typeAnnotationIds[typeAnnotation]!;
      serializer.addNum(id);
      return true;
    case SerializationMode.server:
      // Server side we may create new ids for unseen annotations,
      // and continue to serialize the rest of the annotation.
      int id = _typeAnnotationIds[typeAnnotation] ?? _nextTypeAnnotationId++;
      // TODO: We should clean these up at some point.
      _typeAnnotationsById[id] = typeAnnotation;
      serializer.addNum(id);
      break;
  }
  serializer.addNum(kind.index);
  serializer.addBool(typeAnnotation.isNullable);
  return false;
}

extension SerializeNamedTypeAnnotation on NamedTypeAnnotation {
  void serialize(Serializer serializer) {
    if (_doSharedTypeAnnotationSerialization(
        serializer, this, TypeAnnotationKind.namedType)) {
      return;
    }
    serializer.addString(name);
    serializer.startList();
    for (TypeAnnotation typeArg in typeArguments) {
      typeArg.serialize(serializer);
    }
    serializer.endList();
  }
}

extension SerializeFunctionTypeAnnotation on FunctionTypeAnnotation {
  void serialize(Serializer serializer) {
    if (_doSharedTypeAnnotationSerialization(
        serializer, this, TypeAnnotationKind.functionType)) {
      return;
    }

    returnType.serialize(serializer);

    serializer.startList();
    for (ParameterDeclaration param in positionalParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (ParameterDeclaration param in namedParameters) {
      param.serialize(serializer);
    }
    serializer.endList();

    serializer.startList();
    for (TypeParameterDeclaration typeParam in typeParameters) {
      typeParam.serialize(serializer);
    }
    serializer.endList();
  }
}

/// Does the shared parts of [Declaration] serialization.
void _serializeDeclaration(Serializer serializer, Declaration declaration) {
  serializer.addNum(declaration.kind.index);
  serializer.addString(declaration.name);
}

/// Checks the type and deserializes it appropriately.
extension SerializeDeclaration on Declaration {
  void serialize(Serializer serializer) {
    switch (kind) {
      case DeclarationKind.parameter:
        (this as ParameterDeclaration).serialize(serializer);
        break;
      case DeclarationKind.typeParameter:
        (this as TypeParameterDeclaration).serialize(serializer);
        break;
      case DeclarationKind.function:
        (this as FunctionDeclaration).serialize(serializer);
        break;
      default:
        throw new UnimplementedError('Cant serialize $kind yet');
    }
  }
}

extension SerializeParameterDeclaration on ParameterDeclaration {
  void serialize(Serializer serializer) {
    _serializeDeclaration(serializer, this);
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

extension SerializeTypeParameterDeclaration on TypeParameterDeclaration {
  void serialize(Serializer serializer) {
    _serializeDeclaration(serializer, this);
    TypeAnnotation? bounds = this.bounds;
    if (bounds == null) {
      serializer.addNull();
    } else {
      bounds.serialize(serializer);
    }
  }
}

extension SerializeFunctionDeclaration on FunctionDeclaration {
  void serialize(Serializer serializer) {
    _serializeDeclaration(serializer, this);
    serializer
      ..addBool(isAbstract)
      ..addBool(isExternal)
      ..addBool(isGetter)
      ..addBool(isSetter)
      ..startList();
    for (ParameterDeclaration named in namedParameters) {
      named.serialize(serializer);
    }
    serializer
      ..endList()
      ..startList();
    for (ParameterDeclaration positional in positionalParameters) {
      positional.serialize(serializer);
    }
    serializer.endList();
    returnType.serialize(serializer);
    serializer.startList();
    for (TypeParameterDeclaration param in typeParameters) {
      param.serialize(serializer);
    }
    serializer.endList();
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
      } else if (part is TypeAnnotation) {
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
