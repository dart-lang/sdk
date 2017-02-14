// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/file_repository.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileRepositoryTest);
  });
}

/// Generic URI resolver tests which do not depend on the particular path
/// context in use.
@reflectiveTest
class FileRepositoryTest {
  final fileRepository = new FileRepository();

  test_clearContents() {
    var uri = Uri.parse('file:///foo/bar.dart');
    fileRepository.store(uri, 'contents1');
    expect(fileRepository.getContentsForTesting(), isNotEmpty);
    fileRepository.clearContents();
    expect(fileRepository.getContentsForTesting(), isEmpty);
  }

  test_contentsForPath() {
    var path1 =
        fileRepository.store(Uri.parse('file:///foo/bar.dart'), 'contents1');
    var path2 =
        fileRepository.store(Uri.parse('package:foo/bar.dart'), 'contents2');
    expect(fileRepository.contentsForPath(path1), 'contents1');
    expect(fileRepository.contentsForPath(path2), 'contents2');
  }

  test_pathForUri() {
    var uri1 = Uri.parse('file:///foo/bar.dart');
    var path1 = fileRepository.store(uri1, 'contents1');
    var uri2 = Uri.parse('package:foo/bar.dart');
    var path2 = fileRepository.store(uri2, 'contents2');
    expect(fileRepository.pathForUri(uri1), path1);
    expect(fileRepository.pathForUri(uri2), path2);
  }

  test_pathForUri_allocate() {
    var uri1 = Uri.parse('file:///foo/bar.dart');
    var path1 = fileRepository.pathForUri(uri1, allocate: true);
    var uri2 = Uri.parse('package:foo/bar.dart');
    var path2 = fileRepository.pathForUri(uri2, allocate: true);
    expect(fileRepository.store(uri1, 'contents1'), path1);
    expect(fileRepository.store(uri2, 'contents2'), path2);
  }

  test_store() {
    var uri = Uri.parse('file:///foo/bar.dart');
    var path = fileRepository.store(uri, 'contents1');
    expect(path, endsWith('.dart'));
    expect(fileRepository.contentsForPath(path), 'contents1');
    expect(fileRepository.getContentsForTesting(), {path: 'contents1'});
    expect(fileRepository.store(uri, 'contents2'), path);
    expect(fileRepository.contentsForPath(path), 'contents2');
    expect(fileRepository.getContentsForTesting(), {path: 'contents2'});
  }

  test_uriForPath() {
    var uri1 = Uri.parse('file:///foo/bar.dart');
    var path1 = fileRepository.store(uri1, 'contents1');
    var uri2 = Uri.parse('package:foo/bar.dart');
    var path2 = fileRepository.store(uri2, 'contents2');
    expect(fileRepository.uriForPath(path1), uri1);
    expect(fileRepository.uriForPath(path2), uri2);
  }
}
