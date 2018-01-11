// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A memory + physical file system used to mock input for tests but provide
/// sdk sources from disk.
library front_end.src.hybrid_file_system;

import 'dart:async';

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';

/// A file system that mixes files from memory and a physical file system. All
/// memory entities take priotity over file system entities.
class HybridFileSystem implements FileSystem {
  final MemoryFileSystem memory;
  final StandardFileSystem physical = StandardFileSystem.instance;

  HybridFileSystem(this.memory);

  @override
  FileSystemEntity entityForUri(Uri uri) =>
      new HybridFileSystemEntity(uri, this);
}

/// Entity that delegates to an underlying memory or phisical file system
/// entity.
class HybridFileSystemEntity implements FileSystemEntity {
  final Uri uri;
  FileSystemEntity _delegate;
  final HybridFileSystem _fs;

  HybridFileSystemEntity(this.uri, this._fs);

  Future<FileSystemEntity> get delegate async {
    if (_delegate != null) return _delegate;
    FileSystemEntity entity = _fs.memory.entityForUri(uri);
    if ((uri.scheme != 'file' && uri.scheme != 'data') ||
        await entity.exists()) {
      _delegate = entity;
      return _delegate;
    }
    return _delegate = _fs.physical.entityForUri(uri);
  }

  @override
  Future<bool> exists() async => (await delegate).exists();

  @override
  Future<List<int>> readAsBytes() async => (await delegate).readAsBytes();

  @override
  Future<String> readAsString() async => (await delegate).readAsString();
}
