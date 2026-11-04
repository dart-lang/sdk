// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';
import 'logging_repository.dart';

final _logger = Logger('DdsStreamManager');

/// An event wrapping a VM service event for streaming.
final class VmServiceStreamEvent extends StreamEvent {
  VmServiceStreamEvent({required this.event, required super.streamId})
    : super(kind: event.kind ?? 'Event');

  final vm.Event event;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    StreamEvent.kEvent: event.json ?? event.toJson(),
    StreamEvent.kStreamId: streamId,
  };
}

/// Manages stream subscriptions, event forwarding, and event history for DDS.
final class DdsStreamManager {
  DdsStreamManager({required this.backend});

  final DartRuntimeServiceDdsBackend backend;

  static const _kEchoStream = '_Echo';
  static const _kLoggingStream = vm.EventStreams.kLogging;
  static const _kStdoutStream = vm.EventStreams.kStdout;
  static const _kStderrStream = vm.EventStreams.kStderr;
  static const _kExtensionStream = vm.EventStreams.kExtension;

  static const _kDestinationStreamKey = '__destinationStream';
  static const _kIncludePrivateMembersKey = '_includePrivateMembers';
  static const _kIncludePrivateMembersParam = 'includePrivateMembers';
  static const _kSetStreamIncludePrivateMembersRpc =
      '_setStreamIncludePrivateMembers';
  static const _kStreamIdParam = 'streamId';

  static const _isolateManagerStreams = <String>{
    vm.EventStreams.kDebug,
    vm.EventStreams.kIsolate,
  };

  static const _loggingRepositoryStreams = <String>{
    _kLoggingStream,
    _kStdoutStream,
    _kStderrStream,
    _kExtensionStream,
    vm.EventStreams.kTimer,
  };

  static final _ddsCoreStreams = <String>{
    ..._isolateManagerStreams,
    ..._loggingRepositoryStreams,
  };

  /// Core VM service streams that cannot be targeted by [postEvent].
  static final _coreStreams = <String>{
    ..._ddsCoreStreams,
    _kEchoStream,
    vm.EventStreams.kGC,
    vm.EventStreams.kHeapSnapshot,
    vm.EventStreams.kProfiler,
    vm.EventStreams.kService,
    vm.EventStreams.kTimeline,
    vm.EventStreams.kVM,
  };

  final loggingRepositories = <String, LoggingRepository>{};
  final _streamSubscriptions = <String, StreamSubscription<vm.Event>>{};

  /// Initializes core stream subscriptions with the target VM service.
  Future<void> initialize() async {
    for (final stream in _loggingRepositoryStreams) {
      loggingRepositories[stream] = LoggingRepository();
    }
    for (final stream in _ddsCoreStreams) {
      _streamSubscriptions[stream] = backend.vmServiceClient
          .onEvent(stream)
          .listen((vm.Event event) => _handleVmServiceEvent(stream, event));
      try {
        await backend.vmServiceClient.streamListen(stream);
      } on Object {
        await _streamSubscriptions.remove(stream)?.cancel();
      }
    }
  }

  void _handleVmServiceEvent(String streamId, vm.Event event) {
    if (event.extensionData?.data.remove(_kDestinationStreamKey)
        case final String destinationStream) {
      if (destinationStream != _kExtensionStream) {
        if (_coreStreams.contains(destinationStream) ||
            !backend.frontend.eventStreams.hasListeners(destinationStream)) {
          // __destinationStream is only used by developer.postEvent, which is
          // only permitted to post events to the Extension stream or to custom
          // streams with active listeners.
          return;
        }
        backend.frontend.eventStreams.streamNotify(
          data: VmServiceStreamEvent(event: event, streamId: destinationStream),
          streamId: destinationStream,
        );
        return;
      }
    }

    if (_isolateManagerStreams.contains(streamId)) {
      backend.isolateManager.handleIsolateEvent(event);
    }

    if (loggingRepositories[streamId] case final loggingRepo?) {
      if (event.json case final Map<String, Object?> eventJson) {
        loggingRepo.add(<String, Object?>{
          StreamEvent.kEvent: eventJson,
          StreamEvent.kStreamId: streamId,
        });
      }
    }
    backend.frontend.eventStreams.streamNotify(
      data: VmServiceStreamEvent(event: event, streamId: streamId),
      streamId: streamId,
    );
  }

  /// Retrieves the recorded event history for [stream].
  List<Map<String, Object?>>? getStreamHistory(String stream) {
    final repo = loggingRepositories[stream];
    if (repo == null) {
      return null;
    }
    return <Map<String, Object?>>[
      for (final event in repo())
        (event[StreamEvent.kEvent] as Map<String, Object?>?) ?? event,
    ];
  }

  /// Returns the buffer size of the logging stream history repository.
  int getLogHistorySize() {
    final repo = loggingRepositories[_kLoggingStream];
    return repo?.bufferSize ?? 0;
  }

  /// Sets the buffer size of the logging stream history repository.
  void setLogHistorySize(int size) {
    if (size < 0) {
      throw json_rpc.RpcException.invalidParams(
        "'size' must be greater or equal to zero",
      );
    }
    final repo = loggingRepositories[_kLoggingStream];
    if (repo == null) {
      throw json_rpc.RpcException.invalidParams(
        'Logging stream history is not enabled.',
      );
    }
    repo.resize(size);
  }

  /// Posts an event to [stream] with [eventKind] and [eventData].
  ///
  /// Throws a [json_rpc.RpcException] with
  /// [vm.RPCErrorKind.kCoreStreamNotAllowed] if [stream] is a core VM service
  /// stream, or [vm.RPCErrorKind.kCustomStreamDoesNotExist] if no clients are
  /// currently subscribed to [stream].
  void postEvent(
    String stream,
    String eventKind,
    Map<String, Object?> eventData,
  ) {
    if (_coreStreams.contains(stream)) {
      throw json_rpc.RpcException(
        vm.RPCErrorKind.kCoreStreamNotAllowed.code,
        vm.RPCErrorKind.kCoreStreamNotAllowed.message,
      );
    }
    // Custom streams are not pre-registered via a separate RPC and do not
    // buffer historical events for future listeners, so a custom stream only
    // exists while at least one client is actively subscribed to it via
    // `streamListen`. Throw `kCustomStreamDoesNotExist` when there are no
    // active listeners so callers can tell nobody is listening instead of
    // having the event silently dropped.
    if (!backend.frontend.eventStreams.hasListeners(stream)) {
      throw json_rpc.RpcException(
        vm.RPCErrorKind.kCustomStreamDoesNotExist.code,
        vm.RPCErrorKind.kCustomStreamDoesNotExist.message,
      );
    }
    backend.frontend.eventStreams.streamNotify(
      data: VmServiceStreamEvent(
        event: vm.Event(
          extensionData: vm.ExtensionData.parse(eventData),
          extensionKind: eventKind,
          kind: 'Extension',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
        streamId: stream,
      ),
      streamId: stream,
    );
  }

  /// Handles when a new client subscribes to [streamId].
  ///
  /// Sends any historical logs for [streamId] to [client] and forwards
  /// `_includePrivateMembers` updates to the VM service.
  Future<void> onClientSubscribe(
    Client client,
    String streamId, {
    required Map<String, Object?> params,
  }) async {
    // Send historical logs before awaiting so events delivered while the
    // VM service request is in flight are not duplicated in the replay.
    loggingRepositories[streamId]?.sendHistoricalLogs(client);
    if (params[_kIncludePrivateMembersKey] case final bool includePrivates) {
      try {
        await backend.vmServiceClient.callMethod(
          _kSetStreamIncludePrivateMembersRpc,
          args: <String, Object?>{
            _kIncludePrivateMembersParam: includePrivates,
            _kStreamIdParam: streamId,
          },
        );
      } on vm.RPCError catch (e, st) {
        // _setStreamIncludePrivateMembers is an optional private RPC not
        // implemented by all VM service backends (e.g. web/DWDS).
        _logger.fine(
          'Failed to invoke $_kSetStreamIncludePrivateMembersRpc on '
          '$streamId',
          e,
          st,
        );
      }
    }
  }

  /// Subscribes DDS to [streamId] on the remote VM service when the first
  /// client listens to a non-core stream.
  Future<bool> onStreamListen({
    required Map<String, Object?> params,
    required String streamId,
  }) async {
    try {
      if (!_streamSubscriptions.containsKey(streamId)) {
        _streamSubscriptions[streamId] = backend.vmServiceClient
            .onEvent(streamId)
            .listen((vm.Event event) => _handleVmServiceEvent(streamId, event));
        try {
          await backend.vmServiceClient.streamListen(streamId);
        } on vm.RPCError catch (e) {
          if (e.code != vm.RPCErrorKind.kStreamAlreadySubscribed.code) {
            await _streamSubscriptions.remove(streamId)?.cancel();
            rethrow;
          }
        } on Object {
          await _streamSubscriptions.remove(streamId)?.cancel();
          rethrow;
        }
      }
      return true;
    } on vm.RPCError catch (e, st) {
      if (e.code == vm.RPCErrorKind.kInvalidParams.code) {
        // vmServiceClient.streamListen returns kInvalidParams for custom
        // streams registered by external clients/extensions rather than the VM.
        // DDS allows clients to subscribe to custom streams even though the
        // remote VM service does not host them.
        return true;
      }
      _logger.warning('Failed to subscribe to stream $streamId', e, st);
      return false;
    }
  }

  /// Unsubscribes DDS from [streamId] on the remote VM service when no clients
  /// remain subscribed (unless it's a core stream).
  Future<void> onStreamCancel({required String streamId}) async {
    if (_ddsCoreStreams.contains(streamId)) {
      return;
    }
    final sub = _streamSubscriptions.remove(streamId);
    await sub?.cancel();
    try {
      await backend.vmServiceClient.streamCancel(streamId);
    } on vm.RPCError catch (e, st) {
      // Canceling custom streams or streams when the VM is shutting down
      // can throw RPCError.
      _logger.fine('Failed to cancel stream $streamId on VM service', e, st);
    }
  }

  /// Cancels all subscriptions and clears logging history upon shutdown.
  Future<void> shutdown() async {
    final subscriptions = _streamSubscriptions.values.toList();
    _streamSubscriptions.clear();
    loggingRepositories.clear();
    for (final sub in subscriptions) {
      await sub.cancel();
    }
  }
}
