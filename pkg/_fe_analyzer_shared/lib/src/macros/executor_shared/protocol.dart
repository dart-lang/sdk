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
import 'serialization_extensions.dart';

/// Base class all requests extend, provides a unique id for each request.
abstract class Request implements Serializable {
  final int id;

  final int serializationZoneId;

  Request({int? id, required this.serializationZoneId})
      : this.id = id ?? _next++;

  /// The [serializationZoneId] is a part of the header and needs to be parsed
  /// before deserializing objects, and then passed in here.
  Request.deserialize(Deserializer deserializer, this.serializationZoneId)
      : id = (deserializer..moveNext()).expectInt();

  /// The [serializationZoneId] needs to be separately serialized before the
  /// rest of the object. This is not done by the instances themselves but by
  /// the macro implementations.
  @mustCallSuper
  void serialize(Serializer serializer) => serializer.addInt(id);

  static int _next = 0;
}

/// A generic response object that contains either a response or an error, and
/// a unique ID.
class Response {
  final Object? response;
  final Object? error;
  final String? stackTrace;
  final int requestId;
  final MessageType responseType;

  Response({
    this.response,
    this.error,
    this.stackTrace,
    required this.requestId,
    required this.responseType,
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
  });

  /// You must first parse the [serializationZoneId] yourself, and then
  /// call this function in that zone, and pass the ID.
  factory SerializableResponse.deserialize(
      Deserializer deserializer, int serializationZoneId) {
    deserializer.moveNext();
    MessageType responseType = MessageType.values[deserializer.expectInt()];
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
      case MessageType.namedStaticType:
        response = RemoteInstance.deserialize(deserializer);
        break;
      case MessageType.boolean:
        response = new BooleanValue.deserialize(deserializer);
        break;
      case MessageType.declarationList:
        response = new DeclarationList.deserialize(deserializer);
        break;
      case MessageType.remoteInstance:
        deserializer.moveNext();
        if (!deserializer.checkNull()) {
          response = deserializer.expectRemoteInstance();
        }
        break;
      default:
        throw new StateError('Unexpected response type $responseType');
    }

    return new SerializableResponse(
        responseType: responseType,
        response: response,
        error: error,
        stackTrace: stackTrace,
        requestId: (deserializer..moveNext()).expectInt(),
        serializationZoneId: serializationZoneId);
  }

  void serialize(Serializer serializer) {
    serializer
      ..addInt(serializationZoneId)
      ..addInt(MessageType.response.index)
      ..addInt(responseType.index);
    switch (responseType) {
      case MessageType.error:
        serializer.addString(error!.toString());
        serializer.addNullableString(stackTrace);
        break;
      default:
        response.serializeNullable(serializer);
    }
    serializer.addInt(requestId);
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

/// A serialized list of [Declaration]s.
class DeclarationList<T extends DeclarationImpl> implements Serializable {
  final List<T> declarations;

  DeclarationList(this.declarations);

  DeclarationList.deserialize(Deserializer deserializer)
      : declarations = [
          for (bool hasNext = (deserializer
                    ..moveNext()
                    ..expectList())
                  .moveNext();
              hasNext;
              hasNext = deserializer.moveNext())
            deserializer.expectRemoteInstance(),
        ];

  @override
  void serialize(Serializer serializer) {
    serializer.startList();
    for (DeclarationImpl declaration in declarations) {
      declaration.serialize(serializer);
    }
    serializer.endList();
  }
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
      ..addInt(MessageType.loadMacroRequest.index)
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

  /// The ID to assign to the identifier, this needs to come from the requesting
  /// side so that it is unique.
  final int instanceId;

  InstantiateMacroRequest(
      this.macroClass, this.constructorName, this.arguments, this.instanceId,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  InstantiateMacroRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : macroClass = new MacroClassIdentifierImpl.deserialize(deserializer),
        constructorName = (deserializer..moveNext()).expectString(),
        arguments = new Arguments.deserialize(deserializer),
        instanceId = (deserializer..moveNext()).expectInt(),
        super.deserialize(deserializer, serializationZoneId);

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.instantiateMacroRequest.index);
    macroClass.serialize(serializer);
    serializer.addString(constructorName);
    arguments.serialize(serializer);
    serializer.addInt(instanceId);
    super.serialize(serializer);
  }
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteTypesPhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final DeclarationImpl declaration;

  ExecuteTypesPhaseRequest(this.macro, this.declaration,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecuteTypesPhaseRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : macro = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        declaration = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.executeTypesPhaseRequest.index);
    macro.serialize(serializer);
    declaration.serialize(serializer);

    super.serialize(serializer);
  }
}

/// A request to execute a macro on a particular declaration in the definition
/// phase.
class ExecuteDeclarationsPhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final DeclarationImpl declaration;

  final RemoteInstanceImpl typeResolver;
  final RemoteInstanceImpl classIntrospector;

  ExecuteDeclarationsPhaseRequest(
      this.macro, this.declaration, this.typeResolver, this.classIntrospector,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecuteDeclarationsPhaseRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : macro = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        declaration = RemoteInstance.deserialize(deserializer),
        typeResolver = RemoteInstance.deserialize(deserializer),
        classIntrospector = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.executeDeclarationsPhaseRequest.index);
    macro.serialize(serializer);
    declaration.serialize(serializer);
    typeResolver.serialize(serializer);
    classIntrospector.serialize(serializer);

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
    serializer.addInt(MessageType.executeDefinitionsPhaseRequest.index);
    macro.serialize(serializer);
    declaration.serialize(serializer);
    typeResolver.serialize(serializer);
    classIntrospector.serialize(serializer);
    typeDeclarationResolver.serialize(serializer);

    super.serialize(serializer);
  }
}

/// A request to resolve on a type annotation code object
class ResolveTypeRequest extends Request {
  final TypeAnnotationCode typeAnnotationCode;
  final RemoteInstanceImpl typeResolver;

  ResolveTypeRequest(this.typeAnnotationCode, this.typeResolver,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveTypeRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : typeAnnotationCode = (deserializer..moveNext()).expectCode(),
        typeResolver = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.resolveTypeRequest.index);
    typeAnnotationCode.serialize(serializer);
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
    serializer.addInt(MessageType.isExactlyTypeRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsSubtypeOfRequest extends Request {
  final RemoteInstanceImpl leftType;
  final RemoteInstanceImpl rightType;

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
    serializer.addInt(MessageType.isSubtypeOfRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A general request class for all requests coming from methods on the
/// [ClassIntrospector] interface.
class ClassIntrospectionRequest extends Request {
  final ClassDeclarationImpl classDeclaration;
  final RemoteInstanceImpl classIntrospector;
  final MessageType requestKind;

  ClassIntrospectionRequest(
      this.classDeclaration, this.classIntrospector, this.requestKind,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again and it should instead be passed in here.
  ClassIntrospectionRequest.deserialize(
      Deserializer deserializer, this.requestKind, int serializationZoneId)
      : classDeclaration = RemoteInstance.deserialize(deserializer),
        classIntrospector = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(requestKind.index);
    classDeclaration.serialize(serializer);
    classIntrospector.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get a [TypeDeclaration] for a [StaticType].
class DeclarationOfRequest extends Request {
  final IdentifierImpl identifier;
  final RemoteInstanceImpl typeDeclarationResolver;

  DeclarationOfRequest(this.identifier, this.typeDeclarationResolver,
      {required int serializationZoneId})
      : super(serializationZoneId: serializationZoneId);

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  DeclarationOfRequest.deserialize(
      Deserializer deserializer, int serializationZoneId)
      : identifier = RemoteInstance.deserialize(deserializer),
        typeDeclarationResolver = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.declarationOfRequest.index);
    identifier.serialize(serializer);
    typeDeclarationResolver.serialize(serializer);
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
  Future<StaticType> resolve(TypeAnnotationCode typeAnnotation) async {
    ResolveTypeRequest request = new ResolveTypeRequest(
        typeAnnotation, remoteInstance,
        serializationZoneId: serializationZoneId);
    RemoteInstanceImpl remoteType =
        _handleResponse(await _sendRequest(request));
    switch (remoteType.kind) {
      case RemoteInstanceKind.namedStaticType:
        return new ClientNamedStaticTypeImpl(_sendRequest,
            remoteInstance: remoteType,
            serializationZoneId: serializationZoneId);
      case RemoteInstanceKind.staticType:
        return new ClientStaticTypeImpl(_sendRequest,
            remoteInstance: remoteType,
            serializationZoneId: serializationZoneId);
      default:
        throw new StateError(
            'Expected either a StaticType or NamedStaticType but got '
            '${remoteType.kind}');
    }
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
    IsSubtypeOfRequest request = new IsSubtypeOfRequest(
        remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await sendRequest(request)).value;
  }
}

/// Named variant of the [ClientStaticTypeImpl].
class ClientNamedStaticTypeImpl extends ClientStaticTypeImpl
    implements NamedStaticType {
  ClientNamedStaticTypeImpl(
      Future<Response> Function(Request request) sendRequest,
      {required RemoteInstanceImpl remoteInstance,
      required int serializationZoneId})
      : super(sendRequest,
            remoteInstance: remoteInstance,
            serializationZoneId: serializationZoneId);
}

/// Client side implementation of the [ClientClassIntrospector], converts all
/// invocations into remote RPC calls.
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
  Future<List<ConstructorDeclaration>> constructorsOf(
      ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.constructorsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<FieldDeclaration>> fieldsOf(ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.fieldsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<ClassDeclaration>> interfacesOf(
      ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.interfacesOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<MethodDeclaration>> methodsOf(ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.methodsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<ClassDeclaration>> mixinsOf(ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.mixinsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclarationImpl clazz) async {
    ClassIntrospectionRequest request = new ClassIntrospectionRequest(
        clazz, remoteInstance, MessageType.superclassOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<ClassDeclaration?>(await sendRequest(request));
  }
}

/// Client side implementation of a [TypeDeclarationResolver], converts all
/// invocations into remote procedure calls.
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
  Future<TypeDeclaration> declarationOf(IdentifierImpl identifier) async {
    DeclarationOfRequest request = new DeclarationOfRequest(
        identifier, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<TypeDeclaration>(await sendRequest(request));
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
  if (response.responseType == MessageType.error) {
    throw new RemoteException(response.error!.toString(), response.stackTrace);
  }
  return response.response as T;
}

enum MessageType {
  boolean,
  constructorsOfRequest,
  declarationOfRequest,
  declarationList,
  fieldsOfRequest,
  interfacesOfRequest,
  methodsOfRequest,
  mixinsOfRequest,
  superclassOfRequest,
  error,
  executeDeclarationsPhaseRequest,
  executeDefinitionsPhaseRequest,
  executeTypesPhaseRequest,
  instantiateMacroRequest,
  resolveTypeRequest,
  isExactlyTypeRequest,
  isSubtypeOfRequest,
  loadMacroRequest,
  remoteInstance,
  macroClassIdentifier,
  macroInstanceIdentifier,
  macroExecutionResult,
  namedStaticType,
  response,
  staticType,
}
