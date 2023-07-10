// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/execute_macro.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/message_grouper.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/response_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// Implements the client side of the macro instantiation/expansion protocol.
final class MacroExpansionClient {
  /// A map of the instantiable macro constructors.
  ///
  /// The outer map is keyed by the URI of the library defining macros, whose
  /// values are Maps keyed
  final Map<Uri, Map<String, Map<String, Function>>> _macroConstructors;

  /// Maps macro instance identifiers to instances.
  final Map<MacroInstanceIdentifierImpl, Macro> _macroInstances = {};

  /// Holds on to response completers by request id.
  final Map<int, Completer<Response>> _responseCompleters = {};

  MacroExpansionClient._(void Function(Serializer) sendResult,
      Stream<Object?> messageStream, this._macroConstructors) {
    messageStream.listen((message) => _handleMessage(message, sendResult));
  }

  /// Spawns a client connecting either to [sendPort] or a socket address and
  /// port given in [arguments].
  static Future<MacroExpansionClient> start(
      SerializationMode serializationMode,
      Map<Uri, Map<String, Map<String, Function>>> macroConstructors,
      List<String> arguments,
      SendPort? sendPort) {
    return withSerializationMode(serializationMode, () async {
      // Function that sends the result of a `Serializer` using either
      // `sendPort` or `stdout`.
      void Function(Serializer) sendResult;

      // The stream for incoming messages, could be either a ReceivePort, stdin,
      // or a socket.
      Stream<Object?> messageStream;

      String? socketAddress;
      int? socketPort;
      if (arguments.isNotEmpty) {
        if (arguments.length != 2) {
          throw new ArgumentError(
              'Expected exactly two or zero arguments, got $arguments.');
        }
        socketAddress = arguments.first;
        socketPort = int.parse(arguments[1]);
      }

      if (sendPort != null) {
        ReceivePort receivePort = new ReceivePort();
        messageStream = receivePort;
        sendResult =
            (Serializer serializer) => _sendIsolateResult(serializer, sendPort);
        // If using isolate communication, first send a sendPort to the parent
        // isolate.
        sendPort.send(receivePort.sendPort);
      } else {
        late Stream<List<int>> inputStream;
        if (socketAddress != null && socketPort != null) {
          Socket socket = await Socket.connect(socketAddress, socketPort);
          // Nagle's algorithm slows us down >100x, disable it.
          socket.setOption(SocketOption.tcpNoDelay, true);
          sendResult = _sendIOSinkResultFactory(socket);
          inputStream = socket;
        } else {
          sendResult = _sendIOSinkResultFactory(stdout);
          inputStream = stdin;
        }
        if (serializationMode == SerializationMode.byteData) {
          messageStream = new MessageGrouper(inputStream).messageStream;
        } else if (serializationMode == SerializationMode.json) {
          messageStream = const Utf8Decoder()
              .bind(inputStream)
              .transform(const LineSplitter())
              .map((line) => jsonDecode(line)!);
        } else {
          throw new UnsupportedError(
              'Unsupported serialization mode $serializationMode for '
              'ProcessExecutor');
        }
      }

      return new MacroExpansionClient._(
          sendResult, messageStream, macroConstructors);
    });
  }

  void _handleMessage(
      Object? message, void Function(Serializer) sendResult) async {
    // Serializes `request` and sends it using `sendResult`.
    Future<Response> sendRequest(Request request) =>
        _sendRequest(request, sendResult);

    if (serializationMode == SerializationMode.byteData &&
        message is TransferableTypedData) {
      message = message.materialize().asUint8List();
    }
    Deserializer deserializer = deserializerFactory(message)..moveNext();
    int zoneId = deserializer.expectInt();
    await withRemoteInstanceZone(zoneId, () async {
      deserializer..moveNext();
      MessageType type = MessageType.values[deserializer.expectInt()];
      Serializer serializer = serializerFactory();
      switch (type) {
        case MessageType.instantiateMacroRequest:
          InstantiateMacroRequest request =
              new InstantiateMacroRequest.deserialize(deserializer, zoneId);
          (await _instantiateMacro(request)).serialize(serializer);
        case MessageType.disposeMacroRequest:
          DisposeMacroRequest request =
              new DisposeMacroRequest.deserialize(deserializer, zoneId);
          _macroInstances.remove(request.identifier);
          return;
        case MessageType.executeDeclarationsPhaseRequest:
          ExecuteDeclarationsPhaseRequest request =
              new ExecuteDeclarationsPhaseRequest.deserialize(
                  deserializer, zoneId);
          (await _executeDeclarationsPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.executeDefinitionsPhaseRequest:
          ExecuteDefinitionsPhaseRequest request =
              new ExecuteDefinitionsPhaseRequest.deserialize(
                  deserializer, zoneId);
          (await _executeDefinitionsPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.executeTypesPhaseRequest:
          ExecuteTypesPhaseRequest request =
              new ExecuteTypesPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeTypesPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.response:
          SerializableResponse response =
              new SerializableResponse.deserialize(deserializer, zoneId);
          _responseCompleters.remove(response.requestId)!.complete(response);
          return;
        case MessageType.destroyRemoteInstanceZoneRequest:
          DestroyRemoteInstanceZoneRequest request =
              new DestroyRemoteInstanceZoneRequest.deserialize(
                  deserializer, zoneId);
          destroyRemoteInstanceZone(request.serializationZoneId);
          return;
        default:
          throw new StateError('Unhandled event type $type');
      }
      sendResult(serializer);
    }, createIfMissing: true);
  }

  /// Handles [InstantiateMacroRequest]s.
  Future<SerializableResponse> _instantiateMacro(
      InstantiateMacroRequest request) async {
    try {
      Map<String, Map<String, Function>> classes =
          _macroConstructors[request.library] ??
              (throw new ArgumentError(
                  'Unrecognized macro library ${request.library}'));
      Map<String, Function> constructors = classes[request.name] ??
          (throw new ArgumentError(
              'Unrecognized macro class ${request.name} for library '
              '${request.library}'));
      Function constructor = constructors[request.constructor] ??
          (throw new ArgumentError(
              'Unrecognized constructor name "${request.constructor}" for '
              'macro class "${request.name}".'));

      Macro instance = Function.apply(constructor, [
        for (Argument argument in request.arguments.positional) argument.value,
      ], {
        for (MapEntry<String, Argument> entry
            in request.arguments.named.entries)
          new Symbol(entry.key): entry.value.value,
      }) as Macro;
      MacroInstanceIdentifierImpl identifier =
          new MacroInstanceIdentifierImpl(instance, request.instanceId);
      _macroInstances[identifier] = instance;
      return new SerializableResponse(
          responseType: MessageType.macroInstanceIdentifier,
          response: identifier,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return new SerializableResponse(
          responseType: MessageType.error,
          error: e.toString(),
          stackTrace: s.toString(),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeTypesPhase(
      ExecuteTypesPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw new StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));
      ClientIdentifierResolver identifierResolver =
          new ClientIdentifierResolver(sendRequest,
              remoteInstance: request.identifierResolver,
              serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result =
          await executeTypesMacro(instance, request.target, identifierResolver);
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return new SerializableResponse(
          responseType: MessageType.error,
          error: e.toString(),
          stackTrace: s.toString(),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeDeclarationsPhase(
      ExecuteDeclarationsPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw new StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));

      ClientIdentifierResolver identifierResolver =
          new ClientIdentifierResolver(sendRequest,
              remoteInstance: request.identifierResolver,
              serializationZoneId: request.serializationZoneId);
      ClientTypeIntrospector typeIntrospector = new ClientTypeIntrospector(
          sendRequest,
          remoteInstance: request.typeIntrospector,
          serializationZoneId: request.serializationZoneId);
      ClientTypeDeclarationResolver typeDeclarationResolver =
          new ClientTypeDeclarationResolver(sendRequest,
              remoteInstance: request.typeDeclarationResolver,
              serializationZoneId: request.serializationZoneId);
      ClientTypeResolver typeResolver = new ClientTypeResolver(sendRequest,
          remoteInstance: request.typeResolver,
          serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result = await executeDeclarationsMacro(
          instance,
          request.target,
          identifierResolver,
          typeIntrospector,
          typeDeclarationResolver,
          typeResolver);
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return new SerializableResponse(
          responseType: MessageType.error,
          error: e.toString(),
          stackTrace: s.toString(),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeDefinitionsPhase(
      ExecuteDefinitionsPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw new StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));
      ClientIdentifierResolver identifierResolver =
          new ClientIdentifierResolver(sendRequest,
              remoteInstance: request.identifierResolver,
              serializationZoneId: request.serializationZoneId);
      ClientTypeResolver typeResolver = new ClientTypeResolver(sendRequest,
          remoteInstance: request.typeResolver,
          serializationZoneId: request.serializationZoneId);
      ClientTypeDeclarationResolver typeDeclarationResolver =
          new ClientTypeDeclarationResolver(sendRequest,
              remoteInstance: request.typeDeclarationResolver,
              serializationZoneId: request.serializationZoneId);
      ClientTypeIntrospector typeIntrospector = new ClientTypeIntrospector(
          sendRequest,
          remoteInstance: request.typeIntrospector,
          serializationZoneId: request.serializationZoneId);
      ClientTypeInferrer typeInferrer = new ClientTypeInferrer(sendRequest,
          remoteInstance: request.typeInferrer,
          serializationZoneId: request.serializationZoneId);
      ClientLibraryDeclarationsResolver libraryDeclarationsResolver =
          new ClientLibraryDeclarationsResolver(sendRequest,
              remoteInstance: request.libraryDeclarationsResolver,
              serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result = await executeDefinitionMacro(
          instance,
          request.target,
          identifierResolver,
          typeIntrospector,
          typeResolver,
          typeDeclarationResolver,
          typeInferrer,
          libraryDeclarationsResolver);
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return new SerializableResponse(
          responseType: MessageType.error,
          error: e.toString(),
          stackTrace: s.toString(),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  /// Serializes [request], passes it to [sendResult], and sets up a [Completer]
  /// in [_responseCompleters] to handle the response.
  Future<Response> _sendRequest(
      Request request, void Function(Serializer serializer) sendResult) {
    Completer<Response> completer = new Completer();
    _responseCompleters[request.id] = completer;
    Serializer serializer = serializerFactory();
    serializer.addInt(request.serializationZoneId);
    request.serialize(serializer);
    sendResult(serializer);
    return completer.future;
  }
}

/// Sends [serializer.result] to [sendPort], possibly wrapping it in a
/// [TransferableTypedData] object.
void _sendIsolateResult(Serializer serializer, SendPort sendPort) {
  if (serializationMode == SerializationMode.byteData) {
    sendPort.send(
        new TransferableTypedData.fromList([serializer.result as Uint8List]));
  } else {
    sendPort.send(serializer.result);
  }
}

/// Returns a function which takes a [Serializer] and sends its result to
/// [sink].
///
/// Serializes the result to a string if using JSON.
void Function(Serializer) _sendIOSinkResultFactory(IOSink sink) =>
    (Serializer serializer) {
      if (serializationMode == SerializationMode.json) {
        sink.writeln(jsonEncode(serializer.result));
      } else if (serializationMode == SerializationMode.byteData) {
        Uint8List result = (serializer as ByteDataSerializer).result;
        int length = result.lengthInBytes;
        BytesBuilder bytesBuilder = new BytesBuilder(copy: false);
        bytesBuilder.add([
          length >> 24 & 0xff,
          length >> 16 & 0xff,
          length >> 8 & 0xff,
          length & 0xff,
        ]);
        bytesBuilder.add(result);
        sink.add(bytesBuilder.takeBytes());
      } else {
        throw new UnsupportedError(
            'Unsupported serialization mode $serializationMode for '
            'ProcessExecutor');
      }
    };
