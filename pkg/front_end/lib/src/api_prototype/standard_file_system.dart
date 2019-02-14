// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.standard_file_system;

import 'dart:async';
import 'dart:io' as io;

import 'file_system.dart';

import '../fasta/compiler_context.dart' show CompilerContext;

/// Concrete implementation of [FileSystem] handling standard URI schemes.
///
/// file: URIs are handled using file I/O.
/// data: URIs return their data contents.
///
/// Not intended to be implemented or extended by clients.
class StandardFileSystem implements FileSystem {
  static final StandardFileSystem instance = new StandardFileSystem._();

  StandardFileSystem._();

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == 'file' || uri.scheme == '') {
      // TODO(askesc): Empty schemes should have been handled elsewhere.
      return new _IoFileSystemEntity(Uri.base.resolveUri(uri));
    } else if (uri.scheme == 'data') {
      return new DataFileSystemEntity(Uri.base.resolveUri(uri));
    } else {
      throw new FileSystemException(
          uri, 'StandardFileSystem only supports file:* and data:* URIs');
    }
  }
}

/// Concrete implementation of [FileSystemEntity] for file: URIs.
class _IoFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;

  _IoFileSystemEntity(this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _IoFileSystemEntity && other.uri == uri;

  @override
  Future<bool> exists() async {
    if (await io.FileSystemEntity.isDirectory(uri.toFilePath())) {
      return true;
    } else {
      return new io.File.fromUri(uri).exists();
    }
  }

  @override
  Future<List<int>> readAsBytes() async {
    try {
      CompilerContext.recordDependency(uri);
      return new io.File.fromUri(uri).readAsBytesSync();
    } on io.FileSystemException catch (exception) {
      throw _toFileSystemException(exception);
    }
  }

  @override
  Future<String> readAsString() async {
    try {
      CompilerContext.recordDependency(uri);
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

/// Concrete implementation of [FileSystemEntity] for data: URIs.
class DataFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;

  DataFileSystemEntity(this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DataFileSystemEntity && other.uri == uri;

  @override
  Future<bool> exists() async {
    return true;
  }

  @override
  Future<List<int>> readAsBytes() async {
    return uri.data.contentAsBytes();
  }

  @override
  Future<String> readAsString() async {
    return uri.data.contentAsString();
  }
}
