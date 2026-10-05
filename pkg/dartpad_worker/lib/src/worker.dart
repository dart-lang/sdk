// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';

import 'resource_provider/resource_provider_ext.dart';
import 'resource_provider/resource_provider_wrap_cwd.dart';
import 'shared.dart' hide FileSystemException;
import 'tools/file_watch.dart';
import 'tools/language_server.dart';
import 'tools/pub.dart';
import 'tools/sandbox.dart';
import 'util/parameters_ext.dart';
import 'worker_protocol_version.dart';

final class Worker {
  final ResourceProvider _rp;
  final DartPadConfig _config;
  final VersionInfo _version;
  final _analysisCache = MemoryCachingByteStore(
    NullByteStore(),
    128 * 1024 * 1024,
  );
  int _nextLanguageServerId = 1;
  int _nextWorkspaceId = 1;
  int _nextWatcherId = 1;
  int _nextSandboxId = 1;

  Worker._(this._rp, this._config, this._version);

  static String _readRequiredFile(ResourceProvider rp, String path) {
    final file = rp.getFile(path);
    if (!file.exists) {
      throw FormatException('sdk.tar must contain $path');
    }
    return file.readAsStringSync().trim();
  }

  static Future<Worker> create(
    Stream<List<int>> sdkTarStream, {
    String? pubHostedUrl,
  }) async {
    final rp = MemoryResourceProvider(context: p.posix);
    await rp.getFolder('/').extractTarStream(sdkTarStream);

    final configFile = rp.getFile(DartPadConfig.defaultDartPadConfigPath);
    if (!configFile.exists) {
      throw const FormatException(
        'sdk.tar must contain ${DartPadConfig.defaultDartPadConfigPath}',
      );
    }
    final DartPadConfig config;
    try {
      config = DartPadConfig.fromJson(
        jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>,
      ).copyWith(pubHostedUrl: pubHostedUrl);
    } catch (e) {
      throw FormatException(
        'Error reading ${DartPadConfig.defaultDartPadConfigPath}: $e',
      );
    }

    final dartVersion = _readRequiredFile(
      rp,
      rp.pathContext.join(config.dartSdkPath, 'version'),
    );
    final dartRevision = _readRequiredFile(
      rp,
      rp.pathContext.join(config.dartSdkPath, 'revision'),
    );

    final properties = <String, String>{};
    if (config.flutterSdkPath case final flutterSdkPath?) {
      final flutterVersionPath = rp.pathContext.join(
        flutterSdkPath,
        'bin',
        'cache',
        'flutter.version.json',
      );
      final flutterVersionContent = _readRequiredFile(rp, flutterVersionPath);
      final Map<String, Object?> flutterVersionJson;
      try {
        flutterVersionJson =
            jsonDecode(flutterVersionContent) as Map<String, Object?>;
      } catch (e) {
        throw FormatException('Error reading $flutterVersionPath: $e');
      }
      properties.addAll(extractFlutterVersionProperties(flutterVersionJson));
    }

    final version = createVersionInfo(
      workerProtocolMajor: workerProtocolMajorVersion,
      workerProtocolMinor: workerProtocolMinorVersion,
      modes: [for (final m in config.modes) m.mode],
      dartVersion: dartVersion,
      dartRevision: dartRevision,
      properties: properties,
    );

    return Worker._(rp, config, version);
  }

  void session(StreamChannel<Object?> channel) {
    _Session(channel, this);
  }
}

class _Session {
  static const _idleTimeout = Duration(minutes: 5);
  static const _idleCheckInterval = Duration(seconds: 60);
  static const _idleConfirmDelay = Duration(seconds: 40);

  final Worker _worker;
  late final Peer _rpc;
  final _workspaces = <int, _Workspace>{};
  DateTime _lastActivity = clock.now();
  int _activeRequests = 0;

  _Session(StreamChannel<Object?> channel, this._worker) {
    _rpc = Peer.withoutJson(channel, onUnhandledError: _onUnhandledError);
    _registerMethod('version', _version);
    _registerMethod('ping', (_) => <String, Object?>{});
    _registerMethod('createWorkspace', _createWorkspace);
    _registerMethod('workspace/close', _closeWorkspace);
    _registerMethod(
      'workspace/writeFileFromText',
      _forwardToWorkspace((ws) => ws._writeFileFromText),
    );
    _registerMethod(
      'workspace/writeFileFromBytes',
      _forwardToWorkspace((ws) => ws._writeFileFromBytes),
    );
    _registerMethod(
      'workspace/readFileAsText',
      _forwardToWorkspace((ws) => ws._readFileAsText),
    );
    _registerMethod(
      'workspace/readFileAsBytes',
      _forwardToWorkspace((ws) => ws._readFileAsBytes),
    );
    _registerMethod(
      'workspace/deleteFileSystemEntity',
      _forwardToWorkspace((ws) => ws._deleteFileSystemEntity),
    );
    _registerMethod('workspace/stat', _forwardToWorkspace((ws) => ws._stat));
    _registerMethod(
      'workspace/listDirectory',
      _forwardToWorkspace((ws) => ws._listDirectory),
    );
    _registerMethod(
      'workspace/importTarArchive',
      _forwardToWorkspace((ws) => ws._importTarArchive),
    );
    _registerMethod(
      'workspace/exportTarArchive',
      _forwardToWorkspace((ws) => ws._exportTarArchive),
    );
    _registerMethod(
      'workspace/createFolder',
      _forwardToWorkspace((ws) => ws._createFolder),
    );
    _registerMethod('workspace/pub', _forwardToWorkspace((ws) => ws._pub));
    _registerMethod(
      'workspace/startLanguageServer',
      _forwardToWorkspace((ws) => ws._startLanguageServer),
    );
    _registerMethod(
      'workspace/languageServer/message',
      _forwardToWorkspace((ws) => ws._languageServerMessage),
    );
    _registerMethod(
      'workspace/languageServer/close',
      _closeInWorkspace((ws) => ws._closeLanguageServer),
    );
    _registerMethod(
      'workspace/startWatcher',
      _forwardToWorkspace((ws) => ws._watch),
    );
    _registerMethod(
      'workspace/watcher/close',
      _closeInWorkspace((ws) => ws._closeWatcher),
    );
    _registerMethod(
      'workspace/connectSandbox',
      _forwardToWorkspace((ws) => ws._connectSandbox),
    );
    _registerMethod(
      'workspace/sandbox/run',
      _forwardToWorkspace((ws) => ws._sandboxRun),
    );
    _registerMethod(
      'workspace/sandbox/hotRestart',
      _forwardToWorkspace((ws) => ws._sandboxHotRestart),
    );
    _registerMethod(
      'workspace/sandbox/hotReload',
      _forwardToWorkspace((ws) => ws._sandboxHotReload),
    );
    _registerMethod(
      'workspace/sandbox/close',
      _closeInWorkspace((ws) => ws._sandboxClose),
    );
    _registerMethod(
      'workspace/sandbox/connectServiceProtocol',
      _forwardToWorkspace((ws) => ws._sandboxConnectServiceProtocol),
    );
    // Every 60s, if the session has no in-flight requests and has been idle for
    // at least 5 minutes, wait an extra 40s (30s ping interval + 10s slack) and
    // re-check before closing. This gives a client that unfroze simultaneously
    // with the worker (or whose pings were queued behind a long compile) time
    // to send a ping before the session is reaped.
    bool isIdle() =>
        _activeRequests == 0 &&
        clock.now().difference(_lastActivity) >= _idleTimeout;

    Timer? confirmTimer;
    final idleTimer = Timer.periodic(_idleCheckInterval, (_) {
      if (isIdle() && !(confirmTimer?.isActive ?? false)) {
        confirmTimer = Timer(_idleConfirmDelay, () {
          if (isIdle()) {
            _rpc.close().ignore();
          }
        });
      }
    });
    unawaited(() async {
      try {
        await _rpc.listen();
      } finally {
        idleTimer.cancel();
        confirmTimer?.cancel();
        // Delete all workspaces to cleanup resources
        await Future.wait(
          _workspaces.values.toList().map((ws) => ws._closeWorkspace()),
        );
      }
    }());
  }

  void _registerMethod(String name, Object? Function(Parameters) callback) {
    _rpc.registerMethod(name, (Parameters params) async {
      _activeRequests++;
      _lastActivity = clock.now();
      try {
        return await (callback(params) as FutureOr<Object?>);
      } finally {
        _activeRequests--;
        _lastActivity = clock.now();
      }
    });
  }

  Map<String, Object?> _version(Parameters _) => _worker._version.toJson();

  Object? _createWorkspace(Parameters params) async {
    final workspaceId = _worker._nextWorkspaceId++;
    final workspaceFolder = '/workspace/pad_$workspaceId';
    _worker._rp.getFolder(workspaceFolder).create();
    _workspaces[workspaceId] = _Workspace(
      _worker,
      this,
      workspaceId,
      workspaceFolder,
      resourceProviderWithCurrentWorkingDirectory(_worker._rp, workspaceFolder),
    );
    return {'workspaceId': workspaceId, 'workspaceFolder': workspaceFolder};
  }

  Object? _closeWorkspace(Parameters params) async {
    final workspace = _workspaces.remove(params['workspaceId'].asNum.toInt());
    if (workspace != null) {
      await workspace._closeWorkspace();
    }
    // Closing a workspace that doesn't exist is a no-op
    // This ensures that closing is an idempotent operation!
    return <String, Object?>{};
  }

  Object? Function(Parameters) _forwardToWorkspace(
    Object? Function(Parameters params) Function(_Workspace ws) resolveHandler,
  ) {
    return (Parameters params) async {
      final workspaceId = params['workspaceId'].asNum.toInt();
      final workspace = _workspaces[workspaceId];
      if (workspace == null) {
        throw WorkspaceNotFoundException(
          'Invalid "workspaceId", no such workspace exists',
          data: {'workspaceId': workspaceId},
        );
      }
      return resolveHandler(workspace)(params);
    };
  }

  /// Like [_forwardToWorkspace], but for methods closing a resource held by
  /// the workspace. Closing a workspace closes all its resources, so these
  /// are a no-op when the workspace doesn't exist.
  Object? Function(Parameters) _closeInWorkspace(
    Object? Function(Parameters params) Function(_Workspace ws) resolveHandler,
  ) {
    return (Parameters params) async {
      final workspace = _workspaces[params['workspaceId'].asNum.toInt()];
      if (workspace == null) {
        return <String, Object?>{};
      }
      return resolveHandler(workspace)(params);
    };
  }

  void _onUnhandledError(Object? e, Object? st) {
    print('Unhandled error not forwarded to the client: $e, $st');
  }
}

class _Workspace {
  final Worker _worker;
  final _Session _session;
  final int _workspaceId;
  final String _workspaceFolder;
  final ResourceProvider _rp;
  final _languageServers = <int, LanguageServer>{};
  final _fileWatches = <int, FileWatch>{};
  final _sandboxes = <int, Sandbox>{};

  _Workspace(
    this._worker,
    this._session,
    this._workspaceId,
    this._workspaceFolder,
    this._rp,
  );

  String _resolvePath(String path) =>
      _rp.pathContext.normalize(_rp.pathContext.join(_workspaceFolder, path));

  Object? _writeFileFromText(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final text = params['text'].asString;
    try {
      final file = _rp.getFile(path);
      file.writeAsStringSync(text);
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(e.message, data: {'path': path});
    }
    return <String, Object?>{};
  }

  Object? _writeFileFromBytes(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final bytes = params.bytesAsUint8List;
    try {
      final file = _rp.getFile(path);
      file.writeAsBytesSync(bytes);
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(e.message, data: {'path': path});
    }
    return <String, Object?>{};
  }

  Object? _readFileAsText(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    try {
      return {'text': _rp.getFile(path).readAsStringSync()};
    } on FileSystemException catch (e) {
      throw FileNotFoundException(e.message, data: {'path': path});
    }
  }

  Object? _readFileAsBytes(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    try {
      return {'bytes': _rp.getFile(path).readAsBytesSync()};
    } on FileSystemException catch (e) {
      throw FileNotFoundException(e.message, data: {'path': path});
    }
  }

  Object? _deleteFileSystemEntity(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    try {
      final resource = _rp.getResource(path);
      // Safe to check before delete: synchronous on an in-memory filesystem.
      if (resource.exists) {
        resource.delete();
      }
    } on FileSystemException catch (e) {
      throw FileDeletionFailedException(e.message, data: {'path': path});
    }
    return <String, Object?>{};
  }

  Object? _stat(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final resource = _rp.getResource(path);
    if (!resource.exists) {
      throw FileNotFoundException(
        'File or directory not found',
        data: {'path': path},
      );
    }
    if (resource is File) {
      return {'type': 'file', 'size': resource.lengthSync};
    } else if (resource is Folder) {
      return {'type': 'folder'};
    } else {
      return {'type': 'other'};
    }
  }

  Object? _createFolder(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    try {
      _rp.getFolder(path).create();
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(e.message, data: {'path': path});
    }
    return <String, Object?>{};
  }

  Object? _listDirectory(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final recursive = params['recursive'].asBoolOr(false);
    final ignoreHidden = params['ignoreHidden'].asBoolOr(false);

    try {
      final folder = _rp.getFolder(path);
      if (!folder.exists) {
        throw FileSystemException('Directory not found', path);
      }
      final entries = <Map<String, String>>[];

      void traverse(Folder dir) {
        for (final child in dir.getChildren()) {
          if (ignoreHidden && child.shortName.startsWith('.')) continue;

          final relativePath = _rp.pathContext.relative(child.path, from: path);
          if (child is File) {
            entries.add({'path': relativePath, 'type': 'file'});
          } else if (child is Folder) {
            entries.add({'path': relativePath, 'type': 'folder'});
            if (recursive) {
              traverse(child);
            }
          }
        }
      }

      traverse(folder);

      return {'entries': entries};
    } on FileSystemException catch (e) {
      throw FileNotFoundException(e.message, data: {'path': path});
    }
  }

  Object? _importTarArchive(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final bytes = params.bytesAsUint8List;

    await _rp.getFolder(path).extractTarStream(Stream.value(bytes));

    return <String, Object?>{};
  }

  Object? _exportTarArchive(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final folder = _rp.getFolder(path);
    if (!folder.exists) {
      throw FileNotFoundException('Directory not found', data: {'path': path});
    }

    return {'bytes': await collectBytes(folder.createTarStream())};
  }

  Object? _pub(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final command = params['command'].asString;
    final args = params['args'].asListOr(const <String>[]);
    if (!supportedPubCommands.contains(command)) {
      throw RpcException.invalidParams(
        '`command` must be one of: ${supportedPubCommands.join(', ')}',
      );
    }

    if (args.any((a) => a is! String)) {
      throw RpcException.invalidParams('args must be a list of strings');
    }

    final (:log) = await pub(
      resourceProvider: _rp,
      currentWorkingDirectory: path,
      command: command,
      args: args.whereType<String>().toList(),
      config: _worker._config,
      version: _worker._version,
    );

    return {'log': log};
  }

  Object? _startLanguageServer(Parameters params) async {
    final languageServerId = _worker._nextLanguageServerId++;
    final ls = _languageServers[languageServerId] = LanguageServer(
      resourceProvider: _rp,
      config: _worker._config,
      byteStore: _worker._analysisCache,
    );
    ls.messages.listen((m) {
      _session._rpc.sendNotification('workspace/languageServer/message', {
        'workspaceId': _workspaceId,
        'languageServerId': languageServerId,
        'message': m,
      });
    });
    unawaited(
      ls.closed.whenComplete(() {
        _session._rpc.sendNotification('workspace/languageServer/exited', {
          'workspaceId': _workspaceId,
          'languageServerId': languageServerId,
        });
      }),
    );
    return {'languageServerId': languageServerId};
  }

  Object? _languageServerMessage(Parameters params) async {
    final languageServerId = params['languageServerId'].asNum.toInt();
    final languageServer = _languageServers[languageServerId];
    if (languageServer == null) {
      throw LanguageServerNotFoundException(
        'Language server not found, check the "languageServerId"',
        data: {
          'workspaceId': _workspaceId,
          'languageServerId': languageServerId,
        },
      );
    }
    await languageServer.handle(params['message'].asMap.cast());
    return <String, Object?>{};
  }

  Object? _closeLanguageServer(Parameters params) async {
    final languageServerId = params['languageServerId'].asNum.toInt();
    final languageServer = _languageServers.remove(languageServerId);
    await languageServer?.close();
    return <String, Object?>{};
  }

  Object? _watch(Parameters params) async {
    final path = _resolvePath(params['path'].asString);
    final watcherId = _worker._nextWatcherId++;

    _fileWatches[watcherId] = await FileWatch.create(_rp, path, (events) {
      _session._rpc.sendNotification('workspace/watcher/events', {
        'workspaceId': _workspaceId,
        'watcherId': watcherId,
        'events': events.map((e) => {'type': e.event, 'path': e.path}).toList(),
      });
    });

    return {'watcherId': watcherId};
  }

  Object? _closeWatcher(Parameters params) async {
    final watcherId = params['watcherId'].asNum.toInt();
    final fileWatch = _fileWatches.remove(watcherId);
    await fileWatch?.close();
    return <String, Object?>{};
  }

  Object? _connectSandbox(Parameters params) async {
    final port = params.portAsMessagePort;
    final sandboxId = _worker._nextSandboxId++;
    final sandbox = _sandboxes[sandboxId] = await Sandbox.create(
      port: port,
      resourceProvider: _rp,
      config: _worker._config,
      version: _worker._version,
      onClosed: () => _sandboxes.remove(sandboxId),
    );
    sandbox.onConsole.listen((e) {
      _session._rpc.sendNotification('workspace/sandbox/console', {
        'workspaceId': _workspaceId,
        'sandboxId': sandboxId,
        'level': e.level,
        'message': e.message,
      });
    });
    return {
      'sandboxId': sandboxId,
      'modes': _worker._config.modes.map((m) => m.mode).toList(),
    };
  }

  Sandbox _getSandbox(Parameters params) {
    final id = params['sandboxId'].asNum.toInt();
    final s = _sandboxes[id];
    if (s == null) {
      throw SandboxNotFoundException(
        'Sandbox not found',
        data: {'sandboxId': id},
      );
    }
    return s;
  }

  Object? _sandboxRun(Parameters params) async {
    final s = _getSandbox(params);
    final path = _resolvePath(params['path'].asString);
    final mode = params['mode'].asString;
    final m = _worker._config.modes.where((m) => m.mode == mode).firstOrNull;
    if (m == null) {
      throw RpcException.invalidParams('Unsupported mode: "$mode"');
    }

    final result = await s.run(path, m);
    return {'log': result.log};
  }

  Object? _sandboxHotRestart(Parameters params) async {
    final s = _getSandbox(params);
    final result = await s.hotRestart();
    return {'log': result.log};
  }

  Object? _sandboxHotReload(Parameters params) async {
    final s = _getSandbox(params);
    final result = await s.hotReload();
    return {'log': result.log};
  }

  Object? _sandboxClose(Parameters params) async {
    final id = params['sandboxId'].asNum.toInt();
    final s = _sandboxes.remove(id);
    await s?.close();
    return <String, Object?>{};
  }

  Object? _sandboxConnectServiceProtocol(Parameters params) {
    final s = _getSandbox(params);
    final port = params.portAsMessagePort;
    s.connectServiceProtocol(port);
    return <String, Object?>{};
  }

  Future<void> _closeWorkspace() async {
    try {
      await Future.wait([
        ..._languageServers.values.map((ls) => ls.close()),
        ..._fileWatches.values.map((fw) => fw.close()),
        ..._sandboxes.values.map((s) => s.close()),
      ]);
    } finally {
      final folder = _rp.getFolder(_workspaceFolder);
      // Safe to check before delete: synchronous on an in-memory filesystem.
      if (folder.exists) {
        folder.delete();
      }
    }
  }
}
