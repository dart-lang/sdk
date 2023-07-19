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
          // A response to a request we sent, everything else is a request from
          // the client.
          if (messageType == MessageType.response) {
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
            return;
          }

          // These are initialized in the switch below.
          final Serializable result;
          final MessageType resultType;
          int? requestId;

          // Initialized after the switch or in the catch handler.
          late final SerializableResponse response;
          try {
            switch (messageType) {
              case MessageType.resolveIdentifierRequest:
                ResolveIdentifierRequest request =
                    new ResolveIdentifierRequest.deserialize(
                        deserializer, zoneId);
                requestId = request.id;
                result = await (request.introspector.instance
                            as TypePhaseIntrospector)
                        // ignore: deprecated_member_use_from_same_package
                        .resolveIdentifier(request.library, request.name)
                    as IdentifierImpl;
                resultType = MessageType.remoteInstance;
              case MessageType.resolveTypeRequest:
                ResolveTypeRequest request =
                    new ResolveTypeRequest.deserialize(deserializer, zoneId);
                requestId = request.id;
                StaticType instance = await (request.introspector.instance
                        as DeclarationPhaseIntrospector)
                    .resolve(request.typeAnnotationCode);
                result = new RemoteInstanceImpl(
                    id: RemoteInstance.uniqueId,
                    instance: instance,
                    kind: instance is NamedStaticType
                        ? RemoteInstanceKind.namedStaticType
                        : RemoteInstanceKind.staticType);
                resultType = instance is NamedStaticType
                    ? MessageType.namedStaticType
                    : MessageType.staticType;
              case MessageType.inferTypeRequest:
                InferTypeRequest request =
                    new InferTypeRequest.deserialize(deserializer, zoneId);
                requestId = request.id;
                result = await (request.introspector.instance
                        as DefinitionPhaseIntrospector)
                    .inferType(request.omittedType) as TypeAnnotationImpl;
                resultType = MessageType.remoteInstance;
              case MessageType.isExactlyTypeRequest:
                IsExactlyTypeRequest request =
                    new IsExactlyTypeRequest.deserialize(deserializer, zoneId);
                requestId = request.id;
                StaticType leftType = request.leftType.instance as StaticType;
                StaticType rightType = request.rightType.instance as StaticType;
                result = new BooleanValue(await leftType.isExactly(rightType));
                resultType = MessageType.boolean;
              case MessageType.isSubtypeOfRequest:
                IsSubtypeOfRequest request =
                    new IsSubtypeOfRequest.deserialize(deserializer, zoneId);
                requestId = request.id;
                StaticType leftType = request.leftType.instance as StaticType;
                StaticType rightType = request.rightType.instance as StaticType;
                result =
                    new BooleanValue(await leftType.isSubtypeOf(rightType));
                resultType = MessageType.boolean;
              case MessageType.declarationOfRequest:
                DeclarationOfRequest request =
                    new DeclarationOfRequest.deserialize(
                        deserializer, zoneId, messageType);
                requestId = request.id;
                DefinitionPhaseIntrospector introspector = request
                    .introspector.instance as DefinitionPhaseIntrospector;
                result = (await introspector.declarationOf(request.identifier))
                    // TODO: Consider refactoring to avoid the need for
                    //  this cast.
                    as Serializable;
                resultType = MessageType.remoteInstance;
              case MessageType.typeDeclarationOfRequest:
                DeclarationOfRequest request =
                    new DeclarationOfRequest.deserialize(
                        deserializer, zoneId, messageType);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result =
                    (await introspector.typeDeclarationOf(request.identifier))
                        // TODO: Consider refactoring to avoid the need for
                        //  this cast.
                        as Serializable;
                resultType = MessageType.remoteInstance;
              case MessageType.constructorsOfRequest:
                TypeIntrospectorRequest request =
                    new TypeIntrospectorRequest.deserialize(
                        deserializer, messageType, zoneId);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result = new DeclarationList((await introspector.constructorsOf(
                        request.declaration as IntrospectableType))
                    // TODO: Consider refactoring to avoid the need for this.
                    .cast<ConstructorDeclarationImpl>());
                resultType = MessageType.declarationList;
              case MessageType.topLevelDeclarationsOfRequest:
                DeclarationsOfRequest request =
                    new DeclarationsOfRequest.deserialize(deserializer, zoneId);
                requestId = request.id;
                DefinitionPhaseIntrospector introspector = request
                    .introspector.instance as DefinitionPhaseIntrospector;
                result = new DeclarationList(// force newline
                    (await introspector.topLevelDeclarationsOf(request.library))
                        // TODO: Consider refactoring to avoid the need for
                        // this.
                        .cast<DeclarationImpl>());
                resultType = MessageType.declarationList;
              case MessageType.fieldsOfRequest:
                TypeIntrospectorRequest request =
                    new TypeIntrospectorRequest.deserialize(
                        deserializer, messageType, zoneId);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result = new DeclarationList((await introspector
                        .fieldsOf(request.declaration as IntrospectableType))
                    // TODO: Consider refactoring to avoid the need for this.
                    .cast<FieldDeclarationImpl>());
                resultType = MessageType.declarationList;
              case MessageType.methodsOfRequest:
                TypeIntrospectorRequest request =
                    new TypeIntrospectorRequest.deserialize(
                        deserializer, messageType, zoneId);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result = new DeclarationList((await introspector
                        .methodsOf(request.declaration as IntrospectableType))
                    // TODO: Consider refactoring to avoid the need for this.
                    .cast<MethodDeclarationImpl>());
                resultType = MessageType.declarationList;
              case MessageType.typesOfRequest:
                TypeIntrospectorRequest request =
                    new TypeIntrospectorRequest.deserialize(
                        deserializer, messageType, zoneId);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result = new DeclarationList((await introspector
                        .typesOf(request.declaration as Library))
                    // TODO: Consider refactoring to avoid the need for this.
                    .cast<TypeDeclarationImpl>());
                resultType = MessageType.declarationList;
              case MessageType.valuesOfRequest:
                TypeIntrospectorRequest request =
                    new TypeIntrospectorRequest.deserialize(
                        deserializer, messageType, zoneId);
                requestId = request.id;
                DeclarationPhaseIntrospector introspector = request
                    .introspector.instance as DeclarationPhaseIntrospector;
                result = new DeclarationList((await introspector
                        .valuesOf(request.declaration as IntrospectableEnum))
                    // TODO: Consider refactoring to avoid the need for this.
                    .cast<EnumValueDeclarationImpl>());
                resultType = MessageType.declarationList;
              default:
                throw new StateError('Unexpected message type $messageType');
            }
            response = new SerializableResponse(
                response: result,
                requestId: requestId,
                responseType: resultType,
                serializationZoneId: zoneId);
          } on ArgumentError catch (error) {
            // TODO: Something better here.
            if (requestId == null) rethrow;
            response = new SerializableResponse(
                error: '$error',
                requestId: requestId,
                responseType: MessageType.argumentError,
                serializationZoneId: zoneId);
          } catch (error, stackTrace) {
            // TODO: Something better here.
            if (requestId == null) rethrow;
            response = new SerializableResponse(
                error: '$error',
                stackTrace: '$stackTrace',
                requestId: requestId,
                responseType: MessageType.error,
                serializationZoneId: zoneId);
          }
          Serializer serializer = serializerFactory();
          response.serialize(serializer);
          sendResult(serializer);
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
          MacroTarget target,
          DeclarationPhaseIntrospector introspector) =>
      _sendRequest((zoneId) => new ExecuteDeclarationsPhaseRequest(
          macro,
          target as RemoteInstance,
          new RemoteInstanceImpl(
              instance: introspector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.declarationPhaseIntrospector),
          serializationZoneId: zoneId));

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          MacroTarget target,
          DefinitionPhaseIntrospector introspector) =>
      _sendRequest((zoneId) => new ExecuteDefinitionsPhaseRequest(
          macro,
          target as RemoteInstance,
          new RemoteInstanceImpl(
              instance: introspector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.definitionPhaseIntrospector),
          serializationZoneId: zoneId));

  @override
  Future<MacroExecutionResult> executeTypesPhase(MacroInstanceIdentifier macro,
          MacroTarget target, TypePhaseIntrospector introspector) =>
      _sendRequest((zoneId) => new ExecuteTypesPhaseRequest(
          macro,
          target as RemoteInstance,
          new RemoteInstanceImpl(
              instance: introspector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typePhaseIntrospector),
          serializationZoneId: zoneId));

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
          Uri library, String name, String constructor, Arguments arguments) =>
      _sendRequest((zoneId) => new InstantiateMacroRequest(
          library, name, constructor, arguments, RemoteInstance.uniqueId,
          serializationZoneId: zoneId));

  @override
  void disposeMacro(MacroInstanceIdentifier instance) =>
      _sendRequest((zoneId) =>
          new DisposeMacroRequest(instance, serializationZoneId: zoneId));

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
