// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.memory_file_system;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'file_system.dart';

/// Concrete implementation of [FileSystem] which performs its operations on an
/// in-memory virtual file system.
///
/// Not intended to be implemented or extended by clients.
class MemoryFileSystem implements FileSystem {
  @override
  final p.Context context;

  final Map<Uri, Uint8List> _files = {};

  /// The "current directory" in the in-memory virtual file system.
  ///
  /// This is used to convert relative URIs to absolute URIs.
  ///
  /// Always ends in a trailing '/'.
  Uri currentDirectory;

  MemoryFileSystem(this.context, Uri currentDirectory)
      : currentDirectory = _addTrailingSlash(currentDirectory);

  @override
  MemoryFileSystemEntity entityForUri(Uri uri) {
    return new MemoryFileSystemEntity._(
        this, currentDirectory.resolveUri(uri).normalizePath());
  }

  static Uri _addTrailingSlash(Uri uri) {
    if (!uri.path.endsWith('/')) {
      uri = uri.replace(path: uri.path + '/');
    }
    return uri;
  }
}

/// Concrete implementation of [FileSystemEntity] for use by
/// [MemoryFileSystem].
class MemoryFileSystemEntity implements FileSystemEntity {
  final MemoryFileSystem _fileSystem;

  @override
  final Uri uri;

  MemoryFileSystemEntity._(this._fileSystem, this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is MemoryFileSystemEntity &&
      other.uri == uri &&
      identical(other._fileSystem, _fileSystem);

  @override
  Future<List<int>> readAsBytes() async {
    List<int> contents = _fileSystem._files[uri];
    if (contents != null) {
      return contents.toList();
    }
    throw new Exception('File does not exist');
  }

  @override
  Future<String> readAsString() async {
    List<int> contents = await readAsBytes();
    return UTF8.decode(contents);
  }

  /// Writes the given raw bytes to this file system entity.
  ///
  /// If no file exists, one is created.  If a file exists already, it is
  /// overwritten.
  void writeAsBytesSync(List<int> bytes) {
    _fileSystem._files[uri] = new Uint8List.fromList(bytes);
  }

  /// Writes the given string to this file system entity.
  ///
  /// The string is encoded as UTF-8.
  ///
  /// If no file exists, one is created.  If a file exists already, it is
  /// overwritten.
  void writeAsStringSync(String s) {
    // Note: the return type of UTF8.encode is List<int>, but in practice it
    // always returns Uint8List.  We rely on that for efficiency, so that we
    // don't have to make an extra copy.
    _fileSystem._files[uri] = UTF8.encode(s) as Uint8List;
  }
}
