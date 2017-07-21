// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A memory + physical file system used to mock input for tests but provide
/// sdk sources from disk.
library front_end.src.hybrid_file_system;

import 'dart:async';

import 'package:front_end/file_system.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/physical_file_system.dart';

/// A file system that mixes files from memory and a physical file system. All
/// memory entities take priotity over file system entities.
class HybridFileSystem implements FileSystem {
  final MemoryFileSystem memory;
  final PhysicalFileSystem physical = PhysicalFileSystem.instance;

  HybridFileSystem(this.memory);

  @override
  FileSystemEntity entityForUri(Uri uri) => new HybridFileSystemEntity(
      memory.entityForUri(uri), physical.entityForUri(uri));
}

/// Entity that delegates to an underlying memory or phisical file system
/// entity.
class HybridFileSystemEntity implements FileSystemEntity {
  final FileSystemEntity memory;
  final FileSystemEntity physical;

  HybridFileSystemEntity(this.memory, this.physical);

  FileSystemEntity _delegate;
  Future<FileSystemEntity> get delegate async {
    return _delegate ??= (await memory.exists()) ? memory : physical;
  }

  @override
  Uri get uri => memory.uri;

  @override
  Future<bool> exists() async => (await delegate).exists();

  @override
  Future<List<int>> readAsBytes() async => (await delegate).readAsBytes();

  @override
  Future<String> readAsString() async => (await delegate).readAsString();
}
