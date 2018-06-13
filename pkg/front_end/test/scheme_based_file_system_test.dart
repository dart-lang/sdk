// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/scheme_based_file_system.dart';

import 'package:test/test.dart';

main() {
  test('lookup of registered schemes is handled', () {
    var fs1 = new MockFileSystem('scheme1');
    var fs2 = new MockFileSystem('scheme2');
    var fileSystem =
        new SchemeBasedFileSystem({'scheme1': fs1, 'scheme2': fs2});

    MockFileSystemEntity e1 =
        fileSystem.entityForUri(Uri.parse('scheme1:a.dart'));
    MockFileSystemEntity e2 =
        fileSystem.entityForUri(Uri.parse('scheme2:a.dart'));
    expect(e1.fileSystem, fs1);
    expect(e2.fileSystem, fs2);
  });

  test('lookup of an unregistered scheme will throw', () {
    var fileSystem =
        new SchemeBasedFileSystem({'scheme1': new MockFileSystem('scheme1')});
    expect(() => fileSystem.entityForUri(Uri.parse('scheme2:a.dart')),
        throwsA((e) => e is FileSystemException));
  });
}

class MockFileSystem implements FileSystem {
  String scheme;
  MockFileSystem(this.scheme);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme != scheme) throw "unsupported";
    return new MockFileSystemEntity(uri, this);
  }
}

class MockFileSystemEntity implements FileSystemEntity {
  final Uri uri;
  final FileSystem fileSystem;
  MockFileSystemEntity(this.uri, this.fileSystem);

  noSuchMethod(m) => super.noSuchMethod(m);
}
