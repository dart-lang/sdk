// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A file system that implements [CopilerOptions.multiRoots].
library front_end.src.multi_roots_file_system;

import 'dart:async';

import 'package:front_end/file_system.dart';

/// Wraps a file system to create an overlay of files from multiple roots.
///
/// Regular `file:` URIs are resolved directly in the underlying file system,
/// but URIs that use a special [markerScheme] are resolved by searching
/// under a set of given roots in order.
///
/// For example, consider the following inputs:
///
///   - markerScheme is `multi-root`
///   - the set of roots are `file:///a/` and `file:///b/`
///   - the underlying file system contains files:
///         a/c/a1.dart
///         a/c/a2.dart
///         b/c/b1.dart
///         b/c/a2.dart
///         c/c1.dart
///
/// Then:
///
///   - file:///c/c1.dart is resolved as file:///c/c1.dart
///   - multi-root:///c/a1.dart is resolved as file:///a/c/a1.dart
///   - multi-root:///c/b1.dart is resolved as file:///b/c/b1.dart
///   - multi-root:///c/a2.dart is resolved as file:///a/c/b2.dart
class MultiRootFileSystem implements FileSystem {
  final String markerScheme;
  final List<Uri> roots;
  final FileSystem original;

  MultiRootFileSystem(this.markerScheme, List roots, this.original)
      : roots = roots.map(_normalize).toList();

  @override
  FileSystemEntity entityForUri(Uri uri) =>
      new MultiRootFileSystemEntity(this, uri);
}

/// Entity that searches the multiple roots and resolve a, possibly multi-root,
/// entity to a plain entity under `multiRootFileSystem.original`.
class MultiRootFileSystemEntity implements FileSystemEntity {
  final MultiRootFileSystem multiRootFileSystem;
  final Uri uri;
  FileSystemEntity _delegate;
  Future<FileSystemEntity> get delegate async =>
      _delegate ??= await _resolveEntity();

  Future<FileSystemEntity> _resolveEntity() async {
    if (uri.scheme == multiRootFileSystem.markerScheme && uri.isAbsolute) {
      var original = multiRootFileSystem.original;
      assert(uri.path.startsWith('/'));
      var path = uri.path.substring(1);
      for (var root in multiRootFileSystem.roots) {
        var candidate = original.entityForUri(root.resolve(path));
        if (await candidate.exists()) return candidate;
      }
    }
    return multiRootFileSystem.original.entityForUri(uri);
  }

  MultiRootFileSystemEntity(this.multiRootFileSystem, this.uri);

  @override
  Future<bool> exists() async => (await delegate).exists();

  @override
  Future<List<int>> readAsBytes() async => (await delegate).readAsBytes();

  @override
  Future<String> readAsString() async => (await delegate).readAsString();
}

_normalize(Uri uri) =>
    uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
