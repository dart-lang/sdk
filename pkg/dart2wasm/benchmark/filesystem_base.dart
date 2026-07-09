// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity;

final _fakeSdkRoot = '/FakeSdkRoot';

abstract class WasmCompilerFileSystemBase implements FileSystem {
  final String sdkRoot = _fakeSdkRoot;

  @override
  FileSystemEntity entityForUri(Uri uri) =>
      WasmCompilerFileSystemEntity(this, uri);

  Future<String?> _tryReadString(Uri uri) async {
    final bytes = await _tryReadBytes(uri);
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }

  Future<Uint8List?> _tryReadBytes(Uri uri) async {
    String relativePath;
    final path = uri.path;
    if (path.startsWith('/')) {
      assert(uri.path.startsWith(_fakeSdkRoot));
      relativePath = uri.path.substring(_fakeSdkRoot.length + 1);
    } else {
      relativePath = path;
    }

    return tryReadBytesSync(relativePath);
  }

  void writeStringSync(String filename, String value) {
    writeBytesSync(filename, utf8.encode(value));
  }

  // Overriden by subclasses.
  Uint8List? tryReadBytesSync(String relativePath);

  // Overriden by subclasses.
  void writeBytesSync(String filename, Uint8List bytes);
}

class WasmCompilerFileSystemEntity implements FileSystemEntity {
  final WasmCompilerFileSystemBase _fileSystem;

  @override
  final Uri uri;

  WasmCompilerFileSystemEntity(this._fileSystem, this.uri);

  @override
  int get hashCode => Object.hash(_fileSystem, uri);

  @override
  bool operator ==(Object other) =>
      other is WasmCompilerFileSystemEntity &&
      other._fileSystem == _fileSystem &&
      other.uri == uri;

  @override
  Future<bool> exists() async {
    // CFE uses it to detect whether a directory exists.
    // We claim it does (because we cannot use JS APIs to detect existence of
    // directory).
    if (uri.path.endsWith('/')) return true;
    return (await _fileSystem._tryReadBytes(uri)) != null;
  }

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<Uint8List> readAsBytes() async {
    final result = await _fileSystem._tryReadBytes(uri);
    if (result != null) return result;
    throw FileSystemException('Failed to read $uri');
  }

  @override
  Future<Uint8List> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async {
    final result = await _fileSystem._tryReadString(uri);
    if (result != null) return result;
    throw FileSystemException('Failed to read $uri');
  }
}
