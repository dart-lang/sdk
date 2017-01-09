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
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme != 'file' && uri.scheme != '') {
      throw new ArgumentError('File URI expected');
    }
    // Note: we don't have to verify that the URI's path is absolute, because
    // URIs with non-empty schemes always have absolute paths.
    var path = context.fromUri(uri);
    return new _PhysicalFileSystemEntity(
        context.normalize(context.absolute(path)));
  }
}

/// Concrete implementation of [FileSystemEntity] for use by
/// [PhysicalFileSystem].
class _PhysicalFileSystemEntity implements FileSystemEntity {
  final String _path;

  _PhysicalFileSystemEntity(this._path);

  @override
  int get hashCode => _path.hashCode;

  @override
  Uri get uri => p.toUri(_path);

  @override
  bool operator ==(Object other) =>
      other is _PhysicalFileSystemEntity && other._path == _path;

  @override
  Future<List<int>> readAsBytes() => new io.File(_path).readAsBytes();

  @override
  Future<String> readAsString() => new io.File(_path).readAsString();
}
