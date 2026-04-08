// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:file/local.dart';

/// An outstanding write request managed by [_WriteLimiter].
class _PendingWrite {
  _PendingWrite({
    required this._localFs,
    required this.uri,
    required this.bytes,
  });
  final completer = Completer<void>();

  final LocalFileSystem _localFs;
  final Uri uri;
  final Stream<List<int>> bytes;

  Future<void> write() async {
    final file = _localFs.file(uri);
    final parentDir = file.parent;
    await parentDir.create(recursive: true);
    if (await file.exists()) {
      await file.delete();
    }
    final sink = file.openWrite();
    await sink.addStream(bytes);
    await sink.close();
    completer.complete();
    _WriteLimiter._writeCompleted();
  }
}

/// A utility class to schedule and limit the number of concurrent file system
/// writes as non-rooted Android devices have a very low limit for the number
/// of open files.
abstract class _WriteLimiter {
  static final pendingWrites = <_PendingWrite>[];

  // Artificially cap ourselves to 16.
  static const _kMaxOpenWrites = 16;
  static int _openWrites = 0;

  static Future<void> scheduleWrite({
    required LocalFileSystem localFs,
    required Uri uri,
    required List<int> bytes,
  }) => scheduleWriteStream(
    localFs: localFs,
    uri: uri,
    bytes: Stream.fromIterable([bytes]),
  );

  static Future<void> scheduleWriteStream({
    required LocalFileSystem localFs,
    required Uri uri,
    required Stream<List<int>> bytes,
  }) {
    // Create a new pending write.
    final pw = _PendingWrite(localFs: localFs, uri: uri, bytes: bytes);
    pendingWrites.add(pw);
    _maybeWriteFiles();
    return pw.completer.future;
  }

  static void _maybeWriteFiles() {
    while (_openWrites < _kMaxOpenWrites) {
      if (pendingWrites.isEmpty) {
        break;
      }
      final pw = pendingWrites.removeLast();
      pw.write();
      _openWrites++;
    }
  }

  static void _writeCompleted() {
    _openWrites--;
    assert(_openWrites >= 0);
    _maybeWriteFiles();
  }
}

/// A [DevelopmentFileSystem] rooted at [rootUri], providing restricted file
/// system access to clients.
final class VMDevelopmentFileSystem extends DevelopmentFileSystem {
  VMDevelopmentFileSystem({
    required this._localFs,
    required super.name,
    required super.rootUri,
  });

  final LocalFileSystem _localFs;

  /// Reads the contents of the file at [uri].
  ///
  /// If the file does not exist, a [RpcException.fileDoesNotExist] exception
  /// is thrown.
  @override
  Future<RpcResponse> readFile({required String uri}) async {
    try {
      final bytes = await _localFs
          .file(resolve(method: '_readDevFSFile', uri: uri))
          .readAsBytes();
      // TODO(bkonyi): create package:vm_service type if we make this public.
      return {'type': 'FSFile', 'fileContents': base64.encode(bytes)};
    } on PathNotFoundException catch (e) {
      RpcException.fileDoesNotExist.throwExceptionWithDetails(
        details: '_readDevFSFile: $e',
      );
    }
  }

  /// Writes [bytes] to [uri].
  @override
  Future<void> writeFile({
    required String uri,
    required List<int> bytes,
  }) async {
    await _WriteLimiter.scheduleWrite(
      localFs: _localFs,
      uri: resolve(method: '_writeDevFSFile', uri: uri),
      bytes: bytes,
    );
  }

  /// Writes a stream of [bytes] to [uri].
  @override
  Future<void> writeStreamFile({
    required String uri,
    required Stream<List<int>> bytes,
  }) async {
    await _WriteLimiter.scheduleWriteStream(
      localFs: _localFs,
      uri: resolve(method: '_writeDevFSFile', uri: uri),
      bytes: bytes,
    );
  }

  /// Lists all files contained in the [DevelopmentFileSystem].
  ///
  /// Each file is reported with its size in bytes and last modified timestamp
  /// in milliseconds since epoch.
  @override
  Future<RpcResponse> listFiles() async {
    final dir = _localFs.directory(rootUri);
    final dirPathStr = dir.path;
    final stream = dir.list(recursive: true);
    final files = <Map<String, Object?>>[];
    await for (final fileEntity in stream) {
      final filePath = Uri.file(fileEntity.path).path;
      final stat = await fileEntity.stat();
      if (stat.type == FileSystemEntityType.file &&
          filePath.startsWith(dirPathStr)) {
        files.add(<String, Object?>{
          // Remove any url-encoding in the filenames.
          'name': Uri.decodeFull('/${filePath.substring(dirPathStr.length)}'),
          'size': stat.size,
          'modified': stat.modified.millisecondsSinceEpoch,
        });
      }
    }
    // TODO(bkonyi): create package:vm_service type if we make this public.
    return <String, Object?>{'type': 'FSFileList', 'files': files};
  }
}

/// A collection of [DevelopmentFileSystem]s.
final class VMDevelopmentFileSystemCollection
    extends DevelopmentFileSystemCollection {
  /// Creates a [DevFS] instance with a [VMDevelopmentFileSystemCollection]
  /// backend.
  static DevFS<VMDevelopmentFileSystemCollection> createDevFS() =>
      DevFS(fileSystems: VMDevelopmentFileSystemCollection());

  final _fsMap = <String, VMDevelopmentFileSystem>{};
  final _localFs = const LocalFileSystem();

  @override
  List<String> get fsNames => _fsMap.keys.toList();

  /// Destroys all [DevelopmentFileSystem]s in the collection.
  @override
  Future<void> cleanup() async {
    await Future.wait(<Future<void>>[
      for (final fs in _fsMap.values)
        _localFs.directory(fs.rootUri).delete(recursive: true),
    ]);
    _fsMap.clear();
  }

  /// Creates a new [DevelopmentFileSystem] named [name].
  ///
  /// Throws a [RpcException.fileSystemAlreadyExists] if the file system has
  /// already been created.
  @override
  Future<DevelopmentFileSystem> createFileSystem({required String name}) async {
    if (_fsMap.containsKey(name)) {
      RpcException.fileSystemAlreadyExists.throwExceptionWithDetails(
        details: "_createDevFS: file system '$name' already exists",
      );
    }
    final temp = await _localFs.systemTempDirectory.createTemp(name);
    final uri = (await temp.childDirectory(name).create()).uri;
    return _fsMap[name] = VMDevelopmentFileSystem(
      localFs: _localFs,
      name: name,
      rootUri: uri,
    );
  }

  /// Destroys the [DevelopmentFileSystem] with name [name].
  ///
  /// Throws a [RpcException.fileSystemDoesNotExist] if the file system does
  /// not exist.
  @override
  Future<void> deleteFileSystem({required String name}) async {
    final fs = _fsMap.remove(name);
    if (fs == null) {
      RpcException.fileSystemDoesNotExist.throwExceptionWithDetails(
        details: "_deleteDevFS: file system '$name' does not exist",
      );
    }
    await _localFs.directory(fs.rootUri).delete(recursive: true);
  }

  /// Retrieves an existing [DevelopmentFileSystem] based on a JSON-RPC
  /// request.
  ///
  /// Throws a [RpcException.fileSystemDoesNotExist] if the file system does
  /// not exist.
  @override
  DevelopmentFileSystem getFileSystem({required String name}) {
    final fs = _fsMap[name];
    if (fs == null) {
      RpcException.fileSystemDoesNotExist.throwException();
    }
    return fs;
  }
}
