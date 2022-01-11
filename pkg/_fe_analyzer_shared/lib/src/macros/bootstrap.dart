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
  withSerializationMode(SerializationMode.client, () {
    ReceivePort receivePort = new ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      var deserializer = JsonDeserializer(message as Iterable<Object?>)
          ..moveNext();
      var type = MessageType.values[deserializer.expectNum()];
      var serializer = JsonSerializer();
      switch (type) {
        case MessageType.instantiateMacroRequest:
          var request = InstantiateMacroRequest.deserialize(deserializer);
          (await _instantiateMacro(request)).serialize(serializer);
          break;
        case MessageType.executeDefinitionsPhaseRequest:
          var request = ExecuteDefinitionsPhaseRequest.deserialize(
              deserializer,
              ClientTypeResolver(),
              ClientClassIntrospector(),
              ClientTypeDeclarationsResolver());
          (await _executeDefinitionsPhase(request)).serialize(serializer);
          break;
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
        requestId: request.id);
  } catch (e) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      requestId: request.id);
  }
}

Future<SerializableResponse> _executeDefinitionsPhase(
    ExecuteDefinitionsPhaseRequest request) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    Declaration declaration = request.declaration;
    if (instance is FunctionDefinitionMacro &&
        declaration is FunctionDeclaration) {
      FunctionDefinitionBuilderImpl builder = new FunctionDefinitionBuilderImpl(
          declaration,
          request.typeResolver,
          request.typeDeclarationResolver,
          request.classIntrospector);
      await instance.buildDefinitionForFunction(declaration, builder);
      return new SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: builder.result,
          requestId: request.id);
    } else {
      throw new UnsupportedError(
          ('Only FunctionDefinitionMacros are supported currently'));
    }
  } catch (e) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      requestId: request.id);
  }
}
''';
