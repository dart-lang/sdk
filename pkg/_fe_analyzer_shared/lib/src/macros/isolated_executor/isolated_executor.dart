// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import '../api.dart';
import '../executor_shared/protocol.dart';
import '../executor_shared/serialization.dart';
import '../executor_shared/response_impls.dart';
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
          Declaration declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector) =>
      _executors[macro]!.executeDeclarationsPhase(
          macro, declaration, typeResolver, classIntrospector);

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          Declaration declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _executors[macro]!.executeDefinitionsPhase(macro, declaration,
          typeResolver, classIntrospector, typeDeclarationResolver);

  @override
  Future<MacroExecutionResult> executeTypesPhase(
          MacroInstanceIdentifier macro, Declaration declaration) =>
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
  final Stream<Response> responseStream;

  /// The send port where we should send requests.
  final SendPort sendPort;

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() onClose;

  /// A map of response completers by request id.
  final responseCompleters = <int, Completer<Response>>{};

  _SingleIsolatedMacroExecutor(
      {required this.onClose,
      required this.responseStream,
      required this.sendPort}) {
    responseStream.listen((event) {
      Completer<Response>? completer =
          responseCompleters.remove(event.requestId);
      if (completer == null) {
        throw new StateError(
            'Got a response for an unrecognized request id ${event.requestId}');
      }
      completer.complete(event);
    });
  }

  static Future<_SingleIsolatedMacroExecutor> start(
      Uri library, String name, Uri precompiledKernelUri) async {
    ReceivePort receivePort = new ReceivePort();
    Isolate isolate =
        await Isolate.spawnUri(precompiledKernelUri, [], receivePort.sendPort);
    Completer<SendPort> sendPortCompleter = new Completer();
    StreamController<Response> responseStreamController =
        new StreamController(sync: true);
    receivePort.listen((message) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message as SendPort);
      } else {
        withSerializationMode(SerializationMode.server, () {
          JsonDeserializer deserializer =
              new JsonDeserializer(message as List<Object?>);
          SerializableResponse response =
              new SerializableResponse.deserialize(deserializer);
          responseStreamController.add(response);
        });
      }
    }).onDone(responseStreamController.close);

    return new _SingleIsolatedMacroExecutor(
        onClose: () {
          receivePort.close();
          isolate.kill();
        },
        responseStream: responseStreamController.stream,
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
      Declaration declaration,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector) {
    // TODO: implement executeDeclarationsPhase
    throw new UnimplementedError();
  }

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          Declaration declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _sendRequest(new ExecuteDefinitionsPhaseRequest(macro, declaration,
          typeResolver, classIntrospector, typeDeclarationResolver));

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
      _sendRequest(
          new InstantiateMacroRequest(macroClass, constructor, arguments));

  /// These calls are handled by the higher level executor.
  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
          {Uri? precompiledKernelUri}) =>
      throw new StateError('Unreachable');

  /// Sends a [request] and handles the response, casting it to the expected
  /// type or throwing the error provided.
  Future<T> _sendRequest<T>(Request request) =>
      withSerializationMode(SerializationMode.server, () async {
        JsonSerializer serializer = new JsonSerializer();
        request.serialize(serializer);
        sendPort.send(serializer.result);
        Completer<Response> completer = new Completer<Response>();
        responseCompleters[request.id] = completer;
        Response response = await completer.future;
        T? result = response.response as T?;
        if (result != null) return result;
        throw response.error!;
      });
}
