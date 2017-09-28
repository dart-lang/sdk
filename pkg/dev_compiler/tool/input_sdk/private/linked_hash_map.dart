// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Efficient JavaScript based implementation of a linked hash map used as a
// backing map for constant maps and the [LinkedHashMap] patch

part of dart._js_helper;

// DDC-specific, just use Object-backed maps
//const _USE_ES6_MAPS = const bool.fromEnvironment("dart2js.use.es6.maps");

class JsLinkedHashMap<K, V> implements LinkedHashMap<K, V>, InternalMap<K, V> {
  @notNull
  int _length = 0;

  // The hash map contents are divided into three parts: one part for
  // string keys, one for numeric keys, and one for the rest. String
  // and numeric keys map directly to their linked cells, but the rest
  // of the entries are stored in bucket lists of the form:
  //
  //    [cell-0, cell-1, ...]
  //
  // where all keys in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // The keys and values are stored in cells that are linked together
  // to form a double linked list.
  LinkedHashMapCell<K, V> _first;
  LinkedHashMapCell<K, V> _last;

  // We track the number of modifications done to the key set of the
  // hash map to be able to throw when the map is modified while being
  // iterated over.
  int _modifications = 0;

//  static bool get _supportsEs6Maps {
//    return JS('returns:bool;depends:none;effects:none;throws:never;gvn:true',
//              'typeof Map != "undefined"');
//  }

  JsLinkedHashMap();

  /// If ES6 Maps are available returns a linked hash-map backed by an ES6 Map.
//  @ForceInline()
  factory JsLinkedHashMap.es6() {
//    return (_USE_ES6_MAPS && JsLinkedHashMap._supportsEs6Maps)
//        ? new Es6LinkedHashMap<K, V>()
//        : new JsLinkedHashMap<K, V>();
    return new JsLinkedHashMap<K, V>();
  }

  @notNull
  int get length => _length;
  @notNull
  bool get isEmpty => _length == 0;
  @notNull
  bool get isNotEmpty => !isEmpty;

  Iterable<K> get keys {
    return new LinkedHashMapKeyIterable<K>(this);
  }

  Iterable<V> get values {
    return new MappedIterable<K, V>(keys, (each) => this[each]);
  }

  @notNull
  bool containsKey(Object key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) return false;
      return _containsTableEntry(strings, key);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) return false;
      return _containsTableEntry(nums, key);
    } else {
      return internalContainsKey(key);
    }
  }

  @notNull
  bool internalContainsKey(Object key) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, key);
    return internalFindBucketIndex(bucket, key) >= 0;
  }

  bool containsValue(Object value) {
    return keys.any((each) => this[each] == value);
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  V operator [](Object key) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) return null;
      LinkedHashMapCell/*<K, V>*/ cell = _getTableCell(strings, key);
      return (cell == null) ? null : cell.hashMapCellValue;
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) return null;
      LinkedHashMapCell/*<K, V>*/ cell = _getTableCell(nums, key);
      return (cell == null) ? null : cell.hashMapCellValue;
    } else {
      return internalGet(key);
    }
  }

  V internalGet(Object key) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, key);
    int index = internalFindBucketIndex(bucket, key);
    if (index < 0) return null;
    LinkedHashMapCell/*<K, V>*/ cell = JS('var', '#[#]', bucket, index);
    return cell.hashMapCellValue;
  }

  void operator []=(K key, V value) {
    if (_isStringKey(key)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      _addHashTableEntry(strings, key, value);
    } else if (_isNumericKey(key)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      _addHashTableEntry(nums, key, value);
    } else {
      internalSet(key, value);
    }
  }

  void internalSet(K key, V value) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = internalComputeHashCode(key);
    var bucket = _getTableBucket(rest, hash);
    if (bucket == null) {
      LinkedHashMapCell/*<K, V>*/ cell = _newLinkedCell(key, value);
      _setTableEntry(rest, hash, JS('var', '[#]', cell));
    } else {
      int index = internalFindBucketIndex(bucket, key);
      if (index >= 0) {
        LinkedHashMapCell/*<K, V>*/ cell = JS('var', '#[#]', bucket, index);
        cell.hashMapCellValue = value;
      } else {
        LinkedHashMapCell/*<K, V>*/ cell = _newLinkedCell(key, value);
        JS('void', '#.push(#)', bucket, cell);
      }
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  V remove(Object key) {
    if (_isStringKey(key)) {
      return _removeHashTableEntry(_strings, key);
    } else if (_isNumericKey(key)) {
      return _removeHashTableEntry(_nums, key);
    } else {
      return internalRemove(key);
    }
  }

  V internalRemove(Object key) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, key);
    int index = internalFindBucketIndex(bucket, key);
    if (index < 0) return null;
    // Use splice to remove the [cell] element at the index and
    // unlink the cell before returning its value.
    LinkedHashMapCell/*<K, V>*/ cell =
        JS('var', '#.splice(#, 1)[0]', bucket, index);
    _unlinkCell(cell);
    // TODO(kasperl): Consider getting rid of the bucket list when
    // the length reaches zero.
    return cell.hashMapCellValue;
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _first = _last = null;
      _length = 0;
      _modified();
    }
  }

  void forEach(void action(K key, V value)) {
    LinkedHashMapCell/*<K, V>*/ cell = _first;
    int modifications = _modifications;
    while (cell != null) {
      action(cell.hashMapCellKey, cell.hashMapCellValue);
      if (modifications != _modifications) {
        throw new ConcurrentModificationError(this);
      }
      cell = cell._next;
    }
  }

  void _addHashTableEntry(var table, K key, V value) {
    LinkedHashMapCell/*<K, V>*/ cell = _getTableCell(table, key);
    if (cell == null) {
      _setTableEntry(table, key, _newLinkedCell(key, value));
    } else {
      cell.hashMapCellValue = value;
    }
  }

  V _removeHashTableEntry(var table, Object key) {
    if (table == null) return null;
    LinkedHashMapCell/*<K, V>*/ cell = _getTableCell(table, key);
    if (cell == null) return null;
    _unlinkCell(cell);
    _deleteTableEntry(table, key);
    return cell.hashMapCellValue;
  }

  void _modified() {
    // Value cycles after 2^30 modifications so that modification counts are
    // always unboxed (Smi) values. Modification detection will be missed if you
    // make exactly some multiple of 2^30 modifications between advances of an
    // iterator.
    _modifications = (_modifications + 1) & 0x3ffffff;
  }

  // Create a new cell and link it in as the last one in the list.
  LinkedHashMapCell/*<K, V>*/ _newLinkedCell(K key, V value) {
    LinkedHashMapCell/*<K, V>*/ cell =
        new LinkedHashMapCell/*<K, V>*/(key, value);
    if (_first == null) {
      _first = _last = cell;
    } else {
      LinkedHashMapCell/*<K, V>*/ last = _last;
      cell._previous = last;
      _last = last._next = cell;
    }
    _length++;
    _modified();
    return cell;
  }

  // Unlink the given cell from the linked list of cells.
  void _unlinkCell(LinkedHashMapCell/*<K, V>*/ cell) {
    LinkedHashMapCell/*<K, V>*/ previous = cell._previous;
    LinkedHashMapCell/*<K, V>*/ next = cell._next;
    if (previous == null) {
      assert(cell == _first);
      _first = next;
    } else {
      previous._next = next;
    }
    if (next == null) {
      assert(cell == _last);
      _last = previous;
    } else {
      next._previous = previous;
    }
    _length--;
    _modified();
  }

  @notNull
  static bool _isStringKey(var key) {
    return key is String;
  }

  @notNull
  static bool _isNumericKey(var key) {
    // Only treat unsigned 30-bit integers as numeric keys. This way,
    // we avoid converting them to strings when we use them as keys in
    // the JavaScript hash table object.
    return key is num && JS('bool', '(# & 0x3ffffff) === #', key, key);
  }

  int internalComputeHashCode(var key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & 0x3ffffff', key.hashCode);
  }

  List<dynamic/*=LinkedHashMapCell<K, V>*/ > _getBucket(var table, var key) {
    var hash = internalComputeHashCode(key);
    return _getTableBucket(table, hash);
  }

  @notNull
  int internalFindBucketIndex(var bucket, var key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell/*<K, V>*/ cell = JS('var', '#[#]', bucket, i);
      if (cell.hashMapCellKey == key) return i;
    }
    return -1;
  }

  String toString() => Maps.mapToString(this);

  /*=LinkedHashMapCell<K, V>*/ _getTableCell(var table, var key) {
    return JS('var', '#[#]', table, key);
  }

  /*=List<LinkedHashMapCell<K, V>>*/ _getTableBucket(var table, var key) {
    return JS('var', '#[#]', table, key);
  }

  void _setTableEntry(var table, var key, var value) {
    assert(value != null);
    JS('void', '#[#] = #', table, key, value);
  }

  void _deleteTableEntry(var table, var key) {
    JS('void', 'delete #[#]', table, key);
  }

  @notNull
  bool _containsTableEntry(var table, var key) {
    LinkedHashMapCell/*<K, V>*/ cell = _getTableCell(table, key);
    return cell != null;
  }

  _newHashTable() {
    // Create a new JavaScript object to be used as a hash table. Use
    // Object.create to avoid the properties on Object.prototype
    // showing up as entries.
    var table = JS('var', 'Object.create(null)');
    // Attempt to force the hash table into 'dictionary' mode by
    // adding a property to it and deleting it again.
    var temporaryKey = '<non-identifier-key>';
    _setTableEntry(table, temporaryKey, table);
    _deleteTableEntry(table, temporaryKey);
    return table;
  }
}

class Es6LinkedHashMap<K, V> extends JsLinkedHashMap<K, V> {
  @override
  /*=LinkedHashMapCell<K, V>*/ _getTableCell(var table, var key) {
    return JS('var', '#.get(#)', table, key);
  }

  @override
  /*=List<LinkedHashMapCell<K, V>>*/ _getTableBucket(var table, var key) {
    return JS('var', '#.get(#)', table, key);
  }

  @override
  void _setTableEntry(var table, var key, var value) {
    JS('void', '#.set(#, #)', table, key, value);
  }

  @override
  void _deleteTableEntry(var table, var key) {
    JS('void', '#.delete(#)', table, key);
  }

  @override
  bool _containsTableEntry(var table, var key) {
    return JS('bool', '#.has(#)', table, key);
  }

  @override
  _newHashTable() {
    return JS('var', 'new Map()');
  }
}

class LinkedHashMapCell<K, V> {
  final dynamic/*=K*/ hashMapCellKey;
  dynamic/*=V*/ hashMapCellValue;

  LinkedHashMapCell/*<K, V>*/ _next;
  LinkedHashMapCell/*<K, V>*/ _previous;

  LinkedHashMapCell(this.hashMapCellKey, this.hashMapCellValue);
}

class LinkedHashMapKeyIterable<E> extends EfficientLengthIterable<E> {
  final dynamic/*=JsLinkedHashMap<E, dynamic>*/ _map;
  LinkedHashMapKeyIterable(this._map);

  int get length => _map._length;
  bool get isEmpty => _map._length == 0;

  Iterator<E> get iterator {
    return new LinkedHashMapKeyIterator<E>(_map, _map._modifications);
  }

  bool contains(Object element) {
    return _map.containsKey(element);
  }

  void forEach(void f(E element)) {
    LinkedHashMapCell/*<E, dynamic>*/ cell = _map._first;
    int modifications = _map._modifications;
    while (cell != null) {
      f(cell.hashMapCellKey);
      if (modifications != _map._modifications) {
        throw new ConcurrentModificationError(_map);
      }
      cell = cell._next;
    }
  }
}

class LinkedHashMapKeyIterator<E> implements Iterator<E> {
  final dynamic/*=JsLinkedHashMap<E, dynamic>*/ _map;
  final int _modifications;
  LinkedHashMapCell/*<E, dynamic>*/ _cell;
  E _current;

  LinkedHashMapKeyIterator(this._map, this._modifications) {
    _cell = _map._first;
  }

  E get current => _current;

  bool moveNext() {
    if (_modifications != _map._modifications) {
      throw new ConcurrentModificationError(_map);
    } else if (_cell == null) {
      _current = null;
      return false;
    } else {
      _current = _cell.hashMapCellKey;
      _cell = _cell._next;
      return true;
    }
  }
}

class ImmutableMap<K, V> extends JsLinkedHashMap<K, V> {
  ImmutableMap(JSArray elements) {
    if (elements == null) return;
    for (var i = 0, end = elements.length - 1; i < end; i += 2) {
      super[JS('', '#[#]', elements, i)] = JS('', '#[#]', elements, i + 1);
    }
  }

  void operator []=(Object key, Object value) {
    throw _unsupported();
  }

  void addAll(Object other) => throw _unsupported();
  void clear() => throw _unsupported();
  V remove(Object key) => throw _unsupported();
  V putIfAbsent(Object key, Object ifAbsent()) => throw _unsupported();

  static Error _unsupported() =>
      new UnsupportedError("Cannot modify unmodifiable map");
}
