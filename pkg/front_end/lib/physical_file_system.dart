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
    return new _PhysicalFileSystemEntity(Uri.base.resolveUri(uri));
  }
}

/// Concrete implementation of [FileSystemEntity] for use by
/// [PhysicalFileSystem].
class _PhysicalFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;

  _PhysicalFileSystemEntity(this.uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _PhysicalFileSystemEntity && other.uri == uri;

  @override
  Future<List<int>> readAsBytes() => new io.File.fromUri(uri).readAsBytes();

  @override
  Future<String> readAsString() => new io.File.fromUri(uri).readAsString();
}
