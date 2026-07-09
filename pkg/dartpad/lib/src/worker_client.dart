// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/stream_channel.dart';

import 'exceptions.dart' show rethrowAsDartPadException;
import 'shared.dart';

export 'exceptions.dart' hide rethrowAsDartPadException;

/// Client for talking to `shared_worker.dart`.
base class WorkerClient {
  final rpc.Peer _peer;
  final _languageServers = <int, LanguageServer>{};
  final _hotReloadCompilers = <int, HotReloadCompiler>{};
  final _watchers = <int, Sink<FileChangeEvent>>{};

  /// Creates a client that communicates over [channel].
  ///
  /// The [channel] usually connects to a `Worker` instance (in tests) or a
  /// `MessagePort` (in the browser).
  WorkerClient(StreamChannel<String> channel) : _peer = rpc.Peer(channel) {
    _peer.registerMethod('workspace/languageServer/message', _handleLsMessage);
    _peer.registerMethod('workspace/languageServer/exited', _handleLsExited);
    _peer.registerMethod('workspace/watcher/events', _handleWatchEvent);
    _peer.listen();
  }

  Future<void> get done => _peer.done;

  /// Closes the connection to the worker.
  Future<void> dispose() async {
    await _peer.close();
  }

  /// Creates a workspace in the worker.
  ///
  /// A [Workspace] is allocated a unique folder [Workspace.workspaceFolder].
  /// Disposing of a workspace using [Workspace.dispose] deletes the
  /// _workspace folder_ and any [LanguageServer] and [HotReloadCompiler]
  /// started within said workspace.
  ///
  /// Workspaces are not isolated, and file operations may interfere with other
  /// _workspace folders_. This may change in the future.
  Future<Workspace> createWorkspace() async {
    final result = await _peer.request<Map>('createWorkspace', {});
    return Workspace._(
      this,
      (result['workspaceId'] as num).toInt(),
      Uri.parse(result['workspaceFolder'] as String),
    );
  }

  void _handleLsMessage(rpc.Parameters params) {
    final id = (params['languageServerId'].value as num).toInt();
    final message = params['message'].asMap;
    _languageServers[id]?._incomingMessages.add(message);
  }

  void _handleLsExited(rpc.Parameters params) {
    final id = (params['languageServerId'].value as num).toInt();
    _languageServers[id]?._handleExited();
  }

  void _handleWatchEvent(rpc.Parameters params) {
    final watcherId = (params['watcherId'].value as num).toInt();
    final events = params['events'].asList;
    final controller = _watchers[watcherId];
    if (controller != null) {
      for (final e in events) {
        final map = e as Map;
        final type = map['type'] as String;
        final uri = Uri.parse(map['uri'] as String);
        controller.add(switch (type) {
          'add' => FileAddedEvent(uri),
          'modify' => FileModifiedEvent(uri),
          'remove' => FileRemovedEvent(uri),
          _ => FileModifiedEvent(uri),
        });
      }
    }
  }
}

/// Representation of a _workspace_ inside the worker with methods wrapping
/// the RPC interface.
///
/// All URIs and paths passed to methods will be resolved relative to the the
/// [workspaceFolder].
final class Workspace {
  final WorkerClient _client;
  final int id;
  final Uri workspaceFolder;

  Workspace._(this._client, this.id, this.workspaceFolder);

  /// Helper to attach the workspaceId to every request.
  Future<T> _request<T>(String method, [Map<String, Object?>? params]) async {
    return await _client._peer.request<T>(method, {
      ...?params,
      'workspaceId': id,
    });
  }

  Future<void> writeFileFromText(String uri, String text) =>
      _request('workspace/writeFileFromText', {'uri': uri, 'text': text});

  Future<void> writeFileFromBytes(String uri, Uint8List bytes) => _request(
    'workspace/writeFileFromBytes',
    {'uri': uri, 'base64': base64.encode(bytes)},
  );

  Future<String> readFileAsText(String uri) async {
    final result = await _request<Map>('workspace/readFileAsText', {
      'uri': uri,
    });
    return result['text'] as String;
  }

  Future<Uint8List> readFileAsBytes(String uri) async {
    final result = await _request<Map>('workspace/readFileAsBytes', {
      'uri': uri,
    });
    return base64.decode(result['base64'] as String);
  }

  Future<void> importTarArchive(String uri, Uint8List tarArchive) => _request(
    'workspace/importTarArchive',
    {'uri': uri, 'base64': base64.encode(tarArchive)},
  );

  Future<Uint8List> exportTarArchive(String uri) async {
    final result = await _request<Map>('workspace/exportTarArchive', {
      'uri': uri,
    });
    return base64.decode(result['base64'] as String);
  }

  Future<void> deleteFileSystemEntity(String uri) =>
      _request('workspace/deleteFileSystemEntity', {'uri': uri});

  /// Get information about a file or folder in this workspace.
  Future<({String type, int? size})> stat(String uri) async {
    final result = await _request<Map>('workspace/stat', {'uri': uri});
    return (
      type: result['type'] as String,
      size: (result['size'] as num?)?.toInt(),
    );
  }

  /// Returns true if a file exists at [uri] in this workspace.
  Future<bool> fileExist(String uri) async {
    try {
      final s = await stat(uri);
      return s.type == 'file';
    } on FileNotFoundException {
      return false;
    }
  }

  /// Returns true if a folder exists at [uri] in this workspace.
  Future<bool> folderExist(String uri) async {
    try {
      final s = await stat(uri);
      return s.type == 'folder';
    } on FileNotFoundException {
      return false;
    }
  }

  Future<void> createFolder(String uri) =>
      _request('workspace/createFolder', {'uri': uri});

  Future<List<({String path, String type})>> listDirectory({
    required String uri,
    bool recursive = false,
    bool ignoreHidden = false,
  }) async {
    final result = await _request<Map>('workspace/listDirectory', {
      'uri': uri,
      'recursive': recursive,
      'ignoreHidden': ignoreHidden,
    });
    return (result['entries'] as List).map((e) {
      final map = e as Map;
      return (path: map['path'] as String, type: map['type'] as String);
    }).toList();
  }

  /// Watch a file or directory for changes.
  WorkspaceWatcher watch(String uri) =>
      WorkspaceWatcher._(this, Uri.parse(uri));

  Future<CompileResult> compile(Uri entrypoint) async {
    final c = await startHotReloadCompiler(entrypoint);
    try {
      return await c.compile();
    } finally {
      await c.close();
    }
  }

  Future<({String log})> pub({
    String uri = '',
    required String command,
    List<String> args = const <String>[],
  }) async {
    final result = await _request<Map>('workspace/pub', {
      'uri': uri,
      'command': command,
      'args': args,
    });
    return (log: result['log'] as String);
  }

  Future<HotReloadCompiler> startHotReloadCompiler(Uri uri) async {
    final result = await _request<Map>('workspace/startHotReloadCompiler', {
      'uri': uri.toString(),
    });
    final id = (result['hotReloadCompilerId'] as num).toInt();

    final c = HotReloadCompiler._(this, id);
    _client._hotReloadCompilers[id] = c;
    return c;
  }

  Future<LanguageServer> startLanguageServer() async {
    final result = await _request<Map>('workspace/startLanguageServer');
    final lsId = (result['languageServerId'] as num).toInt();

    final ls = LanguageServer._(_client, this, lsId);
    _client._languageServers[lsId] = ls;
    return ls;
  }

  Future<void> dispose() async {
    await _client._peer.request<void>('workspace/dispose', {'workspaceId': id});
  }
}

/// A client for the language server running within a workspace.
final class LanguageServer {
  final WorkerClient _client;
  final Workspace workspace;
  final int id;

  final _incomingMessages = StreamController<Object?>();
  final _outgoingMessages = StreamController<Object?>();
  late final StreamChannel<Object?> _channel;

  LanguageServer._(this._client, this.workspace, this.id) {
    _channel = StreamChannel(_incomingMessages.stream, _outgoingMessages.sink);

    // Forward outgoing LSP messages to the worker tunnel
    _outgoingMessages.stream.listen((message) {
      _client._peer.sendNotification('workspace/languageServer/message', {
        'workspaceId': workspace.id,
        'languageServerId': id,
        'message': message,
      });
    });
  }

  /// Communication channel over which standard LSP JSON-RPC 2.0 messages
  /// travel.
  ///
  /// These are not encoded as JSON Strings, but instead travels as the kind of
  /// JSON values returned by [json] codec from `dart:convert`.
  StreamChannel<Object?> get languageServerChannel => _channel;

  /// Stops the language server.
  Future<void> stop() async {
    try {
      await _client._peer.request<void>('workspace/languageServer/stop', {
        'workspaceId': workspace.id,
        'languageServerId': id,
      });
    } catch (_) {
      // Ignore if already closed
    } finally {
      _cleanup();
    }
  }

  void _handleExited() {
    _cleanup();
  }

  void _cleanup() {
    _client._languageServers.remove(id);
    _incomingMessages.close();
    _outgoingMessages.close();
  }
}

final class HotReloadCompiler {
  final Workspace workspace;
  final int id;

  HotReloadCompiler._(this.workspace, this.id);

  /// Compile the _entrypoint_ this [HotReloadCompiler] was started with.
  ///
  /// Calling compile a second time may throw [HotReloadRejectedException], if
  /// code changes are such that a hot-reload is not possible.
  Future<CompileResult> compile() async {
    final result = await workspace._request<Map>(
      'workspace/hotReloadCompiler/compile',
      {'hotReloadCompilerId': id},
    );

    return (
      code: result['code'] as String,
      compiledLibraryUris: (result['compiledLibraryUris'] as List)
          .cast<String>(),
      log: result['log'] as String,
    );
  }

  /// Release resources associated with this [HotReloadCompiler].
  Future<void> close() async {
    try {
      await workspace._request<Map>('workspace/hotReloadCompiler/close', {
        'hotReloadCompilerId': id,
      });
    } catch (_) {
      // Ignore if already closed
    } finally {
      _cleanup();
    }
  }

  void _cleanup() {
    workspace._client._hotReloadCompilers.remove(id);
  }
}

final class WorkspaceWatcher {
  final Workspace workspace;

  /// Folder or file to be watched.
  final Uri uri;

  var _watcherId = Completer<int>();
  late final StreamController<FileChangeEvent> _controller;

  WorkspaceWatcher._(this.workspace, this.uri) {
    _controller = StreamController<FileChangeEvent>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  /// Broadcast stream with [FileChangeEvent] for [uri].
  ///
  /// File changes will only be reported while this stream subscribers.
  /// When a subscription is made, events prior to [ready] being resolved may
  /// not be reported.
  ///
  /// Generally, you should subscribe to the [changes] stream, and wait for
  /// [ready] before assuming that events for file changes will arrive.
  Stream<FileChangeEvent> get changes => _controller.stream;

  /// A [Future] that completes when the watcher is initialized and reporting
  /// events in [changes].
  ///
  /// This future will not complete until a subscription to [changes] has been
  /// made. This future will change when all subscriptions to [changes] are
  /// cancelled.
  Future<void> get ready => _watcherId.future;

  /// True, if watcher is initialized and reporting events in [changes].
  bool get isReady => _watcherId.isCompleted;

  void _onListen() {
    assert(!_watcherId.isCompleted);
    _watcherId.complete(
      Future(() async {
        final result = await workspace._request<Map>('workspace/startWatcher', {
          'uri': uri.toString(),
        });
        final watcherId = (result['watcherId'] as num).toInt();
        workspace._client._watchers[watcherId] = _controller;
        return watcherId;
      }),
    );
  }

  void _onCancel() {
    _watcherId.future.then((watcherId) async {
      try {
        await workspace._request<Map>('workspace/watcher/stop', {
          'watcherId': watcherId,
        });
      } finally {
        workspace._client._watchers.remove(watcherId);
      }
    }).ignore();
    _watcherId = Completer();
  }
}

/// Represents a change to a file or directory in the workspace.
sealed class FileChangeEvent {
  /// Absolute URI of the file or folder.
  final Uri uri;
  const FileChangeEvent(this.uri);
}

/// An event fired when a file or directory is added to the workspace.
final class FileAddedEvent extends FileChangeEvent {
  const FileAddedEvent(super.uri);
}

/// An event fired when a file or directory in the workspace is modified.
final class FileModifiedEvent extends FileChangeEvent {
  const FileModifiedEvent(super.uri);
}

/// An event fired when a file or directory is removed from the workspace.
final class FileRemovedEvent extends FileChangeEvent {
  const FileRemovedEvent(super.uri);
}

extension on rpc.Peer {
  /// Wrap [sendRequest] with casting the return to [T]
  Future<T> request<T>(String method, [Object? parameters]) async {
    try {
      return await sendRequest(method, parameters) as T;
    } on rpc.RpcException catch (e) {
      rethrowAsDartPadException(e);
    }
  }
}
