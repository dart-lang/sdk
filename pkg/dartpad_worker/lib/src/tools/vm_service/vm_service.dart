// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart';

import '../../shared.dart';
import '../sandbox_client.dart';
import 'isolate_manager.dart';
import 'logging_repository.dart';
import 'runner_client.dart';
import 'stream_event.dart';

final _vmServiceVersionParts = vmServiceVersion
    .split('.')
    .map(int.parse)
    .toList(growable: false);
final _vmServiceMajorVersion = _vmServiceVersionParts[0];
final _vmServiceMinorVersion = _vmServiceVersionParts[1];

/// Creates and initializes a [DartRuntimeService] router backed by [client].
Future<DartRuntimeService> createDartPadVmService({
  required SandboxClient client,
  required ResourceProvider resourceProvider,
  required DartPadConfig config,
  required VersionInfo version,
  required String? Function() packageConfigPath,
  required Future<void> Function() onHotRestart,
  required Future<void> Function() onHotReload,
}) => DartRuntimeService.initialize(
  config: const DartRuntimeServiceOptions(
    autoStart: false,
    disableAuthCodes: true,
  ),
  backendBuilder: (frontend) => _DartPadVmServiceBackend(
    frontend: frontend,
    client: client,
    resourceProvider: resourceProvider,
    config: config,
    version: version,
    packageConfigPath: packageConfigPath,
    onHotRestart: onHotRestart,
    onHotReload: onHotReload,
  ),
);

/// Private [DartRuntimeServiceBackend] implementation that bridges a
/// [DartRuntimeService] frontend to a DartPad [SandboxClient].
final class _DartPadVmServiceBackend
    extends DartRuntimeServiceBackend<IsolateManager> {
  final SandboxClient _client;
  final VersionInfo _version;
  final Future<void> Function() _onHotRestart;
  final Future<void> Function() _onHotReload;

  @override
  late final IsolateManager isolateManager;

  final _loggingRepository = LoggingRepository();
  final _subscriptions = <StreamSubscription<Object?>>[];
  final int _vmStartTimeMillis = DateTime.now().millisecondsSinceEpoch;

  _DartPadVmServiceBackend({
    required super.frontend,
    required SandboxClient client,
    required ResourceProvider resourceProvider,
    required DartPadConfig config,
    required VersionInfo version,
    required String? Function() packageConfigPath,
    required Future<void> Function() onHotRestart,
    required Future<void> Function() onHotReload,
  }) : _client = client,
       _version = version,
       _onHotRestart = onHotRestart,
       _onHotReload = onHotReload {
    isolateManager = createSandboxIsolateManager(
      client: _client,
      resourceProvider: resourceProvider,
      config: config,
      packageConfigPath: packageConfigPath,
      emitEvent: _emitEvent,
    );
  }

  @override
  Future<void> initialize() async {
    _subscriptions.addAll([
      _client.onConsole.listen(_handleConsoleEvent),
      _client.onExtensionEvent.listen(_handleExtensionEvent),
      _client.onLog.listen(_handleDeveloperLog),
    ]);
    attachDartPadRunnerClient(
      service: frontend,
      onHotReload: _onHotReload,
      onHotRestart: _onHotRestart,
      flutterVersion: _buildFlutterVersion(_version),
    );
  }

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {}

  @override
  Future<void> onServerShutdown() async {}

  @override
  Future<void> clearState() async {}

  @override
  Future<void> shutdown() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await isolateManager.shutdown();
  }

  @override
  void onClientSubscribe(Client client, String streamId) {
    _loggingRepository.sendHistoricalEvents(client, streamId);
  }

  @override
  late final UnmodifiableListView<ServiceRpcHandler> rpcs =
      UnmodifiableListView([
        ('getVersion', _getVersion),
        ('getSupportedProtocols', _getSupportedProtocols),
        ('getVM', _getVM),
        ('getFlagList', _getFlagList),
        ('reloadSources', _reloadSources),
        ('getIsolate', _sendToIsolate),
        ('getScripts', _sendToIsolate),
        ('getObject', _sendToIsolate),
        ('lookupResolvedPackageUris', _sendToIsolate),
        ('lookupPackageUris', _sendToIsolate),
      ]);

  @override
  late final UnmodifiableListView<RpcHandlerWithParameters> fallbacks =
      UnmodifiableListView([_invokeExtensionFallback]);

  /// Implements the 'getVersion' RPC method.
  RpcResponse _getVersion() => Version(
    major: _vmServiceMajorVersion,
    minor: _vmServiceMinorVersion,
  ).toJson();

  /// Implements the 'getSupportedProtocols' RPC method.
  RpcResponse _getSupportedProtocols() => ProtocolList(
    protocols: [
      Protocol(
        protocolName: 'VM Service',
        major: _vmServiceMajorVersion,
        minor: _vmServiceMinorVersion,
      ),
    ],
  ).toJson();

  /// Implements the 'getVM' RPC method.
  ///
  /// Uses `name: 'WebSocketDebugProxy'` (matching DWDS's
  /// `WebSocketProxyService`) because DevTools checks for `'ChromeDebugProxy'`
  /// or `'WebSocketDebugProxy'` to detect that the target is a web app rather
  /// than a native Dart VM (`ConnectedApp.isRunningOnDartVM`), and treats
  /// `'WebSocketDebugProxy'` as a web app without a Chrome CDP JS debugger.
  RpcResponse _getVM() {
    final isolates = isolateManager.isolates.values;
    return VM(
      name: 'WebSocketDebugProxy',
      architectureBits: -1,
      hostCPU: 'DWDS',
      operatingSystem: 'web',
      targetCPU: 'Web',
      version: _version.dartVersion,
      pid: -1,
      startTime: _vmStartTimeMillis,
      isolates: [for (final i in isolates) i.isolateRef],
      isolateGroups: const [],
      systemIsolates: const [],
      systemIsolateGroups: const [],
    ).toJson();
  }

  /// Implements the 'getFlagList' RPC method.
  RpcResponse _getFlagList() => FlagList(flags: const []).toJson();

  /// Implements the 'reloadSources' RPC method.
  Future<RpcResponse> _reloadSources(json_rpc.Parameters _) =>
      reloadSourcesRpc(_onHotReload);

  /// Forwards an isolate-scoped RPC method to [isolateManager].
  Future<RpcResponse> _sendToIsolate(json_rpc.Parameters params) =>
      isolateManager.sendToIsolate(
        method: params.method,
        params: params.asMap.cast<String, Object?>(),
      );

  /// Fallback handler for dynamic `ext.*` service extension RPCs registered in
  /// the sandbox isolate via `dart:developer.registerExtension`.
  Future<RpcResponse> _invokeExtensionFallback(json_rpc.Parameters params) {
    final method = params.method;
    if (!method.startsWith('ext.')) {
      RpcException.methodNotFound.throwExceptionWithDetails(
        details: 'Method $method is not supported in DartPad.',
      );
    }
    final rawMap = params.value is Map
        ? params.asMap.cast<String, Object?>()
        : const <String, Object?>{};
    return isolateManager.sendToIsolate(method: method, params: rawMap);
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  void _emitEvent(String streamId, Event event) {
    final streamEvent = createStreamEvent(streamId: streamId, event: event);
    _loggingRepository.add(streamEvent);
    frontend.sendEvent(event: streamEvent);
  }

  void _handleConsoleEvent(({String level, String message}) event) {
    final isError = event.level == 'error' || event.level == 'warn';
    final streamId = isError ? EventStreams.kStderr : EventStreams.kStdout;
    _emitEvent(
      streamId,
      Event(
        kind: EventKind.kWriteEvent,
        isolate: isolateManager.currentIsolateRef,
        bytes: base64Encode(utf8.encode('${event.message}\n')),
        timestamp: _now(),
      ),
    );
  }

  void _handleExtensionEvent(({String kind, Map<String, Object?> data}) event) {
    final data = Map<String, Object?>.of(event.data);
    final destinationStream = data.remove('__destinationStream');
    final streamId = destinationStream is String
        ? destinationStream
        : EventStreams.kExtension;
    _emitEvent(
      streamId,
      Event(
        kind: EventKind.kExtension,
        isolate: isolateManager.currentIsolateRef,
        extensionKind: event.kind,
        extensionData: ExtensionData.parse(data),
        timestamp: _now(),
      ),
    );
  }

  void _handleDeveloperLog(SandboxLogRecord record) {
    _emitEvent(
      EventStreams.kLogging,
      Event(
        kind: EventKind.kLogging,
        isolate: isolateManager.currentIsolateRef,
        logRecord: record.toLogRecord(),
        timestamp: record.time,
      ),
    );
  }
}

Map<String, Object?>? _buildFlutterVersion(VersionInfo version) {
  final flutterVersion = version.properties['flutterVersion'];
  if (flutterVersion == null) return null;
  String? shortRev(String? rev) => rev != null && rev.isNotEmpty
      ? (rev.length > 10 ? rev.substring(0, 10) : rev)
      : null;
  final flutterRevision = version.properties['flutterRevision'];
  final engineRevision = version.properties['engineRevision'];
  return <String, Object?>{
    'type': 'FlutterVersion',
    'frameworkVersion': flutterVersion,
    'flutterVersion': flutterVersion,
    'frameworkRevision': ?flutterRevision,
    'frameworkRevisionShort': ?shortRev(flutterRevision),
    'engineRevision': ?engineRevision,
    'engineRevisionShort': ?shortRev(engineRevision),
    'dartSdkVersion': version.dartVersion,
  };
}
