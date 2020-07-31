// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';

Future<FileSystem>? _fileSystem;

Future<FileSystem> get fileSystem async {
  if (_fileSystem != null) return _fileSystem!;

  _fileSystem = window.requestFileSystem(100);

  var fs = await _fileSystem!;
  expect(fs.runtimeType, FileSystem);
  expect(fs.root.runtimeType, DirectoryEntry);

  return _fileSystem!;
}

main() {
  test('supported', () {
    expect(FileSystem.supported, true);
  });

  test('requestFileSystem', () async {
    var expectation = FileSystem.supported ? returnsNormally : throws;
    expect(() async {
      var fs = await fileSystem;
    }, expectation);
  });
}
