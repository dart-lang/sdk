// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// Hash table with open addressing that separates the index from keys/values.
abstract class _HashBase {
  // Each occupied entry in _index is a fixed-size integer that encodes a pair:
  //   [ hash pattern for key | index of entry in _data ]
  // The hash pattern is based on hashCode, but is guaranteed to be non-zero.
  // The length of _index is always a power of two, and there is always at
  // least one unoccupied entry.
  Uint32List _index;

  // The number of bits used for each component is determined by table size.
  // The length of _index is twice the number of entries in _data, and both
  // are doubled when _data is full. Thus, _index will have a max load factor
  // of 1/2, which enables one more bit to be used for the hash.
  // TODO(koda): Consider growing _data by factor sqrt(2), twice as often. 
  static const int _INITIAL_INDEX_BITS = 3;
  static const int _INITIAL_INDEX_SIZE = 1 << (_INITIAL_INDEX_BITS + 1);
  
  // Unused and deleted entries are marked by 0 and 1, respectively.
  static const int _UNUSED_PAIR = 0;
  static const int _DELETED_PAIR = 1;
  
  // Cached in-place mask for the hash pattern component. On 32-bit, the top
  // bits are wasted to avoid Mint allocation.
  // TODO(koda): Reclaim the bits by making the compiler treat hash patterns
  // as unsigned words.
  int _hashMask = int.is64Bit() ?
      (1 << (32 - _INITIAL_INDEX_BITS)) - 1 :
      (1 << (30 - _INITIAL_INDEX_BITS)) - 1;
  
  static int _hashPattern(int fullHash, int hashMask, int size) =>
      // TODO(koda): Consider keeping bit length and use left shift.
      (fullHash == 0) ? (size >> 1) : (fullHash & hashMask) * (size >> 1);

  // Linear probing.
  static int _firstProbe(int fullHash, int sizeMask) {
    final int i = fullHash & sizeMask;
    // Light, fast shuffle to mitigate bad hashCode (e.g., sequential).
    return ((i << 1) + i) & sizeMask;
  }
  static int _nextProbe(int i, int sizeMask) => (i + 1) & sizeMask;
  
  // Fixed-length list of keys (set) or key/value at even/odd indices (map).
  List _data;
  // Length of _data that is used (i.e., keys + values for a map).
  int _usedData = 0;
  // Number of deleted keys.
  int _deletedKeys = 0;
  
  // A self-loop is used to mark a deleted key or value.
  static bool _isDeleted(List data, Object keyOrValue) =>
      identical(keyOrValue, data);
  static void _setDeletedAt(List data, int d) {
    data[d] = data;
  }

  // Concurrent modification detection relies on this checksum monotonically
  // increasing between reallocations of _data.
  int get _checkSum => _usedData + _deletedKeys;
  bool _isModifiedSince(List oldData, int oldCheckSum) =>
      !identical(_data, oldData) || (_checkSum != oldCheckSum);
}

// Map with iteration in insertion order (hence "Linked"). New keys are simply
// appended to _data.
class _CompactLinkedHashMap<K, V>
    extends MapBase<K, V> with _HashBase
    implements HashMap<K, V>, LinkedHashMap<K, V> {

  _CompactLinkedHashMap() {
    assert(_HashBase._UNUSED_PAIR == 0);
    _index = new Uint32List(_HashBase._INITIAL_INDEX_SIZE);
    _data = new List(_HashBase._INITIAL_INDEX_SIZE);
  }
  
  int get length => (_usedData >> 1) - _deletedKeys;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
  
  void _rehash() {
    if ((_deletedKeys << 1) > _usedData) {
      // TODO(koda): Consider shrinking.
      // TODO(koda): Consider in-place compaction and more costly CME check.
      _init(_index.length, _hashMask, _data, _usedData);
    } else {
      // TODO(koda): Support 32->64 bit transition (and adjust _hashMask).
      _init(_index.length << 1, _hashMask >> 1, _data, _usedData);
    }
  }
  
  void clear() {
    if (!isEmpty) {
      _init(_index.length, _hashMask);
    }
  }

  // Allocate new _index and _data, and optionally copy existing contents.
  void _init(int size, int hashMask, [List oldData, int oldUsed]) {
    assert(size & (size - 1) == 0);
    assert(_HashBase._UNUSED_PAIR == 0);
    _index = new Uint32List(size);
    _hashMask = hashMask;
    _data = new List(size);
    _usedData = 0;
    _deletedKeys = 0;
    if (oldData != null) {
      for (int i = 0; i < oldUsed; i += 2) {
        var key = oldData[i];
        if (!_HashBase._isDeleted(oldData, key)) {
          // TODO(koda): While there are enough hash bits, avoid hashCode calls.
          this[key] = oldData[i + 1];
        }
      }
    }
  }
  
  void _insert(K key, V value, int hashPattern, int i) {
    if (_usedData == _data.length) {
      _rehash();
      this[key] = value;
    } else {
      assert(0 <= hashPattern && hashPattern <  (1 << 32));
      final int index = _usedData >> 1;
      assert((index & hashPattern) == 0);
      _index[i] = hashPattern | index;
      _data[_usedData++] = key;
      _data[_usedData++] = value;
    }
  }
  
  // If key is present, returns the index of the value in _data, else returns
  // the negated insertion point in _index.
  int _findValueOrInsertPoint(K key, int fullHash, int hashPattern, int size) {
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int firstDeleted = -1;
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair == _HashBase._DELETED_PAIR) {
        if (firstDeleted < 0){
          firstDeleted = i;
        }
      } else {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (key == _data[d]) {
            return d + 1;
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return firstDeleted >= 0 ? -firstDeleted : -i;
  }
  
  void operator[]=(K key, V value) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    final int d = _findValueOrInsertPoint(key, fullHash, hashPattern, size);
    if (d > 0) {
      _data[d] = value;
    } else {
      final int i = -d;
      _insert(key, value, hashPattern, i);
    }
  }
  
  V putIfAbsent(K key, V ifAbsent()) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    final int d = _findValueOrInsertPoint(key, fullHash, hashPattern, size);
    if (d > 0) {
      return _data[d];
    }
    // 'ifAbsent' is allowed to modify the map.
    List oldData = _data;
    int oldCheckSum = _checkSum;
    V value = ifAbsent();
    if (_isModifiedSince(oldData, oldCheckSum)) {
      this[key] = value;
    } else {
      final int i = -d;
      _insert(key, value, hashPattern, i);
    }
    return value;
  }
  
  V remove(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (key == _data[d]) {
            _index[i] = _HashBase._DELETED_PAIR;
            _HashBase._setDeletedAt(_data, d);
            V value = _data[d + 1];
            _HashBase._setDeletedAt(_data, d + 1);
            ++_deletedKeys;
            return value;
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return null;
  }
  
  // If key is absent, return _data (which is never a value).
  Object _getValueOrData(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (key == _data[d]) {
            return _data[d + 1];
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return _data;
  }
  
  bool containsKey(Object key) => !identical(_data, _getValueOrData(key));
  
  V operator[](Object key) {
    var v = _getValueOrData(key);
    return identical(_data, v) ? null : v;
  }
  
  bool containsValue(Object value) {
    for (var v in values) {
      if (v == value) {
        return true;
      }
    }
    return false;
  }

  void forEach(void f(K key, V value)) {
    var ki = keys.iterator;
    var vi = values.iterator;
    while (ki.moveNext()) {
      vi.moveNext();
      f(ki.current, vi.current);
    }
  }

  Iterable<K> get keys =>
      new _CompactIterable<K>(this, _data, _usedData, -2, 2);
  Iterable<V> get values =>
      new _CompactIterable<V>(this, _data, _usedData, -1, 2);
}

// Iterates through _data[_offset + _step], _data[_offset + 2*_step], ...
// and checks for concurrent modification.
class _CompactIterable<E> extends IterableBase<E> {
  final _table;
  final List _data;
  final int _len;
  final int _offset;
  final int _step;

  _CompactIterable(this._table, this._data, this._len,
                   this._offset, this._step);

  Iterator<E> get iterator =>
      new _CompactIterator<E>(_table, _data, _len, _offset, _step);

  int get length => _table.length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}

class _CompactIterator<E> implements Iterator<E> {
  final _table;
  final List _data;
  final int _len;
  int _offset;
  final int _step;
  final int _checkSum;
  E current;

  _CompactIterator(table, this._data, this._len, this._offset, this._step) :
      _table = table, _checkSum = table._checkSum;

  bool moveNext() {
    if (_table._isModifiedSince(_data, _checkSum)) {
      throw new ConcurrentModificationError(_table);
    }
    do {
      _offset += _step;
    } while (_offset < _len && _HashBase._isDeleted(_data, _data[_offset]));
    if (_offset < _len) {
      current = _data[_offset];
      return true;
    } else {
      current = null;
      return false;
    }
  }
}

// Set implementation, analogous to _CompactLinkedHashMap.
class _CompactLinkedHashSet<K>
    extends SetBase<K> with _HashBase
    implements HashSet<K>, LinkedHashSet<K> {

  _CompactLinkedHashSet() {
    assert(_HashBase._UNUSED_PAIR == 0);
    _index = new Uint32List(_HashBase._INITIAL_INDEX_SIZE);
    _data = new List(_HashBase._INITIAL_INDEX_SIZE >> 1);
  }

  int get length => _usedData - _deletedKeys;

  void _rehash() {
    if ((_deletedKeys << 1) > _usedData) {
      _init(_index.length, _hashMask, _data, _usedData);
    } else {
      _init(_index.length << 1, _hashMask >> 1, _data, _usedData);
    }
  }
  
  void clear() {
    if (!isEmpty) {
      _init(_index.length, _hashMask);
    }
  }
  
  void _init(int size, int hashMask, [List oldData, int oldUsed]) {
    _index = new Uint32List(size);
    _hashMask = hashMask;
    _data = new List(size >> 1);
    _usedData = 0;
    _deletedKeys = 0;
    if (oldData != null) {
      for (int i = 0; i < oldUsed; i += 1) {
        var key = oldData[i];
        if (!_HashBase._isDeleted(oldData, key)) {
          add(key);
        }
      }
    }
  }

  bool add(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int firstDeleted = -1;
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair == _HashBase._DELETED_PAIR) {
        if (firstDeleted < 0){
          firstDeleted = i;
        }
      } else {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && key == _data[d]) {
          return false;
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    if (_usedData == _data.length) {
      _rehash();
      add(key);
    } else {
      final int insertionPoint = (firstDeleted >= 0) ? firstDeleted : i;
      assert(0 <= hashPattern && hashPattern < (1 << 32));
      assert((hashPattern & _usedData) == 0);
      _index[insertionPoint] = hashPattern | _usedData;
      _data[_usedData++] = key;
    }
    return true;
  }
  
  // If key is absent, return _data (which is never a value).
  Object _getKeyOrData(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && key == _data[d]) {
          return _data[d];  // Note: Must return the existing key.
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return _data;    
  }

  K lookup(Object key) {
    var k = _getKeyOrData(key);
    return identical(_data, k) ? null : k;
  }
  
  bool contains(Object key) => !identical(_data, _getKeyOrData(key));

  bool remove(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = key.hashCode;
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && key == _data[d]) {
          _index[i] = _HashBase._DELETED_PAIR;
          _HashBase._setDeletedAt(_data, d);
          ++_deletedKeys;
          return true;
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return false;
  }
                                                
  Iterator<K> get iterator =>
      new _CompactIterator<K>(this, _data, _usedData, -1, 1);

  Set<K> toSet() => new Set<K>()..addAll(this);  
}
