// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates a Dart program for a given set of macros, which can be compiled
/// and then passed as a precompiled kernel file to `MacroExecutor.loadMacro`.
///
/// The [macroDeclarations] is a map from library URIs to macro classes for the
/// macros supported. The macro classes are provided as a map from macro class
/// names to the names of the macro class constructors.
String bootstrapMacroIsolate(
    Map<String, Map<String, List<String>>> macroDeclarations) {
  StringBuffer imports = new StringBuffer();
  StringBuffer constructorEntries = new StringBuffer();
  macroDeclarations
      .forEach((String macroImport, Map<String, List<String>> macroClasses) {
    imports.writeln('import \'$macroImport\';');
    macroClasses.forEach((String macroName, List<String> constructorNames) {
      constructorEntries
          .writeln("MacroClassIdentifierImpl(Uri.parse('$macroImport'), "
              "'$macroName'): {");
      for (String constructor in constructorNames) {
        constructorEntries.writeln("'$constructor': "
            "$macroName.${constructor.isEmpty ? 'new' : constructor},");
      }
      constructorEntries.writeln('},');
    });
  });
  return template.replaceFirst(_importMarker, imports.toString()).replaceFirst(
      _macroConstructorEntriesMarker, constructorEntries.toString());
}

const String _importMarker = '{{IMPORT}}';
const String _macroConstructorEntriesMarker = '{{MACRO_CONSTRUCTOR_ENTRIES}}';

const String template = '''
import 'dart:async';
import 'dart:isolate';

import 'package:_fe_analyzer_shared/src/macros/executor_shared/execute_macro.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/response_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/serialization.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/protocol.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

$_importMarker

/// Entrypoint to be spawned with [Isolate.spawnUri].
///
/// Supports the client side of the macro expansion protocol.
void main(_, SendPort sendPort) {
  /// Local function that sends requests and returns responses using [sendPort].
  Future<Response> sendRequest(Request request) => _sendRequest(request, sendPort);

  /// TODO: More directly support customizable serialization types.
  withSerializationMode(SerializationMode.jsonClient, () {
    ReceivePort receivePort = new ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      var deserializer = deserializerFactory(message)
          ..moveNext();
      int zoneId = deserializer.expectInt();
      deserializer..moveNext();
      var type = MessageType.values[deserializer.expectInt()];
      var serializer = serializerFactory();
      switch (type) {
        case MessageType.instantiateMacroRequest:
          var request = new InstantiateMacroRequest.deserialize(deserializer, zoneId);
          (await _instantiateMacro(request)).serialize(serializer);
          break;
        case MessageType.executeDeclarationsPhaseRequest:
          var request = new ExecuteDeclarationsPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeDeclarationsPhase(request, sendRequest)).serialize(serializer);
          break;
        case MessageType.executeDefinitionsPhaseRequest:
          var request = new ExecuteDefinitionsPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeDefinitionsPhase(request, sendRequest)).serialize(serializer);
          break;
        case MessageType.executeTypesPhaseRequest:
          var request = new ExecuteTypesPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeTypesPhase(request, sendRequest)).serialize(serializer);
          break;
        case MessageType.response:
          var response = new SerializableResponse.deserialize(deserializer, zoneId);
          _responseCompleters.remove(response.requestId)!.complete(response);
          return;
        default:
          throw new StateError('Unhandled event type \$type');
      }
      sendPort.send(serializer.result);
    });
  });
}

/// Maps macro identifiers to constructors.
final _macroConstructors = <MacroClassIdentifierImpl, Map<String, Macro Function()>>{
  $_macroConstructorEntriesMarker
};

/// Maps macro instance identifiers to instances.
final _macroInstances = <MacroInstanceIdentifierImpl, Macro>{};

/// Handles [InstantiateMacroRequest]s.
Future<SerializableResponse> _instantiateMacro(
    InstantiateMacroRequest request) async {
  try {
    var constructors = _macroConstructors[request.macroClass];
    if (constructors == null) {
      throw new ArgumentError('Unrecognized macro class \${request.macroClass}');
    }
    var constructor = constructors[request.constructorName];
    if (constructor == null) {
      throw new ArgumentError(
          'Unrecognized constructor name "\${request.constructorName}" for '
          'macro class "\${request.macroClass}".');
    }

    var instance = Function.apply(constructor, request.arguments.positional, {
      for (MapEntry<String, Object?> entry in request.arguments.named.entries)
        new Symbol(entry.key): entry.value,
    }) as Macro;
    var identifier = new MacroInstanceIdentifierImpl(instance, request.instanceId);
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
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }

    var result = await executeTypesMacro(instance, request.declaration);
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
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    var classIntrospector = ClientClassIntrospector(
        sendRequest,
        remoteInstance: request.classIntrospector,
        serializationZoneId: request.serializationZoneId);
    var typeResolver = ClientTypeResolver(
        sendRequest,
        remoteInstance: request.typeResolver,
        serializationZoneId: request.serializationZoneId);

    var result = await executeDeclarationsMacro(
        instance, request.declaration, classIntrospector, typeResolver);
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
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    var typeResolver = ClientTypeResolver(
        sendRequest,
        remoteInstance: request.typeResolver,
        serializationZoneId: request.serializationZoneId);
    var typeDeclarationResolver = ClientTypeDeclarationResolver(
        sendRequest,
        remoteInstance: request.typeDeclarationResolver,
        serializationZoneId: request.serializationZoneId);
    var classIntrospector = ClientClassIntrospector(
        sendRequest,
        remoteInstance: request.classIntrospector,
        serializationZoneId: request.serializationZoneId);

    var result = await executeDefinitionMacro(
        instance, request.declaration, classIntrospector, typeResolver,
        typeDeclarationResolver);
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

/// Holds on to response completers by request id.
final _responseCompleters = <int, Completer<Response>>{};

/// Serializes [request], sends it to [sendPort], and sets up a [Completer] in
/// [_responseCompleters] to handle the response.
Future<Response> _sendRequest(Request request, SendPort sendPort) {
  Completer<Response> completer = Completer();
  _responseCompleters[request.id] = completer;
  Serializer serializer = serializerFactory();
  serializer.addInt(request.serializationZoneId);
  request.serialize(serializer);
  sendPort.send(serializer.result);
  return completer.future;
}
''';
