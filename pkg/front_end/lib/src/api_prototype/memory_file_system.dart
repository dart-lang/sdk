// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.memory_file_system;

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
      : currentDirectory = _addTrailingSlash(currentDirectory) {
    _directories.add(currentDirectory);
  }

  @override
  MemoryFileSystemEntity entityForUri(Uri uri) {
    return new MemoryFileSystemEntity._(
        this, currentDirectory.resolveUri(uri).normalizePath());
  }

  String get debugString {
    StringBuffer sb = new StringBuffer();
    _files.forEach((uri, _) => sb.write("- $uri\n"));
    _directories.forEach((uri) => sb.write("- $uri\n"));
    return '$sb';
  }

  static Uri _addTrailingSlash(Uri uri) {
    if (!uri.path.endsWith('/')) {
      // Coverage-ignore-block(suite): Not run.
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

  // Coverage-ignore(suite): Not run.
  /// Create a directory for this file system entry.
  ///
  /// If the entry is an existing file, this is an error.
  void createDirectory() {
    if (_fileSystem._files[uri] != null) {
      throw new FileSystemException(uri, 'Entry $uri is a file.');
    }
    _fileSystem._directories.add(uri);
  }

  @override
  Future<bool> exists() {
    return new Future.value(_fileSystem._files[uri] != null ||
        _fileSystem._directories.contains(uri));
  }

  @override
  // Coverage-ignore(suite): Not run.
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  // Coverage-ignore(suite): Not run.
  Future<Uint8List> readAsBytes() {
    Uint8List? contents = _fileSystem._files[uri];
    if (contents == null) {
      return new Future.error(
          new FileSystemException(uri, 'File $uri does not exist.'),
          StackTrace.current);
    }
    return new Future.value(contents);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Future<Uint8List> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  // Coverage-ignore(suite): Not run.
  Future<String> readAsString() async {
    List<int> bytes = await readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException catch (e) {
      throw new FileSystemException(uri, e.message);
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Writes the given raw bytes to this file system entity.
  ///
  /// If no file exists, one is created.  If a file exists already, it is
  /// overwritten.
  void writeAsBytesSync(List<int> bytes) {
    if (bytes is Uint8List) {
      _update(uri, bytes);
    } else {
      _update(uri, new Uint8List.fromList(bytes));
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Writes the given string to this file system entity.
  ///
  /// The string is encoded as UTF-8.
  ///
  /// If no file exists, one is created.  If a file exists already, it is
  /// overwritten.
  void writeAsStringSync(String s) {
    _update(uri, utf8.encode(s));
  }

  // Coverage-ignore(suite): Not run.
  void _update(Uri uri, Uint8List data) {
    if (_fileSystem._directories.contains(uri)) {
      throw new FileSystemException(uri, 'Entry $uri is a directory.');
    }
    _fileSystem._files[uri] = data;
  }
}
