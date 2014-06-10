// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.file_page_manager;

import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:analysis_server/src/index/b_plus_tree.dart';
import 'package:analysis_server/src/index/file_page_manager.dart';
import 'package:analysis_server/src/index/page_node_manager.dart';
import 'package:path/path.dart' as pathos;
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('FixedStringCodecTest', () {
    runReflectiveTests(_FilePageManagerTest);
  });
}


int _intComparator(int a, int b) => a - b;


@ReflectiveTestCase()
class _FilePageManagerTest {
  FilePageManager manager;
  int pageSize = 1024;
  Directory tempDir;

  void setUp() {
    tempDir = Directory.systemTemp.createTempSync('testIndex_');
    String path = pathos.join(tempDir.path, 'my.index');
    manager = new FilePageManager(pageSize, path);
  }

  void tearDown() {
    manager.close();
    manager.delete();
    tempDir.deleteSync(recursive: true);
  }

  void test_alloc_reuseFree() {
    int id = manager.alloc();
    manager.free(id);
    int newId = manager.alloc();
    expect(newId, id);
  }

  void test_alloc_unique() {
    int idA = manager.alloc();
    int idB = manager.alloc();
    expect(idB, isNot(idA));
  }

  void test_btree_stress_random() {
    NodeManager<int, String, int> nodeManager = new PageNodeManager<int,
        String>(manager, Uint32Codec.INSTANCE, new FixedStringCodec(7));
    nodeManager = new CachingNodeManager(nodeManager, 32, 32);
    BPlusTree<int, String, int> tree = new BPlusTree(_intComparator,
        nodeManager);
    // insert
    int maxKey = 1000000;
    int tryCount = 1000;
    Set<int> keys = new Set<int>();
    {
      Random random = new Random(37);
      for (int i = 0; i < tryCount; i++) {
        int key = random.nextInt(maxKey);
        keys.add(key);
        tree.insert(key, 'V$key');
      }
    }
    // find every
    for (int key in keys) {
      expect(tree.find(key), 'V$key');
    }
    // remove random keys
    {
      Random random = new Random(37);
      Set<int> removedKeys = new HashSet<int>();
      for (int key in new Set<int>.from(keys)) {
        if (random.nextBool()) {
          removedKeys.add(key);
          keys.remove(key);
          expect(tree.remove(key), 'V$key');
        }
      }
      // check the removed keys are actually gone
      for (int key in removedKeys) {
        expect(tree.find(key), isNull);
      }
    }
    // find every remaining key
    for (int key in keys) {
      expect(tree.find(key), 'V$key');
    }
  }

  void test_free_double() {
    int id = manager.alloc();
    manager.free(id);
    expect(() {
      manager.free(id);
    }, throws);
  }

  void test_writeRead() {
    // write
    int id1 = manager.alloc();
    int id2 = manager.alloc();
    manager.write(id1, new Uint8List.fromList(new List.filled(pageSize, 1)));
    manager.write(id2, new Uint8List.fromList(new List.filled(pageSize, 2)));
    // read
    expect(manager.read(id1), everyElement(1));
    expect(manager.read(id2), everyElement(2));
  }
}
