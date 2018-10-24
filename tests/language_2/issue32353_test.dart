// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class io_FileSystemEntity {}

class io_Directory extends io_FileSystemEntity {}

class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, io_Directory>
    with ForwardingDirectory, DirectoryAddOnsMixin {
  noSuchMethod(invocation) => null;
}

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
    D extends io_FileSystemEntity> extends ForwardingFileSystemEntity<T, D> {}

abstract class FileSystemEntity implements io_FileSystemEntity {}

abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
    D extends io_FileSystemEntity> implements FileSystemEntity {}

mixin ForwardingDirectory<T extends Directory>
    on ForwardingFileSystemEntity<T, io_Directory> implements Directory {
  get t => T;
}

abstract class Directory implements FileSystemEntity, io_Directory {}

abstract class DirectoryAddOnsMixin implements Directory {}

main() {
  var x = new _LocalDirectory();
  Expect.equals(x.t, _LocalDirectory);
}
