// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.physical_file_system;

import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as p;

import 'file_system.dart';

/// Concrete implementation of [FileSystem] which performs its operations using
/// I/O.
///
/// Not intended to be implemented or extended by clients.
class PhysicalFileSystem implements FileSystem {
  static final PhysicalFileSystem instance = new PhysicalFileSystem._();

  PhysicalFileSystem._();

  @override
  p.Context get context => p.context;

  @override
  FileSystemEntity entityForPath(String path) =>
      new _PhysicalFileSystemEntity(context.normalize(context.absolute(path)));

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme != 'file') throw new ArgumentError('File URI expected');
    // Note: we don't have to verify that the URI's path is absolute, because
    // URIs with non-empty schemes always have absolute paths.
    return entityForPath(context.fromUri(uri));
  }
}

/// Concrete implementation of [FileSystemEntity] for use by
/// [PhysicalFileSystem].
class _PhysicalFileSystemEntity implements FileSystemEntity {
  @override
  final String path;

  _PhysicalFileSystemEntity(this.path);

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _PhysicalFileSystemEntity && other.path == path;

  @override
  Future<List<int>> readAsBytes() => new io.File(path).readAsBytes();

  @override
  Future<String> readAsString() => new io.File(path).readAsString();
}
