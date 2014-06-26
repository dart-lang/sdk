// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.page_node_manager;

import 'dart:collection';
import 'dart:typed_data';

import 'package:analysis_server/src/index/b_plus_tree.dart';
import 'package:analysis_server/src/index/lru_cache.dart';


/**
 * A [NodeManager] that caches a specified number of index and leaf nodes.
 */
class CachingNodeManager<K, V, N> implements NodeManager<K, V, N> {
  final NodeManager<K, V, N> _delegate;
  LRUCache<N, IndexNodeData<K, N>> _indexCache;
  LRUCache<N, LeafNodeData<K, V>> _leafCache;

  CachingNodeManager(this._delegate, int indexNodeCacheSize,
      int leafNodeCacheSize) {
    _indexCache = new LRUCache<N, IndexNodeData<K, N>>(indexNodeCacheSize,
        _delegate.writeIndex);
    _leafCache = new LRUCache<N, LeafNodeData<K, V>>(leafNodeCacheSize,
        _delegate.writeLeaf);
  }

  @override
  int get maxIndexKeys => _delegate.maxIndexKeys;

  @override
  int get maxLeafKeys => _delegate.maxLeafKeys;

  @override
  N createIndex() {
    return _delegate.createIndex();
  }

  @override
  N createLeaf() {
    return _delegate.createLeaf();
  }

  @override
  void delete(N id) {
    _indexCache.remove(id);
    _leafCache.remove(id);
    _delegate.delete(id);
  }

  @override
  bool isIndex(N id) {
    return _delegate.isIndex(id);
  }

  @override
  IndexNodeData<K, N> readIndex(N id) {
    IndexNodeData<K, N> data = _indexCache.get(id);
    if (data == null) {
      data = _delegate.readIndex(id);
      _indexCache.put(id, data);
    }
    return data;
  }

  @override
  LeafNodeData<K, V> readLeaf(N id) {
    LeafNodeData<K, V> data = _leafCache.get(id);
    if (data == null) {
      data = _delegate.readLeaf(id);
      _leafCache.put(id, data);
    }
    return data;
  }

  @override
  void writeIndex(N id, IndexNodeData<K, N> data) {
    _indexCache.put(id, data);
  }

  @override
  void writeLeaf(N id, LeafNodeData<K, V> data) {
    _leafCache.put(id, data);
  }
}


/**
 * A [Codec] encodes and decodes data.
 */
abstract class Codec<E> {
  /**
   * The size of the value in bytes.
   */
  int get sizeInBytes;

  /**
   * Returns the value decoded from [buffer].
   *
   * The given [buffer] has exactly [sizeInBytes] bytes length.
   */
  E decode(ByteData buffer);

  /**
   * Encodes [value] into [buffer].
   *
   * The given [buffer] has exactly [sizeInBytes] bytes length.
   */
  void encode(ByteData buffer, E value);
}


/**
 * A [Codec] for strings with a predefined maximum length.
 */
class FixedStringCodec implements Codec<String> {
  final int maxLength;
  final int sizeInBytes;

  const FixedStringCodec(int maxLength)
      : maxLength = maxLength,
        sizeInBytes = 2 + 2 * maxLength;

  @override
  String decode(ByteData buffer) {
    int length = buffer.getUint16(0);
    int offset = 2;
    List<int> codeUnits = new List<int>(length);
    for (int i = 0; i < length; i++) {
      codeUnits[i] = buffer.getUint16(offset);
      offset += 2;
    }
    return new String.fromCharCodes(codeUnits);
  }

  @override
  void encode(ByteData buffer, String value) {
    int length = value.length;
    if (length > maxLength) {
      throw new ArgumentError(
          'String $value length=$length is greater than allowed $maxLength');
    }
    buffer.setUint16(0, length);
    int offset = 2;
    List<int> codeUnits = value.codeUnits;
    for (int i = 0; i < length; i++) {
      buffer.setUint16(offset, codeUnits[i]);
      offset += 2;
    }
  }
}


/**
 * A [PageManager] that keeps all [Uint8List] pages in memory.
 */
class MemoryPageManager implements PageManager {
  final int pageSizeInBytes;
  int _nextPage = 0;
  final Map<int, Uint8List> _pages = new HashMap<int, Uint8List>();

  MemoryPageManager(this.pageSizeInBytes);

  @override
  int alloc() {
    int id = _nextPage++;
    Uint8List page = new Uint8List(pageSizeInBytes);
    _pages[id] = page;
    return id;
  }

  @override
  void free(int id) {
    Uint8List page = _pages.remove(id);
    if (page == null) {
      throw new StateError('Page $id has been already freed.');
    }
  }

  @override
  Uint8List read(int id) {
    Uint8List page = _pages[id];
    if (page == null) {
      throw new StateError('Page $id does not exist.');
    }
    return page;
  }

  @override
  void write(int id, Uint8List page) {
    if (!_pages.containsKey(id)) {
      throw new StateError('Page $id does not exist.');
    }
    if (page.length != pageSizeInBytes) {
      throw new ArgumentError('Page $id has length ${page.length}, '
          'but $pageSizeInBytes is expected.');
    }
    _pages[id] = page;
  }
}


/**
 * [PageManager] allows to allocate, read, write and free [Uint8List] pages.
 */
abstract class PageManager {
  /**
   * The size of pages provided by this [PageManager].
   */
  int get pageSizeInBytes;

  /**
   * Allocates a new page and returns its identifier.
   */
  int alloc();

  /**
   * Frees the page with the given identifier.
   */
  void free(int id);

  /**
   * Reads the page with the given identifier and returns its content.
   *
   * An internal representation of the page is returned, any changes made to it
   * may be accessible to other clients reading the same page.
   */
  Uint8List read(int id);

  /**
   * Writes the given page.
   */
  void write(int id, Uint8List page);
}


/**
 * A [NodeManager] that keeps nodes in [PageManager].
 */
class PageNodeManager<K, V> implements NodeManager<K, V, int> {
  static const int _INDEX_OFFSET_DATA = 4;
  static const int _INDEX_OFFSET_KEY_COUNT = 0;
  static const int _LEAF_OFFSET_DATA = 4;
  static const int _LEAF_OFFSET_KEY_COUNT = 0;

  final Set<int> _indexPages = new HashSet<int>();
  Codec<K> _keyCodec;
  final Set<int> _leafPages = new HashSet<int>();
  PageManager _pageManager;
  Codec<V> _valueCodec;

  PageNodeManager(this._pageManager, this._keyCodec, this._valueCodec);

  @override
  int get maxIndexKeys {
    int keySize = _keyCodec.sizeInBytes;
    int childSize = 4;
    int dataSize = _pageManager.pageSizeInBytes - _INDEX_OFFSET_DATA;
    return (dataSize - childSize) ~/ (keySize + childSize);
  }

  @override
  int get maxLeafKeys {
    int keySize = _keyCodec.sizeInBytes;
    int valueSize = _valueCodec.sizeInBytes;
    int dataSize = _pageManager.pageSizeInBytes - _INDEX_OFFSET_DATA;
    return dataSize ~/ (keySize + valueSize);
  }

  @override
  int createIndex() {
    int id = _pageManager.alloc();
    _indexPages.add(id);
    return id;
  }

  @override
  int createLeaf() {
    int id = _pageManager.alloc();
    _leafPages.add(id);
    return id;
  }

  @override
  void delete(int id) {
    _pageManager.free(id);
    _indexPages.remove(id);
    _leafPages.remove(id);
  }

  @override
  bool isIndex(int id) {
    return _indexPages.contains(id);
  }

  @override
  IndexNodeData<K, int> readIndex(int id) {
    Uint8List page = _pageManager.read(id);
    // read header
    int keyCount;
    {
      ByteData data = new ByteData.view(page.buffer);
      keyCount = data.getInt32(_INDEX_OFFSET_KEY_COUNT);
    }
    // read keys/children
    List<K> keys = new List<K>();
    List<int> children = new List<int>();
    int keySize = _keyCodec.sizeInBytes;
    int offset = _INDEX_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // read child
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        int childPage = byteData.getUint32(0);
        children.add(childPage);
        offset += 4;
      }
      // read key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        K key = _keyCodec.decode(byteData);
        keys.add(key);
        offset += keySize;
      }
    }
    // read last child
    {
      ByteData byteData = new ByteData.view(page.buffer, offset);
      int childPage = byteData.getUint32(0);
      children.add(childPage);
    }
    // done
    return new IndexNodeData<K, int>(keys, children);
  }

  @override
  LeafNodeData<K, V> readLeaf(int id) {
    Uint8List page = _pageManager.read(id);
    // read header
    int keyCount;
    {
      ByteData data = new ByteData.view(page.buffer);
      keyCount = data.getInt32(_LEAF_OFFSET_KEY_COUNT);
    }
    // read keys/children
    List<K> keys = new List<K>();
    List<V> values = new List<V>();
    int keySize = _keyCodec.sizeInBytes;
    int valueSize = _valueCodec.sizeInBytes;
    int offset = _LEAF_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // read key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        K key = _keyCodec.decode(byteData);
        keys.add(key);
        offset += keySize;
      }
      // read value
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        V value = _valueCodec.decode(byteData);
        values.add(value);
        offset += valueSize;
      }
    }
    // done
    return new LeafNodeData<K, V>(keys, values);
  }

  @override
  void writeIndex(int id, IndexNodeData<K, int> data) {
    Uint8List page = new Uint8List(_pageManager.pageSizeInBytes);
    // write header
    int keyCount = data.keys.length;
    {
      ByteData byteData = new ByteData.view(page.buffer);
      byteData.setUint32(PageNodeManager._INDEX_OFFSET_KEY_COUNT, keyCount);
    }
    // write keys/children
    int keySize = _keyCodec.sizeInBytes;
    int offset = PageNodeManager._INDEX_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // write child
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        byteData.setUint32(0, data.children[i]);
        offset += 4;
      }
      // write key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        _keyCodec.encode(byteData, data.keys[i]);
        offset += keySize;
      }
    }
    // write last child
    {
      ByteData byteData = new ByteData.view(page.buffer, offset);
      byteData.setUint32(0, data.children.last);
    }
    // write page
    _pageManager.write(id, page);
  }

  @override
  void writeLeaf(int id, LeafNodeData<K, V> data) {
    Uint8List page = new Uint8List(_pageManager.pageSizeInBytes);
    // write header
    int keyCount = data.keys.length;
    {
      ByteData byteData = new ByteData.view(page.buffer);
      byteData.setUint32(PageNodeManager._LEAF_OFFSET_KEY_COUNT, keyCount);
    }
    // write keys/values
    int keySize = _keyCodec.sizeInBytes;
    int valueSize = _valueCodec.sizeInBytes;
    int offset = PageNodeManager._LEAF_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // write key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        _keyCodec.encode(byteData, data.keys[i]);
        offset += keySize;
      }
      // write value
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        _valueCodec.encode(byteData, data.values[i]);
        offset += valueSize;
      }
    }
    // write page
    _pageManager.write(id, page);
  }
}


/**
 * A [Codec] for unsigned 32-bit integers.
 */
class Uint32Codec implements Codec<int> {
  static const Uint32Codec INSTANCE = const Uint32Codec._();

  const Uint32Codec._();

  @override
  int get sizeInBytes => 4;

  @override
  int decode(ByteData buffer) {
    return buffer.getUint32(0);
  }

  @override
  void encode(ByteData buffer, int element) {
    buffer.setUint32(0, element);
  }
}
