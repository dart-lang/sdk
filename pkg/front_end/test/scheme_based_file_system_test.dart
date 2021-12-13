// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/scheme_based_file_system.dart';

import 'package:test/test.dart';

import 'mock_file_system.dart';

void main() {
  test('lookup of registered schemes is handled', () {
    var fs1 = new MockFileSystem(scheme: 'scheme1');
    var fs2 = new MockFileSystem(scheme: 'scheme2');
    var fileSystem =
        new SchemeBasedFileSystem({'scheme1': fs1, 'scheme2': fs2});

    MockFileSystemEntity e1 = fileSystem
        .entityForUri(Uri.parse('scheme1:a.dart')) as MockFileSystemEntity;
    MockFileSystemEntity e2 = fileSystem
        .entityForUri(Uri.parse('scheme2:a.dart')) as MockFileSystemEntity;
    expect(e1.fileSystem, fs1);
    expect(e2.fileSystem, fs2);
  });

  test('lookup of an unregistered scheme will throw', () {
    var fileSystem = new SchemeBasedFileSystem(
        {'scheme1': new MockFileSystem(scheme: 'scheme1')});
    expect(() => fileSystem.entityForUri(Uri.parse('scheme2:a.dart')),
        throwsA((e) => e is FileSystemException));
  });
}
