// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index.page_node_manager;

import 'dart:collection';
import 'dart:typed_data';

import 'b_plus_tree.dart';


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
    for (int codeUnit in value.codeUnits) {
      buffer.setUint16(offset, codeUnit);
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
  static const int INDEX_OFFSET_DATA = 4;
  static const int INDEX_OFFSET_KEY_COUNT = 0;
  static const int LEAF_OFFSET_DATA = 4;
  static const int LEAF_OFFSET_KEY_COUNT = 0;

  final Set<int> indexPages = new HashSet<int>();
  Codec<K> keyCodec;
  final Set<int> leafPages = new HashSet<int>();
  PageManager pageManager;
  Codec<V> valueCodec;

  PageNodeManager(this.pageManager, this.keyCodec, this.valueCodec);

  @override
  int createIndex() {
    int id = pageManager.alloc();
    indexPages.add(id);
    return id;
  }

  @override
  int createLeaf() {
    int id = pageManager.alloc();
    leafPages.add(id);
    return id;
  }

  @override
  void delete(int id) {
    pageManager.free(id);
    indexPages.remove(id);
    leafPages.remove(id);
  }

  @override
  bool isIndex(int id) {
    return indexPages.contains(id);
  }

  @override
  IndexNodeData<K, int> readIndex(int id) {
    Uint8List page = pageManager.read(id);
    // read header
    int keyCount;
    {
      ByteData data = new ByteData.view(page.buffer);
      keyCount = data.getInt32(INDEX_OFFSET_KEY_COUNT);
    }
    // read keys/children
    List<K> keys = new List<K>();
    List<int> children = new List<int>();
    int keySize = keyCodec.sizeInBytes;
    int offset = INDEX_OFFSET_DATA;
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
        K key = keyCodec.decode(byteData);
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
    Uint8List page = pageManager.read(id);
    // read header
    int keyCount;
    {
      ByteData data = new ByteData.view(page.buffer);
      keyCount = data.getInt32(LEAF_OFFSET_KEY_COUNT);
    }
    // read keys/children
    List<K> keys = new List<K>();
    List<V> values = new List<V>();
    int keySize = keyCodec.sizeInBytes;
    int valueSize = valueCodec.sizeInBytes;
    int offset = LEAF_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // read key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        K key = keyCodec.decode(byteData);
        keys.add(key);
        offset += keySize;
      }
      // read value
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        V value = valueCodec.decode(byteData);
        values.add(value);
        offset += valueSize;
      }
    }
    // done
    return new LeafNodeData<K, V>(keys, values);
  }

  @override
  void writeIndex(int id, IndexNodeData<K, int> data) {
    Uint8List page = new Uint8List(pageManager.pageSizeInBytes);
    // write header
    int keyCount = data.keys.length;
    {
      ByteData byteData = new ByteData.view(page.buffer);
      byteData.setUint32(INDEX_OFFSET_KEY_COUNT, keyCount);
    }
    // write keys/children
    int keySize = keyCodec.sizeInBytes;
    int offset = INDEX_OFFSET_DATA;
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
        keyCodec.encode(byteData, data.keys[i]);
        offset += keySize;
      }
    }
    // write last child
    {
      ByteData byteData = new ByteData.view(page.buffer, offset);
      byteData.setUint32(0, data.children.last);
    }
    // write page
    pageManager.write(id, page);
  }

  @override
  void writeLeaf(int id, LeafNodeData<K, V> data) {
    Uint8List page = new Uint8List(pageManager.pageSizeInBytes);
    // write header
    int keyCount = data.keys.length;
    {
      ByteData byteData = new ByteData.view(page.buffer);
      byteData.setUint32(LEAF_OFFSET_KEY_COUNT, keyCount);
    }
    // write keys/values
    int keySize = keyCodec.sizeInBytes;
    int valueSize = valueCodec.sizeInBytes;
    int offset = LEAF_OFFSET_DATA;
    for (int i = 0; i < keyCount; i++) {
      // write key
      {
        ByteData byteData = new ByteData.view(page.buffer, offset, keySize);
        keyCodec.encode(byteData, data.keys[i]);
        offset += keySize;
      }
      // write value
      {
        ByteData byteData = new ByteData.view(page.buffer, offset);
        valueCodec.encode(byteData, data.values[i]);
        offset += valueSize;
      }
    }
    // write page
    pageManager.write(id, page);
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
