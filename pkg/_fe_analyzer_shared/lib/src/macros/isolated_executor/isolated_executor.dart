// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';

import '../api.dart';
import '../executor_shared/introspection_impls.dart';
import '../executor_shared/protocol.dart';
import '../executor_shared/response_impls.dart';
import '../executor_shared/serialization.dart';
import '../executor.dart';

/// Returns an instance of [_IsolatedMacroExecutor].
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start() async => new _IsolatedMacroExecutor();

/// A [MacroExecutor] implementation which spawns a separate isolate for each
/// macro that is loaded. Each of these is wrapped in its own
/// [_SingleIsolatedMacroExecutor] which requests are delegated to.
///
/// This implementation requires precompiled kernel files when loading macros,
/// (you must pass a `precompiledKernelUri` to [loadMacro]).
///
/// Spawned isolates are not ran in the same isolate group, so objects are
/// serialized between isolates.
class _IsolatedMacroExecutor implements MacroExecutor {
  /// Individual executors indexed by [MacroClassIdentifier] or
  /// [MacroInstanceIdentifier].
  final _executors = <Object, _SingleIsolatedMacroExecutor>{};

  @override
  Future<String> buildAugmentationLibrary(
      Iterable<MacroExecutionResult> macroResults) {
    // TODO: implement buildAugmentationLibrary
    throw new UnimplementedError();
  }

  @override
  void close() {
    for (_SingleIsolatedMacroExecutor executor in _executors.values) {
      executor.close();
    }
  }

  @override
  Future<MacroExecutionResult> executeDeclarationsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector) =>
      _executors[macro]!.executeDeclarationsPhase(
          macro, declaration, typeResolver, classIntrospector);

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _executors[macro]!.executeDefinitionsPhase(macro, declaration,
          typeResolver, classIntrospector, typeDeclarationResolver);

  @override
  Future<MacroExecutionResult> executeTypesPhase(
          MacroInstanceIdentifier macro, DeclarationImpl declaration) =>
      _executors[macro]!.executeTypesPhase(macro, declaration);

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
      MacroClassIdentifier macroClass,
      String constructor,
      Arguments arguments) async {
    _SingleIsolatedMacroExecutor executor = _executors[macroClass]!;
    MacroInstanceIdentifier instance =
        await executor.instantiateMacro(macroClass, constructor, arguments);
    _executors[instance] = executor;
    return instance;
  }

  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
      {Uri? precompiledKernelUri}) async {
    if (precompiledKernelUri == null) {
      throw new UnsupportedError(
          'This environment requires a non-null `precompiledKernelUri` to be '
          'passed when loading macros.');
    }
    MacroClassIdentifier identifier =
        new MacroClassIdentifierImpl(library, name);
    _executors.remove(identifier)?.close();

    _SingleIsolatedMacroExecutor executor =
        await _SingleIsolatedMacroExecutor.start(
            library, name, precompiledKernelUri);
    _executors[identifier] = executor;
    return identifier;
  }
}

class _SingleIsolatedMacroExecutor extends MacroExecutor {
  /// The stream on which we receive responses.
  final Stream<Object> messageStream;

  /// The send port where we should send requests.
  final SendPort sendPort;

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() onClose;

  /// A map of response completers by request id.
  final responseCompleters = <int, Completer<Response>>{};

  /// We need to know which serialization zone to deserialize objects in, so
  /// that we read them from the correct cache. Each request creates its own
  /// zone which it stores here by ID and then responses are deserialized in
  /// the same zone.
  static final serializationZones = <int, Zone>{};

  /// Incrementing identifier for the serialization zone ids.
  static int _nextSerializationZoneId = 0;

  _SingleIsolatedMacroExecutor(
      {required this.onClose,
      required this.messageStream,
      required this.sendPort}) {
    messageStream.listen((message) {
      withSerializationMode(SerializationMode.server, () {
        JsonDeserializer deserializer =
            new JsonDeserializer(message as List<Object?>);
        // Every object starts with a zone ID which dictates the zone in which
        // we should deserialize the message.
        deserializer.moveNext();
        int zoneId = deserializer.expectNum();
        Zone zone = serializationZones[zoneId]!;
        zone.run(() async {
          deserializer.moveNext();
          MessageType messageType =
              MessageType.values[deserializer.expectNum()];
          switch (messageType) {
            case MessageType.response:
              SerializableResponse response =
                  new SerializableResponse.deserialize(deserializer, zoneId);
              Completer<Response>? completer =
                  responseCompleters.remove(response.requestId);
              if (completer == null) {
                throw new StateError(
                    'Got a response for an unrecognized request id '
                    '${response.requestId}');
              }
              completer.complete(response);
              break;
            case MessageType.resolveTypeRequest:
              ResolveTypeRequest request =
                  new ResolveTypeRequest.deserialize(deserializer, zoneId);
              StaticType instance =
                  await (request.typeResolver.instance as TypeResolver)
                      .resolve(request.typeAnnotation);
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
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.isExactlyTypeRequest:
              IsExactlyTypeRequest request =
                  new IsExactlyTypeRequest.deserialize(deserializer, zoneId);
              StaticType leftType = request.leftType.instance as StaticType;
              StaticType rightType = request.leftType.instance as StaticType;
              SerializableResponse response = new SerializableResponse(
                  response:
                      new BooleanValue(await leftType.isExactly(rightType)),
                  requestId: request.id,
                  responseType: MessageType.boolean,
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.isSubtypeOfRequest:
              IsSubtypeOfRequest request =
                  new IsSubtypeOfRequest.deserialize(deserializer, zoneId);
              StaticType leftType = request.leftType.instance as StaticType;
              StaticType rightType = request.leftType.instance as StaticType;
              SerializableResponse response = new SerializableResponse(
                  response:
                      new BooleanValue(await leftType.isSubtypeOf(rightType)),
                  requestId: request.id,
                  responseType: MessageType.boolean,
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.declarationOfRequest:
              DeclarationOfRequest request =
                  new DeclarationOfRequest.deserialize(deserializer, zoneId);
              NamedStaticType type = request.type.instance as NamedStaticType;
              TypeDeclarationResolver resolver = request
                  .typeDeclarationResolver.instance as TypeDeclarationResolver;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.remoteInstance,
                  response: (await resolver.declarationOf(type)
                      // TODO: Consider refactoring to avoid the need for this.
                      as TypeDeclarationImpl),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.constructorsOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await classIntrospector
                          .constructorsOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<ConstructorDeclarationImpl>()),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.fieldsOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await classIntrospector
                          .fieldsOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<FieldDeclarationImpl>()),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.interfacesOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await classIntrospector
                          .interfacesOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<ClassDeclarationImpl>()),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.methodsOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await classIntrospector
                          .methodsOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<MethodDeclarationImpl>()),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.mixinsOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.declarationList,
                  response: new DeclarationList((await classIntrospector
                          .mixinsOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      .cast<ClassDeclarationImpl>()),
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            case MessageType.superclassOfRequest:
              ClassIntrospectionRequest request =
                  new ClassIntrospectionRequest.deserialize(
                      deserializer, messageType, zoneId);
              ClassIntrospector classIntrospector =
                  request.classIntrospector.instance as ClassIntrospector;
              SerializableResponse response = new SerializableResponse(
                  requestId: request.id,
                  responseType: MessageType.remoteInstance,
                  response: (await classIntrospector
                          .superclassOf(request.classDeclaration))
                      // TODO: Consider refactoring to avoid the need for this.
                      as ClassDeclarationImpl?,
                  serializationZoneId: zoneId);
              JsonSerializer serializer = new JsonSerializer();
              response.serialize(serializer);
              sendPort.send(serializer.result);
              break;
            default:
              throw new StateError('Unexpected message type $messageType');
          }
        });
      });
    });
  }

  static Future<_SingleIsolatedMacroExecutor> start(
      Uri library, String name, Uri precompiledKernelUri) async {
    ReceivePort receivePort = new ReceivePort();
    Isolate isolate =
        await Isolate.spawnUri(precompiledKernelUri, [], receivePort.sendPort);
    Completer<SendPort> sendPortCompleter = new Completer();
    StreamController<Object> messageStreamController =
        new StreamController(sync: true);
    receivePort.listen((message) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message as SendPort);
      } else {
        messageStreamController.add(message);
      }
    }).onDone(messageStreamController.close);

    return new _SingleIsolatedMacroExecutor(
        onClose: () {
          receivePort.close();
          isolate.kill();
        },
        messageStream: messageStreamController.stream,
        sendPort: await sendPortCompleter.future);
  }

  @override
  void close() => onClose();

  /// These calls are handled by the higher level executor.
  @override
  Future<String> buildAugmentationLibrary(
          Iterable<MacroExecutionResult> macroResults) =>
      throw new StateError('Unreachable');

  @override
  Future<MacroExecutionResult> executeDeclarationsPhase(
      MacroInstanceIdentifier macro,
      DeclarationImpl declaration,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector) {
    // TODO: implement executeDeclarationsPhase
    throw new UnimplementedError();
  }

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _sendRequest((zoneId) => new ExecuteDefinitionsPhaseRequest(
          macro,
          declaration,
          new RemoteInstanceImpl(
              instance: typeResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeResolver),
          new RemoteInstanceImpl(
              instance: classIntrospector,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.classIntrospector),
          new RemoteInstanceImpl(
              instance: typeDeclarationResolver,
              id: RemoteInstance.uniqueId,
              kind: RemoteInstanceKind.typeDeclarationResolver),
          serializationZoneId: zoneId));

  @override
  Future<MacroExecutionResult> executeTypesPhase(
      MacroInstanceIdentifier macro, Declaration declaration) {
    // TODO: implement executeTypesPhase
    throw new UnimplementedError();
  }

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
          MacroClassIdentifier macroClass,
          String constructor,
          Arguments arguments) =>
      _sendRequest((zoneId) => new InstantiateMacroRequest(
          macroClass, constructor, arguments,
          serializationZoneId: zoneId));

  /// These calls are handled by the higher level executor.
  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
          {Uri? precompiledKernelUri}) =>
      throw new StateError('Unreachable');

  /// Creates a [Request] with a given serialization zone ID, and handles the
  /// response, casting it to the expected type or throwing the error provided.
  Future<T> _sendRequest<T>(Request Function(int) requestFactory) =>
      withSerializationMode(SerializationMode.server, () async {
        int zoneId = _nextSerializationZoneId++;
        serializationZones[zoneId] = Zone.current;
        Request request = requestFactory(zoneId);
        JsonSerializer serializer = new JsonSerializer();
        // It is our responsibility to add the zone ID header.
        serializer.addNum(zoneId);
        request.serialize(serializer);
        sendPort.send(serializer.result);
        Completer<Response> completer = new Completer<Response>();
        responseCompleters[request.id] = completer;
        try {
          Response response = await completer.future;
          T? result = response.response as T?;
          if (result != null) return result;
          throw new RemoteException(
              response.error!.toString(), response.stackTrace);
        } finally {
          // Clean up the zone after the request is done.
          serializationZones.remove(zoneId);
        }
      });
}
