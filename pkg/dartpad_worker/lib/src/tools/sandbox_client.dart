// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: implementation_imports
import 'package:dartpad/src/exceptions.dart' show rethrowAsDartPadException;
import 'package:json_rpc_2/json_rpc_2.dart';

import '../util/message_port.dart';

/// Client for talking to the [MessagePort] posted by `sandbox.js`.
final class SandboxClient {
  final Peer _peer;
  final void Function() _onClosed;

  final _consoleController = StreamController<({String message})>.broadcast();
  final _unhandledRejectionController =
      StreamController<({String message})>.broadcast();
  final _errorController = StreamController<({String message})>.broadcast();
  final _extensionEventController =
      StreamController<({String kind, Map<String, Object?> data})>.broadcast();

  /// Create a [SandboxClient] for talking to the `sandbox.js` that posted
  /// [port].
  ///
  /// When [port] is closed, [onClosed] will be called.
  SandboxClient(MessagePort port, void Function() onClosed)
    : _peer = Peer.withoutJson(port.jsonRpcChannel()),
      _onClosed = onClosed {
    // Register notification handlers
    _peer.registerMethod('console', (Parameters params) {
      final message = params['message'].asString;

      _consoleController.add((message: message));
    });

    _peer.registerMethod('unhandledRejection', (Parameters params) {
      final message = params['message'].asString;

      _unhandledRejectionController.add((message: message));
    });

    _peer.registerMethod('error', (Parameters params) {
      final message = params['message'].asString;

      _errorController.add((message: message));
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

    // Start listening
    scheduleMicrotask(() async {
      try {
        await _peer.listen();
      } finally {
        _onClosed();
        _peer.close().ignore();
      }
    });
  }

  /// Close the sandbox client, this will NOT remove the iframe.
  ///
  /// Closing the [SandboxClient] just closes the [MessagePort], it doesn't not
  /// delete the iframe from the page. The life-cycle of the iframe is not owned
  /// by the worker, only communication with the iframe.
  Future<void> close() async {
    await _peer.close();
    _onClosed();
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
  Stream<({String message})> get onConsole => _consoleController.stream;

  /// Stream of unhandled rejections from the sandbox.
  Stream<({String message})> get onUnhandledRejection =>
      _unhandledRejectionController.stream;

  /// Stream of runtime errors from the sandbox.
  Stream<({String message})> get onError => _errorController.stream;

  /// Stream of custom extension events from the sandbox.
  ///
  /// These events are fired by `dart:developer`'s `postEvent` method.
  Stream<({String kind, Map<String, Object?> data})> get onExtensionEvent =>
      _extensionEventController.stream;

  /// Injects compiled DDC module into the sandbox.
  Future<void> loadModule({
    required String code,
    String moduleName = 'main',
  }) async {
    await _sendRequest<void>('loadModule', {
      'code': code,
      'moduleName': moduleName,
    });
  }

  /// Runs the application by calling `main()` in the target library.
  Future<void> runMain(Uri libraryUri) async {
    await _sendRequest<void>('runMain', {'libraryUri': libraryUri.toString()});
  }

  /// Run flutter app by calling `main()` from [libraryUri].
  ///
  /// This requires `flutter.js`, which is loaded when running with Flutter SDK.
  /// You may expect [hotReload] to work after this, but [hotRestart] will not.
  Future<void> runApp(Uri libraryUri) async {
    await _sendRequest<void>('runApp', {'libraryUri': libraryUri.toString()});
  }

  /// Triggers a hot restart, resetting global state.
  ///
  /// Returns the current hot restart generation number from the embedder.
  Future<({int generation})> hotRestart({
    String? code,
    String? moduleName = 'main',
  }) async {
    final r = await _sendRequest<Map>('hotRestart', {
      'code': ?code,
      'moduleName': ?moduleName,
    });
    return (generation: (r['generation'] as num).toInt());
  }

  /// Triggers a stateful hot reload.
  ///
  /// [librariesToReload] should contain the URIs of the libraries that changed.
  ///
  /// Returns the current hot reload generation number from the embedder.
  Future<({int generation})> hotReload({
    String? code,
    String? moduleName = 'main',
    List<Uri> librariesToReload = const [],
  }) async {
    final r = await _sendRequest<Map>('hotReload', {
      'code': ?code,
      'moduleName': ?moduleName,
      'librariesToReload': librariesToReload.map((u) => u.toString()).toList(),
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
