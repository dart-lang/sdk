// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';
import 'dds_client.dart';
import 'dds_isolate_manager.dart';

/// Handles DDS-specific and forwarded RPCs exposed by the Dart Development
/// Service.
///
/// Registers protocol handlers for custom DDS methods (such as stream history,
/// log sizing, and multi-client resume permissions) as well as VM Service
/// interception methods (such as `createIdZone` and `resume`).
class DdsRpcHandlers {
  DdsRpcHandlers(this.backend);

  /// The backend providing VM service client access and DDS manager instances.
  final DartRuntimeServiceDdsBackend backend;

  static const _kDdsProtocolName = 'DDS';
  static const _kDdsVersionMajor = 2;
  static const _kDdsVersionMinor = 1;

  static const _kCreateIdZone = 'createIdZone';
  static const _kGetAvailableCachedCpuSamples = 'getAvailableCachedCpuSamples';
  static const _kGetCachedCpuSamples = 'getCachedCpuSamples';
  static const _kGetDartDevelopmentServiceVersion =
      'getDartDevelopmentServiceVersion';
  static const _kGetLogHistorySize = 'getLogHistorySize';
  static const _kGetPerfettoVMTimelineWithCpuSamples =
      'getPerfettoVMTimelineWithCpuSamples';
  static const _kGetRequireUserPermissionToResume =
      'getRequireUserPermissionToResume';
  static const _kGetStreamHistory = 'getStreamHistory';
  static const _kGetSupportedProtocols = 'getSupportedProtocols';
  static const _kPostEvent = 'postEvent';
  static const _kReadyToResume = 'readyToResume';
  static const _kRequirePermissionToResume = 'requirePermissionToResume';
  static const _kRequireUserPermissionToResume =
      'requireUserPermissionToResume';
  static const _kResume = 'resume';
  static const _kSetLogHistorySize = 'setLogHistorySize';

  /// Returns the unmodifiable list of RPC handlers provided by DDS.
  UnmodifiableListView<ServiceRpcHandler> get rpcs => UnmodifiableListView([
    (_kCreateIdZone, createIdZone),
    (_kGetAvailableCachedCpuSamples, getAvailableCachedCpuSamples),
    (_kGetCachedCpuSamples, getCachedCpuSamples),
    (_kGetDartDevelopmentServiceVersion, getDartDevelopmentServiceVersion),
    (_kGetLogHistorySize, getLogHistorySize),
    (
      _kGetPerfettoVMTimelineWithCpuSamples,
      getPerfettoVMTimelineWithCpuSamples,
    ),
    (_kGetRequireUserPermissionToResume, getRequireUserPermissionToResume),
    (_kGetStreamHistory, getStreamHistory),
    (_kGetSupportedProtocols, getSupportedProtocols),
    (_kPostEvent, postEvent),
    (_kReadyToResume, readyToResume),
    (_kRequirePermissionToResume, requirePermissionToResume),
    (_kRequireUserPermissionToResume, requireUserPermissionToResume),
    (_kResume, resume),
    (_kSetLogHistorySize, setLogHistorySize),
  ]);

  /// Handles the `createIdZone` RPC.
  ///
  /// Forwards the request to the VM Service to allocate an ID zone for the
  /// target isolate, and tracks the created zone on [client] so that it can
  /// be automatically cleaned up if the client disconnects.
  Future<RpcResponse> createIdZone(
    json_rpc.Parameters parameters,
    Client client,
  ) async {
    final response = await backend.callVmService(
      parameters.method,
      args: parameters.value == null
          ? null
          : parameters.asMap.cast<String, Object?>(),
    );
    if (response case {'id': final String zoneId}) {
      (client as DdsClient).addServiceIdZone(
        isolateId: parameters['isolateId'].asString,
        serviceIdZoneId: zoneId,
      );
    }
    return response;
  }

  /// Handles the `getAvailableCachedCpuSamples` custom DDS RPC.
  ///
  /// Returns an [AvailableCachedCpuSamples] response listing the names of
  /// available cached CPU sample profiles.
  ///
  /// **NOTE**: this RPC is deprecated and returns an empty response.
  RpcResponse getAvailableCachedCpuSamples(json_rpc.Parameters parameters) {
    return AvailableCachedCpuSamples(cacheNames: <String>[]).toJson();
  }

  /// Handles the `getCachedCpuSamples` custom DDS RPC.
  ///
  /// Returns a [CachedCpuSamples] response containing cached CPU samples for
  /// the requested user tag.
  ///
  /// **NOTE**: this RPC is deprecated and returns an empty response.
  RpcResponse getCachedCpuSamples(json_rpc.Parameters parameters) {
    return CachedCpuSamples(
      functions: <vm.ProfileFunction>[],
      maxStackDepth: -1,
      pid: -1,
      sampleCount: -1,
      samplePeriod: -1,
      samples: <vm.CpuSample>[],
      timeExtentMicros: -1,
      timeOriginMicros: -1,
      userTag: '',
    ).toJson();
  }

  /// Handles the `getDartDevelopmentServiceVersion` custom DDS RPC.
  ///
  /// Returns the current semantic [vm.Version] of the DDS protocol implemented
  /// by this service instance.
  RpcResponse getDartDevelopmentServiceVersion(json_rpc.Parameters parameters) {
    return vm.Version(
      major: _kDdsVersionMajor,
      minor: _kDdsVersionMinor,
    ).toJson();
  }

  /// Handles the `getLogHistorySize` custom DDS RPC.
  ///
  /// Returns a [Size] response representing the maximum number of log events
  /// retained in memory by the logging ring buffer.
  RpcResponse getLogHistorySize(json_rpc.Parameters parameters) {
    return Size(size: backend.streamManager.getLogHistorySize()).toJson();
  }

  /// Handles the `getPerfettoVMTimelineWithCpuSamples` RPC.
  ///
  /// Forwards the timeline request to the VM Service with the provided time
  /// origin and extent parameters.
  Future<RpcResponse> getPerfettoVMTimelineWithCpuSamples(
    json_rpc.Parameters parameters,
  ) {
    return backend.callVmService(
      'getPerfettoVMTimelineWithCpuSamples',
      args: parameters.value == null
          ? null
          : parameters.asMap.cast<String, Object?>(),
    );
  }

  /// Handles the `getRequireUserPermissionToResume` custom DDS RPC.
  ///
  /// Delegates to [DdsIsolateManager.getRequireUserPermissionToResume] to
  /// return whether user approval is required to resume paused isolates.
  RpcResponse getRequireUserPermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) {
    return backend.isolateManager.getRequireUserPermissionToResume(
      parameters,
      client,
    );
  }

  /// Handles the `getStreamHistory` custom DDS RPC.
  ///
  /// Returns a [StreamHistory] response containing historical events buffered
  /// for the specified `stream` (e.g. `Logging` or `Stdout`).
  ///
  /// Throws a [json_rpc.RpcException] if historical buffering is not supported
  /// for the requested stream.
  RpcResponse getStreamHistory(json_rpc.Parameters parameters) {
    final stream = parameters['stream'].asString;
    final history = backend.streamManager.getStreamHistory(stream);
    if (history == null) {
      throw json_rpc.RpcException.invalidParams(
        "Event history is not collected for stream '$stream'",
      );
    }
    return StreamHistory(
      history: history.map(vm.Event.parse).whereType<vm.Event>().toList(),
    ).toJson();
  }

  /// Handles the `getSupportedProtocols` RPC.
  ///
  /// Queries the target VM Service for supported protocols and appends the
  /// DDS protocol specification to the returned [vm.ProtocolList].
  Future<RpcResponse> getSupportedProtocols(
    json_rpc.Parameters parameters,
  ) async {
    final protocolList = await backend.vmServiceClient.getSupportedProtocols();
    final protocols = protocolList.protocols ??= <vm.Protocol>[];
    protocols.add(
      vm.Protocol(
        major: _kDdsVersionMajor,
        minor: _kDdsVersionMinor,
        protocolName: _kDdsProtocolName,
      ),
    );
    return protocolList.toJson();
  }

  /// Handles the `postEvent` custom DDS RPC.
  ///
  /// Publishes an arbitrary custom event to the specified `stream` with
  /// `eventKind` and `eventData`, broadcasting it to all connected clients
  /// subscribed to that stream.
  RpcResponse postEvent(json_rpc.Parameters parameters) {
    final stream = parameters['stream'].asString;
    final eventKind = parameters['eventKind'].asString;
    final eventData = parameters['eventData'].asMap.cast<String, Object?>();
    backend.streamManager.postEvent(stream, eventKind, eventData);
    return vm.Success().toJson();
  }

  /// Handles the `readyToResume` custom DDS RPC.
  ///
  /// Delegates to [DdsIsolateManager.readyToResume] to signal that [client]
  /// approves resuming the specified isolate.
  Future<RpcResponse> readyToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) {
    return backend.isolateManager.readyToResume(parameters, client);
  }

  /// Handles the `requirePermissionToResume` custom DDS RPC.
  ///
  /// Delegates to [DdsIsolateManager.requirePermissionToResume] to register
  /// resume requirements for [client].
  Future<RpcResponse> requirePermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) {
    return backend.isolateManager.requirePermissionToResume(parameters, client);
  }

  /// Handles the `requireUserPermissionToResume` custom DDS RPC.
  ///
  /// Delegates to [DdsIsolateManager.requireUserPermissionToResume] to
  /// configure whether user approval is required to resume isolates.
  Future<RpcResponse> requireUserPermissionToResume(
    json_rpc.Parameters parameters,
    Client client,
  ) {
    return backend.isolateManager.requireUserPermissionToResume(
      parameters,
      client,
    );
  }

  /// Handles the VM Service `resume` RPC.
  ///
  /// Delegates to [DdsIsolateManager.resume] to record [client] resume approval
  /// and resume the isolate if all required approvals are satisfied.
  Future<RpcResponse> resume(json_rpc.Parameters parameters, Client client) {
    return backend.isolateManager.resume(parameters, client);
  }

  /// Handles the `setLogHistorySize` custom DDS RPC.
  ///
  /// Updates the maximum capacity of the logging ring buffer to `size`
  /// entries.
  RpcResponse setLogHistorySize(json_rpc.Parameters parameters) {
    final size = parameters['size'].asInt;
    backend.streamManager.setLogHistorySize(size);
    return vm.Success().toJson();
  }
}
