// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint32List;
import 'dart:_internal' as internal;

// Hash table with open addressing that separates the index from keys/values.

abstract class _HashFieldBase {
  // Each occupied entry in _index is a fixed-size integer that encodes a pair:
  //   [ hash pattern for key | index of entry in _data ]
  // The hash pattern is based on hashCode, but is guaranteed to be non-zero.
  // The length of _index is always a power of two, and there is always at
  // least one unoccupied entry.
  // NOTE: When maps are deserialized, their _index and _hashMask is regenerated
  // lazily by _regenerateIndex.
  // TODO(koda): Consider also using null _index for tiny, linear-search tables.
  Uint32List _index = new Uint32List(_HashBase._INITIAL_INDEX_SIZE);

  // Cached in-place mask for the hash pattern component.
  int _hashMask = _HashBase._indexSizeToHashMask(_HashBase._INITIAL_INDEX_SIZE);

  // Fixed-length list of keys (set) or key/value at even/odd indices (map).
  List _data;

  // Length of _data that is used (i.e., keys + values for a map).
  int _usedData = 0;

  // Number of deleted keys.
  int _deletedKeys = 0;

  // Note: All fields are initialized in a single constructor so that the VM
  // recognizes they cannot hold null values. This makes a big (20%) performance
  // difference on some operations.
  _HashFieldBase(int dataSize) : this._data = new List(dataSize);
}

// Base class for VM-internal classes; keep in sync with _HashFieldBase.
abstract class _HashVMBase {
  Uint32List get _index native "LinkedHashMap_getIndex";
  void set _index(Uint32List value) native "LinkedHashMap_setIndex";

  int get _hashMask native "LinkedHashMap_getHashMask";
  void set _hashMask(int value) native "LinkedHashMap_setHashMask";

  List get _data native "LinkedHashMap_getData";
  void set _data(List value) native "LinkedHashMap_setData";

  int get _usedData native "LinkedHashMap_getUsedData";
  void set _usedData(int value) native "LinkedHashMap_setUsedData";

  int get _deletedKeys native "LinkedHashMap_getDeletedKeys";
  void set _deletedKeys(int value) native "LinkedHashMap_setDeletedKeys";
}

// This mixin can be applied to _HashFieldBase or _HashVMBase (for
// normal and VM-internalized classes, respectiveley), which provide the
// actual fields/accessors that this mixin assumes.
// TODO(koda): Consider moving field comments to _HashFieldBase.
abstract class _HashBase implements _HashVMBase {
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

  // On 32-bit, the top bits are wasted to avoid Mint allocation.
  // TODO(koda): Reclaim the bits by making the compiler treat hash patterns
  // as unsigned words.
  static int _indexSizeToHashMask(int indexSize) {
    int indexBits = indexSize.bitLength - 2;
    return internal.is64Bit
        ? (1 << (32 - indexBits)) - 1
        : (1 << (30 - indexBits)) - 1;
  }

  static int _hashPattern(int fullHash, int hashMask, int size) {
    final int maskedHash = fullHash & hashMask;
    // TODO(koda): Consider keeping bit length and use left shift.
    return (maskedHash == 0) ? (size >> 1) : maskedHash * (size >> 1);
  }

  // Linear probing.
  static int _firstProbe(int fullHash, int sizeMask) {
    final int i = fullHash & sizeMask;
    // Light, fast shuffle to mitigate bad hashCode (e.g., sequential).
    return ((i << 1) + i) & sizeMask;
  }

  static int _nextProbe(int i, int sizeMask) => (i + 1) & sizeMask;

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

class _OperatorEqualsAndHashCode {
  int _hashCode(e) => e.hashCode;
  bool _equals(e1, e2) => e1 == e2;
}

class _IdenticalAndIdentityHashCode {
  int _hashCode(e) => identityHashCode(e);
  bool _equals(e1, e2) => identical(e1, e2);
}

// VM-internalized implementation of a default-constructed LinkedHashMap.
class _InternalLinkedHashMap<K, V> extends _HashVMBase
    with
        MapMixin<K, V>,
        _LinkedHashMapMixin<K, V>,
        _HashBase,
        _OperatorEqualsAndHashCode
    implements LinkedHashMap<K, V> {
  _InternalLinkedHashMap() {
    _index = new Uint32List(_HashBase._INITIAL_INDEX_SIZE);
    _hashMask = _HashBase._indexSizeToHashMask(_HashBase._INITIAL_INDEX_SIZE);
    _data = new List(_HashBase._INITIAL_INDEX_SIZE);
    _usedData = 0;
    _deletedKeys = 0;
  }
}

abstract class _LinkedHashMapMixin<K, V> implements _HashVMBase {
  int _hashCode(e);
  bool _equals(e1, e2);
  int get _checkSum;
  bool _isModifiedSince(List oldData, int oldCheckSum);

  int get length => (_usedData >> 1) - _deletedKeys;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  void _rehash() {
    if ((_deletedKeys << 2) > _usedData) {
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
      // Use _data.length, since _index might be null.
      _init(_data.length, _hashMask, null, 0);
    }
  }

  // Allocate new _index and _data, and optionally copy existing contents.
  void _init(int size, int hashMask, List oldData, int oldUsed) {
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

  int _getIndexLength() {
    return (_index == null) ? _regenerateIndex() : _index.length;
  }

  int _regenerateIndex() {
    assert(_index == null);
    _index = new Uint32List(_data.length);
    assert(_hashMask == 0);
    _hashMask = _HashBase._indexSizeToHashMask(_index.length);
    final int tmpUsed = _usedData;
    _usedData = 0;
    for (int i = 0; i < tmpUsed; i += 2) {
      // TODO(koda): Avoid redundant equality tests and stores into _data.
      this[_data[i]] = _data[i + 1];
    }
    return _index.length;
  }

  void _insert(K key, V value, int hashPattern, int i) {
    if (_usedData == _data.length) {
      _rehash();
      this[key] = value;
    } else {
      assert(1 <= hashPattern && hashPattern < (1 << 32));
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
        if (firstDeleted < 0) {
          firstDeleted = i;
        }
      } else {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
            return d + 1;
          }
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return firstDeleted >= 0 ? -firstDeleted : -i;
  }

  void operator []=(K key, V value) {
    final int size = _getIndexLength();
    final int sizeMask = size - 1;
    final int fullHash = _hashCode(key);
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
    final int size = _getIndexLength();
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
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
    final int size = _getIndexLength();
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
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
    final int size = _getIndexLength();
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int entry = hashPattern ^ pair;
        if (entry < maxEntries) {
          final int d = entry << 1;
          if (_equals(key, _data[d])) {
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

  V operator [](Object key) {
    var v = _getValueOrData(key);
    return identical(_data, v) ? null : v;
  }

  bool containsValue(Object value) {
    for (var v in values) {
      // Spec. says this should always use "==", also for identity maps, etc.
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

class _CompactLinkedIdentityHashMap<K, V> extends _HashFieldBase
    with
        MapMixin<K, V>,
        _LinkedHashMapMixin<K, V>,
        _HashBase,
        _IdenticalAndIdentityHashCode
    implements LinkedHashMap<K, V> {
  _CompactLinkedIdentityHashMap() : super(_HashBase._INITIAL_INDEX_SIZE);
}

class _CompactLinkedCustomHashMap<K, V> extends _HashFieldBase
    with MapMixin<K, V>, _LinkedHashMapMixin<K, V>, _HashBase
    implements LinkedHashMap<K, V> {
  final _equality;
  final _hasher;
  final _validKey;

  // TODO(koda): Ask gbracha why I cannot have fields _equals/_hashCode.
  int _hashCode(e) => _hasher(e);
  bool _equals(e1, e2) => _equality(e1, e2);

  bool containsKey(Object o) => _validKey(o) ? super.containsKey(o) : false;
  V operator [](Object o) => _validKey(o) ? super[o] : null;
  V remove(Object o) => _validKey(o) ? super.remove(o) : null;

  _CompactLinkedCustomHashMap(this._equality, this._hasher, validKey)
      : _validKey = (validKey != null) ? validKey : new _TypeTest<K>().test,
        super(_HashBase._INITIAL_INDEX_SIZE);
}

// Iterates through _data[_offset + _step], _data[_offset + 2*_step], ...
// and checks for concurrent modification.
class _CompactIterable<E> extends IterableBase<E> {
  final _table;
  final List _data;
  final int _len;
  final int _offset;
  final int _step;

  _CompactIterable(
      this._table, this._data, this._len, this._offset, this._step);

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

  _CompactIterator(table, this._data, this._len, this._offset, this._step)
      : _table = table,
        _checkSum = table._checkSum;

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
class _CompactLinkedHashSet<E> extends _HashFieldBase
    with _HashBase, _OperatorEqualsAndHashCode, SetMixin<E>
    implements LinkedHashSet<E> {
  _CompactLinkedHashSet() : super(_HashBase._INITIAL_INDEX_SIZE >> 1) {
    assert(_HashBase._UNUSED_PAIR == 0);
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
      _init(_index.length, _hashMask, null, 0);
    }
  }

  void _init(int size, int hashMask, List oldData, int oldUsed) {
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

  bool add(E key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int firstDeleted = -1;
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair == _HashBase._DELETED_PAIR) {
        if (firstDeleted < 0) {
          firstDeleted = i;
        }
      } else {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
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
      assert(1 <= hashPattern && hashPattern < (1 << 32));
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
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
          return _data[d]; // Note: Must return the existing key.
        }
      }
      i = _HashBase._nextProbe(i, sizeMask);
      pair = _index[i];
    }
    return _data;
  }

  E lookup(Object key) {
    var k = _getKeyOrData(key);
    return identical(_data, k) ? null : k;
  }

  bool contains(Object key) => !identical(_data, _getKeyOrData(key));

  bool remove(Object key) {
    final int size = _index.length;
    final int sizeMask = size - 1;
    final int maxEntries = size >> 1;
    final int fullHash = _hashCode(key);
    final int hashPattern = _HashBase._hashPattern(fullHash, _hashMask, size);
    int i = _HashBase._firstProbe(fullHash, sizeMask);
    int pair = _index[i];
    while (pair != _HashBase._UNUSED_PAIR) {
      if (pair != _HashBase._DELETED_PAIR) {
        final int d = hashPattern ^ pair;
        if (d < maxEntries && _equals(key, _data[d])) {
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

  Iterator<E> get iterator =>
      new _CompactIterator<E>(this, _data, _usedData, -1, 1);

  // Returns a set of the same type, although this
  // is not required by the spec. (For instance, always using an identity set
  // would be technically correct, albeit surprising.)
  Set<E> toSet() => new _CompactLinkedHashSet<E>()..addAll(this);
}

class _CompactLinkedIdentityHashSet<E> extends _CompactLinkedHashSet<E>
    with _IdenticalAndIdentityHashCode {
  Set<E> toSet() => new _CompactLinkedIdentityHashSet<E>()..addAll(this);
}

class _CompactLinkedCustomHashSet<E> extends _CompactLinkedHashSet<E> {
  final _equality;
  final _hasher;
  final _validKey;

  int _hashCode(e) => _hasher(e);
  bool _equals(e1, e2) => _equality(e1, e2);

  bool contains(Object o) => _validKey(o) ? super.contains(o) : false;
  E lookup(Object o) => _validKey(o) ? super.lookup(o) : null;
  bool remove(Object o) => _validKey(o) ? super.remove(o) : false;

  _CompactLinkedCustomHashSet(this._equality, this._hasher, validKey)
      : _validKey = (validKey != null) ? validKey : new _TypeTest<E>().test;

  Set<E> toSet() =>
      new _CompactLinkedCustomHashSet<E>(_equality, _hasher, _validKey)
        ..addAll(this);
}
