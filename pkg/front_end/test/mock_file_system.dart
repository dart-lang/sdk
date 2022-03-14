// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/file_system.dart';

class MockFileSystem implements FileSystem {
  final String? scheme;

  const MockFileSystem({this.scheme});

  @override
  FileSystemEntity entityForUri(Uri uri) {
    final scheme = this.scheme;
    if (scheme != null && !uri.isScheme(scheme)) throw "unsupported";
    return new MockFileSystemEntity(uri, this);
  }
}

class MockFileSystemEntity implements FileSystemEntity {
  @override
  final Uri uri;
  final FileSystem fileSystem;
  MockFileSystemEntity(this.uri, this.fileSystem);

  @override
  dynamic noSuchMethod(m) => super.noSuchMethod(m);
}
