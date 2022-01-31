// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:mirrors';

import 'isolate_mirrors_impl.dart';
import 'protocol.dart';
import '../executor.dart';
import '../api.dart';

/// A [MacroExecutor] implementation which relies on [IsolateMirror.loadUri]
/// in order to load macros libraries.
///
/// All actual work happens in a separate [Isolate], and this class serves as
/// a bridge between that isolate and the language frontends.
class IsolateMirrorMacroExecutor implements MacroExecutor {
  /// The actual isolate doing macro loading and execution.
  final Isolate _macroIsolate;

  /// The channel used to send requests to the [_macroIsolate].
  final SendPort _sendPort;

  /// The stream of responses from the [_macroIsolate].
  final Stream<GenericResponse> _responseStream;

  /// A map of response completers by request id.
  final _responseCompleters = <int, Completer<GenericResponse>>{};

  /// A function that should be invoked when shutting down this executor
  /// to perform any necessary cleanup.
  final void Function() _onClose;

  IsolateMirrorMacroExecutor._(
      this._macroIsolate, this._sendPort, this._responseStream, this._onClose) {
    _responseStream.listen((event) {
      Completer<GenericResponse>? completer =
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
    StreamController<GenericResponse> responseStreamController =
        new StreamController<GenericResponse>(sync: true);
    receivePort.listen((message) {
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message as SendPort);
      } else {
        responseStreamController.add(message as GenericResponse);
      }
    }).onDone(responseStreamController.close);
    Isolate macroIsolate = await Isolate.spawn(spawn, receivePort.sendPort);

    return new IsolateMirrorMacroExecutor._(
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

  @override
  Future<MacroClassIdentifier> loadMacro(Uri library, String name) =>
      _sendRequest(new LoadMacroRequest(library, name));

  /// Sends a request and returns the response, casting it to the expected
  /// type.
  Future<T> _sendRequest<T>(Request request) async {
    _sendPort.send(request);
    Completer<GenericResponse<T>> completer =
        new Completer<GenericResponse<T>>();
    _responseCompleters[request.id] = completer;
    GenericResponse<T> response = await completer.future;
    T? result = response.response;
    if (result != null) return result;
    throw response.error!;
  }
}
