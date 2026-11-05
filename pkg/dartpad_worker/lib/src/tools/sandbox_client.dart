// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: implementation_imports
import 'package:dartpad/src/exceptions.dart' show rethrowAsDartPadException;
import 'package:json_rpc_2/json_rpc_2.dart';

import '../shared.dart';
import '../util/message_port.dart';
import '../util/parameters_ext.dart';

/// Structured `dart:developer.log` entry emitted by the sandbox.
typedef SandboxLogRecord = ({
  String message,
  String name,
  int level,
  int sequenceNumber,
  int time,
  String? error,
  String? stackTrace,
});

/// Lifecycle event for the running application in the sandbox.
sealed class SandboxIsolateEvent {
  const SandboxIsolateEvent();
}

/// Fired when `run` or `hotRestart` starts a new application generation.
final class SandboxIsolateStarted extends SandboxIsolateEvent {
  final String entrypointUri;
  final String mode;

  /// Libraries from compiled modules loaded via [SandboxClient.loadModules] or
  /// [SandboxClient.hotRestart], excluding built-in `dart:*` SDK libraries and
  /// precompiled `DartPadRunMode.libraries`.
  final List<String> libraries;

  const SandboxIsolateStarted({
    required this.entrypointUri,
    required this.mode,
    required this.libraries,
  });
}

/// Fired when `run` fails or `hotRestart` tears down the previous generation.
final class SandboxIsolateExited extends SandboxIsolateEvent {
  const SandboxIsolateExited();
}

/// Fired when `hotReload` completes.
final class SandboxIsolateReloaded extends SandboxIsolateEvent {
  /// Libraries from compiled modules loaded so far, excluding built-in `dart:*`
  /// SDK libraries and precompiled `DartPadRunMode.libraries`.
  final List<String> libraries;

  const SandboxIsolateReloaded({required this.libraries});
}

/// Client for talking to the [MessagePort] posted by `sandbox.js`.
final class SandboxClient {
  final Peer _peer;
  final void Function() _onClosed;

  final _loadedLibraries = <String>{};
  final _consoleController =
      StreamController<({String level, String message})>.broadcast();
  final _extensionEventController =
      StreamController<({String kind, Map<String, Object?> data})>.broadcast();
  final _registerExtensionController = StreamController<String>.broadcast();
  final _logController = StreamController<SandboxLogRecord>.broadcast();
  final _isolateEventController =
      StreamController<SandboxIsolateEvent>.broadcast();

  /// Create a [SandboxClient] for talking to the `sandbox.js` that posted
  /// [port].
  ///
  /// When [port] is closed, [onClosed] will be called.
  SandboxClient(MessagePort port, void Function() onClosed)
    : _peer = Peer.withoutJson(port.jsonRpcChannel()),
      _onClosed = onClosed {
    // Register notification handlers
    _peer.registerMethod('console', (Parameters params) {
      final level = params['level'].asString;
      final message = params['message'].asString;

      _consoleController.add((level: level, message: message));
    });

    _peer.registerMethod('extensionEvent', (Parameters params) {
      final kind = params['kind'].asString;
      final Object? data;
      try {
        data = jsonDecode(params['data'].asString);
      } on FormatException catch (e) {
        throw RpcException.invalidParams('Invalid JSON in data: $e');
      }
      if (data is! Map<String, Object?>) {
        throw RpcException.invalidParams('Data must be a JSON object (Map)');
      }

      _extensionEventController.add((kind: kind, data: data));
    });

    _peer.registerMethod('registerExtension', (Parameters params) {
      _registerExtensionController.add(params['method'].asString);
    });

    _peer.registerMethod('log', (Parameters params) {
      _logController.add((
        message: params['message'].asStringOr(''),
        name: params['name'].asStringOr(''),
        level: params['level'].asIntOr(0),
        sequenceNumber: params['sequenceNumber'].asIntOr(0),
        time: params['time'].asIntOr(DateTime.now().millisecondsSinceEpoch),
        error: params['error'].asStringOrNull,
        stackTrace: params['stackTrace'].asStringOrNull,
      ));
    });

    _peer.registerMethod('isolateStart', (Parameters params) {
      _isolateEventController.add(
        SandboxIsolateStarted(
          entrypointUri: params['entrypointUri'].asString,
          mode: params['mode'].asString,
          libraries: _loadedLibraries.toList(),
        ),
      );
    });

    _peer.registerMethod('isolateExit', (Parameters _) {
      _isolateEventController.add(const SandboxIsolateExited());
    });

    _peer.registerMethod('isolateReload', (Parameters _) {
      _isolateEventController.add(
        SandboxIsolateReloaded(libraries: _loadedLibraries.toList()),
      );
    });

    // Start listening
    _peer.listen().whenComplete(() {
      _cleanup();
      _peer.close().ignore();
    }).ignore();
  }

  bool _isClosed = false;

  void _cleanup() {
    if (_isClosed) return;
    _isClosed = true;
    _onClosed();
    unawaited(_consoleController.close());
    unawaited(_extensionEventController.close());
    unawaited(_registerExtensionController.close());
    unawaited(_logController.close());
    unawaited(_isolateEventController.close());
  }

  /// Close the sandbox client, this will NOT remove the iframe.
  ///
  /// Closing the [SandboxClient] just closes the [MessagePort], it does not
  /// delete the iframe from the page. The life-cycle of the iframe is not owned
  /// by the worker, only communication with the iframe.
  Future<void> close() async {
    try {
      await _peer.close();
    } finally {
      _cleanup();
    }
  }

  Future<T> _sendRequest<T>(
    String method, [
    Map<String, Object?> params = const {},
  ]) async {
    try {
      return await _peer.sendRequest(method, params) as T;
    } on RpcException catch (e) {
      rethrowAsDartPadException(e);
    }
  }

  /// Stream of console output from the sandbox.
  Stream<({String level, String message})> get onConsole =>
      _consoleController.stream;

  /// Stream of custom extension events from the sandbox.
  ///
  /// These events are fired by `dart:developer`'s `postEvent` method.
  Stream<({String kind, Map<String, Object?> data})> get onExtensionEvent =>
      _extensionEventController.stream;

  /// Stream of service extension registrations from the sandbox.
  Stream<String> get onRegisterExtension => _registerExtensionController.stream;

  /// Stream of `dart:developer.log` records from the sandbox.
  Stream<SandboxLogRecord> get onLog => _logController.stream;

  /// Stream of isolate lifecycle events (`start`, `exit`, `reload`).
  Stream<SandboxIsolateEvent> get onIsolateEvent =>
      _isolateEventController.stream;

  /// Injects compiled DDC library bundles into the sandbox.
  Future<void> loadModules({required List<CompiledModule> modules}) async {
    assert(modules.isNotEmpty);
    for (final module in modules) {
      _loadedLibraries.addAll(module.libraries);
    }
    await _sendRequest<void>('loadModules', {'modules': modules.toJson()});
  }

  /// Runs the application using the specified mode.
  Future<void> run(String libraryUri, {required String mode}) async {
    await _sendRequest<void>('run', {'libraryUri': libraryUri, 'mode': mode});
  }

  /// Triggers a hot restart, resetting global state.
  ///
  /// Returns the current hot restart generation number from the embedder.
  Future<({int generation})> hotRestart({
    List<CompiledModule> modules = const [],
  }) async {
    for (final module in modules) {
      _loadedLibraries.addAll(module.libraries);
    }
    final r = await _sendRequest<Map>('hotRestart', {
      'modules': modules.toJson(),
    });
    return (generation: (r['generation'] as num).toInt());
  }

  /// Triggers a stateful hot reload.
  ///
  /// Returns the current hot reload generation number from the embedder.
  Future<({int generation})> hotReload({
    List<CompiledModule> modules = const [],
  }) async {
    for (final module in modules) {
      _loadedLibraries.addAll(module.libraries);
    }
    final r = await _sendRequest<Map>('hotReload', {
      'modules': modules.toJson(),
    });

    return (generation: (r['generation'] as num).toInt());
  }

  /// Fetches the current hot restart generation counter.
  Future<({int generation})> getHotRestartGeneration() async {
    final r = await _sendRequest<Map>('getHotRestartGeneration');
    return (generation: (r['generation'] as num).toInt());
  }

  /// Fetches the current hot reload generation counter.
  Future<({int generation})> getHotReloadGeneration() async {
    final r = await _sendRequest<Map>('getHotReloadGeneration');
    return (generation: (r['generation'] as num).toInt());
  }

  /// Get application metrics from the sandbox.
  Future<
    ({
      int dartSize,
      int jsSize,
      int sourceMapSize,
      int evaluatedModules,
      Duration loadTime,
    })
  >
  appMetrics() async {
    final r = await _sendRequest<Map>('appMetrics');
    return (
      dartSize: (r['dartSize'] as num).toInt(),
      jsSize: (r['jsSize'] as num).toInt(),
      sourceMapSize: (r['sourceMapSize'] as num).toInt(),
      evaluatedModules: (r['evaluatedModules'] as num).toInt(),
      loadTime: Duration(milliseconds: (r['loadTimeMs'] as num).toInt()),
    );
  }

  /// Invokes a developer service extension inside the running app.
  Future<String> invokeExtension(
    String method,
    Map<String, String> args,
  ) async {
    return await _sendRequest<String>('invokeExtension', {
      'method': method,
      'args': args,
    });
  }
}

extension on List<CompiledModule> {
  List<Map<String, Object?>> toJson() => [
    for (final module in this)
      {
        'moduleName': module.moduleName,
        'code': module.code,
        'libraries': module.libraries,
      },
  ];
}
