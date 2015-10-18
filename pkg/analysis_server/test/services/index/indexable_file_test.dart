// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.index.indexable_file;

import 'package:analysis_server/src/services/index/indexable_file.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(IndexableFileKindTest);
  defineReflectiveTests(IndexableFileTest);
}

@reflectiveTest
class IndexableFileKindTest {
  void test_decode() {
    IndexableFile object =
        IndexableFileKind.INSTANCE.decode(null, '/a.dart', -1);
    expect(object.path, '/a.dart');
  }

  void test_encodeHash() {
    StringCodec stringCodec = new StringCodec();
    String path = '/a/bb/ccc.dart';
    int hash1 = IndexableFileKind.INSTANCE
        .encodeHash(stringCodec.encode, new IndexableFile(path));
    int hash2 = IndexableFileKind.INSTANCE
        .encodeHash(stringCodec.encode, new IndexableFile(path));
    expect(hash2, hash1);
  }
}

@reflectiveTest
class IndexableFileTest {
  void test_equals() {
    IndexableFile a = new IndexableFile('/a.dart');
    IndexableFile a2 = new IndexableFile('/a.dart');
    IndexableFile b = new IndexableFile('/b.dart');
    expect(a == a, isTrue);
    expect(a == a2, isTrue);
    expect(a == b, isFalse);
  }

  void test_getters() {
    String path = '/a/bb/ccc.dart';
    IndexableFile indexable = new IndexableFile(path);
    expect(indexable.kind, IndexableFileKind.INSTANCE);
    expect(indexable.filePath, path);
    expect(indexable.offset, -1);
    expect(indexable.toString(), path);
  }
}
