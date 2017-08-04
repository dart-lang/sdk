// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.memory_file_system;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'file_system.dart';

/// Concrete implementation of [FileSystem] which performs its operations on an
/// in-memory virtual file system.
///
/// Not intended to be implemented or extended by clients.
class MemoryFileSystem implements FileSystem {
  final Map<Uri, Uint8List> _files = {};
  final Set<Uri> _directories = new Set<Uri>();

  /// The "current directory" in the in-memory virtual file system.
  ///
  /// This is used to convert relative URIs to absolute URIs.
  ///
  /// Always ends in a trailing '/'.
  Uri currentDirectory;

  MemoryFileSystem(Uri currentDirectory)
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

  /// Create a directory for this file system entry.
  ///
  /// If the entry already exists, either as a file, or as a directory,
  /// this is an error.
  void createDirectory() {
    if (_fileSystem._files[uri] != null) {
      throw new FileSystemException(uri, 'Entry $uri is a file.');
    }
    if (_fileSystem._directories.contains(uri)) {
      throw new FileSystemException(uri, 'Directory $uri already exists.');
    }
    _fileSystem._directories.add(uri);
  }

  @override
  Future<bool> exists() async {
    return _fileSystem._files[uri] != null ||
        _fileSystem._directories.contains(uri);
  }

  @override
  Future<List<int>> readAsBytes() async {
    List<int> contents = _fileSystem._files[uri];
    if (contents == null) {
      throw new FileSystemException(uri, 'File $uri does not exist.');
    }
    return contents.toList();
  }

  @override
  Future<String> readAsString() async {
    List<int> bytes = await readAsBytes();
    try {
      return UTF8.decode(bytes);
    } on FormatException catch (e) {
      throw new FileSystemException(uri, e.message);
    }
  }

  /// Writes the given raw bytes to this file system entity.
  ///
  /// If no file exists, one is created.  If a file exists already, it is
  /// overwritten.
  void writeAsBytesSync(List<int> bytes) {
    _update(uri, new Uint8List.fromList(bytes));
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
    _update(uri, UTF8.encode(s) as Uint8List);
  }

  void _update(Uri uri, Uint8List data) {
    if (_fileSystem._directories.contains(uri)) {
      throw new FileSystemException(uri, 'Entry $uri is a directory.');
    }
    _fileSystem._files[uri] = data;
  }
}
