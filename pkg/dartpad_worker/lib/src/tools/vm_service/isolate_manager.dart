// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart';

import '../../shared.dart';
import '../frontend_server_compiler.dart';
import '../sandbox_client.dart';

extension RunningIsolateRefExt on RunningIsolate {
  String get isolateId => 'isolates/$id';

  IsolateRef get isolateRef => IsolateRef(
    id: isolateId,
    name: name,
    number: '$id',
    isSystemIsolate: false,
  );
}

extension IsolateManagerRefExt on IsolateManager {
  IsolateRef? get currentIsolateRef => isolates.values.firstOrNull?.isolateRef;
}

/// Creates an [IsolateManager] managing the synthetic DDC isolate inside a
/// DartPad sandbox.
IsolateManager createSandboxIsolateManager({
  required SandboxClient client,
  required ResourceProvider resourceProvider,
  required DartPadConfig config,
  required String? Function() packageConfigPath,
  required void Function(String streamId, Event event) emitEvent,
}) => _SandboxIsolateManager(
  client: client,
  resourceProvider: resourceProvider,
  config: config,
  packageConfigPath: packageConfigPath,
  emitEvent: emitEvent,
);

/// Represents the single synthetic DDC isolate running inside a DartPad
/// sandbox `<iframe>`, analogous to DWDS's `AppInspector` / `createIsolate`.
final class _SandboxRunningIsolate extends RunningIsolate {
  final String entrypointUri;
  final int startTimeMillis;
  final Set<String> libraryUris;
  final Set<String> extensionRPCs = {};

  _SandboxRunningIsolate({
    required super.id,
    required this.entrypointUri,
    required this.startTimeMillis,
    required Iterable<String> libraryUris,
  }) : libraryUris = {entrypointUri, ...libraryUris},
       super(name: 'main');

  Event get pauseEvent => Event(
    kind: EventKind.kResume,
    isolate: isolateRef,
    timestamp: startTimeMillis,
  );

  List<LibraryRef> get libraries => [
    for (final uri in libraryUris)
      LibraryRef(
        id: 'libraries/$uri',
        name: uri == entrypointUri ? 'main' : uri,
        uri: uri,
      ),
  ];

  Isolate toIsolate() {
    final libs = libraries;
    return Isolate(
      id: isolateId,
      name: name,
      number: '$id',
      isSystemIsolate: false,
      startTime: startTimeMillis,
      runnable: true,
      livePorts: 1,
      pauseOnExit: false,
      pauseEvent: pauseEvent,
      rootLib: libs.first,
      libraries: libs,
      breakpoints: const [],
      exceptionPauseMode: ExceptionPauseMode.kNone,
      extensionRPCs: extensionRPCs.toList(),
      isolateFlags: const [],
    );
  }
}

/// Precompiled DDC SDK libraries (mirrors `MetadataProvider.sdkLibraries` in
/// `package:dwds`).
const _sdkLibraries = [
  'dart:_runtime',
  'dart:_debugger',
  'dart:_foreign_helper',
  'dart:_interceptors',
  'dart:_internal',
  'dart:_isolate_helper',
  'dart:_js_helper',
  'dart:_js_primitives',
  'dart:_metadata',
  'dart:_native_typed_data',
  'dart:_rti',
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:developer',
  'dart:io',
  'dart:isolate',
  'dart:js',
  'dart:js_interop',
  'dart:js_interop_unsafe',
  'dart:js_util',
  'dart:math',
  'dart:typed_data',
  'dart:indexed_db',
  'dart:html',
  'dart:html_common',
  'dart:svg',
  'dart:web_audio',
  'dart:web_gl',
  'dart:ui',
  'dart:ui_web',
];

/// Manages the single synthetic DDC isolate lifecycle using [IsolateManager]
/// from `package:dart_runtime_service`.
final class _SandboxIsolateManager extends IsolateManager {
  final SandboxClient _client;
  final ResourceProvider _rp;
  final DartPadConfig _config;
  final String? Function() _packageConfigPath;
  final void Function(String streamId, Event event) _emitEvent;
  final _subscriptions = <StreamSubscription<Object?>>[];
  int _nextGeneration = 1;
  _SandboxRunningIsolate? _current;

  _SandboxIsolateManager({
    required SandboxClient client,
    required ResourceProvider resourceProvider,
    required DartPadConfig config,
    required String? Function() packageConfigPath,
    required void Function(String streamId, Event event) emitEvent,
  }) : _client = client,
       _rp = resourceProvider,
       _config = config,
       _packageConfigPath = packageConfigPath,
       _emitEvent = emitEvent {
    _subscriptions.addAll([
      client.onIsolateEvent.listen(_handleIsolateEvent),
      client.onRegisterExtension.listen(_registerExtension),
    ]);
  }

  _SandboxRunningIsolate? _lookupIsolate(
    String method,
    Map<String, Object?> params,
  ) {
    if (params['isolateId'] is! String) {
      RpcException.invalidParams.throwExceptionWithDetails(
        details:
            "$method: invalid 'isolateId' parameter: ${params['isolateId']}",
      );
    }
    return lookupIsolateFromParams(method: method, params: params)
        as _SandboxRunningIsolate?;
  }

  @override
  Future<void> shutdown() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await super.shutdown();
  }

  @override
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  }) async {
    if (method.startsWith('ext.')) {
      return await _invokeExtension(method, params);
    }
    final isolate = _lookupIsolate(method, params);
    if (isolate == null) {
      return Sentinel(
        kind: SentinelKind.kCollected,
        valueAsString: '<collected>',
      ).toJson();
    }

    return switch (method) {
      'getIsolate' => isolate.toIsolate().toJson(),
      // Return an empty script list, matching DWDS WebSocket mode.
      'getScripts' => ScriptList(scripts: const []).toJson(),
      'getObject' => _getObject(params),
      'lookupResolvedPackageUris' => _lookupResolvedPackageUris(params),
      'lookupPackageUris' => _lookupPackageUris(params),
      _ => RpcException.methodNotFound.throwException(),
    };
  }

  Future<RpcResponse> _invokeExtension(
    String method,
    Map<String, Object?> params,
  ) async {
    final isolate = params['isolateId'] != null
        ? _lookupIsolate(method, params)
        : _current;
    if (isolate == null) {
      return Sentinel(
        kind: SentinelKind.kCollected,
        valueAsString: '<collected>',
      ).toJson();
    }
    if (!isolate.extensionRPCs.contains(method)) {
      RpcException.methodNotFound.throwExceptionWithDetails(
        details:
            'Service extension $method is not registered on '
            '${isolate.isolateId}.',
      );
    }
    final args = <String, String>{
      for (final entry in params.entries)
        if (entry.key != 'isolateId' && entry.value != null)
          entry.key: entry.value is String
              ? entry.value as String
              : jsonEncode(entry.value),
    };
    final rawResult = await _client.invokeExtension(method, args);
    final decoded = jsonDecode(rawResult);
    if (decoded case {
      'code': final int code,
      'message': final String message,
    }) {
      throw json_rpc.RpcException(code, message, data: decoded['data']);
    }
    return <String, Object?>{
      'type': '_extensionType',
      if (decoded is Map)
        ...decoded.cast<String, Object?>()
      else
        'result': decoded,
    };
  }

  RpcResponse _getObject(Map<String, Object?> params) {
    final objectId = params['objectId'];
    if (objectId is! String) {
      RpcException.invalidParams.throwExceptionWithDetails(
        details: "getObject: invalid 'objectId' parameter: $objectId",
      );
    }
    return Sentinel(
      kind: SentinelKind.kCollected,
      valueAsString: '<collected>',
    ).toJson();
  }

  ({PackageConfig packages, String root})? _loadPackages() {
    final path = _packageConfigPath();
    if (path == null) return null;
    final file = _rp.getFile(path);
    if (!file.exists) return null;
    final context = _rp.pathContext;
    final packages = PackageConfig.parseString(
      file.readAsStringSync(),
      context.toUri(path),
    );
    final root = context.dirname(context.dirname(path));
    return (packages: packages, root: root);
  }

  RpcResponse _lookupResolvedPackageUris(Map<String, Object?> params) {
    final uris = params['uris'];
    if (uris is! List) {
      RpcException.invalidParams.throwExceptionWithDetails(
        details: "lookupResolvedPackageUris: invalid 'uris' parameter: $uris",
      );
    }
    final loaded = _loadPackages();
    return UriList(
      uris: [
        for (final uri in uris)
          if (uri is String) _resolvePackageUri(uri, loaded) else null,
      ],
    ).toJson();
  }

  RpcResponse _lookupPackageUris(Map<String, Object?> params) {
    final uris = params['uris'];
    if (uris is! List) {
      RpcException.invalidParams.throwExceptionWithDetails(
        details: "lookupPackageUris: invalid 'uris' parameter: $uris",
      );
    }
    final loaded = _loadPackages();
    return UriList(
      uris: [
        for (final uri in uris)
          if (uri is String) _unresolvePackageUri(uri, loaded) else null,
      ],
    ).toJson();
  }

  String? _resolvePackageUri(
    String uriString,
    ({PackageConfig packages, String root})? loaded,
  ) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if (uri.isScheme('file')) {
      return uriString;
    }
    if (loaded == null) return null;
    if (uri.isScheme('package')) {
      return loaded.packages.resolve(uri)?.toString();
    }
    if (uri.isScheme(FrontendServerCompiler.scheme)) {
      final context = _rp.pathContext;
      return context
          .toUri(context.joinAll([loaded.root, ...uri.pathSegments]))
          .toString();
    }
    return null;
  }

  String? _unresolvePackageUri(
    String uriString,
    ({PackageConfig packages, String root})? loaded,
  ) {
    final uri = Uri.tryParse(uriString);
    if (uri == null || !uri.isScheme('file') || loaded == null) return null;
    if (loaded.packages.toPackageUri(uri) case final packageUri?) {
      return packageUri.toString();
    }
    final context = _rp.pathContext;
    final path = context.fromUri(uri);
    if (context.isWithin(loaded.root, path)) {
      return Uri(
        scheme: FrontendServerCompiler.scheme,
        host: '',
        pathSegments: context.split(context.relative(path, from: loaded.root)),
      ).toString();
    }
    return null;
  }

  void _handleIsolateEvent(SandboxIsolateEvent event) {
    switch (event) {
      case SandboxIsolateStarted(
        :final entrypointUri,
        :final mode,
        :final libraries,
      ):
        _createIsolate(
          entrypointUri: entrypointUri,
          mode: mode,
          libraries: libraries,
        );
      case SandboxIsolateExited():
        _destroyIsolate();
      case SandboxIsolateReloaded(:final libraries):
        _reloadIsolate(libraries: libraries);
    }
  }

  void _createIsolate({
    required String entrypointUri,
    required String mode,
    required List<String> libraries,
  }) {
    _destroyIsolate();
    final id = _nextGeneration++;
    final now = DateTime.now().millisecondsSinceEpoch;
    final modeLibraries = _config.modes
        .where((m) => m.mode == mode)
        .firstOrNull
        ?.libraries;
    final isolate = _SandboxRunningIsolate(
      id: id,
      entrypointUri: entrypointUri,
      startTimeMillis: now,
      libraryUris: [..._sdkLibraries, ...?modeLibraries, ...libraries],
    );
    _current = isolate;
    isolateStarted(isolate: isolate);

    final ref = isolate.isolateRef;
    _emitEvent(
      EventStreams.kIsolate,
      Event(kind: EventKind.kIsolateStart, isolate: ref, timestamp: now),
    );
    _emitEvent(
      EventStreams.kIsolate,
      Event(kind: EventKind.kIsolateRunnable, isolate: ref, timestamp: now),
    );
  }

  void _destroyIsolate() {
    final running = _current;
    if (running == null) return;
    _current = null;
    rootIsolateId = null;
    isolateExited(id: running.id);
    _emitEvent(
      EventStreams.kIsolate,
      Event(
        kind: EventKind.kIsolateExit,
        isolate: running.isolateRef,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _reloadIsolate({required List<String> libraries}) {
    final running = _current;
    if (running == null) return;
    running.libraryUris.addAll(libraries);
    _emitEvent(
      EventStreams.kIsolate,
      Event(
        kind: EventKind.kIsolateReload,
        isolate: running.isolateRef,
        status: 'success',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _registerExtension(String method) {
    final running = _current;
    if (running != null && running.extensionRPCs.add(method)) {
      _emitEvent(
        EventStreams.kIsolate,
        Event(
          kind: EventKind.kServiceExtensionAdded,
          isolate: running.isolateRef,
          extensionRPC: method,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }
}
