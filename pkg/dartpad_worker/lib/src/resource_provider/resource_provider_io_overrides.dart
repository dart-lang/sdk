// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:file/file.dart' as f;

import 'resource_provider_file.dart';

/// Runs [body] with all `dart:io` file-system operations redirected into
/// [resourceProvider].
R runWithResourceProviderIO<R>(
  ResourceProvider resourceProvider,
  R Function() body,
) => IOOverrides.runWithIOOverrides(
  body,
  _ResourceProviderIOOverrides(
    resourceProviderAsFileFileSystem(resourceProvider),
  ),
);

/// An [IOOverrides] that serves all file-system operations from [fileSystem].
final class _ResourceProviderIOOverrides extends IOOverrides {
  final f.FileSystem fileSystem;

  _ResourceProviderIOOverrides(this.fileSystem);

  @override
  Directory createDirectory(String path) => fileSystem.directory(path);

  @override
  File createFile(String path) => fileSystem.file(path);

  @override
  Link createLink(String path) => fileSystem.link(path);

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) =>
      fileSystem.type(path, followLinks: followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      fileSystem.typeSync(path, followLinks: followLinks);

  @override
  Future<bool> fseIdentical(String path1, String path2) =>
      fileSystem.identical(path1, path2);

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      fileSystem.identicalSync(path1, path2);

  @override
  bool fsWatchIsSupported() => fileSystem.isWatchSupported;

  @override
  Stream<FileSystemEvent> fsWatch(String path, int events, bool recursive) =>
      fileSystem.directory(path).watch(events: events, recursive: recursive);

  @override
  Directory getCurrentDirectory() => fileSystem.currentDirectory;

  @override
  void setCurrentDirectory(String path) {
    fileSystem.currentDirectory = path;
  }

  @override
  Directory getSystemTempDirectory() => fileSystem.systemTempDirectory;

  @override
  Future<FileStat> stat(String path) => fileSystem.stat(path);

  @override
  FileStat statSync(String path) => fileSystem.statSync(path);
}
