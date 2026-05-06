// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import 'native_bindings.dart';

/// A running isolate for the Dart VM.
final class VmRunningIsolate extends RunningIsolate {
  VmRunningIsolate({
    required super.id,
    required super.name,
    required this.sendPort,
  });

  /// The port used to send service requests to the isolate within the VM.
  final SendPort sendPort;

  /// The set of ports for outstanding requests that are used by the VM to send
  /// responses.
  final outstandingRequestPorts = <RawReceivePort>{};

  @override
  void shutdown() {
    for (final requestPort in outstandingRequestPorts) {
      requestPort.close();
    }
    outstandingRequestPorts.clear();
    super.shutdown();
  }
}

/// Manages and tracks running isolates in the Dart VM.
final class VmIsolateManager extends IsolateManager {
  /// Initializes the [VmIsolateManager].
  ///
  /// [runningIsolatesStream] should be a stream of [VmRunningIsolate]s reported
  /// by the Dart VM as started once the VM service has finished initializing.
  VmIsolateManager({required Stream<VmRunningIsolate> runningIsolatesStream}) {
    _runningIsolatesStreamSub = runningIsolatesStream.listen(
      (isolate) => isolateStarted(isolate: isolate),
    );
  }

  final _logger = Logger('$VmIsolateManager');
  final _nativeBindings = NativeBindings();
  late final StreamSubscription<VmRunningIsolate> _runningIsolatesStreamSub;

  @override
  Future<void> shutdown() async {
    await _runningIsolatesStreamSub.cancel();
    await super.shutdown();
  }

  /// Registers a newly started isolate reported via a message over the
  /// service's control port.
  void onIsolateStartupMessage({
    required int id,
    required SendPort sendPort,
    required String name,
  }) {
    final isolate = VmRunningIsolate(id: id, name: name, sendPort: sendPort);
    _logger.info('Isolate startup message received for $isolate');
    isolateStarted(isolate: isolate);
  }

  /// Reports that an isolate is shutting down based on a message over the
  /// service's control port.
  void onIsolateShutdownMessage({required int id}) {
    _logger.info('Received isolate shutdown message for isolate $id');
    isolateExited(id: id);
  }

  @override
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  }) async {
    final isolate =
        lookupIsolateFromParams(method: method, params: params)
            as VmRunningIsolate?;
    if (isolate == null) {
      // There is some chance that this isolate may have lived before,
      // so return a sentinel rather than an error.
      return Sentinel(
        kind: SentinelKind.kCollected,
        valueAsString: '<collected>',
      ).toJson();
    }
    return _nativeBindings.sendToIsolate(
      isolate: isolate,
      method: method,
      params: params,
    );
  }
}
