// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    as front_end
    show MultiRootFileSystem;
import 'package:file/file.dart' as file;
import 'package:file/memory.dart' as file;
import 'package:front_end/src/api_unstable/vm.dart'
    as front_end
    show FileSystem, FileSystemEntity;

/// Creates an in-memory [file.FileSystem] populated with [fileContents].
///
/// Wraps it in a [front_end.MultiRootFileSystem] under the given [root] path.
(front_end.FileSystem, file.FileSystem) fssForTests(
  String root,
  Map<String, String> fileContents,
) {
  final fs = file.MemoryFileSystem();
  for (final entry in fileContents.entries) {
    final file = fs.file(fs.path.join(root, entry.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }

  final primaryFs = FileBackedFrontendFileSystem(fs);
  final roots = [root, '$root/blaze-bin', '$root/blaze-genfiles'];
  final secondaryFs = front_end.MultiRootFileSystem(
    'google3',
    roots.map(Uri.parse).toList(),
    primaryFs,
  );
  return (secondaryFs, fs);
}

/// A [front_end.FileSystem] implementation backed by a [file.FileSystem].
class FileBackedFrontendFileSystem implements front_end.FileSystem {
  final file.FileSystem fs;

  FileBackedFrontendFileSystem(this.fs);

  @override
  front_end.FileSystemEntity entityForUri(Uri uri) =>
      FileBackedFrontendFileSystemEntity(fs, uri);
}

/// A [front_end.FileSystemEntity] implementation backed by a [file.FileSystem].
class FileBackedFrontendFileSystemEntity implements front_end.FileSystemEntity {
  final file.FileSystem fs;

  @override
  final Uri uri;

  var _resolved = false;
  late final file.FileSystemEntity _entity;
  Future<file.FileSystemEntity> get entity async {
    await _resolve();
    return _entity;
  }

  FileBackedFrontendFileSystemEntity(this.fs, this.uri);

  Future<void> _resolve() async {
    if (_resolved) return;
    final path = fs.path.fromUri(uri);
    final stat = await fs.stat(path);
    switch (stat.type) {
      case file.FileSystemEntityType.directory:
        _entity = fs.directory(path);
      default:
        _entity = fs.file(path);
    }
    _resolved = true;
  }

  @override
  Future<bool> exists() async => (await entity).exists();

  @override
  Future<bool> existsAsyncIfPossible() => exists();

  @override
  Future<Uint8List> readAsBytes() async =>
      ((await entity) as file.File).readAsBytes();

  @override
  Future<Uint8List> readAsBytesAsyncIfPossible() => readAsBytes();

  @override
  Future<String> readAsString() async =>
      ((await entity) as file.File).readAsString();
}
