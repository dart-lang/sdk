// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:async/async.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as p;
import 'package:stream_channel/stream_channel.dart';

import 'resource_provider/resource_provider_ext.dart';
import 'resource_provider/resource_provider_wrap_cwd.dart';
import 'shared.dart' hide FileSystemException;
import 'tools/file_watch.dart';
import 'tools/hot_reload_compiler.dart' show HotReloadCompiler;
import 'tools/language_server.dart';
import 'tools/pub.dart';

final class Worker {
  final _rp = MemoryResourceProvider(context: p.posix);
  var _config = DartPadConfig();
  int _nextLanguageServerId = 1;
  int _nextHotReloadCompilerId = 1;
  int _nextWorkspaceId = 1;
  int _nextWatcherId = 1;

  Worker._();

  static Future<Worker> create(
    Stream<List<int>> sdkTarStream, {
    String? pubHostedUrl,
  }) async {
    final w = Worker._();

    await w._rp.getFolder('/').extractTarStream(sdkTarStream);

    final configFile = w._rp.getFile(DartPadConfig.defaultDartPadConfigPath);
    if (configFile.exists) {
      try {
        w._config = DartPadConfig.fromJson(
          jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>,
        );
      } catch (e) {
        // TODO(jonasfj): Find a better way to propogate this error.
        //                This is only relevant for people making their own
        //                sdk.tar files. But it'd also make general debugging
        //                easier. To report it better we might also want to
        //                report progress updates while loading.
        print('Error reading dartpad-config.json: $e');
      }
    }
    w._config = w._config.copyWith(pubHostedUrl: pubHostedUrl);
    return w;
  }

  void connect(StreamChannel<String> channel) {
    _Session(channel, this);
  }
}

class _Session {
  final Worker _worker;
  late final Peer _rpc;
  final _workspaces = <int, _Workspace>{};

  _Session(StreamChannel<String> channel, this._worker) {
    _rpc = Peer(channel, onUnhandledError: _onUnhandledError);
    _rpc.registerMethod('createWorkspace', _createWorkspace);
    _rpc.registerMethod('workspace/dispose', _disposeWorkspace);
    _rpc.registerMethod(
      'workspace/writeFileFromText',
      _forwardToWorkspace((ws) => ws._writeFileFromText),
    );
    _rpc.registerMethod(
      'workspace/writeFileFromBytes',
      _forwardToWorkspace((ws) => ws._writeFileFromBytes),
    );
    _rpc.registerMethod(
      'workspace/readFileAsText',
      _forwardToWorkspace((ws) => ws._readFileAsText),
    );
    _rpc.registerMethod(
      'workspace/readFileAsBytes',
      _forwardToWorkspace((ws) => ws._readFileAsBytes),
    );
    _rpc.registerMethod(
      'workspace/deleteFileSystemEntity',
      _forwardToWorkspace((ws) => ws._deleteFileSystemEntity),
    );
    _rpc.registerMethod(
      'workspace/stat',
      _forwardToWorkspace((ws) => ws._stat),
    );
    _rpc.registerMethod(
      'workspace/listDirectory',
      _forwardToWorkspace((ws) => ws._listDirectory),
    );
    _rpc.registerMethod(
      'workspace/importTarArchive',
      _forwardToWorkspace((ws) => ws._importTarArchive),
    );
    _rpc.registerMethod(
      'workspace/exportTarArchive',
      _forwardToWorkspace((ws) => ws._exportTarArchive),
    );
    _rpc.registerMethod(
      'workspace/createFolder',
      _forwardToWorkspace((ws) => ws._createFolder),
    );
    _rpc.registerMethod('workspace/pub', _forwardToWorkspace((ws) => ws._pub));
    _rpc.registerMethod(
      'workspace/startHotReloadCompiler',
      _forwardToWorkspace((ws) => ws._startHotReloadCompiler),
    );
    _rpc.registerMethod(
      'workspace/hotReloadCompiler/compile',
      _forwardToWorkspace((ws) => ws._hotReloadCompilerCompile),
    );
    _rpc.registerMethod(
      'workspace/hotReloadCompiler/close',
      _forwardToWorkspace((ws) => ws._hotReloadCompilerClose),
    );
    _rpc.registerMethod(
      'workspace/startLanguageServer',
      _forwardToWorkspace((ws) => ws._startLanguageServer),
    );
    _rpc.registerMethod(
      'workspace/languageServer/message',
      _forwardToWorkspace((ws) => ws._languageServerMessage),
    );
    _rpc.registerMethod(
      'workspace/languageServer/stop',
      _forwardToWorkspace((ws) => ws._stopLanguageServer),
    );
    _rpc.registerMethod(
      'workspace/startWatcher',
      _forwardToWorkspace((ws) => ws._watch),
    );
    _rpc.registerMethod(
      'workspace/watcher/stop',
      _forwardToWorkspace((ws) => ws._unwatch),
    );
    unawaited(() async {
      await _rpc.listen();
      // Delete all workspaces to cleanup resources
      await Future.wait(
        _workspaces.values.toList().map((ws) => ws._deleteWorkspace()),
      );
    }());
  }

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
    return {
      'workspaceId': workspaceId,
      'workspaceFolder': Uri.directory(workspaceFolder).toString(),
    };
  }

  Object? _disposeWorkspace(Parameters params) async {
    final workspace = _workspaces.remove(params['workspaceId'].asNum.toInt());
    if (workspace != null) {
      await workspace._deleteWorkspace();
    }
    // Deleting a workspace that doesn't exist is a no-op
    // This ensures that deletion is an idempotent operation!
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
  final _hotReloadCompilers = <int, HotReloadCompiler>{};
  final _fileWatches = <int, FileWatch>{};

  _Workspace(
    this._worker,
    this._session,
    this._workspaceId,
    this._workspaceFolder,
    this._rp,
  );

  String _resolvePath(Uri u) {
    final path = _rp.pathContext.fromUri(u);
    if (_rp.pathContext.isAbsolute(path)) {
      return _rp.pathContext.normalize(path);
    }
    return _rp.pathContext.normalize(
      _rp.pathContext.join(_workspaceFolder, path),
    );
  }

  Object? _writeFileFromText(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final text = params['text'].asString;
    try {
      final file = _rp.getFile(path);
      file.parent.createRecursively();
      file.writeAsStringSync(text);
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
    return <String, Object?>{};
  }

  Object? _writeFileFromBytes(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final bytes = base64.decode(params['base64'].asString);
    try {
      final file = _rp.getFile(path);
      file.parent.createRecursively();
      file.writeAsBytesSync(bytes);
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
    return <String, Object?>{};
  }

  Object? _readFileAsText(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    try {
      return {'text': _rp.getFile(path).readAsStringSync()};
    } on FileSystemException catch (e) {
      throw FileNotFoundException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
  }

  Object? _readFileAsBytes(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    try {
      return {'base64': base64.encode(_rp.getFile(path).readAsBytesSync())};
    } on FileSystemException catch (e) {
      throw FileNotFoundException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
  }

  Object? _deleteFileSystemEntity(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    try {
      _rp.getResource(path).delete();
    } on FileSystemException catch (e) {
      throw FileDeletionFailedException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
    return <String, Object?>{};
  }

  Object? _stat(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final resource = _rp.getResource(path);
    if (!resource.exists) {
      throw FileNotFoundException(
        'File or directory not found',
        data: {'resolvedUri': Uri.file(path).toString()},
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
    final path = _resolvePath(params['uri'].asUri);
    try {
      _rp.getFolder(path).createRecursively();
    } on FileSystemException catch (e) {
      throw FileWriteConflictException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
    return <String, Object?>{};
  }

  Object? _listDirectory(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
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
      throw FileNotFoundException(
        e.message,
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }
  }

  Object? _importTarArchive(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final bytes = base64.decode(params['base64'].asString);

    await _rp.getFolder(path).extractTarStream(Stream.value(bytes));

    return <String, Object?>{};
  }

  Object? _exportTarArchive(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final folder = _rp.getFolder(path);
    if (!folder.exists) {
      throw FileNotFoundException(
        'Directory not found',
        data: {'resolvedUri': Uri.file(path).toString()},
      );
    }

    return {
      'base64': base64.encode(await collectBytes(folder.createTarStream())),
    };
  }

  String _findPackageConfigFromEntrypoint(String entrypoint) {
    var parent = _rp.getFile(entrypoint).parent;
    do {
      final pkgConfig = parent
          .getFolder('.dart_tool')
          .getFile('package_config.json');

      if (pkgConfig.exists) {
        return pkgConfig.path;
      }

      parent = parent.parent;
    } while (!parent.isRoot);
    throw PackageConfigNotFoundException(
      'Unable to find `.dart_tool/package_config.json` in any '
      'parent directory of `$entrypoint`.',
      data: {'entrypoint': entrypoint},
    );
  }

  Object? _pub(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
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
    );

    return {'log': log};
  }

  Object? _startHotReloadCompiler(Parameters params) async {
    var entrypoint = _resolvePath(params['uri'].asUri);

    // Test if the file we're compiling exists.
    // Otherwise, we get really ugly errors if there is a bootstrap file in play
    if (!_rp.getFile(entrypoint).exists) {
      throw CompilationFailedException(
        'Compilation entrypoint "$entrypoint" not found',
        data: {'entrypoint': entrypoint},
      );
    }

    var rp = _rp;
    final bootstrapCodeTemplate = _worker._config.bootstrapCode;
    if (bootstrapCodeTemplate != null) {
      final originalEntrypoint = entrypoint;
      entrypoint = '$originalEntrypoint.virtual-bootstrap-wrapper.dart';

      final overlay = rp = OverlayResourceProvider(_rp);
      overlay.setOverlay(
        entrypoint,
        content: bootstrapCodeTemplate.replaceAll(
          '{{entrypoint}}',
          originalEntrypoint,
        ),
        modificationStamp: 0,
      );
    }

    final id = _worker._nextHotReloadCompilerId++;
    _hotReloadCompilers[id] = HotReloadCompiler(
      resourceProvider: rp,
      packageConfig: _findPackageConfigFromEntrypoint(entrypoint),
      targetPath: entrypoint,
      config: _worker._config,
    );
    return {'hotReloadCompilerId': id};
  }

  HotReloadCompiler _getHotReloadCompiler(Parameters params) {
    final id = params['hotReloadCompilerId'].asNum.toInt();
    final c = _hotReloadCompilers[id];
    if (c == null) {
      throw HotReloadCompilerNotFoundException(
        'HotReloadCompiler not found, check the "hotReloadCompilerId"',
        data: {'workspaceId': _workspaceId, 'hotReloadCompilerId': id},
      );
    }
    return c;
  }

  Object? _hotReloadCompilerCompile(Parameters params) async {
    final c = _getHotReloadCompiler(params);
    final (:code, :compiledLibraryUris, :log) = await c.compile();
    return {
      'code': code,
      'compiledLibraryUris': compiledLibraryUris,
      'log': log,
    };
  }

  Object? _hotReloadCompilerClose(Parameters params) async {
    final id = params['hotReloadCompilerId'].asNum.toInt();
    final c = _getHotReloadCompiler(params);
    _hotReloadCompilers.remove(id);
    await c.close();
    return <String, Object?>{};
  }

  Object? _startLanguageServer(Parameters params) async {
    final languageServerId = _worker._nextLanguageServerId++;
    final ls = _languageServers[languageServerId] = LanguageServer(
      resourceProvider: _rp,
      config: _worker._config,
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
    await languageServer.handle(
      params['message'].asMap as Map<String, Object?>,
    );
    return <String, Object?>{};
  }

  Object? _stopLanguageServer(Parameters params) async {
    final languageServerId = params['languageServerId'].asNum.toInt();
    final languageServer = _languageServers.remove(languageServerId);
    await languageServer?.close();
    return <String, Object?>{};
  }

  Object? _watch(Parameters params) async {
    final path = _resolvePath(params['uri'].asUri);
    final watcherId = _worker._nextWatcherId++;

    _fileWatches[watcherId] = await FileWatch.create(_rp, path, (events) {
      _session._rpc.sendNotification('workspace/watcher/events', {
        'workspaceId': _workspaceId,
        'watcherId': watcherId,
        'events': events
            .map((e) => {'type': e.event, 'uri': e.uri.toString()})
            .toList(),
      });
    });

    return {'watcherId': watcherId};
  }

  Object? _unwatch(Parameters params) async {
    final watcherId = params['watcherId'].asNum.toInt();
    final fileWatch = _fileWatches.remove(watcherId);
    await fileWatch?.stop();
    return <String, Object?>{};
  }

  Future<void> _deleteWorkspace() async {
    try {
      await Future.wait([
        ..._languageServers.values.map((ls) => ls.close()),
        ..._hotReloadCompilers.values.map((cs) => cs.close()),
        ..._fileWatches.values.map((fw) => fw.stop()),
      ]);
    } finally {
      _rp.getFolder(_workspaceFolder).delete();
    }
  }
}
