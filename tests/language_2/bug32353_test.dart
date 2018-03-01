// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

import 'dart:io' as io;

import "package:expect/expect.dart";

class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, io.Directory>
    with ForwardingDirectory, DirectoryAddOnsMixin {
  noSuchMethod(invocation) => null;
}

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {}

abstract class FileSystemEntity implements io.FileSystemEntity {}

abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
    D extends io.FileSystemEntity> implements FileSystemEntity {}

abstract class ForwardingDirectory<T extends Directory>
    extends ForwardingFileSystemEntity<T, io.Directory> implements Directory {
  get t => T;
}

abstract class Directory implements FileSystemEntity, io.Directory {}

abstract class DirectoryAddOnsMixin implements Directory {}

main() {
  var x = new _LocalDirectory();
  Expect.equals(x.t, _LocalDirectory);
}
