// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/build_integration.dart';

/// A [FileSystem] that resolves custom URIs to entities under a specified root
/// folder on an underlying [FileSystem].
///
/// This abstraction lets packages like `package:front_end` use absolute URIs
/// freely, while hiding machine-specific or user-specific details. In
/// particular, this file-system is used to create a machine-independent .dill
/// files in distributed build systems.
///
/// The resolution rules are as follows: if a given URI uses a special
/// [markerScheme] it gets resolved under the given [root], while a given URI
/// with any other scheme will produce an error.
///
/// For example, if [markerScheme] is `single-root`, and [root] is
/// `file:///a/b/c/`, then, calling [entityForUri] will:
///
///   * resolve `single-root:///f1.dart` to `file:///a/b/c/f1.dart`.
///   * resolve `single-root:///d/f2.dart` to `file:///a/b/c/d/f2.dart`.
///   * throw on `other-custom-scheme:///d/f2.dart`.
///   * throw on `file:///d/f2.dart`.
class SingleRootFileSystem implements FileSystem {
  final String markerScheme;
  final Uri root;
  final FileSystem original;

  SingleRootFileSystem(this.markerScheme, Uri root, this.original)
      : root = _normalize(root);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme != markerScheme) {
      throw new FileSystemException(
          uri,
          "This SingleRootFileSystem only handles URIs with the '$markerScheme'"
          " scheme and cannot handle URIs with scheme '${uri.scheme}': $uri");
    }
    if (!uri.path.startsWith('/')) {
      throw new FileSystemException(
          uri, "This SingleRootFileSystem only handles absolutes URIs: $uri");
    }
    var path = uri.path.substring(1);
    return new SingleRootFileSystemEntity(
        uri, original.entityForUri(root.resolve(path)));
  }
}

/// [FileSystemEntity] with a URI of the `SingleRootFileSystem.markerScheme`,
/// that delegates all operations to an underlying entity in the original
/// `SingleRootFileSystem.filesystem`.
class SingleRootFileSystemEntity implements FileSystemEntity {
  final Uri uri;
  final FileSystemEntity delegate;

  SingleRootFileSystemEntity(this.uri, this.delegate);

  @override
  Future<bool> exists() async => delegate.exists();

  @override
  Future<List<int>> readAsBytes() async => delegate.readAsBytes();

  @override
  Future<String> readAsString() async => delegate.readAsString();
}

_normalize(root) {
  Uri uri = root;
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}
