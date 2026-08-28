// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';
import 'logging_repository.dart';

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

  static const _kLoggingStream = vm.EventStreams.kLogging;
  static const _kStdoutStream = vm.EventStreams.kStdout;
  static const _kStderrStream = vm.EventStreams.kStderr;
  static const _kExtensionStream = vm.EventStreams.kExtension;

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
    vm.EventStreams.kGC,
    vm.EventStreams.kHeapSnapshot,
    vm.EventStreams.kTimeline,
    vm.EventStreams.kVM,
  };

  final loggingRepositories = <String, LoggingRepository>{};
  final _streamSubscriptions = <String, StreamSubscription<vm.Event>>{};

  /// Initializes core stream subscriptions with the target VM service.
  Future<void> initialize() async {
    for (final stream in _ddsCoreStreams) {
      try {
        await backend.vmServiceClient.streamListen(stream);
        if (_loggingRepositoryStreams.contains(stream)) {
          loggingRepositories[stream] = LoggingRepository();
        }
        _streamSubscriptions[stream] = backend.vmServiceClient
            .onEvent(stream)
            .listen((vm.Event event) => _handleVmServiceEvent(stream, event));
      } catch (_) {}
    }
  }

  static const _kDestinationStreamKey = '__destinationStream';

  void _handleVmServiceEvent(String streamId, vm.Event event) {
    var targetStreamId = streamId;

    if (event.extensionData?.data.remove(_kDestinationStreamKey)
        case final String destinationStream) {
      targetStreamId = destinationStream;
    }

    if (_isolateManagerStreams.contains(streamId)) {
      backend.isolateManager.handleIsolateEvent(event);
    }

    if (loggingRepositories[targetStreamId] case final loggingRepo?) {
      if (event.json case final Map<String, Object?> eventJson) {
        loggingRepo.add(<String, Object?>{
          'event': eventJson,
          'streamId': targetStreamId,
        });
      }
    }
    backend.frontend.eventStreams.streamNotify(
      data: VmServiceStreamEvent(event: event, streamId: targetStreamId),
      streamId: targetStreamId,
    );
  }

  /// Retrieves the recorded event history for [stream].
  List<Map<String, Object?>>? getStreamHistory(String stream) {
    final repo = loggingRepositories[stream];
    if (repo == null) {
      return null;
    }
    return [
      for (final event in repo())
        (event['event'] as Map<String, Object?>?) ?? event,
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
  void postEvent(
    String stream,
    String eventKind,
    Map<String, Object?> eventData,
  ) {
    if (_ddsCoreStreams.contains(stream)) {
      throw json_rpc.RpcException(
        vm.RPCErrorKind.kCoreStreamNotAllowed.code,
        vm.RPCErrorKind.kCoreStreamNotAllowed.message,
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
  void onClientSubscribe(Client client, String streamId) {
    loggingRepositories[streamId]?.sendHistoricalLogs(client);
  }

  /// Subscribes DDS to [streamId] on the remote VM service when a client
  /// listens to a non-core stream.
  Future<bool> onStreamListen({
    required Map<String, Object?> params,
    required String streamId,
  }) async {
    try {
      final includePrivateMembers = params['_includePrivateMembers'] as bool?;
      if (!_streamSubscriptions.containsKey(streamId)) {
        await backend.vmServiceClient.streamListen(streamId);
        if (includePrivateMembers != null) {
          try {
            await backend.vmServiceClient.callMethod(
              '_setStreamIncludePrivateMembers',
              args: <String, Object?>{
                'includePrivateMembers': includePrivateMembers,
                'streamId': streamId,
              },
            );
          } catch (_) {}
        }
        _streamSubscriptions[streamId] = backend.vmServiceClient
            .onEvent(streamId)
            .listen((vm.Event event) => _handleVmServiceEvent(streamId, event));
      }
      return true;
    } on vm.RPCError catch (e) {
      if (e.code == vm.RPCErrorKind.kInvalidParams.code) {
        return true;
      }
      return false;
    } catch (_) {
      return true;
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
    } catch (_) {}
  }

  /// Cancels all subscriptions and clears logging history upon shutdown.
  Future<void> shutdown() async {
    for (final sub in _streamSubscriptions.values) {
      await sub.cancel();
    }
    _streamSubscriptions.clear();
    loggingRepositories.clear();
  }
}
