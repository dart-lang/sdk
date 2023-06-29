// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';

import '../api.dart';
import '../executor/introspection_impls.dart';
import '../executor/protocol.dart';
import '../executor/serialization.dart';
import '../executor.dart';

/// Base implementation for macro executors which communicate with some external
/// process to run macros.
///
/// Subtypes must extend this class and implement the [close] and [sendResult]
/// apis to handle communication with the external macro program.
abstract class ExternalMacroExecutorBase extends MacroExecutor {
  /// The stream on which we receive messages from the external macro executor.
  final Stream<Object> messageStream;

  /// The mode to use for serialization - must be a `server` variant.
  final SerializationMode serializationMode;

  /// A map of response completers by request id.
  final _responseCompleters = <int, Completer<Response>>{};

  ExternalMacroExecutorBase(
      {required this.messageStream, required this.serializationMode}) {
    withSerializationMode(serializationMode, () {
      messageStream.listen((message) {
        // No need for a remote cache in this zone we only read a zone ID and
        // then immediately run in that zone.
        Deserializer deserializer = deserializerFactory(message);
        // Every object starts with a zone ID which dictates the zone in which
        // we should deserialize the message.
        deserializer.moveNext();
        int zoneId = deserializer.expectInt();
        withRemoteInstanceZone(zoneId, () async {
          deserializer.moveNext();
          MessageType messageType =
              MessageType.values[deserializer.expectInt()];
          switch (messageType) {
            case MessageType.response:
              SerializableResponse response =
                  new SerializableResponse.deserialize(deserializer, zoneId);
              Completer<Response>? completer =
                  _responseCompleters.remove(response.requestId);
              if (completer == null) {
                throw new StateError(
                    'Got a response for an unrecognized request id '
                    '${response.requestId}');
              }
              completer.complete(response);
              break;
            case MessageType.resolveIdentifierRequest:
              ResolveIdentifierRequest request =
                  new ResolveIdentifierRequest.deserialize(
                      deserializer, zoneId);
              SerializableResponse response;
              try {
                IdentifierImpl identifier = await (request
                            .identifierResolver.instance as IdentifierResolver)
                        // ignore: deprecated_member_use_from_same_package
                        .resolveIdentifier(request.library, request.name)
                    as IdentifierImpl;
                response = new SerializableResponse(
                    response: identifier,
                    requestId: request.id,
                    responseType: MessageType.remoteInstance,
                    serializationZoneId: zoneId);
              } catch (error, stackTrace) {
                response = new SerializableResponse(
                    error: '$error',
                    stackTrace: '$stackTrace',
                    requestId: request.id,
                    responseType: MessageType.error,
                    serializationZoneId: zoneId);
              }
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.resolveTypeRequest:
              ResolveTypeRequest request =
                  new ResolveTypeRequest.deserialize(deserializer, zoneId);
              StaticType instance =
                  await (request.typeResolver.instance as TypeResolver)
                      .resolve(request.typeAnnotationCode);
              SerializableResponse response = new SerializableResponse(
                  response: new RemoteInstanceImpl(
                      id: RemoteInstance.uniqueId,
                      instance: instance,
                      kind: instance is NamedStaticType
                          ? RemoteInstanceKind.namedStaticType
                          : RemoteInstanceKind.staticType),
                  requestId: request.id,
                  responseType: instance is NamedStaticType
                      ? MessageType.namedStaticType
                      : MessageType.staticType,
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.inferTypeRequest:
              InferTypeRequest request =
                  new InferTypeRequest.deserialize(deserializer, zoneId);
              TypeAnnotationImpl inferredType =
                  await (request.typeInferrer.instance as TypeInferrer)
                      .inferType(request.omittedType) as TypeAnnotationImpl;
              SerializableResponse response = new SerializableResponse(
                  response: inferredType,
                  requestId: request.id,
                  responseType: MessageType.remoteInstance,
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.isExactlyTypeRequest:
              IsExactlyTypeRequest request =
                  new IsExactlyTypeRequest.deserialize(deserializer, zoneId);
              StaticType leftType = request.leftType.instance as StaticType;
              StaticType rightType = request.rightType.instance as StaticType;
              SerializableResponse response = new SerializableResponse(
                  response:
                      new BooleanValue(await leftType.isExactly(rightType)),
                  requestId: request.id,
                  responseType: MessageType.boolean,
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.isSubtypeOfRequest:
              IsSubtypeOfRequest request =
                  new IsSubtypeOfRequest.deserialize(deserializer, zoneId);
              StaticType leftType = request.leftType.instance as StaticType;
              StaticType rightType = request.rightType.instance as StaticType;
              SerializableResponse response = new SerializableResponse(
                  response:
                      new BooleanValue(await leftType.isSubtypeOf(rightType)),
                  requestId: request.id,
                  responseType: MessageType.boolean,
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.declarationOfRequest:
              DeclarationOfRequest request =
                  new DeclarationOfRequest.deserialize(deserializer, zoneId);
              SerializableResponse response;
              try {
                TypeDeclarationResolver resolver = request
                    .typeDeclarationResolver
                    .instance as TypeDeclarationResolver;
                response = new SerializableResponse(
                    requestId: request.id,
                    responseType: MessageType.remoteInstance,
                    response: (await resolver.declarationOf(request.identifier)
                        // TODO: Consider refactoring to avoid the need for
                        //  this cast.
                        as Serializable),
                    serializationZoneId: zoneId);
              } on ArgumentError catch (error) {
                response = new SerializableResponse(
                    error: '$error',
                    requestId: request.id,
                    responseType: MessageType.argumentError,
                    serializationZoneId: zoneId);
              } catch (error, stackTrace) {
                // TODO(johnniwinther,jakemac): How should we handle errors in
                // general?
                response = new SerializableResponse(
                    error: '$error',
                    stackTrace: '$stackTrace',
                    requestId: request.id,
                    responseType: MessageType.error,
                    serializationZoneId: zoneId);
              }
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.constructorsOfRequest:
              TypeIntrospectorRequest request =
                  new TypeIntrospectorRequest.deserialize(
                      deserializer, messageType, zoneId);
              TypeIntrospector typeIntrospector =
                  request.typeIntrospector.instance as TypeIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await typeIntrospector
                          .constructorsOf(
                              request.declaration as IntrospectableType))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<ConstructorDeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.topLevelDeclarationsOfRequest:
              DeclarationsOfRequest request =
                  new DeclarationsOfRequest.deserialize(deserializer, zoneId);
              LibraryDeclarationsResolver libraryDeclarationsResolver = request
                  .libraryDeclarationsResolver
                  .instance as LibraryDeclarationsResolver;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList(// force newline
                      (await libraryDeclarationsResolver
                              .topLevelDeclarationsOf(request.library))
                          // TODO: Consider refactoring to avoid the need for
                          // this.
                          .cast<DeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.fieldsOfRequest:
              TypeIntrospectorRequest request =
                  new TypeIntrospectorRequest.deserialize(
                      deserializer, messageType, zoneId);
              TypeIntrospector typeIntrospector =
                  request.typeIntrospector.instance as TypeIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await typeIntrospector
                          .fieldsOf(request.declaration as IntrospectableType))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<FieldDeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.methodsOfRequest:
              TypeIntrospectorRequest request =
                  new TypeIntrospectorRequest.deserialize(
                      deserializer, messageType, zoneId);
              TypeIntrospector typeIntrospector =
                  request.typeIntrospector.instance as TypeIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await typeIntrospector
                          .methodsOf(request.declaration as IntrospectableType))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<MethodDeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.typesOfRequest:
              TypeIntrospectorRequest request =
                  new TypeIntrospectorRequest.deserialize(
                      deserializer, messageType, zoneId);
              TypeIntrospector typeIntrospector =
                  request.typeIntrospector.instance as TypeIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await typeIntrospector
                          .typesOf(request.declaration as Library))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<TypeDeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            case MessageType.valuesOfRequest:
              TypeIntrospectorRequest request =
                  new TypeIntrospectorRequest.deserialize(
                      deserializer, messageType, zoneId);
              TypeIntrospector typeIntrospector =
                  request.typeIntrospector.instance as TypeIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await typeIntrospector
                          .valuesOf(request.declaration as IntrospectableEnum))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<EnumValueDeclarationImpl>()),
                  serializationZoneId: zoneId);
              Serializer serializer = serializerFactory();
              response.serialize(serializer);
              sendResult(serializer);
              break;
            default:
              throw new StateError('Unexpected message type $messageType');
          }
        });
      });
    });
  }

  /// These calls are handled by the higher level executor.
  @override
  String buildAugmentationLibrary(
          Iterable<MacroExecutionResult> macroResults,
          TypeDeclaration Function(Identifier) resolveDeclaration,
          ResolvedIdentifier Function(Identifier) resolveIdentifier,
          TypeAnnotation? Function(OmittedTypeAnnotation) inferOmittedType,
          {Map<OmittedTypeAnnotation, String>? omittedTypes}) =>
      throw new StateError('Unreachable');

  @override
  Future<MacroExecutionResult> executeDeclarationsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeDeclarationResolver typeDeclarationResolver,
          TypeResolver typeResolver,
          TypeIntrospector typeIntrospector) =>
      _sendRequest((zoneId) => new ExecuteDeclarationsPhaseRequest(
          macro,
          declaration,
          new RemoteInstanceImpl(
              instance: identifierResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.identifierResolver),
          new RemoteInstanceImpl(
              instance: typeDeclarationResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeDeclarationResolver),
          new RemoteInstanceImpl(
              instance: typeResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeResolver),
          new RemoteInstanceImpl(
              instance: typeIntrospector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeIntrospector),
          serializationZoneId: zoneId));

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeDeclarationResolver typeDeclarationResolver,
          TypeResolver typeResolver,
          TypeIntrospector typeIntrospector,
          TypeInferrer typeInferrer,
          LibraryDeclarationsResolver libraryDeclarationsResolver) =>
      _sendRequest((zoneId) => new ExecuteDefinitionsPhaseRequest(
          macro,
          declaration,
          new RemoteInstanceImpl(
              instance: identifierResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.identifierResolver),
          new RemoteInstanceImpl(
              instance: typeResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeResolver),
          new RemoteInstanceImpl(
              instance: typeIntrospector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeIntrospector),
          new RemoteInstanceImpl(
              instance: typeDeclarationResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeDeclarationResolver),
          new RemoteInstanceImpl(
              instance: typeInferrer,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeInferrer),
          new RemoteInstanceImpl(
              instance: libraryDeclarationsResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.libraryDeclarationsResolver),
          serializationZoneId: zoneId));

  @override
  Future<MacroExecutionResult> executeTypesPhase(MacroInstanceIdentifier macro,
          DeclarationImpl declaration, IdentifierResolver identifierResolver) =>
      _sendRequest((zoneId) => new ExecuteTypesPhaseRequest(
          macro,
          declaration,
          new RemoteInstanceImpl(
              instance: identifierResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.identifierResolver),
          serializationZoneId: zoneId));

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
          Uri library, String name, String constructor, Arguments arguments) =>
      _sendRequest((zoneId) => new InstantiateMacroRequest(
          library, name, constructor, arguments, RemoteInstance.uniqueId,
          serializationZoneId: zoneId));

  /// Sends [serializer.result] to [sendPort], possibly wrapping it in a
  /// [TransferableTypedData] object.
  void sendResult(Serializer serializer);

  /// Creates a [Request] with a given serialization zone ID, and handles the
  /// response, casting it to the expected type or throwing the error provided.
  Future<T> _sendRequest<T>(Request Function(int) requestFactory) =>
      withSerializationMode(serializationMode, () {
        final int zoneId = newRemoteInstanceZone();
        return withRemoteInstanceZone(zoneId, () async {
          Request request = requestFactory(zoneId);
          Serializer serializer = serializerFactory();
          // It is our responsibility to add the zone ID header.
          serializer.addInt(zoneId);
          request.serialize(serializer);
          sendResult(serializer);
          Completer<Response> completer = new Completer<Response>();
          _responseCompleters[request.id] = completer;
          try {
            Response response = await completer.future;
            T? result = response.response as T?;
            if (result != null) return result;
            throw new RemoteException(
                response.error!.toString(), response.stackTrace);
          } finally {
            // Clean up the zone after the request is done.
            destroyRemoteInstanceZone(zoneId);
            // Tell the remote client to clean it up as well.
            Serializer serializer = serializerFactory();
            serializer.addInt(zoneId);
            new DestroyRemoteInstanceZoneRequest(serializationZoneId: zoneId)
                .serialize(serializer);
            sendResult(serializer);
          }
        });
      });
}
