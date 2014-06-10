// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.page_node_manager;

import 'dart:math';
import 'dart:typed_data';

import 'package:analysis_server/src/index/b_plus_tree.dart';
import 'package:analysis_server/src/index/page_node_manager.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('FixedStringCodecTest', () {
    runReflectiveTests(_FixedStringCodecTest);
  });
  group('MemoryPageManager', () {
    runReflectiveTests(_MemoryPageManagerTest);
  });
  group('PageNodeManager', () {
    runReflectiveTests(_PageNodeManagerTest);
  });
  group('Uint32CodecTest', () {
    runReflectiveTests(_Uint32CodecTest);
  });
  test('B+ tree with PageNodeManager', _treeWithPageNodeManager);
}


int _intComparator(int a, int b) => a - b;


/**
 * A stress test for [BPlusTree] using [PageNodeManager].
 */
_treeWithPageNodeManager() {
  int pageSize = 256;
  MemoryPageManager pageManager = new MemoryPageManager(pageSize);
  NodeManager<int, String, int> nodeManager = new PageNodeManager<int, String>(
      pageManager, Uint32Codec.INSTANCE, new FixedStringCodec(7));
//  NodeManager<int, String, int> nodeManager = new MemoryNodeManager();
  print('maxIndexKeys: ${nodeManager.maxIndexKeys}   '
      'maxLeafKeys: ${nodeManager.maxLeafKeys}');
  BPlusTree<int, String, int> tree = new BPlusTree(_intComparator, nodeManager);
  int maxKey = 1000000;
  int tryCount = 1000;
  Set<int> keys = new Set<int>();
  {
    Random random = new Random();
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
    Random random = new Random();
    for (int key in new Set<int>.from(keys)) {
      if (random.nextBool()) {
        keys.remove(key);
        expect(tree.remove(key), 'V$key');
      }
    }
  }
  // find every remaining key
  for (int key in keys) {
    expect(tree.find(key), 'V$key');
  }
}


@ReflectiveTestCase()
class _FixedStringCodecTest {
  ByteData buffer;
  Uint8List bytes = new Uint8List(2 + 2 * 4);
  FixedStringCodec codec = new FixedStringCodec(4);

  void setUp() {
    buffer = new ByteData.view(bytes.buffer);
  }

  test_empty() {
    // encode
    codec.encode(buffer, '');
    expect(bytes, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    // decode
    expect(codec.decode(buffer), '');
  }

  test_fourChars() {
    // encode
    codec.encode(buffer, 'ABCD');
    expect(bytes, [0, 4, 0, 65, 0, 66, 0, 67, 0, 68]);
    // decode
    expect(codec.decode(buffer), 'ABCD');
  }

  test_tooManyChars() {
    expect(() {
      codec.encode(buffer, 'ABCDE');
    }, throws);
  }

  test_twoChars() {
    // encode
    codec.encode(buffer, 'AB');
    expect(bytes, [0, 2, 0, 65, 0, 66, 0, 0, 0, 0]);
    // decode
    expect(codec.decode(buffer), 'AB');
  }
}



@ReflectiveTestCase()
class _MemoryPageManagerTest {
  static const PAGE_SIZE = 8;
  MemoryPageManager manager = new MemoryPageManager(PAGE_SIZE);

  test_alloc() {
    int idA = manager.alloc();
    int idB = manager.alloc();
    expect(idB, isNot(idA));
  }

  test_free() {
    int id = manager.alloc();
    manager.free(id);
    // double free
    expect(() {
      manager.free(id);
    }, throws);
  }

  test_read() {
    int id = manager.alloc();
    Uint8List page = manager.read(id);
    expect(page.length, PAGE_SIZE);
  }

  test_read_doesNotExist() {
    expect(() {
      manager.read(0);
    }, throws);
  }

  test_write() {
    int id = manager.alloc();
    // do write
    {
      Uint8List page = new Uint8List(PAGE_SIZE);
      page[3] = 42;
      manager.write(id, page);
    }
    // now read
    {
      Uint8List page = manager.read(id);
      expect(page.length, PAGE_SIZE);
      expect(page[3], 42);
    }
  }

  test_write_doesNotExist() {
    expect(() {
      Uint8List page = new Uint8List(PAGE_SIZE);
      manager.write(42, page);
    }, throws);
  }
}



@ReflectiveTestCase()
class _PageNodeManagerTest {
  static const Codec KEY_CODEC = Uint32Codec.INSTANCE;
  static const int PAGE_SIZE = 128;
  static const Codec VALUE_CODEC = const FixedStringCodec(4);

  PageNodeManager<int, String> nodeManager;
  MemoryPageManager pageManager = new MemoryPageManager(PAGE_SIZE);

  setUp() {
    nodeManager = new PageNodeManager<int, String>(pageManager, KEY_CODEC,
        VALUE_CODEC);
  }

  test_index_createDelete() {
    int id = nodeManager.createIndex();
    expect(nodeManager.isIndex(id), isTrue);
    // do delete
    nodeManager.delete(id);
    expect(nodeManager.isIndex(id), isFalse);
  }

  test_index_readWrite() {
    int id = nodeManager.createIndex();
    expect(nodeManager.isIndex(id), isTrue);
    // write
    {
      var keys = [1, 2];
      var children = [10, 20, 30];
      nodeManager.writeIndex(id, new IndexNodeData<int, int>(keys, children));
    }
    // check the page
    {
      Uint8List page = pageManager.read(id);
      expect(page, [0, 0, 0, 2, 0, 0, 0, 10, 0, 0, 0, 1, 0, 0, 0, 20, 0, 0, 0,
          2, 0, 0, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0]);
    }
    // read
    {
      IndexNodeData<int, int> data = nodeManager.readIndex(id);
      expect(data.keys, [1, 2]);
      expect(data.children, [10, 20, 30]);
    }
  }

  test_leaf_readWrite() {
    int id = nodeManager.createLeaf();
    expect(nodeManager.isIndex(id), isFalse);
    // write
    {
      var keys = [1, 2, 3];
      var children = ['A', 'BB', 'CCC'];
      nodeManager.writeLeaf(id, new LeafNodeData<int, String>(keys, children));
    }
    // check the page
    {
      Uint8List page = pageManager.read(id);
      expect(page, [0, 0, 0, 3, 0, 0, 0, 1, 0, 1, 0, 65, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 2, 0, 2, 0, 66, 0, 66, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 0, 67, 0, 67, 0, 67, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0]);
    }
    // read
    {
      LeafNodeData<int, String> data = nodeManager.readLeaf(id);
      expect(data.keys, [1, 2, 3]);
      expect(data.values, ['A', 'BB', 'CCC']);
    }
  }
}

@ReflectiveTestCase()
class _Uint32CodecTest {
  ByteData buffer;
  Uint8List bytes = new Uint8List(4);
  Uint32Codec codec = Uint32Codec.INSTANCE;

  void setUp() {
    buffer = new ByteData.view(bytes.buffer);
  }

  test_all() {
    // encode
    codec.encode(buffer, 42);
    expect(bytes, [0, 0, 0, 42]);
    // decode
    expect(codec.decode(buffer), 42);
  }
}
