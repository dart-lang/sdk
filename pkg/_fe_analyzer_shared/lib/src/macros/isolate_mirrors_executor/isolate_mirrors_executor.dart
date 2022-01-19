// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:mirrors';

import 'isolate_mirrors_impl.dart';
import '../executor_shared/introspection_impls.dart';
import '../executor_shared/protocol.dart';
import '../executor_shared/remote_instance.dart';
import '../executor.dart';
import '../api.dart';

/// Returns an instance of [_IsolateMirrorMacroExecutor].
///
/// This is the only public api exposed by this library.
Future<MacroExecutor> start() => _IsolateMirrorMacroExecutor.start();

/// A [MacroExecutor] implementation which relies on [IsolateMirror.loadUri]
/// in order to load macros libraries.
///
/// All actual work happens in a separate [Isolate], and this class serves as
/// a bridge between that isolate and the language frontends.
class _IsolateMirrorMacroExecutor implements MacroExecutor {
  /// The actual isolate doing macro loading and execution.
  final Isolate _macroIsolate;

  /// The channel used to send requests to the [_macroIsolate].
  final SendPort _sendPort;

  /// The stream of responses from the [_macroIsolate].
  final Stream<Response> _responseStream;

  /// A map of response completers by request id.
  final _responseCompleters = <int, Completer<Response>>{};

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() _onClose;

  _IsolateMirrorMacroExecutor._(
      this._macroIsolate, this._sendPort, this._responseStream, this._onClose) {
    _responseStream.listen((event) {
      Completer<Response>? completer =
          _responseCompleters.remove(event.requestId);
      if (completer == null) {
        throw new StateError(
            'Got a response for an unrecognized request id ${event.requestId}');
      }
      completer.complete(event);
    });
  }

  /// Initialize an [IsolateMirrorMacroExecutor] and return it once ready.
  ///
  /// Spawns the macro isolate and sets up a communication channel.
  static Future<MacroExecutor> start() async {
    ReceivePort receivePort = new ReceivePort();
    Completer<SendPort> sendPortCompleter = new Completer<SendPort>();
    StreamController<Response> responseStreamController =
        new StreamController<Response>(sync: true);
    receivePort.listen((message) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message as SendPort);
      } else {
        responseStreamController.add(message as Response);
      }
    }).onDone(responseStreamController.close);
    Isolate macroIsolate = await Isolate.spawn(spawn, receivePort.sendPort);

    return new _IsolateMirrorMacroExecutor._(
        macroIsolate,
        await sendPortCompleter.future,
        responseStreamController.stream,
        receivePort.close);
  }

  @override
  Future<String> buildAugmentationLibrary(
      Iterable<MacroExecutionResult> macroResults) {
    // TODO: implement buildAugmentationLibrary
    throw new UnimplementedError();
  }

  @override
  void close() {
    _onClose();
    _macroIsolate.kill();
  }

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
          DeclarationImpl declaration,
          TypeResolver typeResolver,
          ClassIntrospector classIntrospector,
          TypeDeclarationResolver typeDeclarationResolver) =>
      _sendRequest(new ExecuteDefinitionsPhaseRequest(
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
          // Serialization zones are not necessary in this executor.
          serializationZoneId: -1));

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
          new InstantiateMacroRequest(macroClass, constructor, arguments,
              // Serialization zones are not necessary in this executor.
              serializationZoneId: -1));

  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name,
      {Uri? precompiledKernelUri}) {
    if (precompiledKernelUri != null) {
      // TODO: Implement support?
      throw new UnsupportedError(
          'The IsolateMirrorsExecutor does not support precompiled dill files');
    }
    return _sendRequest(new LoadMacroRequest(library, name,
        // Serialization zones are not necessary in this executor.
        serializationZoneId: -1));
  }

  /// Sends a request and returns the response, casting it to the expected
  /// type.
  Future<T> _sendRequest<T>(Request request) async {
    _sendPort.send(request);
    Completer<Response> completer = new Completer<Response>();
    _responseCompleters[request.id] = completer;
    Response response = await completer.future;
    T? result = response.response as T?;
    if (result != null) return result;
    throw response.error!;
  }
}
