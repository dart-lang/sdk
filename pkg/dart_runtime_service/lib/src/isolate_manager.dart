// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/error_code.dart' as json_rpc_error;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'dart_runtime_service.dart';

enum IsolateState {
  start,
  running,
  pauseStart,
  pauseExit,
  pausePostRequest,
  unknown,
}

/// Base class for representing the state of a running isolate.
base class RunningIsolate {
  RunningIsolate({required this.id, required this.name})
    : _state = IsolateState.unknown;

  late final _logger = Logger('Isolate ($name)');
  final String name;
  final int id;
  // ignore: unused_field, will be used for resume permission logic.
  IsolateState _state;

  /// Invoked when the isolate has shutdown.
  ///
  /// Override this to clean up any state associated with this isolate.
  @mustCallSuper
  void shutdown() {
    _logger.info('Shutting down.');
  }

  // State setters.
  void pausedOnExit() => _stateChange(IsolateState.pauseExit);

  void pausedOnStart() => _stateChange(IsolateState.pauseStart);

  void pausedPostRequest() => _stateChange(IsolateState.pausePostRequest);

  void resumed() => running();

  void running() => _stateChange(IsolateState.running);

  void started() => _stateChange(IsolateState.start);

  void _stateChange(IsolateState updated) {
    _logger.info('${_state.name} => ${updated.name}');
    _state = updated;
  }

  @override
  String toString() => 'Isolate(name: $name id: $id)';
}

/// This file contains functionality used to track the running state of
/// all isolates in a given Dart process.
///
/// [RunningIsolate] is a representation of a single live isolate and contains
/// running state information for that isolate. In addition, approvals from
/// clients used to synchronize isolate resuming across multiple clients are
/// tracked in this class.
///
/// The [IsolateManager] keeps track of all the isolates in the
/// target process and handles isolate lifecycle events including:
///   - Startup
///   - Shutdown
///   - Pauses
///
/// The [IsolateManager] also handles the `resume` RPC, which checks the
/// resume approvals in the target [RunningIsolate] to determine if the
/// isolate should be resumed or wait for additional approvals to be granted.
abstract base class IsolateManager {
  final _logger = Logger('$IsolateManager');
  final isolates = <int, RunningIsolate>{};

  /// The ID of the root isolate.
  ///
  /// Used to support the `isolates/root` isolate ID.
  int? _rootIsolateId;

  @mustCallSuper
  Future<void> shutdown() async {
    _logger.info('Shutting down.');
  }

  /// Forwards the RPC request for [method] to be handled in the context of an
  /// isolate.
  ///
  /// [params] is the set of parameters for the RPC and must include a valid
  /// `isolateId`.
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  });

  /// Initializes state for a newly started isolate.
  void isolateStarted({required RunningIsolate isolate}) {
    _logger.info('Starting isolate: $isolate');
    if (_rootIsolateId == null) {
      // TODO(bkonyi): ensure this is a non-system isolate
      _logger.info('$isolate is the root isolate.');
      _rootIsolateId = isolate.id;
    }
    isolate.running();
    isolates[isolate.id] = isolate;
  }

  /// Cleans up state for an isolate that has exited.
  void isolateExited({required int id}) {
    final isolate = isolates.remove(id);
    if (isolate == null) {
      _logger.warning(
        'isolateExited called with id: $id, but the isolate is not registered. '
        'Ignoring.',
      );
      return;
    }
    _logger.info('Isolate exited: $isolate');
    isolate.shutdown();
  }

  /// Looks up a [RunningIsolate] based on the `isolateId` entry in [params].
  ///
  /// If the isolate ID is malformed, a [json_rpc.RpcException] is thrown with
  /// an invalid parameters error.
  ///
  /// If the isolate ID is not associated with a running isolate, null is
  /// returned.
  RunningIsolate? lookupIsolateFromParams({
    required String method,
    required Map<String, Object?> params,
  }) {
    const kIsolateId = 'isolateId';
    const kIsolateIdPrefix = 'isolates/';
    assert(params.containsKey(kIsolateId));
    final isolateIdParam = params[kIsolateId] as String;

    Never throwInvalidIsolateId() => throw json_rpc.RpcException(
      json_rpc_error.INVALID_PARAMS,
      'Invalid params',
      data: {
        'details':
            "$method: invalid '$kIsolateId' parameter: "
            '$isolateIdParam',
      },
    );

    if (!isolateIdParam.startsWith(kIsolateIdPrefix)) {
      _logger.warning('Malformed $kIsolateId: $isolateIdParam');
      throwInvalidIsolateId();
    }

    final isolateId = isolateIdParam.substring(kIsolateIdPrefix.length);
    int id;
    if (isolateId == 'root') {
      if (_rootIsolateId == null) {
        throwInvalidIsolateId();
      }
      id = _rootIsolateId!;
    } else {
      try {
        id = int.parse(isolateId);
      } on FormatException {
        throwInvalidIsolateId();
      }
    }
    return isolates[id];
  }
}
