// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generates a Dart program for a given macro, which can be compiled and then
/// passed as a precompiled kernel file to `MacroExecutor.loadMacro`.
String bootstrapMacroIsolate(
    String macroImport, String macroName, List<String> constructorNames) {
  StringBuffer constructorEntries = new StringBuffer(
      "MacroClassIdentifierImpl(Uri.parse('$macroImport'), '$macroName'): {");
  for (String constructor in constructorNames) {
    constructorEntries.writeln("'$constructor': "
        "$macroName.${constructor.isEmpty ? 'new' : constructor},");
  }
  constructorEntries.writeln('},');
  return template
      .replaceFirst(_importMarker, 'import \'$macroImport\';')
      .replaceFirst(
          _macroConstructorEntriesMarker, constructorEntries.toString());
}

const String _importMarker = '{{IMPORT}}';
const String _macroConstructorEntriesMarker = '{{MACRO_CONSTRUCTOR_ENTRIES}}';

const String template = '''
import 'dart:async';
import 'dart:isolate';

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

  withSerializationMode(SerializationMode.client, () {
    ReceivePort receivePort = new ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      var deserializer = JsonDeserializer(message as Iterable<Object?>)
          ..moveNext();
      int zoneId = deserializer.expectNum();
      deserializer..moveNext();
      var type = MessageType.values[deserializer.expectNum()];
      var serializer = JsonSerializer();
      switch (type) {
        case MessageType.instantiateMacroRequest:
          var request = new InstantiateMacroRequest.deserialize(deserializer, zoneId);
          (await _instantiateMacro(request)).serialize(serializer);
          break;
        case MessageType.executeDefinitionsPhaseRequest:
          var request = new ExecuteDefinitionsPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeDefinitionsPhase(request, sendRequest)).serialize(serializer);
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
    var identifier = new MacroInstanceIdentifierImpl();
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

    Declaration declaration = request.declaration;
    if (instance is FunctionDefinitionMacro &&
        declaration is FunctionDeclarationImpl) {
      FunctionDefinitionBuilderImpl builder = new FunctionDefinitionBuilderImpl(
          declaration,
          typeResolver,
          typeDeclarationResolver,
          classIntrospector);
      await instance.buildDefinitionForFunction(declaration, builder);
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: builder.result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } else if (instance is MethodDefinitionMacro
        && declaration is MethodDeclarationImpl) {
      FunctionDefinitionBuilderImpl builder = new FunctionDefinitionBuilderImpl(
          declaration,
          typeResolver,
          typeDeclarationResolver,
          classIntrospector);
      await instance.buildDefinitionForMethod(declaration, builder);
      var result = builder.result;
      // Wrap augmentations up as a part of the class
      if (result.augmentations.isNotEmpty) {
        result = MacroExecutionResultImpl(
          augmentations: [
            DeclarationCode.fromParts([
              'augment class ',
              declaration.definingClass,
              ' {\\n',
              ...result.augmentations,
              '\\n}',
            ]),
          ],
          imports: result.imports,
        );
      }
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } else {
      throw new UnsupportedError(
          'Unsupported macro type, only Method and Function Definition '
          'Macros are supported currently');
    }
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
  JsonSerializer serializer = JsonSerializer();
  serializer.addNum(request.serializationZoneId);
  request.serialize(serializer);
  sendPort.send(serializer.result);
  return completer.future;
}
''';
