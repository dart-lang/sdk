// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:collection classes.
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show
        fillLiteralMap,
        fillLiteralSet,
        InternalMap,
        JsLinkedHashMap,
        JsIdentityLinkedHashMap,
        LinkedHashMapCell,
        LinkedHashMapKeyIterable,
        LinkedHashMapKeyIterator;

import 'dart:_internal' hide Symbol;

const int _mask30 = 0x3fffffff; // Low 30 bits.



@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap({
    bool equals(K key1, K key2)?,
    int hashCode(K key)?,
    bool isValidKey(potentialKey)?,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return JsLinkedHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return JsIdentityLinkedHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _LinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashMap.identity() = JsIdentityLinkedHashMap<K, V>;

  // Private factory constructor called by generated code for map literals.
  @pragma('dart2js:noInline')
  factory LinkedHashMap._literal(List keyValuePairs) {
    return fillLiteralMap(keyValuePairs, JsLinkedHashMap<K, V>());
  }

  // Private factory constructor called by generated code for map literals.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  factory LinkedHashMap._empty() {
    return JsLinkedHashMap<K, V>();
  }
}

// TODO(sra): Move to same library as JsLinkedHashMap and make the `internalXXX`
// names private.
base class _LinkedCustomHashMap<K, V> extends JsLinkedHashMap<K, V> {
  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;
  final bool Function(Object?) _validKey;

  _LinkedCustomHashMap(
    this._equals,
    this._hashCode,
    bool validKey(potentialKey)?,
  ) : _validKey = (validKey != null) ? validKey : ((v) => v is K);

  V? operator [](Object? key) {
    if (!_validKey(key)) return null;
    return super.internalGet(key);
  }

  void operator []=(K key, V value) {
    super.internalSet(key, value);
  }

  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    return super.internalContainsKey(key);
  }

  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    return super.internalRemove(key);
  }

  int internalComputeHashCode(key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', _hashCode(key), _mask30);
  }

  int internalFindBucketIndex(bucket, key) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      LinkedHashMapCell cell = JS('var', '#[#]', bucket, i);
      if (_equals(cell.hashMapCellKey, key)) return i;
    }
    return -1;
  }
}



@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet({
    bool equals(E e1, E e2)?,
    int hashCode(E e)?,
    bool isValidKey(potentialKey)?,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return _LinkedHashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _LinkedIdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return _LinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashSet.identity() = _LinkedIdentityHashSet<E>;

  // Private factory constructor called by generated code for set literals.
  @pragma('dart2js:noThrows')
  @pragma('dart2js:noInline')
  @pragma('dart2js:noSideEffects')
  factory LinkedHashSet._empty() => _LinkedHashSet<E>();

  // Private factory constructor called by generated code for set literals.
  @pragma('dart2js:noInline')
  factory LinkedHashSet._literal(List values) =>
      fillLiteralSet(values, _LinkedHashSet<E>());
}

base class _LinkedHashSet<E> extends _SetBase<E> implements LinkedHashSet<E> {
  int _length = 0;

  // The hash set contents are divided into three parts: one part for
  // string elements, one for numeric elements, and one for the
  // rest. String and numeric elements map directly to their linked
  // cells, but the rest of the entries are stored in bucket lists of
  // the form:
  //
  //    [cell-0, cell-1, ...]
  //
  // where all elements in the same bucket share the same hash code.
  var _strings;
  var _nums;
  var _rest;

  // The elements are stored in cells that are linked together
  // to form a double linked list.
  _LinkedHashSetCell? _first;
  _LinkedHashSetCell? _last;

  // We track the number of modifications done to the element set to
  // be able to throw when the set is modified while being iterated
  // over.
  int _modifications = 0;

  _LinkedHashSet();

  Set<E> _newSet() => _LinkedHashSet<E>();
  Set<R> _newSimilarSet<R>() => _LinkedHashSet<R>();

  void _unsupported(String operation) {
    throw 'LinkedHashSet: unsupported $operation';
  }

  // Iterable.
  Iterator<E> get iterator {
    return _LinkedHashSetIterator(this, _modifications);
  }

  int get length => _length;
  bool get isEmpty => _length == 0;
  bool get isNotEmpty => !isEmpty;

  bool contains(Object? object) {
    if (_isStringElement(object)) {
      var strings = _strings;
      if (strings == null) return false;
      _LinkedHashSetCell? cell = _getTableEntry(strings, object);
      return cell != null;
    } else if (_isNumericElement(object)) {
      var nums = _nums;
      if (nums == null) return false;
      _LinkedHashSetCell? cell = _getTableEntry(nums, object);
      return cell != null;
    } else {
      return _contains(object);
    }
  }

  bool _contains(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var bucket = _getBucket(rest, object);
    return _findBucketIndex(bucket, object) >= 0;
  }

  E? lookup(Object? object) {
    if (_isStringElement(object) || _isNumericElement(object)) {
      return this.contains(object) ? object as E : null;
    } else {
      return _lookup(object);
    }
  }

  E? _lookup(Object? object) {
    var rest = _rest;
    if (rest == null) return null;
    var bucket = _getBucket(rest, object);
    var index = _findBucketIndex(bucket, object);
    if (index < 0) return null;
    return JS<_LinkedHashSetCell>('', '#[#]', bucket, index)._element;
  }

  void forEach(void action(E element)) {
    _LinkedHashSetCell? cell = _first;
    int modifications = _modifications;
    while (cell != null) {
      action(cell._element);
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
      cell = cell._next;
    }
  }

  E get first {
    var first = _first;
    if (first == null) throw StateError("No elements");
    return first._element;
  }

  E get last {
    var last = _last;
    if (last == null) throw StateError("No elements");
    return last._element;
  }

  // Collection.
  bool add(E element) {
    if (_isStringElement(element)) {
      var strings = _strings;
      if (strings == null) _strings = strings = _newHashTable();
      return _addHashTableEntry(strings, element);
    } else if (_isNumericElement(element)) {
      var nums = _nums;
      if (nums == null) _nums = nums = _newHashTable();
      return _addHashTableEntry(nums, element);
    } else {
      return _add(element);
    }
  }

  bool _add(E element) {
    var rest = _rest;
    if (rest == null) _rest = rest = _newHashTable();
    var hash = _computeHashCode(element);
    var bucket = JS('var', '#[#]', rest, hash);
    if (bucket == null) {
      _LinkedHashSetCell cell = _newLinkedCell(element);
      _setTableEntry(rest, hash, JS('var', '[#]', cell));
    } else {
      int index = _findBucketIndex(bucket, element);
      if (index >= 0) return false;
      _LinkedHashSetCell cell = _newLinkedCell(element);
      JS('void', '#.push(#)', bucket, cell);
    }
    return true;
  }

  bool remove(Object? object) {
    if (_isStringElement(object)) {
      return _removeHashTableEntry(_strings, object);
    } else if (_isNumericElement(object)) {
      return _removeHashTableEntry(_nums, object);
    } else {
      return _remove(object);
    }
  }

  bool _remove(Object? object) {
    var rest = _rest;
    if (rest == null) return false;
    var hash = _computeHashCode(object);
    var bucket = JS('var', '#[#]', rest, hash);
    int index = _findBucketIndex(bucket, object);
    if (index < 0) return false;
    // Use splice to remove the [cell] element at the index and unlink it.
    _LinkedHashSetCell cell = JS('var', '#.splice(#, 1)[0]', bucket, index);
    if (0 == JS('int', '#.length', bucket)) {
      _deleteTableEntry(rest, hash);
    }
    _unlinkCell(cell);
    return true;
  }

  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    _LinkedHashSetCell? cell = _first;
    while (cell != null) {
      E element = cell._element;
      _LinkedHashSetCell? next = cell._next;
      int modifications = _modifications;
      bool shouldRemove = (removeMatching == test(element));
      if (modifications != _modifications) {
        throw ConcurrentModificationError(this);
      }
      if (shouldRemove) remove(element);
      cell = next;
    }
  }

  void clear() {
    if (_length > 0) {
      _strings = _nums = _rest = _first = _last = null;
      _length = 0;
      _modified();
    }
  }

  bool _addHashTableEntry(table, E element) {
    _LinkedHashSetCell? cell = _getTableEntry(table, element);
    if (cell != null) return false;
    _setTableEntry(table, element, _newLinkedCell(element));
    return true;
  }

  bool _removeHashTableEntry(table, Object? element) {
    if (table == null) return false;
    _LinkedHashSetCell? cell = _getTableEntry(table, element);
    if (cell == null) return false;
    _unlinkCell(cell);
    _deleteTableEntry(table, element);
    return true;
  }

  void _modified() {
    // Value cycles after 2^30 modifications. If you keep hold of an
    // iterator for that long, you might miss a modification
    // detection, and iteration can go sour. Don't do that.
    _modifications = _mask30 & (_modifications + 1);
  }

  // Create a new cell and link it in as the last one in the list.
  _LinkedHashSetCell _newLinkedCell(E element) {
    _LinkedHashSetCell cell = _LinkedHashSetCell(element);
    if (_first == null) {
      _first = _last = cell;
    } else {
      _LinkedHashSetCell last = _last!;
      cell._previous = last;
      _last = last._next = cell;
    }
    _length++;
    _modified();
    return cell;
  }

  // Unlink the given cell from the linked list of cells.
  void _unlinkCell(_LinkedHashSetCell cell) {
    _LinkedHashSetCell? previous = cell._previous;
    _LinkedHashSetCell? next = cell._next;
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

  static bool _isStringElement(element) {
    return element is String && element != '__proto__';
  }

  static bool _isNumericElement(element) {
    // Only treat unsigned 30-bit integers as numeric elements. This
    // way, we avoid converting them to strings when we use them as
    // keys in the JavaScript hash table object.
    return element is num &&
        JS('bool', '(# & #) === #', element, _mask30, element);
  }

  int _computeHashCode(element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', element.hashCode, _mask30);
  }

  static _getTableEntry(table, key) {
    return JS('var', '#[#]', table, key);
  }

  static void _setTableEntry(table, key, value) {
    assert(value != null);
    JS('void', '#[#] = #', table, key, value);
  }

  static void _deleteTableEntry(table, key) {
    JS('void', 'delete #[#]', table, key);
  }

  List? _getBucket(table, element) {
    var hash = _computeHashCode(element);
    return JS('var', '#[#]', table, hash);
  }

  int _findBucketIndex(bucket, element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (cell._element == element) return i;
    }
    return -1;
  }

  static _newHashTable() {
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

base class _LinkedIdentityHashSet<E> extends _LinkedHashSet<E> {
  Set<E> _newSet() => _LinkedIdentityHashSet<E>();
  Set<R> _newSimilarSet<R>() => _LinkedIdentityHashSet<R>();

  int _computeHashCode(key) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic keys like '__proto__'. Another option
    // would be to throw an exception if the hash code isn't a number.
    return JS('int', '# & #', identityHashCode(key), _mask30);
  }

  int _findBucketIndex(bucket, element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (identical(cell._element, element)) return i;
    }
    return -1;
  }
}

base class _LinkedCustomHashSet<E> extends _LinkedHashSet<E> {
  _Equality<E> _equality;
  _Hasher<E> _hasher;
  bool Function(Object?) _validKey;
  _LinkedCustomHashSet(
    this._equality,
    this._hasher,
    bool validKey(potentialKey)?,
  ) : _validKey = (validKey != null) ? validKey : ((x) => x is E);

  Set<E> _newSet() => _LinkedCustomHashSet<E>(_equality, _hasher, _validKey);
  Set<R> _newSimilarSet<R>() => _LinkedHashSet<R>();

  int _findBucketIndex(bucket, element) {
    if (bucket == null) return -1;
    int length = JS('int', '#.length', bucket);
    for (int i = 0; i < length; i++) {
      _LinkedHashSetCell cell = JS('var', '#[#]', bucket, i);
      if (_equality(cell._element, element)) return i;
    }
    return -1;
  }

  int _computeHashCode(element) {
    // We force the hash codes to be unsigned 30-bit integers to avoid
    // issues with problematic elements like '__proto__'. Another
    // option would be to throw an exception if the hash code isn't a
    // number.
    return JS('int', '# & #', _hasher(element), _mask30);
  }

  bool add(E element) => super._add(element);

  bool contains(Object? object) {
    if (!_validKey(object)) return false;
    return super._contains(object);
  }

  E? lookup(Object? object) {
    if (!_validKey(object)) return null;
    return super._lookup(object);
  }

  bool remove(Object? object) {
    if (!_validKey(object)) return false;
    return super._remove(object);
  }

  bool containsAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (!_validKey(element) || !this.contains(element)) return false;
    }
    return true;
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) {
      if (_validKey(element)) {
        super._remove(element);
      }
    }
  }
}

class _LinkedHashSetCell {
  final _element;

  _LinkedHashSetCell? _next;
  _LinkedHashSetCell? _previous;

  _LinkedHashSetCell(this._element);
}

// TODO(kasperl): Share this code with LinkedHashMapKeyIterator<E>?
class _LinkedHashSetIterator<E> implements Iterator<E> {
  final _LinkedHashSet<E> _set;
  final int _modifications;
  _LinkedHashSetCell? _cell;
  E? _current;

  _LinkedHashSetIterator(this._set, this._modifications) {
    _cell = _set._first;
  }

  E get current => _current as E;

  bool moveNext() {
    var cell = _cell;
    if (_modifications != _set._modifications) {
      throw ConcurrentModificationError(_set);
    } else if (cell == null) {
      _current = null;
      return false;
    } else {
      _current = cell._element;
      _cell = cell._next;
      return true;
    }
  }
}
