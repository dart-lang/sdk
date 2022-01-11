// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:mirrors';

import '../executor_shared/response_impls.dart';
import '../executor_shared/protocol.dart';
import '../api.dart';

/// Spawns a new isolate for loading and executing macros.
void spawn(SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    Response response;
    if (message is LoadMacroRequest) {
      response = await _loadMacro(message);
    } else if (message is InstantiateMacroRequest) {
      response = await _instantiateMacro(message);
    } else if (message is ExecuteDefinitionsPhaseRequest) {
      response = await _executeDefinitionsPhase(message);
    } else {
      throw new StateError('Unrecognized event type $message');
    }
    sendPort.send(response);
  });
}

/// Maps macro identifiers to class mirrors.
final _macroClasses = <MacroClassIdentifierImpl, ClassMirror>{};

/// Handles [LoadMacroRequest]s.
Future<Response> _loadMacro(LoadMacroRequest request) async {
  try {
    MacroClassIdentifierImpl identifier =
        new MacroClassIdentifierImpl(request.library, request.name);
    if (_macroClasses.containsKey(identifier)) {
      throw new UnsupportedError(
          'Reloading macros is not supported by this implementation');
    }
    LibraryMirror libMirror =
        await currentMirrorSystem().isolate.loadUri(request.library);
    ClassMirror macroClass =
        libMirror.declarations[new Symbol(request.name)] as ClassMirror;
    _macroClasses[identifier] = macroClass;
    return new Response(response: identifier, requestId: request.id);
  } catch (e) {
    return new Response(error: e, requestId: request.id);
  }
}

/// Maps macro instance identifiers to instances.
final _macroInstances = <MacroInstanceIdentifierImpl, Macro>{};

/// Handles [InstantiateMacroRequest]s.
Future<Response> _instantiateMacro(InstantiateMacroRequest request) async {
  try {
    ClassMirror? clazz = _macroClasses[request.macroClass];
    if (clazz == null) {
      throw new ArgumentError('Unrecognized macro class ${request.macroClass}');
    }
    Macro instance = clazz.newInstance(
        new Symbol(request.constructorName), request.arguments.positional, {
      for (MapEntry<String, Object?> entry in request.arguments.named.entries)
        new Symbol(entry.key): entry.value,
    }).reflectee as Macro;
    MacroInstanceIdentifierImpl identifier = new MacroInstanceIdentifierImpl();
    _macroInstances[identifier] = instance;
    return new Response(response: identifier, requestId: request.id);
  } catch (e) {
    return new Response(error: e, requestId: request.id);
  }
}

Future<Response> _executeDefinitionsPhase(
    ExecuteDefinitionsPhaseRequest request) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance ${request.macro}\n'
          'Known instances: $_macroInstances)');
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
      return new Response(response: builder.result, requestId: request.id);
    } else {
      throw new UnsupportedError(
          ('Only FunctionDefinitionMacros are supported currently'));
    }
  } catch (e) {
    return new Response(error: e, requestId: request.id);
  }
}
