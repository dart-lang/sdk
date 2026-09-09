// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/error_code.dart' as json_rpc_error;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart' as vm;

/// Bitmasks for configuring pause event types that require client resume
/// permissions or user approval before resuming execution.
abstract final class PauseTypeMasks {
  /// Mask for isolates paused on startup before executing user code.
  static const pauseOnStartMask = 1 << 0;

  /// Mask for isolates paused after an isolate reload or post-request.
  static const pauseOnReloadMask = 1 << 1;

  /// Mask for isolates paused on exit before terminating.
  static const pauseOnExitMask = 1 << 2;
}

/// Tracks the active [Client] instances associated with a given client name and
/// their aggregated resume [permissionsMask].
final class ClientResumePermissions {
  /// All active client connections registered under this client name.
  final clients = <Client>[];

  /// Bitmask composed of [PauseTypeMasks] specifying pause types requiring
  /// approval from this named client group.
  int permissionsMask = 0;
}

/// Represents the lifecycle and pause state of an isolate tracked by DDS.
///
/// Coordinates multi-client resume policies and tracks approvals granted by
/// named clients before the isolate is permitted to resume execution on the VM.
final class DdsRunningIsolate {
  DdsRunningIsolate({
    required this.id,
    required this.isolateManager,
    required this.name,
  }) : _state = IsolateState.unknown;

  /// The unique identifier for this isolate.
  final String id;

  /// The parent [DdsIsolateManager] tracking this isolate.
  final DdsIsolateManager isolateManager;

  /// The debug name of this isolate.
  final String name;

  late final _logger = Logger('Isolate ($name)');
  final _resumeApprovalsByName = <String>{};

  /// The current lifecycle and execution state of this isolate.
  IsolateState get state => _state;
  IsolateState _state;

  /// Shuts down isolate tracking when the isolate exits.
  void shutdown() {
    _logger.info('Shutting down.');
  }

  /// Transitions isolate state to [IsolateState.pauseExit].
  void pausedOnExit() => _stateChange(IsolateState.pauseExit);

  /// Transitions isolate state to [IsolateState.pauseStart].
  void pausedOnStart() => _stateChange(IsolateState.pauseStart);

  /// Transitions isolate state to [IsolateState.pausePostRequest].
  void pausedPostRequest() => _stateChange(IsolateState.pausePostRequest);

  /// Transitions isolate state to [IsolateState.running].
  void resumed() => running();

  /// Transitions isolate state to [IsolateState.running].
  void running() => _stateChange(IsolateState.running);

  /// Transitions isolate state to [IsolateState.start].
  void started() => _stateChange(IsolateState.start);

  /// Clears all pending resume approvals granted by clients for this isolate.
  void clearResumeApprovals() => _resumeApprovalsByName.clear();

  void _stateChange(IsolateState updated) {
    _logger.info('${_state.name} => ${updated.name}');
    _state = updated;
  }

  /// Evaluates whether this isolate meets all requirements to resume execution.
  ///
  /// Checks whether:
  /// 1. The isolate is currently in a paused state that requires approval.
  /// 2. If user permission is required (e.g. from VM flags
  ///    `--pause-isolates-on-start` or `requireUserPermissionToResume`),
  ///    [resumingClient] is recognized as a user permission client.
  /// 3. All named client groups registered via `requirePermissionToResume` have
  ///    either previously sent `readyToResume` (stored in
  ///    [_resumeApprovalsByName]) or [resumingClient] is currently issuing the
  ///    `resume` request.
  bool shouldResume({Client? resumingClient}) {
    final pauseTypeMask = switch (_state) {
      IsolateState.pauseStart => PauseTypeMasks.pauseOnStartMask,
      IsolateState.pauseExit => PauseTypeMasks.pauseOnExitMask,
      IsolateState.pausePostRequest => PauseTypeMasks.pauseOnReloadMask,
      _ => 0,
    };
    if (pauseTypeMask == 0) return true;

    if ((isolateManager.requireUserPermissionToResumeMask & pauseTypeMask) !=
        0) {
      if (resumingClient == null ||
          !isolateManager.userPermissionClients.contains(resumingClient)) {
        return false;
      }
    }

    final permissions = isolateManager.clientResumePermissions;
    for (final MapEntry(key: name, value: perm) in permissions.entries) {
      if ((perm.permissionsMask & pauseTypeMask) != 0) {
        final clientApproved =
            _resumeApprovalsByName.contains(name) ||
            (resumingClient?.name == name);
        if (!clientApproved) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() => 'DdsRunningIsolate(name: $name id: $id)';
}

/// An [IsolateManager] implementation for DDS that coordinates isolate
/// lifecycle events and enforces multi-client resume permissions across
/// connected tooling.
final class DdsIsolateManager extends IsolateManager {
  DdsIsolateManager({required this.vmServiceClient});

  /// Client connection to the target VM Service.
  final vm.VmService vmServiceClient;

  /// Map of isolate IDs to active [DdsRunningIsolate] instances.
  final ddsIsolates = <String, DdsRunningIsolate>{};

  /// Registered resume permissions grouped by client name.
  final clientResumePermissions = <String, ClientResumePermissions>{};

  /// Set of clients authorized to provide user resume permissions.
  final userPermissionClients = <Client>{};

  /// Bitmask composed of [PauseTypeMasks] specifying pause types requiring
  /// user resume permission.
  int requireUserPermissionToResumeMask = 0;

  /// Initializes isolate tracking for all existing isolates in the target VM.
  ///
  /// Fetches the current VM isolate list, queries their initial pause states
  /// without blocking initialization on unreachable isolates, and inspects VM
  /// flags to determine startup pause policies.
  Future<void> initializeIsolates() async {
    try {
      final vmData = await vmServiceClient.getVM();
      for (final isolateRef in vmData.isolates ?? const <vm.IsolateRef>[]) {
        if (isolateRef case vm.IsolateRef(
          id: final id?,
          :final name,
        ) when id.isNotEmpty) {
          final isolate = ddsIsolates.putIfAbsent(
            id,
            () => DdsRunningIsolate(
              id: id,
              isolateManager: this,
              name: name ?? id,
            ),
          );
          unawaited(
            vmServiceClient
                .getIsolate(id)
                .then((iso) {
                  if (iso.pauseEvent?.kind case final eventKind?) {
                    switch (eventKind) {
                      case vm.EventKind.kPauseExit:
                        isolate.pausedOnExit();
                      case vm.EventKind.kPausePostRequest:
                        isolate.pausedPostRequest();
                      case vm.EventKind.kPauseStart:
                        isolate.pausedOnStart();
                      case vm.EventKind.kResume:
                        isolate.resumed();
                    }
                  } else {
                    isolate.running();
                  }
                })
                .catchError((_) {}),
          );
        }
      }
    } catch (_) {}

    await _determineRequireUserPermissionToResumeFromFlags();
  }

  Future<void> _determineRequireUserPermissionToResumeFromFlags() async {
    try {
      final flagList = await vmServiceClient.getFlagList();
      bool? pauseOnStart;
      bool? pauseOnExit;
      for (final flag in flagList.flags ?? const <vm.Flag>[]) {
        switch (flag) {
          case vm.Flag(name: 'pause_isolates_on_start', valueAsString: 'true'):
            pauseOnStart = true;
          case vm.Flag(name: 'pause_isolates_on_exit', valueAsString: 'true'):
            pauseOnExit = true;
        }
        if (pauseOnStart != null && pauseOnExit != null) break;
      }
      var mask = 0;
      if (pauseOnStart == true) mask |= PauseTypeMasks.pauseOnStartMask;
      if (pauseOnExit == true) mask |= PauseTypeMasks.pauseOnExitMask;
      requireUserPermissionToResumeMask = mask;
    } catch (_) {}
  }

  /// Handles incoming isolate lifecycle and pause events received from the
  /// target VM.
  ///
  /// Tracks isolate startup, exit, pause states, and resume events, updating
  /// the corresponding [DdsRunningIsolate] state and clearing pending approvals
  /// when an isolate resumes.
  void handleIsolateEvent(vm.Event event) {
    if (event case vm.Event(
      kind: final kind?,
      isolate: vm.IsolateRef(id: final id?, :final name),
    ) when id.isNotEmpty && kind != vm.EventKind.kIsolateReload) {
      switch (kind) {
        case vm.EventKind.kIsolateStart:
          final isolate = ddsIsolates.putIfAbsent(
            id,
            () => DdsRunningIsolate(
              id: id,
              isolateManager: this,
              name: name ?? id,
            ),
          );
          isolate.started();
        case vm.EventKind.kIsolateExit:
          ddsIsolates.remove(id)?.shutdown();
        case vm.EventKind.kPauseExit:
          ddsIsolates[id]?.pausedOnExit();
        case vm.EventKind.kPausePostRequest:
          ddsIsolates[id]?.pausedPostRequest();
        case vm.EventKind.kPauseStart:
          ddsIsolates[id]?.pausedOnStart();
        case vm.EventKind.kResume:
          if (ddsIsolates[id] case final isolate?) {
            isolate.clearResumeApprovals();
            isolate.resumed();
          }
      }
    }
  }

  int _calculatePermissionsMask(json_rpc.Parameters parameters) {
    var mask = 0;
    if (parameters['onPauseStart'].asBoolOr(false)) {
      mask |= PauseTypeMasks.pauseOnStartMask;
    }
    if (parameters['onPauseReload'].asBoolOr(false)) {
      mask |= PauseTypeMasks.pauseOnReloadMask;
    }
    if (parameters['onPauseExit'].asBoolOr(false)) {
      mask |= PauseTypeMasks.pauseOnExitMask;
    }
    return mask;
  }

  /// Handles the `requirePermissionToResume` custom DDS RPC.
  ///
  /// Registers resume requirements for a named [client]. When an isolate enters
  /// a pause state matching the configured permissions (`onPauseStart`,
  /// `onPauseReload`, `onPauseExit`), it will not resume until all clients with
  /// registered permissions have signaled readiness via [readyToResume] or
  /// [resume].
  ///
  /// Throws a [json_rpc.RpcException] with [json_rpc_error.INVALID_REQUEST] if
  /// the client has not set a client name.
  Future<RpcResponse> requirePermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) async {
    final name = client.name;
    if (name.isEmpty) {
      throw json_rpc.RpcException(
        json_rpc_error.INVALID_REQUEST,
        'Cannot set resume permissions for unnamed client',
      );
    }
    final mask = _calculatePermissionsMask(parameters);
    final entry = clientResumePermissions.putIfAbsent(
      name,
      ClientResumePermissions.new,
    );
    if (!entry.clients.contains(client)) {
      entry.clients.add(client);
    }
    entry.permissionsMask = mask;

    return vm.Success().toJson();
  }

  /// Handles the `requireUserPermissionToResume` custom DDS RPC.
  ///
  /// Configures whether DDS requires an explicit user resume command before
  /// resuming isolates paused on start (`onPauseStart`) or exit
  /// (`onPauseExit`). Registers [client] as authorized to provide user resume
  /// permission.
  Future<RpcResponse> requireUserPermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) async {
    requireUserPermissionToResumeMask = _calculatePermissionsMask(parameters);
    userPermissionClients.add(client);

    return vm.Success().toJson();
  }

  /// Handles the `getRequireUserPermissionToResume` custom DDS RPC.
  ///
  /// Returns a [ResumePermissionsRequired] response describing whether user
  /// approval is currently required to resume isolates paused on start or exit.
  RpcResponse getRequireUserPermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) => ResumePermissionsRequired(
    onPauseExit:
        (requireUserPermissionToResumeMask & PauseTypeMasks.pauseOnExitMask) !=
        0,
    onPauseStart:
        (requireUserPermissionToResumeMask & PauseTypeMasks.pauseOnStartMask) !=
        0,
  ).toJson();

  /// Handles the `readyToResume` custom DDS RPC.
  ///
  /// Signals that the calling [client] approves resuming the isolate specified
  /// by `isolateId`. If all other required clients and user permissions have
  /// also granted approval, forwards the resume request to the target VM.
  ///
  /// Throws a [json_rpc.RpcException] with [json_rpc_error.INVALID_PARAMS] if
  /// `isolateId` is not recognized.
  Future<RpcResponse> readyToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) async {
    final isolateId = parameters['isolateId'].asString;
    final isolate = ddsIsolates[isolateId];
    if (isolate == null) {
      throw json_rpc.RpcException(
        json_rpc_error.INVALID_PARAMS,
        'Invalid isolateId: $isolateId',
      );
    }
    if (client.name case final name when name.isNotEmpty) {
      isolate._resumeApprovalsByName.add(name);
    }
    if (isolate.shouldResume(resumingClient: client)) {
      await sendResumeRequest(isolateId: isolateId);
    }
    return vm.Success().toJson();
  }

  /// Handles the VM Service `resume` RPC.
  ///
  /// Records the calling [client]'s approval to resume the isolate specified
  /// by `isolateId`. If all required approvals are satisfied, forwards the
  /// request to the VM via [sendResumeRequest]. Otherwise, acknowledges the
  /// request with a success response while keeping the isolate paused until
  /// remaining approvals are received.
  Future<RpcResponse> resume(
    json_rpc.Parameters parameters,
    Client client,
  ) async {
    final isolateId = parameters['isolateId'].asString;
    if (ddsIsolates[isolateId] case final isolate?) {
      if (client.name case final name when name.isNotEmpty) {
        isolate._resumeApprovalsByName.add(name);
      }
      if (!isolate.shouldResume(resumingClient: client)) {
        return vm.Success().toJson();
      }
    }
    return await sendResumeRequest(
      isolateId: isolateId,
      parameters: parameters,
    );
  }

  /// Sends the `resume` request to the target VM Service client with optional
  /// `step` and `frameIndex` parameters.
  Future<RpcResponse> sendResumeRequest({
    required String isolateId,
    json_rpc.Parameters? parameters,
  }) async {
    const invalidFrameIndex = -1;
    final step = switch (parameters?['step']) {
      final s? when s.exists => s.asString,
      _ => null,
    };
    final frameIndex = switch (parameters?['frameIndex']) {
      final fi? when fi.exists => fi.asInt,
      _ => null,
    };
    final response = await vmServiceClient.resume(
      isolateId,
      frameIndex: frameIndex == invalidFrameIndex ? null : frameIndex,
      step: step,
    );
    return response.json ?? response.toJson();
  }

  /// Called when a [client] disconnects to remove its permissions and resume
  /// any isolates that were blocked solely waiting on this client.
  void handleClientDisconnected(Client client) {
    userPermissionClients.remove(client);
    final name = client.name;
    if (clientResumePermissions[name] case final perm?) {
      perm.clients.remove(client);
      if (perm.clients.isEmpty) {
        clientResumePermissions.remove(name);
        _maybeResumeAfterClientChange();
      }
    }
  }

  void _maybeResumeAfterClientChange() {
    for (final isolate in ddsIsolates.values) {
      if (isolate.state
          case IsolateState.pauseStart ||
              IsolateState.pauseExit ||
              IsolateState.pausePostRequest) {
        if (isolate.shouldResume()) {
          unawaited(sendResumeRequest(isolateId: isolate.id));
        }
      }
    }
  }

  @override
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  }) {
    throw UnimplementedError(
      'sendToIsolate is not implemented in DdsIsolateManager.',
    );
  }
}
