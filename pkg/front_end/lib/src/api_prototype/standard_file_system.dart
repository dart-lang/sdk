// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.standard_file_system;

import 'dart:async';
import 'dart:io' as io;

import 'file_system.dart';

/// Concrete implementation of [FileSystem] which performs its operations using
/// I/O.
///
/// Not intended to be implemented or extended by clients.
class StandardFileSystem implements FileSystem {
  static final StandardFileSystem instance = new StandardFileSystem._();

  StandardFileSystem._();

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme != 'file' && uri.scheme != '') {
      throw new FileSystemException(
          uri, 'StandardFileSystem only supports file:* URIs');
    }
    return new _StandardFileSystemEntity(Uri.base.resolveUri(uri));
  }
}

/// Concrete implementation of [FileSystemEntity] for use by
/// [StandardFileSystem].
class _StandardFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;

  _StandardFileSystemEntity(this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _StandardFileSystemEntity && other.uri == uri;

  @override
  Future<bool> exists() async {
    if (await io.FileSystemEntity.isFile(uri.toFilePath())) {
      return new io.File.fromUri(uri).exists();
    } else {
      return new io.Directory.fromUri(uri).exists();
    }
  }

  @override
  Future<List<int>> readAsBytes() async {
    try {
      return await new io.File.fromUri(uri).readAsBytes();
    } on io.FileSystemException catch (exception) {
      throw _toFileSystemException(exception);
    }
  }

  @override
  Future<String> readAsString() async {
    try {
      return await new io.File.fromUri(uri).readAsString();
    } on io.FileSystemException catch (exception) {
      throw _toFileSystemException(exception);
    }
  }

  /**
   * Return the [FileSystemException] for the given I/O exception.
   */
  FileSystemException _toFileSystemException(io.FileSystemException exception) {
    String message = exception.message;
    String osMessage = exception.osError?.message;
    if (osMessage != null && osMessage.isNotEmpty) {
      message = osMessage;
    }
    return new FileSystemException(uri, message);
  }
}
