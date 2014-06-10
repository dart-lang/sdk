// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.page_node_manager;

import 'dart:math';
import 'dart:typed_data';

import 'package:analysis_server/src/index/b_plus_tree.dart';
import 'package:analysis_server/src/index/page_node_manager.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('_CachingNodeManagerTest', () {
    runReflectiveTests(_CachingNodeManagerTest);
  });
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
  BPlusTree<int, String, int> tree = new BPlusTree(_intComparator, nodeManager);
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
class _CachingNodeManagerTest {
  _NodeManagerMock<int, String, int> delegate = new _NodeManagerMock<int,
      String, int>();
  NodeManager<int, String, int> manager;

  void setUp() {
    when(delegate.writeIndex).thenReturn((key, value) {
      delegate.writeIndex(key, value);
    });
    when(delegate.writeLeaf).thenReturn((key, value) {
      delegate.writeLeaf(key, value);
    });
    manager = new CachingNodeManager<int, String, int>(delegate, 4, 4);
    resetInteractions(delegate);
  }

  void test_maxIndexKeys() {
    when(delegate.maxIndexKeys).thenReturn(42);
    expect(manager.maxIndexKeys, 42);
  }

  void test_maxLeafKeys() {
    when(delegate.maxLeafKeys).thenReturn(42);
    expect(manager.maxLeafKeys, 42);
  }

  void test_createIndex() {
    when(delegate.createIndex()).thenReturn(77);
    expect(manager.createIndex(), 77);
  }

  void test_createLeaf() {
    when(delegate.createLeaf()).thenReturn(99);
    expect(manager.createLeaf(), 99);
  }

  void test_delete() {
    manager.delete(42);
    verify(delegate.delete(42)).once();
  }

  void test_isIndex() {
    when(delegate.isIndex(1)).thenReturn(true);
    when(delegate.isIndex(2)).thenReturn(false);
    expect(manager.isIndex(1), isTrue);
    expect(manager.isIndex(2), isFalse);
  }

  void test_readIndex_cached() {
    var data = new IndexNodeData<int, int>([1, 2], [10, 20, 30]);
    manager.writeIndex(2, data);
    expect(manager.readIndex(2), data);
    // delete, forces request to the delegate
    manager.delete(2);
    manager.readIndex(2);
    verify(delegate.readIndex(2)).once();
  }

  void test_readIndex_delegate() {
    var data = new IndexNodeData<int, int>([1, 2], [10, 20, 30]);
    when(delegate.readIndex(2)).thenReturn(data);
    expect(manager.readIndex(2), data);
  }

  void test_readLeaf_cached() {
    var data = new LeafNodeData<int, String>([1, 2, 3], ['A', 'B', 'C']);
    manager.writeLeaf(2, data);
    expect(manager.readLeaf(2), data);
    // delete, forces request to the delegate
    manager.delete(2);
    manager.readLeaf(2);
    verify(delegate.readLeaf(2)).once();
  }

  void test_readLeaf_delegate() {
    var data = new LeafNodeData<int, String>([1, 2, 3], ['A', 'B', 'C']);
    when(delegate.readLeaf(2)).thenReturn(data);
    expect(manager.readLeaf(2), data);
  }

  void test_writeIndex() {
    var data = new IndexNodeData<int, int>([1], [10, 20]);
    manager.writeIndex(1, data);
    manager.writeIndex(2, data);
    manager.writeIndex(3, data);
    manager.writeIndex(4, data);
    manager.writeIndex(1, data);
    verifyZeroInteractions(delegate);
    // only 4 nodes can be cached, 5-th one cause write to the delegate
    manager.writeIndex(5, data);
    verify(delegate.writeIndex(2, data)).once();
  }

  void test_writeLeaf() {
    var data = new LeafNodeData<int, String>([1, 2], ['A', 'B']);
    manager.writeLeaf(1, data);
    manager.writeLeaf(2, data);
    manager.writeLeaf(3, data);
    manager.writeLeaf(4, data);
    manager.writeLeaf(1, data);
    verifyZeroInteractions(delegate);
    // only 4 nodes can be cached, 5-th one cause write to the delegate
    manager.writeLeaf(5, data);
    verify(delegate.writeLeaf(2, data)).once();
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

  test_russian() {
    // encode
    codec.encode(buffer, 'ЩУКА');
    expect(bytes, [0, 4, 4, 41, 4, 35, 4, 26, 4, 16]);
    // decode
    expect(codec.decode(buffer), 'ЩУКА');
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

  test_write_invalidLength() {
    int id = manager.alloc();
    Uint8List page = new Uint8List(0);
    expect(() {
      manager.write(id, page);
    }, throws);
  }
}



class _NodeManagerMock<K, V, N> extends TypedMock implements NodeManager<K, V,
    N> {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
