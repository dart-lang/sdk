// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the objects used for communication between the macro executor and
/// the isolate or process doing the work of macro loading and execution.
library _fe_analyzer_shared.src.macros.executor_shared.protocol;

import 'package:meta/meta.dart';

import '../executor.dart';
import '../api.dart';
import '../executor_shared/response_impls.dart';
import 'introspection_impls.dart';
import 'remote_instance.dart';
import 'serialization.dart';

/// Base class all requests extend, provides a unique id for each request.
abstract class Request implements Serializable {
  final int id;

  final int serializationZoneId;

  Request({int? id, required this.serializationZoneId})
      : this.id = id ?? _next++;

  /// The [serializationZoneId] is a part of the header and needs to be parsed
  /// before deserializing objects, and then passed in here.
  Request.deserialize(Deserializer deserializer, this.serializationZoneId)
      : id = (deserializer..moveNext()).expectNum();

  /// The [serializationZoneId] needs to be separately serialized before the
  /// rest of the object. This is not done by the instances themselves but by
  /// the macro implementations.
  @mustCallSuper
  void serialize(Serializer serializer) => serializer.addNum(id);

  static int _next = 0;
}

/// A generic response object that contains either a response or an error, and
/// a unique ID.
class Response {
  final Object? response;
  final Object? error;
  final String? stackTrace;
  final int requestId;

  Response({
    this.response,
    this.error,
    this.stackTrace,
    required this.requestId,
  })  : assert(response != null || error != null),
        assert(response == null || error == null);
}

/// A serializable [Response], contains the message type as an enum.
class SerializableResponse implements Response, Serializable {
  final Serializable? response;
  final MessageType responseType;
  final String? error;
  final String? stackTrace;
  final int requestId;
  final int serializationZoneId;

  SerializableResponse({
    this.error,
    this.stackTrace,
    required this.requestId,
    this.response,
    required this.responseType,
    required this.serializationZoneId,
  })  : assert(response != null || error != null),
        assert(response == null || error == null);

  /// You must first parse the [serializationZoneId] yourself, and then
  /// call this function in that zone, and pass the ID.
  factory SerializableResponse.deserialize(
      Deserializer deserializer, int serializationZoneId) {
    deserializer.moveNext();
    MessageType responseType = MessageType.values[deserializer.expectNum()];
    Serializable? response;
    String? error;
    String? stackTrace;
    switch (responseType) {
      case MessageType.error:
        deserializer.moveNext();
        error = deserializer.expectString();
        deserializer.moveNext();
        stackTrace = deserializer.expectNullableString();
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
      case MessageType.staticType:
        response = RemoteInstance.deserialize(deserializer);
        break;
      case MessageType.boolean:
        response = new BooleanValue.deserialize(deserializer);
        break;
      default:
        throw new StateError('Unexpected response type $responseType');
    }

    return new SerializableResponse(
        responseType: responseType,
        response: response,
        error: error,
        stackTrace: stackTrace,
        requestId: (deserializer..moveNext()).expectNum(),
        serializationZoneId: serializationZoneId);
  }

  void serialize(Serializer serializer) {
    serializer
      ..addNum(serializationZoneId)
      ..addNum(MessageType.response.index)
      ..addNum(responseType.index);
    if (response != null) {
      response!.serialize(serializer);
    } else if (error != null) {
      serializer.addString(error!.toString());
      serializer.addNullableString(stackTrace);
    }
    serializer.addNum(requestId);
  }
}

class BooleanValue implements Serializable {
  final bool value;

  BooleanValue(this.value);

  BooleanValue.deserialize(Deserializer deserializer)
      : value = (deserializer..moveNext()).expectBool();

  @override
  void serialize(Serializer serializer) => serializer..addBool(value);
}

/// A request to load a macro in this isolate.
class LoadMacroRequest extends Request {
  final Uri library;
  final String name;

  LoadMacroRequest(this.library, this.name, {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  LoadMacroRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize(deserializer, serializationZoneId);

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

  InstantiateMacroRequest(this.macroClass, this.constructorName, this.arguments,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  InstantiateMacroRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : macroClass = new MacroClassIdentifierImpl.deserialize(deserializer),
        constructorName = (deserializer..moveNext()).expectString(),
        arguments = new Arguments.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

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
  final DeclarationImpl declaration;

  final RemoteInstanceImpl typeResolver;
  final RemoteInstanceImpl classIntrospector;
  final RemoteInstanceImpl typeDeclarationResolver;

  ExecuteDefinitionsPhaseRequest(this.macro, this.declaration,
      this.typeResolver, this.classIntrospector, this.typeDeclarationResolver,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecuteDefinitionsPhaseRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : macro = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        declaration = RemoteInstance.deserialize(deserializer),
        typeResolver = RemoteInstance.deserialize(deserializer),
        classIntrospector = RemoteInstance.deserialize(deserializer),
        typeDeclarationResolver = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.executeDefinitionsPhaseRequest.index);
    macro.serialize(serializer);
    declaration.serialize(serializer);
    typeResolver.serialize(serializer);
    classIntrospector.serialize(serializer);
    typeDeclarationResolver.serialize(serializer);

    super.serialize(serializer);
  }
}

/// A request to reflect on a type annotation
class ResolveTypeRequest extends Request {
  final TypeAnnotationImpl typeAnnotation;
  final RemoteInstanceImpl typeResolver;

  ResolveTypeRequest(this.typeAnnotation, this.typeResolver,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveTypeRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : typeAnnotation = RemoteInstance.deserialize(deserializer),
        typeResolver = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.resolveTypeRequest.index);
    typeAnnotation.serialize(serializer);
    typeResolver.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsExactlyTypeRequest extends Request {
  final RemoteInstanceImpl leftType;
  final RemoteInstanceImpl rightType;

  IsExactlyTypeRequest(this.leftType, this.rightType,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsExactlyTypeRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.isExactlyTypeRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsSubtypeOfRequest extends Request {
  final ClientStaticTypeImpl leftType;
  final ClientStaticTypeImpl rightType;

  IsSubtypeOfRequest(this.leftType, this.rightType,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsSubtypeOfRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addNum(MessageType.isSubtypeOfRequest.index);
    leftType.remoteInstance.serialize(serializer);
    rightType.remoteInstance.serialize(serializer);
    super.serialize(serializer);
  }
}

/// Client side implementation of a [TypeResolver], which creates a
/// [ResolveTypeRequest] and passes it to a given [sendRequest] function which
/// can return the [Response].
class ClientTypeResolver implements TypeResolver {
  /// The actual remote instance of this type resolver.
  final RemoteInstanceImpl remoteInstance;

  /// The ID of the zone in which to find the original type resolver.
  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final Future<Response> Function(Request request) _sendRequest;

  ClientTypeResolver(this._sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});

  @override
  Future<StaticType> resolve(TypeAnnotationImpl typeAnnotation) async {
    ResolveTypeRequest request = new ResolveTypeRequest(
        typeAnnotation, remoteInstance,
        serializationZoneId: serializationZoneId);
    RemoteInstanceImpl remoteType =
        _handleResponse(await _sendRequest(request));
    return new ClientStaticTypeImpl(_sendRequest,
        remoteInstance: remoteType, serializationZoneId: serializationZoneId);
  }
}

class ClientStaticTypeImpl implements StaticType {
  /// The actual remote instance of this static type.
  final RemoteInstanceImpl remoteInstance;

  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final Future<Response> Function(Request request) sendRequest;

  ClientStaticTypeImpl(this.sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});

  @override
  Future<bool> isExactly(ClientStaticTypeImpl other) async {
    IsExactlyTypeRequest request = new IsExactlyTypeRequest(
        this.remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await sendRequest(request)).value;
  }

  @override
  Future<bool> isSubtypeOf(ClientStaticTypeImpl other) async {
    IsSubtypeOfRequest request = new IsSubtypeOfRequest(this, other,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await sendRequest(request)).value;
  }
}

/// TODO: Implement this
class ClientClassIntrospector implements ClassIntrospector {
  /// The actual remote instance of this class introspector.
  final RemoteInstanceImpl remoteInstance;

  /// The ID of the zone in which to find the original type resolver.
  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final Future<Response> Function(Request request) sendRequest;

  ClientClassIntrospector(this.sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});

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
class ClientTypeDeclarationResolver implements TypeDeclarationResolver {
  /// The actual remote instance of this type resolver.
  final RemoteInstanceImpl remoteInstance;

  /// The ID of the zone in which to find the original type resolver.
  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final Future<Response> Function(Request request) sendRequest;

  ClientTypeDeclarationResolver(this.sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});

  @override
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) {
    // TODO: implement declarationOf
    throw new UnimplementedError();
  }
}

/// An exception that occurred remotely, the exception object and stack trace
/// are serialized as [String]s and both included in the [toString] output.
class RemoteException implements Exception {
  final String error;
  final String? stackTrace;

  RemoteException(this.error, [this.stackTrace]);

  String toString() =>
      'RemoteException: $error${stackTrace == null ? '' : '\n\n$stackTrace'}';
}

/// Either returns the actual response from [response], casted to [T], or throws
/// a [RemoteException] with the given error and stack trace.
T _handleResponse<T>(Response response) {
  if (response.response != null) {
    return response.response as T;
  }
  throw new RemoteException(response.error!.toString(), response.stackTrace);
}

enum MessageType {
  boolean,
  error,
  executeDefinitionsPhaseRequest,
  instantiateMacroRequest,
  isExactlyTypeRequest,
  isSubtypeOfRequest,
  loadMacroRequest,
  resolveTypeRequest,
  macroClassIdentifier,
  macroInstanceIdentifier,
  macroExecutionResult,
  response,
  staticType,
}
