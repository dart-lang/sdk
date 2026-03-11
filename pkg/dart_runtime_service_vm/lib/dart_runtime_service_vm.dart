// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';

import 'src/native_bindings.dart';

class DartRuntimeServiceVMBackend extends DartRuntimeServiceBackend {
  /// The backend implementation for the Dart VM Service.
  ///
  /// [signalWatch] is the internal implementation of [ProcessSignal.watch],
  /// which bypasses checks that prevent [ProcessSignal.sigquit] from being
  /// watched.
  DartRuntimeServiceVMBackend({required this.signalWatch});

  /// The internal implementation of [ProcessSignal.watch].
  final Stream<ProcessSignal> Function(ProcessSignal signal) signalWatch;

  final _nativeBindings = NativeBindings();
  final _logger = Logger('VM Backend');

  StreamSubscription<ProcessSignal>? _sigquitSubscription;

  @override
  Future<void> initialize() async {
    _logger.info('Initializing...');
    _nativeBindings.onStart();
    _logger.info('Initialized!');
  }

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {
    // SIGQUIT isn't supported on Fuchsia or Windows.
    if (Platform.isFuchsia || Platform.isWindows) {
      return;
    }
    _sigquitSubscription = signalWatch(ProcessSignal.sigquit).listen((_) {
      _logger.info('SIGQUIT received. Toggling VM Service HTTP server.');
      service.toggleServer();
    });
  }

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {
    // TODO(bkonyi): handle DDS connection case.
    stdout.writeln('The Dart VM service is listening on $httpUri');
    _nativeBindings.onServerAddressChange(httpUri.toString());
  }

  @override
  Future<void> clearState() async {
    // Do nothing for now.
  }

  @override
  Future<void> shutdown() async {
    await _sigquitSubscription?.cancel();
    _nativeBindings.onExit();
  }

  @override
  void registerRpcs(json_rpc.Peer clientPeer) {
    // The VM service handles its service requests in service.cc.
  }

  @override
  void registerFallbacks(json_rpc.Peer clientPeer) {
    // If the registered Dart RPC handlers can't handle a request, forward it
    // it to the native VM service implementation for processing.
    clientPeer.registerFallback(sendToRuntime);
  }

  /// Sends service requests to the Dart VM runtime for processing.
  Future<RpcResponse> sendToRuntime(json_rpc.Parameters request) async {
    final method = request.method;
    final params = request.asMap.cast<String, Object?>();
    if (params case {'isolateId': final String _}) {
      // TODO(bkonyi): handle isolate requests
      RpcException.serverError.throwException();
    }
    return await _nativeBindings.sendToVM(method: method, params: params);
  }
}
