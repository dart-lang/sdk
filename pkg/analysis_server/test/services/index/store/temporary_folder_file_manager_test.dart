// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.temporary_folder_file_mananer;

import 'dart:io';

import 'package:analysis_server/src/services/index/store/temporary_folder_file_manager.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import '../../../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(_SeparateFileManagerTest);
}


@ReflectiveTestCase()
class _SeparateFileManagerTest {
  TemporaryFolderFileManager fileManager;

  void setUp() {
    fileManager = new TemporaryFolderFileManager();
  }

  void tearDown() {
    fileManager.clear();
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
    return fileManager.write('other.index', <int>[1, 2, 3, 4]).then((_) {
      String name = "42.index";
      fileManager.delete(name);
    });
  }

  test_delete_noDirectory() {
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

  test_read_noDirectory() {
    String name = "42.index";
    return fileManager.read(name).then((bytes) {
      expect(bytes, isNull);
    });
  }

  bool _existsSync(String name) {
    Directory directory = fileManager.test_directory;
    if (directory == null) {
      return false;
    }
    return new File(join(directory.path, name)).existsSync();
  }
}
