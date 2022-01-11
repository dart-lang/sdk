// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the objects used for communication between the macro executor and
/// the isolate or process doing the work of macro loading and execution.
library _fe_analyzer_shared.src.macros.executor_shared.protocol;

import '../executor.dart';
import '../api.dart';
import '../executor_shared/response_impls.dart';
import 'serialization.dart';
import 'serialization_extensions.dart';

/// Base class all requests extend, provides a unique id for each request.
abstract class Request implements Serializable {
  final int id;

  Request({int? id}) : this.id = id ?? _next++;

  Request.deserialize(Deserializer deserializer)
      : id = (deserializer..moveNext()).expectNum();

  void serialize(Serializer serializer) => serializer.addNum(id);

  static int _next = 0;
}

/// A generic response object that contains either a response or an error, and
/// a unique ID.
class Response {
  final Object? response;
  final Object? error;
  final int requestId;

  Response({this.response, this.error, required this.requestId})
      : assert(response != null || error != null),
        assert(response == null || error == null);
}

/// A serializable [Response], contains the message type as an enum.
class SerializableResponse implements Response, Serializable {
  final Serializable? response;
  final MessageType responseType;
  final String? error;
  final int requestId;

  SerializableResponse({
    this.error,
    required this.requestId,
    this.response,
    required this.responseType,
  })  : assert(response != null || error != null),
        assert(response == null || error == null);

  factory SerializableResponse.deserialize(Deserializer deserializer) {
    deserializer.moveNext();
    MessageType responseType = MessageType.values[deserializer.expectNum()];
    Serializable? response;
    String? error;
    switch (responseType) {
      case MessageType.error:
        deserializer.moveNext();
        error = deserializer.expectString();
        break;
      case MessageType.macroClassIdentifier:
        response = new MacroClassIdentifierImpl.deserialize(deserializer);
        break;
      case MessageType.macroInstanceIdentifier:
        response = new MacroInstanceIdentifierImpl.deserialize(deserializer);
        break;
      case MessageType.macroExecutionResult:
        response = new MacroExecutionResultImpl.deserialize(deserializer);
        break;
      default:
        throw new StateError('Unexpected response type $responseType');
    }

    return new SerializableResponse(
        responseType: responseType,
        response: response,
        error: error,
        requestId: (deserializer..moveNext()).expectNum());
  }

  void serialize(Serializer serializer) {
    serializer.addNum(responseType.index);
    if (response != null) {
      response!.serialize(serializer);
    } else if (error != null) {
      serializer.addString(error!.toString());
    }
    serializer.addNum(requestId);
  }
}

/// A request to load a macro in this isolate.
class LoadMacroRequest extends Request {
  final Uri library;
  final String name;

  LoadMacroRequest(this.library, this.name);

  LoadMacroRequest.deserialize(Deserializer deserializer)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize(deserializer);

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addNum(MessageType.loadMacroRequest.index)
      ..addString(library.toString())
      ..addString(name);
    super.serialize(serializer);
  }
}

/// A request to instantiate a macro instance.
class InstantiateMacroRequest extends Request {
  final MacroClassIdentifier macroClass;
  final String constructorName;
  final Arguments arguments;

  InstantiateMacroRequest(
      this.macroClass, this.constructorName, this.arguments);

  InstantiateMacroRequest.deserialize(Deserializer deserializer)
      : macroClass = new MacroClassIdentifierImpl.deserialize(deserializer),
        constructorName = (deserializer..moveNext()).expectString(),
        arguments = new Arguments.deserialize(deserializer),
        super.deserialize(deserializer);

  @override
  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.instantiateMacroRequest.index);
    macroClass.serialize(serializer);
    serializer.addString(constructorName);
    arguments.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to execute a macro on a particular declaration in the definition
/// phase.
class ExecuteDefinitionsPhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final Declaration declaration;

  /// Client/Server specific implementation, not serialized.
  final TypeResolver typeResolver;

  /// Client/Server specific implementation, not serialized.
  final ClassIntrospector classIntrospector;

  /// Client/Server specific implementation, not serialized.
  final TypeDeclarationResolver typeDeclarationResolver;

  ExecuteDefinitionsPhaseRequest(this.macro, this.declaration,
      this.typeResolver, this.classIntrospector, this.typeDeclarationResolver);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecuteDefinitionsPhaseRequest.deserialize(Deserializer deserializer,
      this.typeResolver, this.classIntrospector, this.typeDeclarationResolver)
      : macro = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        declaration = (deserializer..moveNext()).expectDeclaration(),
        super.deserialize(deserializer);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.executeDefinitionsPhaseRequest.index);
    macro.serialize(serializer);
    declaration.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to reflect on a type annotation
class ReflectTypeRequest extends Request {
  final TypeAnnotation typeAnnotation;

  ReflectTypeRequest(this.typeAnnotation);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ReflectTypeRequest.deserialize(Deserializer deserializer)
      : typeAnnotation = (deserializer..moveNext()).expectTypeAnnotation(),
        super.deserialize(deserializer);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.reflectTypeRequest.index);
    typeAnnotation.serialize(serializer);
    super.serialize(serializer);
  }
}

/// TODO: Implement this
class ClientTypeResolver implements TypeResolver {
  @override
  Future<StaticType> resolve(TypeAnnotation typeAnnotation) {
    // TODO: implement resolve
    throw new UnimplementedError();
  }
}

/// TODO: Implement this
class ClientClassIntrospector implements ClassIntrospector {
  @override
  Future<List<ConstructorDeclaration>> constructorsOf(ClassDeclaration clazz) {
    // TODO: implement constructorsOf
    throw new UnimplementedError();
  }

  @override
  Future<List<FieldDeclaration>> fieldsOf(ClassDeclaration clazz) {
    // TODO: implement fieldsOf
    throw new UnimplementedError();
  }

  @override
  Future<List<ClassDeclaration>> interfacesOf(ClassDeclaration clazz) {
    // TODO: implement interfacesOf
    throw new UnimplementedError();
  }

  @override
  Future<List<MethodDeclaration>> methodsOf(ClassDeclaration clazz) {
    // TODO: implement methodsOf
    throw new UnimplementedError();
  }

  @override
  Future<List<ClassDeclaration>> mixinsOf(ClassDeclaration clazz) {
    // TODO: implement mixinsOf
    throw new UnimplementedError();
  }

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) {
    // TODO: implement superclassOf
    throw new UnimplementedError();
  }
}

/// TODO: Implement this
class ClientTypeDeclarationsResolver implements TypeDeclarationResolver {
  @override
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) {
    // TODO: implement declarationOf
    throw new UnimplementedError();
  }
}

enum MessageType {
  error,
  executeDefinitionsPhaseRequest,
  instantiateMacroRequest,
  loadMacroRequest,
  reflectTypeRequest,
  macroClassIdentifier,
  macroInstanceIdentifier,
  macroExecutionResult,
}
