// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the objects used for communication between the macro executor and
/// the isolate or process doing the work of macro loading and execution.
library _fe_analyzer_shared.src.macros.executor_shared.protocol;

import 'package:meta/meta.dart';

import '../executor.dart';
import '../api.dart';
import '../executor/response_impls.dart';
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
  @override
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
  @override
  final Serializable? response;
  @override
  final MessageType responseType;
  @override
  final String? error;
  @override
  final String? stackTrace;
  @override
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
      case MessageType.argumentError:
        deserializer.moveNext();
        error = deserializer.expectString();
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

  @override
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
      case MessageType.argumentError:
        serializer.addString(error!.toString());
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

  LoadMacroRequest(this.library, this.name,
      {required super.serializationZoneId});

  LoadMacroRequest.deserialize(super.deserializer, super.serializationZoneId)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize();

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
  final Uri library;
  final String name;
  final String constructor;
  final Arguments arguments;

  /// The ID to assign to the identifier, this needs to come from the requesting
  /// side so that it is unique.
  final int instanceId;

  InstantiateMacroRequest(this.library, this.name, this.constructor,
      this.arguments, this.instanceId,
      {required super.serializationZoneId});

  InstantiateMacroRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = (deserializer..moveNext()).expectUri(),
        name = (deserializer..moveNext()).expectString(),
        constructor = (deserializer..moveNext()).expectString(),
        arguments = new Arguments.deserialize(deserializer),
        instanceId = (deserializer..moveNext()).expectInt(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.instantiateMacroRequest.index)
      ..addUri(library)
      ..addString(name)
      ..addString(constructor)
      ..addSerializable(arguments)
      ..addInt(instanceId);
    super.serialize(serializer);
  }
}

/// A request to dispose a macro instance by ID.
class DisposeMacroRequest extends Request {
  final MacroInstanceIdentifier identifier;

  DisposeMacroRequest(this.identifier, {required super.serializationZoneId});

  DisposeMacroRequest.deserialize(super.deserializer, super.serializationZoneId)
      : identifier = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.disposeMacroRequest.index);
    serializer..addSerializable(identifier);
    super.serialize(serializer);
  }
}

/// Base class for the requests to execute a macro in a certain phase.
abstract class ExecutePhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final RemoteInstance target;
  final RemoteInstanceImpl introspector;

  MessageType get kind;

  ExecutePhaseRequest(this.macro, this.target, this.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ExecutePhaseRequest.deserialize(super.deserializer, super.serializationZoneId)
      : macro = new MacroInstanceIdentifierImpl.deserialize(deserializer),
        target = RemoteInstance.deserialize(deserializer),
        introspector = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(kind.index);
    macro.serialize(serializer);
    target.serialize(serializer);
    introspector.serialize(serializer);

    super.serialize(serializer);
  }
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteTypesPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeTypesPhaseRequest;

  ExecuteTypesPhaseRequest(super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteTypesPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteDeclarationsPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeDeclarationsPhaseRequest;

  ExecuteDeclarationsPhaseRequest(
      super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteDeclarationsPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to execute a macro on a particular declaration in the types phase.
class ExecuteDefinitionsPhaseRequest extends ExecutePhaseRequest {
  @override
  MessageType get kind => MessageType.executeDefinitionsPhaseRequest;

  ExecuteDefinitionsPhaseRequest(
      super.macro, super.target, super.identifierResolver,
      {required super.serializationZoneId});

  ExecuteDefinitionsPhaseRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();
}

/// A request to destroy a remote instance zone by id.
class DestroyRemoteInstanceZoneRequest extends Request {
  DestroyRemoteInstanceZoneRequest({required super.serializationZoneId});

  DestroyRemoteInstanceZoneRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.destroyRemoteInstanceZoneRequest.index);
    super.serialize(serializer);
  }
}

class IntrospectionRequest extends Request {
  final RemoteInstanceImpl introspector;

  IntrospectionRequest(this.introspector, {required super.serializationZoneId});

  IntrospectionRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : introspector = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    introspector.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to create a resolved identifier.
class ResolveIdentifierRequest extends IntrospectionRequest {
  final Uri library;
  final String name;

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveIdentifierRequest(this.library, this.name, super.introspector,
      {required super.serializationZoneId});

  ResolveIdentifierRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = Uri.parse((deserializer..moveNext()).expectString()),
        name = (deserializer..moveNext()).expectString(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer
      ..addInt(MessageType.resolveIdentifierRequest.index)
      ..addString(library.toString())
      ..addString(name);

    super.serialize(serializer);
  }
}

/// A request to resolve on a type annotation code object
class ResolveTypeRequest extends IntrospectionRequest {
  final TypeAnnotationCode typeAnnotationCode;

  ResolveTypeRequest(this.typeAnnotationCode, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  ResolveTypeRequest.deserialize(super.deserializer, super.serializationZoneId)
      : typeAnnotationCode = (deserializer..moveNext()).expectCode(),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.resolveTypeRequest.index);
    typeAnnotationCode.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to check if a type is exactly another type.
class IsExactlyTypeRequest extends Request {
  final RemoteInstanceImpl leftType;
  final RemoteInstanceImpl rightType;

  IsExactlyTypeRequest(this.leftType, this.rightType,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsExactlyTypeRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
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
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  IsSubtypeOfRequest.deserialize(super.deserializer, super.serializationZoneId)
      : leftType = RemoteInstance.deserialize(deserializer),
        rightType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.isSubtypeOfRequest.index);
    leftType.serialize(serializer);
    rightType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A general request class for all requests coming from methods on the
/// [DeclarationPhaseIntrospector] interface that are related to a single type.
class TypeIntrospectorRequest extends IntrospectionRequest {
  final Object declaration;
  final MessageType requestKind;

  TypeIntrospectorRequest(
      this.declaration, super.introspector, this.requestKind,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again and it should instead be passed in here.
  TypeIntrospectorRequest.deserialize(
      Deserializer deserializer, this.requestKind, int serializationZoneId)
      : declaration = RemoteInstance.deserialize(deserializer),
        super.deserialize(deserializer, serializationZoneId);

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(requestKind.index);
    (declaration as Serializable).serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get a [TypeDeclaration] for a [StaticType].
class DeclarationOfRequest extends IntrospectionRequest {
  final IdentifierImpl identifier;

  DeclarationOfRequest(this.identifier, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  DeclarationOfRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : identifier = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.declarationOfRequest.index);
    identifier.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get an inferred [TypeAnnotation] for an
/// [OmittedTypeAnnotation].
class InferTypeRequest extends IntrospectionRequest {
  final OmittedTypeAnnotationImpl omittedType;

  InferTypeRequest(this.omittedType, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  InferTypeRequest.deserialize(super.deserializer, super.serializationZoneId)
      : omittedType = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.inferTypeRequest.index);
    omittedType.serialize(serializer);
    super.serialize(serializer);
  }
}

/// A request to get all the top level [Declaration]s in a [Library].
class DeclarationsOfRequest extends IntrospectionRequest {
  final LibraryImpl library;

  DeclarationsOfRequest(this.library, super.introspector,
      {required super.serializationZoneId});

  /// When deserializing we have already consumed the message type, so we don't
  /// consume it again.
  DeclarationsOfRequest.deserialize(
      super.deserializer, super.serializationZoneId)
      : library = RemoteInstance.deserialize(deserializer),
        super.deserialize();

  @override
  void serialize(Serializer serializer) {
    serializer.addInt(MessageType.topLevelDeclarationsOfRequest.index);
    library.serialize(serializer);
    super.serialize(serializer);
  }
}

/// The base class for the client side introspectors from any phase, as well as
/// client side [StaticType]s.
///
/// These convert all method calls into RPCs, sent via [_sendRequest].
base class ClientIntrospector {
  /// The actual remote instance to call methods on.
  final RemoteInstanceImpl remoteInstance;

  /// The ID of the zone in which to find the original builder.
  final int serializationZoneId;

  /// A function that can send a request and return a response using an
  /// arbitrary communication channel.
  final Future<Response> Function(Request request) _sendRequest;

  ClientIntrospector(this._sendRequest,
      {required this.remoteInstance, required this.serializationZoneId});
}

/// Client side implementation of an [TypeBuilder], which creates converts all
/// method calls to remote procedure calls and sends them using [_sendRequest].
final class ClientTypePhaseIntrospector extends ClientIntrospector
    implements TypePhaseIntrospector {
  ClientTypePhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<Identifier> resolveIdentifier(Uri library, String name) async {
    ResolveIdentifierRequest request = new ResolveIdentifierRequest(
        library, name, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse(await _sendRequest(request));
  }
}

/// Client side implementation of a [DeclarationBuilder].
final class ClientDeclarationPhaseIntrospector
    extends ClientTypePhaseIntrospector
    implements DeclarationPhaseIntrospector {
  ClientDeclarationPhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<StaticType> resolve(TypeAnnotationCode typeAnnotation) async {
    ResolveTypeRequest request = new ResolveTypeRequest(
        typeAnnotation, remoteInstance,
        serializationZoneId: serializationZoneId);
    RemoteInstanceImpl remoteType =
        _handleResponse(await _sendRequest(request));
    return switch (remoteType.kind) {
      RemoteInstanceKind.namedStaticType => new ClientNamedStaticTypeImpl(
          _sendRequest,
          remoteInstance: remoteType,
          serializationZoneId: serializationZoneId),
      RemoteInstanceKind.staticType => new ClientStaticTypeImpl(_sendRequest,
          remoteInstance: remoteType, serializationZoneId: serializationZoneId),
      _ => throw new StateError(
          'Expected either a StaticType or NamedStaticType but got '
          '${remoteType.kind}'),
    };
  }

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
      IntrospectableType type) async {
    TypeIntrospectorRequest request = new TypeIntrospectorRequest(
        type, remoteInstance, MessageType.constructorsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<EnumValueDeclaration>> valuesOf(
      IntrospectableEnum enumType) async {
    TypeIntrospectorRequest request = new TypeIntrospectorRequest(
        enumType, remoteInstance, MessageType.valuesOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<FieldDeclaration>> fieldsOf(IntrospectableType type) async {
    TypeIntrospectorRequest request = new TypeIntrospectorRequest(
        type, remoteInstance, MessageType.fieldsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<MethodDeclaration>> methodsOf(IntrospectableType type) async {
    TypeIntrospectorRequest request = new TypeIntrospectorRequest(
        type, remoteInstance, MessageType.methodsOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast
        .cast();
  }

  @override
  Future<List<TypeDeclaration>> typesOf(Library library) async {
    TypeIntrospectorRequest request = new TypeIntrospectorRequest(
        library, remoteInstance, MessageType.typesOfRequest,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations
        // TODO: Refactor so we can remove this cast.
        .cast();
  }

  @override
  Future<TypeDeclaration> declarationOf(IdentifierImpl identifier) async {
    DeclarationOfRequest request = new DeclarationOfRequest(
        identifier, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<TypeDeclaration>(await _sendRequest(request));
  }
}

/// Client side implementation of a [StaticType].
base class ClientStaticTypeImpl extends ClientIntrospector
    implements StaticType {
  ClientStaticTypeImpl(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<bool> isExactly(ClientStaticTypeImpl other) async {
    IsExactlyTypeRequest request = new IsExactlyTypeRequest(
        this.remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await _sendRequest(request)).value;
  }

  @override
  Future<bool> isSubtypeOf(ClientStaticTypeImpl other) async {
    IsSubtypeOfRequest request = new IsSubtypeOfRequest(
        remoteInstance, other.remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<BooleanValue>(await _sendRequest(request)).value;
  }
}

/// Named variant of the [ClientStaticTypeImpl].
final class ClientNamedStaticTypeImpl extends ClientStaticTypeImpl
    implements NamedStaticType {
  ClientNamedStaticTypeImpl(super.sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});
}

/// Client side implementation of a [DeclarationBuilder].
final class ClientDefinitionPhaseIntrospector
    extends ClientDeclarationPhaseIntrospector
    implements DefinitionPhaseIntrospector {
  ClientDefinitionPhaseIntrospector(super._sendRequest,
      {required super.remoteInstance, required super.serializationZoneId});

  @override
  Future<TypeAnnotation> inferType(
      OmittedTypeAnnotationImpl omittedType) async {
    InferTypeRequest request = new InferTypeRequest(omittedType, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<TypeAnnotation>(await _sendRequest(request));
  }

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(LibraryImpl library) async {
    DeclarationsOfRequest request = new DeclarationsOfRequest(
        library, remoteInstance,
        serializationZoneId: serializationZoneId);
    return _handleResponse<DeclarationList>(await _sendRequest(request))
        .declarations;
  }
}

/// An exception that occurred remotely, the exception object and stack trace
/// are serialized as [String]s and both included in the [toString] output.
class RemoteException implements Exception {
  final String error;
  final String? stackTrace;

  RemoteException(this.error, [this.stackTrace]);

  @override
  String toString() =>
      'RemoteException: $error${stackTrace == null ? '' : '\n\n$stackTrace'}';
}

/// Either returns the actual response from [response], casted to [T], or throws
/// a [RemoteException] with the given error and stack trace.
T _handleResponse<T>(Response response) {
  if (response.responseType == MessageType.error) {
    throw new RemoteException(response.error!.toString(), response.stackTrace);
  } else if (response.responseType == MessageType.argumentError) {
    throw new ArgumentError(response.error!.toString());
  }

  return response.response as T;
}

enum MessageType {
  argumentError,
  boolean,
  constructorsOfRequest,
  declarationOfRequest,
  declarationList,
  destroyRemoteInstanceZoneRequest,
  disposeMacroRequest,
  valuesOfRequest,
  fieldsOfRequest,
  methodsOfRequest,
  error,
  executeDeclarationsPhaseRequest,
  executeDefinitionsPhaseRequest,
  executeTypesPhaseRequest,
  instantiateMacroRequest,
  resolveIdentifierRequest,
  resolveTypeRequest,
  inferTypeRequest,
  isExactlyTypeRequest,
  isSubtypeOfRequest,
  loadMacroRequest,
  remoteInstance,
  macroInstanceIdentifier,
  macroExecutionResult,
  namedStaticType,
  response,
  staticType,
  topLevelDeclarationsOfRequest,
  typesOfRequest,
}
