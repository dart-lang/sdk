// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api_prototype/file_system.dart';

/// A [FileSystem] that delegates to other file systems based on the URI scheme.
class SchemeBasedFileSystem implements FileSystem {
  final Map<String, FileSystem> fileSystemByScheme;

  SchemeBasedFileSystem(this.fileSystemByScheme);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    FileSystem delegate = fileSystemByScheme[uri.scheme];
    if (delegate == null) {
      throw new FileSystemException(
          uri,
          "SchemeBasedFileSystem doesn't handle URIs with "
          "scheme '${uri.scheme}': $uri");
    }
    return delegate.entityForUri(uri);
  }
}
