// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.engine.src.index.store.separate_file_mananer;

import 'dart:io';

import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/index/store/separate_file_manager.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  group('SeparateFileManager', () {
    runReflectiveTests(_SeparateFileManagerTest);
  });
}


@ReflectiveTestCase()
class _SeparateFileManagerTest {
  Directory tempDir;
  SeparateFileManager fileManager;

  void setUp() {
    tempDir = Directory.systemTemp.createTempSync('AnalysisServer_index');
    fileManager = new SeparateFileManager(tempDir);
  }

  void tearDown() {
    tempDir.delete(recursive: true);
  }

  test_clear() {
    String name = "42.index";
    // create the file
    return fileManager.write(name, <int>[1, 2, 3, 4]).then((_) {
      // check that the file exists
      expect(_existsSync(name), isTrue);
      // clear
      fileManager.clear();
      expect(_existsSync(name), isFalse);
    });
  }

  test_delete_doesNotExist() {
    String name = "42.index";
    fileManager.delete(name);
  }

  test_outputInput() {
    String name = "42.index";
    // create the file
    return fileManager.write(name, <int>[1, 2, 3, 4]).then((_) {
      // check that that the file exists
      expect(_existsSync(name), isTrue);
      // read the file
      return fileManager.read(name).then((bytes) {
        expect(bytes, <int>[1, 2, 3, 4]);
        // delete
        fileManager.delete(name);
        // the file does not exist anymore
        return fileManager.read(name).then((bytes) {
          expect(bytes, isNull);
        });
      });
    });
  }

  bool _existsSync(String name) {
    return new File(join(tempDir.path, name)).existsSync();
  }
}
